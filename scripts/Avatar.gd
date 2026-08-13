extends RefCounted

# Avatar — ujung tumbuh yang dikendalikan pemain (P1, docs/13 §3).
#
# Dua moda:
#   MERAMBAT — menempel di jaringan (WorldMap.jaringan): gerak bebas segala
#              arah selama sel tujuan masih dekat jaringan; energi PULIH.
#   LEPAS    — platformer: gravitasi grid sendiri (tanpa physics engine,
#              aturan lama), energi terkikis; menyentuh jaringan = menempel
#              lagi (dengan jeda singkat setelah melepaskan diri).
#
# Energi habis saat LEPAS = LAYU: bangun di simpul jaringan terakhir.
# Semua input datang dari main.gd lewat parameter update() — file ini tidak
# pernah membaca Input.

const MERAMBAT = 0
const LEPAS    = 1

var pos = Vector2()        # SATUAN simulasi; pos = titik KAKI
var vel = Vector2()
var moda = LEPAS
var energi = 0.0
var simpul = Vector2()     # titik bangun setelah layu
var simpul_dalam = false   # simpul berada di interior?
var di_tanah = false
var di_dalam = false       # P2: sedang di interior gedung
var layu_baru = false      # sekali-baca oleh main untuk pesan HUD
var mengisi = false        # P3: sedang di sumber (untuk denyut view)
var sumber = ""            # "air" / "cahaya" saat mengisi — untuk ikon HUD
var jejak = []             # P3: jalur sulur yang DITUMBUHKAN avatar —
                           # [{pos, dalam}] digambar JejakView
var hadap = 1.0            # arah hadap terakhir (dipakai view & belok)
var _tempel_jeda = 0.0     # cooldown menempel setelah lepas

# RK Langkah 2 — status deteksi sensor, DIISI main tiap frame sebelum
# update() (Avatar tidak tahu sensor; ia hanya merasakan akibatnya)
var terdeteksi = false     # kuning: terlihat sensor dalam keadaan terbuka
var curiga = false         # tersamar di jaringan dalam jangkauan sensor
var regen_mati = false     # sensor waspada: jaringan menolak memulihkan

# Tahap CDD §9: 1 TUNAS BARU, 2 MUDA, 3 DEWASA, 4 TUA/KAYU. Murni
# tonggak WUJUD dari tumbuh_total — TIDAK membuka kemampuan (GDD §15 =
# jatah Phase 7). Ukuran badan tetap kontinu lewat ukuran().
var tahap = 1
var tahap_baru = 0         # event sekali-baca untuk kartu metamorfosis main
var energi_max = 100.0
var tumbuh_total = 0.0     # satuan jaringan yang pernah ditumbuhkan
var jangkar_n = 0
var pernah_air = false     # pernah minum dari keran/akuifer (diisi main)
var pernah_cahaya = false

# pengampunan platformer (GDD §7)
var _coyote = 0.0          # sisa waktu "masih boleh lompat" setelah lepas pijakan
var _buffer = 0.0          # sisa waktu lompat-lebih-awal yang masih dihormati
var _melompat = false      # sedang di fase naik lompatan (untuk potong dini)


func mulai(p):
	pos = p
	vel = Vector2()
	moda = LEPAS
	energi = Config.AVATAR_ENERGI_MAX
	simpul = p
	simpul_dalam = false
	di_tanah = false
	di_dalam = false
	mengisi = false
	jejak = []
	_tempel_jeda = 0.0
	tahap = 1
	tahap_baru = 0
	energi_max = Config.AVATAR_ENERGI_MAX
	tumbuh_total = 0.0
	jangkar_n = 0
	pernah_air = false
	pernah_cahaya = false


func tahap_nama():
	return ["", "TUNAS BARU", "MUDA", "DEWASA", "TUA/KAYU"][tahap]


# Kemajuan tumbuh 0..1 — memilih frame strip pertumbuhan 16-frame DAN
# skala halus. Sprite-nya sendiri sudah membesar per frame, jadi rentang
# skala tambahan dibuat sempit (anti patah-patah, anti dobel-besar).
func tumbuh_frak():
	return clamp(tumbuh_total / Config.UKURAN_PENUH, 0.0, 1.0)


func ukuran():
	return 0.85 + 0.3 * tumbuh_frak()


# P3: isi energi dari sumber — dipanggil main yang tahu fase & cahaya
func isi(jumlah):
	energi = min(energi_max, energi + jumlah)


