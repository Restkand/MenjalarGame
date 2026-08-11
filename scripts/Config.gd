extends Node

# TAHAP A — dunia diperbesar dari 240x160 ke 480x320.
#
# Aturan penskalaan yang dipakai di SELURUH file ini: apa pun yang diukur dalam
# piksel dunia dikalikan 2, dan apa pun yang diukur dalam piksel-per-detik juga
# dikalikan 2. Dengan begitu permainan terasa persis sama seperti sebelumnya
# saat dilihat pada zoom 4x — zoom 4x mereproduksi tampilan lama.
#
# Yang TIDAK diskalakan: nilai tanpa satuan (MAX_TURN dalam radian, semua
# ambang 0..1, eksponen biaya) dan ekonomi energi. Angka 9.0 di TreeSim dan
# Structure sengaja dibiarkan — ia sudah dilepas dari GROWTH_SPEED sejak lama,
# jadi ia konstanta biaya, bukan kecepatan.
# Playtest 11 Agustus 2026: akar terasa terlalu cepat, sulur terlalu lambat.
# Keduanya didekatkan — akar turun 18 -> 12, sulur naik 6.4 -> 9.6. Sulur
# yang "sengaja lambat untuk rasa stealth" tidak berlaku lagi: rasa stealth
# datang dari kalender inspeksi (TAHAP D), bukan dari kursor yang lamban.
var GROWTH_SPEED   = 12.0
var VINE_SPEED     = 9.6
var MAX_TURN       = 1.1
var NOISE_AMOUNT   = 0.35
var ENERGY_RATE    = 7.0
var COST_PER_PIXEL = 0.30
var COST_TIP_EXP   = 0.62
# Tempo diperlambat (playtest yang sama): siang-malam lebih panjang membuat
# permainan bernafas — patokannya Terra Nil, bukan arcade.
var DAY_LEN        = 30.0
var NIGHT_LEN      = 34.0

# regu perawatan gedung
#
# Mereka tidak mencurigai apa pun — begitu menemukan tanaman dalam jangkauan,
# langsung dicabut. Prioritas sasaran memakai peta vis, jadi tumbuh di area
# terang berarti ditemukan lebih dulu. Bayangan tetap berguna tanpa jadi
# stealth. Akar di bawah tanah tidak punya nilai vis sama sekali, jadi hanya
# ditemukan dari kedekatan — bawah tanah memang lebih aman.
# CREW_PINGSAN adalah satu-satunya jawaban pemain terhadap regu: puing yang
# jatuh menimbun mereka. Sengaja sementara, bukan permanen — kalau regu bisa
# dihabisi, pemain tinggal membersihkan peta lalu bekerja tanpa lawan. Yang
# sementara justru memberi irama: runtuhkan, dapat jeda aman, mereka kembali.
# PEREDAAN SEMENTARA (playtest 11 Agustus: musuh terasa terlalu pintar dan
# tidak imbang, terutama pemanjat): CREW_MAX 4 -> 2, CLIMB_MAX 3 -> 1.
# Ini BUKAN perbaikan — sistem spawn terus-menerus ini memang dijadwalkan
# DIGANTI oleh inspeksi terjadwal di TAHAP D-E (docs/06 §4). Jangan buang
# waktu menyetel yang akan dibuang.
var CREW_SPEED   = 36.0   # piksel per detik
var CREW_CABUT   = 0.55   # detik per potongan
var CREW_MAX     = 2      # jumlah regu saat gedung nyaris rata
var CREW_PINGSAN = 6.0    # detik tertimbun sebelum bangkit lagi

const CREW_LEBAR = 6.0    # setengah lebar badan, untuk deteksi tertimpa

# Pemanjat.
#
# Regu darat hanya menjangkau pita di sekitar garis tanah, jadi seluruh fasad
# atas selama ini zona aman total. Pemanjat mengisinya — dan ia naik lewat
# SULUR PEMAIN SENDIRI. Itu yang membuatnya tidak pernah jadi pola hafalan:
# jalur musuh adalah bangunan pemain, jadi tiap keputusan menumbuhkan juga
# keputusan soal mobilitas dia.
#
# Jawabannya: putus sulur di bawahnya (tombol X). Dia jatuh, dengan harga
# pertumbuhan di atas titik potong itu ikut hilang.
# Titik sulur berjarak 1 px, jadi ini juga kecepatannya di layar. Di dunia 2x,
# sulur sepanjang itu juga punya 2x lebih banyak titik, jadi nilainya ikut
# digandakan supaya waktu tempuhnya tetap sama: 600 titik dalam 12 detik —
# sekitar setengah siang, cukup lama untuk terlihat datang dan disikapi, cukup
# cepat untuk sampai. Pada setengahnya dibutuhkan 33 detik, lebih lama dari
# satu siang penuh, sehingga pemanjat tidak akan pernah tiba di ujung.
var CLIMB_SPEED   = 50.0   # titik sulur yang dilalui per detik
# Lebih lambat daripada CREW_CABUT: mereka bekerja canggung di ketinggian, dan
# itu memberi pemain waktu bereaksi. Memutus sulur lebih awal jauh lebih murah
# daripada terlambat, karena yang hilang adalah pertumbuhan di atas potongan.
var CLIMB_CABUT   = 1.2    # detik per potongan setelah sampai di ujung
var CLIMB_MAX     = 1      # diredakan dari 3 — lihat catatan peredaan di atas
var CLIMB_PINGSAN = 8.0    # detik setelah jatuh sebelum mencoba lagi

