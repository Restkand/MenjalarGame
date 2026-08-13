# TENDRIL — ENVIRONMENT DIRECTION V2
## Dari Tile-Based Room menjadi Modular Industrial Architecture

**Status:** ART DIRECTION REVISION
**Scope:** Room 01 / Single-Room Prototype
**Pipeline:** PixelLab.Ai → Modular Assets → Godot
**Visual Reference Direction:** Industrial side-scrolling exploration dengan rasa seperti fasilitas yang benar-benar dibangun manusia, bukan dungeon atau kumpulan texture tiles.

---

# 1. KEPUTUSAN UTAMA

Setelah meninjau beberapa hasil Room 01, masalahnya sekarang sudah cukup jelas:

> **PixelLab bukan masalah utamanya. Workflow `tile-first` yang kita gunakan yang tidak cocok dengan target visual TENDRIL.**

PixelLab tetap dapat digunakan untuk:

- environment,
- scene,
- map,
- tileset,
- sidescroller tileset,
- texture,
- modular environment pieces.

Namun kita tidak boleh menjadikan **tile 32×32 sebagai sumber utama bentuk ruangan**.

Mulai dari dokumen ini, prinsipnya berubah:

> **PixelLab = pembuat bahan visual dan architectural pieces.**
> **Godot = pembuat dan penyusun ruangan.**

---

# 2. MASALAH PADA HASIL ROOM SAAT INI

Screenshot terbaru sudah berhasil meninggalkan kesan dungeon batu.

Namun muncul masalah baru:

```text
TILE
+
TILE
+
TILE
+
PROP
+
PIPE
+
TENDRIL
```

masih terlihat sebagai kumpulan asset terpisah.

Yang kita inginkan:

```text
             SATU RUANGAN
                   │
        ┌──────────┴───────────┐
        │                      │
    ARCHITECTURE        INFRASTRUCTURE
        │                      │
        └──────────┬───────────┘
                   │
                TENDRIL
```

Room harus terasa sebagai **satu tempat fisik**, bukan tileset yang disusun menjadi tempat.

---

# 3. TARGET VISUAL

Target visual TENDRIL adalah:

> **Industrial service / maintenance facility yang gelap, tua, fungsional, dan perlahan dikolonisasi organisme hidup.**

Bukan:

- dungeon,
- cave,
- ruins,
- stone temple,
- fantasy laboratory,
- texture showcase.

Dan bukan pula:

> kumpulan tile beton yang sangat detail.

Targetnya adalah:

```text
ARCHITECTURE
      +
INFRASTRUCTURE
      +
LIGHTING
      +
WEAR
      +
BIOLOGICAL GROWTH
```

---

# 4. PRINSIP CARRION-LIKE YANG KITA AMBIL

Kita **tidak menyalin aset atau desain Carrion**.

Yang diambil hanya prinsip visual dan spatial:

- side-view environment,
- industrial facility,
- large architectural shapes,
- functional infrastructure,
- low-detail background,
- readable foreground,
- strong spatial composition,
- environment designed around creature traversal,
- pipes, cables, platforms, vents, doors, machinery,
- architecture feels human-made,
- organic creature contrasts with the facility.

Kemudian TENDRIL memiliki identitas sendiri:

> **gedung maintenance yang perlahan diambil alih oleh jaringan tumbuhan hidup.**

---

# 5. PERUBAHAN WORKFLOW

## WORKFLOW LAMA

```text
Generate Tile
↓
Generate Tile
↓
Generate Tile
↓
Generate Prop
↓
Generate Prop
↓
Susun di Godot
↓
Semoga terlihat menyatu
```

Masalah:

- lighting berbeda,
- scale berbeda,
- material berbeda,
- contrast berbeda,
- texture terlalu aktif,
- prop terlihat ditempel,
- tile pattern terlihat jelas.

---

# 6. WORKFLOW BARU

```text
DESIGN ROOM
↓
LOCK VISUAL LANGUAGE
↓
LOCK GLOBAL LIGHTING
↓
LOCK VALUE HIERARCHY
↓
CREATE MATERIAL
↓
CREATE ARCHITECTURAL PIECES
↓
CREATE INFRASTRUCTURE
↓
CREATE DECALS
↓
ASSEMBLE IN GODOT
↓
ADD TENDRIL
↓
FINAL LIGHT / VALUE PASS
```

Urutan ini wajib dipertahankan untuk Room 01.

---

# 7. PIXEL ART HIERARCHY BARU

Environment dibagi menjadi empat level.

