extends Node2D

# Orkestrator vertical slice ROOM 01 (SRD-TENDRIL-ROOM01 §28, §33).
# Scene mandiri: dunia Ruang01 + Avatar + kamera-ikut. Kota lama
# (main.tscn) TIDAK disentuh — boot project menunjuk ke sini selama
# vertical slice. Pola input mengikuti aturan produksi: SEMUA input
# dibaca terpusat di file main scene, Avatar tidak pernah membaca Input.
#
# Kendali: WASD/panah gerak, Spasi lompat/lepas, Shift LARI (GDD §7),
# F jangkar, R ulang.

const Ruang01Cls     = preload("res://scripts/Ruang01.gd")
const Ruang01ViewCls = preload("res://scripts/render/Ruang01View.gd")
const AvatarCls      = preload("res://scripts/Avatar.gd")
const AvatarViewCls  = preload("res://scripts/render/AvatarView.gd")
const JejakViewCls   = preload("res://scripts/render/JejakView.gd")
const SensorCls      = preload("res://scripts/Sensor.gd")

var world
var avatar
var avatar_view
var cam
var ruang_view             # Ruang01View — diberi tahu state sensor
var sensor                 # RK Langkah 2: tiga state deteksi di grid
var _waspada = 0.0         # sisa detik sensor waspada setelah TERDETEKSI
var _lampu_sensor          # PointLight2D amber sensor — didorong state
var _t_sensor = 0.0        # penggerak denyut lampu sensor
var _cahaya_avatar         # PointLight2D hijau mengikuti TENDRIL (EDV3 §8)
var _lompat_lalu = false   # edge Spasi
var _jangkar_lalu = false  # edge F


func _ready():
	world = Ruang01Cls.new()
	avatar = AvatarCls.new()
	avatar.mulai(world.mulai_pos)

	ruang_view = Ruang01ViewCls.new(world)
	add_child(ruang_view)
	add_child(JejakViewCls.new(avatar))
	avatar_view = AvatarViewCls.new(avatar)
	avatar_view.visible = true
	add_child(avatar_view)

	# kamera §27: side-view, mengikuti halus, TIDAK memperlihatkan seluruh
	# ruangan sekaligus (zoom 3 -> jendela 640x360 px dari 1024x576)
	cam = Camera2D.new()
	cam.zoom = Vector2(3.0, 3.0)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = world.W * Config.PPU
	cam.limit_bottom = world.H * Config.PPU
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 5.0
	cam.position = avatar.pos * float(Config.PPU)
	add_child(cam)
	cam.make_current()

	# EDV3 §8 (D5/D6): grading global mendinginkan scene, lalu cahaya
	# SUNGGUHAN mengembalikannya setempat — kerucut poligon dihapus.
	# Tiap cahaya punya sumber terlihat: dua rumah lampu fluorescent,
	# sensor amber, dan pendar biologis TENDRIL sendiri.
	var grading = CanvasModulate.new()
	grading.color = Color("8FA0B8")
	add_child(grading)
	var tex_lampu = _tex_cahaya()
	_lampu(tex_lampu, Vector2(272, 70), Color("C9D6DE"), 0.9, 5.0)
	_lampu(tex_lampu, Vector2(848, 70), Color("C9D6DE"), 0.9, 5.0)
	_lampu_sensor = _lampu(tex_lampu, Vector2(720, 62), Color("D89A3C"),
			0.55, 3.0)
	_cahaya_avatar = _lampu(tex_lampu, avatar.pos * float(Config.PPU),
			Color("D6FF8F"), 0.4, 2.5)

	sensor = SensorCls.new()
	sensor.pos = world.sensor_pos


