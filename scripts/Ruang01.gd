extends RefCounted

# ROOM 01 — SERVICE/MAINTENANCE ROOM (SRD-TENDRIL-ROOM01 §2-§8, §19).
# Phase 1 GRAYBOX (§33): floor, wall, ceiling, network, crack, sensor —
# tanpa art final. Dunia mandiri yang memenuhi antarmuka Avatar
# (padat_avatar / jaringan_di / tandai_jaringan / di_gerbang_interior)
# supaya seluruh sistem moda-energi-tumbuh yang sudah teruji dipakai apa
# adanya, dan kota lama tidak disentuh.
#
# Grid PADAT beresolusi TILE (8 satuan) — ruangan 32x18 tile = 256x144
# satuan (§3: 24-32 x 14-18 tile). Jaringan beresolusi SATUAN karena
# avatar menumbuhkan jalur bebas-bentuk (dict Vector2i -> 1).
#
# TIGA RUTE (§19), semuanya dari benih jaringan yang sama:
#   AMAN    jaringan rumah -> dinding kiri -> plafon -> dinding kanan.
#   CEPAT   lepas di lantai, crawl, tangga peti, lewati blok (di bawah
#           sensor), jatuh ke kanan, tempel di jaringan tujuan.
#   RAHASIA celah lantai (1 tile) -> koridor drain bawah lantai berisi
#           jaringan tersembunyi -> cerobong naik -> muncul dekat tujuan.

const TILE   = 8
const PT_W   = 32          # lebar ruangan, tile
const PT_H   = 18          # tinggi ruangan, tile
const W      = PT_W * TILE # 256 satuan
const H      = PT_H * TILE # 144 satuan

var padat_t = PackedByteArray()   # 1 per tile = beton graybox
var jaringan = {}                 # Vector2i satuan -> 1
var jaringan_tumbuh = {}          # sel yang DITUMBUHKAN pemain — bisa
                                  # dipangkas Pemangkas (benih & node
                                  # jangkar PERMANEN, RK-2 [C])
var jalur_seed = []               # [Vector2 a, Vector2 b] — digambar view
var mulai_pos = Vector2(28.0, 111.9)   # di jaringan rumah (§5: START)
var sensor_pos = Vector2(180.0, 10.0)  # MAINTENANCE SENSOR (§14)
# GDD §39 (penyimpangan #1): sumber energi = KEBOCORAN KATUP di pipa
# dinding kanan (pipa membawa air, GDD §12) — tepat di jalur jaringan
# tujuan, jadi juga alasan untuk kembali (§34). Node terpasang di
# jaringan rumah = checkpoint kelahiran (§6.2).
var air_pos = Vector2(242.0, 64.0)
var node_pos = Vector2(28.0, 109.0)

# RK-2 [D]: TUJUAN ruangan — bulb dorman di dinding kanan, menyala saat
# dicapai lewat jaringan (SRD §19: ujung rute = dinding kanan)
var tujuan_pos = Vector2(244.0, 40.0)

# RK-2 [B]: node yang DITANAM pemain lewat F (GDD §6.2)
var node_tanam = []

# RK-2 [A] — MATERIAL PERMUKAAN (GDD §12, MVP tiga kelas): BETON=0
# menolak pertumbuhan; RETAK=1 tumbuh normal; LEMBAP=2 tumbuh murah.
# Zona dalam SATUAN. Lembap: koridor drain + cerobong + celah masuk +
# kolom dinding kanan yang dialiri kebocoran katup. Retak: bercak
# dinding tengah (decal retak).
const ZONA_LEMBAP = [
	Rect2i(56, 118, 168, 18),    # koridor drain
	Rect2i(216, 110, 8, 10),     # cerobong keluar
	Rect2i(64, 110, 8, 10),      # celah masuk
	Rect2i(234, 28, 14, 84),     # kolom air dinding kanan
]
const ZONA_RETAK = [
	Rect2i(100, 40, 20, 26),     # bercak retak dinding tengah
]


func _init():
	build()


