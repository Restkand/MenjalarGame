# TENDRIL — Game Design Document

**Tagline:** GROW. HIDE. SURVIVE.
**Genre:** 2D Pixel Art Metroidvania / Platformer / Stealth / Exploration
**Engine:** Godot
**Primary Art Pipeline:** PixelLab.Ai + manual pixel-art cleanup
**Perspective:** 2D side view
**Target Experience:** Eksplorasi, pertumbuhan jaringan, stealth, platforming, dan penguasaan kembali gedung yang perlahan berubah menjadi tubuh organisme.

> Dokumen ini ditulis PEMILIK PROYEK dan adalah SATU-SATUNYA sumber
> kebenaran desain. Semua keputusan produksi tunduk ke sini.

---

## 1. Visi Utama

**TENDRIL** adalah game metroidvania 2D pixel art tentang sebuah **ujung tumbuh tanaman merambat** yang dapat melepaskan diri dari jaringan induknya.

Gedung tempat permainan berlangsung adalah sekaligus:

- dunia permainan,
- jalan raya,
- rumah,
- sumber energi,
- tempat persembunyian,
- tubuh organisme,
- dan sistem checkpoint.

Pemain tidak sekadar menjelajahi gedung.

> **Pemain menumbuhkan jalannya sendiri dan secara perlahan mengubah gedung menjadi tubuhnya.**

Kota mengetahui adanya pertumbuhan biologis abnormal tersebut dan berusaha memangkas, membakar, menyemprot, serta membersihkannya.

Tujuan pemain bukan sekadar membunuh musuh.

Tujuan utama adalah:

1. Bertahan hidup.
2. Menyebarkan jaringan.
3. Membuka area baru.
4. Menghubungkan kembali bagian-bagian gedung.
5. Mengembangkan kemampuan biologis.
6. Menghindari deteksi.
7. Mengubah gedung menjadi ekosistem hidup.

---

# 2. Pilar Desain

Seluruh sistem game harus mendukung lima pilar berikut.

## 2.1 Grow Your Own Map

Pemain dapat membuat jaringan tanaman baru.

Jaringan yang dibuat pemain menjadi:

- jalur perjalanan,
- tempat regenerasi,
- tempat kamuflase,
- shortcut,
- titik pemulihan,
- dan bagian dari sistem progression.

**Prinsip:** map bukan hanya sesuatu yang ditemukan. Map sebagian dibuat oleh pemain.

---

## 2.2 Two Modes, One Body

Pemain memiliki dua moda utama:

### MERAMBAT

Pemain berada di jaringan tanaman.

Karakter:

- bergerak 360 derajat,
- menempel pada dinding,
- menempel pada plafon,
- bergerak cepat,
- energi pulih perlahan,
- dapat berkamuflase di jaringan yang sesuai,
- tidak menggunakan gravitasi platformer biasa.

### LEPAS

Pemain melepaskan ujung tumbuh dari jaringan.

Karakter:

- mengikuti gravitasi,
- berjalan,
- berlari,
- melompat,
- jatuh,
- melakukan panjat pendek,
- menggunakan kemampuan aktif,
- kehilangan energi secara perlahan.

**Aturan utama:**

> Menyentuh jaringan yang aktif mengembalikan pemain ke MERAMBAT.

Perpindahan kedua moda harus terasa cepat dan tidak mengganggu flow.

---

## 2.3 Stealth Through Biology

Pemain adalah organisme yang seharusnya tidak diketahui manusia.

Stealth bukan sistem tambahan. Stealth merupakan bagian dari survival.

Pemain harus mempertimbangkan:

- cahaya,
- suara,
- gerakan,
- sensor,
- kamera,
- aktivitas jaringan,
- dan lokasi musuh.

Diam di jaringan yang berdaun dapat membuat pemain tidak terlihat.

---

## 2.4 The Building Is Alive

Gedung berubah mengikuti perkembangan jaringan.

Awal permainan:

- gedung hampir steril,
- jaringan sedikit,
- ruangan masih mudah dikenali sebagai bangunan manusia.

Pertengahan:

- sulur memenuhi koridor,
- akar menembus dinding,
- ruangan mulai berubah,
- jaringan membuat shortcut.

Akhir:

- gedung menjadi ekosistem,
- struktur manusia dan organisme bercampur,
- jalur lama berubah,
- beberapa area menjadi habitat baru.

