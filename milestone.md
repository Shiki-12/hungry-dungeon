# Master Milestone & Autonomous AI Execution Plan — Koki Dungeon (v1.0)

> **Acuan Utama:**
> 1. `docs/PRD Teknis v1.0 Koki Dungeon (Working Title).md` (**Satu-satunya acuan teknis utama**)
> 2. `docs/Daftar Aset Game Koki Dungeon (Working Title) (2).pdf` (Daftar ID aset, ukuran frame, & palet)
> 3. **Revisi Mutlak Proyek:** Game ini **WAJIB 2 PEMAIN (Co-op Murni: 2P Lokal di Fase 1 & 2P Online di Fase 2)**. Seluruh fitur 1 pemain (`swap_cook`, tombol `Tab`, `FR-MOV-05`, dan `FR-SKL-10`) **DIHAPUS & DILARANG DIIMPLEMENTASIKAN**.

---

## Protokol Eksekusi Mandiri untuk AI Agent (Wajib Dipatuhi)

Setiap kali AI Agent diminta mengerjakan milestone dari file ini, ikuti siklus **5 Langkah Anti-Rusak** berikut:

1. **Baca Target Sub-Milestone Aktif:** Ambil satu sub-milestone berstatus `[ ]` paling atas (misal `M0.2`). Jangan melompati urutan sub-milestone.
2. **Audit File Eksisting:** Baca file yang sudah ada di proyek (lihat bagian *Baseline Kondisi Proyek* di bawah) agar tidak merusak fungsi yang sudah berjalan, namun wajib me-*refactor* file versi v0.1 agar patuh penuh pada **PRD Teknis v1.0**.
3. **Implementasi Kode & Data:**
   - Gunakan **GDScript Godot 4.7.x** dengan **Static Typing penuh** (`var x: int = 0`, `func tick(dt: float) -> void:`).
   - Pastikan `res://sim/` **100% murni logika** (tanpa `Sprite2D`, `AnimationPlayer`, `AudioStreamPlayer`, UI, maupun `CharacterBody2D`).
   - Gunakan hanya **ID String aset** (contoh: `"cook_rangga"`, `"item_bawang_raw"`). Dilarang memakai `preload("res://assets/...")` di luar `res://view/` dan `res://autoload/assets.gd` (`FR-AST-01`).
4. **Verifikasi Mandiri (Self-Check & Unit Test):**
   - Buat atau perbarui *script* pengujian di `res://tests/` untuk sub-milestone tersebut.
   - Jalankan verifikasi via terminal *headless* Godot:
     `godot --headless --script res://tests/run_tests.gd` (atau *script* tool terkait seperti `res://tools/sync_assets.gd`).
   - Jika terdapat *error* kompilasi GDScript, *warning* tipe data, atau *test* gagal, **perbaiki kode terlebih dahulu** sampai keluar dengan kode `0` (*PASS*).
5. **Update Checklist:** Setelah verifikasi lulus, ubah kotak `[ ]` menjadi `[x]` pada `milestone.md`, lalu laporkan kesiapan untuk lanjut ke sub-milestone berikutnya.

---

## Baseline Kondisi Proyek Saat Ini (Hasil Audit `tree /f`)

Berdasarkan struktur repositori saat ini:
- **Sudah Ada (Fondasi Awal v0.1):**
  - Root: `.gitattributes`, `.gitignore`, `GEMINI.md`, `project.godot`, `README.md`, `milestone.md`.
  - `res://autoload/`: `audio.gd`, `events.gd`, `game.gd`, `net.gd`, `save.gd`, `settings.gd`.
  - `res://data/`: `item_data.gd`, `level_data.gd`, `monster_data.gd`, `recipe_data.gd`, `station_data.gd`, `step_data.gd`.
  - `res://sim/`: `entities/cook.gd`, `systems/throw_math.gd`.
  - `res://view/`: `cook_view.gd`.
  - `res://levels/`: `test_kitchen.gd`, `test_kitchen.tscn`.
  - `res://tests/`: `test_throw_math.gd`.
- **Gap Terhadap PRD Teknis v1.0 (Wajib Di-upgrade di M0 & M1):**
  - Belum ada Autoload ke-7 `res://autoload/assets.gd` dan sistem placeholder `box_<warna>` (`§5`).
  - Belum ada folder `data/assets/`, `assets/_incoming/`, `assets_src/`, `reports/`, `tools/`, `locale/`, `net/`.
  - `res://data/*.gd` perlu dilengkapi properti barunya sesuai `§4.5` PRD v1.0 (seperti `plate_count`, `washing_enabled`, `max_open_tickets`, `attention`, `SeatingData`, `SpriteSetData`, `FacingMapData`, `EmoteMapData`).
  - `res://sim/entities/cook.gd` dan `test_kitchen.tscn` perlu dipastikan bebas dari `CharacterBody2D` dan beralih ke sistem tabrakan deterministik `res://sim/systems/collision.gd` (`FR-MOV-08`).

---

## MILESTONE M0: Persiapan, Arsitektur v1.0, & Sistem Aset Placeholder (`§4, §5, §6, §20`)
**Kriteria Selesai M0:** Proyek patuh struktur PRD v1.0, sistem `Assets` & `PlaceholderFactory` (`box_<warna>`) aktif, `sync_assets.gd` menghasilkan `index.json` & laporan tanpa `INVALID`, `anim_gallery.tscn` memutar semua ID M1, dan *test runner* headless berjalan bersih.

### M0.1 — Penyelarasan Struktur Folder, Konfigurasi Proyek, & Input 2 Pemain (`§4.1–4.3, §6`)
- **Referensi PRD v1.0:** `§2`, `§4.1`, `§4.2`, `§4.3`, `§6` (Tanpa `swap_cook`).
- **Checklist Tugas:**
  - [x] Inisialisasi Git (`main`), `.gitignore`, `.gitattributes` (Git LFS), dan `README.md`.
  - [x] Konfigurasi dasar `project.godot` (Viewport $480 \times 270$, Window $1920 \times 1080$, Stretch `viewport` + `integer`, renderer `gl_compatibility`, physics $60\text{ Hz}$).
  - [x] Buat seluruh direktori standar PRD v1.0 `§4.2` yang belum ada:
    - `res://data/assets/`, `res://data/levels/`, `res://data/recipes/`, `res://data/monsters/`, `res://data/skills/`, `res://data/hazards/`, `res://data/tutorial/`
    - `res://assets/_incoming/`, `res://assets_src/`, `res://reports/`, `res://tools/`, `res://net/`, `res://locale/`
  - [x] Audit `project.godot` Input Map khusus **Wajib 2 Pemain** (`§6`):
    - **P1 (`p1_*`):** `move_up` (W), `move_down` (S), `move_left` (A), `move_right` (D), `interact` (E), `work` (F), `strike` (Space), `skill_1` (Q), `skill_2` (R), `throw` (C), `pause` (Esc), serta dukungan Gamepad 0.
    - **P2 (`p2_*`):** `move_up` (Up), `move_down` (Down), `move_left` (Left), `move_right` (Right), `interact` (Period `.`), `work` (Comma `,`), `strike` (Slash `/`), `skill_1` (Semicolon `;`), `skill_2` (Apostrophe `'`), `throw` (Right Shift), `pause` (Backspace/Start), serta dukungan Gamepad 1.
    - Pastikan aksi `swap_cook` **tidak ada** di `project.godot` maupun di kode.
  - [x] Buat kerangka *test runner* mandiri `res://tests/run_tests.gd` (berbasis `SceneTree` untuk mengeksekusi semua `res://tests/test_*.gd` via `godot --headless --script res://tests/run_tests.gd` dan keluar dengan kode `0` jika semua lulus, atau `1` jika ada yang gagal).
- **Verifikasi AI:** Jalankan `godot --headless --script res://tests/run_tests.gd` dan pastikan `test_throw_math.gd` dieksekusi dan lulus.

### M0.2 — Upgrade Skema Resource Data ke Standar PRD v1.0 (`§4.5, §7, §8, §9.4, §13`)
- **Referensi PRD v1.0:** `§4.5`, `§5.5`, `§7`, `§8.4–8.8`, `§9.4`, `§13.2`.
- **Checklist Tugas:**
  - [x] Buat `res://data/sprite_set_data.gd` (`class_name SpriteSetData`) sesuai spesifikasi `§5.5` (`id`, `prefix`, `frame_size`, `pivot`, `anims`, `placeholder`, `status`).
  - [ ] Perbarui `res://data/item_data.gd` (`class_name ItemData`): `id: StringName`, `category: StringName` (`INGREDIENT`, `DISH`, `COOKWARE`, `PLATE`, `SNACK`), `form: StringName` (`raw`, `prepped`, `cooked`, `burnt`), `container: StringName`, `sprite_id: StringName`, `icon_id: StringName`, `can_throw: bool`, `components: Array[StringName]`.
  - [ ] Perbarui `res://data/step_data.gd` (`class_name StepData`): `type: StringName` (`CHOP`, `MIX`, `COOK`, `FRY`, `BOIL`, `WILT`, `WRAP`, `STEAM`, `GRILL`, `POUND`, `ASSEMBLE`), `inputs: Array[StringName]`, `output: StringName`, `station_type: StringName`, `duration: float`, `rhythm_bpm: int`, `rhythm_beats: int`, `attention_interval: float`, `attention_window: float`, `attention_miss_penalty: float` (awal $0.3$).
  - [ ] Perbarui `res://data/recipe_data.gd` (`class_name RecipeData`): `id: StringName`, `display_name_key: StringName`, `steps: Array[StepData]`, `final_components: Array[StringName]`, `container_type: StringName`, `dish_item_id: StringName`, `icon_id: StringName`, `base_points: int` (awal $150$), `burn_time: float` (awal $10.0$).
  - [ ] Perbarui `res://data/station_data.gd` (`class_name StationData`): `id: StringName`, `type: StringName`, `size_tiles: Vector2i`, `capacity: int`, `accepted_steps: Array[StringName]`, `auto_work: bool`, `burn_duration: float`, `linked_rack_id: StringName`.
  - [ ] Perbarui `res://data/monster_data.gd` (`class_name MonsterData`): `id: StringName`, `size_px: Vector2i`, `base_patience_sec: float`, `favorite_recipes: Array[StringName]`, `attack_pattern: StringName` (`MELEE_RAGE`, `STEAL_RUN`, `TAIL_SWEEP`, `SHOCKWAVE`, `FREEZE_TOUCH`, `NONE`), `allowed_seat_types: Array[StringName]`, `cracker_pause_sec: float` (awal $8.0$), `rare_drop_id: StringName`, `variants: Array[StringName]`.
  - [ ] Buat `res://data/seating_data.gd` (`class_name SeatingData`): definisi kursi meja panjang (`long_seats`), meja kecil (`small_tables`), `max_active_monsters: int`, `max_open_tickets: int`, `long_table_bias: float`, `seat_patience_scale_long: float` ($1.0$), `seat_patience_scale_small: float` ($0.85$), serta offset titik jangkar balon & emoticon (`FR-SEAT-01` s.d. `FR-SEAT-09`).
  - [ ] Perbarui `res://data/level_data.gd` (`class_name LevelData`): `id: StringName`, `stage: int`, `duration_sec: float`, `lapak_module_id: StringName`, `stations_layout: Array[Dictionary]`, `seating: SeatingData`, `active_recipes: Array[StringName]`, `monster_waves: Array[Dictionary]`, `hazards: Array[StringName]`, `star_thresholds: Vector3i`, `special_guest_id: StringName`, `unlocked_skills: Array[StringName]`, `plate_count: int`, `washing_enabled: bool`, `is_tutorial: bool`.
  - [ ] Buat script Resource pendukung: `res://data/skill_data.gd`, `res://data/hazard_data.gd`, `res://data/tutorial_data.gd`, `res://data/world_map_data.gd`, `res://data/emote_map_data.gd` (`FR-EMO-02`), dan `res://data/facing_map_data.gd` (`FR-MOV-10`).
