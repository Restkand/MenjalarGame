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


func _init(w):
	world = w


func _r(rect):
	return Rect2(rect.position * Config.PPU, rect.size * Config.PPU)


func _draw():
	var ppu = float(Config.PPU)

	# jendela: bingkai ambang, kaca, palang tengah
	for w in world.windows:
		# jendela yang sudah runtuh tidak digambar — aturan yang sama dengan
		# lampu malam di Suasana.set_night()
		if world.at(int(w.x), int(w.y)) != Config.T_WINDOW:
			continue
		var r = Rect2i(int(w.x) - 7, int(w.y) - 8, 14, 16)
		draw_rect(_r(r), Config.C_WALL_DARK)                    # bingkai
		draw_rect(_r(r.grow(-1)), Config.C_WINDOW)              # kaca
		# palang jendela — dua garis tipis menyilang
		draw_rect(Rect2((r.position.x + 1) * ppu, (w.y - 0.5) * ppu,
				12.0 * ppu, 1.0 * ppu), Config.C_WALL_DARK)
		draw_rect(Rect2((w.x - 0.5) * ppu, (r.position.y + 1) * ppu,
				1.0 * ppu, 14.0 * ppu), Config.C_WALL_DARK)
		# ambang bawah menonjol — sisi bawah gelap, aturan volume docs/01 §5
		draw_rect(Rect2((r.position.x - 1) * ppu, r.end.y * ppu,
				16.0 * ppu, 1.0 * ppu), Config.C_LEDGE)

	for f in world.fitur:
		var r = f.rect
		var tengah = r.get_center()
		if world.at(tengah.x, tengah.y) == Config.T_SKY:
			continue   # sudah runtuh
		if f.jenis == "pintu":
			draw_rect(_r(r.grow(1)), Config.C_WALL_DARK)        # kusen
			draw_rect(_r(r), Config.C_DOOR)
			# garis belah dua daun pintu
			draw_rect(Rect2((tengah.x - 0.5) * ppu, r.position.y * ppu,
					1.0 * ppu, r.size.y * ppu), Config.C_WALL_DARK)
		else:
			draw_rect(_r(r), Config.C_LEDGE)
			# sisi bawah (atau kanan, untuk yang tegak) diberi bayangan
			if r.size.x >= r.size.y:
				draw_rect(Rect2(r.position.x * ppu, (r.end.y - 1) * ppu,
						r.size.x * ppu, 1.0 * ppu), Config.C_RETAK)
			else:
				draw_rect(Rect2((r.end.x - 1) * ppu, r.position.y * ppu,
						1.0 * ppu, r.size.y * ppu), Config.C_RETAK)
