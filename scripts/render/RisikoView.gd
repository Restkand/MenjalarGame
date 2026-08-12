extends Node2D

# Peta risiko (tahan V) — petak fasad dengan vis tinggi disorot. Sejak R4
# vis hidup per petak 8x8, jadi petak itulah yang digambar: jujur terhadap
# resolusi datanya, dan jauh lebih terbaca daripada kisi titik lama.

var world


func _init(w):
	world = w
	visible = false


func _process(_delta):
	if visible:
		queue_redraw()


func _draw():
	var ppu = float(Config.PPU)
	var petak = world.PETAK
	var c = Config.C_ALERT
	var ty0 = Config.FACADE_Y0 / petak
	var ty1 = int(ceil(float(Config.FACADE_Y1) / petak))
	var tx0 = Config.FACADE_X0 / petak
	var tx1 = int(ceil(float(Config.FACADE_X1) / petak))
	for ty in range(ty0, ty1):
		for tx in range(tx0, tx1):
			var v = world.vis_at(tx * petak + petak / 2,
					ty * petak + petak / 2)
			if v <= 0.6:
				continue
			c.a = 0.14 + 0.30 * clamp((v - 0.6) / 0.4, 0.0, 1.0)
			draw_rect(Rect2(tx * petak * ppu, ty * petak * ppu,
					petak * ppu, petak * ppu), c)
