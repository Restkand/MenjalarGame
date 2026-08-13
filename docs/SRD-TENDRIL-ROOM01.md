# TENDRIL — SINGLE ROOM DESIGN MAP
## Vertical Slice Ruangan Pertama untuk Menguji Adaptasi Karakter terhadap Lingkungan

**Status:** FOUNDATION / VERTICAL SLICE
**Target:** Godot + PixelLab.Ai
**Fokus:** Satu ruangan terlebih dahulu
**Tujuan:** Membuktikan bahwa TENDRIL dapat beradaptasi terhadap lingkungan melalui MERAMBAT, LEPAS, material permukaan, energi, kamuflase, pertumbuhan, dan kemampuan inti.

---

# 1. TUJUAN VERTICAL SLICE

Sebelum membuat gedung besar, buat **satu ruangan kecil, padat, dan dapat membuktikan identitas game**.

Ruangan pertama harus menjawab:

- Apakah TENDRIL terasa hidup?
- Apakah MERAMBAT dan LEPAS terasa berbeda?
- Apakah lingkungan memengaruhi cara bergerak?
- Apakah jaringan terasa seperti rumah sekaligus jalan?
- Apakah pemain menggunakan lingkungan sebagai bagian dari strategi?
- Apakah material berbeda menghasilkan perilaku berbeda?
- Apakah pemain belajar tanpa tutorial panjang?
- Apakah TENDRIL terasa kecil dibanding bangunan?

Prinsip utama:

> **Room 01 bukan tutorial panjang. Room 01 adalah eksperimen biologis kecil yang memperlihatkan bagaimana TENDRIL hidup di dalam gedung.**

---

# 2. KONSEP RUANGAN

## ROOM 01 — SERVICE / MAINTENANCE ROOM

Ruangan servis tua di dalam gedung.

Isi utama:

- pipa,
- kabel,
- retakan beton,
- kayu tua,
- saluran air,
- celah sempit,
- permukaan lembap,
- jaringan TENDRIL,
- satu sumber cahaya,
- satu jalur terbuka,
- satu area berbahaya.

Lingkungan harus terasa seperti:

> **bangunan tua yang perlahan telah menjadi ekosistem bagi tanaman.**

---

# 3. SKALA

Target prototype:

```text
LEBAR  : ±24–32 tile
TINGGI : ±14–18 tile
```

Ruangan tidak boleh terlalu besar.

Pemain harus dapat membangun mental map dengan cepat.

Struktur:

```text
          CEILING / NETWORK
    🌿🌿───────────────🌿
       │              │
       │   AREA HIGH  │
       │              │
   🌿──┤              ├──
       │
 START │      OPEN AREA
  🌿───┴───────────────
                      │
      CRACK      CABLE│
──────────────┬───────┴────────
      WOOD    │     DRAIN
```

Layout ini adalah **logic map**, bukan final art.

---

# 4. FILOSOFI LAYOUT

Ruangan harus memiliki kombinasi:

```text
LOW
MID
HIGH
```

dan:

```text
OPEN
TIGHT
HIDDEN
DANGEROUS
```

Sehingga TENDRIL harus mempertimbangkan:

- permukaan,
- ketinggian,
- celah,
- jaringan,
- material,
- cahaya,
- energi,
- jalur aman.

---

# 5. AREA A — HOME / ROOT NETWORK

Tempat awal.

TENDRIL memulai dalam keadaan terhubung.

Fungsi:

- MERAMBAT,
- memulihkan energi,
- bersembunyi,
- berpindah antar jaringan,
- mengamati lingkungan.

Visual:

```text
🌿🌿🌿
🌿  🌿────
🌿    │
──────┘
```

Area harus terasa:

> **aman, lembap, hidup, dan familiar.**

---

# 6. AREA B — OPEN FLOOR

Area pertama untuk LEPAS.

Flow:

```text
NETWORK
   ↓
DETACH
   ↓
OPEN FLOOR
```

Pemain belajar:

