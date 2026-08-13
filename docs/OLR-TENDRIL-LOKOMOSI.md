# TENDRIL — ORGANIC LOCOMOTION REVISION
## Traveling Wave, Growing Tip Lead, dan True CRAWL Animation

**Dokumen:** Character Animation / Movement Specification
**Status:** REVISION REQUIRED — MOVE RIGHT & MOVE LEFT belum final
**Character:** TENDRIL_MASTER A
**Target:** PixelLab.Ai + Godot
**Scope:** LEPAS locomotion, CRAWL_RIGHT, CRAWL_LEFT, directional movement language

> Dokumen PEMILIK PROYEK — kanon keenam. Merevisi MDS (kanon kelima):
> bahasa resmi lokomotasi = CRAWL, bukan WALK.

---

# 1. TUJUAN DOKUMEN

Dokumen ini memperbaiki definisi gerakan TENDRIL berdasarkan evaluasi sprite terbaru.

Sprite sebelumnya sudah berhasil membuat variasi kiri dan kanan tanpa sekadar melakukan `flip_h`, tetapi secara visual masih belum menunjukkan mekanisme locomotion yang diinginkan.

Masalah utamanya:

> TENDRIL masih terlihat seperti tanaman yang mengubah pose atau menggulung di tempat, bukan organisme yang benar-benar merayap.

Karena itu, movement TENDRIL harus didefinisikan ulang bukan sebagai **walking animation**, tetapi sebagai:

> **ORGANIC VINE CRAWL**

atau:

> **SERPENTINE VINE LOCOMOTION WITHOUT SNAKE ANATOMY**

---

# 2. DIAGNOSIS SPRITE TERBARU

Pada sprite terbaru, pola yang masih terlihat:

- bagian bawah tubuh mempertahankan bentuk U yang relatif sama,
- growing tip tetap berada tinggi dan relatif vertikal,
- spiral kepala berubah sedikit tetapi tidak benar-benar turun,
- daun melakukan perubahan yang cukup besar,
- tubuh melakukan perubahan lekukan kecil,
- tetapi pusat massa tidak cukup berpindah,
- tidak terlihat gelombang gerakan yang berjalan dari depan ke belakang.

Akibatnya animasi terasa seperti:

```text
pose
 ↓
curl
 ↓
uncurl
 ↓
pose
```

Bukan:

```text
search
 ↓
lower
 ↓
reach
 ↓
pull
 ↓
follow
 ↓
advance
```

---

# 3. KESALAHAN KONSEPTUAL PADA PROMPT SEBELUMNYA

Prompt sebelumnya menggunakan istilah seperti:

- `walking animation`
- `forward lean`
- `growing tip reaches forward`
- `body follows`

Secara desain istilah tersebut benar, tetapi terlalu ambigu untuk generator gambar.

AI dapat menafsirkannya sebagai:

```text
POSE A
 ↓
POSE B
 ↓
POSE C
```

bukan sebagai:

```text
PHYSICAL LOCOMOTION
 ↓
WEIGHT SHIFT
 ↓
TRAVELING BODY WAVE
 ↓
SPATIAL DISPLACEMENT
```

Akibatnya model hanya mengubah pose lokal:

- sudut daun,
- posisi spiral,
- lekukan tubuh,
- sedikit kemiringan.

Tetapi karakter tidak terlihat benar-benar bergerak.

---

# 4. KEPUTUSAN BARU: JANGAN GUNAKAN "WALK"

Untuk locomotion TENDRIL, istilah utama:

```text
CRAWL
ORGANIC CRAWL
VINE CRAWL
SERPENTINE VINE LOCOMOTION
TRAVELING BODY WAVE
```

Hindari sebagai istilah utama:

```text
WALK
WALKING
WALKING CYCLE
FORWARD LEAN WALK
```

Alasannya adalah kata "walk" membawa bias visual humanoid.

TENDRIL tidak berjalan.

> **TENDRIL merayap dengan mekanisme pertumbuhan dan dorongan tubuh lunak.**

---

# 5. IDENTITAS LOCOMOTION TENDRIL

TENDRIL bukan manusia hijau.

TENDRIL bukan ular.

TENDRIL bukan ulat.

TENDRIL adalah:

> **ujung tumbuh yang mencari permukaan, kemudian menarik tubuh sulurnya untuk mengikuti arah pertumbuhan tersebut.**

