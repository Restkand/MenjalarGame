extends CanvasLayer

signal play_pressed

var _e_fill
var _c_fill
var _lbl_phase
var _lbl_energy
var _lbl_res
var _lbl_cov
var _lbl_win
var _overlay
var _msg = ""
var _msg_t = 0.0


func _ready():
	layer = 20

	var box = PanelContainer.new()
	box.rect_position = Vector2(692, 12)
	box.rect_min_size = Vector2(256, 0)
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
	_lbl_win.rect_position = Vector2(330, 250)
	add_child(_lbl_win)

	_build_overlay()


func _bar(vb, col):
	var bg = ColorRect.new()
	bg.color = Color(0.11, 0.11, 0.13)
	bg.rect_min_size = Vector2(238, 11)
	vb.add_child(bg)

	var f = ColorRect.new()
	f.color = col
	f.rect_size = Vector2(0, 11)
	bg.add_child(f)
	return f


func _build_overlay():
	_overlay = Control.new()
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	add_child(_overlay)

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.70)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	_overlay.add_child(dim)

	var info = Label.new()
	info.rect_position = Vector2(140, 80)
	info.text = "TUJUAN   Runtuhkan gedung. Bar STRUKTUR habis = menang.\n\nSIANG    Akar tumbuh. Arahkan sebagian ke tanah lembap atau pipa untuk\n         energi, sebagian lagi ke kaki kolom untuk menggerogotinya.\n         Akar di tanah kering hampir tidak menghasilkan air.\n\nMALAM    Sulur merambat di fasad. Dekatkan ujungnya ke sambungan rangka\n         untuk melemahkannya.\n\nENERGI   Bertambah sebesar min(Air, Cahaya), dan HANYA saat siang.\n         Yang lebih kecil ditandai '<' — itu leher botolnya.\n\nRUNTUH   Sambungan yang lemah menurunkan kapasitas member. Saat beban\n         melebihi kapasitas, member gagal dan bebannya pindah ke\n         tetangga, yang bisa ikut gagal beruntun. Panel dinding jatuh\n         menyusul rangkanya.\n\n         Retakan = member mendekati batas.\n         Tahan B untuk melihat rangka: hijau santai, merah di ambang."
	_overlay.add_child(info)

	var btn = Button.new()
	btn.text = "  MULAI  "
	btn.rect_position = Vector2(430, 520)
	btn.rect_min_size = Vector2(100, 44)
	btn.focus_mode = Control.FOCUS_NONE
	btn.connect("pressed", self, "_on_play")
	_overlay.add_child(btn)


func _on_play():
	_overlay.visible = false
	emit_signal("play_pressed")


func show_overlay():
	_overlay.visible = true


func flash_msg(text):
	_msg = text
	_msg_t = 1.8


func refresh(sim, w, st, won):
	var ph = "SIANG" if w.phase == Config.PHASE_DAY else "MALAM"
	_lbl_phase.text = "%s   %d%%" % [ph, int(w.progress() * 100)]
	if w.phase == Config.PHASE_NIGHT and w.progress() > 0.78:
		_lbl_phase.text += "   — FAJAR SEGERA"
		_lbl_phase.modulate = Config.C_WARN
	else:
		_lbl_phase.modulate = Color(1, 1, 1)

	_e_fill.rect_size = Vector2(238.0 * (sim.energy / Config.ENERGY_MAX), 11)
	_e_fill.color = Config.C_ALERT if sim.starved else Config.C_LEAF
	_lbl_energy.text = "ENERGI  %d" % int(sim.energy)

	var bn = sim.bottleneck()
	_lbl_res.text = "AIR %d%s    CAHAYA %d%s" % [
		int(sim.water), " <" if bn == "AIR" else "",
		int(sim.light), " <" if bn == "CAHAYA" else ""]

	# Bar ini menyusut saat gedung dilemahkan dan diruntuhkan.
	var integ = st.integritas_total()
	_lbl_cov.text = "STRUKTUR  %d%%" % int(round(integ * 100))
	_c_fill.rect_size = Vector2(238.0 * clamp(integ, 0.0, 1.0), 11)

	_msg_t = max(0.0, _msg_t - get_process_delta_time())

	if won:
		_lbl_win.text = "GEDUNG RUNTUH     (R untuk ulang)"
	elif _msg_t > 0.0:
		_lbl_win.text = _msg
	else:
		_lbl_win.text = ""
