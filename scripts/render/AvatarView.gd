extends Node2D

# Tampilan avatar (P3.75, docs/13 §3.2) — kepala sulur dengan EKOR TENDRIL
# yang mengikuti jejak gerakan: tubuhnya tanaman yang mengalir, bukan bola
# yang melayang. Prosedural dulu; sprite PixelLab menunggu bentuknya
# terbukti enak (pertanyaan terbuka docs/13 §10).
#
# Bahasa gerak:
#   - ekor: antrean posisi kepala beberapa frame terakhir, digambar sebagai
#     ruas mengecil — otomatis meliuk mengikuti belokan
#   - squash & stretch: memanjang saat melesat/melompat, memipih sesaat
#     saat mendarat
#   - daun kecil di ruas ekor mengibas makin cepat saat bergerak cepat

var avatar
var _t = 0.0
var _ekor = []             # posisi dunia (px) ruas-ruas ekor
var _di_tanah_lalu = false
var _darat_t = 0.0         # sisa waktu pipih pendaratan
var _tahap_tex = []        # sprite per fase — CADANGAN kalau strip tak ada
var _tumbuh_tex = null     # strip pertumbuhan 16+ frame (papan acuan user)
var _tumbuh_n = 1
var _ukuran_halus = 0.85   # skala badan yang MENGEJAR ukuran() — anti patah
var _frak_halus = 0.0      # kemajuan frame yang MENGEJAR tumbuh_frak()
var _meta_t = 0.0          # sisa animasi mekar metamorfosis
var _tahap_lalu = 1


func _init(a):
	avatar = a
	visible = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# strip pertumbuhan kontinu — frame dipilih dari tumbuh_frak(), jadi
	# sang bibit MENJADI perambat frame demi frame, bukan tukar wujud kasar
	if ResourceLoader.exists("res://aset/avatar_tumbuh.png"):
		_tumbuh_tex = load("res://aset/avatar_tumbuh.png")
		_tumbuh_n = max(1, _tumbuh_tex.get_width() / 48)
	for n in range(1, 7):
		var jalur = "res://aset/avatar_tahap%d.png" % n
		_tahap_tex.append(load(jalur) if ResourceLoader.exists(jalur)
				else null)


func _process(delta):
	_t += delta
	if not visible:
		return

	# ekor mengejar kepala: tiap ruas mengejar ruas di depannya — gerak
	# ular yang halus tanpa fisika apa pun
	var kepala = avatar.pos * float(Config.PPU) \
			+ Vector2(0.0, -Config.AVATAR_TINGGI * float(Config.PPU) * 0.5)
	if _ekor.is_empty() or _ekor[0].distance_to(kepala) > 200.0:
		# teleport (layu/masuk gedung): ekor menyusul seketika, jangan
		# meninggalkan coretan melintasi peta
		_ekor = []
		for i in range(6):
			_ekor.append(kepala)
	_ekor[0] = _ekor[0].lerp(kepala, clamp(delta * 22.0, 0.0, 1.0))
	for i in range(1, _ekor.size()):
		_ekor[i] = _ekor[i].lerp(_ekor[i - 1], clamp(delta * 14.0, 0.0, 1.0))

	# deteksi pendaratan untuk squash
	if avatar.di_tanah and not _di_tanah_lalu:
		_darat_t = 0.18
	_di_tanah_lalu = avatar.di_tanah
	_darat_t = max(0.0, _darat_t - delta)

	# ukuran & frame tumbuh mengejar target kontinu dengan lembut
	_ukuran_halus = lerpf(_ukuran_halus, avatar.ukuran(),
			clamp(delta * 3.0, 0.0, 1.0))
	_frak_halus = lerpf(_frak_halus, avatar.tumbuh_frak(),
			clamp(delta * 2.0, 0.0, 1.0))
	# metamorfosis: mainkan mekar saat tahap berganti
	if avatar.tahap != _tahap_lalu:
		_tahap_lalu = avatar.tahap
		_meta_t = 0.6
	_meta_t = max(0.0, _meta_t - delta)

	queue_redraw()


