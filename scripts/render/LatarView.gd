extends Node2D

# Latar parallax (G8): langit + dua barisan siluet kota jauh di belakang
# fasad. Ubin langit TileMap tidak dipakai lagi di pane atas — langit milik
# view ini, jadi siluet bisa bergeser lebih lambat daripada dunia dan
# kedalaman muncul tanpa satu aset pun.
#
# Rumus parallax: gambar pada x' = x + cam.x * (1 - f). Kamera bergeser
# 100 px -> lapisan ikut 100*(1-f) px -> gerak tampak = 100*f px (lebih
# pelan dari dunia).
#
# Siluetnya strip PixelLab (gelombang 3, docs/12) yang di-recolor ke rona
# lapisnya — bentuk dari model, warna tetap milik palet kita. Tiap strip
# diulang horizontal menutupi rentang pandang, berjangkar di horizon.
#
# CanvasModulate pane ikut menggelapkan latar saat malam — gratis.

var pane
var _lapis = []
var _cam_last = Vector2.INF


func _init(p):
	pane = p
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# skala 2: strip 100/140 px terlalu pendek dibanding fasad 192*4 px;
	# diperbesar bulat supaya pikselnya tetap tajam
	_lapis = [
		{"f": 0.25, "tex": load("res://aset/latar_jauh.png"), "skala": 2.0},
		{"f": 0.50, "tex": load("res://aset/latar_dekat.png"), "skala": 2.0},
	]


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
		var w = l.tex.get_width() * l.skala
		var h = l.tex.get_height() * l.skala
		# mulai dari ubin strip pertama yang masih masuk pandangan kiri
		var kiri = cam.x - 1400.0
		var mulai = floor((kiri - geser) / w) * w + geser
		var x = mulai
		while x < cam.x + 1400.0:
			draw_texture_rect(l.tex, Rect2(x, horizon - h, w, h), false)
			x += w
