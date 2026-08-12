# Menjalar — konteks proyek

Game 2D pixel art. Pemain adalah tanaman merambat yang tumbuh di fasad gedung
kota. Dunia berukuran 480×320 piksel dan LEBIH BESAR daripada layar; ia dilihat
lewat dua pane split screen di jendela 960×640, masing-masing berkamera sendiri.

---

## Lingkungan — jangan salah engine

- **Godot 4.7 stable**, GDScript 2.0, renderer **Compatibility** (OpenGL 3.3).
- **BUKAN Godot 3.** Proyek ini dimigrasikan dari 3.5.3 pada 8 Agustus 2026.
  Kalau menemukan API Godot 3 di kode, itu sisa yang terlewat — perbaiki.

| Godot 3 (jangan dipakai lagi) | Godot 4 |
|---|---|
| `extends Reference` | `extends RefCounted` |
| `PoolByteArray`, `PoolRealArray` | `PackedByteArray`, `PackedFloat32Array` |
| `img.lock()` / `img.unlock()` | tidak ada — `set_pixel()` langsung |
| `Image.new()` + `img.create(...)` | `Image.create_empty(...)` (statis) |
| `tex.create_from_image(img, 0)` | `ImageTexture.create_from_image(img)` (statis) |
| mengarahkan ulang tekstur ke Image lain | `tex.set_image(img)` |
| `tex.set_data(img)` | `tex.update(img)` |
| `Sprite` | `Sprite2D` + `texture_filter = TEXTURE_FILTER_NEAREST` |
| `rect_position` / `rect_size` / `rect_min_size` | `position` / `size` / `custom_minimum_size` |
| `connect("sig", self, "_m", [arg])` | `sig.connect(_m.bind(arg))` |
| `emit_signal("sig")` | `sig.emit()` |
| `add_constant_override` / `add_font_override` | `add_theme_constant_override` / `add_theme_font_override` |
| `event.scancode` | `event.keycode` |
| `BUTTON_LEFT` / `BUTTON_RIGHT` | `MOUSE_BUTTON_LEFT` / `MOUSE_BUTTON_RIGHT` |
| `arr.empty()` | `arr.is_empty()` |
| `arr.remove(i)` | `arr.remove_at(i)` |
| `rand_range(a, b)` | `randf_range(a, b)` |
| `deg2rad` / `rad2deg` | `deg_to_rad` / `rad_to_deg` |
| `Color.linear_interpolate(c, t)` | `Color.lerp(c, t)` |

Verifikasi tanpa membuka editor:

```
"C:/Users/renaldi.iskandar/godot/Godot_v4.7.1-stable_win64_console.exe" \
    --headless --path . --quit-after 180
```

Nol keluaran selain baris versi berarti tidak ada error parse maupun runtime.

## Target hardware

Laptop pengembang, lewat renderer Compatibility (**minimal OpenGL 3.3**).

**PC lawas Intel HD OpenGL 2.1 sudah TIDAK didukung** sejak pindah ke Godot 4 —
tidak ada renderer Godot 4 yang turun sampai GL 2.1. Batasan di bawah ini
dipertahankan sebagai **disiplin desain**, bukan lagi karena dipaksa hardware:
ia menjaga game tetap murah, dan sudah membentuk seluruh identitas visualnya.

- **Tanpa shader.** Tidak ada `ShaderMaterial`, tidak ada `.gdshader`.
- **Tanpa physics engine.** Tidak ada `RigidBody2D`, `Area2D`, atau
  `CharacterBody2D`. Tabrakan dihitung sendiri lewat grid.
- **Draw call harus minimal.** Jumlah `Sprite2D` di scene dijaga tetap kecil.
- **Light2D BOLEH** — batasan ini dicabut 8 Agustus 2026, lihat di bawah.

## ARSITEKTUR RENDER DIGANTI — baca ini dulu

**11 Agustus 2026: `docs/09-arsitektur-render-baru.md` memisahkan simulasi
dari tampilan.** Simulasi tetap 480×320 satuan float; tampilan pindah ke node
Godot biasa (`Line2D`, `TileMapLayer`, `Sprite2D`, `Control`) dengan aset PNG
32–64 px ditampilkan 1:1, `Config.PPU = 4`, jendela 1920×1080. Dikerjakan
bertahap R1–R6 (§9 dokumen 09); gameplay harus tetap berjalan di setiap tahap.

Akibatnya, tiga kelompok aturan di bawah punya masa berlaku terbatas:

- **"Pencahayaan 2D"** (falloff bertangga, nearest wajib) — berlaku sampai R6.
  Setelah itu falloff halus boleh; larangan shader DICABUT.
- **"Aturan render"** (Image + ImageTexture, tiga lapis, texture.update) —
  berlaku selama `PixelCanvas.gd` masih hidup; ia dihapus bertahap R1–R4.
- **Larangan zoom pecahan** — hanya berlaku selama piksel diperbesar. Setelah
  aset tampil 1:1, `Camera2D.zoom` bebas.

Yang TIDAK ikut berubah: tanpa physics engine, input hanya di `main.gd`,
`Config.gd` nol fungsi, simulasi float, dan identitas warna — **kota abu-abu
dan tidak jenuh; tanaman satu-satunya yang berwarna.**

## Pencahayaan 2D — boleh, dengan dua syarat

Siang-malam memakai `CanvasModulate` (meredupkan kanvas layer 0) plus
`PointLight2D` di jendela yang menyala. HUD dan panel tuning ada di CanvasLayer
sendiri, jadi keduanya tidak ikut gelap tanpa perlu diatur.

Dua syarat yang **tidak boleh dilanggar**, karena inilah yang menjaga
identitas pixel art:

1. Tekstur lampu dibuat prosedural dengan falloff **bertangga**
   (`LAMPU_TINGKAT`), bukan gradien halus — lihat `PixelCanvas._make_lamp_tex()`.
   Gradien lembut melanggar aturan "tanpa gradien" di `docs/01-konteks-game.md` §5.
