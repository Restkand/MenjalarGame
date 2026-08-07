extends Reference

var phase     = Config.PHASE_DAY
var t         = 0.0
var suspicion = 0.0
var pos_x     = 20.0
var dir       = 1.0
var gaze      = -PI / 2.0
var did_prune = false
var last_cut  = 0
var flash     = 0.0
var spotting  = false


func reset():
	phase = Config.PHASE_DAY
	t = 0.0
	suspicion = 0.0
	pos_x = 20.0
	dir = 1.0
	gaze = -PI / 2.0
	did_prune = false
	last_cut = 0
	flash = 0.0
	spotting = false


func eye():
	return Vector2(pos_x, Config.GROUND_Y - 8.0)


func phase_len():
	return Config.DAY_LEN if phase == Config.PHASE_DAY else Config.NIGHT_LEN


func progress():
	return t / phase_len()


func night_amount():
	if phase == Config.PHASE_NIGHT:
		return min(1.0, t / 2.5)
	return max(0.0, 1.0 - t / 2.5)


func sees(p, world):
	var e = eye()
	var d = p - e
	if d.length() > Config.GAZE_RANGE:
		return false
	if abs(wrapf(atan2(d.y, d.x) - gaze, -PI, PI)) > Config.GAZE_HALF:
		return false
	return world.vis_at(int(round(p.x)), int(round(p.y))) > 0.42


func update(delta, sim, world, seen):
	did_prune = false
	spotting = false
	flash = max(0.0, flash - delta)

	if phase == Config.PHASE_DAY:
		pos_x += dir * 15.0 * delta
		if pos_x > 214.0:
			pos_x = 214.0; dir = -1.0
		if pos_x < 20.0:
			pos_x = 20.0; dir = 1.0
		gaze = -PI / 2.0 + sin(t * 0.9) * 0.62
		_scan(sim, world, delta)
	else:
		# jejak hanya menumpuk di area yang benar-benar terang
		if sim.selected != null and seen > 0.45:
			sim.selected.heat = min(1.0, sim.selected.heat
					+ (seen - 0.45) * Config.NIGHT_HEAT * delta)

	for s in sim.strands:
		if not s.is_root:
			s.heat = max(0.0, s.heat - Config.HEAT_DECAY * delta)

	suspicion = 0.0
	for s in sim.strands:
		if s.alive and not s.is_root:
			suspicion = max(suspicion, s.heat)

	t += delta
	if t >= phase_len():
		t = 0.0
		if phase == Config.PHASE_DAY:
			_prune(sim)
			phase = Config.PHASE_NIGHT
		else:
			phase = Config.PHASE_DAY
		sim.ensure_selection(phase)


func _scan(sim, world, delta):
	for s in sim.strands:
		if not s.alive or s.is_root or s.points.size() < 4:
			continue
		var hit = 0
		var tot = 0
		for i in s.hot_points():
			tot += 1
			if sees(s.points[i], world):
				hit += 1
		if hit > 0:
			spotting = true
			s.heat = min(1.0,
					s.heat + (float(hit) / max(1, tot)) * Config.HEAT_RATE * delta)


func _prune(sim):
	last_cut = 0
	for s in sim.strands:
		if s.alive and not s.is_root and s.heat >= 1.0:
			s.trim(50)
			s.heat = 0.0
			last_cut += 1
	if last_cut > 0:
		did_prune = true
		flash = 2.0
