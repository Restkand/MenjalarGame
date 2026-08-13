# TENDRIL — konteks produksi

**GROW. HIDE. SURVIVE.** Metroidvania 2D pixel art: ujung tumbuh tanaman
merambat menjadikan sebuah gedung sebagai tubuhnya.

## Sumber kebenaran desain (SEMUA ditulis pemilik proyek) — 7 AKTIF

1. **`docs/GDD-TENDRIL.md`** — desain game menyeluruh (45 bagian).
2. **`docs/SPP-TENDRIL-SPRITE.md`** — prompt pack produksi sprite (63
   bagian): SEMUA sprite karakter wajib dari prompt di sini, urutan §62.
3. **`docs/ADR-TENDRIL-MASTER-A.md`** — keputusan art director:
   **MASTER A LOCKED** (silhouette/proporsi/daun/S-curve/palet terkunci;
   ujung tumbuh sudah di-refine jadi tunas menggulung via inpaint),
   idle/detach/attach KEEP, prioritas = AvatarView Godot → playtest
   "apakah terasa hidup saat dikendalikan". Sprite kanon di
   `aset/konsep_tendril/` (48px/frame, palet kanon; idle/detach/attach
   masih memakai ujung-daun master pra-refine — sengaja, menunggu
   putusan playtest §21).
4. **`docs/OLR-TENDRIL-LOKOMOSI.md`** — bahasa lokomotasi resmi:
   **CRAWL** (kata "walking" TERLARANG di prompt), Growing Tip Downward
   Rule, traveling body wave, Spatial Displacement Rule (frame
   digenerate BERPINDAH lalu di-re-center saat perakitan). DOD:
   "TENDRIL sedang merayap", bukan "menggulung".
5. **`docs/SRD-TENDRIL-ROOM01.md`** — single room design map (39 bagian):
   vertical slice RUANG PERTAMA (service/maintenance room 24-32 x 14-18
   tile) SEBELUM gedung besar. Area A-G, TIGA RUTE (aman lewat jaringan
   / cepat lewat lantai / rahasia lewat celah), matriks adaptasi §21,
   tutorial tanpa teks §23, urutan build §33, kriteria sukses §31, yang
   BELUM perlu ada §32. Semua room berikutnya lahir dari bahasa desain
   Room 01.
6. **`docs/EDV3-TENDRIL-SPEK-EKSEKUSI.md`** — spek eksekusi environment
   (PixelLab → Godot). Diagnosa D1-D8 §1, PALET 18 WARNA TERKUNCI §3.1
   (+aturan value: env ≤40%, amber ≤63%, TENDRIL 60-85% selalu paling
   terang), parameter terkunci §3.2, prompt PENDEK 8-20 kata §4 (buang
   abstraksi desain dari prompt!), urutan generate berantai §5
   (MASTER_ID → tileset → trim → arch → infra → prop via INPAINTING →
   decal), aturan pipa wajib flange/elbow/bracket, tugas Godot §8
   (parallax, PointLight2D, contact shadow, CanvasModulate 8FA0B8),
   QA GATES 1-6 §9, controlled strip 128 sebelum full room §10.
7. **`docs/CDD-TENDRIL-KARAKTER.md`** — desain karakter (46 bagian) +
   papan acuan visualnya. Kanon untuk SEGALA hal tentang sang Ujung
   Tumbuh: anatomi, palet hijau kanon (#102016, #19351E, #285B2B,
   #4F8F32, #79B83F, #A8D94A), warna status (kuning=terdeteksi/energi
   rendah, merah=diburu, ungu=racun, biru-putih=listrik), LIMA tahap,
   proporsi (karakter 16–32 px < manusia 32–48 px), 8 Design Rules
   (§42), north star: "Kecil sebagai individu. Besar sebagai jaringan."

**Dokumen HISTORIS** (alasan desain tersimpan, bercap `> HISTORIS` di
kepalanya masing-masing — JANGAN dipakai sebagai acuan aktif):

- `docs/MDS-TENDRIL-GERAK.md` — ditimpa istilahnya oleh OLR.
- `docs/RAD-TENDRIL-RUANG-SERVIS.md` — sebagian ditimpa EDV3 (FUNCTION
  OVER ROCK & kit modular hidup lewat EDV3).
- `docs/ECR-TENDRIL-ROOM01-KOHESI.md` — digantikan pipeline EDV3.
- `docs/EDV2-TENDRIL-ARSITEKTUR-MODULAR.md` — ditimpa operasional oleh
  EDV3 (prinsipnya dirangkum EDV3 §12).

