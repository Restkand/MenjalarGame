extends RefCounted

# Regu perawatan gedung — TERJADWAL (TAHAP E, docs/06 §4.3).
#
# Mereka tidak lagi berpatroli tiap siang. Regu HANYA datang pada hari
# perawatan yang sudah diumumkan kalender berhari-hari sebelumnya, masuk
# dari tepi layar, membersihkan tanaman di ZONA yang dijadwalkan, lalu
# PULANG begitu zonanya bersih (atau saat malam tiba). Jumlahnya ditentukan
# seberapa tinggi perhatian saat inspeksi.
#
# Itulah seluruh janji stealth sistemik: pemain selalu tahu KAPAN dan DI
# MANA mereka akan bekerja, jadi tekanannya lahir dari perencanaan —
# memangkas sendiri sebelum hari-H, mengalihkan pertumbuhan, atau merelakan
# zona itu.
#
# Jangkauan mereka tetap pita di sekitar garis tanah; zona ATAS urusan
# pemanjat. Counterplay menimbun dengan puing (CREW_PINGSAN) tetap hidup.

var units    = []     # {x, sasaran, kerja, pingsan, pulang}
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
			u.sasaran = null
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
# Inilah jawaban pemain: waktukan gugurnya fasad saat mereka berada di
# bawah reruntuhan.
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


# Jumlah regu = seberapa cemas pengelola saat inspeksi. Masuk dari tepi
# layar di sisi zona — kedatangan mereka terlihat, bukan muncul dari udara.
func _sesuaikan_jumlah(cycle, barat):
	var n = 1 + int(clamp(cycle.rawat_kekuatan, 0.0, 1.0)
			* float(Config.CREW_MAX - 1))
	n = int(clamp(n, 1, Config.CREW_MAX))
	while units.size() < n:
		units.append({
			"x": 6.0 if barat else Config.W - 6.0,
			"sasaran": null,
			"kerja": 0.0,
			"pingsan": 0.0,
			"pulang": false,
		})
	while units.size() > n:
		units.remove_at(units.size() - 1)


func _update_unit(u, delta, sim, world, x0, x1):
	if u.sasaran != null and not _sah(u.sasaran, x0, x1):
		u.sasaran = null
	if u.sasaran == null:
		u.sasaran = _cari_zona(sim, u.x, x0, x1)
		u.kerja = 0.0

	# zona bersih — pulang. Tidak ada patroli: regu yang berkeliaran tanpa
	# tujuan adalah sistem lama yang membuat game terasa arcade.
	if u.sasaran == null:
		u.pulang = true
		return

	var dx = u.sasaran.tip.x - u.x
	if abs(dx) > Config.CREW_JANGKAUAN:
		u.x = u.x + sign(dx) * Config.CREW_SPEED * delta
		u.kerja = 0.0
		return

	u.kerja = u.kerja + delta
	if u.kerja < Config.CREW_CABUT:
		return
	u.kerja = 0.0
	u.sasaran.trim(Config.CREW_PANJANG, world)
	dipotong += 1
	if not u.sasaran.alive:
		u.sasaran = null


# Hanya pita di sekitar garis tanah. Sulur tinggi di luar jangkauan mereka.
func _bisa_diraih(s):
	if not s.alive or s.points.size() < 6:
		return false
	if s.is_root:
		return s.tip.y <= Config.GROUND_Y + Config.CREW_BAND_BAWAH
	return s.tip.y >= Config.GROUND_Y - Config.CREW_BAND_ATAS


func _sah(s, x0, x1):
	return _bisa_diraih(s) and s.tip.x >= x0 and s.tip.x < x1


# Sasaran terdekat di dalam zona. Tanpa batas jarak — mereka DIPANGGIL ke
# zona ini, jadi mereka berjalan sejauh apa pun di dalamnya.
func _cari_zona(sim, ux, x0, x1):
	var terbaik = null
	var jarak = 1e9
	for s in sim.strands:
		if not _sah(s, x0, x1):
			continue
		var d = abs(s.tip.x - ux)
		if d < jarak:
			jarak = d
			terbaik = s
	return terbaik
