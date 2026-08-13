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
# Tempo (diluruskan playtest 12 Agustus): yang harus LAMBAT adalah
# MENJALARNYA — rasa "sabar, organik" datang dari batang yang merayap pelan,
# bukan dari jam dunia yang diulur. Hari justru dikembalikan lebih pendek
# supaya ritme kalender inspeksi tetap terasa hidup.
var GROWTH_SPEED   = 7.0    # akar
var VINE_SPEED     = 5.5    # sulur
var MAX_TURN       = 1.1
var NOISE_AMOUNT   = 0.35
var ENERGY_RATE    = 7.0
var COST_PER_PIXEL = 0.30
var COST_TIP_EXP   = 0.62
var DAY_LEN        = 28.0
var NIGHT_LEN      = 30.0

# Kartu pergantian fase: permainan berhenti sejenak, kartu besar mengumumkan
# hari/inspeksi/kedatangan regu. Ini kendaraan pengajaran utama — sistem
# perhatian dijelaskan TEPAT saat relevan, bukan lewat dinding teks tutorial.
# Klik untuk melewati.
var KARTU_DETIK = 2.8

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
# TAHAP E: regu tidak lagi spawn terus-menerus — mereka HANYA datang pada
# hari perawatan yang diumumkan kalender, sebanyak 1 + perhatian-saat-
# inspeksi * (MAX-1), bekerja di zona yang dijadwalkan, lalu pulang begitu
# zonanya bersih. MAX kembali normal karena tekanannya kini berjadwal, bukan
# banjir.
# Dirombak playtest 12 Agustus: regu MEMOTONG SULUR DI PANGKALNYA (seluruh
# bagian di atas potongan lenyap sekali gergaji), dan TIDAK pernah menyentuh
# akar — pengelola tidak melihat bawah tanah. CREW_POTONG adalah lama
# menggergaji satu sulur; cukup panjang untuk ditimbun puing atau direlakan.
var CREW_SPEED   = 36.0   # piksel per detik
var CREW_POTONG  = 2.4    # detik menggergaji sebelum sulur putus di pangkal
var CREW_MAX     = 3      # regu terbanyak dalam satu hari perawatan
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
# Lambat: mereka bekerja canggung di ketinggian, dan
# itu memberi pemain waktu bereaksi. Memutus sulur lebih awal jauh lebih murah
# daripada terlambat, karena yang hilang adalah pertumbuhan di atas potongan.
var CLIMB_CABUT   = 1.2    # detik per potongan setelah sampai di ujung
var CLIMB_MAX     = 2      # pemanjat terbanyak; hanya untuk zona ATAS
var CLIMB_PINGSAN = 8.0    # detik setelah jatuh sebelum mencoba lagi

# Pangkal sulur harus di bawah baris ini supaya bisa dicapai dari tanah.
# Sulur yang dicabangkan tinggi-tinggi jadi jaringan yang tak terjangkau —
# itulah imbalan untuk menumbuhkan jaringan terpisah, bukan satu jalur besar.
const CLIMB_BASIS     = 140.0
const CLIMB_MIN_TITIK = 80   # sulur harus cukup panjang untuk dipanjat

const CREW_JANGKAUAN  = 10.0    # sedekat apa untuk mulai menggergaji
const CREW_PANJANG    = 28      # titik per potongan PEMANJAT (regu: pangkal)
const CREW_BAND_ATAS  = 45.0    # setinggi apa di fasad regu bisa meraih

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
# Pertumbuhan daun meniru panel "Tahap Pertumbuhan" acuan (playtest 12
# Agustus): daun BENAR-BENAR tumbuh, bukan ditempel jadi.
#
#   1. Ujung yang merambat menanam TUNAS kecil tiap LEAF_SPACING satuan.
#   2. Tiap tunas membesar pelan selama DAUN_DEWASA detik — bagian muda
#      sulur selalu penuh kuncup kecil, bagian tua berdaun besar.
#   3. Batang yang hidup terus MENAMBAH daun baru di titik acak sepanjang
#      tubuhnya tiap TUNAS_TIAP detik ("daun bertambah" -> "lebat" ->
#      "mendominasi") — kerimbunan datang dari WAKTU, bukan dari taburan.
const LEAF_SPACING = 6.0
const TUNAS_TIAP   = 2.0    # detik antar daun susulan per sulur
const DAUN_DEWASA  = 30.0   # detik dari kuncup sampai ukuran penuh

