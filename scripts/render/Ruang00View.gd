extends Node2D

# Tampilan RUANG 00 — LAB BOTANI (SRD Lab §3/§9): bahasa piksel yang
# SAMA dengan Room 01 (atlas dual-grid, blob zona, rumpun jaringan)
# plus identitas lab: overlay steril cyan di Zona B, kerucut grow
# light merah-muda hangat, tabung induk, dan panel yang MEMBASAH.
# Prop lab bertekstur PixelLab bila ada; cadangan graybox selalu hidup.

var world
var sensor_state = 1       # 1 menyala, 2 curiga, 3 terdeteksi
var _tex = {}
var _t = 0.0

const C_BAYANG  = Color("0B0E12")
const C_STERIL  = Color("BFD8DC")   # cyan klinis (SRD §3)
const C_GROW    = Color("E8909E")   # merah-muda hangat — BUKAN ungu
const C_KACA    = Color("7FA8B0")
const C_LOGAM   = Color("1B2128")


func _init(w):
	world = w
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for n in ["atlas_beton", "atlas_baja", "latar", "atlas_lembap",
			"atlas_retak", "atlas_air", "node_bulb", "rumpun_1",
			"rumpun_2", "sulur_jaringan", "noda_air", "retak"]:
		var jalur = "res://aset/ruang01/%s.png" % n
		if ResourceLoader.exists(jalur):
			_tex[n] = load(jalur)
	for n in ["tabung_induk", "rak_semai", "lampu_grow", "pintu_keluar",
			"kaca_latar", "tabung_pecah"]:
		var jalur = "res://aset/ruang00/%s.png" % n
		if ResourceLoader.exists(jalur):
			_tex[n] = load(jalur)


func _process(delta):
	_t += delta
	queue_redraw()