Perubahan visual juga harus mencerminkan progression pemain.

---

## 2.5 Survival Through Adaptation

Progression bukan hanya mendapatkan senjata.

Progression terutama berupa **adaptasi biologis**.

Pemain mendapatkan kemampuan baru yang membuka:

- material baru,
- jalur baru,
- strategi stealth baru,
- cara melawan ancaman,
- dan shortcut baru.

---

# 3. Premis Dunia

Sebuah organisme tanaman tidak dikenal mulai tumbuh di dalam gedung yang sebagian besar sudah ditinggalkan.

Organisme ini tidak tumbuh seperti tanaman normal.

Ia:

- membangun jaringan,
- merespons lingkungan,
- menyimpan energi,
- memperbaiki diri,
- belajar,
- dan berkembang.

Pemain mengendalikan ujung tumbuh paling muda dari organisme tersebut.

Ujung tumbuh dapat melepaskan diri dari jaringan induknya untuk mencari:

- air,
- mineral,
- biomassa,
- tempat tumbuh,
- dan jalur baru.

Kota menganggap organisme tersebut sebagai ancaman biologis.

Operasi pembersihan dimulai.

---

# 4. Fantasi Pemain

Pemain harus merasa seperti:

> "Saya adalah tanaman kecil yang hidup di dalam gedung besar."

Bukan manusia yang mengendalikan tanaman.

Karakter utama harus terasa seperti organisme.

Karena itu:

- gerakan harus elastis,
- tubuh dapat meregang,
- animasi pertumbuhan penting,
- jaringan terasa hidup,
- kematian terasa seperti bagian tubuh terputus,
- dan lingkungan harus bereaksi terhadap pertumbuhan.

---

# 5. Core Gameplay Loop

Loop utama:

```text
EKSPLORASI
    ↓
LEPAS DARI JARINGAN
    ↓
MENEMUKAN AREA BARU
    ↓
MENCARI SUMBER DAYA
    ↓
MENEMUKAN PERMUKAAN YANG BISA DITUMBUHI
    ↓
TUMBUHKAN JARINGAN
    ↓
KEMBALI KE MERAMBAT
    ↓
MEMBUAT SHORTCUT
    ↓
MENGEMBANGKAN KEMAMPUAN
    ↓
MUSUH / SISTEM KEAMANAN BEREAKSI
    ↓
MEMUTUSKAN: SEMBUNYI, LARI, ATAU MELAWAN
    ↓
MENCAPAI AREA BARU
```

Loop harus terus memberikan alasan untuk berpindah antara MERAMBAT dan LEPAS.

---

# 6. Sistem MERAMBAT

## 6.1 Movement

Saat MERAMBAT:

- input kiri/kanan/atas/bawah mengontrol arah,
- gravitasi tidak berlaku,
- pemain dapat berpindah sepanjang jaringan,
- pemain dapat berpindah dari lantai ke dinding,
- pemain dapat berpindah dari dinding ke plafon.

Gerakan harus terasa lebih cepat daripada LEPAS.

---

## 6.2 Network Nodes

Jaringan terdiri dari node.

Node memiliki fungsi:

- koneksi jaringan,
- checkpoint,
- respawn,
- regenerasi,
- fast travel,
- atau lokasi penyimpanan state.

Contoh:

```text
        NODE
          │
       /  |  \
      /   |   \
     ───────────
          |
          ↓
```

---

## 6.3 Active Network

Jaringan aktif adalah jaringan yang masih hidup dan dapat digunakan.

Jaringan dapat:

- tumbuh,
- menyebar,
- rusak,
- terputus,
- terinfeksi,
- atau mati.

---

# 7. Sistem LEPAS

Saat pemain LEPAS:

### Movement dasar

- Walk
- Run
- Jump
- Short Climb
- Fall

### Prinsip

Mode LEPAS lebih lambat dan lebih berbahaya daripada MERAMBAT.

Namun mode ini diperlukan untuk:

- menjangkau tempat baru,
- melewati jaringan yang belum tersedia,
- mengambil resource,
- menemukan material baru,
- dan membuat jaringan baru.

---

# 8. Transisi Moda

## LEPAS → MERAMBAT

Trigger:

- menyentuh jaringan aktif,
- memasuki node,
- atau melakukan reconnect tertentu.

Transisi harus cepat.

Contoh:

```text
LEPAS
  ↓
menyentuh sulur
  ↓
tubuh menempel
  ↓
MERAMBAT
```

