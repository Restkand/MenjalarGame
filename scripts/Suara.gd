extends Node

# Suara (G7) — separuh nyawa genre tenang. Semua file di aset/suara/
# disintesis prosedural (scratchpad gen_suara.gd); timpa dengan suara
# kurasi kapan saja, penyambungannya tidak berubah.
#
# Empat kanal:
#   - ambience siang & malam: dua pemutar loop yang saling silang mengikuti
#     night_amount() — telinga tahu fase tanpa melihat HUD
#   - gergaji & bor: loop yang hidup HANYA selama pekerjaannya berlangsung —
#     gergaji regu terdengar walau terjadi di luar layar, dan itu disengaja:
#     ia peringatan audio
#   - sfx satu-tembak lewat kolam pemutar bergilir

const NAMA_SFX = ["potong", "sting", "pohon", "daun", "thunk", "puing"]

var _amb_siang
var _amb_malam
var _gergaji
var _bor
var _sfx = []
var _sfx_i = 0
var _stream = {}


func _ready():
	_amb_siang = _pemutar("ambience_siang", true, -16.0)
	_amb_malam = _pemutar("ambience_malam", true, -60.0)
	_amb_siang.play()
	_amb_malam.play()

	_gergaji = _pemutar("gergaji", true, -13.0)
	_bor = _pemutar("bor", true, -15.0)

	for _i in range(5):
		var p = AudioStreamPlayer.new()
		p.volume_db = -9.0
		add_child(p)
		_sfx.append(p)
	for n in NAMA_SFX:
		_stream[n] = _muat(n, false)


# Pemutar yang masih berputar saat engine berhenti meninggalkan objek
# playback yang bocor (peringatan ObjectDB di exit) — hentikan semuanya.
func _exit_tree():
	for anak in get_children():
		if anak is AudioStreamPlayer:
			anak.stop()
			anak.stream = null


func _muat(nama, ulang):
	var s = load("res://aset/suara/%s.wav" % nama)
	if s != null and ulang:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = s.data.size() / 2   # 16-bit mono: 2 byte per frame
	return s


func _pemutar(nama, ulang, vol):
	var p = AudioStreamPlayer.new()
	p.stream = _muat(nama, ulang)
	p.volume_db = vol
	add_child(p)
	return p


# a = night_amount(): 0 siang bolong .. 1 malam penuh
func set_malam(a):
	_amb_siang.volume_db = linear_to_db(clamp(1.0 - a, 0.01, 1.0)) - 16.0
	_amb_malam.volume_db = linear_to_db(clamp(a, 0.01, 1.0)) - 13.0


func set_gergaji(aktif):
	if aktif and not _gergaji.playing:
		_gergaji.play()
	elif not aktif and _gergaji.playing:
		_gergaji.stop()


func set_bor(aktif):
	if aktif and not _bor.playing:
		_bor.play()
	elif not aktif and _bor.playing:
		_bor.stop()


func mainkan(nama):
	if not _stream.has(nama) or _stream[nama] == null:
		return
	var p = _sfx[_sfx_i]
	_sfx_i = (_sfx_i + 1) % _sfx.size()
	p.stream = _stream[nama]
	p.play()
