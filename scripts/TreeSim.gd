extends Reference

const Strand = preload("res://scripts/Strand.gd")

var strands  = []
var selected = null
var time     = 0.0
var energy   = 0.0
var water    = 0.0
var light    = 0.0
var coverage = 0.0
var starved  = false
var _next_id = 0


func reset():
	strands = []
	_next_id = 0
	time = 0.0
	energy = Config.ENERGY_START
	water = 0.0
	light = 0.0
	coverage = 0.0
	starved = false
	var root = _make(Config.SEED_X, Config.GROUND_Y + 1, PI / 2, true, 0)
	var vine = _make(Config.SEED_X, Config.FACADE_Y1 - 2, -PI / 2, false, 0)
	strands.append(root)
	strands.append(vine)
	selected = root


func _make(x, y, a, is_root, gen):
	_next_id += 1
	return Strand.new(x, y, a, is_root, gen, _next_id)


# mengembalikan total nilai keterlihatan pertumbuhan frame ini
func update(delta, steering, mouse, world, phase):
	time += delta
	water = _water(world)
	light = _light(world)

	# Fotosintesis hanya terjadi siang hari
	if phase == Config.PHASE_DAY:
		energy = min(Config.ENERGY_MAX,
				energy + min(water, light) * Config.ENERGY_RATE * delta)

	var growing = []
	for s in strands:
		if not s.alive:
			continue
		if phase == Config.PHASE_DAY and s.is_root:
			growing.append(s)
		elif phase == Config.PHASE_NIGHT and not s.is_root:
			growing.append(s)

	var cost = pow(max(1.0, float(growing.size())), Config.COST_TIP_EXP) \
			* 9.0 * Config.COST_PER_PIXEL * delta
	if energy < cost:
		energy = 0.0
		starved = true
		return 0.0
	energy -= cost
	starved = false

	var seen = 0.0
	for s in growing:
		var steer = null
		if steering and s == selected:
			if s.tip.distance_to(mouse) > Config.DEAD_ZONE:
				steer = atan2(mouse.y - s.tip.y, mouse.x - s.tip.x)
		seen += s.grow(delta, steer, time, world)
		s.age_leaves(delta)
	return seen

func _water(world):
	var w = 1.0   # serapan dasar dari bibit — mencegah kebuntuan
	for s in strands:
		if not s.alive or not s.is_root:
			continue
		var near_pipe = false
		for dy in range(-3, 4):
			for dx in range(-3, 4):
				if world.at(int(round(s.tip.x)) + dx,
						int(round(s.tip.y)) + dy) == Config.T_PIPE:
					near_pipe = true
		if near_pipe:
			w += 3.0
		elif world.at(int(round(s.tip.x)),
				int(round(s.tip.y))) == Config.T_SOIL_WET:
			w += 2.0
		else:
			w += 0.25
	return w

func _light(world):
	var l = 1.0   # daun kotiledon bibit
	for s in strands:
		if s.is_root:
			continue
		for lf in s.leaves:
			l += world.light_at(int(round(lf.pos.x)),
					int(round(lf.pos.y))) * 0.4
	return l

func bottleneck():
	if water < light:
		return "AIR"
	elif light < water:
		return "CAHAYA"
	return ""


func render(canvas, full):
	for s in strands:
		if full:
			canvas.draw_strand_full(s)
		else:
			canvas.draw_strand(s)
	for s in strands:
		canvas.draw_leaves(s)
	for s in strands:
		if s.alive and not s.is_root:
			canvas.draw_heat(s, time)
	for s in strands:
		if s.alive:
			canvas.draw_tip(s.tip, s == selected, time)

func select_near(m, phase):
	var best = 9.0
	var found = null
	for s in strands:
		if not s.alive:
			continue
		if phase == Config.PHASE_DAY and not s.is_root:
			continue
		if phase == Config.PHASE_NIGHT and s.is_root:
			continue
		var d = s.tip.distance_to(m)
		if d < best:
			best = d
			found = s
	if found != null:
		selected = found
		return true
	return false


func ensure_selection(phase):
	if selected != null and selected.alive:
		if phase == Config.PHASE_DAY and selected.is_root:
			return
		if phase == Config.PHASE_NIGHT and not selected.is_root:
			return
	for s in strands:
		if not s.alive:
			continue
		if phase == Config.PHASE_DAY and s.is_root:
			selected = s
			return
		if phase == Config.PHASE_NIGHT and not s.is_root:
			selected = s
			return


func branch():
	if selected == null or not selected.alive:
		return false
	if strands.size() >= Config.MAX_STRANDS or energy < Config.COST_BRANCH:
		return false
	energy -= Config.COST_BRANCH
	var side = 1.0 if randf() < 0.5 else -1.0
	var off = deg2rad(rand_range(25, 40)) * side
	strands.append(_make(selected.tip.x, selected.tip.y,
			selected.angle + off, selected.is_root, selected.generation + 1))
	return true


func spend(amount):
	if amount <= 0.0:
		return
	energy = max(0.0, energy - amount)


# Sulur menempel pada fasad. Kalau fasad di bawah ujungnya lenyap karena
# keruntuhan, ujung itu kehilangan pijakan dan berhenti — badannya tetap
# tergambar. Meruntuhkan gedung berarti ikut menghancurkan pijakan sendiri.
func prune_unsupported(world):
	var n = 0
	for s in strands:
		if not s.alive or s.is_root:
			continue
		if not world.on_facade(s.tip.x, s.tip.y):
			s.alive = false
			n += 1
	return n


func stop_selected():
	if selected != null:
		selected.alive = false

func shed():
	if selected == null or not selected.alive or selected.is_root:
		return false
	if selected.heat < 0.15 or selected.points.size() < 20:
		return false
	selected.trim(Config.SHED_COST)
	selected.heat = 0.0
	return true

func alive_count():
	var n = 0
	for s in strands:
		if s.alive:
			n += 1
	return n
