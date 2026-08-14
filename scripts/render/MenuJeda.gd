extends CanvasLayer

# Menu JEDA minimal (permintaan UX pemilik). ESC membekukan pohon scene
# (get_tree().paused oleh Ruang01Main — input tetap terpusat di main);
# layer ini hanya menggambar. Sekalian jadi kartu KENDALI: pemain yang
# bingung "memencet apa" menemukan jawabannya di sini, bukan di dunia
# (dunia tetap tanpa teks, SRD §23).

const C_LATAR  = Color("0B0E12")
const C_LABEL  = Color("59636F")
const C_TERANG = Color("A8D94A")

const KENDALI = [
	["WASD",  "bergerak / arah rambat"],
	["W / S", "menempel ke garis jaringan"],
	["SPASI", "lompat / melepaskan diri"],
	["SHIFT", "lari (moda lepas)"],
	["F",     "tanam jangkar simpul (mahal)"],
	["R",     "ulang ruangan"],
]

var papan


class Papan extends Node2D:
	var font
	var tex_panel = null

	func _init():
		font = ThemeDB.fallback_font
		if ResourceLoader.exists("res://aset/hud/panel_jeda.png"):
			tex_panel = load("res://aset/hud/panel_jeda.png")

	func _draw():
		var layar = get_viewport_rect().size
		var gelap = C_LATAR
		gelap.a = 0.72
		draw_rect(Rect2(Vector2(), layar), gelap)
		var cx = layar.x * 0.5

		# KARTU JUDUL: panel header PixelLab khusus jeda (kit seed 1102)
		# — judul & aksi DI DALAM pelat, tidak ada teks menembus bingkai
		var py = 170.0
		if tex_panel:
			var pw = float(tex_panel.get_width())
			var ph = float(tex_panel.get_height())
			draw_texture_rect(tex_panel,
					Rect2(cx - pw * 0.5, py, pw, ph), false)
			# semua teks HARUS di interior pelat (~cx +- 210)
			_teks(cx - 54.0, py + 70.0, "JEDA", 42, C_TERANG)
			_teks(cx - 185.0, py + 118.0, "[ESC] LANJUT", 19, C_TERANG)
			_teks(cx + 15.0, py + 118.0, "[R] ULANG RUANGAN", 19, C_TERANG)
		else:
			_teks(cx - 54.0, py + 60.0, "JEDA", 42, C_TERANG)
			_teks(cx - 185.0, py + 110.0, "[ESC] LANJUT", 19, C_TERANG)
			_teks(cx + 15.0, py + 110.0, "[R] ULANG RUANGAN", 19, C_TERANG)

		# KOTAK KENDALI: pelat gelap tenang berbingkai metal, kolom
		# sejajar — rapi terpisah dari kartu judul
		var kw = 520.0
		var kx = cx - kw * 0.5
		var ky = py + 190.0
		var kh = 64.0 + KENDALI.size() * 34.0
		var latar_k = C_LATAR
		latar_k.a = 0.85
		draw_rect(Rect2(kx, ky, kw, kh), latar_k)
		var bingkai = Color("59636F")
		bingkai.a = 0.5
		draw_rect(Rect2(kx, ky, kw, kh), bingkai, false, 2.0)
		_teks(kx + 28.0, ky + 38.0, "KENDALI", 18, C_LABEL)
		var y = ky + 74.0
		for baris in KENDALI:
			_teks(kx + 28.0, y, baris[0], 20, C_TERANG)
			_teks(kx + 140.0, y, baris[1], 20, C_LABEL)
			y += 34.0

	func _teks(x, y, teks, ukuran, warna):
		var bayang = C_LATAR
		bayang.a = 0.9
		draw_string(font, Vector2(x + 2.0, y + 2.0), teks,
				HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran, bayang)
		draw_string(font, Vector2(x, y), teks,
				HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran, warna)


func _init():
	layer = 90
	visible = false
	papan = Papan.new()
	add_child(papan)


func buka(b):
	visible = b
	papan.queue_redraw()