```text
LEVEL 1
MATERIAL

LEVEL 2
ARCHITECTURE

LEVEL 3
INFRASTRUCTURE

LEVEL 4
COMPOSITION
```

---

# 8. LEVEL 1 — MATERIAL

Material dasar tetap boleh menggunakan tile kecil.

Contoh:

```text
concrete_dark
concrete_floor
metal_dark
metal_grate
wall_dark
```

Ukuran:

```text
16×16
32×32
64×64
```

sesuai kebutuhan.

Tetapi material tile harus:

- sederhana,
- low contrast,
- low noise,
- seamless,
- tidak memiliki focal point,
- tidak terlihat seperti batu bata,
- tidak terlihat seperti dungeon.

Tujuan:

> **Material harus menghilang ke dalam ruangan.**

---

# 9. LEVEL 2 — ARCHITECTURE

Ini adalah perubahan terpenting.

Kita mulai membuat **potongan struktur besar**, bukan hanya tile.

Contoh:

```text
WALL_SECTION_SMALL
128×128

WALL_SECTION_LARGE
256×128

FLOOR_SECTION_SMALL
128×64

FLOOR_SECTION_LARGE
256×64

CEILING_SECTION
256×64

STRUCTURAL_BEAM
128×32

SERVICE_PLATFORM
128×64

MAINTENANCE_LEDGE
96×32

WALL_RECESS
128×96

SERVICE_SHAFT
64×128
```

Potongan ini membuat ruangan mempunyai **bentuk arsitektur**.

---

# 10. LEVEL 3 — INFRASTRUCTURE

Infrastructure harus memberikan fungsi pada ruangan.

Contoh:

```text
PIPE_STRAIGHT
PIPE_VERTICAL
PIPE_CORNER
PIPE_T_JUNCTION

CABLE_TRAY
CABLE
CONDUIT

JUNCTION_BOX
ELECTRICAL_PANEL

VALVE
VENT
DRAIN

FLUORESCENT_LIGHT
WARNING_LIGHT

MAINTENANCE_HATCH
SERVICE_DOOR
```

Setiap benda harus terasa memiliki hubungan dengan bangunan.

---

# 11. LEVEL 4 — COMPOSITION

Godot menyusun:

```text
MATERIAL
+
ARCHITECTURE
+
INFRASTRUCTURE
+
DECALS
+
LIGHTING
+
TENDRIL
```

Sehingga hasil akhirnya adalah:

> **satu ruangan.**

Bukan:

> tileset showcase.

---

# 12. ROOM KIT STRUCTURE

Folder yang direkomendasikan:

```text
TENDRIL_ROOM01_KIT/

├── 01_MATERIAL/
│   ├── concrete_dark
│   ├── concrete_floor
│   ├── metal_dark
│   ├── metal_grate
│   └── wall_dark
│
├── 02_STRUCTURE/
│   ├── wall_small
│   ├── wall_large
│   ├── floor_small
│   ├── floor_large
│   ├── ceiling
│   ├── support_beam
│   ├── service_platform
│   ├── maintenance_ledge
│   ├── wall_recess
│   └── service_shaft
│
├── 03_INFRASTRUCTURE/
│   ├── pipe_straight
│   ├── pipe_vertical
│   ├── pipe_corner
│   ├── pipe_t_junction
│   ├── cable
│   ├── cable_tray
│   ├── conduit
│   ├── junction_box
│   ├── electrical_panel
│   ├── valve
│   ├── vent
│   └── drain
│
├── 04_PROPS/
│   ├── fluorescent_light
│   ├── warning_light
│   ├── maintenance_hatch
│   ├── service_door
│   └── small_machine
│
├── 05_DECALS/
│   ├── water_stain
│   ├── rust
│   ├── grime
│   ├── oil_stain
│   ├── crack_small
│   ├── paint_wear
│   └── warning_mark
│
└── 06_TENDRIL/
    ├── network
    ├── nodes
    ├── growth
    └── interaction_points
```

---

# 13. 32×32 TILE TIDAK DIHAPUS

Tile kecil tetap berguna.

Tetapi fungsinya:

> **material filler.**

Bukan:

> **arsitektur utama.**

Contoh:

```text
32×32 CONCRETE
        ↓
digunakan untuk mengisi
        ↓
WALL_SECTION_256×128
```

Jadi mata pemain melihat:

```text
SATU DINDING BESAR
```

bukan:

```text
32 | 32 | 32 | 32
32 | 32 | 32 | 32
32 | 32 | 32 | 32
```

---

# 14. MACRO SHAPE > MICRO DETAIL

