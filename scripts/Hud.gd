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


func _build_overlay():
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.70)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)

	var info = Label.new()
	info.position = Vector2(120, 28)
	info.text = "LAYAR     Atas = fasad gedung, bawah = bawah tanah. Tiap pane punya\n          kameranya sendiri: WASD menggeser, roda mouse zoom 2x/4x,\n          tahan roda-tengah untuk menyeret. Pane yang dikendalikan adalah\n          yang sedang ditunjuk kursor.\n\nTUJUAN    Runtuhkan gedung. Bar STRUKTUR habis = menang.\n\nSIANG     Akar tumbuh. Sebagian ke air, sebagian ke kaki kolom untuk\n          menggerogotinya. Regu perawatan mencabut tanaman di sekitar\n          garis tanah; yang di area terang ditemukan lebih dulu.\n\nMALAM     Regu pulang. Sulur merambat. Dekatkan ujungnya ke sambungan\n          rangka untuk melemahkannya.\n\nENERGI    Bertambah sebesar min(Air, Cahaya), dan HANYA saat siang.\n          Yang lebih kecil ditandai '<' — itu leher botolnya.\n\nRUNTUH    Sambungan lemah menurunkan kapasitas member. Beban yang lewat\n          batas membuatnya gagal dan berpindah ke tetangga — beruntun.\n          Puing yang jatuh MENIMBUN regu di bawahnya.\n\nPEMANJAT  Naik lewat sulur Anda sendiri untuk mencabut dari atas.\n          Tekan X di atas sulur untuk MEMUTUSNYA — dia jatuh, tapi\n          pertumbuhan di atas potongan itu ikut hilang.\n\nPUING     Reruntuhan jadi tanah baru. Tanaman di atasnya menjalar sendiri,\n          dan yang bertahan cukup lama BERAKAR JADI POHON.\n\nPOHON     Permanen, kebal regu, menyumbang air sekaligus cahaya. Klik\n          kanan di dekatnya untuk menumbuhkan jaringan baru dari sana."
	_overlay.add_child(info)

	_btn = Button.new()
	_btn.text = "  MULAI  "
	_btn.position = Vector2(400, 570)
	_btn.custom_minimum_size = Vector2(160, 44)
	_btn.focus_mode = Control.FOCUS_NONE
	_btn.pressed.connect(_on_play)
	_overlay.add_child(_btn)


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


func refresh(sim, w, st, crew, climbers, won):
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

	# Bar ini menyusut saat gedung dilemahkan dan diruntuhkan.
	var integ = st.integritas_total()
	_lbl_cov.text = "STRUKTUR  %d%%" % int(round(integ * 100))
	_c_fill.size = Vector2(238.0 * clamp(integ, 0.0, 1.0), 11)

	_msg_t = max(0.0, _msg_t - get_process_delta_time())

	if won:
		_lbl_win.text = "GEDUNG RUNTUH     (R untuk ulang)"
	elif _msg_t > 0.0:
		_lbl_win.text = _msg
	else:
		_lbl_win.text = ""
