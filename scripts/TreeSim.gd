extends RefCounted

const Strand = preload("res://scripts/Strand.gd")

var strands  = []
var trees    = []     # {x, y, tinggi} — permanen, tidak bisa dicabut regu
var bangkai  = []     # potongan gergaji regu yang sedang mengering (G3)
var selected = null
var time     = 0.0
var energy   = 0.0
var water    = 0.0
var light    = 0.0
var starved  = false
var dekat_akuifer = false   # ada akar di akuifer frame ini — gerbang babak I
var _next_id = 0
var _world   = null


func reset():
	strands = []
	trees = []
	bangkai = []
	_next_id = 0
	time = 0.0
	energy = Config.ENERGY_START
	water = 0.0
	light = 0.0
	starved = false
	var root = _make(Config.SEED_X, Config.GROUND_Y + 1, PI / 2, true, 0)
	var vine = _make(Config.SEED_X, Config.FACADE_Y1 - 2, -PI / 2, false, 0)
	strands.append(root)
	strands.append(vine)
	selected = root


func _make(x, y, a, is_root, gen):
	_next_id += 1
	return Strand.new(x, y, a, is_root, gen, _next_id)


# mengembalikan total nilai keterlihatan pertumbuhan frame ini
func update(delta, steering, mouse, world, phase, kering = false):
	# Disimpan supaya select_near() dan ensure_selection() bisa memeriksa
	# apakah sebuah untai berdiri di atas puing, tanpa harus mengubah
	# tanda tangan mereka di Cycle dan main.
	_world = world
	time += delta
	_bangkai_step(delta, world)
	water = _water(world, delta, kering)
	light = _light(world)

	# Fotosintesis hanya terjadi siang hari
	if phase == Config.PHASE_DAY:
		energy = min(Config.ENERGY_MAX,
				energy + min(water, light) * Config.ENERGY_RATE * delta)

	# Yang sefase tumbuh penuh. Yang berdiri di atas puing tetap menjalar
	# walau di luar fasenya, tapi lebih pelan — puing itu tanah subur, dan
	# itu yang membuat dunia selalu terlihat menghijau sendiri.
	var growing = []
	var bobot = 0.0
	for s in strands:
		if not s.alive:
			continue

		# akar yang sedang menembus beton berhenti tumbuh dan membayar
		# tarifnya sendiri (TAHAP C)
		if s.is_root and s.tembus >= 0.0:
			if _sefase(s, phase):
				_tembus_step(s, world, delta)
			continue

		var laju = 0.0
		if _sefase(s, phase):
			laju = 1.0
		elif s.on_puing(world):
			laju = Config.PUING_LAMBAT
		if laju <= 0.0:
			continue

		# terrain bawah tanah memengaruhi laju akar: humus menyuburkan,
		# gorong-gorong adalah jalan bebas hambatan
		if s.is_root:
			var k = world.at(int(round(s.tip.x)), int(round(s.tip.y)))
			if k == Config.T_HUMUS:
				laju *= Config.HUMUS_LAJU
			elif k == Config.T_GORONG:
				laju *= Config.GORONG_LAJU

		growing.append({"s": s, "laju": laju})
		bobot += laju

	# Biaya ditimbang laju, jadi pertumbuhan pelan di puing juga lebih murah.
	var cost = pow(max(1.0, bobot), Config.COST_TIP_EXP) \
			* 9.0 * Config.COST_PER_PIXEL * delta
	if energy < cost:
		energy = 0.0
		starved = true
		return 0.0
	energy -= cost
	starved = false

	# Seberapa mencolok pertumbuhan malam ini, dari peta vis. Belum ada yang
	# memakainya sejak sistem stealth dihapus, tapi ini persis sinyal yang
	# dibutuhkan regu perawatan nanti: seberapa cepat mereka menemukannya.
	var seen = 0.0
	for g in growing:
		var s = g.s
		var steer = null
		if steering and s == selected:
			if s.tip.distance_to(mouse) > Config.DEAD_ZONE:
				steer = atan2(mouse.y - s.tip.y, mouse.x - s.tip.x)
		seen += s.grow(delta, steer, time, world, g.laju)
		s.age_leaves(delta)
		_berakar(s, world, delta)
		# akar yang menyentuh utilitas mengganggu layanan gedung — masuk ke
		# kanal `terlihat` yang sama dengan pertumbuhan mencolok (TAHAP C)
		if s.is_root and world.at(int(round(s.tip.x)),
				int(round(s.tip.y))) == Config.T_UTILITAS:
			seen += Config.UTILITAS_SEEN * delta

	for t in trees:
		t.tinggi = min(float(Config.POHON_TINGGI),
				t.tinggi + Config.POHON_TUMBUH * delta)
	return seen


