# TENDRIL — ENVIRONMENT DIRECTION V3

## Executable Spec untuk PixelLab.ai → Godot

**Status:** REVISI V2 → V3 (PixelLab-actionable)
**Scope:** Room 01 / Single-Room Prototype
**Perubahan utama dari V2:** V2 adalah dokumen art direction untuk manusia. V3 adalah **spesifikasi yang bisa dieksekusi**: palet terkunci, parameter terkunci, urutan generate terkunci, prompt siap copy-paste.

---

## 0. CARA MEMAKAI DOKUMEN INI

Bagian **1–7 wajib dibaca dan dipatuhi**. Bagian 8+ adalah pendukung.

Aturan tunggal yang mengikat seluruh dokumen:

> **Tidak ada satu pun asset yang boleh di-generate tanpa mewarisi `base_tile_id` atau style reference dari MASTER MATERIAL.**

Kalau aturan ini dilanggar sekali saja, seluruh room akan kembali terlihat kasar. Ini penyebab nomor satu masalah pada screenshot saat ini.

---

## 1. DIAGNOSA SCREENSHOT SAAT INI

Ini bukan kritik umum. Ini daftar cacat spesifik yang terlihat di build sekarang, karena setiap perbaikan di dokumen ini menyerang salah satunya.

| # | Cacat | Bukti di screenshot | Penyebab |
|---|-------|---------------------|----------|
| D1 | **Dua bahasa pixel dalam satu layar** | Blok bermotif labirin/"FE" di kiri-tengah punya kontras internal tinggi & pola sangat terbaca; slab abu di sebelahnya nyaris rata tanpa kontras | Dua tileset di-generate terpisah tanpa parent yang sama |
| D2 | **Tidak ada trim / edge piece** | Semua platform berhenti dengan potongan 90° polos, tanpa lip atas, tanpa cornice, tanpa bayangan jatuh ke dinding | Tileset hanya punya center tile, tidak punya edge/cap/corner |
| D3 | **Outline tidak konsisten** | Vending machine punya outline gelap + rim oranye; dinding & lantai lineless | Parameter `outline` berbeda antar generate |
| D4 | **Tiga temperatur warna** | Prop hangat (oranye), dinding dingin (biru-abu), motif labirin netral | Palet tidak pernah dikunci |
| D5 | **Background berisik & sevalue dengan foreground** | Pola noise dinding belakang terbaca sejelas lantai depan | Background pakai tile beresolusi detail yang sama, tanpa penurunan value |
| D6 | **Cahaya digambar, bukan disinari** | Kerucut kuning bertepi keras, tanpa lampu di sumbernya, tidak menyentuh lantai | Cahaya dibuat sebagai sprite/polygon, bukan `PointLight2D` |
| D7 | **Prop dan pipa melayang** | Vending machine tidak menyentuh apa pun; pipa kanan tidak masuk ke dinding di atas maupun bawah | Tidak ada mounting/flange/bracket piece |
| D8 | **Tidak ada contact shadow** | Pertemuan lantai–dinding adalah garis potong keras | Tidak ada AO trim tile / shader |

**D1, D3, D4 = tugas PixelLab.**
**D2, D7 = asset yang belum pernah dibuat.**
**D5, D6, D8 = tugas Godot, bukan PixelLab.**

---

## 2. AKAR MASALAH

> Masalahnya bukan kualitas PixelLab. Masalahnya adalah **setiap asset di-generate sebagai kejadian independen**.

PixelLab punya tiga mekanisme konsistensi yang belum dipakai sama sekali:

1. **`base_tile_id` chaining** — tileset baru mewarisi material dari tileset sebelumnya.
2. **Style reference / init image** — generate baru mengikuti gaya gambar acuan.
3. **Palette locking + parameter lock (seed & .json)** — warna dan gaya render dikunci.

V3 menjadikan ketiganya wajib.

---

## 3. STYLE LOCK — TIDAK BOLEH DIUBAH TANPA MENGULANG SELURUH ROOM

### 3.1 PALET TERKUNCI (18 warna)

Ini yang paling hilang di V2: V2 menulis "cold desaturated palette" tapi tidak pernah menyebut satu warna pun. Model tidak bisa menebak.

**STRUCTURE — concrete (dingin, biru-abu)**
```
#0B0E12   void / background terjauh
#12171D   background wall (jauh)
#1A2029   background wall (dekat)
#232B36   concrete base          ← warna dominan room
#2E3846   concrete lit
#3D4757   concrete edge highlight
```