# Pangkal sulur harus di bawah baris ini supaya bisa dicapai dari tanah.
# Sulur yang dicabangkan tinggi-tinggi jadi jaringan yang tak terjangkau —
# itulah imbalan untuk menumbuhkan jaringan terpisah, bukan satu jalur besar.
const CLIMB_BASIS     = 140.0
const CLIMB_MIN_TITIK = 80   # sulur harus cukup panjang untuk dipanjat

const CREW_JANGKAUAN  = 10.0    # sedekat apa untuk mulai mencabut
const CREW_CARI       = 240.0   # sejauh apa mereka mencari sasaran
const CREW_PANJANG    = 28      # titik yang dipotong tiap potongan
const CREW_BAND_ATAS  = 45.0    # setinggi apa di fasad mereka bisa meraih
const CREW_BAND_BAWAH = 48.0    # sedalam apa mereka bisa menggali

const DEAD_ZONE = 14.0
const C_WARN = Color("D8A34A")

# Dunia, bukan layar. Sejak TAHAP A dunia LEBIH BESAR daripada jendela dan
# ditampilkan lewat dua SubViewport berkamera sendiri, jadi Config.SCALE
# DIHAPUS — penskalaan ke layar sekarang urusan SubViewportContainer.
const W = 480
const H = 320
const GROUND_Y = 192

const MAX_STRANDS = 24
const SEED_X = 240
const LEAF_SPACING = 14.0

# Berapa titik yang disimpan tiap untai, dan berapa titik terakhir yang
# digambar ulang tiap frame ke lapisan pohon yang akumulatif.
const STRAND_MAX_TITIK = 1800
const STRAND_EKOR      = 360

# Radius pencarian klik, dalam piksel dunia.
const PILIH_RADIUS  = 18.0   # memilih ujung
const PUTUS_RADIUS  = 16.0   # memutus sulur dengan X
const COST_BRANCH = 15.0
const ENERGY_MAX = 200.0
const ENERGY_START = 120.0

const FACADE_X0 = 96
const FACADE_X1 = 384
const FACADE_Y0 = 24
const FACADE_Y1 = 192

const PHASE_DAY = 0
const PHASE_NIGHT = 1

# ---------------------------------------------------------------------------
# Split screen
#
# Angka-angka ini dipilih supaya SEMUA penskalaan jatuh di kelipatan bulat.
# Zoom pecahan membuat piksel berkedip dan buram, dan itu melanggar seluruh
# aturan render proyek ini — jadi zoom hanya boleh bilangan bulat.
#
#   zoom 2  pane atas melihat 480x192 = SELURUH zona udara (0..191)
#           pane bawah melihat 480x128 = SELURUH zona tanah (192..319)
#   zoom 4  pane atas melihat 240x96, pane bawah melihat 240x64
#
# Akibat yang disengaja: pada zoom 2 tidak ada gulir vertikal sama sekali,
# karena tiap pane pas menampilkan zonanya utuh. Gulir vertikal baru muncul di
# zoom 4. Jadi 2 = "lihat keseluruhan", 4 = "kerja teliti".
const PANE_LEBAR       = 960
const PANE_ATAS_TINGGI = 384
const PANE_BAWAH_TINGGI = 256

const ZOOM_MIN     = 2
const ZOOM_MAX     = 4
const ZOOM_LANGKAH = 2      # 2 -> 4 -> 2; hanya kelipatan bulat

# Piksel per satuan simulasi (docs/09 §2). Simulasi tidak pernah tahu tentang
# piksel — konversi hanya terjadi di lapis tampilan (scripts/render/), dengan
# mengalikan posisi satuan dengan PPU. Selama masa transisi R1-R4, node view
# di-skala balik 1/PPU supaya sejajar dengan lapis PixelCanvas lama yang masih
# 1 piksel = 1 satuan.
const PPU = 4

var GESER_SPEED = 220.0     # piksel dunia per detik saat menahan WASD

