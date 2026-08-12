extends RefCounted

# Manajer lapis tampilan tanaman (R1, docs/09).
#
# Satu Node2D akar per pane. Sejak R5 viewport hidup di ruang piksel, jadi
# semua koordinat lokal adalah satuan simulasi x PPU.
# Untai sulur masuk ke pane atas, akar ke pane bawah — kamera tiap pane
# dijepit ke zonanya masing-masing, jadi satu untai tidak pernah perlu
# tampil di dua pane sekaligus.
#
# sinkron() dipanggil main tiap frame: untai baru mendapat SulurView,
# untai yang hilang dari sim (reset) kehilangan view-nya. Untai yang mati
# tapi masih di daftar TETAP digambar — bangkainya memang bagian dunia.

const SulurViewCls = preload("res://scripts/render/SulurView.gd")
const DaunViewCls  = preload("res://scripts/render/DaunView.gd")
const PohonViewCls = preload("res://scripts/render/PohonView.gd")

var _sim
var _root_atas
var _root_bawah
var _daun
var _pohon
var _views = {}   # strand.id -> SulurView


func setup(pane_atas, pane_bawah, sim):
	_sim = sim
	_root_atas = _buat_root(pane_atas)
	_root_bawah = _buat_root(pane_bawah)

	# pohon dulu, daun sesudahnya: sama-sama z 1, jadi urutan tempel yang
	# menaruh daun di atas tajuk pohon
	_pohon = PohonViewCls.new(sim)
	_pohon.z_index = 1
	_root_atas.add_child(_pohon)

	# penabur daun — hanya pane atas; akar tidak berdaun
	_daun = DaunViewCls.new(sim)
	_daun.z_index = 1   # di atas batang sulur
	_root_atas.add_child(_daun)


func _buat_root(pane):
	var r = Node2D.new()
	# di atas terrain (0), di bawah puing melayang (2) dan aktor (3)
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