Urutan biologis gerakan:

```text
GROWING TIP
      ↓
SEARCH
      ↓
LOWER
      ↓
REACH
      ↓
CONTACT / SEARCH FOR SUPPORT
      ↓
PULL
      ↓
BODY FOLLOWS
      ↓
REAR FOLLOWS
      ↓
GROW FORWARD
```

---

# 6. GROWING TIP DOWNWARD RULE

Ini adalah aturan baru yang wajib.

Ketika TENDRIL bergerak di permukaan:

> **Growing Tip harus turun menuju permukaan sebelum atau ketika mulai melakukan dorongan ke depan.**

Jangan mempertahankan growing tip secara vertikal sepanjang animasi.

Ujung tumbuh:

1. turun,
2. mencari permukaan,
3. menjulur,
4. bergerak ke depan,
5. memimpin tubuh.

Bukan tetap tegak sementara hanya pangkal yang bergeser.

---

# 7. TRAVELING BODY WAVE

Ini adalah elemen paling penting dalam locomotion baru.

Gerakan tidak boleh terjadi pada seluruh tubuh sekaligus.

Gerakan harus merambat dari depan ke belakang.

```text
GROWING TIP
     ↓
UPPER VINE
     ↓
MIDDLE VINE
     ↓
LOWER VINE
     ↓
REAR SECTION
```

Bayangkan sebuah gelombang fleksibilitas berjalan sepanjang tubuh.

---

# 8. CONTOH SEKUENS GERAKAN

- Frame 1 — COMPRESS: tubuh sedikit mengumpul (anticipation, rasa berat).
- Frame 2 — TIP LOWERS: growing tip turun — awal perubahan arah tubuh.
- Frame 3 — TIP REACHES: growing tip menjulur ke depan; ujung memimpin.
- Frame 4 — UPPER BODY FOLLOWS: bagian atas mengikuti.
- Frame 5 — MIDDLE BODY FOLLOWS: gelombang bergerak ke belakang.
- Frame 6 — REAR PULL: bagian belakang tertarik ke depan.
- Frame 7 — EXTENSION: tubuh kembali memanjang.
- Frame 8 — NEW SEARCH: growing tip mencari posisi berikutnya.
- Frame 9 — NEW LOCOMOTION POSITION: tubuh sudah benar-benar berpindah.

---

# 9. SPATIAL DISPLACEMENT RULE

Animasi tidak boleh hanya mengubah pose.

Setiap frame harus memperlihatkan perubahan posisi organisme.

Konsep:

```text
FRAME 1
[ TENDRIL ]

FRAME 2
    [ TENDRIL ]

FRAME 3
         [ TENDRIL ]

FRAME 4
             [ TENDRIL ]
```

Bukan tubuh yang hanya berubah bentuk di tempat.

**Center of mass harus bergerak.**

**Rear contact point harus berubah posisi.**

---

# 10. CENTER OF MASS RULE

Dalam setiap cycle:

> **Center of Mass TENDRIL harus berpindah menuju arah locomotion.**

Perubahan tidak perlu besar pada setiap frame, tetapi keseluruhan cycle harus menghasilkan displacement yang jelas.

---

# 11. REAR CONTACT RULE

Bagian belakang TENDRIL tidak boleh selalu tertanam pada koordinat yang sama.

Saat growing tip bergerak:

```text
TIP
 ↓
REACH
 ↓
PULL
 ↓
REAR RELEASE
 ↓
REAR ADVANCE
```

Dengan demikian bagian belakang terasa ikut bergerak.

---

# 12. BODY SHAPE

Bentuk tubuh harus berubah secara dinamis.

Hindari:

```text
U-shape
U-shape
U-shape
U-shape
```

Gunakan variasi:

```text
C-shape
 ↓
S-shape
 ↓
leaning C
 ↓
elongated S
 ↓
compressed C
```

Tujuan:

> tubuh terlihat fleksibel, bukan seperti satu gambar statis yang digerakkan.

---

# 13. S-CURVE LOCOMOTION

S-curve adalah bahasa visual penting, tetapi S-curve tidak harus identik
setiap frame — gelombangnya berpindah sepanjang tubuh.

---

# 14. LEAF SECONDARY MOTION RULE

Daun bukan penggerak utama.

Daun harus:

> **bereaksi terhadap gerakan tubuh.**