# Berapa titik yang disimpan tiap untai.
const STRAND_MAX_TITIK = 1800

# Radius pencarian klik, dalam piksel dunia.
const PILIH_RADIUS  = 18.0   # memilih ujung
const PUTUS_RADIUS  = 16.0   # memutus sulur dengan X
const COST_BRANCH = 15.0
const ENERGY_MAX = 200.0
const ENERGY_START = 120.0

# Dua kata kerja aktif (G2) — keduanya saluran keluar energi, supaya energi
# kembali terasa sebagai anggaran dan pemain punya alasan menekan sesuatu:
#
# TUNAS ULANG: klik kanan di BEKAS RAMBATAN (peta tutup) menumbuhkan untai
# baru dari titik itu. Lebih mahal daripada bercabang biasa karena ia
# menghidupkan kembali wilayah yang digergaji regu tanpa merayap ulang dari
# tanah — jawaban pemain terhadap potongan-pangkal.
var COST_TUNAS = 25.0
# PERKUAT PANGKAL: sulur terpilih menebal; gergaji regu butuh DUA KALI
# durasi. Mahal — pertahanan proaktif untuk sulur yang zonanya dijadwalkan.
var COST_KOKOH = 60.0

# BANGKAI LAYU (G3): gergaji regu tidak melenyapkan bagian atas seketika —
# ia jadi bangkai kering yang menyusut dari ujung selama BANGKAI_UMUR detik
# (~satu hari penuh), dan tutupannya terkikis MENGIKUTI penyusutan itu.
# Kerugian totalnya sama, tapi pemain melihat prosesnya dan punya jendela
# menyambung lewat tunas ulang selama bekas rambatannya belum terkikis.
# X pemain tetap instan — pemangkasan sukarela memang harus langsung bersih.
var BANGKAI_UMUR = 50.0

# ---------------------------------------------------------------------------
# Air yang tidak pernah selesai (G4) — jawaban untuk "ekonomi mati setelah
# babak I": begitu akar duduk di akuifer, air dulunya beres selamanya dan
# min(Air, Cahaya) berhenti jadi keputusan.
#
# AKUIFER MENYUSUT: tiap akar yang menyedot menurunkan permukaan air
# (baris teratas kolam berubah jadi tanah lembap — kelihatan di peta).
# Banyak akar = cepat kering; akar harus mengejar permukaan yang turun,
# dan dua kolam = dua babak kehidupan air.
# 0.09 baris/detik: satu akar menguras kolam 22 baris dalam ~4 siklus hari.
var AKUIFER_SEDOT = 0.09

# MUSIM KERING: event kalender yang DIUMUMKAN dua hari sebelumnya — selama
# berlangsung, tanah lembap dihitung kering dan hanya akuifer yang memberi
# air. Datang tiap KERING_SIKLUS hari, berlangsung KERING_LAMA hari.
var KERING_SIKLUS = 6
var KERING_LAMA   = 2

const FACADE_X0 = 96
const FACADE_X1 = 384
const FACADE_Y0 = 24
const FACADE_Y1 = 192

const PHASE_DAY = 0
const PHASE_NIGHT = 1

# ---------------------------------------------------------------------------
# Split screen (angka R5, docs/09 §2)
#
# Jendela 1920x1080; dunia 480x320 satuan x PPU 4 = 1920x1280 piksel. Aset
# tampil 1:1, jadi larangan zoom bulat TIDAK berlaku lagi — Camera2D.zoom
# bebas dan mulus.
#
# Anatomi layar (docs/08 §3): DUA PITA HUD mengapit kanvas — pita atas
# (sumber daya + kalender) dan pita bawah (babak + bar zona). Pane menyusut
# memberi ruang, jadi TIDAK ADA elemen HUD di dalam wilayah kanvas; satu-
# satunya yang boleh menimpa tepi kanvas adalah band pesan sementara di
# bawah pita atas (pola "pita inspeksi" ui_kit).
const HUD_ATAS  = 40
const HUD_BAWAH = 40

const PANE_LEBAR        = 1920
const PANE_ATAS_TINGGI  = 700
const PANE_BAWAH_TINGGI = 300

