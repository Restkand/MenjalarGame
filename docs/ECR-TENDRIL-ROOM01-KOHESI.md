# TENDRIL — REVIEW & ART DIRECTION REVISION
## Single Room Environment: Tile Terasa Terpisah, Kontras, dan Tidak Menyatu

**Status:** REVIEW / REVISION REQUEST
**Scope:** Room 01 — Service / Maintenance Room
**Target Pipeline:** PixelLab.Ai → Tileset → Godot
**Tujuan:** Mengubah hasil prototype dari sekumpulan tile yang benar secara teknis menjadi **satu ruangan yang terasa sebagai ruang fisik yang utuh**.

---

# 1. KESIMPULAN REVIEW

Hasil terbaru sudah bergerak ke arah yang benar secara konsep.

Ruangan sekarang sudah memiliki:

- beton,
- platform,
- metal grate,
- panel listrik,
- lampu,
- warning marking,
- drain,
- struktur maintenance,
- elemen industrial.

Namun masalah utama sekarang **bukan lagi "terlalu seperti dungeon"**.

Masalah baru adalah:

> **setiap tile dan asset terlihat seperti benda yang ditempelkan ke ruangan, bukan bagian dari ruangan yang sama.**

Secara visual hasilnya masih terasa seperti:

```text
TILE A
+
TILE B
+
TILE C
+
PROP D
+
PROP E
+
TENDRIL
```

bukan:

```text
        SATU RUANGAN
              │
       ┌──────┴──────┐
       │             │
    STRUCTURE    INFRASTRUCTURE
       │             │
       └──────┬──────┘
              │
        TENDRIL LIFE
```

---

# 2. MASALAH UTAMA YANG HARUS DIPERBAIKI

Ada **6 masalah utama**:

1. **Tile terlalu kontras satu sama lain**
2. **Tekstur tile terlalu jelas sebagai pola berulang**
3. **Material tidak memiliki hubungan pencahayaan yang sama**
4. **Foreground / midground / background belum menyatu**
5. **Asset terlihat seperti sprite terpisah, bukan bagian konstruksi**
6. **Ruangan belum memiliki "material language" yang konsisten**

Prioritas revisi harus diarahkan ke enam hal ini.

---

# 3. MASALAH #1 — TILE TERLALU KONTRAS

Pada screenshot terbaru, concrete floor terlihat jauh lebih terang daripada background wall.

Metal grate juga mempunyai kontras yang sangat tinggi.

Akibatnya mata membaca:

```text
BACKGROUND
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

FLOOR
████████████████████
^^^^^^^^^^^^^^^^^^^^
HIGH CONTRAST

GRATE
██████████████████
VERY HIGH CONTRAST
```

Setiap elemen berteriak:

> "Saya adalah asset!"

Padahal kita ingin:

> "Saya adalah bagian dari ruangan."

---

# 4. PRINSIP BARU — VALUE HIERARCHY

Jangan menentukan warna setiap tile secara independen.

Semua tile harus tunduk pada **value hierarchy** ruangan.

Gunakan konsep:

```text
DARKEST
   │
   ├── Deep Background
   │
   ├── Structural Wall
   │
   ├── Floor
   │
   ├── Metal Infrastructure
   │
   ├── Interactive / Important Objects
   │
   └── TENDRIL
BRIGHTEST
```

Tetapi perbedaannya harus **bertahap**, bukan lompat.

Contoh:

```text
BACKGROUND     20–25% value
WALL           28–35%
FLOOR          35–42%
METAL          40–48%
PROP           45–55%
TENDRIL        65–90%
```

Angka ini adalah **pedoman visual**, bukan aturan warna absolut.

---

# 5. MASALAH #2 — TILE 32x32 TERLALU TERLIHAT

Tile:

- `beton_dinding`
- `beton_lantai`
- `jeruji`

saat diulang berkali-kali membuat pola visual yang mudah dikenali.

Ini menyebabkan efek:

> "Saya sedang melihat texture tiles."

bukan:

> "Saya sedang melihat sebuah dinding beton."

---

# 6. SOLUSI — TILE TIDAK BOLEH MENJADI TEKSTUR UTAMA

Tile 32x32 hanya boleh menyediakan:

> **material base.**

Detail besar harus dibuat melalui:

- decals,
- trim,
- panel seams,
- stains,
- cracks,
- pipes,
- brackets,
- shadows,
- large structural pieces.

