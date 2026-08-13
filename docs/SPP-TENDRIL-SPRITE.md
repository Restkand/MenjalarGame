# TENDRIL — SPRITE PROMPT PACK
## Prompt Produksi Sprite Karakter untuk PixelLab.Ai

**Dokumen:** Sprite Prompt Pack
**Game:** TENDRIL
**Genre:** 2D Pixel Art Metroidvania / Platformer / Stealth
**Karakter:** Ujung Tumbuh / Tendril
**Target Tool:** PixelLab.Ai
**Target Engine:** Godot

> Dokumen ini ditulis PEMILIK PROYEK — kanon ketiga, setara GDD & CDD.
> Semua produksi sprite karakter WAJIB memakai prompt dari sini.

---

# 0. TUJUAN

Dokumen ini hanya berisi **prompt produksi sprite**.

Dokumen ini bukan GDD, bukan tutorial Godot, dan bukan character bible lengkap.

Tujuannya:

> Menghasilkan sprite TENDRIL yang konsisten dari satu master character, lalu mengembangkan sprite tersebut menjadi seluruh kebutuhan gameplay.

Urutan produksi:

```text
MASTER SPRITE
    ↓
POSE DASAR
    ↓
MERAMBAT
    ↓
LEPAS
    ↓
GERAK
    ↓
INTERAKSI JARINGAN
    ↓
PERTUMBUHAN
    ↓
ABILITY
    ↓
STATUS
    ↓
DEATH / REGROWTH
```

---

# 1. IDENTITAS SPRITE — WAJIB

Setiap prompt sprite TENDRIL harus mempertahankan identitas berikut:

```text
small young vine growing tip
thin flexible vine body
pointed sensitive glowing growing tip
one young leaf
small growth nodes
organic S-curve silhouette
non-humanoid plant organism
dark atmospheric 2D pixel art
side-scroller game sprite
limited green palette
clear readable silhouette
```

Dalam bahasa desain:

> **SULUR + TUNAS + KEHIDUPAN**

---

# 2. NORTH STAR

> **Kecil sebagai individu. Besar sebagai jaringan.**

Sprite tidak boleh terlihat seperti:

- manusia hijau,
- monster humanoid,
- ular,
- naga,
- tentakel,
- pohon mini,
- bunga berjalan.

TENDRIL adalah **ujung pertumbuhan dari jaringan tanaman**, bukan makhluk berkaki.

---

# 3. ANATOMI KANON

Sprite harus memperlihatkan empat komponen utama:

## 3.1 UJUNG TUMBUH

- berada di bagian depan,
- berbentuk tunas/runcing,
- sedikit bercahaya,
- sensitif terhadap cahaya,
- menjadi titik fokus sprite.

## 3.2 DAUN MUDA

- satu daun utama,
- kecil,
- lentur,
- dapat membuka/menutup,
- menjadi bagian dari ekspresi karakter.

## 3.3 SULUR FLEKSIBEL

- merupakan tubuh,
- tipis,
- melengkung,
- memiliki S-curve,
- dapat memanjang,
- dapat squash/stretch.

## 3.4 NODE PERTUMBUHAN

- tonjolan kecil pada sulur,
- calon percabangan,
- jangan terlalu banyak,
- menjadi penghubung visual dengan jaringan.

---

# 4. PALET KANON

Gunakan palet visual berikut sebagai target:

```text
Deep Shadow     #102016
Dark Green      #19351E
Forest Green    #285B2B
Plant Green     #4F8F32
Young Leaf      #79B83F
Glow Highlight  #A8D94A
```

Aturan:

- jangan memakai hijau neon berlebihan,
- ujung tumbuh boleh menjadi titik paling terang,
- daun muda sedikit lebih terang dari batang,
- shadow cenderung hijau gelap, bukan hitam murni,
- jangan menggunakan gradient halus.

---

# 5. TARGET UKURAN

Prioritas:

```text
32×32  → gameplay sprite
48×48  → master sprite yang lebih mudah dibaca
64×64  → reference / animasi / cleanup
```

Untuk prototype awal:

> **Mulai dari 48×48 sebagai MASTER.**