- **Verifikasi AI:** Buat `res://tests/test_data_resources.gd` untuk menginstansiasi seluruh `Resource` di atas, memverifikasi properti default dan serialisasi tanpa error via `run_tests.gd`.

### M0.3 — Sistem Aset, Manifest CSV, `PlaceholderFactory`, & Autoload `Assets` (`§5.1–5.9`)
- **Referensi PRD v1.0:** `FR-AST-01` s.d. `FR-AST-15`.
- **Checklist Tugas:**
  - [ ] Buat `res://data/assets/manifest.csv` yang mendaftarkan seluruh ID aset Milestone M0 & M1 sesuai tabel prefix `§5.2` dan tag animasi `§13.1`:
    - `cook_rangga`, `cook_sekar` ($32 \times 32$, `box_blue`, tag: `idle_down`, `idle_up`, `idle_side`, `walk_down`, `walk_up`, `walk_side`, `work_down`, `work_up`, `work_side`, `strike_down`, `strike_up`, `strike_side`, `throw_down`, `throw_up`, `throw_side`, `knocked`, `dash_down`, `dash_up`, `dash_side`).
    - `mon_goblin`, `mon_goblin_chief`, `mon_scarecrow` ($32 \times 32$, `box_red`, tag: `walk_down`, `walk_up`, `walk_side`, `sit_a`, `sit_b`, `eat`, `rage`, `expelled`).
    - Semua `item_*` Stage 1 (`bawang`, `jamur_tiram`, `tempe`, `tepung`, `daun_bawang`, `singkong`, `santan`, `gula_merah`, `nasi`, `kerupuk`, `truffle_gua`, `kuali`, `sutil`, `burnt_food` dalam form `_raw`, `_prepped`, `_cooked`, `_burnt` ukuran $16 \times 16$, `box_orange`).
    - Semua `dish_*` ($16 \times 16$, `box_orange`) dan `icon_*` ($24 \times 24$, `box_orange`) Stage 1 (`nasi_goreng_jamur`, `tempe_mendoan`, `bubur_singkong`).
    - `plate_clean`, `plate_dirty` ($16 \times 16$, `box_brown`).
    - Semua `station_*` Stage 1 (`peti_bahan`, `peti_nasi`, `meja_potong`, `meja_kerja`, `cobek`, `tungku`, `meja_alas`, `rak_piring`, `tempat_cuci`, `tempat_sampah`, `box_brown` dengan tag state `empty`, `working`, `done`, `burning`, `burnt`, `disabled`, `no_cookware`).
    - Semua `furn_*` (`tikar_lapak`, `table_long`, `table_small`, `seat_bench`, `seat_stool`, `kendi`, `box_gray`) dan `cart_stall_clean`, `cart_stall_dusty`, `cart_stall_loaded` ($24 \times 32$, `box_brown`).
    - Atlas `tile_lapak`, `tile_gua`, `tile_halaman` (`box_gray`) serta `res://data/assets/tile_slots.csv` (Slot 0–7 sesuai `§5.6`).
    - Ke-19 `emote_*` ($16 \times 16$, `box_pink`, `FR-EMO-01`) dan elemen `ui_*` (`box_green`) serta `vfx_*` (`box_white`).
  - [ ] Buat `res://view/placeholder_factory.gd` (`class_name PlaceholderFactory`) yang men-generate `ImageTexture` dan `SpriteFrames` `box_<warna>` secara prosedural di memori:
    - Warna sesuai prefix (`box_blue`, `box_red`, `box_orange`, `box_brown`, `box_gray`, `box_white`, `box_pink`, `box_green`, `box_purple`, serta `MISSING` magenta dan `INVALID` berbingkai merah).
    - Menggambar garis tepi $1\text{ px}$ lebih gelap, label teks ID/tag dipotong, panah arah untuk tag berarah (`_down`, `_up`, `_side`), serta pergeseran $1\text{ px}$ per nomor frame agar animasi placeholder tampak bergerak (`FR-AST-04`).
    - Menghasilkan `AudioStreamWAV` bunyi bip sintetis pendek untuk prefix `sfx_*` atau hening (`FR-AST-15`).
  - [ ] Buat Autoload ke-7 `res://autoload/assets.gd` dan daftarkan sebagai `Assets` di `project.godot`:
    - Menyediakan fungsi `frames(id: StringName) -> SpriteFrames`, `texture(id: StringName) -> Texture2D`, `audio(id: StringName) -> AudioStream`, `status(id: StringName, anim: StringName = &"") -> StringName`, dan `reload() -> void` (`FR-AST-02`, `FR-AST-11`).
    - Mengimplementasikan urutan *fallback* per animasi (`FR-AST-05`): aset final `<anim>_<arah>` $\rightarrow$ aset final `<anim>` tanpa arah $\rightarrow$ placeholder `<anim>_<arah>`.
    - Menjadi *no-op* (tidak mengalokasikan tekstur/audio) ketika berjalan di mode server dedicated (`OS.has_feature("dedicated_server")` — `FR-AST-12`).
- **Verifikasi AI:** Buat `res://tests/test_assets_system.gd` yang menguji `Assets.frames()`, `Assets.texture()`, fallback animasi, penanganan ID tidak dikenal (`MISSING:<id>` tanpa crash `FR-AST-03`), lalu jalankan via `run_tests.gd`.

### M0.4 — Tool Pipeline Aset (`sync_assets.gd`, `asset_audit.gd`) & `anim_gallery.tscn` (`§5.7–5.9`)
- **Referensi PRD v1.0:** `§5.7`, `§5.8`, `FR-AST-06`, `FR-AST-10`.
- **Checklist Tugas:**
  - [ ] Buat `res://tools/make_placeholders.gd` dan `res://tools/sync_assets.gd` (dijalankan dengan `godot --headless --script res://tools/sync_assets.gd`):
    - Memindahkan file dari `res://assets/_incoming/` ke `res://assets/<prefix>/<ID>/` sesuai aturan nama `§5.3`.
    - Memvalidasi format nama (`<ID>.png` atau `<ID>__<anim>.png`), ukuran frame terhadap `manifest.csv`, dan membangun `res://data/assets/index.json` serta laporan `res://reports/asset_status.md` dan `res://reports/asset_status.json`.
    - Keluar dengan kode bukan nol jika ditemukan aset berstatus `INVALID`.
  - [ ] Buat `res://tools/asset_audit.gd` untuk mengaudit ukuran frame, transparansi, dan batas warna palet.
  - [ ] Buat `res://tools/gif_to_strip.py` (konverter GIF di `_incoming/` menjadi strip horizontal PNG `FR-AST-14`).
  - [ ] Buat `res://tests/anim_gallery.tscn` dan `res://tests/anim_gallery.gd` yang menampilkan seluruh ID dari `manifest.csv` berdampingan dengan pemutar animasi dan label status (`box_*` atau `FINAL`), ditambah *overlay debug* tombol **F3** (`FR-AST-10`) dan *hot-reload* **F5** (`FR-AST-11`).
- **Verifikasi AI:** Jalankan `godot --headless --script res://tools/sync_assets.gd` dan tambahkan pengujian di `res://tests/test_assets_system.gd` yang memverifikasi `res://data/assets/index.json` dan `res://reports/asset_status.json` terbentuk valid tanpa status `INVALID`.

---

## MILESTONE M1: Prototipe Stage 1 — Fisika Deterministik, Masak, Cuci Piring, Lapak, & Goblin (`§7–§11`)
**Kriteria Selesai M1:** Seluruh mekanik inti memasak, cuci piring, samperin, Sutil & Kuali Dua Mode, serta 4 level Stage 1 (`1-1` s.d. `1-4`) berjalan deterministik untuk 2 pemain lokal dengan placeholder `box_*` dan lulus semua unit test.

### M1.1 — Fisika Deterministik (`collision.gd`), Gerak 8 Arah, & Probe Interaksi (`§7`)
- **Referensi PRD v1.0:** `FR-MOV-01` s.d. `FR-MOV-11` (**Tanpa `FR-MOV-05` / Tanpa `CharacterBody2D`**).
- **Checklist Tugas:**
  - [x] Buat `res://sim/systems/collision.gd` (`class_name SimCollision`):
    - Menyimpan *grid* statis $30 \times 14$ tile ($16 \times 16\text{ px}$ per tile) dengan tipe sel (`FLOOR`, `MAT`, `WALL`, `GATE`, `LONG_TABLE`, `WATER`, `LAVA`, `ICE`) serta daftar AABB stasiun/meja dan lingkaran koki lain.
    - Fungsi `move_circle_with_slide(pos: Vector2, delta_move: Vector2, radius: float = 6.0)` yang menyelesaikan benturan lingkaran radius $6\text{ px}$ melawan dinding *grid*, AABB stasiun/meja panjang, dan lingkaran koki lain dengan *corner sliding* mulus (`FR-MOV-02`, `FR-MOV-08`, `FR-LAY-04`).
  - [x] Refactor `res://sim/entities/cook.gd` (`class_name SimCook` mewarisi `RefCounted` atau `Node` murni tanpa node visual/fisika Godot):
    - Input per tick via `CookInput`: vektor arah 8 arah ternormalisasi, kecepatan dasar $5.0\text{ tile/s}$ ($80.0\text{ px/s}$), waktu percepatan $0.06\text{ s}$ ($0.35\text{ s}$ di lantai es `FR-MOV-03`).
    - Enum `Facing8` (`E`, `SE`, `S`, `SW`, `W`, `NW`, `N`, `NE`) dibulatkan ke kelipatan $45^\circ$ dan bertahan saat diam (`FR-MOV-04`).
    - Fungsi `query_interaction_target()` dengan *probe* lingkaran radius $9.0\text{ px}$ (diperlebar menjadi $14.0\text{ px}$ untuk kursi) berpusat di $\text{posisi koki} + \text{Facing8} \times 12.0\text{ px}$ dengan urutan prioritas: **1. Stasiun $\rightarrow$ 2. Item di lantai $\rightarrow$ 3. Kursi**, seri diputus dengan jarak terdekat ke pusat *probe* (`FR-MOV-06`).
    - Fungsi `get_strike_aabb()` untuk pukulan Sutil ($1.2\text{ tile} = 19.2\text{ px}$) dan Kuali ($1.6\text{ tile} = 25.6\text{ px}$) berpusat di $\text{posisi koki} + \text{Facing8} \times 0.9\text{ tile}$ ($14.4\text{ px}$), tanpa rotasi (`FR-MOV-07`).
  - [x] Refactor `res://view/cook_view.gd`:
    - Membaca state `SimCook`, memetakan `Facing8` ke arah sprite (`down`, `up`, `side` + `flip_h`) menggunakan `FacingMapData` (`FR-MOV-10`), memutar `SpriteFrames` dari `Assets.frames(cook_id)`, menampilkan panah kecil `Facing8` di atas kotak koki (`FR-MOV-11`), dan menggambar sprite item yang sedang dipegang $16 \times 16\text{ px}$ di atas kepala (`FR-INT-01`).
