extends Node2D

# Tampilan TENDRIL (ADR §18: Godot AvatarView = prioritas setelah master
# LOCKED). Lima animasi kanon dari aset/konsep_tendril/: idle, merambat,
# lepas, detach, attach — 48 px per frame, palet kanon CDD §7.
#
# Aturan state (CDD §15-16): pergantian moda MEMUTAR transisi sekali —
# detach 0.28 dtk (target 0.15-0.30), attach 0.20 dtk (target 0.10-0.25) —
# lalu jatuh ke loop moda. Idle dipakai saat nyaris diam di moda mana pun:
# organisme harus terlihat hidup justru ketika pemain tidak berbuat apa-apa
# (CDD Rule 8). Kecepatan main 8-12 fps sesuai catatan papan pemilik proyek.

# Set prototype spec gerak §26: idle, gerak kanan & kiri (digenerate
# TERPISAH — bukan cermin, §8), belok dua arah (§21), merambat, transisi.
# "lepas" lama tinggal sebagai cadangan.
const ANIM = ["idle", "merambat", "kanan", "kiri", "putar_kiri",
		"putar_kanan", "lompat", "jatuh", "darat", "lepas", "detach",
		"attach"]

var avatar
var _t = 0.0
var _anim = {}            # nama -> {tex, n}
var _state = "idle"
var _transisi_t = 0.0     # sisa waktu memutar detach/attach
var _transisi = ""
var _moda_lalu = -1
var _pos_lalu = Vector2()
var _jarak = 0.0          # jarak tempuh — penggerak frame lokomotasi
var _miring = 0.0         # condongan ujung ke arah gerak (CDD §5.1/SPP §56)
var _hadap_lalu = 1.0     # deteksi balik arah → animasi BELOK (spec §9)
var _putar_t = 0.0        # sisa waktu animasi belok
var _putar = ""           # "putar_kiri" (kanan→kiri) / "putar_kanan"
var _udara_t = 0.0        # lama melayang — penggerak frame LOMPAT (play-once)
var _darat_t = 0.0        # sisa waktu animasi mendarat (play-once)
var _meta_t = 0.0         # kilau metamorfosis (sistem tahap lama tetap hidup)
var _tahap_lalu = 1


func _init(a):
	avatar = a
	visible = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for n in ANIM:
		var jalur = "res://aset/konsep_tendril/%s.png" % n
		if ResourceLoader.exists(jalur):
			var t = load(jalur)
			_anim[n] = {"tex": t, "n": max(1, t.get_width() / 48)}


func _process(delta):
	_t += delta
	if not visible:
		return

	# transisi moda: putar detach/attach sekali (CDD §15-16)
	if avatar.moda != _moda_lalu:
		if _moda_lalu != -1:
			_transisi = "detach" if avatar.moda == avatar.LEPAS else "attach"
			_transisi_t = 0.28 if _transisi == "detach" else 0.20
		_moda_lalu = avatar.moda
	_transisi_t = max(0.0, _transisi_t - delta)

	# metamorfosis lama: kilau singkat saat tahap naik
	if avatar.tahap != _tahap_lalu:
		_tahap_lalu = avatar.tahap
		_meta_t = 0.6
	_meta_t = max(0.0, _meta_t - delta)

	# balik arah saat LEPAS = animasi BELOK sungguhan (spec §9: "TENDRIL
	# tidak berpindah arah — ia mengubah arah pertumbuhannya"), bukan flip
	if avatar.hadap != _hadap_lalu:
		if avatar.moda == avatar.LEPAS:
			_putar = "putar_kiri" if avatar.hadap < 0.0 else "putar_kanan"
			if _anim.has(_putar):
				_putar_t = 0.32   # ± 5-6 frame, anticipation singkat (§17)
		_hadap_lalu = avatar.hadap
	_putar_t = max(0.0, _putar_t - delta)

	# pilih state: transisi > gerak per moda > idle. Frame lokomotasi
	# dimajukan oleh JARAK TEMPUH, bukan waktu — tanpa ini tubuh meliuk
	# lepas sinkron dari perpindahan dan jalannya terbaca "meluncur"
	# (temuan playtest pemilik proyek).
	var pindah = _pos_lalu.distance_to(avatar.pos)
	var bergerak = pindah > delta * 3.0
	if bergerak:
		_jarak += pindah
	_pos_lalu = avatar.pos

	# udara & pendaratan (OLR §34, setelah crawl lulus playtest): LOMPAT
	# maju berbasis lama melayang (play-once), DARAT menyala di tepi
	# menyentuh tanah kembali — hanya bermakna di moda LEPAS
	if avatar.moda == avatar.LEPAS and not avatar.di_tanah:
		_udara_t += delta
	else:
		if _udara_t > 0.12 and avatar.moda == avatar.LEPAS \
				and _anim.has("darat"):
			_darat_t = 0.18   # sentuhan singkat: pegas memantul lalu tegak
		_udara_t = 0.0
	_darat_t = max(0.0, _darat_t - delta)

	# ujung memimpin (permintaan playtest, sesuai ADR §11): saat berjalan
	# LEPAS, tubuh condong halus ke arah gerak sehingga ujung/daun tampak
	# melangkah lebih dulu. Kecil (~9°) supaya tidak terbaca mau jatuh;
	# cermin hadap membuat condongannya otomatis mengikuti arah.
	var target_miring = 0.16 if (bergerak and avatar.moda == avatar.LEPAS) \
			else 0.0
	_miring = lerpf(_miring, target_miring, clamp(delta * 8.0, 0.0, 1.0))
	# prioritas: transisi > belok > darat > udara > gerak > idle
	if _transisi_t > 0.0 and _anim.has(_transisi):
		_state = _transisi
	elif _putar_t > 0.0:
		_state = _putar
	elif avatar.moda == avatar.MERAMBAT:
		_state = "merambat" if bergerak else "idle"
	elif _darat_t > 0.0:
		_state = "darat"
	elif not avatar.di_tanah:
		# naik = LOMPAT (play-once, membeku di frame akhir), turun = JATUH
		var udara = "lompat" if avatar.vel.y < 0.0 else "jatuh"
		_state = udara if _anim.has(udara) else "lepas"
	elif bergerak:
		# strip berarah (spec §22-23) kalau ada; "lepas" lama = cadangan
		var arah_anim = "kanan" if avatar.hadap > 0.0 else "kiri"
		_state = arah_anim if _anim.has(arah_anim) else "lepas"
	else:
		_state = "idle"

	queue_redraw()


