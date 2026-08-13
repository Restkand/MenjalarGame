> **HISTORIS - ditimpa istilahnya oleh OLR-TENDRIL-LOKOMOSI.md.** Simpan sebagai alasan desain; jangan pakai sebagai acuan bahasa gerak.

# TENDRIL — MOVEMENT & DIRECTIONAL ANIMATION SPEC
## Forward Lean, Organic Locomotion, dan Turn Left ↔ Right

**Dokumen:** Character Animation Direction
**Status:** Draft untuk PixelLab.Ai + Godot
**Character:** TENDRIL_MASTER A
**Scope:** LEPAS movement, directional turn, left/right animation, silhouette consistency

> Dokumen PEMILIK PROYEK — kanon kelima. Ditulis setelah playtest gerak
> pertama: transisi menggulung terasa terlalu cepat/kurang natural, dan
> kiri-kanan tidak boleh terasa flip objek.

---

# 1. KEPUTUSAN UTAMA

Setelah evaluasi sprite terbaru, movement TENDRIL perlu dikoreksi.

Versi sebelumnya terlalu terasa seperti:

> **"daun melipat → tubuh menggulung → membuka kembali."**

Padahal movement yang kita inginkan adalah:

> **"ujung tumbuh mencari arah → tubuh mendorong → sulur mengikuti → daun menyusul."**

Dengan demikian:

## TENDRIL tidak berjalan seperti manusia.

TENDRIL:

> **mendorong dirinya untuk tumbuh ke depan.**

---

# 2. FORWARD MOMENTUM RULE

Dalam mode **LEPAS**, arah gerak selalu dipimpin oleh **ujung tumbuh**.

Hierarki gerakan:

```text
        1. UJUNG TUMBUH
               ↓
        2. ARAH TUBUH
               ↓
        3. SULUR
               ↓
        4. NODE
               ↓
        5. DAUN
```

Jika daun bergerak terlebih dahulu sementara tubuh hanya berubah pose:

> **ANIMASI GAGAL**

Jika ujung tumbuh bergerak terlebih dahulu dan tubuh mengejar:

> **ANIMASI BERHASIL**

---

# 3. POSE LEPAS YANG DIINGINKAN

TENDRIL harus memiliki:

- sedikit condong ke depan,
- sedikit condong ke bawah,
- tubuh lebih rendah daripada posisi idle,
- ujung tumbuh berada di depan,
- bagian belakang tertinggal,
- daun mengikuti dengan delay kecil.

Bukan tegak lurus statis, tetapi lebih seperti:

```text
                ✦
              ╱
            ╱
          ╱
       ╭─╯
     ╭─╯
─────╯

        → ARAH GERAK
```

**Catatan:** Jangan membuatnya terlalu horizontal. TENDRIL tetap harus terlihat seperti organisme vertikal yang sedang mencari arah.

---

# 4. MOVEMENT CYCLE

Satu siklus gerak dasar:

```text
1. COMPRESS
       ↓
2. PUSH
       ↓
3. GROWING TIP REACH
       ↓
4. BODY FOLLOW
       ↓
5. RECOVER
       ↓
6. REPEAT
```

## Frame 1 — Compress

Tubuh sedikit mengumpul.

Tujuan:

- memberi anticipation,
- memberi rasa berat,
- mempersiapkan dorongan.

## Frame 2 — Push

Bagian bawah mendorong.

Tubuh mulai condong.

## Frame 3 — Reach

Ujung tumbuh bergerak paling jauh ke depan.

Ini adalah frame penting.

> **Growing Tip harus terlihat memimpin movement.**

## Frame 4 — Follow Through

Tubuh mengikuti ujung tumbuh.

Bagian belakang masih sedikit tertinggal.

## Frame 5 — Recover

Tubuh kembali ke posisi movement yang lebih stabil.

Daun menyusul sedikit terlambat.

---

# 5. SECONDARY MOTION DAUN

Daun bukan sumber utama gerakan.

Urutannya:

```text
UJUNG TUMBUH
      ↓
SULUR
      ↓
NODE
      ↓
DAUN
```

Daun harus mempunyai sedikit **secondary motion**.

Contoh:

```text
FRAME 1
body bergerak
leaf hampir diam

FRAME 2
body maju
leaf mulai mengikuti

FRAME 3
body mencapai posisi
leaf tertinggal sedikit

FRAME 4
leaf menyelesaikan gerak
```

Efek ini membuat TENDRIL terasa memiliki massa dan fleksibilitas.

---

# 6. JANGAN MEMBUAT TENDRIL SEPERTI ULAT

TENDRIL tidak memiliki:

- kaki,
- lengan,
- telapak,
- lutut,
- pinggul,
- gerakan ulat.

