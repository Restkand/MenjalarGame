# PROMPT CLAUDE CODE — Pivot ke Pembongkaran

Panduan urutan kerja untuk mengubah Menjalar dari stealth-coverage menjadi
game pembongkaran struktural.

---

## Aturan main sebelum mulai

**Satu prompt, satu langkah.** Jangan gabungkan dua tahap. Kode yang berubah di
lima file sekaligus tidak bisa kamu verifikasi, dan kalau ada yang rusak kamu
tidak tahu bagian mana.

**Commit setiap kali satu tahap jalan.** Ini yang membuat eksperimen jadi murah:

```
git add .
git commit -m "tahap 2: rangka struktural di WorldMap"
```

**Minta rencana dulu untuk perubahan besar.** Tambahkan kalimat ini di akhir
prompt: *"Sebutkan rencanamu dalam 3-5 kalimat dan tunggu persetujuanku sebelum
menulis kode."* Kamu akan menangkap salah paham sebelum ada 200 baris yang
harus dibuang.

**Jalankan gamenya sendiri setiap tahap.** Claude Code tidak bisa membuka Godot.
Kalau ada error, salin pesan errornya persis — termasuk nomor baris.

---

## TAHAP 0 — Pasang konteks permanen

Sekali saja. Setelah ini kamu tidak perlu menjelaskan ulang tiap sesi.

```
Buat file CLAUDE.md di akar proyek. Isinya harus mencakup:

- Godot 3.5.3 stable, GLES2, GDScript. BUKAN Godot 4 — API berbeda.
- Target hardware: PC lawas, Intel HD Graphics, OpenGL 2.1.
- Batasan keras: tanpa shader, tanpa Light2D, tanpa physics engine,
  draw call minimal.
- Render lewat Image + ImageTexture, bukan _draw(). Image.lock()/unlock()
  wajib sebelum set_pixel. Pakai texture.set_data(img) tiap frame, jangan
  buat ImageTexture baru.
- Simulasi 240x160, skala 4x lewat Sprite.scale.
- Simulasi pakai float, pembulatan hanya saat render.
- Semua input mouse/keyboard HANYA di main.gd.
- Config.gd hanya var & const, nol fungsi.

Lalu baca docs/04-status-proyek.md dan salin isi tabel §9 (bug yang sudah
diperbaiki) ke dalam CLAUDE.md sebagai bagian "Jangan diulang".

Terakhir tambahkan bagian "Arah saat ini": proyek bergeser dari stealth-coverage
ke pembongkaran struktural. Detail di docs/06-desain-pembongkaran.md.
```

Setelah itu, salin keempat dokumen `.md` kamu ke folder `docs/` kalau belum.

---

## TAHAP 1 — Orientasi

Jangan lewati ini. Tujuannya memastikan Claude Code benar-benar membaca kodemu,
bukan menebak.

```
Baca scripts/WorldMap.gd, scripts/Strand.gd, scripts/TreeSim.gd, dan
scripts/Config.gd.

Jelaskan padaku:
1. Bagaimana WorldMap.grid dibangun dan enum terrain apa saja yang ada
2. Bagaimana Strand mendeteksi tabrakan dan melakukan tigmotropisme
3. Di mana persisnya energi ditambah dan dikurangi

Jangan ubah apa pun. Aku hanya ingin tahu kamu membaca kode yang benar.
```

Kalau jawabannya melenceng dari yang kamu tahu, hentikan dan perbaiki
konteksnya dulu. Melanjutkan di atas pemahaman yang salah cuma membuang waktu.

---

## TAHAP 2 — Rangka struktural (data saja)

Belum ada keruntuhan. Cuma struktur data dan cara melihatnya.

