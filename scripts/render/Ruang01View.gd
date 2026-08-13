extends Node2D

# ROOM 01 — lapis visual Phase 5 (SRD §33) di atas tata letak graybox yang
# LULUS uji. Tekstur PixelLab dari aset/ruang01/ (crop tengah + snap palet
# kelabu ruangan): tile 8 satuan x PPU 4 = 32 px = ukuran tekstur, jadi
# semua terpasang 1:1 tanpa penskalaan.
#
# Kontras inti §24 dijaga: seluruh ruangan kelabu gelap tak jenuh;
# jaringan (dan avatar) = satu-satunya yang hijau. Latar belakang digambar
# lebih redup daripada tile padat supaya siluet & pijakan tetap menang.

var world
var _tex = {}

const C_JARING = Color("4F8F32")   # sulur induk (palet CDD §7)
const C_DAUN   = Color("79B83F")
const C_SENSOR = Color("D8A34A")   # kuning status CDD (waspada)
const REDUP_LATAR = Color(0.44, 0.47, 0.55)   # latar mundur ke belakang
const C_SOROT  = Color("5A646D")   # bibir permukaan pijakan
const C_BAYANG = Color("0E1114")


func _init(w):
	world = w
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	for n in ["beton_dinding", "beton_lantai", "latar", "pipa", "kabel",
			"sensor", "retak"]:
		var jalur = "res://aset/ruang01/%s.png" % n
		if ResourceLoader.exists(jalur):
			_tex[n] = load(jalur)


func _draw():
	var ppu = float(Config.PPU)
	var t = world.TILE * ppu

	# latar: panel logam gelap se-ruangan, diredupkan (§24: latar tidak
	# boleh mengalahkan siluet)
	if _tex.has("latar"):
		draw_texture_rect(_tex.latar,
				Rect2(0, 0, world.W * ppu, world.H * ppu), true, REDUP_LATAR)
	else:
		draw_rect(Rect2(0, 0, world.W * ppu, world.H * ppu),
				Color(0.075, 0.085, 0.10))

	# properti di depan latar, di belakang cangkang: pipa air turun di
	# dekat jaringan tujuan (§35: pipa = sumber), dua kabel menggantung
	if _tex.has("pipa"):
		draw_texture_rect(_tex.pipa, Rect2(912, 32, 32, 416), true)
	if _tex.has("kabel"):
		draw_texture_rect(_tex.kabel, Rect2(400, 32, 64, 32), false)
		draw_texture_rect(_tex.kabel, Rect2(600, 32, 64, 32), false)

	# cangkang & pijakan: dinding/plafon = pasangan bata gelap, massa
	# pijakan (pita lantai, tangga peti, blok, panggung) = slab lantai
	for ty in range(world.PT_H):
		for tx in range(world.PT_W):
			if world.padat_t[ty * world.PT_W + tx] == 0:
				continue
			var kulit = ty == 0 or tx == 0 or tx == world.PT_W - 1
			var nama = "beton_dinding" if kulit else "beton_lantai"
			var r = Rect2(tx * t, ty * t, t, t)
			if _tex.has(nama):
				draw_texture_rect(_tex[nama], r, false)
			else:
				draw_rect(r, Color(0.33, 0.35, 0.38))
			# bibir permukaan: sisi yang menghadap udara diberi aksen
			# supaya pijakan/tepian terbaca dalam gelap
			if _terbuka(tx, ty - 1):
				var sorot = C_SOROT
				sorot.a = 0.45
				draw_rect(Rect2(r.position, Vector2(t, ppu * 0.5)), sorot)
			if _terbuka(tx, ty + 1):
				var bayang = C_BAYANG
				bayang.a = 0.6
				draw_rect(Rect2(r.position + Vector2(0, t - ppu * 0.5),
						Vector2(t, ppu * 0.5)), bayang)

	# dekal retak (§23: celah = undangan): di bibir celah lantai dan
	# di mulut cerobong keluar
	if _tex.has("retak"):
		draw_texture_rect(_tex.retak, Rect2(256, 432, 32, 32), false)
		draw_texture_rect(_tex.retak, Rect2(864, 432, 32, 32), false)

	# benih jaringan: hijau harus menang di atas segala kelabu (§24) —
	# bahasa visual sama dengan JejakView
	for seg in world.jalur_seed:
		var a = seg[0] * ppu
		var b = seg[1] * ppu
		draw_line(a, b, C_JARING, 3.0)
		var jarak = a.distance_to(b)
		var n = int(jarak / (10.0 * ppu))   # sehelai tiap ~10 satuan
		for i in range(n + 1):
			var p = a.lerp(b, float(i) / float(max(1, n)))
			var sisi = 1.0 if i % 2 == 0 else -1.0
			var arah = (b - a).normalized()
			var normal = Vector2(-arah.y, arah.x) * sisi * 4.0
			draw_circle(p + normal, 3.0, C_DAUN)

	# sensor perawatan (§14) di DEPAN jaringan — benda asing menggantung
	# menutupi sulur di belakangnya. Phase 1 masih penanda niat; logika
	# deteksi jatah Phase 4.
	var s = world.sensor_pos * ppu
	if _tex.has("sensor"):
		draw_texture_rect(_tex.sensor, Rect2(s.x - 16.0, 28.0, 32, 32),
				false)
	else:
		draw_rect(Rect2(s + Vector2(-8, -8), Vector2(16, 12)),
				Color(0.2, 0.21, 0.23))
	var kerucut = PackedVector2Array([
		s + Vector2(0, 24),
		s + Vector2(-56, 300),
		s + Vector2(56, 300),
	])
	var warna_kerucut = C_SENSOR
	warna_kerucut.a = 0.10
	draw_colored_polygon(kerucut, warna_kerucut)


func _terbuka(tx, ty):
	if tx < 0 or tx >= world.PT_W or ty < 0 or ty >= world.PT_H:
		return false
	return world.padat_t[ty * world.PT_W + tx] == 0