# Sulur yang bertahan di atas puing perlahan berakar. Begitu penuh, sebatang
# pohon ditanam di titik itu dan hitungannya diulang — jadi sulur yang merayap
# menyeberangi tumpukan meninggalkan barisan pohon di belakangnya.
func _berakar(s, world, delta):
	if s.is_root or not s.on_puing(world):
		return
	s.berakar += Config.POHON_LAJU * delta
	if s.berakar < 1.0:
		return
	s.berakar = 0.0
	_tanam(s.tip)


func _tanam(p):
	if trees.size() >= Config.POHON_MAX:
		return
	for t in trees:
		if Vector2(t.x, t.y).distance_to(p) < Config.POHON_JARAK:
			return
	trees.append({"x": p.x, "y": p.y, "tinggi": 1.0})


func _sefase(s, phase):
	if phase == Config.PHASE_DAY:
		return s.is_root
	return not s.is_root


# Menembus beton: ujung diam, energi terkuras dengan tarif COST_CRACK /
# CRACK_DURATION. Energi habis = kemajuan MEMBEKU (bukan hilang) — persis
# rancangan docs/02 §7. Selesai = terowongan terbuka, akar bebas lanjut.
func _tembus_step(s, world, delta):
	var biaya = Config.COST_CRACK / Config.CRACK_DURATION * delta
	if energy < biaya:
		return   # beku, menunggu energi
	energy -= biaya
	s.tembus += delta / Config.CRACK_DURATION
	if s.tembus < 1.0:
		return
	world.tembus_beton(s.tip, s.angle)
	s.tembus = -1.0


func _water(world, delta, kering):
	# Pohon berakar dalam dan berdaun lebar, jadi ia menyumbang ke KEDUA sisi
	# min(Air, Cahaya). Itulah yang melepas cekikan ekonomi dan membebaskan
	# akar dari tugas ganda.
	dekat_akuifer = false
	var w = 1.0 + trees.size() * Config.POHON_HASIL
	for s in strands:
		if not s.alive or not s.is_root:
			continue
		# akuifer adalah hadiah di balik beton — sumber air terbesar, TAPI
		# menyedotnya menurunkan permukaan (G4): akar harus mengejar air
		# yang surut, dan kolam yang diperas ramai-ramai cepat habis
		var near_akuifer = false
		for dy in range(-4, 5):
			for dx in range(-4, 5):
				if world.at(int(round(s.tip.x)) + dx,
						int(round(s.tip.y)) + dy) == Config.T_AKUIFER:
					near_akuifer = true
		if near_akuifer:
			w += 4.0
			dekat_akuifer = true
			world.sedot_di(s.tip, Config.AKUIFER_SEDOT * delta)
		elif world.at(int(round(s.tip.x)),
				int(round(s.tip.y))) == Config.T_SOIL_WET:
			# musim kering (G4): tanah lembap tidak memberi apa-apa —
			# hanya akuifer yang bertahan
			w += 0.25 if kering else 2.0
		else:
			w += 0.25
	return w