func build():
	padat_t.resize(PT_W * PT_H)
	padat_t.fill(0)
	jaringan = {}
	jaringan_tumbuh = {}
	jalur_seed = []
	node_tanam = []

	# cangkang: plafon, dua dinding, dan pita lantai tebal (§4: LOW band)
	_isi(0, 0, PT_W - 1, 0, 1)            # plafon
	_isi(0, 0, 0, PT_H - 1, 1)            # dinding kiri
	_isi(PT_W - 1, 0, PT_W - 1, PT_H - 1, 1)   # dinding kanan
	_isi(0, 14, PT_W - 1, PT_H - 1, 1)    # lantai: permukaan di y=112

	# AREA C+RAHASIA (§7, §19): celah 1 tile di lantai -> koridor drain
	# 2 tile di dalam pita lantai -> cerobong keluar di kanan blok.
	_isi(8, 14, 8, 14, 0)                 # celah masuk (squeeze turun)
	_isi(7, 15, 27, 16, 0)                # koridor drain (TIGHT, §4)
	_isi(27, 14, 27, 14, 0)               # cerobong keluar

	# AREA D (§8): panggung tinggi di bawah plafon — hanya terjangkau
	# lewat jaringan plafon (turun/tumbuh), mustahil dilompati dari lantai
	_isi(10, 4, 17, 4, 1)

	# kanopi rumah (§5): birai kecil di atas titik mulai, terjangkau
	# hanya dengan merambat dinding kiri — pelajaran vertikal pertama
	_isi(3, 10, 5, 10, 1)

	# AREA B->CEPAT (§6, §19): tangga peti menuju blok mesin; tiap anak
	# tangga naik 1 tile (8 satuan) — pas di bawah tinggi lompatan (9.2)
	_isi(17, 13, 18, 13, 1)               # anak 1: puncak 104
	_isi(19, 12, 20, 13, 1)               # anak 2: puncak 96
	_isi(21, 11, 24, 13, 1)               # blok mesin: puncak 88

	# --- benih jaringan (§29: node -> node -> node) --------------------
	# rumah (§5) + rute AMAN: dinding kiri -> plafon -> dinding kanan
	_benih(Vector2(12, 109), Vector2(56, 109))     # lantai rumah
	_benih(Vector2(12, 109), Vector2(12, 12))      # dinding kiri
	_benih(Vector2(12, 12), Vector2(244, 12))      # plafon
	_benih(Vector2(244, 12), Vector2(244, 108))    # dinding kanan = TUJUAN
	# jaringan tersembunyi di koridor drain (§19 SECRET, §29)
	_benih(Vector2(160, 133), Vector2(220, 133))


func _isi(x0, y0, x1, y1, v):
	for ty in range(y0, y1 + 1):
		for tx in range(x0, x1 + 1):
			padat_t[ty * PT_W + tx] = v


# garis benih: tandai sel jaringan selebar 3 sepanjang segmen, dan catat
# segmennya untuk digambar Ruang01View sebagai sulur induk
func _benih(a, b):
	jalur_seed.append([a, b])
	var jarak = a.distance_to(b)
	var n = int(jarak) + 1
	for i in range(n + 1):
		var p = a.lerp(b, float(i) / float(n))
		tandai_jaringan(int(round(p.x)), int(round(p.y)))


# --- antarmuka yang dipakai Avatar.gd --------------------------------------

func padat(px, py):
	if px < 0 or px >= W or py < 0 or py >= H:
		return true
	return padat_t[floori(py / float(TILE)) * PT_W
			+ floori(px / float(TILE))] == 1


func padat_avatar(px, py, _di_dalam):
	return padat(px, py)


# RK-2 [A]: kelas material di titik satuan (GDD §12)
func material(px, py):
	var p = Vector2i(px, py)
	for z in ZONA_LEMBAP:
		if z.has_point(p):
			return 2
	for z in ZONA_RETAK:
		if z.has_point(p):
			return 1
	return 0


func bisa_tumbuh(px, py):
	return material(px, py) > 0


# faktor biaya tumbuh: lembap murah (GDD §12 "material ideal")
func faktor_tumbuh(px, py):
	return 0.5 if material(px, py) == 2 else 1.0


# RK-2 [B]: aura node — regen lebih cepat di dekat node (rumah/tanaman)
func dekat_node(p):
	if p.distance_to(node_pos) <= Config.NODE_AURA:
		return true
	for n in node_tanam:
		if p.distance_to(n) <= Config.NODE_AURA:
			return true
	return false


func di_gerbang_interior(_px, _py):
	return false   # Room 01 tidak punya pintu interior (§32)


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
			# sel tumbuhan pemain ditandai TERPISAH — hanya sel yang
			# belum jadi jaringan (benih/node tak boleh ikut terpangkas)
			if tumbuh and not jaringan.has(sel):
				jaringan_tumbuh[sel] = 1
			jaringan[sel] = 1


# RK-2 [C]: Pemangkas memotong sel tumbuhan pemain (benih/node aman)
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


# GDD §39: cukup dekat dengan kebocoran katup = bisa minum (§16 AIR)
func dekat_air(px, py, _di_dalam):
	return Vector2(px, py).distance_to(air_pos) <= Config.AIR_RADIUS
