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
const DaunViewCls    = preload("res://scripts/render/DaunView.gd")
const SensorCls      = preload("res://scripts/Sensor.gd")
const PemangkasCls   = preload("res://scripts/Pemangkas.gd")
const PemangkasViewCls = preload("res://scripts/render/PemangkasView.gd")
const HudCls         = preload("res://scripts/render/Hud.gd")
const MenuJedaCls    = preload("res://scripts/render/MenuJeda.gd")

var world
var avatar
var avatar_view
var cam
var ruang_view             # Ruang01View — diberi tahu state sensor
var sensor                 # RK Langkah 2-3: deteksi bersiklus di grid
var _waspada = 0.0         # sisa detik alarm setelah TERDETEKSI
var _lampu_sensor          # PointLight2D amber sensor — didorong state
var _t_sensor = 0.0        # penggerak denyut lampu sensor
var _pos_diam = Vector2()  # pelacak gerak untuk aturan diam=tersembunyi
var _grading               # CanvasModulate — bergeser hangat saat alarm
var _cahaya_avatar         # PointLight2D hijau mengikuti TENDRIL (EDV3 §8)
var _lampu_ruang = []      # dua lampu fluorescent — kedip mikro grading
var _lompat_lalu = false   # edge Spasi
var _jangkar_lalu = false  # edge F
var _sergap_lalu = false   # edge E — sergap senyap (Phase 5-6)
var _esc_lalu = false      # edge Esc — menu jeda
var menu_jeda
var pemangkas              # RK-2 [C]: musuh pertama
var hud
var _tujuan_capai = false  # RK-2 [D]: tujuan ruangan sekali-capai


