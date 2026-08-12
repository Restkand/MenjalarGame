extends CanvasLayer

# HUD anatomi dua pita (docs/08 §3): pita ATAS = sumber daya + kalender,
# pita BAWAH = babak + bar tutupan per zona. Kanvas hidup DI ANTARA
# keduanya — tidak ada satu pun elemen HUD mengambang di wilayah kanvas.
# Satu-satunya yang boleh menimpa tepi kanvas: band pesan sementara tepat
# di bawah pita atas (pola "pita inspeksi" dari ui_kit).
#
# Aturan warna antarmuka (docs/08 §8.3): sorotan C_TIP hanya untuk SATU hal
# yang paling perlu diperhatikan — leher botol min(Air, Cahaya) disorot
# bingkai + warna angka, zona yang dijadwalkan dirawat disorot bingkai bar.
# Bar perhatian memakai warna JENDELA, bukan merah: palet tidak punya warna
# panik, dan itu disengaja.

signal play_pressed

const LATAR = Color(0.085, 0.095, 0.09)
const REDUP = Color(0.55, 0.58, 0.6)
const BAR_BG = Color(0.11, 0.11, 0.13)

var _overlay
var _btn
var _msg = ""
var _msg_t = 0.0

var _kartu
var _kartu_judul
var _kartu_isi

# pita atas
var _air_lbl
var _air_style
var _cahaya_lbl
var _cahaya_style
var _e_fill
var _lbl_laju      # laju energi "+N/dtk" — mengajarkan min() lewat angka
var _p_fill
var _lbl_tren      # panah tren perhatian
var _lbl_kalender
var _p_prev = 0.0
var _p_akum = 0.0
var _p_delta = 0.0

# band pesan
var _band
var _band_lbl

# pita bawah
var _lbl_babak
var _zona_fill = []
var _zona_style = []
var _c_fill        # bar kemajuan babak (babak I & III)
var _c_bar_bg


func _ready():
	layer = 20
	_pita_atas()
	_band_pesan()
	_pita_bawah()
	_build_overlay()
	_build_kartu()


# ---------------------------------------------------------------------------
# Pita atas — kiri ke kanan: air, cahaya, energi, perhatian, lalu kalender
# di ujung kanan (docs/08 §3.1-3.2)
# ---------------------------------------------------------------------------

func _pita_atas():
	var bg = ColorRect.new()
	bg.color = LATAR
	bg.position = Vector2(0, 0)
	bg.size = Vector2(1920, Config.HUD_ATAS)
	add_child(bg)

	var hb = HBoxContainer.new()
	hb.position = Vector2(12, 0)
	hb.size = Vector2(1896, Config.HUD_ATAS)
	hb.add_theme_constant_override("separation", 18)
	add_child(hb)

	var air = _kotak_sumber("ikon_air")
	_air_lbl = air.lbl
	_air_style = air.style
	hb.add_child(air.panel)

	var cahaya = _kotak_sumber("ikon_cahaya")
	_cahaya_lbl = cahaya.lbl
	_cahaya_style = cahaya.style
	hb.add_child(cahaya.panel)

	_ikon(hb, "ikon_energi")
	_e_fill = _bar(hb, Config.C_LEAF, 220.0)
	# laju pemasukan energi, angka hidup — sebab-akibat min(Air, Cahaya)
	# terlihat langsung: air 1 membuat laju anjlok walau cahaya 84
	_lbl_laju = Label.new()
	_lbl_laju.add_theme_font_size_override("font_size", 13)
	_lbl_laju.add_theme_color_override("font_color", REDUP)
	_lbl_laju.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(_lbl_laju)

	_ikon(hb, "ikon_perhatian")
	_p_fill = _bar(hb, Config.C_WINDOW, 220.0, Config.AMBANG_RAWAT)
	_lbl_tren = Label.new()
	_lbl_tren.add_theme_font_size_override("font_size", 15)
	_lbl_tren.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(_lbl_tren)

	var isi = Control.new()
	isi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(isi)

	_ikon(hb, "ikon_kalender")
	_lbl_kalender = Label.new()
	_lbl_kalender.add_theme_font_size_override("font_size", 13)
	_lbl_kalender.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(_lbl_kalender)


