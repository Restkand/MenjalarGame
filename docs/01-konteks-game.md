# KONTEKS — Akar & Beton

Dokumen ini menjelaskan *apa* yang sedang dibangun dan *kenapa*. Untuk aturan main dan rumus, lihat dokumen Logika.

---

## 1. Ringkasan

Pemain adalah sebuah pohon yang tumbuh di celah kota beton. Layar terbagi dua secara horizontal: di bawah garis tanah ada akar yang mencari air, di atasnya ada dahan yang mencari cahaya. Pemain mengarahkan pertumbuhan dengan mouse.

Game penuhnya adalah puzzle-stealth. **Prototipe ini bukan itu.** Prototipe ini hanya menguji lapisan paling dasar.

---

## 2. Satu Pertanyaan yang Harus Dijawab Prototipe

> Apakah mengarahkan pertumbuhan pohon itu menyenangkan, atau membosankan?

Semua keputusan dalam prototipe harus tunduk pada pertanyaan ini. Kalau sebuah fitur tidak membantu menjawabnya, fitur itu tidak dibangun.

**Tolok ukur keberhasilan:** setelah 5 menit bermain, apakah masih ada dorongan untuk terus menumbuhkan cabang berikutnya?

---

## 3. Yang Dibangun dan Yang Tidak

| Dibangun | Sengaja TIDAK dibangun |
|---|---|
| Pertumbuhan akar dan dahan | Siklus siang-malam |
| Batas kecepatan belok | Sistem stealth / paparan |
| Ekonomi `min(Air, Cahaya)` | Tukang kebun dan pengamat |
| Beton yang menghalangi akar | Naturalisasi |
| Bayangan gedung | Sifat / progresi |
| Merambat di dinding | Menu, level, kondisi menang |
| Klik-tarik + pratinjau jalur | Audio |

Menambahkan hal dari kolom kanan akan mengaburkan jawaban atas pertanyaan di §2.

---

## 4. Rasa yang Dikejar

Kata kunci: **merambat, sabar, organik, sedikit di luar kendali.**

Pohon tidak boleh terasa seperti kursor. Pemain **mengusulkan** arah; tanaman **memutuskan** dengan caranya sendiri — melengkung, condong ke cahaya, menempel di dinding. Sedikit ketidakpatuhan adalah fiturnya. Kalau cabang bergerak persis mengikuti mouse, rasanya jadi menggambar, bukan menumbuhkan.

Referensi rasa: menonton time-lapse tanaman merambat, bukan menggerakkan karakter.

---

## 5. Arah Visual

### Gaya
Pixel art, tampak samping, potongan melintang tanah — seperti melihat isi sarang semut buatan atau diagram di buku biologi.

### Teknik render
Gambar ke buffer resolusi rendah **240×160**, lalu skalakan 4× dengan *nearest neighbor* (`image-rendering: pixelated`). Ini wajib. Menggambar langsung di resolusi tinggi akan menghasilkan garis halus yang merusak identitas visual.

### Palet

Kontras adalah keseluruhan pesan game ini. Kota digambar tanpa kebencian — hanya tanpa kehidupan. Pohon adalah satu-satunya warna jenuh di layar.

| Elemen | Hex | Catatan |
|---|---|---|
| Langit | `#8B96A3` | Abu kebiruan, pucat |
| Gedung | `#5F6874` | Datar, tanpa detail berlebih |
| Gedung (sisi terang) | `#6E7784` | |
| Jendela | `#9AA4B0` | Kotak kecil, tidak menyala |
| Tanah | `#4A3728` | Cokelat hangat gelap |
| Tanah lembap | `#5C4433` | Sedikit lebih terang |
| Beton | `#7D7D75` | Abu kehijauan kusam |
| Pipa air | `#4A6B7C` | Satu-satunya biru |
| Akar | `#A87B4E` | Cokelat kekuningan |
| Batang / dahan | `#7A5C3A` | |
| Daun | `#5EC24A` | **Hijau jenuh — satu-satunya di layar** |
| Ujung tumbuh | `#B8E986` | Berdenyut, menarik mata |
| Retakan | `#3A3A36` | |

### Aturan warna
Tidak ada gradien. Tidak ada bayangan lembut. Setiap piksel adalah salah satu warna di atas. Kalau butuh kedalaman, gunakan satu piksel warna lebih gelap di sisi bawah objek.

---

## 6. Antarmuka

Minimal dan menepi. Game ini soal mengamati; UI tidak boleh bersaing dengan kanvas.

Yang ditampilkan:
- **Energi** — bar horizontal
- **Air** dan **Cahaya** — dua angka kecil berdampingan, dengan penanda mana yang sedang jadi leher botol
- **Jumlah ujung aktif**

Penanda leher botol itu penting: pemain harus langsung paham kenapa energinya lambat. Kalau Air = 4 dan Cahaya = 1, sorot Cahaya. Ini mengajarkan aturan `min()` tanpa satu kalimat tutorial.

Tidak ada teks bertema, tidak ada narasi, tidak ada tips. Kalau sebuah gagasan harus ditulis di layar, berarti mekaniknya belum bekerja.

---

## 7. Batasan Kontrol

Seluruh permainan lewat **satu tangan di mouse**. Klik-tarik untuk mengarahkan, hover untuk melihat, satu tombol untuk percabangan. Tidak ada menu di tengah permainan, tidak ada kombinasi tombol.

Ini bukan preferensi estetis — ini pilar desain yang mengalahkan fitur apa pun.

---

## 8. Konteks Proyek

- Game pertama pengembang; ruang lingkup dijaga ketat dengan sengaja
- Target akhir: PC, distribusi Steam, premium sekali bayar
- Engine akhir: Godot 4 (prototipe HTML ini hanya untuk menguji rasa, bukan fondasi kode)
- Aset akhir: pixel art; pohon dirender prosedural sehingga tidak butuh sprite
