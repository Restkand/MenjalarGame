# TENDRIL — SERVICE / MAINTENANCE ROOM ART DIRECTION
## Revisi Visual Single Room agar Terasa Seperti Ruang Servis Gedung, Bukan Ruang Batu / Dungeon

**Status:** ART DIRECTION REVISION
**Target:** PixelLab.Ai + Godot
**Scope:** Room 01 / Single Room
**Prioritas:** Environment readability, industrial identity, functional architecture

---

# 1. MASALAH VISUAL SAAT INI

Prototype Room 01 saat ini sudah memiliki:

- lantai,
- dinding,
- platform,
- background,
- kabel,
- jaringan TENDRIL.

Namun secara keseluruhan ruangan masih terbaca seperti:

> **STONE CAVE / DUNGEON / UNDERGROUND RUINS**

bukan:

> **SERVICE ROOM / MAINTENANCE ROOM / BUILDING INFRASTRUCTURE**

Masalah utamanya bukan sekadar tekstur.

Masalah utamanya adalah **bahasa bentuk lingkungan**.

Saat hampir seluruh permukaan menggunakan blok beton/batu yang berulang, pemain akan membaca:

```text
BLOCK
BLOCK
BLOCK
BLOCK
BLOCK
```

sebagai:

> dungeon / bunker / cave

Padahal yang kita inginkan:

```text
WALL
│
├── PIPE
├── CABLE TRAY
├── CONDUIT
├── VALVE
├── ACCESS PANEL
├── DRAIN
├── MAINTENANCE PLATFORM
├── SUPPORT BRACKET
└── WARNING MARKING
```

sehingga pemain membaca:

> **bangunan yang memiliki fungsi.**

---

# 2. TARGET VISUAL BARU

Room 01 harus terasa seperti:

> **ruang servis tersembunyi di dalam gedung tua yang masih memiliki infrastruktur aktif.**

Referensi konsep:

- maintenance corridor,
- utility room,
- electrical service room,
- mechanical room,
- plumbing access room,
- basement maintenance area,
- industrial building service shaft.

Bukan:

- cave,
- ancient ruins,
- stone dungeon,
- fantasy castle,
- natural underground cavern.

---

# 3. KALIMAT VISUAL UTAMA

Gunakan prinsip:

> **FUNCTION OVER ROCK.**

Jika sebuah elemen ada di ruangan, pemain harus dapat membayangkan:

> "Untuk apa benda ini ada di sini?"

Contoh:

```text
PIPE
→ membawa air

CABLE
→ membawa listrik/data

VALVE
→ mengatur aliran

PANEL
→ akses teknisi

DRAIN
→ membuang air

BRACKET
→ menopang instalasi

GRATE
→ akses maintenance

LIGHT
→ penerangan kerja
```

Ini membuat environment terasa seperti tempat nyata.

---

# 4. PERUBAHAN TERBESAR: JANGAN MEMBUAT SEMUA DINDING MENJADI BATU

## CURRENT

```text
████████████████████
████████████████████
████████████████████
████████████████████
```

Terlalu banyak blok identik.

## TARGET

```text
┌──────────────────┐
│  PIPE =======    │
│        ┌──────┐  │
│  CABLE │ PANEL│  │
│        └──────┘  │
│   │              │
│   │ PIPE         │
└──────────────────┘
```

Dinding menjadi **background architecture**.

Bukan objek utama.

---

# 5. HIRARKI VISUAL ENVIRONMENT

Gunakan tiga lapisan.

## LAYER 1 — STRUCTURE

Elemen besar:

- concrete wall,
- concrete floor,
- ceiling,
- support column,
- large structural beam.

Tujuan:

> membentuk ruangan.

---

## LAYER 2 — INFRASTRUCTURE

Elemen yang membuat ruangan menjadi SERVICE ROOM:

- pipes,
- cable trays,
- conduits,
- ventilation ducts,
- junction boxes,
- electrical panels,
- valves,
- drains,
- maintenance rails.

Tujuan:

> memberi identitas fungsi.

---

## LAYER 3 — WEAR / LIFE

Detail kecil:

- noda air,
- karat,
- kabel longgar,
- baut,
- label,
- warning stripe,
- lumut,
- TENDRIL,
- daun,
- retakan kecil.

Tujuan:

> membuat ruangan terasa sudah digunakan dan mulai diambil alih tanaman.

---

# 6. PROPORSI VISUAL

Target kasar:

```text
STRUCTURE        60%
INFRASTRUCTURE   25%
WEAR / DETAIL    10%
TENDRIL / LIFE    5%
```

Catatan:

TENDRIL harus tetap menjadi focal point ketika gameplay berlangsung.

