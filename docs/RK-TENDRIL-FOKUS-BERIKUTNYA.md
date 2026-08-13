# RK-TENDRIL — RENCANA KERJA FOKUS BERIKUTNYA

**Status: RENCANA KERJA, BUKAN KANON.**
Dokumen ini **tidak** masuk daftar sumber kebenaran di CLAUDE.md.
Buang setelah Langkah 5 selesai. Kalau ada keputusan di sini yang terbukti
benar, lipat ke GDD atau SRD, jangan biarkan dokumen ini hidup sebagai
kanon kesebelas.

Alasan aturan ini ada: untuk satu ruangan yang sama sudah lahir empat
dokumen berurutan (RAD → ECR → EDV2 → EDV3). Tiap dokumen memperbaiki
masalah yang disebutnya, jadi ini bukan pemborosan. Tapi polanya sama
dengan 13 dokumen era Menjalar yang akhirnya dihapus karena membuat
produksi bercabang.

Tanggal: 14 Agustus 2026

---

## DIAGNOSA SATU KALIMAT

> Ruang 01 dirancang untuk tiga keputusan, tapi saat ini hanya
> menyediakan **satu sumbu biaya** (energi), sehingga tiga rute runtuh
> menjadi satu. Ini bukan masalah art.

Konsekuensinya bisa diprediksi tanpa playtest:

- Energi longgar → rute LANTAI (cepat) mendominasi. Merayap tidak ada untungnya.
- Energi ketat → rute JARINGAN mendominasi. Lantai jadi jebakan.

Dua-duanya menghasilkan hal yang sama: pilihan rute bukan pilihan.
Sumbu kedua yang hilang adalah **stealth**.

---

## KEPUTUSAN YANG DIMINTA DARI PEMILIK PROYEK

Ada satu urutan yang tidak bisa saya putuskan sendiri, karena CLAUDE.md
melarang mengarang arah.

**Aturan Emas GDD §42** menaruh FEEL tepat sesudah MOVEMENT, sebelum
NETWORK dan STEALTH. **SRD §33** menaruh Pixel Art paling akhir, sesudah
Stealth. Keduanya sedang dilanggar sekarang: utang FEEL belum dibayar,
Stealth belum ada, tapi pixel art sudah jalan.

Dua opsi, pilih satu:

| Opsi | Urutan | Kapan dipilih |
| --- | --- | --- |
| **A (rekomendasi)** | FEEL dulu (1-2 sesi), lalu STEALTH | Kalau ingin menutup pelanggaran urutan dan utang animasinya kecil serta terbatas |
| **B** | STEALTH dulu, FEEL menyusul | Kalau rasa tidak-puas terhadap map itu yang paling mengganggu dan ingin cepat tahu penyebabnya |

Saya condong ke **A**: utang FEEL bounded (tiga pass animasi), murah, dan
menutup pelanggaran §42 tanpa menunda stealth lama. Tapi kalau yang
paling mengganggu adalah "map-nya belum memuaskan", **B** menjawab itu
lebih cepat, karena stealth-lah yang membuat gelap punya pekerjaan.

Sisa dokumen ini ditulis dalam urutan **A**. Untuk **B**, tukar Langkah 2
dengan Langkah 3.

---

## LANGKAH 0 — KEBERSIHAN DOKUMEN (30 menit, sekali)

Bukan pekerjaan game, tapi ini yang menurunkan biaya tiap sesi berikutnya.

Empat dari sebelas dokumen kanon sudah ditimpa sebagian tapi masih
terdaftar sebagai sumber kebenaran setara:

- `MDS-TENDRIL-GERAK.md` — ditimpa istilahnya oleh OLR
- `EDV2-TENDRIL-ARSITEKTUR-MODULAR.md` — ditimpa operasional oleh EDV3
- `ECR-TENDRIL-ROOM01-KOHESI.md` — digantikan pipeline EDV3
- `RAD-TENDRIL-RUANG-SERVIS.md` — sebagian ditimpa EDV3

