# TENDRIL — RUANG 00: LAB BOTANI (KELAHIRAN / TUTORIAL)

> *Grow. Hide. Survive.*
> Ruangan pembuka: tempat kelahiran TENDRIL, tutorial empat mekanik
> inti tanpa teks.

**Status:** KANON AKTIF — putusan pemilik proyek 15 Agustus 2026.
**Asal:** dokumen pemilik `tendril-ruangan-01-lab.md` (ditulis sebagai
kandidat Room 01), diadaptasi menjadi RUANG 00 atas keputusan pemilik:
ukuran diciutkan mengikuti GDD §39, posisi menjadi ruang tersembunyi
bertetangga Room 01.
**Jadwal produksi:** SETELAH gerbang RK Langkah 3 (playtest tiga rute
Room 01) lolos. Ruang 00 tidak boleh mendahului bukti bahwa inti
stealth-nya seru.

---

## 0. POSISI DI DUNIA — SAMBUNGAN KE ROOM 01

Putusan pemilik: lab berada **berdampingan dengan ruang servis
(Room 01)** dan berstatus **ruang tersembunyi** — dari sisi Room 01 ia
hanya bisa dicapai melalui ruang servis/maintenance.

Alur permainan:

```text
RUANG 00 (LAB)                    ROOM 01 (SERVIS)
kelahiran & tutorial   ──lorong──>  vertical slice tiga rute
                        tersamar
```

- Pemain LAHIR di lab (`spawn_mother`), menjalani tutorial, lalu keluar
  lewat lorong di ujung kanan lab menuju Room 01.
- Dari sisi Room 01, mulut lorong itu TERSAMAR (kandidat: gril
  ventilasi `int_vent` atau ujung koridor drain rute rahasia SRD
  Room 01 §19) — pemain yang kembali menemukanya sebagai ruang
  rahasia.
- Penyesuaian pada SRD-TENDRIL-ROOM01 (§19/§38) menunggu tangan
  pemilik proyek — dokumen ini tidak mengubah kanon Room 01.

---

## 1. KONSEP RUANGAN

Pemain adalah **ujung sulur muda** yang baru melepaskan diri dari
jaringan induknya (CDD §2). Ruang 00 adalah **tempat kelahirannya**:
lab botani tempat jaringan induk dibudidayakan, lalu lepas kendali.

**Fungsi naratif:**

- Menjelaskan asal-usul pemain tanpa satu baris teks pun.
- Manusia yang menanam, dan manusia pula yang kehilangan kendali.
- Kontras visual: sisi kiri masih steril, sisi kanan dikuasai sulur.

**Fungsi mekanis** — empat mekanik inti diajarkan berurutan, tanpa
tutorial pop-up:

| Urutan | Mekanik | Cara diajarkan |
|---|---|---|
| 1 | MERAMBAT | Spawn di jaringan induk, hanya bisa bergerak di sulur |
| 2 | LEPAS | Celah tanpa jaringan yang harus dilompati |
| 3 | TUMBUHKAN JARINGAN | Trellis di seberang celah bisa ditumbuhi |
| 4 | STEALTH | Grow light menyinari koridor tengah, lewat di balik rak |

Prinsip: Ruang 00 BOLEH menjadi tutorial (berbeda dengan Room 01 yang
"bukan tutorial panjang", SRD Room 01 §1) — tapi tetap lewat
**cause → action → consequence**, bukan teks.

---

## 2. SKALA (DICIUTKAN — GDD §39)

Ukuran asli usulan 60×20 diciutkan atas mandat pemilik:

```text
LEBAR  : ±32 tile
TINGGI : ±14 tile
```

Selaras pita ukuran SRD Room 01 (24–32 × 14–18). Tiga zona
dipertahankan, proporsinya dipadatkan:

```text
[ ZONA A ]        [ ZONA B ]         [ ZONA C ]
Tabung Induk  ->  Koridor Terang  -> Lorong Keluar
(tile 0-9)        (tile 10-22)       (tile 23-32)

Organik, gelap    Steril, terang     Setengah dikuasai
Aman              Bahaya cahaya      Node simpan + keluar
```

---

## 3. PALET & ATURAN VISUAL

Palet bergeser dari ruang servis: lebih banyak kaca, cyan klinis, dan
hijau **budidaya** (rapi, dalam wadah) — bukan hijau liar.

| Peran | Warna | Catatan |
|---|---|---|
| Struktur | Abu baja gelap, putih steril | Dinding, lantai, meja |
| Cahaya lab | Cyan pucat | Monitor, kaca, cairan spesimen |
| Grow light | **Merah-muda hangat** | Satu-satunya warna hangat, sekaligus bahaya. CATATAN: JANGAN ungu — ungu = status RACUN (CDD §7). Nilai final menunggu grading |
| Jaringan pemain | Hijau limau menyala | Selalu elemen paling terang (aturan value EDV3 §3.1) |
| Kontaminasi | Hijau gelap kusam | Lumut; membedakan liar vs budidaya |

