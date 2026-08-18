extends RefCounted

# RUANG 00 — LAB BOTANI (SRD-TENDRIL-RUANG00-LAB): ruang KELAHIRAN +
# tutorial empat mekanik tanpa teks. 32x14 tile = 256x112 satuan (§2).
#
# TIGA ZONA (§6):
#   A  Tabung Induk  (tile 0-9)   — organik, aman; spawn di jaringan
#      induk; CELAH di tile 8-9 memaksa LEPAS + lompat pertama.
#   B  Koridor Terang (tile 10-22) — steril; tiga kerucut grow light
#      (kenop di Ruang01Main); dua rak + meja memberi bayangan/pijakan.
#   C  Lorong Keluar (tile 23-31) — node simpan, trellis naik, KATUP
#      membasahi panel kanan -> permukaan tumbuh cepat -> lorong keluar
#      di kanan-atas menuju Room 01.
#
# Aturan permukaan (§5): keramik/kaca/baja steril MENOLAK tumbuh;
# panel yang DIBASAHI sprinkler = tumbuh cepat (sel_basah dinamis).

const TILE = 8
const PT_W = 32
const PT_H = 14
const W    = PT_W * TILE   # 256
const H    = PT_H * TILE   # 112

var padat_t = PackedByteArray()
var jaringan = {}
var jaringan_tumbuh = {}
var jalur_seed = []
var mulai_pos = Vector2(20.0, 95.9)    # lahir di sulur induk (§6 A)
var node_pos = Vector2(196.0, 94.0)    # int_node tile 24 (§6 C)
var node_tanam = []
var katup_pos = Vector2(224.0, 52.0)   # int_valve di platform atas
var sprinkler_pos = Vector2(244.0, 10.0)
var katup_terbuka = false
var basah_maju = 0.0                   # air merambat turun (animasi)
var keluar_rect = Rect2(248.0, 16.0, 8.0, 20.0)   # int_door tile 31

# material dilukis (semantik = Room 01) + SEL BASAH dinamis sprinkler
var sel_lembap = {}
var sel_retak = {}
var sel_air = {}
var sel_basah = {}


func _init():
	build()


func build():
	padat_t.resize(PT_W * PT_H)
	padat_t.fill(0)
	jaringan = {}
	jaringan_tumbuh = {}
	jalur_seed = []
	node_tanam = []
	sel_basah = {}
	katup_terbuka = false
	basah_maju = 0.0

	# cangkang
	_isi(0, 0, PT_W - 1, 0, 1)                 # plafon
	_isi(0, 0, 0, PT_H - 1, 1)                 # dinding kiri
	_isi(PT_W - 1, 0, PT_W - 1, PT_H - 1, 1)   # dinding kanan
	_isi(0, 12, PT_W - 1, PT_H - 1, 1)         # lantai: permukaan y=96

	# CELAH tutorial LEPAS (§6 A): lubang di lantai tile 8. DEVIASI
	# SADAR dari SRD §6 "2 tile": jangkauan lompat fisika terkunci
	# ±13 satuan — 2 tile (16) mustahil; 1 tile (8) nyaman untuk
	# lompatan PERTAMA pemain. Dasar celah tertutup: jatuh = memanjat
	# pulang lewat sulur dinding celah, bukan hukuman keras.
	_isi(8, 12, 8, 12, 0)

	# ZONA B: dua rak semai RENDAH (1 tile — bisa dilompati; bayangan
	# saku gelap di sisinya + puncaknya di luar kerucut) + meja lab
	# lebih tinggi yang dipanjat lewat puncak rak: koridor jadi rantai
	# panjat rak -> meja -> rak (§6 B)
	_isi(13, 11, 13, 11, 1)    # spc_rack kiri, puncak y=88
	_isi(18, 11, 18, 11, 1)    # spc_rack kanan
	_isi(15, 10, 16, 11, 1)    # prp_bench, puncak y=80

	# ZONA C: platform katup (dicapai lewat trellis tile 26)
	_isi(26, 7, 28, 7, 1)      # puncak y=56

	# LORONG KELUAR (§0): bukaan di dinding kanan atas -> Room 01
	_isi(31, 2, 31, 4, 0)

	_baca_peta()

	# benih jaringan induk (§6 A): cincin sulur zona A + tali penyelamat
	# celah + pad node zona C + trellis (§6 C)
	_benih(Vector2(8, 94), Vector2(62, 94))     # lantai induk
	_benih(Vector2(8, 94), Vector2(8, 14))      # dinding kiri
	_benih(Vector2(8, 14), Vector2(62, 14))     # plafon A
	_benih(Vector2(66, 108), Vector2(66, 96))   # dinding celah (pulang)
	_benih(Vector2(190, 94), Vector2(202, 94))  # pad node simpan
	_benih(Vector2(208, 94), Vector2(208, 58))  # trellis naik platform