**Rencana kerja aktif (BUKAN kanon, dibuang setelah selesai):**
`docs/RK-TENDRIL-FOKUS-BERIKUTNYA.md` — urutan Opsi A: [0] kebersihan
dokumen ✓ → [1] utang FEEL (lompat/jatuh/crawl) → [2] SENSOR jadi nyata
(sumbu kedua) → [3] playtest tiga rute (GERBANG KERAS) → [4] grading
final art (dengan sensor menyala) → [5] lipat ke kanon, buang RK.

Baca kanon aktif sebelum menyentuh mekanik/visual apa pun. 13 dokumen
era Menjalar sengaja dihapus karena membuat produksi bercabang. Kalau
sebuah keputusan tidak ada di GDD/CDD, tanyakan ke pemilik proyek —
jangan mengarang arah.

**Penyelarasan kode→CDD yang MASIH TERUTANG** (dicatat 13 Agu, belum
dikerjakan — menunggu urutan dari pemilik proyek):

- Palet avatar & jejak masih memakai warna era Menjalar (5EC24A dkk.) —
  harus pindah ke palet CDD §7.
- Tahap avatar di kode = 6 (BIJI..LEBAT); CDD §9 = 5 (Tunas Baru, Muda,
  Dewasa, Tua/Kayu, Terinfeksi-ops). Perlu pemetaan ulang nama, wujud
  (tahap 4 = kecokelatan kayu), dan strip tumbuh.
- Energi 0 saat LEPAS: CDD/papan = "bagian tersebut TERPUTUS" — jejak
  yang ditumbuhkan sesi lepas itu harusnya mengering, bukan awet.
- MERAMBAT baru bisa di jaringan; papan juga menuntut "menempel di
  permukaan" tertentu & "masuk celah kecil" (GDD §6.1, §12 material).
- Wujud saat MERAMBAT vs LEPAS harus berbeda (CDD §11 vs §14) — sekarang
  satu sprite untuk dua moda.
- State machine formal CDD §37 belum ada.

Aturan produksi dari GDD yang mengikat cara kerja:

- **§41 Urutan Development (Phase 1–8)** adalah peta jalan. Kerjakan
  SATU langkah per sesi, commit tiap langkah terverifikasi.
- **§42 Aturan Emas**: MOVEMENT → FEEL → NETWORK → EXPLORATION → STEALTH
  → ENEMY → ABILITY → WORLD → STORY. Jangan lompat.
- **§39 MVP dulu**: kalau ragu skala, kecilkan.
- **§43**: tanpa simulasi biologis literal, tanpa AI kompleks, tanpa
  procgen besar. Rasa biologis datang dari ATURAN GAMEPLAY.

## Lingkungan teknis

- **Godot 4.7 stable**, GDScript 2.0, renderer Compatibility.
- Verifikasi tanpa editor (nol keluaran selain baris versi = bersih):
  `"C:/Users/renaldi.iskandar/godot/Godot_v4.7.1-stable_win64_console.exe" --headless --path . --quit-after 180`
- Setelah menambah/mengubah PNG: jalankan sekali dengan `--import`.
- Commit memakai identitas repo-lokal (reiskand07@gmail.com), pesan
  bahasa Indonesia, satu commit per langkah terverifikasi.
- Peringatan "AudioStreamWAV leaked" lama sudah TIDAK relevan — sumber
  suaranya ikut terhapus saat bersih-bersih 13 Agu; verifikasi bersih
  = benar-benar nol keluaran selain baris versi.
- Tabrakan dihitung sendiri di grid (tanpa physics engine Godot) — sudah
  terbukti cukup dan sejalan GDD §43.
- Input dibaca terpusat di `Ruang01Main.gd` (main scene); `Config.gd`
  = AutoLoad var/const saja (nol fungsi); `Avatar.gd` tidak pernah
  membaca Input.
- Jangan menamai method `_set` (bentrok `Object._set`, gagal parse).

## Pipeline PixelLab (GDD §22–23)

Langganan Tier 1: 2000 generasi/bulan (terpakai ±55). Kunci di `.mcp.json`
(di-gitignore). Alur: prompt → generate → SELEKSI → snap palet prosedural
(skrip scratchpad) → sprite sheet → import → uji di game. Hasil AI tidak
pernah final tanpa kurasi.

Pengetahuan operasional yang sudah dibayar mahal:

- **UNDUH HASIL SEGERA setelah job selesai** — hasil MCP bisa digusur
  server jauh sebelum jendela "8 jam" resminya (crawl 13 Agu lenyap
  dalam hitungan menit; regenerasi untung murah karena seed dicatat).
  Endpoint download TIDAK mendukung HEAD — cek kesiapan lewat get_image,
  bukan probe HTTP.

