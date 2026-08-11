extends Node

# Semua yang menulis piksel ada di sini.
#
# Catatan Godot 4: Image.lock()/unlock() sudah dihapus — set_pixel() boleh
# dipanggil langsung. Penggantinya untuk mengunggah ke GPU adalah
# ImageTexture.update(img), bukan set_data(img). ImageTexture.create_from_image()
# sekarang STATIS dan mengembalikan tekstur baru; untuk mengarahkan tekstur yang
# sudah ada ke Image lain, pakai set_image().
#
# R2: lapis world sudah pindah ke TerrainView (TileMapLayer) + FasadView.
# Yang tersisa di sini dua Image: `tree` (akumulatif — sekarang hanya pohon)
# dan `overlay` (dibersihkan tiap frame — ujung, pratinjau, aktor, puing
# melayang, debu, retakan, peta debug). Tiap pane punya SET SPRITE-NYA
# SENDIRI yang menunjuk ke ImageTexture YANG SAMA.
#
# Tiap SubViewport punya World2D-nya sendiri, jadi CanvasModulate juga harus
# ada satu per pane. Lampu jendela TIDAK diduplikasi: jendela semuanya di atas
# garis tanah, jadi pane bawah tidak pernah membutuhkannya.

var _tree_img
var _tree_tex
var _ovl_img
var _ovl_tex
var _panes     = []     # semua pane, untuk getaran dan malam
var _modulates = []     # satu CanvasModulate per pane
var _lights    = []     # PointLight2D di jendela yang menyala
var _lamp_tex           # tekstur falloff bertangga, dibuat sekali
var _world              # untuk memadamkan lampu saat jendelanya runtuh


func setup(panes):
	_panes = panes

	_tree_img = _blank()
	_tree_tex = ImageTexture.create_from_image(_tree_img)

	_ovl_img = _blank()
	_ovl_tex = ImageTexture.create_from_image(_ovl_img)

	_modulates = []
	for p in _panes:
		# z 0 milik TerrainView/FasadView, z 1 milik batang sulur
		# (TanamanView). Urutannya: terrain+fasad, batang, pohon+daun,
		# overlay.
		p.tempel(_sprite(_tree_tex, 2))
		p.tempel(_sprite(_ovl_tex, 3))

		# CanvasModulate hanya memengaruhi kanvas viewport tempat ia berada.
		# HUD (CanvasLayer 20) dan panel tuning (layer 10) hidup di luar kedua
		# SubViewport, jadi keduanya tetap terang penuh tanpa diatur apa pun.
		var cm = CanvasModulate.new()
		cm.color = Color(1, 1, 1)
		p.tempel(cm)
		_modulates.append(cm)


# Getaran sekarang menggeser KAMERA tiap pane, bukan sprite. Sprite dipakai
# bersama dua pane, jadi menggesernya akan mengguncang keduanya dari satu
# sumber dan tidak bisa disetel per pane.
func add_shake(amp):
	for p in _panes:
		p.guncang(amp)


# Lampu jendela. Dipanggil ulang tiap kali dunia dibangun ulang (reset),
# karena grid terrain-nya baru dan lampu yang padam harus menyala lagi.
#
# Hanya sebagian jendela yang dipilih, bukan semuanya: 28 lampu itu mahal di
# renderer Compatibility (tiap lampu menambah satu lintasan per objek yang
# disinari), dan gedung yang setiap jendelanya menyala justru terbaca palsu.
# Langkah tetap, bukan acak, supaya polanya sama tiap kali dimulai ulang.
func setup_lights(world, pane):
	_world = world
	for l in _lights:
		l.node.queue_free()
	_lights = []

	if _lamp_tex == null:
		_lamp_tex = _make_lamp_tex()

	var n = world.windows.size()
	if n == 0:
		return
	var langkah = int(max(1, n / Config.LAMPU_JUMLAH))
	var i = 0
	while i < n:
		var w = world.windows[i]
		var l = PointLight2D.new()
		l.texture = _lamp_tex
		# Sprite tidak lagi diskalakan, jadi satu texel lampu = satu piksel
		# dunia dan posisinya langsung koordinat dunia.
		l.texture_scale = 1.0
		l.color = Config.C_LAMPU
		l.energy = 0.0                     # siang: padam
		l.position = w
		l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pane.tempel(l)
		_lights.append({"node": l, "win": w})
		i += langkah


