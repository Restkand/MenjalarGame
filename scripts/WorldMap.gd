extends RefCounted

# Sejak R2 dunia TIDAK punya Image lagi — grid satuan adalah satu-satunya
# kebenaran, dan tampilannya diterjemahkan TerrainView (TileMapLayer) plus
# FasadView (jendela/pintu/ledge). Perubahan grid ditandai per PETAK 8x8
# lewat tile_kotor, lalu view yang menggambar ulang petak itu.

var grid
var jaringan           # 0/1 per satuan — jejak untai untuk avatar (P1)
var dalam              # grid interior gedung (P2) — enum T_RUANG.. di tapak fasad
var dijelajah          # 0/1 per PETAK — kabut peta layar M (P3.75)
var light
var vis
var windows = []       # titik tengah tiap jendela — dipakai lampu & FasadView
var fitur   = []       # {jenis, rect} — pintu & ledge, digambar FasadView
var settled            # puing yang sudah mengendap, 0/1 per piksel
var settled_n = 0      # jumlah sel mengendap — PuingTanahView redraw saat berubah
var puing_atas = 0     # baris tertinggi yang sudah tertutup puing

var tile_kotor = {}    # Vector2i petak -> true; diambil TerrainView tiap frame

var kolam = []         # cadangan akuifer (G4); diisi build()
var pesan_kering = ""  # pengumuman kolam yang habis; dibaca-kosongkan main

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

# Tutupan per kuadran (TAHAP F): sasaran babak II adalah TIAP zona, bukan
# angka global — menumpuk semuanya di satu sudut gelap tidak lagi menang.
var zona_luas  = [0, 0, 0, 0]
var zona_tutup = [0, 0, 0, 0]

const PETAK = 8        # satuan per petak TileMap (32 px / PPU 4)

var _pw = 0            # lebar grid petak (Config.W / PETAK), diisi build()


func build():
	grid = PackedByteArray(); grid.resize(Config.W * Config.H)
	tutup = PackedByteArray(); tutup.resize(Config.W * Config.H)
	# jaringan (P1, docs/13): jejak SEMUA untai — sulur DAN akar, di terrain
	# apa pun. Inilah "jalan raya" avatar; beda dari `tutup` yang hanya
	# menandai fasad demi ekonomi tutupan.
	jaringan = PackedByteArray(); jaringan.resize(Config.W * Config.H)
	dijelajah = PackedByteArray()
	dijelajah.resize((Config.W / PETAK) * (Config.H / PETAK))
	_bangun_interior()
	rambatan_baru = []
	tutup_luas = 0
	# light & vis per PETAK 8x8, bukan per satuan (R4) — 2.400 sel.
	# light default 1.0: area di luar fasad (langit, atas tumpukan puing di
	# tepi) dianggap tersinari penuh; vis default 0 (tak ada yang melihat).
	_pw = Config.W / PETAK
	var _ph = Config.H / PETAK
	light = PackedFloat32Array(); light.resize(_pw * _ph)
	light.fill(1.0)
	vis = PackedFloat32Array(); vis.resize(_pw * _ph)
	settled = PackedByteArray(); settled.resize(Config.W * Config.H)
	settled_n = 0
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

	# --- terowongan metroidvania (P3.75, docs/13 §4) -----------------------
	# Bawah tanah jadi wilayah jelajah sungguhan bagi avatar LEPAS: dua
	# lubang got dari trotoar turun ke selokan dangkal, tulang tengah
	# menghubungkannya ke gorong lama, dan dua cabang buntu berhenti TEPAT
	# di cangkang beton akuifer — gerbang yang kelak dibuka bor (P7).
	_rect(146, Config.GROUND_Y, 5, 18, Config.T_GORONG)   # got barat
	_rect(330, Config.GROUND_Y, 5, 18, Config.T_GORONG)   # got timur
	_rect(120, 210, 240, 7, Config.T_GORONG)              # selokan dangkal
	_rect(236, 217, 5, 45, Config.T_GORONG)               # turunan ke gorong
	_rect(120, 217, 5, 60, Config.T_GORONG)               # cabang barat
	_rect(96, 270, 29, 7, Config.T_GORONG)                # ...ke cangkang barat
	_rect(355, 217, 5, 62, Config.T_GORONG)               # cabang timur
	_rect(360, 272, 32, 7, Config.T_GORONG)               # ...ke cangkang timur

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

	# cadangan tiap kolam (G4): permukaan airnya turun saat disedot akar.
	# `level` = kedalaman float yang sudah terkuras; `terkuras` = baris yang
	# sudah dikonversi jadi tanah lembap.
	kolam = [
		{"x0": 55, "x1": 154, "y0": 296, "y1": 317,
				"level": 0.0, "terkuras": 0, "nama": "BARAT"},
		{"x0": 402, "x1": 467, "y0": 296, "y1": 317,
				"level": 0.0, "terkuras": 0, "nama": "TIMUR"},
	]
	pesan_kering = ""

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
	zona_luas = [0, 0, 0, 0]
	zona_tutup = [0, 0, 0, 0]
	for i in range(grid.size()):
		var k = grid[i]
		if k == Config.T_WALL or k == Config.T_WINDOW \
				or k == Config.T_DOOR or k == Config.T_LEDGE:
			facade_luas += 1
			zona_luas[_zona(i % Config.W, i / Config.W)] += 1
			if k == Config.T_WINDOW:
				jendela_luas += 1
			elif k == Config.T_DOOR:
				pintu_luas += 1

	bake_semua()


