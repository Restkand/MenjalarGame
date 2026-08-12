# 13 — PIVOT IV: Menjalar sebagai stealth-platformer organik

12 Agustus 2026, malam. Pemilik proyek memutuskan pivot penuh setelah
playtest orang-dekat (teman dekat + pasangan): keduanya kebingungan dan
tidak menemukan keasyikan di gameplay stealth sistemik. Acuan baru:
**Carrion, Metroid, Splinter Cell 2D.**

Tiga keputusan dasar (dijawab pemilik proyek lewat pertanyaan terarah):

1. **Kamera tunggal** mengikuti avatar. Split-screen dua pane DIBONGKAR.
2. **Dua tingkat serangan**: lilit (murah, pingsan sementara, senyap) dan
   bunuh (mahal, permanen, mayat yang ditemukan = eskalasi drastis).
3. **Akhir permainan: menyebar ke kota.** Gedung pertama = seluruh isi
   game sekarang; penyebaran adalah babak penutupnya (benih terbang,
   siluet kota parallax menghijau), sekaligus pintu sekuel gedung
   berikutnya.

Ini pivot ke-EMPAT dan harus jadi yang terakhir. Aturannya sama dengan
pivot yang berhasil sebelumnya: dokumen ini dulu, lalu tahapan P1–P8 yang
masing-masing menghasilkan build yang BISA DIMAINKAN.

---

## 1. Fantasi inti

Anda adalah **ujung tumbuh** — kepala sulur muda yang bisa melepaskan diri
dari jaringan induknya. Jaringan akar-sulur yang memenuhi gedung adalah
rumah, jalan raya, dan nyawa cadangan Anda. Kota ingin memangkas Anda.
Tumbuhlah lebih cepat daripada gunting mereka, dan jangan terlihat.

## 2. Pilar (menggantikan pilar docs/06)

1. **Jaringan = nyawa.** Di atas jaringan: cepat, aman, energi pulih.
   Lepas dari jaringan: platforming, terekspos, energi terkikis.
2. **Energi = keberanian.** Semua aksi di luar jaringan membayar energi;
   habis = layu, bangun di simpul jaringan terakhir.
3. **Jangan terlihat.** Penjaga berkerucut pandang, alarm bertingkat.
   (Larangan lama atas kerucut pandang DICABUT — alasannya dulu adalah
   perhatian terbelah dua pane; pane-nya sudah tidak ada.)
4. **Kota abu-abu dan tidak jenuh; Anda satu-satunya yang berwarna.**
   Identitas visual TIDAK ikut pivot. Kitab gaya docs/12 tetap hukum.

Batasan teknis yang tidak berubah: TANPA physics engine (tabrakan grid
sendiri), input hanya di main.gd, Config.gd nol fungsi, simulasi float,
Godot 4.7 Compatibility.

## 3. Avatar & kontrol

Dua moda, berpindah mulus:

- **MERAMBAT** (di jaringan / permukaan yang sudah dirambati `tutup`):
  bergerak bebas segala arah sepanjang jaringan dengan cepat, menempel
  dinding/plafon, energi PULIH pelan. Tidak bisa terlihat selama diam
  di jaringan yang berdaun (kamuflase).
- **LEPAS** (platformer): jalan, lompat, panjat pendek, jatuh dengan
  gravitasi grid sendiri. Energi terkikis pelan; aksi khusus membayar
  lebih. Kembali menyentuh jaringan = kembali ke moda MERAMBAT.

Aksi:

| Aksi | Moda | Biaya | Catatan |
|---|---|---|---|
| Tanam jangkar | keduanya | sedang | menumbuhkan simpul jaringan baru di posisi — checkpoint + memperpanjang jaringan |
| Lilit | dekat musuh | kecil | senyap; korban pingsan sementara; ditemukan rekan = CURIGA |
| Bunuh | dekat musuh | besar | permanen; mayat ditemukan = SIAGA + eskalasi naik |
| Bor beton | di retakan | besar | reuse mekanik tembus; gerbang kemajuan |
| Sprint/lesat | LEPAS | sedang | melintasi koridor terang dengan cepat |

Layu (energi habis saat LEPAS): bangun di simpul terakhir; perhatian kota
naik sedikit — bukan game over, tapi terasa.

## 4. Dunia: satu gedung = peta Metroid

- **Interior gedung DIBANGUN** (baru): lantai-lantai berisi kamar,
  koridor, poros lift, saluran ventilasi (jalan tikus sulur), ruang
  gelap (aman) vs koridor terang (berbahaya). Grid & terrain enum yang
  ada diperluas, bukan diganti.
- **Eksterior fasad** (reuse penuh): jalur memanjat alternatif; jendela =
  pintu masuk-keluar interior.
- **Bawah tanah** (reuse penuh): akuifer = stasiun air; gorong/utilitas =
  jalur rahasia antar sisi gedung.