## MERAMBAT → LEPAS

Trigger:

- tombol release,
- ujung jaringan,
- titik lompat tertentu,
- atau kemampuan khusus.

---

# 9. Energy System

Energi adalah resource utama saat pemain berada di luar jaringan.

Contoh:

```text
ENERGI
██████████████░░░░ 72/100
```

## Saat LEPAS

Energi terus berkurang.

Contoh:

```text
Idle        - kecil
Walking     - kecil
Running     - sedang
Jumping     - sedang
Ability     - besar
Special     - sangat besar
```

## Saat MERAMBAT

Energi pulih perlahan.

```text
MERAMBAT
+ regenerasi
+ aman
+ cepat
```

## Saat Energi Habis

Pemain mati.

Namun kematian bukan game over tradisional.

Pemain tumbuh kembali dari node jaringan hidup terdekat.

---

# 10. Death & Regrowth

Ketika ujung tumbuh mati:

1. tubuh mengering,
2. jaringan tetap hidup,
3. kamera berpindah ke node,
4. ujung tumbuh baru muncul,
5. pemain melanjutkan permainan.

Prinsip:

> Tubuh dapat mati. Jaringan adalah kehidupan sebenarnya.

---

# 11. Network Growth

Kemampuan dasar:

## TUMBUHKAN

Pemain membuat jaringan baru pada permukaan yang sesuai.

Contoh:

```text
Existing Network
       │
       |
       |
       └───────→ NEW GROWTH
```

Growth dapat digunakan untuk:

- membuat jalur,
- membuka shortcut,
- menciptakan checkpoint,
- mencapai area tinggi,
- menyebarkan jaringan.

---

# 12. Material Permukaan

Setiap permukaan memiliki aturan berbeda.

| Material | Pertumbuhan | Catatan |
|---|---|---|
| Lumut/lembap | Cepat | Material ideal |
| Retak | Bisa | Dapat ditembus |
| Kayu | Bisa | Rapuh |
| Pipa air | Sangat baik | Sumber air |
| Kabel | Terbatas | Listrik berbahaya |
| Beton | Tidak | Membutuhkan adaptasi |
| Logam | Tidak | Membutuhkan kemampuan |
| Kaca | Sangat terbatas | Bisa menjadi puzzle |
| Tanah | Sangat baik | Area akar |
| Dinding terlapis | Lambat | Bergantung kondisi |

Aturan material harus konsisten sehingga pemain dapat belajar tanpa tutorial terus-menerus.

---

# 13. Stealth System

Visibility memiliki tiga state utama.

## TERSEMBUNYI

Musuh tidak mengetahui posisi pemain.

Kondisi:

- diam di jaringan yang sesuai,
- berada di area gelap,
- tidak berada dalam sensor.

## TERDETEKSI

Musuh mulai menyelidiki.

Pemicu:

- gerakan cepat,
- pertumbuhan jaringan,
- suara,
- aktivitas di depan sensor,
- atau interaksi tertentu.

## DIBURU

Musuh mengetahui lokasi pemain.

Musuh akan:

- mengejar,
- memotong jaringan,
- menyalakan lampu,
- menyemprot,
- memasang jebakan,
- atau menutup akses.

---

# 14. Ancaman

## 14.1 Pemangkas

Musuh utama jaringan.

Fungsi:

- memotong sulur,
- membersihkan area,
- menghancurkan shortcut.

Gameplay:

> pemain harus menghindari jalur pemangkas atau mengalihkan mereka.

---

## 14.2 Drone

Drone memiliki sensor.

Kemampuan:

- patroli,
- scan,
- mendeteksi gerakan,
- mendeteksi pertumbuhan.

Drone cocok untuk area modern seperti kantor dan laboratorium.

---

## 14.3 Sprinkler

Sprinkler bersifat ambigu.

Air dapat:

- membantu pertumbuhan,
- mengisi sumber air,
- atau menjadi mekanisme pembersihan tertentu.

Sprinkler harus dapat digunakan pemain sebagai environmental puzzle.

---

## 14.4 Pestisida

Ancaman serius terhadap jaringan.

Pestisida dapat menyebar sepanjang jaringan.

Konsekuensi:

- jaringan rusak,
- regenerasi berhenti,
- jaringan mati.

Pemain dapat memilih memutus jaringan sendiri untuk mencegah penyebaran.

