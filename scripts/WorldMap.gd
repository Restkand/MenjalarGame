extends Reference

var image
var grid
var light
var vis


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
