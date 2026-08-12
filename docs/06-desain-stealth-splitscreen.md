# DESAIN — Menjalar: Split Screen & Stealth Sistemik

Menggantikan `docs/05-prompt-pivot-pembongkaran.md` sebagai arah kerja.
Dokumen itu tetap disimpan sebagai riwayat, tapi TAHAP 7–8 di dalamnya sudah
tidak berlaku.

Terakhir diperbarui: 10 Agustus 2026

---

## 0. Ringkasan perubahan

| | Sebelum (pembongkaran) | Sesudah (dokumen ini) |
|---|---|---|
| Tujuan | runtuhkan seluruh gedung | tutupi gedung dengan tanaman, tanpa dibersihkan |
| Kamera | dunia = layar, 240×160, skala tetap 4× | dunia 480×320, dua pane, scroll + zoom |
| Antagonis | regu patroli terus-menerus + pemanjat | inspeksi **terjadwal**; regu datang hanya kalau dipanggil |
| Keruntuhan | rangka, beban, runtuh berantai — inti permainan | erosi lokal — **kosmetik**, hadiah atas ketekunan |
| Bawah tanah | pita tipis, cuma cari air | pane penuh dengan deposit dan bahayanya sendiri |
| Rasa | arcade, destruktif | sabar, sistemik, terencana |

Patokan kualitas: **Terra Nil**. Yang ditiru bukan mekaniknya, tapi nadanya —
tenang, sistemik, tidak ada refleks, dan kepuasan datang dari melihat sistem
bekerja.

---

## 1. Tiga pilar

1. **Perhatian adalah sumber daya yang sesungguhnya.**
   Dua pane terlihat bersamaan, tapi pemain hanya bisa mengarahkan **satu**
   ujung pada satu waktu (`TreeSim.selected`, sudah ada). Ujung lain tetap
   tumbuh — mengikuti tropisme, tanpa kendali. Memilih pane berarti memilih
   apa yang lepas dari pengawasan.

2. **Ancaman selalu diumumkan sebelum tiba.**
   Tidak ada kejutan. Pemain melihat kalender: inspeksi hari ke berapa, zona
   mana yang dijadwalkan dirawat. Ketegangan lahir dari perencanaan, bukan
   dari kaget. Inilah yang membuat stealth tidak bertabrakan dengan nada
   tenang.

3. **Pembongkaran adalah hadiah, bukan tujuan.**
   Fasad yang lama dirambati gugur sepetak demi sepetak. Ia tidak memenangkan
   permainan; ia menandai bahwa pemain sudah bertahan lama di tempat itu.

---

## 2. Kamera dan tata letak layar

### 2.1 Angka

Dipilih supaya semuanya jatuh di kelipatan bulat — tidak ada satu pun
penskalaan pecahan.

```
Dunia            480 × 320 piksel simulasi
  zona udara     y   0 .. 191
  GARIS TANAH    y = 192
  zona tanah     y 192 .. 319

Jendela          960 × 640  (tidak berubah)
  pane ATAS      960 × 384
  pane BAWAH     960 × 256

Zoom 2x  pane atas melihat 480 × 192  = SELURUH zona udara
         pane bawah melihat 480 × 128  = SELURUH zona tanah
Zoom 4x  pane atas melihat 240 ×  96
         pane bawah melihat 240 ×  64
```

Konsekuensi yang disengaja: **pada 2× tidak ada gulir vertikal sama sekali** —
tiap pane pas menampilkan zonanya utuh. Gulir vertikal hanya muncul di 4×.
Jadi 2× adalah "lihat keseluruhan", 4× adalah "kerja teliti", dan keduanya
punya peran jelas alih-alih jadi slider tanpa arti.

### 2.2 Kenapa hanya dua tingkat zoom

Pixel art hanya tetap tajam pada penskalaan **bilangan bulat**. Zoom 1.7× atau
2.3× menghasilkan piksel berkedip dan buram — persis yang dilarang aturan
render proyek ini. Jadi zoom bersifat diskrit: 2× dan 4×, tanpa antara.

