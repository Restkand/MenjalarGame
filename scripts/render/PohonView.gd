extends Node2D

# Pohon — sprite PixelLab, satu batch _draw() untuk semua pohon (R6).
#
# Pohon tumbuh MENYELURUH dari kecil ke besar (skala seragam berjangkar di
# pangkal batang), bukan diregangkan tingginya — meregangkan sprite merusak
# gambarnya, sedangkan pohon muda yang utuh-tapi-kecil justru terlihat wajar.
#
# Sejak G8 redraw berjalan selama ada pohon — mereka berayun pelan ditiup
# angin. Tanpa pohon, nol kerja.

var sim
var _t = 0.0
var _tex


func _init(s):
	sim = s
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tex = load("res://aset/pohon.png")


func _process(delta):
	# G8: pohon berayun pelan ditiup angin — redraw terus selama ada pohon
	_t += delta
	if not sim.trees.is_empty():
		queue_redraw()


func _draw():
	if _tex == null:
		return
	var ppu = float(Config.PPU)
	# skala saat dewasa: tinggi sprite 128 px menutupi POHON_TINGGI satuan
	var penuh = float(Config.POHON_TINGGI) * ppu / 128.0
	for t in sim.trees:
		var f = clamp(float(t.tinggi) / float(Config.POHON_TINGGI), 0.0, 1.0)
		var s = (0.22 + 0.78 * f) * penuh
		# ayunan halus berjangkar di pangkal batang; fase dari posisi
		var angin = sin(_t * 0.8 + t.x * 0.05) * 0.014
		draw_set_transform(Vector2(t.x, t.y) * ppu, angin, Vector2(s, s))
		draw_texture(_tex, Vector2(-48.0, -128.0))
	draw_set_transform_matrix(Transform2D())