Jadi:

```text
32x32 TILE
     ↓
BASE MATERIAL
     +
LARGE SHAPE
     +
DECAL
     +
LIGHT
     +
PROP
     ↓
ROOM
```

Bukan:

```text
32x32 TILE
×
100
=
ROOM
```

---

# 7. DINDING BETON

## MASALAH

Dinding sekarang mempunyai noise kecil yang relatif seragam.

Ketika diulang:

```text
xxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxx
```

noise tersebut membentuk pola.

Dinding akhirnya terlihat seperti:

> texture generator.

---

# 8. SOLUSI DINDING

Dinding harus mempunyai **variasi skala besar**.

Gunakan:

### BASE

Flat dark concrete.

### LARGE VARIATION

Beberapa panel lebih gelap/terang.

### STRUCTURAL SEAMS

Garis sambungan antar panel.

### LOCAL WEAR

Noda hanya pada area tertentu.

### INFRASTRUCTURE

Pipa dan kabel memecah bidang besar.

Contoh:

```text
┌─────────────────────────────┐
│                             │
│      PANEL                  │
│                             │
├────── PIPE ─────────────────┤
│                             │
│              [PANEL]        │
│                             │
│       stain                 │
└─────────────────────────────┘
```

Bukan:

```text
tile tile tile tile tile
tile tile tile tile tile
tile tile tile tile tile
```

---

# 9. LANTAI BETON

## MASALAH

Floor sekarang terasa seperti:

> material berbeda yang ditempel di bawah dinding.

Alasannya:

- terlalu terang,
- tekstur terlalu aktif,
- batas antara wall/floor terlalu keras,
- belum memiliki shadow relationship.

---

# 10. SOLUSI FLOOR

Floor harus memiliki:

```text
BASE CONCRETE
+
EDGE SHADOW
+
STRUCTURAL SEAM
+
LOCAL STAIN
+
DRAIN
+
OCCLUSION
```

Pertemuan wall dan floor harus mempunyai **visual grounding**.

Contoh:

```text
WALL
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
        ↓
      SHADOW
████████████████████
FLOOR
████████████████████
```

Bukan:

```text
WALL
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

FLOOR
████████████████████
```

---

# 11. METAL GRATE

## MASALAH

Metal grate saat ini terlalu kontras sehingga terlihat seperti:

> sprite obstacle yang ditempel.

Bukan:

> struktur walkway yang merupakan bagian dari ruangan.

---

# 12. SOLUSI METAL GRATE

Metal harus memiliki hubungan warna dengan concrete.

Jangan:

```text
CONCRETE = abu-abu
GRATE    = putih terang
```

Gunakan:

```text
CONCRETE = abu-abu gelap
GRATE    = abu-abu sedikit lebih terang
EDGE     = highlight kecil
SHADOW   = sangat gelap
```

Metal juga perlu:

- support beam,
- mounting,
- shadow,
- overlap.

Dengan begitu ia terlihat **dipasang**, bukan ditempel.

---

# 13. MASALAH #3 — TIDAK ADA GLOBAL LIGHTING

Ini salah satu masalah terbesar.

Saat setiap asset dibuat sendiri oleh AI, masing-masing dapat menghasilkan:

- highlight sendiri,
- shadow sendiri,
- brightness sendiri,
- saturation sendiri.

Akibatnya:

```text
WALL ← lighting A
FLOOR ← lighting B
GRATE ← lighting C
PANEL ← lighting D
```

Ruangan terasa tidak konsisten.

---

# 14. SOLUSI — SATU SUMBER CAHAYA RUANGAN

Sebelum membuat asset baru, tentukan:

> **ROOM LIGHTING MODEL**

Untuk Room 01:

```text
MAIN LIGHT
→
cold overhead fluorescent

SECONDARY
→
weak industrial ambient

ACCENT
→
amber electrical indicators

BIOLOGICAL
→
green TENDRIL glow
```

Semua asset harus dibuat seolah-olah berada di bawah lighting tersebut.

---

# 15. GLOBAL LIGHTING RULE

Untuk Room 01:

> **Tidak ada asset yang boleh terlihat seperti diterangi dari arah yang berbeda.**

Contoh:

Jika lampu utama berada di atas:

```text
TOP
────────────
   LIGHT
     ↓
────────────
  PIPE
  bright top
  dark bottom
```

Pipe harus mengikuti lighting tersebut.

