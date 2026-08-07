extends Reference

# Jam siklus siang-malam.
#
# File ini dulu bernama Warden.gd dan memegang seluruh sistem stealth: kerucut
# pandang, panas per-sulur, kecurigaan, dan pemangkasan saat fajar. Semuanya
# dihapus saat konsep bergeser ke pembongkaran. Stealth menuntut pemain lemah
# dan tersembunyi; pembongkaran menuntut sebaliknya, jadi keduanya saling
# menarik ke arah berlawanan.
#
# Antagonis baru (regu perawatan yang mencabut tanaman dan memanjat sulur
# pemain) dibangun sebagai sistem terpisah, bukan penerus file ini.

var phase = Config.PHASE_DAY
var t     = 0.0


func reset():
	phase = Config.PHASE_DAY
	t = 0.0


func phase_len():
	return Config.DAY_LEN if phase == Config.PHASE_DAY else Config.NIGHT_LEN


func progress():
	return t / phase_len()


# 0 saat siang bolong, 1 saat malam penuh. Dipakai untuk menggelapkan layar.
func night_amount():
	if phase == Config.PHASE_NIGHT:
		return min(1.0, t / 2.5)
	return max(0.0, 1.0 - t / 2.5)


func update(delta, sim):
	t += delta
	if t < phase_len():
		return
	t = 0.0
	phase = Config.PHASE_NIGHT if phase == Config.PHASE_DAY else Config.PHASE_DAY
	sim.ensure_selection(phase)