- gravitasi,
- CRAWL,
- lompat,
- jatuh,
- energi terkikis,
- kembali ke jaringan.

Jangan gunakan musuh berat.

Tujuan:

> **mengajari tubuh TENDRIL.**

---

# 7. AREA C — CRACK / SMALL GAP

Celah kecil pada dinding.

```text
────────
██  🌿
██    ─────
██        │
██────────┘
```

Fungsi:

> ukuran kecil TENDRIL menjadi kemampuan.

TENDRIL dapat:

- masuk,
- melewati,
- menemukan jaringan tersembunyi.

---

# 8. AREA D — WALL / CEILING ROUTE

Rute vertikal yang memperlihatkan keunggulan MERAMBAT.

TENDRIL dapat:

- menempel,
- bergerak di dinding,
- berpindah ke plafon,
- melewati rute yang sulit/tidak mungkin saat LEPAS.

```text
        🌿────🌿
       ╱
      🌿
      │
      │
──────┴────────
```

Tujuan:

> pemain memahami bahwa ruang TENDRIL bukan hanya kiri-kanan.

---

# 9. AREA E — MATERIAL TEST

Perkenalkan material:

```text
LEMBAP
RETAK
KAYU
BETON
KABEL
LOGAM
PIPA AIR
```

Tidak semuanya harus memiliki sistem kompleks pada vertical slice.

Yang penting:

> **permukaan bukan sekadar dekorasi.**

---

# 10. MATERIAL INTERACTION

| Material | Perilaku utama | Fungsi desain |
|---|---|---|
| LEMBAP | Tumbuh cepat | Growth route |
| RETAK | Bisa ditembus/dikembangkan | Shortcut |
| KAYU | Rapuh | Breakable route |
| BETON | Sulit ditembus | Boundary |
| LOGAM | Butuh adaptasi | Alternative route |
| KABEL | Bahaya listrik | Hazard |
| PIPA AIR | Air/nutrisi | Growth landmark |
| PESTISIDA | Menyebar lewat jaringan | Environmental threat |

---

# 11. AREA F — LIGHT / VISIBILITY

Buat variasi cahaya:

```text
DARK → DIM → BRIGHT
```

Cahaya menjadi bagian dari gameplay.

Jaringan berdaun:

```text
TERSEMBUNYI
```

Area terbuka:

```text
TERDETEKSI
```

Saat musuh aktif mencari:

```text
DIBURU
```

---

# 12. KAMUFLASE

Jaringan yang sudah berdaun adalah tempat berlindung.

Saat TENDRIL diam di jaringan:

```text
TERSEMBUNYI
```

Gunakan:

- daun,
- shadow,
- warna,
- gerakan idle kecil.

Hindari UI besar untuk menjelaskan kamuflase.

Pemain harus **melihat dan merasakan** bahwa jaringan adalah tempat aman.

---

# 13. AREA G — DANGER

Masukkan satu environmental hazard sederhana:

- lampu/sensor,
- kabel listrik,
- pestisida.

Tujuan bukan membunuh pemain terus-menerus.

Tujuannya:

> **memaksa pemain memanfaatkan jaringan dan lingkungan.**

---

# 14. MUSUH PERTAMA

Untuk vertical slice gunakan satu tipe musuh.

Contoh:

## MAINTENANCE SENSOR

State:

```text
IDLE
 ↓
SCAN
 ↓
DETECT
 ↓
SEARCH
```

Belum perlu combat kompleks.

Pertanyaan desain:

> Apakah TENDRIL dapat menghindari deteksi dengan memanfaatkan lingkungan?

---

# 15. VISIBILITY STATES

```text
TERSEMBUNYI
TERDETEKSI
DIBURU
```

### TERSEMBUNYI
- berada di jaringan,
- area gelap,
- tidak menarik perhatian.

### TERDETEKSI
- sensor melihat,
- pemain harus bereaksi.

