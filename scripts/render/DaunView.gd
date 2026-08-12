extends Node2D

# Penabur daun (docs/09 §5) — dimajukan dari R3 supaya sulur Line2D tidak
# pernah tampil telanjang. SATU node menggambar SEMUA daun lewat _draw();
# satu Sprite2D per daun akan jadi ratusan node.
#
# Dari gambar acuan mekanik merambat: batang dan daun adalah lapisan
# TERPISAH. Itulah yang memungkinkan tahap pertumbuhan (kepadatan daun naik
# di batang yang sama), daun layu per helai, dan pemangkasan — semuanya
# mustahil kalau daun dibakar ke tekstur batang.
#
# Sejak G8 redraw berjalan tiap frame — daun bergoyang ditiup angin, dan
# dunia yang diam sempurna terbaca mati. Tetap murah: satu canvas item.

var sim
var atlas
var _t = 0.0
var kering = false     # musim kering: rona daun mengering (TanamanView)
var _ada_bunga = false # atlas punya sel bunga (kolom 8)?


func _init(s):
	sim = s
	atlas = load("res://aset/daun_atlas.png")
	_ada_bunga = atlas != null and atlas.get_width() >= 216
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta):
	# Sejak G8 daun BERGOYANG ditiup angin, jadi redraw berjalan terus —
	# dunia yang diam sempurna terbaca mati. Ini batch satu canvas item;
	# ribuan quad per frame masih murah.
	_t += delta
	queue_redraw()


func _draw():
	if atlas == null:
		return
	# Dua lintasan: lapis BELAKANG dulu (lebih gelap, sedikit lebih besar),
	# lalu lapis DEPAN dengan variasi rona per daun. Inilah yang membuat
	# tumpukan terbaca sebagai kanopi bertingkat, bukan stiker ditempel —
	# playtest 12 Agustus.
	_gambar_lapis(0)
	_gambar_lapis(1)
	draw_set_transform_matrix(Transform2D())


func _gambar_lapis(lapis):
	var ppu = float(Config.PPU)
	for s in sim.strands:
		if s.is_root:
			continue
		for l in s.leaves:
			if int(l.get("lapis", 1)) != lapis:
				continue
			# Tahapan tunas dari gambar acuan: sepertiga umur pertama tampil
			# sebagai SPRITE KUNCUP (sel 0) — bukan daun dewasa yang
			# dikecilkan sampai jadi gumpalan — lalu "membuka" jadi daun
			# yang membesar sampai DAUN_DEWASA.
			var t = min(1.0, l.age / Config.DAUN_DEWASA)
			var v = int(l.get("varian", 0))
			var sk = l.get("skala", 1.0)
			if t < 0.3:
				v = 0
				sk *= 0.7 + 0.6 * t
			else:
				sk *= 0.55 + 0.45 * (t - 0.3) / 0.7
			var rona = l.get("rona", 1.0)
			var warna
			if lapis == 0:
				sk *= 1.12
				warna = Color(0.5 * rona, 0.62 * rona, 0.5 * rona)
			else:
				warna = Color(rona * 0.96, rona, rona * 0.94)
			# musim kering (papan acuan §6): rona bergeser ke cokelat kering
			if kering:
				warna = warna * Color(1.02, 0.82, 0.55)
			# angin (G8): tiap daun bergoyang dengan fase dari posisinya —
			# gelombang menyapu kanopi, bukan seluruh daun serempak
			var angin = sin(_t * 1.3 + l.pos.x * 0.11 + l.pos.y * 0.07) * 0.055
			var dasar = l.get("sudut", -PI / 2.0) + PI / 2.0 + angin
			# GEROMBOL (playtest kelima: "daun terasa tempelan") — tiap titik
			# daun digambar sebagai rumpun tiga helai: dua helai samping yang
			# lebih kecil dan sedikit gelap, lalu helai utama menutupinya.
			# Rumpun membaca sebagai massa dedaunan, bukan stiker tunggal.
			# Hanya daun yang sudah membuka (bukan kuncup) yang bergerombol.
			if t >= 0.3:
				for sisi in [-0.55, 0.55]:
					draw_set_transform(l.pos * ppu, dasar + sisi,
							Vector2(sk * 0.66, sk * 0.66))
					draw_texture_rect_region(atlas,
							Rect2(Vector2(-14.0, -24.0), Vector2(28.0, 28.0)),
							Rect2(v * 24, 0, 24, 24), warna * 0.88)
			# BERJANGKAR di pangkalnya: transform di titik tempel pada sumbu
			# sulur, diputar searah `sudut`, pangkal terbenam 4 px di bawah
			# batang supaya sambungannya tidak pernah terlihat putus.
			draw_set_transform(l.pos * ppu, dasar, Vector2(sk, sk))
			draw_texture_rect_region(atlas,
					Rect2(Vector2(-14.0, -24.0), Vector2(28.0, 28.0)),
					Rect2(v * 24, 0, 24, 24), warna)
			# bunga bermunculan (papan acuan §8): daun tua terpilih (hash
			# posisi, deterministik) memunculkan bunga kecil di lapis depan
			if _ada_bunga and lapis == 1 and t >= 1.0 and not kering \
					and int(l.pos.x * 7.0 + l.pos.y * 13.0) % 11 == 0:
				draw_set_transform(l.pos * ppu, dasar,
						Vector2(sk * 0.5, sk * 0.5))
				draw_texture_rect_region(atlas,
						Rect2(Vector2(-12.0, -30.0), Vector2(24.0, 24.0)),
						Rect2(8 * 24, 0, 24, 24), Color.WHITE)