**METAL (lebih dingin, lebih rendah saturasi)**
```
#1B2128   metal shadow
#2B333C   metal base
#414B57   metal lit
#59636F   metal specular edge (pakai sangat sedikit, 1px)
```

**WEAR / GRIME (satu-satunya warna hangat di arsitektur)**
```
#3A3128   rust / stain dark
#55452F   rust mid
```

**AMBER — technical accent (maks 3% luas layar)**
```
#8A5A20   amber dim
#D89A3C   amber lit
```

**TENDRIL — hanya untuk makhluk & pertumbuhannya**
```
#3E7A32   green shadow
#6FBF3E   green base
#A8E85C   green highlight
#D6FF8F   green glow (opsional, hanya untuk Light2D)
```

**Aturan value:**

```
Environment    : luminance 5% – 40%
Amber accent   : boleh sampai 63%
TENDRIL        : 60% – 85%   ← elemen paling terang di layar, selalu
```

Kalau ada asset environment yang melewati 40% luminance, asset itu salah — bukan roomnya yang perlu digelapkan.

### 3.2 PARAMETER PIXELLAB TERKUNCI

| Kategori | view | outline | shading | detail |
|---|---|---|---|---|
| Material / tileset | `side` | `lineless` | `basic shading` | `low detail` |
| Architecture piece | `side` | `lineless` | `basic shading` | `low detail` |
| Infrastructure (pipa, kabel, tray) | `side` | `selective outline` | `basic shading` | `medium detail` |
| Props (panel, hatch, lampu) | `side` | `selective outline` | `medium shading` | `medium detail` |
| Decals | `side` | `lineless` | `flat shading` | `low detail` |
| TENDRIL | `side` | `single color outline` | `medium shading` | `medium detail` |

**Kenapa `lineless` untuk arsitektur:** outline hitam pada tile adalah penyebab langsung mata membaca "kotak-kotak". Outline hanya boleh naik untuk benda yang memang harus terbaca sebagai objek terpisah dari dinding.

**Kenapa `low detail` untuk material:** detail tinggi pada tile 32px menghasilkan noise frekuensi tinggi yang membuat pola pengulangan makin jelas, bukan makin kaya.

### 3.3 GRID & UKURAN

```
TILE GRID       : 32 × 32   (kunci, jangan campur 16 dan 32 di layer yang sama)
TRANSITION SIZE : 0.25      (medium blend — 0 terlalu tajam untuk beton)
PROPS           : kelipatan 32, tinggi bebas
DECALS          : 32×32 atau 64×32, transparent background
```

**Catatan batas teknis:** tool map/extend PixelLab membatasi kanvas (±140×140 pada tier bawah, ±200×200 pada tier lebih tinggi). Target V2 berupa piece 256×128 dalam satu generate **tidak realistis di tier bawah**. Solusinya:

- buat 128×128, lalu **Extend Map** ke kanan untuk menyambung, atau
- buat sebagai 2 piece 128×128 yang dirancang bersambung, atau
- pakai tool image ukuran besar kalau tier mendukung.

### 3.4 SEED & PARAMETER FILE

Setiap generate yang berhasil: **simpan file .json parameternya.** PixelLab bisa memuat ulang seed + parameter dari .json. Simpan di:

```
TENDRIL_ROOM01_KIT/_GEN_PARAMS/<nama_asset>.json
```

Tanpa ini, kamu tidak bisa membuat varian yang cocok tiga minggu lagi.

---

## 4. ATURAN PROMPT PIXELLAB

### 4.1 PROMPT PENDEK MENGALAHKAN PROMPT PANJANG

Ini koreksi terbesar terhadap V2. Master prompt V2 panjangnya 24 baris. Pada PixelLab, prompt sepanjang itu **melemahkan sinyal**, bukan menguatkan: setiap klausa tambahan mengencerkan bobot klausa yang benar-benar penting, dan sebagian besar klausa V2 ("cohesive pixel cluster style", "designed to integrate with other modular room pieces", "not a texture showcase") adalah **niat desain, bukan deskripsi visual** — model tidak bisa menggambarnya.

Ganti dengan struktur ini:

```
[ OBJEK ]  +  [ MATERIAL ]  +  [ 1 detail bentuk ]  +  [ arah cahaya ]
```

Target: **8–20 kata.**

