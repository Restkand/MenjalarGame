# TENDRIL — ART DIRECTION REVIEW
## Evaluasi TENDRIL_MASTER & Keputusan Pipeline Sprite

**Status:** ART REVIEW
**Master Candidate:** A
**Keputusan:** LOCK MASTER A
**Tahap:** Seleksi → Refinement → Implementasi Prototype Godot

> Dokumen keputusan PEMILIK PROYEK (art director) — kanon keempat.
> Ringkasan keputusan operasional ada di §24 Final Decision Log.

---

# 1. RINGKASAN KEPUTUSAN

Setelah melihat contact sheet hasil generasi sprite, **TENDRIL_MASTER A dipilih sebagai master resmi** untuk rantai animasi berikutnya.

Alasan utama:

- S-curve sangat jelas.
- Ujung tumbuh langsung terbaca.
- Satu daun menjadi identitas visual.
- Tubuh cukup tipis untuk terasa seperti sulur.
- Bagian bawah memberi kesan menumpu tanpa menjadi kaki.
- Karakter tetap terlihat sebagai tanaman ketika ukurannya kecil.
- Siluet memiliki cukup fleksibilitas untuk dikembangkan menjadi MERAMBAT dan LEPAS.
- TENDRIL terasa seperti organisme yang dapat mengubah bentuk, bukan karakter yang hanya menjalankan animasi berjalan.

**Keputusan:**

> Jangan reroll desain keseluruhan TENDRIL_MASTER A.

Yang diperlukan hanya **micro-refinement** pada beberapa detail anatomi.

---

# 2. NORTH STAR VISUAL

Identitas utama TENDRIL:

> **SULUR + TUNAS + KEHIDUPAN**

Dan prinsip visual:

> **Kecil sebagai individu, besar sebagai jaringan.**

TENDRIL bukan:

- manusia hijau,
- monster humanoid,
- ular,
- naga,
- tentakel,
- pohon mini,
- bunga berjalan.

TENDRIL adalah:

> **ujung pertumbuhan dari jaringan tanaman yang hidup.**

---

# 3. EVALUASI MASTER A

## 3.1 Yang Sudah Berhasil

### S-Curve

Siluet S-curve sudah menjadi ciri khas yang kuat.

Ini penting karena tubuh TENDRIL harus dapat:

- melengkung,
- memanjang,
- menciut,
- menekuk,
- menarik diri,
- mengikuti permukaan.

S-curve menjadi fondasi semua animasi tersebut.

---

## 3.2 Ujung Tumbuh

Ujung tumbuh sudah terlihat dan menjadi titik fokus.

Namun masih ada satu masalah kecil:

> Pada beberapa frame, ujung tumbuh mulai terlihat seperti batang yang terpotong, bukan tunas sensitif.

Karena itu, refinement berikutnya harus memperjelas bentuk ujung tumbuh tanpa mengubah desain utama.

### Target:

```text
UJUNG TUMBUH
    →
lebih runcing
lebih organik
lebih mudah dibaca
sedikit bercahaya
menjadi titik fokus
```

Jangan membuatnya menjadi:

- kepala manusia,
- mata,
- mulut,
- wajah,
- bunga besar.

---

# 4. HIERARKI ANATOMI

Hierarki visual yang harus dipertahankan:

```text
        ✦ UJUNG TUMBUH
              ↓
          DAUN MUDA
              ↓
            SULUR
              ↓
             NODE
```

**Ujung tumbuh harus menjadi "wajah" TENDRIL walaupun TENDRIL tidak memiliki wajah.**

Ini berarti perhatian pemain diarahkan melalui:

- bentuk,
- cahaya,
- arah gerak,
- posisi,
- perubahan postur.

Bukan melalui ekspresi wajah.

---

# 5. DAUN MUDA

Daun saat ini sudah cukup kuat sebagai identitas.

**Jangan memperbesar daun secara drastis.**

Fungsinya bukan sekadar dekorasi.

Daun adalah bagian dari bahasa tubuh TENDRIL.