# i = Dictionary input dari main: arah (Vector2), lompat (edge),
# lompat_tahan (bool), lari (bool — GDD §7 RUN), masuk (edge)
func update(dt, i, world):
	if dt <= 0.0:
		return
	_tempel_jeda = max(0.0, _tempel_jeda - dt)
	if i.arah.x != 0.0:
		hadap = signf(i.arah.x)

	# E di jendela/pintu fasad: keluar-masuk gedung (P2). Transisi memutus
	# moda merambat — di sisi seberang Anda jatuh dulu ke lantai/jaringan.
	if i.masuk and world.di_gerbang_interior(int(round(pos.x)),
			int(round(pos.y - 2.0))):
		di_dalam = not di_dalam
		moda = LEPAS
		vel = Vector2()
		_tempel_jeda = Config.AVATAR_TEMPEL_JEDA
		return

	if moda == MERAMBAT:
		_rambat(dt, i, world)
	else:
		_lepas(dt, i, world)


# F: menanam simpul jaringan di posisi avatar (P2) — checkpoint + titik
# pulih di mana pun, termasuk interior. Mahal supaya jadi keputusan.
func jangkar(world):
	if energi < Config.JANGKAR_BIAYA + 5.0:
		return false
	energi -= Config.JANGKAR_BIAYA
	var px = int(round(pos.x))
	var py = int(round(pos.y - 2.0))
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			world.tandai_jaringan(px + dx, py + dy)
	simpul = pos
	simpul_dalam = di_dalam
	jangkar_n += 1
	return true


func _rambat(dt, i, world):
	var arah = i.arah
	# konsekuensi deteksi (RK 2b): selama sensor waspada, jaringan
	# MENOLAK memulihkan — ketahuan lalu bersembunyi tidak langsung
	# mengembalikan hak pulih
	if not regen_mati:
		energi = min(energi_max, energi + Config.AVATAR_REGEN * dt)
	simpul = pos
	simpul_dalam = di_dalam

	# melepaskan diri: lompatan kecil ke arah input
	if i.lompat:
		moda = LEPAS
		_melompat = true
		_tempel_jeda = Config.AVATAR_TEMPEL_JEDA
		vel = Vector2(arah.x * Config.AVATAR_JALAN,
				-Config.AVATAR_LOMPAT * 0.75)
		return

	if arah == Vector2.ZERO:
		return
	# laju merambat tunggal — sprint era pivot dihapus (bukan kanon);
	# merambat memang sudah moda tercepat (GDD §6.1)
	var langkah = arah.normalized() * Config.AVATAR_RAMBAT * dt
	# coba gerak penuh; kalau keluar jaringan, coba per sumbu (menyusur).
	# Kandidat yang tidak benar-benar bergerak DILEWATI — kandidat sumbu
	# dengan komponen nol adalah "gerakan nol yang selalu sah" dan diam-diam
	# menyumbat cabang tumbuh di bawah.
	for calon in [pos + langkah, pos + Vector2(langkah.x, 0.0),
			pos + Vector2(0.0, langkah.y)]:
		if calon.distance_squared_to(pos) < 0.0001:
			continue
		if world.jaringan_di(int(round(calon.x)), int(round(calon.y))):
			pos = calon
			return

	# MENJALAR = TUMBUH (P3, docs/13 §3.1): di tepi jaringan, terus menekan
	# arah = memperpanjang tanaman. Jalurnya jadi sulur baru (jejak +
	# jaringan), dibayar energi per satuan — dan hanya menembus sel yang
	# TIDAK padat: menembus beton tetap urusan bor (P7).
	var tumbuh_ke = pos + langkah
	var cx = int(round(tumbuh_ke.x))
	var cy = int(round(tumbuh_ke.y))
	if world.padat_avatar(cx, cy, di_dalam):
		return
	var biaya = langkah.length() * Config.RAMBAT_TUMBUH_BIAYA
	if energi <= biaya + 4.0:
		return   # sisakan napas — jangan layu karena tumbuh
	energi -= biaya
	pos = tumbuh_ke
	world.tandai_jaringan(cx, cy)
	# tonggak wujud CDD §9 — murni dari total pertumbuhan, tanpa membuka
	# kemampuan apa pun
	tumbuh_total += langkah.length()
	if tahap == 1 and tumbuh_total >= Config.TAHAP_MUDA:
		tahap = 2
		tahap_baru = 2
	elif tahap == 2 and tumbuh_total >= Config.TAHAP_DEWASA:
		tahap = 3
		tahap_baru = 3
	elif tahap == 3 and tumbuh_total >= Config.TAHAP_TUA:
		tahap = 4
		tahap_baru = 4
	if jejak.is_empty() \
			or jejak[jejak.size() - 1].pos.distance_to(pos) >= 1.5:
		jejak.append({"pos": pos, "dalam": di_dalam})


