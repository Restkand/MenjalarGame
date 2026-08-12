extends CanvasLayer

# Catatan Godot 4: properti tata letak Control berganti nama —
# rect_position -> position, rect_size -> size, rect_min_size ->
# custom_minimum_size. Sinyal disambung lewat Callable: btn.pressed.connect(f).

signal play_pressed

var _e_fill
var _c_fill
var _p_fill
var _lbl_phase
var _lbl_energy
var _lbl_res
var _lbl_cov
var _lbl_perhatian
var _lbl_kalender
var _lbl_win
var _overlay
var _btn
var _msg = ""
var _msg_t = 0.0

# kartu pergantian fase — permainan jeda, kartu besar mengumumkan keadaan
var _kartu
var _kartu_judul
var _kartu_isi


# Lebar isi panel HUD. Playtest 11 Agustus: teks babak terpotong di tepi
# kanan — panel dilebarkan, font diperkecil, dan SEMUA teks dinamis wajib
# muat di lebar ini.
const HUD_LEBAR = 300.0


func _ready():
	layer = 20

	var box = PanelContainer.new()
	box.position = Vector2(1596, 12)
	box.custom_minimum_size = Vector2(HUD_LEBAR + 12, 0)
	add_child(box)

	var vb = VBoxContainer.new()
	box.add_child(vb)

	_lbl_phase = _lbl(vb)

	# Kalender — jadwal inspeksi & perawatan, SELALU terlihat. Inilah seluruh
	# sistem peringatan game ini: ancaman diumumkan sebelum tiba (docs/06 §1
	# pilar 2), jadi ia tidak boleh disembunyikan.
	_lbl_kalender = _lbl(vb)

	_lbl_energy = _lbl(vb)
	_e_fill = _bar(vb, Config.C_LEAF)

	_lbl_res = _lbl(vb)

	_lbl_perhatian = _lbl(vb)
	# Bar perhatian memakai warna JENDELA, bukan merah — palet tidak punya
	# warna panik, dan itu disengaja: perhatian naik pelan dan diumumkan
	# lewat kalender (docs/08 §3.1). Garis kecil menandai AMBANG_RAWAT.
	_p_fill = _bar(vb, Config.C_WINDOW, Config.AMBANG_RAWAT)
	# Satu baris redup menjelaskan tuas perhatian. Larangan "nol tips" docs/08
	# dilonggarkan atas permintaan pemilik proyek: sistemnya membingungkan
	# tanpa satu kalimat ini (playtest 11 Agustus).
	var info = _lbl(vb)
	info.text = "naik: tumbuh di terang, jendela, utilitas — turun: waktu, pangkas (X)"
	info.add_theme_font_size_override("font_size", 11)
	info.add_theme_color_override("font_color", Color(0.55, 0.58, 0.6))

	_lbl_cov = _lbl(vb)
	_c_fill = _bar(vb, Config.C_LEAF)

	_lbl_win = Label.new()
	_lbl_win.position = Vector2(830, 420)
	add_child(_lbl_win)

	_build_overlay()
	_build_kartu()


func _lbl(vb):
	var l = Label.new()
	l.add_theme_font_size_override("font_size", 14)
	vb.add_child(l)
	return l


func _bar(vb, col, ambang = -1.0):
	var bg = ColorRect.new()
	bg.color = Color(0.11, 0.11, 0.13)
	bg.custom_minimum_size = Vector2(HUD_LEBAR, 11)
	vb.add_child(bg)

	var f = ColorRect.new()
	f.color = col
	f.size = Vector2(0, 11)
	bg.add_child(f)

	if ambang > 0.0:
		var garis = ColorRect.new()
		garis.color = Config.C_TIP
		garis.position = Vector2(HUD_LEBAR * ambang, 0)
		garis.size = Vector2(2, 11)
		bg.add_child(garis)
	return f


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


# Layar judul — bukan tirai tembus pandang berisi dinding teks.
#
# Dulu overlay MULAI menumpuk sembilan paragraf tutorial di atas dunia yang
# masih terlihat, plus panel tuning yang terbuka — playtest 11 Agustus
# menyebutnya "terlalu ramai". Sekarang: latar pekat (menutup dunia DAN
# panel tuning di layer bawah), judul, satu tagline, tombol MULAI, satu
# baris kontrol. Aturan §6 Konteks berlaku lagi: kalau sebuah gagasan harus
# ditulis di layar, mekaniknya belum bekerja.
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


# set_bake() dihapus di R4 — bake petak selesai seketika, MULAI tidak pernah
# perlu dikunci lagi.


func _on_play():
	_overlay.visible = false
	play_pressed.emit()


