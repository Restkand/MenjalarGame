# PANDUAN ASET — Menjalar

Cara menggambar, menambah, dan memakai aset piksel. Dokumen ini melengkapi
`06-desain-stealth-splitscreen.md`; kalau ada bentrok soal mekanik, dokumen 06
yang menang. Palet dan aturan render tetap tunduk pada `01-konteks-game.md` §5.

> **CATATAN 11 Agustus 2026:** `09-arsitektur-render-baru.md` menggantikan
> pipeline dokumen ini. Aset tidak lagi dikirim sebagai data GDScript 8–16 px
> lewat `Aset.gd`; ia dipesan ke PixelLab pada 32–64 px sebagai PNG dan
> ditampilkan 1:1. Yang tetap berharga dari dokumen ini: aturan menggambar §4
> (arah cahaya, garis luar, bidang datar), pasangan bayangan §3, dan katalog §6
> sebagai daftar kebutuhan aset. Disimpan sebagai acuan nada dan kelengkapan.

Terakhir diperbarui: 11 Agustus 2026

---

## 1. Kenapa aset ini ada

`04-status-proyek.md` §10 mencatat "belum ada satu file PNG pun" dan rencana
memakai layanan sprite nanti. Aset ini menggantikan rencana itu: semuanya
digambar tangan di dalam palet yang sudah ada, dan dikirim sebagai **data
GDScript**, bukan tekstur.

Alasannya bukan selera. Menambah PNG berarti menambah `Sprite2D`, pengaturan
filter per tekstur, dan draw call — tiga hal yang `CLAUDE.md` jaga tetap
minimal. Data byte yang di-blit ke `Image` lewat `PixelCanvas.gd` masuk ke
pipeline yang sudah berjalan, tanpa satu pun node baru.

Konsekuensinya yang harus diterima: aset tidak bisa diputar, diskalakan, atau
diberi warna ulang saat runtime. Kalau butuh varian, gambar varian barunya.

---

## 2. Berkas

```
alat/
├── art.py       definisi seni piksel — SATU-SATUNYA sumber kebenaran
├── render.py    art.py → PNG per aset + pratinjau.png + Aset.gd
└── adegan.py    menyusun aset jadi potongan dunia untuk uji mata
res://scripts/
└── Aset.gd      keluaran; jangan disunting tangan
```

Jalankan `python3 render.py` setiap kali `art.py` berubah, lalu salin
`Aset.gd` ke `res://scripts/`. Butuh Pillow (`pip install pillow`).

**`art.py` adalah sumbernya, `Aset.gd` adalah keluarannya.** Menyunting
`Aset.gd` langsung akan hilang pada render berikutnya.

---

## 3. Palet dan huruf

13 warna, tidak bertambah. Setiap huruf di `art.py` memetakan ke satu indeks.

| Huruf | Nama | Hex | Dipakai untuk |
|---|---|---|---|
| `s` | LANGIT | `#8B96A3` | latar; jarang dipakai di aset |
| `G` | GEDUNG | `#5F6874` | badan fasad, celana, batu |
| `T` | TERANG | `#6E7784` | sisi kena cahaya, rompi |
| `J` | JENDELA | `#9AA4B0` | kaca, kulit, kilau air |
| `n` | TANAH | `#4A3728` | tanah kering |
| `m` | LEMBAP | `#5C4433` | tanah lembap, humus |
| `c` | BETON | `#7D7D75` | beton, ambang, helm |
| `p` | PIPA | `#4A6B7C` | air, akuifer, pipa |
| `a` | AKAR | `#A87B4E` | akar |
| `b` | BATANG | `#7A5C3A` | batang, dahan, sisi gelap daun |
| `d` | DAUN | `#5EC24A` | daun |
| `u` | UJUNG | `#B8E986` | ujung tumbuh, sisi terang daun |
| `o` | RETAK | `#3A3A36` | garis luar, retakan, bayangan, lubang |
| `.` | — | — | transparan (255 di `PackedByteArray`) |

### Pasangan bayangan

Tidak ada gradien, jadi kedalaman datang dari memilih tiga warna yang sudah
ada. Pakai pasangan ini, jangan mengarang sendiri:

