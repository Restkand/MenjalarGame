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
const TanamanViewCls = preload("res://scripts/render/TanamanView.gd")
const TerrainViewCls = preload("res://scripts/render/TerrainView.gd")
const PuingViewCls   = preload("res://scripts/render/PuingView.gd")
const AktorViewCls   = preload("res://scripts/render/AktorView.gd")
const UjungViewCls   = preload("res://scripts/render/UjungView.gd")
const RisikoViewCls  = preload("res://scripts/render/RisikoView.gd")
const TuningPanelCls = preload("res://scripts/TuningPanel.gd")
const HudCls         = preload("res://scripts/Hud.gd")

var world
var sim
var cycle
var crew
var climbers
var erosi
var babak
var suasana
var tanaman
var terrain
var panel
var hud

var ujung_atas
var ujung_bawah
var risiko

var _babak_terakhir = 1
var _fase_terakhir = Config.PHASE_DAY
var _kartu_t = 0.0        # sisa waktu kartu pergantian fase; > 0 = jeda
var _flash_potong = 0.0   # peredam supaya "regu memangkas" tidak spam

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

	# Pane dibuat lebih dulu: semua view menempelkan node-nya ke dalam
	# viewport masing-masing pane, jadi pane harus sudah ada.
	pane_atas = PaneCls.new()
	add_child(pane_atas)
	pane_atas.siapkan(Vector2(0, 0),
			Vector2(Config.PANE_LEBAR, Config.PANE_ATAS_TINGGI),
			0, Config.GROUND_Y)

	pane_bawah = PaneCls.new()
	add_child(pane_bawah)
	pane_bawah.siapkan(Vector2(0, Config.PANE_ATAS_TINGGI),
			Vector2(Config.PANE_LEBAR, Config.PANE_BAWAH_TINGGI),
			Config.GROUND_Y, Config.H)

	_pane_aktif = pane_atas

	# terrain paling dulu: z-nya eksplisit, tapi urutan tempel menentukan
	# siapa yang menang saat z sama (FasadView di atas ubin)
	terrain = TerrainViewCls.new()
	terrain.setup(pane_atas, pane_bawah, world)

	suasana = SuasanaCls.new()
	add_child(suasana)
	suasana.setup([pane_atas, pane_bawah])
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

	ujung_bawah = UjungViewCls.new(sim)
	ujung_bawah.z_index = 4
	pane_bawah.tempel(ujung_bawah)

	risiko = RisikoViewCls.new(world)
	risiko.z_index = 4
	pane_atas.tempel(risiko)

	panel = TuningPanelCls.new()
	add_child(panel)
	panel.reset_pressed.connect(_restart)

	hud = HudCls.new()
	add_child(hud)
	hud.play_pressed.connect(_on_play)

func _on_play():
	playing = true


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
	_kartu_t = Config.KARTU_DETIK
	if cycle.phase == Config.PHASE_NIGHT:
		hud.tampil_kartu("MALAM",
				"sulur merambat — bayangan aman, tempat terang menaikkan perhatian")
		return

	# fajar — hari baru
	var judul = "HARI %d" % cycle.hari
	var isi = ""
	if cycle.rawat_hari_ini():
		judul = "REGU PERAWATAN DATANG"
		isi = "zona %s dibersihkan hari ini — lindungi, timbun, atau relakan" \
				% cycle.rawat_zona
	elif cycle.inspeksi_dalam() == 0:
		judul = "HARI %d — INSPEKSI" % cycle.hari
		if cycle.rawat_hari >= 0:
			isi = "perhatian %d%% melewati ambang %d%%\nPERAWATAN dijadwalkan hari %d — zona %s" \
					% [int(round(cycle.perhatian * 100)),
					int(round(Config.AMBANG_RAWAT * 100)),
					cycle.rawat_hari, cycle.rawat_zona]
		else:
			isi = "perhatian %d%% — masih di bawah ambang %d%%, gedung dianggap wajar" \
					% [int(round(cycle.perhatian * 100)),
					int(round(Config.AMBANG_RAWAT * 100))]
	else:
		isi = "akar mencari air — inspeksi dalam %d hari" % cycle.inspeksi_dalam()
		if cycle.rawat_hari >= 0:
			isi += "\nPERAWATAN hari %d — zona %s" \
					% [cycle.rawat_hari, cycle.rawat_zona]
	hud.tampil_kartu(judul, isi)