func _draw():
	var ppu = float(Config.PPU)
	var t = world.TILE * ppu

	# latar dasar (tekstur Room 01 — satu gedung yang sama)
	if _tex.has("latar"):
		draw_texture_rect(_tex.latar,
				Rect2(0, 0, world.W * ppu, world.H * ppu), true)

	# ZONA B STERIL: pita overlay cyan pucat + panel kaca latar
	# (kontras naratif SRD §1: kiri organik, tengah steril)
	var steril = C_STERIL
	steril.a = 0.055
	draw_rect(Rect2(80.0 * ppu, 8.0 * ppu, 104.0 * ppu, 88.0 * ppu),
			steril)
	if _tex.has("kaca_latar"):
		draw_texture_rect(_tex.kaca_latar,
				Rect2(84.0 * ppu, 40.0 * ppu, 96.0 * ppu, 40.0 * ppu),
				true, Color(1, 1, 1, 0.5))
	else:
		# graybox kaca: bingkai panel + refleksi miring
		for k in range(3):
			var kx = (86.0 + k * 32.0) * ppu
			var kaca = C_KACA
			kaca.a = 0.10
			draw_rect(Rect2(kx, 44.0 * ppu, 28.0 * ppu, 36.0 * ppu), kaca)
			kaca.a = 0.25
			draw_rect(Rect2(kx, 44.0 * ppu, 28.0 * ppu, 36.0 * ppu),
					kaca, false, 2.0)

	# noda di dinding lab (hemat)
	for i in range(6):
		var hn = absi((i * 48611) ^ 91733)
		var nx = 12.0 + float(hn % 230)
		var ny = 14.0 + float((hn / 11) % 70)
		var nama_d = "noda_air" if (hn / 5) % 2 == 0 else "retak"
		if _tex.has(nama_d):
			draw_texture_rect(_tex[nama_d],
					Rect2(nx * ppu, ny * ppu, 4.0 * ppu, 4.0 * ppu),
					false, Color(1, 1, 1, 0.3))

	# STRUKTUR dual-grid (identik Room 01): baja untuk rak/meja/platform
	for vy in range(world.PT_H + 1):
		for vx in range(world.PT_W + 1):
			var kunci = 0
			var n_padat = 0
			var n_baja = 0
			for c in [[vx - 1, vy - 1, 1], [vx, vy - 1, 2],
					[vx - 1, vy, 4], [vx, vy, 8]]:
				if _padat(c[0], c[1]):
					kunci += c[2]
					n_padat += 1
					if _baja(c[0], c[1]):
						n_baja += 1
			if kunci == 0:
				continue
			var nama = "atlas_baja" if n_baja * 2 >= n_padat \
					else "atlas_beton"
			if not _tex.has(nama):
				continue
			var src = Rect2((kunci % 4) * 32.0,
					floori(kunci / 4.0) * 32.0, 32.0, 32.0)
			var mod = Color(1, 1, 1)
			if kunci == 15:
				var h = absi((vx * 73856093) ^ (vy * 19349663))
				src = _src_interior(nama, h)
				var f = [0.90, 0.95, 1.0][(h / 13) % 3]
				mod = Color(f, f, f)
			draw_texture_rect_region(_tex[nama],
					Rect2(vx * t - t * 0.5, vy * t - t * 0.5, t, t),
					src, mod)

	# garis pijakan (aturan >=2x luminance — identik Room 01)
	var pijak = Color("6A7683")
	pijak.a = 0.5
	for ty in range(world.PT_H):
		for tx in range(world.PT_W):
			if world.padat_t[ty * world.PT_W + tx] == 1 \
					and ty > 0 \
					and world.padat_t[(ty - 1) * world.PT_W + tx] == 0:
				draw_rect(Rect2(tx * t, ty * t, t, 3.0), pijak)

	# occlusion tepi permukaan (D8 ringkas)
	for ty in range(world.PT_H):
		for tx in range(world.PT_W):
			if world.padat_t[ty * world.PT_W + tx] == 0:
				continue
			if ty > 0 and world.padat_t[(ty - 1) * world.PT_W + tx] == 0:
				var oc = C_BAYANG
				oc.a = 0.15
				draw_rect(Rect2(tx * t, ty * t - ppu, t, ppu), oc)

	# blob zona material (semantik & seni Room 01)
	_zona_wang(world.sel_lembap, "atlas_lembap", 0.85, ppu, 0.72)
	_zona_wang(world.sel_retak, "atlas_retak", 0.8, ppu, 0.85)
	_zona_wang(world.sel_air, "atlas_air", 0.9, ppu, 0.82)
	# panel MEMBASAH (dinamis katup): kilau air di dinding kanan
	_zona_wang(world.sel_basah, "atlas_air", 0.85, ppu, 0.95)

	# jaringan benih bergambar + rumpun tempat sembunyi (bahasa Room 01)
	for seg in world.jalur_seed:
		var a = seg[0] * ppu
		var b = seg[1] * ppu
		if _tex.has("sulur_jaringan"):
			var tex_s = _tex.sulur_jaringan
			var tw = float(tex_s.get_width())
			var th = float(tex_s.get_height())
			var v = b - a
			draw_set_transform(a, v.angle(), Vector2.ONE)
			var pjg = v.length()
			var x = 0.0
			while x < pjg:
				var w2 = min(tw, pjg - x)
				draw_texture_rect_region(tex_s,
						Rect2(x, -th * 0.5, w2, th),
						Rect2(0.0, 0.0, w2, th))
				x += tw
			draw_set_transform_matrix(Transform2D())
		else:
			draw_line(a, b, Color("3E7A32"), 3.0)
	for si in range(world.jalur_seed.size()):
		var seg2 = world.jalur_seed[si]
		var a2 = seg2[0]
		var b2 = seg2[1]
		var jml_r = int(a2.distance_to(b2) / 24.0)
		for k in range(jml_r):
			var h2 = absi((si * 73471) ^ ((k + 1) * 15731))
			var t2 = (float(k) + 0.5) / float(jml_r)
			var pr = a2.lerp(b2, t2) * ppu
			var nama_r = "rumpun_1" if h2 % 3 == 0 else "rumpun_2"
			if not _tex.has(nama_r):
				continue
			var tr = _tex[nama_r]
			var sk = [0.75, 0.9, 1.05][(h2 / 7) % 3]
			var w3 = tr.get_width() * sk
			var h3 = tr.get_height() * sk
			draw_set_transform(pr, (b2 - a2).angle(),
					Vector2(-1.0 if (h2 / 13) % 2 == 0 else 1.0, 1.0))
			draw_texture_rect(tr, Rect2(-w3 * 0.5, -h3 * 0.55, w3, h3),
					false)
			draw_set_transform_matrix(Transform2D())

	# TABUNG INDUK (spawn_mother, §4.3): kelahiran pemain
	if _tex.has("tabung_induk"):
		var ti = _tex.tabung_induk
		draw_texture_rect(ti, Rect2(10.0 * ppu,
				96.0 * ppu - ti.get_height(),
				float(ti.get_width()), float(ti.get_height())), false)
	else:
		# graybox: tangki retak + pendar isi hijau berdenyut
		draw_rect(Rect2(11.0 * ppu, 52.0 * ppu, 20.0 * ppu, 44.0 * ppu),
				Color("1A2029"))
		var isi = Color("4F8F32")
		isi.a = 0.5 + 0.15 * sin(_t * 2.0)
		draw_rect(Rect2(13.0 * ppu, 58.0 * ppu, 16.0 * ppu, 36.0 * ppu),
				isi)
		draw_rect(Rect2(11.0 * ppu, 52.0 * ppu, 20.0 * ppu, 44.0 * ppu),
				Color("3D4757"), false, 2.0)
	# tabung pecah berserakan (§6 A)
	if _tex.has("tabung_pecah"):
		for px2 in [38.0, 50.0]:
			var tp = _tex.tabung_pecah
			draw_texture_rect(tp, Rect2(px2 * ppu,
					96.0 * ppu - tp.get_height(),
					float(tp.get_width()), float(tp.get_height())), false)
	else:
		for px2 in [38.0, 50.0]:
			draw_rect(Rect2(px2 * ppu, 84.0 * ppu, 6.0 * ppu, 12.0 * ppu),
					Color(0.5, 0.66, 0.69, 0.25))

	# RAK SEMAI di muka blok baja (§6 B) — art bila ada
	if _tex.has("rak_semai"):
		for rx in [104.0, 144.0]:
			var rs = _tex.rak_semai
			draw_texture_rect(rs, Rect2(rx * ppu,
					96.0 * ppu - rs.get_height(),
					float(rs.get_width()), float(rs.get_height())), false)

	# GROW LIGHT bar + kerucut cahaya (SRD §3: merah-muda hangat).
	# Kerucut = SIGNIFIER JUJUR dari angka Sensor yang sama.
	for gx in [90.0, 124.0, 158.0]:
		if _tex.has("lampu_grow"):
			var lg = _tex.lampu_grow
			draw_texture_rect(lg, Rect2(gx * ppu - lg.get_width() * 0.5,
					8.0 * ppu, float(lg.get_width()),
					float(lg.get_height())), false)
		else:
			draw_rect(Rect2(gx * ppu - 14.0, 8.0 * ppu, 28.0, 6.0),
					Color("2E3844"))
			var bar = C_GROW
			bar.a = 0.9
			draw_rect(Rect2(gx * ppu - 12.0, 9.5 * ppu, 24.0, 3.0), bar)
		var dy = 96.0 - 10.0
		var lebar_atas = 3.0 * ppu
		var lebar_bawah = (3.0 + dy * 0.12) * ppu
		var kerucut = PackedVector2Array([
			Vector2(gx * ppu - lebar_atas, 10.0 * ppu),
			Vector2(gx * ppu + lebar_atas, 10.0 * ppu),
			Vector2(gx * ppu + lebar_bawah, 96.0 * ppu),
			Vector2(gx * ppu - lebar_bawah, 96.0 * ppu),
		])
		var wc = C_GROW
		wc.a = [0.0, 0.10, 0.14, 0.22][clamp(sensor_state, 0, 3)]
		draw_colored_polygon(kerucut, wc)

	# NODE simpan (§6 C) — bulb bernapas (aset Room 01, satu bahasa)
	var np = world.node_pos * ppu
	if _tex.has("node_bulb"):
		var wr = 16.0 * (1.0 + 0.04 * sin(_t * 2.0))
		draw_texture_rect(_tex.node_bulb,
				Rect2(np.x - wr * 0.5, np.y + 8.0 - wr, wr, wr), false)
	for nd in world.node_tanam:
		var pn = nd * ppu
		if _tex.has("node_bulb"):
			draw_texture_rect(_tex.node_bulb,
					Rect2(pn.x - 8.0, pn.y, 16.0, 16.0), false)

	# KATUP + SPRINKLER (§4.5): roda kuningan; menyemprot bila terbuka
	var kp = world.katup_pos * ppu
	draw_circle(kp, 6.0, Color("8A5A20"))
	draw_circle(kp, 3.5, Color("D89A3C"))
	draw_line(kp + Vector2(-6.0, 0.0), kp + Vector2(6.0, 0.0),
			Color("59636F"), 2.0)
	var sp = world.sprinkler_pos * ppu
	draw_rect(Rect2(sp.x - 6.0, sp.y - 4.0, 12.0, 6.0), C_LOGAM)
	if world.katup_terbuka:
		# semprotan: garis air jatuh ke panel kanan (deterministik)
		for k in range(5):
			var fase = fmod(_t * 1.6 + float(k) * 0.2, 1.0)
			var ax = sp.x + 8.0 + float(k) * 7.0
			var ay = sp.y + fase * (86.0 * ppu * world.basah_maju)
			var air = Color("8FC3D6")
			air.a = 0.5 * (1.0 - fase * 0.5)
			draw_line(Vector2(ax, ay), Vector2(ax, ay + 8.0), air, 1.5)

	# LORONG KELUAR (§0): bukaan berbingkai + pendar mengundang
	if _tex.has("pintu_keluar"):
		var pk = _tex.pintu_keluar
		draw_texture_rect(pk, Rect2(248.0 * ppu - 4.0, 14.0 * ppu,
				float(pk.get_width()), float(pk.get_height())), false)
	else:
		draw_rect(Rect2(246.0 * ppu, 14.0 * ppu, 10.0 * ppu, 24.0 * ppu),
				Color("3D4757"), false, 3.0)
	var undang = Color("D6FF8F")
	undang.a = 0.10 + 0.05 * sin(_t * 2.2)
	draw_rect(Rect2(248.0 * ppu, 16.0 * ppu, 8.0 * ppu, 20.0 * ppu),
			undang)


