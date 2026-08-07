# LOGIKA — Akar & Beton (Prototipe)

Spesifikasi mekanik dan teknis. Semua angka adalah **titik awal untuk dituning**, bukan nilai final.

---

## 1. Kanvas & Koordinat

```
Resolusi internal : 240 × 160 piksel
Skala tampilan    : 4× (960 × 640), nearest neighbor
Garis tanah       : y = 68
Zona udara        : y = 0 .. 67
Zona tanah        : y = 68 .. 159
Sumbu y           : bertambah ke bawah
```

Semua logika berjalan di koordinat internal 240×160. Konversi posisi mouse: `bagi dengan 4`.

---

## 2. Struktur Data

### Strand (untai)

Pohon adalah kumpulan untai. Setiap untai adalah rantai titik yang tumbuh dari satu ujung.

```js
Strand {
  points: [{x, y}]      // float, bukan integer
  isRoot: boolean        // true = akar, false = dahan
  angle: float           // radian, arah tumbuh saat ini
  alive: boolean         // false jika ujung berhenti
  generation: int        // 0 = untai awal, +1 tiap percabangan
  crackProgress: float   // 0..1, hanya saat menembus beton
  leaves: [{x, y, size}] // hanya untuk dahan
}
```

### Prinsip Penting

**Simulasi memakai float, render membulatkan ke integer.**

Posisi ujung boleh berada di `(12.7, 45.3)` dengan sudut `37.2°`. Pembulatan hanya terjadi saat menggambar. Ini yang memungkinkan kurva halus tetap tampil sebagai pixel art bersih.

Jangan menyimpan posisi sebagai integer — hasilnya akan tersendat dan bersudut.

---

## 3. Konstanta

```js
const GROWTH_SPEED    = 7.0;   // piksel per detik
const MAX_TURN        = 1.5;   // radian per detik
const NOISE_AMOUNT     = 0.35;  // radian per detik, dari Perlin/sin
const TROPISM_STRENGTH = 0.6;   // radian per detik

const ENERGY_RATE      = 6.0;   // energi per detik per unit min()
const COST_PER_PIXEL   = 1.4;   // energi per piksel per ujung
const COST_BRANCH      = 25;
const COST_CRACK       = 40;    // total untuk menembus satu blok beton
const CRACK_DURATION   = 3.0;   // detik

const LEAF_SPACING     = 8;     // piksel antar daun di dahan
const SUN_DIR          = normalize(0.35, -1.0);
const MAX_STRANDS      = 24;    // batas keamanan performa
```

---

## 4. Loop Pertumbuhan

Dijalankan tiap frame untuk setiap untai yang `alive`.

### 4.1 Urutan

```
1. Hitung sudut yang diinginkan (input pemain + tropisme + noise)
2. Batasi perubahan sudut ke MAX_TURN
3. Hitung posisi kandidat berikutnya
4. Cek tabrakan — tangani (merambat / retak / berhenti)
5. Kurangi energi; kalau energi 0, jangan tumbuh
6. Tambahkan titik baru
```

### 4.2 Pengarahan Sudut

```js
let target = strand.angle;

// Input pemain (hanya untuk untai yang dipilih)
if (strand === selected && isDragging) {
  target = atan2(mouse.y - tip.y, mouse.x - tip.x);
}

// Tropisme
target += tropism(strand) * TROPISM_STRENGTH * dt;

// Noise organik
target += (noise(time + strand.id) - 0.5) * NOISE_AMOUNT * dt;

// Batas belok — INI yang menghasilkan rasa merambat
let delta = wrapAngle(target - strand.angle);
delta = clamp(delta, -MAX_TURN * dt, MAX_TURN * dt);
strand.angle += delta;
```

**`MAX_TURN` adalah parameter terpenting dalam prototipe ini.** Terlalu tinggi — terasa seperti menggambar dengan kursor. Terlalu rendah — terasa tidak responsif. Sediakan slider untuk menyetelnya saat runtime.

### 4.3 Batasan Zona

- Akar (`isRoot = true`) tidak boleh naik di atas `y = 68`
- Dahan (`isRoot = false`) tidak boleh turun di bawah `y = 68`

Kalau ujung mencoba menyeberang, sudutnya dipantulkan menjauh dari garis tanah.

---

## 5. Tropisme

Tiga perilaku yang membuat pohon terasa hidup — dan yang membuat pemain merasa *mengusulkan*, bukan *mengendalikan*.

### 5.1 Fototropisme (dahan)

Dahan condong ke arah cahaya. Cari arah dengan cahaya terkuat dalam kerucut ±60° dari sudut saat ini, condongkan ke sana.

Deviasi maksimal **15°** dari arah yang diminta pemain. Lebih dari itu terasa kehilangan kendali.

