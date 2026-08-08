extends RefCounted

# Pemanjat — antagonis fasad atas.
#
# Regu darat hanya menjangkau pita di sekitar garis tanah, jadi seluruh fasad
# atas selama ini zona aman total. Pemanjat mengisinya, dan ia naik lewat SULUR
# PEMAIN SENDIRI: posisinya adalah indeks di dalam strand.points, bukan
# koordinat bebas. Jalur musuh adalah bangunan pemain.
#
# Dua imbalan yang lahir dari itu, tanpa perlu aturan tambahan:
#   - sulur yang dicabangkan tinggi punya pangkal di luar jangkauan tanah,
#     jadi jaringan terpisah memang lebih aman
#   - sulur yang tumbuh dari pohon di atas puing sama sekali bukan turunan
#     sulur utama, jadi ia jaringan baru
#
# Jawaban pemain: TreeSim.sever_at() memutus sulur, lalu jatuhkan() menjatuhkan
# pemanjat yang berada di atas titik potong.

var units    = []   # {s, idx, kerja, pingsan}
var dipotong = 0    # potongan frame ini; dibaca lalu dinolkan


func reset():
	units = []
	dipotong = 0


func update(delta, sim, structure, phase):
	dipotong = 0

	# Ikut pulang bersama regu darat saat malam.
	if phase != Config.PHASE_DAY:
		units = []
		return

	_bersihkan()
	_sesuaikan_jumlah(sim, structure)
	for c in units:
		_update_unit(c, delta)


# Posisi di layar: titik sulur yang sedang dipijak.
func pos(c):
	var n = c.s.points.size()
	if n == 0:
		return Vector2()
	return c.s.points[int(clamp(c.idx, 0, n - 1))]


func aktif():
	var n = 0
	for c in units:
		if c.pingsan <= 0.0:
			n += 1
	return n


# Dipanggil setelah pemain memutus sulur. Yang berada di atas titik potong
# kehilangan pijakan dan jatuh.
func jatuhkan(s, idx):
	var n = 0
	for c in units:
		if c.s == s and c.pingsan <= 0.0 and c.idx >= float(idx):
			c.pingsan = Config.CLIMB_PINGSAN
			c.idx = 0.0
			c.kerja = 0.0
			n += 1
	return n


func _bersihkan():
	var sisa = []
	for c in units:
		# sulur yang habis dibuang lebih dulu: tanpa ini pemanjat tersangkut
		# di untai kosong dan terus menjatuhkan dirinya sendiri
		if not c.s.alive or c.s.points.size() < 2:
			continue
		if c.pingsan > 0.0 or _bisa_dipanjat(c.s):
			sisa.append(c)
	units = sisa


func _sesuaikan_jumlah(sim, structure):
	# slider boleh diturunkan ke 0 untuk mematikan pemanjat saat menyetel
	if Config.CLIMB_MAX < 1:
		units = []
		return

	var n = 1 + int((1.0 - structure.integritas_total())
			* float(Config.CLIMB_MAX - 1))
	n = int(clamp(n, 1, Config.CLIMB_MAX))

	while units.size() > n:
		units.remove_at(units.size() - 1)
	if units.size() >= n:
		return

	var s = _cari_sulur(sim)
	if s == null:
		return
	units.append({"s": s, "idx": 0.0, "kerja": 0.0, "pingsan": 0.0})


func _cari_sulur(sim):
	for s in sim.strands:
		if not _bisa_dipanjat(s):
			continue
		var terpakai = false
		for c in units:
			if c.s == s:
				terpakai = true
				break
		if not terpakai:
			return s
	return null


func _bisa_dipanjat(s):
	if not s.alive or s.is_root:
		return false
	if s.points.size() < Config.CLIMB_MIN_TITIK:
		return false
	# pangkalnya harus bisa dicapai dari tanah
	if s.points[0].y < Config.CLIMB_BASIS:
		return false
	# ujung yang masih rendah biar diurus regu darat saja
	return s.tip.y < Config.GROUND_Y - Config.CREW_BAND_ATAS


func _update_unit(c, delta):
	if c.pingsan > 0.0:
		c.pingsan = max(0.0, c.pingsan - delta)
		return

	var akhir = float(c.s.points.size() - 1)

	# sulur diputus di bawahnya
	if c.idx > akhir:
		c.pingsan = Config.CLIMB_PINGSAN
		c.idx = 0.0
		c.kerja = 0.0
		return

	# masih memanjat
	if c.idx < akhir - 2.0:
		c.idx = min(akhir, c.idx + Config.CLIMB_SPEED * delta)
		c.kerja = 0.0
		return

	# sudah di ujung — mencabut, lalu ikut turun bersama sulur yang memendek
	c.kerja = c.kerja + delta
	if c.kerja < Config.CLIMB_CABUT:
		return
	c.kerja = 0.0
	c.s.trim(Config.CREW_PANJANG)
	dipotong += 1
	c.idx = min(c.idx, float(max(0, c.s.points.size() - 1)))
