# Menjalar — konteks proyek

Game 2D pixel art. Pemain adalah tanaman merambat yang tumbuh di fasad gedung
kota. Simulasi berjalan di 240×160 piksel, ditampilkan 960×640.

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
- Tiga lapis Image, masing-masing satu Sprite: `world` (statis, sekali saat
  load), `tree` (akumulatif, hanya titik terbaru yang digambar ulang), dan
  `overlay` (dibersihkan tiap frame).
- Skala 4× lewat **`Sprite.scale`**, bukan stretch viewport — supaya UI tetap
  tajam sementara game tetap pixel art keras.

## Aturan simulasi

- **Simulasi memakai float; pembulatan ke integer hanya saat render.**
  Menyimpan posisi sebagai integer membuat pertumbuhan tersendat dan bersudut.
- Ukuran dunia: `Config.W = 240`, `Config.H = 160`, `Config.SCALE = 4`.
- Konversi mouse: `get_viewport().get_mouse_position() / float(Config.SCALE)`.

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
    ├── Cycle.gd           jam siklus siang-malam (dulu Warden.gd)
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

---

## Arah saat ini

**Menjalar adalah game pembongkaran.** Inspirasinya Rampage, dibalut isu
lingkungan: pemain adalah alam yang merebut kembali kota, dan regu perawatan
gedung melawan.

**Sistem stealth sudah DIHAPUS seluruhnya** — heat per-sulur, kerucut pandang,
kecurigaan, pemangkasan fajar. Stealth menuntut pemain lemah dan tersembunyi,
pembongkaran menuntut sebaliknya; keduanya saling menarik ke arah berlawanan.
Jangan hidupkan lagi. `Warden.gd` sudah dihapus, sisanya jadi `Cycle.gd` yang
hanya memegang jam siang-malam.

Antagonis baru yang sedang dibangun (menggantikan TAHAP 7 di dokumen):

- Regu darat menggali akar di sekitar kaki gedung — tepat di titik yang paling
  ingin dikuasai pemain untuk menggerogoti kolom.
- Pemanjat **menaiki sulur pemain sendiri**. Jalur musuh adalah bangunan
  pemain, jadi tiap keputusan menumbuhkan juga keputusan soal mobilitas dia.
  Ini yang membuatnya tidak pernah jadi pola hafalan.
- Pemain bisa memutus sulurnya sendiri untuk menjatuhkan pemanjat, dengan
  harga pertumbuhan di atas potongan itu.
- Jumlah regu bertambah seiring `STRUKTUR` turun, jadi tekanan memuncak justru
  saat pemain hampir menang.

Peta `vis` tetap dipakai, tapi maknanya bergeser dari "pemain tak terlihat"
jadi "regu menemukannya lebih lambat". Bayangan tetap berguna tanpa jadi
stealth.

Riwayat: proyek bergeser dari stealth-coverage ke pembongkaran struktural.

Konsep lama: sulur menutupi 55% fasad tanpa ketahuan tukang kebun.
Konsep baru: gedung punya rangka (kolom, balok, sambungan) dengan aliran beban.
Tanaman melemahkan sambungan sampai struktur runtuh berantai. Puing yang jatuh
jadi tanah baru untuk dipanjat.

Urutan kerja bertahap ada di **`docs/05-prompt-pivot-pembongkaran.md`**
(TAHAP 0 sampai TAHAP 8). Kerjakan **satu tahap per sesi**, commit tiap tahap
yang sudah terverifikasi jalan.

Status pivot: **TAHAP 0–6 selesai. Berikutnya: pohon dari sulur yang runtuh
bersama gedung, lalu pemanjat, lalu banyak gedung + kamera geser.**

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

Sistem yang sudah ada dari pivot:

- `WorldMap.members` / `.joints` — rangka 4 kolom × 5 balok, disimpan sebagai
  31 ruas antar-joint. `solve_order` sudah topologis atas-ke-bawah.
- `WorldMap.kapasitas(m)` — satu-satunya sumber kebenaran kapasitas:
  `integritas_member * min(integritas kedua joint) * KAPASITAS_MAX`.
- `WorldMap.panels` — 12 panel dinding di antara rangka. **Inilah massa gedung
  yang sebenarnya**; member cuma garis selebar 3 px. Panel jatuh saat
  `PANEL_AMBANG` dari 4 member yang mengurungnya sudah gagal.
- `Structure.gd` — solve beban, keruntuhan berantai per gelombang, puing,
  debu, panel, dan pelemahan oleh tanaman.
- Sulur menyerang joint, akar menyerang ruas kolom paling bawah.
- `WorldMap.vine_ok()` — predikat pijakan sulur, mengizinkan rentangan
  `VINE_JEMBATAN` px melewati celah sempit.
- `T_PUING` — puing yang mengendap ditulis ke `grid`, bukan cuma ke `image`,
  jadi ia terrain sungguhan: bisa ditumbuhi sulur dan ikut melempar bayangan.
  Peta cahaya dipanggang ulang sekali setelah puing diam (`PUING_TENANG`), dan
  hanya dari baris puncak tumpukan ke bawah — sinar datang dari atas-kiri jadi
  puing hanya membayangi yang di bawahnya. Hemat ~66% dibanding panggang penuh.
- `Crew.gd` — regu perawatan, antagonis darat. Jangkauannya hanya pita di
  sekitar garis tanah; sulur tinggi belum ada yang mengancam. Jawaban pemain
  terhadap mereka adalah **menimbun mereka dengan puing yang jatuh**
  (`CREW_PINGSAN`) — sengaja sementara, karena regu yang bisa dihabisi berarti
  peta bisa dibersihkan lalu pemain bekerja tanpa lawan sama sekali.

- `TreeSim.trees` — sulur yang bertahan di atas puing berakar jadi **pohon**.
  Satu-satunya hal permanen: gedung runtuh, sulur dipangkas regu, pohon
  tinggal. Pembagian peran yang harus dijaga — **pohon = ekonomi, sulur dan
  akar = senjata.** Pohon menyumbang ke air DAN cahaya (menaikkan lantai
  `min()`), tapi tidak bisa melemahkan apa pun, jadi pemain tidak bisa menang
  dengan berdiam diri menanam. Klik kanan dekat pohon menumbuhkan sulur baru
  dari sana — itu titik awal terpisah, prasyarat agar pemanjat nanti punya
  lawan.

Kondisi menang: `Structure.hancur()` — tidak ada KOLOM tersisa. Sengaja bukan
"semua member mati", karena balok level dasar berdiri di pondasi sehingga tidak
pernah gagal karena kehilangan tumpuan, dan tidak terjangkau akar maupun sulur
setelah fasadnya lenyap. Syarat coverage 55% sudah dihapus seluruhnya.

Dokumen `docs/01-konteks-game.md` dan `docs/02-logika-game.md` adalah rancangan
prototipe asli. Yang masih berlaku dari keduanya: palet warna, teknik render
240×160 skala 4×, prinsip float-untuk-simulasi, batas kecepatan belok
(`MAX_TURN`), dan ekonomi `min(Air, Cahaya)`. Tata letak level dan daftar
konstanta di sana **sudah tidak berlaku** — lihat `docs/04-status-proyek.md` §2.
