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
var jejak_daun = []        # gumpalan daun DITANAM ujung saat merambat —
                           # [{pos, sudut, varian, dalam}], DaunView
var _daun_jarak = 0.0      # akumulator jarak antar tanaman gumpalan
var _denyut = 0.0          # jam denyut tumbuh (julur-cengkeram)
var hadap = 1.0            # arah hadap terakhir (dipakai view & belok)
var bisa_tempel = false    # LEPAS menyentuh jaringan — petunjuk HUD [W]
var tumbuh_tolak = 0.0     # RK-2 [A]: sisa kedip "beton menolak tumbuh"
var jangkar_baru = 0.0     # RK-2 [B]: sisa denyut kelahiran node
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
	bisa_tempel = false
	jejak = []
	jejak_daun = []
	_daun_jarak = 0.0
	_denyut = 0.0
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
	tumbuh_tolak = max(0.0, tumbuh_tolak - dt)
	jangkar_baru = max(0.0, jangkar_baru - dt)
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
		# ujung MENANAM dedaunan di jalur yang dilaluinya (permintaan
		# pemilik: merambat menyatu dengan ekosistem — tubuh tanaman =
		# jejak yang tertinggal, ujung hanyalah tunas kecil yang hidup)
		var pos_r = pos
		_rambat(dt, i, world)
		var d = pos_r.distance_to(pos)
		if d > 0.0:
			_daun_jarak += d
			if _daun_jarak >= Config.RAMBAT_DAUN_JARAK:
				_daun_jarak -= Config.RAMBAT_DAUN_JARAK
				jejak_daun.append({"pos": pos,
						"sudut": (pos - pos_r).angle(),
						"varian": jejak_daun.size() % 3,
						"dalam": di_dalam, "layu": 0.0})
	else:
		_lepas(dt, i, world)

	# DAUR HIDUP JEJAK (GDD §6.3: jaringan bisa mati; usul pemilik):
	# melewati batas ring, gumpalan TERTUA tidak dihapus mendadak —
	# ia MENGERING (hijau -> cokelat -> pudar) lalu rontok. Hanya
	# beberapa tertua yang layu bersamaan; sisanya menunggu giliran.
	if jejak_daun.size() > Config.RAMBAT_DAUN_MAX:
		var lebih = jejak_daun.size() - Config.RAMBAT_DAUN_MAX
		for j in range(min(lebih, 4)):
			jejak_daun[j].layu += dt
		while jejak_daun.size() > 0 \
				and jejak_daun[0].layu >= Config.RAMBAT_DAUN_LAYU:
			jejak_daun.pop_front()


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
	# RK-2 [B] (GDD §6.2): node yang TERLIHAT & TERASA — bulb tertanam
	# di dunia, denyut kelahiran, dan aura regen 2x di sekitarnya
	world.node_tanam.append(Vector2(px, py))
	jangkar_baru = 0.6
	return true