func _rect(x, y, w, h, kind):
	for j in range(y, y + h):
		for i in range(x, x + w):
			if i < 0 or i >= Config.W or j < 0 or j >= Config.H:
				continue
			grid.set(j * Config.W + i, kind)


# ---------------------------------------------------------------------------
# Bake cahaya & keterlihatan — GRID PETAK (R4, docs/09 §6)
#
# light dan vis hidup per petak 8x8 satuan: 60x40 = 2.400 sel, ~600 sinar di
# area fasad. Selesai dalam hitungan milidetik, jadi boleh dipanggang ulang
# kapan saja — seluruh mesin cicilan lama (bake_langkah, tombol MULAI
# terkunci) sudah dibuang. Resolusi 8-satuan cukup: vis dipakai sebagai laju
# perhatian, bukan gambar.
# ---------------------------------------------------------------------------

func bake_semua():
	_bake_petak(int(Config.FACADE_Y0 / PETAK))


# Dipanggil tiap tumpukan puing stabil / fasad gugur. Sinar datang dari
# atas-kiri, jadi perubahan siluet hanya membayangi baris DI BAWAHNYA.
func rebake_dari(y_awal):
	_bake_petak(int(clamp(y_awal, Config.FACADE_Y0, Config.FACADE_Y1 - 1))
			/ PETAK)


func _bake_petak(ty0):
	var tx0 = Config.FACADE_X0 / PETAK
	var tx1 = int(ceil(float(Config.FACADE_X1) / PETAK))
	var ty1 = int(ceil(float(Config.FACADE_Y1) / PETAK))
	for ty in range(ty0, ty1):
		var cy = ty * PETAK + PETAK / 2
		var h = clamp(float(cy - Config.FACADE_Y0) \
				/ float(Config.FACADE_Y1 - Config.FACADE_Y0), 0.0, 1.0)
		for tx in range(tx0, tx1):
			var cx = tx * PETAK + PETAK / 2
			var l = 1.0 if _ray_clear(cx, cy) else 0.16
			light.set(ty * _pw + tx, l)

			# vis petak: dasar + cahaya + ketinggian, lalu isi petaknya —
			# jendela/pintu menonjol, ledge meneduhkan
			var jendela = 0
			var pintu = 0
			var ledge = 0
			for dy in range(PETAK):
				var bar = (ty * PETAK + dy) * Config.W + tx * PETAK
				for dx in range(PETAK):
					var k = grid[bar + dx]
					if k == Config.T_WINDOW:
						jendela += 1
					elif k == Config.T_DOOR:
						pintu += 1
					elif k == Config.T_LEDGE:
						ledge += 1
			var v = 0.20 + 0.48 * l + 0.28 * h
			if jendela >= 8:
				v += 0.30
			if pintu >= 8 or cy > Config.FACADE_Y1 - 26:
				v += 0.30
			if ledge >= 8:
				v -= 0.28
			vis.set(ty * _pw + tx, clamp(v, 0.0, 1.0))


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


