extends Node2D

const WorldMapCls    = preload("res://scripts/WorldMap.gd")
const TreeSimCls     = preload("res://scripts/TreeSim.gd")
const CycleCls       = preload("res://scripts/Cycle.gd")
const CrewCls        = preload("res://scripts/Crew.gd")
const ClimberCls     = preload("res://scripts/Climber.gd")
const StructureCls   = preload("res://scripts/Structure.gd")
const PaneCls        = preload("res://scripts/Pane.gd")
const PixelCanvasCls = preload("res://scripts/PixelCanvas.gd")
const TanamanViewCls = preload("res://scripts/render/TanamanView.gd")
const TerrainViewCls = preload("res://scripts/render/TerrainView.gd")
const PuingViewCls   = preload("res://scripts/render/PuingView.gd")
const TuningPanelCls = preload("res://scripts/TuningPanel.gd")
const HudCls         = preload("res://scripts/Hud.gd")

var world
var sim
var cycle
var crew
var climbers
var structure
var canvas
var tanaman
var terrain
var panel
var hud

var pane_atas
var pane_bawah

var is_steering = false
var playing = false
var won = false
var show_risk = false
var show_frame = false
var _freeze = 0.0

# Pane yang sedang di bawah kursor. Semua perintah kamera dan semua konversi
# mouse memakai yang ini — tidak perlu klik untuk "memilih" pane.
var _pane_aktif
var _geser_drag = false


func _ready():
	randomize()

	world = WorldMapCls.new()
	world.build()

	# Pane dibuat sebelum PixelCanvas: canvas menempelkan sprite-nya ke dalam
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

	# terrain dulu baru canvas: keduanya z-eksplisit, tapi urutan tempel
	# menentukan siapa yang menang saat z sama (FasadView di atas ubin)
	terrain = TerrainViewCls.new()
	terrain.setup(pane_atas, pane_bawah, world)

	canvas = PixelCanvasCls.new()
	add_child(canvas)
	canvas.setup([pane_atas, pane_bawah])
	canvas.setup_lights(world, pane_atas)

	structure = StructureCls.new()
	structure.setup(world)

	# puing melayang & debu — hanya pane atas; blocked() menghentikan puing
	# di garis tanah, jadi ia tidak pernah masuk zona bawah
	var puing_view = PuingViewCls.new(structure)
	puing_view.scale = Vector2.ONE / float(Config.PPU)
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
	canvas.setup_lights(world, pane_atas)   # grid baru — lampu yang padam menyala lagi
	structure.setup(world)
	sim.reset()
	# id untai mulai dari 1 lagi setelah reset, jadi view lama WAJIB dibuang
	# eksplisit — sinkron() tidak bisa membedakannya dari untai baru
	tanaman.bersih()
	cycle.reset()
	crew.reset()
	climbers.reset()
	is_steering = false
	playing = false
	won = false
	show_risk = false
	show_frame = false
	_freeze = 0.0
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
	# Dibagi tingkat zoom supaya kecepatan geser terasa sama di layar: pada
	# zoom 4 satu piksel dunia memakan empat piksel layar.
	_pane_aktif.geser(v.normalized() * Config.GESER_SPEED * delta
			/ float(_pane_aktif.tingkat_zoom))


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

	# Peta cahaya dipanggang dicicil beberapa baris per frame. Selama belum
	# selesai, permainan ditahan di layar MULAI — jadi seluruh penantiannya
	# tersembunyi dan tidak pernah terlihat sebagai hitch.
	if world.bake_sibuk():
		world.bake_langkah(Config.BAKE_BARIS_MAIN if playing
				else Config.BAKE_BARIS_DIAM)
	hud.set_bake(world.bake_sibuk(), world.bake_kemajuan())

	if _freeze > 0.0:
		# jeda mikro — simulasi beku, render dan getaran tetap jalan
		_freeze = max(0.0, _freeze - delta)
	else:
		# berjalan juga sebelum MULAI, supaya uji klik-kanan bisa dilakukan
		structure.update(delta)

		if structure.wave_panjang > 0.0:
			canvas.add_shake(structure.wave_panjang * Config.SHAKE_PER_PANJANG)
			if structure.wave_index == 1:
				_freeze = Config.FREEZE_TIME
			structure.wave_panjang = 0.0
			# fasad baru saja berlubang — ujung yang kehilangan pijakan
			# mundur. SulurView melihat jumlah titiknya berubah dan membangun
			# ulang garisnya sendiri.
			if sim.retreat_unsupported(world) > 0:
				sim.ensure_selection(cycle.phase)

		if playing and not won:
			sim.update(delta, is_steering, m, world, cycle.phase)
			cycle.update(delta, sim)
			sim.spend(structure.weaken(sim, delta, cycle.phase))

			crew.update(delta, sim, world, structure, cycle.phase)
			climbers.update(delta, sim, structure, cycle.phase)
			if crew.dipotong > 0 or climbers.dipotong > 0:
				sim.ensure_selection(cycle.phase)

	tanaman.sinkron()
	terrain.sinkron()
	canvas.begin_frame()
	sim.render(canvas)
	canvas.draw_cracks(world)
	if show_risk:
		canvas.draw_risk(world)
	if show_frame:
		canvas.draw_frame(world)
	canvas.draw_crew(crew)
	canvas.draw_climbers(climbers)
	if playing and is_steering and sim.selected != null and sim.selected.alive:
		canvas.draw_preview(sim.selected.preview(m, 80, world))

	# Menang saat seluruh member gedung gagal. Menggantikan syarat coverage
	# 55%, yang sudah tidak nyambung sejak konsepnya bergeser ke pembongkaran
	# dan bar HUD diganti integritas struktur.
	if playing and not won and structure.hancur():
		won = true
	canvas.end_frame()

	canvas.set_night(cycle.night_amount())
	hud.refresh(sim, cycle, structure, crew, climbers, won)


