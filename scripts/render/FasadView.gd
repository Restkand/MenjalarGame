extends Node2D

# Fitur fasad — jendela, pintu, ledge — digambar di atas ubin dinding.
#
# Fitur-fitur ini TIDAK duduk di kisi petak 8 satuan (jendela 14x16 pada
# pitch 30x26), jadi memaksakannya jadi ubin akan menggeser tata letak dan
# mengubah gameplay. Sebagai gantinya satu node menggambar semuanya lewat
# _draw() pada posisi satuan persisnya; grid tetap memegang bentuk aslinya
# untuk tigmotropisme dan vis.
#
# Digambar ulang hanya ketika TerrainView menemukan petak kotor — saat
# keruntuhan melenyapkan fitur, gambarnya ikut lenyap karena tiap fitur
# dicek ke grid sebelum digambar.
#
# Koordinat lokal di sini piksel tampilan (parent di-skala 1/PPU oleh
# TerrainView), jadi semua rect satuan dikalikan PPU.

var world
var _tex_jendela
var _tex_pintu


func _init(w):
	world = w
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tex_jendela = load("res://aset/jendela.png")
	_tex_pintu = load("res://aset/pintu.png")


func _r(rect):
	return Rect2(rect.position * Config.PPU, rect.size * Config.PPU)


func _draw():
	var ppu = float(Config.PPU)

	# jalan raya (playtest 12 Agu): trotoar beton di sepanjang garis tanah
	# dengan siar antar lempeng dan bibir jalan gelap — digambar paling awal
	# supaya kaki gedung, pintu, dan aktor duduk di atasnya
	# trotoar digambar per SEGMEN, menyisakan celah di dua lubang got
	# (P3.75) — pintu masuk bawah tanah harus terlihat, bukan jebakan
	var gy = float(Config.GROUND_Y)
	for seg in [[0, 146], [151, 330], [335, Config.W]]:
		draw_rect(Rect2(seg[0] * ppu, (gy - 3.0) * ppu,
				(seg[1] - seg[0]) * ppu, 3.0 * ppu), Color("8D8D85"))
		draw_rect(Rect2(seg[0] * ppu, (gy - 0.75) * ppu,
				(seg[1] - seg[0]) * ppu, 0.75 * ppu), Color("55554F"))
	var sx = 0
	while sx < Config.W:
		if (sx < 146 or sx >= 151) and (sx < 330 or sx >= 335):
			draw_rect(Rect2(float(sx) * ppu, (gy - 3.0) * ppu,
					1.0, 3.0 * ppu), Color("6B6B64"))
		sx += 10

	# jendela: sprite PixelLab 56x64 (gelombang 2, docs/12) — kanvas persis
	# 14x16 satuan, jadi digambar 1:1 pada rect fiturnya
	for w in world.windows:
		# jendela yang sudah runtuh tidak digambar — aturan yang sama dengan
		# lampu malam di Suasana.set_night()
		if world.at(int(w.x), int(w.y)) != Config.T_WINDOW:
			continue
		var r = Rect2i(int(w.x) - 7, int(w.y) - 8, 14, 16)
		draw_texture_rect(_tex_jendela, _r(r), false)

	for f in world.fitur:
		var r = f.rect
		var tengah = r.get_center()
		if world.at(tengah.x, tengah.y) == Config.T_SKY:
			continue   # sudah runtuh
		if f.jenis == "pintu":
			draw_texture_rect(_tex_pintu, _r(r), false)
		else:
			draw_rect(_r(r), Config.C_LEDGE)
			# sisi bawah (atau kanan, untuk yang tegak) diberi bayangan
			if r.size.x >= r.size.y:
				draw_rect(Rect2(r.position.x * ppu, (r.end.y - 1) * ppu,
						r.size.x * ppu, 1.0 * ppu), Config.C_RETAK)
			else:
				draw_rect(Rect2((r.end.x - 1) * ppu, r.position.y * ppu,
						1.0 * ppu, r.size.y * ppu), Config.C_RETAK)
