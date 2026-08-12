extends RefCounted

# Kalender & perhatian — jantung stealth sistemik (TAHAP D, docs/06 §4).
#
# File ini dua kali berganti peran: lahir sebagai Warden.gd (stealth lama:
# kerucut pandang, panas per-sulur — semua dihapus), menyusut jadi jam
# siang-malam, dan sekarang naik pangkat jadi KALENDER. Satu hari = satu
# siang + satu malam.
#
# Seluruh sistem stealth-nya ada di sini dan bisa dibaca pemain di HUD:
#
#   tiap INSPEKSI_TIAP hari  ->  INSPEKSI saat fajar
#       perhatian >= AMBANG_RAWAT  ->  PERAWATAN dijadwalkan JEDA_RAWAT hari
#       ke depan, sasarannya zona dengan rambatan paling mencolok
#
# Ancaman selalu diumumkan sebelum tiba (pilar 2, docs/06 §1). Ketegangan
# lahir dari perencanaan — pemain punya jendela waktu untuk mengalihkan
# pertumbuhan ke bayangan atau merelakan satu zona — bukan dari kaget.
#
# `perhatian` adalah SATU angka untuk seluruh gedung. Bukan panas per-sulur;
# itu dilarang hidup lagi (CLAUDE.md) karena menuntut pengawasan yang
# mustahil dengan perhatian pemain terbagi dua pane.

var phase = Config.PHASE_DAY
var t     = 0.0
var hari  = 1

var perhatian = 0.0

var rawat_hari     = -1    # hari kedatangan perawatan; -1 = tidak ada jadwal
var rawat_zona     = ""
var rawat_zona_idx = -1    # indeks Config.ZONA_NAMA; 0-1 = zona ATAS
var rawat_kekuatan = 0.0   # perhatian saat inspeksi — menentukan jumlah regu

# Musim kering (G4): diumumkan dua hari sebelumnya, seperti semua ancaman.
var kering_hari  = -1      # hari mulai; -1 = tidak ada jadwal
var kering_akhir = -1      # hari pertama SETELAH musim kering berakhir

# Eskalasi (G6): tingkat kewaspadaan kota, naik tiap ESKALASI_TIAP hari.
var eskalasi = 0
var eskalasi_baru = false  # di-set saat naik; dibaca-kosongkan main (kartu)


func reset():
	phase = Config.PHASE_DAY
	t = 0.0
	hari = 1
	perhatian = 0.0
	rawat_hari = -1
	rawat_zona = ""
	rawat_zona_idx = -1
	rawat_kekuatan = 0.0
	kering_hari = -1
	kering_akhir = -1
	eskalasi = 0
	eskalasi_baru = false


# Ambang inspeksi turun seiring eskalasi — kota yang waspada menoleransi
# lebih sedikit hijau sebelum memanggil regu.
func ambang_efektif():
	return max(0.25, Config.AMBANG_RAWAT - eskalasi * 0.06)


# Regu yang berpengalaman menggergaji lebih cepat.
func faktor_gergaji():
	return max(0.6, 1.0 - eskalasi * 0.08)


func rawat_hari_ini():
	return rawat_hari == hari


func musim_kering():
	return kering_hari >= 0 and hari >= kering_hari and hari < kering_akhir


func phase_len():
	return Config.DAY_LEN if phase == Config.PHASE_DAY else Config.NIGHT_LEN


func progress():
	return t / phase_len()


# 0 saat siang bolong, 1 saat malam penuh. Dipakai untuk menggelapkan layar.
func night_amount():
	if phase == Config.PHASE_NIGHT:
		return min(1.0, t / 2.5)
	return max(0.0, 1.0 - t / 2.5)


# Berapa hari lagi sampai inspeksi berikutnya. 0 = hari ini hari inspeksi.
func inspeksi_dalam():
	var tiap = max(1, int(Config.INSPEKSI_TIAP))
	return (tiap - (hari % tiap)) % tiap


func update(delta, sim, world, terlihat):
	# --- perhatian -----------------------------------------------------------
	# pertumbuhan di area terlihat — sinyal `terlihat` dari TreeSim adalah
	# jumlah nilai vis di tiap titik yang tumbuh frame ini
	perhatian += terlihat * Config.PERHATIAN_TUMBUH
	# keluhan yang berjalan terus: jendela tertutup dan pintu terambati
	perhatian += (world.rasio_jendela_tertutup() * Config.PERHATIAN_JENDELA
			+ world.rasio_pintu_tertutup() * Config.PERHATIAN_PINTU) * delta
	perhatian = clamp(perhatian - Config.PERHATIAN_LURUH * delta, 0.0, 1.0)

	# --- jam -----------------------------------------------------------------
	t += delta
	if t < phase_len():
		return
	t = 0.0
	if phase == Config.PHASE_DAY:
		phase = Config.PHASE_NIGHT
	else:
		phase = Config.PHASE_DAY
		_fajar(world)
	sim.ensure_selection(phase)


func _fajar(world):
	hari += 1

	# Hari perawatan sudah lewat: pengelola menganggap masalahnya tertangani.
	# Perhatian dan bobot zona turun separuh — kalau pemain terus mencolok,
	# keduanya akan naik lagi dan siklusnya berulang.
	if rawat_hari >= 0 and hari > rawat_hari:
		rawat_hari = -1
		rawat_zona = ""
		rawat_zona_idx = -1
		perhatian *= Config.PERHATIAN_SETELAH_RAWAT
		for i in range(4):
			world.zona_bobot[i] *= 0.5

	# musim kering yang usai dibersihkan; yang baru dijadwalkan tiap
	# KERING_SIKLUS hari, diumumkan dua hari sebelumnya (kartu & kalender)
	if kering_akhir >= 0 and hari >= kering_akhir:
		kering_hari = -1
		kering_akhir = -1
	if kering_hari < 0 and hari > 2 \
			and hari % max(3, int(Config.KERING_SIKLUS)) == 0:
		kering_hari = hari + 2
		kering_akhir = kering_hari + max(1, int(Config.KERING_LAMA))

	# kota makin waspada (G6) — kenaikan ditandai untuk diumumkan kartu
	if hari > 2 and hari % max(2, int(Config.ESKALASI_TIAP)) == 0 \
			and eskalasi < int(Config.ESKALASI_MAX):
		eskalasi += 1
		eskalasi_baru = true

	if inspeksi_dalam() == 0:
		_inspeksi(world)


func _inspeksi(world):
	if rawat_hari >= 0:
		return   # sudah ada jadwal berjalan
	if perhatian < ambang_efektif():
		return   # gedung dianggap masih wajar
	rawat_hari = hari + max(1, int(Config.JEDA_RAWAT))
	rawat_zona_idx = world.zona_teratas_idx()
	rawat_zona = Config.ZONA_NAMA[rawat_zona_idx]
	rawat_kekuatan = perhatian