### 5.2 Hidrotropisme (akar)

Akar tertarik ke sumber air dalam radius **30 piksel**. Kekuatan tarikan berbanding terbalik dengan jarak. Efeknya: pemain bisa "mencium" pipa air sebelum melihatnya.

### 5.3 Tigmotropisme — Merambat di Dinding

**Ini perilaku terpenting untuk rasa yang dikejar.**

Kalau posisi kandidat berikutnya berada di dalam gedung atau beton:

```
1. Cari normal permukaan pada titik tabrakan
2. Proyeksikan arah tumbuh ke bidang singgung permukaan
3. Set sudut ke arah proyeksi itu
4. Geser posisi 1 piksel keluar dari permukaan
```

Hasilnya: cabang tidak menabrak dan berhenti — dia **membelok dan menyusuri** dinding. Ini yang membuat pohon terlihat seperti sulur, bukan garis.

Kalau permukaan itu **beton di bawah tanah**, akar punya pilihan tambahan: menembus (lihat §7).

---

## 6. Ekonomi Sumber Daya

### 6.1 Air

```js
air = 0;
for (setiap ujung akar yang hidup) {
  if (di tanah lembap)      air += 1.0;
  if (menyentuh pipa air)   air += 3.0;
  if (di tanah kering/beton) air += 0.0;
}
```

### 6.2 Cahaya

Untuk setiap daun, tembakkan sinar berlawanan arah `SUN_DIR` sampai keluar layar:

```js
cahaya = 0;
for (setiap daun) {
  if (tidak ada gedung yang menghalangi)  cahaya += 1.0;
  else if (terhalang sebagian)            cahaya += 0.3;
  else                                    cahaya += 0.0;
}
```

Batasi ke maksimal **40 raycast per frame** untuk performa. Kalau daun lebih banyak, ambil sampel bergilir.

### 6.3 Energi

```js
bottleneck = min(air, cahaya);
energi += bottleneck * ENERGY_RATE * dt;
```

**Ini aturan tunggal yang menopang seluruh permainan.** Menumpuk satu sisi tidak berguna. Akar sebanyak apa pun percuma kalau daun tertutup bayangan.

UI harus menyorot mana yang sedang jadi leher botol.

### 6.4 Konsumsi

```js
biaya = jumlahUjungHidup * GROWTH_SPEED * COST_PER_PIXEL * dt;
energi -= biaya;
if (energi <= 0) { energi = 0; pertumbuhan berhenti; }
```

Konsekuensi desain: **lebih banyak ujung = konsumsi lebih cepat.** Ini yang membuat percabangan jadi keputusan, bukan aksi gratis.

---

## 7. Menembus Beton

Saat ujung akar bertabrakan dengan blok beton, pemain bisa memilih menembus (klik pada ujung tersebut).

```
- Ujung berhenti bergerak
- crackProgress naik dari 0 ke 1 selama CRACK_DURATION
- Energi terkuras COST_CRACK / CRACK_DURATION per detik
- Kalau energi habis di tengah jalan, progress membeku (tidak reset)
- Saat mencapai 1.0: lubang muncul di beton, akar melanjutkan
```

Visual: retakan tumbuh dari titik kontak, bertambah tiap 25% progress.

---

## 8. Percabangan

Dipicu dengan menekan **spasi** atau klik kanan pada ujung terpilih.

```
- Biaya COST_BRANCH energi
- Untai baru dibuat di posisi ujung
- Sudut awal: sudut induk ± (25° sampai 40°), arah acak
- generation = induk.generation + 1
- Untai induk tetap hidup dan melanjutkan
- Ditolak kalau jumlah untai >= MAX_STRANDS atau energi kurang
```

---

## 9. Daun

Hanya pada untai dahan, hanya di atas garis tanah.

```
- Ditambahkan tiap LEAF_SPACING piksel pertumbuhan
- Posisi: pada titik untai, digeser tegak lurus ± (1..3) piksel, sisi acak
- Ukuran: 2×2 saat baru, tumbuh ke 3×3 selama 1.5 detik
- Berkontribusi ke perhitungan cahaya
```

---

## 10. Render

### 10.1 Urutan Gambar

```
1. Langit dan tanah (dua persegi panjang datar)
2. Zona tanah lembap (warna sedikit berbeda)
3. Beton dan pipa
4. Gedung
5. Akar (dari untai tertua ke terbaru)
6. Batang dan dahan
7. Daun
8. Ujung berdenyut
9. Pratinjau jalur (kalau sedang menyeret)
10. UI
```

### 10.2 Menggambar Untai

**Jangan gunakan `lineTo`.** Anti-aliasing akan merusak estetika pixel art.

Sebagai gantinya, gambar **lingkaran piksel** di sepanjang jalur:

