extends Node2D

# ROOM 01 — RUANG SERVIS (revisi RAD-TENDRIL-RUANG-SERVIS §40).
# FUNCTION OVER ROCK (§3): identitas ruangan datang dari pipa/kabel/
# panel/katup/drain/jeruji/lampu, bukan dari tekstur batu. Tiga lapis §5:
# STRUCTURE (panel beton) + INFRASTRUCTURE (midground logam) + WEAR/LIFE
# (noda di tekstur, stripe peringatan, TENDRIL yang menyusup §36).
# Urutan depth §22: latar -> pipa -> kabel -> platform -> TENDRIL.
#
# Tekstur aset/ruang01/ (PixelLab, snap palet kelabu; latar diderivasi
# dari panel dinding karena model keukeuh menggambar bata). Tile 8 satuan
# x PPU 4 = 32 px = 1:1.

var world
var _tex = {}

const C_JARING = Color("4F8F32")   # sulur induk (palet CDD §7)
const C_DAUN   = Color("79B83F")
const C_SENSOR = Color("D8A34A")   # kuning status CDD (waspada)
const C_SOROT  = Color("5A646D")   # bibir permukaan pijakan
const C_BAYANG = Color("0E1114")
const C_KABEL  = Color("23282D")   # garis conduit tray -> panel -> mesin
const C_LAMPU  = Color("C9D6DE")   # pendar dingin lampu kerja (§19)
const C_AMBER  = Color("D8A34A")   # stripe peringatan (§18, hemat!)


func _init(w):
	world = w
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	for n in ["beton_dinding", "beton_lantai", "jeruji", "latar", "pipa",
			"pipa_h", "pipa_siku", "katup", "rak_kabel", "kabel", "saluran",
			"sensor", "retak", "panel_listrik", "kotak_sambung", "lampu"]:
		var jalur = "res://aset/ruang01/%s.png" % n
		if ResourceLoader.exists(jalur):
			_tex[n] = load(jalur)


