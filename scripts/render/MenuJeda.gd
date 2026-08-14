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
	["W / S", "menempel ke jaringan (saat menyentuh garis hijau)"],
	["SPASI", "lompat - dari jaringan: melepaskan diri"],
	["SHIFT", "lari (moda lepas)"],
	["F",     "menanam jangkar simpul (mahal)"],
	["R",     "ulang ruangan"],
]

var papan


class Papan extends Node2D:
	var font
	var tex_panel = null

	func _init():
		font = ThemeDB.fallback_font
		if ResourceLoader.exists("res://aset/hud/panel.png"):
			tex_panel = load("res://aset/hud/panel.png")

	func _draw():
		var layar = get_viewport_rect().size
		var gelap = C_LATAR
		gelap.a = 0.72
		draw_rect(Rect2(Vector2(), layar), gelap)

		var cx = layar.x * 0.5
		# kartu = panel PixelLab yang sama dengan HUD, skala 2x
		if tex_panel:
			var pw = tex_panel.get_width() * 2.0
			var ph = tex_panel.get_height() * 2.0
			draw_texture_rect(tex_panel,
					Rect2(cx - pw * 0.5, 130.0, pw, ph), false)
		var y = 216.0
		_teks(cx - 64.0, y, "JEDA", 52, C_TERANG)
		y += 74.0
		_teks(cx - 216.0, y, "[ESC] LANJUT", 25, C_TERANG)
		_teks(cx + 30.0, y, "[R] ULANG RUANGAN", 25, C_TERANG)
		y = 480.0
		_teks(cx - 216.0, y, "KENDALI", 20, C_LABEL)
		y += 36.0
		for baris in KENDALI:
			_teks(cx - 216.0, y, baris[0], 22, C_TERANG)
			_teks(cx - 100.0, y, baris[1], 22, C_LABEL)
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