| Bahan | Terang | Tengah | Gelap |
|---|---|---|---|
| Fasad, batu | `T` | `G` | `o` |
| Beton | `T` | `c` | `o` |
| Tanah | `m` | `n` | `o` |
| Air | `J` | `p` | `o` |
| Daun | `u` | `d` | `b` |
| Kayu | `a` | `b` | `o` |

`J` di atas beton atau tanah membaca sebagai kilau basah; jangan dipakai
sebagai warna terang biasa.

---

## 4. Aturan menggambar

1. **Cahaya datang dari kiri-atas.** Ikuti `SUN_DIR = normalize(0.35, -1.0)`
   di §3 Logika. Sisi terang di kiri dan atas, `o` di kanan dan bawah. Aset
   yang melanggar ini akan terlihat asing begitu diletakkan bersebelahan.
2. **Garis luar hanya untuk benda yang bergerak.** Aktor dan ikon HUD dibungkus
   `o` supaya siluetnya lepas dari fasad abu-abu. Tekstur dan fasad **tidak**
   pakai garis luar — kalau dipakai, jahitan antar-ubin akan terlihat.
3. **Bidang datar lebih baik daripada bercak.** Bercak yang tersebar merata
   terbaca sebagai derau, bukan bahan. Kumpulkan detail jadi beberapa gugus,
   dan sisakan area kosong yang lega. Ini kesalahan yang paling sering muncul.
4. **Detail terkecil 2 piksel.** Satu piksel sendirian akan hilang saat mata
   membaca dari jauh, kecuali ia memang kilau atau mata.
5. **Fasad harus tenang.** Tanaman satu-satunya yang jenuh warnanya; kalau
   dinding menarik perhatian, sulur kehilangan panggungnya.

---

## 5. Dua jenis aset

| Jenis | Arti | Aturan |
|---|---|---|
| `ubin` | tekstur berulang untuk isi terrain | tepi kiri harus menyambung ke tepi kanan, atas ke bawah; jangan taruh detail yang menonjol di tepi |
| `bebas` | benda tunggal | boleh transparan, boleh bentuk apa pun |

Cara memeriksa ubin: `pratinjau.png` menampilkan semua tekstur `ubin` sebanyak
3×3. Kalau ada garis atau pola diagonal yang muncul di gabungan itu tapi tidak
ada di satu ubin, jahitannya bermasalah.

---

## 6. Katalog

### 6.1 Fasad — pane atas

| Aset | Ukuran | Jenis | Catatan |
|---|---|---|---|
| `dinding_panel` | 8×8 | ubin | dinding dasar, panel beton |
| `dinding_bata` | 8×8 | ubin | untuk lantai dasar atau gedung tua |
| `dinding_noda` | 8×8 | ubin | noda air vertikal, taruh di bawah `ledge` |
| `jendela_padam` | 8×10 | bebas | `T_WINDOW` |
| `jendela_menyala` | 8×10 | bebas | pasangan `PointLight2D`, lihat `CLAUDE.md` |
| `pintu` | 8×16 | bebas | `T_DOOR` |
| `ledge` | 16×5 | bebas | permukaan merambat, penurun `vis` |
| `lapuk_1..3` | 4×4 | bebas | tahap erosi, dipetakan ke `lapuk / LAPUK_AMBANG` |
| `lapuk_4_gugur` | 4×4 | bebas | seluruhnya transparan — petak sudah gugur |
| `puing_petak` | 16×16 | ubin | isi `T_PUING` |

Petak lapuk sengaja 4×4 supaya sepadan dengan satuan erosi di §5 dokumen 06.
Empat tahap dipilih dengan `int(lapuk / LAPUK_AMBANG * 4)`.

### 6.2 Bawah tanah — pane bawah

| Aset | Ukuran | Enum terrain |
|---|---|---|
| `tanah_kering` | 16×16 | tanah biasa |
| `tanah_lembap` | 16×16 | `T_SOIL_WET` |
| `humus` | 16×16 | `T_HUMUS` |
| `batu` | 16×16 | `T_BATU` |
| `beton` | 16×16 | `T_CONCRETE` |
| `akuifer` | 16×16 | `T_AKUIFER` |
| `gorong` | 16×8 | `T_GORONG` — tinggi 8 supaya jadi koridor, bukan blok |
| `utilitas` | 16×8 | `T_UTILITAS` |