### DIBURU
- sensor/musuh aktif mencari,
- pemain harus kembali ke jaringan atau mencari jalur alternatif.

---

# 16. ENERGI

## MERAMBAT

```text
ENERGI ↑
```

Pulih perlahan.

## LEPAS

```text
ENERGI ↓
```

Terkikis perlahan.

Aksi khusus menghabiskan energi lebih banyak.

Energi bukan sekadar resource.

> **Energi adalah jam biologis TENDRIL saat terlepas dari induknya.**

---

# 17. REGROWTH

Jika energi mencapai 0 saat LEPAS:

```text
TENDRIL MATI
      ↓
BAGIAN LEPAS TERPUTUS
      ↓
NODE TERAKHIR TETAP HIDUP
      ↓
REGROW
```

Jaringan induk adalah:

- checkpoint biologis,
- sumber energi,
- tempat tumbuh kembali,
- jalur traversal.

---

# 18. FIRST ROOM GAMEPLAY LOOP

```text
START
  ↓
MERAMBAT
  ↓
OBSERVE
  ↓
DETACH
  ↓
CRAWL
  ↓
EXPLORE
  ↓
ADAPT TO SURFACE
  ↓
AVOID DETECTION
  ↓
FIND NEW NETWORK
  ↓
ATTACH
  ↓
RECOVER
```

Kemudian:

```text
GROW
  ↓
CREATE NEW ROUTE
  ↓
EXPLORE AGAIN
```

---

# 19. THREE ROUTES

Room 01 sebaiknya memiliki tiga solusi.

## SAFE ROUTE

```text
NETWORK
 ↓
NETWORK
 ↓
NETWORK
```

Aman, tetapi lebih lambat.

## FAST ROUTE

```text
DETACH
 ↓
CRAWL
 ↓
JUMP
 ↓
ATTACH
```

Cepat, tetapi energi terkuras.

## SECRET ROUTE

```text
CRACK
 ↓
SMALL GAP
 ↓
HIDDEN NETWORK
```

Sulit ditemukan, tetapi memberi keuntungan.

---

# 20. ENVIRONMENT IS THE BODY

Untuk TENDRIL:

> **Level bukan sekadar tempat bermain.**

Jaringan adalah:

- rumah,
- jalan,
- checkpoint,
- recovery point,
- kamuflase,
- jalur alternatif.

Permukaan adalah:

- media tumbuh,
- hambatan,
- sumber daya,
- bahaya,
- petunjuk.

---

# 21. CHARACTER ADAPTATION MATRIX

```text
GROUND
 ↓
CRAWL

WALL
 ↓
ATTACH
 ↓
CLIMB

CEILING
 ↓
MERAMBAT

CRACK
 ↓
SQUEEZE

DAMP
 ↓
GROW

NETWORK
 ↓
RECOVER

LIGHT / SENSOR
 ↓
HIDE
```

Karakter harus terlihat **beradaptasi**, bukan hanya berjalan melalui background.

---

# 22. ROOM FLOW

```text
[START NETWORK]
       ↓
[MERAMBAT]
       ↓
[SEE OPEN AREA]
       ↓
[DETACH]
       ↓
[CRAWL]
       ↓
[ENERGY DRAINS]
       ↓
[SMALL GAP]
       ↓
[HIDDEN AREA]
       ↓
[AVOID SENSOR]
       ↓
[NEW NETWORK]
       ↓
[ATTACH]
       ↓
[ENERGY RECOVERS]
       ↓
[ROOM COMPLETE]
```

---

# 23. TUTORIAL TANPA TEKS

Room 01 harus mengajarkan lewat bentuk.

### Jaringan terlihat di atas
Pemain mencoba MERAMBAT.

### Jalur terbuka
Pemain mencoba LEPAS.

### Energi turun
Pemain mulai mencari jaringan.

### Celah kecil
Pemain menemukan kemampuan ukuran kecil.

### Sensor
Pemain belajar kamuflase.

### Jaringan baru
Pemain mendapatkan reward berupa keamanan dan recovery.

