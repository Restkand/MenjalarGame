extends Node2D

# Gumpalan daun yang DITANAM ujung tumbuh saat merambat (avatar.
# jejak_daun) — tubuh tanaman adalah jejak yang tertinggal di dunia,
# bukan sprite yang ikut berpindah. Gumpalan diiris dari art untai
# daun yang disetujui pemilik (satu bahasa piksel), digelapkan satu
# tangga supaya UJUNG yang hidup selalu paling terang (EDV3 §3.1).
# Redraw TIAP FRAME (600 quad murah) — pemicu berbasis jumlah dulu
# membeku begitu ring buffer penuh: jumlah tak berubah lagi padahal
# isinya berganti, jejak baru tak pernah tampil (temuan playtest
# pemilik: "jejak merambat hilang lalu baru muncul belakangan").

var avatar
var _tex


func _init(a):
	avatar = a
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists("res://aset/player/rambat_daun.png"):
		_tex = load("res://aset/player/rambat_daun.png")


func _process(_delta):
	queue_redraw()


func _draw():
	if _tex == null:
		return
	var ppu = float(Config.PPU)
	var n = max(1, _tex.get_width() / 16)
	for g in avatar.jejak_daun:
		if g.dalam != avatar.di_dalam:
			continue
		draw_set_transform(g.pos * ppu, g.sudut, Vector2.ONE)
		draw_texture_rect_region(_tex,
				Rect2(Vector2(-8.0, -8.0), Vector2(16.0, 16.0)),
				Rect2((g.varian % n) * 16.0, 0.0, 16.0, 16.0))
	draw_set_transform_matrix(Transform2D())