- **Sumber daya PUNYA ALAMAT** — jawaban langsung playtest ("tidak tahu
  di mana dapat air dan sinar matahari"): AIR dari akuifer, pipa bocor,
  keran; CAHAYA dari jendela cerah, lubang atap, atap. Berdiri di
  sumber = energi terisi; jaringan yang menyentuh sumber mengisi lebih
  cepat. Ikon denyut halus menandai sumber yang sudah ditemukan.
- **Gerbang ala Metroid**: retakan beton (butuh bor), teralis (butuh
  massa jaringan), lantai atas terkunci sampai jaringan lantai bawah
  cukup, ruang server panas, dll.

## 5. Musuh & alarm

- **Penjaga/tukang kebun** patroli rute tetap per shift (reuse sprite &
  animasi pipeline karakter docs/12 §6; tambah state: senter, curiga,
  menyeret rekan). Kerucut pandang digambar samar — jujur, terbaca.
- **Alarm bertingkat**: TENANG → CURIGA (investigasi titik terakhir
  terlihat) → SIAGA (perburuan + regu tambahan) → mereda seiring waktu.
- **Eskalasi antar-hari** (reuse G6): patroli makin rapat, gergaji makin
  cepat, senter makin lebar.
- **Regu pemangkas menyerang JARINGAN** (reuse crew/gergaji/bangkai):
  jalur Anda bisa diputus saat Anda jauh; perkuat (kokoh) bertahan 2×.
  Kehilangan jaringan = kehilangan rute & titik bangun — inilah tekanan
  strategisnya.

## 6. Ekonomi

SATU angka: **ENERGI** (reservoir). `min(air, cahaya)` yang abstrak
DILEBUR jadi fisik: reservoir terisi di sumber air ATAU cahaya, tapi
laju penuh butuh keduanya pernah disentuh hari itu (bonus "seimbang").
Semua biaya aksi dari tabel §3. Upgrade permanen (Metroid): kapasitas
reservoir, efisiensi lilit, bor lebih cepat, lesat lebih jauh — dibeli
dengan MEKAR di titik-titik ikonik gedung (taman jendela, mural, dsb).

## 7. Struktur babak & akhir

- **BABAK I — BASEMEN.** Gelap, tanpa penjaga awalnya; ajari moda
  merambat/lepas, jangkar, sumber air pertama. (Sekaligus onboarding —
  pengganti G9.)
- **BABAK II — GEDUNG.** Lantai demi lantai, shift penjaga, gerbang,
  upgrade, regu pemangkas mulai agresif.
- **BABAK III — ATAP & PENYEBARAN.** Mekar besar di atap; benih terbang;
  siluet kota parallax MENGHIJAU satu per satu = layar kemenangan dan
  janji sekuel.

## 8. Peta reuse (apa yang selamat)

| Sistem lama | Nasib |
|---|---|
| Grid dunia, terrain enum, WorldMap | REUSE — interior menambah enum, tidak mengganti |
| `tutup` (jaringan rambatan) | NAIK PANGKAT — jadi jaringan-nyawa pemain |
| Render views (Terrain/Fasad/Latar/Daun/Sulur/Pohon/Puing/Aktor) | REUSE penuh |
| Pipeline karakter PixelLab (docs/12 §6) | REUSE — tambah animasi penjaga |
| Suara, siang-malam, senja, lampu | REUSE |
| Eskalasi (G6), gergaji+bangkai (G3), kokoh (G2), tembus beton | REUSE dengan makna baru |
| Kalender inspeksi terjadwal | MATI → jadi shift patroli & mereda-nya alarm |
| Split-screen, Pane ganda | MATI → satu kamera ikut avatar |
| Babak tutupan zona, menang lewat tutupan | MATI → babak §7 |
| Kartu fase sebagai pengajar utama | MENYUSUT → tetap untuk pergantian hari/shift |
| Steering ujung via mouse, tunas ulang, tanam pohon (T) | MATI sebagai kontrol; pohon jadi upgrade/mekar |
| G9/G10 (peta jalan docs/11) | BATAL — digantikan P1–P8 |

## 9. Peta jalan P1–P8 (satu tahap = satu build yang bisa dimainkan)

- **P1 — Avatar.** Kamera tunggal, moda MERAMBAT di jaringan awal +
  LEPAS platforming (gravitasi grid), energi terkikis/pulih, layu →
  bangun di simpul. Dunia yang sekarang dipakai apa adanya.
- **P2 — Interior.** Gedung diisi lantai/kamar/ventilasi/poros; pintu
  masuk lewat jendela; gerbang statis pertama.
- **P3 — Sumber daya.** Stasiun air & cahaya berfungsi; jangkar; ikon
  sumber ditemukan; ekonomi energi penuh.
- **P4 — Penjaga.** Patroli + kerucut pandang + alarm 3 tingkat.
- **P5 — Lilit & bunuh.** Dua serangan, korban pingsan/mayat, penemuan
  oleh rekan, eskalasi.
- **P6 — Perang jaringan.** Regu pemangkas menyerang jaringan; perkuat;
  bangkai & tunas ulang dalam konteks baru.
- **P7 — Metroid penuh.** Gerbang + upgrade + peta gedung (layar M).
- **P8 — Babak & ending.** Basemen-tutorial, atap, penyebaran, polish.

Kerjakan SATU tahap per sesi; commit tiap tahap terverifikasi. Sistem
lama yang mati baru DIHAPUS ketika tahap yang menggantikannya berdiri —
jangan pernah membongkar sebelum penggantinya jalan.

## 10. Pertanyaan terbuka (diputuskan saat tahapnya tiba)

- Bentuk visual avatar: kepala sulur bercahaya (C_TIP) — butuh sprite
  sendiri atau cukup prosedural denyut? (P1 pakai prosedural dulu.)
- Apakah siang-malam memengaruhi shift penjaga (malam lebih sedikit
  penjaga tapi senter)? (Condong: ya, di P4.)
- Nada kekerasan bunuh: diseret ke dalam dedaunan, tanpa darah. (Condong
  kuat; keputusan final saat P5.)
- Save/checkpoint antar sesi bermain. (P7.)
