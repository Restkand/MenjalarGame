extends Node2D

# Bangkai sulur (G3) — potongan gergaji regu yang sedang mengering.
# Satu batch _draw(): tiap bangkai digambar sebagai polyline kering
# kecokelatan yang MENYUSUT dari ujung; itulah umpan balik bahwa tutupan
# sedang terkikis dan waktu menyambung (tunas ulang) sedang berjalan habis.
#
# Redraw tiap frame selama ada bangkai — mereka memang berubah terus.
# Kosong = satu redraw penutup, lalu nol kerja.

var sim
var _ada = false


func _init(s):
	sim = s
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(_delta):
	if sim.bangkai.is_empty():
		if _ada:
			_ada = false
			queue_redraw()
		return
	_ada = true
	queue_redraw()


func _draw():
	var ppu = float(Config.PPU)
	for b in sim.bangkai:
		if b.pts.size() < 2:
			continue
		var pl = PackedVector2Array()
		var i = 0
		while i < b.pts.size():
			pl.append(b.pts[i] * ppu)
			i += 3
		if b.pts.size() % 3 != 1:
			pl.append(b.pts[b.pts.size() - 1] * ppu)
		if pl.size() < 2:
			continue
		draw_polyline(pl, Config.C_BANGKAI, 2.2 * ppu)
