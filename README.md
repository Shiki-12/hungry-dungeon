# Hungry Dungeon

Game memasak co-op 2D pixel art bergaya Overcooked bertema kuliner Nusantara dan dungeon fantasy, dikembangkan menggunakan **Godot 4.7**.

---

## 1. Deskripsi Game

*Hungry Dungeon* adalah game aksi memasak kooperatif murni **2 Pemain (2P Lokal & 2P Online)**. Pemain berperan sebagai koki Nusantara (**Rangga** dan **Sekar**) yang harus menyajikan hidangan lezat untuk memuaskan pelanggan monster lapar di dapur dungeon sebelum mereka mengamuk.

### Mekanik Kunci:
- **Kuali Dua Mode (Dual-Use Pan):** Kuali berfungsi ganda sebagai alat memasak utama sekaligus senjata pemukul monster mengamuk. Jika dipakai memukul saat berisi bahan/masakan, masakan akan tumpah (-25 poin) dan kuali terkunci selama 4 detik.
- **Lempar Bidik Busur (Arc Throwing):** Bahan mentah dan hidangan jadi dapat dilempar melintasi dapur atau langsung ke meja monster. Menampilkan garis trajektori parabola dan zona bidik **Jitu** (+25 poin, +5 kepuasan).
- **Co-op Wajib 2 Pemain:** Tidak ada mode 1 pemain atau pergantian koki (*no cook swapping*). Kedua pemain harus bekerja sama secara simultan.

---

## 2. Spesifikasi Teknis & Cara Menjalankan

### Spesifikasi Teknis
- **Engine:** Godot 4.7.x stable
- **Renderer:** `gl_compatibility` (WebGL 2 / OpenGL 3.3, kompatibel untuk web export single-thread)
- **Bahasa:** GDScript murni dengan **Static Typing penuh**
- **Resolusi Viewport:** `480x270` px (Aspect: `keep`, Stretch Mode: `viewport`, Scale: `integer`)
- **Resolusi Jendela Standar:** `1920x1080` (skala 4x), minimum `960x540` (skala 2x)
- **Physics Tick:** `60 Hz` deterministik
- **Tekstur:** Default filter `Nearest` (0), snap transform & vertex 2D aktif

### Tata Letak Layar (480x270 px)
- **HUD Atas (480x30 px):** Tiket pesanan monster, skor tim, timer level.
- **Area Dapur (480x224 px):** 30x14 tile (ukuran 1 tile = 16x16 px), kamera tetap tanpa scroll.
- **HUD Bawah (480x16 px):** Hati Dapur (5 max), ikon skill dan kontrol bantuan.

### Cara Menjalankan Proyek
1. Unduh dan buka **Godot Engine 4.7.x** (versi Standard / non-.NET).
2. Pilih **Import** lalu arahkan ke direktori root proyek ini (`project.godot`).
3. Tekan **F5** untuk menjalankan scene utama atau jalankan scene tes dapur langsung di `res://levels/test_kitchen.tscn` (**F6**).

---

## 3. Skema Kontrol Sementara

| Aksi | Pemain 1 (Rangga) | Pemain 2 (Sekar) | Gamepad (P1 / P2) |
| :--- | :--- | :--- | :--- |
| **Gerak (8 Arah)** | `W`, `A`, `S`, `D` | Tombol Panah (`↑`, `↓`, `←`, `→`) / Numpad `8, 2, 4, 6` | Stik Kiri / D-Pad |
| **Interaksi (Ambil / Taruh)** | `E` | `Numpad 1` / `K` | Tombol Bawah / `A` |
| **Kerja (Potong / Ulek)** | `F` | `Numpad 2` / `L` | Tombol Kiri / `X` |
| **Pukul (Sutil / Kuali)** | `Spasi` | `Numpad 0` / `Enter` / `M` | Tombol Kanan / `B` |
| **Skill 1 (Dash / Teleport)** | `Q` | `Numpad 7` / `U` | Tombol Atas / `Y` |
| **Skill 2 (Buff Kecepatan / Api)** | `R` | `Numpad 9` / `O` | Bumper Kanan (`RB` / `R1`) |
| **Lempar (Ketuk / Tahan Bidik)** | `C` | `Numpad 3` / `I` | Bumper Kiri (`LB` / `L1`) |
| **Jeda (Pause)** | `Escape` | `Numpad .` / `\` | Tombol `Start` |

---

## 4. Struktur Folder Proyek

```text
res://
├── autoload/        # 6 Singleton: Game, Net, Save, Audio, Events, Settings
├── sim/             # Logika simulasi murni tanpa node visual (headless compatible)
│   ├── entities/    # cook.gd, monster, stasiun, item
│   └── systems/     # throw_math.gd, orders, scoring, hazards
├── view/            # Tampilan visual koki (cook_view.gd), Sprite, VFX, animasi
├── ui/              # HUD, menu utama, dialog, peta dunia
├── data/            # Custom Resource (.gd & .tres): item, resep, stasiun, monster, level
├── levels/          # Scene level dapur (test_kitchen.tscn, level_1_1, dst.)
├── tests/           # Unit test simulasi headless (test_throw_math.gd)
└── docs/            # Dokumentasi PRD Teknis dan Daftar Aset Game
```

### Aturan Pemisahan Simulasi (`sim/`) dan Tampilan (`view/`)
- Folder `sim/` **dilarang memuat visual/audio nodes** (`Sprite2D`, `AnimationPlayer`, `AudioStreamPlayer`, UI) agar dapat berjalan di dedicated server Godot headless.
- Komunikasi antar sistem menggunakan bus sinyal global `Events` (`res://autoload/events.gd`).
- Semua parameter gameplay berbasis data di `res://data/`.

---

## 5. Ringkasan Roadmap & Status

| Milestone | Target | Status |
| :--- | :--- | :--- |
| **M0: Persiapan** | Setup proyek, resolusi 480x270, 6 Autoload, Custom Resource data, rumus lempar, scene dapur uji `test_kitchen.tscn` dengan 2 koki. | **SELESAI** |
| **M1: Prototipe Stage 1** | Implementasi entitas item & piring, stasiun dasar (cobek, talenan, tungku), Goblin, Kuali Dua Mode, level 1-1 s/d 1-4. | **TARGET BERIKUTNYA** |
| **M2: Vertical Slice** | Mekanik lempar bidik busur penuh, tutorial T-1 s/d T-5, skill Dash, HUD dinamis, playtest internal pertama. | Menunggu |
| **M3: Konten Stage 2–5** | Resep lanjutan Nusantara, monster baru (Kadal, Ogre, Hantu, Boss Sang Ageng), hazard dinamis, combo skill. | Menunggu |
| **M4: Polish & Rilis 1.0** | Integrasi SFX & BGM, penyeimbangan data, save game atomik, ekspor Windows 64-bit dan Web HTML5 ke itch.io. | Menunggu |
| **M5: Online Beta** | Server Godot headless otoritatif di AWS Fargate, Lobby API (WebSocket), sinkronisasi 2P online. | Menunggu |
| **M6: Online Rilis** | Observabilitas CloudWatch, hardening, rilis publik fitur co-op online. | Menunggu |