### 2.3 Cara membangunnya di Godot 4

```
main.tscn
└── Node2D (main.gd)
    ├── SubViewportContainer  (960×384, stretch=on)   pane ATAS
    │   └── SubViewport       (480×192 @2x, 240×96 @4x)
    │       ├── Sprite2D world / tree / overlay   scale = 1
    │       ├── Camera2D                          hanya menggeser
    │       ├── CanvasModulate
    │       └── PointLight2D ...
    ├── SubViewportContainer  (960×256, y=384)        pane BAWAH
    │   └── SubViewport ...  (Sprite2D menunjuk ImageTexture YANG SAMA)
    ├── TuningPanel  (CanvasLayer 10)   tidak terpengaruh
    └── Hud          (CanvasLayer 20)   tidak terpengaruh
```

**Zoom diubah dengan mengubah ukuran `SubViewport`, bukan `Camera2D.zoom`.**
Kontainer melakukan penskalaan bulat ke ukuran tetapnya, jadi tidak ada
pengambilan sampel sub-piksel yang mungkin terjadi. `Camera2D` hanya untuk
menggeser.

Ketiga `ImageTexture` dipakai bersama oleh kedua pane — satu sumber gambar,
dua jendela. Jumlah Sprite jadi 6, masih sangat kecil.

### 2.4 Yang rusak dan harus diperbaiki

| Tempat | Sekarang | Jadi |
|---|---|---|
| `Config.W/H` | 240 / 160 | 480 / 320 |
| `Config.SCALE` | 4, dipakai di mana-mana | **dihapus** — penskalaan urusan kontainer |
| `main._mouse_sim()` | `mouse / SCALE` | `_mouse_world()` → `{pane, pos}` lewat kamera pane di bawah kursor |
| `PixelCanvas._add_sprite` | `scale = SCALE` | `scale = 1`, ditaruh di dalam SubViewport |
| `PixelCanvas.add_shake` | geser posisi × SCALE | geser `Camera2D.offset` per pane, kelipatan 1 px dunia |
| `setup_lights` | `pos = w * SCALE`, `texture_scale = SCALE` | `pos = w`, `texture_scale = 1` |
| `WorldMap` grid/light/vis | 38.400 sel | 153.600 sel (~3,5 MB total, aman) |
| `_bake_light_from` | ~3.800 sinar | ~15.000 sinar → **terlalu lambat untuk satu frame** |

Solusi bake: kerjakan saat layar MULAI masih tampil. Overlay itu sudah ada di
[Hud.gd](../scripts/Hud.gd) dan sudah menahan permainan — bake dicicil di sana,
jadi pemain tidak pernah melihat hitch.

### 2.5 Kontrol — pilar "satu tangan di mouse" resmi dicabut

`docs/01-konteks-game.md` §7 menyatakan seluruh permainan lewat satu tangan di
mouse. Kamera independen membuat itu mustahil. Diganti dengan:

| Aksi | Input |
|---|---|
| Pane aktif | ditentukan posisi kursor — tidak perlu klik |
| Geser pane | `WASD`, atau tahan roda-tengah lalu seret |
| Zoom pane aktif | roda mouse |
| Pilih & arahkan ujung | klik kiri (tidak berubah) |
| Bercabang | klik kanan / `Spasi` (tidak berubah) |
| Rontokkan daun mencolok | `X` |

---

## 3. Bawah tanah jadi pane sungguhan

Sekarang bawah tanah cuma pita tipis dengan `T_SOIL_WET` dan satu pipa. Untuk
mengisi separuh layar, ia butuh isi dan risikonya sendiri.

