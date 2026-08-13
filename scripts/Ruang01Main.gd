extends Node2D

# Orkestrator vertical slice ROOM 01 (SRD-TENDRIL-ROOM01 §28, §33).
# Scene mandiri: dunia Ruang01 + Avatar + kamera-ikut. Kota lama
# (main.tscn) TIDAK disentuh — boot project menunjuk ke sini selama
# vertical slice. Pola input mengikuti aturan produksi: SEMUA input
# dibaca terpusat di file main scene, Avatar tidak pernah membaca Input.
#
# Kendali: WASD/panah gerak, Spasi lompat/lepas, Shift lesat/sprint,
# F jangkar, R ulang.

const Ruang01Cls     = preload("res://scripts/Ruang01.gd")
const Ruang01ViewCls = preload("res://scripts/render/Ruang01View.gd")
const AvatarCls      = preload("res://scripts/Avatar.gd")
const AvatarViewCls  = preload("res://scripts/render/AvatarView.gd")
const JejakViewCls   = preload("res://scripts/render/JejakView.gd")

var world
var avatar
var avatar_view
var cam
var _lompat_lalu = false   # edge Spasi
var _lesat_lalu = false    # edge Shift
var _jangkar_lalu = false  # edge F


func _ready():
	world = Ruang01Cls.new()
	avatar = AvatarCls.new()
	avatar.mulai(world.mulai_pos)

	add_child(Ruang01ViewCls.new(world))
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


func _process(delta):
	var arah = Vector2(
			_sumbu(KEY_A, KEY_LEFT, KEY_D, KEY_RIGHT),
			_sumbu(KEY_W, KEY_UP, KEY_S, KEY_DOWN))

	var lompat_tahan = Input.is_physical_key_pressed(KEY_SPACE)
	var lesat_tahan = Input.is_physical_key_pressed(KEY_SHIFT)
	var jangkar_tahan = Input.is_physical_key_pressed(KEY_F)

	var i = {
		"arah": arah,
		"lompat": lompat_tahan and not _lompat_lalu,
		"lompat_tahan": lompat_tahan,
		"lesat": lesat_tahan and not _lesat_lalu,
		"sprint": lesat_tahan,
		"masuk": false,
	}
	_lompat_lalu = lompat_tahan
	_lesat_lalu = lesat_tahan

	if jangkar_tahan and not _jangkar_lalu:
		avatar.jangkar(world)
	_jangkar_lalu = jangkar_tahan

	if Input.is_physical_key_pressed(KEY_R):
		world.build()
		avatar.mulai(world.mulai_pos)

	avatar.update(delta, i, world)

	# kamera mengejar titik tengah badan
	cam.position = (avatar.pos + Vector2(0.0, -Config.AVATAR_TINGGI * 0.5)) \
			* float(Config.PPU)


func _sumbu(neg1, neg2, pos1, pos2):
	var v = 0.0
	if Input.is_physical_key_pressed(neg1) or Input.is_physical_key_pressed(neg2):
		v -= 1.0
	if Input.is_physical_key_pressed(pos1) or Input.is_physical_key_pressed(pos2):
		v += 1.0
	return v