Timing:

```text
BODY
 ↓
movement
 ↓
delay
 ↓
LEAF
```

Daun harus terlihat seperti memiliki massa dan elastisitas.

---

# 15. GROWING TIP SEBAGAI PUSAT ARAH

TENDRIL tidak memiliki mata.

Tetapi Growing Tip berfungsi sebagai:

> **visual direction center.**

Ketika berbalik:

```text
Growing Tip mencari arah baru
          ↓
Upper body mengikuti
          ↓
Middle body mengikuti
          ↓
Rear body mengikuti
```

---

# 16. MOVE RIGHT

Nama animasi final:

```text
CRAWL_RIGHT
```

Bukan `MOVE_RIGHT`.

Prinsip:

```text
TIP → LOWER → REACH → → PULL → → BODY → → REAR →
```

TENDRIL harus benar-benar berpindah ke kanan.

---

# 17. MOVE LEFT

Nama animasi final:

```text
CRAWL_LEFT
```

Prinsip yang sama ke arah kiri.

Ini bukan hasil `flip_h`.

Ini adalah locomotion dengan arah pertumbuhan berlawanan.

---

# 18. LEFT / RIGHT BUKAN MIRROR

Untuk final:

```text
RIGHT SPRITE
     ↓
TURN
     ↓
LEFT SPRITE
```

bukan flip_h.

Perbedaan kiri/kanan dapat terjadi pada:

- lengkungan sulur,
- sudut growing tip,
- posisi node,
- timing daun,
- bentuk S-curve,
- distribusi massa,
- arah secondary motion.

Namun identitas karakter tetap sama.

---

# 19. ORGANIC TURN

Ketika arah berubah:

```text
MOVE RIGHT
    ↓
DECELERATE
    ↓
GROWING TIP SEARCHES LEFT
    ↓
TIP LOWERS
    ↓
UPPER BODY FOLLOWS
    ↓
MIDDLE BODY FOLLOWS
    ↓
REAR FOLLOWS
    ↓
MOVE LEFT
```

TENDRIL tidak "berputar".

Ia:

> **mengubah arah pertumbuhannya.**

---

# 20. TURNING WAVE

Perubahan arah harus merambat sepanjang tubuh.

```text
TIP
 ↓
UPPER
 ↓
MIDDLE
 ↓
REAR
```

Jangan: SELURUH TUBUH ROTATE.

Jangan: FLIP INSTANTLY.

---

# 21. ISTILAH YANG HARUS DIHINDARI

Jangan gunakan istilah ini sebagai deskripsi utama:

```text
walking
walking cycle
humanoid movement
forward walking
forward lean walk
legless walking
```

Walaupun kita memberikan negative prompt, konsep "walking" tetap dapat memengaruhi interpretasi generator.

---

# 22. ISTILAH YANG DISARANKAN

Gunakan:

```text
organic crawling locomotion
vine crawl
serpentine vine locomotion
traveling body wave
growing-tip-led movement
soft-body crawling
forward body propagation
organic pull-and-reach locomotion
```

Tambahkan:

```text
without snake anatomy
without snake head
without snake body
without legs
without humanoid movement
```

---

# 23. MASTER PIXELLAB.AI PROMPT — CRAWL

```text
Use the exact TENDRIL_MASTER A character as reference.

Create a TRUE ORGANIC LOCOMOTION animation, not a pose animation.

The TENDRIL is a small young vine organism crawling along the ground without legs.

The locomotion is driven by a TRAVELING WAVE through the flexible vine body.

The growing tip is the leading part of the organism.

At the beginning of the movement, the growing tip lowers downward toward the ground.

The growing tip then reaches forward along the ground.

The upper vine follows after a short delay.

The middle vine follows after another delay.

The rear section is pulled forward last.

The movement propagates from the growing tip toward the rear like a flexible organic body wave.

The growing tip must NOT remain vertically upright throughout the animation.

The growing tip must visibly lower, reach, pull, and lead the body forward.

The body must form changing C-curves and S-curves during locomotion.

The entire organism must visibly travel through space from frame to frame.

The center of mass must move forward.

The rear contact point must change position.

Do NOT keep the lower body in the same U-shaped location while only changing the pose.

The organism should feel soft, flexible, alive, slightly vulnerable and physically grounded.

The motion may resemble the mechanics of a soft worm-like or serpentine organism, BUT DO NOT CREATE A SNAKE.

This is a plant organism with a young growing tip, one young leaf, flexible vine body and growth nodes.

The leaf is SECONDARY MOTION ONLY.

The body moves first.
The leaf follows with a slight delay.

The leaf must NOT drive the locomotion.

Crisp 2D pixel art.
Small game sprite.
Readable silhouette.
Limited canonical green palette.
No anti-aliasing.
No smooth vector curves.
Preserve the exact TENDRIL_MASTER A identity.

The final result must look like a living vine crawling forward, not a plant repeatedly curling in place.
```