func at(x, y):
	if x < 0 or x >= Config.W or y < 0 or y >= Config.H:
		return Config.T_NEIGHBOR
	return grid[y * Config.W + x]


# light dan vis dibaca lewat petak — pemanggil tetap memakai koordinat satuan
func light_at(x, y):
	if x < 0 or x >= Config.W or y < 0 or y >= Config.H:
		return 0.0
	return light[(y / PETAK) * _pw + (x / PETAK)]


func vis_at(x, y):
	if x < 0 or x >= Config.W or y < 0 or y >= Config.H:
		return 0.0
	return vis[(y / PETAK) * _pw + (x / PETAK)]


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
				var z = _zona(x, y)
				zona_bobot[z] += vis_at(x, y)
				zona_tutup[z] += 1
			elif k == Config.T_PUING:
				tutup.set(i, 1)


# Kebalikan rambati() — dipanggil saat sulur DIPANGKAS (regu, pemanjat, atau
# X pemain). Inilah yang membuat hukuman regu TERASA: bar HIJAU dan zona
# benar-benar mundur, bukan cuma garis di layar yang memendek (playtest 11
# Agustus: "punishment tidak terasa" — karena dulu tutup permanen).
# Sel bisa dibangun lagi dengan merambat ulang.
func hapus_rambatan(px, py):
	for dy in range(-1, 2):
		var y = py + dy
		if y < 0 or y >= Config.H:
			continue
		for dx in range(-1, 2):
			var x = px + dx
			if x < 0 or x >= Config.W:
				continue
			var i = y * Config.W + x
			if tutup[i] == 0:
				continue
			tutup.set(i, 0)
			var k = grid[i]
			if k == Config.T_WALL or k == Config.T_WINDOW \
					or k == Config.T_DOOR or k == Config.T_LEDGE:
				tutup_luas = max(0, tutup_luas - 1)
				zona_tutup[_zona(x, y)] = max(0, zona_tutup[_zona(x, y)] - 1)
				if k == Config.T_WINDOW:
					tutup_jendela = max(0, tutup_jendela - 1)
				elif k == Config.T_DOOR:
					tutup_pintu = max(0, tutup_pintu - 1)


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


func zona_tutupan(i):
	if zona_luas[i] == 0:
		return 1.0   # kuadran tanpa fasad dianggap selesai
	return float(zona_tutup[i]) / float(zona_luas[i])


# Akar menyedot kolam akuifer di dekat titik ini (G4): permukaan airnya
# turun, dan baris teratas yang terkuras berubah jadi tanah lembap — sisa
# basah, air kecil. Kolam yang habis diumumkan lewat pesan_kering.
func sedot_di(p, jumlah):
	for k in kolam:
		if p.x < k.x0 - 6 or p.x > k.x1 + 6 \
				or p.y < k.y0 - 6 or p.y > k.y1 + 6:
			continue
		var dalam = k.y1 - k.y0 + 1
		if k.terkuras >= dalam:
			return
		k.level += jumlah
		while k.terkuras < int(k.level) and k.terkuras < dalam:
			var y = k.y0 + k.terkuras
			for x in range(k.x0, k.x1 + 1):
				if grid[y * Config.W + x] == Config.T_AKUIFER:
					grid.set(y * Config.W + x, Config.T_SOIL_WET)
					_tandai_petak(x, y)
			k.terkuras += 1
			if k.terkuras >= dalam:
				pesan_kering = "Akuifer %s TERKURAS HABIS" % k.nama
			elif k.terkuras == dalam / 2:
				pesan_kering = "Akuifer %s tinggal separuh — permukaannya turun" \
						% k.nama
		return