func _draw():
	var ppu = float(Config.PPU)
	var t = world.TILE * ppu

	# LAYER BACKGROUND: panel beton samar, kontras sangat rendah (§21, §28)
	if _tex.has("latar"):
		draw_texture_rect(_tex.latar,
				Rect2(0, 0, world.W * ppu, world.H * ppu), true)
	else:
		draw_rect(Rect2(0, 0, world.W * ppu, world.H * ppu),
				Color(0.075, 0.085, 0.10))

	# LAYER INFRASTRUCTURE (midground §21) — semua punya asal & tujuan §3:
	# rak kabel menyusuri plafon, kabel menjuntai darinya
	if _tex.has("rak_kabel"):
		draw_texture_rect(_tex.rak_kabel, Rect2(352, 32, 336, 32), true)
	if _tex.has("kabel"):
		draw_texture_rect(_tex.kabel, Rect2(420, 56, 64, 32), false)
		draw_texture_rect(_tex.kabel, Rect2(568, 56, 64, 32), false)
	# jalur pipa (§11 signature): horizontal di atas -> siku -> turun di
	# dinding kanan sampai lantai; katup besar di tengahnya (§14). Benih
	# jaringan tujuan menuruni pipa ini -> TENDRIL melilit pipa (§36).
	if _tex.has("pipa_h"):
		draw_texture_rect(_tex.pipa_h, Rect2(72, 72, 880, 32), true)
	if _tex.has("pipa_siku"):
		draw_texture_rect(_tex.pipa_siku, Rect2(952, 72, 32, 32), false)
	if _tex.has("pipa"):
		draw_texture_rect(_tex.pipa, Rect2(952, 104, 32, 344), true)
	if _tex.has("katup"):
		draw_texture_rect(_tex.katup, Rect2(952, 240, 32, 32), false)
	# rantai listrik (§12): tray -> conduit -> kotak sambung -> panel ->
	# kabel makan ke blok mesin
	draw_rect(Rect2(614, 64, 4, 96), C_KABEL)
	if _tex.has("kotak_sambung"):
		draw_texture_rect(_tex.kotak_sambung, Rect2(600, 160, 32, 32), false)
	draw_rect(Rect2(614, 192, 4, 108), C_KABEL)
	if _tex.has("panel_listrik"):
		draw_texture_rect(_tex.panel_listrik, Rect2(600, 300, 32, 48), false)
	draw_rect(Rect2(614, 348, 4, 82), C_KABEL)
	draw_rect(Rect2(614, 426, 58, 4), C_KABEL)
	# lampu kerja fluorescent (§19) + pendar dingin bertangga
	for lx in [240.0, 816.0]:
		if _tex.has("lampu"):
			draw_texture_rect(_tex.lampu, Rect2(lx, 32, 64, 32), false)
		var pendar = C_LAMPU
		pendar.a = 0.05
		draw_colored_polygon(PackedVector2Array([
			Vector2(lx + 8, 62), Vector2(lx + 56, 62),
			Vector2(lx + 84, 210), Vector2(lx - 20, 210)]), pendar)

	# LAYER STRUCTURE + platform (foreground §21): kulit cangkang = panel
	# beton; tangga & panggung & birai = jeruji logam (§10 walkway);
	# pita lantai & blok mesin = slab beton
	for ty in range(world.PT_H):
		for tx in range(world.PT_W):
			if world.padat_t[ty * world.PT_W + tx] == 0:
				continue
			var r = Rect2(tx * t, ty * t, t, t)
			var nama = "beton_lantai"
			if ty == 0 or tx == 0 or tx == world.PT_W - 1:
				nama = "beton_dinding"
			elif _jeruji(tx, ty):
				nama = "jeruji"
			if _tex.has(nama):
				draw_texture_rect(_tex[nama], r, false)
			else:
				draw_rect(r, Color(0.33, 0.35, 0.38))
			# bibir permukaan: sisi menghadap udara diberi aksen supaya
			# pijakan terbaca dalam gelap
			if _terbuka(tx, ty - 1):
				var sorot = C_SOROT
				sorot.a = 0.45
				draw_rect(Rect2(r.position, Vector2(t, ppu * 0.5)), sorot)
			if _terbuka(tx, ty + 1):
				var bayang = C_BAYANG
				bayang.a = 0.6
				draw_rect(Rect2(r.position + Vector2(0, t - ppu * 0.5),
						Vector2(t, ppu * 0.5)), bayang)

	# WEAR/AKSEN (§18, hemat): stripe peringatan di tepi blok mesin dan
	# tepi panggung tinggi
	_stripe(Vector2(676, 442))
	_stripe(Vector2(324, 154))

	# drain di mulut celah lantai (§15): fiksi lengkap — air turun ke
	# sini, koridor rahasia di bawah ADALAH salurannya, dan jaringan
	# tersembunyi berkembang di sekitarnya (§36)
	if _tex.has("saluran"):
		draw_texture_rect(_tex.saluran, Rect2(256, 434, 32, 16), false)
	# dekal retak di mulut cerobong keluar (§23: undangan)
	if _tex.has("retak"):
		draw_texture_rect(_tex.retak, Rect2(864, 432, 32, 32), false)

	# BIOLOGICAL INVASION (§35): benih jaringan di atas semua kelabu —
	# hijau satu-satunya yang hidup (§20)
	for seg in world.jalur_seed:
		var a = seg[0] * ppu
		var b = seg[1] * ppu
		draw_line(a, b, C_JARING, 3.0)
		var jarak = a.distance_to(b)
		var n = int(jarak / (10.0 * ppu))   # sehelai tiap ~10 satuan
		for i in range(n + 1):
			var p = a.lerp(b, float(i) / float(max(1, n)))
			var sisi = 1.0 if i % 2 == 0 else -1.0
			var arah = (b - a).normalized()
			var normal = Vector2(-arah.y, arah.x) * sisi * 4.0
			draw_circle(p + normal, 3.0, C_DAUN)

	# sensor perawatan (§14 SRD) paling depan — benda asing menggantung
	# menutupi sulur di belakangnya; logika deteksi jatah Phase 4
	var s = world.sensor_pos * ppu
	if _tex.has("sensor"):
		draw_texture_rect(_tex.sensor, Rect2(s.x - 16.0, 28.0, 32, 32),
				false)
	var kerucut = PackedVector2Array([
		s + Vector2(0, 24),
		s + Vector2(-56, 300),
		s + Vector2(56, 300),
	])
	var warna_kerucut = C_SENSOR
	warna_kerucut.a = 0.10
	draw_colored_polygon(kerucut, warna_kerucut)


# tangga peti, panggung tinggi, dan birai rumah = jeruji logam (RAD §10)
func _jeruji(tx, ty):
	if ty == 4:
		return true                          # panggung maintenance
	if ty == 10 and tx >= 3 and tx <= 5:
		return true                          # birai rumah
	if ty == 13 and tx >= 17 and tx <= 18:
		return true                          # anak tangga 1
	if tx >= 19 and tx <= 20 and ty >= 12 and ty <= 13:
		return true                          # anak tangga 2
	return false


# stripe peringatan kuning-hitam kecil (§18: aksen, jangan sekamar)
func _stripe(pos):
	for i in range(4):
		var warna = C_AMBER if i % 2 == 0 else C_BAYANG
		draw_rect(Rect2(pos + Vector2(i * 6.0, 0.0), Vector2(6.0, 5.0)),
				warna)


func _terbuka(tx, ty):
	if tx < 0 or tx >= world.PT_W or ty < 0 or ty >= world.PT_H:
		return false
	return world.padat_t[ty * world.PT_W + tx] == 0
