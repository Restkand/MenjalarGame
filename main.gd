extends Node2D

const WorldMapCls    = preload("res://scripts/WorldMap.gd")
const TreeSimCls     = preload("res://scripts/TreeSim.gd")
const CycleCls       = preload("res://scripts/Cycle.gd")
const CrewCls        = preload("res://scripts/Crew.gd")
const ClimberCls     = preload("res://scripts/Climber.gd")
const ErosiCls       = preload("res://scripts/Erosi.gd")
const BabakCls       = preload("res://scripts/Babak.gd")
const PaneCls        = preload("res://scripts/Pane.gd")
const SuasanaCls     = preload("res://scripts/Suasana.gd")
const SuaraCls       = preload("res://scripts/Suara.gd")
const TanamanViewCls = preload("res://scripts/render/TanamanView.gd")
const TerrainViewCls = preload("res://scripts/render/TerrainView.gd")
const PuingViewCls   = preload("res://scripts/render/PuingView.gd")
const AktorViewCls   = preload("res://scripts/render/AktorView.gd")
const UjungViewCls   = preload("res://scripts/render/UjungView.gd")
const RisikoViewCls  = preload("res://scripts/render/RisikoView.gd")
const LatarViewCls   = preload("res://scripts/render/LatarView.gd")
const TuningPanelCls = preload("res://scripts/TuningPanel.gd")
const HudCls         = preload("res://scripts/Hud.gd")
const AvatarCls      = preload("res://scripts/Avatar.gd")
const AvatarViewCls  = preload("res://scripts/render/AvatarView.gd")
const InteriorViewCls = preload("res://scripts/render/InteriorView.gd")
const JejakViewCls   = preload("res://scripts/render/JejakView.gd")

var world
var sim
var cycle
var crew
var climbers
var erosi
var babak
var suasana
var suara
var _settled_prev = 0     # untuk debum puing mendarat
var _puing_cooldown = 0.0
var tanaman
var terrain
var panel
var hud

var ujung_atas
var ujung_bawah
var risiko

# PIVOT IV P1 (docs/13): avatar dua moda + kamera tunggal mengikuti
var avatar
var avatar_view
var _lompat_tekan = false   # edge tombol Spasi, dikosongkan tiap frame
var _masuk_tekan = false    # edge tombol E (masuk/keluar gedung, P2)
var _sumber_air_dikenal = false      # flash penemuan sekali (P3)
var _sumber_cahaya_dikenal = false


var _babak_terakhir = 1
var _fase_terakhir = Config.PHASE_DAY
var _kartu_t = 0.0        # sisa waktu kartu pergantian fase; > 0 = jeda
var _flash_potong = 0.0   # peredam supaya "regu memangkas" tidak spam

# kontrol waktu (G1): Spasi = jeda, 1/2 = kecepatan simulasi
var _jeda = false
var _laju_waktu = 1.0

var pane_atas
var pane_bawah

var is_steering = false
var playing = false
var won = false
var show_risk = false

# Pane yang sedang di bawah kursor. Semua perintah kamera dan semua konversi
# mouse memakai yang ini — tidak perlu klik untuk "memilih" pane.
var _pane_aktif
var _geser_drag = false


