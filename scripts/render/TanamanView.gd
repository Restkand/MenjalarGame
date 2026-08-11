extends RefCounted

# Manajer lapis tampilan tanaman (R1, docs/09).
#
# Satu Node2D akar per pane, di-skala 1/PPU supaya koordinat piksel tampilan
# sejajar dengan lapis PixelCanvas lama yang masih 1 piksel = 1 satuan.
# Untai sulur masuk ke pane atas, akar ke pane bawah — kamera tiap pane
# dijepit ke zonanya masing-masing, jadi satu untai tidak pernah perlu
# tampil di dua pane sekaligus.
#
# sinkron() dipanggil main tiap frame: untai baru mendapat SulurView,
# untai yang hilang dari sim (reset) kehilangan view-nya. Untai yang mati
# tapi masih di daftar TETAP digambar — bangkainya memang bagian dunia.

const SulurViewCls = preload("res://scripts/render/SulurView.gd")
const DaunViewCls  = preload("res://scripts/render/DaunView.gd")

var _sim
var _root_atas
var _root_bawah
var _daun
var _views = {}   # strand.id -> SulurView


func setup(pane_atas, pane_bawah, sim):
	_sim = sim
	_root_atas = _buat_root(pane_atas)
	_root_bawah = _buat_root(pane_bawah)

	# penabur daun — hanya pane atas; akar tidak berdaun
	_daun = DaunViewCls.new(sim)
	_daun.z_index = 1   # di atas batang sulur
	_root_atas.add_child(_daun)


func _buat_root(pane):
	var r = Node2D.new()
	r.scale = Vector2.ONE / float(Config.PPU)
	# di atas lapis world (0), di bawah lapis tree/overlay milik PixelCanvas
	r.z_index = 1
	pane.tempel(r)
	return r


func sinkron():
	var hidup = {}
	for s in _sim.strands:
		hidup[s.id] = true
		if not _views.has(s.id):
			var v = SulurViewCls.new(s)
			if s.is_root:
				_root_bawah.add_child(v)
			else:
				_root_atas.add_child(v)
			_views[s.id] = v

	# sim.reset() membuat untai baru dengan id baru — view lama dibuang.
	# (id TIDAK unik lintas-reset, jadi bersih() wajib dipanggil saat restart;
	# sapuan ini hanya jaring pengaman.)
	for id in _views.keys():
		if not hidup.has(id):
			_views[id].queue_free()
			_views.erase(id)


func bersih():
	for id in _views:
		_views[id].queue_free()
	_views = {}