func _draw():
	var ppu = float(Config.PPU)
	var p = avatar.pos * ppu + Vector2(0.0, -Config.AVATAR_TINGGI * ppu * 0.5)
	var denyut = 1.0 + sin(_t * 5.0) * 0.10
	var laju = avatar.vel.length()

	# sedang mengisi dari sumber (P3): cincin mengembang — "minum"
	if avatar.mengisi:
		var isi_c = Config.C_TIP
		isi_c.a = 0.35 * (1.0 - fmod(_t, 0.8) / 0.8)
		draw_arc(p, 10.0 + fmod(_t, 0.8) * 14.0, 0.0, TAU, 24, isi_c, 2.0)

	if avatar.moda == avatar.MERAMBAT:
		var cincin = Config.C_TIP
		cincin.a = 0.22
		draw_circle(p, 13.0 * denyut, cincin)

	# --- ekor tendril (mulai fase TUNAS — bibit belum berekor) --------------
	if avatar.tahap >= 2:
		var gelap = Config.C_LEAF.darkened(0.30)
		for i in range(_ekor.size() - 1, 0, -1):
			var f = 1.0 - float(i) / _ekor.size()
			draw_line(_ekor[i], _ekor[i - 1], Config.C_BRANCH, 2.0 + 2.0 * f)
			if i % 2 == 0:
				var kibas = sin(_t * (4.0 + laju * 0.15) + i * 1.7) * 0.35
				var sisi = Vector2(0, -1).rotated(kibas) \
						* (3.0 + 2.0 * f)
				draw_circle(_ekor[i] + sisi, 2.0 + 1.5 * f, gelap)

	# --- tubuh: sprite fase PixelLab (P3.9) + squash & stretch --------------
	var skala = Vector2.ONE
	if _darat_t > 0.0:
		var q = _darat_t / 0.18
		skala = Vector2(1.0 + 0.35 * q, 1.0 - 0.30 * q)   # pipih mendarat
	elif avatar.moda == avatar.LEPAS and absf(avatar.vel.y) > 20.0:
		var s = clamp(absf(avatar.vel.y) / 90.0, 0.0, 0.35)
		skala = Vector2(1.0 - s * 0.6, 1.0 + s)           # memanjang di udara
	# ukuran KONTINU dari jaringan yang ditumbuhkan — badan membesar mulus,
	# tahap hanya mengganti wujud (P3.9, anti patah-patah)
	skala *= _ukuran_halus * (1.0 + (denyut - 1.0) * 0.4)
	# mekar metamorfosis: pantulan skala sesaat + cincin di bawah
	if _meta_t > 0.0:
		var q = 1.0 - _meta_t / 0.6
		skala *= 1.0 + 0.28 * sin(q * PI)
		var cincin_m = Config.C_TIP
		cincin_m.a = 0.5 * (1.0 - q)
		draw_arc(p, 8.0 + q * 30.0, 0.0, TAU, 28, cincin_m, 3.0)
		draw_arc(p, 4.0 + q * 44.0, 0.0, TAU, 28,
				Color(cincin_m.r, cincin_m.g, cincin_m.b, cincin_m.a * 0.5),
				2.0)
	var miring = clamp(-avatar.vel.x * 0.004, -0.4, 0.4)
	# hadap kiri = cermin sprite
	draw_set_transform(p, miring, Vector2(skala.x * avatar.hadap, skala.y))

	if _tumbuh_tex != null:
		# strip pertumbuhan: frame dari kemajuan tumbuh yang dihaluskan
		var fr = int(round(_frak_halus * float(_tumbuh_n - 1)))
		draw_texture_rect_region(_tumbuh_tex,
				Rect2(Vector2(-24.0, -28.0), Vector2(48.0, 48.0)),
				Rect2(fr * 48.0, 0.0, 48.0, 48.0))
	elif _tahap_tex[avatar.tahap - 1] != null:
		draw_texture(_tahap_tex[avatar.tahap - 1], Vector2(-24.0, -28.0))
	else:
		# cadangan prosedural kalau sprite belum ada
		draw_circle(Vector2.ZERO, 8.0, Config.C_LEAF.darkened(0.25))
		draw_circle(Vector2(-1.0, -1.0), 6.0, Config.C_LEAF)
		draw_circle(Vector2(-2.0, -2.0), 3.0 * denyut, Config.C_TIP)
	draw_set_transform_matrix(Transform2D())

	# bar energi
	var w = 26.0
	var atas = p + Vector2(-w * 0.5, -22.0)
	draw_rect(Rect2(atas, Vector2(w, 4.0)), Color(0.1, 0.1, 0.1, 0.6))
	var isi = clamp(avatar.energi / avatar.energi_max, 0.0, 1.0)
	var c = Config.C_TIP if isi > 0.3 else Config.C_ALERT
	draw_rect(Rect2(atas, Vector2(w * isi, 4.0)), c)