---

# 7. DINDING

Dinding jangan dibuat seperti batu bata dungeon.

Gunakan:

> **flat concrete / painted concrete / industrial wall**

Ciri:

- bidang besar,
- panel sambungan,
- garis konstruksi,
- noda,
- retakan struktural ringan,
- mounting bracket,
- kabel,
- pipa.

Kurangi:

- batu individual,
- outline setiap blok,
- pola bata terlalu seragam,
- bentuk batu natural.

---

# 8. CONCRETE WALL PIXEL ART

Untuk PixelLab.Ai:

### TARGET

```text
industrial concrete wall
dark utility building
large flat concrete panels
subtle seams
small cracks
water stains
old maintenance environment
```

### HINDARI

```text
stone wall
cave wall
fantasy dungeon
ancient ruins
medieval castle
brick dungeon
rock formation
natural cave
```

Negative prompt sangat penting.

---

# 9. LANTAI

Lantai saat ini dapat terbaca terlalu seperti:

> batu blok.

Untuk service room, lantai harus lebih menyerupai:

> **concrete maintenance floor**

Gunakan:

- slab beton,
- garis sambungan,
- drain,
- metal grate,
- noda minyak/air,
- baut,
- retakan tipis,
- area lembap.

Contoh:

```text
┌──────────────────────┐
│ concrete slab        │
│       ┌──────┐       │
│       │ DRAIN│       │
│       └──────┘       │
│   stain       stain  │
└──────────────────────┘
```

---

# 10. PLATFORM

Platform sebaiknya tidak semuanya terlihat seperti blok batu.

Variasikan:

## CONCRETE PLATFORM

Untuk struktur permanen.

## METAL GRATE

Untuk maintenance walkway.

## METAL PLATFORM

Untuk area teknisi.

## PIPE SUPPORT

Untuk jalur kecil.

## WOOD

Hanya pada bagian tua/rusak tertentu.

Tujuan:

> pemain melihat bahwa platform memiliki konstruksi.

---

# 11. PIPE SYSTEM

Pipa harus menjadi salah satu signature Room 01.

Minimal tiga ukuran:

```text
SMALL PIPE
MEDIUM PIPE
LARGE PIPE
```

Arah:

```text
HORIZONTAL
VERTICAL
ELBOW
T-JUNCTION
```

Tambahkan:

- clamp,
- bracket,
- valve,
- connector.

Pipa dapat menjadi:

- visual landmark,
- jalur TENDRIL,
- pembatas ruang,
- background depth.

---

# 12. CABLE SYSTEM

Kabel yang sekarang sudah membantu, tetapi perlu diperluas menjadi:

```text
Cable
 ↓
Cable Tray
 ↓
Junction Box
 ↓
Electrical Panel
```

Jangan membuat kabel hanya sebagai garis.

Kabel harus terlihat memiliki:

> **asal dan tujuan.**

Contoh:

```text
[POWER PANEL]
      │
      │
──────┴─────────
      │
      └──── [MACHINE]
```

---

# 13. ELECTRICAL PANEL

Tambahkan satu panel servis.

Visual:

```text
┌─────────────┐
│  POWER      │
│  ┌───────┐  │
│  │ ||||| │  │
│  └───────┘  │
│    ○ ○ ○    │
└─────────────┘
```

Panel tidak harus interaktif pada prototype.

Fungsinya pertama-tama:

> **menjelaskan bahwa ruangan memiliki fungsi maintenance.**

---

# 14. VALVE / PIPE CONTROL

Tambahkan valve besar.

Contoh:

```text
       ╭────╮
───────┤ O ├───────
       ╰────╯
```

Valve adalah visual shortcut yang sangat kuat.

Satu valve dapat membuat ruangan langsung terasa seperti:

> mechanical / plumbing room.

---

# 15. DRAIN

Tambahkan drain di lantai.

Drain berguna untuk:

- menunjukkan fungsi air,
- menciptakan landmark,
- memberi area lembap,
- menjadi tempat TENDRIL berkembang.

Contoh:

```text
──────────────
     ┌─────┐
     │ ▓▓▓ │
     └─────┘
──────────────
```

---

# 16. VENTILATION

Tambahkan:

- ventilation duct,
- exhaust fan,
- vent grille.

Vent tidak harus besar.

Satu atau dua elemen cukup.

Tujuan:

> memperkuat kesan bahwa ini bagian dari gedung yang memiliki sistem mekanis.

---

# 17. MAINTENANCE ACCESS

Tambahkan:

- access hatch,
- service door,
- maintenance panel,
- removable wall panel.

