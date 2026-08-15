extends Node2D

# Tampilan PEMANGKAS (RK-2 [C]): strip teknisi dari aset/musuh bila
# ada (jalan timur + cermin; 48 px/frame — manusia 32-48 px CDD,
# 1.5x sprite player supaya pemain terasa kecil), cadangan prosedural
# selama art belum lulus kurasi pemilik. Lampu kepala amber = bahasa
# ancaman dunia (identitas: manusia kelabu, organisme yang hijau).

var pemangkas
var _t = 0.0
var _tex_jalan
var _tex_diam


func _init(p):
	pemangkas = p
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists("res://aset/musuh/teknisi_jalan.png"):
		_tex_jalan = load("res://aset/musuh/teknisi_jalan.png")
	if ResourceLoader.exists("res://aset/musuh/teknisi_diam.png"):
		_tex_diam = load("res://aset/musuh/teknisi_diam.png")


func _process(delta):
	_t += delta
	queue_redraw()


func _draw():
	var ppu = float(Config.PPU)
	var p = pemangkas.pos * ppu + Vector2(0.0, -24.0)
	var tex = _tex_jalan if pemangkas.state != pemangkas.IDLE else _tex_diam
	if tex == null:
		tex = _tex_jalan
	# bayangan kontak (D8): teknisi duduk di lantai yang sama dengan dunia
	draw_set_transform(pemangkas.pos * ppu + Vector2(0.0, 1.0), 0.0,
			Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, 10.0, Color(0.02, 0.03, 0.04, 0.30))
	draw_set_transform_matrix(Transform2D())
	if tex != null:
		var n = max(1, tex.get_width() / 48)
		var fr = int(_t * 8.0) % n
		if pemangkas.state == pemangkas.IDLE:
			fr = int(_t * 3.0) % n
		draw_set_transform(p, 0.0, Vector2(pemangkas.arah, 1.0))
		draw_texture_rect_region(tex,
				Rect2(Vector2(-24.0, -24.0), Vector2(48.0, 48.0)),
				Rect2(fr * 48.0, 0.0, 48.0, 48.0))
		draw_set_transform_matrix(Transform2D())
	else:
		# cadangan graybox: siluet teknisi + helm amber
		var badan = Color("2B333C")
		draw_rect(Rect2(p + Vector2(-5.0, -14.0), Vector2(10.0, 38.0)),
				badan)
		draw_rect(Rect2(p + Vector2(-6.0, -20.0), Vector2(12.0, 7.0)),
				Color("8A5A20"))
	# lampu kepala: berkedip saat KEJAR (bahasa ancaman)
	var lampu = Color("D89A3C")
	lampu.a = 0.9 if pemangkas.state == pemangkas.KEJAR \
			and int(_t * 8.0) % 2 == 0 else 0.55
	draw_circle(p + Vector2(pemangkas.arah * 7.0, -18.0), 2.5, lampu)
