extends CanvasLayer

# Layar peta (tombol M — P3.75, docs/13 §4, acuan Hollow Knight/Metroid).
#
# Menggambar dunia per PETAK 8x8 (60x40 sel), HANYA petak yang pernah
# didekati avatar (world.dijelajah). Satu petak = 16 px layar -> panel
# 960x640 di tengah. Warna disarikan dari sel tengah petak: cukup jujur
# untuk navigasi, cukup kabur untuk tetap menyisakan misteri.

var world
var avatar
var _panel      # Control anak yang menggambar (CanvasLayer bukan CanvasItem)
var _t = 0.0

const SEL = 16.0
const X0 = (1920.0 - 60 * SEL) / 2.0
const Y0 = (1080.0 - 40 * SEL) / 2.0


func _init(w, a):
	world = w
	avatar = a
	layer = 15   # di atas dunia, di bawah HUD (20)
	visible = false


func _ready():
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.draw.connect(_gambar)
	add_child(_panel)


func _process(delta):
	_t += delta
	if visible:
		_panel.queue_redraw()


func _gambar():
	# latar redup menutup dunia — fokus ke peta
	_panel.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.04, 0.05, 0.06, 0.93))
	_panel.draw_rect(Rect2(X0 - 8, Y0 - 8, 60 * SEL + 16, 40 * SEL + 16),
			Color(0.12, 0.13, 0.15))

	var pw = Config.W / world.PETAK
	var ph = Config.H / world.PETAK
	for ty in range(ph):
		for tx in range(pw):
			if world.dijelajah[ty * pw + tx] == 0:
				continue
			var cx = tx * world.PETAK + world.PETAK / 2
			var cy = ty * world.PETAK + world.PETAK / 2
			var r = Rect2(X0 + tx * SEL, Y0 + ty * SEL, SEL - 1, SEL - 1)
			_panel.draw_rect(r, _warna(cx, cy))
			# jaringan menimpa samar — wilayah yang sudah dikuasai tanaman
			if world.jaringan[cy * Config.W + cx] == 1:
				var hij = Config.C_LEAF
				hij.a = 0.5
				_panel.draw_rect(r, hij)

	# penanda: simpul bangun (jangkar) dan avatar berkedip
	var sp = Vector2(X0 + avatar.simpul.x / world.PETAK * SEL,
			Y0 + avatar.simpul.y / world.PETAK * SEL)
	_panel.draw_circle(sp, 4.0, Config.C_WARN)
	if fmod(_t, 0.8) < 0.5:
		var ap = Vector2(X0 + avatar.pos.x / world.PETAK * SEL,
				Y0 + avatar.pos.y / world.PETAK * SEL)
		_panel.draw_circle(ap, 5.0, Config.C_TIP)


# Warna petak dari sel tengahnya. Interior dipakai kalau avatar sedang di
# dalam DAN petaknya di tapak gedung — dua dunia, satu peta.
func _warna(cx, cy):
	if avatar.di_dalam and cx >= Config.FACADE_X0 and cx < Config.FACADE_X1 \
			and cy >= Config.FACADE_Y0 and cy < Config.FACADE_Y1:
		match world.dalam[cy * Config.W + cx]:
			Config.T_LANTAI, Config.T_DINDING_DALAM:
				return Color("3A3F49")
			Config.T_VENT:
				return Color("31504F")
			Config.T_POROS:
				return Color("15171B")
			Config.T_KERAN:
				return Color("4A9BC4")
			Config.T_TERALIS:
				return Color("6B6B64")
			_:
				return Color("22252B")
	match world.at(cx, cy):
		Config.T_SKY:
			return Color("15171B")
		Config.T_WALL, Config.T_WINDOW, Config.T_DOOR, Config.T_LEDGE:
			return Color("40454F")
		Config.T_NEIGHBOR:
			return Color("2A2E36")
		Config.T_GORONG, Config.T_UTILITAS:
			return Color("4A4E42")
		Config.T_AKUIFER:
			return Color("4A9BC4")
		Config.T_CONCRETE, Config.T_BATU:
			return Color("50524E")
		Config.T_HUMUS:
			return Color("3A2B1E")
		_:
			return Color("33281E")   # tanah
