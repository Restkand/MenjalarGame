# TENDRIL — konteks produksi

**GROW. HIDE. SURVIVE.** Metroidvania 2D pixel art: ujung tumbuh tanaman
merambat menjadikan sebuah gedung sebagai tubuhnya.

## Sumber kebenaran desain (SEMUA ditulis pemilik proyek) — 8 AKTIF

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
8. **`docs/SRD-TENDRIL-RUANG00-LAB.md`** — RUANG 00: Lab Botani
   (kelahiran + tutorial 4 mekanik tanpa teks). Putusan pemilik 15 Agu:
   dokumen lab-nya (semula kandidat Room 01) dijadikan ruangan PEMBUKA,
   posisi = ruang tersembunyi bertetangga Room 01 (lorong keluar lab →
   ruang servis; dari sisi Room 01 tersamar, kandidat: gril ventilasi /
   ujung koridor drain §19), ukuran diciutkan 60×20 → ±32×14 (GDD §39).
   Aturan permukaan §5 (kaca mati, baja menolak, basah cepat) sejalan
   matriks SRD Room 01 §10. Grow light JANGAN ungu (bentrok status
   racun CDD §7). Prompt di dalamnya = referensi niat pra-EDV3 — tulis
   ulang lewat EDV3 §4 saat produksi. DIPRODUKSI SETELAH gerbang RK
   Langkah 3 lolos; amendemen SRD Room 01 §19/§38 menunggu pemilik.

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
dokumen ✓ → [1] utang FEEL ✓ → [2] SENSOR ✓ → [3] playtest tiga rute
(GERBANG) → [4] grading final art → [5] lipat ke kanon, buang RK.
**`docs/RK2-TENDRIL-LOOP.md` (disahkan 15 Agu, DISISIPKAN sebelum
Langkah 4/5)**: verdict gerbang putaran 2 = teknis lulus, LOOP bolong
(4 temuan pemilik = halaman GDD yang belum dibangun). Tahapan: [A]
material bicara (§12: lembap/retak/beton, beton menolak tumbuh;
v3 15 Agu: MATERIAL DILUKIS — aset/ruang01/peta_material.png = kanvas
64x36 (1px = 1 sel 4-satuan; #00A000 lembap #A05000 retak #0050A0
air), SATU sumber kebenaran mekanik+visual, blob Wang dual-grid dari
sel lukisan; pemilik bebas melukis ulang PNG-nya di editor apa pun;
atlas 5 material 128x160 = 16 kunci + 3 varian interior bertepi
identik anti-monoton; lembar tileset web tersimpan di
aset/ruang01/tileset_map) →
[B] jangkar berdampak (§6.2: node terlihat + aura regen 2x) → [C]
musuh pertama PEMANGKAS (§14: KARAKTER BARU — bukan Regu Perawat lama,
putusan pemilik; kandidat dikurasi dulu; patroli lantai, hanya lihat
moda LEPAS, memotong pertumbuhan pemain, jaringan benih aman) → [D]
tujuan ruangan (bulb dorman dinding kanan + kabar HUD). Lalu playtest
loop → baru Langkah 4/5 RK lama.

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
- DOD Langkah 1: LOLOS 14 Agustus dengan catatan ketidakpuasan pemilik
  (utang FEEL belum nol — jangan dianggap lunas total).

**Langkah 2 (sensor jadi nyata) DIKERJAKAN 14 Agustus:**

- `scripts/Sensor.gd`: tiga state SRD §13 di grid — AMAN / CURIGA
  (tersamar: moda MERAMBAT = kamuflase daun) / TERDETEKSI (terbuka).
  Kerucut menghadap bawah (Config.SENSOR_KERUCUT_DASAR 4.0 + LEBAR 0.38
  per satuan, berhenti y=118) + raycast garis-pandang di grid (beton
  memutus — bayangan tangga & koridor drain jadi tempat sembunyi
  sungguhan).
