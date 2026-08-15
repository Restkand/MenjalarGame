extends RefCounted

# PEMANGKAS — musuh pertama (RK-2 [C]; GDD §14, Phase 5-6 MVP):
# teknisi perawatan gedung yang berpatroli di lantai ruang servis.
#
# State: IDLE (jeda di ujung patroli) -> PATROL -> KEJAR (melihat
# avatar moda LEPAS di ketinggian lantai, garis pandang bebas beton).
# TANPA combat: tertangkap = kuras energi besar + terpental + jeda.
#
# MEMOTONG (inti loop "sesuatu yang bisa hilang"): gumpalan jejak dan
# sel jaringan TUMBUHAN pemain yang dilewatinya dipangkas. Jaringan
# BENIH tidak pernah disentuh — tiga rute dasar selalu hidup.
# Avatar moda MERAMBAT tidak pernah dilihatnya: bagi manusia, jaringan
# hanyalah tanaman liar (alasan merambat, GDD §2.3).

const IDLE    = 0
const PATROL  = 1
const KEJAR   = 2
const SELIDIK = 3          # Phase 5 "enemy investigation": memeriksa
                           # titik terakhir avatar terlihat sebelum
                           # menyerah kembali berpatroli
const MASUK   = 4          # ESKALASI: pengganti berjalan masuk dari
                           # kanan MENCARI REKANNYA — fokus ke mayat,
                           # belum menoleh ke mana-mana

var pos = Vector2()
var arah = 1.0             # hadap: 1 kanan, -1 kiri
var state = PATROL
var hidup = true           # false = tersergap; tubuh jadi bangkai
var mati_t = 0.0           # detik sejak tersergap (penggerak anim view)
var selidik_pos = 0.0      # x avatar TERAKHIR terlihat (memori kejar)
var awas = false           # sudah tahu ada yang salah: pandang melebar
var kaget = 0.0            # membeku sesaat ketika PERTAMA melihat pemain
var tiba_mayat = false     # event sekali-baca: pengganti sampai di mayat
var _masuk_tujuan = 0.0    # x mayat yang dicari saat MASUK
var _selidik_t = 0.0
var _jeda = 0.0            # sisa detik IDLE / cooldown usai menangkap
var _batas_kiri = 84.0
var _batas_kanan = 200.0


func _init(kiri, kanan):
	_batas_kiri = kiri
	_batas_kanan = kanan
	pos = Vector2(kiri, 111.9)


func reset():
	pos = Vector2(_batas_kiri, 111.9)
	arah = 1.0
	state = PATROL
	hidup = true
	mati_t = 0.0
	awas = false
	kaget = 0.0
	tiba_mayat = false
	_jeda = 0.0


# ESKALASI: teknisi pengganti masuk dari tepi kanan ruangan, berjalan
# menuju x mayat rekannya. Ia datang SUDAH AWAS — kota tahu ada yang
# hilang. (Pemain tetap boleh menyergapnya saat ia lengah berjalan.)
func masuk(x_mayat):
	pos = Vector2(250.0, 111.9)
	arah = -1.0
	state = MASUK
	_masuk_tujuan = x_mayat
	hidup = true
	mati_t = 0.0
	awas = true
	kaget = 0.0


# SERGAP SENYAP (GDD §37 "menyerang titik lemah" + arah horor pemilik
# "membunuh dalam diam"): hanya dari MERAMBAT — tanaman menyerang dari
# jaringannya — dan hanya pada musuh yang BELUM melihat pemain. Musuh
# yang sedang memburu tidak bisa disergap: kesabaran dulu, baru taring.
func bisa_sergap(avatar):
	return hidup and state != KEJAR and avatar.moda == avatar.MERAMBAT \
			and avatar.pos.distance_to(pos + Vector2(0.0, -4.0)) \
			<= Config.SERGAP_JARAK


func sergap(avatar):
	if not bisa_sergap(avatar):
		return false
	hidup = false
	mati_t = 0.0
	# biomassa terserap jaringan (GDD §16) — membunuh memberi makan
	avatar.energi = min(avatar.energi_max,
			avatar.energi + Config.SERGAP_PANEN)
	return true


