extends RefCounted

var points     = []
var leaves     = []
var tip        = Vector2()
var angle      = 0.0
var is_root    = false
var alive      = true
var generation = 0
var id         = 0
var _acc       = 0.0
var _leaf_acc  = 0.0
var berakar    = 0.0   # kemajuan menjadi pohon saat berdiri di atas puing
var tembus     = -1.0  # menembus beton: -1 = tidak; 0..1 = kemajuan bor


func _init(x, y, a, root, gen, sid):
	tip = Vector2(x, y)
	points = [Vector2(x, y)]
	angle = a
	is_root = root
	generation = gen
	id = sid

func solid_at(world, x, y):
	if is_root:
		var k = world.at(int(round(x)), int(round(y)))
		# beton solid TAPI bisa ditembus (klik ujung, bayar energi);
		# batu solid selamanya. Akuifer, humus, gorong, dan utilitas semua
		# bisa dilalui — utilitas dihukum lewat perhatian, bukan tembok.
		return k == Config.T_CONCRETE or k == Config.T_BATU \
				or k == Config.T_NEIGHBOR or y < Config.GROUND_Y
	return not world.vine_ok(x, y)


func normal_at(world, x, y):
	var n = Vector2()
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			if dx == 0 and dy == 0:
				continue
			if solid_at(world, x + dx, y + dy):
				n.x -= dx
				n.y -= dy
	if n.length() < 0.001:
		return Vector2(0, -1)
	return n.normalized()


func on_puing(world):
	return world.at(int(round(tip.x)), int(round(tip.y))) == Config.T_PUING


func grow(delta, steer, t, world, laju = 1.0):
	var target = angle
	if steer != null:
		target = steer
	target += sin(t * 2.7 + id * 13.0) * Config.NOISE_AMOUNT * delta

	var d = wrapf(target - angle, -PI, PI)
	angle += clamp(d, -Config.MAX_TURN * delta, Config.MAX_TURN * delta)

	var spd = Config.GROWTH_SPEED if is_root else Config.VINE_SPEED
	var step = spd * laju * delta
	var np = Vector2(tip.x + cos(angle) * step, tip.y + sin(angle) * step)

	if np.x < 2.0 or np.x > Config.W - 3.0:
		angle = PI - angle
		np = Vector2(tip.x + cos(angle) * step, tip.y + sin(angle) * step)
	if np.y < 2.0 or np.y > Config.H - 3.0:
		angle = -angle
		np = Vector2(tip.x + cos(angle) * step, tip.y + sin(angle) * step)

	# tigmotropisme — membelok lalu menyusuri
	if solid_at(world, np.x, np.y):
		var n = normal_at(world, np.x, np.y)
		var tv = Vector2(-n.y, n.x)
		if tv.dot(Vector2(cos(angle), sin(angle))) < 0.0:
			tv = -tv
		angle = atan2(tv.y, tv.x)
		np = Vector2(tip.x + tv.x * step, tip.y + tv.y * step)
		if solid_at(world, np.x, np.y):
			np += n
			if solid_at(world, np.x, np.y):
				return 0.0

	tip = np
	var gained = 0.0

	_acc += step
	if _acc >= 1.0:
		_acc -= 1.0
		points.append(Vector2(tip.x, tip.y))
		if not is_root:
			gained = world.vis_at(int(round(tip.x)), int(round(tip.y)))
			# jejak rambatan: pijakan kekal + bahan bakar erosi + tutupan
			world.rambati(int(round(tip.x)), int(round(tip.y)))
		if points.size() > Config.STRAND_MAX_TITIK:
			points.remove_at(0)

	if not is_root:
		_leaf_acc += step
		if _leaf_acc >= Config.LEAF_SPACING:
			_leaf_acc -= Config.LEAF_SPACING
			_spawn_leaf(world)

	return gained


func _spawn_leaf(world):
	if leaves.size() > 60 or not world.on_facade(tip.x, tip.y):
		return
	var side = 1.0 if randf() < 0.5 else -1.0
	var off = Vector2(-sin(angle), cos(angle)) * randf_range(1.0, 3.0) * side
	var p = tip + off
	if not world.on_facade(p.x, p.y):
		p = tip
	# varian dipakai DaunView untuk memilih sprite dari atlas — disimpan di
	# sini supaya tiap daun tidak berganti bentuk antar frame
	leaves.append({"pos": p, "age": 0.0, "varian": randi() % 4})


func age_leaves(delta):
	for l in leaves:
		l.age = min(1.5, l.age + delta)


# retreat_to_facade() dihapus di TAHAP B — lihat catatan di TreeSim.


func trim(n, world = null):
	for _i in range(n):
		if points.size() <= 2:
			alive = false
			return
		var p = points[points.size() - 1]
		# pemangkasan menghapus jejak rambatan — bar HIJAU/zona ikut mundur
		if not is_root and world != null:
			world.hapus_rambatan(int(round(p.x)), int(round(p.y)))
		points.remove_at(points.size() - 1)
	tip = points[points.size() - 1]
	angle = angle + PI
	var keep = []
	for l in leaves:
		if l.pos.distance_to(tip) < 120.0:
			keep.append(l)
	leaves = keep


func preview(mouse, length, world):
	var out = []
	var a = angle
	var p = Vector2(tip.x, tip.y)
	var spd = Config.GROWTH_SPEED if is_root else Config.VINE_SPEED
	var turn_px = Config.MAX_TURN / max(0.001, spd)
	for _i in range(int(length)):
		var a2 = a
		if p.distance_to(mouse) > Config.DEAD_ZONE:
			a2 = atan2(mouse.y - p.y, mouse.x - p.x)
		var d = wrapf(a2 - a, -PI, PI)
		a += clamp(d, -turn_px, turn_px)
		var q = Vector2(p.x + cos(a), p.y + sin(a))
		if solid_at(world, q.x, q.y):
			var n = normal_at(world, q.x, q.y)
			var tv = Vector2(-n.y, n.x)
			if tv.dot(Vector2(cos(a), sin(a))) < 0.0:
				tv = -tv
			a = atan2(tv.y, tv.x)
			q = Vector2(p.x + tv.x, p.y + tv.y)
		p = q
		out.append(Vector2(p.x, p.y))
	return out
