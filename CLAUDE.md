# TENDRIL — konteks produksi

**GROW. HIDE. SURVIVE.** Metroidvania 2D pixel art: ujung tumbuh tanaman
merambat menjadikan sebuah gedung sebagai tubuhnya.

## Sumber kebenaran desain (KEDUANYA ditulis pemilik proyek)

1. **`docs/GDD-TENDRIL.md`** — desain game menyeluruh (45 bagian).
2. **`docs/SPP-TENDRIL-SPRITE.md`** — prompt pack produksi sprite (63
   bagian): SEMUA sprite karakter wajib dari prompt di sini, urutan §62.
3. **`docs/ADR-TENDRIL-MASTER-A.md`** — keputusan art director:
   **MASTER A LOCKED** (silhouette/proporsi/daun/S-curve/palet terkunci;
   ujung tumbuh sudah di-refine jadi tunas menggulung via inpaint),
   idle/detach/attach KEEP, merambat & lepas sudah di-refine dari master
   refined, **Jump/Fall/Land DILARANG sebelum playtest** (§19), prioritas
   = AvatarView Godot → playtest "apakah terasa hidup saat dikendalikan".
   Sprite kanon di `aset/konsep_tendril/` (master + 5 strip animasi,
   48px/frame, palet kanon; idle/detach/attach masih memakai ujung-daun
   master pra-refine — sengaja, menunggu putusan playtest §21).
4. **`docs/MDS-TENDRIL-GERAK.md`** — spec gerak & arah: ujung memimpin,
   kiri/kanan bukan flip (fallback flip hanya prototype), belok organik.
5. **`docs/OLR-TENDRIL-LOKOMOSI.md`** — REVISI lokomotasi yang MENIMPA
   istilah MDS: bahasa resmi = **CRAWL** (kata "walking" TERLARANG di
   prompt), Growing Tip Downward Rule, traveling body wave, Spatial
   Displacement Rule (frame digenerate BERPINDAH lalu di-re-center oleh
   gen_tendril.gd), turn dibuat ulang SETELAH crawl lolos playtest,
   jump/fall/land menunggu. DOD: "TENDRIL sedang merayap", bukan
   "menggulung".
