# STATUS PROYEK — Menjalar (Akar & Beton)

Dokumen serah-terima. Lampirkan ini bersama `01-konteks-game.md` dan
`02-logika-game.md` saat memulai percakapan baru.

Terakhir diperbarui: 8 Agustus 2026

---

## 1. Lingkungan

| Item | Nilai |
|---|---|
| Engine | Godot **3.5.3 stable** (bukan Godot 4 — API berbeda) |
| Renderer | **GLES2** |
| GPU | Intel HD Graphics, driver 8.15.10.2900 (OpenGL 2.1) |
| Nama proyek | Menjalar |
| Bahasa | GDScript |

Batasan yang mengikuti dari sini: tanpa shader, tanpa Light2D, tanpa physics
engine, jumlah draw call harus minimal.

---

## 2. Perubahan Arah dari Dokumen Asli

**Dokumen `01` dan `02` sudah tidak sepenuhnya berlaku.**

Dokumen asli merancang prototipe murni untuk menguji satu pertanyaan: apakah
mengarahkan pertumbuhan itu menyenangkan? Stealth, siklus siang-malam, dan
tukang kebun secara eksplisit masuk kolom "sengaja TIDAK dibangun".

Di tengah pengembangan, pemilik proyek memutuskan prototipe terasa terlalu jauh
dari game yang dibayangkan, dan meminta konsep aslinya dibangun:

> Tanaman merambat memenuhi satu gedung penuh dengan hijau, sebagai stealth
> game — tanpa ketahuan tukang kebun. Siang mengumpulkan sumber daya, malam
> merambat pelan-pelan tanpa sepengetahuan orang.

Yang masih berlaku dari dokumen asli: palet warna (§5 Konteks), teknik render
240x160 skala 4x, prinsip float-untuk-simulasi, batas kecepatan belok, dan
ekonomi `min(Air, Cahaya)`.

Yang sudah tidak berlaku: tata letak level §12 Logika, daftar "yang sengaja
tidak ada" §15 Logika, dan konstanta numerik §3 Logika.

---

## 3. Konsep Game Saat Ini

Kita melihat **fasad gedung dari depan** (bukan potongan melintang seperti
rancangan awal). Sulur merambat di permukaan fasad. Di bawah garis tanah,
akar mencari air.

### Ketegangan inti

Tukang kebun melihat apa yang **terkena cahaya**. Area terang memberi energi
tapi mudah ketahuan. Area teduh aman tapi tidak menghasilkan apa-apa.

Pemain harus menumbuhkan daun di tempat terang untuk punya energi, lalu
merambat lewat bayangan untuk menutup gedung.

### Siklus

| Fase | Yang terjadi |
|---|---|
| **Siang** | Akar tumbuh (di bawah tanah, tak terlihat). Daun berfotosintesis. Tukang kebun berpatroli dengan kerucut pandang yang menyapu fasad. Sulur yang tertangkap pandangan **memanas**. Pemain hanya bisa merontokkan (`X`), tidak bisa menumbuhkan sulur. |
| **Malam** | Tukang kebun pulang. Sulur merambat. Tumbuh di area **terang** meninggalkan jejak panas; tumbuh di area teduh gratis. |
| **Fajar** | Sulur yang panasnya mencapai 100% dipangkas 50 piksel. |

### Kondisi menang

Tutupi **55%** area fasad dengan pohon (`COVERAGE_GOAL`).

---

## 4. Struktur File

```
res://
├── main.tscn              (root: Node2D, script main.gd)
├── main.gd                orkestrator; SATU-SATUNYA yang baca input
└── scripts/
    ├── Config.gd          AutoLoad — hanya var & const, NOL fungsi
    ├── WorldMap.gd        peta + grid terrain + bake cahaya & keterlihatan
    ├── Strand.gd          satu untai: tumbuh, tigmotropisme, pratinjau
    ├── TreeSim.gd         kumpulan untai + ekonomi energi
    ├── Warden.gd          tukang kebun, kerucut pandang, panas, pangkas
    ├── PixelCanvas.gd     semua yang menulis piksel
    ├── TuningPanel.gd     slider runtime
    └── Hud.gd             bar energi/tertutup/terlihat + overlay MULAI
```

