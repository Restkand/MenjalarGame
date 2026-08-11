extends RefCounted

# Terrain sebagai TileMapLayer (R2, docs/09). Grid satuan tetap satu-satunya
# kebenaran untuk tabrakan; petak 32 px (8 satuan) hanyalah gambarnya.
#
# Dua TileMapLayer, satu per pane, masing-masing hanya mengisi baris petak
# zonanya sendiri (atas 0..23, bawah 24..39) — kamera tiap pane memang tidak
# pernah bisa melihat zona seberang.
#
# Perubahan dunia (keruntuhan melubangi fasad, puing mengendap) sampai ke
# sini lewat world.ambil_tile_kotor(): hanya petak yang berubah yang dihitung
# dan di-set ulang. Nol kerja saat dunia diam.

const FasadViewCls = preload("res://scripts/render/FasadView.gd")
const PuingTanahViewCls = preload("res://scripts/render/PuingTanahView.gd")

# terrain enum -> kolom atlas terrain_atlas.png
const ATLAS = {
	Config.T_SKY: 0,
	Config.T_WALL: 1,
	Config.T_WINDOW: 1,   # fitur digambar FasadView; ubinnya tetap dinding
	Config.T_DOOR: 1,
	Config.T_LEDGE: 1,
	Config.T_NEIGHBOR: 2,
	Config.T_SOIL_DRY: 3,
	Config.T_SOIL_WET: 4,
	Config.T_CONCRETE: 5,
	Config.T_PIPE: 6,
	# Puing yang mengendap TIDAK diubinkan — pemetaan mayoritas 8x8
	# meratakan gundukan jadi balok kaku (playtest 11 Agustus). Ia digambar
	# per sel oleh PuingTanahView; ubinnya cukup langit di belakangnya.
	Config.T_PUING: 0,
	Config.T_AKUIFER: 8,
	Config.T_HUMUS: 9,
	Config.T_BATU: 10,
	Config.T_GORONG: 11,
	Config.T_UTILITAS: 12,
}

var _world
var _atas          # TileMapLayer pane atas
var _bawah         # TileMapLayer pane bawah
var _fasad         # FasadView — jendela, pintu, ledge
var _baris_batas = 0   # baris petak pertama milik pane bawah


func setup(pane_atas, pane_bawah, world):
	_world = world
	_baris_batas = Config.GROUND_Y / _world.PETAK

	var ts = _buat_tileset()
	_atas = _buat_layer(pane_atas, ts)
	_bawah = _buat_layer(pane_bawah, ts)

	_fasad = FasadViewCls.new(world)
	_fasad.scale = Vector2.ONE / float(Config.PPU)
	_fasad.z_index = 0
	pane_atas.tempel(_fasad)

	# tumpukan puing per sel — di atas ubin & fasad, di bawah batang sulur
	var puing_tanah = PuingTanahViewCls.new(world)
	puing_tanah.scale = Vector2.ONE / float(Config.PPU)
	puing_tanah.z_index = 0
	pane_atas.tempel(puing_tanah)

	bangun_ulang()


func _buat_tileset():
	var ts = TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	var src = TileSetAtlasSource.new()
	src.texture = load("res://aset/terrain_atlas.png")
	src.texture_region_size = Vector2i(32, 32)
	for i in range(13):
		src.create_tile(Vector2i(i, 0))
	ts.add_source(src, 0)
	return ts


func _buat_layer(pane, ts):
	var l = TileMapLayer.new()
	l.tile_set = ts
	# petak 32 px = 8 satuan: skala 1/PPU menjatuhkannya ke ruang satuan,
	# sejajar dengan semua lapis lain
	l.scale = Vector2.ONE / float(Config.PPU)
	l.z_index = 0
	l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pane.tempel(l)
	return l


# Isi ulang seluruh peta — dipanggil saat setup dan setelah world.build()
# (reset R). 2.400 set_cell, sekali jalan, bukan per frame.
func bangun_ulang():
	_atas.clear()
	_bawah.clear()
	var kolom = Config.W / _world.PETAK
	var baris = Config.H / _world.PETAK
	for ty in range(baris):
		var layer = _atas if ty < _baris_batas else _bawah
		for tx in range(kolom):
			_set_petak(layer, tx, ty)
	_fasad.queue_redraw()


func sinkron():
	var kotor = _world.ambil_tile_kotor()
	if kotor.is_empty():
		return
	for c in kotor:
		var layer = _atas if c.y < _baris_batas else _bawah
		_set_petak(layer, c.x, c.y)
	# keruntuhan bisa melenyapkan jendela/pintu/ledge — gambar fitur harus
	# mengikuti grid
	_fasad.queue_redraw()


func _set_petak(layer, tx, ty):
	var k = _world.tile_terrain(tx, ty)
	layer.set_cell(Vector2i(tx, ty), 0, Vector2i(ATLAS[k], 0))