2. Setiap lampu wajib `texture_filter = TEXTURE_FILTER_NEAREST`, dan
   `texture_scale = Config.SCALE` supaya ukurannya sepadan dengan dunia 240×160.

Jumlah lampu dijaga kecil (`LAMPU_JUMLAH`): di renderer Compatibility tiap
lampu menambah satu lintasan render per objek yang disinari.

Nilai yang sudah disetel dari tangkapan layar: `LAMPU_RADIUS 14`,
`LAMPU_ENERGI 0.55`. Pada 30/1.1 jendelanya blown-out putih dan lingkaran
cahayanya saling tindih menutupi seluruh fasad.

## Aturan render

Semua yang menulis piksel ada di `scripts/PixelCanvas.gd`.

- Render lewat **`Image` + `ImageTexture`**, bukan `_draw()`. Menggambar ribuan
  piksel lewat `_draw()` jauh lebih mahal.
- `Image.lock()` / `unlock()` **sudah tidak ada di Godot 4** — panggil
  `set_pixel()` / `get_pixel()` langsung.
- Nearest-neighbor dipasang **dua lapis**: `texture_filter =
  TEXTURE_FILTER_NEAREST` di tiap `Sprite2D`, plus
  `textures/canvas_textures/default_texture_filter=0` di `project.godot`.
  Tanpa ini pixel art-nya jadi buram saat diskalakan 4×.
- Perbarui tekstur dengan **`texture.update(img)`** tiap frame. Jangan pernah
  membuat `ImageTexture` baru per frame.
- Tiga lapis Image: `world` (statis, sekali saat load), `tree` (akumulatif,
  hanya titik terbaru yang digambar ulang), dan `overlay` (dibersihkan tiap
  frame). Tiap pane punya SET SPRITE-nya sendiri yang menunjuk ke
  `ImageTexture` yang SAMA — satu gambar, dua jendela, 3 draw call per pane.
- **Pembesaran ke layar lewat `SubViewportContainer.stretch_shrink`**, bukan
  `Sprite.scale` dan bukan `Camera2D.zoom`. `stretch_shrink` adalah bilangan
  bulat, jadi ia menjamin pembesaran kelipatan bulat yang bebas pengambilan
  sampel sub-piksel. `Camera2D` di dalam tiap pane HANYA menggeser, zoom-nya
  tetap 1. Posisi kamera dibulatkan ke piksel dunia penuh (`Pane._terapkan`) —
  posisi pecahan menggeser seluruh kisi piksel setengah texel.
- Tiap `SubViewport` punya `World2D` sendiri, jadi `CanvasModulate` harus ada
  satu per pane. `PointLight2D` TIDAK diduplikasi: jendela semuanya di atas
  garis tanah, jadi pane bawah tidak pernah membutuhkannya.

## Aturan simulasi

- **Simulasi memakai float; pembulatan ke integer hanya saat render.**
  Menyimpan posisi sebagai integer membuat pertumbuhan tersendat dan bersudut.
- Ukuran dunia: `Config.W = 480`, `Config.H = 320`, `Config.GROUND_Y = 192`.
  **`Config.SCALE` sudah DIHAPUS** — tidak ada lagi satu skala tunggal, karena
  tiap pane punya zoom dan geserannya sendiri.
- Konversi mouse lewat `main._mouse_dunia()`, yang memakai kamera pane di bawah
  kursor. Jangan pernah membagi posisi mouse dengan sebuah konstanta.
- Zoom hanya boleh **bilangan bulat** (2 dan 4). Zoom pecahan membuat piksel
  berkedip dan buram.

## Aturan struktur kode

- **Semua input mouse dan keyboard HANYA di `main.gd`.** Kalau ada
  `Input.`, `get_global_mouse_position`, atau handler `_input` di file lain,
  itu salah tempat. Node UI berkomunikasi ke `main.gd` lewat sinyal.
- **`Config.gd` hanya berisi `var` dan `const`. Nol fungsi.** Dia AutoLoad
  dengan nama persis `Config` (Project Settings > AutoLoad).
- `WorldMap.grid` adalah `PoolByteArray` sepanjang `W * H` berisi enum terrain.
  Dia melayani tigmotropisme, deteksi air, dan bake cahaya sekaligus.

```
res://
├── main.tscn              root: Node2D, script main.gd
├── main.gd                orkestrator; SATU-SATUNYA yang baca input
└── scripts/
    ├── Config.gd          AutoLoad — hanya var & const, NOL fungsi
    ├── WorldMap.gd        peta + grid terrain + bake cahaya & keterlihatan
    ├── Strand.gd          satu untai: tumbuh, tigmotropisme, pratinjau
    ├── TreeSim.gd         kumpulan untai + ekonomi energi
    ├── Structure.gd       beban, keruntuhan, puing, pelemahan
    ├── Cycle.gd           kalender: hari, perhatian, jadwal inspeksi/rawat
    ├── Pane.gd            satu pane split screen: viewport, kamera, zoom
    ├── PixelCanvas.gd     semua yang menulis piksel
    ├── TuningPanel.gd     slider runtime
    └── Hud.gd             bar energi/tertutup/terlihat + overlay MULAI
```

---

## Jangan diulang — bug yang sudah pernah diperbaiki

Diambil dari `docs/04-status-proyek.md` §9.

