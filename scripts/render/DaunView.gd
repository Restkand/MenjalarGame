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
# queue_redraw() hanya saat ada yang berubah: jumlah daun bergeser (lahir,
# dipangkas regu, rontok saat mundur) atau masih ada daun muda yang sedang
# membesar. Sulur dewasa yang diam tidak menggambar ulang apa pun.

var sim
var atlas
var _n = -1


func _init(s):
	sim = s
	atlas = load("res://aset/daun_atlas.png")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(_delta):
	var n = 0
	var muda = false
	for s in sim.strands:
		if s.is_root:
			continue
		n += s.leaves.size()
		if not muda:
			for l in s.leaves:
				if l.age < Config.DAUN_DEWASA:
					muda = true
					break
	if n != _n or muda:
		_n = n
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
			# BERJANGKAR di pangkalnya: transform di titik tempel pada sumbu
			# sulur, diputar searah `sudut`, pangkal terbenam 4 px di bawah
			# batang supaya sambungannya tidak pernah terlihat putus.
			draw_set_transform(l.pos * ppu,
					l.get("sudut", -PI / 2.0) + PI / 2.0,
					Vector2(sk, sk))
			draw_texture_rect_region(atlas,
					Rect2(Vector2(-14.0, -24.0), Vector2(28.0, 28.0)),
					Rect2(v * 24, 0, 24, 24), warna)
