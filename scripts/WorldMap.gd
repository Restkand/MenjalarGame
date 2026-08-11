extends RefCounted

# Sejak R2 dunia TIDAK punya Image lagi — grid satuan adalah satu-satunya
# kebenaran, dan tampilannya diterjemahkan TerrainView (TileMapLayer) plus
# FasadView (jendela/pintu/ledge). Perubahan grid ditandai per PETAK 8x8
# lewat tile_kotor, lalu view yang menggambar ulang petak itu.

var grid
var light
var vis
var windows = []       # titik tengah tiap jendela — dipakai lampu & FasadView
var fitur   = []       # {jenis, rect} — pintu & ledge, digambar FasadView
var settled            # puing yang sudah mengendap, 0/1 per piksel
var puing_atas = 0     # baris tertinggi yang sudah tertutup puing

var tile_kotor = {}    # Vector2i petak -> true; diambil TerrainView tiap frame

# Peta rambatan (TAHAP B). tutup[i] = 1 berarti sel itu pernah dirambati
# sulur. Tiga peran sekaligus:
#   1. pijakan KEKAL — vine_ok() menerimanya, jadi sulur tidak kehilangan
#      pijakan saat fasad di bawahnya gugur oleh erosi
#   2. bahan bakar erosi — sel fasad baru yang tertutup dilaporkan ke Erosi
#      lewat rambatan_baru
#   3. kemajuan pemain — tutupan() = sel fasad tertutup / luas fasad
var tutup
var rambatan_baru = []   # Vector2i petak-erosi yang baru mendapat sel tertutup
var facade_luas = 0      # sel fasad saat build; penyebut tutupan()
var tutup_luas  = 0      # sel fasad yang sudah dirambati

# Pengumpan perhatian (TAHAP D): keluhan penghuni datang dari jendela yang
# tertutup dan pintu yang terambati, dan zona dengan rambatan paling mencolok
# (berbobot vis) jadi sasaran perawatan yang diumumkan.
var jendela_luas = 0
var pintu_luas   = 0
var tutup_jendela = 0
var tutup_pintu   = 0
var zona_bobot = [0.0, 0.0, 0.0, 0.0]   # indeks = Config.ZONA_NAMA

var _bake_y    = -1    # baris bake berikutnya; -1 = tidak ada bake berjalan
var _bake_awal = 0     # baris awal bake ini, hanya untuk menghitung kemajuan

const PETAK = 8        # satuan per petak TileMap (32 px / PPU 4)