Dengan demikian tutorial terjadi melalui:

> **cause → action → consequence.**

---

# 24. PIXEL ART ENVIRONMENT DIRECTION

Lingkungan:

- gelap,
- lembap,
- industrial,
- tua,
- padat,
- terbaca dalam pixel art.

Kontras utama:

```text
DARK BUILDING
      +
LIVING GREEN NETWORK
```

TENDRIL harus tetap menjadi objek yang mudah dibaca.

Background tidak boleh mengalahkan silhouette karakter.

---

# 25. TILESET PRIORITY

Untuk Room 01:

```text
1. FLOOR
2. WALL
3. CEILING
4. CRACK
5. DAMP SURFACE
6. WOOD
7. CONCRETE
8. METAL
9. PIPE
10. CABLE
11. NETWORK
12. LEAF COVER
13. WATER/NUTRIENT DETAIL
14. HAZARD
15. SENSOR
```

Jangan membuat seluruh gedung sekaligus.

---

# 26. SCALE

TENDRIL harus kecil dibanding ruangan.

Tujuan visual:

> **"Saya adalah kehidupan kecil yang menyusup di dalam bangunan besar."**

Bukan:

> "Saya adalah karakter besar di dalam level platformer."

Perbandingan karakter terhadap:

- pintu,
- pipa,
- lantai,
- beton,
- manusia/NPC jika nanti ada,

harus memperkuat rasa skala.

---

# 27. CAMERA

Untuk vertical slice:

- side-view,
- pixel-perfect,
- mengikuti TENDRIL dengan halus,
- tidak terlalu cepat,
- tidak memperlihatkan seluruh level sekaligus.

Tujuan:

> pemain menemukan lingkungan secara bertahap.

---

# 28. GODOT ROOM STRUCTURE

Struktur awal:

```text
Room01
├── TileMap
│   ├── Background
│   ├── Structure
│   ├── Surface
│   └── Collision
│
├── TendrilNetwork
│   ├── NetworkNode
│   ├── NetworkNode
│   └── NetworkNode
│
├── Interactables
│   ├── Crack
│   ├── Wood
│   ├── Pipe
│   └── Cable
│
├── Hazards
│   ├── Electricity
│   └── Sensor
│
├── Player
│   └── Tendril
│
└── Camera
```

---

# 29. NETWORK NODE DESIGN

Jaringan tidak perlu menjadi satu objek besar.

Gunakan node:

```text
NetworkNode
     ↓
NetworkNode
     ↓
NetworkNode
     ↓
NetworkNode
```

Node dapat berfungsi sebagai:

- recovery point,
- regrowth point,
- camouflage point,
- traversal point.

---

# 30. TEST SCENARIOS

## TEST A — MOVEMENT

```text
CRAWL → DETACH → ATTACH
```

TENDRIL harus tetap terasa sebagai organisme tanpa kaki.

## TEST B — ENVIRONMENT

Apakah pemain menggunakan:

```text
floor
wall
ceiling
crack
```

secara berbeda?

## TEST C — ENERGY

Apakah pemain berpikir:

> "Saya harus kembali ke jaringan."

## TEST D — STEALTH

Apakah jaringan terasa seperti tempat berlindung?

## TEST E — SCALE

Apakah ruangan membuat TENDRIL terlihat kecil?

---

# 31. ROOM 01 SUCCESS CRITERIA

Vertical slice berhasil apabila pemain dapat:

- [ ] berpindah MERAMBAT ↔ LEPAS,
- [ ] memahami jaringan sebagai safe zone,
- [ ] melakukan CRAWL,
- [ ] menggunakan permukaan berbeda,
- [ ] masuk celah kecil,
- [ ] menghindari satu sensor,
- [ ] mengelola energi,
- [ ] menemukan jaringan baru,
- [ ] kembali pulih,
- [ ] memahami bahwa lingkungan menentukan cara bertahan hidup.

---

# 32. YANG BELUM PERLU ADA

