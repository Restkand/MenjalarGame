extends Node2D

# Tampilan TENDRIL (ADR §18: Godot AvatarView = prioritas setelah master
# LOCKED). Lima animasi kanon dari aset/konsep_tendril/: idle, merambat,
# lepas, detach, attach — 48 px per frame, palet kanon CDD §7.
#
# Aturan state (CDD §15-16): pergantian moda MEMUTAR transisi sekali —
# detach 0.28 dtk (target 0.15-0.30), attach 0.20 dtk (target 0.10-0.25) —
# lalu jatuh ke loop moda. Idle dipakai saat nyaris diam di moda mana pun:
# organisme harus terlihat hidup justru ketika pemain tidak berbuat apa-apa
# (CDD Rule 8). Kecepatan main 8-12 fps sesuai catatan papan pemilik proyek.

const ANIM = ["idle", "merambat", "lepas", "detach", "attach"]

var avatar
var _t = 0.0
var _anim = {}            # nama -> {tex, n}
var _state = "idle"
var _transisi_t = 0.0     # sisa waktu memutar detach/attach
var _transisi = ""
var _moda_lalu = -1
var _pos_lalu = Vector2()
var _meta_t = 0.0         # kilau metamorfosis (sistem tahap lama tetap hidup)
var _tahap_lalu = 1


func _init(a):
	avatar = a
	visible = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for n in ANIM:
		var jalur = "res://aset/konsep_tendril/%s.png" % n
		if ResourceLoader.exists(jalur):
			var t = load(jalur)
			_anim[n] = {"tex": t, "n": max(1, t.get_width() / 48)}


func _process(delta):
	_t += delta
	if not visible:
		return

	# transisi moda: putar detach/attach sekali (CDD §15-16)
	if avatar.moda != _moda_lalu:
		if _moda_lalu != -1:
			_transisi = "detach" if avatar.moda == avatar.LEPAS else "attach"
			_transisi_t = 0.28 if _transisi == "detach" else 0.20
		_moda_lalu = avatar.moda
	_transisi_t = max(0.0, _transisi_t - delta)

	# metamorfosis lama: kilau singkat saat tahap naik
	if avatar.tahap != _tahap_lalu:
		_tahap_lalu = avatar.tahap
		_meta_t = 0.6
	_meta_t = max(0.0, _meta_t - delta)

	# pilih state: transisi > gerak per moda > idle
	var bergerak = _pos_lalu.distance_to(avatar.pos) > delta * 3.0
	_pos_lalu = avatar.pos
	if _transisi_t > 0.0 and _anim.has(_transisi):
		_state = _transisi
	elif avatar.moda == avatar.MERAMBAT:
		_state = "merambat" if bergerak else "idle"
	else:
		_state = "lepas" if bergerak or not avatar.di_tanah else "idle"

	queue_redraw()


func _draw():
	var ppu = float(Config.PPU)
	var p = avatar.pos * ppu + Vector2(0.0, -Config.AVATAR_TINGGI * ppu * 0.5)

	# mengisi dari sumber: cincin "minum" mengembang
	if avatar.mengisi:
		var isi_c = Color("A8D94A")
		isi_c.a = 0.35 * (1.0 - fmod(_t, 0.8) / 0.8)
		draw_arc(p, 10.0 + fmod(_t, 0.8) * 14.0, 0.0, TAU, 24, isi_c, 2.0)

	# kilau metamorfosis
	if _meta_t > 0.0:
		var q = 1.0 - _meta_t / 0.6
		var cincin = Color("A8D94A")
		cincin.a = 0.5 * (1.0 - q)
		draw_arc(p, 8.0 + q * 30.0, 0.0, TAU, 28, cincin, 3.0)

	if _anim.has(_state):
		var a = _anim[_state]
		var fr
		if _state == "detach" or _state == "attach":
			# transisi diputar SEKALI, maju sesuai sisa waktunya
			var total = 0.28 if _state == "detach" else 0.20
			var maju = 1.0 - _transisi_t / total
			fr = int(clamp(maju * a.n, 0.0, a.n - 1.0))
		else:
			# loop 10 fps (papan: 8-12 fps agar natural)
			fr = int(_t * 10.0) % a.n
		# hadap kiri = cermin
		draw_set_transform(p, 0.0, Vector2(avatar.hadap, 1.0))
		draw_texture_rect_region(a.tex,
				Rect2(Vector2(-24.0, -26.0), Vector2(48.0, 48.0)),
				Rect2(fr * 48.0, 0.0, 48.0, 48.0))
		draw_set_transform_matrix(Transform2D())
	else:
		# cadangan prosedural bila strip belum ada
		draw_circle(p, 6.0, Color("4F8F32"))
		draw_circle(p + Vector2(-2.0, -2.0), 3.0, Color("A8D94A"))

	# bar energi (UI minimal GDD §31)
	var w = 26.0
	var atas = p + Vector2(-w * 0.5, -26.0)
	draw_rect(Rect2(atas, Vector2(w, 4.0)), Color(0.06, 0.12, 0.08, 0.7))
	var isi = clamp(avatar.energi / avatar.energi_max, 0.0, 1.0)
	var c = Color("A8D94A") if isi > 0.3 else Color("C25A4A")
	draw_rect(Rect2(atas, Vector2(w * isi, 4.0)), c)