- **Verifikasi AI:** Buat `res://tests/test_sim_movement.gd` untuk menguji normalisasi kecepatan diagonal ($80\text{ px/s}$), penolakan tembus dinding/meja panjang, *sliding* di sudut, akurasi `Facing8`, dan prioritas *probe* interaksi.

### M1.2 — Entitas Item, Wadah Piring, Meja Alas, & Siklus Cuci Piring (`§8.5–§8.7`)
- **Referensi PRD v1.0:** `FR-INT-01` s.d. `FR-INT-05`, `FR-STA-14`, `FR-STA-15`, `FR-STA-17`, `FR-STA-18`, `FR-WSH-01` s.d. `FR-WSH-09`.
- **Checklist Tugas:**
  - [x] Buat `res://sim/entities/item.gd` (`class_name SimItem`):
    - Menyimpan `item_id: StringName`, `category`, `form`, daftar `components: Array[StringName]` (maksimal 3 komponen untuk piring biasa, 8 untuk nampan tumpeng `FR-INT-05`), status `is_dirty: bool`, `stack_count: int` (untuk tumpukan piring kotor maksimal 3), dan `cookware_locked_timer: float`.
    - Fungsi pencocokan tanda tangan komponen tanpa urutan (`matches_signature(required: Array[StringName]) -> bool` — `FR-STA-12`, `FR-INT-05`).
  - [x] Buat sistem manajemen piring & stasiun pendukung di `res://sim/entities/station.gd`:
    - **Peti Bahan (`FR-STA-15`):** Memberi bahan `RAW` tanpa batas; **Peti Nasi** memberi `item_nasi_cooked`; **Peti Bumbu Kacang** memberi `item_bumbu_kacang`; **Kendi** memberi `item_air`.
    - **Meja Alas (`FR-STA-17`):** Permukaan 1 slot. Jika koki memegang piring dan berinteraksi dengan komponen di Meja Alas, komponen masuk ke piring. Jika koki memegang komponen dan berinteraksi dengan piring di Meja Alas, komponen masuk ke piring.
    - **Tempat Sampah (`FR-STA-14`):** Membuang bahan/masakan di tangan; jika koki memegang Piring atau Kuali berisi masakan/gosong, isinya terbuang sementara Piring/Kuali tetap di tangan dalam keadaan kosong dan bersih.
    - **Pool Piring Terbatas & Cuci Piring (`FR-WSH`):** Jumlah total piring di level dikunci sebesar `LevelData.plate_count` ($\ge \text{max\_open\_tickets} + 1$). Piring kotor dapat ditumpuk hingga 3 di tangan/Tempat Cuci, dicuci dengan menahan `work` selama $2.0\text{ s}$ per piring di **Tempat Cuci**, lalu otomatis berpindah ke **Rak Piring** terhubung (`linked_rack`).
- **Verifikasi AI:** Buat `res://tests/test_items_and_plates.gd` yang memverifikasi perakitan 3 komponen tanpa urutan di Meja Alas, pembuangan isi kuali/piring di Tempat Sampah, dan kekekalan jumlah total piring (`plate_count` selalu konstan sepanjang siklus bersih $\rightarrow$ saji $\rightarrow$ kotor $\rightarrow$ cuci $\rightarrow$ rak).

### M1.3 — State Machine Stasiun Masak, Kuali Serbaguna, & Mekanik Aduk/Balik (`§8.4, §8.5, §8.8`)
- **Referensi PRD v1.0:** `FR-STA-01` s.d. `FR-STA-07`, `FR-STA-11` s.d. `FR-STA-13`, `FR-STA-16`, `FR-STA-21`.
- **Checklist Tugas:**
  - [x] Lengkapi `res://sim/entities/station.gd` (`class_name SimStation`) dengan state machine: `EMPTY`, `WORKING`, `DONE`, `BURNING`, `BURNT` (`FR-STA-01`) dan flag kondisi (`DISABLED`, `FROZEN`, `NO_COOKWARE`, `NEEDS_ATTENTION`).
  - [x] Implementasikan kerja manual vs otomatis (`FR-STA-02`):
    - **Manual (`meja_potong`, `meja_kerja`, `cobek`, `tempat_cuci`):** Progres bertambah hanya saat koki menahan `work` (atau mode toggle *Tekan untuk bekerja* `FR-STA-21`).
    - **Otomatis (`tungku` dengan `kuali`, `dandang`, `anglo`, `panci`):** Bekerja otomatis begitu bahan di dalamnya cocok dengan salah satu resep (`FR-STA-12`). Sebelum cocok, `interact` tangan kosong mengeluarkan bahan terakhir yang dimasukkan.
  - [x] Implementasikan timer gosong (`FR-STA-03`, `FR-STA-13`): Setelah `DONE`, hitung mundur `burn_duration` (awal $10.0\text{ s}$): masuk `BURNING` (asap) lalu `BURNT` (mengubah isi menjadi `item_burnt_food` dan mengurangi skor $-25\text{ poin}$).
  - [x] Implementasikan mekanik **Aduk & Balik (`NEEDS_ATTENTION` — `FR-STA-04` s.d. `FR-STA-07`)**:
    - Membaca `StepData.attention = {interval, window, miss_penalty}` (jika `Settings.wide_attention_window` aktif, `window` dikali $1.5$).
    - Saat masuk `NEEDS_ATTENTION`, pancarkan sinyal untuk menampilkan `emote_stir`. Jika koki tidak menekan `work` dalam `window` detik, timer gosong saat `DONE` dikalikan `miss_penalty` ($0.3 \times 10\text{ s} = 3.0\text{ s}$).
  - [x] Implementasikan **Kuali Bisa Diangkat (`FR-STA-16`)**: Kuali di tungku menampung maksimal 3 bahan dan menjalankan `COOK`, `FRY`, dan `BOIL`. Saat kuali diangkat dari tungku, tungku menjadi `NO_COOKWARE`, progres masak berhenti sementara di dalam item kuali, dan berlanjut saat ditaruh kembali di tungku.
  - [x] Buat file `.tres` atau registri data untuk **3 Resep Stage 1 (`§8.8`)**:
    1. **Nasi Goreng Jamur (`recipe_nasi_goreng_jamur`):** Potong jamur ($3\text{ s}$) + potong bawang ($2\text{ s}$) $\rightarrow$ Kuali: `nasi_cooked` + `jamur_prepped` + `bawang_prepped` (`COOK` $10\text{ s}$, aduk tiap $4\text{ s}$ jendela $1.5\text{ s}$).
    2. **Tempe Mendoan (`recipe_tempe_mendoan`):** Potong tempe ($3\text{ s}$) $\rightarrow$ Meja Kerja: `tempe_prepped` + `tepung_raw` + `daun_bawang_raw` (`MIX` $3\text{ s}$) $\rightarrow$ Kuali (`FRY` $8\text{ s}$).
    3. **Bubur Singkong (`recipe_bubur_singkong`):** Cobek: parut singkong (`POUND` tahan biasa $3\text{ s}$) $\rightarrow$ Kuali: `singkong_prepped` + `santan_raw` + `gula_merah_raw` (`BOIL` $12\text{ s}$).
- **Verifikasi AI:** Buat `res://tests/test_cooking_stations.gd` yang mensimulasikan pembuatan ke-3 resep Stage 1 dari bahan mentah sampai hidangan di piring, serta menguji penalti lupa aduk ($3\text{ s}$ gosong) dan angkat-taruh kuali.

### M1.4 — Lapak Kaki Lima (`LapakModule`), Kursi (`Seat`), & Meja Panjang/Kecil (`§9.1–§9.4`)
- **Referensi PRD v1.0:** `FR-LAY-01` s.d. `FR-LAY-06`, `FR-SEAT-01` s.d. `FR-SEAT-10`.
- **Checklist Tugas:**
  - [x] Buat `res://sim/entities/seat.gd` (`class_name SimSeat` dan `class_name SimSeatingTable`):
    - Menyimpan `seat_id`, `table_id`, `table_kind` (`LONG`, `SMALL`, `ALTAR`), `position: Vector2`, `facing: Vector2`, `seat_type` (`BENCH`, `STOOL`, `MAT`), `serve_radius: float` ($12.0\text{ px}$), `plate_state` (`NONE`, `SERVED`, `DIRTY`), `occupant_monster_id: int`, serta offset balon pesanan dan emoticon (`FR-SEAT-09`).
    - Timer otomatis $2.0\text{ s}$ setelah monster pergi untuk mengubah piring di kursi menjadi `DIRTY` (`FR-SEAT-07`) agar bisa diambil koki dan dibawa ke Tempat Cuci.
  - [x] Buat `res://levels/lapak_module.gd` dan `res://levels/lapak_module.tscn` sesuai denah ASCII `§9.2` ($30 \times 14$ tile = $480 \times 224\text{ px}$):
    - Kolom `0..11`: Tikar lapak krem, prop statis Gerobak $2 \times 2$ tile (`cart_stall_clean` $24 \times 32\text{ px}$) di `(x=0..1, r=4..5)`, dan slot penempatan stasiun.
    - Kolom `12`: Meja Panjang $1 \times 10$ tile (`r=1..10`) yang memblokir jalan koki tetapi bisa dilewati lemparan (`FR-LAY-04`), serta **Gerbang 2 tile** di `(x=12, r=11..12)`.
    - Kolom `13`: 5–7 kursi Meja Panjang berjarak $18\text{ px}$ vertikal (`FR-SEAT-01`) dengan balon pesanan di sisi kanan monster (`FR-SEAT-09`).
    - Kolom `13..29`: Sisi Dungeon dengan Terowongan Masuk `D` di `(x=21, r=0)`, titik pasang Meja Kecil Dekat di kolom `15..18` (`r=3` dan `r=9`), serta Meja Kecil Jauh di kolom `23..26` (`r=5` dan `r=11`).
