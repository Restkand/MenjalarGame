# 12 — Kitab gaya visual (era kuota PixelLab Tier 1)

12 Agustus 2026. Pemilik proyek berlangganan PixelLab Tier 1 (2000 generasi
per bulan). Kuota bukan lagi alasan berhemat — tapi kuota besar justru
memperbesar bahaya utama pass aset sebelumnya: **hasil yang berbeda-beda**.
Dokumen ini adalah kontraknya. SETIAP generasi PixelLab wajib tunduk ke sini;
aset yang menyimpang dibuang, bukan "disesuaikan nanti".

---

## 1. Identitas yang tidak bisa ditawar

Diwarisi dari docs/01 §5 dan docs/08, tetap berlaku penuh:

1. **Kota abu-abu dan tidak jenuh. Tanaman satu-satunya yang berwarna.**
   Aset kota tidak boleh punya saturasi berarti; kalau sebuah ubin terlihat
   "menarik" sendirian, ia salah — kota adalah latar, bukan bintang.
2. **Cahaya datang dari kiri-atas.** Sisi bawah dan kanan lebih gelap.
3. **Tanpa outline hitam.** Gaya `lineless` / outline warna-sendiri;
   garis hitam pekat membuat aset terbaca kartun dan lepas dari dunianya.
4. **Chunky, bukan renik.** Detail rendah, gumpalan besar — preseden yang
   sudah disetujui pemilik proyek adalah daun_atlas (tiga rona, gumpal).
   Aset dengan tekstur derau halus akan bertabrakan dengannya.
5. Aset tampil **1:1** (PPU 4, docs/09). Ukuran kanvas = ukuran tampil,
   kecuali dinyatakan lain (trik 2×: generate 2× lalu perkecil nearest —
   dipakai saat model menggambar terlalu renik di kanvas kecil).

## 2. Parameter PixelLab yang DIKUNCI

Setiap panggilan `create_image_pixflux` memakai persis:

| Parameter | Nilai | Kenapa |
|---|---|---|
| `view` | `side` | seluruh game tampak samping |
| `shading` | `basic shading` | dua-tiga rona per bidang, cocok daun_atlas |
| `detail` | `low detail` | pilar chunky |
| `outline` | `lineless` | pilar tanpa-outline |
| `color_image` | palet resmi (§3) | pemaksa palet — kunci konsistensi #1 |
| `seed` | dicatat di log §6 | reproduksi |
| `no_background` | true untuk sprite, false untuk ubin/latar | — |

Awalan prompt tetap (city / bawah tanah):

> "muted desaturated pixel art for a quiet city builder, soft top-left
> light, chunky shapes, no black outlines, ..."

Untuk aset TANAMAN awalannya memakai anchor hijau:

> "lush climbing plant pixel art, chunky three-tone green leaves, soft
> top-left light, no black outlines, ..."

`create_image_pro` hanya untuk aset pahlawan (judul, pohon) — dengan
`style_image_url` menunjuk aset yang sudah disetujui + `style_copy` penuh,
supaya kualitas naik TANPA ganti gaya. `edit_image` mode referensi dipakai
untuk MENYERAGAMKAN frame lama, bukan membuat gaya baru.

## 3. Palet resmi

Sumber kebenaran warna adalah `Config.gd`. Palet generasi disusun prosedural
oleh `gen_palet.gd` (scratchpad) menjadi tiga PNG — tiap warna dasar diberi
dua tangga nilai (±12%) supaya model punya ruang shading tanpa keluar palet:

- **palet_kota.png** — C_SKY, C_WALL, C_WALL_DARK, C_NEIGHBOR, C_WINDOW,
  C_LEDGE, C_DOOR, C_WARDEN, C_RETAK, C_PUING, C_PUING_HL, C_PUING_DK, C_DEBU.
- **palet_bawah.png** — C_SOIL, C_SOIL_WET, C_CONCRETE, C_PIPE, C_RETAK,
  C_PUING_DK + humus gelap (2E2218) + air akuifer (3E5A6B).
- **palet_tanaman.png** — C_LEAF, C_TIP, C_BRANCH, C_ROOT, C_BANGKAI +
  hijau gelap kanopi (3E8F35, 2F6B2A).

**Pasca-proses WAJIB**: setiap hasil dipaksa masuk palet (snap ke warna
palet terdekat, alpha dipertahankan) oleh skrip compose scratchpad sebelum
masuk `aset/`. Inilah kunci konsistensi #2 — dua generasi yang gayanya agak
melenceng tetap bersaudara setelah disnap ke palet yang sama.

## 4. Kontrak ukuran per aset