```
Tambahkan sistem rangka struktural ke WorldMap.gd.

Gedung berhenti jadi persegi panjang solid. Dia jadi kumpulan "member":
kolom vertikal dan balok horizontal, dengan sambungan (joint) di titik temu.

Struktur data:
- member: { id, x0, y0, x1, y1, tipe (KOLOM/BALOK), integritas 0.0-1.0,
  beban 0.0, member_bawah (array id) }
- joint: { id, x, y, member_terhubung (array id), integritas 0.0-1.0 }

Buat tata letak hardcoded untuk satu gedung: 4 kolom vertikal dengan jarak
merata di dalam FACADE_X0..FACADE_X1, dan 5 balok horizontal yang
menghubungkannya. Joint di setiap perpotongan.

Grid terrain yang sudah ada tetap dipertahankan apa adanya — member adalah
lapisan data tambahan di atasnya, bukan pengganti.

Tambahkan mode debug: tahan tombol B untuk menggambar member sebagai garis di
lapisan overlay, dengan warna berdasarkan integritas (hijau penuh ke merah).
Ingat, input hanya boleh ditulis di main.gd.

Belum ada perhitungan beban dan belum ada keruntuhan. Tahap ini hanya struktur
data plus cara melihatnya.
```

**Verifikasi:** jalankan, tahan B, pastikan rangkanya terlihat masuk akal dan
sejajar dengan fasad yang digambar.

---

## TAHAP 3 — Aliran beban dan keruntuhan

Ini jantungnya. Kerjakan sampai benar sebelum lanjut.

```
Tambahkan perhitungan beban dan keruntuhan berantai ke sistem member.

Aturan beban:
- Setiap member punya berat dasar
- Beban mengalir dari atas ke bawah lewat member_bawah, dibagi rata ke
  semua penopang yang masih hidup
- Kapasitas member = integritas * KAPASITAS_MAX
- Kalau beban > kapasitas, member gagal

Keruntuhan berantai:
- Saat satu member gagal, hitung ulang seluruh aliran beban
- Member yang sekarang kelebihan beban ikut gagal
- Ulangi sampai stabil, maksimal 20 iterasi per frame untuk keamanan
- Beri jeda 0.15 detik antar gagal berurutan supaya rantainya terlihat,
  bukan terjadi dalam satu frame

Saat member gagal:
- Hapus piksel member itu dari lapisan world
- Tambahkan ke daftar puing yang jatuh dengan gravitasi sederhana
- Puing berhenti saat menyentuh tanah atau tumpukan puing lain

Untuk tes, tambahkan sementara: klik kanan pada member saat mode debug (B)
aktif akan langsung menggagalkannya.

Perhitungan ulang beban hanya saat ada perubahan, jangan tiap frame.
```

**Verifikasi:** ini momen penentu. Gagalkan satu kolom bawah dan lihat apakah
seluruh sisi gedung turun. Kalau runtuhnya sudah membuat kamu ingin
mengulanginya, konsepnya benar. Kalau hambar, hentikan di sini dan kabari saya
sebelum membangun lebih jauh.

---

## TAHAP 4 — Juice

Runtuh yang benar secara logika tapi tidak terasa apa-apa adalah runtuh yang
gagal. Tahap ini murah dan dampaknya paling besar.

```
Tambahkan umpan balik visual untuk keruntuhan. Semua tanpa shader dan tanpa
physics engine.

1. Getaran layar: geser posisi Sprite 2-3 piksel acak selama 0.3 detik saat
   member gagal, meredam ke nol. Skalakan dengan ukuran member.
2. Debu: 20-40 piksel warna beton yang naik pelan lalu memudar, muncul di
   titik kegagalan. Gambar di lapisan overlay.
3. Jeda mikro: bekukan simulasi 0.08 detik tepat saat member pertama gagal
   dalam sebuah rantai. Ini membuat otak pemain mendaftarkan momennya.
4. Retakan menjalar: sebelum member gagal, gambar retakan yang tumbuh di
   sepanjang member sesuai integritas yang menurun.

Semua nilai di atas taruh di Config.gd supaya bisa disetel.
```

---

## TAHAP 5 — Sambungkan tanaman

Baru sekarang tanaman terhubung ke struktur.