---

## 14.5 Sensor Cahaya

Mendeteksi:

- gerakan,
- perubahan biomassa,
- atau aktivitas organisme.

Pemain harus menggunakan bayangan dan jaringan untuk menghindarinya.

---

## 14.6 Teknisi

NPC manusia.

Dapat:

- membuka/menutup pintu,
- memperbaiki mesin,
- membersihkan jaringan,
- memasang alat,
- memindahkan benda.

Teknisi dapat digunakan sebagai environmental puzzle.

---

# 15. Progression / Adaptasi

Progression utama:

## 15.1 TENDRIL

Sulur dapat:

- menjangkau,
- menarik objek,
- mengaktifkan mekanisme,
- mengambil resource.

---

## 15.2 HOOK VINE

Sulur kait.

Fungsi:

- grapple,
- swing,
- menarik objek,
- mengakses area vertikal.

---

## 15.3 ROOT BURST

Akar menghasilkan dorongan besar.

Fungsi:

- menghancurkan permukaan rapuh,
- membuka jalur,
- memindahkan benda berat.

---

## 15.4 SPORA

Menghasilkan spora.

Fungsi:

- mengganggu sensor,
- mengganggu musuh,
- mengubah kondisi ruangan,
- membantu pertumbuhan tertentu.

---

## 15.5 PARASIT

Pemain dapat menginfeksi organisme/host tertentu.

Fungsi:

- mengendalikan host sementara,
- membuka pintu,
- membawa objek,
- melewati area manusia,
- mengaktifkan mekanisme.

Kemampuan ini sebaiknya diperkenalkan setelah gameplay dasar sudah dikuasai.

---

## 15.6 KAMUFLASE

Meningkatkan kemampuan bersembunyi.

Contoh:

- menyatu dengan dedaunan,
- mengurangi deteksi,
- bertahan lebih lama di area terang.

---

# 16. Resource

Gunakan resource yang sederhana terlebih dahulu.

## AIR

Digunakan untuk:

- pertumbuhan,
- regenerasi,
- kemampuan tertentu.

## MINERAL

Digunakan untuk:

- evolusi,
- jaringan keras,
- kemampuan penetrasi.

## BIOMASS

Digunakan untuk:

- kemampuan biologis,
- parasit,
- spora,
- regenerasi tertentu.

---

# 17. Struktur Gedung

Gedung utama adalah satu world besar yang saling terhubung.

Contoh:

```text
                 ROOFTOP
                    │
          ┌─────────┴─────────┐
          │                   │
        OFFICE             GREENHOUSE
          │                   │
          └────────┬──────────┘
                   │
                 ATRIUM
              ┌────┴────┐
              │         │
          LIBRARY    LABORATORY
              │         │
              └────┬────┘
                   │
             HOSPITAL WING
                   │
              ┌────┴────┐
              │         │
           PARKING    LOBBY
              │
           BASEMENT
              │
          ROOT DEPTHS
```

Jaringan pemain dapat menciptakan hubungan tambahan di antara area.

---

# 18. Area Utama

## BASEMENT

Fungsi:

- tutorial,
- sumber air,
- jaringan awal,
- pengenalan energi.

Mood:

- gelap,
- lembap,
- banyak pipa,
- sedikit manusia.

---

## HOSPITAL WING

Fungsi:

- area stealth,
- pengenalan manusia,
- sumber biomassa,
- environmental storytelling.

Mood:

- dingin,
- steril,
- lampu berkedip,
- jaringan mulai terlihat.

---

## LIBRARY

Fungsi:

- area eksplorasi,
- banyak rak,
- ruang sempit,
- vertical traversal.

---

## LABORATORY

Fungsi:

- eksperimen organisme,
- lore,
- material baru,
- ancaman pestisida.

---

## OFFICE

Fungsi:

- kamera,
- drone,
- teknisi,
- jaringan listrik.

---

## GREENHOUSE

Fungsi:

- area pertumbuhan besar,
- tanaman lain,
- resource,
- evolusi biologis.

---

## ATRIUM

Fungsi:

- central hub,
- koneksi antar lantai,
- landmark besar.

---

## PARKING

Fungsi:

- area terbuka,
- stealth,
- cahaya,
- patroli.

---

## ROOFTOP

Fungsi:

- area akhir,
- kanopi,
- pertumbuhan terbesar,
- akses ke luar gedung.

---