16×16 dipilih supaya pola tidak terbaca berulang di pane bawah yang tinggi
128 piksel. Kalau nanti terasa masih berulang, perbesar ke 32×32 — jangan
menambah bercak, itu hanya menambah derau.

### 6.3 Flora

| Aset | Ukuran | Catatan |
|---|---|---|
| `daun_besar` | 6×6 | daun utama di sulur dewasa |
| `daun_kecil` | 4×4 | sulur muda; ini yang paling sering dipakai |
| `daun_pasangan` | 10×6 | rumpun, hemat panggilan |
| `ujung_terang` / `ujung_redup` | 3×3 | dua bingkai denyut ujung, siklus ~0,6 detik (§10.5 Logika) |
| `tunas` | 5×5 | titik awal sulur baru dari pohon |
| `pohon` | 16×20 | `TreeSim.trees` |

**Sulur dan akar tidak punya sprite dan tidak boleh dibuatkan.** Keduanya
digambar sebagai lingkaran piksel per titik (§10.2 Logika) karena ketebalannya
mengikuti umur untai. Sprite akan mematikan sifat itu.

> Dicabut oleh 09 §4: sulur dan akar sekarang `Line2D` bertekstur dengan
> `width_curve`. Larangan ini lahir dari pipeline piksel yang sudah diganti.

### 6.4 Aktor

| Aset | Ukuran | Catatan |
|---|---|---|
| `regu_diam` / `regu_jalan` | 10×16 | dua bingkai; ganti tiap ~0,25 detik saat berjalan |
| `regu_kerja` | 10×16 | dipakai saat memangkas di lokasi |
| `pemanjat_naik` / `pemanjat_gantung` | 12×16 | pemanjat lebih lebar karena lengannya terangkat |

Wajah dan tangan memakai `J`, bukan warna kulit. Ini disengaja: kota digambar
tanpa kehidupan, dan menambah warna kulit berarti menambah warna jenuh kedua
ke layar.

### 6.5 HUD

`ikon_air`, `ikon_cahaya`, `ikon_energi`, `ikon_perhatian`, `ikon_tutupan`,
`ikon_malam`, `ikon_kalender`, `ikon_regu` — semua 8×8.

Ikon HUD digambar di `CanvasLayer` HUD, bukan di lapis dunia, jadi ia tidak
ikut gelap saat malam (`CanvasModulate` hanya menyentuh layer 0). Untuk penanda
leher botol di §6 Konteks, sorot dengan menaikkan kecerahan latar ikonnya,
bukan warna ikonnya — palet tidak punya warna aksen.

---

## 7. Menambah aset baru

Empat langkah, tidak ada yang kelima.

1. Buka `art.py`, cari kelompok yang cocok (`FASAD`, `TANAH`, `FLORA`,
   `AKTOR`, `HUD`).
2. Tambahkan entri: nama, jenis (`"ubin"` atau `"bebas"`), lalu daftar baris
   string. Baris yang kependekan otomatis dipadatkan dengan transparan, jadi
   salah hitung tidak akan membuat skrip gagal — tapi hasilnya akan terpotong.
3. Jalankan `python3 render.py`, buka `pratinjau.png`, periksa dengan mata.
4. Salin `Aset.gd` ke `res://scripts/`, lalu panggil dari `PixelCanvas.gd`.

Contoh entri:

```python
"jendela_pecah": ("bebas", [
    "cccccccc",
    "TTTTTTTT",
    "ToJoTooT",
    "TooJTooT",
    "ToooTJoT",
    "ToooToJT",
    "ToooTooT",
    "TTTTTTTT",
    "cccccccc",
    "oooooooo",
]),
```

Setelah menambah beberapa aset, jalankan `python3 adegan.py` dan lihat
`adegan.png`. Aset yang bagus sendirian bisa saja gagal ketika bersebelahan
dengan yang lain — kontrasnya terlalu tinggi, atau justru tenggelam.

---

## 8. Memakainya di Godot

Semua penulisan piksel tetap hanya di `PixelCanvas.gd`. `Config.gd` tidak
boleh menyentuh ini — dia hanya `var` dan `const`, nol fungsi.