func _ready():
	world = Ruang01Cls.new()
	avatar = AvatarCls.new()
	avatar.mulai(world.mulai_pos)

	ruang_view = Ruang01ViewCls.new(world)
	add_child(ruang_view)
	# JejakView (garis + bulatan) PENSIUN — tubuh jejak kini sepenuhnya
	# gumpalan daun DaunView (putusan pemilik)
	add_child(DaunViewCls.new(avatar))
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
	_grading = CanvasModulate.new()
	_grading.color = Color("8FA0B8")
	add_child(_grading)
	var tex_lampu = _tex_cahaya()
	_lampu_ruang.append(
			_lampu(tex_lampu, Vector2(272, 70), Color("C9D6DE"), 0.9, 5.0))
	_lampu_ruang.append(
			_lampu(tex_lampu, Vector2(848, 70), Color("C9D6DE"), 0.9, 5.0))
	_lampu_sensor = _lampu(tex_lampu, Vector2(720, 62), Color("D89A3C"),
			0.55, 3.0)
	_cahaya_avatar = _lampu(tex_lampu, avatar.pos * float(Config.PPU),
			Color("D6FF8F"), 0.4, 2.5)

	sensor = SensorCls.new()
	sensor.pos = world.sensor_pos

	# RK-2 [C]: SATU Pemangkas berpatroli di lantai tengah terbuka
	# (x 84-130, sebelum tangga peti) — rute cepat kini berpenjaga
	pemangkas = PemangkasCls.new(84.0, 130.0)
	add_child(PemangkasViewCls.new(pemangkas))

	# HUD GDD §31 di CanvasLayer sendiri — tidak ikut kamera/zoom
	var lapis_hud = CanvasLayer.new()
	add_child(lapis_hud)
	hud = HudCls.new(avatar)
	lapis_hud.add_child(hud)

	# MENU JEDA: main berjalan TERUS (membaca ESC saat pohon dibekukan);
	# seluruh logika game di _process dipagari get_tree().paused, dan
	# anak-anak yang punya _process ditandai PAUSABLE eksplisit supaya
	# ikut beku (di bawah induk ALWAYS, INHERIT berarti ikut jalan)
	process_mode = Node.PROCESS_MODE_ALWAYS
	for anak in get_children():
		anak.process_mode = Node.PROCESS_MODE_PAUSABLE
	menu_jeda = MenuJedaCls.new()
	add_child(menu_jeda)



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
	# MENU JEDA: ESC membuka/menutup; saat jeda hanya ESC & R yang hidup
	var esc = Input.is_physical_key_pressed(KEY_ESCAPE)
	if esc and not _esc_lalu:
		get_tree().paused = not get_tree().paused
		menu_jeda.buka(get_tree().paused)
	_esc_lalu = esc
	if get_tree().paused:
		if Input.is_physical_key_pressed(KEY_R):
			get_tree().paused = false
			menu_jeda.buka(false)
			world.build()
			avatar.mulai(world.mulai_pos)
			pemangkas.reset()
			_waspada = 0.0
		return

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
		pemangkas.reset()
		_waspada = 0.0
		_tujuan_capai = false
		ruang_view.tujuan_nyala = false

	# RK Langkah 2-3: siklus pindai jalan dulu, lalu state — TERDETEKSI
	# menyalakan alarm (pindai terkunci + jaringan menolak memulihkan)
	sensor.alarm = _waspada > 0.0
	sensor.update(delta)
	var diam = _pos_diam.distance_to(avatar.pos) < delta * 3.0
	_pos_diam = avatar.pos
	var st = sensor.state(avatar, world, diam)
	if st == sensor.TERDETEKSI:
		_waspada = Config.SENSOR_WASPADA
	else:
		_waspada = max(0.0, _waspada - delta)
	avatar.terdeteksi = st == sensor.TERDETEKSI
	avatar.curiga = st == sensor.CURIGA
	avatar.regen_mati = avatar.terdeteksi or _waspada > 0.0
	# view: 0 idle-redup, 1 memindai, 2 curiga, 3 terdeteksi
	var tampil = 0
	if st == sensor.TERDETEKSI:
		tampil = 3
	elif st == sensor.CURIGA:
		tampil = 2
	elif sensor.memindai():
		tampil = 1
	ruang_view.sensor_state = tampil

	# ruangan ikut bereaksi (opsi 2b RK: lampu ruangan berubah): grading
	# bergeser hangat-waspada selama alarm, pulih dingin sesudahnya
	var target_grading = Color("A6987F") if _waspada > 0.0 \
			else Color("8FA0B8")
	_grading.color = _grading.color.lerp(target_grading,
			clamp(delta * 3.0, 0.0, 1.0))

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

	# kedip mikro fluorescent (grading Langkah 4): lampu tua ruang servis
	# sesekali tersendat sekejap — deterministik dari jam, fase digeser
	# per lampu supaya keduanya tidak pernah tersendat serempak
	for li in range(_lampu_ruang.size()):
		var tik = int((_t_sensor + li * 1.37) * 60.0)
		_lampu_ruang[li].energy = 0.9 if tik % 211 > 3 else 0.62

	# Phase 5-6: DIBURU (merah CDD §7) saat musuh mengejar, dan SERGAP
	# SENYAP [E] — hanya dari jaringan, hanya pada yang belum melihat
	avatar.diburu = pemangkas.hidup and pemangkas.state == pemangkas.KEJAR
	avatar.bisa_sergap_musuh = pemangkas.bisa_sergap(avatar)
	var sergap_tahan = Input.is_physical_key_pressed(KEY_E)
	if sergap_tahan and not _sergap_lalu and avatar.bisa_sergap_musuh:
		if pemangkas.sergap(avatar):
			hud.kabar("BIOMASSA DISERAP", 2.5)
	_sergap_lalu = sergap_tahan

	avatar.update(delta, i, world)
	pemangkas.update(delta, avatar, world)

	# RK-2 [D]: mencapai TUJUAN lewat jaringan — bulb menyala + kabar
	if not _tujuan_capai and avatar.moda == avatar.MERAMBAT \
			and avatar.pos.distance_to(world.tujuan_pos) < 5.0:
		_tujuan_capai = true
		ruang_view.tujuan_nyala = true
		hud.kabar("RUANGAN DITEMBUS", 4.0)

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

