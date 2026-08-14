extends Node2D

# HUD minimal GDD §31: ENERGI (bar 10 sel) / MODA / VISIBILITAS.
# Ability [Q]/[E] SENGAJA belum — jatah Phase 7 (GDD §42: jangan lompat).
#
# Prinsip §31 "saat tidak diperlukan, UI dapat menghilang": HUD memudar
# ke bayang samar setelah beberapa detik keadaan nominal (energi sehat,
# TERSEMBUNYI, tanpa waspada) dan bangun seketika begitu ada yang
# berubah. Warna status ikut CDD §7: kuning = terdeteksi / energi
# rendah; hijau = sehat. Teks hanya di HUD — dunia tetap tanpa teks
# (SRD §23).
#
# Ditambah dua bahasa UX yang sebelumnya bisu:
#   - VISIBILITAS "WASPADA": sensor masih mengunci — jaringan menolak
#     memulihkan (menjawab "kenapa energiku tidak naik?");
#   - kedip gelap singkat saat LAYU (konsumen event avatar.layu_baru —
#     tanpa ini perpindahan ke simpul terasa teleport tanpa sebab).

const C_LATAR   = Color("0B0E12")
const C_LABEL   = Color("59636F")
const C_SEHAT   = Color("A8D94A")
const C_REDUP   = Color("4F8F32")
const C_KUNING  = Color("D89A3C")
const C_KOSONG  = Color("232B36")

var avatar
var _t = 0.0
var _alpha = 1.0          # pudar §31 — target 1 saat penting
var _tenang = 0.0         # lama keadaan nominal berturut-turut
var _moda_lalu = -1
var _energi_lalu = -1.0
var _tempel_lalu = false  # tepi bisa_tempel — bangunkan HUD untuk petunjuk
var _layu_flash = 0.0     # sisa kedip gelap layu

var _font
var _tex_panel                 # aset/hud PixelLab (permintaan pemilik):
var _tex_bar                   # bar penuh (fill hijau generatan)
var _tex_bar_kosong            # bar palung kosong — fill di-clip energi

# palung bar di tekstur (hasil kalibrasi proses_hud): x7..185, y38..49
const PALUNG_X = 7.0
const PALUNG_W = 179.0
const PALUNG_Y = 38.0
const PALUNG_H = 12.0


func _init(a):
	avatar = a
	_font = ThemeDB.fallback_font
	for info in [["panel", "_tex_panel"], ["bar_energi", "_tex_bar"],
			["bar_energi_kosong", "_tex_bar_kosong"]]:
		var jalur = "res://aset/hud/%s.png" % info[0]
		if ResourceLoader.exists(jalur):
			set(info[1], load(jalur))


func _process(delta):
	_t += delta

	# konsumsi event layu (sekali-baca)
	if avatar.layu_baru:
		avatar.layu_baru = false
		_layu_flash = 0.9
	_layu_flash = max(0.0, _layu_flash - delta)

	# §31: penting = ada yang berubah / keadaan tidak nominal
	var isi = avatar.energi / avatar.energi_max
	var nominal = isi > 0.9 and not avatar.terdeteksi and not avatar.curiga \
			and not avatar.regen_mati and not avatar.mengisi \
			and _layu_flash <= 0.0 and avatar.tumbuh_tolak <= 0.0
	if avatar.moda != _moda_lalu or abs(isi - _energi_lalu) > 0.1 \
			or (avatar.bisa_tempel and not _tempel_lalu):
		_tenang = 0.0
		_moda_lalu = avatar.moda
		_energi_lalu = isi
	_tempel_lalu = avatar.bisa_tempel
	_tenang = _tenang + delta if nominal else 0.0
	var target = 0.14 if _tenang > 3.0 else 1.0
	_alpha = lerpf(_alpha, target, clamp(delta * 6.0, 0.0, 1.0))

	queue_redraw()


