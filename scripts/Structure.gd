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
var dust       = []      # debu yang naik lalu memudar
var luruh      = []      # panel yang sedang runtuh: {p, y}
var collapsing = false
var dirty_img  = false   # world.image berubah — minta canvas.refresh_world()
var last_wave  = 0       # jumlah member yang gagal di gelombang terakhir

# Dibaca lalu dinolkan oleh main.gd untuk memicu getaran dan jeda mikro.
# wave_panjang > 0 berarti baru saja ada gelombang; wave_index == 1 berarti itu
# gelombang pertama sebuah rantai.
var wave_panjang = 0.0
var wave_index   = 0

var dirty_caps = false   # ada joint/member yang melemah — cek gagal ulang

var _timer = 0.0
var _iter  = 0
var _last_cap = 0.0


func setup(w):
	world = w
	queue = []
	falling = []
	dust = []
	luruh = []
	collapsing = false
	dirty_img = false
	last_wave = 0
	wave_panjang = 0.0
	wave_index = 0
	dirty_caps = false
	_timer = 0.0
	_iter = 0
	_last_cap = Config.KAPASITAS_MAX
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
		if m.beban > world.kapasitas(m):
			out.append(m.id)
	return out


func _ada_tumpuan(m):
	for bid in m.member_bawah:
		if world.members[bid].alive:
			return true
	return false


# Nol berarti gedung sudah rata. Member dan joint dihitung bersama supaya
# melemahkan sambungan pun langsung menggerakkan bar di HUD.
# Gedung dianggap runtuh saat tidak ada KOLOM yang tersisa — kolomlah yang
# menahannya berdiri.
#
# Sengaja bukan "semua member mati". Balok level dasar berdiri di pondasi, jadi
# tidak pernah gagal karena kehilangan tumpuan, dan akar hanya menyasar kolom.
# Kalau seluruh panel sudah jatuh, fasadnya lenyap dan sulur tidak punya tempat
# hidup lagi — balok dasar itu jadi mustahil dijangkau siapa pun dan permainan
# buntu. Kolom selalu bisa dihabisi akar dari bawah tanah, jadi kemenangan
# selalu terjangkau.
func hancur():
	for m in world.members:
		if m.alive and m.tipe == Config.M_KOLOM:
			return false
	return true


func integritas_total():
	var n = world.members.size() + world.joints.size()
	if n == 0:
		return 0.0
	var sisa = 0.0
	for m in world.members:
		if m.alive:
			sisa += m.integritas
	# Joint yang semua membernya sudah mati tidak lagi berarti apa-apa, jadi
	# dihitung nol. Tanpa ini bar berhenti di 39% walau gedungnya sudah rata.
	for j in world.joints:
		for mid in j.member_terhubung:
			if world.members[mid].alive:
				sisa += j.integritas
				break
	return sisa / float(n)


# ---------------------------------------------------------------------------
# Pelemahan oleh tanaman
# ---------------------------------------------------------------------------

# Sulur menyerang joint, akar menyerang member pondasi. Mengembalikan biaya
# energi; TreeSim yang memiliki energi, jadi pemanggil yang membelanjakannya.
# Kalau energi tidak cukup, tidak ada yang melemah sama sekali.
func weaken(sim, delta):
	var sasaran = []
	for s in sim.strands:
		if not s.alive:
			continue
		if s.is_root:
			var f = world.foundation_at(s.tip, Config.JOINT_RADIUS)
			if f != null:
				sasaran.append(f)
		else:
			var j = world.nearest_joint(s.tip, Config.JOINT_RADIUS)
			if j != null:
				sasaran.append(j)

	if sasaran.empty():
		return 0.0

	# laju yang sama seperti satu ujung yang tumbuh biasa
	var biaya = sasaran.size() * 9.0 * Config.COST_PER_PIXEL * delta
	if sim.energy < biaya:
		return 0.0

	for t in sasaran:
		t.integritas = max(0.0, t.integritas - Config.WEAKEN_RATE * delta)
	dirty_caps = true
	return biaya


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
	_dust_step(delta)
	_luruh_step(delta)

	# KAPASITAS_MAX bisa digeser lewat panel tuning saat bermain, dan itu
	# mengubah ambang gagal setiap member sekaligus.
	if Config.KAPASITAS_MAX != _last_cap:
		_last_cap = Config.KAPASITAS_MAX
		dirty_caps = true

	# Beban tidak berubah saat integritas turun — hanya kapasitasnya. Jadi
	# solve() tetap event-driven; yang dicek ulang hanya ambang gagalnya, dan
	# itu pun hanya kalau ada yang benar-benar melemah frame ini.
	if dirty_caps and not collapsing:
		dirty_caps = false
		var f = _failures()
		if not f.empty():
			queue = f
			collapsing = true
			_timer = 0.0
			_iter = 0

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
	wave_index = _iter
	wave_panjang = 0.0
	for id in queue:
		wave_panjang = wave_panjang + world.members[id].panjang
		_kill(world.members[id])
	queue = []

	# panel dicek setelah member mati, jadi runtuhnya menyusul di gelombang
	# yang sama dan terbaca sebagai satu kejadian
	wave_panjang = wave_panjang + _runtuhkan_panel()

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
	_spawn_dust(m)
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