# Ikon + angka dengan BINGKAI yang bisa disorot — penanda leher botol.
# Antara Air dan Cahaya, yang lebih kecil diberi bingkai & angka C_TIP:
# satu-satunya cara aturan min() diajarkan tanpa teks (docs/08 §3.1).
func _kotak_sumber(ikon):
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_border_width_all(1)
	style.border_color = Color(0, 0, 0, 0)
	style.set_content_margin_all(4)

	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)

	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	panel.add_child(hb)

	_ikon(hb, ikon)
	var lbl = Label.new()
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(lbl)

	return {"panel": panel, "lbl": lbl, "style": style}


func _ikon(induk, nama):
	var t = TextureRect.new()
	t.texture = load("res://aset/%s.png" % nama)
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.custom_minimum_size = Vector2(32, 32)
	induk.add_child(t)
	return t


func _bar(induk, col, lebar, ambang = -1.0):
	var tengah = CenterContainer.new()
	induk.add_child(tengah)

	var bg = ColorRect.new()
	bg.color = BAR_BG
	bg.custom_minimum_size = Vector2(lebar, 12)
	tengah.add_child(bg)

	var f = ColorRect.new()
	f.color = col
	f.size = Vector2(0, 12)
	bg.add_child(f)

	if ambang > 0.0:
		var garis = ColorRect.new()
		garis.color = Config.C_TIP
		garis.position = Vector2(lebar * ambang, 0)
		garis.size = Vector2(2, 12)
		bg.add_child(garis)
	return f


# ---------------------------------------------------------------------------
# Band pesan — pita sementara di bawah pita atas. Flash ("Regu memangkas!")
# dan pengumuman akhir permainan; sembunyi saat tidak ada apa-apa.
# ---------------------------------------------------------------------------

func _band_pesan():
	_band = ColorRect.new()
	_band.color = Color(LATAR.r, LATAR.g, LATAR.b, 0.92)
	_band.position = Vector2(0, Config.HUD_ATAS)
	_band.size = Vector2(1920, 30)
	_band.visible = false
	add_child(_band)

	_band_lbl = Label.new()
	_band_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_band_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_band_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_band_lbl.add_theme_font_size_override("font_size", 15)
	_band_lbl.add_theme_color_override("font_color", Config.C_TIP)
	_band.add_child(_band_lbl)


# ---------------------------------------------------------------------------
# Pita bawah — babak berjalan di kiri, empat bar zona di kanan (docs/08 §3.3)
# ---------------------------------------------------------------------------

func _pita_bawah():
	var y = 1080 - Config.HUD_BAWAH
	var bg = ColorRect.new()
	bg.color = LATAR
	bg.position = Vector2(0, y)
	bg.size = Vector2(1920, Config.HUD_BAWAH)
	add_child(bg)

	var hb = HBoxContainer.new()
	hb.position = Vector2(12, y)
	hb.size = Vector2(1896, Config.HUD_BAWAH)
	hb.add_theme_constant_override("separation", 14)
	add_child(hb)

	_lbl_babak = Label.new()
	_lbl_babak.add_theme_font_size_override("font_size", 14)
	_lbl_babak.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_babak.custom_minimum_size = Vector2(430, 0)
	hb.add_child(_lbl_babak)

	# bar kemajuan babak — dipakai babak I (dua syarat) dan III (pohon)
	_c_fill = _bar(hb, Config.C_LEAF, 180.0)
	_c_bar_bg = _c_fill.get_parent()

	var isi = Control.new()
	isi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(isi)

	# empat bar zona: target ZONA_TARGET ditandai garis; zona yang
	# dijadwalkan dirawat diberi bingkai sorot
	_zona_fill = []
	_zona_style = []
	var singkat = ["BA", "TA", "BB", "TB"]
	for i in range(4):
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		style.set_border_width_all(1)
		style.border_color = Color(0, 0, 0, 0)
		style.set_content_margin_all(4)
		var panel = PanelContainer.new()
		panel.add_theme_stylebox_override("panel", style)
		var zh = HBoxContainer.new()
		zh.add_theme_constant_override("separation", 6)
		panel.add_child(zh)
		var lbl = Label.new()
		lbl.text = singkat[i]
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", REDUP)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		zh.add_child(lbl)
		_zona_fill.append(_bar(zh, Config.C_LEAF, 190.0, Config.ZONA_TARGET))
		_zona_style.append(style)
		hb.add_child(panel)


# ---------------------------------------------------------------------------
# Kartu pergantian fase — permainan jeda sejenak, kartu mengumumkan keadaan.
# Inilah pengajar utama game ini: sistem perhatian dijelaskan TEPAT saat
# relevan (saat inspeksi, saat regu datang), bukan lewat tembok teks.
# ---------------------------------------------------------------------------