- **Verifikasi AI:** Buat `res://tests/test_lapak_and_seating.gd` untuk menguji geometri denah $30 \times 14$, jangkar kursi kolom 13, akses jangkauan *probe* koki dari kolom 11 ke kursi kolom 13 (`FR-SRV-02`), dan munculnya piring kotor $2.0\text{ s}$ setelah kursi kosong.

### M1.5 — Monster Goblin, State `BROWSING`, `STEAL_RUN`, & Samperin (`§9.6, §10.1`)
- **Referensi PRD v1.0:** `FR-SRV-01`, `FR-SRV-02`, `FR-MON-01` s.d. `FR-MON-09`, `FR-MON-12`, `FR-MON-13`.
- **Checklist Tugas:**
  - [x] Buat `res://sim/entities/monster.gd` (`class_name SimMonster`) dengan state machine lengkap (`FR-MON-02`):
    - `ARRIVING` $\rightarrow$ `SEATED` $\rightarrow$ `BROWSING` $\rightarrow$ `WAITING` $\rightarrow$ `EATING` $\rightarrow$ `SATISFIED` $\rightarrow$ `LEAVING`, serta cabang amarah `ENRAGED` $\rightarrow$ `ATTACKING` / `STEAL_RUN` $\rightarrow$ `EXPELLED`.
  - [x] Implementasikan `res://sim/systems/orders.gd` (`class_name SimOrderSystem`):
    - Spawner memilih kursi kosong menggunakan RNG ber-seed dengan `long_table_bias` ($0.6$ di Stage 1) dan menjamin porsi meja kecil minimal $40\%$ jika level memiliki meja kecil (`FR-SEAT-03`).
    - Jika jumlah tiket aktif sudah mencapai `max_open_tickets`, monster yang baru duduk masuk state `BROWSING` (menampilkan `emote_menu`, kesabaran belum berkurang `FR-SEAT-06`, `FR-MON-12`) sampai ada slot tiket terbuka.
    - Saat masuk `WAITING`, kesabaran turun linear dari $100$ ke $0$ selama $\text{base\_patience\_sec} \times \text{seat\_patience\_scale}$ (Goblin $40\text{ s}$ di meja panjang, $40 \times 0.85 = 34\text{ s}$ di meja kecil `FR-MON-03`, `FR-SEAT-08`).
    - **Tahap Kesabaran (`FR-MON-04`):** Tahap 1 ($>50\%$): normal/menggerutu; Tahap 2 ($50\%..0\%$): bonus cepat berhenti; Tahap 3 ($0\%$): masuk `ENRAGED`.
  - [x] Implementasikan **Goblin `STEAL_RUN` & Serangan Mengamuk (`FR-MON-05`, `FR-MON-13`)**:
    - Pada Tahap 3 ($0\%$), Goblin dapat menjalankan `STEAL_RUN`: berdiri, mengambil 1 item terdekat di permukaan stasiun/meja/lantai (bukan di tangan koki), lalu berlari $3.0\text{ tile/s}$ menuju terowongan `D`. Jika sampai di `D`, item hilang dan Hati Dapur $-1$.
    - Jika mode `ATTACKING` (mengamuk menyerang dapur selama $10.0\text{ s}$): bila tidak diusir dalam $10.0\text{ s}$, Hati Dapur $-1$, stasiun terdekat menjadi `DISABLED` selama $8.0\text{ s}$, lalu monster pergi.
  - [x] Implementasikan **Samperin (`FR-SRV-01`)**:
    - Saat koki menekan `interact` sambil membawa hidangan di dekat kursi (radius *probe* $14\text{ px}$), sistem memilih kursi dalam jangkauan yang pesanannya cocok. Jika cocok: hidangan tersaji aman, hitung kepuasan $\text{satisfaction} = \min(100.0, 40.0 + \text{patience\_left} \times 0.4 + \text{sambal\_bonus} + \text{jitu\_bonus})$ (`FR-MON-06`). Jika tidak ada yang cocok: tampilkan `emote_no` tanpa penalti.
- **Verifikasi AI:** Buat `res://tests/test_monster_and_orders.gd` untuk menguji antrean `BROWSING` vs `max_open_tickets`, penurunan kesabaran meja panjang vs meja kecil ($0.85\times$), logika `STEAL_RUN`, dan penyajian *Samperin*.

### M1.6 — Pertahanan Sutil, Kuali Dua Mode, & Kerupuk (`§11.1`)
- **Referensi PRD v1.0:** `FR-CMB-01` s.d. `FR-CMB-08`, `FR-SRV-04`, `FR-MON-09`.
- **Checklist Tugas:**
  - [x] Implementasikan aksi `strike` di `SimCook` dan resolusinya di simulasi dapur:
    - `strike` memiliki prioritas di atas `work` dan langsung menghentikan pekerjaan manual yang sedang ditahan (`FR-CMB-08`).
    - Pukulan **hanya mengenai monster berstatus `ENRAGED`, `ATTACKING`, atau `STEAL_RUN`**; monster duduk lain (`BROWSING`, `WAITING`, `EATING`) di dalam hitbox diabaikan (`FR-SRV-04`).
  - [x] **Mode Sutil (Default saat tidak memegang Kuali — `FR-CMB-01`):**
    - Hitbox AABB $1.2\text{ tile}$, aktif $0.12\text{ s}$, cooldown $0.4\text{ s}$. Mendorong monster kecil dan membutuhkan **3 pukulan** untuk mengusir (`EXPELLED`) monster yang sedang mengamuk (atau **1 pukulan** untuk menghentikan Goblin `STEAL_RUN` dan menjatuhkan item curiannya `FR-MON-13`).
  - [x] **Mode Kuali (`COOKWARE` di tangan — `FR-CMB-02` s.d. `FR-CMB-04`):**
    - Hitbox AABB $1.6\text{ tile}$, cooldown $0.8\text{ s}$. **1 pukulan** langsung mengusir monster (`EXPELLED`).
    - **Aturan Tumpah (`FR-CMB-03`):** Jika kuali yang dipakai memukul berisi bahan mentah, setengah matang, atau matang, seluruh isinya hilang, memancarkan event noda tumpah di lantai, dan mengurangi skor **$-25\text{ poin}$**.
    - Setelah dipakai memukul (baik kosong maupun berisi), kuali terkena status `COOKWARE_LOCKED` selama **$4.0\text{ s}$** (tidak bisa dipakai memasak di tungku sampai timer habis `FR-CMB-04`).
  - [x] **Interaksi Kerupuk (`FR-MON-09`, `FR-MON-13`):**
    - Memberikan atau melempar `item_kerupuk` (dalam radius $24\text{ px}$) ke monster `WAITING` menahan penurunan kesabaran selama $8.0\text{ s}$; jika mengenai Goblin `STEAL_RUN`, Goblin berhenti makan kerupuk $2.0\text{ s}$ dan menjatuhkan item curiannya.
- **Verifikasi AI:** Buat `res://tests/test_combat_and_kuali.gd` untuk menguji 3 pukulan sutil vs 1 pukulan kuali, pengabaian monster duduk, penalti kuali tumpah ($-25\text{ poin}$), dan penguncian kuali $4.0\text{ s}$.

### M1.7 — Sistem Skor, Hati Dapur, Tamu Istimewa, & Level 1-1 s.d. 1-4 (`§9.5, §10.1, §12.2`)
- **Referensi PRD v1.0:** `§9.5` (Tabel Parameter Level), `FR-MON-07`, `§12.2` (`MUSHROOM_SPORES`).
- **Checklist Tugas:**
  - [x] Buat `res://sim/systems/scoring.gd` (`class_name SimScoring`):
    - Mengelola **5 Hati Dapur** bersama (level gagal jika mencapai $0$), skor tim, perhitungan bintang ($1..3$ bintang berdasarkan `LevelData.star_thresholds`), dan pengecekan Tamu Istimewa (kepuasan $\ge 80$ menjatuhkan Bahan Langka stage tersebut ke `Save` — `FR-MON-07`).
  - [x] Buat `res://sim/systems/hazards.gd` (`class_name SimHazardController`) dan implementasikan hazard pertama Stage 1: **`MUSHROOM_SPORES`** (tiap $25\text{ s}$ mengeluarkan awan spora yang menutupi sebagian pandangan layar selama $1.0\text{ s}$ di Level 1-3 dan 1-4).
  - [x] Buat konfigurasi data untuk ke-4 level Stage 1 sesuai tabel `§9.5` dan GDD:
    - **Level 1-1 (`level_1_1` — Bekal Terakhir):** Durasi $180\text{ s}$, `max_open_tickets = 2`, `max_active_monsters = 4`, `plate_count = 3`, `washing_enabled = false`, Kursi panjang = 5, Meja kecil = `0/0`, Menu: Nasi Goreng Jamur, Bintang: `300 / 600 / 900`.
    - **Level 1-2 (`level_1_2` — Tungku Menyala):** Durasi $180\text{ s}$, `max_open_tickets = 3`, `max_active_monsters = 5`, `plate_count = 4`, `washing_enabled = true` (pop-up cuci piring `FR-TUT-07`), Kursi panjang = 5, Meja kecil = `0/0`, Menu: Nasi Goreng Jamur, Bintang: `350 / 700 / 1000`.
    - **Level 1-3 (`level_1_3` — Si Pencuri):** Durasi $180\text{ s}$, `max_open_tickets = 3`, `max_active_monsters = 5`, `plate_count = 4`, `washing_enabled = true`, Kursi panjang = 5, Meja kecil dekat = `1`, Menu: Nasi Goreng Jamur + Tempe Mendoan, Goblin `STEAL_RUN` aktif, Hazard `MUSHROOM_SPORES`, membuka skill `Dash` Rangga, Bintang: `400 / 800 / 1150`.
    - **Level 1-4 (`level_1_4` — Pesta Goblin):** Durasi $240\text{ s}$, `max_open_tickets = 4`, `max_active_monsters = 6`, `plate_count = 5`, `washing_enabled = true`, Kursi panjang = 5, Meja kecil dekat = `2`, Menu: Nasi Goreng Jamur + Tempe Mendoan + Bubur Singkong, Tamu Istimewa: `mon_goblin_chief` (drop `item_truffle_gua`), Bintang: `550 / 1100 / 1550`.
  - [ ] Hubungkan keseluruhan simulasi Stage 1 ke scene permainan utama `res://levels/kitchen_stage.tscn` (dan perbarui `test_kitchen.tscn` agar memakai sistem baru ini).