| Terrain | Enum | Fungsi |
|---|---|---|
| Akuifer | `T_AKUIFER` | sumber **Air** utama; besar tapi jarang |
| Tanah lembap | `T_SOIL_WET` | air kecil, tersebar |
| Humus | `T_HUMUS` | mempercepat pertumbuhan akar di sekitarnya |
| Batuan | `T_BATU` | penghalang keras, harus diputari |
| Beton | `T_CONCRETE` | bisa **ditembus** — lihat §3.1 |
| Gorong-gorong | `T_GORONG` | koridor cepat, akar tumbuh 2× di dalamnya |
| **Utilitas** | `T_UTILITAS` | kabel & pipa induk — **menyentuhnya menaikkan PERHATIAN** |

Baris terakhir itu yang membuat pane bawah bukan sekadar zona aman: bawah tanah
tidak punya nilai `vis` (tidak terlihat), tapi mengganggu layanan gedung
memanggil teknisi. Jadi kedua pane punya risiko, dengan watak berbeda —
**atas = terlihat, bawah = terasa.**

### 3.1 Menembus beton — akhirnya dibangun

Dirancang di `docs/02-logika-game.md` §7 dan tercatat sebagai "belum ada sama
sekali" di `docs/04` §10. Sekarang ia punya alasan untuk ada: beton adalah
satu-satunya hal yang memisahkan akar dari akuifer besar.

```
- Ujung akar yang menempel di beton bisa diperintahkan menembus (klik ujungnya)
- crackProgress 0 → 1 selama CRACK_DURATION detik
- Menguras COST_CRACK / CRACK_DURATION energi per detik
- Energi habis di tengah = progress MEMBEKU, tidak reset
- Selesai: lubang muncul di grid, akar melanjutkan
```

---

## 4. Stealth sistemik

### 4.1 PERHATIAN — satu angka, bukan panas per-sulur

Sistem lama memberi tiap sulur nilai `heat` sendiri. Itu dihapus dan **tidak
dihidupkan lagi** — ia menuntut pemain mengawasi 24 untai sekaligus, mustahil
dengan perhatian yang sudah terbagi dua pane.

Gantinya satu angka untuk seluruh gedung: `perhatian` (0..1). Ini seberapa
sadar pengelola gedung bahwa ada masalah tanaman.

Naik dari:

| Sumber | Kenapa |
|---|---|
| tutupan di area `vis` tinggi | terlihat dari jalan |
| tanaman menutupi jendela (`T_WINDOW`) | penghuni mengeluh |
| tanaman di dekat pintu (`T_DOOR`) | pengelola melewatinya tiap hari |
| menyentuh `T_UTILITAS` | gangguan layanan memanggil teknisi |

Turun dari: waktu (peluruhan lambat), dan pemain merontokkan daun di titik
mencolok (`X`).

Peta `vis` yang sudah di-bake tetap dipakai apa adanya. Maknanya sekarang:
**seberapa cepat sesuatu menaikkan perhatian.**

### 4.2 Kalender

`Cycle.gd` naik pangkat jadi kalender. Satu hari = satu siang + satu malam.

```
Tiap INSPEKSI_TIAP hari  →  INSPEKSI
    perhatian dihitung terhadap AMBANG_RAWAT
    kalau lewat  →  PERAWATAN dijadwalkan JEDA_RAWAT hari ke depan,
                    dengan ZONA sasaran = petak dengan perhatian tertinggi

Saat hari PERAWATAN tiba  →  regu datang ke zona itu
```

HUD wajib menampilkan ini terus-menerus:

```
HARI 6   MALAM 40%
INSPEKSI dalam 1 hari
PERAWATAN  hari 9  — zona TIMUR ATAS
```

Itulah seluruh sistem stealth-nya. Pemain punya jendela waktu yang jelas untuk
memangkas sendiri, mengalihkan pertumbuhan ke bayangan, atau memutuskan
merelakan satu zona demi zona lain.

### 4.3 Regu dan pemanjat — dipertahankan, pemicunya diganti