func _ready():
	randomize()

	world = WorldMapCls.new()
	world.build()

	# PIVOT IV P1 (docs/13): SATU pane layar penuh, kamera bebas menjelajah
	# seluruh dunia 0..H. `pane_bawah` di-alias ke pane yang sama supaya
	# seluruh wiring era split-screen (terrain dua layer, view akar, ujung)
	# tetap hidup tanpa dibongkar — aturan emas docs/13 §9: jangan menghapus
	# sistem lama sebelum penggantinya berdiri.
	pane_atas = PaneCls.new()
	add_child(pane_atas)
	pane_atas.siapkan(Vector2(0, Config.HUD_ATAS),
			Vector2(Config.PANE_LEBAR,
					Config.PANE_ATAS_TINGGI + Config.PANE_BAWAH_TINGGI),
			0, Config.H)
	pane_atas.set_zoom(Config.ZOOM_AVATAR)
	pane_bawah = pane_atas

	_pane_aktif = pane_atas

	# latar parallax di bawah segalanya (G8) — langit + siluet kota jauh
	var latar = LatarViewCls.new(pane_atas)
	latar.z_index = -1
	pane_atas.tempel(latar)

	# terrain paling dulu: z-nya eksplisit, tapi urutan tempel menentukan
	# siapa yang menang saat z sama (FasadView di atas ubin)
	terrain = TerrainViewCls.new()
	terrain.setup(pane_atas, pane_bawah, world)

	suasana = SuasanaCls.new()
	add_child(suasana)
	# satu pane = satu CanvasModulate; dua akan saling menumpuk gelap
	suasana.setup([pane_atas])
	suasana.setup_lights(world, pane_atas)

	erosi = ErosiCls.new()
	erosi.setup(world)

	# puing melayang & debu — hanya pane atas; blocked() menghentikan puing
	# di garis tanah, jadi ia tidak pernah masuk zona bawah
	var puing_view = PuingViewCls.new(erosi)
	puing_view.z_index = 2
	pane_atas.tempel(puing_view)

	sim = TreeSimCls.new()
	sim.reset()

	# lapis view tanaman: sulur/akar = Line2D, daun = sprite (R1, docs/09)
	tanaman = TanamanViewCls.new()
	tanaman.setup(pane_atas, pane_bawah, sim)

	cycle = CycleCls.new()
	cycle.reset()

	crew = CrewCls.new()
	crew.reset()

	climbers = ClimberCls.new()
	climbers.reset()

	babak = BabakCls.new()
	babak.reset()

	# lapis view sisa overlay lama (R6): aktor, ujung/pratinjau, peta risiko
	var aktor = AktorViewCls.new(crew, climbers)
	aktor.z_index = 3
	pane_atas.tempel(aktor)

	ujung_atas = UjungViewCls.new(sim)
	ujung_atas.z_index = 4
	pane_atas.tempel(ujung_atas)
	# P3.5: denyut ujung & kotak pilihan milik steering lama — disembunyikan
	# selama moda avatar supaya layar tidak bicara dua bahasa
	ujung_atas.visible = false

	ujung_bawah = UjungViewCls.new(sim)
	ujung_bawah.z_index = 4
	pane_bawah.tempel(ujung_bawah)
	# pane tunggal (P1): ujung_atas sudah menggambar semuanya di viewport
	# yang sama — kembarannya disembunyikan supaya tidak menggambar dobel
	ujung_bawah.visible = false

	risiko = RisikoViewCls.new(world)
	risiko.z_index = 4
	pane_atas.tempel(risiko)

	# avatar (P1, docs/13) — lahir saat MULAI, view-nya siap dari sekarang
	avatar = AvatarCls.new()
	# interior (P2): menutup fasad saat avatar di dalam; avatar tetap di atas
	var interior = InteriorViewCls.new(world, avatar)
	interior.z_index = 4
	pane_atas.tempel(interior)
	# jejak sulur yang ditumbuhkan avatar (P3) — di atas interior, di bawah
	# avatar
	var jejak_view = JejakViewCls.new(avatar)
	jejak_view.z_index = 4
	pane_atas.tempel(jejak_view)
	avatar_view = AvatarViewCls.new(avatar)
	avatar_view.z_index = 5
	pane_atas.tempel(avatar_view)

	panel = TuningPanelCls.new()
	add_child(panel)
	panel.reset_pressed.connect(_restart)

	hud = HudCls.new()
	add_child(hud)
	hud.play_pressed.connect(_on_play)
	# P3.5: HUD bicara bahasa avatar — pita ekonomi lama disembunyikan.
	# _ready anak sudah berjalan di dalam add_child, jadi panggil langsung.
	hud.set_avatar(avatar)

	suara = SuaraCls.new()
	add_child(suara)


