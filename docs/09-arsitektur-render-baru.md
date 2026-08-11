# ARSITEKTUR RENDER BARU — Menjalar

Menggantikan lapis render lama. **Tidak ada satu pun aturan main yang berubah** —
dokumen `06-desain-stealth-splitscreen.md` tetap berlaku penuh. Yang dibongkar
hanya cara menggambar.

Terakhir diperbarui: 11 Agustus 2026

---

## 1. Keputusan

Selama ini resolusi simulasi dan resolusi tampilan adalah benda yang sama.
Itu sumber hampir semua kesulitan teknis proyek ini: bake cahaya mahal, aset
terkurung di 16 piksel, HUD butuh font buatan sendiri, dan setiap piksel harus
ditulis tangan lewat `Image.set_pixel`.

**Keduanya dipisahkan.**

- **Simulasi** tetap berjalan di ruang 480×320 satuan, float, persis seperti
  sekarang. `Strand.gd`, `TreeSim.gd`, ekonomi `min(Air, Cahaya)`, kalender,
  perhatian — tidak berubah sama sekali.
- **Tampilan** memakai node Godot biasa: `Line2D`, `TileMapLayer`, `Sprite2D`,
  `PointLight2D`, `Control`. Aset digambar pada ukuran akhir dan ditampilkan
  1:1, jadi tidak ada lagi urusan penskalaan bilangan bulat.

Dua sasaran yang mendorong keputusan ini: aset harus bisa dipesan lewat
PixelLab (butuh 48–64 piksel, bukan 16), dan tampilannya harus berhenti
terlihat seperti prototipe.

---

## 2. Angka

```
Ruang simulasi     480 x 320 satuan      (tidak berubah dari rencana TAHAP A)
  zona udara       y   0 .. 191
  GARIS TANAH      y = 192
  zona tanah       y 192 .. 319

PPU                4 piksel per satuan
Dunia dalam piksel 1920 x 1280

Petak TileMap      32 px = 8 satuan  ->  grid petak 60 x 40
Jendela            1920 x 1080
  pane ATAS        1920 x 720   (melihat 480 x 180 satuan)
  pane BAWAH       1920 x 360   (melihat 480 x  90 satuan)
```

Satu konstanta baru, `Config.PPU = 4`, dan satu aturan: **simulasi tidak pernah
tahu tentang piksel.** Konversi hanya terjadi di lapis tampilan, dengan
mengalikan posisi satuan dengan `PPU`.

Zoom sekarang bebas — `Camera2D.zoom` boleh 0.75, 1.0, atau 1.5. Larangan zoom
pecahan hanya berlaku saat piksel diperbesar; di sini aset ditampilkan pada
ukuran aslinya.

### 2.1 Ukuran aset

| Aset | Piksel | Satuan simulasi |
|---|---|---|
| petak terrain & fasad | 32×32 | 8×8 |
| jendela | 32×48 | 8×12 |
| pintu | 32×64 | 8×16 |
| daun | 16–24 | 4–6 |
| tekstur batang untuk `Line2D` | 32×8, bisa diubin | lebar 8–20 px |
| pohon | 96×128 | 24×32 |
| regu & pemanjat | 48×64 | 12×16 |
| ikon HUD | 32×32 | — |

---

## 3. Struktur node

```
main.tscn
└── Node2D (main.gd)                  orkestrator; SATU-SATUNYA pembaca input
    ├── SubViewportContainer 1920x720          pane ATAS
    │   └── SubViewport
    │       ├── Camera2D
    │       ├── TileMapLayer  fasad
    │       ├── Node2D        PuingView      _draw batch
    │       ├── Node2D        SulurRoot      berisi Line2D per untai
    │       ├── Node2D        DaunView       _draw batch
    │       ├── Node2D        AktorView      Sprite2D regu & pemanjat
    │       ├── CanvasModulate
    │       └── PointLight2D  x N            jendela menyala
    ├── SubViewportContainer 1920x360, y=720  pane BAWAH
    │   └── SubViewport
    │       ├── Camera2D
    │       ├── TileMapLayer  tanah
    │       └── Node2D        AkarRoot       Line2D per akar
    ├── Hud          CanvasLayer 20          Control biasa, font sungguhan
    └── TuningPanel  CanvasLayer 10
```

