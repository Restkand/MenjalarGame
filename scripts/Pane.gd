extends SubViewportContainer

# Satu pane split screen — angka R5 (docs/09 §2).
#
# SubViewport berukuran piksel penuh (1920x720 / 1920x360) dan semua view di
# dalamnya hidup di RUANG PIKSEL (satuan simulasi x PPU). Zoom sekarang murni
# `Camera2D.zoom`, BEBAS dan mulus — larangan zoom bulat era stretch_shrink
# sudah tidak berlaku karena aset tampil pada ukuran aslinya, bukan piksel
# yang diperbesar.
#
# Pane tidak pernah membaca input. main.gd yang membaca, lalu memanggil
# geser() / set_zoom() / ubah_zoom(). Lihat aturan struktur kode di CLAUDE.md.

var vp                      # SubViewport
var cam                     # Camera2D
var zoom = 1.0

var _y0 = 0.0               # batas pita dunia pane ini, dalam PIKSEL
var _y1 = 0.0
var _pusat = Vector2()      # posisi kamera yang diinginkan, sebelum dijepit
var _shake_t   = 0.0
var _shake_amp = 0.0


# band_y0/band_y1 dalam SATUAN simulasi; dikonversi ke piksel di sini.
func siapkan(pos, ukuran, band_y0, band_y1):
	_y0 = float(band_y0 * Config.PPU)
	_y1 = float(band_y1 * Config.PPU)

	vp = SubViewport.new()
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.canvas_item_default_texture_filter = \
			Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(vp)

	cam = Camera2D.new()
	cam.position_smoothing_enabled = false
	cam.ignore_rotation = true
	vp.add_child(cam)

	position = pos
	size = ukuran
	stretch = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Semua input dibaca main.gd. Tanpa ini kontainer menelan klik.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_pusat = Vector2(float(Config.W * Config.PPU) * 0.5, (_y0 + _y1) * 0.5)
	_terapkan()


# Menempelkan node visual ke dalam viewport pane ini.
func tempel(node):
	vp.add_child(node)


# Potongan dunia yang terlihat, dalam piksel.
func petak_terlihat():
	return Vector2(size) / zoom


func set_zoom(z):
	zoom = clamp(z, Config.ZOOM_MIN, Config.ZOOM_MAX)
	cam.zoom = Vector2(zoom, zoom)
	_terapkan()


func ubah_zoom(faktor):
	set_zoom(zoom * faktor)


func geser(v_px):
	_pusat += v_px
	_terapkan()


# Menjepit kamera ke pita dunia pane ini, lalu membulatkan ke piksel penuh —
# posisi pecahan membuat tekstur nearest bergetar halus saat menggulir.
func _terapkan():
	var lihat = petak_terlihat()
	var bw = float(Config.W * Config.PPU)
	var bh = _y1 - _y0

	var x = bw * 0.5
	if lihat.x < bw:
		x = clamp(_pusat.x, lihat.x * 0.5, bw - lihat.x * 0.5)

	var y = _y0 + bh * 0.5
	if lihat.y < bh:
		y = clamp(_pusat.y, _y0 + lihat.y * 0.5, _y1 - lihat.y * 0.5)

	_pusat = Vector2(x, y)
	cam.position = Vector2(round(x), round(y))


func berisi(titik_layar):
	return Rect2(position, size).has_point(titik_layar)


# Titik layar (koordinat jendela) -> titik dunia dalam SATUAN simulasi.
func titik_dunia(titik_layar):
	var lokal = titik_layar - position
	var kiri_atas = cam.position + cam.offset - petak_terlihat() * 0.5
	return (kiri_atas + lokal / zoom) / float(Config.PPU)


# Getaran menggeser kamera. Amplitudo datang dalam satuan simulasi.
func guncang(amp):
	_shake_amp = max(_shake_amp, min(Config.SHAKE_MAX, amp)) * Config.PPU
	_shake_t = Config.SHAKE_DECAY


func _process(delta):
	if _shake_t <= 0.0:
		return
	_shake_t = max(0.0, _shake_t - delta)
	if _shake_t <= 0.0:
		_shake_amp = 0.0
		cam.offset = Vector2()
		return
	var a = _shake_amp * (_shake_t / Config.SHAKE_DECAY)
	cam.offset = Vector2(round(randf_range(-a, a)), round(randf_range(-a, a)))
