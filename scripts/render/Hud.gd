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
var _layu_flash = 0.0     # sisa kedip gelap layu

var _font


func _init(a):
	avatar = a
	_font = ThemeDB.fallback_font


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
			and _layu_flash <= 0.0
	if avatar.moda != _moda_lalu or abs(isi - _energi_lalu) > 0.1:
		_tenang = 0.0
		_moda_lalu = avatar.moda
		_energi_lalu = isi
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
	var x = 28.0
	var y = 30.0

	# panel bayang tipis supaya terbaca di atas scene terang mana pun
	var latar = C_LATAR
	latar.a = 0.55 * a
	draw_rect(Rect2(x - 12.0, y - 12.0, 288.0, 158.0), latar)

	# --- ENERGI: bar 10 sel (mock §31) -------------------------------
	_label(x, y, "ENERGI", a)
	var isi = clamp(avatar.energi / avatar.energi_max, 0.0, 1.0)
	var sel_isi = int(round(isi * 10.0))
	var warna = C_SEHAT if isi > 0.3 else C_KUNING
	if avatar.terdeteksi:
		warna = C_KUNING
		warna.a = 0.7 + 0.3 * sin(_t * 12.0)   # stres: bar ikut berdenyut
	for s in range(10):
		var c = warna if s < sel_isi else C_KOSONG
		c.a = c.a * a
		draw_rect(Rect2(x + s * 24.0, y + 8.0, 20.0, 14.0), c)
	# jaringan menolak memulihkan: bingkai kuning tipis di sekeliling bar
	if avatar.regen_mati:
		var kunci = C_KUNING
		kunci.a = (0.5 + 0.3 * sin(_t * 7.0)) * a
		draw_rect(Rect2(x - 3.0, y + 5.0, 10.0 * 24.0 + 2.0, 20.0),
				kunci, false, 2.0)

	# --- MODA ---------------------------------------------------------
	var y2 = y + 52.0
	_label(x, y2, "MODA", a)
	var moda_txt = "MERAMBAT" if avatar.moda == avatar.MERAMBAT else "LEPAS"
	_nilai(x, y2 + 26.0, moda_txt, C_SEHAT, a)

	# --- VISIBILITAS (tiga state SRD §13 + waspada) -------------------
	var y3 = y2 + 58.0
	_label(x, y3, "VISIBILITAS", a)
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
	_nilai(x, y3 + 26.0, txt, c3, a)


func _label(x, y, teks, a):
	var c = C_LABEL
	c.a = c.a * a
	draw_string(_font, Vector2(x, y), teks,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, c)


func _nilai(x, y, teks, warna, a):
	var bayang = C_LATAR
	bayang.a = 0.8 * a
	draw_string(_font, Vector2(x + 2.0, y + 2.0), teks,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 24, bayang)
	var c = warna
	c.a = c.a * a
	draw_string(_font, Vector2(x, y), teks,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 24, c)
