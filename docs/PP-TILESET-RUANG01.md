# PP — PROMPT PACK TILESET RUANG 01 (untuk PixelLab Web / Mode Map)

**Status:** ALAT KERJA — BUKAN KANON. Dipakai pemilik proyek langsung di
aplikasi web PixelLab (fitur Map hanya ada di web, tidak di API).
Latar: tileset Room 01 sekarang dirasa pemilik kurang memuaskan; paket
ini = generasi ulang yang lebih terarah + bahan Mode Map.

---

## 1. ALUR PAKAI DI WEB

1. Buat TILESET dulu (menu tileset) memakai prompt di §3 — hasil
   tersimpan di akun dan BISA DIPILIH saat membuat Map.
2. Buat tileset secara BERANTAI (EDV3 §5): tileset pertama = MASTER;
   tileset berikutnya pilih opsi "gunakan tile yang ada sebagai
   dasar/referensi" (base tile) supaya semua material menyambung mulus.
3. Baru buka Mode Map dan rakit ruangan memakai tileset-tileset itu.
4. CATAT SEED setiap generasi yang lolos kurasi (tulis di file ini).
5. UNDUH hasil segera — hasil server bisa digusur cepat (pelajaran
   mahal 13 Agu).

**Catatan integrasi (penting, keputusan sadar):** ekspor Map editor
ditujukan ke template Phaser PixelLab, bukan Godot. Peta yang Anda rakit
di sana = papan komposisi/acuan visual; untuk masuk game perlu importer
khusus (dibahas terpisah bila Anda jatuh cinta pada editornya). Tileset
PNG-nya sendiri SELALU bisa diunduh dan masuk pipeline kita.

---

## 2. ATURAN YANG DIJAGA SAAT MENULIS/MEMILIH (EDV3)

- Prompt PENDEK 8–20 kata, konkret, TANPA abstraksi desain
  ("stealth game", "moody") — sebut benda dan sifat fisiknya.
- Palet acuan 18 warna EDV3 §3.1 (snap palet dilakukan pipeline kita
  setelah unduh — tapi makin dekat hasil mentah, makin bagus):
  STRUCTURE 0B0E12 12171D 1A2029 232B36 2E3846 3D4757 ·
  METAL 1B2128 2B333C 414B57 59636F · WEAR 3A3128 55452F ·
  AMBER 8A5A20 D89A3C · TENDRIL 3E7A32 6FBF3E A8E85C D6FF8F.
- Value: lingkungan ≤40% luminance; amber ≤63%; hijau TENDRIL selalu
  paling terang. Kalau hasil terlalu terang = tolak, reroll.
- Ukuran tile 32 px, detail rendah, shading datar-dasar (parameter
  terkunci EDV3 §3.2).
- Kurasi: uji sambungan (rapatkan 3×3 — tidak boleh ada jahitan), uji
  blur (bentuk besar tetap terbaca), uji grayscale (hirarki value).

---

## 3. PROMPT PACK — SIDESCROLLER (proyeksi game kita)

Urutan generate WAJIB berantai: A dulu, lalu B–E memakai A sebagai base.

### A. BETON DINDING — MASTER (pengganti beton sekarang)

```text
dark weathered concrete wall panels, hairline cracks, faint water
streaks, dusty seams, cold industrial corridor
```

Alternatif bila hasil terlalu polos:

```text
aged cast concrete wall, formwork lines, chipped corners, grime
buildup near edges
```

### B. BETON LANTAI (base: A)

```text
dark concrete floor slabs, worn walking path, thin expansion joints,
oil stains
```

### C. BAJA / MESIN (base: A)

```text
brushed dark steel plating, rivet seams, worn scratched edges,
industrial machine housing
```

### D. BETON LEMBAP / BERLUMUT (base: A — zona TUMBUH, GDD §12)

```text
damp concrete overgrown with dark wet moss patches, dripping water
stains, slick sheen
```

### E. BETON RETAK (base: A — zona TUMBUH)

```text
old fractured concrete, deep dark fissures, crumbling plaster
patches, exposed aggregate
```

### F. KAYU LAPUK (base: A — material SRD §10 yang belum ada)

```text
rotten wooden plank boards, warped grain, rusty nail heads, aged
service scaffolding
```

---

## 4. PROMPT PACK — TOPDOWN (khusus eksperimen Mode Map web)

Mode Map web memakai tileset topdown (terrain Wang). Pasangan
lower→upper berantai, transisi disebut eksplisit:

1. `lantai beton -> beton lembap`
   - lower: `dark concrete floor, drain stains, dusty seams`
   - upper: `wet mossy concrete, dark green moss patches`
   - transisi: `spreading damp stain with thin moss edge`
2. `beton lembap -> genangan air` (base: hasil #1)
   - upper: `shallow dark water puddle, faint ripples`
   - transisi: `wet concrete rim with drips`
3. `lantai beton -> baja mesin` (base: #1 lower)
   - upper: `dark riveted steel deck plate, worn tread pattern`
   - transisi: `bolted steel edge strip`
4. `lantai beton -> beton retak` (base: #1 lower)
   - upper: `cracked crumbling concrete, deep fissures`
   - transisi: `hairline cracks spreading`

---

## 5. SETELAH LOLOS KURASI ANDA

- Tulis seed + nama tileset yang lolos di bagian ini.
- Serahkan ke sesi produksi: unduh PNG → pipeline kita (iris, snap
  palet 18 warna, pita value, pasang ke renderer Wang Godot) — atau,
  bila Anda memutuskan pindah ke Mode Map penuh, kita jadwalkan
  importer ekspor-Map → Godot sebagai langkah arsitektur tersendiri.

**Seed lolos kurasi:** (belum ada — isi di sini)
