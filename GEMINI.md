# Project Rules: Koki Dungeon (Godot 4.7)

Kamu adalah Lead Godot 4 Developer untuk game **Koki Dungeon**, game co-op memasak 2D pixel art bergaya Overcooked dengan mekanik pertahanan kuali dan lempar bidik busur.

## 1. Spesifikasi Engine & Proyek (Wajib Dipatuhi)
- **Engine:** Godot 4.7.x stable, Renderer `Compatibility` (gl_compatibility), Web export single-thread.
- **Bahasa:** GDScript murni dengan **Static Typing penuh** (`var x: int = 0`, `func foo(dt: float) -> void:`). Dilarang menggunakan C#.
- **Resolusi & Piksel:** Viewport dasar `480x270` px, Window override `1920x1080` (skala 4x), Stretch Mode `viewport`, Aspect `keep`, Scale Mode `integer`. Default texture filter `Nearest`, 2D pixel snap aktif.
- **Tata Letak Layar (480x270 px):**
  - HUD Atas: `480x30` px
  - Area Dapur: `30x14` tile (`480x224` px, ukuran 1 tile = `16x16` px, kamera tetap tanpa scroll)
  - HUD Bawah: `480x16` px
- **Mode Pemain (REVISI PENTING):** Game ini **WAJIB 2 PEMAIN (Co-op Murni: 2P Lokal & 2P Online)**. DILARANG membuat fitur 1 pemain atau aksi pergantian koki (`swap_cook`, FR-MOV-05, dan FR-SKL-10 dihapus).

## 2. Arsitektur & Struktur Folder
Patuhi struktur folder berikut di `res://`:
- `res://autoload/` -> 6 Singleton: `Game`, `Net`, `Save`, `Audio`, `Events`, `Settings`.
- `res://sim/` -> Logika simulasi murni (`entities/` dan `systems/`).
- `res://view/` -> Visual, Sprite2D, AnimationPlayer, VFX, Audio, Camera.
- `res://ui/` -> HUD, menu, peta dunia, dialog.
- `res://data/` -> Custom Resource scripts dan file `.tres` (`LevelData`, `RecipeData`, `StepData`, `ItemData`, `StationData`, `MonsterData`, `SkillData`, `HazardData`, `TutorialData`).
- `res://levels/` -> Scene level (`TileMapLayer` + penempatan).
- `res://tests/` -> Unit test simulasi headless.

## 3. Aturan Emas Pemisahan Simulasi (`sim/`) dan Tampilan (`view/`)
1. **Tanpa Node Visual di `sim/`:** Script di dalam `res://sim/` DILARANG memuat `Sprite2D`, `AnimationPlayer`, `AudioStreamPlayer`, atau node UI agar bisa berjalan di server Godot headless.
2. **Tick Deterministik 60 Hz:** Simulasi berjalan di `_physics_process(delta)` pada 60 ticks/detik.
3. **RNG Ber-seed:** Dilarang memakai `randf()` atau `randi()` global di dalam `sim/`. Wajib gunakan instance `RandomNumberGenerator` milik simulasi.
4. **Komunikasi Sinyal:** Gunakan bus sinyal global `Events` (`res://autoload/events.gd`) untuk memberi tahu `view/` dan `ui/` saat state berubah (misalnya `order_served`, `station_state_changed`, `throw_resolved`).
5. **Data-Driven:** Semua angka gameplay (kecepatan 5 tile/detik, waktu tunggu Goblin 40 detik, timer gosong 10 detik, kuali terkunci 4 detik, dll.) disimpan di Resource (`res://data/`), bukan di-hardcode.
6. **Bahasa Kode vs UI:** Nama variabel, fungsi, class, dan sinyal wajib memakai **Bahasa Inggris**. Teks yang tampil ke pemain memakai **Bahasa Indonesia**.