func _light(world):
	var l = 1.0 + trees.size() * Config.POHON_HASIL
	for s in strands:
		if s.is_root:
			continue
		for lf in s.leaves:
			l += world.light_at(int(round(lf.pos.x)),
					int(round(lf.pos.y))) * 0.4
	return l

func bottleneck():
	if water < light:
		return "AIR"
	elif light < water:
		return "CAHAYA"
	return ""


# render() dihapus di R6 — seluruh penggambaran kini milik lapis view
# (SulurView, DaunView, PohonView, AktorView, UjungView, RisikoView).

# Yang sefase selalu bisa dipilih. Yang menjalar sendiri di atas puing juga —
# kalau tidak, pemain menonton sesuatu tumbuh tanpa bisa menyentuhnya.
func _bisa_dipilih(s, phase):
	if not s.alive:
		return false
	if _sefase(s, phase):
		return true
	return _world != null and s.on_puing(_world)


func select_near(m, phase):
	var best = Config.PILIH_RADIUS
	var found = null
	for s in strands:
		if not _bisa_dipilih(s, phase):
			continue
		var d = s.tip.distance_to(m)
		if d < best:
			best = d
			found = s
	if found != null:
		selected = found
		return true
	return false


func ensure_selection(phase):
	if selected != null and _bisa_dipilih(selected, phase):
		return
	for s in strands:
		if _bisa_dipilih(s, phase):
			selected = s
			return


# Bercabang dari pohon, bukan dari ujung terpilih. Pohon adalah titik awal
# baru: jaringan yang terpisah dari sulur utama, dan itu yang nanti membuat
# pemanjat punya lawan — satu jalur besar bisa diputus, jaringan terpisah
# tidak. Dicoba lebih dulu daripada branch() biasa.
func branch_at(p):
	for t in trees:
		if Vector2(t.x, t.y).distance_to(p) > Config.POHON_JARAK:
			continue
		if strands.size() >= Config.MAX_STRANDS or energy < Config.COST_BRANCH:
			return false
		energy -= Config.COST_BRANCH
		var ns = _make(t.x, t.y - t.tinggi * 0.6, -PI / 2.0, false, 0)
		strands.append(ns)
		selected = ns
		return true
	return false


func branch():
	if selected == null or not selected.alive:
		return false
	if strands.size() >= Config.MAX_STRANDS or energy < Config.COST_BRANCH:
		return false
	energy -= Config.COST_BRANCH
	var side = 1.0 if randf() < 0.5 else -1.0
	var off = deg_to_rad(randf_range(25, 40)) * side
	strands.append(_make(selected.tip.x, selected.tip.y,
			selected.angle + off, selected.is_root, selected.generation + 1))
	return true


# TUNAS ULANG (G2): untai sulur baru dari bekas rambatan (peta tutup).
# Inilah yang menghidupkan kembali wilayah yang digergaji regu tanpa harus
# merayap ulang dari tanah — dan alasan hukuman potongan-pangkal tetap adil.
func tunas_di(p, world):
	if world == null or not world.ada_rambatan(p):
		return false
	if strands.size() >= Config.MAX_STRANDS or energy < Config.COST_TUNAS:
		return false
	energy -= Config.COST_TUNAS
	var ns = _make(p.x, p.y, -PI / 2.0, false, 0)
	strands.append(ns)
	selected = ns
	return true


# GERGAJI REGU (G3): seperti pangkas(), tapi bagian atas TIDAK lenyap —
# ia jadi bangkai kering yang menyusut dari ujung selama BANGKAI_UMUR,
# dan jejak rambatannya terkikis mengikuti penyusutan itu. Selama bekasnya
# masih ada, tunas ulang (G2) bisa menyambungnya.
func gergaji(s, i):
	i = max(i, 2)
	if i >= s.points.size() - 1:
		return false

	var pts = []
	for j in range(i + 1, s.points.size()):
		pts.append(s.points[j])
	bangkai.append({
		"pts": pts,
		"laju": float(pts.size()) / max(1.0, Config.BANGKAI_UMUR),
		"acc": 0.0,
	})

	s.points.resize(i + 1)
	s.tip = Vector2(s.points[i].x, s.points[i].y)
	s.angle = s.angle + PI
	# daunnya rontok seketika — yang tinggal batang kering
	var keep = []
	for l in s.leaves:
		if l.pos.distance_to(s.tip) < 80.0:
			keep.append(l)
	s.leaves = keep
	return true