| ✗ Jangan | ✓ Pakai |
|---|---|
| `large modular industrial maintenance room wall section, side-scrolling game environment, dark cold concrete, large readable flat forms, subtle panel seams, very restrained grime, single unified fluorescent lighting, same shadow direction as the rest of the room, low contrast, low texture noise, designed to connect with other wall sections, designed as part of one continuous building, not a standalone texture...` | `dark cold concrete facility wall, flat surface, faint horizontal formwork seams, lit from above` |

Konsistensi **tidak** dicapai lewat kata-kata dalam prompt. Konsistensi dicapai lewat `base_tile_id`, style reference, dan palet terkunci. Prompt hanya menjelaskan *apa bendanya*.

### 4.2 NEGATIVE PROMPT — SATU SET, PENDEK

```
brick, cobblestone, dungeon, cave, fantasy, bright, saturated,
high contrast, heavy noise, black outline, drop shadow, isolated sprite
```

Negative prompt V2 (25 baris) juga terlalu panjang dan sebagian saling tumpang tindih. Yang di atas sudah menutup semua kegagalan yang benar-benar pernah terjadi.

### 4.3 KOSAKATA YANG TERBUKTI BEKERJA / TIDAK

**Bekerja** (deskripsi fisik): `formwork seams`, `steel capping`, `riveted`, `grime streak`, `flat`, `matte`, `lit from above`, `worn edge`, `conduit`, `flange`, `bracket`

**Tidak bekerja** (abstraksi desain): `cohesive`, `modular`, `designed to connect`, `part of one building`, `not a texture showcase`, `unified lighting`, `readable`, `macro shape`

Buang seluruh kelompok kedua dari semua prompt.

---

## 5. URUTAN GENERATE — WAJIB BERURUTAN

Ini menggantikan urutan di V2 §6. Perbedaannya: setiap langkah **menyuapkan ID hasilnya ke langkah berikutnya.**

```
STEP 0  ROUGH BLOCK-IN DI GODOT
        Susun room pakai kotak abu polos. Belum ada art sama sekali.
        Screenshot → jadi init image untuk STEP 2.
             ↓
STEP 1  MASTER MATERIAL  — SATU-SATUNYA generate tanpa parent
        concrete_base 32×32
        Simpan: MASTER_ID + palette + .json
             ↓
STEP 2  SIDESCROLLER TILESET (concrete)
        base_tile_id = MASTER_ID
             ↓
STEP 3  SIDESCROLLER TILESET (metal floor plate)
        base_tile_id = MASTER_ID        ← bukan dari step 2
             ↓
STEP 4  TRIM & EDGE SET                 ← YANG HILANG SEKARANG
        base_tile_id = MASTER_ID
             ↓
STEP 5  ARCHITECTURE PIECES
        style reference = tileset step 2
        init image = crop dari block-in Godot
             ↓
STEP 6  INFRASTRUCTURE (pipa, tray, conduit) + MOUNTING PIECES
        style reference = step 3
             ↓
STEP 7  PROPS — via inpainting ke screenshot room
        background_image = screenshot room asli
             ↓
STEP 8  DECALS (transparent)
             ↓
STEP 9  ASSEMBLE + LIGHTING DI GODOT
             ↓
STEP 10 TENDRIL
```

**Gate wajib:** setelah STEP 4, jalankan QA §9. Kalau gagal, **jangan lanjut ke STEP 5.** Perbaiki step yang gagal, bukan reroll semuanya.

---

## 6. PROMPT LIBRARY — SIAP COPY-PASTE

### STEP 1 — MASTER MATERIAL

Tool: **Create Texture** atau **Create Tileset** (center tile)

```
dark cold concrete facility wall, flat matte surface,
faint horizontal formwork seams, lit from above
```
```
view: side | outline: lineless | shading: basic shading | detail: low detail
size: 32 | palette: <lock ke §3.1 STRUCTURE>
```

Kriteria lolos: kalau tile ini di-tile 8×8 dan kamu masih bisa menemukan titik yang menarik mata, **regenerate.** Master material harus membosankan. Kebosanan adalah fiturnya.

---

### STEP 2 — SIDESCROLLER TILESET (CONCRETE)

```python
create_sidescroller_tileset(
    lower       = "dark cold concrete wall, flat, faint formwork seams",
    transition  = "worn steel capping strip with rivets and thin grime line",
    base_tile_id = MASTER_ID,
)
```

`transition` adalah **top tile** — inilah yang memberi lantai sebuah "bibir" sehingga tidak berakhir sebagai potongan 90°. Ini memperbaiki D2 secara langsung.

---

### STEP 3 — SIDESCROLLER TILESET (METAL)