# ---------------------------------------------------------------------------
# Bake cahaya
#
# Fasad sekarang 288x168 = 48.384 piksel. Pada kisi 2 px itu 12.096 sinar, dan
# di GDScript satu sapuan penuh memakan waktu jauh lebih lama daripada satu
# frame. Jadi bake DICICIL beberapa baris per frame.
#
# Layar MULAI sudah menahan permainan sebelum dimulai, jadi cicilan pertama
# sembunyi di balik layar itu dan pemain tidak pernah melihat hitch.
#
# BAKE_LANGKAH 2.0: sinar melompat 2 unit sekali langkah, bukan 1. Ledge
# setebal 4 px tetap terdeteksi, dan biayanya separuh. Risikonya hanya tepi
# tipis tumpukan puing bisa terlewat — bayangan bocor sedikit, tidak fatal.
#
# Diukur di mesin pengembang: bake penuh 168 baris = 209 ms, jadi 1,24 ms per
# baris. Dua anggaran berbeda, karena bake dipanggil di dua keadaan:
#
#   DIAM   di balik layar MULAI, tidak ada yang lain berjalan. 16 baris =
#          20 ms per frame, seluruh fasad selesai dalam ~13 frame.
#   MAIN   saat bermain, dipicu tumpukan puing yang baru diam. 2 baris =
#          2,5 ms per frame — muat di sisa anggaran frame tanpa terasa.
#          Peta cahaya sempat basi beberapa frame; itu tidak terlihat.
const BAKE_BARIS_DIAM = 16
const BAKE_BARIS_MAIN = 2
const BAKE_LANGKAH    = 2.0    # panjang satu langkah sinar
const BAKE_MAX        = 220    # langkah maksimal sebelum sinar dianggap lolos

# ---------------------------------------------------------------------------
# Erosi — pembongkaran sebagai KOSMETIK (TAHAP B, docs/06 §5)
#
# Seluruh sistem rangka/beban/keruntuhan-berantai/pelemahan DIBUANG. Fasad
# yang lama dirambati sulur melapuk sepetak (EROSI_PETAK x EROSI_PETAK
# satuan) demi sepetak, gugur jadi puing, mengendap jadi tanah baru. Ia
# hadiah visual atas ketekunan — BUKAN jalan menang.
#
# LAPUK_LAJU: laju lapuk per detik pada petak yang penuh tertutup rambatan.
# 0.015 berarti fasad gugur setelah ~67 detik dirambati penuh — cukup lama
# untuk terasa "sudah lama di sini", cukup cepat untuk terlihat dalam satu
# sesi. Kalau pemain mulai sengaja menumbuhkan demi meruntuhkan, angka ini
# terlalu tinggi.
var LAPUK_LAJU = 0.015

const EROSI_PETAK = 4    # sisi petak lapuk, satuan
const EROSI_PUING = 3    # bongkah puing per petak yang gugur
const EROSI_DEBU  = 8    # debu per petak yang gugur

const PUING_GRAVITASI   = 240.0
const PUING_MAX         = 3000

# getaran kamera — dipakai Pane.guncang(); sejak keruntuhan berantai dibuang
# tidak ada yang memicunya, tapi mekanismenya disimpan untuk gempa/peristiwa
# nanti
var SHAKE_MAX        = 6.0    # piksel dunia
var SHAKE_DECAY      = 0.30   # detik sampai reda

const DEBU_MAX_TOTAL = 400
const DEBU_NAIK      = 18.0
const DEBU_UMUR      = 1.1

# Seberapa lebar celah yang masih bisa direntang sulur. Sejak TAHAP B satu-
# satunya lubang adalah petak erosi 4 satuan — lebih lebar dari jembatan ini,
# TAPI bekas rambatan (world.tutup) adalah pijakan kekal, jadi sulur tidak
# pernah terkurung oleh erosinya sendiri.
const VINE_JEMBATAN = 3

# Kondisi menang SEMENTARA sampai TAHAP F menggantinya dengan target per
# zona: tutupi sekian bagian fasad dengan rambatan. Angka dari rancangan
# paling awal (docs/04 §3).
const COVERAGE_GOAL = 0.55

