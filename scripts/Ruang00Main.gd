extends Node2D

# Orkestrator RUANG 00 — LAB BOTANI (SRD-TENDRIL-RUANG00-LAB).
# Ruangan PEMBUKA: kelahiran + tutorial empat mekanik tanpa teks.
# Scene mandiri; lorong keluar mengganti scene ke ruang01.tscn — Room 01
# tidak disentuh sama sekali (arah modular GDD §27).
#
# Kendali identik Room 01: WASD/panah, Spasi lompat/lepas, Shift lari,
# F jangkar, E interaksi (katup), R ulang, ESC jeda.

const Ruang00Cls     = preload("res://scripts/Ruang00.gd")
const Ruang00ViewCls = preload("res://scripts/render/Ruang00View.gd")
const AvatarCls      = preload("res://scripts/Avatar.gd")
const AvatarViewCls  = preload("res://scripts/render/AvatarView.gd")
const DaunViewCls    = preload("res://scripts/render/DaunView.gd")
const SensorCls      = preload("res://scripts/Sensor.gd")
const HudCls         = preload("res://scripts/render/Hud.gd")
const MenuJedaCls    = preload("res://scripts/render/MenuJeda.gd")

var world
var avatar
var avatar_view
var cam
var ruang_view
var kerucut = []           # tiga "sensor" grow light (Zona B)
var _waspada = 0.0
var _pos_diam = Vector2()
var _grading
var _cahaya_avatar
var _lampu_grow = []
var _t = 0.0
var _lompat_lalu = false
var _jangkar_lalu = false
var _interaksi_lalu = false
var _esc_lalu = false
var _keluar = false        # transisi sekali jalan
var menu_jeda
var hud