```python
create_sidescroller_tileset(
    lower       = "dark steel floor plate, low sheen, subtle panel joints",
    transition  = "concrete lip with chipped edge",
    base_tile_id = MASTER_ID,   # tetap dari master, bukan dari step 2
)
```

Menurunkan keduanya dari master yang sama membuat beton dan baja punya *hubungan material* — persis yang diminta di checklist V2 tapi tidak pernah punya mekanismenya.

---

### STEP 4 — TRIM & EDGE SET (BARU — TIDAK ADA DI V2)

Ini set yang paling menentukan apakah room terlihat menyatu. Tanpa ini, semua langkah lain sia-sia.

| Asset | Ukuran | Prompt |
|---|---|---|
| `trim_floor_lip` | 32×16 | `worn steel edge capping on concrete, thin dark shadow line beneath` |
| `trim_wall_base` | 32×32 | `concrete wall meeting floor, soft dark gradient in the corner, dust buildup` |
| `trim_platform_under` | 32×16 | `underside of concrete slab, deep shadow, exposed rebar stub` |
| `trim_corner_outer` | 32×32 | `chipped outer concrete corner, exposed aggregate, worn edge` |
| `trim_corner_inner` | 32×32 | `inner concrete corner, dark ambient shadow, faint grime` |
| `trim_ceiling_edge` | 32×16 | `concrete ceiling edge with steel angle bracket, dark underside` |
| `trim_seam_vertical` | 16×32 | `vertical expansion joint in concrete wall, thin recessed dark line` |

Semua dengan `base_tile_id = MASTER_ID`, `lineless`, `basic shading`, `low detail`.

---

### STEP 5 — ARCHITECTURE PIECES

Gunakan **init image dari block-in Godot** (STEP 0). Ini yang membuat proporsi cocok dengan level design, bukan sebaliknya.

```
industrial wall recess with steel frame, dark concrete, lit from above
```
```
service platform, steel deck on concrete corbels, visible thickness, dark underside
```
```
maintenance ledge, concrete slab with steel angle edge, worn
```
```
vertical service shaft opening, steel frame, dark interior
```
```
structural beam, riveted steel I-beam against concrete, lit from above
```

Semua: `init image = crop block-in`, `style reference = tileset STEP 2`, `lineless`, `basic shading`, `low detail`.

---

### STEP 6 — INFRASTRUCTURE + MOUNTING

Setiap pipa **wajib** dibuat berpasangan dengan potongan sambungannya. Ini memperbaiki D7.

```
straight steel pipe section, side view, dark metal, subtle top highlight
```
```
steel pipe 90 degree elbow, dark metal, side view
```
```
steel pipe wall flange, bolted mounting plate, pipe entering concrete wall
```
```
steel pipe support bracket clamped to wall, side view
```
```
cable tray with bundled cables, dark steel, side view
```
```
electrical conduit running along wall with clamps
```

Semua: `selective outline`, `basic shading`, `medium detail`, style reference = STEP 3.

**Aturan pipa:** pipa tidak boleh masuk atau keluar layar tanpa flange, bracket, atau elbow. Pipa yang berhenti di udara adalah bug, bukan pilihan estetika.

---

### STEP 7 — PROPS VIA INPAINTING — TEKNIK PALING PENTING

Jangan generate prop di kanvas kosong lalu tempel ke room. Generate prop **langsung di atas screenshot room-nya.**

```python
create_map_object(
    description     = "wall-mounted steel electrical panel with conduit entering the wall",
    view            = "side",
    outline         = "selective outline",
    shading         = "medium shading",
    detail          = "medium detail",
    background_image = "<screenshot region Room 01>",
    inpainting       = "<mask di posisi panel akan dipasang>",
)
```

Kenapa ini menyelesaikan masalah: model melihat dinding aslinya, lalu mencocokkan palet, arah cahaya, dan densitas pixel secara otomatis. Ini persis yang gagal pada vending machine di screenshot sekarang (D3, D4, D7) — benda itu jelas di-generate di kanvas terpisah.

Prop yang harus dibuat dengan cara ini:
```
fluorescent light fixture mounted on ceiling, steel housing, dim amber tubes
warning light on wall bracket, small amber dome
maintenance hatch set into wall, steel, bolted frame
service door, dark steel, small window, recessed into wall
small pump machine bolted to floor, pipes entering from above
```

---

### STEP 8 — DECALS

