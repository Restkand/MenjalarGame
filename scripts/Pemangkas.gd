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

const IDLE   = 0
const PATROL = 1
const KEJAR  = 2

var pos = Vector2()
var arah = 1.0             # hadap: 1 kanan, -1 kiri
var state = PATROL
var _jeda = 0.0            # sisa detik IDLE / cooldown usai menangkap
var _batas_kiri = 84.0
var _batas_kanan = 200.0


func _init(kiri, kanan):
	_batas_kiri = kiri
	_batas_kanan = kanan
	pos = Vector2(kiri, 111.9)


func update(dt, avatar, world):
	_jeda = max(0.0, _jeda - dt)

	# melihat avatar? hanya moda LEPAS, sejajar lantai, searah hadap,
	# dalam jarak pandang, tanpa beton menghalangi
	var lihat = false
	if avatar.moda == avatar.LEPAS and _jeda <= 0.0:
		var d = avatar.pos - pos
		if abs(d.y) < 8.0 and abs(d.x) < Config.PEMANGKAS_PANDANG \
				and signf(d.x) == signf(arah) and _los(world, avatar.pos):
			lihat = true

	match state:
		IDLE:
			if lihat:
				state = KEJAR
			elif _jeda <= 0.0:
				arah = -arah
				state = PATROL
		PATROL:
			if lihat:
				state = KEJAR
			else:
				pos.x += arah * Config.PEMANGKAS_JALAN * dt
				if pos.x <= _batas_kiri or pos.x >= _batas_kanan:
					pos.x = clamp(pos.x, _batas_kiri, _batas_kanan)
					state = IDLE
					_jeda = Config.PEMANGKAS_JEDA
		KEJAR:
			var d2 = avatar.pos.x - pos.x
			arah = signf(d2) if abs(d2) > 0.5 else arah
			pos.x += arah * Config.PEMANGKAS_KEJAR * dt
			pos.x = clamp(pos.x, _batas_kiri, _batas_kanan)
			# hilang dari pandangan (naik jaringan / menjauh) -> patroli
			if not lihat and abs(d2) > Config.PEMANGKAS_PANDANG:
				state = PATROL
			# menangkap: kuras besar + terpental (TANPA membunuh)
			if avatar.moda == avatar.LEPAS \
					and avatar.pos.distance_to(pos) < 4.0:
				avatar.energi -= Config.PEMANGKAS_KURAS
				avatar.vel = Vector2(arah * 30.0, -24.0)
				_jeda = Config.PEMANGKAS_JEDA
				state = IDLE

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
