extends Node2D

const WorldMapCls    = preload("res://scripts/WorldMap.gd")
const TreeSimCls     = preload("res://scripts/TreeSim.gd")
const WardenCls      = preload("res://scripts/Warden.gd")
const StructureCls   = preload("res://scripts/Structure.gd")
const PixelCanvasCls = preload("res://scripts/PixelCanvas.gd")
const TuningPanelCls = preload("res://scripts/TuningPanel.gd")
const HudCls         = preload("res://scripts/Hud.gd")

var world
var sim
var warden
var structure
var canvas
var panel
var hud

var is_steering = false
var playing = false
var won = false
var show_risk = false
var show_frame = false
var _cov_t = 0.0


func _ready():
	randomize()

	world = WorldMapCls.new()
	world.build()

	canvas = PixelCanvasCls.new()
	add_child(canvas)
	canvas.setup(world.image)

	structure = StructureCls.new()
	structure.setup(world)

	sim = TreeSimCls.new()
	sim.reset()

	warden = WardenCls.new()
	warden.reset()

	panel = TuningPanelCls.new()
	add_child(panel)
	panel.connect("reset_pressed", self, "_restart")

	hud = HudCls.new()
	add_child(hud)
	hud.connect("play_pressed", self, "_on_play")


func _on_play():
	playing = true


func _restart():
	# Keruntuhan mengubah grid dan image secara permanen, jadi dunianya harus
	# dibangun ulang — bukan sekadar mereset pohon.
	world.build()
	canvas.set_world_image(world.image)
	structure.setup(world)
	sim.reset()
	warden.reset()
	canvas.clear_tree()
	is_steering = false
	playing = false
	won = false
	show_risk = false
	show_frame = false
	hud.show_overlay()


func _mouse_sim():
	return get_viewport().get_mouse_position() / float(Config.SCALE)


func _try_branch():
	if sim.branch():
		return
	if sim.selected == null or not sim.selected.alive:
		hud.flash_msg("Pilih ujung dulu (klik kiri)")
	elif sim.energy < Config.COST_BRANCH:
		hud.flash_msg("Energi kurang — butuh %d" % int(Config.COST_BRANCH))
	else:
		hud.flash_msg("Batas untai tercapai")


func _process(delta):
	delta = min(delta, 1.0 / 30.0)
	var m = _mouse_sim()
	var seen = 0.0

	# berjalan juga sebelum MULAI, supaya uji klik-kanan bisa dilakukan
	structure.update(delta)
	if structure.dirty_img:
		structure.dirty_img = false
		canvas.refresh_world()

	if playing and not won:
		seen = sim.update(delta, is_steering, m, world, warden.phase)
		warden.update(delta, sim, world, seen)

	if warden.did_prune:
		canvas.clear_tree()

	canvas.begin_frame()
	sim.render(canvas, warden.did_prune)
	if show_risk:
		canvas.draw_risk(world)
	if show_frame:
		canvas.draw_frame(world)
	canvas.draw_warden(warden, world)
	canvas.draw_debris(structure.falling)
	if playing and is_steering and sim.selected != null and sim.selected.alive:
		canvas.draw_preview(sim.selected.preview(m, 40, world))

	_cov_t += delta
	if _cov_t > 0.5:
		_cov_t = 0.0
		sim.coverage = canvas.count_covered()
		if sim.coverage >= Config.COVERAGE_GOAL:
			won = true
	canvas.end_frame()

	canvas.set_night(warden.night_amount())
	hud.refresh(sim, warden, won)


func _input(event):
	if event is InputEventMouseButton and not event.pressed \
			and event.button_index == BUTTON_LEFT:
		is_steering = false

	if event is InputEventKey and event.scancode == KEY_V:
		show_risk = event.pressed

	if event is InputEventKey and event.scancode == KEY_B:
		show_frame = event.pressed


func _unhandled_input(event):
	# tombol yang selalu aktif, bahkan sebelum MULAI
	if event is InputEventKey and event.pressed and not event.echo:
		if event.scancode == KEY_R:
			_restart()
			return
		elif event.scancode == KEY_TAB:
			panel.toggle()
			return

	# uji keruntuhan: tahan B lalu klik kanan pada member. Disyaratkan
	# show_frame supaya tidak bentrok dengan klik-kanan-bercabang.
	if show_frame and event is InputEventMouseButton and event.pressed \
			and event.button_index == BUTTON_RIGHT:
		var id = world.member_at(_mouse_sim(), 6.0)
		if id >= 0:
			structure.fail_member(id)
		return

	if not playing or won:
		return

	if event is InputEventMouseButton and event.pressed:
		var m = _mouse_sim()
		if event.button_index == BUTTON_LEFT:
			sim.select_near(m, warden.phase)
			is_steering = true
		elif event.button_index == BUTTON_RIGHT:
			if sim.select_near(m, warden.phase):
				_try_branch()

	if event is InputEventKey and event.pressed and not event.echo:
		if event.scancode == KEY_SPACE:
			_try_branch()
		elif event.scancode == KEY_X:
			if warden.phase == Config.PHASE_DAY:
				if not sim.shed():
					hud.flash_msg("Tidak ada yang perlu dirontokkan")
			else:
				sim.stop_selected()
