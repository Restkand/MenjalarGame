extends Node

var GROWTH_SPEED   = 9.0
var VINE_SPEED     = 3.2
var MAX_TURN       = 1.1
var NOISE_AMOUNT   = 0.35
var ENERGY_RATE    = 7.0
var COST_PER_PIXEL = 0.30
var COST_TIP_EXP   = 0.62
var DAY_LEN        = 22.0
var NIGHT_LEN      = 24.0

# regu perawatan gedung
#
# Mereka tidak mencurigai apa pun — begitu menemukan tanaman dalam jangkauan,
# langsung dicabut. Prioritas sasaran memakai peta vis, jadi tumbuh di area
# terang berarti ditemukan lebih dulu. Bayangan tetap berguna tanpa jadi
# stealth. Akar di bawah tanah tidak punya nilai vis sama sekali, jadi hanya
# ditemukan dari kedekatan — bawah tanah memang lebih aman.
var CREW_SPEED = 18.0    # piksel per detik
var CREW_CABUT = 0.55    # detik per potongan
var CREW_MAX   = 4       # jumlah regu saat gedung nyaris rata

const CREW_JANGKAUAN  = 5.0     # sedekat apa untuk mulai mencabut
const CREW_CARI       = 120.0   # sejauh apa mereka mencari sasaran
const CREW_PANJANG    = 14      # titik yang dipotong tiap potongan
const CREW_BAND_ATAS  = 26.0    # setinggi apa di fasad mereka bisa meraih
const CREW_BAND_BAWAH = 18.0    # sedalam apa mereka bisa menggali

const DEAD_ZONE = 7.0
const C_WARN = Color("D8A34A")
const W = 240
const H = 160
const SCALE = 4
const GROUND_Y = 112
const MAX_STRANDS = 24
const SEED_X = 120
const LEAF_SPACING = 7.0
const COST_BRANCH = 15.0
const ENERGY_MAX = 200.0
const ENERGY_START = 120.0

const FACADE_X0 = 44
const FACADE_X1 = 196
const FACADE_Y0 = 12
const FACADE_Y1 = 112

const PHASE_DAY = 0
const PHASE_NIGHT = 1

# rangka struktural
const M_KOLOM = 0
const M_BALOK = 1

const FRAME_COLS = 4
const FRAME_ROWS = 5

# beban & keruntuhan
#
# KAPASITAS_MAX adalah angka paling menentukan di sistem ini. Dengan
# BERAT_PER_PIKSEL = 1.0, beban ruas kolom paling bawah saat gedung utuh adalah
# 199 / 301 / 301 / 199, jadi ambang harus di atas 301 atau gedung runtuh
# sendiri saat mulai. Perilaku terukur:
#
#   350  runtuh berantai besar: satu serangan menjatuhkan 20 dari 31 member.
#        Terlalu mudah — playtest menunjukkan gedung roboh setelah menjalar
#        sedikit saja.
#   420  DIPAKAI. Terkurung: satu serangan menjatuhkan satu garis kolom
#        (4 member) tanpa merambat ke tetangga, jadi butuh 4 serangan berhasil
#        untuk menang. Margin gedung utuh 28% (stress terberat 0.717).
var BERAT_PER_PIKSEL = 1.0
var KAPASITAS_MAX    = 420.0
var COLLAPSE_STEP    = 0.15

const COLLAPSE_MAX_ITER = 20
const MEMBER_TEBAL      = 1
const PUING_PER_PIKSEL  = 0.6
const PUING_GRAVITASI   = 120.0
const PUING_MAX         = 1400

# Panel dinding jatuh saat sekian dari 4 member yang mengurungnya sudah gagal.
# 3, bukan 2: dengan 2, satu serangan menjatuhkan hampir seluruh dinding
# sekaligus dan gedung terasa rapuh.
const PANEL_AMBANG   = 3

# Panel luruh baris demi baris dari atas, bukan lenyap seketika. Tanpa ini,
# dindingnya hilang dalam satu frame dan yang tersisa cuma awan titik — pemain
# tidak melihat massa apa pun jatuh.
const PANEL_LURUH    = 85.0  # baris per detik
const PUING_PER_LUAS = 14    # satu bongkah puing tiap sekian piksel persegi