| Bug | Penyebab | Perbaikan |
|---|---|---|
| Pohon seperti cacing gemuk | 1 titik per frame, bukan per piksel | akumulator `_acc`, catat titik tiap 1 px |
| Ekonomi buntu total | `min(air, cahaya)` = 0 karena belum ada daun | beri nilai dasar 1.0 pada air dan cahaya |
| Energi boros tak masuk akal | biaya linear terhadap jumlah ujung, dan terikat `GROWTH_SPEED` | pangkat `COST_TIP_EXP`, lepas dari `GROWTH_SPEED` |
| Panas 98% di malam pertama | `heat += seen * NIGHT_HEAT` tanpa `delta` | tambah `* delta` + ambang `vis > 0.45` |
| Ujung mengorbit kursor | sudut target dihitung walau kursor sangat dekat | `DEAD_ZONE` 7 px — di dalamnya, tumbuh lurus |
| Ujung mati di tepi layar | tidak ada pantulan | pantul sudut di tepi |
| `z_index` pada `ColorRect` | `ColorRect` adalah `Control`, bukan `Node2D` | pindah ke `CanvasLayer` terpisah |
| Fotosintesis jalan malam hari | tidak dicek fase | energi hanya bertambah saat `PHASE_DAY` |
| Permainan buntu setelah keruntuhan besar | ujung sulur yang kehilangan fasad dimatikan permanen, padahal satu rantai melubangi sampai 20 dari 31 member sekaligus | ujung **mundur** ke titik terakhir yang masih menempel, lalu lanjut hidup (`Strand.retreat_to_facade`) |
| STRUKTUR 0% tapi gedung tetap berdiri | member hanya garis 3 px; menghancurkan seluruh rangka cuma menghapus 31 garis tipis dari persegi panjang padat | `WorldMap.panels` — massa dinding jatuh menyusul rangkanya (`Structure._runtuhkan_panel`) |
| Regu perawatan meruntuhkan gedungnya sendiri | `Crew.trim()` menarik ujung sulur mundur; kalau mendarat dekat sambungan ia parkir di sana sepanjang sisa siang (sulur tidak tumbuh siang) sambil terus melemahkan — 22 detik gratis, berulang tiap regu memotong | pelemahan digerbang fase: akar hanya menggerogoti saat siang, sulur hanya saat malam, yaitu saat masing-masing memang aktif tumbuh |
| Sulur terkurung di panel fasad | lubang keruntuhan selebar 3 px diperlakukan seperti langit, karena bagi sulur "solid" berarti bukan-fasad | `WorldMap.vine_ok()` — sulur boleh merentang `VINE_JEMBATAN` piksel. **Semua** cek pijakan sulur harus lewat `vine_ok()`, bukan `on_facade()` mentah, atau perbaikannya batal sendiri |
| Tombol tidak bereaksi setelah pindah ke Godot 4 | satu `scancode` milik Godot 3 pecah jadi `keycode` (ikut layout) dan `physical_keycode` (posisi fisik); salah satunya bisa 0 tergantung asal event | `main._kunci(event, kode)` memeriksa **keduanya**. Semua pembacaan tombol wajib lewat helper itu, jangan bandingkan `event.keycode` langsung |
| Peta risiko (V) dikira rusak padahal jalan | alpha 0.30 pada kisi 4 px praktis tak terlihat di atas fasad abu-abu — terbaca sebagai derau, bukan peta | dinaikkan ke alpha 0.55 kisi 3 px. Sebelum memburu bug render, buktikan dulu piksel benar-benar tertulis (hitung piksel non-transparan di `_ovl_img`) |
| Panel tuning terpotong di tepi bawah | font bawaan Godot 4 lebih besar daripada Godot 3, jadi daftar slider yang dulu pas jadi meluber | `ScrollContainer` setinggi `Config.PANEL_TINGGI`. Menambah slider baru tidak akan pernah lagi memotong yang di bawahnya |
| Menekan R (ulang) melempar error di `setup_lights` | `_lights` berisi `{"node":…, "win":…}`, tapi kode pembersihnya memanggil `l.queue_free()` — itu memanggil metode Node pada sebuah Dictionary | `l.node.queue_free()`. Kalau sebuah array diisi dict pembungkus, SETIAP tempat yang menyapunya harus ikut dibongkar |
| Bake cahaya jadi hitch setelah dunia diperbesar | fasad 4× lebih luas berarti 12.096 sinar dalam satu frame | bake DICICIL: `WorldMap.bake_langkah(baris)` dipanggil tiap frame, dengan dua anggaran (`BAKE_BARIS_DIAM` 16 di balik layar MULAI, `BAKE_BARIS_MAIN` 2 saat bermain). Aman dicicil karena `vis[y]` hanya membaca `light[y]`. Tombol MULAI dikunci sampai selesai, supaya fotosintesis tidak pernah jalan di atas peta cahaya kosong |
| Nilai ambang keruntuhan ditebak setelah ukuran fasad berubah | beban member sebanding panjangnya, jadi memperbesar fasad menaikkan seluruh beban sekaligus | `Structure.lapor_stress()` mengukur rasio beban terberat. Patokannya 0.717; setelah dunia 480×320 beban puncaknya 549, jadi `KAPASITAS_MAX = 765`. **Ukur, jangan tebak** — tiap kali geometri fasad berubah, jalankan ulang |

---

## Arah saat ini

**Arah berubah lagi pada 10 Agustus 2026. Rancangan yang berlaku sekarang ada
di `docs/06-desain-stealth-splitscreen.md`. Baca itu sebelum menyentuh mekanik
apa pun.** Ringkasnya:

**Menjalar adalah game stealth sistemik dengan layar terbagi dua.** Patokan
kualitasnya Terra Nil — tenang, sistemik, tanpa refleks. BUKAN lagi game
pembongkaran ala Rampage.

- **Split screen.** Pane atas = fasad gedung, pane bawah = bawah tanah.
  Masing-masing punya kamera sendiri: scroll bebas, zoom diskrit 2× dan 4×.
  Dunia jadi 480×320, lebih besar daripada layar.
- **Perhatian adalah sumber daya.** Pemain hanya bisa mengarahkan satu ujung
  pada satu waktu; yang lain tumbuh liar. Memilih pane berarti memilih apa yang
  lepas dari pengawasan.
- **Stealth kembali, tapi TERJADWAL.** Satu angka `perhatian` untuk seluruh
  gedung, inspeksi berkala, jadwal perawatan yang diumumkan lebih dulu. Regu
  datang hanya saat dipanggil jadwal. Tekanan dari perencanaan, bukan kaget.
- **Pembongkaran turun pangkat jadi kosmetik.** Fasad yang lama dirambati gugur
  sepetak demi sepetak jadi puing. Ia BUKAN jalan menang.