const ZOOM_MIN    = 0.75
const ZOOM_MAX    = 3.0
const ZOOM_FAKTOR = 1.25    # pengali per gerigi roda mouse

# Piksel per satuan simulasi (docs/09 §2). Simulasi tidak pernah tahu tentang
# piksel — konversi hanya terjadi di lapis tampilan (scripts/render/), dengan
# mengalikan posisi satuan dengan PPU. Selama masa transisi R1-R4, node view
# di-skala balik 1/PPU supaya sejajar dengan lapis PixelCanvas lama yang masih
# 1 piksel = 1 satuan.
const PPU = 4

var GESER_SPEED = 220.0     # piksel dunia per detik saat menahan WASD

# ---------------------------------------------------------------------------
# Bake cahaya (R4, docs/09 §6)
#
# light dan vis hidup di GRID PETAK 60x40 (8 satuan per petak) — 2.400 sel,
# bukan 153.600. Satu bake penuh cuma ~600 sinar di area fasad dan selesai
# dalam hitungan milidetik, jadi seluruh mesin cicilan (bake per baris,
# tombol MULAI terkunci) DIBUANG. Boleh dipanggang ulang kapan saja.
const BAKE_LANGKAH = 2.0    # panjang satu langkah sinar
const BAKE_MAX     = 220    # langkah maksimal sebelum sinar dianggap lolos

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

# Dipakai untuk menskalakan jumlah regu dari tutupan; kondisi menang
# sesungguhnya sejak TAHAP F adalah tiga babak di bawah.
const COVERAGE_GOAL = 0.55

# ---------------------------------------------------------------------------
# Tiga babak (TAHAP F, docs/06 §6) — busur Terra Nil: bangun, penuhi
# spesifikasi, tinggalkan jejak permanen.
#
#   I   MENYUSUP      jangkau akuifer + pijakan di fasad   (kunci: ekonomi)
#   II  MENGHIJAUKAN  tutupan per ZONA, semua kuadran      (kunci: perhatian)
#   III MENETAP       pohon permanen                        (kunci: waktu)
#
# Target per zona, bukan persentase global: angka global bisa dipenuhi
# dengan menumpuk semuanya di satu sudut gelap, dan itu membuat peta vis
# tidak berarti apa-apa.
var BABAK1_PIJAK = 0.02   # tutupan minimal yang dihitung "punya pijakan"
var ZONA_TARGET  = 0.45   # tutupan yang harus dicapai TIAP kuadran
var BABAK3_POHON = 4      # pohon permanen untuk menutup permainan

# ---------------------------------------------------------------------------
# Perhatian & kalender (TAHAP D, docs/06 §4)
#
# SATU angka untuk seluruh gedung — seberapa sadar pengelola bahwa ada
# masalah tanaman. BUKAN panas per-sulur; itu dilarang hidup lagi.
#
# Naik dari: tumbuh di area terlihat (peta vis — inilah makna vis sekarang),
# jendela yang tertutup (penghuni mengeluh), rambatan di pintu (pengelola
# melewatinya tiap hari). Turun dari: waktu.
#
# Kalibrasi PERHATIAN_TUMBUH: sulur 9.6 titik/detik pada vis rata-rata 0.5
# menyumbang ~4.8 "terlihat"/detik; 0.0008 membuat satu malam penuh (34 s)
# pertumbuhan sembrono menaikkan ~0.13 — dua-tiga hari ceroboh menembus
# ambang. Tumbuh di bayangan (vis 0.2) 2,5x lebih pelan.
var PERHATIAN_TUMBUH  = 0.0008   # per satuan "terlihat" saat titik tumbuh
var PERHATIAN_JENDELA = 0.012    # per detik, saat SEMUA jendela tertutup
var PERHATIAN_PINTU   = 0.010    # per detik, saat seluruh pintu terambati
var PERHATIAN_LURUH   = 0.002    # peluruhan per detik (~0.13 per hari)