[Crew.gd](../scripts/Crew.gd) dan [Climber.gd](../scripts/Climber.gd) tidak
dibuang. Yang berubah:

| | Sekarang | Jadi |
|---|---|---|
| Kapan muncul | tiap siang, terus-menerus | hanya pada hari PERAWATAN |
| Berapa | dari `integritas_total()` gedung | dari tingkat perhatian saat inspeksi |
| Ke mana | sulur terdekat/paling mencolok | ke ZONA yang dijadwalkan |
| Selesai | tidak pernah | pulang setelah zona bersih atau hari berakhir |

Pemanjat tetap naik lewat sulur pemain, dan `X` tetap memutus sulur untuk
menjatuhkannya. Mekanik itu bagus dan tidak tersentuh perubahan arah.

---

## 5. Erosi — pembongkaran sebagai kosmetik

Rangka struktural (`members`, `joints`, `panels`, aliran beban, keruntuhan
berantai, `KAPASITAS_MAX`) **dibuang seluruhnya**. Gantinya satu peta baru:

```
lapuk[]  PackedFloat32Array seukuran dunia
```

- Piksel fasad yang tertutup sulur menaikkan `lapuk` lokal, `LAPUK_LAJU * delta`
- Saat `lapuk` sepetak (4×4) melewati `LAPUK_AMBANG`, petak itu gugur
- Petak yang gugur → `_spawn_debris()` → jatuh → `settle_many()` → `T_PUING`
- `T_PUING` bisa ditumbuhi, dan sulur yang bertahan di atasnya jadi **pohon**

Seluruh rantai setelah "petak gugur" **sudah ada dan berjalan** di
[Structure.gd](../scripts/Structure.gd) — tidak perlu ditulis ulang, hanya
dipanggil dari pemicu baru.

Yang dijaga: erosi **tidak boleh** jadi jalan menang, dan tidak boleh membuka
jalur yang mustahil dicapai tanpa erosi. Ia hadiah visual atas ketekunan.
Kalau pemain mulai sengaja menumbuhkan tanaman demi meruntuhkan sesuatu,
`LAPUK_LAJU` terlalu tinggi.

Nama file diusulkan berganti: `Structure.gd` → `Erosi.gd`.

---

## 6. Tujuan permainan

Tiga babak, meniru busur Terra Nil (bangun → penuhi spesifikasi → tinggalkan
jejak permanen).

| Babak | Tujuan | Yang mengunci |
|---|---|---|
| **I. Menyusup** | jangkau satu akuifer, dapatkan pijakan di fasad | ekonomi `min(Air, Cahaya)` |
| **II. Menghijaukan** | penuhi target tutupan **per zona**, bukan satu angka global | perhatian & jadwal perawatan |
| **III. Menetap** | tanaman jadi permanen: pohon di puing, akar di dalam beton | erosi & waktu |

Target per zona, bukan persentase global, karena persentase global bisa
dipenuhi dengan menumpuk semuanya di satu sudut gelap — dan itu membuat peta
`vis` tidak berarti apa-apa.

**Kalah:** energi nol dan tidak ada ujung hidup yang bisa mencapai air. Sama
seperti rancangan lama; tetap berlaku.

---

## 7. Urutan kerja

Aturan lama tetap: **satu tahap per sesi, commit tiap tahap yang terverifikasi
jalan, jalankan sendiri di Godot sebelum lanjut.**

### TAHAP A — Kamera & split screen  ✅ SELESAI
Murni teknis. Gameplay lama tetap berjalan apa adanya di dalam kerangka baru.
Dunia ke 480×320, dua SubViewport, scroll, zoom 2×/4×, konversi mouse per-pane,
bake dicicil di balik layar MULAI.
*Dikerjakan pertama karena inilah risiko teknis terbesar, dan ia tidak
bergantung pada satu pun keputusan desain di bawahnya.*

Yang terverifikasi otomatis (headless):

