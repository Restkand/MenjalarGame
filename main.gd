extends Node2D

const WorldMapCls    = preload("res://scripts/WorldMap.gd")
const TreeSimCls     = preload("res://scripts/TreeSim.gd")
const CycleCls       = preload("res://scripts/Cycle.gd")
const CrewCls        = preload("res://scripts/Crew.gd")
const StructureCls   = preload("res://scripts/Structure.gd")
const PixelCanvasCls = preload("res://scripts/PixelCanvas.gd")
const TuningPanelCls = preload("res://scripts/TuningPanel.gd")
const HudCls         = preload("res://scripts/Hud.gd")

var world
var sim
var cycle
var crew
var structure
var canvas
var panel
var hud

var is_steering = false
var playing = false
var won = false
var show_risk = false
var show_frame = false
var _freeze = 0.0
var _redraw_tree = false


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

	cycle = CycleCls.new()
	cycle.reset()

	crew = CrewCls.new()
	crew.reset()

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
	# dibangun ulang â€” bukan sekadar mereset pohon.
	world.build()
	canvas.set_world_image(world.image)
	structure.setup(world)
	sim.reset()
	cycle.reset()
	crew.reset()
	canvas.clear_tree()
	is_steering = false
	playing = false
	won = false
	show_risk = false
	show_frame = false
	_freeze = 0.0
	_redraw_tree = false
	hud.show_overlay()


func _mouse_sim():
	return get_viewport().get_mouse_position() / float(Config.SCALE)


func _try_branch():
	# pohon di dekat kursor jadi titik awal baru, kalau ada
	if sim.branch_at(_mouse_sim()):
		return
	if sim.branch():
		return
	if sim.selected == null or not sim.selected.alive:
		hud.flash_msg("Pilih ujung dulu (klik kiri)")
	elif sim.energy < Config.COST_BRANCH:
		hud.flash_msg("Energi kurang â€” butuh %d" % int(Config.COST_BRANCH))
	else:
		hud.flash_msg("Batas untai tercapai")


func _process(delta):
	delta = min(delta, 1.0 / 30.0)
	var m = _mouse_sim()

	if _freeze > 0.0:
		# jeda mikro â€” simulasi beku, render dan getaran tetap jalan
		_freeze = max(0.0, _freeze - delta)
	else:
		# berjalan juga sebelum MULAI, supaya uji klik-kanan bisa dilakukan
		structure.update(delta)

		if structure.wave_panjang > 0.0:
			canvas.add_shake(structure.wave_panjang * Config.SHAKE_PER_PANJANG)
			if structure.wave_index == 1:
				_freeze = Config.FREEZE_TIME
			structure.wave_panjang = 0.0
			# fasad baru saja berlubang â€” ujung yang kehilangan pijakan mundur
			if sim.retreat_unsupported(world) > 0:
				# titik yang menggantung di atas lubang sudah dibuang, jadi
				# lapisan pohon harus digambar ulang dari nol
				_redraw_tree = true
				sim.ensure_selection(cycle.phase)

		if structure.dirty_img:
			structure.dirty_img = false
			canvas.refresh_world()

		if playing and not won:
			sim.update(delta, is_steering, m, world, cycle.phase)
			cycle.update(delta, sim)
			sim.spend(structure.weaken(sim, delta, cycle.phase))

			crew.update(delta, sim, world, structure, cycle.phase)
			if crew.dipotong > 0:
				# titik sudah dibuang dari untai, jadi lapisan pohon yang
				# akumulatif harus digambar ulang dari nol
				_redraw_tree = true
				sim.ensure_selection(cycle.phase)

	var gambar_penuh = _redraw_tree
	_redraw_tree = false
	if gambar_penuh:
		canvas.clear_tree()

	canvas.begin_frame()
	sim.render(canvas, gambar_penuh)
	canvas.draw_cracks(world)
	if show_risk:
		canvas.draw_risk(world)
	if show_frame:
		canvas.draw_frame(world)
	canvas.draw_crew(crew)
	canvas.draw_debris(structure.falling)
	canvas.draw_dust(structure.dust)
	if playing and is_steering and sim.selected != null and sim.selected.alive:
		canvas.draw_preview(sim.selected.preview(m, 40, world))

	# Menang saat seluruh member gedung gagal. Menggantikan syarat coverage
	# 55%, yang sudah tidak nyambung sejak konsepnya bergeser ke pembongkaran
	# dan bar HUD diganti integritas struktur.
	if playing and not won and structure.hancur():
		won = true
	canvas.end_frame()

	canvas.set_night(cycle.night_amount())
	hud.refresh(sim, cycle, structure, crew, won)


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
			sim.select_near(m, cycle.phase)
			is_steering = true
		elif event.button_index == BUTTON_RIGHT:
			if sim.select_near(m, cycle.phase):
				_try_branch()

	if event is InputEventKey and event.pressed and not event.echo:
		if event.scancode == KEY_SPACE:
			_try_branch()
		elif event.scancode == KEY_X:
			sim.stop_selected()