`PixelCanvas.gd` dihapus seluruhnya. Tidak ada lagi `Image`, `ImageTexture`,
`set_pixel`, atau `texture.update()` di mana pun.

Kedua pane tidak lagi berbagi tekstur seperti rancangan lama; masing-masing
melihat cabang node yang berbeda. Ini justru lebih murah, karena tiap pane hanya
menggambar apa yang memang ada di zonanya.

---

## 4. Menggambar sulur dan akar

Inti perubahannya. `Strand.points` sudah berisi rantai titik float — persis
yang dibutuhkan `Line2D`.

```gdscript
# scripts/render/SulurView.gd
extends Line2D

var strand: Strand

func _ready() -> void:
	texture = preload("res://aset/sulur_batang.png")
	texture_mode = Line2D.LINE_TEXTURE_TILE
	joint_mode = Line2D.LINE_JOINT_ROUND
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND
	width_curve = preload("res://aset/kurva_tebal.tres")  # tebal di pangkal, tipis di ujung

func _process(_delta: float) -> void:
	if strand.points.size() < 2:
		return
	var pts := PackedVector2Array()
	pts.resize(strand.points.size())
	for i in strand.points.size():
		pts[i] = strand.points[i] * Config.PPU
	points = pts
	width = strand.tebal_pangkal * Config.PPU
```

`width_curve` menggantikan rumus ketebalan di §10.3 Logika: batang menebal
seiring umur, ujung tetap tipis, dan sekarang gratis karena Godot yang
menghitungnya.

Batasi jumlah titik: satu titik tiap 2–3 satuan sudah cukup halus untuk
`Line2D` (dulu tiap 1 piksel), jadi jumlah titik justru **turun**.

Untuk akar, ganti tekstur dan warnanya saja — tanpa daun.

---

## 5. Daun, puing, dan aktor

**Daun.** Jangan satu `Sprite2D` per daun; ratusan node akan menggigit. Satu
`Node2D` menggambar semuanya:

```gdscript
# scripts/render/DaunView.gd
extends Node2D

var atlas: Texture2D = preload("res://aset/daun_atlas.png")
var daun: Array = []          # {pos: Vector2, varian: int, skala: float}

func _draw() -> void:
	for d in daun:
		var src := Rect2(d.varian * 24, 0, 24, 24)
		var uk := 24.0 * d.skala
		draw_texture_rect_region(
			atlas, Rect2(d.pos * Config.PPU - Vector2(uk, uk) * 0.5,
			Vector2(uk, uk)), src)
```

Panggil `queue_redraw()` hanya saat ada daun lahir atau gugur, bukan tiap frame.
`_draw()` yang dulu dilarang justru murah di sini: yang digambar tekstur, bukan
piksel satuan.

**Puing.** Selagi jatuh, gambar lewat batch yang sama. Begitu diam, tulis ke
`TileMapLayer` sebagai petak `PUING` dan hapus dari daftar jatuh — sama seperti
alur `Structure.gd` yang sudah berjalan, hanya keluarannya petak, bukan piksel.

**Aktor.** `Sprite2D` biasa dengan `AnimatedSprite2D` atau `SpriteFrames`.
Jumlahnya kecil (beberapa regu, beberapa pemanjat), jadi node per aktor aman.

---

## 6. Cahaya, malam, dan peta vis

Batasan "tanpa shader" **dicabut**. `CanvasModulate` untuk malam,
`PointLight2D` untuk jendela menyala, dan falloff boleh halus sekarang —
aturan falloff bertangga di `CLAUDE.md` hanya ada untuk menjaga estetika piksel
keras, dan estetika itu berubah.

