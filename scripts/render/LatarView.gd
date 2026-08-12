extends Node2D

# Latar parallax (G8): langit + dua barisan siluet kota jauh di belakang
# fasad. Ubin langit TileMap tidak dipakai lagi di pane atas — langit milik
# view ini, jadi siluet bisa bergeser lebih lambat daripada dunia dan
# kedalaman muncul tanpa satu aset pun.
#
# Rumus parallax: gambar pada x' = x + cam.x * (1 - f). Kamera bergeser
# 100 px -> lapisan ikut 100*(1-f) px -> gerak tampak = 100*f px (lebih
# pelan dari dunia). Siluet digambar deterministik (seed tetap) supaya
# kotanya sama tiap kali dibuka.
#
# CanvasModulate pane ikut menggelapkan latar saat malam — gratis.

var pane
var _lapis = []
var _cam_last = Vector2.INF


func _init(p):
	pane = p
	var rng = RandomNumberGenerator.new()
	rng.seed = 7
	_lapis = [
		{"f": 0.25, "warna": Color("7E8896"),
				"gedung": _barisan(rng, 120, 300, 70)},
		{"f": 0.50, "warna": Color("6F7987"),
				"gedung": _barisan(rng, 200, 480, 100)},
	]


func _barisan(rng, t_min, t_max, lebar):
	var keluar = []
	var x = -1400.0
	while x < 3600.0:
		var w = lebar * (0.7 + rng.randf() * 0.9)
		keluar.append({"x": x, "w": w,
				"h": t_min + rng.randf() * (t_max - t_min)})
		x += w + rng.randf() * 90.0
	return keluar


func _process(_delta):
	# hanya redraw saat kamera benar-benar berpindah
	if pane.cam.position != _cam_last:
		_cam_last = pane.cam.position
		queue_redraw()


func _draw():
	var cam = pane.cam.position

	# langit terkunci ke kamera — selalu menutup seluruh pandangan
	draw_rect(Rect2(cam - Vector2(2600, 2600), Vector2(5200, 5200)),
			Config.C_SKY)

	var horizon = float(Config.GROUND_Y * Config.PPU)
	for l in _lapis:
		var geser = cam.x * (1.0 - l.f)
		for g in l.gedung:
			draw_rect(Rect2(g.x + geser, horizon - g.h, g.w, g.h), l.warna)