Ini aturan visual baru.

Prioritas:

```text
MACRO SHAPE
████████████████████

STRUCTURAL DETAIL
────── PIPE ────────

FUNCTIONAL DETAIL
[ PANEL ]

MICRO TEXTURE
·······
```

Macro shape harus dibaca terlebih dahulu.

Micro texture hanya mendukung.

---

# 15. CONCRETE WALL

Concrete tidak perlu terlalu detail.

Gunakan:

- dark cold gray,
- flat surface,
- subtle seams,
- occasional stains,
- few irregular pixels.

Hindari:

- individual stone blocks,
- brick pattern,
- strong cracks everywhere,
- bright speckles,
- high-frequency noise.

Target:

> **wall terlihat sebagai bidang besar.**

---

# 16. FLOOR

Floor harus terlihat seperti struktur gedung.

Gunakan:

- large slab,
- structural seam,
- edge,
- shadow,
- drain,
- occasional wear.

Hindari:

- cobblestone,
- repeating stone pattern,
- extremely bright concrete,
- texture yang lebih menarik daripada karakter.

---

# 17. METAL

Metal harus menjadi bagian dari architecture.

Bukan sprite obstacle.

Tambahkan:

- edge,
- thickness,
- support,
- mounting,
- shadow,
- bolts secukupnya.

Contoh:

```text
       METAL WALKWAY
───────────────────────────
│                         │
─────────────┬─────────────
             │
         SUPPORT BEAM
             │
         ────┴────
```

---

# 18. GLOBAL LIGHTING

Semua asset harus dibuat seolah-olah berada di bawah satu lighting model.

Room 01:

```text
MAIN LIGHT
→
cold overhead fluorescent

AMBIENT
→
dark industrial blue-gray

TECHNICAL ACCENT
→
muted amber

BIOLOGICAL ACCENT
→
TENDRIL green
```

Tidak boleh:

```text
Wall → lighting A
Pipe → lighting B
Panel → lighting C
Floor → lighting D
```

---

# 19. VALUE HIERARCHY

Urutan visual:

```text
DARKEST
↓
Background
↓
Wall
↓
Floor
↓
Metal
↓
Props
↓
TENDRIL
BRIGHTEST
```

TENDRIL harus menjadi salah satu elemen paling mudah dibaca.

---

# 20. TENDRIL SEBAGAI COLOR ANCHOR

Environment:

```text
DARK
DESATURATED
LOW CONTRAST
```

TENDRIL:

```text
LIVING GREEN
HIGH READABILITY
SUBTLE GLOW
```

Jangan membuat environment terlalu colorful.

Jika semua benda terang:

> TENDRIL kehilangan identitas.

---

# 21. SETIAP PROP HARUS TERHUBUNG

Golden rule:

> **Every prop needs a connection.**

Connection dapat berupa:

- pipe,
- cable,
- conduit,
- bracket,
- mounting,
- support,
- shadow,
- wall recess.

Contoh:

```text
        CABLE
          │
          │
     ┌────┴─────┐
     │  PANEL   │
     └────┬─────┘
          │
       CONDUIT
```

Jangan hanya:

```text
[PANEL]
```

karena akan terlihat floating.

---

# 22. TENDRIL HARUS MENGGUNAKAN INFRASTRUCTURE

Ini merupakan identitas gameplay TENDRIL.

Environment bukan sekadar tempat karakter berada.

Environment adalah:

> **jaringan yang dapat dimanfaatkan organisme.**

Contoh:

```text
PIPE
──────────────╮
              │
              │
             🌿
```

TENDRIL dapat:

- mengikuti pipa,
- menempel pada conduit,
- masuk drain,
- melewati celah,
- menggunakan platform,
- menyusup di balik panel,
- menyebar melalui jaringan.

---

# 23. ARCHITECTURE = GAMEPLAY

Setiap elemen arsitektur harus berpotensi menjadi gameplay.

### PIPE

Movement route.

### CABLE

Possible traversal / hazard.

### DRAIN

Secret route.

### VENT

Small passage.

### MAINTENANCE GAP

Escape route.

### ELECTRICAL PANEL

Interaction / hazard.

### GRATE

Platform / visibility relationship.

Dengan demikian environment tidak hanya indah.

> **Environment mengajarkan cara bermain.**

---

# 24. ROOM 01 COMPOSITION

Target kasar:

```text
┌──────────────────────────────────────────┐
│             DARK WALL                    │
│                                          │
│   ───────────── PIPE ──────────────╮     │
│                                    │     │
│                              [PANEL]     │
│                                    │     │
│       ┌──────────────┐             │     │
│       │   PLATFORM   │             │     │
│       └──────┬───────┘             │     │
│              │                     │     │
├──────────────┴─────────────────────┼─────┤
│              FLOOR                 │     │
│                         🌿         │     │
└──────────────────────────────────────────┘
```

Komposisi harus memiliki:

- area traversal,
- vertical route,
- infrastructure route,
- secret gap,
- maintenance structure,
- tempat TENDRIL dapat beradaptasi.

---

# 25. CONTROLLED TEST SEBELUM FULL ROOM

Jangan langsung membuat full room.

Buat terlebih dahulu:

```text
256 × 128 px
```

isi:

```text
ONE WALL
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

Tanpa TENDRIL.

Tujuan:

> membuktikan bahwa seluruh asset terasa berasal dari gedung yang sama.

Jika ini gagal:

> jangan membuat full room.

---

# 26. TEST KOHESI

## TEST 1 — BLUR

Blur screenshot.

Harus tetap terbaca:

```text
wall
floor
structure
infrastructure
```

Jika berubah menjadi kumpulan kotak:

> FAIL.

---

# 27. TEST 2 — GRAYSCALE

Hilangkan warna.

TENDRIL tetap harus terbaca.

Jika tidak:

> environment terlalu terang atau TENDRIL kurang menonjol.

---

# 28. TEST 3 — FIVE SECOND TEST

Lihat screenshot selama lima detik.

Harus langsung terbaca:

> **industrial maintenance room.**

Bukan:

> dungeon.

Bukan:

> collection of tiles.

---

# 29. TEST 4 — TILE SEAM

Jika mata langsung menemukan:

```text
32 | 32 | 32 | 32 | 32
```

maka tile terlalu terlihat.

Perbaiki dengan:

- macro structure,
- decals,
- shadow,
- seams,
- large architectural pieces.

---

# 30. TEST 5 — PROP CONNECTION

Untuk setiap prop:

> "Bagaimana benda ini terhubung ke gedung?"

Jika tidak terlihat:

> tambahkan connection detail.

---

# 31. MASTER PROMPT — ROOM MATERIAL

Gunakan sebagai header setiap prompt PixelLab:

```text
TENDRIL ROOM 01 ENVIRONMENT STYLE,
same physical industrial maintenance facility,
dark abandoned service building,
cold desaturated industrial palette,
old concrete and dark steel,
subtle dampness,
restrained grime,
single unified room lighting,
cold overhead fluorescent lighting,
consistent shadow direction,
consistent highlight direction,
low contrast environment,
low texture noise,
large readable shapes,
strong architectural forms,
cohesive pixel cluster style,
consistent pixel density,
designed to integrate with other modular room pieces,
not an isolated sprite,
not a texture showcase,
not a dungeon,
not fantasy architecture
```

---

# 32. MASTER NEGATIVE PROMPT

```text
stone dungeon,
cave,
fantasy ruins,
medieval architecture,
brick wall,
cobblestone,
high contrast,
bright concrete,
white concrete,
high saturation,
random lighting,
random highlights,
random shadows,
independent asset lighting,
isolated sprite,
floating object,
overly detailed texture,
high frequency noise,
obvious tile repetition,
photorealistic,
3D,
smooth vector art,
ornamental fantasy,
decorative dungeon
```

---

# 33. PROMPT — LARGE ARCHITECTURAL WALL

```text
large modular industrial maintenance room wall section,
side-scrolling game environment,
dark cold concrete,
128x128 or 256x128 pixel art architectural piece,
large readable flat forms,
subtle panel seams,
very restrained grime,
small amount of wear,
single unified fluorescent lighting,
same shadow direction as the rest of the room,
low contrast,
low texture noise,
designed to connect with other wall sections,
designed as part of one continuous building,
not a standalone texture,
not a stone wall,
not brick,
not dungeon,
not fantasy
```

---

# 34. PROMPT — SERVICE PLATFORM

```text
large modular industrial maintenance platform,
side-scrolling pixel art,
dark steel and concrete construction,
visible structural thickness,
support brackets,
mounting points,
subtle edge highlights,
dark underside shadow,
same cold industrial lighting as TENDRIL ROOM 01,
low contrast,
restrained texture,
functional human-built architecture,
designed to connect with floor and wall,
designed as a modular architectural piece,
not a floating platform,
not a fantasy platform,
not a standalone sprite
```

---

# 35. PROMPT — PIPE SYSTEM

```text
industrial maintenance pipe system,
side-scrolling pixel art,
dark steel pipe,
large readable shape,
straight pipe section,
90 degree elbow,
vertical section,
T-junction,
subtle metal highlights,
dark underside,
consistent cold fluorescent lighting,
same material language as TENDRIL ROOM 01,
designed to connect physically to walls and machinery,
functional infrastructure,
low texture noise,
not decorative,
not fantasy,
not isolated sprite
```

---

# 36. PROMPT — ELECTRICAL PANEL

```text
industrial electrical control panel mounted on a maintenance room wall,
side-scrolling pixel art,
dark steel enclosure,
subtle amber indicator lights,
visible conduit entering and leaving the panel,
mounting brackets,
small service details,
same cold industrial lighting as TENDRIL ROOM 01,
low contrast body,
restrained highlights,
functional human-built infrastructure,
must visually connect to the wall,
not floating,
not futuristic sci-fi,
not fantasy
```

---

# 37. PROMPT — DECALS

Decals harus dibuat terpisah.

Contoh:

```text
small industrial water stain,
pixel art decal,
transparent background,
dark muted gray-brown,
very low contrast,
irregular organic shape,
subtle aging,
designed to overlay a concrete wall,
not a complete tile,
not a full texture
```

Dengan sistem ini, variasi ruangan dibuat di Godot.

---

# 38. JANGAN MEMBUAT FULL ROOM TERLEBIH DAHULU

Sebelum Room 01 selesai, pipeline wajib:

```text
CONTROLLED WALL
      ↓
