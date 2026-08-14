# RK-2 — LOOP ROOM 01

**Status:** RENCANA KERJA AKTIF — BUKAN KANON. Dibuang setelah selesai
(seperti RK pertama). Disahkan pemilik proyek 15 Agustus 2026.

## Latar

Gerbang Langkah 3 putaran 2: secara teknis tiga rute tertempuh, tapi
playtest pemilik menemukan empat lubang: (1) loop belum menarik,
(2) tombol F tanpa dampak, (3) batas moda LEPAS membingungkan,
(4) alasan MERAMBAT kurang jelas. Keempatnya BUKAN penyimpangan GDD —
semuanya halaman GDD yang belum dibangun. RK-2 menyisipkan satu putaran
LOOP sebelum Langkah 4 (grading) dan Langkah 5 (lipat kanon) RK lama.

## Tahapan (urut, satu commit per tahap terverifikasi)

### A. MATERIAL BICARA (GDD §12, MVP §39: tiga kelas saja)

- LEMBAP (tumbuh murah): koridor drain + cerobong + celah masuk +
  kolom dinding kanan yang dialiri air katup.
- RETAK (tumbuh normal): bercak retak dinding tengah ruangan.
- BETON (TIDAK bisa ditumbuhi): sisanya. Merambat = hanya jaringan
  yang sudah ada; menyeberang bentang beton = alasan hidup moda LEPAS.
- Umpan balik wajib: ujung berkedip menolak + petunjuk HUD singkat
  saat mencoba tumbuh di beton. Zona lembap diberi rona lumut samar
  (signifier jujur).
- Melunasi utang kanon: "MERAMBAT menuntut permukaan tertentu".

### B. JANGKAR BERDAMPAK (GDD §6.2)

- F menanam NODE TERLIHAT (bulb yang sama dengan node rumah) + denyut
  kelahiran di avatar.
- Aura node: regen 2x dalam radius node (rumah maupun tanaman).
- Node tetap mahal (JANGKAR_BIAYA) — dampak yang terasa membuat
  harganya jadi keputusan. Fast travel = jatah fase berikutnya.

### C. MUSUH PERTAMA: PEMANGKAS (GDD §14, Phase 5-6; MVP: satu, tanpa combat)

- Sprite: KARAKTER BARU (putusan pemilik 15 Agu: Regu Perawat lama
  tidak dipakai). ATURAN IDENTITAS (pemilik): tiap karakter musuh
  punya ciri khas SESUAI RUANGANNYA — Room 01 = ruang servis, maka
  musuhnya TEKNISI PERAWATAN GEDUNG (coverall kelabu, helm/headlamp,
  sabuk alat, alat pangkas menonjol di siluet). Kandidat digenerate
  dan dikurasi pemilik SEBELUM dianimasikan.
- ATURAN SKALA (pemilik): pemain moda LEPAS harus terlihat KECIL di
  samping manusia. Keputusan MVP: manusia 48 px = batas atas rentang
  CDD (manusia 32-48) = 1.5x sprite player, TANPA membesarkan layout;
  kalau kurang dramatis setelah dilihat, pembesaran ruangan dibahas
  sebagai keputusan terpisah (konsekuensi: seluruh layout ikut).
- Patroli lantai tengah; state IDLE -> PATROL -> DETECT -> KEJAR.
- Hanya melihat avatar moda LEPAS di ketinggian lantai (garis pandang
  grid) — MERAMBAT di jaringan = aman darinya: alasan merambat.
- Tertangkap = kuras energi besar + terpental. TANPA membunuh instan.
- MEMOTONG: gumpalan jejak & sel jaringan TUMBUHAN pemain yang
  dilewatinya dipangkas (jaringan benih tidak disentuh — rute dasar
  aman). Pertumbuhan pemain jadi sesuatu yang bisa HILANG.

### D. TUJUAN RUANGAN (SRD §19, GDD §34)

- Penanda TUJUAN di dinding kanan (bulb dorman) — menyala + kabar
  HUD saat dicapai lewat jaringan.
- Loop lengkap: pilih rute -> tumbuh/menyusup -> Pemangkas memangkas
  -> pilih ulang -> capai tujuan -> pulang (alasan-kembali: katup air).

## Sesudah RK-2

Playtest loop oleh pemilik. Bila menarik: lanjut Langkah 4 (grading
final + sensor menyala) lalu Langkah 5 (lipat kanon, buang RK & RK-2).