### Bahasa daun:

| Kondisi | Perilaku daun |
|---|---|
| Normal | sedikit terbuka |
| Kenyang | membuka |
| Takut | menutup |
| Terdeteksi | naik / tegang |
| Diburu | tertarik ke belakang |
| Lemah | menggantung |
| Mati | menutup / mengering |

Dengan demikian TENDRIL dapat memiliki kepribadian tanpa wajah.

---

# 6. SULUR

Sulur adalah tubuh utama.

Karakteristik yang harus dipertahankan:

- tipis,
- fleksibel,
- S-curve,
- organik,
- dapat squash/stretch,
- dapat memanjang,
- dapat menciut.

Jangan membuatnya terlalu tebal.

Jika sulur terlalu tebal:

> TENDRIL mulai terlihat seperti monster atau pohon kecil.

---

# 7. NODE

Node harus tetap kecil.

Fungsinya:

- memberi kesan biologis,
- menunjukkan calon percabangan,
- menghubungkan TENDRIL dengan jaringan induk,
- menjadi titik pertumbuhan,
- menjadi titik regenerasi.

Node jangan menjadi ornamen yang memenuhi tubuh.

---

# 8. EVALUASI ANIMASI

Contact sheet menunjukkan bahwa identitas karakter relatif stabil antar-frame.

Ini adalah hasil yang sangat penting.

Prioritas kita bukan membuat setiap frame sangat detail.

Prioritas:

> **Karakter harus tetap menjadi TENDRIL ketika bergerak.**

Konsistensi silhouette lebih penting daripada detail kecil.

---

# 9. IDLE

Idle sudah cukup baik untuk prototype.

Fungsi idle:

> Membuktikan bahwa TENDRIL adalah organisme hidup bahkan ketika pemain tidak melakukan apa-apa.

Gerakan yang diinginkan:

```text
batang sedikit mengembang
        ↓
batang sedikit mengecil
        ↓
daun bergerak
        ↓
ujung tumbuh berdenyut
        ↓
kembali ke posisi awal
```

Target:

**4–8 frame**

Idle tidak boleh terlalu dramatis.

Jika idle terlalu besar, karakter akan terlihat seperti sedang melakukan action.

---

# 10. MERAMBAT

MERAMBAT sudah berada di arah yang benar.

Hal yang harus dipertahankan:

- tidak menggunakan gravitasi,
- tidak memiliki langkah kaki,
- tubuh meliuk,
- tubuh mengikuti jaringan,
- karakter terasa ringan,
- gerak berasal dari curl/stretch/bend.

Gerakannya harus terasa seperti:

```text
CURL
  ↓
STRETCH
  ↓
BEND
  ↓
PULL
  ↓
REPEAT
```

Bukan:

```text
LEFT LEG
  ↓
RIGHT LEG
  ↓
LEFT LEG
```

---

# 11. PERBAIKAN MERAMBAT

Ada satu peningkatan penting yang disarankan:

> **Ujung tumbuh harus menarik tubuh.**

Artinya bukan seluruh tubuh bergerak sebagai satu objek.

Idealnya:

```text
FRAME 01

       ✦
      /
    ╭
   ╰──╮


FRAME 02

        ✦
       /
     ╭
    ╰──╮


FRAME 03

          ✦
         /
       ╭
      ╰──╮
```

Konsepnya:

> **Growing Tip mencari jalan → tubuh mengikuti.**

Ini akan membuat MERAMBAT terasa lebih biologis.

---

# 12. LEPAS

LEPAS adalah salah satu animasi terpenting.

Karena pemain harus dapat merasakan perbedaan:

## MERAMBAT

> Saya adalah bagian dari jaringan.

## LEPAS

> Saya sekarang sendirian.

Perbedaan ini harus terasa secara visual, bukan hanya melalui kode.

---

# 13. VISUAL LEPAS

LEPAS sebaiknya memiliki:

- tubuh sedikit lebih tegang,
- S-curve lebih pendek,
- ujung tumbuh lebih terarah,
- daun lebih banyak bergerak,
- gravitasi lebih terasa,
- squash/stretch lebih jelas.

Perbandingan:

```text
MERAMBAT
────────────────
relaxed
weightless
connected
fluid
network-oriented


LEPAS
────────────────
tense
gravity
vulnerable
independent
movement-oriented
```

Prinsip:

> **MERAMBAT = bebas**

> **LEPAS = hidup tetapi rentan**

---

# 14. DETACH

Detach harus terlihat seperti organisme benar-benar melepaskan diri dari jaringan.

Urutan visual:

```text
NETWORK
   ↓
TENDRIL TERHUBUNG
   ↓
BATANG MENEGANG
   ↓
KONEKSI MENIPIS
   ↓
KONEKSI PUTUS
   ↓
TENDRIL BEBAS
```

Jangan menggunakan:

- teleport,
- fade out,
- pergantian sprite tiba-tiba,
- efek mekanis.

Detach harus terasa biologis.

---

# 15. ATTACH

Attach adalah kebalikan dari detach.

Urutan:

```text
TENDRIL BEBAS
      ↓
UJUNG MENYENTUH JARINGAN
      ↓
KONEKSI MULAI TERBENTUK
      ↓
TUBUH MENARIK DIRI
      ↓
MENYATU DENGAN JARINGAN
      ↓
MERAMBAT
```

Prinsip:

> Jaringan tidak sekadar menjadi platform. Jaringan adalah rumah dan tubuh TENDRIL.

---

# 16. HUBUNGAN SPRITE DENGAN GAMEPLAY

Visual TENDRIL harus mendukung gameplay inti:

```text
MERAMBAT
    →
8 arah
    →
menempel
    →
masuk celah
    →
energi pulih
    →
camouflage

LEPAS
    →
gravitasi
    →
platformer
    →
energi terkikis
    →
aksi khusus
    →
kembali ke jaringan
```

Dengan demikian, perubahan visual antara mode bukan kosmetik.

Ia menjelaskan keadaan gameplay kepada pemain.

---

# 17. KEPUTUSAN MASTER

## STATUS

**MASTER A = LOCKED**

Jangan membuat kandidat baru kecuali ditemukan masalah fundamental.

### Yang dikunci:

- silhouette,
- proporsi,
- jumlah daun,
- bentuk sulur,
- S-curve,
- ukuran relatif,
- palet,
- identitas anatomi.

### Yang masih boleh direfine:

- ujung tumbuh,
- artikulasi kecil sulur,
- posisi node,
- timing animasi,
- secondary motion daun.

---

# 18. URUTAN PIPELINE BERIKUTNYA

Pipeline yang direkomendasikan:

```text
             TENDRIL_MASTER A
                    │
                    ▼
             ┌─────────────┐
             │ REFINEMENT  │
             │ Growing Tip │
             └──────┬──────┘
                    │
                    ▼
          ┌───────────────────┐
          │   GODOT AVATAR    │
          └─────────┬─────────┘
                    │
          ┌─────────┴─────────┐
          ▼                   ▼
      MERAMBAT              LEPAS
          │                   │
          ▼                   ▼
      8-DIRECTION          GRAVITY
          │                   │
          └─────────┬─────────┘
                    ▼
               DETACH / ATTACH
                    │
                    ▼
                 PLAYTEST
                    │
          ┌─────────┴─────────┐
          ▼                   ▼
       TERASA                 TIDAK
        HIDUP                  HIDUP
          │                     │
          ▼                     ▼
        LOCK                 REROLL
```

---

# 19. JANGAN LANGSUNG MEMBUAT JUMP/FALL/LAND

Walaupun Jump/Fall/Land sudah ada dalam pipeline, **jangan langsung mengerjakannya sekarang.**

Prioritas berikutnya adalah:

```text
MASTER
 ↓
MERAMBAT
 ↓
LEPAS
 ↓
DETACH
 ↓
ATTACH
 ↓
GODOT PLAYTEST
```

