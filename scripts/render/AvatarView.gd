extends Node2D

# Tampilan TENDRIL — KARAKTER PLAYER buatan pemilik (aset/player, 32 px
# per frame, palet CDD §7 + putih mata). Master A (konsep_tendril)
# pensiun dari view ini — diarsipkan sebagai calon NPC.
#
# Strip yang ada: idle_timur/barat (7f), crawl_timur/barat (9f, bedah
# v7), lompat/jatuh/darat_pegas (6/6/5f, bahasa pegas), rambat_ujung
# (+senyap) 4f — ujung tunas ~10px untuk moda MERAMBAT: tubuh tanaman
# adalah JEJAK DAUN yang ditanam Avatar (digambar DaunView), sprite
# hanya ujung hidup berpivot di garis dengan sudut kontinu. Idle &
# crawl BERARAH (digambar apa adanya); strip pegas satu arah timur,
# dicermin `hadap`. Belok/detach/attach otomatis nonaktif sampai
# strip-nya ada — state machine sudah memagari dengan has().
# Idle dipakai saat nyaris diam di moda mana pun: organisme harus
# terlihat hidup justru ketika pemain diam (CDD Rule 8), 8-12 fps.
const ANIM = ["idle_timur", "idle_barat", "crawl_timur", "crawl_barat",
		"lompat_pegas", "jatuh_pegas", "darat_pegas", "putar_kiri",
		"putar_kanan", "detach", "attach"]

var avatar
var _t = 0.0
var _anim = {}            # nama -> {tex, n}
var _state = "idle"
var _transisi_t = 0.0     # sisa waktu memutar detach/attach
var _transisi = ""
var _moda_lalu = -1
var _pos_lalu = Vector2()
var _jarak = 0.0          # jarak tempuh — penggerak frame lokomotasi
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
		var jalur = "res://aset/player/%s.png" % n
		if ResourceLoader.exists(jalur):
			var t = load(jalur)
			var jml = max(1, t.get_width() / 32)
			_anim[n] = {"tex": t, "n": jml, "geser": _pusat(t, jml)}


# Badan karakter tidak di tengah kanvas 32 px (menumpuk di satu sisi) —
# tanpa koreksi, ganti hadap membuat badan MELONCAT +-15 px (temuan
# playtest pemilik). Ukur pusat massa horizontal rata-rata seluruh
# frame strip sekali saat muat; _draw menggeser rect sebesar selisihnya
# supaya badan selalu berpivot tepat di posisi avatar.
func _pusat(tex, jml):
	var img = tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	var jumlah = 0.0
	var bobot = 0
	for i in range(jml):
		for y in range(img.get_height()):
			for x in range(32):
				if img.get_pixel(i * 32 + x, y).a >= 0.5:
					jumlah += x
					bobot += 1
	if bobot == 0:
		return 0.0
	return 16.0 - jumlah / bobot   # positif = badan condong kiri kanvas