Setelah bentuk benar, buat versi gameplay 32×32.

---

# 6. CAMERA

Gunakan:

```text
SIDE VIEW
SIDESCROLLER
```

Bukan:

```text
TOP DOWN
ISOMETRIC
FRONT VIEW
THREE QUARTER RPG
```

---

# 7. MASTER SPRITE

## Prompt

```text
A small young vine growing tip from a massive living plant network inside an abandoned urban building.

2D pixel art metroidvania game sprite, side-scroller side view.

The character is a tiny plant organism, approximately 1.2 meters tall when fully extended, much smaller than a human.

The body is a thin flexible vine with a clear organic S-curve.

At the front is a distinct pointed young growing tip with a subtle natural glow, sensitive to light.

A single young leaf grows near the upper section of the vine.

Small growth nodes appear along the stem as future branching points.

The character is completely plant-like and non-humanoid.

No arms.
No hands.
No legs.
No feet.
No clothing.
No armor.
No human face.
No eyes.
No mouth.
No animal anatomy.

The organism should look young, vulnerable, agile and alive.

Dark atmospheric pixel art.
Limited forest-green palette.
Deep green shadows.
Bright young-leaf highlights.
Subtle glowing growing tip.

Strong readable silhouette.
Organic S-curve.
Crisp pixel clusters.
No gradients.
No anti-aliasing.
No blurry pixels.

Full character visible.
Centered.
Isolated sprite.
Transparent background.
```

---

# 8. NEGATIVE PROMPT MASTER

Jika PixelLab menyediakan Negative Description:

```text
humanoid, human, human body, arms, hands, legs, feet, shoes, clothing, armor, helmet, weapon, sword, shield, human face, eyes, mouth, teeth, animal, snake, dragon, octopus, tentacle monster, tree creature, walking plant, flower monster, cartoon mascot, mechanical parts, robotic, realistic photography, 3D render, smooth vector art, gradients, blurry pixels, anti-aliased edges, excessive detail, giant leaves, giant flower, large roots covering the character
```

---

# 9. MASTER SILHOUETTE

Sebelum detail, hasilkan silhouette.

## Prompt

```text
Minimal silhouette of a tiny young vine growing tip.

2D side-scroller pixel art.

Thin flexible vine body forming a graceful S-curve.

One distinct pointed growing tip.
One small young leaf.
Two or three subtle growth nodes.

The growing tip is the brightest visual focal point.

Very clear silhouette.
Small and lightweight organism.
Much smaller than a human.

No humanoid anatomy.
No arms.
No legs.
No face.

Limited dark green pixel palette.
Crisp pixel clusters.
No background.
Transparent background.
```

---

# 10. MASTER IDLE — BERNAPAS

Idle adalah sprite paling penting setelah master.

## Prompt

```text
Animate the exact TENDRIL master character.

Idle breathing animation.

The young vine remains in place but appears alive.

The thin stem slowly expands and contracts with a subtle biological breathing rhythm.

The S-curve gently shifts.

The young leaf slowly opens and relaxes.

The glowing growing tip softly pulses.

Small growth nodes make an almost imperceptible movement.

Very subtle 4 to 8 frame idle animation.

No walking.
No jumping.
No attack.
No large movement.

The character must feel alive even while standing still.

Preserve exact anatomy, silhouette, proportions and palette.

2D pixel art.
Side-scroller.
Transparent background.
```

---

# 11. IDLE — TAKUT

```text
Animate the exact TENDRIL master character.

Fear idle animation.

The vine body contracts inward and becomes smaller.

The S-curve tightens.

The young leaf partially closes.

The growing tip lowers slightly and becomes less bright.

The whole organism appears cautious and vulnerable.

No facial expression.
No eyes.
No mouth.

Emotion must be communicated entirely through body posture and leaf movement.

4 to 8 frame pixel art animation.

Preserve exact character identity.
Transparent background.
```

---

# 12. IDLE — KENYANG / TERHUBUNG