func show_overlay():
	_overlay.visible = true


func flash_msg(text):
	_msg = text
	_msg_t = 1.8


func refresh(sim, w, world, crew, climbers, babak):
	var ph = "SIANG" if w.phase == Config.PHASE_DAY else "MALAM"
	_lbl_phase.text = "HARI %d   %s %d%%" % [w.hari, ph,
			int(w.progress() * 100)]
	if crew.aktif() > 0:
		_lbl_phase.text += "   REGU %d" % crew.aktif()
	if climbers.aktif() > 0:
		_lbl_phase.text += "   PEMANJAT %d" % climbers.aktif()
	if w.phase == Config.PHASE_NIGHT and w.progress() > 0.78:
		_lbl_phase.text += "   — FAJAR SEGERA"
		_lbl_phase.modulate = Config.C_WARN
	else:
		_lbl_phase.modulate = Color(1, 1, 1)

	# kalender: baris inspeksi selalu ada; baris perawatan hanya saat ada
	# jadwal, dan disorot — itulah ancaman yang sedang berjalan
	var sisa = w.inspeksi_dalam()
	if sisa == 0:
		_lbl_kalender.text = "INSPEKSI HARI INI"
	else:
		_lbl_kalender.text = "INSPEKSI dalam %d hari" % sisa
	if w.rawat_hari >= 0:
		if w.hari == w.rawat_hari:
			_lbl_kalender.text += "\nPERAWATAN HARI INI — %s" % w.rawat_zona
		else:
			_lbl_kalender.text += "\nPERAWATAN hari %d — %s" \
					% [w.rawat_hari, w.rawat_zona]
		_lbl_kalender.modulate = Config.C_WARN
	else:
		_lbl_kalender.modulate = Color(1, 1, 1)

	_e_fill.size = Vector2(HUD_LEBAR * (sim.energy / Config.ENERGY_MAX), 11)
	_e_fill.color = Config.C_ALERT if sim.starved else Config.C_LEAF
	_lbl_energy.text = "ENERGI  %d" % int(sim.energy)

	_lbl_perhatian.text = "PERHATIAN  %d%%" % int(round(w.perhatian * 100))
	_p_fill.size = Vector2(HUD_LEBAR * clamp(w.perhatian, 0.0, 1.0), 11)

	var bn = sim.bottleneck()
	_lbl_res.text = "AIR %d%s    CAHAYA %d%s" % [
		int(sim.water), " <" if bn == "AIR" else "",
		int(sim.light), " <" if bn == "CAHAYA" else ""]
	if sim.trees.size() > 0:
		_lbl_res.text += "    POHON %d" % sim.trees.size()

	# Baris babak: tujuan saat ini + bar kemajuannya. Babak II mengukur zona
	# TERLEMAH, bukan rata-rata — menumpuk di satu sudut tidak menggerakkan
	# bar-nya.
	match babak.babak:
		1:
			_lbl_cov.text = "BABAK I  MENYUSUP — jangkau akuifer, sentuh fasad"
			var maju = 0.0
			if sim.dekat_akuifer:
				maju += 0.5
			if world.tutupan() >= Config.BABAK1_PIJAK:
				maju += 0.5
			_c_fill.size = Vector2(HUD_LEBAR * maju, 11)
		2:
			_lbl_cov.text = "BABAK II  ZONA  %d%% %d%% %d%% %d%%  target %d%%" % [
				int(round(world.zona_tutupan(0) * 100)),
				int(round(world.zona_tutupan(1) * 100)),
				int(round(world.zona_tutupan(2) * 100)),
				int(round(world.zona_tutupan(3) * 100)),
				int(round(Config.ZONA_TARGET * 100))]
			_c_fill.size = Vector2(HUD_LEBAR * clamp(
					babak.min_zona(world) / Config.ZONA_TARGET, 0.0, 1.0), 11)
		3:
			_lbl_cov.text = "BABAK III  MENETAP — pohon %d dari %d" % [
				sim.trees.size(), int(Config.BABAK3_POHON)]
			_c_fill.size = Vector2(HUD_LEBAR * clamp(float(sim.trees.size())
					/ float(Config.BABAK3_POHON), 0.0, 1.0), 11)

	_msg_t = max(0.0, _msg_t - get_process_delta_time())

	if babak.menang:
		_lbl_win.text = "KOTA MENGHIJAU — pohon-pohonnya tinggal   (R untuk ulang)"
	elif babak.kalah:
		_lbl_win.text = "SELURUH TANAMAN MATI   (R untuk ulang)"
	elif _msg_t > 0.0:
		_lbl_win.text = _msg
	else:
		_lbl_win.text = ""
