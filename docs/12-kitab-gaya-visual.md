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

## 6. Log generasi

Dicatat per gelombang: tanggal, jumlah generasi terpakai, seed ubin terpilih.

| Tanggal | Gelombang | Terpakai | Kumulatif |
|---|---|---|---|
| 12 Agu | 1 — ubin terrain | 18 | 18 / 2000 |
| 12 Agu | 2 — jendela + pintu | 3 | 21 / 2000 |
| 12 Agu | 3 — dua strip siluet latar | 2 | 23 / 2000 |
| 12 Agu | 4 — batang sulur/akar + pohon varian 2 | 4 | 27 / 2000 |

Pelajaran gelombang 1, wajib dibawa gelombang berikutnya:

- Di kanvas 32×32 model menggambar OBJEK berbingkai (kolam oval, gerbang
  lengkung), bukan tekstur isi. Resep yang berhasil: kanvas 64×64, frasa
  "flat repeating texture fill … closeup, edge-to-edge, no border, no
  frame", lalu **crop tengah 32×32** — sisa bingkai terpotong.
- "no archway / no masonry" di prompt sering diabaikan; jangan re-roll
  berkali-kali, pilih kandidat terdekat lalu perbaiki lewat crop + snap.
- Snap palet per-ubin (gen_atlas3.gd) ampuh membuang warna nyasar — biru
  akuifer yang menempel di ubin batu hilang tanpa generasi ulang.