**Aturan produksi:** semua prompt di dokumen ini adalah REFERENSI
NIAT, gaya pra-EDV3. Saat produksi, tulis ulang lewat pipeline EDV3
(prompt pendek 8–20 kata §4, palet terkunci §3.1 + warna lab baru yang
disahkan pemilik, urutan berantai §5, QA gates §9).

---

## 4. ASSET LIST

### 4.1 Struktur Ruangan

| ID | Tile | Niat visual |
|---|---|---|
| `flr_ceramic` | Lantai keramik | keramik putih bersih, nat abu tipis, pantulan cyan samar |
| `flr_grate` | Lantai grate steril | grate baja di lantai putih, pendar hijau samar dari bawah |
| `wal_glass` | Dinding kaca | panel kaca berbingkai baja, refleksi cyan, siluet tanaman |
| `wal_panel` | Dinding panel steril | panel putih mulus, garis sambung tipis, lampu status cyan |
| `prp_bench` | Meja lab | tepi meja kerja baja, permukaan bersih, gagang laci |

### 4.2 Wadah Tanaman Percobaan

| ID | Tile | Niat visual |
|---|---|---|
| `spc_tube` | Tabung spesimen | silinder kaca cairan cyan, kecambah hijau melayang |
| `spc_broken` | Tabung pecah | kaca pecah, cairan tumpah, kecambah cokelat mati |
| `spc_rack` | Rak semai | rak hidroponik semai berbaris, strip grow light di atas |
| `spc_pot` | Pot spesimen | pot kecil berlabel, satu tunas limau menyala |
| `spc_incub` | Inkubator | ruang kaca tertutup, sulur menekan kaca dari dalam |
| `lgt_grow` | Grow light | bar lampu tumbuh di plafon (warna lihat §3) |

### 4.3 Jejak Eksperimen

| ID | Tile | Niat visual |
|---|---|---|
| `env_monitor` | Monitor | layar grafik pertumbuhan, pendar cyan, kedip statik |
| `env_board` | Papan tulis | diagram tanaman pudar, coretan catatan |
| `env_tube` | Selang nutrisi | selang transparan, cairan hijau mengalir |
| `env_tank` | Tangki nutrisi | tangki baja berjendela, cairan hijau kental, katup |
| `spawn_mother` | **Tabung induk** | tangki penahan retak, sulur induk menyembur keluar |

`spawn_mother` = **titik spawn** — jaringan induk yang pemain lepas
darinya.

### 4.4 Overlay Sulur

| ID | Tile | Niat visual |
|---|---|---|
| `vin_trellis` | Sulur budidaya | sulur rapi terlatih di kawat trellis, daun berjarak |
| `vin_wild` | Sulur lepas kendali | sulur liar menyembur dari tangki pecah |
| `vin_root` | Akar menembus lantai | akar menyala meretakkan keramik |
| `vin_moss` | Lumut kontaminasi | lumut gelap menjalar di panel steril |

### 4.5 Interaktif

| ID | Tile | Niat visual |
|---|---|---|
| `int_node` | Node jaringan | bola node limau menyala, save point |
| `int_sensor` | Sensor cahaya | sensor dinding lensa merah |
| `int_sprink` | Sprinkler | kepala sprinkler plafon |
| `int_valve` | Katup air | roda katup kuningan + pengukur tekanan |
| `int_door` | Lorong keluar | bukaan servis berbingkai baja menuju Room 01 (lihat §0) |
| `int_vent` | Ventilasi | gril ventilasi baja — kandidat mulut tersamar di sisi Room 01 |

---

## 5. ATURAN PERMUKAAN

Sisi steril menolak pertumbuhan, sisi organik menerimanya.

| Permukaan | Bisa ditumbuhi? | Kecepatan | Alasan desain |
|---|---|---|---|
| Trellis | Ya | Cepat | Dirancang untuk merambat |
| Tanah pot | Ya | Cepat | Media tumbuh |
| Retakan lantai | Ya | Sedang | Jalur alternatif tersembunyi |
| Panel steril | Ya | Lambat | Butuh usaha, boros energi |
| Kaca | **Tidak** | — | Licin dan steril; penghalang alami |
| Baja bersih | **Tidak** | — | Memaksa moda LEPAS |

Kaca sebagai permukaan mati = kunci teka-teki: pemain melihat tujuan
di balik kaca, tapi harus memutar. Tabel ini KOMPATIBEL dengan matriks
material SRD Room 01 §10 — bila diadopsi lebih dulu di Room 01,
gunakan semantik yang sama.

