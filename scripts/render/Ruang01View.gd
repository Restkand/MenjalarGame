extends Node2D

# ROOM 01 — renderer EDV3: tileset Wang beton & baja (satu induk
# MASTER_ID) dipilih per sel via marching-squares kunci-sudut, jadi tiap
# permukaan otomatis mendapat lip/tepi/sudutnya sendiri (D2). Palet
# terkunci §3.1; latar tile datar tersendiri (D5); prop punya koneksi
# fisik (D7); kerucut sensor DIHAPUS — cahaya kini PointLight2D di
# Ruang01Main (D6). Bayangan kontak & occlusion digambar di sini (D8).

var world
# diisi Ruang01Main tiap frame: 0 idle-redup, 1 memindai, 2 curiga,
# 3 terdeteksi (siklus pindai SRD §14 — jendela aman vs bahaya HARUS
# terbaca dari kerucutnya)
var sensor_state = 0
var _state_lalu = -1
var _tex = {}
var tujuan_nyala = false   # RK-2 [D]: diset Ruang01Main saat tercapai

# DIGELAPKAN (playtest pemilik: vegetasi terlalu terang, kurang horor)
# — massa tanaman tenggelam ke rona gelap; satu-satunya hijau menyala
# di layar adalah UJUNG yang hidup (aturan value EDV3 justru menguat)
const C_JARING = Color("3E7A32")   # green base §3.1, tangga gelap
const C_DAUN   = Color("4F8F32")   # aksen daun redup
const C_BAYANG = Color("0B0E12")
const C_LOGAM  = Color("1B2128")   # rod/balok penopang
const C_KABEL  = Color("1B2128")
const C_AMBER  = Color("D89A3C")


func _init(w):
	world = w
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	for n in ["atlas_beton", "atlas_baja", "latar", "pipa", "pipa_h",
			"pipa_siku", "katup", "rak_kabel", "kabel", "saluran", "sensor",
			"retak", "panel_v3", "kotak_sambung", "lampu", "flange",
			"bracket", "noda_air", "sulur_jaringan", "materi_lembap",
			"materi_retak", "tangki_air", "atlas_lembap", "atlas_retak",
			"atlas_air", "latar_panel", "latar_pipa"]:
		var jalur = "res://aset/ruang01/%s.png" % n
		if ResourceLoader.exists(jalur):
			_tex[n] = load(jalur)
	# jumbai lumut memakai gumpalan daun player — satu bahasa piksel
	if ResourceLoader.exists("res://aset/player/rambat_daun.png"):
		_tex["jumbai"] = load("res://aset/player/rambat_daun.png")


# BLOB WANG zona material: sampel keanggotaan zona di 4 titik sudut
# tiap ubin 4-satuan, pilih tile transisi dari atlas kunci-sudut
# (bit = sudut BERISI material) — tepi blob mengikuti seni transisi
# membulat Varian A. Cadangan bertingkat: tekstur interior rata ->
# rona polos.
# blob Wang dari SEL LUKISAN (dual-grid): tile kandidat = sekitar sel
# terlukis; sudut tile berisi bila sel di sudut itu terlukis — tepi
# mengikuti sapuan kuas pelukis, tile transisi Varian A merangkainya
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
		# anti-monoton: interior memilih 4 varian + jitter value
		var h = absi((tx * 40503) ^ (ty * 88651))
		var f = [0.88, 0.94, 1.0][(h / 13) % 3] * gelap
		var mod = Color(f, f, f, a)
		var src = Rect2((kunci % 4) * 32,
				floori(kunci / 4.0) * 32, 32, 32)
		if kunci == 15:
			src = _src_interior(nama_atlas, h)
		# dual-grid: tile digambar bergeser +2 satuan (setengah sel)
		# supaya sudut-sudutnya jatuh di pusat sel yang dilukis
		draw_texture_rect_region(tex,
				Rect2((tx * 4 + 2) * ppu, (ty * 4 + 2) * ppu,
				4 * ppu, 4 * ppu), src, mod)


# pilih sumber tile interior: asli (kunci-15) atau salah satu dari 3
# varian sintesis di baris y=128 atlas (bila atlasnya sudah diperluas)
func _src_interior(nama, h):
	var pilihan = [Rect2(96, 96, 32, 32)]
	if _tex.has(nama) and _tex[nama].get_height() >= 160:
		pilihan.append(Rect2(0, 128, 32, 32))
		pilihan.append(Rect2(32, 128, 32, 32))
		pilihan.append(Rect2(64, 128, 32, 32))
	return pilihan[h % pilihan.size()]