# Bangkai menyusut dari ujung; tiap titik yang lenyap membawa jejak
# rambatannya. Bar HIJAU/zona mundur BERTAHAP — pemain melihat prosesnya.
func _bangkai_step(delta, world):
	if bangkai.is_empty():
		return
	var sisa = []
	for b in bangkai:
		b.acc += b.laju * delta
		var k = int(b.acc)
		b.acc -= k
		while k > 0 and not b.pts.is_empty():
			var p = b.pts.pop_back()
			world.hapus_rambatan(int(round(p.x)), int(round(p.y)))
			k -= 1
		if not b.pts.is_empty():
			sisa.append(b)
	bangkai = sisa


# PERKUAT PANGKAL (G2): sulur terpilih menebal, gergaji regu butuh dua kali
# durasi. Sekali dan permanen untuk untai itu.
func perkuat():
	if selected == null or not selected.alive or selected.is_root \
			or selected.kokoh:
		return false
	if energy < Config.COST_KOKOH:
		return false
	energy -= Config.COST_KOKOH
	selected.kokoh = true
	return true


func spend(amount):
	if amount <= 0.0:
		return
	energy = max(0.0, energy - amount)


# retreat_unsupported() dihapus di TAHAP B: satu-satunya yang melenyapkan
# fasad sekarang adalah erosi, dan bekas rambatan (world.tutup) adalah
# pijakan kekal — sulur tidak pernah kehilangan tempat berdiri.


# Memutus sulur di titik terdekat kursor. Seluruh bagian di atas potongan
# hilang — itu harganya, dan itu yang membuat menjatuhkan pemanjat jadi
# keputusan, bukan tombol gratis.
#
# Mengembalikan {s, i} supaya pemanggil bisa menjatuhkan pemanjat yang berada
# di atas titik itu, atau null kalau tidak ada sulur di dekat kursor.
func sever_at(p):
	var best = Config.PUTUS_RADIUS
	var found = null
	var found_i = -1
	for s in strands:
		if not s.alive or s.is_root or s.points.size() < 8:
			continue
		# melangkah 2 titik: titik berjarak 1 px, jadi ini masih jauh lebih
		# teliti daripada radius pencarian 8 px, dan setengah lebih murah
		var i = 0
		while i < s.points.size():
			var d = s.points[i].distance_to(p)
			if d < best:
				best = d
				found = s
				found_i = i
			i += 2

	if found == null or found_i < 2:
		return null

	pangkas(found, found_i)
	return {"s": found, "i": found_i}


# Memotong untai pada indeks titik i: seluruh bagian di atasnya hilang,
# jejak rambatannya terhapus (bar HIJAU/zona mundur), daun-daunnya rontok.
# Dipakai sever_at (tombol X pemain) dan regu perawatan (potong di pangkal).
func pangkas(s, i, world = null):
	if world == null:
		world = _world
	i = max(i, 2)   # sisakan tunggul — untai tetap hidup dan bisa tumbuh lagi
	if i >= s.points.size() - 1:
		return false

	if world != null:
		for j in range(i + 1, s.points.size()):
			world.hapus_rambatan(int(round(s.points[j].x)),
					int(round(s.points[j].y)))

	s.points.resize(i + 1)
	s.tip = Vector2(s.points[i].x, s.points[i].y)
	s.angle = s.angle + PI
	var keep = []
	for l in s.leaves:
		if l.pos.distance_to(s.tip) < 80.0:
			keep.append(l)
	s.leaves = keep
	return true


func alive_count():
	var n = 0
	for s in strands:
		if s.alive:
			n += 1
	return n
