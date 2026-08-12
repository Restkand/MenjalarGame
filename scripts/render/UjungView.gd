extends Node2D

# Denyut ujung tumbuh, kotak pilihan, bar menembus, dan pratinjau jalur —
# penghuni terakhir lapisan overlay lama, kini digambar vektor (R6).
#
# Satu instans per pane; kamera pane yang menentukan mana yang terlihat.
# Redraw tiap frame memang perlu: denyut adalah animasi kontinu, dan isinya
# hanya beberapa lingkaran — murah.

var sim
var _t = 0.0
var pratinjau = []   # titik satuan simulasi; diisi main saat mengarahkan


func _init(s):
	sim = s


func _process(delta):
	_t += delta
	queue_redraw()


func _draw():
	var ppu = float(Config.PPU)

	for s in sim.strands:
		if not s.alive:
			continue
		var p = s.tip * ppu
		# denyut ~0,6 detik (§10.5 Logika) — tetap penarik mata utama
		var col = Config.C_TIP if fmod(_t, 0.6) < 0.3 else Config.C_LEAF
		draw_circle(p, 4.0, col)

		if s == sim.selected:
			# kotak sebesar radius klik — penanda yang jujur
			var r = Config.PILIH_RADIUS * ppu * 0.35
			draw_rect(Rect2(p - Vector2(r, r), Vector2(r * 2.0, r * 2.0)),
					Config.C_TIP, false, 2.0)

		# bar kemajuan menembus beton, di atas ujung akar yang mengebor
		if s.tembus >= 0.0:
			draw_rect(Rect2(p + Vector2(-20.0, -32.0), Vector2(40.0, 5.0)),
					Config.C_RETAK)
			draw_rect(Rect2(p + Vector2(-20.0, -32.0),
					Vector2(40.0 * clamp(s.tembus, 0.0, 1.0), 5.0)),
					Config.C_TIP)

	# pratinjau jalur — titik putus, memakai aturan tumbuh yang sama
	if not pratinjau.is_empty():
		var c = Config.C_TIP
		c.a = 0.55
		var i = 0
		while i < pratinjau.size():
			draw_circle(pratinjau[i] * ppu, 2.0, c)
			i += 3