- Konsekuensi = opsi 2b RK yang "lebih menarik": TERDETEKSI menyalakan
  kewaspadaan Config.SENSOR_WASPADA 4 dtk; selama waspada `avatar.
  regen_mati` — jaringan MENOLAK memulihkan energi (gate di _rambat).
  Ketahuan lalu sembunyi ≠ langsung boleh pulih.
- Bahasa tanpa teks (SRD §23): lampu sensor berdenyut kuning per state,
  cincin kuning kanon CDD §7 di avatar (terang=TERDETEKSI, redup=
  waspada, samar=CURIGA), dan ZONA kerucut digambar dari angka Config
  yang SAMA dengan logika (signifier jujur — bukan cahaya palsu D6;
  pendarnya tetap PointLight2D).
- DOD RK terverifikasi deterministik (blok uji sudah dibuang): lantai
  terbuka & puncak blok = TERDETEKSI; merambat plafon = CURIGA saja;
  koridor drain = AMAN; balik tangga = AMAN via LoS; regen berhenti
  saat waspada & pulih sesudahnya.

**Penyimpangan GDD #1-#3 DIPERBAIKI (14 Agustus, atas audit &
perintah pemilik)** — audit lengkap lihat riwayat percakapan/commit:

- #1 (§39 MVP): Room 01 kini punya SUMBER ENERGI — kebocoran katup pipa
  dinding kanan (`Ruang01.air_pos`, minum via `dekat_air` + AIR_ISI
  18/dtk, radius Config.AIR_RADIUS 5) — sekaligus alasan-kembali §34;
  dan NODE terpasang di jaringan rumah (`node_pos`, bola hijau =
  checkpoint kelahiran §6.2). Tetesan + genangan digambar di view.
- #2 (§7/§9): RUN dasar = tahan Shift saat LEPAS (AVATAR_LARI 32 —
  sengaja DI BAWAH merambat 34, §6.1); biaya bergradasi: diam ×0.5 <
  jalan ×1.0 < lari ×1.8 (KURAS_DIAM/KURAS_LARI), lompat & tumbuh
  tetap bertarif sendiri.
- #3 (progression): LESAT & SPRINT-MERAMBAT DIHAPUS (bukan kanon;
  kemampuan = GDD §15 jatah Phase 7; kode di riwayat git). Tahap
  dipetakan ulang ke CDD §9: TUNAS BARU → MUDA (25) → DEWASA (70) →
  TUA/KAYU (160), murni tonggak wujud dari tumbuh_total, TANPA membuka
  kemampuan; pengali energi/biaya per tahap ikut dicabut. Input dict
  kini {arah, lompat, lompat_tahan, lari, masuk}.
- Utang yang SENGAJA belum: wujud sprite per tahap CDD (art), #4-#9
  audit (semantik state → RK Langkah 5; kamuflase-berdaun; upacara
  kematian; §38 grading → Langkah 4; struktur folder). UI LUNAS 15 Agu:
  `render/Hud.gd` = HUD minimal GDD §31 di CanvasLayer (ENERGI bar 10
  sel + MODA + VISIBILITAS TERSEMBUNYI/TERSAMAR/WASPADA/TERDETEKSI,
  warna CDD §7, memudar saat nominal, bingkai kuning saat regen ditolak,
  kedip gelap konsumen event layu_baru; ability [Q]/[E] SENGAJA belum —
  Phase 7). Bar mini di atas kepala avatar dicabut dari AvatarView.
  UX 15 Agu (permintaan pemilik "tidak paham memencet apa"): AUTO-TEMPEL
  DIHAPUS — menempel kini DISENGAJA gaya tangga (sentuh garis + W/S;
  `avatar.bisa_tempel` = petunjuk kontekstual di HUD "[W/S] MERAMBAT" /
  "[SPASI] LEPAS"); LEPAS murni platformer di beton tileset. MENU JEDA
  `render/MenuJeda.gd` (ESC buka/tutup, R ulang; main process ALWAYS +
  anak PAUSABLE, logika _process dipagari paused) sekaligus kartu
  KENDALI. Terverifikasi deterministik (blok uji dibuang).