| Cek | Hasil |
|---|---|
| Pane atas zoom 2 | `SubViewport` 480×192, layar (0,0)→dunia (0,0), layar (960,384)→dunia (480,192) |
| Pane bawah zoom 2 | `SubViewport` 480×128, layar (0,384)→dunia (0,192), layar (960,640)→dunia (480,320) |
| Jepitan kamera zoom 4 | atas (120,48)…(360,144), bawah (120,288) — tepat di batas pita |
| Keruntuhan + puing | `fail_member(7)` → struktur 0.92, 87 puing melayang |
| Ulang (R) | struktur kembali 1.00, tanpa error |

Angka yang diukur, bukan ditebak: bake penuh **209 ms** (1,24 ms per baris),
beban puncak **549** di member 7 sehingga `KAPASITAS_MAX = 765` menjaga rasio
lama 0.717.

**Sisa verifikasi manual (butuh mata di layar):** ketajaman piksel di kedua
tingkat zoom, rasa kecepatan geser `GESER_SPEED`, dan apakah pane bawah terasa
kosong sebelum TAHAP C mengisinya.

### TAHAP B — Susutkan Structure jadi Erosi
Buang rangka, beban, keruntuhan berantai, `weaken()`, kondisi menang lama.
Tambah peta `lapuk`. Puing, debu, pohon tetap hidup.
**Verifikasi:** sulur yang lama diam di satu titik membuat fasadnya gugur
sepetak, puingnya jatuh dan menumpuk, dan pohon masih bisa tumbuh di atasnya.

### TAHAP C — Bawah tanah jadi pane sungguhan
Deposit baru, generator tata letak bawah tanah, menembus beton.
**Verifikasi:** akuifer besar hanya bisa dicapai dengan menembus beton, dan
menembusnya terasa sebagai keputusan energi.

### TAHAP D — Perhatian & kalender
`perhatian`, inspeksi terjadwal, HUD kalender. Belum ada regu.
**Verifikasi:** menumbuhkan di jendela menaikkan perhatian jauh lebih cepat
daripada di bayangan, dan pemain bisa membaca jadwalnya tanpa bertanya.

### TAHAP E — Regu terjadwal
`Crew.gd` dan `Climber.gd` dipicu jadwal, bekerja per zona, lalu pulang.
**Verifikasi:** ada jendela waktu yang cukup untuk bereaksi sebelum mereka tiba.

### TAHAP F — Babak & kondisi menang
Target tutupan per zona, tiga babak, menang/kalah.

### TAHAP G — Poles
Parallax, audio, transisi, layar judul.

---

## 8. Yang TIDAK boleh dihidupkan lagi

- **Panas per-sulur.** Mustahil diawasi dengan perhatian yang sudah terbagi.
  Perhatian adalah satu angka untuk seluruh gedung.
- **Kerucut pandang real-time.** Menuntut mata pemain di pane atas terus-menerus
  dan mematikan separuh layar yang lain.
- **Keruntuhan berantai.** Ia yang membuat game terasa arcade.
- **Zoom pecahan.** Merusak pixel art.
- **Menang lewat kerusakan.** Erosi kosmetik, titik.

---

## 9. Yang tetap berlaku dari dokumen lama

Dari `01-konteks-game.md`: palet warna (§5), aturan tanpa gradien, rasa
"merambat, sabar, organik" (§4). **Tidak** berlaku lagi: §7 satu tangan di
mouse.

Dari `02-logika-game.md`: prinsip float-untuk-simulasi (§2), batas kecepatan
belok `MAX_TURN` (§4.2), tigmotropisme (§5.3), ekonomi `min(Air, Cahaya)` (§6),
menembus beton (§7), pratinjau jalur (§11). **Tidak** berlaku: §12 tata letak,
§15 daftar larangan.

Dari `CLAUDE.md`: seluruh tabel migrasi Godot 3→4, seluruh aturan render,
seluruh tabel "jangan diulang". Semuanya masih berlaku penuh.