func _draw():
	# kedip gelap layu — di atas segalanya, memudar cepat
	if _layu_flash > 0.0:
		var gelap = C_LATAR
		gelap.a = 0.85 * (_layu_flash / 0.9)
		draw_rect(get_viewport_rect(), gelap)

	var a = _alpha
	var x = 16.0
	var y = 16.0

	# panel PixelLab (aset/hud, permintaan pemilik); fallback prosedural
	if _tex_panel:
		draw_texture(_tex_panel, Vector2(x, y), Color(1, 1, 1, a))
	else:
		var latar = C_LATAR
		latar.a = 0.55 * a
		draw_rect(Rect2(x, y, 283.0, 143.0), latar)
	# padding kiri interior pelat (playtest pemilik: teks terlalu mepet
	# tepi — bingkai sulur butuh ruang napas)
	var ix = x + 48.0

	# --- MODA lalu VISIBILITAS BERTUMPUK (permintaan pemilik: teks
	# tidak boleh melewati pelat panel) ---------------------------------
	_label(ix, y + 32.0, "MODA", a)
	var moda_txt = "MERAMBAT" if avatar.moda == avatar.MERAMBAT else "LEPAS"
	_nilai(ix, y + 52.0, moda_txt, C_SEHAT, a)

	_label(ix, y + 76.0, "VISIBILITAS", a)
	var txt = "TERSEMBUNYI"
	var c3 = C_REDUP
	if avatar.terdeteksi:
		txt = "TERDETEKSI"
		c3 = C_KUNING
		c3.a = 0.7 + 0.3 * sin(_t * 12.0)
	elif avatar.regen_mati:
		txt = "WASPADA"
		c3 = C_KUNING
	elif avatar.curiga:
		txt = "TERSAMAR"
		c3 = C_KUNING
		c3.a = 0.6
	_nilai(ix, y + 96.0, txt, c3, a)

	# --- petunjuk tombol kontekstual (jawaban "memencet apa?") --------
	if avatar.tumbuh_tolak > 0.0:
		# RK-2 [A]: kenapa tidak bisa tumbuh — beton menolak (GDD §12)
		var kelabu = C_LABEL
		kelabu.a = 1.0
		_label(ix, y + 118.0, "BETON MENOLAK TUMBUH", a)
	elif avatar.moda == avatar.MERAMBAT:
		_label(ix, y + 118.0, "[SPASI] LEPAS   [ESC] JEDA", a)
	elif avatar.bisa_tempel:
		_label(ix, y + 118.0, "[W/S] MERAMBAT   [ESC] JEDA", a)
	else:
		_label(ix, y + 118.0, "[ESC] JEDA", a)

	# --- ENERGI: bingkai bar PixelLab, fill hijau generatan di-clip ---
	var by = y + 146.0
	var isi = clamp(avatar.energi / avatar.energi_max, 0.0, 1.0)
	if _tex_bar and _tex_bar_kosong:
		draw_texture(_tex_bar_kosong, Vector2(x, by), Color(1, 1, 1, a))
		var lebar_src = PALUNG_X + PALUNG_W * isi
		var mod = Color(1, 1, 1, a)
		if avatar.terdeteksi:
			mod = Color(1.0, 0.85, 0.4, (0.7 + 0.3 * sin(_t * 12.0)) * a)
		elif isi <= 0.3:
			mod = Color(1.0, 0.7, 0.3, a)   # kuning CDD §7: energi rendah
		draw_texture_rect_region(_tex_bar,
				Rect2(x, by, lebar_src, _tex_bar.get_height()),
				Rect2(0.0, 0.0, lebar_src, _tex_bar.get_height()), mod)
		# takik 10 segmen (mock §31) di atas palung
		var takik = C_LATAR
		takik.a = 0.65 * a
		for k in range(1, 10):
			draw_rect(Rect2(x + PALUNG_X + PALUNG_W * k / 10.0,
					by + PALUNG_Y, 2.0, PALUNG_H), takik)
		_label(x + 36.0, by + 34.0, "ENERGI", a)
		# jaringan menolak memulihkan: bingkai kuning di sekitar palung
		if avatar.regen_mati:
			var kunci = C_KUNING
			kunci.a = (0.5 + 0.3 * sin(_t * 7.0)) * a
			draw_rect(Rect2(x + PALUNG_X - 3.0, by + PALUNG_Y - 3.0,
					PALUNG_W + 6.0, PALUNG_H + 6.0), kunci, false, 2.0)
	else:
		var sel_isi = int(round(isi * 10.0))
		var warna = C_SEHAT if isi > 0.3 else C_KUNING
		for s in range(10):
			var c = warna if s < sel_isi else C_KOSONG
			c.a = c.a * a
			draw_rect(Rect2(x + s * 24.0, by, 20.0, 14.0), c)


func _label(x, y, teks, a):
	var c = C_LABEL
	c.a = c.a * a
	draw_string(_font, Vector2(x, y), teks,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, c)


func _nilai(x, y, teks, warna, a):
	# 19 px: "TERSEMBUNYI" harus muat di kolom kanan interior panel
	# (playtest pemilik: 24 px meluber keluar bingkai)
	var bayang = C_LATAR
	bayang.a = 0.8 * a
	draw_string(_font, Vector2(x + 2.0, y + 2.0), teks,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 19, bayang)
	var c = warna
	c.a = c.a * a
	draw_string(_font, Vector2(x, y), teks,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 19, c)