**Kerjakan:** tambahkan satu baris `> HISTORIS — ditimpa oleh <X>` di
kepala masing-masing, dan pindahkan ke bagian "sejarah" di CLAUDE.md.
Jangan dihapus (ada alasan desain di dalamnya), cukup turunkan statusnya.

**DOD:** daftar sumber kebenaran aktif turun dari 11 ke 7.

---

## LANGKAH 1 — LUNASI UTANG FEEL (1-2 sesi)

Semua sudah tercatat, tidak satu pun dibayar, dan menua tiap sesi.

| Utang | Catatan playtest |
| --- | --- |
| Lompat | Belum terasa effort/impact, butuh pose lebih ekstrem |
| Jatuh | KURANG membungkuk, belum terkesan menerima impact |
| Crawl | Masih sedikit menggulung (lulus dengan utang, 12 Agu) |

Aturan yang berlaku: pemilik sudah bilang **jangan reroll tanpa diminta**.
Ini adalah "diminta". Pass animasi ini yang diantre.

Yang **tidak** dikerjakan di langkah ini: idle/detach/attach masih boleh
pakai master pra-refine (sengaja, menunggu §21), merambat belum perlu
berbahasa OLR.

**DOD:** lompat terbaca sebagai usaha, mendarat terbaca sebagai menerima
beban. Uji dengan mata, bukan dengan asersi.

---

## LANGKAH 2 — SENSOR JADI NYATA (2-3 sesi) — INTI

Ini langkah dengan rasio hasil-per-usaha tertinggi di seluruh papan.
Semua bahannya sudah ada: sprite sensor, posisinya di Ruang01, dan
`render/Ruang01View.gd` sudah menggambarnya di depan jaringan. Yang
belum ada hanya logikanya.

### 2a. Tiga state deteksi (SRD §13)

Implementasi paling kecil yang bekerja:

```
TIDAK TERLIHAT  — default
CURIGA          — avatar di dalam jangkauan sensor, tapi tersamar
                   (di jaringan tersembunyi / di celah / di balik massa)
TERDETEKSI      — avatar di dalam jangkauan sensor, terbuka
```

Warnanya sudah kanon, jangan mengarang: **CDD §7 warna status, kuning =
terdeteksi**. Pakai itu. Merah dicadangkan untuk "diburu" (Phase 6).

Jangkauan sensor dihitung di grid, sejalan dengan keputusan "tabrakan
dihitung sendiri di grid tanpa physics engine" yang sudah terbukti.

### 2b. Konsekuensi termurah yang membuat sumbu kedua nyata

**Jangan bikin musuh.** Pemangkas/Teknisi itu Phase 6, dan menariknya
maju akan mengulangi kesalahan yang sama persis.

Konsekuensi yang cukup dan murah, pilih satu:

- TERDETEKSI → laju kuras energi naik (mis. 2x) selama masih terdeteksi
- TERDETEKSI → lampu ruangan berubah, dan jaringan berhenti memulihkan energi

Yang kedua lebih menarik secara desain, karena menyerang **tepat** hal
yang membuat jaringan berharga. Tapi yang pertama lebih cepat dibangun.

**DOD Langkah 2:** berjalan lewat rute LANTAI memicu kuning; merayap
lewat rute JARINGAN plafon tidak; merayap lewat koridor drain (RAHASIA)
tidak, walaupun melewati jangkauan sensor.

Kalau DOD ketiga gagal, artinya rute rahasia belum punya nilai, dan
itu bug desain yang lebih penting daripada apa pun di daftar ini.

---

## LANGKAH 3 — PLAYTEST TIGA RUTE (1 sesi) — GERBANG

Mainkan Ruang 01 tiga kali, satu kali per rute (SRD §19).

Satu pertanyaan saja:

> **Apakah memilih rute terasa seperti keputusan?**

| Hasil | Artinya | Tindakan |
| --- | --- | --- |
| Ada rute yang selalu menang | Dominant strategy | **Tuning angka**, bukan tambah fitur. Geser laju kuras energi atau jangkauan sensor |
| Semua rute terasa sama | Sumbu keduanya belum menggigit | Naikkan konsekuensi deteksi, jangan tambah rute keempat |
| Terasa memilih | Lolos | Lanjut Langkah 4 |

