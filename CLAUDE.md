# Menjalar — konteks proyek

Game 2D pixel art. Pemain adalah tanaman merambat yang tumbuh di fasad gedung
kota. Simulasi berjalan di 240×160 piksel, ditampilkan 960×640.

---

## Lingkungan — jangan salah engine

- **Godot 3.5.3 stable**, GDScript, renderer **GLES2**.
- **BUKAN Godot 4.** API-nya berbeda. Jangan pakai `@onready`, `@export`,
  anotasi tipe gaya Godot 4, `Callable`, `Signal.connect(callable)`,
  `PackedByteArray`, atau `Node2D.position` di tempat `rect_position`.
  Sinyal disambung dengan `obj.connect("nama", self, "_metode")`.
- Array pool memakai nama Godot 3: `PoolByteArray`, `PoolRealArray`.

## Target hardware — ini yang membentuk semua keputusan

PC lawas: **Intel HD Graphics, OpenGL 2.1**, driver 8.15.10.2900.

Batasan keras yang mengikuti:

- **Tanpa shader.** Tidak ada `ShaderMaterial`, tidak ada `.gdshader`.
- **Tanpa Light2D** dan tanpa apa pun dari sistem pencahayaan 2D.
- **Tanpa physics engine.** Tidak ada `RigidBody2D`, `Area2D`, atau
  `KinematicBody2D`. Tabrakan dihitung sendiri lewat grid.
- **Draw call harus minimal.** Jumlah `Sprite` di scene dijaga tetap kecil.

## Aturan render

Semua yang menulis piksel ada di `scripts/PixelCanvas.gd`.

- Render lewat **`Image` + `ImageTexture`**, bukan `_draw()`. Menggambar ribuan
  piksel lewat `_draw()` akan mematikan Intel HD.
- `Image.lock()` / `Image.unlock()` **wajib** mengapit setiap blok `set_pixel`
  dan `get_pixel`.
- `ImageTexture.create_from_image(img, 0)` — flags `0` berarti tanpa filter dan
  tanpa mipmap. Tanpa ini pixel art-nya jadi buram.
- Perbarui tekstur dengan **`texture.set_data(img)`** tiap frame. Jangan pernah
  membuat `ImageTexture` baru per frame.
- Tiga lapis Image, masing-masing satu Sprite: `world` (statis, sekali saat
  load), `tree` (akumulatif, hanya titik terbaru yang digambar ulang), dan
  `overlay` (dibersihkan tiap frame).
- Skala 4× lewat **`Sprite.scale`**, bukan stretch viewport — supaya UI tetap
  tajam sementara game tetap pixel art keras.

## Aturan simulasi

- **Simulasi memakai float; pembulatan ke integer hanya saat render.**
  Menyimpan posisi sebagai integer membuat pertumbuhan tersendat dan bersudut.
- Ukuran dunia: `Config.W = 240`, `Config.H = 160`, `Config.SCALE = 4`.
- Konversi mouse: `get_viewport().get_mouse_position() / float(Config.SCALE)`.

## Aturan struktur kode

- **Semua input mouse dan keyboard HANYA di `main.gd`.** Kalau ada
  `Input.`, `get_global_mouse_position`, atau handler `_input` di file lain,
  itu salah tempat. Node UI berkomunikasi ke `main.gd` lewat sinyal.
- **`Config.gd` hanya berisi `var` dan `const`. Nol fungsi.** Dia AutoLoad
  dengan nama persis `Config` (Project Settings > AutoLoad).
- `WorldMap.grid` adalah `PoolByteArray` sepanjang `W * H` berisi enum terrain.
  Dia melayani tigmotropisme, deteksi air, dan bake cahaya sekaligus.

```
res://
├── main.tscn              root: Node2D, script main.gd
├── main.gd                orkestrator; SATU-SATUNYA yang baca input
└── scripts/
    ├── Config.gd          AutoLoad — hanya var & const, NOL fungsi
    ├── WorldMap.gd        peta + grid terrain + bake cahaya & keterlihatan
    ├── Strand.gd          satu untai: tumbuh, tigmotropisme, pratinjau
    ├── TreeSim.gd         kumpulan untai + ekonomi energi
    ├── Warden.gd          tukang kebun, kerucut pandang, panas, pangkas
    ├── PixelCanvas.gd     semua yang menulis piksel
    ├── TuningPanel.gd     slider runtime
    └── Hud.gd             bar energi/tertutup/terlihat + overlay MULAI
```

---

## Jangan diulang — bug yang sudah pernah diperbaiki

Diambil dari `docs/04-status-proyek.md` §9.

