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
var _tex = {}
var tujuan_nyala = false   # RK-2 [D]: diset Ruang01Main saat tercapai
var _umur_tanam = {}       # node F -> detik sejak tanam (animasi tumbuh)
var _t = 0.0               # jam view — napas bulb & efek halus lain

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
			"atlas_air", "latar_panel", "latar_pipa", "node_bulb",
			"node_bulb_dorman", "node_bulb_nyala", "node_tunas",
			"gril_drain", "rumpun_1", "rumpun_2"]:
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
			# alpha DITURUNKAN 0.5 -> 0.3 (koreksi pemilik: panel
			# terbaca seperti kaca/pijakan) — latar harus MUNDUR jelas
			# di belakang segala yang padat (GDD §38 readability)
			draw_texture_rect(_tex.latar_panel,
					Rect2(px * ppu, 18.0 * ppu, lebar * ppu,
					tinggi * ppu), true, Color(f, f, f, 0.3))
			px += lebar + 2.0
			idx += 1
	# 2) PITA UTILITAS di belakang jalur pipa — kesan konduit tertanam
	if _tex.has("latar_pipa"):
		draw_texture_rect(_tex.latar_pipa,
				Rect2(16.0 * ppu, 66.0 * ppu,
				(world.W - 32.0) * ppu, 22.0 * ppu), true,
				Color(1, 1, 1, 0.28))
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

	# STRUKTUR: DUAL-GRID kunci-sudut — selaras anatomi tile Varian A
	# (isi tile hidup di SUDUT PADAT, batas material di tengah tile).
	# Tile digambar BERPUSAT DI TITIK SUDUT grid, kunci dari 4 sel di
	# sekelilingnya; dengan ini permukaan tergambar TEPAT di garis
	# tabrakan. Renderer lama (tile sejajar sel) membuat crust melorot
	# setengah tile ke dalam massa — temuan audit pijakan Langkah 4.
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
			# material tile campuran: mayoritas sel padat di sudut ini
			var nama = "atlas_baja" if n_baja * 2 >= n_padat \
					else "atlas_beton"
			if not _tex.has(nama):
				continue
			var src = Rect2((kunci % 4) * 32.0,
					floori(kunci / 4.0) * 32.0, 32.0, 32.0)
			var mod = Color(1, 1, 1)
			# ANTI-MONOTON v2 (koreksi pemilik): interior memilih dari
			# 4 VARIAN TILE (asli + 3 sintesis ber-tepi-identik, baris
			# y=128 atlas) + jitter value per-sel — pola khas tile tidak
			# pernah lagi berulang rapat di grid
			if kunci == 15:
				var h = absi((vx * 73856093) ^ (vy * 19349663))
				src = _src_interior(nama, h)
				var f = [0.90, 0.95, 1.0][(h / 13) % 3]
				mod = Color(f, f, f)
			draw_texture_rect_region(_tex[nama],
					Rect2(vx * t - t * 0.5, vy * t - t * 0.5, t, t),
					src, mod)

	# GARIS PIJAKAN: strip terang tipis di permukaan atas tiap massa
	# padat — permukaan yang bisa dipijak/dirambati terbaca seketika
	# (aturan pijakan >= 2x luminance dinding), sekaligus memecah kotak
	# kontras dinaikkan (koreksi pemilik: bidang pijak vs latar belum
	# tegas) — permukaan berjalan adalah informasi gameplay, bukan mood
	var pijak = Color("6A7683")
	pijak.a = 0.5
	for ty in range(world.PT_H):
		for tx in range(world.PT_W):
			if world.padat_t[ty * world.PT_W + tx] == 1 \
					and ty > 0 \
					and world.padat_t[(ty - 1) * world.PT_W + tx] == 0:
				draw_rect(Rect2(tx * t, ty * t, t, 3.0), pijak)

	# GRIL DRAIN (koreksi pemilik: manusia terlihat berjalan di atas
	# lubang): kedua celah lantai ditutup gril besi — MANUSIA berjalan
	# DI ATASNYA, TANAMAN menyelinap lewat sela-selanya. Satu aset yang
	# menjelaskan aturan lintasan tanpa teks, sekaligus menandai titik
	# sergap rute rahasia.
	if _tex.has("gril_drain"):
		var gw = float(_tex.gril_drain.get_width())
		var gh = float(_tex.gril_drain.get_height())
		for gx in [68.0, 220.0]:
			draw_texture_rect(_tex.gril_drain,
					Rect2(gx * ppu - gw * 0.5, 111.5 * ppu, gw, gh),
					false)

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

	# RUMPUN DAUN di jaringan benih (koreksi tester pemilik: tempat
	# sembunyi tak terbaca): bahasa genre "semak = tempat melebur".
	# Mekanik TIDAK berubah — merambat di jaringan memang tersembunyi;
	# rumpun hanya membuat janji itu TERLIHAT. Value dijepit di bawah
	# ujung hidup & jejak pemain (EDV3 §3.1): rumpun benih tua lebih
	# gelap daripada pertumbuhan segar.
	for si in range(world.jalur_seed.size()):
		var seg2 = world.jalur_seed[si]
		var a2 = seg2[0]
		var b2 = seg2[1]
		var jml_r = int(a2.distance_to(b2) / 26.0)
		for k in range(jml_r):
			var h2 = absi((si * 73471) ^ ((k + 1) * 15731))
			var t2 = (float(k) + 0.5 + float(h2 % 40) * 0.01) \
					/ float(jml_r)
			var pr = a2.lerp(b2, t2) * ppu
			var nama_r = "rumpun_1" if h2 % 3 == 0 else "rumpun_2"
			if not _tex.has(nama_r):
				continue
			var tr = _tex[nama_r]
			var sk = [0.8, 0.95, 1.1][(h2 / 7) % 3]
			var w2 = tr.get_width() * sk
			var h_r = tr.get_height() * sk
			var cermin2 = -1.0 if (h2 / 13) % 2 == 0 else 1.0
			draw_set_transform(pr, (b2 - a2).angle(),
					Vector2(cermin2, 1.0))
			draw_texture_rect(tr,
					Rect2(-w2 * 0.5, -h_r * 0.55, w2, h_r), false)
			draw_set_transform_matrix(Transform2D())

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

	# NODE = sprite bulb PixelLab (seed 1701, 16x16, palet CDD §7) —
	# lingkaran prosedural pensiun; cadangan hidup bila tekstur hilang
	# node rumah: napas halus — organisme terlihat hidup justru saat
	# diam (CDD Rule 8)
	var np = world.node_pos * ppu
	if _tex.has("node_bulb"):
		var wr = 16.0 * (1.0 + 0.04 * sin(_t * 2.0))
		draw_texture_rect(_tex.node_bulb,
				Rect2(np.x - wr * 0.5, np.y + 8.0 - wr, wr, wr), false)
	else:
		draw_circle(np, 7.0, Color("285B2B"))
		draw_circle(np, 4.0, Color("3E7A32"))
		draw_circle(np + Vector2(-1.0, -1.0), 1.6, Color("79B83F"))

	# RK-2 [B]: node yang DITANAM pemain (F) — ANIMASI TUMBUH dua tahap
	# (koreksi pemilik: jangan muncul tiba-tiba): tunas kecil menyembul
	# dari titik tanam, lalu membesar jadi bulb dengan pantulan pegas,
	# lalu bernapas halus seperti node rumah
	for nd in world.node_tanam:
		var pn = nd * ppu
		var u = _umur_tanam.get(nd, 9.9)
		var mulai_bulb = 0.35 if _tex.has("node_tunas") else 0.0
		if u < mulai_bulb:
			var st = 0.5 + 0.5 * (u / mulai_bulb)
			var wt = 12.0 * st
			draw_texture_rect(_tex.node_tunas,
					Rect2(pn.x - wt * 0.5, pn.y + 8.0 - wt, wt, wt), false)
			continue
		var s = 1.0
		if u < 0.8:
			var q = clamp((u - mulai_bulb) / (0.8 - mulai_bulb), 0.0, 1.0)
			s = q * 1.25 if q < 0.8 else 1.25 - (q - 0.8) * 1.25
		else:
			s = 1.0 + 0.04 * sin(_t * 2.5 + float(nd.x) * 0.7)
		if _tex.has("node_bulb"):
			var w = 16.0 * s
			draw_texture_rect(_tex.node_bulb,
					Rect2(pn.x - w * 0.5, pn.y + 8.0 - w, w, w), false)
		else:
			draw_circle(pn, 6.0 * s, Color("285B2B"))
			draw_circle(pn, 3.5 * s, Color("3E7A32"))
			draw_circle(pn + Vector2(-1.0, -1.0), 1.4, Color("79B83F"))

	# RK-2 [D]: TUJUAN di dinding kanan — bulb DORMAN (kelabu-amber)
	# yang MENYALA hijau saat dicapai lewat jaringan (SRD §19); tujuan
	# sedikit lebih besar dari node biasa = penanda tengara
	var tp = world.tujuan_pos * ppu
	var nama_tujuan = "node_bulb_nyala" if tujuan_nyala \
			else "node_bulb_dorman"
	if _tex.has(nama_tujuan):
		# dorman = diam membeku; menyala = ikut bernapas (bangun hidup)
		var wu = 20.0 * (1.0 + 0.05 * sin(_t * 2.5)) if tujuan_nyala \
				else 20.0
		draw_texture_rect(_tex[nama_tujuan],
				Rect2(tp.x - wu * 0.5, tp.y - wu * 0.5, wu, wu), false)
	elif tujuan_nyala:
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


func _process(delta):
	# BUG playtest pemilik (bulb F "telat muncul"): view lama hanya
	# menggambar ulang saat state sensor berganti, jadi node tertanam /
	# tujuan menyala baru tampak di pergantian siklus berikutnya.
	# Kini menggambar ulang tiap frame (DaunView sudah begitu) — dan
	# umur tanam dipelihara untuk ANIMASI TUMBUH bulb.
	_t += delta
	for nd in world.node_tanam:
		if not _umur_tanam.has(nd):
			_umur_tanam[nd] = 0.0
		else:
			_umur_tanam[nd] += delta
	for k in _umur_tanam.keys():
		if not world.node_tanam.has(k):
			_umur_tanam.erase(k)   # restart R: dunia dibangun ulang
	queue_redraw()


# _kunci marching-squares lama DIHAPUS — struktur kini dual-grid murni
# (kunci dihitung langsung di loop _draw dari 4 sel sekeliling sudut)


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