Floor juga.

Wall juga.

Panel juga.

---

# 16. MASALAH #4 — FOREGROUND, MIDGROUND, BACKGROUND BELUM JELAS

Saat ini background terlalu aktif sementara beberapa foreground terlalu terang.

Target:

## BACKGROUND

Sangat tenang.

```text
dark
flat
low contrast
```

## MIDGROUND

```text
pipes
cables
ducts
panels
```

## FOREGROUND

```text
floor
platform
grate
interactive structure
```

## CHARACTER

```text
TENDRIL
brightest biological element
```

---

# 17. RULE KONTRAS

Gunakan:

```text
BACKGROUND
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

MIDGROUND
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

FOREGROUND
██████████████

TENDRIL
██████████████
        ↑
highest readability
```

Jika background memiliki detail sebanyak foreground:

> depth hilang.

---

# 18. MASALAH #5 — PROP TERLIHAT "DITEMPEL"

Panel listrik, lampu, drain, dan platform sudah benar secara desain.

Tetapi mereka masih perlu:

> **CONNECTION DETAILS**

Contoh panel listrik.

Jangan hanya:

```text
[ PANEL ]
```

Gunakan:

```text
      CABLE
        │
        │
┌───────┴───────┐
│ ELECTRICAL    │
│ PANEL         │
└───────┬───────┘
        │
      CONDUIT
```

Dengan demikian pemain percaya:

> panel tersebut benar-benar terhubung ke sistem gedung.

---

# 19. GOLDEN RULE — EVERY PROP NEEDS A CONNECTION

Setiap prop besar harus mempunyai setidaknya satu:

- pipe,
- cable,
- bracket,
- conduit,
- shadow,
- support,
- wall mounting.

Jika tidak:

> asset terasa floating.

---

# 20. MASALAH #6 — RUANGAN BELUM MEMILIKI MATERIAL LANGUAGE

Semua material harus terasa berasal dari gedung yang sama.

Tentukan material canon:

### CONCRETE

- dark gray
- cold
- slightly damp
- old

### METAL

- dark steel
- slightly brighter than concrete
- subtle rust

### CABLE

- almost black
- muted color markings

### WARNING

- restrained amber/yellow

### TENDRIL

- living green

Jangan biarkan AI memilih warna material secara bebas setiap kali.

---

# 21. PALET RUANGAN

Gunakan prinsip:

```text
INDUSTRIAL
        ↓
DARK
        ↓
DESATURATED
        ↓
LOW CONTRAST
        ↓
SMALL ACCENTS
        ↓
TENDRIL GREEN
```

TENDRIL adalah pengecualian.

---

# 22. TENDRIL HARUS MENJADI "COLOR ANCHOR"

Jika environment terlalu berwarna:

> TENDRIL kehilangan identitas.

Jika environment cukup muted:

> satu hijau terang langsung terasa hidup.

Target:

```text
ENVIRONMENT
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

TENDRIL
       🌿
```

Bukan:

```text
ENVIRONMENT
🟨 🟦 🟥 🟫 🟧
🌿
```

---

# 23. JANGAN MEMBUAT SETIAP TILE TERLIHAT "SEMPURNA"

PixelLab.Ai sering menghasilkan asset yang terlihat selesai secara individual.

Masalahnya:

> asset yang sempurna secara individual bisa gagal ketika digabungkan.

Karena itu prompt harus mengutamakan:

```text
CONSISTENCY
```

lebih daripada:

```text
DETAIL
```

---

# 24. PROMPT MASTER BARU — ENVIRONMENT CONSISTENCY

Gunakan prompt berikut sebagai **header tetap** setiap kali membuat asset Room 01:

```text
TENDRIL ROOM 01 ENVIRONMENT STYLE,
consistent 2D pixel art tileset for the same industrial building,
dark abandoned building maintenance room,
cold desaturated industrial palette,
old concrete and dark steel,
subtle dampness and age,
single unified room lighting,
soft low-contrast ambient lighting,
overhead fluorescent lighting,
consistent material colors,
consistent pixel cluster style,
consistent shadow direction,
consistent highlight direction,
high visual cohesion between tiles,
designed to be assembled into one seamless game environment,
32x32 pixel art base,
simple readable forms,
low texture noise,
large-scale material variation,
no isolated decorative object look,
no random color variation,
no independent lighting,
no fantasy architecture
```

Tambahkan asset spesifik setelah bagian ini.