func _ready():
	world = Ruang00Cls.new()
	avatar = AvatarCls.new()
	avatar.mulai(world.mulai_pos)
	# KELAHIRAN (SRD §1/§6 A): pemain lahir DI jaringan induk — beat 1
	# mengajarkan merambat sebelum apa pun
	avatar.moda = avatar.MERAMBAT

	ruang_view = Ruang00ViewCls.new(world)
	add_child(ruang_view)
	add_child(DaunViewCls.new(avatar))
	avatar_view = AvatarViewCls.new(avatar)
	avatar_view.visible = true
	add_child(avatar_view)

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

	# grading lab: dasar dingin yang sama; nuansa steril datang dari
	# overlay view + cahaya. Grow light = MERAH-MUDA HANGAT (SRD §3 —
	# satu-satunya warna hangat sekaligus bahaya; BUKAN ungu racun)
	_grading = CanvasModulate.new()
	_grading.color = Color("8FA0B8")
	add_child(_grading)
	var tex_lampu = _tex_cahaya()
	# pendar hijau tabung induk (zona A hidup)
	_lampu(tex_lampu, Vector2(80, 300), Color("9FE87F"), 0.5, 4.0)
	for gx in [90.0, 124.0, 158.0]:
		_lampu_grow.append(_lampu(tex_lampu,
				Vector2(gx * 4.0, 60.0), Color("E8909E"), 0.7, 3.2))
	_cahaya_avatar = _lampu(tex_lampu, avatar.pos * float(Config.PPU),
			Color("D6FF8F"), 0.4, 2.5)

	# tiga kerucut grow light = "sensor" Zona B (SRD §6 B): SELALU
	# memindai (lampu tumbuh tidak berkedip) — jendela amannya RUANG
	# GELAP di antara kerucut & di balik rak, bukan waktu
	for gx in [90.0, 124.0, 158.0]:
		var s = SensorCls.new()
		s.pos = Vector2(gx, 10.0)
		s.lantai_y = 96.0
		s.dasar = 3.0
		s.lebar = 0.12
		s.alarm = true   # kunci: memindai terus
		kerucut.append(s)

	var lapis_hud = CanvasLayer.new()
	add_child(lapis_hud)
	hud = HudCls.new(avatar)
	lapis_hud.add_child(hud)

	process_mode = Node.PROCESS_MODE_ALWAYS
	for anak in get_children():
		anak.process_mode = Node.PROCESS_MODE_PAUSABLE
	menu_jeda = MenuJedaCls.new()
	add_child(menu_jeda)


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
	# MENU JEDA: pola edge ESC yang sama dengan Room 01
	var esc = Input.is_physical_key_pressed(KEY_ESCAPE)
	if esc and not _esc_lalu:
		get_tree().paused = not get_tree().paused
		menu_jeda.buka(get_tree().paused)
	_esc_lalu = esc
	if get_tree().paused:
		if Input.is_physical_key_pressed(KEY_R):
			get_tree().paused = false
			menu_jeda.buka(false)
			_ulang()
		return

	_t += delta
	world.update(delta)

	var arah = Vector2(
			_sumbu(KEY_A, KEY_LEFT, KEY_D, KEY_RIGHT),
			_sumbu(KEY_W, KEY_UP, KEY_S, KEY_DOWN))
	var lompat_tahan = Input.is_physical_key_pressed(KEY_SPACE)
	var i = {
		"arah": arah,
		"lompat": lompat_tahan and not _lompat_lalu,
		"lompat_tahan": lompat_tahan,
		"lari": Input.is_physical_key_pressed(KEY_SHIFT),
		"masuk": false,
	}
	_lompat_lalu = lompat_tahan

	var jangkar_tahan = Input.is_physical_key_pressed(KEY_F)
	if jangkar_tahan and not _jangkar_lalu:
		avatar.jangkar(world)
	_jangkar_lalu = jangkar_tahan

	if Input.is_physical_key_pressed(KEY_R):
		_ulang()

	# KATUP (SRD Lab §6 C beat 6): dekat katup + E = sprinkler membasahi
	# panel kanan -> permukaan tumbuh cepat -> jalan keluar
	avatar.bisa_interaksi = not world.katup_terbuka \
			and avatar.pos.distance_to(world.katup_pos) <= 8.0
	var e_tahan = Input.is_physical_key_pressed(KEY_E)
	if e_tahan and not _interaksi_lalu and avatar.bisa_interaksi:
		if world.buka_katup():
			hud.kabar("SPRINKLER MEMBASAHI PANEL", 3.0)
	_interaksi_lalu = e_tahan

	# deteksi kerucut grow light: nilai TERBURUK dari ketiganya
	var diam = _pos_diam.distance_to(avatar.pos) < delta * 3.0
	_pos_diam = avatar.pos
	var st = 0
	for s in kerucut:
		s.update(delta)
		st = max(st, s.state(avatar, world, diam))
	if st == kerucut[0].TERDETEKSI:
		_waspada = Config.SENSOR_WASPADA
	else:
		_waspada = max(0.0, _waspada - delta)
	avatar.terdeteksi = st == kerucut[0].TERDETEKSI
	avatar.curiga = st == kerucut[0].CURIGA
	avatar.regen_mati = avatar.terdeteksi or _waspada > 0.0
	ruang_view.sensor_state = 3 if avatar.terdeteksi \
			else (2 if avatar.curiga else 1)

	# grading bergeser hangat selama waspada (bahasa Room 01 yang sama)
	var target = Color("A6987F") if _waspada > 0.0 else Color("8FA0B8")
	_grading.color = _grading.color.lerp(target,
			clamp(delta * 3.0, 0.0, 1.0))
	# grow light mengeras saat terdeteksi
	for l in _lampu_grow:
		l.energy = (1.1 + 0.3 * sin(_t * 14.0)) if avatar.terdeteksi \
				else 0.7

	avatar.update(delta, i, world)

	# LORONG KELUAR (SRD Lab §0): menyentuh bukaan = lahir ke Room 01
	if not _keluar and world.di_keluar(avatar.pos):
		_keluar = true
		get_tree().change_scene_to_file.call_deferred(
				"res://ruang01.tscn")

	cam.position = (avatar.pos + Vector2(0.0, -Config.AVATAR_TINGGI * 0.5)) \
			* float(Config.PPU)
	_cahaya_avatar.position = (avatar.pos
			+ Vector2(0.0, -Config.AVATAR_TINGGI * 0.5)) * float(Config.PPU)


func _ulang():
	world.build()
	avatar.mulai(world.mulai_pos)
	avatar.moda = avatar.MERAMBAT
	_waspada = 0.0


func _sumbu(neg1, neg2, pos1, pos2):
	var v = 0.0
	if Input.is_physical_key_pressed(neg1) or Input.is_physical_key_pressed(neg2):
		v -= 1.0
	if Input.is_physical_key_pressed(pos1) or Input.is_physical_key_pressed(pos2):
		v += 1.0
	return v