Batasan "tanpa physics engine" **tetap dipertahankan**. `WorldMap.grid` per
satuan sudah bekerja untuk tabrakan, tigmotropisme, dan deteksi air. Menukarnya
dengan `Area2D` hanya menambah biaya tanpa menambah kemampuan.

**Peta `light` dan `vis` pindah ke grid petak 60×40** — 2.400 sel, bukan
153.600. Masalah "bake terlalu lambat untuk satu frame" hilang sendiri; sekarang
ia selesai dalam hitungan milidetik dan boleh dihitung ulang kapan saja, bahkan
setiap kali sepetak fasad gugur. Saat membaca nilainya untuk satu titik
simulasi, ambil sel petaknya; kalau terasa kasar, interpolasi bilinear antar
empat sel tetangga.

---

## 7. HUD

`Control` biasa dengan font sungguhan. Font 3×5 buatan sendiri tidak lagi
dibutuhkan — masalah "font bawaan Godot 4 terlalu besar" muncul karena jendela
960×640; pada 1920×1080 ia justru pas.

Yang **tetap berlaku** dari `08-arah-visual.md`: anatomi HUD (dua pita, tidak
ada yang mengambang di tengah), aturan penanda leher botol, kalender tiga baris
yang selalu terlihat, bar zona, dan larangan teks bertema. Semua itu soal
informasi, bukan soal piksel.

---

## 8. Memesan aset ke PixelLab

### 8.1 Daftar pesanan

Urutkan seperti ini; tiap kelompok bisa dikerjakan satu sesi.

| Kelompok | Isi | Ukuran |
|---|---|---|
| 1. Sulur | tekstur batang bisa diubin, 4 varian daun, 2 tahap layu, tunas, ujung tumbuh 2 bingkai | 32×8 dan 16–24 |
| 2. Fasad | dinding beton, bata, bernoda, tepi, sudut, ledge 2 varian | 32×32 |
| 3. Bukaan | jendela padam, jendela menyala, pintu | 32×48 / 32×64 |
| 4. Bawah tanah | kering, lembap, humus, batu, beton, akuifer, gorong, utilitas, puing | 32×32 |
| 5. Aktor | regu: diam, jalan 4 bingkai, kerja 4 bingkai; pemanjat: naik 4, gantung 2 | 48×64 |
| 6. Pohon | 2 varian | 96×128 |
| 7. HUD & efek | 8 ikon, retak 4 tahap, debu 4 bingkai | 32×32 |

Kelompok 1 dulu, karena sulur adalah satu-satunya hal yang selalu terlihat.
Kalau tekstur batang dan daun sudah benar, sisanya mengikuti.

### 8.2 Kerangka prompt

Sertakan empat hal ini di setiap prompt, dan gunakan hasil kelompok 1 sebagai
gambar acuan untuk kelompok berikutnya:

```
[objek], side view, 32x32 pixel art tile, seamless tileable,
light source from upper-left, single dark outline,
muted desaturated grey-blue city palette anchored to
#5F6874 #6E7784 #9AA4B0 #7D7D75 #3A3A36,
plants use the only saturated color #5EC24A #B8E986,
no gradients on flat surfaces, clean readable shapes
```

Palet 13 warna sekarang jadi **jangkar, bukan penjara**: gradasi di antaranya
boleh, warna baru untuk detail kecil boleh. Yang tidak boleh dilanggar cuma satu
kalimat, dan kalimat inilah identitas game Anda:

> Kota tetap abu-abu dan tidak jenuh. Tanaman satu-satunya yang berwarna.

### 8.3 Impor ke Godot

Aset ditampilkan 1:1, jadi pengaturannya sederhana: **Filter mati, Mipmaps
mati** (preset 2D Pixel), dan `TileMapLayer` dengan ukuran petak 32.
`texture_filter = TEXTURE_FILTER_NEAREST` tetap dipasang di node yang menskalakan
apa pun.

Sisihkan waktu membersihkan tangan di Aseprite. PixelLab bagus pada 48 piksel,
tapi ia tidak tahu petak mana yang harus menyambung ke petak sebelahnya —
periksa jahitan tiap tekstur dengan menempelkannya 3×3 sebelum dipakai.

