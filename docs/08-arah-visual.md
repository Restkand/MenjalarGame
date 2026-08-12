# ARAH VISUAL & ANTARMUKA — Menjalar

Papan acuan untuk mendesain, bukan spesifikasi mekanik. Untuk aturan menggambar
aset lihat `07-panduan-aset.md`; untuk mekanik lihat
`06-desain-stealth-splitscreen.md`.

> **CATATAN 11 Agustus 2026:** `09-arsitektur-render-baru.md` mencabut sebagian
> aturan piksel di dokumen ini (zoom bulat, falloff bertangga, font 3×5,
> larangan gradien mutlak). Yang tetap berlaku penuh dari dokumen ini adalah
> **anatomi HUD dan aturan informasinya** (§3), aturan warna antarmuka (§8.3),
> dan rasa yang dikejar (§2). Kalau bentrok soal render, 09 yang menang.

Terakhir diperbarui: 11 Agustus 2026

---

## 1. Empat papan

| Berkas | Isi | Dipakai saat |
|---|---|---|
| `moodboard.png` | rasa, palet, adegan utuh, contoh benar/salah | memutuskan apakah sesuatu "terasa Menjalar" |
| `palet.png` | 13 warna, tangga bayangan, uji kontras | saat menggambar aset baru |
| `wireframe.png` | tata letak 960×640, dua pane, letak HUD, tingkat zoom | saat menyusun scene di Godot |
| `hud_mockup.png` | HUD sungguhan digambar di 240×160, ditampilkan 4× | saat membangun `Hud.gd` |

Semua dihasilkan ulang dengan `python3 papan.py` dan `python3 hud.py`.

---

## 2. Rasa yang dikejar

Kata kuncinya tidak berubah dari §4 Konteks: **merambat, sabar, organik,
sedikit di luar kendali** — sekarang ditambah **tenang** dan **terencana**
sejak arah bergeser ke stealth terjadwal dengan patokan Terra Nil.

Yang membedakannya dari game piksel lain bukan gaya gambarnya, tapi
distribusinya: **kota memenuhi layar tapi tidak menuntut perhatian; tanaman
kecil tapi memenangkan mata.** Kalau sebuah tekstur fasad baru membuat Anda
memperhatikannya lebih dulu daripada sulur, tekstur itu salah, walaupun bagus.

Kota digambar tanpa kebencian. Tidak ada jendela retak dramatis, tidak ada
grafiti, tidak ada langit merah. Hanya beton yang dirawat rapi dan tidak hidup.

---

## 3. Anatomi HUD

Dua pita, tidak ada yang mengambang di tengah. Kanvas ada di antaranya, dan
tidak boleh ada satu pun elemen HUD di dalam wilayah kanvas.

### 3.1 Pita atas — 15 px dunia

Kiri ke kanan: ikon air + angka, ikon cahaya + angka, ikon energi + bar, ikon
perhatian + bar, lalu kalender di ujung kanan.

**Aturan leher botol.** Antara Air dan Cahaya, yang lebih kecil diberi bingkai
`UJUNG` dan angkanya memakai `UJUNG`; yang lain memakai `JENDELA`. Ini satu-
satunya cara aturan `min()` diajarkan — §6 Konteks melarang tutorial teks, dan
larangan itu masih berlaku.

**Bar perhatian memakai `JENDELA`, bukan merah.** Palet tidak punya warna
peringatan, dan itu disengaja: perhatian naik pelan dan diumumkan lewat
kalender, jadi ia tidak butuh warna panik. Kalau butuh penegasan, pakai bingkai
`UJUNG` seperti penanda leher botol.

### 3.2 Kalender — selalu terlihat

Tiga baris di kanan atas, tidak pernah disembunyikan:

```
HARI 6   MALAM 40%
INSPEKSI 1 HARI
RAWAT H9 TIMUR
```