```
Hubungkan pertumbuhan sulur dan akar ke sistem member.

- Saat ujung sulur berada dalam radius 3 piksel dari sebuah joint, joint itu
  mulai melemah: integritas turun dengan laju WEAKEN_RATE * delta
- Akar melakukan hal yang sama pada pondasi (member paling bawah)
- Melemahkan menguras energi, dengan laju yang sama seperti pertumbuhan biasa
- Integritas joint yang turun ikut menurunkan kapasitas member yang terhubung

Tambahkan tigmotropisme ke arah joint: kalau ada joint dalam radius 12 piksel,
ujung sulur sedikit condong ke sana. Batasi deviasi maksimal 15 derajat dari
arah yang diminta pemain, konsisten dengan prinsip di docs/02-logika-game.md §5.

HUD: ganti bar coverage dengan indikator integritas struktur keseluruhan.
```

---

## TAHAP 6 — Puing jadi tanah baru

```
Buat tumpukan puing bisa ditumbuhi.

- Puing yang sudah berhenti jatuh menjadi terrain baru di WorldMap.grid,
  dengan enum PUING
- Sulur bisa tumbuh di atas PUING seperti di fasad
- Akar bisa menembus PUING lebih cepat daripada beton utuh
- Bake ulang peta cahaya setelah tumpukan puing stabil, karena siluetnya
  berubah

Ini memungkinkan pemain naik lebih tinggi lewat reruntuhan yang dia jatuhkan
sendiri.
```

---

## TAHAP 7 — Tukang kebun jadi tim perbaikan

```
Ubah peran Warden.gd dari pengintai jadi tim perbaikan.

- Hapus sistem heat per-sulur dan pemangkasan saat fajar
- Warden sekarang mendeteksi member atau joint dengan integritas < 0.7 yang
  berada di area terang (pakai peta vis yang sudah ada)
- Dia berjalan ke lokasi itu dan memulihkan integritas dengan laju REPAIR_RATE
- Dia hanya bisa memperbaiki satu titik dalam satu waktu, dan mengutamakan
  yang integritasnya paling rendah
- Setelah satu gedung runtuh, tambah satu Warden

Ini mengubah tensinya dari sembunyi menjadi balapan. Area teduh tetap lebih
aman karena Warden lebih lambat menemukannya.
```

---

## TAHAP 8 — Struktur ronde

```
Ganti kondisi menang berbasis coverage 55% dengan struktur ronde.

- Satu ronde = satu gedung
- Menang saat seluruh member gedung gagal
- Kalah saat energi nol dan tidak ada ujung hidup yang bisa mencapai air
- Setelah menang, muat tata letak gedung berikutnya, lebih tinggi dan dengan
  satu Warden tambahan
- Simpan tata letak gedung sebagai data di Config.gd, bukan hardcoded di
  WorldMap.build(), supaya menambah gedung baru cukup menambah entri data

Target durasi satu ronde: 3-5 menit.
```

---

## Prompt untuk saat macet

**Ada error:**
```
Aku dapat error ini saat menjalankan game:

[tempel pesan error persis, termasuk nama file dan nomor baris]

Baca file yang disebut dan perbaiki. Jelaskan penyebabnya sebelum mengubah.
```

**Performa turun:**
```
FPS turun drastis saat [jelaskan kapan]. Target hardware Intel HD lawas.
Cari operasi per-piksel atau per-frame yang bisa di-cache atau dibatasi.
Jangan optimasi dengan menambah kompleksitas kalau bisa dengan membatasi
frekuensi.
```

**Hasilnya tidak sesuai bayangan:**
```
[Jelaskan yang kamu lihat, bukan yang kamu mau.]
Contoh: "Keruntuhannya terjadi terlalu cepat, semua member gagal dalam satu
frame sehingga tidak terlihat seperti rantai."

Perbaiki hanya bagian itu. Jangan sentuh yang lain.
```

**Ingin membatalkan seluruh tahap:**
```
git checkout -- .
```

---

## Yang jangan diminta

- Jangan minta refaktor besar bersamaan dengan fitur baru
- Jangan minta "buat gamenya lebih seru" — terlalu kabur, hasilnya akan
  berupa tumpukan fitur yang tidak kamu butuhkan
- Jangan minta aset visual atau sprite sekarang; mekanik dulu
- Jangan minta audio, menu, atau save sebelum Tahap 8 selesai
