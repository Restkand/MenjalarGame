extends RefCounted

# Sejak R2 dunia TIDAK punya Image lagi — grid satuan adalah satu-satunya
# kebenaran, dan tampilannya diterjemahkan TerrainView (TileMapLayer) plus
# FasadView (jendela/pintu/ledge). Perubahan grid ditandai per PETAK 8x8
# lewat tile_kotor, lalu view yang menggambar ulang petak itu.

var grid
var light
var vis
var members = []
var joints  = []
var panels  = []       # massa dinding di antara rangka
var windows = []       # titik tengah tiap jendela — dipakai lampu & FasadView
var fitur   = []       # {jenis, rect} — pintu & ledge, digambar FasadView
var settled            # puing yang sudah mengendap, 0/1 per piksel
var puing_atas = 0     # baris tertinggi yang sudah tertutup puing
var solve_order = []   # id member dalam urutan topologis atas-ke-bawah

var tile_kotor = {}    # Vector2i petak -> true; diambil TerrainView tiap frame

var _bake_y    = -1    # baris bake berikutnya; -1 = tidak ada bake berjalan
var _bake_awal = 0     # baris awal bake ini, hanya untuk menghitung kemajuan

const PETAK = 8        # satuan per petak TileMap (32 px / PPU 4)


func build():
	grid = PackedByteArray(); grid.resize(Config.W * Config.H)
	light = PackedFloat32Array(); light.resize(Config.W * Config.H)
	vis = PackedFloat32Array(); vis.resize(Config.W * Config.H)
	settled = PackedByteArray(); settled.resize(Config.W * Config.H)
	puing_atas = Config.H

	# TAHAP A: tata letak diskalakan dari dunia 240x160 ke 480x320. Ini
	# penskalaan setia, bukan rancangan ulang — bawah tanah baru dirombak di
	# TAHAP C, dan mencampur keduanya membuat perubahan kamera tidak bisa
	# diverifikasi sendirian.
	_rect(0, 0, Config.W, Config.GROUND_Y, Config.T_SKY)
	_rect(0, Config.GROUND_Y, Config.W, Config.H - Config.GROUND_Y,
			Config.T_SOIL_DRY)
	_rect(0, 234, 148, 86, Config.T_SOIL_WET)
	_rect(336, 242, 144, 78, Config.T_SOIL_WET)
	_rect(120, 214, 52, 24, Config.T_CONCRETE)
	_rect(396, 268, 44, 8, Config.T_PIPE)

	# gedung tetangga di kiri — sumber bayangan; matahari datang dari atas-kiri
	_rect(0, 60, 84, 132, Config.T_NEIGHBOR)
	# tetangga kanan hanya membingkai; terlalu jauh dari arah sinar untuk
	# membayangi fasad
	_rect(400, 104, 80, 88, Config.T_NEIGHBOR)

	# fasad utama
	_rect(Config.FACADE_X0, Config.FACADE_Y0,
			Config.FACADE_X1 - Config.FACADE_X0,
			Config.FACADE_Y1 - Config.FACADE_Y0,
			Config.T_WALL)

	# jendela — titik tengahnya dicatat supaya lampu malam & FasadView tahu di
	# mana harus berdiri, dan supaya keduanya padam saat jendelanya runtuh
	# 6 baris x 9 kolom = 54 jendela. Barisnya menempati y 40-55, 66-81, 92-107,
	# 118-133, 144-159, 170-185; ledge dan pipa sengaja diletakkan di sela-sela
	# itu supaya tidak menimpa satu pun jendela.
	windows = []
	for jy in range(40, 180, 26):
		for jx in range(110, 372, 30):
			_rect(jx, jy, 14, 16, Config.T_WINDOW)
			windows.append(Vector2(jx + 7, jy + 8))

	# Fitur fasad yang digambar FasadView di atas ubin dinding. Grid tetap
	# memegang bentuk persisnya, jadi tigmotropisme dan vis tidak berubah —
	# fitur hanyalah gambarnya.
	fitur = []

	# ledge — penghalang yang harus diputari. Tebalnya 4 px, bukan 3: sinar
	# matahari sekarang melangkah 2 unit sekaligus (Config.BAKE_LANGKAH), dan
	# penghalang setipis 3 px bisa terlewati di antara dua langkah.
	for r in [Rect2i(100, 110, 110, 4), Rect2i(254, 58, 120, 4),
			Rect2i(190, 136, 130, 4)]:
		_rect(r.position.x, r.position.y, r.size.x, r.size.y, Config.T_LEDGE)
		fitur.append({"jenis": "ledge", "rect": r})

	# pintu
	_rect(220, 160, 40, 32, Config.T_DOOR)
	fitur.append({"jenis": "pintu", "rect": Rect2i(220, 160, 40, 32)})

	# jalur pipa vertikal — koridor gelap untuk menyelinap
	_rect(156, Config.FACADE_Y0, 6, 168, Config.T_LEDGE)
	fitur.append({"jenis": "ledge",
			"rect": Rect2i(156, Config.FACADE_Y0, 6, 168)})

	tile_kotor = {}   # TerrainView membangun ulang penuh setelah build()
	bake_mulai(Config.FACADE_Y0)
	_build_frame()