# Falloff BERTANGGA, bukan gradien halus. Tanpa kuantisasi ini cahayanya jadi
# blur lembut dan seluruh kesan pixel art rusak — lihat aturan "tanpa gradien"
# di docs/01-konteks-game.md §5.
func _make_lamp_tex():
	var r = Config.LAMPU_RADIUS
	var d = r * 2
	var img = Image.create_empty(d, d, false, Image.FORMAT_RGBA8)
	for y in range(d):
		for x in range(d):
			var dx = float(x - r) + 0.5
			var dy = float(y - r) + 0.5
			var t = 1.0 - sqrt(dx * dx + dy * dy) / float(r)
			if t <= 0.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var q = ceil(t * Config.LAMPU_TINGKAT) / float(Config.LAMPU_TINGKAT)
			img.set_pixel(x, y, Color(q, q, q, q))
	return ImageTexture.create_from_image(img)


func set_night(a):
	var c = Color(1, 1, 1).lerp(Config.C_MALAM, a * Config.NIGHT_GELAP)
	for cm in _modulates:
		cm.color = c
	var e = a * Config.LAMPU_ENERGI
	for l in _lights:
		# Jendela yang sudah runtuh tidak boleh menyisakan cahaya menggantung
		# di udara. Murah: hanya sejumlah LAMPU_JUMLAH lookup grid per frame.
		if _world != null and _world.at(int(l.win.x), int(l.win.y)) \
				!= Config.T_WINDOW:
			l.node.energy = 0.0
		else:
			l.node.energy = e


func _blank():
	var img = Image.create_empty(Config.W, Config.H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


# Skala 1: pembesaran ke layar sekarang dikerjakan SubViewportContainer lewat
# stretch_shrink, jadi koordinat sprite = koordinat dunia. Itu yang membuat
# posisi lampu, kamera, dan mouse semuanya hidup di satu sistem koordinat.
func _sprite(tex, z):
	var s = Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.z_index = z
	# Pengganti flags=0 milik Godot 3. Tanpa ini pembesarannya jadi buram dan
	# seluruh identitas pixel art-nya hilang.
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return s


func begin_frame():
	_ovl_img.fill(Color(0, 0, 0, 0))


func end_frame():
	_tree_tex.update(_tree_img)
	_ovl_tex.update(_ovl_img)


func clear_tree():
	_tree_img.fill(Color(0, 0, 0, 0))
	_tree_tex.update(_tree_img)


# draw_strand / draw_strand_full / _paint / draw_leaves DIHAPUS di R1 —
# untai kini Line2D (SulurView) dan daun kini sprite (DaunView). Lapisan
# pohon yang akumulatif sekarang hanya berisi pohon.


# Pohon digambar ke lapisan pohon yang akumulatif, sama seperti dulu. Ia
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


func draw_tip(p, is_selected, t):
	var col = Config.C_TIP if fmod(t, 0.6) < 0.3 else Config.C_LEAF
	_stamp(_ovl_img, p.x, p.y, 0.6, col)
	if is_selected:
		# Kotak penanda mengikuti PILIH_RADIUS supaya besarnya jujur: yang
		# terlihat adalah kira-kira sejauh mana klik masih mengenai ujung ini.
		var cx = int(round(p.x))
		var cy = int(round(p.y))
		var r = 6
		for d in range(-r, r + 1):
			if abs(d) == r:
				continue
			_put(_ovl_img, cx + d, cy - r, Config.C_TIP)
			_put(_ovl_img, cx + d, cy + r, Config.C_TIP)
			_put(_ovl_img, cx - r, cy + d, Config.C_TIP)
			_put(_ovl_img, cx + r, cy + d, Config.C_TIP)


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
			for i in range(x - 6, x + 7):
				for j in range(y - 4, y):
					_put(_ovl_img, i, j, Config.C_WARDEN)
			continue

		var bekerja = u.kerja > 0.0 and u.sasaran != null
		var c = Config.C_ALERT if bekerja else Config.C_WARDEN

		# garis ke sasaran digambar dulu supaya badan menutupinya — pemain
		# harus langsung tahu tanaman mana yang sedang dicabut
		if bekerja:
			_line(_ovl_img, x, y - 12,
					int(round(u.sasaran.tip.x)), int(round(u.sasaran.tip.y)),
					Config.C_ALERT)

		for j in range(y - 18, y):
			for i in range(x - 2, x + 3):
				_put(_ovl_img, i, j, c)
		for i in range(x - 5, x - 2):
			_put(_ovl_img, i, y - 12, c)
			_put(_ovl_img, i + 8, y - 12, c)


func draw_climbers(cl):
	for c in cl.units:
		if c.pingsan > 0.0:
			continue   # sudah jatuh, sedang tidak di sulur
		var p = cl.pos(c)
		var x = int(round(p.x))
		var y = int(round(p.y))
		var col = Config.C_ALERT if c.kerja > 0.0 else Config.C_WARDEN
		for j in range(-6, 1):
			_put(_ovl_img, x, y + j, col)
			_put(_ovl_img, x + 1, y + j, col)
		for d in range(2, 4):
			_put(_ovl_img, x - d, y - 4, col)
			_put(_ovl_img, x + 1 + d, y - 4, col)


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