**Penting:** `Config.gd` harus terdaftar di Project Settings > AutoLoad dengan
Name persis `Config`.

---

## 5. Project Settings

| Setting | Nilai |
|---|---|
| Rendering > Quality > Driver > driver_name | `GLES2` |
| Display > Window > Width / Height | `960` / `640` |
| Display > Window > Resizable | off |
| Display > Window > Stretch > Mode | `2d` |
| Display > Window > Stretch > Aspect | `keep` |
| AutoLoad | `Config` → `res://scripts/Config.gd` |

Simulasi berjalan di 240x160. Jendela 960x640. Skala 4x dilakukan lewat
`Sprite.scale`, bukan stretch viewport — supaya UI tetap tajam sementara
game tetap pixel art keras.

Konversi mouse: `get_viewport().get_mouse_position() / float(Config.SCALE)`

---

## 6. Keputusan Arsitektur Penting

### 6.1 Render berbasis Image, bukan draw_rect

Godot tidak punya `fillRect` murah. Menggambar ribuan piksel lewat `_draw()`
akan mematikan Intel HD.

Solusi: tiga lapis `Image` + `ImageTexture`, masing-masing satu Sprite.

| Lapis | Isi | Digambar ulang |
|---|---|---|
| world | langit, tanah, fasad, jendela, ledge, pipa | sekali saat load |
| tree | akar, sulur, daun | hanya 180 titik terakhir tiap untai |
| overlay | ujung berdenyut, pratinjau, kerucut pandang, panas | tiap frame |

Plus satu `CanvasLayer` (layer 5) berisi `ColorRect` untuk gelap malam.

Aturan Godot 3.x: `Image.lock()` / `unlock()` wajib sebelum `set_pixel`.
`ImageTexture.create_from_image(img, 0)` — flags 0 = tanpa filter/mipmap.
Pakai `texture.set_data(img)` tiap frame, jangan buat texture baru.

### 6.2 Tabrakan pakai grid, bukan physics

`WorldMap.grid` adalah `PoolByteArray` sepanjang 240*160, isinya enum terrain.
Melayani tigmotropisme, deteksi air, dan bake cahaya sekaligus. Nol overhead.

### 6.3 Dua peta yang di-bake sekali saat load

- `light[]` — hasil raycast ke arah matahari. Menentukan hasil fotosintesis.
- `vis[]` — keterlihatan. Rumus: cahaya + ketinggian + bonus jendela/pintu,
  minus bonus ledge. Menentukan seberapa cepat sulur memanas.

### 6.4 Panas per-sulur, bukan kecurigaan global

Setiap `Strand` punya `heat` (0..1). Naik saat tertangkap kerucut pandang
(siang) atau saat tumbuh di area `vis > 0.45` (malam). Meluruh terus.
Sulur dengan `heat >= 1.0` dipangkas saat fajar.

HUD menampilkan nilai `heat` tertinggi di antara semua sulur.

### 6.5 Pemisahan urusan

Semua input mouse/keyboard **hanya** di `main.gd`. Kalau menemukan
`get_global_mouse_position` atau `Input.` di file lain, itu salah tempat.

---

## 7. Kontrol

| Aksi | Input |
|---|---|
| Pilih ujung | Klik kiri (radius 9 px) |
| Arahkan | Tahan klik kiri dan seret |
| Bercabang | Klik kanan pada ujung, atau Spasi |
| Rontokkan ujung panas (siang) | `X` |
| Hentikan ujung (malam) | `X` |
| Peta risiko | Tahan `V` |
| Panel tuning | `Tab` |
| Reset | `R` |

Hanya untai yang sesuai fase yang bisa dipilih: siang = akar, malam = sulur.

---

## 8. Nilai Tuning Saat Ini