Alasannya:

Kita perlu menjawab pertanyaan:

> **Apakah TENDRIL terasa seperti makhluk hidup ketika dikendalikan?**

Bukan hanya:

> Apakah sprite-nya bagus?

---

# 20. SETELAH PLAYTEST

Jika movement dasar terasa benar:

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
DEATH / CUT
 ↓
REGROW
 ↓
ABILITY
```

Baru kemudian:

```text
TENDRIL
HOOK VINE
ROOT BURST
SPORA
PARASIT
```

---

# 21. PRIORITAS REROLL

Jika hanya boleh melakukan satu reroll:

### Prioritas #1

**LEPAS**

Karena LEPAS harus menjual perasaan:

> "Saya sekarang sendirian."

### Prioritas #2

**MERAMBAT**

Fokus pada:

> ujung tumbuh menarik tubuh.

### Prioritas #3

**IDLE**

Saat ini sudah cukup baik.

### Prioritas #4

**DETACH / ATTACH**

Pertahankan dulu sampai prototype gameplay dapat dimainkan.

---

# 22. ART DIRECTION GOLDEN RULE

> **Jangan mengejar sprite yang paling detail. Kejar sprite yang paling mudah dikenali ketika hanya dilihat selama 0,2 detik.**

Jika pemain melihat sprite sekilas dan langsung berpikir:

> **"Itu TENDRIL."**

maka sprite tersebut berhasil.

---

# 23. KESIMPULAN ART DIRECTOR

TENDRIL sekarang sudah memiliki **bahasa visual yang cukup kuat untuk dikunci**.

Kita tidak perlu lagi mencari desain karakter baru.

Tahap berikutnya bukan eksplorasi bentuk.

Tahap berikutnya adalah:

> **membuat bahasa visual tersebut terasa hidup ketika dimainkan.**

Fokus:

```text
IDENTITY
   ↓
MOVEMENT
   ↓
FEEL
   ↓
GAMEPLAY
```

Bukan:

```text
DETAIL
   ↓
DETAIL
   ↓
DETAIL
```

---

# 24. FINAL DECISION LOG

| Item | Keputusan |
|---|---|
| Master A | **LOCK** |
| Master B | Reject |
| Master C | Reject |
| Idle | Keep |
| Merambat | Keep + refine |
| Lepas | **Refine / possible reroll** |
| Detach | Keep |
| Attach | Keep |
| Growing Tip | **Micro-refinement** |
| Daun | Lock |
| S-Curve | Lock |
| Palette | Lock |
| Jump | Belum |
| Fall | Belum |
| Land | Belum |
| Godot AvatarView | **Prioritas berikutnya** |

---

# 25. STATUS PROYEK

**TENDRIL CHARACTER DESIGN**

```text
[✓] Konsep karakter
[✓] Anatomi
[✓] Palet
[✓] Master candidate
[✓] Master A selected
[✓] Idle prototype
[✓] Merambat prototype
[✓] Lepas prototype
[✓] Detach prototype
[✓] Attach prototype

[ ] Master refinement
[ ] Godot AvatarView
[ ] Movement playtest
[ ] Jump
[ ] Fall
[ ] Land
[ ] Growth
[ ] Energy
[ ] Death / Cut
[ ] Regrow
[ ] Abilities
```

---

# 26. ART DIRECTION STATEMENT

> **TENDRIL bukan tanaman yang diberi kaki.**
>
> **TENDRIL adalah kehidupan yang sedang mencari tempat untuk tumbuh.**
>
> Ia melengkung ketika bergerak.
>
> Ia mengecil ketika takut.
>
> Ia membuka daun ketika kenyang.
>
> Ia menempel ketika merasa aman.
>
> Ia melepaskan diri ketika harus menjelajah.
>
> Dan ketika bagian yang terlepas mati, kehidupan tidak benar-benar berakhir—
>
> **ia tumbuh kembali dari jaringan yang masih hidup.**
