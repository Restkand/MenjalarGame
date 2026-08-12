extends CanvasLayer

signal reset_pressed

const SPECS = [
	["GROWTH_SPEED",   2.0, 30.0, 0.5],
	["VINE_SPEED",     1.0, 24.0, 0.2],
	["GESER_SPEED",   60.0,600.0,10.0],
	["MAX_TURN",       0.2,  5.0, 0.05],
	["ENERGY_RATE",    1.0, 20.0, 0.5],
	["COST_PER_PIXEL", 0.1,  2.0, 0.05],
	["PUING_LAMBAT",   0.0,  1.0, 0.05],
	["LAPUK_LAJU",     0.0,  0.2, 0.005],
	["AMBANG_RAWAT",   0.1,  1.0, 0.05],
	["INSPEKSI_TIAP",  1.0,  7.0, 1.0],
	["JEDA_RAWAT",     1.0,  5.0, 1.0],
	["PERHATIAN_LURUH", 0.0, 0.02, 0.001],
	["CREW_SPEED",     5.0, 60.0, 1.0],
	["CREW_POTONG",    0.5,  6.0, 0.1],
	["CREW_MAX",       1.0,  8.0, 1.0],
	["CREW_PINGSAN",   0.0, 20.0, 0.5],
	["CLIMB_CABUT",    0.1,  3.0, 0.05],
	["CLIMB_MAX",      0.0,  6.0, 1.0],
	["DAY_LEN",        6.0, 40.0, 1.0],
	["NIGHT_LEN",      6.0, 60.0, 1.0],
	["NIGHT_GELAP",    0.0,  1.0, 0.05],
	["LAMPU_ENERGI",   0.0,  3.0, 0.1],
]

var _labels  = {}
var _sliders = {}
var _panel
var _help


func _ready():
	layer = 10

	_panel = PanelContainer.new()
	_panel.position = Vector2(12, 52)
	add_child(_panel)

	# Font bawaan Godot 4 lebih besar daripada Godot 3, jadi daftar slider yang
	# dulu pas sekarang melewati tepi bawah layar — NIGHT_LEN dan tombol Reset
	# tidak terjangkau sama sekali. ScrollContainer memberi tinggi tetap dan
	# bilah gulir, sehingga menambah slider baru tidak akan pernah lagi
	# memotong yang di bawahnya.
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(268, Config.PANEL_TINGGI)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.focus_mode = Control.FOCUS_NONE
	# Tanpa ini bilah gulirnya merebut fokus dan menelan tombol Tab.
	scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_NONE
	_panel.add_child(scroll)

	var vb = VBoxContainer.new()
	# rapat — dengan 17 slider, jarak bawaan membuat daftarnya jauh lebih
	# panjang daripada yang perlu digulir
	vb.add_theme_constant_override("separation", 1)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vb)

	var title = Label.new()
	title.text = "PANEL TUNING"
	vb.add_child(title)

	for spec in SPECS:
		var key = spec[0]
		var cur = Config.get(key)
		if cur == null:
			printerr("Config tidak punya: ", key)
			continue

		var lbl = Label.new()
		vb.add_child(lbl)
		_labels[key] = lbl

		var sl = HSlider.new()
		sl.min_value = spec[1]
		sl.max_value = spec[2]
		sl.step = spec[3]
		sl.value = cur
		sl.custom_minimum_size = Vector2(230, 14)
		sl.focus_mode = Control.FOCUS_NONE
		# Godot 4: bind() menempelkan argumen tambahan DI BELAKANG argumen
		# sinyal, jadi tanda tangan _on_changed(value, key) tetap benar.
		sl.value_changed.connect(_on_changed.bind(key))
		vb.add_child(sl)
		_sliders[key] = sl

		_refresh(key, sl.value)

	var btn = Button.new()
	btn.text = "Reset pohon  (R)"
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(_on_reset)
	vb.add_child(btn)

	# Dua baris pendek dengan latar, bukan satu baris panjang. Versi lama
	# terpotong di tepi kanan layar 960 px.
	var help_box = PanelContainer.new()
	help_box.position = Vector2(440, 986)
	add_child(help_box)

	_help = Label.new()
	_help.text = "Klik kiri: pilih & arahkan (akar di beton: menembus)   Klik kanan / Spasi: bercabang   X: putus sulur   WASD: geser   Roda: zoom\nTab: panel      R: ulang      Tahan V: peta risiko"
	help_box.add_child(_help)

	# Playtest 11 Agustus: layar pembuka "terlalu ramai" — panel tuning ikut
	# terpampang sejak frame pertama. Sekarang tertutup sampai diminta (Tab).
	_panel.visible = false


func _on_changed(value, key):
	Config.set(key, value)
	_refresh(key, value)


func _refresh(key, value):
	_labels[key].text = "%s   %.2f" % [key, value]


func _on_reset():
	reset_pressed.emit()


func sync_sliders():
	for key in _sliders:
		_sliders[key].value = Config.get(key)


func toggle():
	_panel.visible = not _panel.visible