Hindari:

```text
compress → extend → compress → extend
```

yang terlalu seragam.

Gunakan:

```text
search → reach → pull → settle
```

---

# 7. PERBEDAAN MERAMBAT VS LEPAS

## MERAMBAT

```text
bebas
ringan
fluid
tidak terikat gravitasi
mengikuti jaringan
```

Gerakan:

> **mengalir sepanjang jaringan.**

## LEPAS

```text
berat
rentan
gravitasi
mencari pijakan
mendorong tubuh
```

Gerakan:

> **mencari jalan ke depan.**

---

# 8. DIRECTIONAL ANIMATION

TENDRIL tidak boleh hanya memiliki satu sprite yang di-`flip_h`.

Kita memang dapat menggunakan sprite flip sebagai fallback teknis untuk prototype, tetapi **animasi final harus mempunyai directional treatment sendiri.**

Alasannya:

TENDRIL memiliki anatomi asimetris:

- ujung tumbuh,
- daun,
- node,
- lekukan sulur,
- distribusi massa.

Jika hanya di-flip, gerakan akan terasa seperti:

> **"gambar yang dibalik."**

Bukan:

> **"organisme yang berbalik arah."**

---

# 9. PRINSIP TURN LEFT ↔ RIGHT

Saat TENDRIL mengubah arah:

> **TENDRIL harus benar-benar melakukan turn.**

Bukan:

```text
RIGHT SPRITE
     ↓
FLIP
     ↓
LEFT SPRITE
```

Tetapi:

```text
RIGHT
  ↓
LOOK / REACH
  ↓
BODY ROTATES
  ↓
TIP CHANGES LEAD
  ↓
LEAF FOLLOWS
  ↓
LEFT
```

---

# 10. TURNING LANGUAGE

Turn harus terasa seperti sulur yang mengubah arah pertumbuhan.

Prinsipnya (bukan pose final):

> **ujung tumbuh melakukan perubahan arah terlebih dahulu.**

---

# 11. TURNING ARC

Jangan memutar seluruh tubuh sekaligus.

Gunakan **propagation of motion**:

```text
Growing Tip
     ↓
Upper Vine
     ↓
Middle Vine
     ↓
Lower Vine
     ↓
Leaf
```

Artinya:

> bagian depan berubah arah lebih dahulu, bagian belakang mengikuti.

Ini akan membuat turn terlihat seperti organisme fleksibel.

---

# 12. TURN LEFT — 5 FRAME CONCEPT

- L1 Forward: masih bergerak ke kanan.
- L2 Tip Searches Left: ujung mulai bergerak ke kiri.
- L3 Body Follows: bagian tengah mengikuti.
- L4 Reorientation: tubuh hampir menghadap kiri.
- L5 Left Movement: pose baru stabil.

---

# 13. TURN RIGHT

Turn kanan menggunakan prinsip yang sama tetapi tidak dibuat sebagai mirror mekanis.

Perubahan harus tetap mempunyai:

- timing,
- anticipation,
- follow-through,
- secondary motion,
- perbedaan posisi node,
- perbedaan lengkungan.

---

# 14. ASYMMETRY RULE

Setiap directional sprite sebaiknya memiliki **sedikit variasi organik**.

Bukan random.

### Menghadap kanan

- ujung tumbuh sedikit lebih tinggi,
- daun tertinggal ke belakang,
- lekukan utama berada di sisi tertentu.

### Menghadap kiri

- ujung tumbuh sedikit lebih rendah,
- daun tertinggal dengan sudut berbeda,
- distribusi lekukan berubah.

Tujuannya bukan membuat dua desain berbeda.

Tujuannya:

> **membuat kiri dan kanan terasa sebagai dua pose hidup.**

---

# 15. JANGAN OVERDO ASYMMETRY

Kiri dan kanan tetap harus jelas merupakan TENDRIL yang sama.

Jangan mengubah:

- ukuran tubuh,
- jumlah daun,
- bentuk utama,
- warna,
- proporsi.

Yang boleh berubah:

- sudut,
- lekukan,
- timing,
- posisi daun,
- posisi node,
- arah ujung tumbuh.

---

# 16. TURNING TRANSITION

Ketika pemain menekan arah berlawanan:

```text
MOVE RIGHT
    ↓
DECELERATE
    ↓
TIP LOOKS LEFT
    ↓
BODY BENDS
    ↓
LEAF LAGS
    ↓
BODY FOLLOWS
    ↓
MOVE LEFT
```

Jangan:

```text
RIGHT
 ↓
FLIP
 ↓
LEFT
```

---

# 17. TURNING ANTICIPATION

Sebelum membalik arah, TENDRIL boleh memiliki satu frame anticipation.

Anticipation tidak boleh terlalu lama.

