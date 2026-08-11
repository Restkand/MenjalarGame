extends Node2D

# Pohon — satu batch _draw() untuk semua pohon (R3, docs/09).
#
# Menggantikan penggambaran piksel akumulatif di lapisan tree yang lama.
# Batang + tajuk digambar prosedural pada resolusi PPU; sprite PixelLab
# (pohon_pangkal, docs/10 №12) baru masuk saat R6 — pohon TUMBUH tingginya,
# dan meregangkan sprite mengikuti tinggi akan merusak gambarnya.
#
# Redraw hanya selama ada pohon yang masih meninggi (atau jumlahnya berubah);
# hutan yang sudah dewasa tidak menggambar ulang apa pun.

var sim
var _n = -1
var _tumbuh = false


func _init(s):
	sim = s
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(_delta):
	var tumbuh = false
	for t in sim.trees:
		if t.tinggi < Config.POHON_TINGGI:
			tumbuh = true
			break
	# _tumbuh lama ikut memicu: frame pertama SETELAH berhenti tumbuh masih
	# perlu satu redraw penutup pada tinggi finalnya
	if sim.trees.size() != _n or tumbuh or _tumbuh:
		_n = sim.trees.size()
		_tumbuh = tumbuh
		queue_redraw()


func _draw():
	var ppu = float(Config.PPU)
	for t in sim.trees:
		var h = float(t.tinggi)
		var puncak = Vector2(t.x, t.y - h) * ppu

		# batang, menebal sedikit di pangkal
		draw_rect(Rect2((t.x - 1.0) * ppu, (t.y - h) * ppu,
				2.0 * ppu, h * ppu), Config.C_BRANCH)
		draw_rect(Rect2((t.x - 1.5) * ppu, (t.y - h * 0.33) * ppu,
				3.0 * ppu, h * 0.33 * ppu), Config.C_BRANCH)

		# tajuk: bola daun + sisi terang kiri-atas (arah matahari)
		var r = max(3.0, h / 2.8) * ppu
		draw_circle(puncak, r, Config.C_LEAF)
		draw_circle(puncak + Vector2(-r * 0.35, -r * 0.35), r * 0.45,
				Config.C_TIP)