Baris ketiga memakai `UJUNG` begitu perawatan dijadwalkan, dan hilang kalau
tidak ada jadwal. Inilah seluruh sistem peringatan game ini — pilar kedua di
§1 dokumen 06 menuntut ancaman diumumkan sebelum tiba, dan tiga baris ini yang
memenuhinya.

### 3.3 Pita bawah — 14 px dunia

Empat bar tutupan per zona (BL / BA / TL / TA). Zona yang dijadwalkan dirawat
diberi bingkai `UJUNG`. Target per zona, bukan persentase global — alasannya di
§6 dokumen 06.

### 3.4 Yang tidak boleh ada di HUD

Nol teks bertema, nol narasi, nol tips, nol tombol. Tidak ada angka persen
energi (barnya sudah cukup), tidak ada nama zona panjang, tidak ada ikon yang
tidak memetakan ke satu angka simulasi.

---

## 4. Huruf

Font bawaan Godot 4 lebih besar daripada Godot 3 dan sudah pernah memotong
panel tuning (`CLAUDE.md`, tabel "jangan diulang"). Untuk HUD, jangan pakai itu.

`alat/font3x5.py` berisi font piksel lebar variabel: kebanyakan glif 3×5, dan
`M`, `N`, `W` 4×5 karena tiga huruf itu tidak terbaca di lebar 3. Spasi antar
huruf 1 px, tinggi baris 7 px.

Dua cara memakainya di Godot:

1. **Blit langsung** ke lapis overlay lewat `PixelCanvas.gd`, sama seperti aset
   lain. Paling konsisten, dan teksnya ikut skala dunia.
2. **Ekspor jadi `BitmapFont`** kalau HUD dibangun dari node `Control`. Lebih
   repot, tapi memberi tata letak otomatis.

Semua teks HUD huruf kapital. Font ini tidak punya huruf kecil, dan itu
disengaja — huruf kecil pada 5 px tinggi tidak terbaca.

> Dicabut oleh 09 §7: HUD baru memakai font sungguhan pada jendela 1920×1080.
> Bagian ini disimpan sebagai riwayat.

---

## 5. Cahaya malam

`CanvasModulate` meredupkan layer 0; HUD di CanvasLayer 20 dan panel tuning di
10, jadi keduanya tetap terang tanpa pengaturan tambahan.

Jendela yang menyala memakai `PointLight2D` dengan falloff **bertangga**
(`LAMPU_TINGKAT`), bukan gradien halus. Nilai yang sudah disetel dari tangkapan
layar: `LAMPU_RADIUS 14`, `LAMPU_ENERGI 0.55`. Pada 30/1.1 jendelanya putih
terbakar dan lingkaran cahayanya saling menutupi seluruh fasad.

Aset `jendela_menyala` dan `jendela_padam` harus tetap bisa dibedakan **tanpa**
lampu menyala, karena `vis` dihitung dari peta yang di-bake, bukan dari lampu.

---

## 6. Larangan visual

Sudah tersebar di beberapa dokumen; dikumpulkan di sini supaya bisa dicek
sekaligus.

- Tidak ada gradien, bayangan lembut, atau anti-alias.
- Tidak ada warna ke-14. Termasuk merah untuk peringatan.
- Zoom dan skala hanya bilangan bulat.
- Tidak ada teks bertema, narasi, atau tips di layar.
- Tidak ada elemen HUD yang mengambang di atas kanvas.
- `texture_filter = TEXTURE_FILTER_NEAREST` di setiap Sprite2D, plus
  `default_texture_filter=0` di `project.godot`. Dua lapis, bukan satu.

> Dicabut sebagian oleh 09: gradien di dalam jangkar palet boleh, zoom bebas,
> falloff halus boleh. Yang bertahan: larangan teks bertema, larangan elemen
> HUD mengambang di kanvas, dan "kota abu-abu, tanaman satu-satunya berwarna".

---

## 7. Yang belum diputuskan

