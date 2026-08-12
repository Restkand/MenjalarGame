extends Node

# Suasana — malam dan lampu jendela. Inilah sisa terakhir PixelCanvas.gd:
# seluruh penggambaran piksel per-Image sudah pindah ke lapis view
# (R1-R6, docs/09), tinggal atmosfer yang memang berbasis node sejak awal.
#
# Tiap SubViewport punya World2D-nya sendiri, jadi CanvasModulate harus ada
# satu per pane. Lampu jendela TIDAK diduplikasi: jendela semuanya di atas
# garis tanah, jadi pane bawah tidak pernah membutuhkannya.

var _panes     = []     # semua pane, untuk malam
var _modulates = []     # satu CanvasModulate per pane
var _lights    = []     # PointLight2D di jendela yang menyala
var _lamp_tex           # tekstur falloff bertangga, dibuat sekali
var _world              # untuk memadamkan lampu saat jendelanya runtuh


func setup(panes):
	_panes = panes
	_modulates = []
	for p in _panes:
		# CanvasModulate hanya memengaruhi kanvas viewport tempat ia berada.
		# HUD (CanvasLayer 20) dan panel tuning (layer 10) hidup di luar
		# kedua SubViewport, jadi keduanya tetap terang penuh.
		var cm = CanvasModulate.new()
		cm.color = Color(1, 1, 1)
		p.tempel(cm)
		_modulates.append(cm)


# Lampu jendela. Dipanggil ulang tiap kali dunia dibangun ulang (reset),
# karena grid terrain-nya baru dan lampu yang padam harus menyala lagi.
#
# Hanya sebagian jendela yang dipilih, bukan semuanya: puluhan lampu mahal
# di renderer Compatibility (tiap lampu menambah satu lintasan per objek
# yang disinari), dan gedung yang setiap jendelanya menyala terbaca palsu.
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
		# tekstur lampu beresolusi satuan; PPU membawanya ke ruang piksel
		l.texture_scale = float(Config.PPU)
		l.color = Config.C_LAMPU
		l.energy = 0.0                     # siang: padam
		l.position = w * float(Config.PPU)
		l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pane.tempel(l)
		_lights.append({"node": l, "win": w})
		i += langkah


# Falloff BERTANGGA. Larangan gradien halus sudah dicabut docs/09, tapi
# tangga cahaya tetap dipertahankan sebagai pilihan gaya — ia yang membuat
# malam terasa piksel walau asetnya sudah beresolusi penuh.
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
	# dua tahap (G8): siang -> SENJA -> malam. Perhentian senja menahan biru
	# supaya transisinya terasa seperti langit, bukan sakelar lampu.
	var aa = clamp(a * Config.NIGHT_GELAP, 0.0, 1.0)
	var c
	if aa < 0.5:
		c = Color(1, 1, 1).lerp(Config.C_SENJA, aa * 2.0)
	else:
		c = Config.C_SENJA.lerp(Config.C_MALAM, (aa - 0.5) * 2.0)
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