func _on_play():
	playing = true
	# avatar lahir di trotoar dekat bibit — berjalanlah ke tanaman, sentuh,
	# dan Anda menempel: momen pengajaran pertama tanpa satu kalimat pun
	avatar.mulai(Vector2(Config.SEED_X + 14.0, float(Config.GROUND_Y)))
	avatar_view.visible = true


func _restart():
	# Keruntuhan mengubah grid secara permanen, jadi dunianya harus dibangun
	# ulang — bukan sekadar mereset pohon.
	world.build()
	terrain.bangun_ulang()
	suasana.setup_lights(world, pane_atas)   # grid baru — lampu yang padam menyala lagi
	erosi.setup(world)
	sim.reset()
	# id untai mulai dari 1 lagi setelah reset, jadi view lama WAJIB dibuang
	# eksplisit — sinkron() tidak bisa membedakannya dari untai baru
	tanaman.bersih()
	cycle.reset()
	crew.reset()
	climbers.reset()
	babak.reset()
	_babak_terakhir = 1
	_fase_terakhir = Config.PHASE_DAY
	_kartu_t = 0.0
	_jeda = false
	_laju_waktu = 1.0
	_settled_prev = 0
	_puing_cooldown = 0.0
	if playing:
		avatar.mulai(Vector2(Config.SEED_X + 14.0, float(Config.GROUND_Y)))
	_sumber_air_dikenal = false
	_sumber_cahaya_dikenal = false
	hud.sembunyikan_kartu()
	is_steering = false
	playing = false
	won = false
	show_risk = false
	hud.show_overlay()


# ---------------------------------------------------------------------------
# Input — SELURUHNYA di file ini. Pane dan node UI tidak pernah membaca input;
# mereka hanya dipanggil dari sini.
# ---------------------------------------------------------------------------

# Godot 4 memecah satu `scancode` milik Godot 3 jadi DUA properti:
# `keycode` mengikuti layout papan ketik, `physical_keycode` mengikuti posisi
# fisik ala QWERTY. Salah satunya bisa bernilai 0 tergantung dari mana event
# itu berasal, jadi memeriksa hanya satu membuat tombol diam saja di sebagian
# papan ketik. Semua pembacaan tombol lewat sini.
func _kunci(event, kode):
	return event.keycode == kode or event.physical_keycode == kode


# Versi polling dari _kunci(), untuk tombol yang ditahan (geser kamera).
# Alasan memeriksa keduanya sama persis.
func _tekan(kode):
	return Input.is_key_pressed(kode) or Input.is_physical_key_pressed(kode)


func _pane_di(titik_layar):
	if pane_atas.berisi(titik_layar):
		return pane_atas
	if pane_bawah.berisi(titik_layar):
		return pane_bawah
	return null


# Posisi mouse dalam koordinat DUNIA, lewat kamera pane yang sedang ditunjuk.
# Menggantikan `mouse / Config.SCALE` — sejak TAHAP A tidak ada lagi satu skala
# tunggal, karena tiap pane punya zoom dan geserannya sendiri.
func _mouse_dunia():
	var s = get_viewport().get_mouse_position()
	var p = _pane_di(s)
	if p != null:
		_pane_aktif = p
	return _pane_aktif.titik_dunia(s)


func _kamera(delta):
	# sejak P1 WASD milik avatar dan kamera mengikutinya — pan manual hanya
	# hidup di layar judul (meninjau dunia sebelum MULAI)
	if playing:
		return
	var v = Vector2()
	if _tekan(KEY_A) or _tekan(KEY_LEFT):
		v.x -= 1.0
	if _tekan(KEY_D) or _tekan(KEY_RIGHT):
		v.x += 1.0
	if _tekan(KEY_W) or _tekan(KEY_UP):
		v.y -= 1.0
	if _tekan(KEY_S) or _tekan(KEY_DOWN):
		v.y += 1.0
	if v == Vector2.ZERO:
		return
	# GESER_SPEED dalam satuan dunia; kamera hidup di piksel (x PPU). Dibagi
	# zoom supaya kecepatan geser terasa sama di layar pada zoom berapa pun.
	_pane_aktif.geser(v.normalized() * Config.GESER_SPEED * Config.PPU
			* delta / _pane_aktif.zoom)


