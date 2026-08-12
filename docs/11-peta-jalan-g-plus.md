# PETA JALAN G+ — dari prototipe yang benar ke game yang dimainkan orang

Disusun dari review jujur 12 Agustus 2026, setelah TAHAP A–F dan R1–R6
tuntas. Seluruh mekanik docs/06 sudah berdiri; dokumen ini TIDAK mengubah
satu pun pilarnya — ia menutup jarak antara "sistem yang benar" dan "game
yang orang mainkan dua jam".

Tiga temuan terbesar review, yang menjadi tulang urutan di bawah:

1. **Kepadatan keputusan per menit terlalu rendah** — pemain terlalu banyak
   menonton di antara detak kalender.
2. **Ekonomi mati setelah Babak I** — akuifer tercapai = air selesai
   selamanya, min(Air, Cahaya) berhenti jadi keputusan.
3. **Audio tidak ada** — untuk genre tenang, suara adalah separuh nyawa.

Aturan kerja tidak berubah: **satu tahap per sesi, verifikasi jalan, commit.**
Urutan disusun termurah-berdampak lebih dulu; tiap tahap berdiri sendiri dan
game harus tetap bisa dimainkan setelah tahap mana pun.

Catatan sumber daya: kuota PixelLab gratis sudah HABIS (40/40). Tahap yang
butuh aset baru ditandai — kerjakan dengan prosedural dulu, atau tunda
bagian asetnya sampai kuota pulih / upgrade.

---

## G1 — Kontrol waktu: jeda dan percepat 2×

**Keluhan yang dijawab:** review #1 (menonton garis memanjang pelan).

Game lambat tanpa kontrol waktu adalah keluhan review yang pasti datang.
Spasi = jeda (pindahkan bercabang ke klik-kanan saja), `1`/`2` = kecepatan
normal / 2× (kalikan `delta` simulasi di `main`, JANGAN sentuh `delta`
kamera dan animasi HUD). Indikator kecil di pita atas saat 2× aktif.

- Kartu fase tetap menjeda seperti biasa; 2× otomatis kembali normal saat
  hari perawatan dimulai (momen penting tidak boleh terlewat dipercepat).
- **Verifikasi:** satu siklus penuh dimainkan dengan 2×, semua event
  (inspeksi, regu, babak) tetap benar; jeda benar-benar membekukan simulasi
  tapi kamera tetap bisa digeser.

## G2 — Kata kerja aktif: tunas ulang & perkuat pangkal

**Keluhan yang dijawab:** review #1 (cuma ~3 kata kerja).

Dua alat baru, keduanya membelanjakan energi — supaya ekonomi juga punya
saluran keluar:

- **Tunas ulang**: klik-kanan di rambatan lama (peta `tutup`) menumbuhkan
  untai baru dari titik itu, biaya `COST_BRANCH` + premi. Menghidupkan
  kembali wilayah yang digergaji regu tanpa merayap ulang dari tanah.
- **Perkuat pangkal**: tombol pada untai terpilih — pangkalnya menebal
  (visual lewat `width_curve`), regu butuh 2× durasi gergaji. Biaya energi
  besar; jawaban proaktif terhadap jadwal perawatan selain memangkas diri.

- **Verifikasi:** dalam satu siang-malam pemain punya alasan menekan
  sesuatu minimal tiap ~15 detik; energi kembali terasa sebagai anggaran.

## G3 — Hukuman regu diperhalus: bangkai yang layu

**Keluhan yang dijawab:** review #3 (satu gergaji = dirampok).

Gergaji regu tidak melenyapkan bagian atas seketika: bagian itu jadi
**bangkai kering** — berhenti tumbuh, daunnya menguning (pakai varian layu
atlas / modulasi warna), dan tutupannya terkikis bertahap selama ~satu hari
sebelum hilang. Pemain yang sigap bisa "menyambung" dengan tunas ulang (G2)
sebelum bangkainya habis. Kerugian total sama, rasanya adil.

- Sulur dengan pangkal diperkuat (G2) butuh dua kunjungan gergaji.
- **Verifikasi:** kehilangan besar tetap terjadi tapi pemain melihat proses
  dan punya jendela merespons; tidak ada lagi lenyap-sekejap.

## G4 — Ekonomi tetap hidup: akuifer menyusut & musim kering

**Keluhan yang dijawab:** review #2 (air selesai selamanya).

- **Akuifer menyusut**: tiap akar yang menyedot mengurangi cadangan; sel
  akuifer yang terkuras berubah jadi tanah lembap lalu kering (visual petak
  ikut berubah). Dua akuifer = dua babak kehidupan air.
