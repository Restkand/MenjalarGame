extends Node2D

# Sulur yang DITUMBUHKAN avatar (P3, docs/13 §3.1) — jejak tubuh pemain.
# Satu batch _draw(): polyline batang + daun kecil berselang. Segmen
# disaring per lapis: saat di luar hanya jejak luar yang tampak (jejak
# interior tertutup gedung), saat di dalam sebaliknya (z di atas
# InteriorView).

var avatar
var _n = -1
var _dalam_terakhir = false


func _init(a):
	avatar = a


func _process(_delta):
	if avatar.jejak.size() != _n or avatar.di_dalam != _dalam_terakhir:
		_n = avatar.jejak.size()
		_dalam_terakhir = avatar.di_dalam
		queue_redraw()


func _draw():
	var ppu = float(Config.PPU)
	var batang = Config.C_BRANCH
	var daun = Config.C_LEAF
	var sebelum = null
	for i in range(avatar.jejak.size()):
		var j = avatar.jejak[i]
		if j.dalam != avatar.di_dalam:
			sebelum = null
			continue
		if sebelum != null \
				and sebelum.distance_to(j.pos) < 6.0:
			draw_line(sebelum * ppu, j.pos * ppu, batang, 3.0)
			# daun kecil berselang-seling — cukup untuk terbaca "sulur"
			if i % 3 == 0:
				var sisi = 1.0 if (i / 3) % 2 == 0 else -1.0
				draw_circle(j.pos * ppu + Vector2(sisi * 4.0, -3.0),
						3.0, daun)
		sebelum = j.pos