- **Verifikasi AI:** Buat `res://tests/test_stage1_levels.gd` yang memuat ke-4 `LevelData` Stage 1, memvalidasi aturan `plate_count >= max_open_tickets + 1`, dan menjalankan simulasi headless dari awal sampai akhir level hingga memperoleh minimal 1 bintang dan drop `item_truffle_gua` di 1-4.

---

## MILESTONE M2: Vertical Slice — Lempar Busur v1.0, Skill Dash, Emoticon, Kerumunan, HUD, & Tutorial (`§9.6, §10.2, §13–§15`)
**Kriteria Selesai M2:** Sistem lempar cepat & lempar bidik busur berfungsi presisi dengan Bantuan Bidik keyboard, 19 emoticon & kerumunan latar tampil hidup, HUD atas/bawah sesuai standar $480 \times 270$, dan 5 level Tutorial (`T-1` s.d. `T-5`) dapat diselesaikan oleh 2 pemain.

### M2.1 — Sistem Lempar Cepat, Lempar Bidik Busur, & Bantuan Bidik (`§9.6`)
- **Referensi PRD v1.0:** `FR-THR-01` s.d. `FR-THR-16`, rumus `throw_math.gd`.
- **Checklist Tugas:**
  - [ ] Perbarui `res://sim/systems/throw_math.gd` agar memuat seluruh konstanta dan fungsi PRD v1.0 (`TILE = 16.0`, `MIN_R = 2.0`, `MAX_R = 8.0`, `RAMP_TIME = 1.2`, `SERVE_RADIUS = 12.0`, `JITU_RADIUS = 6.0`, `ASSIST_RADIUS = 20.0`, `range_at`, `flight_time`, `landing_point`, serta kalkulasi bantuan bidik).
  - [ ] Buat `res://sim/entities/projectile.gd` (`class_name SimProjectile`) dan `res://sim/systems/throw_system.gd` (`class_name SimThrowSystem`):
    - **Lempar Cepat (`FR-THR-01`):** Ketuk `throw` ($< 0.18\text{ s}$) saat memegang **bahan (`INGREDIENT` / `SNACK`)** melempar lurus sejauh $4.0\text{ tile}$ ke arah `Facing8`. Hidangan (`DISH`) tidak bisa dilempar cepat (`FR-THR-02`). Kuali dan sutil tidak bisa dilempar (`FR-THR-05`).
    - **Lempar Bidik (`FR-THR-02` s.d. `FR-THR-06`):** Tahan `throw` memperlambat gerak koki $50\%$, menonaktifkan `strike`, dan mengayunkan jarak antara $2.0..8.0\text{ tile}$ setiap $1.2\text{ s}$ (gelombang segitiga). Waktu terbang proyektil $0.4\text{ s}$ (pada $2\text{ tile}$) hingga $0.9\text{ s}$ (pada $8\text{ tile}$), cooldown lempar $0.3\text{ s}$ (`FR-THR-13`).
    - **Bantuan Bidik (`FR-THR-12`):** Aktif secara *default* untuk keyboard dan mati untuk gamepad (bisa diubah di `Settings`). Menempelkan titik jatuh ke pusat kursi berpesanan cocok terdekat dalam radius $20.0\text{ px}$. Hasil bantuan bidik dihitung **Tersaji**, kecuali titik jatuh *mentah* (sebelum ditempel) sudah berada dalam radius $\le 6.0\text{ px}$ DAN jarak lempar $\ge 3.0\text{ tile}$ (`FR-THR-14`), maka tetap dihitung **Jitu**.
    - **Resolusi Titik Jatuh Hidangan (`FR-THR-08`, `FR-THR-09`):**
      1. **Jitu ($\le 6\text{ px}$ dari kursi cocok & jarak $\ge 3\text{ tile}$):** Tersaji, $+25\text{ poin}$, kepuasan $+5$. Tiga Jitu beruntun memberi bonus **$+50\text{ poin}$**.
      2. **Tersaji ($\le 12\text{ px}$ dari kursi cocok):** Tersaji normal.
      3. **Meja Salah ($\le 12\text{ px}$ dari kursi berpesanan beda & tidak ada kursi cocok dalam $12\text{ px}$):** Hidangan hilang, $-50\text{ poin}$, kesabaran monster kursi itu $-10$, piring kembali ke rak setelah $10.0\text{ s}$.
      4. **Mengenai Monster (mendarat di monster yang tidak duduk, misal antre/mengamuk):** Hancur, $-25\text{ poin}$, kesabaran $-25$, piring kembali ke rak setelah $10.0\text{ s}$.
      5. **Meleset (jatuh di lantai):** Hancur, $-25\text{ poin}$, kesabaran monster berpesanan cocok terdekat dalam $40\text{ px}$ berkurang $-15$, piring kembali ke rak setelah $10.0\text{ s}$.
    - **Resolusi Titik Jatuh Bahan (`FR-THR-10`):** Jika mendarat dalam $16\text{ px}$ dari rekan koki bertangan kosong $\rightarrow$ tertangkap otomatis. Jika masuk area terima stasiun yang cocok $\rightarrow$ masuk stasiun. Jika jatuh di lantai biasa $\rightarrow$ bisa dipungut.
  - [ ] Buat `res://view/throw_preview_view.gd` dan `res://view/projectile_view.gd`:
    - Menggambar garis busur putus-putus parabola ($h = r_{\text{tiles}} \times 4.0\text{ px}$) dan penanda titik jatuh dengan bentuk berbeda untuk aksesibilitas buta warna (`FR-THR-03`, `NFR-ACC-02`): **Lingkaran Penuh Hijau** (Jitu), **Setengah Lingkaran Kuning** (Tersaji), dan **Silang Merah** (Meleset/Salah).
    - Menampilkan `Label` melayang untuk hasil lemparan (`FR-THR-15`).
- **Verifikasi AI:** Perluas `res://tests/test_throw_math.gd` untuk menguji kelima hasil lemparan (`Jitu`, `Tersaji`, `Meja Salah`, `Mengenai Monster`, `Meleset`), streak 3x Jitu ($+50$), syarat minimal $3\text{ tile}$ untuk Jitu, Bantuan Bidik $20\text{ px}$, tangkapan otomatis rekan $16\text{ px}$, dan pengembalian piring hancur ke rak setelah $10.0\text{ s}$.

### M2.2 — Sistem Skill Koki Pertama (`Dash` Rangga) (`§7, §11`)
- **Referensi PRD v1.0:** `FR-MOV-09`, Lampiran Konstanta Skill (`Dash` jarak $4\text{ tile}$, cooldown $6.0\text{ s}$).
- **Checklist Tugas:**
  - [ ] Buat `res://sim/systems/skills.gd` (`class_name SimSkillSystem`).
  - [ ] Implementasikan `skill_1` milik Rangga (**`Dash`**): melesat cepat sejauh $4.0\text{ tile}$ ke arah `Facing8` (berhenti bila terhalang dinding/stasiun menggunakan `SimCollision`), cooldown $6.0\text{ s}$, dapat menghentikan Goblin `STEAL_RUN` saat menabraknya (`FR-MON-13`).
- **Verifikasi AI:** Buat `res://tests/test_skills_and_combos.gd` yang menguji jarak `Dash`, benturan dinding saat `Dash`, cooldown $6.0\text{ s}$, dan penghentian Goblin pencuri.

### M2.3 — Sistem 19 Emoticon (`EmoteView`) & Kerumunan Latar (`CrowdController`) (`§10.2, §13.2`)
- **Referensi PRD v1.0:** `FR-EMO-01` s.d. `FR-EMO-06`, `FR-CRD-01` s.d. `FR-CRD-04`.
- **Checklist Tugas:**
  - [ ] Buat `res://view/emote_view.gd`:
    - Memetakan state dan event `sim/` ke 19 emoticon $16 \times 16\text{ px}$ lewat `EmoteMapData` (`FR-EMO-01`, `FR-EMO-02`):
      - Koki (9): `emote_chop`, `emote_mix`, `emote_pound`, `emote_stir`, `emote_wash`, `emote_burn`, `emote_panic`, `emote_cheer`, `emote_no`.
      - Monster (10): `emote_menu`, `emote_hungry`, `emote_grumble`, `emote_rage`, `emote_yum`, `emote_happy`, `emote_scared`, `emote_chat`, `emote_music`, `emote_envy`.
    - Satu emoticon per entitas pada satu waktu, tampil selama `work` ditahan + $0.3\text{ s}$ sesudahnya, digambar pada lapisan di atas entitas tetangga tanpa menutupi balon pesanan (`FR-EMO-03` s.d. `FR-EMO-05`).
  - [ ] Buat `res://view/crowd_controller.gd` (`class_name CrowdController`):
    - Menampilkan monster latar murni di `view/` (antre di terowongan, berjalan lewat, menonton) menggunakan RNG tampilan sendiri (`FR-CRD-01`, `FR-CRD-04`), bereaksi dengan emoticon saat ada event dapur (`FR-CRD-02`), dan mematuhi pengaturan kepadatan (`OFF`, `LOW`, `NORMAL` — `FR-CRD-03`).
- **Verifikasi AI:** Tambahkan pengujian unit pada `res://tests/test_emote_and_crowd.gd` bahwa seluruh 19 ID emoticon terdaftar di `Assets` dan pemetaan `EmoteMapData` mengembalikan ID yang tepat untuk tiap aksi kerja dan tahap kesabaran.

### M2.4 — Tema UI (`theme.tres`), HUD Atas 30 px, HUD Bawah 16 px, & Balon Pesanan (`§14`)
- **Referensi PRD v1.0:** `FR-UI-01` s.d. `FR-UI-08`.
- **Checklist Tugas:**
  - [ ] Buat `res://ui/theme.tres` sebagai satu-satunya tempat gaya dasar font piksel ($8\text{ px}$ teks, $16\text{ px}$ judul), warna, dan *nine-patch* (`FR-UI-05`, `FR-UI-08`).
  - [ ] Buat `res://ui/hud_top.gd` & `res://ui/hud_top.tscn` ($480 \times 30\text{ px}$ — `FR-UI-01`):
    - Menampilkan maksimal 6 kartu tiket pesanan ($40 \times 26\text{ px}$, ikon hidangan $24 \times 24\text{ px}$, bar waktu kesabaran) di sisi kiri, serta papan Skor dan Timer di sisi kanan.
  - [ ] Buat `res://ui/hud_bottom.gd` & `res://ui/hud_bottom.tscn` ($480 \times 16\text{ px}$ — `FR-UI-02`):
    - Menampilkan 5 ikon Hati Dapur ($12 \times 12\text{ px}$), ikon `skill_1` dan `skill_2` untuk Rangga (P1) dan Sekar (P2) ($16 \times 16\text{ px}$) dengan *sweep cooldown* yang digambar kode, serta indikator kesiapan Combo.
  - [ ] Buat `res://view/order_bubble_view.gd` (`FR-UI-03`, `FR-SEAT-09`):
    - Balon pesanan (ikon $24 \times 24\text{ px}$ + bar kesabaran $16 \times 3\text{ px}$ hijau/kuning/merah) yang berjangkar di **sisi kanan** monster pada kursi meja panjang dan di atas monster pada meja kecil.