func _lepas(dt, i, world):
	# biaya bergradasi GDD §9: diam kecil < jalan < lari sedang; lompat
	# & tumbuh membayar tarifnya sendiri
	var faktor = 1.0
	if di_tanah and i.arah.x == 0.0 and abs(vel.x) < 1.0:
		faktor = Config.KURAS_DIAM
	elif i.lari:
		faktor = Config.KURAS_LARI
	energi -= Config.AVATAR_KURAS * faktor * dt

	# menempel kembali begitu menyentuh jaringan (setelah jeda lepas)
	if _tempel_jeda <= 0.0 \
			and world.jaringan_di(int(round(pos.x)), int(round(pos.y - 2.0))):
		moda = MERAMBAT
		vel = Vector2()
		_melompat = false
		simpul = pos
		return

	# coyote & buffer: pengampunan waktu khas platformer yang enak
	_coyote = Config.COYOTE_DETIK if di_tanah else max(0.0, _coyote - dt)
	_buffer = Config.BUFFER_LOMPAT if i.lompat else max(0.0, _buffer - dt)

	# horizontal: akselerasi menuju target — RUN dasar GDD §7 saat Shift
	# ditahan (tetap di bawah laju merambat, §6.1)
	var laju = Config.AVATAR_LARI if i.lari else Config.AVATAR_JALAN
	var target = i.arah.x * laju
	vel.x = move_toward(vel.x, target, Config.AVATAR_ACCEL * dt)
	# vertikal: gravitasi + lompat (tanah ATAU sisa coyote)
	vel.y += Config.AVATAR_GRAV * dt
	if _buffer > 0.0 and (di_tanah or _coyote > 0.0) \
			and energi > Config.AVATAR_LOMPAT_BIAYA:
		vel.y = -Config.AVATAR_LOMPAT
		energi -= Config.AVATAR_LOMPAT_BIAYA
		_buffer = 0.0
		_coyote = 0.0
		_melompat = true
	# lompatan variabel: lepas tombol saat masih naik = lompatan pendek
	if _melompat and not i.lompat_tahan and vel.y < 0.0:
		vel.y *= Config.LOMPAT_POTONG
		_melompat = false
	if vel.y >= 0.0:
		_melompat = false

	_gerak_tabrak(dt, world)
	_cek_layu(world)


# layu: energi habis di luar jaringan — bangun di simpul terakhir
# (termasuk kembali ke lapis tempat simpul itu ditanam)
func _cek_layu(world):
	if energi <= 0.0:
		pos = simpul
		di_dalam = simpul_dalam
		vel = Vector2()
		energi = Config.AVATAR_LAYU_ENERGI
		moda = MERAMBAT if world.jaringan_di(int(round(pos.x)),
				int(round(pos.y - 2.0))) else LEPAS
		layu_baru = true


# Tabrakan kotak vs grid, sumbu terpisah — pola yang sama dengan puing/sulur:
# hitung sendiri, tanpa physics engine.
func _gerak_tabrak(dt, world):
	var hw = Config.AVATAR_SETENGAH_LEBAR
	var t = Config.AVATAR_TINGGI

	var bx = pos.x + vel.x * dt
	if not _tabrak(world, bx, pos.y, hw, t):
		pos.x = bx
	else:
		vel.x = 0.0

	var by = pos.y + vel.y * dt
	if not _tabrak(world, pos.x, by, hw, t):
		pos.y = by
	else:
		if vel.y > 0.0:
			# rapatkan kaki FLUSH ke atas sel padat (x.99): tanpa ini avatar
			# melayang 1 satuan lalu tenggelam pelan tiap frame, dan
			# di_tanah berkedip sehingga lompatan sering tertelan
			pos.y = floor(by)
			while _tabrak(world, pos.x, pos.y, hw, t):
				pos.y -= 1.0
			pos.y += 0.99
		vel.y = 0.0

	# di_tanah dari PROBE sel tepat di bawah kaki — stabil antar frame,
	# bukan efek samping tabrakan frame ini saja
	di_tanah = false
	var ky = int(floor(pos.y + 0.1))
	for cx in range(int(floor(pos.x - hw)), int(floor(pos.x + hw)) + 1):
		if world.padat_avatar(cx, ky, di_dalam):
			di_tanah = true
			break


# Ada sel padat di dalam kotak badan (kaki di (x, y))? Sadar lapis (P2):
# di interior yang padat adalah lantai/dinding, bukan tanah luar.
func _tabrak(world, x, y, hw, t):
	for cy in range(int(floor(y - t)), int(floor(y)) + 1):
		for cx in range(int(floor(x - hw)), int(floor(x + hw)) + 1):
			if world.padat_avatar(cx, cy, di_dalam):
				return true
	return false
