extends Node2D

# Puing yang masih melayang + debu — satu batch _draw() (R3, docs/09 §5).
# Begitu puing diam ia jadi petak T_PUING lewat settle_many -> TerrainView,
# dan hilang dari daftar falling; node ini hanya menggambar yang bergerak.
#
# Selama ada yang melayang, redraw tiap frame memang tak terhindarkan —
# semuanya berpindah. Saat daftar kosong, satu redraw penutup membersihkan
# sisa gambar, lalu nol kerja.

var erosi
var _ada = false


func _init(e):
	erosi = e


func _process(_delta):
	if erosi.falling.is_empty() and erosi.dust.is_empty():
		if _ada:
			_ada = false
			queue_redraw()
		return
	_ada = true
	queue_redraw()


func _draw():
	var ppu = float(Config.PPU)

	# bongkah 2x2 satuan, sama seperti saat mengendap, supaya ukurannya tidak
	# berubah begitu mendarat
	for p in erosi.falling:
		draw_rect(Rect2(p.x * ppu, p.y * ppu, 2.0 * ppu, 2.0 * ppu),
				Config.C_PUING)

	for d in erosi.dust:
		var c = Config.C_DEBU
		c.a = clamp(1.0 - d.age / Config.DEBU_UMUR, 0.0, 1.0) * 0.8
		draw_rect(Rect2(d.x * ppu, d.y * ppu, ppu, ppu), c)