6. **`docs/CDD-TENDRIL-KARAKTER.md`** — desain karakter (46 bagian) +
   papan acuan visualnya. Kanon untuk SEGALA hal tentang sang Ujung
   Tumbuh: anatomi (ujung bercahaya sensitif cahaya, daun muda kamuflase,
   sulur fleksibel, node pertumbuhan), palet hijau kanon (#102016,
   #19351E, #285B2B, #4F8F32, #79B83F, #A8D94A), warna status
   (kuning=terdeteksi/energi rendah, merah=diburu, ungu=racun,
   biru-putih=listrik), LIMA tahap (Tunas Baru, Muda, Dewasa, Tua/Kayu,
   Terinfeksi-opsional), proporsi (karakter 16–32 px < manusia 32–48 px),
   8 Design Rules (§42), dan north star: "Kecil sebagai individu. Besar
   sebagai jaringan."

Baca KEDUANYA sebelum menyentuh mekanik/visual apa pun. 13 dokumen era
Menjalar sengaja dihapus karena membuat produksi bercabang. Kalau sebuah
keputusan tidak ada di GDD/CDD, tanyakan ke pemilik proyek — jangan
mengarang arah.

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
- Peringatan exit "4 ObjectDB AudioStreamWAV leaked" bersifat KAMBUHAN
  (race driver audio dummy headless) — abaikan, jangan diburu.
- Tabrakan dihitung sendiri di grid (tanpa physics engine Godot) — sudah
  terbukti cukup dan sejalan GDD §43.
- Input dibaca terpusat di `main.gd`; `Config.gd` = AutoLoad var/const
  saja (nol fungsi).
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
  generasi (resep strip `aset/avatar_tumbuh.png`). Frame tengah janggal
  disulam frame jangkar.
- **Karakter manusia**: pipeline `create_character` v3 (side, size 64,
  lineless, low detail) + `animate_character` v3 per aksi (template
  me-retarget kerangka & bisa melarkan leher — hindari). Karakter kanon
  "Regu Perawat" id `32cc51a8-78f5-46e2-9520-6f6c82d8279e` — basis sprite
  Pemangkas/Teknisi (GDD §14).
- Identitas warna dunia: kota/gedung kelabu tak jenuh, organisme
  satu-satunya yang hijau. Palet tanaman: E5F6E6, B8E986, 5EC24A, 3E8F35,
  2F6B2A + cokelat A87B4E/7A5C3A/5C4433.

## Status kode terhadap GDD §41 (jujur, per 13 Agustus 2026)

Kode sekarang = hasil evolusi proyek lama yang SUDAH SEARAH GDD di inti
(moda dobel, energi, tumbuh jaringan), plus sisa sistem lama yang
dibungkam. File inti: `scripts/Avatar.gd` (pemain), `WorldMap.gd` (grid
dunia + `jaringan` + `dalam` interior), `render/AvatarView.gd` (strip
tumbuh 17 frame), `render/JejakView.gd`, `render/PetaView.gd` (peta M),
`render/InteriorView.gd`, `Hud.gd` (HUD avatar), `main.gd` (orkestrator).

- **Phase 1 Movement — SEBAGIAN BESAR ✓**: LEPAS (gravity/jump/collision
  + coyote/buffer/lompat-variabel/lesat), MERAMBAT 360° di jaringan +
  transisi dua arah. BELUM: menempel dinding/plafon PERMUKAAN (sekarang
  hanya di jaringan — GDD §6.1 minta lantai→dinding→plafon), state
  machine formal §28.
- **Phase 2 Energy — ✓**: terkuras saat LEPAS, pulih saat MERAMBAT,
  layu → tumbuh kembali dari simpul (jangkar).
- **Phase 3 Network — SEBAGIAN**: growth ✓ (bergerak = tumbuh, biaya per
  satuan), node/jangkar ✓ (checkpoint+respawn, tombol F). BELUM: node
  sebagai objek (health/koneksi, GDD §29), network destruction, fast
  travel.
- **Phase 4 Exploration — SEBAGIAN**: peta M dengan kabut ✓, pintu E
  (jendela/pintu gedung) ✓, interior 6 tingkat variatif + terowongan
  bawah tanah ✓. BELUM: room system formal, shortcut yang dicatat,
  struktur area GDD §17–18 (sekarang masih gedung kantor generik).
- **Phase 5 Stealth — BELUM** (tiga state §13 belum ada).
- **Phase 6 Enemies — BELUM** (aktor lama regu/pemanjat DIBUNGKAM di
  main; sprite-nya siap jadi basis Pemangkas/Teknisi).
- **Phase 7 Progression — BENIH**: metamorfosis 6 tahap membuka
  lesat/sprint/kapasitas — kerangka untuk §15 (Tendril/Hook Vine/dll
  belum ada).
- **Phase 8 World — BELUM** (area §18 belum dibangun).

**Sisa sistem Menjalar yang masih hidup tapi dibungkam** (kode utuh,
update tidak dipanggil / tersembunyi): sim tanaman liar (TreeSim/Strand —
kini berfungsi sebagai jaringan awal dunia), crew/climber (basis musuh),
babak/cycle-kalender lama, kartu ekonomi, panel tuning. Bongkar HANYA
saat langkah GDD yang menggantikannya berdiri, atau saat pemilik proyek
memintanya.

## Harness uji

Pola: blok `UJI-SEMENTARA` di main.gd + flag `--uji`, DIBUANG sebelum
commit. Fisika diuji DETERMINISTIK: panggil `avatar.update(1.0/60, input,
world)` langsung dalam loop — headless berjalan ratusan fps, jangan
mengukur per-frame layar. Jebakan titik uji: dunia penuh benda padat
tersembunyi (gedung tetangga, pita ledge antar jendela, pipa x156) —
tumbuh/gerak uji di langit murni y<24, dan cek tata letak sebelum
menyalahkan mekanik.

## Langkah berikutnya

**Crawl LULUS playtest 12 Agustus** — putusan pemilik proyek: "agak
merayap dan menggulung tapi ya sudah lah untuk sekarang aman dan lulus
uji coba" → LULUS dengan UTANG POLISH (crawl kanan/kiri masih sedikit
menggulung; revisi saat pass animasi berikutnya, jangan reroll tanpa
diminta).

Gerbang OLR §34 terbuka → sudah dibangun sesudahnya (13 Agustus): belok
crawl `putar_kiri`/`putar_kanan` (7f, seed 1051/1052) plus set udara
`lompat` (7f play-once ~14 fps, membeku di frame akhir), `jatuh` (5f
loop 10 fps), `darat` (5f play-once 0.18 dtk, menyala di tepi mendarat,
gerbang `_udara_t > 0.12` supaya turunan kecil tidak memicu pegas).
Semua digenerate dari master base64 dengan teks aksi ber-jangkar (BUKAN
pin frame — dua base64 panjang dalam satu panggilan selalu korup).
Prioritas state AvatarView: transisi > belok > darat > udara > gerak >
idle. Ketiga anim udara NON-berarah (dicermin `hadap` seperti idle).

**Berikutnya: PLAYTEST turn+udara oleh pemilik proyek**, lalu urutan
OLR §34 lanjut: GROW → ENERGY → CUT/DEATH → REGROW → ABILITY. Utang
lain yang antri: merambat belum direvisi ke bahasa OLR; idle/detach/
attach masih master pra-refine (ADR mengizinkan sampai playtest
gameplay).
