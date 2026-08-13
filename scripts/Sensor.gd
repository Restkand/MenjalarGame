extends RefCounted

# MAINTENANCE SENSOR (RK Langkah 2, SRD §13-15) — sumbu kedua Room 01.
# Tiga state deteksi, dihitung DI GRID (kerucut + raycast garis-pandang,
# tanpa physics engine — sejalan aturan tabrakan rumah):
#
#   AMAN       — di luar kerucut, ATAU garis pandang terhalang beton
#                (koridor drain lolos DI SINI: lantai memblokir pandang).
#   CURIGA     — dalam kerucut & terlihat, tapi TERSAMAR: menempel di
#                jaringan (kamuflase daun, SRD §12). Tanpa konsekuensi.
#   TERDETEKSI — dalam kerucut & terlihat, terbuka (moda LEPAS).
#
# Merah "diburu" DICADANGKAN untuk Phase 6 — jangan dipakai di sini.

const AMAN       = 0
const CURIGA     = 1
const TERDETEKSI = 2

var pos = Vector2(180.0, 10.0)   # titik lensa, satuan simulasi


func state(avatar, world):
	var p = avatar.pos + Vector2(0.0, -Config.AVATAR_TINGGI * 0.5)
	if not _dalam_kerucut(p):
		return AMAN
	if not _garis_bebas(p, world):
		return AMAN
	return CURIGA if avatar.moda == avatar.MERAMBAT else TERDETEKSI


# kerucut menghadap bawah: melebar SENSOR_KERUCUT_LEBAR per satuan turun
func _dalam_kerucut(p):
	var dy = p.y - pos.y
	if dy < 0.0 or p.y > 118.0:
		return false
	return abs(p.x - pos.x) <= Config.SENSOR_KERUCUT_DASAR \
			+ dy * Config.SENSOR_KERUCUT_LEBAR


# raycast grid sensor->avatar, langkah 2 satuan; beton memutus pandangan
func _garis_bebas(p, world):
	var n = int(pos.distance_to(p) / 2.0) + 1
	for i in range(1, n):
		var q = pos.lerp(p, float(i) / float(n))
		if world.padat(int(round(q.x)), int(round(q.y))):
			return false
	return true
