extends RefCounted

# Avatar — ujung tumbuh yang dikendalikan pemain (P1, docs/13 §3).
#
# Dua moda:
#   MERAMBAT — menempel di jaringan (WorldMap.jaringan): gerak bebas segala
#              arah selama sel tujuan masih dekat jaringan; energi PULIH.
#   LEPAS    — platformer: gravitasi grid sendiri (tanpa physics engine,
#              aturan lama), energi terkikis; menyentuh jaringan = menempel
#              lagi (dengan jeda singkat setelah melepaskan diri).
#
# Energi habis saat LEPAS = LAYU: bangun di simpul jaringan terakhir.
# Semua input datang dari main.gd lewat parameter update() — file ini tidak
# pernah membaca Input.

const MERAMBAT = 0
const LEPAS    = 1

var pos = Vector2()        # SATUAN simulasi; pos = titik KAKI
var vel = Vector2()
var moda = LEPAS
var energi = 0.0
var simpul = Vector2()     # titik bangun setelah layu
var simpul_dalam = false   # simpul berada di interior?
var di_tanah = false
var di_dalam = false       # P2: sedang di interior gedung
var layu_baru = false      # sekali-baca oleh main untuk pesan HUD
var _tempel_jeda = 0.0     # cooldown menempel setelah lepas


func mulai(p):
	pos = p
	vel = Vector2()
	moda = LEPAS
	energi = Config.AVATAR_ENERGI_MAX
	simpul = p
	simpul_dalam = false
	di_tanah = false
	di_dalam = false
	_tempel_jeda = 0.0


# arah: (-1..1 per sumbu); lompat & masuk: true hanya di frame tombol ditekan
func update(dt, arah, lompat, masuk, world):
	if dt <= 0.0:
		return
	_tempel_jeda = max(0.0, _tempel_jeda - dt)

	# E di jendela/pintu fasad: keluar-masuk gedung (P2). Transisi memutus
	# moda merambat — di sisi seberang Anda jatuh dulu ke lantai/jaringan.
	if masuk and world.di_gerbang_interior(int(round(pos.x)),
			int(round(pos.y - 2.0))):
		di_dalam = not di_dalam
		moda = LEPAS
		vel = Vector2()
		_tempel_jeda = Config.AVATAR_TEMPEL_JEDA
		return

	if moda == MERAMBAT:
		_rambat(dt, arah, lompat, world)
	else:
		_lepas(dt, arah, lompat, world)


# F: menanam simpul jaringan di posisi avatar (P2) — checkpoint + titik
# pulih di mana pun, termasuk interior. Mahal supaya jadi keputusan.
func jangkar(world):
	if energi < Config.JANGKAR_BIAYA + 5.0:
		return false
	energi -= Config.JANGKAR_BIAYA
	var px = int(round(pos.x))
	var py = int(round(pos.y - 2.0))
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			world.tandai_jaringan(px + dx, py + dy)
	simpul = pos
	simpul_dalam = di_dalam
	return true


func _rambat(dt, arah, lompat, world):
	energi = min(Config.AVATAR_ENERGI_MAX, energi + Config.AVATAR_REGEN * dt)
	simpul = pos
	simpul_dalam = di_dalam

	# melepaskan diri: lompatan kecil ke arah input
	if lompat:
		moda = LEPAS
		_tempel_jeda = Config.AVATAR_TEMPEL_JEDA
		vel = Vector2(arah.x * Config.AVATAR_JALAN,
				-Config.AVATAR_LOMPAT * 0.75)
		return

	if arah == Vector2.ZERO:
		return
	var langkah = arah.normalized() * Config.AVATAR_RAMBAT * dt
	# coba gerak penuh; kalau keluar jaringan, coba per sumbu (menyusur)
	for calon in [pos + langkah, pos + Vector2(langkah.x, 0.0),
			pos + Vector2(0.0, langkah.y)]:
		if world.jaringan_di(int(round(calon.x)), int(round(calon.y))):
			pos = calon
			return


func _lepas(dt, arah, lompat, world):
	energi -= Config.AVATAR_KURAS * dt

	# menempel kembali begitu menyentuh jaringan (setelah jeda lepas)
	if _tempel_jeda <= 0.0 \
			and world.jaringan_di(int(round(pos.x)), int(round(pos.y - 2.0))):
		moda = MERAMBAT
		vel = Vector2()
		simpul = pos
		return

	# horizontal: akselerasi menuju kecepatan target
	var target = arah.x * Config.AVATAR_JALAN
	vel.x = move_toward(vel.x, target, Config.AVATAR_ACCEL * dt)
	# vertikal: gravitasi + lompat dari tanah
	vel.y += Config.AVATAR_GRAV * dt
	if lompat and di_tanah and energi > Config.AVATAR_LOMPAT_BIAYA:
		vel.y = -Config.AVATAR_LOMPAT
		energi -= Config.AVATAR_LOMPAT_BIAYA

	_gerak_tabrak(dt, world)

	# layu: energi habis di luar jaringan — bangun di simpul terakhir
	# (termasuk kembali ke lapis tempat simpul itu ditanam)
	if energi <= 0.0:
		pos = simpul
		di_dalam = simpul_dalam
		vel = Vector2()
		energi = Config.AVATAR_LAYU_ENERGI
		moda = MERAMBAT if world.jaringan_di(int(round(pos.x)),
				int(round(pos.y - 2.0))) else LEPAS
		layu_baru = true


# Tabrakan kotak vs grid, sumbu terpisah — pola yang sama dengan puing/sulur:
# hitung sendiri, tanpa physics engine.
func _gerak_tabrak(dt, world):
	var hw = Config.AVATAR_SETENGAH_LEBAR
	var t = Config.AVATAR_TINGGI

	var bx = pos.x + vel.x * dt
	if not _tabrak(world, bx, pos.y, hw, t):
		pos.x = bx
	else:
		vel.x = 0.0

	var by = pos.y + vel.y * dt
	if not _tabrak(world, pos.x, by, hw, t):
		pos.y = by
	else:
		if vel.y > 0.0:
			# rapatkan kaki FLUSH ke atas sel padat (x.99): tanpa ini avatar
			# melayang 1 satuan lalu tenggelam pelan tiap frame, dan
			# di_tanah berkedip sehingga lompatan sering tertelan
			pos.y = floor(by)
			while _tabrak(world, pos.x, pos.y, hw, t):
				pos.y -= 1.0
			pos.y += 0.99
		vel.y = 0.0

	# di_tanah dari PROBE sel tepat di bawah kaki — stabil antar frame,
	# bukan efek samping tabrakan frame ini saja
	di_tanah = false
	var ky = int(floor(pos.y + 0.1))
	for cx in range(int(floor(pos.x - hw)), int(floor(pos.x + hw)) + 1):
		if world.padat_avatar(cx, ky, di_dalam):
			di_tanah = true
			break


# Ada sel padat di dalam kotak badan (kaki di (x, y))? Sadar lapis (P2):
# di interior yang padat adalah lantai/dinding, bukan tanah luar.
func _tabrak(world, x, y, hw, t):
	for cy in range(int(floor(y - t)), int(floor(y)) + 1):
		for cx in range(int(floor(x - hw)), int(floor(x + hw)) + 1):
			if world.padat_avatar(cx, cy, di_dalam):
				return true
	return false