# Isi kartu pergantian fase — pengajaran kontekstual: sistem perhatian
# dijelaskan tepat pada momen ia bekerja (inspeksi, kedatangan regu), bukan
# lewat tembok teks tutorial.
func _kartu_fase():
	# P3.5: kartu MENYUSUT — narasi inspeksi/perawatan/ekonomi-min() milik
	# game lama dibungkam sampai sistemnya kembali relevan (P4+). Kartu
	# sekarang hanya penanda ritme hari, satu baris yang berguna bagi avatar.
	_kartu_t = Config.KARTU_DETIK
	suara.mainkan("sting")
	if cycle.phase == Config.PHASE_NIGHT:
		hud.tampil_kartu("MALAM",
				"matahari tidur — energi hanya dari air (keran & akuifer)")
		return
	hud.tampil_kartu("HARI %d" % cycle.hari,
			"cahaya kembali — area terang mengisi energi")


# Klik kanan bertingkat tiga (G2): pohon > ujung terdekat > bekas rambatan.
# `ada_ujung` = apakah klik jatuh dekat ujung yang bisa dipilih — cabang
# klasik dari ujung didahulukan atas tunas ulang supaya kebiasaan lama tetap
# bekerja (area sekitar ujung hampir selalu juga bekas rambatan).
func _try_branch(m, ada_ujung):
	# pohon di dekat kursor jadi titik awal baru, kalau ada
	if sim.branch_at(m):
		return
	if ada_ujung and sim.branch():
		return
	if sim.tunas_di(m, world):
		suara.mainkan("daun")
		hud.flash_msg("Tunas baru dari bekas rambatan  (-%d energi)"
				% int(Config.COST_TUNAS))
		return
	if sim.strands.size() >= Config.MAX_STRANDS:
		hud.flash_msg("Batas untai tercapai")
	elif sim.energy < Config.COST_TUNAS:
		hud.flash_msg("Energi kurang — butuh %d" % int(Config.COST_TUNAS))
	else:
		hud.flash_msg("Klik kanan di ujung, pohon, atau bekas rambatan")