- **Verifikasi AI:** Buat `res://tests/test_ui_hud.gd` untuk menginstansiasi HUD atas dan bawah, memverifikasi dimensi $480 \times 30\text{ px}$ dan $480 \times 16\text{ px}$, serta pembaruan tiket, skor, dan hati saat sinyal `Events` dipancarkan.

### M2.5 — Sistem `TutorialRunner` & 5 Level Latihan (`T-1` s.d. `T-5`) (`§15`)
- **Referensi PRD v1.0:** `FR-TUT-01` s.d. `FR-TUT-10`.
- **Checklist Tugas:**
  - [ ] Buat `res://sim/systems/tutorial_runner.gd` (`class_name TutorialRunner`) yang membaca `TutorialData`:
    - Mengelola langkah aktif, target sorotan grup node, pemblokiran input yang belum diajarkan, dan penghitungan syarat selesai **gabungan kedua pemain** (`FR-TUT-01`, `FR-TUT-05`).
    - Level tutorial berjalan tanpa timer gagal, tanpa pengurangan Hati Dapur, dan tanpa penilaian bintang (`FR-TUT-03`), menggunakan pelanggan `mon_scarecrow` dan tema `tile_halaman` (`FR-TUT-09`).
  - [ ] Buat data untuk **5 Level Tutorial (`FR-TUT-02`)**:
    - **`T-1` (Dasar & Samperin):** Ambil bahan, potong, rakit di Meja Alas, dan sajikan **3 hidangan** dengan jalan kaki (*samperin*).
    - **`T-2` (Tungku, Aduk, & Gosong):** Masak **3 Nasi Goreng Jamur** di kuali (termasuk **1 sengaja dibiarkan gosong** lalu dibuang ke Tempat Sampah dan mencuci piring).
    - **`T-3` (Lempar Cepat Bahan):** Oper **5 bahan** dengan *Lempar Cepat* ($4\text{ tile}$) ke rekan atau stasiun.
    - **`T-4` (Lempar Bidik ke 3 Meja):** Sajikan **5 lemparan hidangan** ke 3 meja (dekat, jarak 6 petak, dan seberang sungai kecil) dengan minimal **2 Lemparan Jitu**. Jika meleset 3 kali beruntun, radius zona saji latihan otomatis membesar $+25\%$ (`FR-TUT-08`).
    - **`T-5` (Pertahanan Sutil, Kuali Dua Mode, & Kerupuk):** Menampilkan pop-up Kuali Dua Mode (`FR-TUT-07`); syarat selesai: usir **3 monster dengan sutil**, **1 dengan kuali kosong**, lempar **1 kerupuk**, dan lakukan **1 pukulan kuali berisi (tumpah disengaja)**.
  - [ ] Sediakan tombol **Lewati Tutorial** (dengan dialog konfirmasi) dan akses ulang tiap level `T-1..T-5` dari menu **Latihan** (`FR-TUT-04`).
- **Verifikasi AI:** Buat `res://tests/test_tutorial_runner.gd` yang mensimulasikan event penyelesaian gabungan P1+P2 untuk kelima level `T-1` s.d. `T-5` dan memverifikasi adaptasi radius $+25\%$ di `T-4`.

---

## MILESTONE M3: Konten Stage 2 s.d. Stage 5, Skill & Combo Lengkap, Boss Sang Ageng, & Peta Dunia (`§8.8, §9.5, §10–§12, §16`)
**Kriteria Selesai M3:** Seluruh 19 level utama (`1-1` s.d. `5-3`), 16 resep Nusantara, 5 jenis pelanggan, 13 *hazard*, 4 *skill* + 3 *combo* 2 pemain, pertarungan 3 fase Boss Sang Ageng, dan Peta Dunia 5 Lapisan selesai dan dapat ditamatkan dari awal hingga akhir.

### M3.1 — Semua Skill Koki (4 Skill) & Sistem Combo Kooperatif 2 Pemain (3 Combo) (`§11`)
- **Referensi PRD v1.0 & GDD:** Lampiran Konstanta Skill & Combo (Tanpa `FR-SKL-10`).
- **Checklist Tugas:**
  - [ ] Lengkapi `res://sim/systems/skills.gd` untuk ke-4 skill individu (dibuka bertahap mulai 1-3):
    1. **Rangga `skill_1` — `Dash` (Buka di 1-3):** Melesat $4\text{ tile}$, cooldown $6.0\text{ s}$.
    2. **Sekar `skill_1` — `Teleport` (Buka di 2-1):** Berpindah ke titik tujuan/penanda sejauh $4\text{ tile}$ (bisa melintasi celah air/lava/meja), cooldown $8.0\text{ s}$.
    3. **Rangga `skill_2` — `SpeedBuff` (Buka di 2-3):** Kecepatan gerak kedua koki $+40\%$ selama $5.0\text{ s}$, cooldown $15.0\text{ s}$.
    4. **Sekar `skill_2` — `FireBuff` (Buka di 3-1):** Kecepatan proses memasak tungku/anglo/dandang/panci menjadi $2\times$ selama $8.0\text{ s}$, cooldown $20.0\text{ s}$.
  - [ ] Implementasikan **Sistem Combo 2 Pemain (Jendela waktu $3.0\text{ s}$ antar koki, Cooldown Combo bersama $30.0\text{ s}$)**:
    1. **Combo 1 — `Antar Kilat` (`Dash` + `Teleport` dalam $3.0\text{ s}$, Buka di 2-4):** Operan/lemparan berikutnya otomatis menempel Jitu ke kursi tujuan dengan kecepatan terbang instan.
    2. **Combo 2 — `Dapur Membara` (`SpeedBuff` + `FireBuff` dalam $3.0\text{ s}$, Buka di 3-2):** Selama $8.0\text{ s}$ semua stasiun memasak $2\times$ lebih cepat dan timer gosong dibekukan (masakan tidak bisa gosong selama durasi combo).
    3. **Combo 3 — `Tendangan Kuali` (`Dash` + `Strike Kuali` atau kombinasi pertahanan dalam $3.0\text{ s}$, Buka di 3-4):** Melontarkan gelombang kejut arah `Facing8` yang langsung mengusir semua monster mengamuk di jalurnya tanpa menumpahkan isi kuali.
- **Verifikasi AI:** Perluas `res://tests/test_skills_and_combos.gd` untuk menguji ke-4 skill dan pemicuan ke-3 Combo dalam jendela $3.0\text{ s}$ beserta *cooldown* $30.0\text{ s}$.

### M3.2 — Stage 2: Rawa Terendam (`2-1` s.d. `2-4`), Manusia Kadal, Kukus/Bakar, & Hazard Air (`§8.8, §9.5, §10.1, §12.2`)
- **Referensi PRD v1.0:** Tabel Resep `§8.8`, Parameter Level `§9.5`, `FR-MON-15` (`TAIL_SWEEP`), Hazard `TIDE` & `TAIL_SWEEP`.
- **Checklist Tugas:**
  - [ ] Tambahkan stasiun baru: **Dandang (`STEAM`)**, **Anglo (`GRILL`)**, **Panci (`BOIL`)**, dan **Kendi (`item_air`)**.
  - [ ] Tambahkan **4 Resep Stage 2 (`§8.8`)**:
    1. **Pepes Ikan (`recipe_pepes_ikan`):** Layukan daun pisang di tungku (`WILT` $4\text{ s}$) $\rightarrow$ Meja Kerja: `ikan_raw` + `bumbu_raw` + `daun_pisang_prepped` (`WRAP` $3\text{ s}$) $\rightarrow$ Dandang (`STEAM` $12\text{ s}$).
    2. **Ikan Bakar (`recipe_ikan_bakar`):** Meja Kerja: `ikan_raw` + `bumbu_raw` (`MIX` $2\text{ s}$) $\rightarrow$ Anglo (`GRILL` $10\text{ s}$, balik tiap $6\text{ s}$ jendela $1.5\text{ s}$).
    3. **Sayur Asem (`recipe_sayur_asem`):** Potong sayuran ($3\text{ s}$) $\rightarrow$ Panci: `sayuran_prepped` + `asam_raw` + `air` dari Kendi (`BOIL` $10\text{ s}$).
    4. **Nasi Liwet (`recipe_nasi_liwet`):** Kuali: `beras_raw` + `santan_raw` + `daun_salam_raw` (`COOK` $14\text{ s}$).
  - [ ] Tambahkan monster **Manusia Kadal (`mon_kadal`, tamu istimewa `mon_kadal_shaman`)**: Waktu tunggu $50\text{ s}$, pola serang `TAIL_SWEEP` (telegraf garis $1.5\text{ s}$, mendorong koki terpental `knocked` dan menjatuhkan item di tangan `FR-MON-15`), drop langkaStage 2: `item_bunga_teratai` (atau rempah rawa).
  - [ ] Implementasikan hazard **`TIDE`** (periode $20\text{ s}$, air naik menghanyutkan item di lantai papan rendah `FR-INT-04`) dan susun `LevelData` **`2-1`, `2-2`, `2-3`, `2-4`** sesuai tabel `§9.5` (Tiket `3, 3, 3, 4`; Monster `6, 6, 6, 8`; Piring `4, 4, 4, 5`; Kursi panjang `5, 5, 5, 6`; Meja kecil `2/1, 2/1, 2/2, 2/2`; `long_table_bias = 0.5`).
- **Verifikasi AI:** Buat `res://tests/test_stage2_content.gd` untuk menguji rantai resep Pepes Ikan (WILT $\rightarrow$ WRAP $\rightarrow$ STEAM), balik Ikan Bakar $6\text{ s}$, hanyutnya item saat `TIDE`, dan pemuatan Level `2-1..2-4`.