func update(dt, avatar, world):
	if not hidup:
		mati_t += dt
		return
	_jeda = max(0.0, _jeda - dt)

	# melihat avatar? hanya moda LEPAS, sejajar lantai, searah hadap,
	# dalam jarak pandang, tanpa beton menghalangi. Teknisi yang AWAS
	# memandang lebih jauh; yang sedang MASUK fokus mencari rekannya.
	var lihat = false
	var pandang = Config.PEMANGKAS_PANDANG \
			* (Config.AWAS_PANDANG if awas else 1.0)
	if avatar.moda == avatar.LEPAS and _jeda <= 0.0 and state != MASUK:
		var d = avatar.pos - pos
		if abs(d.y) < 8.0 and abs(d.x) < pandang \
				and signf(d.x) == signf(arah) and _los(world, avatar.pos):
			lihat = true

	match state:
		IDLE:
			if lihat:
				state = KEJAR
				selidik_pos = avatar.pos.x
				kaget = Config.PEMANGKAS_KAGET
			elif _jeda <= 0.0:
				arah = -arah
				state = PATROL
		PATROL:
			if lihat:
				state = KEJAR
				selidik_pos = avatar.pos.x
				kaget = Config.PEMANGKAS_KAGET
			else:
				pos.x += arah * Config.PEMANGKAS_JALAN * dt
				if pos.x <= _batas_kiri or pos.x >= _batas_kanan:
					pos.x = clamp(pos.x, _batas_kiri, _batas_kanan)
					state = IDLE
					_jeda = Config.PEMANGKAS_JEDA
		KEJAR:
			# KAGET (bahasa stealth klasik): sedetak membeku saat sadar —
			# jendela reaksi jujur untuk pemain sebelum kejaran dimulai
			if kaget > 0.0:
				kaget -= dt
				if lihat:
					selidik_pos = avatar.pos.x
				return
			# memori: selama terlihat, titik terakhir terus diperbarui;
			# begitu hilang, ia mengejar TITIK itu, bukan pemainnya
			if lihat:
				selidik_pos = avatar.pos.x
			var d2 = selidik_pos - pos.x
			arah = signf(d2) if abs(d2) > 0.5 else arah
			pos.x += arah * Config.PEMANGKAS_KEJAR * dt
			pos.x = clamp(pos.x, _batas_kiri, _batas_kanan)
			# menangkap: kuras besar + terpental (TANPA membunuh)
			if avatar.moda == avatar.LEPAS \
					and avatar.pos.distance_to(pos) < 4.0:
				avatar.energi -= Config.PEMANGKAS_KURAS
				avatar.vel = Vector2(arah * 30.0, -24.0)
				_jeda = Config.PEMANGKAS_JEDA
				state = IDLE
			elif not lihat and (abs(d2) < 2.0 \
					or pos.x <= _batas_kiri or pos.x >= _batas_kanan):
				# tiba di titik terakhir dan tidak ada siapa-siapa:
				# MENYELIDIK dulu (Phase 5), tidak langsung menyerah
				state = SELIDIK
				_selidik_t = Config.PEMANGKAS_SELIDIK
		SELIDIK:
			if lihat:
				state = KEJAR
				selidik_pos = avatar.pos.x
				kaget = Config.PEMANGKAS_KAGET
			else:
				_selidik_t -= dt
				# menoleh kiri-kanan mencari — sapuan deterministik
				arah = 1.0 if int(_selidik_t / 0.8) % 2 == 0 else -1.0
				if _selidik_t <= 0.0:
					state = PATROL
		MASUK:
			# berjalan lurus ke x mayat rekannya (di luar batas patroli
			# pun); sampai -> event tiba_mayat (main membunyikan alarm
			# ruangan) lalu MENYELIDIK di sisi mayat
			var d3 = _masuk_tujuan - pos.x
			arah = signf(d3) if abs(d3) > 0.5 else arah
			pos.x += arah * Config.PEMANGKAS_JALAN * 1.4 * dt
			if abs(d3) < 3.0:
				pos.x = clamp(pos.x, _batas_kiri, _batas_kanan)
				tiba_mayat = true
				state = SELIDIK
				_selidik_t = Config.PEMANGKAS_SELIDIK * 1.5

	# MEMOTONG pertumbuhan pemain yang dilewati (jaringan benih aman)
	_pangkas(avatar, world)


func _pangkas(avatar, world):
	# PAGAR (playtest pemilik: jalur putus di bawah kaki = pemain
	# terdampar tanpa penjelasan): gunting TIDAK menyentuh apa pun
	# dalam radius dekat ujung yang hidup — tanaman melawan di dekat
	# tubuhnya. Pemangkasan hanya memakan jalur yang ditinggalkan.
	var aman = 10.0
	# gumpalan jejak dalam jangkauan gunting -> layu paksa (mengering
	# cepat, sistem daur hidup yang menggugurkan)
	for g in avatar.jejak_daun:
		if g.pos.distance_to(avatar.pos) < aman:
			continue
		if abs(g.pos.x - pos.x) < 5.0 and pos.y - g.pos.y < 12.0 \
				and pos.y - g.pos.y > -4.0 and g.layu <= 0.0:
			g.layu = Config.RAMBAT_DAUN_LAYU * 0.35
	# sel jaringan TUMBUHAN pemain dalam jangkauan -> dipotong
	var px = int(round(pos.x))
	var py = int(round(pos.y))
	for dy in range(-12, 1):
		for dx in range(-4, 5):
			var sx = px + dx
			var sy = py + dy
			if Vector2(sx, sy).distance_to(avatar.pos) < aman:
				continue
			world.potong_tumbuhan(sx, sy)


# garis pandang horizontal sederhana di ketinggian mata (grid)
func _los(world, target):
	var y = int(round(pos.y - 4.0))
	var x0 = int(round(min(pos.x, target.x)))
	var x1 = int(round(max(pos.x, target.x)))
	var x = x0
	while x <= x1:
		if world.padat_avatar(x, y, false):
			return false
		x += 4
	return true