Kenapa stealth boleh hidup lagi padahal dulu dihapus: alasan penghapusannya
adalah benturan dengan pembongkaran (stealth menuntut pemain lemah dan
tersembunyi, pembongkaran menuntut sebaliknya). Pembongkaran sudah turun jadi
kosmetik, jadi benturan itu tidak ada lagi. Yang tetap TIDAK boleh hidup lagi:
**panas per-sulur** dan **kerucut pandang real-time** — keduanya menuntut
pengawasan terus-menerus yang mustahil dengan perhatian terbagi dua pane.

Peta `vis` tetap dipakai. Maknanya sekarang: seberapa cepat sesuatu menaikkan
`perhatian`.

Riwayat arah: stealth-coverage → pembongkaran struktural → stealth sistemik
split screen. Dua yang pertama sudah selesai dibangun dan berjalan; yang ketiga
baru dimulai.

Urutan kerja bertahap ada di **`docs/06-desain-stealth-splitscreen.md`** §7
(TAHAP A sampai TAHAP G). `docs/05-prompt-pivot-pembongkaran.md` disimpan hanya
sebagai riwayat — TAHAP 7 dan 8 di sana sudah tidak berlaku. Kerjakan **satu
tahap per sesi**, commit tiap tahap yang sudah terverifikasi jalan.

Status: **TAHAP A–F dan R1–R6 selesai — seluruh peta jalan docs/06 dan
docs/09 tuntas.** Arah kerja sekarang: **`docs/11-peta-jalan-g-plus.md`**
(G1–G10), disusun dari review jujur 12 Agustus dan DISETUJUI PENUH pemilik
proyek. Berikutnya: **G1** (jeda + percepat 2×). Tiga temuan terbesar
review yang menjadi tulangnya: kepadatan keputusan per menit rendah,
ekonomi mati setelah babak I, dan belum ada audio.

HUD dua-pita (docs/08 §3, dibangun setelah R6):

- Pane diapit dua pita 40 px (`HUD_ATAS`/`HUD_BAWAH`; pane menyusut ke
  700/300) — NOL elemen HUD di wilayah kanvas. Pengecualian tunggal: band
  pesan sementara di bawah pita atas (pola "pita inspeksi" ui_kit) untuk
  flash & teks akhir permainan; `_lbl_win` mengambang dihapus.
- Pita atas: ikon air/cahaya/energi/perhatian/kalender (5 generasi PixelLab
  terakhir — kuota 40/40 HABIS). **Penanda leher botol**: sisi min(Air,
  Cahaya) yang lebih kecil diberi bingkai + angka C_TIP lewat StyleBoxFlat
  yang di-toggle — satu-satunya pengajaran aturan min() (docs/08 §3.1).
- Pita bawah: baris babak + 4 bar zona (BA/TA/BB/TB) bergaris target
  `ZONA_TARGET`; zona yang dijadwalkan dirawat dibingkai `C_WARN`.
- Menang/kalah kini lewat kartu besar sekali (di `main`, transisi `won`)
  lalu band memegang teksnya; sorotan `C_TIP` tetap satu-hal-satu-waktu.
- Panel tuning turun ke y=52 (di bawah pita), help ke (440, 986).

