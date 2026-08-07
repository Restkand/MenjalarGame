extends Reference

var image
var grid
var light
var vis
var members = []
var joints  = []


func build():
	image = Image.new()
	image.create(Config.W, Config.H, false, Image.FORMAT_RGBA8)
	grid = PoolByteArray(); grid.resize(Config.W * Config.H)
	light = PoolRealArray(); light.resize(Config.W * Config.H)
	vis = PoolRealArray(); vis.resize(Config.W * Config.H)

	image.lock()
	_rect(0, 0, Config.W, Config.GROUND_Y, Config.C_SKY, Config.T_SKY)
	_rect(0, Config.GROUND_Y, Config.W, Config.H - Config.GROUND_Y,
			Config.C_SOIL, Config.T_SOIL_DRY)
	_rect(0, 128, 74, 32, Config.C_SOIL_WET, Config.T_SOIL_WET)
	_rect(168, 132, 72, 28, Config.C_SOIL_WET, Config.T_SOIL_WET)
	_rect(60, 120, 26, 12, Config.C_CONCRETE, Config.T_CONCRETE)
	_rect(198, 142, 22, 5, Config.C_PIPE, Config.T_PIPE)

	# gedung tetangga di kiri — sumber bayangan
	_rect(0, 34, 40, 78, Config.C_NEIGHBOR, Config.T_NEIGHBOR)

	# fasad utama
	_rect(Config.FACADE_X0, Config.FACADE_Y0,
			Config.FACADE_X1 - Config.FACADE_X0,
			Config.FACADE_Y1 - Config.FACADE_Y0,
			Config.C_WALL, Config.T_WALL)

	# jendela
	for jy in range(22, 100, 20):
		for jx in range(54, 190, 22):
			_rect(jx, jy, 10, 12, Config.C_WINDOW, Config.T_WINDOW)

	# ledge — penghalang yang harus diputari
	_rect(46, 58, 60, 3, Config.C_LEDGE, Config.T_LEDGE)
	_rect(134, 38, 60, 3, Config.C_LEDGE, Config.T_LEDGE)
	_rect(100, 82, 70, 3, Config.C_LEDGE, Config.T_LEDGE)

	# pintu
	_rect(108, 92, 24, 20, Config.C_DOOR, Config.T_DOOR)

	# jalur pipa vertikal — koridor gelap untuk menyelinap
	_rect(74, Config.FACADE_Y0, 4, 100, Config.C_LEDGE, Config.T_LEDGE)

	image.unlock()
	_bake_light()
	_bake_vis()
	_build_frame()


func _rect(x, y, w, h, col, kind):
	for j in range(y, y + h):
		for i in range(x, x + w):
			if i < 0 or i >= Config.W or j < 0 or j >= Config.H:
				continue
			image.set_pixel(i, j, col)
			grid.set(j * Config.W + i, kind)


func _bake_light():
	var y = Config.FACADE_Y0
	while y < Config.FACADE_Y1:
		var x = Config.FACADE_X0
		while x < Config.FACADE_X1:
			var v = 1.0 if _ray_clear(x, y) else 0.16
			for dy in range(0, 2):
				for dx in range(0, 2):
					var i = (y + dy) * Config.W + (x + dx)
					if i >= 0 and i < light.size():
						light.set(i, v)
			x += 2
		y += 2


func _ray_clear(sx, sy):
	var x = float(sx)
	var y = float(sy)
	for _i in range(170):
		x += Config.SUN_RAY.x
		y += Config.SUN_RAY.y
		if y < 0 or x < 0:
			return true
		var k = at(int(round(x)), int(round(y)))
		if k == Config.T_NEIGHBOR or k == Config.T_LEDGE:
			return false
	return true


func _bake_vis():
	for y in range(Config.FACADE_Y0, Config.FACADE_Y1):
		for x in range(Config.FACADE_X0, Config.FACADE_X1):
			var i = y * Config.W + x
			var h = float(y - Config.FACADE_Y0) \
					/ float(Config.FACADE_Y1 - Config.FACADE_Y0)
			var v = 0.20 + 0.48 * light[i] + 0.28 * h
			var k = grid[i]
			if k == Config.T_WINDOW:
				v += 0.30
			if k == Config.T_DOOR or y > Config.FACADE_Y1 - 14:
				v += 0.30
			if k == Config.T_LEDGE:
				v -= 0.28
			vis.set(i, clamp(v, 0.0, 1.0))


# ---------------------------------------------------------------------------
# Rangka struktural
#
# Lapisan data murni di atas grid terrain. grid, image, light, dan vis tidak
# tersentuh sama sekali. Belum ada perhitungan beban dan belum ada keruntuhan
# — itu TAHAP 3.
#
# Kolom dan balok disimpan sebagai RUAS antar-joint, bukan satu member utuh,
# supaya beban punya kisi untuk mengalir. Di layar tetap tampak 4 kolom dan
# 5 balok.
#
# _kolom_id() dan _balok_id() menghitung id dari koordinat kisi, jadi urutan
# pembuatan di _build_frame() mengikat: SELURUH ruas kolom dibuat lebih dulu,
# baru seluruh ruas balok.
# ---------------------------------------------------------------------------