func _zona_wang(sel, nama_atlas, a, ppu, gelap = 1.0):
	if sel.is_empty() or not _tex.has(nama_atlas):
		return
	var tex = _tex[nama_atlas]
	var kandidat = {}
	for s in sel:
		for dy in range(-1, 1):
			for dx in range(-1, 1):
				kandidat[Vector2i(s.x + dx, s.y + dy)] = true
	for k in kandidat:
		var tx = k.x
		var ty = k.y
		var kunci = 0
		if sel.has(Vector2i(tx, ty)):
			kunci += 1
		if sel.has(Vector2i(tx + 1, ty)):
			kunci += 2
		if sel.has(Vector2i(tx, ty + 1)):
			kunci += 4
		if sel.has(Vector2i(tx + 1, ty + 1)):
			kunci += 8
		if kunci == 0:
			continue
		var h = absi((tx * 40503) ^ (ty * 88651))
		var f = [0.88, 0.94, 1.0][(h / 13) % 3] * gelap
		var mod = Color(f, f, f, a)
		var src = Rect2((kunci % 4) * 32,
				floori(kunci / 4.0) * 32, 32, 32)
		if kunci == 15:
			src = _src_interior(nama_atlas, h)
		draw_texture_rect_region(tex,
				Rect2((tx * 4 + 2) * ppu, (ty * 4 + 2) * ppu,
				4 * ppu, 4 * ppu), src, mod)


func _src_interior(nama, h):
	var pilihan = [Rect2(96, 96, 32, 32)]
	if _tex.has(nama) and _tex[nama].get_height() >= 160:
		pilihan.append(Rect2(0, 128, 32, 32))
		pilihan.append(Rect2(32, 128, 32, 32))
		pilihan.append(Rect2(64, 128, 32, 32))
	return pilihan[h % pilihan.size()]


func _padat(tx, ty):
	if tx < 0 or tx >= world.PT_W or ty < 0 or ty >= world.PT_H:
		return true
	return world.padat_t[ty * world.PT_W + tx] == 1


# rak semai, meja lab, platform katup = pelat baja
func _baja(tx, ty):
	if tx == 13 and ty == 11:
		return true
	if tx == 18 and ty == 11:
		return true
	if tx >= 15 and tx <= 16 and ty >= 10 and ty <= 11:
		return true
	if tx >= 26 and tx <= 28 and ty == 7:
		return true
	return false
