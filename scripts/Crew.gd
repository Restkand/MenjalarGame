extends RefCounted

# Regu perawatan gedung — TERJADWAL (TAHAP E), bekerja seperti tukang kebun
# sungguhan (dirombak setelah playtest 12 Agustus).
#
# Regu HANYA datang pada hari perawatan yang diumumkan kalender, masuk dari
# tepi layar, dan MEMOTONG SULUR DI PANGKALNYA: mereka mencari titik sulur
# yang melintas di pita jangkauan tanah pada paruh zona yang dijadwalkan,
# menggergajinya beberapa detik, dan seluruh rambatan di atas potongan itu
# lenyap. Zona bersih -> pulang.
#
# Regu TIDAK PERNAH menyentuh akar. Pengelola gedung tidak melihat bawah
# tanah — yang ia lihat rambatan di dinding (playtest: "kenapa dia sibuk
# merapikan bawah tanah padahal tanamannya menjalar di gedung?"). Risiko
# bawah tanah datang dari kanal lain: utilitas. Atas = terlihat, bawah =
# terasa.
#
# Counterplay pemain: pangkas sendiri sebelum hari-H (X), alihkan rambatan
# ke paruh zona lain, atau timbun regu dengan puing (CREW_PINGSAN).

var units    = []     # {x, s, i, kerja, pingsan, pulang}
var dipotong = 0      # potongan yang terjadi frame ini; dibaca lalu dinolkan
var ditimpa  = 0      # regu yang baru tertimbun frame ini


func reset():
	units = []
	dipotong = 0
	ditimpa = 0


func update(delta, sim, world, erosi, cycle):
	dipotong = 0
	ditimpa = 0

	# hanya siang di hari perawatan; selain itu tidak ada satu regu pun
	if cycle.phase != Config.PHASE_DAY or not cycle.rawat_hari_ini():
		units = []
		return

	# separuh dunia milik zona yang dijadwalkan (kuadran barat/timur)
	var barat = cycle.rawat_zona_idx % 2 == 0
	var x0 = 0.0 if barat else Config.W / 2.0
	var x1 = Config.W / 2.0 if barat else float(Config.W)

	_sesuaikan_jumlah(cycle, barat)

	var sisa = []
	for u in units:
		if u.pingsan > 0.0:
			u.pingsan = max(0.0, u.pingsan - delta)
			sisa.append(u)
			continue
		if _tertimpa(u, erosi):
			u.pingsan = Config.CREW_PINGSAN
			u.s = null
			u.kerja = 0.0
			ditimpa += 1
			sisa.append(u)
			continue
		if u.pulang:
			# berjalan ke tepi terdekat, lalu hilang — pekerjaan selesai
			u.x += (-1.0 if u.x < Config.W / 2.0 else 1.0) \
					* Config.CREW_SPEED * delta
			if u.x > 4.0 and u.x < Config.W - 4.0:
				sisa.append(u)
			continue
		_update_unit(u, delta, sim, world, x0, x1)
		sisa.append(u)
	units = sisa


# Puing yang jatuh melewati ketinggian badan menimbun regu di bawahnya.
func _tertimpa(u, erosi):
	if erosi.falling.is_empty():
		return false
	for p in erosi.falling:
		if p.y < Config.GROUND_Y - 20.0 or p.y > Config.GROUND_Y:
			continue
		if abs(p.x - u.x) <= Config.CREW_LEBAR:
			return true
	return false


# Yang tertimbun dan yang sedang pulang tidak dihitung — HUD harus
# menunjukkan ancaman yang nyata.
func aktif():
	var n = 0
	for u in units:
		if u.pingsan <= 0.0 and not u.pulang:
			n += 1
	return n


# Titik sasaran unit ini — dipakai AktorView untuk garis & arah hadap.
func titik_sasaran(u):
	if u.s == null or u.s.points.is_empty():
		return null
	return u.s.points[int(min(u.i, u.s.points.size() - 1))]


# Jumlah regu = seberapa cemas pengelola saat inspeksi. Masuk dari tepi
# layar di sisi zona — kedatangan mereka terlihat, bukan muncul dari udara.
func _sesuaikan_jumlah(cycle, barat):
	var n = 1 + int(clamp(cycle.rawat_kekuatan, 0.0, 1.0)
			* float(Config.CREW_MAX - 1))
	n = int(clamp(n, 1, Config.CREW_MAX))
	while units.size() < n:
		units.append({
			"x": 6.0 if barat else Config.W - 6.0,
			"s": null,
			"i": 0,
			"kerja": 0.0,
			"pingsan": 0.0,
			"pulang": false,
		})
	while units.size() > n:
		units.remove_at(units.size() - 1)


func _update_unit(u, delta, sim, world, x0, x1):
	if u.s != null and not _sah(u.s, u.i, x0, x1):
		u.s = null
	if u.s == null:
		var t = _cari_zona(sim, u.x, x0, x1)
		if t == null:
			# zona bersih — pulang. Tidak ada patroli.
			u.pulang = true
			return
		u.s = t.s
		u.i = t.i
		u.kerja = 0.0

	var sasar = u.s.points[u.i]
	var dx = sasar.x - u.x
	if abs(dx) > Config.CREW_JANGKAUAN:
		u.x = u.x + sign(dx) * Config.CREW_SPEED * delta
		u.kerja = 0.0
		return

	# menggergaji pangkal — beberapa detik, lalu SELURUH bagian di atas
	# potongan lenyap. Itulah kerja tukang kebun, dan itulah kenapa hari
	# perawatan pantas ditakuti walau sudah diumumkan dua hari sebelumnya.
	# Pangkal yang DIPERKUAT (G2) butuh dua kali durasi — jendela lebih lebar
	# untuk menimbun regu dengan puing atau merelakan dengan tenang.
	var durasi = Config.CREW_POTONG * (2.0 if u.s.kokoh else 1.0)
	u.kerja = u.kerja + delta
	if u.kerja < durasi:
		return
	u.kerja = 0.0
	# gergaji meninggalkan BANGKAI yang mengering (G3), bukan lenyap sekejap
	if sim.gergaji(u.s, u.i):
		dipotong += 1
	u.s = null


# Titik potong sah: milik sulur hidup, di paruh zona, dan di dalam pita
# jangkauan tanah (regu tidak memanjat — fasad tinggi urusan pemanjat).
func _sah(s, i, x0, x1):
	if not s.alive or s.is_root or i >= s.points.size():
		return false
	var p = s.points[i]
	return p.x >= x0 and p.x < x1 \
			and p.y >= Config.GROUND_Y - Config.CREW_BAND_ATAS \
			and p.y <= Config.GROUND_Y + 2.0


# Cari titik PALING PANGKAL (indeks terkecil) tiap sulur yang melintas di
# pita jangkauan pada paruh zona; ambil yang terdekat dengan posisi regu.
# Memotong di pangkal = kerusakan maksimal, persis prioritas tukang kebun.
func _cari_zona(sim, ux, x0, x1):
	var terbaik = null
	var jarak = 1e9
	for s in sim.strands:
		if not s.alive or s.is_root or s.points.size() < 8:
			continue
		var i = 2
		while i < s.points.size():
			if _sah(s, i, x0, x1):
				var d = abs(s.points[i].x - ux)
				if d < jarak:
					jarak = d
					terbaik = {"s": s, "i": i}
				break   # cukup titik pertama (paling pangkal) per sulur
			i += 4
	return terbaik