# Tempo respons dipercepat (playtest 12 Agustus: "menjalar sejak hari 1,
# tukang kebun baru muncul hari 5"): inspeksi tiap 2 hari + jeda 1 hari =
# regu pertama bisa tiba hari ke-3. Jendela reaksinya tetap satu hari penuh.
var AMBANG_RAWAT  = 0.5    # inspeksi menjadwalkan perawatan di atas ini
var INSPEKSI_TIAP = 2      # inspeksi tiap sekian hari
var JEDA_RAWAT    = 1      # perawatan datang sekian hari setelah dijadwalkan

# Eskalasi antar siklus (G6): kota makin peduli seiring hari. Tiap
# ESKALASI_TIAP hari tingkat waspada naik satu (maks ESKALASI_MAX):
# ambang inspeksi turun 6% per tingkat (Cycle.ambang_efektif), regu
# menggergaji 8% lebih cepat per tingkat (Cycle.faktor_gergaji), dan mulai
# tingkat 2 pemanjat melayani SEMUA zona, bukan hanya zona atas. Semua
# kenaikan DIUMUMKAN lewat kartu — eskalasi pun tunduk pada pilar "ancaman
# selalu diumumkan". Run 30 menit tidak pernah dua siklus yang sama.
var ESKALASI_TIAP = 4
var ESKALASI_MAX  = 4

# Setelah hari perawatan lewat, pengelola menganggap masalahnya tertangani —
# perhatian dikalikan ini (dan bobot zona ikut separuh).
var PERHATIAN_SETELAH_RAWAT = 0.5
# Memutus sulur (X) merontokkan daun-daunnya — pemangkasan sukarela yang
# menurunkan perhatian. Inilah pendamaian dua makna X di docs/06 §2.5:
# satu tombol, jawaban terhadap pemanjat SEKALIGUS cara merapikan diri
# sebelum inspeksi.
var PERHATIAN_PANGKAS = 0.04

# Empat kuadran fasad — sasaran perawatan diumumkan per zona
const ZONA_NAMA = ["BARAT ATAS", "TIMUR ATAS", "BARAT BAWAH", "TIMUR BAWAH"]

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

# Dicerahkan 12 Agu (playtest kelima: "malam terlalu gelap, sulit main di
# pane atas") — malam harus terbaca sebagai suasana, bukan penalti visual.
const C_MALAM       = Color(0.34, 0.38, 0.55)   # warna kanvas saat malam penuh
# Senja (G8, angka docs/08 §8.2): pemberhentian antara siang dan malam —
# biru ditahan lebih tinggi supaya beton mendingin tapi hijau daun tidak
# ikut mati. Tanpa tahap ini malam datang seperti sakelar.
const C_SENJA       = Color(0.72, 0.70, 0.80)
const C_LAMPU       = Color("FFD9A0")           # cahaya hangat dari dalam
# TAHAP A: radius digandakan bersama dunia, dan `texture_scale` turun dari
# SCALE (4) ke 1 — sprite tidak lagi diskalakan, jadi satu texel lampu = satu
# piksel dunia. Hasil di layar identik dengan sebelumnya pada zoom 4.
const LAMPU_RADIUS  = 28    # jangkauan, dalam piksel dunia
const LAMPU_TINGKAT = 4     # jumlah tangga falloff; kecil = makin pixel art
const LAMPU_JUMLAH  = 9     # berapa jendela yang menyala (dari 54 yang ada)

# Tinggi panel tuning yang bisa digulir. Jendela 1080, panel mulai di y=12,
# dan teks bantuan duduk di y=1034.
const PANEL_TINGGI = 930

const SUN_RAY = Vector2(-0.34, -0.94)

const T_SKY      = 0
const T_SOIL_DRY = 1
const T_SOIL_WET = 2
const T_CONCRETE = 3
const T_WALL     = 4
const T_WINDOW   = 5
const T_LEDGE    = 6
const T_PIPE     = 7    # tidak dipakai tata letak sejak TAHAP C; enum dijaga
const T_NEIGHBOR = 8
const T_DOOR     = 9
const T_PUING    = 10

# Terrain bawah tanah (TAHAP C, docs/06 §3). Pane bawah berhenti jadi pita
# kosong: tiap terrain punya fungsi DAN risikonya sendiri — atas = terlihat,
# bawah = terasa.
const T_AKUIFER  = 11   # sumber air utama; besar, jarang, dijaga beton
const T_HUMUS    = 12   # mempercepat pertumbuhan akar
const T_BATU     = 13   # penghalang keras — TIDAK bisa ditembus, putari
const T_GORONG   = 14   # koridor cepat; akar tumbuh 2x di dalamnya
const T_UTILITAS = 15   # kabel & pipa induk — MENYENTUHNYA menaikkan perhatian

