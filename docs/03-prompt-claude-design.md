# Prompt untuk Claude Design

Lampirkan `01-konteks-game.md` dan `02-logika-game.md`, lalu tempel teks di bawah ini.

---

## PROMPT UTAMA

```
Bangun prototipe interaktif untuk game 2D bernama "Akar & Beton". Dua dokumen
terlampir: Konteks (arah visual dan tujuan) dan Logika (mekanik, rumus, konstanta).
Ikuti keduanya secara harfiah — angka, hex warna, dan tata letak level sudah
ditentukan dan tidak perlu ditafsirkan ulang.

Output: satu file HTML mandiri, tanpa dependensi eksternal, tanpa build step.
JavaScript vanilla dan Canvas 2D API saja.

TUJUAN PROTOTIPE
Ini bukan game jadi. Tujuannya menjawab satu pertanyaan: apakah mengarahkan
pertumbuhan pohon terasa menyenangkan? Semua keputusan tunduk pada itu.
Jangan menambahkan kondisi menang, skor, timer, suara, menu, atau siklus
siang-malam — daftar lengkap di §15 dokumen Logika.

TIGA HAL YANG PALING MENENTUKAN KEBERHASILAN

1. Rasa merambat.
   Datang dari batas kecepatan belok (MAX_TURN, §4.2 Logika). Cabang tidak boleh
   bisa patah mendadak — dia harus melengkung untuk berbelok. Kalau cabang
   mengikuti kursor persis, prototipe ini gagal.

2. Render pixel art yang benar.
   Gambar ke canvas 240×160, skalakan 4× dengan image-rendering: pixelated.
   Untai digambar sebagai rangkaian lingkaran piksel (fillRect 1×1 di dalam
   radius), BUKAN dengan lineTo. Anti-aliasing merusak seluruh identitas visual.
   Detail di §10 Logika.

3. Panel tuning.
   Slider runtime untuk enam konstanta di §13 Logika, plus tombol Reset.
   Ini alat utama untuk menemukan rasa yang tepat, bukan fitur tambahan.

PRINSIP YANG MUDAH TERLEWAT

- Simulasi memakai float, render membulatkan ke integer. Jangan simpan posisi
  sebagai integer — hasilnya tersendat dan bersudut.
- Merambat di dinding (tigmotropisme, §5.3) adalah perilaku yang membuat pohon
  terlihat seperti sulur. Cabang yang menyentuh permukaan harus membelok dan
  menyusurinya, bukan berhenti.
- Pratinjau jalur (§11) memakai aturan pertumbuhan yang sama, termasuk tropisme.
  Pemain harus melihat ke mana cabang akan benar-benar tumbuh, bukan ke mana
  kursornya menunjuk.
- UI harus menyorot mana yang sedang jadi leher botol antara Air dan Cahaya.
  Ini mengajarkan aturan min() tanpa tutorial teks.

BATASAN
- Satu tangan di mouse. Tanpa menu di tengah permainan, tanpa kombinasi tombol.
- Nol teks bertema, nol narasi, nol tips.
- Tanpa gradien dan tanpa bayangan lembut. Setiap piksel memakai salah satu
  warna dari palet di §5 Konteks.

Mulai dengan menyatakan rencana implementasimu dalam beberapa kalimat, lalu
bangun.
```

---

## PROMPT LANJUTAN

Gunakan setelah versi pertama jadi. Satu per satu, jangan digabung.

**Kalau gerakan terasa kaku atau seperti kursor:**
```
Pertumbuhan terasa seperti menggambar dengan kursor, bukan tanaman merambat.
Turunkan MAX_TURN, naikkan NOISE_AMOUNT, dan pastikan sudut target dihitung
lewat interpolasi bertahap, bukan diset langsung ke arah mouse.
```

**Kalau garis terlihat kotor atau bergerigi:**
```
Untai terlihat bergerigi. Periksa: apakah menggunakan lingkaran piksel atau
lineTo? Apakah ketebalan konsisten di sudut diagonal? Apakah posisi dibulatkan
saat render saja, bukan saat simulasi?
```

**Kalau terasa membosankan setelah satu menit:**
```
Tambahkan satu hal saja: naikkan kecepatan pertumbuhan dua kali lipat lewat
slider dan biarkan saya coba. Jangan tambahkan mekanik baru — kalau intinya
belum menyenangkan, sistem tambahan hanya menyembunyikan masalahnya.
```

**Kalau ingin memisahkan rasa dari konten:**
```
Tambahkan mode kosong: level tanpa gedung, beton, dan batasan energi. Hanya
pohon yang tumbuh bebas. Saya ingin menilai gerakannya secara terisolasi.
```

---

## CATATAN

Claude Design dirancang untuk mengeksplorasi antarmuka software, jadi prototipe
game kanvas ada di tepi kemampuannya. Kalau hasilnya kurang memuaskan, coba
prompt yang sama di percakapan Claude biasa — artifact HTML di sana lebih
terbiasa dengan kode kanvas interaktif.

Apa pun hasilnya, `MAX_TURN` adalah angka yang perlu kamu setel paling lama.
Sisanya bisa mengikuti.