```gdscript
func blit_aset(img: Image, a: Dictionary, ox: int, oy: int) -> void:
	var w: int = a["w"]
	var px: PackedByteArray = a["px"]
	for i in px.size():
		var v := px[i]
		if v == 255:
			continue
		var x := ox + i % w
		var y := oy + i / w
		if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
			continue
		img.set_pixel(x, y, Aset.PALET[v])

func blit_ubin(img: Image, a: Dictionary, x0: int, y0: int, x1: int, y1: int) -> void:
	var w: int = a["w"]
	var h: int = a["h"]
	var px: PackedByteArray = a["px"]
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var v := px[posmod(y, h) * w + posmod(x, w)]
			if v != 255:
				img.set_pixel(x, y, Aset.PALET[v])
```

Aturan pemakaian:

- Fasad, tekstur tanah, jendela, pintu, ledge → lapis **world**, sekali saat
  load. Jangan pernah tiap frame.
- Daun, pohon, tunas → lapis **tree**, saat daun atau pohon lahir.
- Ujung berdenyut, aktor, ikon pratinjau → lapis **overlay**, dibersihkan tiap
  frame.
- Setelah erosi menggugurkan petak, blit ulang hanya kotak yang berubah dan
  panggil `texture.update(img)` — bukan `ImageTexture` baru.

Menggambar tekstur terrain dari `grid` cukup satu lintasan: baca enum tiap
piksel, ambil aset yang sesuai, tulis warnanya lewat `posmod` seperti di
`blit_ubin`. Tidak perlu tabel per petak.

---

## 9. Yang jangan dilakukan

- **Jangan menambah warna.** Kalau sebuah bentuk hanya terbaca dengan warna
  ke-14, bentuknya yang salah.
- **Jangan memakai gradien atau anti-alias.** Termasuk saat menggambar di
  editor luar lalu menyalinnya masuk.
- **Jangan membuat sprite untuk sulur, akar, atau kerucut pandang.** Dua yang
  pertama prosedural; yang ketiga sudah dicabut dari desain.
- **Jangan mengekspor PNG ke `res://`** kecuali Anda memang sedang mengganti
  seluruh pipeline render. Aset ini dipakai lewat `Aset.gd`.
- **Jangan menyunting `Aset.gd`.** Sunting `art.py`, render ulang.
- **Jangan menskalakan aset dengan angka pecahan.** Alasannya sama dengan
  larangan zoom pecahan di §2.2 dokumen 06.

---

## 10. Yang belum beres

Jujur dicatat supaya tidak terlupa:

- `batu` masih terbaca seperti pasangan bata daripada bongkahan alami. Perlu
  digambar ulang dengan poligon tak beraturan dan retakan yang tidak lurus.
- Kepala `pemanjat_*` lebih kecil daripada kepala `regu_*` karena lengan
  terangkat memakan lebar kanvas. Terlihat kalau keduanya bersebelahan.
- Belum ada aset untuk: sudut dan tepi fasad, penanda zona perawatan,
  bayangan aktor di tanah, dan varian pohon kedua.
- `gorong` dan `utilitas` tinggi 8 sementara tekstur tanah lain 16. Aman
  karena keduanya koridor, tapi jangan diubin vertikal berlapis-lapis.
- Belum satu pun aset diuji di dalam Godot. Semua penilaian sejauh ini dari
  `pratinjau.png` dan `adegan.png`.

---

## 11. Urutan kerja yang disarankan

Aset tidak mendesak — TAHAP A (kamera dan split screen) di dokumen 06 belum
dimulai, dan itu risiko teknis terbesarnya. Aset ini paling masuk akal
dipasang saat **TAHAP B**, ketika `Structure.gd` menyusut jadi `Erosi.gd` dan
petak lapuk butuh sesuatu untuk digambar.

Kalau ingin memasangnya lebih awal, pasang berurutan dan verifikasi tiap
langkah di Godot: tekstur terrain dulu (paling murah, langsung terlihat), lalu
jendela dan pintu, lalu daun dan pohon, lalu aktor. Ikon HUD terakhir — ia
paling tidak berisiko dan paling mudah ditunda.
