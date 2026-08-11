# PROMPT ASET R1 — satu PNG, satu prompt

Setiap bagian di bawah = satu file PNG. Salin blok prompt-nya utuh, tempel ke
PixelLab, minta ukuran PERSIS seperti tertulis. Tidak perlu membaca yang lain.

Cara pakai:

1. Kerjakan berurutan dari №1. Begitu №1 (`sulur_batang.png`) diterima,
   **jadikan ia reference image untuk semua prompt berikutnya** — ini yang
   menjaga 12 aset tetap satu gaya.
2. Hanya №1 dan №2 yang WAJIB untuk R1. Sisanya untuk R3–R6; pesan sekarang
   hanya supaya gayanya seragam.
3. Simpan ke `res://aset/` dengan nama file persis seperti judulnya.
   Import preset **2D Pixel**: Filter OFF, Mipmaps OFF.
4. Kalau hasilnya 2× lebih besar, kecilkan dengan nearest-neighbor. Jangan
   pernah menerima ukuran yang salah.

Checklist tolak/terima ada di bagian paling bawah.

Terakhir diperbarui: 11 Agustus 2026

---

## 1. `sulur_batang.png` — 32×8 — WAJIB R1

Tekstur batang sulur untuk `Line2D`. Diulang memanjang dan ditekuk, jadi harus
mulus kiri-kanan dan tenang.

```
horizontal vine stem texture strip, 32x8 pixel art, seamlessly tileable
left-to-right only, side view. Simple 3-band shading: bright highlight row
along the TOP edge, mid-tone body, single dark outline row along the BOTTOM
edge. Light source from upper-left. Woody green-brown vine colors anchored to
#7A5C3A (body) #A87B4E (warm highlight) #3A3A36 (outline), with a few subtle
#5EC24A green flecks suggesting living tissue. No leaves, no branches, no
background (fully opaque strip). Low detail, calm and readable — this texture
will be tiled and bent along a curved line, so avoid busy patterns that would
reveal repetition. No anti-aliasing halo on the outline.
```

---

## 2. `akar_batang.png` — 32×8 — WAJIB R1

Tekstur batang akar untuk `Line2D`. Tanpa hijau — akar hidup di bawah tanah.

```
horizontal root stem texture strip, 32x8 pixel art, seamlessly tileable
left-to-right only, side view. Simple 3-band shading: soft highlight row along
the TOP edge, mid-tone body, single dark outline row along the BOTTOM edge.
Light source from upper-left. Dry earthy root colors anchored to #A87B4E
(body) #C79A6B (highlight) #7A5C3A (shadow) #3A3A36 (outline). Absolutely no
green — this is an underground root with no foliage. A few short horizontal
bark cracks, nothing busy. Fully opaque strip, no background. This texture
will be tiled and bent along a curved line, keep it calm. No anti-aliasing
halo on the outline.
```

---

## 3. `daun_1.png` — 24×24

Daun varian 1: bentuk hati.

```
single vine leaf sprite, 24x24 pixel art, transparent background, side view.
Heart-shaped leaf with one center vein, tip pointing to the upper-right.
Saturated living green — the ONLY saturated color in this game's grey
desaturated city — anchored to #5EC24A (body) #B8E986 (lit side) #7A5C3A
(short stem and underside shadow). Light source from upper-left: lit side on
the upper-left, shadow on the lower-right. Single dark outline #3A3A36 with
no anti-aliasing halo. No branch, no flowers, no background elements.
```

---

## 4. `daun_2.png` — 24×24

Daun varian 2: oval meruncing.

```
single vine leaf sprite, 24x24 pixel art, transparent background, side view.
Slender pointed oval leaf with one center vein, tip pointing to the
upper-left, slight natural curve in the blade. Saturated living green — the
ONLY saturated color in this game's grey desaturated city — anchored to
#5EC24A (body) #B8E986 (lit side) #7A5C3A (short stem and underside shadow).
Light source from upper-left: lit side on the upper-left, shadow on the
lower-right. Single dark outline #3A3A36 with no anti-aliasing halo. No
branch, no flowers, no background elements.
```

---

## 5. `daun_3.png` — 24×24

Daun varian 3: bulat kecil berpasangan.

```
pair of small round vine leaves on one tiny stem, 24x24 pixel art, transparent
background, side view. Two small round leaves growing from a single short
#7A5C3A stem, one leaf slightly higher than the other. Saturated living
green — the ONLY saturated color in this game's grey desaturated city —
anchored to #5EC24A (body) #B8E986 (lit side). Light source from upper-left:
lit side on the upper-left, shadow on the lower-right. Single dark outline
#3A3A36 with no anti-aliasing halo. No branch, no flowers, no background
elements.
```

---

## 6. `daun_4.png` — 24×24

Daun varian 4: tetes air menunduk.