func _rect(x, y, w, h, kind):
	for j in range(y, y + h):
		for i in range(x, x + w):
			if i < 0 or i >= Config.W or j < 0 or j >= Config.H:
				continue
			grid.set(j * Config.W + i, kind)


# ---------------------------------------------------------------------------
# Bake cahaya & keterlihatan — DICICIL
#
# Fasad 288x168 pada kisi 2 px berarti 12.096 sinar. Satu sapuan penuh jauh
# melewati anggaran satu frame di GDScript, jadi bake dijalankan beberapa baris
# per frame lewat bake_langkah(). Pemanggilnya (main.gd) menahan permainan
# selama bake_sibuk() masih true, dan layar MULAI yang sudah ada menyembunyikan
# seluruh penantian itu.
#
# Aman dicicil karena vis[y] hanya membaca light[y] — satu baris tidak pernah
# bergantung pada baris yang belum dipanggang.
# ---------------------------------------------------------------------------

# Memulai (atau memperluas) bake dari baris y_awal ke bawah.
#
# Dipanggil dua kali: sekali saat build(), dan sekali lagi tiap kali tumpukan
# puing stabil. Yang kedua tidak perlu memanggang seluruh fasad — sinar datang
# dari atas-kiri, jadi puing hanya bisa membayangi yang berada DI BAWAHNYA.
func bake_mulai(y_awal):
	var y0 = int(clamp(y_awal, Config.FACADE_Y0, Config.FACADE_Y1 - 1))
	# tetap selaras dengan kisi 2 px
	y0 -= (y0 - Config.FACADE_Y0) % 2
	# Bake yang sedang berjalan tidak boleh kehilangan sisanya: ambil yang
	# paling atas dari keduanya.
	if _bake_y >= 0:
		y0 = min(y0, _bake_y)
	_bake_awal = y0
	_bake_y = y0


func bake_sibuk():
	return _bake_y >= 0


func bake_kemajuan():
	if _bake_y < 0:
		return 1.0
	var total = Config.FACADE_Y1 - _bake_awal
	if total <= 0:
		return 1.0
	return clamp(float(_bake_y - _bake_awal) / float(total), 0.0, 1.0)


func bake_langkah(baris):
	if _bake_y < 0:
		return
	var akhir = min(Config.FACADE_Y1, _bake_y + baris)
	while _bake_y < akhir:
		_bake_light_row(_bake_y)
		_bake_vis_row(_bake_y)
		_bake_vis_row(_bake_y + 1)
		_bake_y += 2
	if _bake_y >= Config.FACADE_Y1:
		_bake_y = -1


# Satu sapuan mendatar mengisi blok 2x2, jadi baris y sekaligus y+1.
func _bake_light_row(y):
	var x = Config.FACADE_X0
	while x < Config.FACADE_X1:
		var v = 1.0 if _ray_clear(x, y) else 0.16
		for dy in range(0, 2):
			for dx in range(0, 2):
				var i = (y + dy) * Config.W + (x + dx)
				if i >= 0 and i < light.size():
					light.set(i, v)
		x += 2