## ROOT DEPTHS

Fungsi:

- area bawah tanah,
- sumber nutrisi,
- lore organisme,
- area endgame.

---

# 19. World Progression

Gedung berubah secara visual.

### Tahap 1 — Steril

- sedikit tanaman,
- struktur manusia dominan.

### Tahap 2 — Infeksi

- sulur mulai muncul,
- retakan bertambah.

### Tahap 3 — Dominasi Koridor

- jaringan memenuhi jalur.

### Tahap 4 — Ekosistem

- akar,
- daun,
- spora,
- organisme kecil.

### Tahap 5 — Gedung Menjadi Tubuh

- struktur manusia hampir tertutup,
- jaringan menjadi jalur utama,
- ruang terasa seperti organ.

---

# 20. Pixel Art Direction

## Target Visual

Gaya:

- 2D pixel art,
- dark atmospheric,
- high readability,
- limited palette,
- environmental storytelling,
- organic animation.

Referensi rasa:

- metroidvania klasik,
- horror biologis,
- abandoned architecture,
- urban decay.

Namun game harus memiliki identitas sendiri.

---

# 21. Pixel Art Rules

Gunakan ukuran sprite konsisten.

Rekomendasi awal:

### Karakter

16×24 px sampai 32×48 px.

### Tile

16×16 px atau 32×32 px.

### Small props

8×8 / 16×16 px.

### UI icon

16×16 / 24×24 px.

Jangan mencampur terlalu banyak resolusi pixel.

---

# 22. PixelLab.Ai Pipeline

PixelLab.Ai digunakan terutama untuk:

- eksplorasi desain karakter,
- sprite konsep,
- environment,
- props,
- variasi musuh,
- tileset awal,
- referensi animasi.

Hasil AI **tidak langsung dianggap final**.

Pipeline:

```text
IDEA
 ↓
PROMPT
 ↓
PIXELLAB.AI
 ↓
SELECT
 ↓
MANUAL CLEANUP
 ↓
PALETTE NORMALIZATION
 ↓
SPRITE SHEET
 ↓
GODOT IMPORT
 ↓
ANIMATION
 ↓
GAME TEST
```

---

# 23. Konsistensi Pixel Art

Semua asset harus memiliki:

- pixel density sama,
- outline yang konsisten,
- lighting direction konsisten,
- palette terbatas,
- ukuran sprite yang jelas.

Gunakan reference sheet sebagai sumber kebenaran.

---

# 24. Character Design

Karakter utama harus sederhana.

Bentuk dasar:

```text
       ●
      /|
   ~~~ |
    \  |
     \/
```

Identitas karakter berasal dari:

- ujung tumbuh,
- daun kecil,
- sulur,
- akar,
- animasi elastis.

Karakter harus tetap dapat dikenali ketika hanya berukuran sekitar 16–32 pixel tinggi.

---

# 25. Animation Direction

Animasi harus memberikan kesan organisme.

Prioritas animasi:

1. Idle breathing
2. Crawling
3. Fast crawling
4. Release
5. Jump
6. Fall
7. Landing
8. Growth
9. Damage
10. Death
11. Regrowth
12. Camouflage
13. Ability activation

Gerakan jangan terlalu mekanis.

---

# 26. Kamera

Gunakan kamera 2D yang sederhana.

Mode utama:

- follow player,
- sedikit smoothing,
- area room-based untuk boss/scene tertentu.

Jangan membuat kamera terlalu jauh karena sprite pixel kecil akan kehilangan readability.

---

# 27. Godot Architecture

Rekomendasi struktur awal:

```text
project/
├── scenes/
│   ├── player/
│   ├── enemies/
│   ├── world/
│   ├── network/
│   ├── rooms/
│   └── ui/
│
├── scripts/
│   ├── player/
│   ├── enemies/
│   ├── network/
│   ├── systems/
│   └── managers/
│
├── assets/
│   ├── sprites/
│   ├── tilesets/
│   ├── animations/
│   ├── audio/
│   └── ui/
│
├── data/
│   ├── abilities/
│   ├── enemies/
│   ├── materials/
│   └── rooms/
│
└── project.godot
```

---

# 28. Player State Machine

Player sebaiknya menggunakan state machine.

Contoh:

```text
PLAYER
 ├── CRAWL
 ├── RELEASE
 ├── WALK
 ├── RUN
 ├── JUMP
 ├── FALL
 ├── CLIMB
 ├── GROW
 ├── ABILITY
 ├── DAMAGE
 ├── DEAD
 └── REGROW
```