```text
Animate the exact TENDRIL master character.

Healthy connected idle state.

The organism is fully relaxed and nourished by the vine network.

The body has a gentle rhythmic pulse.

The young leaf opens slightly.

The growing tip glows softly.

Tiny growth nodes pulse in sequence.

The posture is relaxed and confident.

No humanoid anatomy.

Organic biological movement.

4 to 8 frame pixel art animation.

Preserve exact silhouette and palette.
Transparent background.
```

---

# 13. MERAMBAT — NETRAL

MERAMBAT adalah moda ketika TENDRIL terhubung dengan jaringan.

## Prompt

```text
Animate the exact TENDRIL master character while attached to its living vine network.

MERAMBAT mode.

The organism moves naturally along the surface of the connected vine network.

The body follows an organic curved path.

The growing tip leads the direction.

The young leaf follows behind with secondary motion.

The character appears weightless while connected.

No gravity-based falling.

No arms.
No legs.

Fast but fluid organic crawling motion.

2D pixel art metroidvania animation.
Side-scroller.
Preserve exact character identity.
```

---

# 14. MERAMBAT — 8 ARAH

```text
Create the exact TENDRIL character moving freely along a connected vine network.

The organism can travel in eight directions.

Show organic directional bending rather than humanoid walking.

The growing tip points toward movement.

The flexible stem curves behind it.

The leaf trails naturally.

The body remains attached to the network.

No gravity.

No legs.
No arms.

Dark green pixel art.
Clear readable silhouette.
```

---

# 15. MERAMBAT — MENEMPEL PERMUKAAN

```text
Animate the exact TENDRIL character attached directly to a building surface.

The plant hugs the wall.

The flexible vine follows the surface contour.

Small root-like contact points hold the organism against the surface.

The growing tip searches along the wall.

The leaf remains visible.

The organism can move horizontally, vertically or upside down.

No humanoid limbs.

Organic adhesion.

2D side-scroller pixel art.
```

---

# 16. MERAMBAT — MASUK CELAH KECIL

```text
Animate the exact TENDRIL character squeezing through a small crack in a building wall.

The thin vine body compresses and stretches naturally.

The growing tip enters the crack first.

The stem becomes extremely narrow.

The young leaf folds inward temporarily.

The body emerges on the other side.

Organic flexibility is the main visual idea.

No humanoid anatomy.

No body horror.
No gore.

Pixel art metroidvania animation.
```

---

# 17. MERAMBAT — CAMOUFLAGE

```text
Create the exact TENDRIL character hidden inside a dense living vine network.

The organism visually blends into surrounding foliage.

The body uses similar dark green values as the network.

The young leaf remains barely distinguishable.

The growing tip is only subtly visible.

No magical invisibility effect.

The camouflage should look biological and natural.

Dark atmospheric pixel art.
Side-scroller.
```

---

# 18. LEPAS — TRANSISI

```text
Animate the exact TENDRIL character transitioning from MERAMBAT to LEPAS.

The organism is initially attached to the living vine network.

The rear connection slowly separates.

The flexible stem stretches.

The growing tip moves forward.

The connection snaps free naturally.

The character becomes a completely independent small vine organism.

The body immediately responds to gravity.

Organic detachment.

No humanoid limbs.

Pixel art.
Side-scroller.
```

---

# 19. LEPAS — IDLE

```text
Animate the exact TENDRIL character while detached from the vine network.

LEPAS mode.

The organism is affected by gravity.

The thin body has a slightly unstable posture.

The growing tip remains alert.

The young leaf moves gently.

The stem sways slightly.

The character appears more vulnerable than in MERAMBAT mode.

No network connection.

No humanoid anatomy.

2D side-scroller pixel art.
```

---

# 20. LEPAS — WALK

```text
Animate the exact TENDRIL character moving while detached.

The character does not have legs.

Movement is achieved through flexible plant-body motion.

The lower stem bends and pushes against the ground.

The growing tip leads forward.

The body performs subtle squash and stretch.

The leaf follows the motion.

The movement should feel like a living vine dragging, curling and pushing itself forward.

No humanoid walking.

No legs.

No feet.

2D pixel art platformer animation.
```

---

# 21. LEPAS — JUMP

