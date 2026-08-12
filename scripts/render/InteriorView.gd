extends Node2D

# Interior gedung (P2, docs/13 §4) — digambar HANYA saat avatar di dalam,
# menutupi fasad & rambatannya: Anda melihat isi gedung, dunia luar
# tersembunyi. Tata letaknya statis, jadi redraw hanya saat toggle.
#
# Digambar per RUN horizontal, bukan per sel — tapak 288x168 berisi puluhan
# ribu sel, tapi hanya beberapa ribu run.

var world
var avatar
var _tampil = false
var _akum = 0.0


func _init(w, a):
	world = w
	avatar = a
	visible = false


func _process(delta):
	if avatar.di_dalam != _tampil:
		_tampil = avatar.di_dalam
		visible = _tampil
		if _tampil:
			queue_redraw()
	# jaringan interior bisa bertambah (jangkar) — segarkan pelan-pelan
	if visible:
		_akum += delta
		if _akum >= 0.5:
			_akum = 0.0
			queue_redraw()


func _draw():
	var ppu = float(Config.PPU)
	var warna = {
		Config.T_RUANG: Color("26292F"),
		Config.T_LANTAI: Color("4A4E57"),
		Config.T_DINDING_DALAM: Color("3A3F49"),
		Config.T_VENT: Color("31353C"),
		Config.T_POROS: Color("1B1E23"),
		Config.T_TERALIS: Color("6B6B64"),
		Config.T_KERAN: Color("4A6B7C"),   # stasiun air (P3) — biru pipa
	}
	# latar ruang satu rect besar; run hanya untuk sel yang bukan ruang
	draw_rect(Rect2(Config.FACADE_X0 * ppu, Config.FACADE_Y0 * ppu,
			288.0 * ppu, 168.0 * ppu), warna[Config.T_RUANG])
	for y in range(Config.FACADE_Y0, Config.FACADE_Y1):
		var x = Config.FACADE_X0
		while x < Config.FACADE_X1:
			var k = world.dalam[y * Config.W + x]
			if k == Config.T_RUANG or not warna.has(k):
				x += 1
				continue
			var x0 = x
			while x < Config.FACADE_X1 \
					and world.dalam[y * Config.W + x] == k:
				x += 1
			draw_rect(Rect2(x0 * ppu, y * ppu, (x - x0) * ppu, ppu),
					warna[k])

	# jendela terlihat dari dalam — cahaya pucat, sekaligus penanda pintu
	# keluar (E). Ambil dari titik tengah jendela dunia luar.
	for w in world.windows:
		if world.at(int(w.x), int(w.y)) != Config.T_WINDOW:
			continue
		var c = Config.C_WINDOW
		c.a = 0.35
		draw_rect(Rect2((w.x - 7.0) * ppu, (w.y - 8.0) * ppu,
				14.0 * ppu, 16.0 * ppu), c)

	# jaringan yang sudah ditanam di dalam — samar, supaya simpul jangkar
	# dan jalur rambat interior terbaca
	var hijau = Config.C_LEAF
	hijau.a = 0.30
	for y in range(Config.FACADE_Y0, Config.FACADE_Y1):
		var x = Config.FACADE_X0
		while x < Config.FACADE_X1:
			if world.jaringan[y * Config.W + x] == 1:
				var x0 = x
				while x < Config.FACADE_X1 \
						and world.jaringan[y * Config.W + x] == 1:
					x += 1
				draw_rect(Rect2(x0 * ppu, y * ppu, (x - x0) * ppu, ppu),
						hijau)
			else:
				x += 1
