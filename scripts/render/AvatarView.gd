extends Node2D

# Tampilan avatar (P1, docs/13) — prosedural dulu sesuai pertanyaan terbuka
# docs/13 §10; sprite menyusul kalau bentuknya sudah terbukti enak.
#
# Kepala sulur bercahaya C_TIP yang berdenyut; saat MERAMBAT ada cincin
# lembut (menempel), saat LEPAS ada ekor kecil searah gerak. Bar energi
# mengambang di atas kepala — HUD menyusul di tahap berikutnya.

var avatar
var _t = 0.0


func _init(a):
	avatar = a
	visible = false


func _process(delta):
	_t += delta
	if visible:
		queue_redraw()


func _draw():
	var ppu = float(Config.PPU)
	var p = avatar.pos * ppu + Vector2(0.0, -Config.AVATAR_TINGGI * ppu * 0.5)
	var denyut = 1.0 + sin(_t * 5.0) * 0.12

	# sedang mengisi dari sumber (P3): cincin mengembang — "minum"
	if avatar.mengisi:
		var isi_c = Config.C_TIP
		isi_c.a = 0.35 * (1.0 - fmod(_t, 0.8) / 0.8)
		draw_arc(p, 10.0 + fmod(_t, 0.8) * 14.0, 0.0, TAU, 24, isi_c, 2.0)

	if avatar.moda == avatar.MERAMBAT:
		var cincin = Config.C_TIP
		cincin.a = 0.25
		draw_circle(p, 13.0 * denyut, cincin)
	else:
		# ekor kecil melawan arah gerak — terbaca "melesat"
		if avatar.vel.length() > 4.0:
			var ekor = Config.C_LEAF
			ekor.a = 0.5
			draw_line(p, p - avatar.vel.normalized() * 10.0, ekor, 3.0)

	# badan: bola daun dua lapis + inti terang
	draw_circle(p, 8.0, Config.C_LEAF.darkened(0.25))
	draw_circle(p + Vector2(-1.0, -1.0), 6.0, Config.C_LEAF)
	draw_circle(p + Vector2(-2.0, -2.0), 3.0 * denyut, Config.C_TIP)
	# dua kuncup daun kecil di pucuk
	draw_circle(p + Vector2(-5.0, -7.0), 2.5, Config.C_LEAF)
	draw_circle(p + Vector2(4.0, -8.0), 2.0, Config.C_LEAF)

	# bar energi
	var w = 26.0
	var atas = p + Vector2(-w * 0.5, -18.0)
	draw_rect(Rect2(atas, Vector2(w, 4.0)), Color(0.1, 0.1, 0.1, 0.6))
	var isi = clamp(avatar.energi / Config.AVATAR_ENERGI_MAX, 0.0, 1.0)
	var c = Config.C_TIP if isi > 0.3 else Config.C_ALERT
	draw_rect(Rect2(atas, Vector2(w * isi, 4.0)), c)
