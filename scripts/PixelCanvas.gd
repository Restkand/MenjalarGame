extends Node2D

var _world_img
var _world_tex
var _tree_img
var _tree_tex
var _ovl_img
var _ovl_tex
var _night
var _shake_t   = 0.0
var _shake_amp = 0.0


func setup(world_img):
	_world_img = world_img
	_world_tex = ImageTexture.new()
	_world_tex.create_from_image(_world_img, 0)
	_add_sprite(_world_tex, 0)

	_tree_img = _blank()
	_tree_tex = ImageTexture.new()
	_tree_tex.create_from_image(_tree_img, 0)
	_add_sprite(_tree_tex, 1)

	_ovl_img = _blank()
	_ovl_tex = ImageTexture.new()
	_ovl_tex.create_from_image(_ovl_img, 0)
	_add_sprite(_ovl_tex, 2)
	
	var layer = CanvasLayer.new()
	layer.layer = 5
	add_child(layer)

	_night = ColorRect.new()
	_night.color = Color(0.05, 0.08, 0.20, 0.0)
	_night.rect_size = Vector2(Config.W * Config.SCALE, Config.H * Config.SCALE)
	_night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_night)


# Getaran digeser dalam kelipatan penuh SCALE, jadi kisi pikselnya tetap lurus.
# Menggeser pecahan piksel layar akan membuat pixel art terlihat kotor.
# _night, HUD, dan panel ada di CanvasLayer, jadi tidak ikut bergetar.
func add_shake(amp):
	_shake_amp = max(_shake_amp, min(Config.SHAKE_MAX, amp))
	_shake_t = Config.SHAKE_DECAY


func _process(delta):
	if _shake_t <= 0.0:
		return
	_shake_t = max(0.0, _shake_t - delta)
	if _shake_t <= 0.0:
		_shake_amp = 0.0
		position = Vector2()
		return
	var a = _shake_amp * (_shake_t / Config.SHAKE_DECAY)
	position = Vector2(
			round(rand_range(-a, a)) * Config.SCALE,
			round(rand_range(-a, a)) * Config.SCALE)


# Dipanggil hanya saat piksel dunia benar-benar berubah — member dilubangi
# atau puing mengendap — bukan tiap frame.
func refresh_world():
	_world_tex.set_data(_world_img)


# world.build() membuat Image baru, jadi setelah reset teksturnya harus
# diarahkan ulang ke objek yang baru.
func set_world_image(world_img):
	_world_img = world_img
	_world_tex.create_from_image(_world_img, 0)


func set_night(a):
	_night.color = Color(0.05, 0.08, 0.20, a * 0.55)


