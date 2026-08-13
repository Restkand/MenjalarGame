# TENDRIL — CHARACTER DESIGN DOCUMENT

**Project:** TENDRIL
**Genre:** 2D Pixel Art Metroidvania / Platformer / Stealth / Exploration
**Character:** Ujung Tumbuh / Tendril
**Engine:** Godot
**Art Pipeline:** PixelLab.Ai → Pixel Cleanup → Sprite Sheet → Godot
**Visual Target:** Dark atmospheric pixel art dengan organisme hijau sebagai fokus visual utama

> Dokumen ini ditulis PEMILIK PROYEK — kanon karakter, setara GDD.
> Papan acuan visualnya (anatomi, tahap, moda, kemampuan, permukaan,
> siluet & animasi kunci) adalah bagian tak terpisahkan dari dokumen ini.

---

# 1. Identitas Karakter

## Nama Kerja

**TENDRIL**

Nama ini merujuk pada ujung sulur yang dikendalikan pemain sekaligus organisme yang menjadi inti gameplay.

Nama karakter di dalam lore dapat ditentukan kemudian.

Untuk sementara, gunakan:

> **Ujung Tumbuh**

Ujung Tumbuh adalah bagian muda dari jaringan tanaman besar yang memenuhi gedung.

Ia bukan manusia.

Ia bukan tanaman biasa.

Ia adalah bagian dari organisme yang mampu:

- bergerak,
- merasakan lingkungan,
- mencari nutrisi,
- menumbuhkan jaringan,
- beradaptasi,
- dan mempertahankan dirinya.

---

# 2. Konsep Utama Karakter

Pemain mengendalikan **kepala sulur muda**, bukan seluruh tanaman.

Tubuh karakter adalah ujung dari jaringan yang dapat memanjang dan bercabang.

Di belakang karakter terdapat jaringan induk yang lebih besar.

Karena itu, karakter memiliki dua kondisi utama:

```text
JARINGAN INDUK
      │
      │
      │
      │
      │
   UJUNG TUMBUH
```

Saat berada pada jaringan:

```text
JARINGAN ── UJUNG TUMBUH
```

Saat melepaskan diri:

```text
JARINGAN
   │
   │
   └───────→ UJUNG TUMBUH
```

Karakter menjadi organisme kecil yang harus mencari jalan kembali.

---

# 3. Fantasi Pemain

Pemain harus merasa:

> "Saya adalah ujung tanaman yang kecil, hidup, rapuh, tetapi mampu mengambil alih sebuah gedung."

Karakter tidak boleh terlihat seperti manusia hijau.

Karakter harus terlihat seperti:

- sulur,
- tunas,
- akar muda,
- organisme tanaman,
- makhluk hidup yang fleksibel.

Bentuknya sederhana sehingga tetap terbaca dalam pixel art berukuran kecil.

---

# 4. Siluet Karakter

Siluet merupakan prioritas utama.

Bahkan tanpa warna, pemain harus dapat mengenali:

- kepala/tunas,
- sulur utama,
- daun,
- ujung tumbuh,
- dan arah gerakan.

Siluet dasar:

```text
       ╱
      ●
     /
    /
   ●
  ╱ ╲
 ╱   ╲
```

Bentuk tidak boleh terlalu kompleks.

Targetnya:

> Jika sprite hanya memiliki 8–12 warna, karakter tetap langsung dikenali.

---

# 5. Anatomi Karakter

Karakter terdiri dari beberapa bagian visual.

## 5.1 Ujung Tumbuh

Bagian paling depan dari karakter.

Fungsi visual:

- menunjukkan arah gerakan,
- menjadi pusat perhatian,
- menunjukkan kondisi karakter.

Ujung tumbuh harus terlihat muda dan aktif.

Bentuk:

- runcing,
- sedikit melengkung,
- seperti tunas yang belum terbuka.

---

## 5.2 Daun Muda

Satu atau beberapa daun kecil berada dekat ujung tubuh.

Fungsi:

- memberikan identitas karakter,
- menjadi indikator kamuflase,
- membantu ekspresi tanpa wajah manusia.

Daun dapat bergerak sedikit saat:

- idle,
- terkena angin,
- berlari,
- melompat,
- terkena damage.

---

## 5.3 Sulur Utama