- Kanvas minimal 32×32 total; strip tipis digenerate 2× lalu diperkecil
  nearest. 422 validasi TIDAK memakan kuota.
- Tekstur isi: kanvas 64×64, frasa "flat repeating texture fill …
  edge-to-edge, no border", crop tengah 32×32. Model suka menggambar
  objek berbingkai di kanvas kecil.
- `create_image_pixflux` + `color_image` (palet mini 1 px/warna, base64
  pendek) = pemaksa palet. Snap palet per-aset sesudahnya = kunci
  konsistensi. JANGAN mengetik ulang base64 panjang (korup di jalur MCP)
  — pakai `*_url` bila ada.
- **Interpolasi wujud**: `animate_image` dengan `first_frame_url` +
  `last_frame_url` + aksi pertumbuhan = 16 frame konsisten dalam SATU
  generasi (resep strip tumbuh era lama — stripnya kini hanya di
  riwayat git). Frame tengah janggal disulam frame jangkar.
- **Karakter manusia**: pipeline `create_character` v3 (side, size 64,
  lineless, low detail) + `animate_character` v3 per aksi (template
  me-retarget kerangka & bisa melarkan leher — hindari). Karakter kanon
  "Regu Perawat" tersimpan di akun PixelLab (cari via `list_characters`;
  ID tidak dicatat di repo) — basis sprite Pemangkas/Teknisi (GDD §14).
- Identitas warna dunia: kota/gedung kelabu tak jenuh, organisme
  satu-satunya yang hijau. Palet tanaman: E5F6E6, B8E986, 5EC24A, 3E8F35,
  2F6B2A + cokelat A87B4E/7A5C3A/5C4433.

## Status kode terhadap GDD §41 (jujur, per 13 Agustus 2026)

**BERSIH-BERSIH BESAR 13 Agustus (perintah pemilik proyek)**: seluruh
prototipe kota era Menjalar DIHAPUS dari working tree — main.tscn/
main.gd, 13 skrip sistem (WorldMap, TreeSim/Strand, Crew, Climber,
Cycle, Babak, Erosi, Hud, Pane, Suasana, Suara, TuningPanel), 15 view
kota, semua aset kota + folder suara. Semuanya UTUH di riwayat git
(commit terakhir sebelum bersih-bersih: `e350f92`) — kalau butuh acuan
implementasi lama (interior 6 tingkat, peta M berkabut, pintu E, regu/
pemanjat, kalender, erosi), gali dari sana, jangan tulis ulang buta.

Kode hidup sekarang = VERTICAL SLICE ROOM 01 murni, 7 skrip:
`Ruang01Main.gd` (orkestrator+input+cahaya), `Ruang01.gd` (dunia),
`Avatar.gd` (pemain — moda dobel, energi, tumbuh=gerak, metamorfosis,
kit gerak), `Config.gd` (autoload), `render/Ruang01View.gd` (Wang
renderer), `render/AvatarView.gd` (12 anim konsep_tendril),
`render/JejakView.gd` (sulur avatar).

- **Phase 1 Movement — ✓ inti** (LEPAS+MERAMBAT+transisi; belum: state
  machine formal §28). **Phase 2 Energy — ✓**. **Phase 3 Network —
  sebagian** (growth+jangkar ✓; node-objek/destruction/fast travel
  belum). **Phase 4 Exploration — di-reset ke Room 01** (rute aman/
  cepat/rahasia; sistem room formal menyusul SRD §38; interior & peta
  M lama ada di riwayat git). **Phase 5-6 Stealth/Enemies — BELUM**
  (sensor baru placeholder visual). **Phase 7 — benih metamorfosis
  ✓**. **Phase 8 World — Room 01 = fondasi bahasanya.**

## Harness uji

Pola: blok `UJI-SEMENTARA` di Ruang01Main.gd + flag `--uji` (jalankan:
`godot --headless --path . -- --uji`), DIBUANG sebelum commit. Fisika
diuji DETERMINISTIK: panggil `avatar.update(1.0/60, input, world)`
langsung dalam loop — headless berjalan ratusan fps, jangan mengukur
per-frame layar. Room 01: 15 asersi tata letak pernah dipakai di sini
(lihat riwayat commit `2bb8172`) — pola siap dihidupkan lagi.

## Langkah berikutnya