# Menembus beton (docs/02 §7 — akhirnya dibangun). Klik ujung akar yang
# menempel beton: ia berhenti, energi terkuras COST_CRACK selama
# CRACK_DURATION detik, lalu terowongan pendek terbuka. Energi habis di
# tengah = kemajuan MEMBEKU, tidak hilang. Lempeng beton lebih tebal dari
# satu terowongan, jadi menjangkau akuifer butuh beberapa kali menembus —
# itulah harga air terbaik.
var COST_CRACK     = 40.0
var CRACK_DURATION = 3.0
const TEMBUS_PANJANG = 6    # panjang terowongan per sekali menembus, satuan

var HUMUS_LAJU  = 1.6    # pengali laju akar di atas humus
var GORONG_LAJU = 2.0    # pengali laju akar di dalam gorong-gorong

# Akar yang menyentuh utilitas mengganggu layanan gedung — teknisi dipanggil.
# Disalurkan lewat kanal `terlihat` yang sama dengan vis. Diukur: akar
# menyeberangi pita utilitas 7 satuan dalam ~0,6 detik, jadi 90 * 0.0008 *
# 0.6 ≈ +0.043 perhatian per lintasan — terasa, apalagi kalau beberapa akar
# bolak-balik. Menyusuri pita memanjang jauh lebih mahal lagi.
var UTILITAS_SEEN = 90.0

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

# TANAM DENGAN SENGAJA (G5): tombol T pada sulur terpilih yang ujungnya
# berdiri di puing — untai itu DIKORBANKAN (mati, berhenti jadi alat) dan
# sebatang pohon berdiri di titiknya. Mahal dua kali: energi terbesar di
# permainan + kehilangan satu untai. Berakar-pasif tetap ada sebagai jalan
# lambat; pemain aktif menutup babak III lebih cepat dan memilih SUSUNAN
# hutannya sendiri — kemenangan sebagai rangkaian keputusan, bukan timer.
var COST_TANAM = 80.0

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

const C_BANGKAI   = Color("6E6154")   # sulur mati mengering
const C_PUING     = Color("6B6B64")
const C_PUING_HL  = Color("7D7D75")   # sisi bongkah yang kena cahaya
const C_PUING_DK  = Color("55554F")   # celah antar bongkah
const C_DEBU      = Color("9A9A92")
const C_RETAK     = Color("3A3A36")

# ---------------------------------------------------------------------------
# PIVOT IV (docs/13) — P1: avatar dua moda
# ---------------------------------------------------------------------------
# Semua kecepatan/percepatan dalam SATUAN simulasi per detik.
var AVATAR_RAMBAT      = 34.0   # laju gerak di jaringan (moda MERAMBAT)
var AVATAR_JALAN       = 24.0   # laju horizontal maksimum saat LEPAS
var AVATAR_ACCEL       = 160.0  # percepatan horizontal LEPAS
var AVATAR_GRAV        = 210.0  # gravitasi LEPAS
var AVATAR_LOMPAT      = 62.0   # impuls lompat (ke atas)
var AVATAR_LOMPAT_BIAYA = 3.0   # energi per lompatan
var AVATAR_ENERGI_MAX  = 100.0
var AVATAR_REGEN       = 7.0    # pemulihan energi per detik di jaringan
var AVATAR_KURAS       = 2.5    # kikisan energi per detik saat LEPAS
var AVATAR_LAYU_ENERGI = 40.0   # energi saat bangun setelah layu
const AVATAR_TEMPEL_JEDA = 0.3  # detik sebelum boleh menempel lagi usai lepas
const AVATAR_SETENGAH_LEBAR = 1.5   # kotak badan: pos = kaki
const AVATAR_TINGGI    = 5.0
const ZOOM_AVATAR      = 2.0    # zoom awal kamera-ikut P1