# Apakah ada bekas rambatan di sekitar titik ini — syarat tunas ulang (G2).
# --- interior gedung (P2, docs/13 §4) --------------------------------------

# Tata letak hardcoded seperti build() — generator menyusul (setara G10
# lama). Lantai menempel di dasar tiap baris jendela (jy+16), jadi masuk
# lewat jendela selalu mendarat pas di lantai. Ventilasi digambar TERAKHIR:
# ia menembus dinding kamar — itulah gunanya ventilasi.
func _bangun_interior():
	dalam = PackedByteArray(); dalam.resize(Config.W * Config.H)

	# seluruh tapak = ruang; cangkang 4 tepi = dinding
	_rect_dalam(Config.FACADE_X0, Config.FACADE_Y0, 288, 168, Config.T_RUANG)
	_rect_dalam(96, 24, 288, 4, Config.T_DINDING_DALAM)
	_rect_dalam(96, 24, 4, 168, Config.T_DINDING_DALAM)
	_rect_dalam(380, 24, 4, 168, Config.T_DINDING_DALAM)
	_rect_dalam(96, 188, 288, 4, Config.T_LANTAI)   # dasar gedung

	# slab lantai per baris jendela: y = jy+16 (jy = 40..170 langkah 26)
	for jy in range(40, 180, 26):
		_rect_dalam(100, jy + 16, 280, 3, Config.T_LANTAI)

	# ENAM TINGKAT, ENAM KARAKTER (P3.9 — playtest: "terlalu tidak varian,
	# kurang tantangan"). Dinding menggantung dari langit-langit dan
	# berhenti 12 satuan di atas lantai = celah pintu.
	var atap_tingkat   = [28, 59, 85, 111, 137, 163]   # udara teratas tiap tingkat
	var lantai_tingkat = [56, 82, 108, 134, 160, 188]  # puncak slab di bawahnya
	# tingkat 0 LOTENG MESIN, 1 KANTOR, 2 LANTAI BOLONG (tanpa sekat),
	# 3 KANTOR+KERAN, 4 GUDANG PETI (tanpa sekat), 5 LOBI (terbuka, berkolom)
	var sekat = [[180, 264], [222], [], [200, 292], [], []]
	for i in range(atap_tingkat.size()):
		var y0 = atap_tingkat[i]
		var y_pintu = lantai_tingkat[i] - 12
		for x in sekat[i]:
			_rect_dalam(x, y0, 3, y_pintu - y0, Config.T_DINDING_DALAM)

	# loteng mesin (tingkat 0): dua bongkah mesin untuk dilompati
	_rect_dalam(140, 48, 10, 8, Config.T_DINDING_DALAM)
	_rect_dalam(238, 46, 12, 10, Config.T_DINDING_DALAM)

	# kantor (tingkat 1 & 3): kubikel pendek = platform loncatan
	_rect_dalam(130, 76, 8, 6, Config.T_LANTAI)
	_rect_dalam(190, 74, 8, 8, Config.T_LANTAI)
	_rect_dalam(340, 76, 8, 6, Config.T_LANTAI)
	_rect_dalam(160, 128, 8, 6, Config.T_LANTAI)
	_rect_dalam(255, 126, 8, 8, Config.T_LANTAI)

	# gudang (tingkat 4): peti bertumpuk — tangga loncat ke ventilasi
	_rect_dalam(148, 154, 10, 6, Config.T_LANTAI)
	_rect_dalam(166, 148, 10, 12, Config.T_LANTAI)
	_rect_dalam(184, 142, 12, 18, Config.T_LANTAI)
	_rect_dalam(298, 152, 14, 8, Config.T_LANTAI)
	_rect_dalam(320, 144, 10, 16, Config.T_LANTAI)

	# lobi (tingkat 5): dua kolom penuh — megah, dan pijakan rambat
	_rect_dalam(214, 163, 4, 25, Config.T_DINDING_DALAM)
	_rect_dalam(262, 163, 4, 25, Config.T_DINDING_DALAM)

	# LANTAI BOLONG: lubang-lubang slab membuka rute vertikal — dan satu
	# celah LEBAR (24 satuan) yang hanya terseberangi dengan LESAT: gerbang
	# kemampuan pertama ala metroidvania
	_rect_dalam(150, 108, 10, 3, Config.T_RUANG)
	_rect_dalam(196, 108, 24, 3, Config.T_RUANG)   # celah lebar — butuh LESAT
	_rect_dalam(250, 108, 8, 3, Config.T_RUANG)
	_rect_dalam(340, 82, 8, 3, Config.T_RUANG)     # jatuhan dari kantor atas
	_rect_dalam(170, 134, 8, 3, Config.T_RUANG)
	_rect_dalam(240, 160, 8, 3, Config.T_RUANG)

	# poros lift: x 306..318, menembus semua slab; dindingnya sendiri
	_rect_dalam(306, 28, 12, 160, Config.T_POROS)
	_rect_dalam(303, 28, 3, 160, Config.T_DINDING_DALAM)
	_rect_dalam(318, 28, 3, 160, Config.T_DINDING_DALAM)
	# bukaan poros per lantai (di sisi kiri, setinggi pintu)
	for jy in range(40, 180, 26):
		_rect_dalam(303, jy + 6, 3, 10, Config.T_POROS)

	# GERBANG P2: teralis menyumbat poros antara lantai 3 dan 4 —
	# janji Metroid yang baru terbuka lewat upgrade (P7)
	_rect_dalam(306, 84, 12, 8, Config.T_TERALIS)

	# ventilasi: duct 3 satuan menempel langit-langit, menembus SEMUA
	# dinding kamar (bukan cangkang) — jalan tikus antar kamar. BERLUBANG
	# berselang-seling (P3.9): bukan jalan tol gratis, lubangnya memaksa
	# turun ke kamar lalu naik lagi.
	var selang = 0
	for jy in range(40, 180, 26):
		_rect_dalam(102, jy + 1, 276, 3, Config.T_VENT)
		if selang % 2 == 0:
			_rect_dalam(198, jy + 1, 8, 3, Config.T_RUANG)
		else:
			_rect_dalam(322, jy + 1, 8, 3, Config.T_RUANG)
		selang += 1

	# keran bocor (P3): stasiun AIR interior — dua titik, sengaja di
	# tingkat 2 barat dan tingkat 4 timur supaya eksplorasi ditarik
	# menyebar. Digambar InteriorView sebagai tetesan biru.
	_rect_dalam(130, 128, 4, 6, Config.T_KERAN)
	_rect_dalam(344, 76, 4, 6, Config.T_KERAN)