func _draw():
	var ppu = float(Config.PPU)
	var p = avatar.pos * ppu + Vector2(0.0, -Config.AVATAR_TINGGI * ppu * 0.5)

	# mengisi dari sumber: cincin "minum" mengembang
	if avatar.mengisi:
		var isi_c = Color("A8D94A")
		isi_c.a = 0.35 * (1.0 - fmod(_t, 0.8) / 0.8)
		draw_arc(p, 10.0 + fmod(_t, 0.8) * 14.0, 0.0, TAU, 24, isi_c, 2.0)

	# kilau metamorfosis
	if _meta_t > 0.0:
		var q = 1.0 - _meta_t / 0.6
		var cincin = Color("A8D94A")
		cincin.a = 0.5 * (1.0 - q)
		draw_arc(p, 8.0 + q * 30.0, 0.0, TAU, 28, cincin, 3.0)

	if _anim.has(_state):
		var a = _anim[_state]
		var fr
		if _state == "detach" or _state == "attach":
			# transisi diputar SEKALI, maju sesuai sisa waktunya
			var total = 0.28 if _state == "detach" else 0.20
			var maju = 1.0 - _transisi_t / total
			fr = int(clamp(maju * a.n, 0.0, a.n - 1.0))
		elif _state == "putar_kiri" or _state == "putar_kanan":
			# belok diputar SEKALI (spec §16), maju sesuai sisa waktunya
			fr = int(clamp((1.0 - _putar_t / 0.32) * a.n, 0.0, a.n - 1.0))
		elif _state == "lompat":
			# play-once ~14 fps, MEMBEKU di frame akhir selama masih naik
			fr = int(clamp(_udara_t * 14.0, 0.0, a.n - 1.0))
		elif _state == "jatuh":
			# melayang turun = loop lembut berbasis waktu
			fr = int(_t * 10.0) % a.n
		elif _state == "darat":
			# pegas mendarat diputar SEKALI, maju sesuai sisa waktunya
			fr = int(clamp((1.0 - _darat_t / 0.18) * a.n, 0.0, a.n - 1.0))
		elif _state == "idle":
			# idle berbasis waktu, 8 fps — napas pelan (papan: 8-12 fps)
			fr = int(_t * 8.0) % a.n
		else:
			# lokomotasi berbasis jarak: satu frame tiap ~3 satuan (tempo
			# diturunkan — playtest: siklus terasa terburu-buru); berhenti
			# = liukan berhenti (tidak ada moonwalk)
			fr = int(_jarak / 3.0) % a.n
		# strip BERARAH (kanan/kiri/putar) digambar apa adanya — arah sudah
		# di dalam gambarnya (spec §8). Selain itu: cermin fallback §25.
		# Matriks T·R·S menerapkan cermin sebelum rotasi, jadi condongan
		# dikalikan hadap supaya selalu ke depan.
		var berarah = _state in ["kanan", "kiri", "putar_kiri",
				"putar_kanan"]
		var cermin = 1.0 if berarah else avatar.hadap
		draw_set_transform(p, _miring * avatar.hadap,
				Vector2(cermin, 1.0))
		draw_texture_rect_region(a.tex,
				Rect2(Vector2(-24.0, -26.0), Vector2(48.0, 48.0)),
				Rect2(fr * 48.0, 0.0, 48.0, 48.0))
		draw_set_transform_matrix(Transform2D())
	else:
		# cadangan prosedural bila strip belum ada
		draw_circle(p, 6.0, Color("4F8F32"))
		draw_circle(p + Vector2(-2.0, -2.0), 3.0, Color("A8D94A"))

	# bar energi (UI minimal GDD §31)
	var w = 26.0
	var atas = p + Vector2(-w * 0.5, -26.0)
	draw_rect(Rect2(atas, Vector2(w, 4.0)), Color(0.06, 0.12, 0.08, 0.7))
	var isi = clamp(avatar.energi / avatar.energi_max, 0.0, 1.0)
	var c = Color("A8D94A") if isi > 0.3 else Color("C25A4A")
	draw_rect(Rect2(atas, Vector2(w * isi, 4.0)), c)
