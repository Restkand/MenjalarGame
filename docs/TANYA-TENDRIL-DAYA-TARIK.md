# TANYA-TENDRIL — DAYA TARIK KESAN PERTAMA

> **Status: DOKUMEN KERJA, BUKAN KANON.** Berisi ringkasan kondisi game
> + pertanyaan desain untuk PEMILIK PROYEK. Jawaban pemilik dilipat ke
> GDD (dan SRD terkait), lalu dokumen ini DIBUANG — pola yang sama
> dengan RK/RK-2.
>
> Pemicu: playtest 3 + N tester — "konsepnya potensial, tapi kesan
> pertama membingungkan / kurang menarik."

Tanggal: 19 Agustus 2026

---

## 1. RINGKASAN GAME (untuk penguji baca 30 detik)

**TENDRIL** — *Grow. Hide. Survive.* Metroidvania 2D pixel art:
kamu adalah **ujung tumbuh termuda** dari organisme tanaman yang lepas
kendali di sebuah gedung. Dua moda satu tubuh: **MERAMBAT** di jaringan
sulur (cepat, aman, memulihkan energi, tak terlihat manusia) dan
**LEPAS** dari jaringan (platformer: rentan, energi terkikis — tapi
satu-satunya cara menjangkau tempat baru). Kamu **menumbuhkan jalanmu
sendiri** di material yang menerimanya, bersembunyi dari sensor dan
manusia, menyergap dari kegelapan, dan perlahan **mengubah gedung
menjadi tubuhmu**.

Fantasi puncaknya (GDD §44): *"Sekarang seluruh ruangan ini sudah
menjadi milik saya."*

---

## 2. KONDISI GAME SEKARANG (jujur, per 19 Agustus 2026)

**Yang sudah hidup dan teruji:**

- **2 ruangan**: Ruang 00 Lab Botani (kelahiran + tutorial 4 mekanik
  tanpa teks, 6 beat) → Room 01 Ruang Servis (vertical slice: tiga
  rute aman/cepat/rahasia, sensor bersiklus, Teknisi patroli).
- **Sistem inti lengkap**: dua moda + morph transisi; energi & ekonomi
  (regen hanya di jaringan, aura node ×2, minum di katup bocor);
  tumbuh = gerak, digerbangi material dilukis (lembap/retak/beton);
  jangkar F (hanya di jaringan); upacara mati & lahir ulang; jejak
  daun hidup-layu-rontok.
- **Stealth sampai membunuh**: TERSEMBUNYI/TERSAMAR/WASPADA/
  TERDETEKSI/DIBURU; kaget + ikon !/?; penyelidikan musuh; SERGAP
  SENYAP dari jaringan (hitstop, tubuh terseret, bangkai ditumbuhi
  simpul); eskalasi (pengganti datang mencari, mayat ditemukan =
  ruangan waspada permanen).
- **Bahasa visual**: palet terkunci, dual-grid, garis pijakan, rumpun
  sembunyi, gril drain, grading gelap + cahaya nyata, HUD minimal.

**Yang BELUM ada (dan terasa absen bagi tester):**

- **Audio: NOL.** Tanpa ambience, tanpa denyut, tanpa suara sergapan.
- **Musuh hanya 1 jenis**, ancaman pasif hanya sensor.
- **Kemampuan (Phase 7) belum satu pun** — belum ada "power-up moment".
- Belum ada peta, save, pintu/ruangan ke-3, cerita tersurat.
- Kesan pertama: lahir di lab yang **sunyi, gelap, lambat** — menit
  pertama belum menjual fantasi "aku organisme yang akan menguasai
  gedung ini".

---

## 3. DIAGNOSIS SAYA (kenapa "kurang menarik" di menit pertama)

1. **Janji fantasi datang terlambat.** Momen paling memikat game ini
   (ruangan MENGHIJAU di jalur yang kulalui; membunuh manusia dalam
   diam; mayat jadi taman) baru terasa 5–10 menit setelah mulai —
   tester berhenti sebelum sampai ke sana.
2. **Sunyi total.** Tanpa audio, gelap = mati, bukan mencekam. Separuh
   atmosfer horor kita belum lahir.
3. **Tempo datar di pembuka.** Lab mengajar dengan benar tapi tanpa
   *spectacle*: tidak ada momen "WAH" dalam 60 detik pertama.
4. **Tujuan tak terlihat.** Pemain tahu *cara* bergerak, tapi tidak
   pernah ditunjukkan *untuk apa* — tidak ada gambar besar yang
   memanggil ("keluar dari sini", "kuasai gedung").
5. **Reward density rendah.** Antara beat tutorial dan sergapan
   pertama, sedikit sekali "hadiah kecil" (penemuan, rahasia, respons
   dunia) yang menetes.

