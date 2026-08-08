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
		return k == Config.T_CONCRETE or k == Config.T_PIPE \
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
	target = _tarik_joint(target, steer, tip, world)
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
		if points.size() > 900:
			points.remove_at(0)

	if not is_root:
		_leaf_acc += step
		if _leaf_acc >= Config.LEAF_SPACING:
			_leaf_acc -= Config.LEAF_SPACING
			_spawn_leaf(world)

	return gained


# Tigmotropisme ke arah sambungan struktur. Hanya sulur — akar tidak mencari
# joint. Saat pemain sedang mengarahkan, deviasinya dibatasi JOINT_TARIK_MAX
# supaya tetap terasa mengusulkan, bukan kehilangan kendali (Logika §5.1).
func _tarik_joint(target, steer, p, world):
	if is_root:
		return target
	var j = world.nearest_joint(p, Config.JOINT_TARIK_RADIUS)
	if j == null:
		return target
	var ke_joint = atan2(j.y - p.y, j.x - p.x)
	if steer == null:
		return ke_joint
	return steer + clamp(wrapf(ke_joint - steer, -PI, PI),
			-Config.JOINT_TARIK_MAX, Config.JOINT_TARIK_MAX)


func _spawn_leaf(world):
	if leaves.size() > 60 or not world.on_facade(tip.x, tip.y):
		return
	var side = 1.0 if randf() < 0.5 else -1.0
	var off = Vector2(-sin(angle), cos(angle)) * randf_range(1.0, 3.0) * side
	var p = tip + off
	if not world.on_facade(p.x, p.y):
		p = tip
	leaves.append({"pos": p, "age": 0.0})


func age_leaves(delta):
	for l in leaves:
		l.age = min(1.5, l.age + delta)


# Fasad di bawah ujung runtuh. Mundur ke titik terakhir yang masih menempel,
# buang bagian yang kini menggantung di atas lubang, lalu lanjut hidup.
# Mengembalikan true kalau untai ini memang terdampak.
func retreat_to_facade(world):
	# Pakai vine_ok(), bukan on_facade() — kalau tidak, sulur yang sedang
	# merentang di atas celah sempit akan dianggap kehilangan pijakan dan
	# ditarik mundur, membatalkan kemampuan menjembatani itu sendiri.
	if is_root or world.vine_ok(tip.x, tip.y):
		return false

	var i = points.size() - 1
	while i >= 0 and not world.vine_ok(points[i].x, points[i].y):
		i -= 1

	if i < 1:
		alive = false   # tidak ada pijakan tersisa sama sekali
		return true

	points.resize(i + 1)
	tip = Vector2(points[i].x, points[i].y)
	angle = angle + PI   # menghadap balik, menjauh dari lubang
	_acc = 0.0
	_leaf_acc = 0.0

	var keep = []
	for l in leaves:
		if world.on_facade(l.pos.x, l.pos.y):
			keep.append(l)
	leaves = keep
	return true


func trim(n):
	for _i in range(n):
		if points.size() <= 2:
			alive = false
			return
		points.remove_at(points.size() - 1)
	tip = points[points.size() - 1]
	angle = angle + PI
	var keep = []
	for l in leaves:
		if l.pos.distance_to(tip) < 60.0:
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
		var st = null
		if p.distance_to(mouse) > Config.DEAD_ZONE:
			st = atan2(mouse.y - p.y, mouse.x - p.x)
			a2 = st
		# pratinjau harus memakai aturan yang sama, termasuk tarikan joint,
		# supaya menunjukkan ke mana sulur benar-benar tumbuh (Logika §11)
		a2 = _tarik_joint(a2, st, p, world)
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