func _draw():
	var ppu = float(Config.PPU)
	var t = world.TILE * ppu

	# BACKGROUND (D5): tile datar khusus latar, bukan tile foreground
	if _tex.has("latar"):
		draw_texture_rect(_tex.latar,
				Rect2(0, 0, world.W * ppu, world.H * ppu), true)

	# LATAR VARIATIF (koreksi pemilik: latar monoton) — komposisi
	# bidang besar bertingkat, semua value rendah (D5):
	# 1) deretan PANEL BETON besar di dinding atas — lebar/tinggi/rona
	#    dipilih hash per panel, dipisah celah seam gelap
	if _tex.has("latar_panel"):
		var px = 20.0
		var idx = 0
		while px < world.W - 24.0:
			var hh = absi((idx * 92821) ^ 68917)
			var lebar = [28.0, 36.0, 44.0][hh % 3]
			var tinggi = [30.0, 38.0, 46.0][(hh / 7) % 3]
			var f = [0.85, 1.0, 1.15][(hh / 31) % 3]
			draw_texture_rect(_tex.latar_panel,
					Rect2(px * ppu, 18.0 * ppu, lebar * ppu,
					tinggi * ppu), true, Color(f, f, f, 0.5))
			px += lebar + 2.0
			idx += 1
	# 2) PITA UTILITAS di belakang jalur pipa — kesan konduit tertanam
	if _tex.has("latar_pipa"):
		draw_texture_rect(_tex.latar_pipa,
				Rect2(16.0 * ppu, 66.0 * ppu,
				(world.W - 32.0) * ppu, 22.0 * ppu), true,
				Color(1, 1, 1, 0.4))
	# 3) SKIRTING gelap di kaki dinding + garis pijakan lantai
	var kaki = Color("0B0E12")
	kaki.a = 0.4
	draw_rect(Rect2(8.0 * ppu, 104.0 * ppu, (world.W - 16.0) * ppu,
			8.0 * ppu), kaki)
	# 4) NODA & RETAK tersebar di dinding latar (hash deterministik)
	for i in range(14):
		var hn = absi((i * 48611) ^ 26339)
		var nx = 16.0 + float(hn % 210)
		var ny = 20.0 + float((hn / 11) % 78)
		var nama_d = "noda_air" if (hn / 5) % 2 == 0 else "retak"
		if _tex.has(nama_d):
			draw_texture_rect(_tex[nama_d],
					Rect2(nx * ppu, ny * ppu, 4.0 * ppu, 4.0 * ppu),
					false, Color(1, 1, 1, 0.35))

	# MIDGROUND infrastruktur — tiap pipa berujung flange/siku/bracket
	# (aturan pipa §6), tiap prop terantai (§19 V2)
	if _tex.has("rak_kabel"):
		draw_texture_rect(_tex.rak_kabel, Rect2(352, 32, 336, 32), true)
	if _tex.has("kabel"):
		draw_texture_rect(_tex.kabel, Rect2(420, 56, 64, 32), false)
		draw_texture_rect(_tex.kabel, Rect2(568, 56, 64, 32), false)
	if _tex.has("pipa_h"):
		draw_texture_rect(_tex.pipa_h, Rect2(32, 72, 920, 32), true)
	if _tex.has("flange"):
		draw_texture_rect(_tex.flange, Rect2(20, 72, 32, 32), false)
	if _tex.has("pipa_siku"):
		draw_texture_rect(_tex.pipa_siku, Rect2(952, 72, 32, 32), false)
	if _tex.has("pipa"):
		draw_texture_rect(_tex.pipa, Rect2(952, 104, 32, 344), true)
	if _tex.has("katup"):
		draw_texture_rect(_tex.katup, Rect2(952, 240, 32, 32), false)
	if _tex.has("bracket"):
		draw_texture_rect(_tex.bracket, Rect2(948, 328, 32, 32), false)
	var b_pipa = C_BAYANG
	b_pipa.a = 0.18
	draw_rect(Rect2(32, 104, 920, 3), b_pipa)
	draw_rect(Rect2(352, 64, 336, 3), b_pipa)

	# rantai listrik: rak -> conduit -> kotak sambung -> PANEL INPAINT
	# (patch fase-selaras x%32==4, y%32==8) -> conduit -> blok mesin
	draw_rect(Rect2(626, 64, 4, 96), C_KABEL)
	if _tex.has("kotak_sambung"):
		draw_texture_rect(_tex.kotak_sambung, Rect2(612, 160, 32, 32), false)
	draw_rect(Rect2(626, 192, 4, 104), C_KABEL)
	if _tex.has("panel_v3"):
		draw_texture_rect(_tex.panel_v3, Rect2(612, 296, 36, 48), false)
	draw_rect(Rect2(626, 344, 4, 82), C_KABEL)
	draw_rect(Rect2(626, 422, 46, 4), C_KABEL)

	# lampu kerja — pendarnya urusan PointLight2D (D6), di sini hanya
	# rumah lampunya
	if _tex.has("lampu"):
		draw_texture_rect(_tex.lampu, Rect2(240, 32, 64, 32), false)
		draw_texture_rect(_tex.lampu, Rect2(816, 32, 64, 32), false)

	# koneksi struktur: rod gantung panggung, balok pikul birai
	draw_rect(Rect2(340, 32, 3, 96), C_LOGAM)
	draw_rect(Rect2(556, 32, 3, 96), C_LOGAM)
	draw_rect(Rect2(32, 344, 64, 4), C_LOGAM)
	draw_rect(Rect2(88, 348, 4, 8), C_LOGAM)

	# STRUKTUR: marching-squares kunci-sudut -> tile Wang dengan trim
	# bawaan; baja untuk tangga/panggung/birai, beton untuk sisanya
	for ty in range(world.PT_H):
		for tx in range(world.PT_W):
			if world.padat_t[ty * world.PT_W + tx] == 0:
				continue
			var nama = "atlas_baja" if _baja(tx, ty) else "atlas_beton"
			if not _tex.has(nama):
				continue
			var kunci = _kunci(tx, ty)
			var src = Rect2((kunci % 4) * 32.0,
					floori(kunci / 4.0) * 32.0, 32.0, 32.0)
			var mod = Color(1, 1, 1)
			# ANTI-MONOTON v2 (koreksi pemilik): interior memilih dari
			# 4 VARIAN TILE (asli + 3 sintesis ber-tepi-identik, baris
			# y=128 atlas) + jitter value per-sel — pola khas tile tidak
			# pernah lagi berulang rapat di grid
			if kunci == 15:
				var h = absi((tx * 73856093) ^ (ty * 19349663))
				src = _src_interior(nama, h)
				var f = [0.90, 0.95, 1.0][(h / 13) % 3]
				mod = Color(f, f, f)
			draw_texture_rect_region(_tex[nama],
					Rect2(tx * t, ty * t, t, t), src, mod)

	# GARIS PIJAKAN: strip terang tipis di permukaan atas tiap massa
	# padat — permukaan yang bisa dipijak/dirambati terbaca seketika
	# (aturan pijakan >= 2x luminance dinding), sekaligus memecah kotak
	var pijak = Color("59636F")
	pijak.a = 0.35
	for ty in range(world.PT_H):
		for tx in range(world.PT_W):
			if world.padat_t[ty * world.PT_W + tx] == 1 \
					and ty > 0 \
					and world.padat_t[(ty - 1) * world.PT_W + tx] == 0:
				draw_rect(Rect2(tx * t, ty * t, t, 3.0), pijak)

	# JUMBAI LUMUT menggantung: sel lembap yang menempel plafon padat
	# diberi jumbai daun (aset player rambat_daun — satu bahasa piksel)
	if _tex.has("jumbai"):
		for s in world.sel_lembap:
			var hj = absi((s.x * 31727) ^ (s.y * 92003))
			if hj % 3 != 0:
				continue
			if world.padat(s.x * 4 + 2, s.y * 4 - 3):
				var n_j = max(1, _tex.jumbai.get_width() / 16)
				draw_texture_rect_region(_tex.jumbai,
						Rect2(s.x * 4 * ppu, (s.y * 4 - 1) * ppu,
						2.0 * ppu, 2.0 * ppu),
						Rect2((hj % n_j) * 16.0, 0.0, 16.0, 16.0),
						Color(1, 1, 1, 0.8))

	# GROUNDING & CONTACT SHADOW (D8): gradasi occlusion di pertemuan
	# permukaan-udara, drop shadow massa gantung
	for ty in range(world.PT_H):
		for tx in range(world.PT_W):
			if world.padat_t[ty * world.PT_W + tx] == 0:
				continue
			for k in range(3):
				var oc = C_BAYANG
				oc.a = [0.18, 0.11, 0.05][k]
				if _terbuka(tx, ty - 1):
					draw_rect(Rect2(tx * t, ty * t - (k + 1) * ppu,
							t, ppu), oc)
				if _terbuka(tx, ty + 1):
					draw_rect(Rect2(tx * t, (ty + 1) * t + k * ppu,
							t, ppu), oc)

	# WEAR: decal noda air (§6 STEP 8) di titik-titik tetap, drain di
	# mulut celah, retak di mulut cerobong, stripe amber hemat
	if _tex.has("noda_air"):
		draw_texture_rect(_tex.noda_air, Rect2(276, 408, 32, 32), false)
		draw_texture_rect(_tex.noda_air, Rect2(920, 320, 32, 32), false)
		draw_texture_rect(_tex.noda_air, Rect2(430, 96, 32, 32), false)
	# demo create_map_object side-view (RK Langkah 4 kelak: prop servis
	# tambahan lewat jalur ini): tangki air menapak lantai sisi kanan
	if _tex.has("tangki_air"):
		draw_texture_rect(_tex.tangki_air, Rect2(1660, 800, 64, 96),
				false)
	if _tex.has("saluran"):
		draw_texture_rect(_tex.saluran, Rect2(256, 434, 32, 16), false)
	if _tex.has("retak"):
		draw_texture_rect(_tex.retak, Rect2(864, 432, 32, 32), false)
	_stripe(Vector2(676, 442))
	_stripe(Vector2(324, 154))

	# BIOLOGICAL INVASION: jaringan benih = SULUR BERGAMBAR (permintaan
	# pemilik: garis + bulatan prosedural diganti model tanaman generate
	# seed 1301) — tekstur diubin sepanjang segmen, dirotasi mengikuti
	# arahnya; garis lama tinggal cadangan bila tekstur hilang
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
				var w = min(tw, pjg - x)
				draw_texture_rect_region(tex_s,
						Rect2(x, -th * 0.5, w, th),
						Rect2(0.0, 0.0, w, th))
				x += tw
			draw_set_transform_matrix(Transform2D())
		else:
			draw_line(a, b, C_JARING, 3.0)

	# GDD §39 (penyimpangan #1): dua penanda MVP, bahasa bentuk tanpa teks
	# — NODE kelahiran di jaringan rumah (§6.2: checkpoint/respawn) dan
	# KEBOCORAN KATUP sebagai sumber air (§16; cincin minum di AvatarView
	# yang mengabarkan saat menghisap)
	# RK-2 [A] v3 (putusan pemilik: material DILUKIS, bukan rect):
	# blob Wang digambar langsung dari sel kanvas peta_material.png —
	# bentuk organik sepenuhnya di tangan pelukis; mekanik memakai sel
	# yang SAMA (Ruang01.material) — mata dan aturan satu sumber.
	# GRADING Langkah 4: value zona DIJEPIT di bawah pita TENDRIL —
	# lumut lingkungan harus kalah terang dari makhluk & pertumbuhannya
	# (aturan EDV3 §3.1: env <= 40%, TENDRIL 60-85% selalu paling terang)
	_zona_wang(world.sel_lembap, "atlas_lembap", 0.85, ppu, 0.72)
	_zona_wang(world.sel_retak, "atlas_retak", 0.8, ppu, 0.85)
	_zona_wang(world.sel_air, "atlas_air", 0.9, ppu, 0.82)

	var np = world.node_pos * ppu
	draw_circle(np, 7.0, Color("285B2B"))
	draw_circle(np, 4.0, Color("3E7A32"))
	draw_circle(np + Vector2(-1.0, -1.0), 1.6, Color("79B83F"))

	# RK-2 [B]: node yang DITANAM pemain (F) — bulb yang sama
	for nd in world.node_tanam:
		var pn = nd * ppu
		draw_circle(pn, 6.0, Color("285B2B"))
		draw_circle(pn, 3.5, Color("3E7A32"))
		draw_circle(pn + Vector2(-1.0, -1.0), 1.4, Color("79B83F"))

	# RK-2 [D]: TUJUAN di dinding kanan — bulb DORMAN (kelabu-amber)
	# yang MENYALA hijau saat dicapai lewat jaringan (SRD §19)
	var tp = world.tujuan_pos * ppu
	if tujuan_nyala:
		draw_circle(tp, 8.0, Color("285B2B"))
		draw_circle(tp, 5.0, Color("6FBF3E"))
		draw_circle(tp + Vector2(-1.5, -1.5), 2.0, Color("D6FF8F"))
	else:
		draw_circle(tp, 7.0, Color("232B36"))
		draw_circle(tp, 4.0, Color("3D4757"))
		draw_circle(tp + Vector2(-1.0, -1.0), 1.5, Color("8A5A20"))
	var ap = world.air_pos * ppu
	var tetes = Color("8FA3AE")
	tetes.a = 0.55
	draw_rect(Rect2(ap.x - 14.0, ap.y + 18.0, 2.0, 8.0), tetes)
	draw_rect(Rect2(ap.x - 14.0, ap.y + 30.0, 2.0, 5.0), tetes)
	var genang = Color("8FA3AE")
	genang.a = 0.30
	draw_rect(Rect2(ap.x - 18.0, ap.y + 38.0, 10.0, 2.0), genang)

	# zona deteksi sensor (RK Langkah 2): BUKAN cahaya palsu (D6 tetap
	# dihormati — pendarnya urusan PointLight2D), melainkan SIGNIFIER
	# gameplay yang jujur: digambar dari angka Config yang SAMA dengan
	# logika Sensor.gd, alpha mengikuti state (tutorial tanpa teks §23)
	var s = world.sensor_pos * ppu
	var dy_dasar = 118.0 - world.sensor_pos.y
	var lebar_dasar = (Config.SENSOR_KERUCUT_DASAR
			+ dy_dasar * Config.SENSOR_KERUCUT_LEBAR) * ppu
	var kerucut = PackedVector2Array([
		s + Vector2(-Config.SENSOR_KERUCUT_DASAR * ppu, 0.0),
		s + Vector2(Config.SENSOR_KERUCUT_DASAR * ppu, 0.0),
		Vector2(s.x + lebar_dasar, 118.0 * ppu),
		Vector2(s.x - lebar_dasar, 118.0 * ppu),
	])
	var warna_zona = Color("D89A3C")
	warna_zona.a = [0.03, 0.11, 0.15, 0.22][clamp(sensor_state, 0, 3)]
	draw_colored_polygon(kerucut, warna_zona)

	# sensor paling depan
	if _tex.has("sensor"):
		draw_texture_rect(_tex.sensor, Rect2(s.x - 16.0, 28.0, 32, 32),
				false)

	# KEDALAMAN AMBIEN (grading Langkah 4): lampu ruang servis menggantung
	# rendah — makin ke plafon makin gelap, dan koridor drain di bawah
	# lantai tenggelam dalam bayangan. Bertangga (bukan gradien halus)
	# supaya tetap bahasa pixel art; digambar SEBELUM node avatar/daun,
	# jadi TENDRIL & pertumbuhannya tetap paling terang (EDV3 §3.1).
	var kedalaman = Color("06080B")
	var pita_a = [0.20, 0.13, 0.07, 0.03]
	for i in range(4):
		kedalaman.a = pita_a[i]
		draw_rect(Rect2(0.0, i * 16.0 * ppu, world.W * ppu, 16.0 * ppu),
				kedalaman)
	kedalaman.a = 0.14
	draw_rect(Rect2(0.0, 116.0 * ppu, world.W * ppu,
			(world.H - 116.0) * ppu), kedalaman)


