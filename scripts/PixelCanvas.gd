extends Node2D

# Semua yang menulis piksel ada di sini.
#
# Catatan Godot 4: Image.lock()/unlock() sudah dihapus — set_pixel() boleh
# dipanggil langsung. Penggantinya untuk mengunggah ke GPU adalah
# ImageTexture.update(img), bukan set_data(img). ImageTexture.create_from_image()
# sekarang STATIS dan mengembalikan tekstur baru; untuk mengarahkan tekstur yang
# sudah ada ke Image lain, pakai set_image().

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
	_world_tex = ImageTexture.create_from_image(_world_img)
	_add_sprite(_world_tex, 0)

	_tree_img = _blank()
	_tree_tex = ImageTexture.create_from_image(_tree_img)
	_add_sprite(_tree_tex, 1)

	_ovl_img = _blank()
	_ovl_tex = ImageTexture.create_from_image(_ovl_img)
	_add_sprite(_ovl_tex, 2)

	var layer = CanvasLayer.new()
	layer.layer = 5
	add_child(layer)

	_night = ColorRect.new()
	_night.color = Color(0.05, 0.08, 0.20, 0.0)
	_night.size = Vector2(Config.W * Config.SCALE, Config.H * Config.SCALE)
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
			round(randf_range(-a, a)) * Config.SCALE,
			round(randf_range(-a, a)) * Config.SCALE)


# Dipanggil hanya saat piksel dunia benar-benar berubah — member dilubangi
# atau puing mengendap — bukan tiap frame.
func refresh_world():
	_world_tex.update(_world_img)


# world.build() membuat Image baru, jadi setelah reset teksturnya harus
# diarahkan ulang ke objek yang baru.
func set_world_image(world_img):
	_world_img = world_img
	_world_tex.set_image(_world_img)


func set_night(a):
	_night.color = Color(0.05, 0.08, 0.20, a * 0.55)


func _blank():
	var img = Image.create_empty(Config.W, Config.H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


func _add_sprite(tex, z):
	var s = Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.scale = Vector2(Config.SCALE, Config.SCALE)
	s.z_index = z
	# Pengganti flags=0 milik Godot 3. Tanpa ini skala 4x jadi buram dan
	# seluruh identitas pixel art-nya hilang.
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(s)


func begin_frame():
	_ovl_img.fill(Color(0, 0, 0, 0))


func end_frame():
	_tree_tex.update(_tree_img)
	_ovl_tex.update(_ovl_img)


func clear_tree():
	_tree_img.fill(Color(0, 0, 0, 0))
	_tree_tex.update(_tree_img)


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


# Pohon digambar ke lapisan pohon yang akumulatif, sama seperti untai. Ia
# tumbuh dari waktu ke waktu, jadi menggambarnya tiap frame juga berfungsi
# sebagai cara ia meninggi.
func draw_tree(t):
	var bx = int(round(t.x))
	var by = int(round(t.y))
	var h = int(t.tinggi)

	for j in range(0, h):
		_put(_tree_img, bx, by - j, Config.C_BRANCH)
		if j > h / 3:   # batang menebal di bagian bawah
			_put(_tree_img, bx - 1, by - j, Config.C_BRANCH)

	var cy = by - h
	var r = max(2, int(h / 3))
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy <= r * r:
				_put(_tree_img, bx + dx, cy + dy, Config.C_LEAF)


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


func draw_crew(crew):
	for u in crew.units:
		var x = int(round(u.x))
		var y = Config.GROUND_Y

		# tertimbun puing — tergeletak, tidak bekerja
		if u.pingsan > 0.0:
			for i in range(x - 3, x + 4):
				_put(_ovl_img, i, y - 1, Config.C_WARDEN)
				_put(_ovl_img, i, y - 2, Config.C_WARDEN)
			continue

		var bekerja = u.kerja > 0.0 and u.sasaran != null
		var c = Config.C_ALERT if bekerja else Config.C_WARDEN

		# garis ke sasaran digambar dulu supaya badan menutupinya — pemain
		# harus langsung tahu tanaman mana yang sedang dicabut
		if bekerja:
			_line(_ovl_img, x, y - 6,
					int(round(u.sasaran.tip.x)), int(round(u.sasaran.tip.y)),
					Config.C_ALERT)

		for j in range(y - 9, y):
			for i in range(x - 1, x + 2):
				_put(_ovl_img, i, j, c)
		_put(_ovl_img, x - 2, y - 6, c)
		_put(_ovl_img, x + 2, y - 6, c)


func draw_climbers(cl):
	for c in cl.units:
		if c.pingsan > 0.0:
			continue   # sudah jatuh, sedang tidak di sulur
		var p = cl.pos(c)
		var x = int(round(p.x))
		var y = int(round(p.y))
		var col = Config.C_ALERT if c.kerja > 0.0 else Config.C_WARDEN
		for j in range(-3, 1):
			_put(_ovl_img, x, y + j, col)
		_put(_ovl_img, x - 1, y - 2, col)
		_put(_ovl_img, x + 1, y - 2, col)


# Alpha 0.30 dengan kisi 4 px praktis tidak terlihat di atas fasad abu-abu —
# tangkapan layar membuktikan titiknya memang tergambar, tapi terbaca sebagai
# derau, bukan sebagai peta. Dinaikkan ke 0.55 dengan kisi 3 px.
func draw_risk(world):
	var c = Config.C_ALERT
	c.a = 0.55
	var y = Config.FACADE_Y0
	while y < Config.FACADE_Y1:
		var x = Config.FACADE_X0
		while x < Config.FACADE_X1:
			if world.vis_at(x, y) > 0.60:
				_put(_ovl_img, x, y, c)
			x += 3
		y += 3


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
				Config.C_FRAME_OK.lerp(Config.C_FRAME_BAD, stress))
	# joint digambar belakangan supaya duduk di atas member
	for j in world.joints:
		var hidup = false
		for mid in j.member_terhubung:
			if world.members[mid].alive:
				hidup = true
				break
		if not hidup:
			continue
		var c = Config.C_FRAME_BAD.lerp(Config.C_JOINT, j.integritas)
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				_put(_ovl_img, j.x + dx, j.y + dy, c)


# Bongkahan 2x2, bukan sebutir. Satu piksel per puing terbaca sebagai debu
# halus, bukan pecahan beton — itu yang membuat keruntuhan terlihat seperti
# coretan alih-alih massa yang jatuh.
func draw_debris(falling):
	for p in falling:
		var x = int(round(p.x))
		var y = int(round(p.y))
		_put(_ovl_img, x, y, Config.C_PUING)
		_put(_ovl_img, x + 1, y, Config.C_PUING)
		_put(_ovl_img, x, y + 1, Config.C_PUING)
		_put(_ovl_img, x + 1, y + 1, Config.C_PUING)


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