func build():
	grid = PackedByteArray(); grid.resize(Config.W * Config.H)
	tutup = PackedByteArray(); tutup.resize(Config.W * Config.H)
	rambatan_baru = []
	tutup_luas = 0
	light = PackedFloat32Array(); light.resize(Config.W * Config.H)
	vis = PackedFloat32Array(); vis.resize(Config.W * Config.H)
	settled = PackedByteArray(); settled.resize(Config.W * Config.H)
	puing_atas = Config.H

	_rect(0, 0, Config.W, Config.GROUND_Y, Config.T_SKY)

	# -----------------------------------------------------------------------
	# Bawah tanah (TAHAP C, docs/06 §3) — pane penuh dengan deposit dan
	# bahayanya sendiri, bukan lagi pita kosong.
	#
	# Puzzle airnya: tanah lembap yang tersebar memberi air kecil untuk
	# bertahan, tapi AKUIFER — sumber besar — dikurung lempeng beton yang
	# hanya bisa ditembus dengan membayar energi. Batu tidak bisa ditembus
	# sama sekali dan memaksa memutar; gorong-gorong mempercepat; utilitas
	# di bawah gedung membangunkan teknisi kalau disentuh.
	# -----------------------------------------------------------------------
	_rect(0, Config.GROUND_Y, Config.W, Config.H - Config.GROUND_Y,
			Config.T_SOIL_DRY)

	# tanah lembap — air kecil, tersebar, cukup untuk hidup hemat
	_rect(20, 230, 70, 30, Config.T_SOIL_WET)
	_rect(300, 210, 50, 25, Config.T_SOIL_WET)
	_rect(430, 250, 40, 30, Config.T_SOIL_WET)

	# humus — mempercepat akar; ditaruh di jalur menuju kedua akuifer
	_rect(180, 220, 50, 25, Config.T_HUMUS)
	_rect(260, 250, 40, 25, Config.T_HUMUS)

	# batu — penghalang mati, harus diputari
	_rect(90, 250, 40, 40, Config.T_BATU)
	_rect(350, 230, 50, 40, Config.T_BATU)
	_rect(200, 285, 40, 30, Config.T_BATU)

	# gorong-gorong — koridor cepat melintasi tengah peta
	_rect(130, 262, 220, 9, Config.T_GORONG)

	# utilitas — pita layanan tepat di bawah gedung, plus satu jalur turun.
	# Celah x 236..250 disisakan supaya akar pertama (lahir di SEED_X=240)
	# tidak langsung menyalakan alarm.
	_rect(150, 200, 86, 7, Config.T_UTILITAS)
	_rect(250, 200, 80, 7, Config.T_UTILITAS)
	_rect(324, 207, 7, 45, Config.T_UTILITAS)

	# dua akuifer di dasar peta, masing-masing terkurung cangkang beton.
	# Tebal tudung ~10 satuan = dua kali menembus (TEMBUS_PANJANG 6).
	_rect(40, 285, 130, 35, Config.T_CONCRETE)
	_rect(55, 296, 100, 22, Config.T_AKUIFER)
	_rect(390, 285, 90, 35, Config.T_CONCRETE)
	_rect(402, 296, 66, 22, Config.T_AKUIFER)

	# -----------------------------------------------------------------------
	# Atas tanah
	# -----------------------------------------------------------------------

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

	# luas fasad — penyebut tutupan(). Dihitung SEKALI di sini: sel yang
	# nanti gugur oleh erosi tetap dihitung tertutup (bekas rambatannya
	# tinggal), jadi penyebutnya tidak boleh ikut menyusut.
	facade_luas = 0
	jendela_luas = 0
	pintu_luas = 0
	tutup_jendela = 0
	tutup_pintu = 0
	zona_bobot = [0.0, 0.0, 0.0, 0.0]
	for i in range(grid.size()):
		var k = grid[i]
		if k == Config.T_WALL or k == Config.T_WINDOW \
				or k == Config.T_DOOR or k == Config.T_LEDGE:
			facade_luas += 1
			if k == Config.T_WINDOW:
				jendela_luas += 1
			elif k == Config.T_DOOR:
				pintu_luas += 1

	bake_mulai(Config.FACADE_Y0)


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
# Tiga lapis, berurutan dari yang termurah:
#   1. fasad/puing biasa
#   2. BEKAS RAMBATAN (tutup) — pijakan kekal. Fasad yang gugur oleh erosi
#      tetap bisa dipijak sulur yang pernah merambatinya; tanpa ini erosi
#      menghukum pemain justru karena berhasil menutup fasad
#   3. jembatan VINE_JEMBATAN piksel melewati celah sempit
#
# Hanya arah sumbu yang dipindai untuk jembatan, bukan kotak penuh — 8
# lookup, bukan 25; penting karena normal_at() memanggil solid_at() 24 kali
# per tabrakan. Dibatasi ke dalam kotak fasad supaya sulur tidak melayang
# keluar siluet.
func vine_ok(x, y):
	var ix = int(round(x))
	var iy = int(round(y))
	if on_facade(ix, iy):
		return true
	if ix < Config.FACADE_X0 or ix >= Config.FACADE_X1 \
			or iy < Config.FACADE_Y0 or iy >= Config.FACADE_Y1:
		return false
	if tutup[iy * Config.W + ix] == 1:
		return true
	for d in range(1, Config.VINE_JEMBATAN + 1):
		if on_facade(ix + d, iy) or on_facade(ix - d, iy) \
				or on_facade(ix, iy + d) or on_facade(ix, iy - d):
			return true
	return false


# ---------------------------------------------------------------------------
# Rambatan (TAHAP B) — dipanggil Strand tiap kali sulur mencatat titik baru
# ---------------------------------------------------------------------------