Sulur utama adalah tubuh karakter.

Karakteristik:

- fleksibel,
- tipis,
- dapat melengkung,
- dapat memanjang,
- dapat menempel pada permukaan.

Sulur merupakan bagian paling penting untuk animasi.

---

## 5.4 Cabang Kecil

Cabang kecil muncul dari tubuh.

Fungsi:

- memperkuat siluet,
- memberikan kesan organisme,
- menjadi indikator perkembangan.

Jangan terlalu banyak menggunakan cabang pada sprite dasar.

Semakin tinggi progression, semakin kompleks jaringan tubuhnya.

---

## 5.5 Node Pertumbuhan

Node kecil dapat muncul pada tubuh atau bagian belakang karakter.

Node berfungsi sebagai indikasi bahwa karakter mampu terhubung dengan jaringan.

Secara visual node dapat berupa:

- tonjolan kecil,
- titik bercahaya,
- daun kecil,
- atau akar bercabang.

---

# 6. Proporsi

Karakter harus terlihat kecil dibandingkan lingkungan.

Rekomendasi:

**Karakter gameplay:**

- tinggi sekitar 16–32 pixel pada resolusi sprite,
- lebar sekitar 8–20 pixel,
- fleksibel sesuai animasi.

**NPC manusia:**

- sekitar 32–48 pixel.

Dengan demikian:

> manusia terlihat besar, sedangkan tanaman terlihat kecil dan rentan.

Perbedaan ukuran ini penting untuk membangun rasa skala gedung.

---

# 7. Warna Utama

Palet utama harus didominasi hijau.

Contoh palet konseptual:

```text
Darkest Green
#102016

Deep Green
#19351E

Forest Green
#285B2B

Plant Green
#4F8F32

Young Leaf
#79B83F

Growth Highlight
#A8D94A
```

Jangan menjadikan semua bagian karakter hijau terang.

Gunakan:

- hijau gelap untuk tubuh,
- hijau sedang untuk volume,
- hijau terang untuk tunas,
- highlight kecil untuk ujung pertumbuhan.

---

# 8. Warna Status

Warna dapat digunakan untuk status gameplay.

## Normal

Hijau.

## Energi rendah

Hijau → kuning.

## Terdeteksi

Kuning.

## Diburu

Merah.

## Terinfeksi / Racun

Ungu.

## Listrik

Biru/putih.

Warna status harus tetap konsisten dengan UI dan lingkungan.

---

# 9. Tahap Pertumbuhan Karakter

Karakter dapat memiliki beberapa visual stage.

## Tahap 1 — Tunas Baru

Ciri:

- sangat kecil,
- satu daun,
- sulur pendek,
- sedikit cabang.

Gameplay:

- kemampuan dasar,
- energi rendah,
- jaringan awal terbatas.

Visual:

```text
   🌱
   │
   │
   │
```

---

## Tahap 2 — Muda

Ciri:

- tubuh lebih panjang,
- daun lebih jelas,
- cabang mulai muncul.

Gameplay:

- movement lebih baik,
- mulai memiliki kemampuan pertumbuhan.

---

## Tahap 3 — Dewasa

Ciri:

- sulur lebih panjang,
- beberapa cabang,
- node lebih banyak,
- daun lebih berkembang.

Gameplay:

- akses kemampuan utama,
- jaringan dapat berkembang lebih jauh.

---

## Tahap 4 — Tua / Kayu

Ciri:

- bagian tubuh lebih tebal,
- tekstur kayu,
- akar lebih kuat,
- warna hijau berkurang.

Gameplay:

- kemampuan pertahanan,
- kemampuan menembus material keras,
- growth lebih kuat.

---

## Tahap 5 — Terinfeksi / Beracun

Tahap ini bersifat opsional.

Ciri:

- warna ungu,
- node bercahaya,
- sulur tidak normal,
- spora.

Tahap ini dapat menjadi:

- upgrade,
- risiko,
- status sementara,
- atau jalur evolusi khusus.

---

# 10. Dua Moda Karakter

Dua moda adalah identitas gameplay utama.

---

# 11. MODE MERAMBAT

Saat MERAMBAT, karakter menyatu dengan jaringan.

## Movement

Karakter dapat:

- bergerak atas,
- bawah,
- kiri,
- kanan,
- diagonal,
- berpindah antara lantai/dinding/plafon.

Secara teknis, karakter tidak menggunakan gravitasi platformer biasa.

---

## Visual

Tubuh lebih menyatu dengan jaringan.

Sulur:

- memanjang,
- mengikuti arah jaringan,
- terlihat lebih organik.

Daun lebih tenang.

---

## Gameplay

MERAMBAT memberikan:

- mobilitas cepat,
- keamanan,
- regenerasi energi,
- stealth,
- akses ke jaringan.

Namun pemain tidak dapat menjelajah sembarang tempat.

---

# 12. Kamuflase MERAMBAT

Saat diam di jaringan yang berdaun:

> karakter menjadi sulit terlihat.

Visual:

- warna karakter sedikit menyatu dengan jaringan,
- animasi melambat,
- daun bergerak kecil,
- highlight berkurang.

State:

```text
VISIBLE
   ↓
HIDDEN
```

Jika bergerak terlalu aktif:

```text
HIDDEN
  ↓
SUSPICIOUS
  ↓
DETECTED
```

---

# 13. MODE LEPAS

Mode LEPAS membuat karakter terpisah dari jaringan.

Karakter menjadi seperti sulur kecil yang hidup sendiri.

## Movement

- berjalan,
- berlari,
- melompat,
- jatuh,
- memanjat pendek,
- menempel pada objek tertentu.

Gravitasi aktif.

---

# 14. Visual MODE LEPAS

Saat LEPAS:

- tubuh lebih tegak,
- ujung tumbuh menjadi fokus,
- sulur mengikuti momentum,
- daun bergerak lebih aktif.

Animasi harus menunjukkan:

> "Karakter sekarang tidak memiliki dukungan jaringan."

---

# 15. Transisi MERAMBAT → LEPAS

Animasi:

```text
MERAMBAT
   ↓
tubuh bergetar
   ↓
sulur terlepas
   ↓
ujung tumbuh melompat
   ↓
LEPAS
```

Durasi target:

**0.15–0.30 detik**

Transisi tidak boleh mengganggu kontrol.

---

# 16. Transisi LEPAS → MERAMBAT

Saat menyentuh jaringan:

```text
LEPAS
   ↓
ujung tumbuh menyentuh jaringan
   ↓
tubuh menempel
   ↓
sulur menyatu
   ↓
MERAMBAT
```

Durasi target:

**0.10–0.25 detik**

---

# 17. Movement Feel

Movement karakter harus terasa:

- ringan,
- elastis,
- responsif,
- sedikit organik.

Hindari movement yang terasa seperti:

- robot,
- manusia biasa,
- ular kaku.

---

# 18. Idle Animation

Idle adalah bagian penting dari identitas karakter.

Saat diam:

- ujung tumbuh bergerak perlahan,
- daun sedikit bergoyang,
- sulur melakukan gerakan kecil,
- tubuh seperti bernapas.

Contoh:

```text
Frame 1 → Frame 2 → Frame 3 → Frame 2
   │          │          │
   ↓          ↓          ↓
  kecil      naik       kecil
```

Target:

**4–8 frame** untuk idle sederhana.

---

# 19. Animasi MERAMBAT

Animasi minimal:

1. Crawl idle
2. Crawl left
3. Crawl right
4. Crawl up
5. Crawl down
6. Fast crawl
7. Turn
8. Stop

Untuk prototype, animasi dapat dibuat lebih sedikit dahulu.

---

# 20. Animasi LEPAS

Minimal:

1. Idle
2. Walk
3. Run
4. Jump
5. Fall
6. Land
7. Climb
8. Release
9. Attach

---

# 21. Animasi Pertumbuhan

Animasi TUMBUHKAN:

```text
Node kecil
    ↓
tonjolan
    ↓
sulur keluar
    ↓
sulur mencari permukaan
    ↓
menempel
    ↓
bercabang
    ↓
jaringan aktif
```

Pertumbuhan harus terasa memuaskan.

Gunakan:

- squash/stretch,
- sedikit particle,
- daun kecil,
- perubahan warna.

---

# 22. TENDRIL

Ability yang memungkinkan sulur memanjang.

Fungsi:

- menarik objek,
- menekan switch,
- mengambil benda,
- menjangkau node,
- berinteraksi dengan lingkungan.