| Aset | Kanvas | Tampil | Catatan |
|---|---|---|---|
| Ubin terrain | 32×32 | 32×32 | seamless-tileable disebut di prompt |
| Jendela fasad | 56×64 | 14×16 satuan | bingkai + kaca + palang |
| Pintu | 40×64 | 10×16 satuan | ukuran dari `world.fitur` |
| Daun | 48×48 → 24 | sel atlas 24 | preseden tersetujui, jangan diubah |
| Pohon | 96×128 | skala seragam | varian baru wajib style-match pohon.png |
| Aktor | 48×64 | 1:1 | palet dinormalisasi ke regu_diam |
| Ikon HUD | 32×32 | 1:1 | satu keluarga bentuk |
| Latar siluet | 400×100 | parallax | dua lapis, makin jauh makin pudar |

## 5. Urutan gelombang

1. **Ubin terrain** (10 ubin) — permukaan terluas di layar, pengaruh terbesar.
2. **Fitur fasad** — jendela, pintu (ledge tetap prosedural, terlalu tipis).
3. **Latar** — dua strip siluet kota untuk LatarView.
4. **Tanaman** — batang sulur/akar (img2img di atas strip prosedural),
   varian pohon kedua.
5. **Aktor** — penyeragaman via edit_image referensi, frame tambahan.
6. **Judul & ikon** — art layar judul, keluarga ikon HUD.

Satu gelombang = generate → kurasi → snap palet → pasang → verifikasi
headless → commit. Tidak ada generasi gelombang berikut sebelum gelombang
berjalan di game.

## 6. TEMPLAT AKTOR — hint lengkap, wajib disalin utuh

Semua manusia di game lahir dari SATU karakter pipeline PixelLab
(`create_character` mode v3), lalu setiap animasi digenerate DARI karakter
itu (`animate_character`). Jangan pernah menggenerate manusia lewat
`create_image_pixflux` lepas — konsistensi identitas hanya dijamin pipeline
karakter.

### 6.1 Karakter kanon

- **ID karakter**: `32cc51a8-78f5-46e2-9520-6f6c82d8279e` ("Regu Perawat",
  grup `79655625-b707-4b96-97c4-aec9a592af4e`). SELAMA karakter ini masih
  ada di akun, semua animasi baru ditambahkan ke ID ini — jangan membuat
  karakter baru untuk peran yang sama.
- **Deskripsi kanon** (dipakai kalau karakter harus dibuat ulang, salin
  persis): "middle-aged city maintenance worker, grey flat cap, muted
  blue-grey overalls over a light grey shirt, dark work boots, empty hands,
  standing relaxed, muted desaturated colors, calm pixel art, no black
  outlines"
- **Parameter pembuatan**: `mode="v3"`, `view="side"`, `size=64`,
  `outline="lineless"`, `detail="low detail"`. Kanvas keluaran pipeline
  120×120 — itu normal (kanvas diberi ruang animasi), JANGAN dianggap
  ukuran karakter.
- **Anatomi acuan**: tinggi berdiri konten ±58 px pada kanvas keluaran
  120 px; kepala bertopi pet abu; lengan kosong (alat hanya boleh muncul
  di animasi kerja). Wajah tidak pernah kelihatan detail — kamera game
  terlalu jauh; jangan buang generasi untuk wajah.

### 6.2 Arah & animasi

- Game HANYA memakai dua arah: **east** untuk semua animasi di tanah
  (jalan, diam, kerja — hadap kiri dicerminkan transform oleh AktorView)
  dan **south** untuk animasi di sulur (naik, gantung — badan menghadap
  pemain, latar adalah fasad).
- Animasi tanah yang ada template-nya pakai TEMPLATE (1 gen):
  `walking-6-frames`, `breathing-idle`. Aksi khusus pakai v3 dengan
  `frame_count` 4–6 dan `keep_first_frame=false` (frame rotasi berdiri
  merusak loop aksi).