func _rect_dalam(x, y, w, h, kind):
	for yy in range(y, min(y + h, Config.H)):
		for xx in range(x, min(x + w, Config.W)):
			dalam[yy * Config.W + xx] = kind


# Padat untuk avatar (P2): tergantung ia di dalam gedung atau di luar.
# Di dalam: cangkang di luar tapak selalu padat; lantai/dinding/teralis
# padat; ruang/vent/poros bisa dilalui.
func padat_avatar(px, py, di_dalam):
	if not di_dalam:
		return padat(px, py)
	if px < Config.FACADE_X0 or px >= Config.FACADE_X1 \
			or py < Config.FACADE_Y0 or py >= Config.FACADE_Y1:
		return true
	match dalam[py * Config.W + px]:
		Config.T_LANTAI, Config.T_DINDING_DALAM, Config.T_TERALIS:
			return true
	return false


# Avatar berdiri di sel jendela/pintu fasad? (gerbang masuk-keluar, tombol E)
func di_gerbang_interior(px, py):
	var k = at(px, py)
	return k == Config.T_WINDOW or k == Config.T_DOOR


# Dekat sumber AIR (P3)? Di luar: akuifer (dicapai lewat jaringan akar);
# di dalam: keran bocor. Radius 3 supaya "berdiri di sebelahnya" cukup.
func dekat_air(px, py, di_dalam):
	for dy in range(-3, 4):
		var y = py + dy
		if y < 0 or y >= Config.H:
			continue
		for dx in range(-3, 4):
			var x = px + dx
			if x < 0 or x >= Config.W:
				continue
			if di_dalam:
				if dalam[y * Config.W + x] == Config.T_KERAN:
					return true
			elif grid[y * Config.W + x] == Config.T_AKUIFER:
				return true
	return false