---

# 24. NEGATIVE PROMPT

```text
walking animation,
walking cycle,
humanoid walking,
legless humanoid walking,
static pose animation,
idle-like movement,
curling in place,
coiling in place,
static U-shape,
same body position every frame,
vertical bobbing,
upright growing tip,
growing tip staying vertical,
leaf folding,
leaf-driven movement,
body rotating in place,
rigid rotation,
instant direction change,
horizontal sprite flip,
mirror copy,
identical pose mirrored,
teleporting,
spinning,
snake anatomy,
snake head,
snake body,
caterpillar,
worm segments,
realistic snake slithering,
extra limbs,
legs,
arms,
feet,
face,
eyes,
mouth,
smooth vector art,
anti-aliased pixels,
photorealistic plant
```

---

# 25. PIXELLAB.AI — CRAWL RIGHT

```text
Create a 9-frame CRAWL_RIGHT animation.

The entire TENDRIL physically travels from left to right.

Frame 1: compress the body and prepare the movement.
Frame 2: lower the growing tip toward the ground.
Frame 3: reach the growing tip forward toward the right.
Frame 4: pull the upper body forward.
Frame 5: propagate the body wave through the middle section.
Frame 6: pull the rear section forward.
Frame 7: extend the body.
Frame 8: the growing tip searches forward again.
Frame 9: the organism reaches a new position farther to the right.

The motion must be continuous.

The growing tip leads.
The body follows.
The rear follows last.

The animation must show clear spatial displacement.

Do not create a stationary curling animation.
```

---

# 26. PIXELLAB.AI — CRAWL LEFT

```text
Create a 9-frame CRAWL_LEFT animation.

The entire TENDRIL physically travels from right to left.

Frame 1: compress the body and prepare the movement.
Frame 2: lower the growing tip toward the ground.
Frame 3: reach the growing tip forward toward the left.
Frame 4: pull the upper body forward.
Frame 5: propagate the body wave through the middle section.
Frame 6: pull the rear section forward.
Frame 7: extend the body.
Frame 8: the growing tip searches forward again.
Frame 9: the organism reaches a new position farther to the left.

The motion must be continuous.

The growing tip leads.
The body follows.
The rear follows last.

Do not horizontally mirror the right-facing sprite.

The left-facing movement must be a naturally reoriented locomotion cycle.
```

---

# 27. PIXEL ART CONSTRAINT

Semua gerakan tetap harus mempertahankan:

- pixel clusters yang jelas,
- resolusi kecil,
- siluet mudah dibaca,
- palet hijau kanon,
- tidak ada anti-aliasing,
- tidak ada smooth vector curve,
- tidak ada tekstur realistis,
- tidak ada anatomi tambahan.

Gerakan boleh lebih ekstrem.

Identitas karakter tidak boleh berubah.

---

# 28. GODOT IMPLEMENTATION

Untuk prototype:

```text
flip_h
```

masih boleh digunakan sebagai fallback.

Namun untuk final:

```text
CRAWL_RIGHT
CRAWL_TURN_RIGHT_LEFT
CRAWL_LEFT
CRAWL_TURN_LEFT_RIGHT
```

harus menggunakan sprite animation terpisah.

Tujuan:

> Gerakan directional harus terasa biologis, bukan matematis.

---

# 29. FINAL ANIMATION CHECKLIST

## Locomotion

- [ ] TENDRIL benar-benar berpindah posisi.
- [ ] Center of mass bergerak.
- [ ] Rear contact point berpindah.
- [ ] Growing Tip turun.
- [ ] Growing Tip reach ke depan.
- [ ] Growing Tip memimpin.
- [ ] Upper body mengikuti.
- [ ] Middle body mengikuti.
- [ ] Rear body mengikuti terakhir.
- [ ] Ada traveling body wave.
- [ ] Tubuh membentuk C/S curves.
- [ ] Tidak hanya menggulung di tempat.