func _rambat(dt, i, world):
	var arah = i.arah
	bisa_tempel = false
	# konsekuensi deteksi (RK 2b): selama sensor waspada, jaringan
	# MENOLAK memulihkan — ketahuan lalu bersembunyi tidak langsung
	# mengembalikan hak pulih
	if not regen_mati:
		# RK-2 [B]: aura node — pulih 2x di dekat node (GDD §6.2
		# "regenerasi"); jangkar yang mahal kini terasa gunanya
		var laju_regen = Config.AVATAR_REGEN
		if world.dekat_node(pos):
			laju_regen *= 2.0
		energi = min(energi_max, energi + laju_regen * dt)
	simpul = pos
	simpul_dalam = di_dalam

	# melepaskan diri: lompatan kecil ke arah input
	if i.lompat:
		moda = LEPAS
		_melompat = true
		_tempel_jeda = Config.AVATAR_TEMPEL_JEDA
		vel = Vector2(arah.x * Config.AVATAR_JALAN,
				-Config.AVATAR_LOMPAT * 0.75)
		_keluarkan_badan(world)
		return

	if arah == Vector2.ZERO:
		return
	# DENYUT TUMBUH BERBEBAN (playtest pemilik: masih terasa cepat —
	# beban ditambah): AVATAR_RAMBAT kini laju PUNCAK juluran; fase
	# cengkeram melambat dalam tanpa normalisasi, rata-rata efektif
	# ~72% puncak. Tafsir GDD §6.1: "34" = laju julur maksimum.
	_denyut += dt
	var fase_d = fmod(_denyut, Config.RAMBAT_DENYUT) / Config.RAMBAT_DENYUT
	var dasar = Config.RAMBAT_DENYUT_DASAR
	var faktor = dasar + (1.0 - dasar) \
			* pow(max(0.0, sin(fase_d * PI)), 0.7)
	var langkah = arah.normalized() * Config.AVATAR_RAMBAT * faktor * dt
	# coba gerak penuh; kalau keluar jaringan, coba per sumbu (menyusur).
	# Kandidat yang tidak benar-benar bergerak DILEWATI — kandidat sumbu
	# dengan komponen nol adalah "gerakan nol yang selalu sah" dan diam-diam
	# menyumbat cabang tumbuh di bawah.
	# Sel tujuan SAH bila jaringan tersentuh di KAKI atau BADAN (selaras
	# aturan menempel y-2) dan selnya BUKAN beton — dua temuan playtest
	# pemilik: (a) band +-1 membuat ujung merayap MASUK beton plafon lalu
	# buntu; (b) kaki di lantai membulat ke sel padat di luar band garis
	# sehingga gerak horizontal mati begitu menempel.
	for calon in [pos + langkah, pos + Vector2(langkah.x, 0.0),
			pos + Vector2(0.0, langkah.y)]:
		if calon.distance_squared_to(pos) < 0.0001:
			continue
		if _sel_rambat_sah(world, int(round(calon.x)),
				int(round(calon.y)), int(round(calon.y - 2.0))):
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
		# kaki membulat ke sel padat (mis. berdiri di lantai): coba tumbuh
		# di tinggi badan — memperpanjang garis di ketinggian garis itu
		cy = int(round(tumbuh_ke.y - 2.0))
		if world.padat_avatar(cx, cy, di_dalam):
			return
	# RK-2 [A] (GDD §12): BETON MENOLAK pertumbuhan — hanya permukaan
	# lembap/retak yang menerima. Umpan balik dunia + HUD lewat event.
	if not world.bisa_tumbuh(cx, cy):
		tumbuh_tolak = 0.5
		return
	var biaya = langkah.length() * Config.RAMBAT_TUMBUH_BIAYA \
			* world.faktor_tumbuh(cx, cy)
	if energi <= biaya + 4.0:
		return   # sisakan napas — jangan layu karena tumbuh
	energi -= biaya
	pos = tumbuh_ke
	world.tandai_jaringan(cx, cy, true)
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


# sel tujuan merambat sah? jaringan tersentuh di ketinggian kaki ATAU
# badan, dan sel yang dipakai bukan beton (ujung menempel di permukaan,
# tidak menembus — menembus beton = urusan bor, GDD P7)
func _sel_rambat_sah(world, cx, cy_kaki, cy_badan):
	if world.jaringan_di(cx, cy_kaki) \
			and not world.padat_avatar(cx, cy_kaki, di_dalam):
		return true
	return world.jaringan_di(cx, cy_badan) \
			and not world.padat_avatar(cx, cy_badan, di_dalam)


