extends RefCounted

# Tiga babak (TAHAP F, docs/06 §6) — busur Terra Nil: bangun ekonomi,
# penuhi spesifikasi, tinggalkan jejak permanen.
#
#   I   MENYUSUP      jangkau satu akuifer DAN dapatkan pijakan di fasad.
#                     Yang mengunci: ekonomi min(Air, Cahaya) — akuifer di
#                     balik dua lapis beton adalah investasi energi pertama.
#   II  MENGHIJAUKAN  tutupan >= ZONA_TARGET di TIAP kuadran. Yang mengunci:
#                     perhatian & jadwal perawatan — zona terang mustahil
#                     dirambati tanpa memancing inspeksi.
#   III MENETAP       BABAK3_POHON pohon permanen berdiri. Yang mengunci:
#                     erosi & waktu — pohon hanya lahir di puing, puing
#                     hanya lahir dari fasad yang lama dirambati.
#
# Transisi satu arah; tidak ada mundur babak.
#
# Kalah = KEMATIAN TOTAL: tidak ada untai hidup DAN tidak ada pohon.
# Bukan timer kelaparan — dasar air/cahaya 1.0 (perbaikan anti-buntu lama)
# menjamin energi selalu pulih di siang hari, jadi selama masih ada yang
# hidup, selalu ada jalan kembali. Pohon ikut dihitung penyelamat karena
# klik kanan di dekatnya menumbuhkan untai baru.

var babak  = 1
var menang = false
var kalah  = false


func reset():
	babak = 1
	menang = false
	kalah = false


func update(_delta, sim, world):
	if menang or kalah:
		return

	if sim.alive_count() == 0 and sim.trees.is_empty():
		kalah = true
		return

	match babak:
		1:
			if sim.dekat_akuifer and world.tutupan() >= Config.BABAK1_PIJAK:
				babak = 2
		2:
			if min_zona(world) >= Config.ZONA_TARGET:
				babak = 3
		3:
			if sim.trees.size() >= int(Config.BABAK3_POHON):
				menang = true


# Kuadran yang paling tertinggal — inilah yang ditampilkan bar HUD di
# babak II: kemajuan diukur dari zona TERLEMAH, bukan rata-rata.
func min_zona(world):
	var terendah = 1.0
	for i in range(4):
		terendah = min(terendah, world.zona_tutupan(i))
	return terendah