```text
Animate the exact TENDRIL character jumping while detached.

The plant compresses before launch.

The flexible stem pushes against the ground.

The organism stretches upward.

The growing tip points in the direction of movement.

The young leaf trails behind.

The body bends naturally in midair.

Strong organic squash and stretch.

No legs.
No arms.

Side-scroller pixel art.
```

---

# 22. LEPAS — FALL

```text
Animate the exact TENDRIL character falling under gravity.

The organism is completely detached from the network.

The growing tip points downward.

The flexible stem bends from air resistance.

The young leaf trails upward.

The body rotates slightly during the fall.

The character should look lightweight and vulnerable.

No humanoid anatomy.

Pixel art platformer animation.
```

---

# 23. LEPAS — LANDING

```text
Animate the exact TENDRIL character landing on a hard surface.

The vine body compresses on impact.

The S-curve briefly becomes flattened.

The growing tip dips downward.

The young leaf reacts one moment later.

Tiny pixel dust appears.

Then the body returns to its normal S-curve.

Organic squash and stretch.

No humanoid anatomy.
```

---

# 24. KEMBALI KE JARINGAN

```text
Animate the exact TENDRIL character touching a living vine network and reconnecting.

The growing tip touches the network.

A small biological connection forms.

The body stretches toward the network.

The character gradually becomes integrated with the surrounding vines.

The weight of gravity disappears.

The organism returns to MERAMBAT mode.

Smooth biological transition.

No magical effects.
No electrical effects.

2D pixel art.
```

---

# 25. URUTAN TRANSISI 5 FRAME KELOMPOK

Gunakan urutan visual ini sebagai acuan:

```text
01  MERAMBAT
        ↓
02  MELEPASKAN DIRI
        ↓
03  LEPAS / BEBAS
        ↓
04  MENYENTUH JARINGAN
        ↓
05  MERAMBAT KEMBALI
```

Setiap frame harus memperjelas perubahan mode.

---

# 26. TUMBUHKAN

```text
Animate the exact TENDRIL character creating a new vine connection.

The growing tip touches a suitable surface.

A tiny green root point appears.

The point expands.

A thin vine shoots outward.

The vine grows across the surface.

A new growth node forms.

The character remains connected to the new growth.

Fast but biological growth.

Pixel art.
Limited green palette.
```

---

# 27. NODE PERTUMBUHAN

```text
Create a small TENDRIL growth node.

A tiny organic plant node attached to a vine.

Round irregular shape.

Small young shoot emerging from the node.

Subtle green glow.

Clearly biological.

This is a future branching point and respawn connection.

2D pixel art game asset.
Transparent background.
```

---

# 28. TENDRIL / TARIK

```text
Animate the exact TENDRIL character using a long flexible tendril.

The character extends a thin vine from its body toward a nearby target.

The tendril rapidly grows outward.

The growing tip remains the main body focal point.

The extended tendril is thin and organic.

The body stretches slightly from the force.

No mechanical cable.
No arm.
No hand.

2D pixel art.
```

---

# 29. HOOK VINE

```text
Animate the exact TENDRIL character launching a hook vine.

A thin organic vine rapidly extends from the body.

The end forms a small natural hook.

The hook attaches to a distant surface.

The vine becomes taut.

The character is pulled toward the anchor point.

Strong elastic motion.

No mechanical grappling hook.
No metal.
No humanoid arm.

Pixel art metroidvania animation.
```

---

# 30. ROOT BURST

```text
Animate the exact TENDRIL character performing ROOT BURST.

The character anchors itself.

Several small roots rapidly grow downward.

The roots expand outward.

The ground cracks.

A short burst of organic force pushes debris outward.

The character remains centered and recognizable.

No fire.
No explosion.
No gore.

Dark green plant colors with earthy brown debris.

2D pixel art.
```

---

# 31. SPORA

```text
Animate the exact TENDRIL character releasing spores.

Small bright spores emerge from the plant body.

They drift outward in a soft cloud.

The spores move slowly and organically.

The growing tip remains visible.

The young leaf moves gently.

The spores should look biological rather than magical.

Tiny green-yellow pixel particles.

2D atmospheric pixel art.
```

---

# 32. PARASIT

