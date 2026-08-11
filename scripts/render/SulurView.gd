extends Line2D

# Satu untai = satu Line2D (docs/09 §4). Strand.points sudah berupa rantai
# titik float — persis yang dibutuhkan Line2D, tinggal dikalikan PPU.
#
# Ketebalan: width_curve menggantikan rumus per-titik lama (§10.3 Logika) —
# tebal di pangkal, menipis ke ujung, dan Godot yang menghitungnya.
#
# points hanya dibangun ulang saat JUMLAH titik berubah (tumbuh, dipangkas
# regu, mundur dari fasad runtuh, diputus X). Di antara itu array-nya diam,
# jadi tidak ada kerja per-frame. Ini juga yang membuat trim otomatis benar
# tanpa sinyal apa pun: ukuran berubah -> garis dibangun ulang.

var strand
var _n_terakhir = -1


func _init(s):
	strand = s
	texture = load("res://aset/akar_batang.png" if s.is_root
			else "res://aset/sulur_batang.png")
	texture_mode = Line2D.LINE_TEXTURE_TILE
	# TILE butuh repeat menyala; tanpa ini texel terakhir dioles memanjang.
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	joint_mode = Line2D.LINE_JOINT_ROUND
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND

	width_curve = Curve.new()
	width_curve.add_point(Vector2(0.0, 1.0))
	width_curve.add_point(Vector2(1.0, 0.35))


func _process(_delta):
	var n = strand.points.size()
	if n == _n_terakhir:
		return
	_n_terakhir = n

	if n < 2:
		visible = false
		return
	visible = true

	# Satu titik tiap 3 satuan cukup halus untuk Line2D (docs/09 §4) —
	# titik simulasi berjarak 1 satuan, jadi ambil setiap titik ketiga.
	# Ujung asli selalu disertakan supaya garisnya sampai ke tip.
	var pts = PackedVector2Array()
	var i = 0
	while i < n - 1:
		pts.append(strand.points[i] * Config.PPU)
		i += 3
	pts.append(strand.points[n - 1] * Config.PPU)
	points = pts

	# Lebar pangkal dalam satuan dunia, menebal seiring umur untai — kurva
	# yang sama dengan rumus lama, dikali PPU karena koordinat lokal di sini
	# adalah piksel tampilan.
	var w = 1.6 + min(4.4, n * 0.012) - strand.generation * 0.6
	width = max(1.4, w) * Config.PPU