func _process(_delta):
	if sensor_state != _state_lalu:
		_state_lalu = sensor_state
		queue_redraw()


# kunci Wang: sudut = padat hanya bila SELURUH 4 sel di sudut itu padat
# (marching squares); luar ruangan dihitung padat supaya cangkang menyatu
func _kunci(tx, ty):
	var kunci = 0
	if _padat(tx, ty - 1) and _padat(tx - 1, ty) and _padat(tx - 1, ty - 1):
		kunci += 1   # NW
	if _padat(tx, ty - 1) and _padat(tx + 1, ty) and _padat(tx + 1, ty - 1):
		kunci += 2   # NE
	if _padat(tx, ty + 1) and _padat(tx - 1, ty) and _padat(tx - 1, ty + 1):
		kunci += 4   # SW
	if _padat(tx, ty + 1) and _padat(tx + 1, ty) and _padat(tx + 1, ty + 1):
		kunci += 8   # SE
	if kunci == 0:
		return 15   # massa setebal 1 tile: tanpa sudut interior -> slab penuh
	return kunci


func _padat(tx, ty):
	if tx < 0 or tx >= world.PT_W or ty < 0 or ty >= world.PT_H:
		return true
	return world.padat_t[ty * world.PT_W + tx] == 1


func _terbuka(tx, ty):
	return not _padat(tx, ty)


# tangga peti, panggung, birai = pelat baja (STEP 3, satu induk material)
func _baja(tx, ty):
	if ty == 4:
		return true
	if ty == 10 and tx >= 3 and tx <= 5:
		return true
	if ty == 13 and tx >= 17 and tx <= 18:
		return true
	if tx >= 19 and tx <= 20 and ty >= 12 and ty <= 13:
		return true
	return false


# stripe peringatan amber (aksen §3.1, maks 3% layar)
func _stripe(pos):
	for i in range(4):
		var warna = C_AMBER if i % 2 == 0 else C_BAYANG
		draw_rect(Rect2(pos + Vector2(i * 6.0, 0.0), Vector2(6.0, 5.0)),
				warna)
