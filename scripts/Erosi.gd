extends RefCounted

# Erosi — pembongkaran turun pangkat jadi KOSMETIK (TAHAP B, docs/06 §5).
#
# Menggantikan Structure.gd. Yang dibuang: rangka member/joint, aliran
# beban, keruntuhan berantai per gelombang, panel, pelemahan oleh tanaman,
# dan kondisi menang lewat kerusakan. Yang bertahan utuh: puing jatuh
# (falling sand), debu, bake-ulang peta cahaya setelah tumpukan diam, dan
# rantai puing -> T_PUING -> pohon.
#
# Cara kerjanya: WorldMap.rambati() melaporkan sel fasad yang baru tertutup
# sulur, dikelompokkan per petak EROSI_PETAK x EROSI_PETAK. Tiap petak yang
# tersentuh melapuk dengan laju sebanding luas tutupannya; begitu penuh,
# petak itu gugur — sel gedungnya dilubangi, puing lahir dan jatuh. Sulur
# di atasnya TIDAK kehilangan pijakan: bekas rambatan (world.tutup) adalah
# pijakan kekal.
#
# Penjaga desain: erosi tidak boleh jadi jalan menang, dan tidak boleh
# menghukum pemain karena berhasil menutup fasad.

var world
var falling = []   # puing melayang — dibaca PuingView dan Crew (menimbun)
var dust    = []

var _petak = {}          # Vector2i petak-erosi -> {n: sel tertutup, lapuk}
var _perlu_bake = false  # ada puing baru mengendap / fasad gugur
var _tenang     = 0.0


func setup(w):
	world = w
	falling = []
	dust = []
	_petak = {}
	_perlu_bake = false
	_tenang = 0.0


func update(delta):
	_debris_step(delta)
	_dust_step(delta)
	_bake_step(delta)
	_lapuk_step(delta)


# ---------------------------------------------------------------------------
# Lapuk
# ---------------------------------------------------------------------------

func _lapuk_step(delta):
	# sel fasad yang baru dirambati menambah bahan bakar petaknya
	for id in world.ambil_rambatan_baru():
		if not _petak.has(id):
			_petak[id] = {"n": 0, "lapuk": 0.0}
		_petak[id].n += 1

	if _petak.is_empty():
		return

	# petak melapuk sebanding luas tutupannya: satu-dua sel tersentuh baru
	# menggerogoti pelan; petak yang benar-benar terselimuti melapuk penuh
	var gugur = []
	for id in _petak:
		var p = _petak[id]
		var bobot = clamp(p.n / 12.0, 0.15, 1.0)
		p.lapuk += Config.LAPUK_LAJU * bobot * delta
		if p.lapuk >= 1.0:
			gugur.append(id)

	for id in gugur:
		_gugurkan(id)
		_petak.erase(id)


func _gugurkan(id):
	var x0 = id.x * Config.EROSI_PETAK
	var y0 = id.y * Config.EROSI_PETAK
	if not world.carve_kotak(x0, y0, Config.EROSI_PETAK):
		return   # sudah tidak ada gedung di situ (mis. sudah gugur duluan)

	# siluet berubah — bayangan di bawah petak ini ikut berubah
	world.rebake_dari(y0)

	var tengah = float(Config.EROSI_PETAK) * 0.5
	for _k in range(Config.EROSI_PUING):
		if falling.size() >= Config.PUING_MAX:
			break
		falling.append({
			"x": x0 + tengah + randf_range(-tengah, tengah),
			"y": y0 + tengah,
			"vx": randf_range(-5.0, 5.0),
			"vy": randf_range(-2.0, 4.0),
		})
	for _k in range(Config.EROSI_DEBU):
		if dust.size() >= Config.DEBU_MAX_TOTAL:
			break
		dust.append({
			"x": x0 + randf() * Config.EROSI_PETAK,
			"y": y0 + randf() * Config.EROSI_PETAK,
			"vx": randf_range(-4.0, 4.0),
			"vy": -randf_range(2.0, Config.DEBU_NAIK),
			"age": 0.0,
		})


# ---------------------------------------------------------------------------
# Puing, debu, dan bake — dibawa utuh dari Structure.gd
# ---------------------------------------------------------------------------

# Peta cahaya dipanggang ulang SEKALI setelah semuanya diam. Tumpukan puing
# (dan fasad yang gugur) mengubah siluet, jadi bayangannya ikut berubah —
# tapi memanggang ulang tiap butir mendarat membuat semuanya tersendat.
func _bake_step(delta):
	if not _perlu_bake:
		return
	if not falling.is_empty():
		_tenang = 0.0
		return
	_tenang = _tenang + delta
	if _tenang < Config.PUING_TENANG:
		return
	_perlu_bake = false
	_tenang = 0.0
	world.rebake_dari(world.puing_atas - 4)


func _dust_step(delta):
	if dust.is_empty():
		return
	var sisa = []
	for d in dust:
		d.age = d.age + delta
		if d.age >= Config.DEBU_UMUR:
			continue
		d.x = d.x + d.vx * delta
		d.y = d.y + d.vy * delta
		d.vx = d.vx * 0.96   # melambat, lalu menggantung
		d.vy = d.vy * 0.97
		sisa.append(d)
	dust = sisa


func _debris_step(delta):
	if falling.is_empty():
		return

	var sisa = []
	var mengendap = []

	for p in falling:
		p.vy = p.vy + Config.PUING_GRAVITASI * delta
		p.x = p.x + p.vx * delta
		p.y = p.y + p.vy * delta

		var ix = int(round(p.x))
		var iy = int(round(p.y))
		if ix < 1 or ix > Config.W - 2 or iy > Config.H - 2:
			continue   # keluar layar, dibuang

		# kalau melesat masuk ke dalam tumpukan, dorong balik ke permukaan
		var guard = 0
		while iy > 1 and world.blocked(ix, iy) and guard < 4:
			iy -= 1
			guard += 1
		p.y = float(iy)

		if not world.blocked(ix, iy + 1):
			sisa.append(p)
			continue

		# falling sand — kalau tepat di bawah terhalang, coba serong dulu
		# supaya tumpukan melandai, bukan jadi menara
		if not world.blocked(ix - 1, iy + 1):
			p.x = p.x - 1.0
			p.vy = p.vy * 0.4
			sisa.append(p)
		elif not world.blocked(ix + 1, iy + 1):
			p.x = p.x + 1.0
			p.vy = p.vy * 0.4
			sisa.append(p)
		else:
			mengendap.append(Vector2(ix, iy))

	falling = sisa
	if not mengendap.is_empty():
		world.settle_many(mengendap)
		_perlu_bake = true
		_tenang = 0.0