func _try_branch():
	# pohon di dekat kursor jadi titik awal baru, kalau ada
	if sim.branch_at(_mouse_dunia()):
		return
	if sim.branch():
		return
	if sim.selected == null or not sim.selected.alive:
		hud.flash_msg("Pilih ujung dulu (klik kiri)")
	elif sim.energy < Config.COST_BRANCH:
		hud.flash_msg("Energi kurang — butuh %d" % int(Config.COST_BRANCH))
	else:
		hud.flash_msg("Batas untai tercapai")


func _process(delta):
	delta = min(delta, 1.0 / 30.0)
	var m = _mouse_dunia()
	_kamera(delta)

	# erosi berjalan juga sebelum MULAI — puing yang masih melayang setelah
	# reset harus tetap jatuh
	erosi.update(delta)

	# kartu pergantian fase menjeda simulasi; render dan kamera tetap hidup
	if _kartu_t > 0.0:
		_kartu_t = max(0.0, _kartu_t - delta)
		hud.kartu_pudar(_kartu_t)
		if _kartu_t <= 0.0:
			hud.sembunyikan_kartu()
	elif playing and not won:
		# `terlihat` = jumlah nilai vis di tiap titik yang tumbuh frame ini —
		# inilah yang menaikkan perhatian pengelola gedung
		var terlihat = sim.update(delta, is_steering, m, world, cycle.phase)
		cycle.update(delta, sim, world, terlihat)

		if cycle.phase != _fase_terakhir:
			_fase_terakhir = cycle.phase
			_kartu_fase()

		crew.update(delta, sim, world, erosi, cycle)
		climbers.update(delta, sim, world, cycle)
		if crew.dipotong > 0 or climbers.dipotong > 0:
			sim.ensure_selection(cycle.phase)
			# hukuman harus TERLIHAT: sekali per beberapa detik, umumkan
			if _flash_potong <= 0.0:
				_flash_potong = 4.0
				hud.flash_msg("Regu memangkas — tutupan zona berkurang!")
		_flash_potong = max(0.0, _flash_potong - delta)

		babak.update(delta, sim, world)
		if babak.babak != _babak_terakhir:
			_babak_terakhir = babak.babak
			if babak.babak == 2:
				hud.flash_msg("BABAK II — hijaukan TIAP zona sampai %d%%"
						% int(round(Config.ZONA_TARGET * 100)))
			else:
				hud.flash_msg("BABAK III — tumbuhkan %d pohon permanen"
						% int(Config.BABAK3_POHON))

	tanaman.sinkron()
	terrain.sinkron()

	# view menggambar dirinya sendiri; main hanya menyuapi data yang tidak
	# bisa mereka hitung: pratinjau jalur (butuh mouse) dan sakelar risiko
	risiko.visible = show_risk
	var pratinjau = []
	if playing and is_steering and sim.selected != null and sim.selected.alive:
		pratinjau = sim.selected.preview(m, 80, world)
	ujung_atas.pratinjau = pratinjau
	ujung_bawah.pratinjau = pratinjau

	# Permainan usai saat babak III tuntas (menang) atau seluruh tanaman
	# mati (kalah). `won` menahan input & simulasi untuk keduanya; HUD yang
	# membedakan lewat objek babak.
	if playing and not won and (babak.menang or babak.kalah):
		won = true

	suasana.set_night(cycle.night_amount())
	hud.refresh(sim, cycle, world, crew, climbers, babak)


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

	if event is InputEventMouseButton and event.pressed:
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
			if sim.select_near(m, cycle.phase):
				_try_branch()

	if event is InputEventKey and event.pressed and not event.echo:
		if _kunci(event, KEY_SPACE):
			_try_branch()
		elif _kunci(event, KEY_X):
			# putus sulur di kursor — menjatuhkan pemanjat di atasnya, DAN
			# merontokkan daun-daunnya: pemangkasan sukarela yang menurunkan
			# perhatian (pendamaian dua makna X, lihat Config.PERHATIAN_PANGKAS)
			var potong = sim.sever_at(_mouse_dunia())
			if potong == null:
				hud.flash_msg("Arahkan kursor ke sulur untuk memutusnya")
			else:
				var n = climbers.jatuhkan(potong.s, potong.i)
				cycle.perhatian = max(0.0,
						cycle.perhatian - Config.PERHATIAN_PANGKAS)
				sim.ensure_selection(cycle.phase)
				if n > 0:
					hud.flash_msg("Pemanjat jatuh: %d" % n)
