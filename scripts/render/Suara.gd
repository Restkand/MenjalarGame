extends Node

# PENGELOLA SUARA MINIMAL (jawaban pemilik B1/B2, 19 Agu): ambience
# gedung berjalan terus; loop situasional (gesek daun rambat, alarm,
# jantung DIBURU) dinyalakan-dimatikan main; SFX sekali-putar (lompat,
# sergap). Semua WAV sintesis prosedural di aset/suara (seed 1717).
# Keheningan total hanya saat pemain diam — sesuai putusan B2.

var _sfx = {}
var _loop = {}


func _ready():
	# verifikasi headless: playback yang hidup saat quit-after dilaporkan
	# ObjectDB leak oleh engine — di headless suara tak bermakna, bisu
	if DisplayServer.get_name() == "headless":
		return
	_muat("ambience_gedung", true, -10.0)
	_muat("rambat", true, -60.0)
	_muat("alarm", true, -60.0)
	_muat("jantung", true, -60.0)
	_muat("lompat", false, -9.0)
	_muat("sergap", false, -5.0)
	if _loop.has("ambience_gedung"):
		_loop.ambience_gedung.play()


func _muat(nama, ulang, db):
	var jalur = "res://aset/suara/%s.wav" % nama
	if not ResourceLoader.exists(jalur):
		return
	# duplicate(): jangan memutasi resource ter-cache — sumber laporan
	# "resources still in use" saat keluar
	var st = load(jalur)
	if st is AudioStreamWAV:
		st = st.duplicate()
		if ulang:
			st.loop_mode = AudioStreamWAV.LOOP_FORWARD
			st.loop_end = st.data.size() / 2
	var p = AudioStreamPlayer.new()
	p.stream = st
	p.volume_db = db
	add_child(p)
	if ulang:
		_loop[nama] = p
	else:
		_sfx[nama] = p


# hantu lama "AudioStreamWAV leaked": stream WAV yang masih terpasang
# di player saat engine keluar dilaporkan bocor — lepaskan eksplisit
func _exit_tree():
	for kumpulan in [_sfx, _loop]:
		for nama in kumpulan:
			kumpulan[nama].stop()
			kumpulan[nama].stream = null
	_sfx = {}
	_loop = {}


func sfx(nama):
	if _sfx.has(nama):
		_sfx[nama].play()


func atur_loop(nama, nyala, db = -12.0):
	if not _loop.has(nama):
		return
	var p = _loop[nama]
	if nyala:
		p.volume_db = db
		if not p.playing:
			p.play()
	elif p.playing:
		p.stop()