### M3.3 — Stage 3: Tambang Magma (`3-1` s.d. `3-4`), Ogre Api, Mini-Game Ulek Ritme, & Hazard Magma (`§8.4, §8.8, §9.5, §10.1, §12.2`)
- **Referensi PRD v1.0:** `FR-STA-08` (Ulek Ritme $90\text{ BPM}$), `FR-MON-14`, `FR-MON-15` (`SHOCKWAVE`), Hazard Stage 3.
- **Checklist Tugas:**
  - [ ] Implementasikan **Mini-Game Ulek Ritme di Cobek (`FR-STA-08`)**:
    - Irama $90\text{ BPM}$ ($\approx 0.667\text{ s}$ per ketukan), 6 ketukan per sambal, dengan kompensasi `Settings.audio_offset_ms` (`FR-STA-09`).
    - Jendela waktu ketukan: **Sempurna** ($\pm 60\text{ ms}$), **Bagus** ($\pm 120\text{ ms}$), selain itu **Meleset**. Kualitas sambal menaikkan kepuasan pelanggan sebesar **$+25$, $+15$, atau $+5$**.
  - [ ] Tambahkan **4 Resep Stage 3 (`§8.8`)**:
    1. **Sate (`recipe_sate`):** Potong daging ($3\text{ s}$) $\rightarrow$ Meja Kerja: `daging_prepped` + `tusuk_sate` (`ASSEMBLE` $2\text{ s}$) $\rightarrow$ Anglo (`GRILL` $12\text{ s}$, balik tiap $6\text{ s}$) $\rightarrow$ Rakit di piring: `sate_cooked` + `bumbu_kacang` (dari Peti Bumbu Kacang).
    2. **Sambal Ulek (`recipe_sambal_ulek`):** Cobek ritme $90\text{ BPM}$ 6 ketukan (`cabai_raw` + `bawang_raw` + `tomat_raw`, $\approx 4\text{ s}$).
    3. **Iga Bakar Sambal (`recipe_iga_bakar_sambal`):** Meja Kerja: `iga_raw` + `bumbu_raw` (`MIX` $2\text{ s}$) $\rightarrow$ Anglo (`GRILL` $14\text{ s}$) $\rightarrow$ Rakit di piring: `iga_cooked` + `sambal_ulek`.
    4. **Rendang Kilat (`recipe_rendang_kilat`):** Potong daging ($3\text{ s}$) $\rightarrow$ Kuali: `daging_prepped` + `santan_raw` + `rempah_raw` (`COOK` $24\text{ s}$, dipercepat $2\times$ oleh `FireBuff`).
  - [ ] Tambahkan monster **Ogre Api (`mon_ogre`, ukuran $48 \times 48\text{ px}$, tamu istimewa `mon_ogre_elder`)**: Waktu tunggu $60\text{ s}$, **hanya boleh duduk di meja kecil (`allowed_seat_types = ["STOOL"]` — `FR-SEAT-04`, `FR-MON-14`)**, serangan `SHOCKWAVE` (menghempaskan item di sekitar), drop langka Stage 3: `item_cabai_magma`.
  - [ ] Implementasikan hazard Stage 3: **`LAVA`** (periode $15\text{ s}$, 3 tile, mementalkan koki ke titik awal dan menghanguskan item), **`HOT_STOVE`** (kecepatan masak $+30\%$, waktu gosong $\times 0.7$ di 3-1), **`STEAM_WIND`** (tiap $10\text{ s}$ menggeser titik jatuh lempar dengan vektor angin `FR-THR-11`), dan **`EXPLOSION`** (tiap $45\text{ s}$ di 3-4 mengguncang layar dan menggeser item $1\text{ tile}$).
  - [ ] Susun `LevelData` **`3-1`, `3-2`, `3-3`, `3-4`** sesuai tabel `§9.5` (`long_table_bias = 0.4`).
- **Verifikasi AI:** Buat `res://tests/test_stage3_content.gd` untuk menguji penilaian jendela waktu Ulek Ritme ($\pm 60\text{ ms}$ / $\pm 120\text{ ms}$), batasan kursi Ogre (`STOOL` saja), pergeseran lemparan oleh `STEAM_WIND`, dan pemuatan Level `3-1..3-4`.

### M3.4 — Stage 4: Kripta Beku (`4-1` s.d. `4-4`), Hantu, Aroma Wedang, & Roh Mbok Laras (`§8.8, §9.5, §10.1, §12.2`)
- **Referensi PRD v1.0:** `FR-MOV-03`, `FR-MON-10`, `FR-MON-15` (`FREEZE_TOUCH`), Hazard `ICE_FLOOR`, `BLACKOUT`, `AROMA`.
- **Checklist Tugas:**
  - [ ] Tambahkan **3 Resep Stage 4 + 1 Varian Spesial Mbok Laras (`§8.8` & GDD)**:
    1. **Wedang Jahe (`recipe_wedang_jahe`):** Cobek: geprek jahe (`POUND` $2\text{ s}$) $\rightarrow$ Panci: `jahe_prepped` + `gula_merah_raw` + `air` (`BOIL` $8\text{ s}$). Setiap seduhan Wedang mengaktifkan awan **`AROMA` selama $15.0\text{ s}$** (`FR-MON-10`).
    2. **Wedang Ronde (`recipe_wedang_ronde`):** Meja Kerja: `tepung_ketan_raw` + `kacang_raw` + `jahe_prepped` (`MIX` $3\text{ s}$) $\rightarrow$ Panci (`BOIL` $8\text{ s}$).
    3. **Bubur Sumsum (`recipe_bubur_sumsum`):** Kuali: `tepung_beras_raw` + `santan_raw` + `gula_merah_raw` (`BOIL` $10\text{ s}$, aduk tiap $3\text{ s}$ jendela $1.5\text{ s}$).
    4. **Wedang Jahe Spesial Mbok Laras (`recipe_wedang_mbok` di 4-4):** Jahe digeprek & diulek halus di cobek, lalu direbus dengan gula merah dan air di panci.
  - [ ] Tambahkan monster **Hantu (`mon_hantu`, serta Tamu Istimewa `mon_mbok_laras` di 4-4)**:
    - Waktu tunggu $60\text{ s}$, transparan dan tidak bisa dipukul sampai masuk Tahap 3 (`ENRAGED` — `FR-MON-10`), serangan `FREEZE_TOUCH` (membekukan stasiun terdekat selama $5.0\text{ s}$ `FR-MON-15`), drop langka Stage 4: `item_jahe_kripta` (atau garam kristal suci).
    - Di Level 4-3 (`AROMA`), hantu hanya terlihat dan bisa memesan saat awan aroma wedang sedang aktif ($15.0\text{ s}$ per seduhan).
  - [ ] Implementasikan hazard Stage 4: **`ICE_FLOOR`** (percepatan gerak $0.35\text{ s}$ licin, bahan yang membeku butuh dihangatkan $3.0\text{ s}$ di tungku), **`BLACKOUT`** (tiap $30\text{ s}$ gelap selama $8.0\text{ s}$, hanya lingkaran radius $3.0\text{ tile}$ di sekitar koki & stasiun serta garis bidik yang menyala `FR-AST-09`), dan **`AROMA`**.
  - [ ] Susun `LevelData` **`4-1`, `4-2`, `4-3`, `4-4`** sesuai tabel `§9.5`.
- **Verifikasi AI:** Buat `res://tests/test_stage4_content.gd` untuk menguji pencairan bahan beku $3.0\text{ s}$, visibilitas pesanan Hantu saat `AROMA` aktif vs mati, kebal pukul Hantu sebelum Tahap 3, dan pemuatan Level `4-1..4-4`.

### M3.5 — Stage 5: Sarang Naga (`5-1` s.d. `5-3`), Pelanggan Manusia, & Boss Sang Ageng 3 Fase (`§8.4, §8.8, §9.5, §10.1, §12.3`)
- **Referensi PRD v1.0:** `FR-STA-10` (Puzzle Tumpeng), `FR-MON-11`, `FR-BOS-01` s.d. `FR-BOS-06`, Hazard `HEARTBEAT` & `DRAGON_BREATH`.
- **Checklist Tugas:**
  - [ ] Buat Level **5-1 (`level_5_1` — Semua Pelanggan Lama)**: Durasi $240\text{ s}$, `max_open_tickets = 5`, `max_active_monsters = 10`, `plate_count = 6`, Kursi panjang = 7, Meja kecil = `2/2`, campuran Goblin, Kadal, Ogre, dan Hantu dengan waktu tunggu $120\%$ (`FR-MON-03`), serta hazard **`HEARTBEAT`** (tiap $20\text{ s}$ menggeser item $1\text{ tile}$ dan menggetarkan penanda bidik selama $0.3\text{ s}$).
  - [ ] Buat Level **5-2 (`level_5_2` — Pelanggan Manusia & Kapten Bramasta)**: Pelanggan prajurit manusia (`mon_human_soldier`, `mon_bramasta`) yang memesan masakan hangat (Nasi Liwet, Sate, dll.); pelanggan manusia **tidak menyerang dapur** — jika kesabaran habis, mereka langsung pergi dan mengurangi Hati Dapur $-1$ (`FR-MON-11`), disertai hazard **`DRAGON_BREATH`** (tiap $30\text{ s}$ api kecil ke satu sudut dengan telegraf $1.5\text{ s}$).
  - [ ] Implementasikan **Cetakan Tumpeng & Perakitan Tumpeng Berurutan (`FR-STA-10`, `§8.8`)**:
    - Sub-langkah wajib berurutan di atas Nampan Tumpeng (kapasitas 8 komponen):
      1. Cetak nasi kuning di Cetakan Tumpeng ($3.0\text{ s}$) lalu taruh di nampan.
      2. Susun lauk & sayur di nampan: `mendoan`, `urap`, dan `sambal_ulek`.
      3. Letakkan ke-4 **Bahan Langka** (`truffle_gua`, `bunga_teratai`, `cabai_magma`, `jahe_kripta`) di puncak tumpeng.
    - Jika pemain memasukkan komponen dengan urutan sub-langkah yang salah, sub-langkah tersebut runtuh dan harus diulang (`FR-STA-10`).
  - [ ] Implementasikan **Level 5-3 (`level_5_3` — Jamuan Sang Ageng / Boss 3 Fase `FR-BOS-01` s.d. `FR-BOS-06`)**:
    - Zona saji berupa **Altar Sang Ageng** (`SeatingTable` jenis `ALTAR` berukuran $3 \times 3$ tile `FR-SRV-06`, `FR-BOS-06`).
    - **Meter Kepuasan Naga (`FR-BOS-05`):** Mulai pada nilai $60.0$, turun $0.5\text{ per detik}$, naik $+30.0$ tiap hidangan tersaji ($+5.0$ tambahan bila Jitu), maksimal $100.0$. Level gagal jika meter kepuasan habis atau 5 Hati Dapur habis (Hati Dapur tidak pulih antar fase `FR-BOS-01`).
    - **Fase 1 (Sup Pembuka `recipe_sup_pembuka`):** Tiap $30\text{ s}$ Naga meniup api ke satu sudut acak dengan telegraf $1.5\text{ s}$ (`FR-BOS-02`).
    - **Fase 2 (Sate & Rendang Kilat):** Tiap $30\text{ s}$ sapuan ekor melintasi dapur dengan telegraf garis $1.5\text{ s}$ (`FR-BOS-03`).
    - **Fase 3 (Tumpeng Lengkap `recipe_tumpeng_lengkap`):** Tiap $20\text{ s}$ napas api menyapu satu baris lantai penuh dengan telegraf $2.0\text{ s}$ (`FR-BOS-04`).