---

## 4. PERTANYAAN UNTUK PEMILIK — jawabannya masuk GDD

> Format: konteks singkat → pertanyaan → opsi/trade-off (+rekomendasi
> saya bila ada). Jawab langsung di bawah tiap nomor, sesingkat apa pun.

### A. 60 detik pertama

**A1.** Apa SATU gambar yang harus dilihat pemain di 60 detik pertama
supaya ia paham fantasi game ini? Kandidat:
- (a) Kelahiran sinematik: tabung induk PECAH, sulur ibu menyembur,
  kamera menyapu lab yang setengah dikuasai tanaman, baru kendali
  diserahkan;
- (b) Melihat organisme LAIN dari kejauhan (sulur raksasa bergerak di
  balik kaca) — "aku bagian dari sesuatu yang besar";
- (c) Langsung aksi: lab sudah runtuh, alarm menyala, tutorial berjalan
  di bawah tekanan.
- *Rekomendasi saya: (a) — murah (kamera + animasi tabung), menjual
  asal-usul, dan menjadikan tutorial "akibat" dari kelahiran.*

**A2.** Bolehkah kamera diambil dari pemain selama 5–8 detik untuk
membuka ruangan (pan singkat memperlihatkan tujuan/lorong keluar)?
GDD §26 saat ini hanya "follow player". Ini alat termurah untuk
"tujuan terlihat".

### B. Suara (lubang terbesar)

**B1.** Audio belum punya fase di GDD §41. Kapan ia naik prioritas —
sekarang (minimal: ambience gedung + 5 SFX inti: rambat, lompat,
sergap, alarm, detak jantung saat DIBURU), atau setelah Phase 7?
- *Rekomendasi saya: SEKARANG, versi minimal. Horor tanpa suara tidak
  horor; ini kemungkinan penyumbang terbesar "kurang menarik".*

**B2.** Identitas suara TENDRIL: organik basah (gesekan daun, denyut
getah) atau sunyi-senyap dengan dunia yang bersuara (pipa, listrik,
langkah)? Keheningan memang dibolehkan GDD §32 — tapi keheningan
TOTAL bukan pilihan sadar, melainkan kekosongan.

### C. Tujuan yang memanggil

**C1.** Untuk setiap ruangan, apa "poster tujuan"-nya — satu objek
terlihat sejak masuk yang membuat pemain berkata "aku mau ke SANA"?
(Room 01 punya bulb tujuan dorman — terlalu kecil? Perlu landmark
lebih besar seperti pintu besar terkunci sulur / lubang cahaya?)

**C2.** Perlukah META-TUJUAN terlihat sejak lab — misalnya peta gedung
pudar di dinding lab (poster evakuasi!) yang menampilkan seluruh
gedung, dengan posisi pemain di basement? Murah (satu prop), memberi
gambar besar, dan kanon dengan GDD §17.

### D. Tempo & kepadatan hadiah

**D1.** Berapa lama waktu yang Anda relakan untuk lab? Sekarang ±2-4
menit. Alternatif: lab dipangkas jadi 90 detik (beat digabung) supaya
pemain cepat sampai ke stealth-kill loop yang sudah terbukti menarik?

**D2.** Setuju menambah "rahasia kecil" bertebaran (1 per zona: tabung
utuh yang bisa dipecah SRD Lab §10, lubang ventilasi berisi genangan,
tulisan tangan peneliti) — hadiah menetes untuk penjelajah?

**D3.** Kill pertama: sekarang pemain BISA tidak pernah menemukan
sergapan. Haruskah desain MEMAKSA satu momen sergap-atau-mati di jalur
utama Room 01 (Teknisi berdiri menghalangi lorong sempit) supaya semua
pemain merasakan mekanik paling seru kita minimal sekali?

### E. Bahaya & drama

**E1.** Kapan pemain pertama kali merasa DIBURU? Sekarang bisa tidak
pernah (jika bermain rapi). Perlukah scripted moment: sensor pertama
kali menangkapmu memicu kejaran pendek yang dirancang selamat — supaya
pemain merasakan adrenalin + belajar konsekuensi dengan aman?

**E2.** Grow light lab sekarang hanya menolak regen. Cukup menggigitkah
untuk mengajar takut-cahaya? Opsi: di lab, terdeteksi ≥3 detik =
lengan sprinkler pestisida menyala (bahaya nyata pertama, kanon §14.4).

### F. Identitas yang membuat orang bercerita