func _build_frame():
	members = []
	joints = []

	var cx = []   # x tiap garis kolom
	for i in range(Config.FRAME_COLS):
		cx.append(Config.FACADE_X0 + int(round(
				float(i) * float(Config.FACADE_X1 - 1 - Config.FACADE_X0)
				/ float(Config.FRAME_COLS - 1))))

	var ry = []   # y tiap level balok
	for j in range(Config.FRAME_ROWS):
		ry.append(Config.FACADE_Y0 + int(round(
				float(j) * float(Config.FACADE_Y1 - 1 - Config.FACADE_Y0)
				/ float(Config.FRAME_ROWS - 1))))

	# joint di tiap perpotongan — id = j * FRAME_COLS + i
	for j in range(Config.FRAME_ROWS):
		for i in range(Config.FRAME_COLS):
			joints.append({
				"id": joints.size(),
				"x": cx[i],
				"y": ry[j],
				"col": i,
				"row": j,
				"member_terhubung": [],
				"integritas": 1.0,
			})

	# ruas kolom — wajib dibuat lebih dulu, lihat _kolom_id()
	for i in range(Config.FRAME_COLS):
		for j in range(Config.FRAME_ROWS - 1):
			_add_member(Config.M_KOLOM, cx[i], ry[j], cx[i], ry[j + 1],
					_joint_id(i, j), _joint_id(i, j + 1))

	# ruas balok
	for j in range(Config.FRAME_ROWS):
		for i in range(Config.FRAME_COLS - 1):
			_add_member(Config.M_BALOK, cx[i], ry[j], cx[i + 1], ry[j],
					_joint_id(i, j), _joint_id(i + 1, j))

	_link_supports()


func _add_member(tipe, x0, y0, x1, y1, ja, jb):
	var m = {
		"id": members.size(),
		"x0": x0, "y0": y0,
		"x1": x1, "y1": y1,
		"tipe": tipe,
		"integritas": 1.0,
		"beban": 0.0,
		"member_bawah": [],
		"joint_a": ja,
		"joint_b": jb,
	}
	members.append(m)
	joints[ja].member_terhubung.append(m.id)
	joints[jb].member_terhubung.append(m.id)
	return m.id


func _link_supports():
	# Ruas kolom ditopang ruas kolom di bawahnya. Yang paling bawah berdiri di
	# pondasi, jadi member_bawah-nya kosong.
	for i in range(Config.FRAME_COLS):
		for j in range(Config.FRAME_ROWS - 1):
			var below = _kolom_id(i, j + 1)
			if below >= 0:
				members[_kolom_id(i, j)].member_bawah.append(below)

	# Ruas balok ditopang ruas kolom yang menggantung di bawah kedua joint
	# ujungnya. Di level paling bawah tidak ada kolom di bawahnya — pondasi.
	for j in range(Config.FRAME_ROWS):
		for i in range(Config.FRAME_COLS - 1):
			var b = members[_balok_id(i, j)]
			for k in [i, i + 1]:
				var kid = _kolom_id(k, j)
				if kid >= 0:
					b.member_bawah.append(kid)


func _joint_id(i, j):
	return j * Config.FRAME_COLS + i


func _kolom_id(i, j):
	# ruas kolom pada garis kolom i, antara level balok j dan j+1
	if i < 0 or i >= Config.FRAME_COLS or j < 0 or j >= Config.FRAME_ROWS - 1:
		return -1
	return i * (Config.FRAME_ROWS - 1) + j


func _balok_id(i, j):
	# ruas balok pada level j, antara garis kolom i dan i+1
	if i < 0 or i >= Config.FRAME_COLS - 1 or j < 0 or j >= Config.FRAME_ROWS:
		return -1
	return Config.FRAME_COLS * (Config.FRAME_ROWS - 1) \
			+ j * (Config.FRAME_COLS - 1) + i


func at(x, y):
	if x < 0 or x >= Config.W or y < 0 or y >= Config.H:
		return Config.T_NEIGHBOR
	return grid[y * Config.W + x]


func light_at(x, y):
	if x < 0 or x >= Config.W or y < 0 or y >= Config.H:
		return 0.0
	return light[y * Config.W + x]


func vis_at(x, y):
	if x < 0 or x >= Config.W or y < 0 or y >= Config.H:
		return 0.0
	return vis[y * Config.W + x]


func on_facade(x, y):
	var k = at(int(round(x)), int(round(y)))
	return k == Config.T_WALL or k == Config.T_WINDOW or k == Config.T_DOOR
