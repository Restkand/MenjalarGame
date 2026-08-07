extends Reference

# Aliran beban dan keruntuhan berantai di atas world.members.
#
# Dua sebab member gagal:
#   1. kelebihan beban  — beban > integritas * KAPASITAS_MAX
#   2. kehilangan tumpuan — member_bawah tidak kosong tapi semuanya sudah mati
# member_bawah yang kosong berarti pondasi, dan tidak pernah gagal karena (2).
#
# Keruntuhan berjalan per gelombang, satu gelombang tiap COLLAPSE_STEP detik,
# supaya rantainya terlihat. Beban hanya dihitung ulang saat ada perubahan.

var world
var queue      = []      # id member yang gagal pada gelombang berikutnya
var falling    = []      # puing yang masih melayang
var collapsing = false
var dirty_img  = false   # world.image berubah — minta canvas.refresh_world()
var last_wave  = 0       # jumlah member yang gagal di gelombang terakhir
var _timer     = 0.0
var _iter      = 0


func setup(w):
	world = w
	queue = []
	falling = []
	collapsing = false
	dirty_img = false
	last_wave = 0
	_timer = 0.0
	_iter = 0
	solve()


# ---------------------------------------------------------------------------
# Beban
# ---------------------------------------------------------------------------

func solve():
	for m in world.members:
		m.beban = (m.panjang * Config.BERAT_PER_PIKSEL) if m.alive else 0.0
	# world.solve_order sudah topologis atas-ke-bawah, jadi satu sapuan cukup
	for id in world.solve_order:
		_pass_down(world.members[id])


func _pass_down(m):
	if not m.alive:
		return
	var hidup = []
	for bid in m.member_bawah:
		if world.members[bid].alive:
			hidup.append(bid)
	if hidup.empty():
		return   # pondasi, atau seluruh tumpuan sudah mati
	var bagi = m.beban / float(hidup.size())
	for bid in hidup:
		world.members[bid].beban += bagi


func _failures():
	var out = []
	for m in world.members:
		if not m.alive:
			continue
		if m.member_bawah.size() > 0 and not _ada_tumpuan(m):
			out.append(m.id)
			continue
		if m.beban > m.integritas * Config.KAPASITAS_MAX:
			out.append(m.id)
	return out


func _ada_tumpuan(m):
	for bid in m.member_bawah:
		if world.members[bid].alive:
			return true
	return false


# Nol berarti gedung sudah rata. Dipakai HUD nanti (TAHAP 5).
func integritas_total():
	if world.members.empty():
		return 0.0
	var hidup = 0.0
	for m in world.members:
		if m.alive:
			hidup += m.integritas
	return hidup / float(world.members.size())


# ---------------------------------------------------------------------------
# Keruntuhan
# ---------------------------------------------------------------------------

func fail_member(id):
	if id < 0 or id >= world.members.size():
		return false
	if not world.members[id].alive:
		return false
	if not queue.has(id):
		queue.append(id)
	collapsing = true
	_timer = 0.0
	_iter = 0
	return true


func update(delta):
	_debris_step(delta)
	if not collapsing:
		return

	_timer -= delta
	if _timer > 0.0:
		return
	_timer = Config.COLLAPSE_STEP

	_iter += 1
	if _iter > Config.COLLAPSE_MAX_ITER:
		push_warning("keruntuhan dihentikan setelah %d gelombang"
				% Config.COLLAPSE_MAX_ITER)
		queue = []
		collapsing = false
		return

	last_wave = queue.size()
	for id in queue:
		_kill(world.members[id])
	queue = []

	solve()
	queue = _failures()
	if queue.empty():
		collapsing = false


func _kill(m):
	m.alive = false
	m.beban = 0.0
	m.integritas = 0.0
	world.carve_member(m)
	_spawn_debris(m)
	dirty_img = true


# ---------------------------------------------------------------------------
# Puing
# ---------------------------------------------------------------------------

func _spawn_debris(m):
	var n = int(m.panjang * Config.PUING_PER_PIKSEL)
	for k in range(n):
		if falling.size() >= Config.PUING_MAX:
			return
		var t = float(k) / float(max(1, n - 1))
		falling.append({
			"x": m.x0 + (m.x1 - m.x0) * t + rand_range(-1.0, 1.0),
			"y": m.y0 + (m.y1 - m.y0) * t,
			"vx": rand_range(-7.0, 7.0),
			"vy": rand_range(-4.0, 6.0),
		})


func _debris_step(delta):
	if falling.empty():
		return

	var sisa = []
	var mengendap = []

	for p in falling:
		p.vy = p.vy + Config.PUING_GRAVITASI * delta
		p.x = p.x + p.vx * delta
		p.y = p.y + p.vy * delta

		var ix = int(round(p.x))
		var iy = int(round(p.y))
		if ix < 1 or ix > Config.W - 2 or iy > Config.H - 2:
			continue   # keluar layar, dibuang

		# kalau melesat masuk ke dalam tumpukan, dorong balik ke permukaan
		var guard = 0
		while iy > 1 and world.blocked(ix, iy) and guard < 4:
			iy -= 1
			guard += 1
		p.y = float(iy)

		if not world.blocked(ix, iy + 1):
			sisa.append(p)
			continue

		# falling sand — kalau tepat di bawah terhalang, coba serong dulu
		# supaya tumpukan melandai, bukan jadi menara
		if not world.blocked(ix - 1, iy + 1):
			p.x = p.x - 1.0
			p.vy = p.vy * 0.4
			sisa.append(p)
		elif not world.blocked(ix + 1, iy + 1):
			p.x = p.x + 1.0
			p.vy = p.vy * 0.4
			sisa.append(p)
		else:
			mengendap.append(Vector2(ix, iy))

	falling = sisa
	if not mengendap.empty():
		world.settle_many(mengendap)
		dirty_img = true