Ini jauh lebih efektif daripada menambah batu.

Contoh:

```text
┌─────────────────┐
│   ACCESS PANEL  │
│ ┌─────────────┐ │
│ │             │ │
│ │    ────     │ │
│ │             │ │
│ └─────────────┘ │
└─────────────────┘
```

---

# 18. WARNING MARKINGS

Gunakan sangat sedikit tetapi jelas.

Contoh:

```text
YELLOW / BLACK
HAZARD STRIPE
```

Gunakan pada:

- kabel,
- electrical panel,
- edge platform,
- maintenance hazard.

Jangan membuat seluruh ruangan kuning.

Tujuan:

> aksen industri.

---

# 19. LIGHTING

Lighting harus terasa seperti gedung servis.

Gunakan:

- ceiling fluorescent,
- wall utility lamp,
- emergency light,
- small indicator light.

Bukan:

- torch,
- fantasy lantern,
- magical light.

Target:

```text
cold industrial darkness
+
small artificial lights
+
green biological glow
```

---

# 20. KONTRAS TENDRIL

Ini sangat penting.

Environment:

```text
dark
desaturated
industrial
cold
```

TENDRIL:

```text
organic
green
alive
subtle glow
```

Dengan demikian:

> **TENDRIL terlihat seperti kehidupan asing yang tumbuh di antara mesin.**

---

# 21. JANGAN MEMBUAT BACKGROUND TERLALU DETAIL

Pixel art environment harus mempunyai:

```text
FOREGROUND
MIDGROUND
BACKGROUND
```

### BACKGROUND

Sangat sederhana.

### MIDGROUND

Pipa, panel, kabel.

### FOREGROUND

Platform, railing, TENDRIL interaction.

Jika semua detail memiliki kontras sama:

> layar akan menjadi noise.

---

# 22. DEPTH

Gunakan overlap:

```text
BACKGROUND WALL
      ↓
PIPE
      ↓
CABLE
      ↓
PLATFORM
      ↓
TENDRIL
```

Ini lebih efektif daripada membuat tekstur batu sangat detail.

---

# 23. RUANGAN HARUS TERASA "BUILT"

Pertanyaan evaluasi:

> Apakah pemain dapat membayangkan manusia pernah memasang semua benda ini?

Jika YA:

> service room berhasil.

Jika terasa seperti:

> "batu muncul sendiri"

maka environment masih terlalu dungeon.

---

# 24. PROMPT MASTER — PIXELLAB.AI

Gunakan prompt dasar:

```text
2D pixel art industrial building service room,
dark abandoned maintenance room inside a large building,
old concrete utility architecture,
large flat concrete wall panels,
subtle construction seams,
industrial pipes running horizontally and vertically,
pipe elbows and valves,
electrical cable trays,
bundled cables,
junction boxes,
electrical maintenance panel,
ventilation duct,
metal maintenance platforms,
metal grates,
floor drain,
service access hatch,
small warning labels,
industrial fluorescent lights,
water stains,
rust and wear,
small cracks,
damp areas,
subtle overgrown green plant roots and tendrils invading the infrastructure,
dark desaturated industrial environment,
clear readable silhouettes,
game-ready environment,
side-view 2D platformer,
metroidvania environment,
consistent tile-based pixel art,
limited color palette,
high readability,
no characters,
no enemies,
no fantasy architecture
```

---

# 25. NEGATIVE PROMPT — WAJIB

```text
stone dungeon,
fantasy dungeon,
cave,
natural rock,
medieval architecture,
ancient ruins,
castle,
brick dungeon,
masonry cave,
giant rocks,
stalactites,
stalagmites,
fantasy temple,
magical architecture,
ornamental fantasy decoration,
random rocks,
natural stone formation,
overly detailed stone texture,
realistic 3D,
photorealistic,
smooth vector art,
anime,
character,
monster,
boss,
text,
UI
```

---

# 26. PROMPT — CONCRETE WALL TILE

Untuk mengganti `beton_dinding.png`:

```text
seamless 32x32 pixel art tile,
industrial utility room concrete wall,
flat dark gray concrete panel,
subtle horizontal and vertical construction seams,
small cracks,
water stains,
slight grime,
industrial building interior,
minimal texture,
readable at small scale,
consistent pixel clusters,
limited palette,
tileable,
no individual stones,
no brick pattern,
no cave,
no fantasy dungeon,
no rocks,
no 3D
```

Target:

> **panel beton**, bukan batu.

---

# 27. PROMPT — FLOOR TILE

Untuk mengganti `beton_lantai.png`:

```text
seamless 32x32 pixel art tile,
industrial maintenance room concrete floor,
flat dark gray slab,
subtle expansion seam,
small scratches,
water stains,
oil stains,
tiny bolts,
slightly worn surface,
industrial utility building,
tileable,
clean readable pixel clusters,
limited palette,
no cobblestone,
no rocks,
no natural stone,
no dungeon floor,
no fantasy,
no 3D
```

---

# 28. PROMPT — BACKGROUND TILE

Untuk mengganti `latar.png`:

```text
seamless 32x32 pixel art background tile,
dark industrial service room wall,
very low contrast,
flat deep blue gray concrete,
subtle panel variation,
minimal texture,
soft grime,
large architectural surfaces,
desaturated,
designed as background for a 2D pixel art platformer,
tileable,
low visual noise,
no rocks,
no stone blocks,
no cave,
no dungeon,
no fantasy
```

Background harus **lebih sederhana daripada foreground**.

---

# 29. PROMPT — CABLE ASSET

Untuk memperbaiki `kabel.png`:

```text
2D pixel art industrial electrical cable asset,
dark maintenance room cable,
bundled black cables with subtle green-gray highlights,
small cable clamps,
straight horizontal section,
vertical section,
slight sag,
junction connector,
clean readable pixel clusters,
side-view platformer asset,
industrial utility building,
tileable modular pieces,
limited palette,
no fantasy,
no organic vine,
no rope,
no wire glowing magically
```

---

# 30. PROMPT — PIPE ASSET

Buat sebagai modular kit:

```text
2D pixel art industrial pipe tileset,
dark metal utility pipes,
horizontal pipe,
vertical pipe,
90 degree elbow,
T-junction,
pipe clamp,
large valve,
small valve,
industrial maintenance room,
aged metal,
subtle rust,
clean pixel clusters,
modular game asset,
side-view 2D platformer,
limited palette,
transparent background,
no fantasy,
no steampunk ornament,
no cave
```

---

# 31. PROMPT — ELECTRICAL PANEL

```text
2D pixel art electrical maintenance panel,
industrial utility room wall mounted electrical box,
dark gray metal casing,
small switches,
warning indicator lights,
cables entering from top and bottom,
aged paint,
small warning marking,
compact readable sprite,
side-view pixel art,
limited palette,
game-ready,
no character,
no fantasy,
no steampunk,
no 3D
```

---

# 32. PROMPT — DRAIN

```text
32x32 2D pixel art industrial floor drain,
square metal drain grate,
dark wet concrete surrounding it,
small water stain,
utility maintenance room,
simple readable pixel clusters,
tileable floor-compatible asset,
limited palette,
side-view game asset,
no dungeon,
no cave,
no fantasy
```

---

# 33. PROMPT — MAINTENANCE GRATE

```text
2D pixel art industrial maintenance metal grate,
dark steel platform,
repeating rectangular holes,
support beams underneath,
side-view platformer platform,
industrial service room,
aged metal,
small rust details,
modular game asset,
clean silhouette,
limited palette,
no fantasy,
no stone,
no dungeon
```

---

# 34. PROMPT — ROOM DECORATION KIT

Jangan generate seluruh ruangan setiap kali.

Buat asset secara modular:

```text
PIPE
PIPE ELBOW
VALVE
CABLE
CABLE TRAY
JUNCTION BOX
ELECTRICAL PANEL
VENT
DRAIN
GRATE
ACCESS PANEL
LIGHT
WARNING SIGN
BRACKET
SUPPORT BEAM
```

Kemudian susun semuanya di Godot.

Ini jauh lebih konsisten daripada meminta AI menghasilkan satu ruangan final setiap kali.

---

# 35. ROOM COMPOSITION RULE

Gunakan pola:

```text
STRUCTURE
+
INFRASTRUCTURE
+
WEAR
+
BIOLOGICAL INVASION
```

Contoh:

```text
CONCRETE WALL
      +
PIPE
      +
CABLE
      +
WATER STAIN
      +
TENDRIL
```

Bukan:

```text
CONCRETE BLOCK
+
CONCRETE BLOCK
+
CONCRETE BLOCK
+
TENDRIL
```

---

# 36. TENDRIL HARUS MENYUSUP KE INFRASTRUKTUR

Ini bagian penting dari identitas game.

TENDRIL jangan hanya tumbuh di dinding.

TENDRIL harus:

- melilit pipa,
- mengikuti kabel,
- keluar dari retakan panel,
- tumbuh di sekitar drain,
- menutupi junction box,
- masuk celah maintenance,
- menjalar di bawah platform.

Dengan demikian hubungan karakter dan environment menjadi visual.

---

# 37. CONTOH HUBUNGAN VISUAL