**Dikemudikan `docs/RK-TENDRIL-FOKUS-BERIKUTNYA.md` (Opsi A).**
Langkah 0 (kebersihan dokumen) SELESAI 14 Agustus: kanon aktif 11 → 7,
empat dokumen bercap HISTORIS, bagian ini dikompres (sejarah pass demi
pass Room 01 hidup di dokumen historis + riwayat git).

**Langkah 1 (utang FEEL) DIKERJAKAN 14 Agustus — menunggu mata pemilik:**

- JATUH v2 (seed 1062) MENANG telak: 4 frame loop tubuh MEMBUNGKUK
  rendah, ujung terselip di depan bawah, daun tersapu — frame tegak
  pembuka dibuang supaya loop konsisten.
- LOMPAT: generasi v2 (seed 1061) squash-nya tidak keluar per-frame →
  diselamatkan lewat KURASI SUSUN-ULANG: strip 6f = jongkok kompak
  (ditahan 2f) → master → meregang → puncak menyala (beku selama naik).
  Teknik baru yang terbukti: frame satu generasi boleh disusun ulang
  jadi urutan aksi — identitas tetap konsisten.
- CRAWL v3 kanan+kiri (seed 1063/1064): DITOLAK kurasi — dua-duanya
  justru lebih menggulung tegak dari versi lama yang sudah lulus.
  Crawl lama DIPERTAHANKAN; utang gulung kecil tetap tercatat. Pelajaran:
  larangan "never coil upright" di teks aksi TIDAK dipatuhi model —
  jangan reroll crawl lagi tanpa teknik baru (mis. pin frame rendah).
- Boncengan lunas: JejakView pindah ke hijau TENDRIL EDV3 §3.1
  (6FBF3E/A8E85C, sama dengan jaringan benih — "makhluk & pertumbuhan-
  nya"); warna Menjalar (C_BRANCH/C_LEAF) tidak dipakai lagi.
- Idle/detach/attach & bahasa-OLR merambat sengaja TIDAK disentuh.
- DOD Langkah 1 dinilai MATA PEMILIK in-game: lompat = usaha, mendarat
  = menerima beban. Lolos → RK Langkah 2 (sensor jadi nyata).

Sesudahnya sesuai RK: [2] sensor jadi nyata (tiga state SRD §13, warna
kuning CDD §7, konsekuensi termurah, TANPA musuh) → [3] playtest tiga
rute = GERBANG KERAS → [4] grading final art dengan sensor menyala →
[5] lipat ke kanon & buang RK.

**Keadaan teknis yang perlu diketahui sesi berikutnya:**

- Animasi avatar: 12 strip di `aset/konsep_tendril/` (idle, merambat,
  kanan/kiri 11f crawl berpindah + re-center, putar_kiri/kanan 7f seed
  1051/1052, lompat 7f play-once ~14 fps beku di ujung, jatuh 5f loop,
  darat 5f play-once 0.18 dtk bergerbang `_udara_t > 0.12`, lepas,
  detach, attach). Semua digenerate dari master base64 dengan teks aksi
  ber-jangkar — JANGAN dua base64 panjang dalam satu panggilan (selalu
  korup). Prioritas state AvatarView: transisi > belok > darat > udara >
  gerak > idle; anim udara non-berarah (dicermin `hadap`).
- Room 01 memakai pipeline EDV3 penuh: tileset Wang beton (MASTER) +
  baja dirantai `base_tile_id`; atlas terindeks kunci-sudut, renderer
  marching-squares (massa 1-tile → fallback slot 15); panel = patch
  inpaint fase-selaras (x%32==4, y%32==8); PointLight2D bertangga +
  CanvasModulate 8FA0B8 + cahaya hijau ikut avatar; seed+prompt di
  `aset/ruang01/_gen_params/` (tanpa ID, keputusan pemilik).
- Jebakan mahal yang SUDAH dibayar: endpoint /image tileset = pratinjau
  dekoratif (iris dari `spritesheet_url` metadata); semantik Wang
  "lower" = PADAT (verifikasi empiris); `Vector2i` menelan pecahan
  (floori dulu); `Select-Object -First` membunuh proses di pipe; pita
  value ditegakkan di perakit atau material runtuh ke warna latar.
- Risiko tercatat: pemisah beton-vs-latar di bidang lebar masih tipis —
  nilai final in-game DENGAN SENSOR MENYALA (RK Langkah 4); pijakan
  wajib ≥2× luminance dinding di belakangnya (signifier, tidak boleh
  ditunda); tombolnya `lo` pita beton di gen_ruang01_v3.gd scratchpad.
- Utang kit environment: decal 1/12, varian center tile 0/3 — bayar di
  RK Langkah 4 kalau sempat.