- **Musim kering**: event kalender yang DIUMUMKAN ("MUSIM KERING dalam 2
  hari — 3 hari") — selama itu tanah lembap dihitung kering, hanya akuifer
  yang memberi air. Kanal pengumuman sudah ada (kartu + pita kalender).

- **Verifikasi:** di babak II–III pemain masih sesekali harus mengurus air;
  bar leher botol berpindah-pindah lagi antara AIR dan CAHAYA.

## G5 — Babak III aktif: menanam pohon dengan sengaja

**Keluhan yang dijawab:** review #4 (menang = menunggu).

Menanam pohon jadi KEPUTUSAN: pada rambatan yang berdiri di puing, tombol
tanam mengubah untai itu jadi pohon — biayanya besar (energi + untai itu
berhenti jadi alat). Mekanik berakar-pasif yang sekarang tetap ada sebagai
jalan lambat, tapi pemain yang aktif menutup permainan lebih cepat dan
memilih SUSUNAN hutannya sendiri.

- **Verifikasi:** kemenangan terasa seperti rangkaian keputusan penempatan,
  bukan timer; posisi 4 pohon berbeda antar run.

## G6 — Eskalasi antar siklus

**Keluhan yang dijawab:** review #5 (siklus ke-2 identik dengan ke-6).

Kota makin peduli seiring hari: tiap ~4 hari, `AMBANG_RAWAT` turun sedikit,
regu menggergaji lebih cepat, dan mulai babak II pemanjat ikut datang untuk
zona BAWAH juga (bukan hanya ATAS). Semua diumumkan lewat kartu inspeksi
("pengelola menaikkan anggaran perawatan") — eskalasi pun tunduk pada pilar
"ancaman selalu diumumkan".

- **Verifikasi:** grafik tekanan naik antar siklus terasa; run 30 menit
  tidak pernah dua siklus yang identik rasanya.

## G7 — Pass audio

**Keluhan yang dijawab:** review #6 (separuh nyawa genre tenang).

Prioritas tertinggi di antara semua poles rasa. Minimum yang mengubah
segalanya: ambience siang (angin + kota jauh) dan malam (jangkrik), denyut
lembut saat daun lahir, gunting/gergaji regu (juga PERINGATAN audio bahwa
pemangkasan terjadi di luar layar!), gemeretak menembus beton, sting pendek
kartu fase, dan nada hangat saat pohon jadi. Sumber: freesound/jsfxr —
tidak butuh komposer untuk lolos standar "tenang".

- **Verifikasi:** main 5 menit tanpa melihat HUD — telinga saja cukup untuk
  tahu fase, kedatangan regu, dan pemangkasan.

## G8 — Kohesi visual & gerak

**Keluhan yang dijawab:** review #7 (dua bahasa visual; dunia diam).

- Daun bergoyang halus (offset sinus per daun di `DaunView` — murah).
- Parallax: siluet kota + langit di belakang fasad (`ParallaxBackground`
  atau dua layer digeser fraksi kamera).
- Ubin terrain & jendela dirapikan agar senada dengan aset organik —
  prosedural dulu (butuh PixelLab = tunggu kuota).
- Transisi malam bertahap beberapa detik (docs/08 §7, masih terbuka).

- **Verifikasi:** satu screenshot siang dan satu malam yang layak dipajang
  di halaman toko tanpa malu.

## G9 — Hari pertama yang dituntun

**Keluhan yang dijawab:** review #9 (semuanya dituang sekaligus).

Hari 1 dimulai dengan kamera terkunci ke bibit dan SATU tujuan di band:
"capai tanah lembap" → tercapai: "malam ini, rambati fasad" → hari 2 dunia
dan seluruh HUD terbuka. Implementasi kecil: flag `tutorial` di `main` yang
menahan pane kedua dan sebagian pita sampai tonggaknya lewat. Tanpa dinding
teks — tetap patuh aturan §6 Konteks.

- **Verifikasi:** orang yang belum pernah melihat game ini mencapai malam
  pertama tanpa bertanya.

## G10 — Variasi dunia

**Keluhan yang dijawab:** review #8 (nol nilai ulang-main).

Generator tata letak dari seed: posisi akuifer/batu/humus/utilitas diacak
dalam aturan (akuifer selalu di balik beton, celah aman selalu di SEED_X),
jendela & ledge fasad bervariasi. Seed ditampilkan di layar judul.
Terakhir karena semua tuning di atasnya harus stabil dulu.

- **Verifikasi:** dua run berturut menuntut rencana akar yang berbeda.

---

## Urutan ringkas

| Tahap | Inti | Biaya | Menjawab |
|---|---|---|---|
| G1 | jeda + 2× | kecil | #1 |
| G2 | tunas ulang + perkuat pangkal | sedang | #1 |
| G3 | bangkai layu, gergaji 2 kunjungan | sedang | #3 |
| G4 | akuifer menyusut + musim kering | sedang | #2 |
| G5 | tanam pohon sengaja | kecil | #4 |
| G6 | eskalasi antar siklus | kecil | #5 |
| G7 | pass audio | sedang | #6 |
| G8 | goyang daun, parallax, ubin senada | sedang* | #7 |
| G9 | hari pertama dituntun | sedang | #9 |
| G10 | generator tata letak + seed | besar | #8 |

*sebagian menunggu kuota PixelLab.

G1–G3 adalah satu paket "game-nya jadi enak dipegang"; G4–G6 paket
"tetap menarik sampai menit 30"; G7–G9 paket "layak untuk orang asing";
G10 paket "dimainkan lagi". Selesai G9, game ini pantas diberi nama versi
dan dicoba orang di luar ruangan ini.