# Tandai 3x3 di sekitar titik sulur sebagai "pernah dirambati" — kira-kira
# selebar badan sulur. Sel fasad yang baru tertutup dilaporkan ke Erosi
# (per petak-erosi) dan dihitung ke tutupan. Sel puing hanya diberi pijakan
# kekal, tanpa erosi dan tanpa hitungan tutupan.
func rambati(px, py):
	for dy in range(-1, 2):
		var y = py + dy
		if y < 0 or y >= Config.H:
			continue
		for dx in range(-1, 2):
			var x = px + dx
			if x < 0 or x >= Config.W:
				continue
			var i = y * Config.W + x
			if tutup[i] == 1:
				continue
			var k = grid[i]
			if k == Config.T_WALL or k == Config.T_WINDOW \
					or k == Config.T_DOOR or k == Config.T_LEDGE:
				tutup.set(i, 1)
				tutup_luas += 1
				rambatan_baru.append(Vector2i(
						x / Config.EROSI_PETAK, y / Config.EROSI_PETAK))
				# pengumpan perhatian: jendela/pintu yang tertutup, dan
				# bobot zona berbanding nilai vis (mencolok = berat)
				if k == Config.T_WINDOW:
					tutup_jendela += 1
				elif k == Config.T_DOOR:
					tutup_pintu += 1
				zona_bobot[_zona(x, y)] += vis[i]
			elif k == Config.T_PUING:
				tutup.set(i, 1)


# Erosi memanggil ini tiap frame: ambil sel-fasad-baru-tertutup (per petak
# erosi; satu entri per sel), kosongkan.
func ambil_rambatan_baru():
	if rambatan_baru.is_empty():
		return []
	var keluar = rambatan_baru
	rambatan_baru = []
	return keluar


# Bagian fasad yang sudah dirambati, 0..1. Kemajuan pemain — dan kondisi
# menang sementara sampai TAHAP F menggantinya dengan target per zona.
func tutupan():
	if facade_luas == 0:
		return 0.0
	return float(tutup_luas) / float(facade_luas)


func rasio_jendela_tertutup():
	if jendela_luas == 0:
		return 0.0
	return float(tutup_jendela) / float(jendela_luas)


func rasio_pintu_tertutup():
	if pintu_luas == 0:
		return 0.0
	return float(tutup_pintu) / float(pintu_luas)


# Kuadran fasad tempat sebuah sel berada — indeks ke Config.ZONA_NAMA.
func _zona(x, y):
	var tx = (Config.FACADE_X0 + Config.FACADE_X1) / 2
	var ty = (Config.FACADE_Y0 + Config.FACADE_Y1) / 2
	return (0 if x < tx else 1) + (0 if y < ty else 2)


# Zona dengan rambatan paling mencolok — sasaran perawatan yang diumumkan
# kalender saat inspeksi.
func zona_teratas_idx():
	var best = 0
	for i in range(1, 4):
		if zona_bobot[i] > zona_bobot[best]:
			best = i
	return best


# ---------------------------------------------------------------------------
# Menembus beton (TAHAP C)
# ---------------------------------------------------------------------------

# Apakah ujung akar menempel beton — syarat memulai menembus.
func dekat_beton(p):
	var px = int(round(p.x))
	var py = int(round(p.y))
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			if at(px + dx, py + dy) == Config.T_CONCRETE:
				return true
	return false


# Menembus selesai: gali terowongan pendek searah pertumbuhan akar. HANYA
# beton yang tergali — batu tetap mustahil, dan itu disengaja: beton adalah
# gerbang berbayar, batu adalah dinding.
func tembus_beton(p, angle):
	var arah = Vector2(cos(angle), sin(angle))
	for langkah in range(0, Config.TEMBUS_PANJANG + 1):
		var c = p + arah * float(langkah)
		var cx = int(round(c.x))
		var cy = int(round(c.y))
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				if dx * dx + dy * dy > 5:
					continue
				var x = cx + dx
				var y = cy + dy
				if x < 0 or x >= Config.W \
						or y < Config.GROUND_Y or y >= Config.H:
					continue
				if grid[y * Config.W + x] == Config.T_CONCRETE:
					grid.set(y * Config.W + x, Config.T_SOIL_DRY)
					_tandai_petak(x, y)


# Erosi menggugurkan satu petak: lubangi semua sel gedung di kotak itu.
# Mengembalikan true kalau memang ada yang terlubangi.
func carve_kotak(x0, y0, sisi):
	var ada = false
	for y in range(y0, y0 + sisi):
		for x in range(x0, x0 + sisi):
			if x < 0 or x >= Config.W or y < 0 or y >= Config.H:
				continue
			var k = grid[y * Config.W + x]
			if k == Config.T_WALL or k == Config.T_WINDOW \
					or k == Config.T_DOOR or k == Config.T_LEDGE:
				_carve_px(x, y)
				ada = true
	return ada


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