---

## 9. Urutan kerja

Satu tahap per sesi, commit tiap tahap yang terverifikasi jalan. Gameplay lama
harus tetap berjalan di setiap tahap.

| Tahap | Isi | Verifikasi |
|---|---|---|
| **R1** | Tambah `Config.PPU`. Ganti render sulur dan akar jadi `Line2D` dengan tekstur sementara. Sisanya masih `PixelCanvas` | sulur tumbuh dan melengkung seperti biasa, tapi sudah halus dan bertekstur |
| **R2** | `TileMapLayer` untuk fasad dan tanah. Hapus penulisan piksel lapis world | peta terlihat benar, tabrakan dan tigmotropisme tidak berubah |
| **R3** | `DaunView` dan `PuingView` batch. Hapus lapis tree dan overlay | daun muncul di sepanjang sulur; puing jatuh lalu jadi petak |
| **R4** | Pindahkan `light` dan `vis` ke grid petak. Hapus `PixelCanvas.gd` | bake selesai seketika; peta risiko `V` masih masuk akal |
| **R5** | Kamera dua pane pada angka baru, scroll dan zoom | klik mendarat di titik simulasi yang benar di kedua pane |
| **R6** | HUD `Control`, aktor `AnimatedSprite2D`, `PointLight2D` malam | semua keadaan di `keadaan_layar.png` bisa dicapai |

R1 sengaja didahulukan karena ia yang paling cepat memberi tahu apakah arah ini
benar. Kalau sulur bertekstur sudah terlihat jauh lebih baik daripada sekarang,
lanjutkan. Kalau tidak, hentikan sebelum menyentuh yang lain — `git checkout`
satu file jauh lebih murah daripada membatalkan enam tahap.

---

## 10. Yang tetap dan yang dibuang

**Tetap berlaku penuh:** seluruh `06-desain-stealth-splitscreen.md`,
`Strand.gd`, `TreeSim.gd`, `Cycle.gd`, `Crew.gd`, `Climber.gd`, tabrakan grid,
ekonomi `min(Air, Cahaya)`, aturan input hanya di `main.gd`, `Config.gd` nol
fungsi, dan anatomi HUD di `08-arah-visual.md`.

**Dibuang:** `PixelCanvas.gd`, aturan render berbasis `Image` di `CLAUDE.md`,
larangan shader, larangan Light2D falloff halus, larangan zoom pecahan, font
3×5, `Aset.gd`, dan seluruh 40 aset piksel 8–16 yang sudah dibuat. Papan arah
visual (`moodboard.png`, `palet.png`, `wireframe.png`, `keadaan_layar.png`)
tetap berguna sebagai acuan nada dan tata letak, bukan sebagai acuan resolusi.

**Berubah bentuk:** "draw call minimal" sekarang berarti "jumlah node minimal".
Bahayanya bukan lagi piksel, melainkan ribuan `Sprite2D`. Karena itu daun dan
puing digambar batch.

---

## 11. Risiko

Batasan teknis yang lama diam-diam menjaga konsistensi: 13 warna dan 16 piksel
membuat semua aset otomatis serasi. Batasan itu hilang, dan penggantinya harus
disiplin manusia — satu arah cahaya, satu tebal garis luar, satu ukuran daun,
satu keluarga warna.

Ini risiko yang lebih sulit ditangani daripada bake cahaya yang lambat, karena
ia baru terlihat setelah 30 aset jadi dan semuanya terasa sedikit berbeda.
Penangkalnya: selalu pakai gambar acuan di PixelLab, dan letakkan tiap aset baru
di samping aset kelompok 1 sebelum menerimanya.

Risiko kedua: ini pergeseran arah kelima. Yang membedakannya dari empat
sebelumnya adalah ia **tidak menyentuh satu pun aturan main** — kalau berhenti
di tengah, game Anda tetap bisa dimainkan seperti sekarang, hanya dengan
sebagian tampilan baru.
