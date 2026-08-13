extends Node2D

# Graybox ROOM 01 (SRD §33 Phase 1) — datar, terbaca, TANPA art final.
# Kontras kunci §24 tetap dipegang sejak graybox: gedung kelabu gelap,
# jaringan = satu-satunya yang hijau. Beton digambar per tile dengan sisi
# dalam lebih gelap supaya tepian/celah terbaca tanpa tekstur.

var world

const C_LATAR  = Color(0.075, 0.085, 0.10)    # udara ruangan: gelap lembap
const C_BETON  = Color(0.33, 0.35, 0.38)      # graybox padat
const C_BETON_TEPI = Color(0.24, 0.26, 0.29)  # inset tile
const C_JARING = Color("4F8F32")              # sulur induk (palet CDD §7)
const C_DAUN   = Color("79B83F")              # simpul/daun benih
const C_SENSOR = Color("D8A34A")              # kuning status CDD (waspada)


func _init(w):
	world = w
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _draw():
	var ppu = float(Config.PPU)
	var t = world.TILE * ppu

	# udara ruangan
	draw_rect(Rect2(0, 0, world.W * ppu, world.H * ppu), C_LATAR)

	# beton per tile: isi + inset gelap (tepi terbaca, §24)
	for ty in range(world.PT_H):
		for tx in range(world.PT_W):
			if world.padat_t[ty * world.PT_W + tx] == 0:
				continue
			var r = Rect2(tx * t, ty * t, t, t)
			draw_rect(r, C_BETON)
			draw_rect(r.grow(-ppu * 0.5), C_BETON_TEPI, false, ppu * 0.5)

	# benih jaringan: sulur induk hijau + daun kecil berselang — bahasa
	# visual yang sama dengan JejakView supaya "jaringan = rumah" terbaca
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

	# sensor placeholder (§14): badan di plafon + kerucut pandang redup.
	# Phase 1 = penanda niat; logika deteksi menyusul Phase 4.
	var s = world.sensor_pos * ppu
	draw_rect(Rect2(s + Vector2(-8, -8), Vector2(16, 12)), Color(0.2, 0.21, 0.23))
	draw_circle(s + Vector2(0, 4), 3.0, C_SENSOR)
	var kerucut = PackedVector2Array([
		s + Vector2(0, 6),
		s + Vector2(-56, 300),
		s + Vector2(56, 300),
	])
	var warna_kerucut = C_SENSOR
	warna_kerucut.a = 0.10
	draw_colored_polygon(kerucut, warna_kerucut)