---

## 6. LAYOUT RUANGAN (SKALA BARU 32×14)

### Zona A — Tabung Induk (tile 0–9)

Zona aman. Pemain spawn dan belajar bergerak.

- `spawn_mother` di tile 1–4, tinggi 5 tile; sulur induk menjalar ke
  kanan.
- `vin_wild` menutupi dinding & lantai — jaringan penuh, bebas
  MERAMBAT.
- `spc_broken` berserakan: kegagalan eksperimen.
- Pencahayaan redup, dominan hijau. Tanpa ancaman.
- **Di tile 8 jaringan terputus** — celah 2 tile tanpa permukaan
  tumbuh. Satu-satunya jalan maju: LEPAS + lompat pertama.

### Zona B — Koridor Terang (tile 10–22)

Zona tekanan. Steril, terang, diawasi.

- Lantai `flr_ceramic`; `wal_glass` di latar menampakkan rak semai.
- Tiga `lgt_grow` membentuk kerucut cahaya di tile **11, 15, 19**.
- `int_sensor` di tile **16**, aktif hanya bila pemain dalam kerucut.
- Dua `spc_rack` di tile **13 dan 18** memberi bayangan — berhenti di
  baliknya = aman.
- `prp_bench` di tile 15–16 sebagai platform melompati kerucut tengah.

Pelajaran tanpa teks: diam di bayangan aman, bergerak di cahaya
bahaya.

### Zona C — Lorong Keluar (tile 23–32)

Zona teka-teki. Kembali setengah organik.

- `int_node` di tile **24** — titik simpan pertama permainan.
- `vin_trellis` naik vertikal di tile **26** menuju platform atas.
- `int_valve` di platform atas tile **28** — memutar katup
  mengaktifkan `int_sprink`.
- Sprinkler membasahi `wal_panel` di tile **30** → permukaan tumbuh
  cepat.
- Lorong keluar (`int_door`) di tile **31–32** → Room 01 (§0).

Teka-teki pertama: air membantu, bukan menghancurkan — menanam gagasan
sprinkler bermuka dua untuk ruangan-ruangan berikutnya.

---

## 7. ALUR TUTORIAL

| Beat | Lokasi (tile) | Yang dipelajari | Hukuman jika gagal |
|---|---|---|---|
| 1 | 1–7 | Merambat bebas di jaringan | Tidak ada |
| 2 | 8–9 | Lepas & lompat | Jatuh, kembali ke node induk |
| 3 | 10–13 | Energi terkikis saat lepas | Energi habis, respawn |
| 4 | 13–20 | Stealth: diam di bayangan | Terdeteksi, alarm |
| 5 | 24 | Node = titik simpan | Tidak ada |
| 6 | 26–30 | Tumbuh di permukaan basah | Buang energi di permukaan salah |

---

## 8. URUTAN PRODUKSI ASSET

1. **Tileset dasar** (Wang, dirantai dari MASTER_ID beton Room 01 bila
   memungkinkan — EDV3 §5) — kerangka dulu.
2. **Struktur** (`flr_*`, `wal_*`) — cukup untuk blockout main-able.
3. **Props spesimen** (`spc_*`) — identitas lab; via INPAINTING di
   scene (EDV3 §5).
4. **Overlay sulur** (`vin_*`) — latar transparan, ditumpuk.
5. **Interaktif** (`int_*`) — terakhir; butuh state ganda:

| Tile | Varian |
|---|---|
| `int_node` | Redup / menyala |
| `int_door` | Tersegel / terbuka |
| `int_sprink` | Diam / menyemprot |
| `lgt_grow` | Menyala / padam |
| `int_sensor` | Siaga / mendeteksi |

---

## 9. SUSUNAN LAYER

```text
1. background   — kaca, siluet rak, kedalaman
2. solid        — lantai, dinding, platform (collision)
3. props        — meja, tabung, rak, tangki
4. network      — sulur & trellis (permukaan tumbuh)
5. interactive  — node, sensor, katup, lorong
6. lighting     — kerucut grow light, glow (additive)
7. player       — sprite TENDRIL
```

Lighting additive supaya kerucut terasa menembus dan hijau pemain
tetap paling terang (aturan value EDV3 §3.1).

---

## 10. CATATAN TERBUKA (dari pemilik, belum diputuskan)

- Tabung induk mati setelah pemain pergi, atau jadi node permanen?
- Berapa lama permukaan basah bertahan sebelum kering?
- Sensor Zona B memanggil musuh, atau mengunci lorong keluar?
- Perlukah satu tabung spesimen utuh yang bisa dipecah sebagai jalan
  pintas opsional?
- Warna final grow light (lihat §3 — jangan ungu racun).
