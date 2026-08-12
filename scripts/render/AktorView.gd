extends Node2D

# Regu perawatan & pemanjat sebagai sprite (R6, docs/09).
#
# Satu node menggambar SEMUA aktor lewat _draw() — jumlahnya kecil tapi
# datang-pergi tiap hari perawatan, jadi batch tanpa siklus hidup node jauh
# lebih sederhana daripada satu Sprite2D per unit.
#
# Gelombang 5 (docs/12): semua animasi adalah STRIP aktor_<nama>.png berisi
# frame 48x64 berderet — digenerate dari SATU karakter pipeline PixelLab,
# jadi tiap frame dijamin orang yang sama. Jumlah frame dibaca dari lebar
# strip; menambah/mengurangi frame tidak butuh perubahan kode.
# Hadap kiri-kanan lewat cermin transform.

var crew
var climbers
var _t = 0.0
var _ada = false
var _anim = {}

const NAMA = ["regu_diam", "regu_jalan", "regu_kerja",
		"pemanjat_naik", "pemanjat_gantung"]
const FRAME_DETIK = 0.15


func _init(c, cl):
	crew = c
	climbers = cl
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for n in NAMA:
		var t = load("res://aset/aktor_%s.png" % n)
		_anim[n] = {"tex": t, "n": max(1, t.get_width() / 48)}


# gambar frame animasi `nama` dengan titik JANGKAR (48x64) di `ofs` relatif
# transform yang sedang aktif
func _frame(nama, ofs, warna = Color.WHITE):
	var a = _anim[nama]
	var f = int(_t / FRAME_DETIK) % a.n
	draw_texture_rect_region(a.tex, Rect2(ofs, Vector2(48.0, 64.0)),
			Rect2(f * 48.0, 0.0, 48.0, 64.0), warna)


func _process(delta):
	_t += delta
	if crew.units.is_empty() and climbers.units.is_empty():
		if _ada:
			_ada = false
			queue_redraw()
		return
	_ada = true
	queue_redraw()


func _draw():
	var ppu = float(Config.PPU)

	for u in crew.units:
		var pos = Vector2(u.x, Config.GROUND_Y) * ppu

		# tertimbun puing — tergeletak redup, tidak bekerja
		if u.pingsan > 0.0:
			draw_set_transform(pos + Vector2(0.0, -10.0), -PI / 2.0,
					Vector2.ONE)
			_frame("regu_diam", Vector2(-24.0, -54.0),
					Color(0.62, 0.62, 0.68))
			continue

		var sasar = crew.titik_sasaran(u)
		var bekerja = u.kerja > 0.0 and sasar != null
		var jalan = u.pulang or (sasar != null
				and abs(sasar.x - u.x) > Config.CREW_JANGKAUAN)
		var nama = "regu_diam"
		if bekerja:
			nama = "regu_kerja"
		elif jalan:
			nama = "regu_jalan"

		var hadap = 1.0
		if sasar != null:
			hadap = 1.0 if sasar.x >= u.x else -1.0
		elif u.pulang:
			hadap = -1.0 if u.x < Config.W / 2.0 else 1.0

		# garis ke titik potong digambar dulu supaya badan menutupinya —
		# pemain harus langsung tahu sulur mana yang sedang digergaji
		if bekerja:
			var c = Config.C_ALERT
			c.a = 0.75
			draw_line(pos + Vector2(0.0, -44.0), sasar * ppu, c, 2.0)

		draw_set_transform(pos, 0.0, Vector2(hadap, 1.0))
		_frame(nama, Vector2(-24.0, -64.0))

	for c in climbers.units:
		if c.pingsan > 0.0:
			continue   # sudah jatuh, sedang tidak di sulur
		var p = climbers.pos(c) * ppu
		var nama = "pemanjat_gantung" if c.kerja > 0.0 else "pemanjat_naik"
		draw_set_transform(p, 0.0, Vector2.ONE)
		# badan berpusat di titik sulur yang sedang dipijak
		_frame(nama, Vector2(-24.0, -36.0))

	draw_set_transform_matrix(Transform2D())