```text
Animate the exact TENDRIL character forming a parasitic connection.

Small secondary vines grow from the character.

They reach a nearby host.

The vines attach to the host surface.

A subtle biological pulse travels through the connection.

The main TENDRIL remains recognizable.

No gore.
No exposed organs.
No graphic body horror.

Dark green and subtle purple biological accents.

Pixel art.
```

---

# 33. DAMAGE

```text
Animate the exact TENDRIL character taking damage.

The entire vine body recoils.

The growing tip bends backward.

The young leaf shakes violently.

One or two tiny plant fragments fall away.

The body briefly loses its normal S-curve.

Then it attempts to recover.

No blood.
No gore.
No humanoid injury.

Pixel art.
```

---

# 34. LOW ENERGY

```text
Create the exact TENDRIL character in a critically low energy state.

The vine body becomes limp.

The S-curve is weaker.

The young leaf droops.

The glowing growing tip becomes dim.

The colors shift toward darker green.

The organism looks tired and vulnerable.

Preserve the same silhouette and anatomy.

2D pixel art.
```

---

# 35. ENERGY 0 — PUTUS

Ini adalah sprite khusus untuk aturan gameplay penting.

```text
Animate the exact TENDRIL character reaching zero energy while in LEPAS mode.

The organism becomes completely exhausted.

The body rapidly loses tension.

The young leaf closes.

The growing tip dims.

The stem collapses and begins to dry.

The detached portion breaks away from its previous growth trail.

The scene should communicate that the newly grown section has died and been severed.

No gore.

Biological drying and collapse.

Dark green shifting toward muted brown.

2D pixel art.
```

---

# 36. JEJAK YANG MENGERING

```text
Create a dead section of vine that was grown while TENDRIL was detached.

The vine is no longer connected to its living node.

It has dried and become brittle.

Green fades into muted brown.

Small leaves droop and disappear.

The living network remains green.

The dead detached trail should clearly contrast with the living network.

2D pixel art environment asset.
```

---

# 37. REGROW DARI NODE TERAKHIR

```text
Animate a new TENDRIL growing from the last living connected growth node.

The old detached section is dead and dry.

The living node remains green.

A tiny new shoot emerges.

The shoot grows upward.

A young leaf unfolds.

The pointed growing tip forms.

The new TENDRIL becomes active.

The new organism must visually match the original master TENDRIL.

Organic regrowth.

2D pixel art.
```

---

# 38. CAMOUFLAGE — TERSEMBUNYI

```text
Create the exact TENDRIL character in TERSEMBUNYI state.

The character is stationary inside dense living foliage.

Its colors closely match the surrounding vines.

The body silhouette becomes difficult to distinguish.

The young leaf blends with nearby leaves.

The growing tip is barely visible.

No glow outline.
No invisibility effect.

Biological camouflage.

Dark atmospheric pixel art.
```

---

# 39. TERDETEKSI

```text
Create the exact TENDRIL character in TERDETEKSI state.

The character remains visually identical.

The organism becomes tense.

The growing tip points toward the source of danger.

The leaf rises slightly.

Add only a subtle yellow warning accent.

Do not recolor the whole character yellow.

2D pixel art game sprite.
```

---

# 40. DIBURU

```text
Create the exact TENDRIL character in DIBURU state.

The organism is highly alert.

The body stretches toward escape.

The growing tip points strongly toward the intended movement direction.

The leaf is tense.

Add a subtle red danger indicator in the surrounding effect or UI.

Do not turn the entire plant red.

The character itself remains green.

2D pixel art.
```

---

# 41. TAHAP 1 — TUNAS BARU

```text
Tiny newborn TENDRIL growing tip.

Very short thin vine.

One tiny young leaf.

One small pointed growing tip.

Almost no branches.

One tiny growth node.

Extremely vulnerable.

2D side-scroller pixel art.
32x32 readable silhouette.
Limited green palette.
Transparent background.
```

---

# 42. TAHAP 2 — MUDA

```text
Young TENDRIL growing tip.

Longer flexible vine body.

One prominent young leaf.

Two or three small branches.

Several small growth nodes.

Healthy bright green growth.

Agile and curious appearance.

Same TENDRIL identity.

2D pixel art.
```