Visual:

```text
TUBUH
  ●───────────────→ TARGET
```

Sulur harus memiliki animasi:

- extend,
- attach,
- pull,
- retract.

---

# 23. HOOK VINE

Sulur khusus untuk mengait.

Fungsi:

- grapple,
- swing,
- menarik tubuh,
- melewati celah.

Visual:

```text
       TARGET
          ●
         /
        /
       /
      ●
     /
   PLAYER
```

Ujung hook dapat berupa bentuk kecil seperti kait tanaman.

---

# 24. ROOT BURST

Karakter menancapkan akar kecil lalu menghasilkan dorongan.

Fungsi:

- menghancurkan permukaan rapuh,
- membuka jalan,
- memindahkan objek,
- mengganggu musuh.

Visual:

```text
       PLAYER
          │
        / | \
       /  |  \
      ROOT ROOT
       \  |  /
        \ | /
       BURST
```

Gunakan debu dan serpihan pixel.

---

# 25. SPORA

Karakter mengeluarkan spora.

Visual:

- partikel kecil,
- bercahaya,
- bergerak perlahan,
- menyebar mengikuti udara.

Fungsi:

- mengganggu sensor,
- mengacaukan musuh,
- mengubah permukaan,
- membantu pertumbuhan.

Spora harus terlihat indah tetapi sedikit berbahaya.

---

# 26. PARASIT

Ability tingkat lanjut.

Karakter dapat mengambil alih host tertentu.

Visual:

```text
PLAYER
  ↓
SPORA / SULUR
  ↓
HOST
  ↓
CONTROL
```

Host dapat:

- membuka pintu,
- menekan tombol,
- membawa benda,
- melewati area manusia.

Jangan menjadikan parasit sebagai sistem utama pada awal pengembangan.

---

# 27. Energy Visual

Energy adalah status penting.

Saat energi tinggi:

- daun terbuka,
- ujung tumbuh terang,
- gerakan aktif.

Saat energi rendah:

- daun sedikit turun,
- warna menjadi kusam,
- animasi melambat,
- ujung tumbuh lebih redup.

Contoh:

```text
ENERGI 100%
████████████████

ENERGI 50%
████████░░░░░░░░

ENERGI 10%
██░░░░░░░░░░░░░░
```

---

# 28. Damage

Karakter tidak menggunakan health bar besar sebagai fokus visual.

Saat terkena bahaya:

- tubuh terpental,
- daun bergetar,
- sulur melengkung,
- pixel kecil terlepas.

Jika kerusakan fatal:

```text
NORMAL
  ↓
DAMAGE
  ↓
WEAK
  ↓
DRY
  ↓
DEATH
```

---

# 29. Death

Kematian harus terasa biologis.

Bukan ledakan.

Contoh:

```text
TUBUH MELEMAH
      ↓
DAUN JATUH
      ↓
SULUR MENGERING
      ↓
UJUNG TUMBUH MATI
      ↓
JARINGAN TETAP HIDUP
```

Kemudian:

```text
NODE
 ↓
TUNAS BARU
 ↓
REGROW
```

---

# 30. Regrowth

Regrowth merupakan salah satu ciri khas karakter.

Node jaringan mengeluarkan tunas baru.

Animasi:

1. tanah/jaringan berdenyut,
2. tonjolan muncul,
3. tunas keluar,
4. daun terbuka,
5. sulur tumbuh,
6. karakter kembali aktif.

Regrowth harus terasa seperti:

> organisme selalu memiliki kesempatan kedua selama jaringannya masih hidup.

---

# 31. Karakter dan Jaringan

Pemain harus selalu merasa bahwa karakter bukan entitas terpisah dari jaringan.

Saat berada di jaringan:

```text
      ┌────────── NETWORK ──────────┐
      │                             │
      │           PLAYER            │
      │             │               │
      │            /|\              │
      │           / | \             │
      └─────────────────────────────┘
```

Saat LEPAS:

```text
NETWORK
   │
   │
   └───────→ PLAYER
```

Ini merupakan hubungan visual penting untuk seluruh game.

---

# 32. Siluet untuk Pixel Art

Karakter harus tetap terbaca pada:

- 16 px,
- 24 px,
- 32 px.

