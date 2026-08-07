extends CanvasLayer

signal reset_pressed

const SPECS = [
	["VINE_SPEED",     0.5, 12.0, 0.1],
	["MAX_TURN",       0.2,  5.0, 0.05],
	["ENERGY_RATE",    1.0, 20.0, 0.5],
	["COST_PER_PIXEL", 0.1,  2.0, 0.05],
	["GAZE_RANGE",    30.0,140.0, 2.0],
	["HEAT_RATE",      0.1,  1.5, 0.02],
	["HEAT_DECAY",     0.0,  0.4, 0.01],
	["NIGHT_HEAT",     0.0,  0.8, 0.02],
	["DAY_LEN",        6.0, 40.0, 1.0],
	["NIGHT_LEN",      6.0, 60.0, 1.0],
]

var _labels  = {}
var _sliders = {}
var _panel
var _help


func _ready():
	layer = 10

	_panel = PanelContainer.new()
	_panel.rect_position = Vector2(12, 12)
	add_child(_panel)

	var vb = VBoxContainer.new()
	_panel.add_child(vb)

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
		sl.rect_min_size = Vector2(230, 18)
		sl.focus_mode = Control.FOCUS_NONE
		sl.connect("value_changed", self, "_on_changed", [key])
		vb.add_child(sl)
		_sliders[key] = sl

		_refresh(key, sl.value)
		
	var btn = Button.new()
	btn.text = "Reset pohon  (R)"
	btn.focus_mode = Control.FOCUS_NONE
	btn.connect("pressed", self, "_on_reset")
	vb.add_child(btn)

	_help = Label.new()
	_help.rect_position = Vector2(12, 604)
	_help.text = "Klik kiri: pilih & arahkan   |   Klik kanan / Spasi: bercabang   |   X: hentikan ujung   |   Tahan V: peta risiko   |   Tahan B: rangka   |   Tab: panel   |   R: reset"
	add_child(_help)


func _on_changed(value, key):
	Config.set(key, value)
	_refresh(key, value)


func _refresh(key, value):
	_labels[key].text = "%s   %.2f" % [key, value]


func _on_reset():
	emit_signal("reset_pressed")


func sync_sliders():
	for key in _sliders:
		_sliders[key].value = Config.get(key)


func toggle():
	_panel.visible = not _panel.visible