# tekstur cahaya BERTANGGA (4 tingkat, disaring nearest) — falloff halus
# akan merusak bahasa pixel art (aturan lama kota dipertahankan)
func _tex_cahaya():
	var img = Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var d = Vector2(x - 32, y - 32).length()
			var a = 0.0
			if d < 10.0:
				a = 1.0
			elif d < 18.0:
				a = 0.62
			elif d < 26.0:
				a = 0.32
			elif d < 31.0:
				a = 0.12
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _lampu(tex, pos, warna, energi, skala):
	var l = PointLight2D.new()
	l.texture = tex
	l.position = pos
	l.color = warna
	l.energy = energi
	l.texture_scale = skala
	add_child(l)
	return l


func _process(delta):
	var arah = Vector2(
			_sumbu(KEY_A, KEY_LEFT, KEY_D, KEY_RIGHT),
			_sumbu(KEY_W, KEY_UP, KEY_S, KEY_DOWN))

	var lompat_tahan = Input.is_physical_key_pressed(KEY_SPACE)
	var jangkar_tahan = Input.is_physical_key_pressed(KEY_F)

	var i = {
		"arah": arah,
		"lompat": lompat_tahan and not _lompat_lalu,
		"lompat_tahan": lompat_tahan,
		"lari": Input.is_physical_key_pressed(KEY_SHIFT),
		"masuk": false,
	}
	_lompat_lalu = lompat_tahan

	if jangkar_tahan and not _jangkar_lalu:
		avatar.jangkar(world)
	_jangkar_lalu = jangkar_tahan

	if Input.is_physical_key_pressed(KEY_R):
		world.build()
		avatar.mulai(world.mulai_pos)
		_waspada = 0.0

	# RK Langkah 2: state sensor SEBELUM avatar bergerak — TERDETEKSI
	# menyalakan kewaspadaan; selama waspada, jaringan menolak memulihkan
	var st = sensor.state(avatar, world)
	if st == sensor.TERDETEKSI:
		_waspada = Config.SENSOR_WASPADA
	else:
		_waspada = max(0.0, _waspada - delta)
	avatar.terdeteksi = st == sensor.TERDETEKSI
	avatar.curiga = st == sensor.CURIGA
	avatar.regen_mati = avatar.terdeteksi or _waspada > 0.0
	ruang_view.sensor_state = st

	# GDD §39/§16: minum dari kebocoran katup — sumber energi Room 01
	avatar.mengisi = world.dekat_air(avatar.pos.x, avatar.pos.y - 2.0,
			false)
	if avatar.mengisi:
		avatar.isi(Config.AIR_ISI * delta)
		avatar.sumber = "air"
		avatar.pernah_air = true

	# lampu sensor berbicara (SRD §23 tanpa teks): kuning menyala keras
	# saat TERDETEKSI, berdenyut pelan selama masih waspada, redup normal
	_t_sensor += delta
	if avatar.terdeteksi:
		_lampu_sensor.energy = 1.3 + 0.35 * sin(_t_sensor * 14.0)
		_lampu_sensor.texture_scale = 4.2
	elif _waspada > 0.0:
		_lampu_sensor.energy = 0.9 + 0.25 * sin(_t_sensor * 7.0)
		_lampu_sensor.texture_scale = 3.6
	elif avatar.curiga:
		_lampu_sensor.energy = 0.75
		_lampu_sensor.texture_scale = 3.2
	else:
		_lampu_sensor.energy = 0.55
		_lampu_sensor.texture_scale = 3.0

	avatar.update(delta, i, world)

	# kamera mengejar titik tengah badan; cahaya hijau mengikuti TENDRIL
	cam.position = (avatar.pos + Vector2(0.0, -Config.AVATAR_TINGGI * 0.5)) \
			* float(Config.PPU)
	_cahaya_avatar.position = (avatar.pos
			+ Vector2(0.0, -Config.AVATAR_TINGGI * 0.5)) * float(Config.PPU)


func _sumbu(neg1, neg2, pos1, pos2):
	var v = 0.0
	if Input.is_physical_key_pressed(neg1) or Input.is_physical_key_pressed(neg2):
		v -= 1.0
	if Input.is_physical_key_pressed(pos1) or Input.is_physical_key_pressed(pos2):
		v += 1.0
	return v