func _build_kartu():
	_kartu = Control.new()
	_kartu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_kartu.visible = false
	add_child(_kartu)

	var dim = ColorRect.new()
	dim.color = Color(0.05, 0.06, 0.05, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_kartu.add_child(dim)

	var tengah = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	_kartu.add_child(tengah)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	tengah.add_child(vb)

	_kartu_judul = Label.new()
	_kartu_judul.add_theme_font_size_override("font_size", 52)
	_kartu_judul.add_theme_color_override("font_color", Config.C_TIP)
	_kartu_judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_kartu_judul)

	_kartu_isi = Label.new()
	_kartu_isi.add_theme_font_size_override("font_size", 20)
	_kartu_isi.add_theme_color_override("font_color", Config.C_WINDOW)
	_kartu_isi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_kartu_isi)

	var lewati = Label.new()
	lewati.text = "klik untuk lanjut"
	lewati.add_theme_font_size_override("font_size", 12)
	lewati.add_theme_color_override("font_color", Color(0.5, 0.53, 0.55))
	lewati.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(lewati)


func tampil_kartu(judul, isi):
	_kartu_judul.text = judul
	_kartu_isi.text = isi
	_kartu.modulate = Color(1, 1, 1, 1)
	_kartu.visible = true


func kartu_pudar(sisa):
	# setengah detik terakhir memudar keluar
	if sisa < 0.5:
		_kartu.modulate = Color(1, 1, 1, sisa / 0.5)


func sembunyikan_kartu():
	_kartu.visible = false


# ---------------------------------------------------------------------------
# Layar judul — latar pekat, judul, tagline, MULAI, satu baris kontrol.
# ---------------------------------------------------------------------------

func _build_overlay():
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	var latar = ColorRect.new()
	latar.color = Color(0.10, 0.11, 0.10)
	latar.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(latar)

	var tengah = CenterContainer.new()
	tengah.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(tengah)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	tengah.add_child(vb)

	var judul = Label.new()
	judul.text = "MENJALAR"
	judul.add_theme_font_size_override("font_size", 84)
	judul.add_theme_color_override("font_color", Config.C_LEAF)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(judul)

	var tagline = Label.new()
	tagline.text = "tumbuh pelan-pelan, hijaukan kotanya"
	tagline.add_theme_color_override("font_color", Config.C_WINDOW)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(tagline)

	var jarak = Control.new()
	jarak.custom_minimum_size = Vector2(0, 36)
	vb.add_child(jarak)

	_btn = Button.new()
	_btn.text = "  MULAI  "
	_btn.custom_minimum_size = Vector2(220, 52)
	_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_btn.focus_mode = Control.FOCUS_NONE
	_btn.pressed.connect(_on_play)
	vb.add_child(_btn)

	var jarak2 = Control.new()
	jarak2.custom_minimum_size = Vector2(0, 28)
	vb.add_child(jarak2)

	var kontrol = Label.new()
	kontrol.text = "klik kiri  arahkan        klik kanan  bercabang        X  putus sulur\nklik akar di beton  menembus        WASD  geser        roda  zoom        Tab  panel"
	kontrol.add_theme_color_override("font_color", Color(0.48, 0.51, 0.54))
	kontrol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(kontrol)


func _on_play():
	_overlay.visible = false
	play_pressed.emit()


func show_overlay():
	_overlay.visible = true


func flash_msg(text):
	_msg = text
	_msg_t = 2.6


# ---------------------------------------------------------------------------
# Refresh per frame
# ---------------------------------------------------------------------------

