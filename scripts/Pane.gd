extends SubViewportContainer

# Satu pane split screen: sebuah jendela ke dunia, dengan kamera sendiri.
#
# Penskalaan ke layar dilakukan lewat `stretch_shrink`, BUKAN lewat
# `Camera2D.zoom` dan bukan lewat `Sprite2D.scale`. Alasannya: stretch_shrink
# adalah bilangan bulat, jadi kontainer melakukan pembesaran kelipatan bulat
# yang dijamin bebas pengambilan sampel sub-piksel. Camera2D.zoom pecahan akan
# mengambil sampel di antara texel dan membuat pixel art buram — itu yang
# dilarang aturan render proyek ini.
#
#   stretch_shrink 2  -> SubViewport 480x192, dibesarkan 2x jadi 960x384
#   stretch_shrink 4  -> SubViewport 240x96,  dibesarkan 4x jadi 960x384
#
# Camera2D di dalamnya HANYA menggeser, zoom-nya tetap 1.
#
# Pane tidak pernah membaca input. main.gd yang membaca, lalu memanggil
# geser() / set_tingkat_zoom(). Lihat aturan struktur kode di CLAUDE.md.

var vp                      # SubViewport
var cam                     # Camera2D
var tingkat_zoom = Config.ZOOM_MIN

var _y0 = 0                 # batas atas pita dunia milik pane ini
var _y1 = 0                 # batas bawah, eksklusif
var _pusat = Vector2()      # posisi kamera yang diinginkan, sebelum dijepit
var _shake_t   = 0.0
var _shake_amp = 0.0


# Dipanggil SETELAH pane masuk ke pohon scene, supaya ukuran Control-nya
# benar-benar diterapkan sebelum SubViewport ikut disesuaikan.
func siapkan(pos, ukuran, band_y0, band_y1):
	_y0 = band_y0
	_y1 = band_y1

	vp = SubViewport.new()
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# Pengaman kedua di samping texture_filter tiap Sprite2D. Viewport punya
	# nilai bawaannya sendiri yang tidak selalu mengikuti project.godot.
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
	stretch_shrink = tingkat_zoom
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Semua input dibaca main.gd. Tanpa ini kontainer menelan klik dan
	# meneruskannya ke dalam SubViewport.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_pusat = Vector2(float(Config.W) * 0.5, float(_y0 + _y1) * 0.5)
	_terapkan()


# Menempelkan node visual (Sprite2D, CanvasModulate, PointLight2D) ke dalam
# viewport pane ini. Dipakai PixelCanvas — dialah yang memiliki tekstur.
func tempel(node):
	vp.add_child(node)


# Ukuran potongan dunia yang terlihat di pane ini, dalam piksel dunia.
func petak_terlihat():
	return Vector2(size) / float(tingkat_zoom)


func set_tingkat_zoom(z):
	z = int(clamp(z, Config.ZOOM_MIN, Config.ZOOM_MAX))
	if z == tingkat_zoom:
		return false
	tingkat_zoom = z
	stretch_shrink = z
	_terapkan()
	return true


func geser(v):
	_pusat += v
	_terapkan()


# Menjepit kamera ke dalam pita dunia milik pane ini, lalu membulatkannya ke
# piksel dunia penuh. Posisi pecahan akan menggeser seluruh kisi piksel
# setengah texel dan membuat gambar bergetar halus saat menggulir.
#
# Hasil jepitan ditulis balik ke _pusat supaya menahan tombol geser di tepi
# tidak menumpuk nilai yang harus "dibayar balik" saat berbalik arah.
func _terapkan():
	var lihat = petak_terlihat()
	var bw = float(Config.W)
	var bh = float(_y1 - _y0)

	var x = bw * 0.5
	if lihat.x < bw:
		x = clamp(_pusat.x, lihat.x * 0.5, bw - lihat.x * 0.5)

	var y = float(_y0) + bh * 0.5
	if lihat.y < bh:
		y = clamp(_pusat.y, float(_y0) + lihat.y * 0.5,
				float(_y1) - lihat.y * 0.5)

	_pusat = Vector2(x, y)
	cam.position = Vector2(round(x), round(y))


func berisi(titik_layar):
	return Rect2(position, size).has_point(titik_layar)


# Titik layar (koordinat jendela 960x640) menjadi titik dunia.
func titik_dunia(titik_layar):
	var lokal = titik_layar - position
	var kiri_atas = cam.position + cam.offset - petak_terlihat() * 0.5
	return kiri_atas + lokal / float(tingkat_zoom)


# Getaran menggeser kamera, bukan sprite — sprite sekarang dipakai bersama dua
# pane, jadi menggesernya akan mengguncang keduanya sekaligus. Digeser dalam
# piksel dunia penuh supaya kisi pikselnya tetap lurus.
func guncang(amp):
	_shake_amp = max(_shake_amp, min(Config.SHAKE_MAX, amp))
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