**F1.** Satu kalimat yang Anda ingin tester ucapkan ke temannya setelah
10 menit main — apa persisnya? ("Gw jadi tanaman yang makan orang",
"Splinter Cell tapi kamu tumbuhan", "Gedungnya pelan-pelan jadi
hutan"?) Kalimat ini menentukan fitur mana yang dimajukan.

**F2.** Momen "gedung menjadi tubuhku" (§44) — perlukah versi mini di
Room 01: saat X% permukaan ditumbuhi, ruangan berubah state (lampu
redup ditelan daun, suara berubah, sensor mati tercekik sulur)?
Ini menunjukkan pilar §2.4 dalam satu ruangan, bukan menunggu gedung
penuh.

### G. Kontrol & keterbacaan (sisa keluhan tester)

**G1.** Tempel-sengaja W/S: dipertahankan (presisi) atau kembali
otomatis dengan toggle (aksesibilitas)? Tester baru sering tidak sadar
harus menekan W.

**G2.** Perlukah "lembar kendali" visual di dinding lab (poster
keselamatan kerja berisi ikon tombol — diegetic, tanpa UI)?

### H. Batas produksi

**H1.** Dari daftar E-F di atas, anggaran PixelLab bulan ini masih
±1900 generasi. Ada batas yang ingin Anda pasang?

**H2.** Urutan pengerjaan usulan saya (setelah jawaban Anda):
audio minimal (B1) → kelahiran sinematik + poster peta (A1, C2) →
kill wajib + kejaran scripted (D3, E1) → rahasia kecil (D2) →
state "ruangan milikku" (F2). Setuju / susun ulang?

---

## 5. JAWABAN PEMILIK (19 Agustus 2026) — SAH, siap dilipat ke GDD

- **A1 = (a)** Kelahiran sinematik: tabung pecah, sulur menyembur,
  kamera menyapu lab, baru kendali diserahkan. Tutorial = "akibat"
  pelarian awal.
- **A2 = YA.** Pan kamera 5–8 dtk ke lorong keluar/tujuan saat pemain
  pertama kali menginjak ruang terbuka — wajib untuk spatial awareness.
- **B1 = SEKARANG**, prioritas tertinggi sebelum Phase 7. Minimal:
  ambience gedung dingin + dengung mesin + 5 SFX inti (rambat, lompat,
  sergap, alarm, detak jantung DIBURU).
- **B2 = campuran organik×industrial**: basah/getah bergesekan logam
  dingin, kabel korslet, langkah bergemerincing di gril. Keheningan
  total HANYA saat pemain diam di tempat gelap.
- **C1**: landmark besar = Pipa Utama / Katup Evakuasi Utama terkunci
  gril tebal di ujung vertikal ruangan — "aku harus naik ke sana."
- **C2 = YA**: poster peta evakuasi pudar di dinding lab (diegetic map,
  posisi pemain di basement terbawah).
- **D1**: lab dipangkas ke ±90 detik, beat dipadatkan.
- **D2 = setuju penuh**: rahasia kecil bertebaran (tabung utuh pecah =
  energi instan, catatan peneliti robek).
- **D3 = wajib satu kali**: Teknisi pertama membelakangi pemain di
  jalur utama Room 01 dengan jeda skrip — hard tutorial sergap senyap.
- **E1 = YA (ringan)**: sensor pertama kali melihat → alarm + pintu
  menutup paksa → panik → merayap cepat → sembunyi di rumpun pertama.
  Mengajarkan DIBURU secara aman & dramatis.
- **E2 = YA**: grow light lab: terdeteksi terlalu lama → semprotan
  pestisida (damage ringan + melunturkan samaran).
- **F1 (kalimat target)**: *"Splinter Cell, tapi kamu adalah tanaman
  parasit yang merayap di langit-langit dan menelan penjaga satu per
  satu."*
- **F2 = YA (versi mini)**: Room 01 ≥60% ditumbuhi → lampu berkedip
  redup, dengung berubah getar organik, sensor zona mati tercekik.
- **G1**: W/S manual DIPERTAHANKAN + ikon tombol kecil transparan di
  dekat sulur pada titik sambung.
- **G2 = YA**: poster K3 korporat fiktif berisi ikon kendali
  (diegetic).
- **H1**: anggaran PixelLab difokuskan aset naratif pembuka + dasar.
- **H2 (urutan disetujui)**: (1) Audio minimal → (2) Kelahiran
  sinematik + poster peta → (3) Kill wajib + kejaran scripted →
  (4) Rahasia kecil + state "ruangan milikku".

## 6. CARA MEMAKAI DOKUMEN INI

1. ~~Pemilik menjawab~~ SELESAI — jawaban di §5.
2. Jawaban yang mengubah desain → pemilik lipat ke GDD/SRD (atau
   perintahkan amendemen).
3. Eksekusi sesuai urutan H2 — satu langkah per sesi, commit
   terverifikasi (GDD §41).
4. Dokumen dibuang setelah semua jawaban terlipat & langkah tuntas.