func _process(delta):
	delta = min(delta, 1.0 / 30.0)
	var m = _mouse_dunia()
	_kamera(delta)

	# Kontrol waktu (G1): jeda membekukan SIMULASI saja — kamera, kartu, dan
	# animasi view tetap hidup. Laju 2x hanya mengalikan delta simulasi;
	# delta kamera/UI tidak pernah disentuh.
	var dt = 0.0 if _jeda else delta * _laju_waktu

	# erosi berjalan juga sebelum MULAI — puing yang masih melayang setelah
	# reset harus tetap jatuh
	erosi.update(dt)

	# kartu pergantian fase menjeda simulasi; render dan kamera tetap hidup
	if _kartu_t > 0.0:
		_kartu_t = max(0.0, _kartu_t - delta)
		hud.kartu_pudar(_kartu_t)
		if _kartu_t <= 0.0:
			hud.sembunyikan_kartu()
	elif not _jeda and playing and not won:
		# `terlihat` = jumlah nilai vis di tiap titik yang tumbuh frame ini —
		# inilah yang menaikkan perhatian pengelola gedung
		var terlihat = sim.update(dt, is_steering, m, world, cycle.phase,
				cycle.musim_kering())
		cycle.update(dt, sim, world, terlihat)

		# kolam akuifer yang menyusut mengumumkan dirinya sendiri
		if world.pesan_kering != "":
			hud.flash_msg(world.pesan_kering)
			world.pesan_kering = ""

		if cycle.phase != _fase_terakhir:
			_fase_terakhir = cycle.phase
			_kartu_fase()

		# P3.5: regu & pemanjat DIBUNGKAM sampai penggantinya berdiri (P4
		# penjaga) — kodenya utuh, update-nya saja yang tidak dipanggil.
		#crew.update(dt, sim, world, erosi, cycle)
		#climbers.update(dt, sim, world, cycle)

		# --- avatar (P1, docs/13): WASD/panah gerak, Spasi lompat/lepas ----
		var arah = Vector2()
		if _tekan(KEY_A) or _tekan(KEY_LEFT):
			arah.x -= 1.0
		if _tekan(KEY_D) or _tekan(KEY_RIGHT):
			arah.x += 1.0
		if _tekan(KEY_W) or _tekan(KEY_UP):
			arah.y -= 1.0
		if _tekan(KEY_S) or _tekan(KEY_DOWN):
			arah.y += 1.0
		avatar.update(dt, arah, _lompat_tekan, _masuk_tekan, world)
		if avatar.layu_baru:
			avatar.layu_baru = false
			hud.flash_msg("LAYU — kembali ke simpul jaringan terakhir")

		# --- sumber daya (P3, docs/13 §4): air & cahaya PUNYA ALAMAT -------
		var apx = int(round(avatar.pos.x))
		var apy = int(round(avatar.pos.y - 2.0))
		avatar.mengisi = false
		avatar.sumber = ""
		if world.dekat_air(apx, apy, avatar.di_dalam):
			avatar.isi(Config.AIR_ISI * dt)
			avatar.mengisi = true
			avatar.sumber = "air"
			if not _sumber_air_dikenal:
				_sumber_air_dikenal = true
				hud.flash_msg("SUMBER AIR — energi terisi selama di dekatnya")
		elif cycle.phase == Config.PHASE_DAY:
			if not avatar.di_dalam and world.light_at(apx, apy) > 0.5:
				avatar.isi(Config.CAHAYA_ISI * dt)
				avatar.mengisi = true
				avatar.sumber = "cahaya"
				if not _sumber_cahaya_dikenal:
					_sumber_cahaya_dikenal = true
					hud.flash_msg("MATAHARI — energi terisi di area terang saat siang")
			elif avatar.di_dalam and world.di_gerbang_interior(apx, apy):
				avatar.isi(Config.CAHAYA_JENDELA * dt)
				avatar.mengisi = true
				avatar.sumber = "cahaya"

		# P3.5: babak lama dibungkam (pengganti: P8)
		#babak.update(dt, sim, world)
		if false and babak.babak != _babak_terakhir:
			_babak_terakhir = babak.babak
			if babak.babak == 2:
				hud.flash_msg("BABAK II — hijaukan TIAP zona sampai %d%%"
						% int(round(Config.ZONA_TARGET * 100)))
			else:
				hud.flash_msg("BABAK III — tanam %d pohon permanen (T di sulur atas puing)"
						% int(Config.BABAK3_POHON))

	tanaman.sinkron()
	tanaman.set_kering(cycle.musim_kering())
	terrain.sinkron()

	# kamera tunggal mengikuti avatar (P1) — halus, sedikit di atas kepala;
	# geser() yang menjepit ke tepi dunia dan membulatkan ke piksel
	if playing:
		var target = avatar.pos * float(Config.PPU) + Vector2(0.0, -40.0)
		pane_atas.geser((target - pane_atas.cam.position)
				* clamp(delta * 6.0, 0.0, 1.0))
	_lompat_tekan = false
	_masuk_tekan = false

	# P3.5: pratinjau steering & menang-kalah babak lama dibungkam bersama
	# sistemnya; peta risiko ikut (maknanya kembali di P4)
	risiko.visible = false

	suasana.set_night(cycle.night_amount())

	# --- audio (G7): ambience mengikuti fase, loop kerja mengikuti keadaan --
	suara.set_malam(cycle.night_amount())
	var ada_gergaji = false
	for u in crew.units:
		if u.pingsan <= 0.0 and u.kerja > 0.0:
			ada_gergaji = true
			break
	suara.set_gergaji(playing and not _jeda and ada_gergaji)
	var ada_bor = false
	if cycle.phase == Config.PHASE_DAY:
		for s in sim.strands:
			if s.alive and s.tembus >= 0.0:
				ada_bor = true
				break
	suara.set_bor(playing and not _jeda and ada_bor)
	# debum saat puing baru mendarat, diredam supaya hujan puing tidak drum
	_puing_cooldown = max(0.0, _puing_cooldown - delta)
	if world.settled_n > _settled_prev and _puing_cooldown <= 0.0:
		suara.mainkan("puing")
		_puing_cooldown = 0.35
	_settled_prev = world.settled_n

	hud.set_waktu(_jeda, _laju_waktu)
	hud.refresh(sim, cycle, world, crew, climbers, babak)

	# petunjuk kontekstual (P3.5) — satu baris, satu hal, sesuai keadaan
	if playing:
		var hint = ""
		if avatar.energi < 25.0:
			hint = "ENERGI KRITIS — cari keran bocor, akuifer, atau area terang bermatahari"
		elif world.di_gerbang_interior(int(round(avatar.pos.x)),
				int(round(avatar.pos.y - 2.0))):
			hint = "E  %s gedung" % ("keluar" if avatar.di_dalam else "masuk")
		elif avatar.moda == avatar.MERAMBAT:
			hint = "WASD merambat — terus tekan di tepi jaringan = TUMBUH        Spasi lepas        F jangkar (%d)" \
					% int(Config.JANGKAR_BIAYA)
		else:
			hint = "WASD gerak        Spasi lompat        sentuh tanaman untuk menempel"
		hud.set_hint(hint)