func _lepas(dt, i, world):
	# biaya bergradasi GDD §9: diam kecil < jalan < lari sedang; lompat
	# & tumbuh membayar tarifnya sendiri. TERDETEKSI (gerbang Langkah 3)
	# = stres biologis: kuras melonjak selama masih dalam pandangan.
	var faktor = 1.0
	if di_tanah and i.arah.x == 0.0 and abs(vel.x) < 1.0:
		faktor = Config.KURAS_DIAM
	elif i.lari:
		faktor = Config.KURAS_LARI
	if terdeteksi:
		faktor = max(faktor, Config.KURAS_TERDETEKSI)
	energi -= Config.AVATAR_KURAS * faktor * dt

	# menempel jadi DISENGAJA (putusan pemilik: auto-tempel membingungkan
	# — jalan biasa di lantai rumah tersedot ke moda rambat tanpa
	# diminta). Tata bahasa tangga klasik: menyentuh jaringan + tekan
	# ATAS/BAWAH = menempel. bisa_tempel diumumkan ke HUD sebagai
	# petunjuk tombol kontekstual.
	bisa_tempel = _tempel_jeda <= 0.0 \
			and world.jaringan_di(int(round(pos.x)), int(round(pos.y - 2.0)))
	if bisa_tempel and i.arah.y != 0.0:
		moda = MERAMBAT
		bisa_tempel = false
		vel = Vector2()
		_melompat = false
		simpul = pos
		# gumpalan ditanam TEPAT di titik melebur: akhir animasi attach
		# (makhluk luruh jadi dedaunan) diserahterimakan ke gumpalan
		# nyata — tubuh benar-benar "menjadi tanaman di sini"
		jejak_daun.append({"pos": pos, "sudut": 0.0,
				"varian": jejak_daun.size() % 3, "dalam": di_dalam,
				"layu": 0.0})
		return

	# coyote & buffer: pengampunan waktu khas platformer yang enak
	_coyote = Config.COYOTE_DETIK if di_tanah else max(0.0, _coyote - dt)
	_buffer = Config.BUFFER_LOMPAT if i.lompat else max(0.0, _buffer - dt)

	# horizontal: GAS pelan (badan berbobot butuh waktu mencapai laju),
	# REM lebih cengkeram saat berhenti/berbalik — tanpa pemisahan ini
	# gerak terasa menggelincir (playtest pemilik). RUN = Shift (GDD §7,
	# tetap di bawah rambat-puncak §6.1).
	var laju = Config.AVATAR_LARI if i.lari else Config.AVATAR_JALAN
	var target = i.arah.x * laju
	var dorong = Config.AVATAR_ACCEL
	if i.arah.x == 0.0 or (vel.x != 0.0 and signf(target) != signf(vel.x)):
		dorong = Config.AVATAR_REM
	vel.x = move_toward(vel.x, target, dorong * dt)
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


# Merambat boleh menembus beton (jaringan menempel di permukaan), tapi
# LEPAS tidak: saat melepaskan diri dari garis yang menempel plafon/
# dinding, badan bisa sedang tumpang-tindih beton — dorong kaki TURUN
# ke posisi legal dulu (turun = arah alami melepaskan diri). Terbatas:
# kalau tidak ketemu posisi legal, batal turun (biarkan tabrakan yang
# menahan) — jangan pernah teleport liar.
func _keluarkan_badan(world):
	var hw = Config.AVATAR_SETENGAH_LEBAR
	var t = Config.AVATAR_TINGGI
	if not _tabrak(world, pos.x, pos.y, hw, t):
		return
	for turun in range(1, int(t) + 4):
		if not _tabrak(world, pos.x, pos.y + turun, hw, t):
			pos.y += turun
			return


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
			# di_tanah berkedip sehingga lompatan sering tertelan.
			# TERBATAS 3 langkah: badan yang benar-benar terjepit di dalam
			# massa (mis. terlepas di bawah garis plafon) tidak boleh
			# memanjat tembus — apalagi beku di while tak berujung
			# (temuan playtest pemilik: nyangkut di pojok kiri-atas).
			var y_awal = pos.y
			pos.y = floor(by)
			var naik = 0
			while _tabrak(world, pos.x, pos.y, hw, t) and naik < 3:
				pos.y -= 1.0
				naik += 1
			if _tabrak(world, pos.x, pos.y, hw, t):
				pos.y = y_awal   # terjepit: tahan di posisi legal terakhir
			else:
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