# Panel yang cukup banyak penopangnya gagal ikut jatuh, membawa serta massa
# dindingnya. Tanpa ini, menghancurkan seluruh rangka hanya menghapus 31 garis
# selebar 3 piksel dan gedungnya tetap berdiri utuh di layar.
# Mengembalikan besaran untuk getaran layar.
func _runtuhkan_panel():
	var besar = 0.0
	for p in world.panels:
		if not p.alive:
			continue
		var mati = 0
		for mid in p.rangka:
			if not world.members[mid].alive:
				mati += 1
		if mati < Config.PANEL_AMBANG:
			continue
		p.alive = false
		luruh.append({"p": p, "y": float(p.y0)})
		_spawn_dust_panel(p)
		besar += float(p.x1 - p.x0 + p.y1 - p.y0)
	return besar


# Panel diluruhkan baris demi baris dari atas, dengan puing lahir di baris yang
# sedang lenyap. Menghapusnya sekaligus membuat dinding hilang dalam satu frame
# dan yang tersisa hanya awan titik — tidak ada massa yang terasa jatuh.
func _luruh_step(delta):
	if luruh.empty():
		return
	var sisa = []
	for l in luruh:
		var dari = int(l.y)
		l.y = l.y + Config.PANEL_LURUH * delta
		var sampai = int(l.y) - 1
		if sampai >= dari:
			world.carve_rows(l.p, dari, sampai)
			_spawn_debris_baris(l.p, dari, min(sampai, l.p.y1))
			dirty_img = true
		if l.y < float(l.p.y1 + 1):
			sisa.append(l)
	luruh = sisa


func _spawn_debris_baris(p, ya, yb):
	var tinggi = yb - ya + 1
	if tinggi <= 0:
		return
	var w = p.x1 - p.x0
	var n = int(float(w * tinggi) / float(Config.PUING_PER_LUAS))
	for _k in range(n):
		if falling.size() >= Config.PUING_MAX:
			return
		falling.append({
			"x": p.x0 + randf() * w,
			"y": float(ya) + randf() * tinggi,
			"vx": rand_range(-5.0, 5.0),
			"vy": rand_range(0.0, 6.0),
		})


func _spawn_dust_panel(p):
	for _k in range(Config.DEBU_MAX):
		if dust.size() >= Config.DEBU_MAX_TOTAL:
			return
		dust.append({
			"x": p.x0 + randf() * (p.x1 - p.x0),
			"y": p.y0 + randf() * (p.y1 - p.y0),
			"vx": rand_range(-6.0, 6.0),
			"vy": -rand_range(2.0, Config.DEBU_NAIK),
			"age": 0.0,
		})


func _spawn_dust(m):
	var n = int(rand_range(Config.DEBU_MIN, Config.DEBU_MAX + 1))
	for _k in range(n):
		if dust.size() >= Config.DEBU_MAX_TOTAL:
			return
		var t = randf()
		dust.append({
			"x": m.x0 + (m.x1 - m.x0) * t + rand_range(-2.0, 2.0),
			"y": m.y0 + (m.y1 - m.y0) * t + rand_range(-2.0, 2.0),
			"vx": rand_range(-5.0, 5.0),
			"vy": -rand_range(2.0, Config.DEBU_NAIK),
			"age": 0.0,
		})


func _dust_step(delta):
	if dust.empty():
		return
	var sisa = []
	for d in dust:
		d.age = d.age + delta
		if d.age >= Config.DEBU_UMUR:
			continue
		d.x = d.x + d.vx * delta
		d.y = d.y + d.vy * delta
		d.vx = d.vx * 0.96   # melambat, lalu menggantung
		d.vy = d.vy * 0.97
		sisa.append(d)
	dust = sisa


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