Room 01 tidak membutuhkan:

- boss,
- combat kompleks,
- banyak musuh,
- inventory besar,
- crafting,
- banyak jenis tanaman,
- puzzle rumit,
- procedural generation,
- banyak NPC,
- map besar.

Tujuan:

> **membuktikan core interaction.**

---

# 33. DEVELOPMENT ORDER

## Phase 1 — Graybox

Buat:

```text
floor
wall
ceiling
network
crack
sensor
```

Tanpa art final.

## Phase 2 — TENDRIL

Masukkan:

- CRAWL,
- MERAMBAT,
- DETACH,
- ATTACH,
- energy.

## Phase 3 — Environment Interaction

Masukkan:

- crack,
- damp,
- wood,
- cable,
- pipe.

## Phase 4 — Stealth

Masukkan:

- hidden,
- detected,
- hunted.

## Phase 5 — Pixel Art

Masukkan:

- tileset,
- background,
- lighting,
- particles,
- foliage.

---

# 34. DEFINITION OF DONE

Room 01 dianggap berhasil apabila **satu ruangan saja sudah mampu menjelaskan identitas dasar TENDRIL**.

Pemain harus memahami:

```text
I am small.
I am alive.
I can grow.
I can hide.
I can crawl.
I can attach.
I can detach.
I need my network.
The building is my environment.
The environment determines how I survive.
```

---

# 35. ART DIRECTION STATEMENT

> **Gedung bukan sekadar level.**
>
> Gedung adalah ekosistem.
>
> Beton menjadi dinding.
>
> Retakan menjadi jalan.
>
> Pipa menjadi sumber kehidupan.
>
> Kabel menjadi bahaya.
>
> Celah menjadi lorong.
>
> Jaringan menjadi rumah.
>
> Dan TENDRIL adalah kehidupan kecil yang belajar menggunakan semuanya.

---

# 36. CORE ENVIRONMENT RULE

> **Setiap lingkungan harus memberi TENDRIL alasan untuk memilih cara bergerak.**

Jika semua permukaan hanya dekorasi:

> environment gagal.

Jika pemain melihat permukaan dan berpikir:

> "Saya harus MERAMBAT di sini."

atau:

> "Saya harus LEPAS di sini."

atau:

> "Saya harus masuk celah."

maka environment berhasil.

---

# 37. FINAL DESIGN PRINCIPLE

> **Jangan membuat ruangan untuk menampung TENDRIL.**
>
> **Buat ruangan yang memaksa TENDRIL menunjukkan bagaimana ia hidup.**
>
> Setiap dinding harus mempunyai alasan.
>
> Setiap celah harus mempunyai fungsi.
>
> Setiap jaringan harus terasa seperti bagian dari organisme.
>
> Setiap bahaya harus mengubah pilihan gerak.
>
> Dan setiap jalur harus membuat pemain bertanya:
>
> **"Bagaimana tanaman kecil ini bisa melewati tempat sebesar ini?"**

---

# 38. NEXT ROOM ROADMAP

Setelah Room 01 stabil:

```text
ROOM 01
CORE SURVIVAL
      ↓
ROOM 02
VERTICAL EXPLORATION
      ↓
ROOM 03
STEALTH
      ↓
ROOM 04
ENVIRONMENTAL HAZARD
      ↓
ROOM 05
GROWTH / ABILITY
```

Semua room berikutnya harus berasal dari bahasa desain Room 01.

---

# 39. FINAL STATEMENT

> **TENDRIL bukan karakter yang ditempatkan di dalam level.**
>
> **TENDRIL adalah organisme yang hidup di dalam level.**
>
> Jaringan adalah rumahnya.
>
> Permukaan adalah tubuh keduanya.
>
> Retakan adalah jalan.
>
> Pipa adalah sumber.
>
> Cahaya adalah ancaman.
>
> Energi adalah waktu hidup.
>
> Dan gedung adalah ekosistem yang harus dipelajarinya.