Paket keterbacaan kedua (playtest keempat, 12 Agustus — "energi & perhatian
masih membingungkan, regu sibuk di bawah tanah"):

- **Regu memotong sulur DI PANGKALNYA** (`Crew._cari_zona` mencari titik
  paling-pangkal tiap sulur di pita jangkauan; `TreeSim.pangkas(s,i)` —
  dipakai juga tombol X): seluruh bagian di atas potongan lenyap sekali
  gergaji (`CREW_POTONG` 2.4 dtk), sisa tunggul 2 titik yang bisa tumbuh
  lagi. **Regu TIDAK PERNAH menyentuh akar** — dulu regu zona BAWAH tak
  bisa meraih ujung sulur tinggi sehingga malah menggali akar, terbaca
  absurd ("pengelola tidak melihat bawah tanah"). Risiko bawah tanah tetap
  kanal utilitas. `CREW_CABUT`/`CREW_BAND_BAWAH` dihapus.
- Tempo respons: `INSPEKSI_TIAP` 2, `JEDA_RAWAT` 1 — regu pertama bisa tiba
  hari ke-3, bukan ke-5 ("menjalar sejak hari 1, tukang kebun baru datang
  hari 5"). Jendela reaksi tetap satu hari penuh.
- Keterbacaan ekonomi: label `+N/dtk` di samping bar energi ("malam +0" =
  fotosintesis siang saja), panah tren ▲/—/▼ di samping bar perhatian
  (cuplikan 0,7 dtk), dan kartu fajar menyebut rumus dengan angka hari itu:
  "energi siang ini: min(AIR 1, CAHAYA 84) — kejar yang kecil".

R6 yang sudah berdiri — `PixelCanvas` MATI, semua visual adalah view:

- `scripts/render/AktorView.gd` — regu & pemanjat sprite PixelLab 48×64,
  satu batch `_draw()`: animasi 2 frame (0,3 dtk), cermin hadap lewat
  transform, pingsan = sprite rebah redup, garis merah ke sasaran saat
  memangkas. Pemanjat berpusat di titik sulur yang dipijaknya.
- `scripts/render/UjungView.gd` (satu per pane) — denyut ujung, kotak
  pilihan sebesar radius klik, bar menembus beton, pratinjau jalur (diisi
  `main` lewat properti `pratinjau`).
- `scripts/render/RisikoView.gd` — peta V per petak vis 8×8, jujur pada
  resolusi datanya. `main` cuma menyetel `visible`.
- `PohonView` memakai sprite `aset/pohon.png`, tumbuh lewat SKALA SERAGAM
  berjangkar di pangkal (0.22→1.0) — bukan diregangkan tingginya.
- **`PixelCanvas.gd` DIHAPUS** → `scripts/Suasana.gd`: hanya CanvasModulate
  per pane + lampu jendela (falloff bertangga dipertahankan sebagai gaya).
  `TreeSim.render()` ikut hilang; tidak ada Image/ImageTexture tersisa.
- Aset aktor dinormalisasi prosedural (scratchpad `normalisasi_aktor.gd`):
  palet dipaksa ke warna `regu_diam`, tinggi bounding-box disamakan —
  jawaban untuk "warna & ukuran antar frame tidak konsisten". Sprite
  pemanjat TIDAK boleh berisi tali/tiang (ia memanjat sulur pemain; tali
  membuat normalisasi mengecilkan karakternya).
- Kuota PixelLab terpakai 35/40. Sisa 5 — untuk TAHAP G, prioritaskan
  varian pohon kedua & ikon HUD; jangan buang untuk tekstur polos.
- Urutan z pane atas: terrain+fasad+puing-tanah 0, tanaman 1, puing
  melayang 2, aktor 3, ujung/risiko 4.

R4+R5 yang sudah berdiri — bake petak & kamera piksel:

- **R4**: `light`/`vis` hidup di GRID PETAK 60×40 (`_pw`, index `(y/PETAK)*
  _pw + x/PETAK` di `light_at`/`vis_at` — pemanggil tetap koordinat satuan).
  ~600 sinar, selesai seketika; SELURUH mesin cicilan dibuang (`bake_langkah`,
  `bake_sibuk`, `set_bake`, tombol MULAI terkunci). `bake_semua()` di build,
  `rebake_dari(y)` saat siluet berubah. Catatan: docs/09 R4 menyebut "hapus
  PixelCanvas.gd" — DITUNDA ke R6, overlay masih menggambar tips/aktor/debug.
- **R5**: jendela **1920×1080** (resizable), pane 1920×720 / 1920×360,
  SubViewport ukuran piksel penuh. SEMUA view hidup di ruang piksel — semua
  skala 1/PPU dihapus; sprite overlay & lampu justru di-skala ×PPU. **Zoom
  `Camera2D` BEBAS** (0.75–3.0, roda ×1.25) — larangan zoom bulat era
  `stretch_shrink` dicabut karena aset tampil 1:1. `Pane.zoom` float;
  `titik_dunia()` tetap mengembalikan SATUAN simulasi.
- HUD pindah ke x=1596; panel tuning setinggi 980; help di y=1034.

Paket keterbacaan (playtest ketiga, 11 Agustus — "bingung objective &
punishment"):

- **Pemangkasan MENGHAPUS rambatan** (`WorldMap.hapus_rambatan`, dipanggil
  `Strand.trim` dan `sever_at`): bar HIJAU/zona benar-benar mundur saat regu
  memotong. Sebelumnya `tutup` permanen — hukuman regu tidak meninggalkan
  bekas sistemik apa pun, hanya garis memendek. Flash "Regu memangkas —
  tutupan zona berkurang!" (diredam 4 detik) menyertainya.
- **Kartu pergantian fase** (`Hud.tampil_kartu`, `main._kartu_fase`):
  permainan JEDA `KARTU_DETIK` saat fase berganti; kartu besar mengumumkan
  hari/inspeksi/kedatangan regu, klik untuk lewati. Inilah pengajar utama —
  sistem perhatian dijelaskan TEPAT saat bekerja (hasil inspeksi menyebut
  angka & ambangnya), bukan lewat tembok teks.
- HUD: panel dilebarkan (`HUD_LEBAR` 300, x 648), font 14 — playtest kedua
  teks babak terpotong kanan. SEMUA teks HUD dinamis wajib muat di lebar itu.
- Satu baris redup di bawah bar perhatian menjelaskan tuasnya (naik/turun).
  Larangan "nol tips" docs/08 DILONGGARKAN atas permintaan pemilik proyek.
- Tempo turun lagi: `DAY_LEN` 42, `NIGHT_LEN` 46.

TAHAP F yang sudah berdiri — tiga babak (`Babak.gd`):

- **I MENYUSUP** — `sim.dekat_akuifer` (ada akar di akuifer) DAN tutupan ≥
  `BABAK1_PIJAK`. **II MENGHIJAUKAN** — `zona_tutupan(i) >= ZONA_TARGET`
  untuk KEEMPAT kuadran; bar HUD mengukur zona TERLEMAH, bukan rata-rata.
  **III MENETAP** — `BABAK3_POHON` pohon permanen → menang. Transisi satu
  arah; flash pesan saat naik babak.
- **Kalah = kematian total**: `alive_count()==0` dan tidak ada pohon.
  BUKAN timer kelaparan — dasar air/cahaya 1.0 (perbaikan anti-buntu lama)
  menjamin energi selalu pulih di siang hari, jadi timer kelaparan tidak
  pernah bisa jatuh; jangan coba menghidupkannya lagi.
- `WorldMap.zona_luas/zona_tutup` + `zona_tutupan(i)` — tutupan per kuadran,
  diisi `rambati()`. `COVERAGE_GOAL` tinggal untuk skala jumlah regu.
- HUD baris babak menggantikan "HIJAU x%": tujuan babak berjalan + bar.

Puing yang mengendap DIGAMBAR PER SEL (`render/PuingTanahView.gd`), BUKAN
ubin — pemetaan mayoritas 8×8 meratakan gundukan falling-sand jadi balok
kaku (playtest 11 Agustus, dua kali dikeluhkan). `T_PUING` dipetakan ke
langit di `TerrainView.ATLAS`; view membaca `world.settled` dan redraw hanya
saat `settled_n` berubah.

TAHAP C yang sudah berdiri — bawah tanah jadi pane sungguhan:

- **Terrain baru** (enum 11–15): `T_AKUIFER` (air +4, terbesar; dikurung
  cangkang beton ~11 satuan = dua kali menembus), `T_HUMUS` (laju akar
  ×1.6), `T_BATU` (solid SELAMANYA — dinding, bukan gerbang), `T_GORONG`
  (koridor, laju ×2), `T_UTILITAS` (bisa dilalui, tapi kontak menaikkan
  perhatian lewat kanal `terlihat` — UTILITAS_SEEN 90, ~+0.04 per lintasan).
  Atas = terlihat, bawah = terasa. `T_PIPE` tidak dipakai tata letak lagi.
- **Menembus beton** (docs/02 §7, akhirnya dibangun): klik ujung akar yang
  menempel beton (`world.dekat_beton`) → `Strand.tembus` 0→1 selama
  `CRACK_DURATION`, tarif `COST_CRACK/CRACK_DURATION`; energi habis =
  kemajuan MEMBEKU; selesai = `world.tembus_beton()` menggali terowongan
  `TEMBUS_PANJANG` searah akar, HANYA sel beton. Bar kemajuan di overlay
  (`draw_tembus`). Digerbang fase: hanya maju saat siang.
- Tata letak bawah tanah baru hardcoded di `WorldMap.build()`: dua akuifer
  di dasar, humus di jalur, tiga bongkah batu, satu gorong lintas tengah,
  pita utilitas di bawah gedung dengan celah aman di SEED_X. Air: akuifer
  +4 / lembap +2 / kering 0.25 (bonus pipa dihapus).
- Ubin puing digambar ulang (playtest: "kurang nyaman") — gugus bongkah
  besar, bukan bercak tersebar; atlas terrain kini 13 ubin (416×32).
- Jebakan harness yang sudah dimakan: menaruh akar uji DI DALAM bongkah
  batu membuatnya terkubur (semua arah solid) dan diam selamanya — itu
  perilaku benar, bukan bug. Cek tata letak dulu sebelum memarkir titik uji.

TAHAP E yang sudah berdiri — regu dipicu kalender:

- Regu HANYA muncul saat `cycle.rawat_hari_ini()` dan siang; selain itu
  `units = []`. Terverifikasi harness: 0 frame regu di luar jadwal, dan ada
  jendela reaksi 2 hari penuh antara pengumuman dan kedatangan.
- Jumlah = `1 + rawat_kekuatan * (CREW_MAX-1)` — `rawat_kekuatan` adalah
  perhatian saat inspeksi. Masuk dari tepi layar sisi zona.
- Bekerja HANYA di paruh dunia milik zona terjadwal (barat/timur). Zona
  bersih → `pulang = true`, berjalan ke tepi, hilang. TIDAK ADA patroli.
- Pemanjat: hanya untuk zona ATAS (idx 0–1), memanjat sulur yang ujungnya
  di paruh zona itu; jumlah dari `rawat_kekuatan` juga.
- Setelah hari perawatan lewat: `perhatian *= PERHATIAN_SETELAH_RAWAT` dan
  `zona_bobot` separuh — siklusnya bisa berulang.
- **Makna ganda X DIDAMAIKAN**: memutus sulur merontokkan daunnya =
  pemangkasan sukarela; `perhatian -= PERHATIAN_PANGKAS`. Satu tombol,
  jawaban pemanjat sekaligus perapian diri sebelum inspeksi.
- `Crew.update(delta, sim, world, erosi, cycle)`;
  `Climber.update(delta, sim, world, cycle)`. `CREW_CARI` dihapus — regu
  dipanggil ke zona, tidak ada batas jarak cari di dalamnya.

TAHAP D yang sudah berdiri — perhatian & kalender (`Cycle.gd` naik pangkat):

- **`Cycle.perhatian`** — SATU angka 0..1 untuk seluruh gedung. Naik dari:
  (1) pertumbuhan di area terlihat — sinyal `terlihat` yang dikembalikan
  `TreeSim.update` (jumlah vis per titik tumbuh; inilah makna peta `vis`
  sekarang); (2) jendela tertutup (`rasio_jendela_tertutup`); (3) pintu
  terambati. Turun: peluruhan waktu. Kalibrasi di komentar Config
  (PERHATIAN_TUMBUH 0.0008 = satu malam sembrono ≈ +0.13).
- **Kalender**: `hari` bertambah tiap fajar; tiap `INSPEKSI_TIAP` hari ada
  INSPEKSI — kalau `perhatian >= AMBANG_RAWAT`, PERAWATAN dijadwalkan
  `JEDA_RAWAT` hari ke depan dengan sasaran `world.zona_teratas()` (kuadran
  fasad dengan rambatan paling mencolok, bobot vis, `zona_bobot`).
- HUD: `HARI n`, baris kalender selalu terlihat ("INSPEKSI dalam N hari" /
  "PERAWATAN hari N — ZONA", disorot saat ada jadwal), bar PERHATIAN warna
  jendela dengan garis penanda ambang — TANPA warna merah panik, sengaja
  (docs/08 §3.1).
- Di TAHAP D regu BELUM dipanggil kalender — mereka masih sistem interim.
  TAHAP E yang menyambungkannya.
- Pertanyaan terbuka: `X` sekarang berarti "putus sulur" (jawaban pemanjat);
  docs/06 §2.5 juga menyebut "rontokkan daun mencolok" sebagai penurun
  perhatian. Dua makna ini belum didamaikan — putuskan saat TAHAP E.

TAHAP B yang sudah berdiri — pembongkaran resmi jadi kosmetik:

- **`Structure.gd` DIHAPUS**, diganti `Erosi.gd` (~190 baris): rangka
  member/joint, aliran beban, keruntuhan berantai, panel, `weaken()`, dan
  menang-lewat-kerusakan semuanya lenyap. Puing jatuh, debu, dan bake-ulang
  cahaya dibawa utuh.
- **`WorldMap.tutup`** — peta bekas rambatan, diisi `rambati()` dari
  `Strand.grow` (3×3 per titik sulur). Tiga peran: (1) pijakan KEKAL —
  `vine_ok()` menerimanya, jadi erosi TIDAK PERNAH membuat sulur kehilangan
  pijakan atas keberhasilannya sendiri; (2) bahan bakar erosi per petak 4×4
  (`LAPUK_LAJU`, berbobot luas tutupan petak); (3) kemajuan pemain lewat
  `tutupan()`.
- **Menang interim** (sampai TAHAP F per zona): `tutupan() >= COVERAGE_GOAL`
  (0.55) — angka dari rancangan paling awal. Bar HUD: `HIJAU x% dari 55%`.
- Jumlah regu/pemanjat interim diskalakan dari `tutupan()`, bukan integritas —
  diganti total oleh perhatian saat TAHAP E.
- Ikut terhapus karena kehilangan pemanggil: `retreat_to_facade`/
  `retreat_unsupported`, `_tarik_joint` (tigmotropisme ke joint), debug rangka
  (tahan B), `draw_cracks`/`draw_frame`, mekanisme freeze/shake keruntuhan.
- `Crew.update(delta, sim, world, erosi, phase)`;
  `Climber.update(delta, sim, world, phase)`;
  `Hud.refresh(sim, cycle, world, ...)`.

Dari playtest yang sama, sudah dijawab langsung:
- Layar pembuka "terlalu ramai" → layar judul pekat yang menutup dunia dan
  panel (judul + tagline + MULAI + satu baris kontrol; dinding teks tutorial
  dihapus — aturan §6 Konteks berlaku lagi), dan panel tuning mulai tertutup.
- Akar terlalu cepat / sulur terlalu lambat → `GROWTH_SPEED` 18→12,
  `VINE_SPEED` 6.4→9.6. Alasan "sulur lambat demi rasa stealth" dicabut:
  rasa stealth datang dari kalender, bukan kursor lamban.
- Tempo diperlambat: `DAY_LEN` 30, `NIGHT_LEN` 34.
- Musuh DIREDAKAN SEMENTARA (`CREW_MAX` 2, `CLIMB_MAX` 1) — bukan perbaikan;
  sistem spawn-nya memang diganti inspeksi terjadwal di TAHAP D–E. Jangan
  menyetel-nyetel yang akan dibuang.

R3 yang sudah berdiri — lapisan `tree` DIHAPUS:

- `scripts/render/PohonView.gd` — semua pohon satu batch `_draw()`; redraw
  hanya selama ada yang masih meninggi. Prosedural dulu — sprite PixelLab
  menunggu R6, karena pohon tumbuh tingginya dan meregangkan sprite merusak
  gambarnya.
- `scripts/render/PuingView.gd` — puing melayang + debu satu batch; saat
  daftar kosong, satu redraw penutup lalu nol kerja.
- Mekanisme `_redraw_tree` / `clear_tree` / `gambar_penuh` di `main.gd`
  DIHAPUS — view membangun ulang dirinya sendiri saat data berubah (SulurView
  lewat jumlah titik, DaunView lewat jumlah daun), jadi trim/retreat/putus
  tidak butuh sinyal render apa pun.
- `TreeSim.render(canvas)` (tanpa `full`) — hanya denyut ujung, di overlay.
- Overlay MASIH hidup (menyimpang dari teks R3 di docs/09, disengaja): aktor
  baru dapat sprite di R6, dan retakan/pratinjau/peta debug ikut pindah saat
  itu. Isi overlay sekarang: tips, pratinjau, crew, climber, retakan, risk,
  frame.

R2 yang sudah berdiri — terrain = TileMapLayer, fitur fasad = _draw:

- **`WorldMap.image` DIHAPUS.** Grid satuan adalah satu-satunya kebenaran;
  `_rect()` tidak lagi menerima warna. Perubahan grid (carve, puing) menandai
  petak 8×8 lewat `tile_kotor`; `TerrainView.sinkron()` mengambilnya tiap
  frame dan hanya menghitung ulang petak yang berubah.
- `scripts/render/TerrainView.gd` — dua `TileMapLayer` (satu per pane, hanya
  baris zonanya), tileset dibangun dari `aset/terrain_atlas.png` (8 ubin
  32×32 prosedural, sementara). Skala 1/PPU menjatuhkannya ke ruang satuan.
- `scripts/render/FasadView.gd` — jendela/pintu/ledge digambar `_draw()` pada
  posisi satuan persisnya, karena fitur TIDAK duduk di kisi petak (jendela
  14×16 pitch 30×26) dan menggesernya berarti mengubah gameplay. Fitur yang
  gridnya sudah runtuh otomatis tidak digambar.
- `WorldMap.tile_terrain(tx,ty)` — mayoritas isi grid petak; jendela/pintu/
  ledge dihitung dinding; puing menang dini (≥6 sel) supaya puncak tumpukan
  tidak melayang.
- Lubang carve selebar 3–5 satuan TIDAK terlihat di ubin (di bawah mayoritas
  petak) — diterima, karena TAHAP B membuang carve member sepenuhnya.
  `vine_ok()` tetap bekerja penuh; ini murni visual.
- Jangan menamai metode `_set` di kelas mana pun — bentrok dengan
  `Object._set(property, value)` bawaan dan gagal parse.

R1 yang sudah berdiri — sulur/akar = `Line2D`, daun = sprite:

- `scripts/render/` — lapis view: `TanamanView` (manajer + root 1/PPU per
  pane), `SulurView` (satu untai = satu Line2D; points dibangun ulang HANYA
  saat jumlah titik berubah, ambil tiap titik ke-3), `DaunView` (semua daun
  satu `_draw()` batch; redraw hanya saat jumlah berubah / ada daun muda).
- Daun dimajukan dari R3 atas keputusan pemilik proyek: batang polos tanpa
  daun terbaca sebagai downgrade. Batang dan daun adalah lapisan TERPISAH —
  itulah yang memungkinkan tahap kepadatan daun, layu per helai, dan
  pemangkasan. Jangan pernah membakar daun ke tekstur batang.
- `aset/` — `sulur_batang.png` & `akar_batang.png` 32×8 (prosedural, tiga
  pita; PixelLab GAGAL untuk strip polos — kuotanya dipakai untuk objek
  organik saja), `daun_atlas.png` 96×24 (4 varian dari PixelLab, 48×48
  diperkecil nearest 2×). PixelLab minimum kanvas 32×32; `Line2D` TILE wajib
  `texture_repeat = TEXTURE_REPEAT_ENABLED`.
- Kunci API PixelLab ada di `.mcp.json` (di-gitignore). Tier gratis dihitung
  per-generation; 422 validasi tidak memakan kuota.
- Urutan z per pane: world 0, batang 1, pohon+daun 2, overlay 3.

Dua keluhan playtest TAHAP A yang harus dijawab sisa jalur R:
1. Zoom `stretch_shrink` tidak terasa seperti "dua dunia" — dijawab R5 + §3
   dokumen 09 (tiap pane cabang node sendiri, zoom `Camera2D` bebas).
2. HUD penuh dan meluber dari tata letak — dijawab R6 + anatomi HUD
   `docs/08-arah-visual.md` §3 (dua pita, nol elemen di atas kanvas).

Mekanik di bawah ini masih versi pembongkaran dan berjalan tanpa error di
dalam kerangka kamera yang baru — jangan anggap rusak hanya karena tidak cocok
dengan rancangan baru.

Catatan yang jangan hilang: akar TIDAK pernah bertemu puing. Puing selalu
mengendap di atas `GROUND_Y` karena `blocked()` menghentikannya di sana,
sedangkan akar hanya hidup di bawahnya. Baris TAHAP 6 soal "akar menembus
puing" di dokumen sengaja dilewati, bukan terlupa.

TAHAP 2–5 sudah dijalankan di Godot dan berjalan tanpa error. Keruntuhan
berantai plus getaran layar dinilai pemilik proyek sudah terasa menarik — jadi
gerbang verifikasi TAHAP 3 lolos dan konsep pivotnya terbukti.

Sisa yang diketahui: lubang hasil keruntuhan selebar 3 piksel memotong fasad
jadi panel-panel terpisah, dan sulur tidak bisa menyeberanginya karena bagi
sulur "solid" berarti bukan-fasad. TAHAP 6 (puing jadi terrain baru) yang
seharusnya membuka jalur lagi.

Sistem yang sudah ada dari pivot. Tanda **[BUANG]** = dihapus di TAHAP B,
**[TETAP]** = dipertahankan apa adanya, **[UBAH]** = bertahan tapi pemicunya
diganti. Rinciannya di `docs/06-desain-stealth-splitscreen.md` §5 dan §4.3.

- **[BUANG]** `WorldMap.members` / `.joints` — rangka 4 kolom × 5 balok, disimpan sebagai
  31 ruas antar-joint. `solve_order` sudah topologis atas-ke-bawah.
- **[BUANG]** `WorldMap.kapasitas(m)` — satu-satunya sumber kebenaran kapasitas:
  `integritas_member * min(integritas kedua joint) * KAPASITAS_MAX`.
- **[BUANG]** `WorldMap.panels` — 12 panel dinding di antara rangka. **Inilah massa gedung
  yang sebenarnya**; member cuma garis selebar 3 px. Panel jatuh saat
  `PANEL_AMBANG` dari 4 member yang mengurungnya sudah gagal.
- **[SEBAGIAN]** `Structure.gd` — solve beban, keruntuhan berantai per gelombang, puing,
  debu, panel, dan pelemahan oleh tanaman. Beban/rangka/pelemahan dibuang;
  puing, debu, dan bake-ulang cahaya tetap. Jadi `Erosi.gd`, ~150 baris.
- **[BUANG]** Sulur menyerang joint, akar menyerang ruas kolom paling bawah.
- **[TETAP]** `WorldMap.vine_ok()` — predikat pijakan sulur, mengizinkan rentangan
  `VINE_JEMBATAN` px melewati celah sempit.
- **[TETAP]** `T_PUING` — puing yang mengendap ditulis ke `grid`, bukan cuma ke `image`,
  jadi ia terrain sungguhan: bisa ditumbuhi sulur dan ikut melempar bayangan.
  Peta cahaya dipanggang ulang sekali setelah puing diam (`PUING_TENANG`), dan
  hanya dari baris puncak tumpukan ke bawah — sinar datang dari atas-kiri jadi
  puing hanya membayangi yang di bawahnya. Hemat ~66% dibanding panggang penuh.
- **[UBAH]** `Crew.gd` — regu perawatan, antagonis darat. Jangkauannya hanya pita di
  sekitar garis tanah; sulur tinggi belum ada yang mengancam. Jawaban pemain
  terhadap mereka adalah **menimbun mereka dengan puing yang jatuh**
  (`CREW_PINGSAN`) — sengaja sementara, karena regu yang bisa dihabisi berarti
  peta bisa dibersihkan lalu pemain bekerja tanpa lawan sama sekali.

- **[TETAP]** `TreeSim.trees` — sulur yang bertahan di atas puing berakar jadi **pohon**.
  Satu-satunya hal permanen: gedung runtuh, sulur dipangkas regu, pohon
  tinggal. Pembagian peran yang harus dijaga — **pohon = ekonomi, sulur dan
  akar = senjata.** Pohon menyumbang ke air DAN cahaya (menaikkan lantai
  `min()`), tapi tidak bisa melemahkan apa pun, jadi pemain tidak bisa menang
  dengan berdiam diri menanam. Klik kanan dekat pohon menumbuhkan sulur baru
  dari sana — itu titik awal terpisah, prasyarat agar pemanjat nanti punya
  lawan.

Kondisi menang kode saat ini: `Structure.hancur()` — tidak ada KOLOM tersisa.
**[BUANG]** — diganti target tutupan per zona dalam tiga babak, lihat
`docs/06-desain-stealth-splitscreen.md` §6.

Dokumen `docs/01-konteks-game.md` dan `docs/02-logika-game.md` adalah rancangan
prototipe asli. Yang masih berlaku dari keduanya: palet warna, prinsip
float-untuk-simulasi, batas kecepatan belok (`MAX_TURN`), tigmotropisme, ekonomi
`min(Air, Cahaya)`, dan menembus beton (§7 Logika — belum pernah dibangun,
dijadwalkan TAHAP C). Tata letak level dan daftar konstanta di sana **sudah
tidak berlaku**. Pilar "satu tangan di mouse" (§7 Konteks) **dicabut** — kamera
independen menuntut papan ketik dan roda mouse.

`docs/04-status-proyek.md` sudah usang seluruhnya (masih era stealth lama,
masih menyebut `Warden.gd` dan `driver_name = GLES2`). Jangan dipakai sebagai
sumber kebenaran; CLAUDE.md dan `docs/06` yang berlaku.