Tujuannya hanya memberi sinyal:

> **arah akan berubah.**

---

# 18. LEAF FOLLOW-THROUGH

Daun harus terlambat mengikuti perubahan arah.

Ini membuat tanaman terasa memiliki elastisitas.

---

# 19. GROWING TIP SEBAGAI "EYE"

Walaupun TENDRIL tidak memiliki mata:

> Growing Tip berfungsi sebagai pusat perhatian dan arah.

Saat berbelok:

**Growing Tip harus terlihat seperti menemukan arah baru.**

Jangan membuat kepala berputar seperti kepala manusia.

Lebih tepat:

> **tubuh tumbuh ke arah baru.**

---

# 20. PIXELLAB.AI — MASTER MOVEMENT PROMPT

Gunakan master berikut sebagai basis:

```text
Use the exact TENDRIL_MASTER A character as the visual reference.

Create a 2D pixel art animation of the same young vine organism moving in a side-scrolling platformer.

The character has no arms, no legs, no feet, no face and no humanoid anatomy.

The TENDRIL moves by compressing, pushing, reaching its growing tip forward, and allowing the flexible vine body to follow.

The growing tip leads the movement.

The entire body leans slightly forward and slightly downward toward the direction of travel.

The movement must communicate forward momentum, gravity, vulnerability and organic growth.

The young leaf is secondary motion only. It follows the body with a slight delay.

Do not make the leaf the main source of movement.

The vine body should squash and stretch organically.

Preserve the exact TENDRIL_MASTER silhouette language, anatomy, proportions, limited green palette and pixel-art readability.

The movement should feel like a young vine pushing itself forward rather than a humanoid walking character.

Crisp pixel clusters.
Readable at small resolution.
No smooth vector curves.
No anti-aliasing.
No realistic plant texture.
No extra limbs.
No face.
No eyes.
No mouth.
No humanoid walking cycle.
```

---

# 21. PIXELLAB.AI — TURNING PROMPT

Untuk animasi berbelok:

```text
Use the exact TENDRIL_MASTER A character as the reference.

Create a directional turning animation for the same TENDRIL organism.

The character must turn organically from one direction to the opposite direction.

Do NOT simply mirror or horizontally flip the original sprite.

The turn must be animated as a biological change of growth direction.

The growing tip changes direction first.

The upper vine follows after the growing tip.

The middle vine follows next.

The lower vine follows last.

The young leaf has delayed secondary motion and follows the body naturally.

Use a subtle anticipation frame before the direction change.

Use squash and stretch during the turn.

The character should briefly form a curved S-shaped transition while changing direction.

Preserve the same character identity, anatomy, proportions, pixel-art style and limited green palette.

The left-facing and right-facing poses should feel like the same organism physically turning around, not two mirrored images.

No humanoid rotation.
No spinning in place.
No instant horizontal flip.
No teleporting.
No rigid rotation.
No symmetrical robotic movement.
No extra limbs.
No face.
No eyes.
No mouth.

Crisp pixel clusters.
Small-game-sprite readability.
Organic hand-crafted pixel-art appearance.
```

---

# 22. PIXELLAB.AI — LEFT FACING PROMPT

```text
Use TENDRIL_MASTER A as the exact character reference.

Create a left-facing movement sprite.

The TENDRIL is actively moving toward the left.

The growing tip must lead toward the left.

The body leans slightly forward and downward toward the left.

The rear section trails behind.

The young leaf follows with subtle delayed motion.

Do not horizontally flip the original sprite.

Reconstruct the left-facing pose as a natural organic pose of the same organism.

Preserve the same anatomy, silhouette language, proportions, palette and pixel density.

Crisp 2D pixel art.
No anti-aliasing.
No smooth vector edges.
No humanoid anatomy.
No legs.
No arms.
No face.
```

---

# 23. PIXELLAB.AI — RIGHT FACING PROMPT

```text
Use TENDRIL_MASTER A as the exact character reference.

Create a right-facing movement sprite.

The TENDRIL is actively moving toward the right.

The growing tip must lead toward the right.

The body leans slightly forward and downward toward the right.

The rear section trails behind.

The young leaf follows with subtle delayed motion.

Do not horizontally flip the original sprite.

Reconstruct the right-facing pose as a natural organic pose of the same organism.

Preserve the same anatomy, silhouette language, proportions, palette and pixel density.

Crisp 2D pixel art.
No anti-aliasing.
No smooth vector edges.
No humanoid anatomy.
No legs.
No arms.
No face.
```

---

# 24. NEGATIVE PROMPT — DIRECTIONAL ANIMATION