---

# 25. NEGATIVE PROMPT BARU

```text
high contrast tile,
bright texture,
isolated sprite look,
random lighting,
random highlights,
random shadows,
different color temperature,
overly noisy texture,
repeating obvious texture,
stone dungeon,
cave,
fantasy ruins,
medieval architecture,
bright concrete,
white concrete,
high saturation,
photorealistic,
3D,
smooth vector art,
ornamental fantasy,
independent asset lighting,
floating object,
unconnected prop
```

---

# 26. PROMPT — CONCRETE WALL REVISI

```text
32x32 pixel art base tile,
dark industrial concrete wall,
same lighting and material language as TENDRIL ROOM 01,
very low contrast,
subtle cold gray palette,
large flat concrete surface,
minimal fine texture,
few irregular pixels,
extremely subtle grime,
designed to disappear into a larger wall,
seamless tile,
no obvious repeating pattern,
no strong cracks,
no bright highlights,
no individual stone blocks,
no brick,
no cave,
no dungeon
```

Tujuan tile:

> **tidak menarik perhatian.**

---

# 27. PROMPT — CONCRETE FLOOR REVISI

```text
32x32 pixel art base tile,
dark industrial concrete maintenance floor,
same material and lighting as TENDRIL ROOM 01,
slightly brighter than background wall,
low contrast,
subtle cold gray,
very restrained surface noise,
small irregular wear,
no repeating visible pattern,
designed to blend into large floor surfaces,
seamless,
no cobblestone,
no stone blocks,
no bright texture,
no strong cracks,
no dungeon floor
```

---

# 28. PROMPT — METAL GRATE REVISI

```text
32x32 pixel art industrial metal grate tile,
same room lighting as TENDRIL ROOM 01,
dark steel,
slightly brighter than concrete but not highly contrasted,
subtle cool gray,
small restrained highlights,
dark interior gaps,
simple rectangular industrial structure,
designed to connect seamlessly with adjacent metal platforms,
consistent pixel clusters,
low texture noise,
no bright white metal,
no glowing edges,
no isolated sprite look,
no fantasy
```

---

# 29. JANGAN MEMINTA AI MEMBUAT "REALISTIC TEXTURE"

Hindari:

```text
highly detailed
realistic concrete
photorealistic texture
extreme surface detail
ultra detailed
rich texture
dramatic lighting
```

Karena hasil akhirnya akan menjadi:

> texture showcase

bukan:

> game environment.

Gunakan:

```text
subtle
restrained
low contrast
cohesive
seamless
consistent
simple
```

---

# 30. ROOM ASSEMBLY METHOD DI GODOT

Jangan hanya:

```text
TileMap
TileMap
TileMap
TileMap
```

Buat struktur:

```text
Room01
│
├── Background
│   └── BackgroundBase
│
├── Architecture
│   ├── Wall
│   ├── Floor
│   ├── Ceiling
│   └── StructuralEdges
│
├── Infrastructure
│   ├── Pipes
│   ├── Cables
│   ├── Panels
│   ├── Grates
│   └── Vents
│
├── Wear
│   ├── WaterStains
│   ├── Rust
│   └── Decals
│
├── Lighting
│   ├── Ambient
│   ├── Fluorescent
│   └── Emergency
│
└── Tendril
    ├── Network
    ├── Nodes
    └── Growth
```

---

# 31. VARIASI BESAR HARUS DIBUAT DI LEVEL ROOM

Bukan semua variasi dimasukkan ke tile.

Contoh:

```text
WALL TILE
      →
simple

ROOM
      →
Panel A
Panel B
Dark section
Pipe
Cable
Water stain
Access hatch
```

Dengan demikian tile tetap reusable.

---

# 32. SISTEM DECAL

Buat decal terpisah:

```text
WATER_STAIN
RUST_STAIN
DARK_GRIME
CRACK_SMALL
CRACK_LONG
OIL_STAIN
MOSS_SMALL
WARNING_MARK
PAINT_WEAR
```

Kemudian tempatkan manual/prosedural di Godot.

Ini akan membuat ruangan:

> **tidak terlihat seperti texture berulang.**

---

# 33. SISTEM SHADOW

Buat beberapa shadow overlay:

```text
SHADOW_SOFT_HORIZONTAL
SHADOW_WALL_EDGE
SHADOW_PIPE
SHADOW_PLATFORM
SHADOW_CORNER
SHADOW_UNDER_GRATE
```