# Melangkah BAKE_LANGKAH unit sekaligus, bukan 1. Separuh biaya, dan penghalang
# yang perlu dikenali (tetangga, ledge 4 px, tumpukan puing) semuanya lebih
# tebal daripada satu langkah. Yang bisa terlewat hanya tepi paling tipis
# sebuah tumpukan puing — bayangannya bocor sedikit, dan itu diterima.
func _ray_clear(sx, sy):
	var x = float(sx)
	var y = float(sy)
	var dx = Config.SUN_RAY.x * Config.BAKE_LANGKAH
	var dy = Config.SUN_RAY.y * Config.BAKE_LANGKAH
	for _i in range(Config.BAKE_MAX):
		x += dx
		y += dy
		if y < 0 or x < 0:
			return true
		var k = at(int(round(x)), int(round(y)))
		# puing ikut memblokir: tumpukan reruntuhan mengubah siluet gedung,
		# jadi ia melemparkan bayangan seperti ledge
		if k == Config.T_NEIGHBOR or k == Config.T_LEDGE \
				or k == Config.T_PUING:
			return false
	return true


func _bake_vis_row(y):
	if y < Config.FACADE_Y0 or y >= Config.FACADE_Y1:
		return
	for x in range(Config.FACADE_X0, Config.FACADE_X1):
		var i = y * Config.W + x
		var h = float(y - Config.FACADE_Y0) \
				/ float(Config.FACADE_Y1 - Config.FACADE_Y0)
		var v = 0.20 + 0.48 * light[i] + 0.28 * h
		var k = grid[i]
		if k == Config.T_WINDOW:
			v += 0.30
		if k == Config.T_DOOR or y > Config.FACADE_Y1 - 26:
			v += 0.30
		if k == Config.T_LEDGE:
			v -= 0.28
		vis.set(i, clamp(v, 0.0, 1.0))


# ---------------------------------------------------------------------------
# Rangka struktural
#
# Lapisan data murni di atas grid terrain. grid, image, light, dan vis tidak
# tersentuh sama sekali. Belum ada perhitungan beban dan belum ada keruntuhan
# — itu TAHAP 3.
#
# Kolom dan balok disimpan sebagai RUAS antar-joint, bukan satu member utuh,
# supaya beban punya kisi untuk mengalir. Di layar tetap tampak 4 kolom dan
# 5 balok.
#
# _kolom_id() dan _balok_id() menghitung id dari koordinat kisi, jadi urutan
# pembuatan di _build_frame() mengikat: SELURUH ruas kolom dibuat lebih dulu,
# baru seluruh ruas balok.
# ---------------------------------------------------------------------------

func _build_frame():
	members = []
	joints = []
	panels = []
	solve_order = []

	var cx = []   # x tiap garis kolom
	for i in range(Config.FRAME_COLS):
		cx.append(Config.FACADE_X0 + int(round(
				float(i) * float(Config.FACADE_X1 - 1 - Config.FACADE_X0)
				/ float(Config.FRAME_COLS - 1))))

	var ry = []   # y tiap level balok
	for j in range(Config.FRAME_ROWS):
		ry.append(Config.FACADE_Y0 + int(round(
				float(j) * float(Config.FACADE_Y1 - 1 - Config.FACADE_Y0)
				/ float(Config.FRAME_ROWS - 1))))

	# joint di tiap perpotongan — id = j * FRAME_COLS + i
	for j in range(Config.FRAME_ROWS):
		for i in range(Config.FRAME_COLS):
			joints.append({
				"id": joints.size(),
				"x": cx[i],
				"y": ry[j],
				"col": i,
				"row": j,
				"member_terhubung": [],
				"integritas": 1.0,
			})

	# ruas kolom — wajib dibuat lebih dulu, lihat _kolom_id()
	for i in range(Config.FRAME_COLS):
		for j in range(Config.FRAME_ROWS - 1):
			_add_member(Config.M_KOLOM, cx[i], ry[j], cx[i], ry[j + 1],
					_joint_id(i, j), _joint_id(i, j + 1))

	# ruas balok
	for j in range(Config.FRAME_ROWS):
		for i in range(Config.FRAME_COLS - 1):
			_add_member(Config.M_BALOK, cx[i], ry[j], cx[i + 1], ry[j],
					_joint_id(i, j), _joint_id(i + 1, j))

	_link_supports()
	_build_solve_order()

	# Panel dinding di antara rangka. INI massa gedung yang sebenarnya.
	# Member cuma garis selebar 3 piksel, jadi tanpa panel, menghancurkan
	# seluruh rangka nyaris tidak mengubah apa pun di layar — persis yang
	# terjadi di playtest: STRUKTUR 0% tapi gedungnya masih berdiri utuh.
	# Empat member yang mengurung tiap panel dicatat sebagai penopangnya.
	for j in range(Config.FRAME_ROWS - 1):
		for i in range(Config.FRAME_COLS - 1):
			panels.append({
				"x0": cx[i], "y0": ry[j],
				"x1": cx[i + 1], "y1": ry[j + 1],
				"alive": true,
				"rangka": [
					_balok_id(i, j), _balok_id(i, j + 1),
					_kolom_id(i, j), _kolom_id(i + 1, j),
				],
			})