```
water stain streak on concrete, transparent background, very low contrast, irregular
```
```
rust bleed from a bolt, transparent background, muted brown
```
```
oil pooling stain, transparent background, dark, matte
```
```
faded yellow warning stripe paint, worn, transparent background
```
```
hairline crack in concrete, transparent background, thin, subtle
```

`flat shading`, `low detail`, `lineless`. Decal ini yang memecah pengulangan tile di Godot — sediakan minimal 12, jangan 5.

---

## 7. TRIM SET & VARIAN — ANTI-REPETISI

Untuk setiap material, siapkan:

```
1 × center tile          (dari master)
3 × center variant       (perbedaan halus saja — 2-4 pixel, bukan motif baru)
1 × top / lip
1 × underside
2 × corner (inner, outer)
1 × vertical seam
```

**Aturan varian:** varian yang berbeda terlalu jauh justru memperjelas grid. Perbedaan yang benar adalah satu noda kecil, satu retak halus, satu baut. Bukan pola baru.

Blok bermotif labirin di screenshot sekarang melanggar aturan ini secara ekstrem — itu bukan varian, itu material lain.

---

## 8. YANG HARUS DIKERJAKAN GODOT — BUKAN PIXELLAB

PixelLab tidak akan pernah bisa memperbaiki D5, D6, dan D8. Jangan buang generate untuk itu.

| Cacat | Perbaikan di Godot |
|---|---|
| D5 background berisik | Layer background: `modulate = Color(0.45, 0.48, 0.55)`, pakai tile **datar** (bukan tile foreground yang sama), taruh di `ParallaxLayer` dengan `motion_scale ≈ 0.6` |
| D6 cahaya poligon | Hapus sprite kerucut. Pakai `PointLight2D` + gradient texture radial, `energy ≈ 0.8`. **Wajib** ada sprite lampu di titik sumbernya. Tambah `LightOccluder2D` di arsitektur agar cahaya benar-benar terpotong |
| D8 no contact shadow | Tambahkan `trim_wall_base` di setiap pertemuan lantai–dinding, plus 1px garis `#0B0E12` di bawah setiap lip |
| Grading global | Satu `CanvasModulate` = `#8FA0B8` untuk mendinginkan seluruh scene sekaligus |
| Kedalaman | Minimal 3 layer: BG jauh (gelap, datar) → BG dekat → FG. Jangan pernah pakai tile yang sama di dua layer |
| Repetisi tile | Aktifkan random variant di TileSet, taruh decal manual setiap 3–5 tile |
| TENDRIL focal | `PointLight2D` hijau kecil (`#D6FF8F`, energy 0.4) mengikuti tendril |

---

## 9. QA GATES

Jalankan **setelah STEP 4** dan lagi setelah STEP 9.

**GATE 1 — BLUR**
Blur screenshot radius 8px. Harus tetap terbaca: dinding / lantai / struktur / infrastruktur. Kalau berubah jadi kumpulan kotak → **FAIL di trim set (STEP 4).**

**GATE 2 — GRAYSCALE**
Hilangkan warna. TENDRIL harus tetap jadi benda paling terang. Kalau tidak → environment terlalu terang, bukan tendril kurang terang.

**GATE 3 — HUE HISTOGRAM** *(baru)*
Buka histogram warna screenshot. Harus terlihat: **satu klaster dingin dominan**, satu klaster amber sangat kecil, satu klaster hijau kecil. Kalau ada klaster keempat → ada asset yang lolos dari palet.

**GATE 4 — SEAM TEST**
Zoom 100%, lihat 5 detik. Kalau mata langsung menemukan grid `32|32|32` → varian kurang atau trim hilang.

**GATE 5 — CONNECTION TEST**
Untuk tiap prop dan tiap pipa: tunjuk titik fisik tempat benda itu menempel ke gedung. Kalau tidak bisa ditunjuk → belum selesai.

**GATE 6 — FIVE SECOND TEST**
Orang yang belum pernah lihat harus bisa bilang "ruang mesin / ruang perawatan", bukan "dungeon", bukan "kumpulan tile".

---

## 10. CONTROLLED TEST SEBELUM FULL ROOM

Tetap dipertahankan dari V2, tapi dengan isi yang lebih spesifik.

Buat satu strip **128 × 128** (bukan 256×128 — lihat batas kanvas §3.3) berisi:

```
concrete wall (STEP 2)
+ trim_floor_lip (STEP 4)
+ trim_wall_base (STEP 4)
+ satu pipa dengan flange (STEP 6)
+ satu electrical panel via inpainting (STEP 7)
+ satu water stain decal (STEP 8)
```