- **Warna sorot kedua.** Sekarang `UJUNG` dipakai untuk dua hal berbeda: ujung
  tumbuh di kanvas dan sorotan di HUD. Belum jelas apakah itu membingungkan
  saat keduanya terlihat bersamaan.
- **Transisi malam.** Belum ada rancangan bagaimana `CanvasModulate` berubah —
  mendadak, atau bertahap dalam beberapa detik.
- **Penanda pane aktif.** Kursor menentukan pane aktif tanpa klik, tapi belum
  ada isyarat visual pane mana yang sedang aktif. Bingkai tipis di tepi pane
  adalah kandidat termurah.
- **Layar judul.** TAHAP G, belum disentuh sama sekali.

---

## 8. Papan tambahan — antarmuka

Dibuat setelah papan di §1, semuanya lewat `python3 ui.py`.

| Berkas | Isi | Dipakai saat |
|---|---|---|
| `ui_kit.png` | 15 komponen antarmuka dalam piksel dunia | membangun `Hud.gd` dan `TuningPanel.gd` |
| `keadaan_layar.png` | tujuh keadaan layar dalam proporsi dunia 480×320 | memastikan HUD tetap di tempat yang sama di semua keadaan |
| `palet_terapan.png` | palet di bawah tiga tingkat cahaya + empat keadaan pita atas | menyetel `CanvasModulate` dan menguji penanda leher botol |

### 8.1 Komponen dan ukurannya

| Komponen | Ukuran (piksel dunia) | Catatan |
|---|---|---|
| bar energi | 52×9 | isi `DAUN`, kosong `GEDUNG`, bingkai `TERANG` |
| bar perhatian | 52×9 | isi `JENDELA`, garis `UJUNG` menandai `AMBANG_RAWAT` |
| bar zona | 46×7 | garis `JENDELA` menandai target zona |
| penanda leher botol | bingkai 1 px | dipasang pada Air atau Cahaya, tidak pernah keduanya |
| panel HUD | bebas | latar `RETAK`, satu garis `TERANG` di tepi atas |
| tooltip | bebas | hanya nama terrain saat hover; bukan penjelasan mekanik |
| penanda ujung terpilih | 13×13 | siku di empat sudut, radius klik 9 px |
| pratinjau jalur | 40 px | titik putus `UJUNG`, memakai aturan tumbuh yang sama (§11 Logika) |
| penanda pane aktif | siku 10 px | menjawab pertanyaan terbuka §7 |
| penanda zona | bingkai putus | dipasang di zona yang dijadwalkan dirawat |
| pita inspeksi | tinggi 16 | muncul sehari penuh, lalu hilang sendiri |
| overlay MULAI | bebas | menahan permainan sambil bake cahaya dicicil |
| slider tuning | tinggi 11 | alur 1 px, kenop 4×5 |
| tombol | tinggi 13 | keadaan aktif = warna dibalik, bukan warna baru |
| penunjuk zoom | 40×11 | dua nilai saja |

### 8.2 Tingkat cahaya malam

Tiga kandidat `CanvasModulate` yang sudah digambar: siang tanpa modulate, senja
`0.72 / 0.70 / 0.80`, malam `0.45 / 0.50 / 0.70`. Nilai malam sengaja menahan
biru lebih tinggi daripada merah supaya beton mendingin tapi daun tidak berubah
jadi abu-abu — kalau hijau ikut mati, satu-satunya warna jenuh di layar hilang
dan seluruh premis visualnya ikut hilang.

### 8.3 Aturan warna antarmuka

- `UJUNG` hanya untuk satu hal dalam satu waktu: yang paling perlu diperhatikan
  sekarang. Ini juga jawaban sementara untuk pertanyaan terbuka di §7.
- Bar kosong selalu `GEDUNG`, bingkai selalu `TERANG`, latar panel selalu
  `RETAK`.
- Teks penting `JENDELA`, teks pendukung `GEDUNG`. Tidak ada tingkat ketiga.