```text
horizontal flip,
mirrored sprite,
mirror copy,
identical left and right pose,
instant direction change,
teleporting,
rigid rotation,
robotic turning,
spinning,
humanoid turning,
humanoid walking,
legs,
arms,
feet,
face,
eyes,
mouth,
caterpillar,
snake,
leaf dancing,
leaf-only movement,
vertical bobbing,
curling in place,
folding repeatedly,
static body,
stiff vine,
vector art,
smooth gradients,
anti-aliased edges,
photorealistic plant
```

---

# 25. GODOT IMPLEMENTATION PRINCIPLE

Untuk prototype, horizontal flip masih boleh digunakan sebagai fallback.

Tetapi untuk final:

```text
Right Animation
       ↓
Turn Animation
       ↓
Left Animation
```

Jangan bergantung pada `flip_h` sebagai sistem directional animation final.

---

# 26. RECOMMENDED ANIMATION SET

Untuk TENDRIL LEPAS:

```text
idle_right
move_right
turn_right_to_left
move_left
turn_left_to_right
jump_right
fall_right
land_right
jump_left
fall_left
land_left
detach
attach
```

Untuk prototype awal, cukup:

```text
idle
move_right
move_left
turn
detach
attach
```

---

# 27. ANIMATION PRIORITY

Prioritas produksi:

```text
1. MASTER A
2. IDLE
3. MOVE RIGHT
4. MOVE LEFT
5. TURN RIGHT → LEFT
6. TURN LEFT → RIGHT
7. DETACH
8. ATTACH
9. JUMP
10. FALL
11. LAND
```

---

# 28. ART DIRECTION GOLDEN RULE

> **TENDRIL tidak berpindah arah. TENDRIL mengubah arah pertumbuhannya.**

Ini harus menjadi prinsip utama directional animation.

Ketika bergerak ke kanan:

> ujung tumbuh mencari kanan.

Ketika berbalik:

> ujung tumbuh menemukan kiri.

Tubuh kemudian mengikuti.

---

# 29. FINAL CHECKLIST

Sebelum menerima animasi:

### Silhouette

- [ ] Masih jelas sebagai TENDRIL.
- [ ] S-curve tetap terbaca.
- [ ] Growing Tip jelas.
- [ ] Daun tidak terlalu dominan.
- [ ] Sulur tetap fleksibel.

### Movement

- [ ] Ada forward lean.
- [ ] Ada sedikit downward lean.
- [ ] Growing Tip memimpin.
- [ ] Tubuh mengikuti.
- [ ] Daun mengikuti belakangan.
- [ ] Ada squash/stretch.
- [ ] Tidak terlihat seperti menggulung di tempat.

### Direction

- [ ] Left tidak sekadar mirror.
- [ ] Right tidak sekadar mirror.
- [ ] Turn memiliki anticipation.
- [ ] Growing Tip berubah arah terlebih dahulu.
- [ ] Tubuh mengikuti secara bertahap.
- [ ] Leaf memiliki follow-through.
- [ ] Tidak ada teleport/flip instan.

### Pixel Art

- [ ] Crisp pixel clusters.
- [ ] Tidak ada anti-aliasing.
- [ ] Tidak ada smooth vector curve.
- [ ] Palet kanon tetap.
- [ ] Terbaca pada ukuran kecil.

---

# 30. STATUS

## MASTER

**LOCK — TENDRIL_MASTER A**

## MOVEMENT

**REVISE**

Fokus:

> forward lean + downward search + growing-tip-led movement

## DIRECTION

**NEW REQUIREMENT**

Left/right harus dibuat sebagai **organic directional animation**, bukan sekadar `flip_h`.

## PRIORITAS BERIKUTNYA

```text
MASTER A
   ↓
MOVE RIGHT
   ↓
MOVE LEFT
   ↓
TURN RIGHT → LEFT
   ↓
TURN LEFT → RIGHT
   ↓
GODOT PLAYTEST
```

Setelah movement terasa hidup:

```text
JUMP
 ↓
FALL
 ↓
LAND
 ↓
GROW
 ↓
ENERGY
 ↓
CUT / DEATH
 ↓
REGROW
```

---

# 31. ART DIRECTION STATEMENT

> **TENDRIL tidak memiliki kaki untuk berjalan.**
>
> Ia menggunakan tubuhnya untuk mencari tempat tumbuh.
>
> Ujung tumbuh bergerak terlebih dahulu.
>
> Tubuh mengikuti.
>
> Daun tertinggal sesaat.
>
> Ketika arah berubah, ia tidak sekadar dibalik.
>
> **Ia benar-benar mengubah arah pertumbuhannya.**
>
> Karena itu setiap gerakan TENDRIL harus terasa seperti:
>
> **sebuah tanaman kecil yang hidup, mencari ruang, dan terus berusaha tumbuh.**
