extends Node2D

# Pohon — sprite PixelLab, satu batch _draw() untuk semua pohon (R6).
#
# Pohon tumbuh MENYELURUH dari kecil ke besar (skala seragam berjangkar di
# pangkal batang), bukan diregangkan tingginya — meregangkan sprite merusak
# gambarnya, sedangkan pohon muda yang utuh-tapi-kecil justru terlihat wajar.
#
# Redraw hanya selama ada pohon yang masih meninggi (atau jumlahnya berubah);
# hutan yang sudah dewasa tidak menggambar ulang apa pun.

var sim
var _n = -1
var _tumbuh = false
var _tex


func _init(s):
	sim = s
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tex = load("res://aset/pohon.png")


func _process(_delta):
	var tumbuh = false
	for t in sim.trees:
		if t.tinggi < Config.POHON_TINGGI:
			tumbuh = true
			break
	# _tumbuh lama ikut memicu: frame pertama SETELAH berhenti tumbuh masih
	# perlu satu redraw penutup pada tinggi finalnya
	if sim.trees.size() != _n or tumbuh or _tumbuh:
		_n = sim.trees.size()
		_tumbuh = tumbuh
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
		draw_set_transform(Vector2(t.x, t.y) * ppu, 0.0, Vector2(s, s))
		draw_texture(_tex, Vector2(-48.0, -128.0))
	draw_set_transform_matrix(Transform2D())