**Gerbang Langkah 3, putaran 2 — SIAP DIUJI (15 Agu)**: bot
deterministik membuktikan tiga rute tertempuh pasca paket beban:
AMAN energi utuh 100 (jaringan penuh, lantai→dinding kiri→plafon→
dinding kanan), CEPAT sisa 58 (lari+lompat celah+tangga peti sampai
x≥210), RAHASIA sisa 84 (celah→drain→tempel garis tersembunyi→tumbuh
naik cerobong, muncul di 216,112). Blok uji dibuang. Yang TIDAK bisa
diuji bot = inti gerbangnya: apakah memilih rute TERASA keputusan
(Splinter Cell) — menunggu playtest pemilik.

**Gerbang Langkah 3, putaran 1 (14 Agustus)**: putusan pemilik —
"memilih rute HARUS terasa seperti keputusan; ini stealth game
terinspirasi Splinter Cell" → sumbu stealth dipertajam sesuai resep RK
(naikkan konsekuensi, jangan tambah rute):

- SIKLUS PINDAI (SRD §14 IDLE→SCAN): sensor tidak lagi awas 24 jam —
  IDLE 3 dtk (kerucut redup alpha .03, TIDAK mendeteksi) ↔ SCAN 2.2
  dtk (kerucut menyala, deteksi aktif). Rute cepat = puzzle waktu.
  Kenop: SENSOR_JEDA / SENSOR_PINDAI.