Prioritas silhouette:

1. Ujung tumbuh
2. Daun
3. Sulur utama
4. Cabang
5. Node

Detail kecil adalah prioritas terakhir.

---

# 33. PixelLab.Ai Character Workflow

Gunakan PixelLab.Ai untuk membuat eksplorasi awal.

Prompt harus selalu menyebut:

- 2D pixel art,
- side-view,
- small sprite,
- limited palette,
- dark background,
- readable silhouette,
- plant tendril creature,
- no human body,
- game sprite.

Setelah mendapatkan hasil:

```text
PIXELLAB.AI
     ↓
PILIH DESAIN
     ↓
BERSIHKAN PIXEL
     ↓
SAMAKAN PALET
     ↓
BUAT SILUET FINAL
     ↓
ANIMASI
     ↓
SPRITE SHEET
     ↓
GODOT
```

---

# 34. Aturan Konsistensi Asset

Semua sprite karakter harus memiliki:

- pixel density sama,
- outline konsisten,
- arah cahaya konsisten,
- palette konsisten,
- proporsi konsisten.

Jangan membuat satu sprite terlihat terlalu realistis sementara sprite lain terlalu kartun.

---

# 35. Sprite Sheet Awal

Untuk prototype, buat sprite sheet sederhana.

Contoh:

```text
ROW 1 — IDLE
[1][2][3][4]

ROW 2 — WALK
[1][2][3][4]

ROW 3 — JUMP/FALL
[1][2][3][4]

ROW 4 — MERAMBAT
[1][2][3][4]

ROW 5 — GROW
[1][2][3][4]

ROW 6 — DAMAGE/DEATH
[1][2][3][4]
```

Tidak perlu membuat semua animasi sekaligus.

---

# 36. Prioritas Animasi untuk MVP

Urutan:

1. Idle
2. Walk
3. Jump
4. Fall
5. Land
6. MERAMBAT
7. LEPAS
8. Attach
9. Grow
10. Damage
11. Death
12. Regrowth

Setelah movement terasa bagus, baru tambahkan ability animation.

---

# 37. Character State Machine

Implementasi Godot direkomendasikan menggunakan state machine.

Contoh:

```text
PLAYER
│
├── MERAMBAT
│   ├── Crawl
│   ├── CrawlIdle
│   └── NetworkTransition
│
├── LEPAS
│   ├── Idle
│   ├── Walk
│   ├── Run
│   ├── Jump
│   ├── Fall
│   └── Climb
│
├── ABILITY
│   ├── Tendril
│   ├── HookVine
│   ├── RootBurst
│   ├── Spora
│   └── Parasit
│
└── SPECIAL
    ├── Damage
    ├── Dead
    └── Regrowth
```

---

# 38. Komponen Player Godot

Struktur awal:

```text
Player
├── CharacterBody2D
│
├── Visual
│   ├── Sprite2D / AnimatedSprite2D
│   ├── AnimationPlayer
│   └── Particles
│
├── Collision
│   ├── CollisionShape2D
│   └── Hurtbox
│
├── Detection
│   ├── NetworkDetector
│   └── InteractionDetector
│
├── Energy
│
├── AbilityController
│
└── StateMachine
```

Struktur dapat berubah saat prototype berkembang.

---

# 39. Character Controller Principle

Controller harus memisahkan:

### Movement Logic

- posisi,
- velocity,
- gravity,
- collision.

### Network Logic

- attachment,
- crawling,
- network detection.

### Ability Logic

- tendril,
- hook,
- spora,
- root burst.

### Status Logic

- energy,
- stealth,
- damage,
- death.

Tujuannya agar karakter mudah dikembangkan tanpa membuat satu script terlalu besar.

---

# 40. Character Personality Tanpa Wajah

Karakter tidak membutuhkan mata dan mulut manusia.

Kepribadian dapat muncul melalui:

- gerakan,
- arah daun,
- posisi tubuh,
- kecepatan respons,
- reaksi terhadap lingkungan.

Contoh:

Saat menemukan air:

```text
sulur berhenti
    ↓
ujung tumbuh mendekat
    ↓
daun terbuka
    ↓
tubuh menyerap
```

Saat takut:

```text
tubuh mengecil
    ↓
daun menutup
    ↓
sulur menempel
```