Shadow ini jauh lebih penting daripada menambah detail pada concrete tile.

---

# 34. PERUBAHAN PENTING: DARI "TILESET FIRST" MENJADI "ROOM FIRST"

Workflow lama:

```text
Generate Tile
↓
Generate Tile
↓
Generate Tile
↓
Generate Prop
↓
Susun
↓
Semoga menyatu
```

Workflow baru:

```text
DESIGN ROOM
↓
TENTUKAN LIGHTING
↓
TENTUKAN VALUE
↓
TENTUKAN MATERIAL
↓
BUAT BASE TILE
↓
BUAT STRUCTURAL PIECES
↓
BUAT INFRASTRUCTURE
↓
BUAT DECALS
↓
ASSEMBLE DI GODOT
↓
COLOR / VALUE PASS
```

---

# 35. ROOM 01 HARUS DITES SEBAGAI GAMBAR UTUH

Jangan mengevaluasi:

> "Apakah beton_dinding.png bagus?"

Pertanyaan yang benar:

> "Apakah seluruh Room 01 terasa seperti satu tempat?"

Tile individual boleh terlihat sederhana.

Yang penting:

> **komposisi final terlihat kohesif.**

---

# 36. TEST A — BLUR TEST

Ambil screenshot Room 01.

Kemudian bayangkan screenshot tersebut diblur.

Jika:

```text
background
floor
platform
pipe
TENDRIL
```

masih memiliki hierarchy yang jelas:

> PASS.

Jika terlihat seperti kumpulan kotak:

> FAIL.

---

# 37. TEST B — GRAYSCALE TEST

Hilangkan warna.

Tanyakan:

> Apakah TENDRIL masih terbaca?

Jika tidak:

> environment terlalu kontras atau TENDRIL kurang terang.

---

# 38. TEST C — 5 SECOND TEST

Lihat ruangan selama lima detik.

Harus terbaca:

> **"Industrial maintenance room."**

Bukan:

> "Kumpulan tiles."

---

# 39. TEST D — TILE SEAM TEST

Perhatikan:

- dinding,
- lantai,
- grate.

Jika mata langsung mengikuti:

```text
32 | 32 | 32 | 32 | 32
```

maka tile pattern terlalu terlihat.

---

# 40. TEST E — PROP CONNECTION TEST

Untuk setiap prop:

> "Bagaimana benda ini terhubung dengan bangunan?"

Jika jawabannya tidak terlihat:

> tambahkan cable / pipe / bracket / shadow / mounting.

---

# 41. TARGET SCREENSHOT BERIKUTNYA

Jangan langsung meminta AI membuat seluruh ruangan baru.

Buat terlebih dahulu **ONE CONTROLLED WALL SECTION**.

Ukuran kira-kira:

```text
256 × 128 px
```

Isi:

```text
CONCRETE WALL
+
ONE PIPE
+
ONE CABLE TRAY
+
ONE PANEL
+
ONE LIGHT
+
ONE SMALL STAIN
```

Tidak ada TENDRIL dulu.

Tujuannya:

> menguji apakah semua material terlihat berasal dari gedung yang sama.

---

# 42. SETELAH CONTROLLED WALL PASS

Baru buat:

```text
FLOOR SECTION
```

Kemudian:

```text
GRATE SECTION
```

Kemudian:

```text
FULL ROOM
```

Jangan membangun full room sebelum material language berhasil.

---

# 43. TARGET VISUAL ROOM 01

Bayangan akhirnya:

```text
┌─────────────────────────────────────────┐
│             DARK CONCRETE               │
│                                         │
│   ─────────── PIPE ────────────────    │
│                    │                    │
│              ┌─────┴──────┐             │
│              │   PANEL    │             │
│              └─────┬──────┘             │
│                    │                    │
│       CABLE ───────┼──────              │
│                    │                    │
│             subtle stains               │
│                                         │
├─────────────────────────────────────────┤
│             CONCRETE FLOOR              │
│       ┌───────┐                         │
│       │ DRAIN │          GRATE          │
└───────┴───────┴─────────────────────────┘
```

Kemudian:

```text
                 🌿
                /  \
       TENDRIL ─── PIPE
```

TENDRIL menjadi kehidupan yang menyatukan seluruh sistem.

---

# 44. ART DIRECTION FINAL

Room 01 **tidak boleh terlihat seperti tileset yang disusun menjadi ruangan.**