Gerbang keras: **jangan lanjut ke Langkah 4 sebelum ini lolos.**
Kalau ruangannya belum jadi keputusan, memoles gambarnya tidak akan
membuatnya jadi keputusan.

---

## LANGKAH 4 — BARU GRADING FINAL ART (1 sesi)

Bekukan semua keputusan grading sampai titik ini. Alasannya:

Di game dengan ancaman, gelap adalah **tugas mekanik** stealth, gelap
punya pekerjaan. Di game tanpa ancaman, gelap hanya menyulitkan
penglihatan tanpa imbalan. Sekarang belum ada ancaman, jadi grading
sedang dinilai dalam kondisi di mana gelap belum bisa membayar dirinya
sendiri. Kalau diterangkan sekarang lalu stealth masuk, akan digelapkan
lagi.

Catatan yang sudah ada di CLAUDE.md ("nilai FINAL harus in-game,
CanvasModulate+lampu mengubah bacaan") diperluas satu langkah:

> Nilai final harus in-game **dengan sensor menyala.**

**Satu pengecualian yang tidak boleh ditunda:** permukaan yang bisa
dipijak wajib terbaca sebagai bisa dipijak. Itu signifier, kategorinya
kecelakaan, bukan mood, jadi tidak ada argumen atmosfer yang membelanya.
Aturan praktisnya: luminance permukaan pijak minimal 2x dinding tepat di
belakangnya. Kalau setelah CanvasModulate+lampu masih di bawah itu,
naikkan lo pita beton di `gen_ruang01_v3.gd` sesuai catatan risiko yang
sudah ditulis.

Utang kit yang boleh dibayar di langkah ini kalau sempat: decal baru 1
dari 12, varian center tile belum 3.

---

## LANGKAH 5 — TUTUP DAN BUANG DOKUMEN INI

Lipat yang terbukti ke kanon:

- Angka tuning sensor & konsekuensi deteksi → GDD (atau SRD §13)
- Aturan "grading dinilai dengan sensor menyala" → EDV3 §9 sebagai gate ke-7
- Aturan luminance 2x permukaan-vs-dinding → EDV3 §3.1, menggantikan
  aturan "env ≤40%" yang ambigu dan sempat terbaca sebagai "gelapkan semua"

Lalu hapus file ini.

---

## YANG SENGAJA TIDAK ADA DI DAFTAR INI

Menahan diri di sini sama pentingnya dengan mengerjakan.

- **Musuh (Pemangkas/Teknisi).** Phase 6. Sprite basisnya sudah siap dan itu justru godaannya. Jangan.
- **Room 02 dan seterusnya.** Semua room lahir dari bahasa desain Room 01, dan bahasa itu belum selesai diuji.
- **Node sebagai objek, network destruction, fast travel.** Phase 3 sisa, menunggu.
- **Menempel permukaan dinding/plafon** (GDD §6.1). Nyata dan tercatat, tapi bukan penghalang untuk menguji tiga rute.
- **State machine formal** (CDD §37). Utang teknis, bukan utang desain. Bayar saat stealth memaksa state bertambah, bukan sebelumnya.
- **Palet avatar pindah ke CDD §7.** Kerjakan bareng Langkah 1 kalau file animasinya toh sedang disentuh, jangan jadi sesi sendiri.
- **Menerangkan ruangan.** Lihat Langkah 4.

---

## RINGKASAN SATU LAYAR

```
0  Kebersihan dokumen         30 menit   11 kanon → 7
1  Utang FEEL                 1-2 sesi   lompat / jatuh / crawl
2  Sensor jadi nyata          2-3 sesi   ← sumbu kedua, inti
3  Playtest tiga rute         1 sesi     ← GERBANG KERAS
4  Grading final art          1 sesi     dengan sensor menyala
5  Lipat ke kanon, buang RK   30 menit
```

Satu langkah per sesi, commit tiap langkah terverifikasi (GDD §41).

Kalau ragu skala, kecilkan (GDD §39).