Saat menemukan nutrisi besar:

```text
tubuh berdenyut
    ↓
cabang tumbuh
    ↓
warna lebih cerah
```

---

# 41. Character Feedback

Setiap aksi penting harus memiliki feedback.

## Tumbuh

- suara lembut,
- pixel growth,
- perubahan jaringan.

## Damage

- flash,
- recoil,
- sound impact.

## Energi rendah

- animasi melemah,
- suara lebih berat,
- UI berubah.

## Hidden

- tubuh menyatu dengan jaringan.

## Detected

- warna/status berubah,
- audio cue.

## Regrowth

- animasi tunas,
- partikel,
- suara biologis.

---

# 42. Design Rules

Karakter TENDRIL harus selalu mengikuti aturan berikut:

### Rule 1

**Jangan membuat karakter terlihat seperti manusia.**

### Rule 2

**Ujung tumbuh harus selalu menjadi pusat identitas.**

### Rule 3

**Sulur harus terasa fleksibel.**

### Rule 4

**Karakter harus terbaca dalam pixel kecil.**

### Rule 5

**Warna hijau adalah identitas utama.**

### Rule 6

**Perubahan warna digunakan untuk status dan evolusi.**

### Rule 7

**Animasi lebih penting daripada detail sprite.**

### Rule 8

**Karakter harus terlihat hidup bahkan saat diam.**

---

# 43. Target Akhir Visual

Saat pemain melihat karakter dalam game, kesan pertama yang diinginkan:

> "Itu tanaman."

Kesan kedua:

> "Tanaman itu hidup."

Kesan ketiga:

> "Tanaman itu sedang mencoba bertahan."

Dan akhirnya:

> "Saya ingin melihat seberapa besar tanaman ini bisa tumbuh."

---

# 44. Character Design North Star

Seluruh keputusan desain karakter harus kembali pada kalimat berikut:

> **TENDRIL adalah ujung tumbuh kecil yang rapuh, hidup, adaptif, dan sangat ingin kembali ke jaringan induknya.**

Karakter bukan superhero.

Karakter bukan monster besar.

Karakter adalah **organisme kecil yang secara perlahan menjadi bagian dari sesuatu yang jauh lebih besar**.

---

# 45. Checklist Character Asset

## Base

- [ ] Idle
- [ ] Walk
- [ ] Run
- [ ] Jump
- [ ] Fall
- [ ] Land

## MERAMBAT

- [ ] Crawl horizontal
- [ ] Crawl vertical
- [ ] Crawl diagonal
- [ ] Crawl idle
- [ ] Attach
- [ ] Detach

## Growth

- [ ] Tumbuh
- [ ] Node creation
- [ ] Network connection
- [ ] Regrowth

## Damage

- [ ] Hit
- [ ] Weak
- [ ] Death

## Ability

- [ ] Tendril
- [ ] Hook Vine
- [ ] Root Burst
- [ ] Spora
- [ ] Parasit

## Status

- [ ] Hidden
- [ ] Detected
- [ ] Hunted
- [ ] Low Energy
- [ ] Poisoned
- [ ] Electrified

---

# 46. Final Character Definition

**TENDRIL** adalah karakter tanaman merambat kecil dalam game metroidvania pixel art.

Ia merupakan **ujung tumbuh dari jaringan tanaman raksasa** yang memenuhi sebuah gedung.

Tubuhnya terdiri dari:

- ujung tumbuh,
- sulur,
- daun muda,
- cabang kecil,
- dan node pertumbuhan.

Ia memiliki dua kondisi utama:

**MERAMBAT**

> cepat, bebas arah, aman, regeneratif, dan menyatu dengan jaringan.

**LEPAS**

> rentan, terikat gravitasi, menghabiskan energi, tetapi mampu menjelajahi wilayah yang belum ditumbuhi.

Karakter berkembang melalui adaptasi biologis seperti:

- TENDRIL,
- HOOK VINE,
- ROOT BURST,
- SPORA,
- PARASIT,
- dan KAMUFLASE.

Identitas visual karakter harus selalu mempertahankan tiga hal:

> **SULUR + TUNAS + KEHIDUPAN**

Dan prinsip karakter yang paling penting:

> **Kecil sebagai individu. Besar sebagai jaringan.**
