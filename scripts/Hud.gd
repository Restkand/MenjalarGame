extends CanvasLayer

# Catatan Godot 4: properti tata letak Control berganti nama —
# rect_position -> position, rect_size -> size, rect_min_size ->
# custom_minimum_size. Sinyal disambung lewat Callable: btn.pressed.connect(f).

signal play_pressed

var _e_fill
var _c_fill
var _lbl_phase
var _lbl_energy
var _lbl_res
var _lbl_cov
var _lbl_win
var _overlay
var _btn
var _msg = ""
var _msg_t = 0.0


func _ready():
	layer = 20

	var box = PanelContainer.new()
	box.position = Vector2(692, 12)
	box.custom_minimum_size = Vector2(256, 0)
	add_child(box)

	var vb = VBoxContainer.new()
	box.add_child(vb)

	_lbl_phase = Label.new()
	vb.add_child(_lbl_phase)

	_lbl_energy = Label.new()
	vb.add_child(_lbl_energy)
	_e_fill = _bar(vb, Config.C_LEAF)

	_lbl_res = Label.new()
	vb.add_child(_lbl_res)

	_lbl_cov = Label.new()
	vb.add_child(_lbl_cov)
	_c_fill = _bar(vb, Config.C_LEAF)

	_lbl_win = Label.new()
	_lbl_win.position = Vector2(330, 250)
	add_child(_lbl_win)

	_build_overlay()


func _bar(vb, col):
	var bg = ColorRect.new()
	bg.color = Color(0.11, 0.11, 0.13)
	bg.custom_minimum_size = Vector2(238, 11)
	vb.add_child(bg)

	var f = ColorRect.new()
	f.color = col
	f.size = Vector2(0, 11)
	bg.add_child(f)
	return f


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
	kontrol.text = "klik kiri  arahkan        klik kanan  bercabang        X  putus sulur\nWASD  geser kamera        roda  zoom        Tab  panel tuning"
	kontrol.add_theme_color_override("font_color", Color(0.48, 0.51, 0.54))
	kontrol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(kontrol)


# Peta cahaya dipanggang dicicil beberapa frame. Tombol MULAI dikunci sampai
# selesai — kalau tidak, permainan bisa dimulai di atas peta cahaya kosong dan
# fotosintesis akan salah hitung di detik-detik pertama.
func set_bake(sibuk, kemajuan):
	if _btn == null:
		return
	_btn.disabled = sibuk
	if sibuk:
		_btn.text = "MENYIAPKAN  %d%%" % int(round(kemajuan * 100))
	else:
		_btn.text = "  MULAI  "


func _on_play():
	_overlay.visible = false
	play_pressed.emit()


func show_overlay():
	_overlay.visible = true


func flash_msg(text):
	_msg = text
	_msg_t = 1.8


func refresh(sim, w, world, crew, climbers, won):
	var ph = "SIANG" if w.phase == Config.PHASE_DAY else "MALAM"
	_lbl_phase.text = "%s   %d%%" % [ph, int(w.progress() * 100)]
	if crew.aktif() > 0:
		_lbl_phase.text += "   REGU %d" % crew.aktif()
	if climbers.aktif() > 0:
		_lbl_phase.text += "   PEMANJAT %d" % climbers.aktif()
	if w.phase == Config.PHASE_NIGHT and w.progress() > 0.78:
		_lbl_phase.text += "   — FAJAR SEGERA"
		_lbl_phase.modulate = Config.C_WARN
	else:
		_lbl_phase.modulate = Color(1, 1, 1)

	_e_fill.size = Vector2(238.0 * (sim.energy / Config.ENERGY_MAX), 11)
	_e_fill.color = Config.C_ALERT if sim.starved else Config.C_LEAF
	_lbl_energy.text = "ENERGI  %d" % int(sim.energy)

	var bn = sim.bottleneck()
	_lbl_res.text = "AIR %d%s    CAHAYA %d%s" % [
		int(sim.water), " <" if bn == "AIR" else "",
		int(sim.light), " <" if bn == "CAHAYA" else ""]
	if sim.trees.size() > 0:
		_lbl_res.text += "    POHON %d" % sim.trees.size()

	# Bar kemajuan: seberapa banyak fasad sudah dirambati. Target interim
	# COVERAGE_GOAL — TAHAP F menggantinya dengan target per zona.
	var hijau = world.tutupan()
	_lbl_cov.text = "HIJAU  %d%%  dari %d%%" % [int(round(hijau * 100)),
			int(round(Config.COVERAGE_GOAL * 100))]
	_c_fill.size = Vector2(238.0 * clamp(hijau / Config.COVERAGE_GOAL,
			0.0, 1.0), 11)

	_msg_t = max(0.0, _msg_t - get_process_delta_time())

	if won:
		_lbl_win.text = "KOTA MULAI MENGHIJAU     (R untuk ulang)"
	elif _msg_t > 0.0:
		_lbl_win.text = _msg
	else:
		_lbl_win.text = ""