# Avatar menyingkap kabut peta di sekitarnya (radius petak) — layar M
# hanya menggambar petak yang pernah didekati (P3.75).
func tandai_jelajah(px, py):
	var tx = px / PETAK
	var ty = py / PETAK
	var ph = Config.H / PETAK
	for dy in range(-2, 3):
		var y = ty + dy
		if y < 0 or y >= ph:
			continue
		for dx in range(-2, 3):
			var x = tx + dx
			if x < 0 or x >= _pw:
				continue
			dijelajah[y * _pw + x] = 1


# --- jaringan avatar (P1, docs/13) ----------------------------------------

# Ditandai Strand.grow untuk TIAP titik untai (sulur & akar), 3x3.
func tandai_jaringan(px, py):
	for dy in range(-1, 2):
		var y = py + dy
		if y < 0 or y >= Config.H:
			continue
		for dx in range(-1, 2):
			var x = px + dx
			if x < 0 or x >= Config.W:
				continue
			jaringan[y * Config.W + x] = 1


# Ada jaringan dalam radius 1 dari titik satuan (px, py)?
func jaringan_di(px, py):
	for dy in range(-1, 2):
		var y = py + dy
		if y < 0 or y >= Config.H:
			continue
		for dx in range(-1, 2):
			var x = px + dx
			if x < 0 or x >= Config.W:
				continue
			if jaringan[y * Config.W + x] == 1:
				return true
	return false


# Sel PADAT untuk fisika platformer avatar (moda LEPAS). Dinding fasad
# SENGAJA bukan padat: dalam tampak samping avatar bergerak DI DEPAN bidang
# fasad; memanjatnya hanya lewat jaringan. Ledge padat = pijakan gratis.
func padat(px, py):
	if px < 0 or px >= Config.W or py < 0 or py >= Config.H:
		return true
	match grid[py * Config.W + px]:
		Config.T_SOIL_DRY, Config.T_SOIL_WET, Config.T_HUMUS, \
		Config.T_BATU, Config.T_CONCRETE, Config.T_NEIGHBOR, \
		Config.T_PUING, Config.T_LEDGE, Config.T_AKUIFER:
			return true
	return false


func ada_rambatan(p):
	var px = int(round(p.x))
	var py = int(round(p.y))
	for dy in range(-2, 3):
		var y = py + dy
		if y < 0 or y >= Config.H:
			continue
		for dx in range(-2, 3):
			var x = px + dx
			if x < 0 or x >= Config.W:
				continue
			if tutup[y * Config.W + x] == 1:
				return true
	return false


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
# di belakangnya tetap dinding. Puing di atas tanah digambar per sel oleh
# PuingTanahView (ubinnya dipetakan ke langit di TerrainView.ATLAS).
func tile_terrain(tx, ty):
	var hitung = {}
	for dy in range(PETAK):
		var y = ty * PETAK + dy
		for dx in range(PETAK):
			var k = grid[y * Config.W + tx * PETAK + dx]
			if k == Config.T_WINDOW or k == Config.T_DOOR \
					or k == Config.T_LEDGE:
				k = Config.T_WALL
			hitung[k] = hitung.get(k, 0) + 1
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
				if settled[y * Config.W + x] == 0:
					settled_n += 1
				settled.set(y * Config.W + x, 1)
				grid.set(y * Config.W + x, Config.T_PUING)
				_tandai_petak(x, y)
				if y < puing_atas:
					puing_atas = y