# P2 (docs/13 §4): interior gedung — grid lapis kedua `dalam`
var JANGKAR_BIAYA = 25.0   # F: menanam simpul jaringan di posisi avatar
const T_RUANG         = 20  # udara interior
const T_LANTAI        = 21  # slab lantai — padat
const T_DINDING_DALAM = 22  # dinding kamar / cangkang — padat
const T_VENT          = 23  # saluran ventilasi — bisa dilalui, menembus dinding
const T_POROS         = 24  # poros lift — udara vertikal
const T_TERALIS       = 25  # gerbang statis P2 — padat sampai upgrade (P7)
const T_KERAN         = 26  # pipa bocor interior — stasiun AIR (P3)

# P3 (docs/13 §3.1 & §4): menjalar = tumbuh, dan sumber daya beralamat
var RAMBAT_TUMBUH_BIAYA = 1.2   # energi per satuan memperpanjang jaringan
var AIR_ISI             = 18.0  # isi energi/dtk di akuifer / keran bocor
var CAHAYA_ISI          = 12.0  # isi energi/dtk di bawah matahari (siang, terang)
var CAHAYA_JENDELA      = 8.0   # isi energi/dtk dekat jendela cerah interior

# Pengampunan platformer (GDD §7 rasa gerak)
const COYOTE_DETIK    = 0.12    # masih boleh lompat setelah lepas pijakan
const BUFFER_LOMPAT   = 0.12    # lompat ditekan sesaat sebelum mendarat
const LOMPAT_POTONG   = 0.45    # pengali vel.y saat tombol lompat dilepas dini

# GDD §7 + §9 (perbaikan penyimpangan #2): RUN dasar & biaya bergradasi.
# LARI sengaja DI BAWAH laju merambat (34) — §6.1: merambat harus terasa
# lebih cepat daripada LEPAS. Kuras = AVATAR_KURAS x faktor keadaan.
var AVATAR_LARI  = 32.0    # laju horizontal saat Shift ditahan (LEPAS)
var KURAS_DIAM   = 0.5     # faktor kuras saat diam           (§9: kecil)
var KURAS_LARI   = 1.8     # faktor kuras saat berlari        (§9: sedang)

# GDD §39 (perbaikan penyimpangan #1): sumber energi Room 01 = kebocoran
# katup pipa (pipa membawa air, §12). Radius "cukup dekat untuk minum".
var AIR_RADIUS = 5.0

# RK Langkah 2 (SRD §13-15): sensor perawatan Room 01 — kenop tuning
# untuk Langkah 3 (playtest tiga rute). Konsekuensi TERDETEKSI = jaringan
# BERHENTI memulihkan energi selama sensor masih waspada (opsi 2b RK:
# menyerang tepat hal yang membuat jaringan berharga).
var SENSOR_KERUCUT_DASAR = 4.0    # setengah lebar kerucut di lensa
var SENSOR_KERUCUT_LEBAR = 0.38   # pelebaran per satuan turun
var SENSOR_WASPADA       = 4.0    # detik alarm (regen mati + pindai kunci)
# Siklus pindai ala Splinter Cell (SRD §14 IDLE->SCAN, gerbang Langkah 3):
# jendela aman untuk bergerak vs jendela bahaya untuk berlindung/diam
var SENSOR_JEDA          = 3.0    # detik fase IDLE (kerucut redup, aman)
var SENSOR_PINDAI        = 2.2    # detik fase SCAN (deteksi aktif)
var KURAS_TERDETEKSI     = 2.5    # faktor kuras saat TERDETEKSI (menggigit)

# Tahap CDD §9 (perbaikan penyimpangan #3): EMPAT tahap aktif — TUNAS
# BARU, MUDA, DEWASA, TUA/KAYU (TERINFEKSI opsional menunggu cerita).
# Murni tonggak WUJUD dari total pertumbuhan; TIDAK membuka kemampuan
# apa pun (kemampuan = GDD §15, jatah Phase 7). Lesat & sprint-merambat
# era pivot DIHAPUS — tidak berasal dari kanon mana pun.
var TAHAP_MUDA   = 25.0    # tumbuh_total: TUNAS BARU -> MUDA
var TAHAP_DEWASA = 70.0    # MUDA -> DEWASA
var TAHAP_TUA    = 160.0   # DEWASA -> TUA/KAYU
var UKURAN_PENUH = 200.0   # tumbuh_total saat badan mencapai ukuran penuh