func _process(delta):
	_t += delta
	if not visible:
		return

	# transisi moda: putar detach/attach sekali (CDD §15-16)
	if avatar.moda != _moda_lalu:
		if _moda_lalu != -1:
			_transisi = "detach" if avatar.moda == avatar.LEPAS else "attach"
			# morph 9f PixelLab: ujung atas rentang CDD §15-16 supaya
			# transformasinya sempat terbaca
			_transisi_t = 0.30 if _transisi == "detach" else 0.25
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
	var gerak = avatar.pos - _pos_lalu
	var pindah = gerak.length()
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
				and _anim.has("darat_pegas"):
			_darat_t = 0.18   # sentuhan singkat: pegas memantul lalu tegak
		_udara_t = 0.0
	_darat_t = max(0.0, _darat_t - delta)

	# condongan "ujung memimpin" era Master A DICABUT (playtest pemilik:
	# di karakter 32px crawl jadi terbaca miring) — bahasa gerak sudah
	# dibawa strip gelombangnya sendiri
	# prioritas: transisi > belok > darat > udara > gerak > idle
	var timur = avatar.hadap > 0.0
	if _transisi_t > 0.0 and _anim.has(_transisi):
		_state = _transisi
	elif _putar_t > 0.0:
		_state = _putar
	elif avatar.moda == avatar.MERAMBAT:
		# WUJUD AKHIR (putusan pemilik): di jaringan pemain TIDAK punya
		# sprite sama sekali — ia ADALAH pertumbuhan itu sendiri. Posisi
		# dibawa kepala jejak daun (DaunView) + pendar cahaya avatar.
		# Satu-satunya saat wujud terlihat berubah = transisi detach/
		# attach (morph PixelLab).
		_state = "rambat_sembunyi"
	elif _darat_t > 0.0:
		_state = "darat_pegas"
	elif not avatar.di_tanah:
		# naik = LOMPAT (play-once, membeku di frame akhir), turun = JATUH
		_state = "lompat_pegas" if avatar.vel.y < 0.0 else "jatuh_pegas"
	elif bergerak:
		_state = "crawl_timur" if timur else "crawl_barat"
	else:
		_state = "idle_timur" if timur else "idle_barat"

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

	# RK-2 [A]: beton menolak tumbuh — kedip kelabu singkat di titik
	# tumbuh (bahasa dunia; teksnya di HUD)
	if avatar.tumbuh_tolak > 0.0:
		var tolak = Color("59636F")
		tolak.a = 0.7 * (avatar.tumbuh_tolak / 0.5)
		draw_arc(avatar.pos * float(Config.PPU), 7.0, 0.0, TAU, 16,
				tolak, 2.0)

	# RK-2 [B]: denyut kelahiran node saat F tertanam
	if avatar.jangkar_baru > 0.0:
		var q2 = 1.0 - avatar.jangkar_baru / 0.6
		var lahir = Color("79B83F")
		lahir.a = 0.6 * (1.0 - q2)
		draw_arc(avatar.pos * float(Config.PPU), 4.0 + q2 * 26.0,
				0.0, TAU, 24, lahir, 3.0)

	if _anim.has(_state):
		var a = _anim[_state]
		var fr
		if _state == "detach" or _state == "attach":
			# transisi diputar SEKALI, maju sesuai sisa waktunya
			var total = 0.30 if _state == "detach" else 0.25
			var maju = 1.0 - _transisi_t / total
			fr = int(clamp(maju * a.n, 0.0, a.n - 1.0))
		elif _state == "putar_kiri" or _state == "putar_kanan":
			# belok diputar SEKALI (spec §16), maju sesuai sisa waktunya
			fr = int(clamp((1.0 - _putar_t / 0.32) * a.n, 0.0, a.n - 1.0))
		elif _state == "lompat_pegas":
			# play-once ~14 fps: squash gepeng 2f lalu melesat, MEMBEKU
			# di frame puncak selama masih naik
			fr = int(clamp(_udara_t * 14.0, 0.0, a.n - 1.0))
		elif _state == "jatuh_pegas":
			# melayang turun = loop goyah lembut berbasis waktu
			fr = int(_t * 10.0) % a.n
		elif _state == "darat_pegas":
			# splat mendarat diputar SEKALI, maju sesuai sisa waktunya
			fr = int(clamp((1.0 - _darat_t / 0.18) * a.n, 0.0, a.n - 1.0))
		elif _state.begins_with("idle"):
			# idle berbasis waktu, 8 fps — napas pelan (papan: 8-12 fps)
			fr = int(_t * 8.0) % a.n
		else:
			# crawl berbasis jarak: satu frame tiap ~3 satuan (tempo
			# diturunkan — playtest: siklus terasa terburu-buru); berhenti
			# = liukan berhenti (tidak ada moonwalk)
			fr = int(_jarak / 3.0) % a.n
		# idle/crawl BERARAH: strip timur & barat terpisah, digambar apa
		# adanya. Strip pegas satu arah timur — dicermin `hadap` (anim
		# udara non-berarah, pola lama). Matriks T·R·S menerapkan cermin
		# sebelum rotasi, jadi condongan dikalikan hadap supaya selalu
		# ke depan.
		var berarah = _state.begins_with("idle") \
				or _state.begins_with("crawl") or _state.begins_with("putar")
		var cermin = 1.0 if berarah else avatar.hadap
		# SQUASH & STRETCH pegas dari kecepatan (koreksi feel pemilik:
		# "tidak terasa dia melompat"): di udara badan MEREGANG mengikuti
		# laju vertikal — makin kencang naik/turun makin panjang; saat
		# darat, strip splat yang bicara. Frame antisipasi jongkok sudah
		# dibuang dari strip lompat (antisipasi di udara terbaca janggal).
		var regang = 0.0
		if avatar.moda == avatar.LEPAS and not avatar.di_tanah:
			regang = clamp(abs(avatar.vel.y) / Config.AVATAR_LOMPAT,
					0.0, 1.0)
		var skala = Vector2(1.0 - 0.12 * regang, 1.0 + 0.18 * regang)
		draw_set_transform(p, 0.0, Vector2(cermin * skala.x, skala.y))
		draw_texture_rect_region(a.tex,
				Rect2(Vector2(-16.0 + a.geser, -10.0), Vector2(32.0, 32.0)),
				Rect2(fr * 32.0, 0.0, 32.0, 32.0))
		draw_set_transform_matrix(Transform2D())
	elif _state != "rambat_sembunyi":
		# cadangan prosedural bila strip belum ada; "rambat_sembunyi"
		# SENGAJA tanpa gambar — pemain = pertumbuhan itu sendiri
		draw_circle(p, 6.0, Color("4F8F32"))
		draw_circle(p + Vector2(-2.0, -2.0), 3.0, Color("A8D94A"))

	# status deteksi (RK Langkah 2, warna kanon CDD §7: kuning =
	# terdeteksi) — bahasa cincin, bukan UI teks (SRD §12/§23)
	if avatar.terdeteksi:
		var kuning = Color("D89A3C")
		kuning.a = 0.75 + 0.25 * sin(_t * 14.0)
		draw_arc(p, 15.0 + 1.5 * sin(_t * 14.0), 0.0, TAU, 24, kuning, 2.0)
	elif avatar.regen_mati:
		# sensor masih waspada: jaringan menolak memulihkan — cincin
		# kuning redup mengingatkan kenapa energi tidak naik
		var was = Color("D89A3C")
		was.a = 0.35
		draw_arc(p, 13.0, 0.0, TAU, 24, was, 1.5)
	elif avatar.curiga:
		var samar = Color("D89A3C")
		samar.a = 0.18
		draw_arc(p, 12.0, 0.0, TAU, 20, samar, 1.0)

	# bar energi lama di atas kepala DICABUT — energi kini bicara lewat
	# HUD GDD §31 (Hud.gd); dunia menyisakan bahasa cincin & pendar saja