```
single drooping vine leaf sprite, 24x24 pixel art, transparent background,
side view. Teardrop-shaped leaf hanging downward from a tiny curved #7A5C3A
stem, tip pointing to the lower-right, gentle bend in the blade. Saturated
living green — the ONLY saturated color in this game's grey desaturated
city — anchored to #5EC24A (body) #B8E986 (lit side). Light source from
upper-left: lit side on the upper-left, shadow on the lower-right. Single
dark outline #3A3A36 with no anti-aliasing halo. No branch, no flowers, no
background elements.
```

---

## 7. `daun_layu_1.png` — 24×24

Layu tahap 1: mulai menguning.

```
single wilting vine leaf sprite, 24x24 pixel art, transparent background,
side view. Heart-shaped leaf with one center vein, edges beginning to curl,
tip drooping slightly downward. Dull fading yellow-green colors anchored to
#8FA84E (body) #A8B86E (remaining lit side) #7A5C3A (stem and curled edges).
Clearly less saturated than a healthy leaf — this plant is starting to dry
out. Light source from upper-left. Single dark outline #3A3A36 with no
anti-aliasing halo. No branch, no flowers, no background elements.
```

---

## 8. `daun_layu_2.png` — 24×24

Layu tahap 2: kering cokelat.

```
single dried dead vine leaf sprite, 24x24 pixel art, transparent background,
side view. Heart-shaped leaf silhouette, strongly curled and drooping
downward, brittle edges. Dry brown colors anchored to #7A5C3A (body) #A87B4E
(dry patches) #5C4433 (deep shadow). No green remains anywhere — this leaf
is completely dead. Light source from upper-left. Single dark outline
#3A3A36 with no anti-aliasing halo. No branch, no flowers, no background
elements.
```

---

## 9. `ujung_tumbuh_1.png` — 16×16

Denyut ujung, bingkai 1 (terang).

```
glowing vine growing tip, 16x16 pixel art, transparent background, side view.
A tiny coiled sprout shape: bright tender bud in #B8E986 sitting on a small
#5EC24A base. This is deliberately the most luminous, eye-catching object in
the whole game — small but glowing. Light source from upper-left. Single dark
outline #3A3A36 with no anti-aliasing halo. No leaves, no background elements.
```

---

## 10. `ujung_tumbuh_2.png` — 16×16

Denyut ujung, bingkai 2 (redup). Silhouette harus SAMA dengan №9 — pakai №9
sebagai reference image dan minta hanya warnanya ditukar.

```
glowing vine growing tip, 16x16 pixel art, transparent background, side view.
Exactly the same tiny coiled sprout silhouette as the reference image, but
with the two greens swapped: bud in #5EC24A, rim highlight in #B8E986. This
is frame 2 of a slow two-frame pulse animation, so only the colors may differ
from the reference — not the shape. Light source from upper-left. Single dark
outline #3A3A36 with no anti-aliasing halo. No leaves, no background elements.
```

---

## 11. `tunas.png` — 16×16

Tunas — penanda "tanaman baru mulai di sini".

```
small vine sprout, 16x16 pixel art, transparent background, side view.
A short upright #7A5C3A stem with two tiny #5EC24A leaves, one on each side,
and a #B8E986 bright tip at the top, growing upward from the bottom edge.
Saturated living green — the ONLY saturated color in this game's grey
desaturated city. Reads clearly at a glance as "a new plant starting here".
Light source from upper-left. Single dark outline #3A3A36 with no
anti-aliasing halo. No soil, no pot, no background elements.
```

---

## 12. `pohon_pangkal.png` — 96×128

Pohon muda di kaki gedung — titik awal permainan. Untuk R1 masih opsional
(pohon masih digambar prosedural), tapi paling murah dipesan selagi satu sesi.

```
small young tree, 96x128 pixel art, transparent background, side view.
Slender trunk anchored to #7A5C3A with #A87B4E bark highlight on the left
side, round slightly asymmetric foliage crown in saturated #5EC24A with
#B8E986 lit leaf clusters on the upper-left. The ONLY saturated color in
this game's grey desaturated city — the tree should feel alive, calm and
hopeful. Light source from upper-left. Single dark outline #3A3A36 with no
anti-aliasing halo. No fruit, no flowers, no ground, no background elements.
```

---

## Checklist tolak/terima

Tolak dan generate ulang kalau salah satu gagal:

- [ ] **Ukuran persis** seperti judul bagian (setelah dikecilkan
      nearest-neighbor kalau perlu)
- [ ] **Jahitan** (№1–2 saja): tempel 3× berdampingan — tidak ada garis
      vertikal di sambungan
- [ ] **Arah cahaya**: terang kiri/atas, gelap kanan/bawah — di semua aset
- [ ] **Outline tanpa halo**: tidak ada piksel setengah-transparan di tepi;
      halo jadi kotor saat Line2D menekuk tekstur
- [ ] **Hijau jenuh hanya di tanaman sehat**: akar (№2) dan daun mati (№8)
      tidak boleh punya hijau
- [ ] **Pasangan bingkai** (№9–10): silhouette identik, hanya warna bertukar
- [ ] **Tenang**: pandang 2 detik — kalau polanya terbaca "berulang" atau
      ramai, tolak