## Leaf

- [ ] Leaf bukan sumber gerakan.
- [ ] Leaf mengikuti tubuh.
- [ ] Ada delay secondary motion.
- [ ] Leaf tidak terlalu dominan.

## Direction

- [ ] CRAWL_RIGHT bukan flip.
- [ ] CRAWL_LEFT bukan flip.
- [ ] Turn memiliki anticipation.
- [ ] Growing Tip mengubah arah terlebih dahulu.
- [ ] Tubuh mengikuti secara bertahap.
- [ ] Rear section mengikuti terakhir.

## Pixel Art

- [ ] Silhouette tetap konsisten.
- [ ] Pixel clusters bersih.
- [ ] Tidak ada anti-aliasing.
- [ ] Palet kanon.
- [ ] Tetap terbaca pada ukuran kecil.

---

# 30. DEFINITION OF DONE

CRAWL animation belum dianggap selesai hanya karena:

- frame sudah lengkap,
- kiri dan kanan sudah berbeda,
- Godot sudah dapat memainkan sprite strip.

Animation baru dianggap selesai jika ketika dimainkan tanpa melihat kode, pemain dapat mengatakan:

> **"TENDRIL sedang merayap."**

bukan:

> **"TENDRIL sedang menggulung."**

Dan ketika dimainkan frame-by-frame:

> **Growing Tip harus terlihat memimpin locomotion, kemudian gelombang gerakan mengikuti tubuh sampai ke belakang.**

---

# 31. ART DIRECTION GOLDEN RULE

> **TENDRIL tidak berjalan.**
>
> **TENDRIL tidak sekadar menggulung.**
>
> **TENDRIL tumbuh ke arah gerak.**
>
> Ujung tumbuh mencari permukaan.
>
> Ujung turun.
>
> Ujung menjulur.
>
> Tubuh tertarik.
>
> Gelombang gerakan berjalan ke belakang.
>
> Daun mengikuti.
>
> Kemudian TENDRIL mencari titik tumbuh berikutnya.

---

# 32. CORE MOVEMENT IDENTITY

```text
SEARCH
   ↓
LOWER
   ↓
REACH
   ↓
PULL
   ↓
FOLLOW
   ↓
EXTEND
   ↓
SEARCH AGAIN
```

Inilah **movement language resmi TENDRIL**.

Bukan:

```text
POSE
 ↓
CURL
 ↓
UNCURL
 ↓
POSE
```

---

# 33. STATUS PRODUKSI

## TENDRIL_MASTER A

**LOCKED**

## CRAWL_RIGHT

**REVISE**

## CRAWL_LEFT

**REVISE**

## TURN RIGHT ↔ LEFT

**REVISE AFTER CRAWL IS CORRECT**

## JUMP / FALL / LAND

**WAIT**

Jangan melanjutkan Jump/Fall/Land sebelum locomotion dasar terasa benar.

---

# 34. PRIORITAS PRODUKSI BARU

```text
MASTER A
   ↓
CRAWL_RIGHT
   ↓
CRAWL_LEFT
   ↓
CRAWL TURN
   ↓
GODOT PLAYTEST
   ↓
JUMP
   ↓
FALL
   ↓
LAND
```

Movement adalah fondasi.

Jika locomotion TENDRIL sudah benar, semua animasi berikutnya akan lebih mudah karena kita sudah mempunyai bahasa gerakan yang konsisten.

---

# 35. ART DIRECTION STATEMENT

> **TENDRIL adalah tanaman yang bergerak dengan pertumbuhan.**
>
> Ia tidak memiliki kaki.
>
> Ia tidak melangkah.
>
> Ia tidak berputar seperti objek.
>
> Ia mencari tempat untuk tumbuh.
>
> Growing Tip bergerak terlebih dahulu.
>
> Tubuh mengikuti.
>
> Gelombang gerakan merambat ke belakang.
>
> Daun tertinggal sesaat.
>
> Ketika arah berubah, TENDRIL tidak sekadar dibalik.
>
> Ia mengubah arah pertumbuhannya.
>
> **TENDRIL tidak berpindah arah.**
>
> **TENDRIL menumbuhkan dirinya ke arah yang baru.**
