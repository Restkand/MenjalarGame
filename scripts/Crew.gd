extends RefCounted

# Regu perawatan gedung — antagonis darat.
#
# Menggantikan sistem stealth lama sepenuhnya. Mereka tidak mengintai dan tidak
# "mencurigai" apa pun: begitu menemukan tanaman dalam jangkauan, mereka
# berjalan ke sana dan mencabutnya sepotong demi sepotong.
#
# Jangkauan mereka hanya pita di sekitar garis tanah — fasad bagian bawah dan
# tanah dangkal. Sulur yang sudah tinggi aman dari mereka; itu urusan pemanjat
# (Langkah C).
#
# Counterplay pemain ada tiga: tumbuh di bayangan (ditemukan belakangan),
# menyebar (satu regu hanya bisa di satu tempat), dan menumbuhkan ulang.

var units    = []     # {x, dir, sasaran, kerja, pingsan}
var dipotong = 0      # potongan yang terjadi frame ini; dibaca lalu dinolkan
var ditimpa  = 0      # regu yang baru tertimbun frame ini


func reset():
	units = []
	dipotong = 0
	ditimpa = 0


func update(delta, sim, world, structure, phase):
	dipotong = 0
	ditimpa = 0

	# Regu pulang saat malam. Itu yang memberi malam artinya: sulur merambat
	# tanpa gangguan, dan siang jadi soal mempertahankan hasilnya.
	if phase != Config.PHASE_DAY:
		units = []
		return

	_sesuaikan_jumlah(structure)
	for u in units:
		if u.pingsan > 0.0:
			u.pingsan = max(0.0, u.pingsan - delta)
			continue
		if _tertimpa(u, structure):
			u.pingsan = Config.CREW_PINGSAN
			u.sasaran = null
			u.kerja = 0.0
			ditimpa += 1
			continue
		_update_unit(u, delta, sim, world)


# Puing yang jatuh melewati ketinggian badan menimbun regu di bawahnya.
# Inilah jawaban pemain: waktukan keruntuhan saat mereka sedang berada di
# bawah reruntuhan.
func _tertimpa(u, structure):
	if structure.falling.is_empty():
		return false
	for p in structure.falling:
		if p.y < Config.GROUND_Y - 10.0 or p.y > Config.GROUND_Y:
			continue
		if abs(p.x - u.x) <= Config.CREW_LEBAR:
			return true
	return false


# Yang tertimbun tidak dihitung — HUD harus menunjukkan ancaman yang nyata.
func aktif():
	var n = 0
	for u in units:
		if u.pingsan <= 0.0:
			n += 1
	return n


# Tekanan naik seiring kerusakan, jadi justru saat pemain hampir menang
# situasinya paling genting. Itu memberi permainan busur, bukan garis datar.
func _sesuaikan_jumlah(structure):
	var n = 1 + int((1.0 - structure.integritas_total())
			* float(Config.CREW_MAX - 1))
	n = int(clamp(n, 1, Config.CREW_MAX))
	while units.size() < n:
		units.append({
			"x": randf_range(20.0, Config.W - 20.0),
			"dir": 1.0 if randf() < 0.5 else -1.0,
			"sasaran": null,
			"kerja": 0.0,
			"pingsan": 0.0,
		})
	while units.size() > n:
		units.remove_at(units.size() - 1)


func _update_unit(u, delta, sim, world):
	if u.sasaran != null and not _bisa_diraih(u.sasaran):
		u.sasaran = null
	if u.sasaran == null:
		u.sasaran = _cari(sim, world, u.x)
		u.kerja = 0.0

	if u.sasaran == null:
		_patroli(u, delta)
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
	u.sasaran.trim(Config.CREW_PANJANG)
	dipotong += 1
	if not u.sasaran.alive:
		u.sasaran = null


func _patroli(u, delta):
	u.x = u.x + u.dir * Config.CREW_SPEED * 0.5 * delta
	if u.x < 14.0:
		u.x = 14.0
		u.dir = 1.0
	elif u.x > Config.W - 14.0:
		u.x = Config.W - 14.0
		u.dir = -1.0


# Hanya pita di sekitar garis tanah. Sulur tinggi di luar jangkauan mereka.
func _bisa_diraih(s):
	if not s.alive or s.points.size() < 6:
		return false
	if s.is_root:
		return s.tip.y <= Config.GROUND_Y + Config.CREW_BAND_BAWAH
	return s.tip.y >= Config.GROUND_Y - Config.CREW_BAND_ATAS


func _cari(sim, world, ux):
	var terbaik = null
	var skor_terbaik = -1.0
	for s in sim.strands:
		if not _bisa_diraih(s):
			continue
		var d = abs(s.tip.x - ux)
		if d > Config.CREW_CARI:
			continue
		# Dekat = mudah ditemukan, terang = mencolok. vis bernilai 0 di bawah
		# tanah, jadi akar hanya ditemukan lewat kedekatan.
		var skor = (1.0 - d / Config.CREW_CARI) \
				+ world.vis_at(int(round(s.tip.x)), int(round(s.tip.y))) * 0.6
		if skor > skor_terbaik:
			skor_terbaik = skor
			terbaik = s
	return terbaik