# Urutan topologis: di tiap level, balok dulu baru ruas kolom. Keduanya hanya
# menyuapi ruas di bawahnya, jadi satu sapuan atas-ke-bawah sudah cukup — tidak
# perlu algoritma graf. Structure.gd memakai daftar ini dan karenanya tidak
# perlu tahu apa pun tentang bentuk kisinya.
func _build_solve_order():
	solve_order = []
	for j in range(Config.FRAME_ROWS):
		for i in range(Config.FRAME_COLS - 1):
			solve_order.append(_balok_id(i, j))
		for i in range(Config.FRAME_COLS):
			var kid = _kolom_id(i, j)
			if kid >= 0:
				solve_order.append(kid)


func _add_member(tipe, x0, y0, x1, y1, ja, jb):
	var m = {
		"id": members.size(),
		"x0": x0, "y0": y0,
		"x1": x1, "y1": y1,
		"tipe": tipe,
		"panjang": Vector2(x1 - x0, y1 - y0).length(),
		"alive": true,
		"integritas": 1.0,
		"beban": 0.0,
		"member_bawah": [],
		"joint_a": ja,
		"joint_b": jb,
	}
	members.append(m)
	joints[ja].member_terhubung.append(m.id)
	joints[jb].member_terhubung.append(m.id)
	return m.id


func _link_supports():
	# Ruas kolom ditopang ruas kolom di bawahnya. Yang paling bawah berdiri di
	# pondasi, jadi member_bawah-nya kosong.
	for i in range(Config.FRAME_COLS):
		for j in range(Config.FRAME_ROWS - 1):
			var below = _kolom_id(i, j + 1)
			if below >= 0:
				members[_kolom_id(i, j)].member_bawah.append(below)

	# Ruas balok ditopang ruas kolom yang menggantung di bawah kedua joint
	# ujungnya. Di level paling bawah tidak ada kolom di bawahnya — pondasi.
	for j in range(Config.FRAME_ROWS):
		for i in range(Config.FRAME_COLS - 1):
			var b = members[_balok_id(i, j)]
			for k in [i, i + 1]:
				var kid = _kolom_id(k, j)
				if kid >= 0:
					b.member_bawah.append(kid)


func _joint_id(i, j):
	return j * Config.FRAME_COLS + i


func _kolom_id(i, j):
	# ruas kolom pada garis kolom i, antara level balok j dan j+1
	if i < 0 or i >= Config.FRAME_COLS or j < 0 or j >= Config.FRAME_ROWS - 1:
		return -1
	return i * (Config.FRAME_ROWS - 1) + j


func _balok_id(i, j):
	# ruas balok pada level j, antara garis kolom i dan i+1
	if i < 0 or i >= Config.FRAME_COLS - 1 or j < 0 or j >= Config.FRAME_ROWS:
		return -1
	return Config.FRAME_COLS * (Config.FRAME_ROWS - 1) \
			+ j * (Config.FRAME_COLS - 1) + i


func at(x, y):
	if x < 0 or x >= Config.W or y < 0 or y >= Config.H:
		return Config.T_NEIGHBOR
	return grid[y * Config.W + x]


func light_at(x, y):
	if x < 0 or x >= Config.W or y < 0 or y >= Config.H:
		return 0.0
	return light[y * Config.W + x]


func vis_at(x, y):
	if x < 0 or x >= Config.W or y < 0 or y >= Config.H:
		return 0.0
	return vis[y * Config.W + x]


# Permukaan yang bisa dicengkeram tanaman. Termasuk PUING: tumpukan reruntuhan
# adalah tanah baru, dan itulah yang membuat pemain bisa memanjat lewat puing
# yang dia jatuhkan sendiri.
func on_facade(x, y):
	var k = at(int(round(x)), int(round(y)))
	return k == Config.T_WALL or k == Config.T_WINDOW \
			or k == Config.T_DOOR or k == Config.T_PUING