func refresh(sim, w, world, crew, climbers, babak):
	# --- pita atas: sumber daya + leher botol -------------------------------
	_air_lbl.text = str(int(sim.water))
	_cahaya_lbl.text = str(int(sim.light))
	var air_seret = sim.water < sim.light
	_sorot(_air_style, _air_lbl, air_seret)
	_sorot(_cahaya_style, _cahaya_lbl, sim.light < sim.water)

	_e_fill.size = Vector2(220.0 * clamp(sim.energy / Config.ENERGY_MAX,
			0.0, 1.0), 12)
	_e_fill.color = Config.C_ALERT if sim.starved else Config.C_LEAF

	# laju energi hanya mengalir SIANG hari, dari sisi yang lebih kecil
	if w.phase == Config.PHASE_DAY:
		_lbl_laju.text = "+%d/dtk" \
				% int(round(min(sim.water, sim.light) * Config.ENERGY_RATE))
	else:
		_lbl_laju.text = "malam +0"

	_p_fill.size = Vector2(220.0 * clamp(w.perhatian, 0.0, 1.0), 12)

	# tren perhatian, dicuplik tiap 0,7 detik supaya panahnya tenang
	_p_akum += get_process_delta_time()
	if _p_akum >= 0.7:
		_p_delta = w.perhatian - _p_prev
		_p_prev = w.perhatian
		_p_akum = 0.0
	if _p_delta > 0.003:
		_lbl_tren.text = "▲"
		_lbl_tren.add_theme_color_override("font_color", Config.C_WARN)
	elif _p_delta < -0.0005:
		_lbl_tren.text = "▼"
		_lbl_tren.add_theme_color_override("font_color", Config.C_LEAF)
	else:
		_lbl_tren.text = "—"
		_lbl_tren.add_theme_color_override("font_color", REDUP)

	# --- kalender (selalu terlihat, docs/08 §3.2) ---------------------------
	var ph = "SIANG" if w.phase == Config.PHASE_DAY else "MALAM"
	var baris1 = "HARI %d  %s %d%%" % [w.hari, ph, int(w.progress() * 100)]
	if crew.aktif() > 0:
		baris1 += "   REGU %d" % crew.aktif()
	if climbers.aktif() > 0:
		baris1 += "   PEMANJAT %d" % climbers.aktif()
	var baris2
	if w.inspeksi_dalam() == 0:
		baris2 = "INSPEKSI HARI INI"
	else:
		baris2 = "INSPEKSI %d HARI" % w.inspeksi_dalam()
	if w.rawat_hari >= 0:
		if w.hari == w.rawat_hari:
			baris2 += "   RAWAT HARI INI — %s" % w.rawat_zona
		else:
			baris2 += "   RAWAT H%d %s" % [w.rawat_hari, w.rawat_zona]
		_lbl_kalender.modulate = Config.C_WARN
	else:
		_lbl_kalender.modulate = Color(1, 1, 1)
	_lbl_kalender.text = baris1 + "\n" + baris2

	# --- pita bawah: babak + zona -------------------------------------------
	match babak.babak:
		1:
			_lbl_babak.text = "BABAK I  MENYUSUP — jangkau akuifer, sentuh fasad"
			var maju = 0.0
			if sim.dekat_akuifer:
				maju += 0.5
			if world.tutupan() >= Config.BABAK1_PIJAK:
				maju += 0.5
			_c_fill.size = Vector2(180.0 * maju, 12)
			_c_bar_bg.get_parent().visible = true
		2:
			_lbl_babak.text = "BABAK II  MENGHIJAUKAN — tiap zona %d%%" \
					% int(round(Config.ZONA_TARGET * 100))
			_c_bar_bg.get_parent().visible = false
		3:
			_lbl_babak.text = "BABAK III  MENETAP — pohon %d dari %d" % [
				sim.trees.size(), int(Config.BABAK3_POHON)]
			_c_fill.size = Vector2(180.0 * clamp(float(sim.trees.size())
					/ float(Config.BABAK3_POHON), 0.0, 1.0), 12)
			_c_bar_bg.get_parent().visible = true

	for i in range(4):
		_zona_fill[i].size = Vector2(190.0 * clamp(world.zona_tutupan(i),
				0.0, 1.0), 12)
		var dirawat = w.rawat_hari >= 0 and w.rawat_zona_idx == i
		_zona_style[i].border_color = Config.C_WARN if dirawat \
				else Color(0, 0, 0, 0)

	# --- band pesan ---------------------------------------------------------
	_msg_t = max(0.0, _msg_t - get_process_delta_time())
	if babak.menang:
		_band_lbl.text = "KOTA MENGHIJAU — pohon-pohonnya tinggal   (R untuk ulang)"
		_band.visible = true
	elif babak.kalah:
		_band_lbl.text = "SELURUH TANAMAN MATI   (R untuk ulang)"
		_band.visible = true
	elif _msg_t > 0.0:
		_band_lbl.text = _msg
		_band.visible = true
	else:
		_band.visible = false


# Penanda leher botol: bingkai + angka C_TIP pada sisi yang lebih kecil.
func _sorot(style, lbl, aktif):
	if aktif:
		style.border_color = Config.C_TIP
		lbl.add_theme_color_override("font_color", Config.C_TIP)
	else:
		style.border_color = Color(0, 0, 0, 0)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1))