---

# 43. TAHAP 3 — DEWASA

```text
Adult TENDRIL growing tip.

Long flexible S-curve body.

Several small branches.

One or two young leaves.

Multiple growth nodes.

Healthy mature green plant.

Still small compared with a human.

Same original TENDRIL identity.

2D side-scroller pixel art.
```

---

# 44. TAHAP 4 — TUA / KAYU

```text
Old woody TENDRIL.

Same original character anatomy and silhouette.

The central stem has become thicker and partially woody.

Muted brown bark appears along the stem.

Leaves are darker and older.

Growth nodes are larger.

The organism still has the same pointed growing tip.

It must clearly look like an aged version of TENDRIL, not a different plant.

Dark green and muted brown pixel palette.

2D pixel art.
```

---

# 45. TAHAP 5 — TERINFEKSI

```text
Corrupted TENDRIL organism.

Preserve the exact original TENDRIL silhouette and anatomy.

Dark green vine body.

Subtle purple infection spreads through several growth nodes.

Small purple growths appear along the stem.

The young leaf is slightly distorted.

The growing tip remains recognizable.

Purple should be an accent, not the dominant color.

Dark biological atmosphere.

No gore.
No blood.

2D pixel art.
```

---

# 46. MATERIAL INTERACTION SPRITES

Material visual tidak perlu mengubah karakter utama secara permanen.

Gunakan karakter master yang sama.

---

## LEMBAP

```text
TENDRIL attached to a damp wet building surface.

The vine grows rapidly across the moist surface.

Small fresh green shoots appear.

Water droplets are subtle.

Dark pixel art.
```

---

## RETAK

```text
TENDRIL entering cracks in a damaged stone wall.

Thin roots penetrate the crack.

The growing tip disappears partially into the opening.

Small green shoots emerge from the damaged surface.

Pixel art.
```

---

## KABEL

```text
TENDRIL interacting with an electrical cable.

The vine wraps around the cable.

Subtle electrical energy passes through the contact.

Use tiny yellow-white pixel sparks.

Do not turn the plant mechanical.
```

---

## PIPA AIR

```text
TENDRIL growing beside a leaking water pipe.

The plant follows moisture around the pipe.

Tiny fresh leaves grow near the water source.

Dark industrial pixel art.
```

---

## KAYU

```text
TENDRIL growing across a wooden surface.

The vine penetrates small gaps in the wood.

The wood gradually becomes overgrown.

Organic green growth.
```

---

## BETON

```text
TENDRIL attempting to grow across hard concrete.

Growth is slower.

Thin roots follow tiny cracks.

Small growth nodes appear.

Hard industrial environment.
```

---

## LOGAM

```text
TENDRIL interacting with a metal surface.

The vine cannot easily penetrate the intact metal.

It searches for seams, gaps and joints.

The growing tip probes the surface.
```

---

## RACUN / PESTISIDA

```text
TENDRIL exposed to toxic pesticide contamination.

The living green vine develops subtle purple-black contamination.

Small unhealthy nodes appear.

The infection spreads through the connected plant network.

No gore.

Dark biological pixel art.
```

---

# 47. SPRITE UNTUK JARINGAN INDUK

TENDRIL harus memiliki visual berbeda ketika menjadi bagian dari jaringan.

## Prompt

```text
Dense living vine network inside an abandoned building.

This is the home and biological highway of TENDRIL.

Thick interconnected vines cover walls, floors and ceilings.

Small growth nodes form junctions.

Young leaves provide camouflage.

The network should feel alive but mostly stationary.

Dark industrial architecture beneath the vegetation.

Deep green pixel palette.

2D metroidvania environment.
```

---

# 48. NODE RESPAWN

```text
Living TENDRIL growth node.

A small organic green junction embedded in a larger vine network.

The node has a subtle pulsing glow.

A young shoot is beginning to emerge.

This node represents a safe regeneration point.

Clear silhouette.

2D pixel art.
```

---

# 49. SPRITE CHECKLIST

Setiap sprite wajib diperiksa:

```text
[ ] Masih terlihat sebagai TENDRIL?
[ ] Ujung tumbuh masih jelas?
[ ] Daun muda masih ada?
[ ] Sulur masih fleksibel?
[ ] Node masih terlihat?
[ ] Tidak menjadi humanoid?
[ ] Silhouette terbaca pada ukuran kecil?
[ ] Palette konsisten?
[ ] Pixel tidak blur?
[ ] Tidak ada detail yang tidak diperlukan?
[ ] Arah cahaya konsisten?
[ ] Animasi menunjukkan gerak organik?
```

---

# 50. PRIORITAS SPRITE

Jangan membuat semuanya sekaligus.

Urutan yang direkomendasikan:

```text
01 MASTER
02 IDLE
03 MERAMBAT IDLE
04 MERAMBAT MOVE
05 LEPAS
06 FALL
07 LAND
08 JUMP
09 ATTACH
10 DETACH
11 GROW
12 DAMAGE
13 LOW ENERGY
14 ENERGY 0 / PUTUS
15 REGROW
16 TENDRIL
17 HOOK VINE
18 ROOT BURST
19 SPORA
20 PARASIT
21 HIDDEN
22 DETECTED
23 HUNTED
24 STAGE VARIANTS
25 MATERIAL INTERACTION
```

---

# 51. ATURAN REFERENCE

Jika PixelLab memungkinkan reference image:

**Gunakan `TENDRIL_MASTER` sebagai reference utama.**

Untuk setiap animasi:

```text
TENDRIL_MASTER
       ↓
POSE / ACTION
       ↓
ANIMATION
```

Jangan:

```text
PROMPT BARU
   ↓
DESAIN BARU
   ↓
ANIMASI
```

Karena itu akan menyebabkan karakter berubah.

---

# 52. TEMPLATE PROMPT CEPAT

Untuk membuat sprite baru:

```text
Use the exact TENDRIL master character as visual reference.

Action:
[DESCRIBE ACTION]

The character must preserve:
- pointed sensitive growing tip
- one young leaf
- thin flexible vine body
- organic S-curve
- small growth nodes
- same proportions
- same green palette
- same silhouette language

The movement must be plant-like, not humanoid.

No arms.
No legs.
No face.
No clothing.
No animal anatomy.

2D dark atmospheric pixel art.
Side-scroller.
Crisp pixels.
Limited palette.
Transparent background.
```

---

# 53. RULE: ACTION FIRST, DETAIL SECOND

Saat membuat animasi:

Jangan meminta:

```text
beautiful detailed pixel art
```

terlebih dahulu.

Minta:

```text
clear readable movement
```

Karena:

> **Animasi TENDRIL lebih penting daripada detail TENDRIL.**

Gerakan harus memperlihatkan:

- fleksibilitas,
- berat,
- elastisitas,
- ketakutan,
- kenyang,
- kelelahan,
- pertumbuhan.

---

# 54. RULE: TANAMAN TIDAK BERJALAN SEPERTI MANUSIA

Gerakan TENDRIL berasal dari:

```text
curl
stretch
compress
bend
anchor
pull
slide
grow
detach
reattach
```

Bukan:

```text
walk with legs
run with legs
swing arms
```

---

# 55. RULE: LEAF = EMOTION

Daun muda digunakan sebagai bahasa tubuh.

```text
NORMAL
→ daun terbuka ringan

KENYANG
→ daun membuka

TAKUT
→ daun menutup

TERDETEKSI
→ daun naik/tegang

DIBURU
→ daun tertarik ke belakang

LEMAH
→ daun menggantung

MATI
→ daun mengering/menutup
```

Jangan menambahkan wajah.

---

# 56. RULE: GROWING TIP = SENSOR

Ujung tumbuh harus menjadi pusat perhatian.

Gunakan:

```text
bright young green
subtle glow
slight directional movement
```

Untuk status:

```text
normal → soft green
danger → slightly dimmer / tense
toxic → contaminated purple tint
dead → dark brown
```

---

# 57. RULE: MODA HARUS TERLIHAT BERBEDA

## MERAMBAT

Visual:

```text
lebih panjang
lebih rileks
terhubung
weightless
menempel
```