func _blank():
	var img = Image.new()
	img.create(Config.W, Config.H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


func _add_sprite(tex, z):
	var s = Sprite.new()
	s.texture = tex
	s.centered = false
	s.scale = Vector2(Config.SCALE, Config.SCALE)
	s.z_index = z
	add_child(s)


func begin_frame():
	_ovl_img.fill(Color(0, 0, 0, 0))
	_tree_img.lock()
	_ovl_img.lock()


func end_frame():
	_tree_img.unlock()
	_ovl_img.unlock()
	_tree_tex.set_data(_tree_img)
	_ovl_tex.set_data(_ovl_img)


func clear_tree():
	_tree_img.fill(Color(0, 0, 0, 0))
	_tree_tex.set_data(_tree_img)


func draw_strand(s):
	_paint(s, max(0, s.points.size() - 180))


func draw_strand_full(s):
	_paint(s, 0)


func _paint(s, start):
	var n = s.points.size()
	var col = Config.C_ROOT if s.is_root else Config.C_BRANCH
	for i in range(start, n):
		var th = 0.6 + min(2.2, (n - i) * 0.015) - s.generation * 0.3
		_stamp(_tree_img, s.points[i].x, s.points[i].y, max(0.6, th), col)


func draw_leaves(s):
	for l in s.leaves:
		_stamp(_tree_img, l.pos.x, l.pos.y,
				0.8 if l.age < 1.5 else 1.2, Config.C_LEAF)


func draw_tip(p, is_selected, t):
	var col = Config.C_TIP if fmod(t, 0.6) < 0.3 else Config.C_LEAF
	_stamp(_ovl_img, p.x, p.y, 0.6, col)
	if is_selected:
		var cx = int(round(p.x))
		var cy = int(round(p.y))
		for d in range(-3, 4):
			if abs(d) == 3:
				continue
			_put(_ovl_img, cx + d, cy - 3, Config.C_TIP)
			_put(_ovl_img, cx + d, cy + 3, Config.C_TIP)
			_put(_ovl_img, cx - 3, cy + d, Config.C_TIP)
			_put(_ovl_img, cx + 3, cy + d, Config.C_TIP)


func draw_preview(pts):
	var c = Config.C_TIP
	c.a = 0.55
	for i in range(pts.size()):
		if i % 3 == 0:
			_put(_ovl_img, int(round(pts[i].x)), int(round(pts[i].y)), c)


func draw_warden(w, world):
	if w.phase != Config.PHASE_DAY:
		return

	# kerucut pandang
	var e = w.eye()
	var col = Config.C_WARN
	col.a = 0.5 if w.spotting else 0.26
	var steps = 9
	for k in range(steps + 1):
		var a = w.gaze - Config.GAZE_HALF \
				+ (2.0 * Config.GAZE_HALF) * float(k) / float(steps)
		var d = 6.0
		while d < Config.GAZE_RANGE:
			var px = e.x + cos(a) * d
			var py = e.y + sin(a) * d
			if py < 2 or px < 2 or px > Config.W - 3:
				break
			if int(d) % 4 < 2:
				_put(_ovl_img, int(round(px)), int(round(py)), col)
			d += 1.0

	# badan
	var x = int(round(w.pos_x))
	var y = Config.GROUND_Y
	var bc = Config.C_ALERT if w.spotting else Config.C_WARDEN
	for j in range(y - 9, y):
		for i in range(x - 1, x + 2):
			_put(_ovl_img, i, j, bc)
	_put(_ovl_img, x - 2, y - 6, bc)
	_put(_ovl_img, x + 2, y - 6, bc)


func draw_heat(s, t):
	if s.heat < 0.12:
		return
	var col = Config.C_WARN if s.heat < 0.6 else Config.C_ALERT
	if s.heat >= 0.85 and fmod(t, 0.4) < 0.2:
		return
	for i in s.hot_points():
		if i % 3 == 0:
			_put(_ovl_img, int(round(s.points[i].x)),
					int(round(s.points[i].y)), col)


func draw_risk(world):
	var c = Config.C_ALERT
	c.a = 0.30
	var y = Config.FACADE_Y0
	while y < Config.FACADE_Y1:
		var x = Config.FACADE_X0
		while x < Config.FACADE_X1:
			if world.vis_at(x, y) > 0.60:
				_put(_ovl_img, x, y, c)
			x += 4
		y += 4


# Member diwarnai menurut RASIO BEBAN, bukan integritas — itu yang perlu
# dilihat saat menyetel KAPASITAS_MAX. Hijau = santai, merah = di ambang.
# Joint tetap diwarnai menurut integritas (baru berubah di TAHAP 5).
func draw_frame(world):
	for m in world.members:
		if not m.alive:
			continue
		var cap = world.kapasitas(m)
		var stress = 1.0 if cap <= 0.0 else clamp(m.beban / cap, 0.0, 1.0)
		_line(_ovl_img, m.x0, m.y0, m.x1, m.y1,
				Config.C_FRAME_OK.linear_interpolate(Config.C_FRAME_BAD, stress))
	# joint digambar belakangan supaya duduk di atas member
	for j in world.joints:
		var hidup = false
		for mid in j.member_terhubung:
			if world.members[mid].alive:
				hidup = true
				break
		if not hidup:
			continue
		var c = Config.C_FRAME_BAD.linear_interpolate(
				Config.C_JOINT, j.integritas)
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				_put(_ovl_img, j.x + dx, j.y + dy, c)


func draw_debris(falling):
	for p in falling:
		_put(_ovl_img, int(round(p.x)), int(round(p.y)), Config.C_PUING)


func draw_dust(dust):
	for d in dust:
		var c = Config.C_DEBU
		c.a = clamp(1.0 - d.age / Config.DEBU_UMUR, 0.0, 1.0) * 0.8
		_put(_ovl_img, int(round(d.x)), int(round(d.y)), c)


# Retakan tumbuh menurut RASIO BEBAN, bukan integritas mentah. Rasionya adalah
# beban / (integritas * KAPASITAS_MAX), jadi ia ikut naik saat integritas turun
# — yang baru terjadi mulai TAHAP 5 saat tanaman melemahkan sambungan.
# Selalu digambar, bukan hanya saat mode debug: ini umpan balik untuk pemain.
func draw_cracks(world):
	for m in world.members:
		if not m.alive:
			continue
		var cap = world.kapasitas(m)
		if cap <= 0.0:
			continue
		var stress = m.beban / cap
		if stress < Config.RETAK_AMBANG:
			continue
		var f = clamp((stress - Config.RETAK_AMBANG)
				/ max(0.01, 1.0 - Config.RETAK_AMBANG), 0.0, 1.0)
		var dx = m.x1 - m.x0
		var dy = m.y1 - m.y0
		var n = int(max(abs(dx), abs(dy)))
		if n <= 0:
			continue
		var pl = Vector2(-dy, dx).normalized()   # tegak lurus member
		for k in range(int(n * f) + 1):
			var t = float(k) / float(n)
			# jitter tetap per member supaya retakan tidak berkedip tiap frame
			var off = round(_hash(m.id * 7.3 + k * 1.7) * 2.0) - 1.0
			_put(_ovl_img,
					int(round(m.x0 + dx * t + pl.x * off)),
					int(round(m.y0 + dy * t + pl.y * off)),
					Config.C_RETAK)


func _hash(n):
	var s = sin(n * 127.1) * 43758.5453
	return s - floor(s)


func count_covered():
	var n = 0
	var y = Config.FACADE_Y0
	while y < Config.FACADE_Y1:
		var x = Config.FACADE_X0
		while x < Config.FACADE_X1:
			if _tree_img.get_pixel(x, y).a > 0.1:
				n += 4
			x += 2
		y += 2
	var total = (Config.FACADE_X1 - Config.FACADE_X0) \
			* (Config.FACADE_Y1 - Config.FACADE_Y0)
	return float(n) / float(total)


func _stamp(img, cx, cy, r, col):
	var ir = int(ceil(r))
	var px = int(round(cx))
	var py = int(round(cy))
	for dy in range(-ir, ir + 1):
		for dx in range(-ir, ir + 1):
			if dx * dx + dy * dy > r * r:
				continue
			_put(img, px + dx, py + dy, col)


func _line(img, x0, y0, x1, y1, col):
	var dx = x1 - x0
	var dy = y1 - y0
	var n = int(max(abs(dx), abs(dy)))
	if n == 0:
		_put(img, x0, y0, col)
		return
	for k in range(n + 1):
		var t = float(k) / float(n)
		_put(img, int(round(x0 + dx * t)), int(round(y0 + dy * t)), col)


func _put(img, x, y, col):
	if x >= 0 and x < Config.W and y >= 0 and y < Config.H:
		img.set_pixel(x, y, col)