| Bug | Penyebab | Perbaikan |
|---|---|---|
| Pohon seperti cacing gemuk | 1 titik per frame, bukan per piksel | akumulator `_acc`, catat titik tiap 1 px |
| Ekonomi buntu total | `min(air, cahaya)` = 0 karena belum ada daun | beri nilai dasar 1.0 pada air dan cahaya |
| Energi boros tak masuk akal | biaya linear terhadap jumlah ujung, dan terikat `GROWTH_SPEED` | pangkat `COST_TIP_EXP`, lepas dari `GROWTH_SPEED` |
| Panas 98% di malam pertama | `heat += seen * NIGHT_HEAT` tanpa `delta` | tambah `* delta` + ambang `vis > 0.45` |
| Ujung mengorbit kursor | sudut target dihitung walau kursor sangat dekat | `DEAD_ZONE` 7 px — di dalamnya, tumbuh lurus |
| Ujung mati di tepi layar | tidak ada pantulan | pantul sudut di tepi |
| `z_index` pada `ColorRect` | `ColorRect` adalah `Control`, bukan `Node2D` | pindah ke `CanvasLayer` terpisah |
| Fotosintesis jalan malam hari | tidak dicek fase | energi hanya bertambah saat `PHASE_DAY` |
| Permainan buntu setelah keruntuhan besar | ujung sulur yang kehilangan fasad dimatikan permanen, padahal satu rantai melubangi sampai 20 dari 31 member sekaligus | ujung **mundur** ke titik terakhir yang masih menempel, lalu lanjut hidup (`Strand.retreat_to_facade`) |
| STRUKTUR 0% tapi gedung tetap berdiri | member hanya garis 3 px; menghancurkan seluruh rangka cuma menghapus 31 garis tipis dari persegi panjang padat | `WorldMap.panels` — massa dinding jatuh menyusul rangkanya (`Structure._runtuhkan_panel`) |
| Sulur terkurung di panel fasad | lubang keruntuhan selebar 3 px diperlakukan seperti langit, karena bagi sulur "solid" berarti bukan-fasad | `WorldMap.vine_ok()` — sulur boleh merentang `VINE_JEMBATAN` piksel. **Semua** cek pijakan sulur harus lewat `vine_ok()`, bukan `on_facade()` mentah, atau perbaikannya batal sendiri |

---

## Arah saat ini

Proyek sedang **bergeser dari stealth-coverage ke pembongkaran struktural.**

Konsep lama: sulur menutupi 55% fasad tanpa ketahuan tukang kebun.
Konsep baru: gedung punya rangka (kolom, balok, sambungan) dengan aliran beban.
Tanaman melemahkan sambungan sampai struktur runtuh berantai. Puing yang jatuh
jadi tanah baru untuk dipanjat.

Urutan kerja bertahap ada di **`docs/05-prompt-pivot-pembongkaran.md`**
(TAHAP 0 sampai TAHAP 8). Kerjakan **satu tahap per sesi**, commit tiap tahap
yang sudah terverifikasi jalan.

Status pivot: **TAHAP 0–5 selesai secara kode. Berikutnya TAHAP 6 (puing jadi
tanah baru).**

TAHAP 2–5 sudah dijalankan di Godot dan berjalan tanpa error. Keruntuhan
berantai plus getaran layar dinilai pemilik proyek sudah terasa menarik — jadi
gerbang verifikasi TAHAP 3 lolos dan konsep pivotnya terbukti.

Sisa yang diketahui: lubang hasil keruntuhan selebar 3 piksel memotong fasad
jadi panel-panel terpisah, dan sulur tidak bisa menyeberanginya karena bagi
sulur "solid" berarti bukan-fasad. TAHAP 6 (puing jadi terrain baru) yang
seharusnya membuka jalur lagi.

Sistem yang sudah ada dari pivot:

- `WorldMap.members` / `.joints` — rangka 4 kolom × 5 balok, disimpan sebagai
  31 ruas antar-joint. `solve_order` sudah topologis atas-ke-bawah.
- `WorldMap.kapasitas(m)` — satu-satunya sumber kebenaran kapasitas:
  `integritas_member * min(integritas kedua joint) * KAPASITAS_MAX`.
- `WorldMap.panels` — 12 panel dinding di antara rangka. **Inilah massa gedung
  yang sebenarnya**; member cuma garis selebar 3 px. Panel jatuh saat
  `PANEL_AMBANG` dari 4 member yang mengurungnya sudah gagal.
- `Structure.gd` — solve beban, keruntuhan berantai per gelombang, puing,
  debu, panel, dan pelemahan oleh tanaman.
- Sulur menyerang joint, akar menyerang ruas kolom paling bawah.
- `WorldMap.vine_ok()` — predikat pijakan sulur, mengizinkan rentangan
  `VINE_JEMBATAN` px melewati celah sempit.

Kondisi menang: `Structure.hancur()` — tidak ada KOLOM tersisa. Sengaja bukan
"semua member mati", karena balok level dasar berdiri di pondasi sehingga tidak
pernah gagal karena kehilangan tumpuan, dan tidak terjangkau akar maupun sulur
setelah fasadnya lenyap. Syarat coverage 55% sudah dihapus seluruhnya.

Dokumen `docs/01-konteks-game.md` dan `docs/02-logika-game.md` adalah rancangan
prototipe asli. Yang masih berlaku dari keduanya: palet warna, teknik render
240×160 skala 4×, prinsip float-untuk-simulasi, batas kecepatan belok
(`MAX_TURN`), dan ekonomi `min(Air, Cahaya)`. Tata letak level dan daftar
konstanta di sana **sudah tidak berlaku** — lihat `docs/04-status-proyek.md` §2.