func _isi(x0, y0, x1, y1, v):
	for ty in range(y0, y1 + 1):
		for tx in range(x0, x1 + 1):
			padat_t[ty * PT_W + tx] = v


func _benih(a, b):
	jalur_seed.append([a, b])
	var n = int(a.distance_to(b)) + 1
	for i in range(n + 1):
		var p = a.lerp(b, float(i) / float(n))
		tandai_jaringan(int(round(p.x)), int(round(p.y)))


func _baca_peta():
	sel_lembap = {}
	sel_retak = {}
	sel_air = {}
	var jalur = ProjectSettings.globalize_path(
			"res://aset/ruang00/peta_material_lab.png")
	if not FileAccess.file_exists(jalur):
		return
	var img = Image.load_from_file(jalur)
	img.convert(Image.FORMAT_RGBA8)
	for y in range(min(28, img.get_height())):
		for x in range(min(64, img.get_width())):
			var c = img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var sel = Vector2i(x, y)
			if c.g > 0.4 and c.r < 0.3 and c.b < 0.3:
				sel_lembap[sel] = 1
			elif c.r > 0.4 and c.b < 0.3:
				sel_retak[sel] = 1
			elif c.b > 0.4 and c.r < 0.3:
				sel_air[sel] = 1


# KATUP -> SPRINKLER (§6 C, beat 6): panel kanan dibasahi bertahap dari
# atas ke bawah; sel basah = kelas tumbuh CEPAT (identik lembap)
func update(dt):
	if katup_terbuka and basah_maju < 1.0:
		basah_maju = min(1.0, basah_maju + dt * 0.5)
		var y_maks = 4 + int(basah_maju * 19.0)   # sel y4..y23
		for y in range(4, y_maks + 1):
			sel_basah[Vector2i(61, y)] = 1
			sel_basah[Vector2i(60, y)] = 1


func buka_katup():
	if katup_terbuka:
		return false
	katup_terbuka = true
	return true


func di_keluar(p):
	return keluar_rect.has_point(p)


# --- antarmuka Avatar (identik Ruang01) --------------------------------

func padat(px, py):
	if px < 0 or px >= W or py < 0 or py >= H:
		return true
	return padat_t[floori(py / float(TILE)) * PT_W
			+ floori(px / float(TILE))] == 1


func padat_avatar(px, py, _di_dalam):
	return padat(px, py)


func material(px, py):
	var sel = Vector2i(floori(px / 4.0), floori(py / 4.0))
	if sel_basah.has(sel) or sel_lembap.has(sel):
		return 2
	if sel_retak.has(sel):
		return 1
	for ofs in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1),
			Vector2i(0, -1)]:
		if sel_basah.has(sel + ofs) or sel_lembap.has(sel + ofs):
			return 2
		if sel_retak.has(sel + ofs):
			return 1
	return 0


func bisa_tumbuh(px, py):
	return material(px, py) > 0


func faktor_tumbuh(px, py):
	return 0.5 if material(px, py) == 2 else 1.0


func dekat_node(p):
	if p.distance_to(node_pos) <= Config.NODE_AURA:
		return true
	for n in node_tanam:
		if p.distance_to(n) <= Config.NODE_AURA:
			return true
	return false


func di_gerbang_interior(_px, _py):
	return false


func tandai_jaringan(px, py, tumbuh = false):
	for dy in range(-1, 2):
		var y = py + dy
		if y < 0 or y >= H:
			continue
		for dx in range(-1, 2):
			var x = px + dx
			if x < 0 or x >= W:
				continue
			var sel = Vector2i(x, y)
			if tumbuh and not jaringan.has(sel):
				jaringan_tumbuh[sel] = 1
			jaringan[sel] = 1


func potong_tumbuhan(px, py):
	var sel = Vector2i(px, py)
	if jaringan_tumbuh.has(sel):
		jaringan_tumbuh.erase(sel)
		jaringan.erase(sel)


func jaringan_di(px, py):
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if jaringan.has(Vector2i(px + dx, py + dy)):
				return true
	return false


func dekat_air(_px, _py, _di_dalam):
	return false   # lab tanpa stasiun minum — energi diajarkan ketat