- Prompt aksi v3 menjelaskan GERAKNYA SAJA, tanpa lingkungan ("sawing at
  waist height...", BUKAN "sawing a vine on a building"). Lingkungan
  membuat model menggambar properti yang tidak bisa dipakai.
- Daftar animasi kanon → nama strip:
  | Strip | Sumber | Arah | Frame |
  |---|---|---|---|
  | aktor_regu_diam | template breathing-idle | east | 4 |
  | aktor_regu_jalan | template walking-6-frames | east | 6 |
  | aktor_regu_kerja | v3 "sawing at waist height with a small handsaw held in both hands, body rocking back and forth with the cutting motion" | east | 6 |
  | aktor_pemanjat_naik | v3 "climbing straight up a vertical rope hand over hand, legs gripping, facing the viewer, moving upward" | south | 6 |
  | aktor_pemanjat_gantung | v3 "hanging below an overhead bar gripped by one arm extended straight up above the head, body dangling vertically, feet swinging gently in the air" | south | 4 |

### 6.3 Normalisasi ukuran — aturan yang tidak boleh dilanggar

Frame mentah dinormalisasi `gen_aktor.gd` (scratchpad) menjadi strip
`aset/aktor_<nama>.png`, sel 48×64 per frame. Tiga aturan kerasnya:

1. **SATU skala global untuk semua animasi satu karakter**: skala = 58 px /
   tinggi konten median `regu_diam`. JANGAN PERNAH menskalakan tiap animasi
   ke tinggi selnya sendiri — pose membungkuk yang kontennya pendek akan
   menggembung setinggi orang berdiri (kesalahan 12 Agu yang ditangkap
   pemilik proyek).
2. **Jangkar**: animasi tanah = kaki di dasar sel (y=64); animasi sulur
   (naik/gantung) = berpusat vertikal, karena AktorView menggambarnya
   berpusat di titik sulur yang dipijak.
3. Konten yang melebihi sel setelah skala global DIPOTONG, tidak pernah
   diskalakan ulang per frame.

AktorView membaca jumlah frame dari lebar strip (lebar/48) — menambah
frame tidak butuh perubahan kode. Tempo global `FRAME_DETIK` 0,15 dtk.

### 6.4 Karakter baru (kalau suatu hari perlu)

Peran baru (misal inspektur) = `create_character` v3 BARU dengan parameter
§6.1 persis (view side, size 64, lineless, low detail) dan deskripsi yang
mengganti HANYA pakaian/atribut — bukan proporsi, bukan gaya. Lalu ulangi
§6.2–6.3. Kalau ingin wajah/badan yang sama persis dengan Regu Perawat,
pakai `create_character_state` pada ID kanon (variasi seragam), bukan
karakter baru.

## 7. Log generasi

Dicatat per gelombang: tanggal, jumlah generasi terpakai, seed ubin terpilih.

| Tanggal | Gelombang | Terpakai | Kumulatif |
|---|---|---|---|
| 12 Agu | 1 — ubin terrain | 18 | 18 / 2000 |
| 12 Agu | 2 — jendela + pintu | 3 | 21 / 2000 |
| 12 Agu | 3 — dua strip siluet latar | 2 | 23 / 2000 |
| 12 Agu | 4 — batang sulur/akar + pohon varian 2 | 4 | 27 / 2000 |
| 12 Agu | 6 — banner layar judul | 2 | 29 / 2000 (angka resmi get_balance) |
| 12 Agu | 5 — karakter Regu Perawat + 6 animasi (26 frame) | 10 | 39 / 2000 |
| 12 Agu | polish playtest kelima (pintu transparan, tetangga, 4 tanah, bunga) | 7 | 46 / 2000 |
| 12 Agu | playtest keenam: jalan v3 (leher template melar) | 2 | 48 / 2000 |

Pelajaran playtest keenam: animasi TEMPLATE me-retarget skeleton generik ke
karakter — di karakter gempal berkepala besar, lehernya bisa melar
menyeramkan. Untuk karakter kanon ini, animasi gerak dasar pun lebih aman
lewat v3 (`action_description` + "normal head and neck proportions").
walking-6-frames di §6.2 DIGANTI: regu_jalan kini v3 "walking calmly to
the side with relaxed short steps, arms swinging naturally, normal head
and neck proportions, steady upright posture".

Pelajaran pass polish: (1) ubin varian papan catur harus PUNYA NILAI TERANG
SAMA — dua generasi berbeda hampir selalu beda nilai dan malah membentuk
papan catur; varian yang aman adalah cermin/rotasi dari ubin yang sama.
(2) Sprite fitur yang duduk di atas ubin (pintu) digenerate TRANSPARAN
tanpa dinding di belakangnya — dinding bawaan sprite tidak akan pernah
menyatu dengan ubin fasad.

Gelombang 5 sempat ditunda (rencana lama: batch edit_image — payload base64
~15rb karakter rawan korup di jalur MCP). Jalur yang akhirnya dipakai dan
BERHASIL: pipeline karakter (create_character v3 + animate_character), yang
sekaligus membuang masalah konsistensi — semua frame lahir dari satu
karakter. Templat lengkapnya di §6; sprite 2-frame lama dihapus.

Pelajaran gelombang 1, wajib dibawa gelombang berikutnya:

- Di kanvas 32×32 model menggambar OBJEK berbingkai (kolam oval, gerbang
  lengkung), bukan tekstur isi. Resep yang berhasil: kanvas 64×64, frasa
  "flat repeating texture fill … closeup, edge-to-edge, no border, no
  frame", lalu **crop tengah 32×32** — sisa bingkai terpotong.
- "no archway / no masonry" di prompt sering diabaikan; jangan re-roll
  berkali-kali, pilih kandidat terdekat lalu perbaiki lewat crop + snap.
- Snap palet per-ubin (gen_atlas3.gd) ampuh membuang warna nyasar — biru
  akuifer yang menempel di ubin batu hilang tanpa generasi ulang.