# Permukaan yang bisa dipijak sulur. Inilah predikat yang dipakai pertumbuhan,
# BUKAN on_facade() mentah.
#
# Lubang hasil keruntuhan hanya selebar 3 piksel. Kalau sulur tidak bisa
# menyeberanginya, fasad terpotong jadi panel-panel terpisah dan sulur
# terkurung selamanya — persis yang terjadi di playtest. Jadi sulur boleh
# merentang sejauh VINE_JEMBATAN piksel, seperti sulur sungguhan melewati
# retakan.
#
# Hanya arah sumbu yang dipindai, bukan kotak penuh: member selalu tegak atau
# mendatar, jadi celahnya pasti sejajar sumbu. 8 lookup, bukan 25 — penting
# karena normal_at() memanggil solid_at() 24 kali per tabrakan.
#
# Dibatasi ke dalam kotak fasad supaya sulur tidak melayang keluar siluet.
func vine_ok(x, y):
	var ix = int(round(x))
	var iy = int(round(y))
	if on_facade(ix, iy):
		return true
	if ix < Config.FACADE_X0 or ix >= Config.FACADE_X1 \
			or iy < Config.FACADE_Y0 or iy >= Config.FACADE_Y1:
		return false
	for d in range(1, Config.VINE_JEMBATAN + 1):
		if on_facade(ix + d, iy) or on_facade(ix - d, iy) \
				or on_facade(ix, iy + d) or on_facade(ix, iy - d):
			return true
	return false


# ---------------------------------------------------------------------------
# Terjemahan grid -> petak TileMap (dipakai TerrainView)
# ---------------------------------------------------------------------------

# Terrain sebuah petak 8x8: mayoritas isi grid-nya. Fitur fasad (jendela,
# pintu, ledge) dihitung sebagai DINDING — gambarnya urusan FasadView, ubin
# di belakangnya tetap dinding. Puing menang lebih awal: tumpukan menipis di
# puncak, dan puncak yang tak tergambar membuat tumpukan terlihat melayang.
func tile_terrain(tx, ty):
	var hitung = {}
	var puing = 0
	for dy in range(PETAK):
		var y = ty * PETAK + dy
		for dx in range(PETAK):
			var k = grid[y * Config.W + tx * PETAK + dx]
			if k == Config.T_WINDOW or k == Config.T_DOOR \
					or k == Config.T_LEDGE:
				k = Config.T_WALL
			if k == Config.T_PUING:
				puing += 1
			hitung[k] = hitung.get(k, 0) + 1
	if puing >= 6:
		return Config.T_PUING
	var best = Config.T_SKY
	var n = -1
	for k in hitung:
		if hitung[k] > n:
			n = hitung[k]
			best = k
	return best


func _tandai_petak(x, y):
	tile_kotor[Vector2i(x / PETAK, y / PETAK)] = true


# TerrainView memanggil ini tiap frame: ambil semua petak kotor, kosongkan.
func ambil_tile_kotor():
	if tile_kotor.is_empty():
		return []
	var keluar = tile_kotor.keys()
	tile_kotor = {}
	return keluar


# ---------------------------------------------------------------------------
# Perusakan — kebalikan dari _rect()
# ---------------------------------------------------------------------------

# Menghapus grid di sepanjang member, menyisakan lubang tembus pandang.
func carve_member(m):
	var n = int(max(abs(m.x1 - m.x0), abs(m.y1 - m.y0)))
	for k in range(n + 1):
		var t = float(k) / float(max(1, n))
		var px = int(round(m.x0 + (m.x1 - m.x0) * t))
		var py = int(round(m.y0 + (m.y1 - m.y0) * t))
		for dy in range(-Config.MEMBER_TEBAL, Config.MEMBER_TEBAL + 1):
			for dx in range(-Config.MEMBER_TEBAL, Config.MEMBER_TEBAL + 1):
				_carve_px(px + dx, py + dy)


# Sepotong panel, dari baris ya sampai yb. Panel diluruhkan sedikit demi
# sedikit dari atas ke bawah, bukan dihapus sekaligus, supaya pemain melihat
# dindingnya jatuh alih-alih menghilang begitu saja.
func carve_rows(p, ya, yb):
	for y in range(max(p.y0, ya), min(p.y1, yb) + 1):
		for x in range(p.x0, p.x1 + 1):
			_carve_px(x, y)


