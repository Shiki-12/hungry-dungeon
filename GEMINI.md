# Project Rules: Hungry Dungeon (PRD Teknis v1.0 — Wajib 2 Pemain)

Kamu adalah Lead Godot 4 Developer otonom untuk proyek **Hungry Dungeon**.
Satu-satunya acuan teknis adalah `docs/PRD Teknis v1.0 Hungry Dungeon.md` dan rencana kerja di `milestone.md`.

## 1. Aturan Mutlak Proyek
1. **Engine & Bahasa:** Godot 4.7.x stable, Renderer `Compatibility` (`gl_compatibility`), Web export single-thread. Gunakan **GDScript dengan Static Typing penuh** (`var x: int = 0`, `func foo(dt: float) -> void:`). Dilarang menggunakan C#.
2. **Resolusi & Tata Letak ($480 \times 270\text{ px}$):**
   - HUD Atas: $480 \times 30\text{ px}$
   - Area Dapur & Dungeon: $30 \times 14\text{ tile}$ ($480 \times 224\text{ px}$, ukuran 1 tile = $16 \times 16\text{ px}$, kamera tetap tanpa scroll)
   - HUD Bawah: $480 \times 16\text{ px}$
3. **WAJIB 2 PEMAIN (Co-op Murni):**
   - Game ini hanya memiliki mode **2 Pemain Lokal** (Fase 1) dan **2 Pemain Online** (Fase 2).
   - **DILARANG KERAS** mengimplementasikan mode 1 pemain, aksi `swap_cook`, tombol `Tab` pergantian koki (`FR-MOV-05`), maupun `FR-SKL-10`. Rangga selalu dikendalikan P1 (`p1_*`) dan Sekar selalu dikendalikan P2 (`p2_*`).
4. **Pemisahan Murni `res://sim/` vs `res://view/`:**
   - Semua kode di `res://sim/` berjalan deterministik pada physics tick $60\text{ Hz}$ dengan `RandomNumberGenerator` ber-seed milik simulasi.
   - `res://sim/` **DILARANG** memuat `Sprite2D`, `AnimationPlayer`, `AudioStreamPlayer`, node `Control`/UI, maupun `CharacterBody2D`.
   - Tabrakan dan gerak dihitung sendiri di `res://sim/systems/collision.gd` (lingkaran radius $6\text{ px}$ melawan grid $16 \times 16$ dan AABB stasiun dengan corner sliding — `FR-MOV-08`).
5. **Kontrak Aset & Placeholder `box_<warna>` (`§5`):**
   - Kode di `sim/`, `ui/`, dan `levels/` hanya boleh merujuk aset lewat **ID String** (contoh: `&"cook_rangga"`, `&"item_bawang_raw"`).
   - Dilarang menggunakan `preload("res://assets/...")` di luar `res://view/` dan `res://autoload/assets.gd` (`FR-AST-01`).
   - Seluruh aset yang belum memiliki PNG final wajib dirender secara prosedural oleh `PlaceholderFactory` dan `Assets` sebagai kotak `box_<warna>` sesuai `res://data/assets/manifest.csv`.

## 2. Siklus Kerja Mandiri Berdasarkan `milestone.md`
Setiap kali diminta mengerjakan milestone:
1. Baca `milestone.md` dan temukan sub-milestone pertama yang masih berstatus `[ ]`.
2. Baca persyaratan terkait di `docs/PRD Teknis v1.0 Hungry Dungeon.md`.
3. Tulis atau perbarui kode di `res://` dengan static typing penuh dan komentar seperlunya.
4. Buat/perbarui unit test untuk fitur tersebut di `res://tests/` dan jalankan:
   - `godot --headless --script res://tests/run_tests.gd`
   - (Serta `godot --headless --script res://tools/sync_assets.gd` bila menyentuh aset/manifest).
5. Jika ada error atau test yang gagal, perbaiki sendiri sampai keluar dengan kode `0` (PASS).
6. Setelah lulus semua test, ubah `[ ]` menjadi `[x]` di `milestone.md` untuk tugas yang sudah selesai, lalu lanjut ke sub-milestone berikutnya sesuai instruksi pengguna.