CONTROLLED FLOOR
      ↓
CONTROLLED PLATFORM
      ↓
PIPE SYSTEM
      ↓
PANEL
      ↓
DECALS
      ↓
ASSEMBLE ROOM
      ↓
TENDRIL
```

Jika salah satu bagian tidak menyatu:

> perbaiki asset tersebut, bukan reroll seluruh room.

---

# 39. GODOT SEBAGAI ROOM COMPOSITOR

Godot bertanggung jawab terhadap:

- tile placement,
- architectural assembly,
- collision,
- lighting,
- depth,
- parallax,
- shadow,
- gameplay routes,
- TENDRIL network,
- interactive surfaces.

PixelLab bertanggung jawab terhadap:

- visual assets,
- architectural pieces,
- materials,
- props,
- decals.

---

# 40. HASIL YANG DICARI

Kita ingin screenshot akhir terlihat seperti:

```text
                 ONE BUILDING
                      │
       ┌──────────────┼───────────────┐
       │              │               │
   CONCRETE         METAL           PIPE
       │              │               │
       └──────────────┼───────────────┘
                      │
                 MAINTENANCE
                      │
                    🌿
                      │
                 TENDRIL
```

Bukan:

```text
tile tile tile tile
tile tile tile tile
tile tile tile tile
+ props
+ character
```

---

# 41. DEFINITION OF DONE

Room 01 dianggap berhasil jika:

- [ ] Terasa sebagai maintenance/service room
- [ ] Tidak terasa seperti dungeon
- [ ] Tidak terasa seperti kumpulan tileset
- [ ] Concrete wall dan floor memiliki hubungan material
- [ ] Metal memiliki hubungan material dengan concrete
- [ ] Semua asset memiliki lighting yang sama
- [ ] Tile repeat tidak menjadi fokus
- [ ] Macro architecture terbaca
- [ ] Props memiliki koneksi fisik
- [ ] Background tenang
- [ ] Foreground jelas
- [ ] TENDRIL menjadi focal point
- [ ] Infrastructure dapat dimanfaatkan sebagai gameplay
- [ ] Ruangan dapat dibangun ulang dengan modular pieces
- [ ] Asset dapat digunakan kembali untuk room berikutnya

---

# 42. FINAL ART DIRECTION

Mulai sekarang:

> **Jangan membuat tileset yang kebetulan bisa menjadi ruangan.**

Buat:

> **arsitektur modular yang kebetulan dapat dirakit menjadi banyak ruangan.**

Prinsip utama:

```text
ARCHITECTURE > TEXTURE
MACRO SHAPE > MICRO DETAIL
COHESION > INDIVIDUAL BEAUTY
GLOBAL LIGHTING > LOCAL EFFECTS
FUNCTION > DECORATION
ROOM > TILE
```

Dan untuk TENDRIL:

> **Human infrastructure creates the maze.**
>
> **TENDRIL learns how to inhabit it.**

Inilah fondasi environment yang harus digunakan untuk Room 01 dan kemudian diperluas ke seluruh gedung TENDRIL.