# juice keruntuhan
#
# RETAK_AMBANG 0.65 dipilih supaya dua ruas kolom dalam paling bawah (rasio
# beban 301/420 = 0.717) menunjukkan retakan sepanjang 19% sejak awal. Itu
# memberi tahu pemain di mana jalur bebannya terberat tanpa satu pun teks.
# Kolom terluar (0.474) tidak menampilkan apa pun. Naikkan ke 0.75 kalau
# retakan hanya boleh muncul sebagai peringatan menjelang gagal.
var SHAKE_MAX        = 3.0    # piksel simulasi
var SHAKE_DECAY      = 0.30   # detik sampai reda
var FREEZE_TIME      = 0.08
var RETAK_AMBANG     = 0.65

const SHAKE_PER_PANJANG = 0.06
const DEBU_MIN       = 20
const DEBU_MAX       = 40
const DEBU_MAX_TOTAL = 400
const DEBU_NAIK      = 9.0
const DEBU_UMUR      = 1.1

# melemahkan struktur
#
# Kapasitas member = integritas_member * min(integritas kedua joint)
#                    * KAPASITAS_MAX
# Member hanya sekuat sambungan terlemahnya.
#
# WEAKEN_RATE adalah knob pacing utama. Dengan kapasitas 420:
#
#   KOLOM1.3 (beban 301)  joint harus turun ke 0.717  ->  5,7 detik kontak
#   KOLOM0.3 (beban 199)  joint harus turun ke 0.474  -> 10,5 detik kontak
#
# Menyerang titik paling terbebani otomatis paling cepat, dan itu mengajarkan
# jalur beban tanpa satu pun teks.
#
# Nilai lama 0.12 hanya butuh 1,2 detik dan itu terlalu mudah. Setelah satu
# garis kolom habis, tetangganya melonjak ke stress 0.955 sehingga serangan
# berikutnya cuma perlu 0,9 detik — kurva kesulitannya menurun sendiri, dan
# endgame memuncak bersamaan dengan bertambahnya regu perawatan.
var WEAKEN_RATE = 0.05

# Seberapa lebar celah yang masih bisa direntang sulur. Lubang hasil
# carve_member selebar 3 piksel, jadi titik tengahnya berjarak 2 piksel dari
# fasad di kedua sisi — nilai 2 pas untuk menyeberanginya. Kawasan yang
# benar-benar runtuh tetap tidak bisa diseberangi.
const VINE_JEMBATAN = 2

const JOINT_RADIUS       = 3.0     # jangkauan melemahkan
const JOINT_TARIK_RADIUS = 12.0    # jangkauan tigmotropisme ke joint
const JOINT_TARIK_MAX    = 0.262   # 15 derajat, batas deviasi dari arah pemain

const SUN_RAY = Vector2(-0.34, -0.94)

const T_SKY      = 0
const T_SOIL_DRY = 1
const T_SOIL_WET = 2
const T_CONCRETE = 3
const T_WALL     = 4
const T_WINDOW   = 5
const T_LEDGE    = 6
const T_PIPE     = 7
const T_NEIGHBOR = 8
const T_DOOR     = 9

const C_SKY       = Color("8B96A3")
const C_WALL      = Color("6E7784")
const C_WALL_DARK = Color("5F6874")
const C_NEIGHBOR  = Color("545C68")
const C_WINDOW    = Color("9AA4B0")
const C_LEDGE     = Color("7D7D75")
const C_DOOR      = Color("4A4E57")
const C_SOIL      = Color("4A3728")
const C_SOIL_WET  = Color("5C4433")
const C_CONCRETE  = Color("7D7D75")
const C_PIPE      = Color("4A6B7C")
const C_ROOT      = Color("A87B4E")
const C_BRANCH    = Color("7A5C3A")
const C_LEAF      = Color("5EC24A")
const C_TIP       = Color("B8E986")
const C_WARDEN    = Color("3A3F49")
const C_ALERT     = Color("C25A4A")

const C_PUING     = Color("6B6B64")
const C_DEBU      = Color("9A9A92")
const C_RETAK     = Color("3A3A36")

# debug rangka (tahan B)
const C_FRAME_OK  = Color("5EC24A")
const C_FRAME_BAD = Color("C25A4A")
const C_JOINT     = Color("B8E986")