# Hanya melubangi bagian gedung. Tanah, pipa, dan beton bawah tanah tidak
# tersentuh walau kuas melebar melewati garis tanah.
func _carve_px(x, y):
	if x < 0 or x >= Config.W or y < 0 or y >= Config.H:
		return
	var k = grid[y * Config.W + x]
	if k != Config.T_WALL and k != Config.T_WINDOW \
			and k != Config.T_DOOR and k != Config.T_LEDGE:
		return
	grid.set(y * Config.W + x, Config.T_SKY)
	_tandai_petak(x, y)


# Puing hanya bertumpu pada tanah dan puing lain. Gedung TIDAK menghalangi:
# kita melihat fasad dari depan, jadi reruntuhan jatuh di depan dinding.
func blocked(x, y):
	if x < 0 or x >= Config.W or y < 0:
		return true
	if y >= Config.GROUND_Y:
		return true
	return settled[y * Config.W + x] != 0


# Sekumpulan puing yang mengendap di frame yang sama. Menulis ke settled dan
# grid — sejak TAHAP 6 puing adalah terrain sungguhan yang bisa ditumbuhi,
# dan sejak R2 gambarnya diurus TerrainView lewat petak kotor.
func settle_many(points):
	if points.is_empty():
		return
	for p in points:
		# 2x2, sama seperti saat melayang, supaya tumpukan tidak mendadak
		# menyusut jadi sebutir begitu mendarat
		for dy in range(0, 2):
			for dx in range(0, 2):
				var x = int(p.x) + dx
				var y = int(p.y) + dy
				if x < 0 or x >= Config.W or y < 0 or y >= Config.H:
					continue
				settled.set(y * Config.W + x, 1)
				grid.set(y * Config.W + x, Config.T_PUING)
				_tandai_petak(x, y)
				if y < puing_atas:
					puing_atas = y


# Member hanya sekuat sambungan terlemahnya. Satu-satunya sumber kebenaran
# untuk kapasitas — dipakai deteksi gagal, warna debug, dan retakan.
func kapasitas(m):
	return m.integritas * min(joints[m.joint_a].integritas,
			joints[m.joint_b].integritas) * Config.KAPASITAS_MAX


# Joint terdekat yang masih layak diserang: belum habis, dan setidaknya satu
# member yang menempel padanya masih hidup.
func nearest_joint(p, radius):
	var best = radius
	var found = null
	for j in joints:
		if j.integritas <= 0.0:
			continue
		var hidup = false
		for mid in j.member_terhubung:
			if members[mid].alive:
				hidup = true
				break
		if not hidup:
			continue
		var d = p.distance_to(Vector2(j.x, j.y))
		if d < best:
			best = d
			found = j
	return found


# Kaki gedung terdekat — ruas KOLOM paling bawah. Sasaran akar.
#
# Sengaja bukan "semua member ber-member_bawah kosong": balok level dasar juga
# memenuhi syarat itu, padahal tidak ada yang bertumpu padanya, jadi
# meruntuhkannya tidak memicu apa pun. Lebih buruk, akar lahir 2 piksel di
# bawah balok dasar dan akan menggerogotinya sia-sia sejak frame pertama.
# Ruas kolom bawahlah yang memikul seluruh gedung.
func foundation_at(p, radius):
	var best = radius
	var found = null
	for m in members:
		if not m.alive or m.tipe != Config.M_KOLOM or m.integritas <= 0.0:
			continue
		if m.member_bawah.size() > 0:
			continue
		var d = _dist_seg(p, Vector2(m.x0, m.y0), Vector2(m.x1, m.y1))
		if d < best:
			best = d
			found = m
	return found


func member_at(p, radius):
	var best = radius
	var found = -1
	for m in members:
		if not m.alive:
			continue
		var d = _dist_seg(p, Vector2(m.x0, m.y0), Vector2(m.x1, m.y1))
		if d < best:
			best = d
			found = m.id
	return found


func _dist_seg(p, a, b):
	var ab = b - a
	var l2 = ab.length_squared()
	if l2 < 0.0001:
		return p.distance_to(a)
	var t = clamp((p - a).dot(ab) / l2, 0.0, 1.0)
	return p.distance_to(a + ab * t)