Room 01 harus terlihat seperti:

> **satu ruang yang kebetulan dibangun menggunakan tileset.**

Perbedaannya sangat penting.

---

# 45. GOLDEN RULE BARU

> **Tile adalah material.**
>
> **Asset adalah konstruksi.**
>
> **Lighting menyatukan keduanya.**
>
> **Decal memberi usia.**
>
> **Infrastructure memberi fungsi.**
>
> **TENDRIL memberi kehidupan.**

Jangan meminta satu tile untuk membawa seluruh identitas ruangan.

---

# 46. PRIORITAS REVISI

Urutan kerja yang disarankan:

```text
[1] LOCK GLOBAL PALETTE
        ↓
[2] LOCK GLOBAL LIGHTING
        ↓
[3] REDUCE TILE CONTRAST
        ↓
[4] REDUCE TILE NOISE
        ↓
[5] MAKE WALL + FLOOR MATERIALLY RELATED
        ↓
[6] ADD LARGE-SCALE STRUCTURAL VARIATION
        ↓
[7] ADD PIPE / CABLE CONNECTIONS
        ↓
[8] ADD DECALS / WEAR
        ↓
[9] ADD DEPTH SHADOWS
        ↓
[10] ASSEMBLE FULL ROOM
        ↓
[11] ADD TENDRIL
        ↓
[12] FINAL VALUE / COLOR PASS
```

---

# 47. HAL YANG JANGAN DILAKUKAN PADA GENERASI BERIKUTNYA

Jangan:

- mengganti seluruh tileset dengan texture baru sekaligus,
- membuat concrete semakin detail,
- membuat metal semakin terang,
- menambah banyak warna,
- menambah banyak props hanya untuk mengisi ruang,
- membuat background lebih detail,
- meminta AI membuat full room sebelum material test,
- menggunakan lighting berbeda untuk setiap asset,
- membuat setiap tile memiliki highlight sendiri.

---

# 48. KALIMAT INSTRUKSI SINGKAT UNTUK PIXELLAB.AI

Jika membutuhkan versi pendek:

```text
This asset belongs to the same physical room as the other TENDRIL Room 01 assets.

Do NOT make it visually impressive by itself.

Make it visually compatible with the existing environment.

Use the same dark cold industrial palette,
the same low-contrast lighting,
the same shadow direction,
the same material language,
the same pixel cluster density,
and the same restrained texture level.

The asset must blend into a larger room instead of looking like an isolated sprite.

Prioritize cohesion over detail.
Prioritize material consistency over realism.
Prioritize readability over texture.
```

---

# 49. DEFINITION OF DONE

Room 01 dianggap berhasil apabila:

- [ ] Tidak lagi terasa seperti dungeon batu
- [ ] Concrete wall dan floor terasa berasal dari material yang sama
- [ ] Tile repeat tidak langsung terlihat
- [ ] Metal tidak terlalu kontras
- [ ] Background tidak menarik perhatian
- [ ] Infrastructure memiliki koneksi fisik
- [ ] Lighting seluruh asset konsisten
- [ ] Props tidak terlihat floating
- [ ] Room terbaca sebagai satu ruang
- [ ] TENDRIL tetap menjadi focal point
- [ ] TENDRIL terlihat mengambil alih infrastructure
- [ ] Screenshot grayscale masih memiliki hierarchy
- [ ] Screenshot 5 detik langsung terbaca sebagai service/maintenance room

---

# 50. FINAL STATEMENT

Masalah Room 01 sekarang bukan:

> **"Kita membutuhkan tile yang lebih bagus."**

Masalah sebenarnya adalah:

> **"Kita membutuhkan sistem visual yang membuat semua tile terlihat berasal dari tempat yang sama."**

Karena itu generasi berikutnya harus mengejar:

**COHESION > DETAIL**

**MATERIAL RELATIONSHIP > INDIVIDUAL BEAUTY**

**ROOM READABILITY > TILE QUALITY**

**GLOBAL LIGHTING > LOCAL EFFECTS**

Dan prinsip paling penting:

> **Kita tidak sedang membuat koleksi pixel-art assets.**
>
> **Kita sedang membuat satu ruangan yang kebetulan dibangun dari pixel-art assets.**

Itulah standar visual yang harus menjadi acuan untuk Room 01 dan kemudian diwariskan ke seluruh environment TENDRIL.