Mode jaringan dan platformer harus dipisahkan secara jelas agar sistem mudah dikembangkan.

---

# 29. Network System

Jaringan sebaiknya diperlakukan sebagai sistem dunia sendiri.

Setiap node dapat memiliki:

```text
NetworkNode
- active
- connected_nodes
- health
- growth_state
- camouflage
- resource_level
- contaminated
```

Jaringan tidak perlu langsung menjadi simulasi biologis kompleks.

Prioritas pertama adalah gameplay.

---

# 30. Save System

Save utama disimpan berdasarkan node jaringan.

Data penting:

- node yang telah ditemukan,
- node yang aktif,
- ability yang terbuka,
- resource progression,
- area yang sudah terbuka,
- shortcut yang telah dibuat,
- state tertentu dari world.

Jangan membuat save terlalu bergantung pada posisi pixel pemain.

---

# 31. UI

UI harus minimal.

Informasi utama:

```text
ENERGY
██████░░░░

MODE
MERAMBAT

VISIBILITY
HIDDEN

ABILITY
[Q] TENDRIL
[E] SPORA
```

Saat tidak diperlukan, UI dapat menghilang.

---

# 32. Audio Direction

Audio harus membantu stealth.

Lapisan audio:

### Ambient

- angin,
- listrik,
- pipa,
- tetesan air,
- mesin gedung.

### Organic

- denyut jaringan,
- pertumbuhan,
- suara akar,
- suara spora.

### Threat

- alarm,
- drone,
- gunting,
- langkah kaki.

Musik tidak perlu selalu aktif.

Keheningan dapat menjadi bagian dari atmosfer.

---

# 33. Environmental Storytelling

Cerita tidak perlu banyak dialog.

Gunakan:

- poster,
- komputer,
- laporan,
- bekas pemangkasan,
- ruang eksperimen,
- tanaman mati,
- rekaman,
- graffiti,
- perubahan lingkungan.

Pemain menyusun sendiri apa yang terjadi.

---

# 34. Prinsip Level Design

Setiap area sebaiknya memiliki:

1. tempat aman,
2. tempat berbahaya,
3. jalur baru,
4. material baru,
5. alasan untuk kembali,
6. minimal satu shortcut,
7. minimal satu peluang pertumbuhan.

---

# 35. Backtracking

Backtracking adalah bagian penting metroidvania.

Namun backtracking harus dibuat lebih cepat melalui jaringan.

Contoh:

Awal:

```text
BASEMENT → HOSPITAL → OFFICE
```

Setelah pemain tumbuh:

```text
BASEMENT
   ↖
    ↖
     OFFICE
```

Pemain membuat jalur baru.

Dengan demikian:

> Pertumbuhan jaringan adalah reward eksplorasi.

---

# 36. Boss Design

Boss tidak harus selalu berupa makhluk.

Contoh boss:

## THE PRUNER

Mesin pemangkas otomatis.

Arena:

- jaringan luas,
- banyak jalur,
- alat pemotong bergerak.

Pemain menang bukan dengan damage langsung saja.

Strategi:

- memancing pemangkas,
- membuat jaringan baru,
- memutus jaringan,
- menyerang titik lemah mesin.

---

## THE CLEANER

Mesin pembersih biologis.

Menggunakan:

- pestisida,
- api,
- air bertekanan.

Pemain harus mengubah arena agar mesin menghancurkan dirinya sendiri.

---

# 37. Combat Philosophy

Combat bukan fokus utama.

Combat harus terasa seperti:

> organisme kecil melawan sistem yang jauh lebih besar.

Pemain dapat:

- menghindar,
- menggunakan lingkungan,
- menggunakan spora,
- menggunakan parasit,
- memutus jalur,
- atau menyerang titik lemah.

Stealth dan environmental manipulation lebih penting daripada DPS.

---

# 38. Accessibility & Readability

Walaupun pixel art gelap, gameplay harus jelas.

Pastikan:

- karakter selalu mudah dikenali,
- jaringan aktif berbeda dari jaringan mati,
- hazard memiliki bentuk visual jelas,
- enemy silhouette mudah dibaca,
- interactable memiliki indikator konsisten.

Jangan membuat seluruh layar terlalu gelap.

---

