extends Reference

const Strand = preload("res://scripts/Strand.gd")

var strands  = []
var selected = null
var time     = 0.0
var energy   = 0.0
var water    = 0.0
var light    = 0.0
var starved  = false
var _next_id = 0
var _world   = null


func reset():
	strands = []
	_next_id = 0
	time = 0.0
	energy = Config.ENERGY_START
	water = 0.0
	light = 0.0
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
	# Disimpan supaya select_near() dan ensure_selection() bisa memeriksa
	# apakah sebuah untai berdiri di atas puing, tanpa harus mengubah
	# tanda tangan mereka di Cycle dan main.
	_world = world
	time += delta
	water = _water(world)
	light = _light(world)

	# Fotosintesis hanya terjadi siang hari
	if phase == Config.PHASE_DAY:
		energy = min(Config.ENERGY_MAX,
				energy + min(water, light) * Config.ENERGY_RATE * delta)

	# Yang sefase tumbuh penuh. Yang berdiri di atas puing tetap menjalar
	# walau di luar fasenya, tapi lebih pelan — puing itu tanah subur, dan
	# itu yang membuat dunia selalu terlihat menghijau sendiri.
	var growing = []
	var bobot = 0.0
	for s in strands:
		if not s.alive:
			continue
		var laju = 0.0
		if _sefase(s, phase):
			laju = 1.0
		elif s.on_puing(world):
			laju = Config.PUING_LAMBAT
		if laju <= 0.0:
			continue
		growing.append({"s": s, "laju": laju})
		bobot += laju

	# Biaya ditimbang laju, jadi pertumbuhan pelan di puing juga lebih murah.
	var cost = pow(max(1.0, bobot), Config.COST_TIP_EXP) \
			* 9.0 * Config.COST_PER_PIXEL * delta
	if energy < cost:
		energy = 0.0
		starved = true
		return 0.0
	energy -= cost
	starved = false

	# Seberapa mencolok pertumbuhan malam ini, dari peta vis. Belum ada yang
	# memakainya sejak sistem stealth dihapus, tapi ini persis sinyal yang
	# dibutuhkan regu perawatan nanti: seberapa cepat mereka menemukannya.
	var seen = 0.0
	for g in growing:
		var s = g.s
		var steer = null
		if steering and s == selected:
			if s.tip.distance_to(mouse) > Config.DEAD_ZONE:
				steer = atan2(mouse.y - s.tip.y, mouse.x - s.tip.x)
		seen += s.grow(delta, steer, time, world, g.laju)
		s.age_leaves(delta)
	return seen


func _sefase(s, phase):
	if phase == Config.PHASE_DAY:
		return s.is_root
	return not s.is_root

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
		if s.alive:
			canvas.draw_tip(s.tip, s == selected, time)

# Yang sefase selalu bisa dipilih. Yang menjalar sendiri di atas puing juga —
# kalau tidak, pemain menonton sesuatu tumbuh tanpa bisa menyentuhnya.
func _bisa_dipilih(s, phase):
	if not s.alive:
		return false
	if _sefase(s, phase):
		return true
	return _world != null and s.on_puing(_world)


func select_near(m, phase):
	var best = 9.0
	var found = null
	for s in strands:
		if not _bisa_dipilih(s, phase):
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
	if selected != null and _bisa_dipilih(selected, phase):
		return
	for s in strands:
		if _bisa_dipilih(s, phase):
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
# keruntuhan, ujung itu MUNDUR ke titik terakhir yang masih menempel, bukan
# mati.
#
# Versi pertama mematikannya, dan itu membuat permainan buntu: satu keruntuhan
# berantai melubangi sampai 20 dari 31 member sekaligus, jadi hampir semua
# sulur mati serentak — padahal sulur adalah satu-satunya alat untuk
# melemahkan joint. Mundur tetap menghukum (pertumbuhan hilang, pijakan
# menyempit) tanpa menghabisi permainannya.
func retreat_unsupported(world):
	var n = 0
	for s in strands:
		if not s.alive or s.is_root:
			continue
		if s.retreat_to_facade(world):
			n += 1
	return n


func stop_selected():
	if selected != null:
		selected.alive = false

func alive_count():
	var n = 0
	for s in strands:
		if s.alive:
			n += 1
	return n