func _input(event):
	if event is InputEventMouseButton and not event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		is_steering = false

	if event is InputEventKey and _kunci(event, KEY_V):
		show_risk = event.pressed

	if event is InputEventKey and _kunci(event, KEY_B):
		show_frame = event.pressed


func _unhandled_input(event):
	# --- kamera: selalu aktif, bahkan sebelum MULAI --------------------------
	if event is InputEventMouseButton and event.pressed:
		var p = _pane_di(event.position)
		if p != null:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				p.set_tingkat_zoom(p.tingkat_zoom + Config.ZOOM_LANGKAH)
				return
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				p.set_tingkat_zoom(p.tingkat_zoom - Config.ZOOM_LANGKAH)
				return

	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_MIDDLE:
		_geser_drag = event.pressed
		return

	if _geser_drag and event is InputEventMouseMotion:
		# dibagi zoom: geseran diberikan dalam piksel layar, kamera hidup di
		# piksel dunia. Tandanya dibalik supaya dunia ikut kursor.
		_pane_aktif.geser(-event.relative / float(_pane_aktif.tingkat_zoom))
		return

	# --- tombol yang selalu aktif -------------------------------------------
	if event is InputEventKey and event.pressed and not event.echo:
		if _kunci(event, KEY_R):
			_restart()
			return
		elif _kunci(event, KEY_TAB):
			panel.toggle()
			return

	# uji keruntuhan: tahan B lalu klik kanan pada member. Disyaratkan
	# show_frame supaya tidak bentrok dengan klik-kanan-bercabang.
	if show_frame and event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_RIGHT:
		var id = world.member_at(_mouse_dunia(), Config.MEMBER_RADIUS)
		if id >= 0:
			structure.fail_member(id)
		return

	if not playing or won:
		return

	if event is InputEventMouseButton and event.pressed:
		var m = _mouse_dunia()
		if event.button_index == MOUSE_BUTTON_LEFT:
			sim.select_near(m, cycle.phase)
			is_steering = true
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if sim.select_near(m, cycle.phase):
				_try_branch()

	if event is InputEventKey and event.pressed and not event.echo:
		if _kunci(event, KEY_SPACE):
			_try_branch()
		elif _kunci(event, KEY_X):
			# putus sulur di kursor — satu-satunya jawaban terhadap pemanjat
			var potong = sim.sever_at(_mouse_dunia())
			if potong == null:
				hud.flash_msg("Arahkan kursor ke sulur untuk memutusnya")
			else:
				var n = climbers.jatuhkan(potong.s, potong.i)
				sim.ensure_selection(cycle.phase)
				if n > 0:
					hud.flash_msg("Pemanjat jatuh: %d" % n)