# Pencahayaan 2D.
#
# Batasan "tanpa Light2D" DILONGGARKAN 8 Agustus 2026. Alasannya hilang: PC
# Intel HD OpenGL 2.1 berhenti jadi target sejak pindah ke Godot 4, dan Iris Xe
# menanganinya tanpa keringat.
#
# Malam tidak lagi berupa ColorRect gelap yang ditimpakan ke seluruh layar —
# itu meredupkan segalanya secara merata dan hasilnya datar. Sekarang:
# CanvasModulate meredupkan kanvas, lalu PointLight2D di jendela-jendela yang
# menyala mengembalikan cahaya secara setempat. Efeknya gedung terlihat
# DIHUNI, dan malam jadi punya bentuk, bukan cuma lebih gelap.
#
# Yang menjaga identitas visual: tekstur lampu dibuat prosedural dengan falloff
# BERTANGGA (LAMPU_TINGKAT tingkat, bukan gradien halus) dan disaring nearest,
# jadi cahayanya tetap terbaca sebagai pixel art. Gradien lembut akan merusak
# aturan "tanpa gradien" di docs/01-konteks-game.md §5.
# Nilai di bawah ini disetel dari tangkapan layar, bukan tebakan. Pada
# RADIUS 30 / ENERGI 1.1 jendelanya blown-out putih dan lingkaran cahayanya
# saling tindih sampai menutupi seluruh fasad — 30 px simulasi berarti 120 px
# di layar. RADIUS 14 membuat tiap lampu tetap milik jendelanya sendiri, dan
# ENERGI 0.55 menahannya di bawah titik jenuh sehingga warna hangatnya
# benar-benar terlihat alih-alih memutih.
var NIGHT_GELAP  = 1.0     # 0 = malam tidak menggelap sama sekali
var LAMPU_ENERGI = 0.55    # kecerahan tiap jendela yang menyala

const C_MALAM       = Color(0.20, 0.24, 0.40)   # warna kanvas saat malam penuh
const C_LAMPU       = Color("FFD9A0")           # cahaya hangat dari dalam
# TAHAP A: radius digandakan bersama dunia, dan `texture_scale` turun dari
# SCALE (4) ke 1 — sprite tidak lagi diskalakan, jadi satu texel lampu = satu
# piksel dunia. Hasil di layar identik dengan sebelumnya pada zoom 4.
const LAMPU_RADIUS  = 28    # jangkauan, dalam piksel dunia
const LAMPU_TINGKAT = 4     # jumlah tangga falloff; kecil = makin pixel art
const LAMPU_JUMLAH  = 9     # berapa jendela yang menyala (dari 54 yang ada)

# Tinggi panel tuning yang bisa digulir. Jendela 640, panel mulai di y=12, dan
# teks bantuan duduk di y=584.
const PANEL_TINGGI = 548

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
const T_PUING    = 10

# Detik hening setelah puing berhenti berjatuhan, sebelum peta cahaya
# dipanggang ulang. Tumpukan puing mengubah siluet gedung, jadi bayangannya
# ikut berubah — tapi memanggang ulang saat puing masih beterbangan cuma
# membuang tenaga.
const PUING_TENANG = 0.6

# Laju tumbuh tanaman yang berdiri di atas puing SAAT DI LUAR FASENYA. Puing
# adalah tanah subur: yang tumbuh di atasnya terus menjalar sendiri siang dan
# malam, jadi dunia selalu terlihat menghijau tanpa harus terus dikemudikan.
# Lebih pelan supaya tetap seimbang, dan pelemahan struktur tetap tergerbang
# fase sehingga pertumbuhan otomatis ini tidak merobohkan apa pun.
var PUING_LAMBAT = 0.45

# Pohon.
#
# Sulur yang bertahan cukup lama di atas puing berakar jadi pohon. Inilah satu-
# satunya hal permanen di permainan: gedung runtuh, sulur dipangkas regu, tapi
# pohon tinggal. Tanpa ini, menang berarti tidak menyisakan apa pun — ending
# seekor monster, bukan ending alam.
#
# Pembagian peran yang dijaga: pohon adalah EKONOMI, sulur dan akar adalah
# SENJATA. Pohon tidak bisa melemahkan apa pun, jadi pemain tidak bisa menang
# dengan berdiam diri menanam. Sebaliknya pohon menyelesaikan cekikan ekonomi
# min(Air, Cahaya), sehingga akar bebas berspesialisasi jadi penyerang.
# POHON_HASIL menyumbang ke air DAN cahaya sekaligus, jadi nilainya berlipat:
# ia menaikkan LANTAI dari min(Air, Cahaya), bukan salah satu sisi saja.
# Dengan dasar air 2, nilai 1.0 dan 40 pohon menghasilkan 287 energi/detik —
# bar penuh dalam 0,7 detik dan ekonomi berhenti jadi kendala. Pada 0.25 dan
# 12 pohon hasilnya sekitar 35/detik, kira-kira 2,5 kali dasar: hadiah yang
# terasa untuk meruntuhkan gedung, tanpa mematikan tekanannya.
var POHON_LAJU  = 0.25   # kemajuan berakar per detik; 1.0 = jadi pohon
var POHON_HASIL = 0.25   # tambahan air DAN cahaya per pohon

const POHON_JARAK  = 24.0   # jarak minimal antar pohon
const POHON_MAX    = 20
const POHON_TINGGI = 44     # tinggi maksimal
const POHON_TUMBUH = 6.0    # piksel tinggi per detik

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
