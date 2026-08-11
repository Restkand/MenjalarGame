extends Node2D

# Puing yang MENGENDAP — digambar per sel, BUKAN per ubin.
#
# Playtest 11 Agustus: tumpukan puing sebagai ubin TileMap "sangat
# mengganggu" — dan penyebabnya struktural. Simulasi pasir-jatuh menghasilkan
# gundukan yang melandai alami, lalu pemetaan mayoritas 8x8 meratakannya jadi
# balok abu-abu kaku bertepi lurus yang terbaca seperti balok beton melayang.
#
# View ini menggambar tiap sel `settled` sebagai satu kotak satuan dengan
# variasi warna deterministik (hash posisi), jadi SILUET TUMPUKAN YANG
# SEBENARNYA yang tampil — melandai, bergerigi, organik. Ubin T_PUING di
# TileMap tidak dipakai lagi (dipetakan ke langit).
#
# Redraw hanya saat ada puing baru mengendap (world.settled_n berubah).
# Tumpukan yang diam tidak menggambar ulang apa pun.

var world
var _n = -1


func _init(w):
	world = w
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(_delta):
	if world.settled_n != _n:
		_n = world.settled_n
		queue_redraw()


func _draw():
	if world.settled_n == 0:
		return
	var ppu = float(Config.PPU)
	var y0 = int(max(0, world.puing_atas - 1))
	for y in range(y0, Config.GROUND_Y):
		var baris = y * Config.W
		for x in range(Config.W):
			if world.settled[baris + x] == 0:
				continue
			# variasi tiga rona dari hash posisi — stabil antar frame,
			# tidak pernah berkedip
			var v = (x * 7 + y * 13) % 5
			var c = Config.C_PUING
			if v == 0:
				c = Config.C_PUING_HL
			elif v == 4:
				c = Config.C_PUING_DK
			draw_rect(Rect2(x * ppu, y * ppu, ppu, ppu), c)