```text
PIPE
──────────────────────
       ╲
        ╲ 🌿
         ╲
          🌿─────
```

atau:

```text
┌───────────────┐
│ ELECTRICAL    │
│ PANEL         │
│       🌿      │
└───────┬───────┘
        │
      CABLE
```

atau:

```text
WALL
────────────────
▓▓▓▓▓  🌿  ▓▓▓
▓▓▓▓▓ 🌿   ▓▓▓
────────────────
```

Environment harus terasa **ditumbuhi**, bukan sekadar ditempeli tanaman.

---

# 38. ROOM 01 VISUAL IDENTITY

Target final:

```text
        INDUSTRIAL
             │
             ▼
       SERVICE ROOM
             │
      ┌──────┴──────┐
      ▼             ▼
   CONCRETE       METAL
      │             │
      └──────┬──────┘
             ▼
       INFRASTRUCTURE
             │
      ┌──────┼──────┐
      ▼      ▼      ▼
    PIPE   CABLE   DRAIN
             │
             ▼
          TENDRIL
```

TENDRIL adalah **kehidupan yang mengambil alih infrastruktur**.

---

# 39. ART TEST — 5 SECOND RULE

Tampilkan screenshot Room 01 selama ±5 detik.

Tanyakan:

### Q1
Apakah saya langsung berpikir:

> "Ini ruang servis?"

Jika tidak → tambah infrastructure.

### Q2
Apakah saya berpikir:

> "Ini dungeon batu?"

Jika ya → kurangi stone-like texture.

### Q3
Apakah saya dapat melihat:

> pipe / cable / panel / maintenance structure?

Jika tidak → environment terlalu kosong.

### Q4
Apakah TENDRIL terlihat jelas?

Jika tidak → kurangi background contrast.

---

# 40. PRIORITAS REVISI SAAT INI

Jangan mengubah semuanya sekaligus.

Urutan:

```text
1. GANTI DINDING BATU
        ↓
2. GANTI LANTAI BATU
        ↓
3. TAMBAHKAN PIPE
        ↓
4. TAMBAHKAN CABLE TRAY
        ↓
5. TAMBAHKAN ELECTRICAL PANEL
        ↓
6. TAMBAHKAN DRAIN
        ↓
7. TAMBAHKAN METAL GRATE
        ↓
8. TAMBAHKAN LIGHT
        ↓
9. TAMBAHKAN WEAR
        ↓
10. BIARKAN TENDRIL MENGAMBIL ALIH
```

---

# 41. JANGAN TERLALU CEPAT MEMBUAT "ABANDONED"

Ada perbedaan:

```text
ABANDONED
```

dan:

```text
OLD MAINTENANCE ROOM
```

Room 01 sebaiknya:

> **masih terlihat dibangun untuk fungsi tertentu, tetapi sudah tua dan mulai ditinggalkan.**

Jangan membuat semuanya:

- hancur,
- runtuh,
- penuh lumut,
- penuh karat,
- gelap total.

Jika terlalu rusak, identitas fungsi bangunan hilang.

---

# 42. TARGET VISUAL FINAL

Bayangkan pemain masuk dan langsung melihat:

```text
[CONCRETE WALL]

      PIPE ==================
             │
             │
        [VALVE]

   [ELECTRICAL PANEL]
          │ │ │
          │ │ │
──────────┼─┼─┼──────── CABLE

              🌿
             /  \
        TENDRIL NETWORK

────────────────────────────
       METAL GRATE

          [DRAIN]
```

Pemain harus langsung memahami:

> **"Ini bagian servis dari sebuah gedung."**

Kemudian TENDRIL membuat tempat tersebut terasa hidup.

---

# 43. GOLDEN RULE

> **Jangan mencoba membuat Service Room dengan tekstur yang lebih realistis.**
>
> Buat Service Room dengan **objek yang lebih fungsional.**

Identitas ruangan datang dari:

```text
PIPE
CABLE
PANEL
VALVE
DRAIN
DUCT
GRATE
LIGHT
ACCESS
```

bukan dari:

```text
HIGH DETAIL STONE
```

---

# 44. FINAL ART DIRECTION

> **TENDRIL berada di dalam gedung, bukan di dalam gua.**
>
> Beton adalah struktur.
>
> Logam adalah infrastruktur.
>
> Pipa membawa air.
>
> Kabel membawa listrik.
>
> Panel menyimpan sistem.
>
> Drain membawa air keluar.
>
> Lampu menerangi tempat kerja.
>
> Retakan menunjukkan usia.
>
> Dan tanaman perlahan mengambil alih semuanya.
>
> **Itulah Service Room TENDRIL.**
