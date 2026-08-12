extends Node2D

# Penabur daun (docs/09 §5) — dimajukan dari R3 supaya sulur Line2D tidak
# pernah tampil telanjang. SATU node menggambar SEMUA daun lewat _draw();
# satu Sprite2D per daun akan jadi ratusan node.
#
# Dari gambar acuan mekanik merambat: batang dan daun adalah lapisan
# TERPISAH. Itulah yang memungkinkan tahap pertumbuhan (kepadatan daun naik
# di batang yang sama), daun layu per helai, dan pemangkasan — semuanya
# mustahil kalau daun dibakar ke tekstur batang.
#
# queue_redraw() hanya saat ada yang berubah: jumlah daun bergeser (lahir,
# dipangkas regu, rontok saat mundur) atau masih ada daun muda yang sedang
# membesar. Sulur dewasa yang diam tidak menggambar ulang apa pun.

var sim
var atlas
var _n = -1


func _init(s):
	sim = s
	atlas = load("res://aset/daun_atlas.png")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(_delta):
	var n = 0
	var muda = false
	for s in sim.strands:
		if s.is_root:
			continue
		n += s.leaves.size()
		if not muda:
			for l in s.leaves:
				if l.age < 1.5:
					muda = true
					break
	if n != _n or muda:
		_n = n
		queue_redraw()


func _draw():
	if atlas == null:
		return
	var ppu = float(Config.PPU)
	for s in sim.strands:
		if s.is_root:
			continue
		for l in s.leaves:
			var v = int(l.get("varian", 0))
			# daun lahir kecil lalu membesar selama 1,5 detik (§9 Logika)
			var sk = l.get("skala", 1.0) * (0.5 + 0.5 * min(1.0, l.age / 1.5))
			# BERJANGKAR di pangkalnya: transform diletakkan di titik tempel
			# pada sumbu sulur, diputar searah `sudut` (tegak lurus sulur,
			# berselang-seling), lalu sprite digambar dengan pangkal di
			# origin — 4 px pangkalnya terbenam di bawah batang supaya
			# sambungannya tidak pernah terlihat putus.
			draw_set_transform(l.pos * ppu,
					l.get("sudut", -PI / 2.0) + PI / 2.0,
					Vector2(sk, sk))
			draw_texture_rect_region(atlas,
					Rect2(Vector2(-14.0, -24.0), Vector2(28.0, 28.0)),
					Rect2(v * 24, 0, 24, 24))
	draw_set_transform_matrix(Transform2D())
