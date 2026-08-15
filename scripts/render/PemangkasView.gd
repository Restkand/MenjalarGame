extends Node2D

# Tampilan PEMANGKAS (RK-2 [C]): strip teknisi dari aset/musuh bila
# ada (jalan timur + cermin; 48 px/frame — manusia 32-48 px CDD,
# 1.5x sprite player supaya pemain terasa kecil), cadangan prosedural
# selama art belum lulus kurasi pemilik. Lampu kepala amber = bahasa
# ancaman dunia (identitas: manusia kelabu, organisme yang hijau).

var pemangkas
var mayat = []             # dipegang Ruang01Main: bangkai [{pos, t}]
var _t = 0.0
var _tex_jalan
var _tex_diam
var _tex_tumbang           # bangkai terbalut sulur (sergap senyap)
var _tex_mati              # strip roboh falling-back-death (48px/frame)
var _tex_daun              # gumpalan daun player — sulur pembungkus
var _tex_seru              # ikon ! — sadar & memburu (PixelLab)
var _tex_tanya             # ikon ? — curiga & menyelidik (PixelLab)
var _state_lalu = -1
var _icon = ""             # "seru" / "tanya" / ""
var _icon_t = 0.0          # umur ikon — penggerak pop & goyang


func _init(p):
	pemangkas = p
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists("res://aset/musuh/teknisi_jalan.png"):
		_tex_jalan = load("res://aset/musuh/teknisi_jalan.png")
	if ResourceLoader.exists("res://aset/musuh/teknisi_diam.png"):
		_tex_diam = load("res://aset/musuh/teknisi_diam.png")
	if ResourceLoader.exists("res://aset/musuh/teknisi_tumbang.png"):
		_tex_tumbang = load("res://aset/musuh/teknisi_tumbang.png")
	if ResourceLoader.exists("res://aset/musuh/teknisi_mati.png"):
		_tex_mati = load("res://aset/musuh/teknisi_mati.png")
	if ResourceLoader.exists("res://aset/player/rambat_daun.png"):
		_tex_daun = load("res://aset/player/rambat_daun.png")
	if ResourceLoader.exists("res://aset/musuh/icon_seru.png"):
		_tex_seru = load("res://aset/musuh/icon_seru.png")
	if ResourceLoader.exists("res://aset/musuh/icon_tanya.png"):
		_tex_tanya = load("res://aset/musuh/icon_tanya.png")


func _process(delta):
	_t += delta
	_icon_t += delta
	# ikon kesadaran mengikuti state: ! saat mulai memburu, ? saat
	# mulai menyelidik — pop baru tiap kali state-nya BERGANTI
	if pemangkas.state != _state_lalu:
		_state_lalu = pemangkas.state
		if pemangkas.state == pemangkas.KEJAR:
			_icon = "seru"
			_icon_t = 0.0
		elif pemangkas.state == pemangkas.SELIDIK:
			_icon = "tanya"
			_icon_t = 0.0
		else:
			_icon = ""
	if not pemangkas.hidup:
		_icon = ""
	queue_redraw()


func _draw():
	var ppu = float(Config.PPU)
	var kaki = pemangkas.pos * ppu
	var p = kaki + Vector2(0.0, -24.0)

	# BANGKAI dari daftar (dipegang Ruang01Main — bertahan walau
	# pengganti sudah datang): tampak setelah anim sergapan 0.9 dtk,
	# lumut merambatinya bertahap seiring umur
	for m in mayat:
		if m.t < 0.9:
			continue
		var km = m.pos * ppu
		if _tex_tumbang != null:
			var w = float(_tex_tumbang.get_width())
			var h = float(_tex_tumbang.get_height())
			draw_texture_rect(_tex_tumbang,
					Rect2(km.x - w * 0.5, km.y - h, w, h), false)
		else:
			draw_rect(Rect2(km + Vector2(-18.0, -8.0),
					Vector2(36.0, 8.0)), Color("2B333C"))
		if _tex_daun != null:
			var n_v2 = max(1, _tex_daun.get_width() / 16)
			var tumbuh_n = clamp(int((m.t - 0.9) / 1.2), 0, 3)
			for k in range(tumbuh_n):
				draw_texture_rect_region(_tex_daun,
						Rect2(km + Vector2(-14.0 + k * 10.0, -14.0),
						Vector2(14.0, 14.0)),
						Rect2((k % n_v2) * 16.0, 0.0, 16.0, 16.0),
						Color(1, 1, 1, 0.9))

	# SERGAP SENYAP: tubuh terseret sulur (gemetar, tenggelam hijau,
	# gumpalan daun mengerubut) — "membunuh dalam diam", tanpa teks
	if not pemangkas.hidup:
		var q = clamp(pemangkas.mati_t / 0.9, 0.0, 1.0)
		if q < 1.0:
			var hijau = Color(1, 1, 1).lerp(Color(0.45, 0.75, 0.4), q)
			hijau.a = 1.0 - q * 0.25
			if _tex_mati != null:
				# STRIP ROBOH (falling-back-death, koreksi pemilik:
				# kematian harus terbaca): diputar sekali sepanjang
				# sergapan, dicermin hadap, makin hijau ditelan jaringan
				var n_m = max(1, _tex_mati.get_width() / 48)
				var fr_m = int(clamp(q * n_m, 0.0, n_m - 1.0))
				draw_set_transform(p, 0.0, Vector2(pemangkas.arah, 1.0))
				draw_texture_rect_region(_tex_mati,
						Rect2(Vector2(-24.0, -24.0), Vector2(48.0, 48.0)),
						Rect2(fr_m * 48.0, 0.0, 48.0, 48.0), hijau)
				draw_set_transform_matrix(Transform2D())
			else:
				var tex_m = _tex_diam if _tex_diam != null else _tex_jalan
				var goyang = sin(pemangkas.mati_t * 42.0) * 2.5 * (1.0 - q)
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
		var berdiri = pemangkas.state == pemangkas.IDLE \
				or pemangkas.state == pemangkas.SELIDIK \
				or pemangkas.kaget > 0.0
		var n = max(1, tex.get_width() / 48)
		var fr = int(_t * 3.0) % n if berdiri else int(_t * 8.0) % n
		# KAGET: badan tersentak bergetar sesaat sebelum kejaran mulai
		var getar = Vector2(sin(_t * 55.0) * 1.8, 0.0) \
				if pemangkas.kaget > 0.0 else Vector2.ZERO
		draw_set_transform(p + getar, 0.0, Vector2(pemangkas.arah, 1.0))
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

	# IKON KESADARAN (PixelLab seed 1705/1706): ! merah = sadar &
	# memburu, ? amber = curiga & menyelidik — pop membesar sekejap
	# (bahasa stealth klasik) lalu mengambang pelan di atas kepala
	var tex_i = null
	if _icon == "seru":
		tex_i = _tex_seru
	elif _icon == "tanya":
		tex_i = _tex_tanya
	if tex_i != null:
		var s_i = 1.0
		if _icon_t < 0.22:
			s_i = lerpf(0.35, 1.3, _icon_t / 0.22)
		elif _icon_t < 0.38:
			s_i = lerpf(1.3, 1.0, (_icon_t - 0.22) / 0.16)
		var apung = sin(_t * 3.5) * 1.5 if _icon_t > 0.38 else 0.0
		# 18 px (koreksi pemilik: 13 px kurang terlihat di zoom kamera)
		var d_i = 18.0 * s_i
		draw_texture_rect(tex_i,
				Rect2(p.x - d_i * 0.5, p.y - 37.0 - d_i * 0.5 + apung,
				d_i, d_i), false)