- DIAM = TERSEMBUNYI (GDD §13 literal; penyimpangan audit #5 lunas):
  diam di jaringan dalam kerucut saat SCAN = AMAN penuh; bergerak di
  jaringan = CURIGA. Splinter Cell: kesabaran adalah senjata.
- Konsekuensi menggigit (opsi 1+2 RK digabung): TERDETEKSI = kuras
  ×2.5 (KURAS_TERDETEKSI) + jaringan menolak memulihkan + alarm
  MENGUNCI sensor terus memindai selama waspada + grading ruangan
  bergeser hangat (8FA0B8 → A6987F) lalu pulih.
- Kerucut kini 4 tingkat alpha di view (idle/scan/curiga/terdeteksi) —
  jendela aman vs bahaya terbaca tanpa teks.

**KARAKTER PLAYER BARU TERKUNCI (14 Agustus)**: Master A dinyatakan
pemilik "sangat jauh dari harapan" — melanggar CDD §2 kalimat pertama
(pemain mengendalikan KEPALA SULUR MUDA, bukan seluruh tanaman). CDD
menang atas kunci ADR. Kandidat pixflux saya DILEWATI — pemilik membuat
karakternya SENDIRI via PixelLab Create Character: makhluk sulur mungil
kepala bulat bermata putih besar, daun di ubun-ubun, tubuh sulur
menggulung seperti pegas, dua lengan sulur kecil, 32px, 8 arah
(timur/barat terpisah bawaan — aturan MDS anti-flip terpenuhi).
Tersimpan di akun PixelLab (cari via `list_characters`; ID tidak
dicatat di repo). Amendemen CDD §40 disadari: mata BOLEH (papan acuan
pemilik bermata); ekspresi = wajah + bahasa tubuh + daun sekaligus.

Struktur aset karakter:
- `aset/player/` — karakter pemain: master.png (timur), rotasi/ 8 arah,
  semua di-snap palet CDD §7 + putih mata.
- `aset/konsep_tendril/` — Master A PENSIUN, diarsipkan sebagai calon
  aset NPC (putusan pemilik). AvatarView MASIH memakainya sampai set
  animasi player lengkap.

Pipeline animasi player: `animate_character` mode v3 (deskripsi aksi
custom, ~1 generasi/arah untuk 32px; HINDARI template humanoid —
retarget kerangka merusak anatomi non-humanoid). Idle 2 arah SELESAI
(idle_timur 7f + idle_barat cermin). CRAWL timur+barat SELESAI dan
DIKUNCI di **bedah v7** (commit 2038ca8): body gelombang dari
animasi akun "crawl_timur" + bedah wajah deterministik per frame
(sapu seluruh tanda interior 3 pass, lalu SATU mata hitam 2x3 +
kilau putih dijangkarkan ke cakram kepala pada fraksi tetap 42%
tinggi / 3 px dari tepi depan; barat = cermin). PUTUSAN PEMILIK
15 Agu: v7 = versi terbaik; TIGA perbaikan lanjutan DITOLAK semua
(susun prosedural penuh; tutup-outline datar; busur bola + tanjakan
landai — skrip di scratchpad bedah_badan/bedah_sambung). JANGAN
bedah crawl lagi tanpa arahan baru pemilik. Utang kosmetik yang
DITERIMA sadar: kepala mepet tepi kanan kanvas (baris hijau tanpa
outline) + massa gelap di bawah kepala (bukan gelombang tipis murni).
JUMP/FALL/LAND SELESAI 15 Agu (LOLOS pemilik): bahasa PEGAS —
lompat_pegas 6f (squash gepeng 2f -> master -> meregang -> puncak
beku), jatuh_pegas 6f loop goyah, darat_pegas 5f (splat -> bangkit
-> settle -> master). Kurasi susun-ulang lintas-generasi; splat
mentah f04 RUSAK dari generator (hijau meluber keluar kanvas) —
diganti f05 blob bermuka; lengan lompat dirapikan; SEMUA hijau
mentah kolom tepi ditutup outline (audit 0 luka). Frame mentah
utuh di akun (grup lompat_pegas/jatuh_pegas/darat_pegas).
**AvatarView SUDAH DIALIHKAN ke aset/player 15 Agu** (rect 32px,
kaki sejajar posisi lama): idle/crawl BERARAH digambar apa adanya,
strip pegas dicermin hadap; belok/detach/attach nonaktif otomatis
(pagar has()) sampai strip player-nya ada. Master A resmi pensiun
dari view.
MERAMBAT SELESAI 15 Agu sebagai WUJUD GANDA (putusan pemilik —
membayar sebagian utang CDD §11 vs §14): di jaringan pemain BUKAN
makhluk imut — wujud TANAMAN MURNI tanpa wajah. Bentuk final =
UNTAIAN DAUN seed 1222 (pixflux 64x32 lebar-pendek — trik kanvas
memaksa komposisi mendatar; gumpalan daun MEMBUNGKUS garis jaringan,
ujung menggulung memimpin; view menggambar berpivot DI garis dengan
rect terpusat). Iterasi penting: bentuk sulur-S tegak (seed 1201)
sempat dipasang lalu DITOLAK pemilik — "terbaca tentakel berjalan,
tidak natural"; pelajaran: wujud rambat harus MENYATU dengan garis,
bukan berdiri di atasnya. Semua kandidat/alasan di
aset/player/_gen_params/wujud_rambat.json.
MODEL FINAL 15 Agu (kritik pemilik atas strip untai yang "seperti
cacing meluncur"): TANAMAN TUMBUH, TIDAK BERPINDAH — arsitektur
"ujung = avatar, tubuh = jejak":
- avatar rambat = rambat_ujung 4f, tunas ~10px diiris dari untai
  seed 1222, berpivot DI garis, sudut 8-arah kontinu lerp_angle
  (sprite sekecil ini bebas rotasi janggal);
- tubuh = JEJAK DAUN yang DITANAM Avatar tiap RAMBAT_DAUN_JARAK
  (avatar.jejak_daun ring RAMBAT_DAUN_MAX, digambar DaunView baru;
  gumpalan diiris dari untai yang sama, gelap SATU tangga — ujung
  hidup selalu paling terang, EDV3 §3.1) — ruangan menghijau di
  jalur yang dilalui, "menyatu dengan ekosistem" pemilik;
- diam = rambat_ujung_senyap (gelap satu tangga = SENADA gumpalan
  tertanam -> pemain lenyap ke dedaunan yang ia tanam sendiri);
- DENYUT TUMBUH di Avatar._rambat (julur-cengkeram sin^0.7,
  Config.RAMBAT_DENYUT/RAMBAT_DENYUT_DASAR, rata-rata DINORMALKAN
  tetap AVATAR_RAMBAT — GDD §6.1 aman) = jawaban "meluncur di es".
Terverifikasi deterministik (blok uji dibuang): rata-rata denyut
±15% RAMBAT, 67 gumpalan / 108 satuan. Strip untai besar DIHAPUS;
grup climb imut akun arsip. Penggelapan tangga-palet = resep GRATIS
(iris_ujung di scratchpad).
WUJUD AKHIR RAMBAT (putusan pemilik 15 Agu): saat merambat TIDAK ADA
sprite avatar sama sekali — pemain = pertumbuhan itu sendiri (kepala
jejak daun DaunView + pendar cahaya = penanda posisi; state
"rambat_sembunyi" di view sengaja tanpa gambar, jumbai/ujung
dihapus). TRANSFORMASI DETACH/ATTACH SELESAI (izin boros pemilik,
2 generasi): attach.png = makhluk meleleh jadi gundukan daun lalu
pudar (2 frame ekor alfa 70/35%; Avatar menanam gumpalan NYATA di
titik melebur = serah-terima mulus), detach.png = menyembul liar
dari dedaunan (frame awal pudar 50%); grup akun ubah_menempel/
ubah_melepas; durasi 0.25/0.30 = ujung atas rentang CDD §15-16
(kalau pemilik ingin morph lebih dramatis, angkanya di AvatarView —
melampaui rentang CDD = keputusan pemilik). Sisa set: belok
(opsional).
SPP perlu revisi pemilik (ditulis untuk Master A). Gerbang RK
Langkah 3 putaran 2 tetap antri setelah karakter berdiri.

Sesudahnya sesuai RK: [2] sensor jadi nyata (tiga state SRD §13, warna
kuning CDD §7, konsekuensi termurah, TANPA musuh) → [3] playtest tiga
rute = GERBANG KERAS → [4] grading final art dengan sensor menyala →
[5] lipat ke kanon & buang RK.

**RK-2 LULUS SEMENTARA (putusan pemilik 15 Agu) → RK LANGKAH 4
(grading) BERJALAN.** Paket 1 selesai (commit `68a63ee`): jangkar
gambar avatar dipindah ke KAKI (baris isi terbawah strip tepat di
pos.y — sejajar Teknisi yang menapak di pos-nya; squash-stretch kini
berpivot kaki, meregang ke atas); bayangan kontak D8 di avatar+Teknisi;
strip Teknisi digrading kelabu (desat+value turun, amber helm dijepit
63% — manusia kelabu, organisme satu-satunya hijau); zona
lumut/retak/air diredupkan lewat kenop `gelap` di `_zona_wang`
(0.72/0.85/0.82) di bawah pita TENDRIL; kedalaman ambien bertangga
(plafon menggelap 4 pita, drain a0.14); kedip mikro dua lampu
fluorescent (Ruang01Main `_lampu_ruang`). Pass komposisi latar
sebelumnya (commit `cfcce7a`): panel beton berirama + pita utilitas
(seed 1601/1602, latar_panel/latar_pipa) + skirting + 14 noda + garis
pijakan permukaan atas + jumbai lumut plafon. Paket 2 (commit `cd3e1b8`):
audit pijakan menemukan RENDERER SALAH GRID — anatomi atlas Varian A =
dual-grid (isi tile di sudut padat, batas material di TENGAH tile)
tapi struktur digambar sejajar sel, jadi crust permukaan melorot 4
satuan ke dalam massa. Pass struktur ditulis ulang dual-grid sejati
(tile berpusat titik sudut, kunci dari 4 sel sekeliling, material
campuran mayoritas; _kunci lama dihapus); permukaan kini tergambar
TEPAT di garis tabrakan. Audit deterministik LOLOS: rasio pijakan/
latar 3.39x (syarat >=2x; skrip audit_pijakan.gd scratchpad). Seed
1601/1602 tercatat di _gen_params/latar_variatif.json. Sisa amunisi
Langkah 4 (OPSIONAL, hasil-menurun — pemilik menyatakan cukup):
create_tiles_pro varian interior, prop create_map_object (utang 12
decal).

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