```js
for (setiap titik dalam strand.points) {
  const tebal = ketebalanDiTitik(i);
  gambarLingkaranPiksel(round(p.x), round(p.y), tebal, warna);
}
```

`gambarLingkaranPiksel` mengisi piksel dengan `fillRect(x, y, 1, 1)` di dalam radius.

**Kenapa lingkaran, bukan garis:** garis akan terlihat menipis saat diagonal. Lingkaran menjaga ketebalan konsisten di segala sudut.

### 10.3 Ketebalan

Titik yang lebih tua (indeks lebih kecil) lebih tebal:

```js
tebal = 1 + min(2.5, (points.length - i) * 0.015) - generation * 0.3;
tebal = max(1, tebal);
```

Efeknya: batang menebal seiring waktu, cabang muda lebih tipis.

### 10.4 Detail yang Memberi Volume

Satu piksel warna lebih gelap di sisi bawah setiap untai. Murah, dan langsung memberi kesan tiga dimensi tanpa sprite.

### 10.5 Denyut Ujung

Piksel terujung setiap untai hidup berkedip antara `#B8E986` dan `#5EC24A`, siklus ~0.6 detik. Sangat murah, tapi langsung menarik mata ke titik pertumbuhan.

---

## 11. Kontrol

| Aksi | Input |
|---|---|
| Pilih ujung | Klik pada atau dekat ujung (radius 8 px) |
| Arahkan pertumbuhan | Tahan dan seret dari ujung terpilih |
| Pratinjau jalur | Otomatis muncul saat menyeret |
| Percabangan | Spasi, atau klik kanan pada ujung |
| Menembus beton | Klik ujung yang sedang bersentuhan dengan beton |
| Hentikan ujung | Tekan `X` pada ujung terpilih |

### Pratinjau Jalur

Saat menyeret, gambar simulasi ke depan **40 piksel** dengan aturan pertumbuhan yang sama (termasuk batas belok dan tropisme), sebagai titik-titik putus setengah transparan.

Ini memberi tahu pemain ke mana cabang akan *benar-benar* tumbuh — bukan ke mana kursornya menunjuk. Fitur ini penting karena tropisme membuat hasil berbeda dari niat.

---

## 12. Tata Letak Level Prototipe

Satu layar statis, dirancang manual. Cukup untuk menguji semua sistem.

**Atas tanah:**
- Dua gedung: kiri `x 10–55, y 8–68`, kanan `x 175–230, y 20–68`
- Celah terbuka di tengah — jalur cahaya terbaik, dan satu-satunya
- Kanopi rendah di gedung kiri, `x 55–75, y 40–48` — permukaan untuk merambat

**Bawah tanah:**
- Tanah lembap: `x 0–70` dan `x 160–240`, mulai `y 100`
- Tanah kering di tengah: `x 70–160`
- Beton menghalangi jalur ke kiri: `x 55–80, y 85–100`
- Pipa air di kanan: `x 195–215, y 120–125`

**Bibit:** `x 120, y 68` — tepat di tengah, di tanah kering, jauh dari air.

**Puzzle implisitnya:** air ada di kiri (di balik beton) dan kanan (jauh). Cahaya terbaik ada di celah tengah. Pemain harus membelah perhatian — dan itulah aturan `min()` yang bekerja tanpa dijelaskan.

---

## 13. Panel Tuning

Sediakan panel yang bisa dibuka-tutup dengan slider langsung untuk:

```
GROWTH_SPEED      1.0 – 25.0
MAX_TURN          0.2 – 5.0     ← paling penting
NOISE_AMOUNT      0.0 – 1.5
TROPISM_STRENGTH  0.0 – 2.0
ENERGY_RATE       1.0 – 20.0
COST_PER_PIXEL    0.2 – 4.0
```

Plus tombol **Reset** untuk mengulang dari bibit.

Panel ini bukan pelengkap — inilah alat utama untuk menjawab pertanyaan §2 di dokumen Konteks. Rasa yang tepat hanya bisa ditemukan dengan menggeser slider sambil bermain.

---

## 14. Catatan Performa

- Batasi total titik: kalau melebihi 4000, hentikan untai tertua
- Raycast cahaya: maksimal 40 per frame, sampel bergilir
- Render ke `<canvas>` 240×160, skalakan lewat CSS
- Target 60fps

---

## 15. Yang Sengaja Tidak Ada

Jangan tambahkan, meski terasa mudah:

- Kondisi menang atau kalah
- Timer atau tekanan waktu
- Skor
- Siklus siang-malam
- Pengamat atau sistem stealth
- Suara
- Layar judul atau menu

Setiap tambahan mengaburkan sinyal. Prototipe ini punya satu tugas.