```gdscript
var GROWTH_SPEED   = 9.0    # akar
var VINE_SPEED     = 3.2    # sulur — sengaja lambat untuk rasa stealth
var MAX_TURN       = 1.1
var NOISE_AMOUNT   = 0.35
var ENERGY_RATE    = 7.0
var COST_PER_PIXEL = 0.30
var COST_TIP_EXP   = 0.62   # biaya = jumlahUjung^0.62, bukan linear
var GAZE_RANGE     = 84.0
var GAZE_HALF      = 0.52
var HEAT_RATE      = 0.30
var HEAT_DECAY     = 0.10
var NIGHT_HEAT     = 0.55
var DAY_LEN        = 22.0
var NIGHT_LEN      = 24.0
```

Konstanta: `GROUND_Y=112`, `FACADE_X0=44`, `FACADE_X1=196`, `FACADE_Y0=12`,
`FACADE_Y1=112`, `COVERAGE_GOAL=0.55`, `COST_BRANCH=15`, `ENERGY_START=120`,
`ENERGY_MAX=200`, `SHED_COST=40`, `DEAD_ZONE=7.0`, `MAX_STRANDS=24`.

**Belum ada satu pun nilai yang tervalidasi lewat playtest.** Semuanya masih
tebakan awal.

---

## 9. Bug yang Sudah Diperbaiki (jangan diulang)

| Bug | Penyebab | Perbaikan |
|---|---|---|
| Pohon seperti cacing gemuk | 1 titik per frame, bukan per piksel | akumulator `_acc`, catat titik tiap 1 px |
| Ekonomi buntu total | `min(air, cahaya)` = 0 karena belum ada daun | beri nilai dasar 1.0 pada air dan cahaya |
| Energi boros tak masuk akal | biaya linear terhadap jumlah ujung, dan terikat `GROWTH_SPEED` | pangkat `COST_TIP_EXP`, lepas dari GROWTH_SPEED |
| Panas 98% di malam pertama | `heat += seen * NIGHT_HEAT` tanpa `delta` | tambah `* delta` + ambang `vis > 0.45` |
| Ujung mengorbit kursor | sudut target dihitung walau kursor sangat dekat | `DEAD_ZONE` 7 px — di dalamnya, tumbuh lurus |
| Ujung mati di tepi layar | tidak ada pantulan | pantul sudut di tepi |
| `z_index` on ColorRect | ColorRect adalah Control, bukan Node2D | pindah ke CanvasLayer terpisah |
| Fotosintesis jalan malam hari | tidak dicek fase | energi hanya bertambah saat `PHASE_DAY` |

---

## 10. Yang Belum Dikerjakan

- **Menembus beton** (§7 dokumen Logika) — belum ada sama sekali
- **Hidrotropisme & fototropisme** — `TROPISM_STRENGTH` sudah dihapus dari
  panel; tropisme aktif hanya tigmotropisme
- **Aset visual** — semua digambar prosedural lewat `_rect()` di `WorldMap.gd`.
  Belum ada satu file PNG pun. Rencana: pakai PixelLab.ai nanti untuk sprite
  tukang kebun dan detail fasad; untuk sekarang tidak dibutuhkan
- **Level kedua** — hanya ada satu tata letak, hardcoded di `WorldMap.build()`
- **Audio, menu, save** — nol

---

## 11. Pertanyaan Terbuka untuk Playtest Berikutnya

1. Apakah kerucut pandang cukup terbaca sebagai ancaman?
2. Apakah ada waktu cukup bereaksi (`X`) sebelum sulur memerah?
3. Apakah merambat di area teduh benar-benar gratis sekarang?
4. Apakah `VINE_SPEED = 3.2` terasa "menyelinap" atau justru membosankan?
5. Apakah 55% coverage terasa terlalu jauh atau pas?

---

## 12. Cara Melanjutkan di Percakapan Baru

Lampirkan tiga file: `01-konteks-game.md`, `02-logika-game.md`, dan dokumen
ini. Lalu sebutkan:

- Godot 3.5.3, GLES2, Intel HD lama
- Konsep sudah bergeser ke stealth (lihat §2 dokumen ini)
- Minta kode lengkap per file, bukan potongan tambal — lebih mudah diikuti
- Sebutkan file mana yang sedang bermasalah beserta pesan error persisnya

Kalau ingin AI melihat kode aktual, salin isi file `.gd` ke chat atau unggah
folder `scripts/`.