- **Verifikasi AI:** Buat `res://tests/test_stage5_and_boss.gd` untuk menguji perilaku pelanggan manusia (`FR-MON-11`), validasi urutan 3 sub-langkah Tumpeng (termasuk skenario salah urutan runtuh), serta transisi Fase $1 \rightarrow 2 \rightarrow 3$ dan kalkulasi Meter Kepuasan Sang Ageng.

### M3.6 — Peta Dunia Vertikal 5 Lapisan (`WorldMap`), Gerobak Rel, & Dialog Cerita (`§16`)
- **Referensi PRD v1.0:** `FR-MAP-01` s.d. `FR-MAP-08`, GDD Bagian 4 & 5.
- **Checklist Tugas:**
  - [ ] Buat `res://ui/world_map.gd` dan `res://ui/world_map.tscn` ($480 \times 270\text{ px}$ — `FR-MAP-01`):
    - Header $20\text{ px}$ (nama stage & indikator Bahan Langka per stage) dan 5 lapisan vertikal setinggi $50\text{ px}$ (`map_layer_1` s.d. `map_layer_5`). Tutorial tidak ditampilkan di peta.
    - Menampilkan 19 node level (`4, 4, 4, 4, 3` per lapisan) dengan 3 status: terkunci, terbuka, selesai ($1..3$ bintang), serta syarat wajib 4 Bahan Langka untuk membuka Level `5-3` (`FR-MAP-02`, `FR-MAP-03`).
    - Animasi gerobak (`cart_map_clean`, `cart_map_dusty`, `cart_map_loaded` sesuai progres stage `FR-MAP-05`) berjalan di atas `Path2D` selama $1.5..3.0\text{ s}$ sambil memuat level di belakang layar, dapat dilewati dengan menahan `interact` (`FR-MAP-04`).
  - [ ] Buat `res://ui/story_dialog.gd` (balon dialog pengantar $3..6$ baris antar level dengan potret `portrait_*` yang bisa dilewati) dan layar Buku Resep Juru Kunci.
- **Verifikasi AI:** Buat `res://tests/test_world_map_progression.gd` untuk memverifikasi terbukanya node berurutan dengan minimal 1 bintang, penguncian Level `5-3` jika Bahan Langka belum lengkap 4, dan pembaruan kondisi gerobak.

---

## MILESTONE M4: Polish, Penyimpanan (`Save`), Lokalisasi, Aksesibilitas, & Rilis 1.0 (`§14, §17, §20, §21`)
**Kriteria Selesai M4:** Sistem penyimpanan atomik + ekspor/impor kode save web berfungsi, seluruh teks memakai kunci lokalisasi, semua menu & opsi aksesibilitas aktif, dan preset ekspor Windows & Web (itch.io single-thread) siap rilis.

### M4.1 — Penyimpanan Atomik (`user://save.json`), Migrasi Skema, & Kode Save Web (`§17`)
- **Referensi PRD v1.0:** `FR-SAV-01` s.d. `FR-SAV-05`, `NFR-REL-01`.
- **Checklist Tugas:**
  - [ ] Lengkapi `res://autoload/save.gd`:
    - Penulisan atomik ke `user://save.json.tmp` lalu mengganti `user://save.json` dengan nomor versi skema (`schema_version = 1`) dan fungsi migrasi otomatis (`FR-SAV-01`, `FR-SAV-04`).
    - Menyimpan bintang & skor terbaik per level, 4 Bahan Langka, halaman Buku Resep, kostum, flag selesai tutorial, posisi node peta terakhir, remap tombol P1/P2, volume, bahasa, serta semua flag aksesibilitas (`FR-SAV-02`).
    - Menyediakan fungsi `export_save_code() -> String` (Base64 + checksum singkat) dan `import_save_code(code: String) -> bool` untuk mengantisipasi penghapusan IndexedDB di browser web (`FR-SAV-03`).
- **Verifikasi AI:** Buat `res://tests/test_save_system.gd` untuk menguji tulis/baca atomik, pemulihan dari file korup tanpa crash (`NFR-REL-01`), migrasi versi skema, dan *round-trip* ekspor/impor kode save Base64.

### M4.2 — Lokalisasi (`locale/`) & Menu Lengkap (Utama, Latihan, Jeda, Hasil, Pengaturan/Aksesibilitas) (`§14, §21`)
- **Referensi PRD v1.0:** `FR-UI-06`, `NFR-ACC-01` s.d. `NFR-ACC-03`, `NFR-LOC-01`.
- **Checklist Tugas:**
  - [ ] Buat tabel terjemahan `res://locale/translations.csv` (Bahasa Indonesia `id` sebagai default dan kerangka Bahasa Inggris `en` — `NFR-LOC-01`) untuk seluruh nama hidangan, instruksi tutorial, dialog cerita, hasil lempar (`JITU!`, `TERSAJI`, `MELESET!`, `MEJA SALAH!`, ` TUMPAH!`), dan menu.
  - [ ] Buat seluruh scene UI di `res://ui/` (`FR-UI-06`):
    - `main_menu.tscn`: Tombol Mulai/Peta Dunia, **Latihan (Tutorial T-1..T-5)**, Buku Resep, Pengaturan, Ekspor/Impor Save, dan nomor versi `major.minor.patch+build`.
    - `pause_menu.tscn` & `results_screen.tscn`: Menampilkan bintang, rincian skor, Bahan Langka yang didapat, serta tombol **Lanjut**, **Peta**, dan **Ulang** (langsung memuat ulang level tanpa animasi gerobak `FR-MAP-04`, `FR-MAP-06`).
    - `settings_menu.tscn`: Pengaturan Volume (Master/BGM/SFX), Bahasa, **Bantuan Bidik** (default ON untuk keyboard), **Tekan untuk Bekerja** (toggle `work`), **Jendela Aduk Lebar** ($1.5\times$), **Kepadatan Kerumunan** (Mati/Rendah/Normal), **Kurangi Gerak/Guncangan Kamera**, **Kontras Tinggi**, **Kalibrasi Offset Audio** (`FR-STA-09`), dan **Remap Tombol P1 & P2**.
- **Verifikasi AI:** Buat `res://tests/test_localization_and_settings.gd` untuk memverifikasi semua kunci teks memiliki terjemahan Bahasa Indonesia dan perubahan opsi di `Settings` langsung memengaruhi simulasi.

### M4.3 — Kesiapan Build Web itch.io (`single-thread`), Gerbang Audio, & Bot Uji Level (`§20, §22`)
- **Referensi PRD v1.0:** `FR-WEB-01` s.d. `FR-WEB-06`, `§20.1`, `§22`.
- **Checklist Tugas:**
  - [ ] Buat layar gerbang awal web **"Klik untuk Mulai / Klik untuk Fokus"** (`FR-WEB-01`, `FR-WEB-02`) sebelum memutar audio pertama, tombol Fullscreen via API browser, peringatan jika dibuka di layar perangkat seluler (`FR-WEB-06`), dan pencegah tombol Spasi/Panah menggulir halaman browser.
  - [ ] Buat `export_presets.cfg` untuk **Windows 64-bit**, **Web (HTML5 Compatibility, `variant/thread_support=false`, GDExtension mati)**, dan **Linux Dedicated Server** (`§20.1`).
  - [ ] Buat bot pengujian otomatis `res://tests/test_bot_playthrough.gd` (`§22` Tes Determinisme & Tes Level) yang memutar rekaman input deterministik dengan *seed* tetap dan memastikan *replay* input yang sama selalu menghasilkan state akhir dan skor yang persis sama.
- **Verifikasi AI:** Jalankan seluruh rangkaian `godot --headless --script res://tests/run_tests.gd` dan `godot --headless --script res://tools/sync_assets.gd` tanpa satu pun kegagalan.

---

## MILESTONE M5 & M6: Fase 2 — Co-op Online 2 Pemain & Infrastruktur AWS (`§18, §19`)
*(Dikerjakan setelah Fase 1 / Rilis 1.0 Lokal selesai dan stabil)*

### M5.1 — Serialisasi Snapshot Biner (`< 400 byte`) & Server Dedicated Headless (`§18.2, §18.3`)
- **Referensi PRD v1.0:** `FR-NET-01` s.d. `FR-NET-08`, `FR-ROM-01` s.d. `FR-ROM-07`.
- **Checklist Tugas:**
  - [ ] Buat serializer biner manual (`PackedByteArray`, posisi fixed-point $1/8\text{ px}$ dengan target ukuran snapshot $< 400\text{ byte}$) di `res://net/snapshot_serializer.gd` (`FR-NET-06`, `FR-NET-07`).
  - [ ] Buat pengelola multi-ruangan `res://net/server_room_manager.gd` (menampung hingga 20 instans `Room` terisolasi per proses 1 vCPU dengan anggaran tick $\le 0.4\text{ ms}$ per ruangan `FR-ROM-06`) dan endpoint pemeriksaan kesehatan HTTP `GET /health` di port `8081` (`§19`).
  - [ ] Implementasikan pengiriman input klien $30\text{ Hz}$, pengiriman snapshot server $20\text{ Hz}$, prediksi lokal koki sendiri + rekonsiliasi, interpolasi entitas lain dengan buffer $100\text{ ms}$ (`FR-NET-02`, `FR-NET-03`), dan jendela sambung ulang $30\text{ s}$ (`FR-ROM-03`).
- **Verifikasi AI:** Buat `res://tests/test_net_serialization.gd` untuk membuktikan *round-trip* serialisasi snapshot menghasilkan state yang identik dengan ukuran paket $< 400\text{ byte}$.

### M5.2 — Lobby API, AWS CDK (ECS Fargate + ALB + DynamoDB), & Uji Beban (`§18.4, §19`)
- **Referensi PRD v1.0:** `§18.4`, `§19`, `NFR-PRF-06`, `NFR-SEC-01`.
- **Checklist Tugas:**
  - [ ] Buat kode infrastruktur AWS CDK (TypeScript) di folder `infra/` untuk DynamoDB (`Rooms`, `Shards`, `Guests`), Lambda + HTTP API Gateway (`/v1/auth/guest`, `/v1/rooms`, `/v1/rooms/{code}/join`, `/v1/health`), ECS Fargate + ALB WebSocket TLS, dan AWS Budgets.
  - [ ] Buat bot uji beban 20 ruangan paralel (`res://tests/load_test_bots.gd`) dengan simulasi latensi $50\text{ ms}$, $150\text{ ms}$, dan $300\text{ ms}$ serta pengujian *graceful draining* (`§19`, `§22`).