# 39. MVP — Minimum Viable Prototype

Jangan langsung membuat seluruh gedung.

Prototype pertama cukup:

### Satu ruangan

Memiliki:

- jaringan,
- lantai,
- dinding,
- satu celah,
- satu sumber energi,
- satu node.

Player dapat:

- MERAMBAT,
- LEPAS,
- berjalan,
- melompat,
- kembali ke jaringan,
- menumbuhkan satu jaringan baru.

Jika loop ini terasa menyenangkan, baru lanjut.

---

# 40. Vertical Slice

Setelah prototype berhasil, buat satu mini-level.

Isi:

- 3–5 ruangan,
- 1 jenis musuh,
- 1 hazard,
- 1 ability,
- 1 resource,
- 1 shortcut,
- 1 checkpoint node.

Target:

> Pemain dapat bermain 10–20 menit tanpa developer harus menjelaskan semuanya secara verbal.

---

# 41. Urutan Development

## Phase 1 — Movement

- [ ] Player movement LEPAS
- [ ] Gravity
- [ ] Jump
- [ ] Collision
- [ ] MERAMBAT movement
- [ ] Wall/ceiling attachment
- [ ] Mode transition

## Phase 2 — Energy

- [ ] Energy drain
- [ ] Energy regeneration
- [ ] Death
- [ ] Regrowth

## Phase 3 — Network

- [ ] Network node
- [ ] Network connection
- [ ] Growth
- [ ] Network destruction
- [ ] Respawn node

## Phase 4 — Exploration

- [ ] Room system
- [ ] Doors
- [ ] Shortcuts
- [ ] Map

## Phase 5 — Stealth

- [ ] Detection
- [ ] Vision cone
- [ ] Hidden state
- [ ] Alert state
- [ ] Enemy investigation

## Phase 6 — Enemies

- [ ] Pruner
- [ ] Drone
- [ ] Technician

## Phase 7 — Progression

- [ ] Tendril
- [ ] Hook Vine
- [ ] Root Burst
- [ ] Spora
- [ ] Parasitic ability

## Phase 8 — World

- [ ] Basement
- [ ] Hospital
- [ ] Library
- [ ] Laboratory
- [ ] Office
- [ ] Greenhouse
- [ ] Atrium
- [ ] Rooftop
- [ ] Root Depths

---

# 42. Aturan Emas Pengembangan

Jangan mengembangkan semua sistem sekaligus.

Urutan prioritas:

```text
MOVEMENT
    ↓
FEEL
    ↓
NETWORK
    ↓
EXPLORATION
    ↓
STEALTH
    ↓
ENEMY
    ↓
ABILITY
    ↓
WORLD
    ↓
STORY
```

Jika movement tidak menyenangkan, game tidak akan terselamatkan oleh art atau lore.

---

# 43. Prinsip Teknis

Gunakan sistem yang sederhana dan modular.

Hindari sejak awal:

- procedural generation besar,
- simulasi akar realistis,
- AI kompleks,
- inventory besar,
- skill tree terlalu banyak,
- physics tanaman realistis.

Game ini harus terasa biologis melalui **aturan gameplay**, bukan simulasi biologis literal.

---

# 44. Definisi Sukses

Prototype TENDRIL berhasil jika pemain mengalami perasaan berikut:

> "Saya aman selama berada di jaringan."

> "Saya harus keluar untuk mencapai tempat itu."

> "Saya hampir kehabisan energi."

> "Kalau saya berhasil menumbuhkan jaringan di sana, saya bisa pulang dengan aman."

> "Oh, saya bisa membuat shortcut sendiri."

> "Mereka akan memotong jaringan saya."

> "Saya harus bersembunyi."

> "Sekarang seluruh ruangan ini sudah menjadi milik saya."

Perasaan terakhir adalah tujuan utama game.

---

# 45. Identitas Singkat Game

**TENDRIL** adalah metroidvania pixel art tentang tanaman yang menjadikan gedung sebagai tubuhnya.

**MERAMBAT** membuat pemain aman dan cepat.

**LEPAS** membuat pemain rentan tetapi memungkinkan eksplorasi.

**PERTUMBUHAN** mengubah dunia.

**STEALTH** menjaga organisme tetap hidup.

**ADAPTASI** membuka dunia baru.

Dan pada akhirnya:

> **Anda tidak menaklukkan gedung. Anda membuat gedung menjadi hidup.**
