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
var _tex_tumbang           # bangkai terbalut sulur (sergap senyap)
var _tex_daun              # gumpalan daun player — sulur pembungkus


func _init(p):
	pemangkas = p
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists("res://aset/musuh/teknisi_jalan.png"):
		_tex_jalan = load("res://aset/musuh/teknisi_jalan.png")
	if ResourceLoader.exists("res://aset/musuh/teknisi_diam.png"):
		_tex_diam = load("res://aset/musuh/teknisi_diam.png")
	if ResourceLoader.exists("res://aset/musuh/teknisi_tumbang.png"):
		_tex_tumbang = load("res://aset/musuh/teknisi_tumbang.png")
	if ResourceLoader.exists("res://aset/player/rambat_daun.png"):
		_tex_daun = load("res://aset/player/rambat_daun.png")


func _process(delta):
	_t += delta
	queue_redraw()


func _draw():
	var ppu = float(Config.PPU)
	var kaki = pemangkas.pos * ppu
	var p = kaki + Vector2(0.0, -24.0)

	# SERGAP SENYAP: tubuh terseret sulur (gemetar, tenggelam hijau,
	# gumpalan daun mengerubut) lalu tinggal BANGKAI terbalut sulur —
	# "membunuh dalam diam", tanpa teks, tanpa suara
	if not pemangkas.hidup:
		var q = clamp(pemangkas.mati_t / 0.9, 0.0, 1.0)
		if q < 1.0:
			var tex_m = _tex_diam if _tex_diam != null else _tex_jalan
			var goyang = sin(pemangkas.mati_t * 42.0) * 2.5 * (1.0 - q)
			var hijau = Color(1, 1, 1).lerp(Color(0.45, 0.75, 0.4), q)
			hijau.a = 1.0 - q * 0.35
			if tex_m != null:
				draw_set_transform(p + Vector2(goyang, q * 12.0), 0.0,
						Vector2(pemangkas.arah, 1.0 - q * 0.4))
				draw_texture_rect_region(tex_m,
						Rect2(Vector2(-24.0, -24.0), Vector2(48.0, 48.0)),
						Rect2(0.0, 0.0, 48.0, 48.0), hijau)
				draw_set_transform_matrix(Transform2D())
			if _tex_daun != null:
				var n_v = max(1, _tex_daun.get_width() / 16)
				for k in range(6):
					var sudut = float(k) * TAU / 6.0 + q * 2.0
					var jarak = 30.0 * (1.0 - q) + 6.0
					var pd = kaki + Vector2(cos(sudut), sin(sudut) * 0.6) \
							* jarak + Vector2(0.0, -12.0)
					draw_texture_rect_region(_tex_daun,
							Rect2(pd - Vector2(8.0, 8.0), Vector2(16.0, 16.0)),
							Rect2((k % n_v) * 16.0, 0.0, 16.0, 16.0))
		else:
			if _tex_tumbang != null:
				var w = float(_tex_tumbang.get_width())
				var h = float(_tex_tumbang.get_height())
				draw_texture_rect(_tex_tumbang,
						Rect2(kaki.x - w * 0.5, kaki.y - h, w, h), false)
			else:
				var bangkai = Color("2B333C")
				draw_rect(Rect2(kaki + Vector2(-18.0, -8.0),
						Vector2(36.0, 8.0)), bangkai)
			# lumut merambati bangkai — pelan, deterministik dari umur
			if _tex_daun != null:
				var n_v2 = max(1, _tex_daun.get_width() / 16)
				var tumbuh_n = clamp(int((pemangkas.mati_t - 0.9) / 1.2),
						0, 3)
				for k in range(tumbuh_n):
					draw_texture_rect_region(_tex_daun,
							Rect2(kaki + Vector2(-14.0 + k * 10.0, -14.0),
							Vector2(14.0, 14.0)),
							Rect2((k % n_v2) * 16.0, 0.0, 16.0, 16.0),
							Color(1, 1, 1, 0.9))
		return

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
	# lampu kepala berbicara (tanpa teks): KEJAR = kedip cepat,
	# SELIDIK = kedip-ganda pelan sambil menoleh, lainnya redup tenang
	var lampu = Color("D89A3C")
	if pemangkas.state == pemangkas.KEJAR:
		lampu.a = 0.9 if int(_t * 8.0) % 2 == 0 else 0.55
	elif pemangkas.state == pemangkas.SELIDIK:
		var fase = fmod(_t, 1.2)
		lampu.a = 0.9 if fase < 0.15 or (fase > 0.3 and fase < 0.45) \
				else 0.45
	else:
		lampu.a = 0.55
	draw_circle(p + Vector2(pemangkas.arah * 7.0, -18.0), 2.5, lampu)
