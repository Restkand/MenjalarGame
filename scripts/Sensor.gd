extends RefCounted

# MAINTENANCE SENSOR (RK Langkah 2-3, SRD §13-15) — sumbu kedua Room 01,
# dipertajam ala Splinter Cell atas putusan gerbang Langkah 3: memilih
# rute harus terasa seperti keputusan.
#
# SIKLUS PINDAI (SRD §14: IDLE → SCAN): sensor TIDAK awas terus-menerus.
#   IDLE  — kerucut redup, tidak mendeteksi apa pun. Jendela bergerak.
#   SCAN  — kerucut menyala, deteksi aktif. Berlindung atau DIAM.
# ALARM (TERDETEKSI) mengunci sensor terus memindai selama waspada.
#
# State deteksi (dihitung di grid: kerucut + raycast garis-pandang):
#   AMAN       — sensor idle, di luar kerucut, terhalang beton, ATAU
#                DIAM di jaringan (GDD §13: diam = TERSEMBUNYI penuh).
#   CURIGA     — BERGERAK di jaringan dalam kerucut saat SCAN — kamuflase
#                daun menyamarkan, tapi gerakan tetap menarik perhatian.
#   TERDETEKSI — terbuka (moda LEPAS) dalam kerucut saat SCAN.
#
# Merah "diburu" DICADANGKAN untuk Phase 6.

const AMAN       = 0
const CURIGA     = 1
const TERDETEKSI = 2

var pos = Vector2(180.0, 10.0)   # titik lensa, satuan simulasi
var alarm = false                # dikunci main selama waspada
# parameter kerucut per-pemasangan (Ruang 00: kerucut grow light lebih
# sempit & lantai lebih tinggi). Negatif = pakai angka Config Room 01.
var lantai_y = 118.0
var dasar = -1.0
var lebar = -1.0
var _fase_t = 0.0                # penghitung siklus
var _memindai = false


func update(dt):
	_fase_t += dt
	if alarm:
		_memindai = true
		_fase_t = 0.0
		return
	if _memindai and _fase_t >= Config.SENSOR_PINDAI:
		_memindai = false
		_fase_t = 0.0
	elif not _memindai and _fase_t >= Config.SENSOR_JEDA:
		_memindai = true
		_fase_t = 0.0


func memindai():
	return _memindai or alarm


func state(avatar, world, diam):
	if not memindai():
		return AMAN
	var p = avatar.pos + Vector2(0.0, -Config.AVATAR_TINGGI * 0.5)
	if not _dalam_kerucut(p):
		return AMAN
	if not _garis_bebas(p, world):
		return AMAN
	if avatar.moda == avatar.MERAMBAT:
		return AMAN if diam else CURIGA
	return TERDETEKSI


# kerucut menghadap bawah: melebar `lebar` per satuan turun
func _dalam_kerucut(p):
	var dy = p.y - pos.y
	if dy < 0.0 or p.y > lantai_y:
		return false
	var d = dasar if dasar > 0.0 else Config.SENSOR_KERUCUT_DASAR
	var l = lebar if lebar > 0.0 else Config.SENSOR_KERUCUT_LEBAR
	return abs(p.x - pos.x) <= d + dy * l


# raycast grid sensor->avatar, langkah 2 satuan; beton memutus pandangan
func _garis_bebas(p, world):
	var n = int(pos.distance_to(p) / 2.0) + 1
	for i in range(1, n):
		var q = pos.lerp(p, float(i) / float(n))
		if world.padat(int(round(q.x)), int(round(q.y))):
			return false
	return true