func _input(event):
	if event is InputEventMouseButton and not event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		is_steering = false

	if event is InputEventKey and _kunci(event, KEY_V):
		show_risk = event.pressed


func _unhandled_input(event):
	# klik apa pun melewati kartu pergantian fase
	if _kartu_t > 0.0 and event is InputEventMouseButton and event.pressed:
		_kartu_t = 0.0
		hud.sembunyikan_kartu()
		return

	# --- kamera: selalu aktif, bahkan sebelum MULAI --------------------------
	if event is InputEventMouseButton and event.pressed:
		var p = _pane_di(event.position)
		if p != null:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				p.ubah_zoom(Config.ZOOM_FAKTOR)
				return
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				p.ubah_zoom(1.0 / Config.ZOOM_FAKTOR)
				return

	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_MIDDLE:
		_geser_drag = event.pressed
		return

	if _geser_drag and event is InputEventMouseMotion:
		# geseran datang dalam piksel layar; dibagi zoom jadi piksel dunia.
		# Tandanya dibalik supaya dunia ikut kursor.
		_pane_aktif.geser(-event.relative / _pane_aktif.zoom)
		return

	# --- tombol yang selalu aktif -------------------------------------------
	if event is InputEventKey and event.pressed and not event.echo:
		if _kunci(event, KEY_R):
			_restart()
			return
		elif _kunci(event, KEY_TAB):
			panel.toggle()
			return

	if not playing or won:
		return

	# --- kontrol waktu (G1) — Spasi pindah tugas dari bercabang ke jeda;
	# bercabang cukup di klik kanan
	if event is InputEventKey and event.pressed and not event.echo:
		if _kunci(event, KEY_SPACE):
			# Kartu tampil = Spasi melewati kartu (jebakan playtest 12 Agu).
			# Sejak P1 Spasi = LOMPAT/lepas; jeda pindah ke P.
			if _kartu_t > 0.0:
				_kartu_t = 0.0
				hud.sembunyikan_kartu()
			elif playing:
				_lompat_tekan = true
			return
		elif _kunci(event, KEY_P):
			_jeda = not _jeda
			return
		elif _kunci(event, KEY_1):
			_laju_waktu = 1.0
			_jeda = false
			return
		elif _kunci(event, KEY_2):
			_laju_waktu = 2.0
			_jeda = false
			return

	# P3.5: steering mouse milik game lama dibungkam — avatar dikendalikan
	# keyboard. Klik kiri/kanan tidak melakukan apa-apa saat bermain.
	if event is InputEventMouseButton and event.pressed and not playing:
		var m = _mouse_dunia()
		if event.button_index == MOUSE_BUTTON_LEFT:
			if sim.select_near(m, cycle.phase):
				# ujung akar yang menempel beton mulai MENEMBUS saat diklik
				# (docs/02 §7): ia berhenti tumbuh dan energi terkuras sampai
				# terowongannya terbuka. Klik lagi tidak mengulang.
				var s = sim.selected
				if s != null and s.is_root and s.alive and s.tembus < 0.0 \
						and world.dekat_beton(s.tip):
					s.tembus = 0.0
					hud.flash_msg("Menembus beton — energi terkuras")
			is_steering = true
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			var ada_ujung = sim.select_near(m, cycle.phase)
			_try_branch(m, ada_ujung)

	if event is InputEventKey and event.pressed and not event.echo:
		# --- kata kerja avatar (P2) — didahulukan dari kata kerja lama -----
		if _kunci(event, KEY_E):
			# masuk/keluar gedung lewat jendela/pintu — diproses Avatar.update
			if playing:
				_masuk_tekan = true
			return
		if playing and _kunci(event, KEY_F):
			# F milik avatar sekarang: tanam jangkar (perkuat lama tetap ada
			# di kode, kehilangan tombol — nasibnya diputuskan P6)
			if avatar.jangkar(world):
				suara.mainkan("daun")
				hud.flash_msg("Jangkar ditanam — simpul bangun & titik pulih  (-%d energi)"
						% int(Config.JANGKAR_BIAYA))
			else:
				hud.flash_msg("Energi kurang — jangkar butuh %d"
						% int(Config.JANGKAR_BIAYA))
			return
		if playing:
			return   # P3.5: kata kerja lama (T/F/X) tidur selama moda avatar
		if _kunci(event, KEY_T):
			# tanam pohon dengan sengaja (G5) — korbankan sulur di puing
			var hasil = sim.tanam_sengaja()
			match hasil:
				"":
					sim.ensure_selection(cycle.phase)
					suara.mainkan("pohon")
					hud.flash_msg("Pohon ditanam — permanen, kebal regu  (-%d energi)"
							% int(Config.COST_TANAM))
				"pilih":
					hud.flash_msg("Tanam: pilih sulur dulu (klik kiri)")
				"puing":
					hud.flash_msg("Pohon hanya bisa ditanam di ujung sulur yang berdiri di PUING")
				"jarak":
					hud.flash_msg("Terlalu dekat dengan pohon lain")
				"penuh":
					hud.flash_msg("Hutan sudah penuh")
				"energi":
					hud.flash_msg("Energi kurang — tanam butuh %d"
							% int(Config.COST_TANAM))
		elif _kunci(event, KEY_F):
			# perkuat pangkal sulur terpilih (G2)
			if sim.perkuat():
				suara.mainkan("thunk")
				hud.flash_msg("Pangkal diperkuat — gergaji regu butuh 2x lebih lama  (-%d energi)"
						% int(Config.COST_KOKOH))
			elif sim.selected == null or not sim.selected.alive \
					or sim.selected.is_root:
				hud.flash_msg("Perkuat: pilih sulur dulu (klik kiri)")
			elif sim.selected.kokoh:
				hud.flash_msg("Sulur ini sudah diperkuat")
			else:
				hud.flash_msg("Energi kurang — perkuat butuh %d"
						% int(Config.COST_KOKOH))
		elif _kunci(event, KEY_X):
			# putus sulur di kursor — menjatuhkan pemanjat di atasnya, DAN
			# merontokkan daun-daunnya: pemangkasan sukarela yang menurunkan
			# perhatian (pendamaian dua makna X, lihat Config.PERHATIAN_PANGKAS)
			var potong = sim.sever_at(_mouse_dunia())
			if potong == null:
				hud.flash_msg("Arahkan kursor ke sulur untuk memutusnya")
			else:
				suara.mainkan("potong")
				var n = climbers.jatuhkan(potong.s, potong.i)
				cycle.perhatian = max(0.0,
						cycle.perhatian - Config.PERHATIAN_PANGKAS)
				sim.ensure_selection(cycle.phase)
				if n > 0:
					hud.flash_msg("Pemanjat jatuh: %d" % n)
