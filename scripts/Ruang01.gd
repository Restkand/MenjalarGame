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
var jalur_seed = []               # [Vector2 a, Vector2 b] — digambar view
var mulai_pos = Vector2(28.0, 111.9)   # di jaringan rumah (§5: START)
var sensor_pos = Vector2(180.0, 10.0)  # placeholder MAINTENANCE SENSOR (§14)


func _init():
	build()


func build():
	padat_t.resize(PT_W * PT_H)
	padat_t.fill(0)
	jaringan = {}
	jalur_seed = []

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


func di_gerbang_interior(_px, _py):
	return false   # Room 01 tidak punya pintu interior (§32)


func tandai_jaringan(px, py):
	for dy in range(-1, 2):
		var y = py + dy
		if y < 0 or y >= H:
			continue
		for dx in range(-1, 2):
			var x = px + dx
			if x < 0 or x >= W:
				continue
			jaringan[Vector2i(x, y)] = 1


func jaringan_di(px, py):
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if jaringan.has(Vector2i(px + dx, py + dy)):
				return true
	return false


# dipakai main untuk pesan HUD sederhana; tidak ada air/keran di Phase 1
func dekat_air(_px, _py, _di_dalam):
	return false