Tanpa TENDRIL. Tanpa lighting effect.

Jalankan GATE 1, 3, 4, 5. Kalau lolos keempatnya, pipeline-nya benar dan boleh scale ke full room. Kalau tidak, perbaiki **asset yang gagal saja** — jangan reroll room.

---

## 11. DEFINITION OF DONE

- [ ] Semua asset diturunkan dari `MASTER_ID` atau style reference-nya
- [ ] Tidak ada warna di luar palet §3.1
- [ ] Environment tidak melewati 40% luminance
- [ ] TENDRIL adalah elemen paling terang di layar
- [ ] Trim set STEP 4 lengkap dan terpasang di semua pertemuan permukaan
- [ ] Setiap pipa berakhir di flange, elbow, atau bracket
- [ ] Setiap prop dibuat via inpainting ke screenshot room
- [ ] Background diturunkan value-nya dan pakai tile berbeda dari foreground
- [ ] Cahaya = `PointLight2D`, bukan sprite; setiap cahaya punya lampu terlihat
- [ ] Minimal 3 varian center tile per material + 12 decal
- [ ] Semua parameter tersimpan sebagai .json di `_GEN_PARAMS/`
- [ ] GATE 1–6 lolos

---

## 12. PRINSIP ART DIRECTION (DIPERTAHANKAN DARI V2)

Bagian ini tidak berubah — masih benar, hanya tidak cukup sendirian.

```
ARCHITECTURE   >  TEXTURE
MACRO SHAPE    >  MICRO DETAIL
COHESION       >  INDIVIDUAL BEAUTY
GLOBAL LIGHTING>  LOCAL EFFECTS
FUNCTION       >  DECORATION
ROOM           >  TILE
```

Target visual tetap:

> Fasilitas perawatan industri yang gelap, tua, fungsional, dan perlahan dikolonisasi organisme hidup.

Pembagian tanggung jawab tetap:

> **PixelLab** = material, architectural pieces, infrastructure, props, decals
> **Godot** = komposisi, lighting, depth, collision, gameplay route, TENDRIL

Dan identitas gameplay tetap:

> **Human infrastructure creates the maze.**
> **TENDRIL learns how to inhabit it.**

Yang V3 tambahkan hanyalah satu hal: **mekanisme teknis agar prinsip-prinsip di atas benar-benar terjadi**, bukan hanya tertulis.

---

## APENDIKS A — RINGKASAN PARAMETER (CHEAT SHEET)

```
GRID            32×32
TRANSITION      0.25
VIEW            side (semua)
PALETTE         terkunci, 18 warna (§3.1)
PROMPT LENGTH   8–20 kata
NEGATIVE        brick, cobblestone, dungeon, cave, fantasy, bright,
                saturated, high contrast, heavy noise, black outline,
                drop shadow, isolated sprite

OUTLINE   material/arch  = lineless
          infra/props    = selective outline
          tendril        = single color outline

SHADING   material/arch  = basic shading
          props          = medium shading
          decals         = flat shading

DETAIL    material/arch  = low detail
          infra/props    = medium detail
          decals         = low detail

CHAIN     semua tileset  → base_tile_id = MASTER_ID
          semua arch     → style reference = tileset concrete
          semua props    → background_image = screenshot room
```

---

# AMENDEMEN PENUTUPAN RK (15 Agustus 2026)

> Dilipat dari RK Langkah 5 (rencana disahkan pemilik proyek).

## Gate ke-7 QA (§9): GRADING DINILAI DENGAN SENSOR MENYALA

Nilai grading final HANYA sah in-game: CanvasModulate + PointLight2D +
kerucut sensor aktif. Screenshot aset lepas tidak pernah jadi dasar
putusan grading — gelap harus dinilai saat gelap punya pekerjaan.

## Aturan pijakan (§3.1): LUMINANCE PIJAKAN ≥ 2× DINDING

Menggantikan bacaan ambigu "env ≤40%" yang sempat terbaca "gelapkan
semua": permukaan yang BISA DIPIJAK/DIRAMBATI wajib ≥2× luminance
dinding latar tepat di belakangnya — ini SIGNIFIER (kategori
kecelakaan), bukan mood; tidak ada argumen atmosfer yang membelanya.
Audit deterministik tersedia (audit_pijakan.gd; rasio saat lulus:
3.39×). Pita value lain tetap berlaku: env gelap tak jenuh, amber
≤63%, TENDRIL 60–85% selalu paling terang.