## LEPAS

Visual:

```text
lebih pendek
lebih tegang
dipengaruhi gravitasi
lebih rapuh
bebas
```

Bukan dua karakter berbeda.

Melainkan:

> **satu organisme dalam dua keadaan biologis.**

---

# 58. FINAL MASTER PROMPT

Jika hanya menggunakan satu prompt untuk menghasilkan sprite pertama:

```text
A small young vine growing tip from a massive living plant network inside an abandoned urban building.

2D dark atmospheric pixel art metroidvania game sprite, side-scroller side view.

The organism is approximately 1.2 meters tall when fully extended and clearly smaller than a human.

Thin flexible vine body with a graceful organic S-curve.

Distinct pointed young growing tip at the front, subtly glowing and sensitive to light.

One young leaf near the upper section, used visually for camouflage and body language.

Several tiny growth nodes along the stem, representing future branching points.

The character is a living plant organism, not a humanoid creature.

No arms.
No hands.
No legs.
No feet.
No face.
No eyes.
No mouth.
No clothing.
No armor.
No weapon.
No animal anatomy.
No mechanical anatomy.

The character should feel young, vulnerable, agile, curious and alive.

Readable at 32x32 pixels.

Limited forest-green pixel palette:
deep green shadows,
dark green stem,
medium forest green,
bright plant green,
young leaf green,
small yellow-green glow at the growing tip.

Crisp pixel clusters.
Strong silhouette.
Subtle shading.
No gradients.
No anti-aliasing.
No blurry pixels.

Full body visible.
Centered.
Isolated.
Transparent background.
```

---

# 59. KALIMAT PENGUNCI

Jika PixelLab mulai menghasilkan desain yang menyimpang, tambahkan kalimat ini:

```text
Preserve the exact visual identity of the supplied TENDRIL reference.

Do not redesign the character.

Only change the requested pose, action or state.

The growing tip, young leaf, vine thickness, S-curve silhouette, growth nodes and green palette must remain consistent.
```

---

# 60. DEFINISI AKHIR SPRITE TENDRIL

TENDRIL bukan:

> karakter manusia yang diganti menjadi tanaman.

TENDRIL adalah:

> **tanaman yang kebetulan menjadi karakter utama.**

Maka seluruh sprite harus berbicara melalui:

```text
SULUR
TUNAS
DAUN
NODE
LENTUR
PERTUMBUHAN
CAHAYA
```

Dan seluruh animasi harus terasa seperti:

```text
organisme
```

bukan:

```text
manusia.
```

---

# 61. TARGET HASIL AKHIR

Paket sprite minimal yang harus selesai sebelum implementasi gameplay penuh:

```text
TENDRIL_MASTER

MERAMBAT
├── idle
├── move_8dir
├── attach
├── detach
└── camouflage

LEPAS
├── idle
├── move
├── jump
├── fall
└── land

GROWTH
├── grow
├── node
├── attach_network
└── regrow

ABILITY
├── tendril
├── hook_vine
├── root_burst
├── spora
└── parasit

STATUS
├── hidden
├── detected
├── hunted
├── low_energy
├── damage
└── dead

STAGES
├── tunas_baru
├── muda
├── dewasa
├── tua_kayu
└── terinfeksi
```

---

# 62. URUTAN KERJA PALING AMAN

```text
TENDRIL_MASTER
      ↓
IDLE
      ↓
MERAMBAT
      ↓
LEPAS
      ↓
JUMP / FALL / LAND
      ↓
ATTACH / DETACH
      ↓
GROW
      ↓
ENERGY / DAMAGE
      ↓
DEATH / REGROW
      ↓
ABILITY
      ↓
STAGE VARIANTS
```

Jangan mengerjakan Stage 4/5 atau ability kompleks sebelum Master + movement dasar benar.

---

# 63. GOLDEN RULE

> **Jangan mengejar sprite yang paling detail. Kejar sprite yang paling mudah dikenali ketika hanya dilihat selama 0,2 detik.**

Jika pemain bisa melihat sekilas dan langsung tahu:

> "Itu TENDRIL."

maka sprite tersebut berhasil.
