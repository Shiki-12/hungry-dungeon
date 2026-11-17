# PRD Teknis v1.0: Hungry Dungeon

Nov 15, 2026 · @Glooms Sarpy

Dokumen ini adalah **satu-satunya acuan teknis**. Ia menggabungkan PRD v0.1 (gameplay, online, AWS, itch.io) dan PRD v0.3 (placeholder-first, memasak, lapak, kerumunan, peta), lalu menambahkan **sistem penamaan aset dan placeholder `box_<warna>`** supaya developer tidak menunggu aset dan penggantian aset cukup dengan menaruh file. Dev tidak perlu lagi membaca dokumen versi lama.

## 0. Riwayat Revisi dan Cara Membaca

| Versi | Isi |
| --- | --- |
| v0.1 | Dasar: gameplay, jaringan, AWS, build itch.io |
| v0.3 | Placeholder-first, memasak, cuci piring, gerak 8 arah, lapak, kursi, kerumunan, emoticon, peta dunia |
| **v1.0** | Penggabungan jadi satu dokumen. Sistem penamaan aset dan placeholder (§5). Aturan lempar baru. Perbaikan hasil tinjauan |

**Perbaikan hasil tinjauan yang sudah dimasukkan:**

- Lempar adalah **jalan pintas opsional** untuk meja yang jauh. Meja panjang cukup disamperin. Lemparan diperlakukan seperti samperin (memilih kursi yang pesanannya cocok), dengan radius sukses 12 px, Jitu 6 px, dan bantuan bidik default untuk keyboard.
- Denah: meja kecil "dekat" digeser ke kolom 15 sampai 18 agar terjangkau lempar dari lapak.
- Alur perakitan dilengkapi: **Meja Alas**, Peti Bumbu Kacang, Kendi, Cetakan Tumpeng, dan urutan bubur singkong diperbaiki.
- `plate_count` minimal `max_open_tickets + 1`. Ada opsi jendela aduk lebar.
- `max_open_tickets` mengikuti "maksimal sekaligus" di GDD per level.
- Balon pesanan di kursi meja panjang diletakkan di sisi kanan monster.
- Tag animasi dirapikan di satu tempat (§13). Emoticon berjumlah 19. Tutorial dipindah ke menu Latihan, bukan ke peta.
- Jadwal M1 diperpanjang.

**Konvensi:** ID persyaratan **FR** (fungsional) dan **NFR** (non-fungsional). Prioritas **P0** wajib Rilis 1.0, **P1** bila waktu cukup, **P2** fase online dan pasca-rilis. Semua angka adalah **nilai awal** di file data (`.tres` atau `.csv`), bukan di kode. Identifier kode berbahasa Inggris, teks pemain berbahasa Indonesia lewat file terjemahan.

## 1. Ringkasan Produk dan Tujuan Teknis

*Hungry Dungeon* adalah game memasak co-op 1 sampai 2 pemain bergaya Overcooked dengan pixel art 2D. Pelanggannya monster yang bisa mengamuk, kuali berfungsi ganda sebagai alat masak dan senjata, dan hidangan bisa disamperin atau dilempar ke kursi monster.

**Tujuan teknis:**

1. Satu basis kode untuk **Windows** dan **web** (itch.io).
2. Mode 1 pemain, 2 pemain lokal, dan (Fase 2) 2 pemain online memakai jalur simulasi yang sama.
3. Semua konten berbasis data.
4. **Developer tidak menunggu aset.** Semua tampilan memakai ID dan placeholder, dan aset final cukup ditaruh sesuai standar nama.
5. Online memakai server otoritatif di AWS agar pemain web dan Windows bisa bermain bersama.

**Bukan tujuan:** 3D, mobile, konsol, voice chat, matchmaking berperingkat, pembelian dalam game, login sosial di Rilis 1.0.

| Kriteria sukses | Target |
| --- | --- |
| Frame rate desktop | 60 FPS di laptop GPU terintegrasi |
| Frame rate web | 60 FPS di Chrome dan Firefox, laptop kelas menengah |
| Waktu muat web | 15 detik atau kurang pada 20 Mbps |
| Konsistensi simulasi | Replay input yang sama menghasilkan skor yang sama |
| Penggantian aset | Menaruh file bernama benar lalu `sync_assets` menggantikan placeholder tanpa mengubah kode |
| Online (Fase 2) | Nyaman sampai RTT 150 ms |

## 2. Keputusan Teknis Utama

| Area | Keputusan | Alasan |
| --- | --- | --- |
| Engine | **Godot 4.7.x stable** (4.7.2 per 18 Agustus 2026). Kunci versi minor, upgrade hanya patch | Stabil selama produksi. Cek ulang saat mulai |
| Bahasa | **GDScript** dengan static typing, tanpa C# | Godot 4 tidak bisa mengekspor C# ke web |
| Renderer | **Compatibility** (WebGL 2) | Wajib untuk web, cukup untuk 2D |
| Platform | Windows 64-bit dan Web di itch.io. Linux opsional |  |
| Web export | **Single-thread** | Default sejak 4.3, tanpa header khusus, paling kompatibel di itch.io |
| Arsitektur | `sim/` dipisah dari `view/`. Mode offline memakai jalur kode yang sama dengan online | Fase 2 tanpa tulis ulang |
| Fisika | Tabrakan dan gerak dihitung sendiri di `sim/`, tanpa `CharacterBody2D` | Deterministik dan jalan di server headless |
| **Aset** | **Placeholder-first. Kode hanya memakai ID. Nama file adalah kontrak. Placeholder `box_<warna>`** | Dev tidak menunggu desainer |
| Ukuran piksel | **Dikunci:** tile 16x16, viewport 480x270 | Menutup pertanyaan lama |
| Arah gerak | 8 arah. Sprite 3 arah (`down`, `up`, `side`) dipetakan lewat data | Hemat aset |
| Kuali | Kuali di tungku menjalankan COOK, FRY, BOIL | Mendoan tanpa wajan |
| Wadah | Piring, mangkuk, cangkir, daun, nampan satu pool, beda tampilan saja | Sederhana |
| Piring | Terbatas dan **cuci piring wajib** | Piring bersih jadi sumber daya berputar |
| Menyajikan | **Samperin** (aman) atau **lempar** (jalan pintas, berisiko) | Lempar mempercepat, bukan wajib |
| Transport online | **WebSocketMultiplayerPeer** (wss) | ENet tidak ada di web |
| Otoritas online | Server dedicated Godot headless | Browser tidak bisa jadi host |
| Hosting | **AWS ECS Fargate + ALB** (TLS) | WebSocket didukung, tanpa SDK khusus. GameLift ditolak karena SDK server hanya C++, C#, Go |
| Lobby dan auth | API Gateway + Lambda + DynamoDB, login tamu dengan JWT | Serverless |
| IaC dan CI/CD | AWS CDK (TypeScript). GitHub Actions. **butler** untuk itch.io | Otomatis |
| Region | AWS Jakarta bila layanan lengkap, cadangan Singapura | Cek ketersediaan layanan |

**Fakta yang dicek per 15 November 2026 dan perlu dicek ulang di awal produksi:** Godot web single-thread adalah default sejak 4.3. Batas itch.io sekitar 500 MB diekstrak, 1.000 file, 200 MB per file (dari panduan komunitas). Godot **tidak mengimpor GIF** secara bawaan (juga tidak WebP atau APNG beranimasi). Ada GDExtension komunitas untuk GIF, tapi GDExtension di export web berisiko, jadi GIF dikonversi ke strip PNG (§5).

## 3. Fase Rilis

| Fase | Isi | Teknologi |
| --- | --- | --- |
| **Fase 1: Rilis 1.0** | Tutorial 5 level, 19 level utama, 1 dan 2 pemain lokal, lempar, skill, combo | Godot, build Windows dan web di itch.io. Tanpa AWS saat berjalan |
| **Fase 2: Online beta** | Co-op online 2 pemain lewat kode ruangan | Server Godot headless di AWS, lobby API |
| **Fase 3: Pasca-rilis** | Mode Warung, bahasa tambahan, kostum, papan skor, akun | Perluasan AWS |

Kode Fase 1 sudah siap online: input dikirim sebagai perintah, `sim/` memegang seluruh state, `view/` hanya membaca.

## 4. Arsitektur Klien Godot

### 4.1 Pengaturan proyek

| Pengaturan | Nilai |
| --- | --- |
| Viewport dasar | 480x270 |
| Stretch | mode viewport, aspect keep, scale mode **integer** |
| Filter tekstur default | Nearest |
| Snap transform 2D ke piksel | Aktif |
| Physics ticks | 60 per detik |
| Jendela default | 1920x1080 (skala 4x), minimum 960x540 (2x) |

**Tata letak layar:** HUD atas 30 px (tiket dan skor), area dapur 30x14 tile = 480x224 px, HUD bawah 16 px (Hati Dapur dan ikon skill). Semua level muat tanpa scroll.

### 4.2 Struktur folder

```
res://
  autoload/        # singleton global (game, net, save, audio, events, settings, assets)
  sim/             # simulasi, tanpa node visual, dipakai klien dan server
    entities/      # cook, monster, item, station, seat, projectile
    systems/       # orders, scoring, hazards, throw, skills, collision
  view/            # sprite, animasi, vfx, audio, kamera, crowd, emote
  ui/              # HUD, menu, peta, dialog, theme.tres
  data/
    assets/        # manifest.csv, tile_slots.csv, index.json (otomatis)
    levels/ recipes/ monsters/ skills/ hazards/ tutorial/
  levels/          # scene level (LapakModule + TileMapLayer)
  assets/          # aset final per ID (lihat §5.3)
  assets_src/      # file sumber Aseprite, tidak diimpor Godot
  reports/         # asset_status.md dan .json (otomatis)
  tools/           # sync_assets, make_placeholders, gif_to_strip, asset_audit
  net/             # klien jaringan dan server (Fase 2)
  tests/           # unit test, anim_gallery.tscn
  locale/          # terjemahan
```

### 4.3 Autoload

| Singleton | Tugas |
| --- | --- |
| `Game` | Alur level, mode permainan, pause, transisi |
| `Net` | Abstraksi sesi: offline, lokal, online |
| `Save` | Progres dan pengaturan |
| `Audio` | Bus musik, SFX, UI |
| `Events` | Bus sinyal global |
| `Settings` | Input, volume, bahasa, bantuan bidik, jendela aduk, kerumunan |
| `Assets` | Menerjemahkan ID ke resource (§5). Tidak memuat apa pun pada server dedicated |

### 4.4 Pemisahan simulasi dan tampilan

- `sim/` tidak memuat node yang bergantung pada render, audio, atau UI.
- Simulasi berjalan di **tick tetap 60 Hz**. `view/` membaca state dan menginterpolasi.
- Aksi pemain masuk sebagai struktur **Input** per tick: arah gerak, `interact`, `work`, `strike`, `skill_1`, `skill_2`, `throw`, data bidik.
- Perubahan state memancarkan **event** (`order_served`, `throw_resolved`, dan sebagainya) yang dibaca `view/` untuk efek dan suara.
- Fungsi acak memakai **RNG ber-seed milik simulasi**. `view/` punya RNG sendiri.
- Offline dan lokal menjalankan simulasi di proses yang sama dengan `OfflineMultiplayerPeer`. Online memasang peer jaringan di tempat yang sama.

### 4.5 Konten berbasis data

| Resource | Isi utama |
| --- | --- |
| `LevelData` | id, stage, durasi, modul lapak, stasiun, kursi dan meja, menu aktif, jadwal monster, hazard, batas bintang, tamu istimewa, skill terbuka, `plate_count`, `washing_enabled`, `max_open_tickets`, `max_active_monsters`, `long_table_bias`, `seat_patience_scale` |
| `RecipeData` | id, nama, langkah, komponen akhir, wadah, ikon, nilai poin |
| `StepData` | tipe, input, output, stasiun, durasi, `rhythm`, `attention` |
| `ItemData` | id, kategori, `form`, wadah, `sprite_id`, `icon_id`, bisa dilempar |
| `StationData` | id, tipe, ukuran, kapasitas, langkah yang diterima, `linked_rack` |
| `MonsterData` | id, ukuran, waktu tunggu, selera, `attack_pattern`, `allowed_seat_types`, efek kerupuk, drop langka, varian |
| `SeatingData` | `long_seats`, `small_tables`, titik jangkar balon dan emoticon |
| `SkillData`, `HazardData`, `TutorialData`, `WorldMapData`, `EmoteMapData`, `FacingMapData` | Parameter masing-masing sistem |

## 5. Sistem Aset: Penamaan, Placeholder, dan Penggantian

Bagian ini adalah **kontrak** antara developer, desainer, dan AI agent. Tujuannya: developer mengerjakan semua fitur dengan placeholder, dan saat aset datang, penggantiannya cukup **menaruh file dengan nama yang benar lalu menjalankan satu perintah**, tanpa mengubah kode gameplay.

### 5.1 Prinsip

1. Kode (`sim/`, `ui/`, `levels/`) hanya merujuk aset lewat **ID string**, misalnya `item_bawang_raw`. Tidak ada `preload("res://assets/...")` di luar `view/` dan `autoload/assets.gd`.
2. **Nama file adalah kontrak.** Dari nama file, tool tahu aset itu milik ID mana, animasi apa, dan arah mana.
3. Aset boleh belum ada kapan saja. Yang tampil adalah **placeholder `box_<warna>`**.
4. Mengganti placeholder dengan aset final tidak menyentuh `sim/`, `view/`, atau `ui/`.

### 5.2 Tata nama ID

Format: `<prefix>_<nama>[_<varian>]`. Huruf kecil, angka, dan garis bawah saja. Tanpa spasi, huruf besar, atau aksara non-ASCII. Nama makanan memakai Bahasa Indonesia, istilah teknis (tag animasi, state) memakai Bahasa Inggris.

| Prefix | Isi | Ukuran frame | Placeholder | Contoh ID |
| --- | --- | --- | --- | --- |
| `cook` | Koki | 32x32 (badan 16x24) | `box_blue` | `cook_rangga` |
| `mon` | Monster dan pelanggan | 32x32 (Ogre 48x48) | `box_red` | `mon_goblin` |
| `item` | Bahan dan perkakas yang dibawa | 16x16 | `box_orange` | `item_bawang_raw` |
| `dish` | Hidangan di dunia (sudah di wadahnya) | 16x16 | `box_orange` | `dish_nasi_goreng_jamur` |
| `icon` | Ikon hidangan untuk tiket | 24x24 | `box_orange` | `icon_nasi_goreng_jamur` |
| `plate` | Wadah | 16x16 | `box_brown` | `plate_clean` |
| `station` | Stasiun | 16x16, 32x16, 32x32 | `box_brown` | `station_tungku` |
| `furn` | Perabot lapak: tikar, meja, kursi, kendi | 16x16 atau 32x16 | `box_gray` | `furn_table_long` |
| `tile` | Atlas tile satu tema | 16x16 per sel | `box_gray` | `tile_gua` |
| `prop` | Dekorasi latar | kelipatan 8 | `box_gray` | `prop_gua_jamur_besar` |
| `vfx` | Efek | 16x16 sampai 32x32 | `box_white` | `vfx_steam` |
| `emote` | Emoticon | 16x16 | `box_pink` | `emote_chop` |
| `ui` | Elemen UI | sesuai §14 | `box_green` | `ui_heart_full` |
| `map` | Latar dan node peta | sesuai manifest | `box_green` | `map_layer_1` |
| `cart` | Gerobak (lapak dan peta) | 24x32 | `box_brown` | `cart_stall_clean` |
| `portrait` | Potret | 48x48 | `box_purple` | `portrait_sekar_happy` |
| `art` | Ilustrasi | 64x96 | `box_purple` | `art_select_rangga` |
| `sfx`, `bgm`, `amb` | Audio | tidak berlaku | bunyi sintetis atau hening | `sfx_chop` |

Bentuk khusus:

- **Bahan** memakai akhiran *form*: `_raw`, `_prepped`, `_cooked`, `_burnt`. Contoh: `item_bawang_raw`, `item_bawang_prepped`.
- **Gerobak** memakai akhiran kondisi: `_clean`, `_dusty`, `_loaded`.
- **Tile** satu file per tema dengan slot bernomor (§5.6).
- **Audio** bervariasi: `sfx_chop_01.ogg`, `sfx_chop_02.ogg`. Engine memilih acak.

### 5.3 Nama file dan struktur folder

Path mengikuti ID: `assets/<prefix>/<ID>/<nama file>`.

| Jenis | Nama file | Contoh |
| --- | --- | --- |
| Statis | `<ID>.png` | `assets/item/item_bawang_raw/item_bawang_raw.png` |
| Animasi satu aksi (`loop` atau `play`) | `<ID>.png` (strip horizontal) | `assets/emote/emote_chop/emote_chop.png` |
| Animasi bertag | `<ID>__<anim>.png` | `cook_rangga__work_side.png` |
| Animasi bertag tanpa arah | `<ID>__<anim>.png` | `station_tungku__working.png` |
| Audio | `<ID>.ogg` atau `<ID>_NN.ogg` | `sfx_chop_01.ogg` |
| Sumber Aseprite | `assets_src/<prefix>/<ID>.aseprite` | `assets_src/cook/cook_rangga.aseprite` |
| Metadata opsional | `<ID>.meta.json` | `{"fps":10,"loop":true,"pivot":[16,32]}` |

- **Dua garis bawah** (`__`) memisahkan ID dari tag animasi.
- Tag berarah berakhiran `_down`, `_up`, atau `_side`. Arah kiri adalah flip dari `side` dan tidak digambar.
- Strip horizontal satu baris, tanpa jarak antar frame. Jumlah frame = lebar gambar dibagi lebar frame.
- PNG 32-bit transparan, tanpa anti-aliasing, tanpa teks di dalam gambar.

```
assets/
  _incoming/        # taruh file mentah di sini (png, gif, ogg), tool memindahkannya
  cook/cook_rangga/cook_rangga__idle_down.png
  cook/cook_rangga/cook_rangga__walk_side.png
  item/item_bawang_raw/item_bawang_raw.png
  station/station_tungku/station_tungku__working.png
  emote/emote_chop/emote_chop.png
  sfx/sfx_chop/sfx_chop_01.ogg
```

### 5.4 Placeholder `box_<warna>`

Placeholder dibuat **oleh kode** (`PlaceholderFactory`), bukan file gambar, sehingga tidak ada yang perlu diganti atau dibersihkan.

| Keadaan | Nama keadaan | Tampilan |
| --- | --- | --- |
| Aset belum ada | `box_<warna>` sesuai prefix (tabel §5.2) | Kotak berwarna seukuran `frame_size`, garis tepi 1 px lebih gelap, ID di tengah (font 8 px, dipotong), panah arah untuk objek berarah |
| Aset ada dan lulus validasi | nama file, misalnya `item_bawang_raw.png` | Sprite final |
| Aset ada tapi salah | `INVALID` | Placeholder dengan bingkai merah dan peringatan di log |
| ID tidak terdaftar | `MISSING` | Kotak magenta berlabel `MISSING:<id>` |

Perilaku placeholder:

- **Animasinya tetap berjalan.** Jumlah frame dan fps mengikuti `manifest.csv`. Tiap frame ditandai nomor dan kotak bergeser 1 px, sehingga alur animasi, pemicu, dan timing bisa dites penuh.
- Warna: `box_blue` koki, `box_red` monster, `box_orange` bahan dan hidangan, `box_brown` stasiun, wadah, dan gerobak, `box_gray` tile dan perabot, `box_white` VFX, `box_pink` emoticon, `box_green` UI dan peta, `box_purple` potret.
- **Fallback per animasi:** untuk `<anim>_<arah>`, aturan pencariannya berurutan: aset final tag itu, aset final tag tanpa arah, lalu placeholder untuk tag itu saja. Jadi satu karakter bisa punya `walk_side` final sementara `idle_side` masih `box_blue`.
- **Aset statis** yang diminta bermain animasi apa pun menampilkan satu frame yang sama tanpa peringatan.
- **Audio:** SFX memakai bunyi sintetis pendek per kategori atau hening. Musik hening.

### 5.5 Manifest dan registri

`data/assets/manifest.csv` adalah satu-satunya tempat yang disunting untuk mendaftarkan aset. Satu baris per ID.

| Kolom | Arti | Contoh |
| --- | --- | --- |
| `id` | ID aset | `cook_rangga` |
| `frame_w`, `frame_h` | Ukuran satu frame | `32`, `32` |
| `pivot` | Titik acuan (default `bottom_center`) | `bottom_center` |
| `anims` | `nama:frame:fps:loop` dipisah \` | \` |
| `placeholder` | Nama `box_*` | `box_blue` |
| `nine_patch` | Margin L,T,R,B (UI) | `4,4,4,4` |
| `milestone` | M0 sampai M4 | `M1` |
| `notes` | Catatan |  |

Contoh baris:

```
id,frame_w,frame_h,pivot,anims,placeholder,nine_patch,milestone,notes
cook_rangga,32,32,bottom_center,idle_down:2:4:loop|walk_down:6:10:loop|work_side:3:8:loop,box_blue,,M1,
item_bawang_raw,16,16,bottom_center,,box_orange,,M1,
emote_chop,16,16,center,loop:3:6:loop,box_pink,,M1,
```

`sync_assets` membangun dari manifest dan file di `assets/` tiga hal: `SpriteFrames` per ID, `data/assets/index.json` (dibaca `Assets` saat runtime), dan laporan status. Jumlah frame dan fps boleh berbeda dari manifest bila desainer menghendaki, tetapi **ukuran frame, pivot, dan nama tag tidak boleh berubah**.

Resource yang dihasilkan:

```gdscript
class_name SpriteSetData extends Resource

@export var id: StringName            # "cook_rangga"
@export var prefix: StringName        # cook, mon, item, ...
@export var frame_size: Vector2i      # (32, 32)
@export var pivot: Vector2            # default tengah-bawah
@export var anims: Dictionary         # "walk_side": {frames, fps, loop, file}
@export var placeholder: StringName   # "box_blue"
@export var status: Dictionary        # "walk_side": "FINAL" atau "box_blue"
```

### 5.6 Atlas tile

Tile dikirim sebagai **satu atlas per tema**, bukan satu file per tile. Contoh: `tile_gua.png` dengan sel 16x16, 8 kolom dan 3 baris (file 128x48 px). Isi tiap slot ditentukan `data/assets/tile_slots.csv` (nomor slot, nama, `kind`). Desainer mengisi slot menurut nomor. Tile `kind` (`WATER`, `LAVA`, `SLIPPERY`) dibaca simulasi, dan gambarnya hanya tampilan.

| Slot | Nama | Slot | Nama |
| --- | --- | --- | --- |
| 0 | `floor_a` | 4 | `wall_corner` |
| 1 | `floor_b` | 5 | `pillar` |
| 2 | `wall` | 6 | `hazard_a` (air, lava, atau es; frame animasi 4 sampai 6 ada di baris ke-2) |
| 3 | `wall_top` | 7 | `hazard_b` |

Tema: `lapak`, `gua`, `rawa`, `magma`, `kripta`, `sarang`.

Untuk tutorial ditambah tema `halaman` (halaman rumah Mbok Laras).

### 5.7 Tool

| Tool | Tugas | Prio |
| --- | --- | --- |
| `tools/sync_assets.gd` | Perintah: `godot --headless --script res://tools/sync_assets.gd`. (1) Memindahkan file dari `assets/_incoming/` ke folder yang benar menurut prefix. (2) Memvalidasi nama, ukuran frame, jumlah frame, dan pivot. (3) Membangun `SpriteFrames` dan `index.json`. (4) Menulis `reports/asset_status.md` dan `.json`. Kode keluar bukan nol bila ada `INVALID` | P0 |
| `tools/make_placeholders.gd` | Dipanggil oleh sync. Membuat `SpriteFrames` placeholder agar editor bisa melihat preview | P0 |
| `tools/asset_audit.gd` | Memeriksa palet (maks 32 warna global + 8 per stage), pivot, ukuran, transparansi | P0 |
| `tests/anim_gallery.tscn` | Memutar semua animasi semua ID berdampingan dengan label status (`box_*` atau nama file) | P0 |
| `tools/gif_to_strip.py` | Mengubah GIF di `assets/_incoming/` menjadi strip PNG bernama benar. Fps diambil dari jeda GIF. Butuh Python dengan Pillow | P1 |
| Impor Aseprite | Desainer mengekspor per tag sebagai strip horizontal bernama `<ID>__<tag>.png`. Cek dulu addon komunitas seperti Importality sebelum menulis importer sendiri, dan pastikan cocok dengan versi Godot yang dikunci | P1 |

**Tentang GIF:** Godot tidak mengimpor GIF secara bawaan. GIF diterima hanya sebagai **masukan**: tool mengubahnya jadi strip PNG, dan game selalu memakai PNG. Jangan memakai GDExtension GIF di game karena berisiko di export web.

### 5.8 Alur mengganti aset (manusia dan AI agent)

1. Desainer mengekspor aset dengan nama sesuai §5.3 (dari Aseprite: satu strip per tag).
2. File ditaruh di `assets/_incoming/` (atau langsung di `assets/<prefix>/<ID>/`).
3. Jalankan `godot --headless --script res://tools/sync_assets.gd`.
4. Baca `reports/asset_status.json`. Setiap ID dan animasi berstatus `box_*`, nama file, atau `INVALID`.
5. Lihat hasilnya di `tests/anim_gallery.tscn` atau jalankan game dengan overlay debug (F3).
6. Perbaiki fps atau pivot lewat `manifest.csv` atau `.meta.json`. Bila ukuran frame salah, minta desainer mengekspor ulang.
7. Commit `assets/`, `assets_src/`, `data/assets/`.

Contoh laporan:

```
id                      anim        status       file
item_bawang_raw         -           box_orange   -
item_jamur_tiram_raw    -           FINAL        item_jamur_tiram_raw.png
cook_rangga             walk_side   FINAL        cook_rangga__walk_side.png
cook_rangga             work_side   box_blue     -
emote_chop              loop        INVALID      emote_chop.png (frame 20x16, seharusnya 16x16)
```

Contoh transisi: awalnya `item_bawang_raw` tampil sebagai **`box_orange`**. Setelah `assets/item/item_bawang_raw/item_bawang_raw.png` ditaruh dan sync lulus, game otomatis menampilkan sprite bawang. Tidak ada kode yang diubah.

**Aturan untuk AI agent:**

- Hanya boleh mengubah `assets/`, `assets_src/`, dan `data/assets/manifest.csv`. **Tidak menyentuh** `sim/`, `view/`, `ui/`, dan `levels/`.
- Selalu membaca `reports/asset_status.json` sebelum dan sesudah sync.
- Nama file harus persis mengikuti §5.3. Jangan menebak nama ID. Jika ID tidak ada di manifest, laporkan, jangan membuat ID baru tanpa persetujuan.
- Jangan mengubah ukuran frame, pivot, atau nama tag untuk "memperbaiki" aset. Laporkan sebagai `INVALID`.
- Jangan menghapus placeholder. Placeholder dibuat oleh kode.

### 5.9 Persyaratan

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-AST-01 | Kode gameplay hanya merujuk aset lewat ID string. Tidak ada `preload("res://assets/...")` di luar `view/` dan `autoload/assets.gd` | P0 |
| FR-AST-02 | `Assets` menyediakan `frames(id)`, `texture(id)`, `audio(id)`, dan `status(id, anim)` | P0 |
| FR-AST-03 | ID tidak ditemukan menghasilkan placeholder magenta `MISSING:<id>` dan peringatan, tanpa crash | P0 |
| FR-AST-04 | Placeholder `box_<warna>` dibuat oleh kode dan animasinya berjalan sesuai manifest | P0 |
| FR-AST-05 | Fallback per animasi: tag berarah, tag tanpa arah, placeholder tag itu | P0 |
| FR-AST-06 | `sync_assets` memindahkan, memvalidasi, membangun `SpriteFrames` dan `index.json`, dan menulis laporan status | P0 |
| FR-AST-07 | Logika `sim/` tidak menunggu animasi selesai. `view/` menyesuaikan `speed_scale` agar muat dalam durasi state. Frame "titik kena" ditentukan data di `sim/` | P0 |
| FR-AST-08 | Teks tidak dibakar ke sprite. Banner COMBO, angka, dan hasil lempar memakai `Label` dan kunci terjemahan | P0 |
| FR-AST-09 | Garis bidik, penanda jatuh, telegraf hazard, dan overlay gelap digambar lewat kode. Aset final hanya opsional sebagai skin | P0 |
| FR-AST-10 | Overlay debug (F3) pada build pengembangan menampilkan ID dan status tiap entitas (`box_orange` atau nama file) | P0 |
| FR-AST-11 | `Assets.reload()` (F5 di build pengembangan) memuat ulang `index.json` tanpa menutup game | P1 |
| FR-AST-12 | Server dedicated tidak memuat aset visual. `Assets` menjadi no-op dan `sim/` hanya memakai ID string | P2 |
| FR-AST-13 | Tile dikirim sebagai atlas per tema dengan slot di `tile_slots.csv` | P0 |
| FR-AST-14 | `gif_to_strip.py` menerima GIF sebagai masukan dan menghasilkan strip PNG | P1 |
| FR-AST-15 | Audio placeholder berupa bunyi sintetis pendek atau hening | P0 |

### 5.10 Aturan ekspor untuk desainer

- Ukuran frame dan pivot **tetap** menurut manifest. Pivot di tengah-bawah, sama untuk semua frame satu ID.
- Satu strip horizontal per tag, tanpa jarak antar frame.
- Jumlah frame dan fps boleh berbeda dari placeholder.
- Tidak ada teks di dalam gambar. Tanpa anti-aliasing. PNG 32-bit transparan.
- Palet mengikuti spesifikasi teknis (maks 32 warna global + 8 per stage).
- Daftar ID, ukuran, tag, dan nama file lengkap ada di dokumen **Daftar Aset v1.0**.

## 6. Input

| Aksi | Keyboard P1 | Gamepad |
| --- | --- | --- |
| `move_*` | WASD | Stik kiri (deadzone 0,2) |
| `interact` (ambil, taruh, angkat ke piring, samperin) | E | A |
| `work` (potong, campur, ulek, cuci, aduk, balik) | F | X |
| `strike` (pukul) | Spasi | B |
| `skill_1` | Q | Y |
| `skill_2` | R | Trigger kanan |
| `throw` (ketuk = lempar cepat, tahan = bidik) | C | Bumper kanan |
| `swap_cook` (mode 1 pemain) | Tab | Bumper kiri |
| `pause` | Esc | Start |

- P1 dan P2 memakai set aksi terpisah (`p1_*`, `p2_*`). **Usulan keyboard P2** (diuji ghosting di M1): panah untuk gerak, lalu `.` interact, `,` work, `/` strike, `;` skill\_1, `'` skill\_2, Shift kanan throw.
- Pemain bisa memetakan ulang tombol. Pengaturan disimpan di `Save`.
- Bidik lempar di gamepad memakai stik kanan.
- Opsi aksesibilitas **Tekan untuk bekerja**: `work` menjadi tombol alih (FR-STA-21).
- Gamepad di web memakai Gamepad API browser dan wajib diuji di Chrome dan Firefox.

## 7. Koki dan Gerak

Koki bergerak dan menghadap 8 arah. Sprite hanya digambar 3 arah, jadi tampilan memetakan 8 arah ke 3 arah lewat tabel data.

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-MOV-01 | Gerak 8 arah. Vektor input dinormalisasi: kecepatan diagonal sama dengan lurus (5 tile per detik, percepatan 0,06 detik) | P0 |
| FR-MOV-02 | Koki bertabrakan dengan dinding, stasiun, meja, dan koki lain | P0 |
| FR-MOV-03 | Lantai licin (stage 4): momentum pada vektor 8 arah, percepatan 0,35 detik | P0 |
| FR-MOV-04 | Arah hadap adalah enum `Facing8` (E, SE, S, SW, W, NW, N, NE), diperbarui dari arah gerak terakhir dibulatkan ke 45 derajat. Saat diam, arah hadap bertahan | P0 |
| FR-MOV-05 | Mode 1 pemain: `swap_cook` memindahkan kendali, koki yang ditinggal diam | P0 |
| FR-MOV-06 | Target interaksi dicari dengan probe lingkaran radius 9 px di posisi koki + `Facing8` x 12 px. Prioritas: stasiun, item di lantai, kursi. Seri diselesaikan dengan jarak terdekat ke pusat probe. Untuk target kursi, radius diperlebar menjadi 14 px | P0 |
| FR-MOV-07 | Hitbox pukulan sutil (1,2 tile) dan kuali (1,6 tile) berbentuk AABB berpusat di posisi koki + `Facing8` x 0,9 tile, tidak dirotasi | P0 |
| FR-MOV-08 | Tabrakan dihitung sendiri di `sim/`: lingkaran radius 6 px melawan grid 16x16 dan AABB stasiun, dengan sliding di sudut. Tanpa `CharacterBody2D` | P0 |
| FR-MOV-09 | Dash, lempar cepat, dan Tendangan Kuali memakai `Facing8`. Lempar bidik memakai arah bebas dari stik (sudut 16-bit) atau 8 arah dari keyboard | P0 |
| FR-MOV-10 | `FacingMapData` memetakan 8 arah ke tag sprite. Nilai awal: N menjadi `up`, S menjadi `down`, E menjadi `side`, W menjadi `side` flip, NE dan NW menjadi `up`, SE dan SW menjadi `side` flip sesuai komponen horizontal. Dapat diubah lewat data | P0 |
| FR-MOV-11 | Placeholder menampilkan panah kecil `Facing8` di atas kotak koki | P0 |

## 8. Item, Stasiun, Resep, dan Piring

### 8.1 Model dasar

Setiap bahan adalah `Item` dengan `form`: `RAW`, `PREPPED` (dipotong, dicampur, diulek), `COOKED`, `BURNT`. Tiap langkah resep (`StepData`) mengubah satu atau beberapa item menjadi satu item baru. Ada dua jenis stasiun:

- **Manual:** bekerja selama `work` ditahan. Contoh: meja potong, meja kerja, cobek, tempat cuci, cetakan tumpeng.
- **Otomatis:** jalan sendiri setelah diisi. Contoh: tungku dengan kuali, dandang, anglo, panci. Sebagian meminta perhatian di tengah jalan (aduk atau balik).

Bahan bergabung di dua tempat yang dibedakan tegas: **di stasiun masak** (kuali menampung 1 sampai 3 bahan) dan **di piring** (menampung 1 sampai 3 komponen, nampan tumpeng 8).

### 8.2 Alur satu hidangan

1. **Ambil** bahan dari peti (`interact`). Satu tangan, satu item.
2. **Siapkan** di stasiun manual (potong, campur, ulek, bungkus). Hasilnya item `PREPPED` yang diambil kembali.
3. **Masukkan** ke stasiun masak. Bahan yang tidak cocok dengan resep aktif apa pun ditolak (ikon silang, bahan tetap di tangan, tanpa hukuman).
4. **Masak** sampai `DONE`. Bila langkahnya punya fase perhatian (aduk atau balik), penanda muncul dan koki harus bereaksi.
5. **Angkat ke piring:** dengan piring bersih di tangan, `interact` pada stasiun `DONE`. Hasil pindah ke piring dan kuali tetap di tungku. Tanpa piring, `interact` mengangkat kuali berisi.
6. **Saji:** samperin atau lempar (§9).
7. **Cuci:** setelah monster pergi, piring kotor dicuci dan kembali ke rak.

### 8.3 Jenis langkah

| Jenis | Stasiun | Cara kerja | Aturan |
| --- | --- | --- | --- |
| `CHOP` potong | Meja potong | Manual, tahan `work` | Bar progres. Progres tersimpan bila dilepas |
| `MIX` campur | Meja kerja | Manual, tahan `work` | 2 sampai 3 bahan jadi satu item adonan atau bumbu |
| `WRAP` bungkus | Meja kerja | Manual | Bahan dan daun pisang jadi bungkusan (pepes) |
| `WILT` layu | Tungku | Otomatis | Daun pisang dilayukan 4 detik |
| `POUND` ulek | Cobek | Manual | `rhythm: false` tahan biasa. `rhythm: true` ulek ritme |
| `COOK` tumis, tanak | Tungku + kuali | Otomatis, bisa minta aduk | Sampai `DONE`, lalu timer gosong |
| `FRY` goreng | Tungku + kuali | Otomatis | Sama dengan COOK, tampilan berbeda. **Tanpa wajan di Rilis 1.0** |
| `BOIL` rebus | Tungku + kuali, panci | Otomatis | Sama dengan COOK, tampilan berbeda |
| `STEAM` kukus | Dandang | Otomatis | Tanpa perhatian |
| `GRILL` bakar | Anglo | Otomatis, minta balik | Balik tiap 6 detik |
| `ASSEMBLE` susun | Meja kerja, cetakan tumpeng, atau piring | Manual | Sate bertusuk dan tumpeng. Urutan salah meruntuhkan susunan |

### 8.4 Aduk dan balik: satu mekanik umum

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-STA-01 | State stasiun: `EMPTY`, `WORKING`, `DONE`, `BURNING`, `BURNT`. Kondisi lain berupa flag (§8.9) | P0 |
| FR-STA-02 | Stasiun otomatis bekerja sendiri sampai DONE. Stasiun manual hanya bekerja selama `work` ditahan | P0 |
| FR-STA-03 | Setelah DONE, timer gosong (awal 10 detik) mengubah state ke BURNING (asap) lalu BURNT | P0 |
| FR-STA-04 | `StepData.attention = {interval, window, miss_penalty}`. Tiap `interval` detik stasiun masuk `NEEDS_ATTENTION` dan menampilkan ikon aduk atau balik. Koki menekan `work` dalam `window` detik | P0 |
| FR-STA-05 | Bila ditangani tepat waktu, kualitas tetap. Bila terlewat, timer gosong dikalikan `miss_penalty` (awal 0,3, gosong jadi 3 detik dari 10) | P0 |
| FR-STA-06 | Nilai awal: sate balik tiap 6 detik jendela 1,5 detik. Nasi goreng aduk tiap 4 detik jendela 1,5 detik. Bubur sumsum aduk tiap 3 detik jendela 1,5 detik. Resep lain tanpa perhatian | P0 |
| FR-STA-07 | Penanda perhatian terlihat oleh kedua koki, sehingga tugas bisa dibagi | P0 |
| FR-STA-08 | **Ulek ritme:** bar irama 90 BPM, 6 ketukan. Jendela Sempurna ±60 ms, Bagus ±120 ms. Kualitas sambal menaikkan kepuasan 25, 15, atau 5 | P0 |
| FR-STA-09 | Layar kalibrasi offset audio untuk latensi suara di web dan perangkat berbeda | P1 |
| FR-STA-10 | **Tumpeng:** sub-langkah cetak nasi kuning (3 detik), susun lauk dan sayur di nampan, lalu 4 Bahan Langka di puncak. Urutan salah meruntuhkan sub-langkah itu | P0 |
| FR-STA-21 | Opsi aksesibilitas **Tekan untuk bekerja** (`work` sebagai tombol alih) dan **Jendela aduk lebar** (jendela dikali 1,5) | P1 |

### 8.5 Kuali, bumbu, dan kesalahan

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-STA-11 | Kuali menampung maksimal 3 bahan. Kecap, minyak, garam, dan bumbu dasar dianggap persediaan stasiun dan hanya muncul sebagai ikon kecil. Hanya komponen resep yang dibawa | P0 |
| FR-STA-12 | Resep dicocokkan lewat tanda tangan komponen tanpa urutan. Kuali mulai bekerja saat isinya cocok persis dengan satu resep. Selama belum cocok, `interact` tangan kosong mengeluarkan bahan terakhir | P0 |
| FR-STA-13 | Item `BURNT` tidak valid untuk resep apa pun. Mengosongkan stasiun gosong menghasilkan item gosong yang harus dibuang. Berpindah ke BURNT memberi -25 poin | P0 |
| FR-STA-14 | Tempat sampah membuang isi item di tangan. Kuali dan piring tetap di tangan, kosong dan bersih | P0 |
| FR-STA-15 | Peti bahan memberi item `RAW` tanpa batas. **Peti Nasi** memberi `nasi` matang. **Peti Bumbu Kacang** memberi `bumbu_kacang`. **Kendi** memberi `air`. Nasi liwet di Stage 2 memasak nasi dari beras | P0 |
| FR-STA-16 | Kuali berisi boleh dibawa pindah. Prosesnya berhenti selama dibawa dan lanjut saat ditaruh di tungku. Aturan tumpah berlaku bila dipakai memukul | P0 |
| FR-STA-17 | **Meja Alas:** permukaan 1 slot di lapak. Menaruh item atau piring di sana dengan `interact`. Dengan piring di tangan, `interact` pada item komponen di Meja Alas memindahkannya ke piring. Dengan komponen di tangan, `interact` pada piring di Meja Alas menambah komponen ke piring | P0 |
| FR-STA-18 | Meja potong dan meja kerja yang sedang kosong juga menerima item sebagai permukaan (1 slot) | P1 |

### 8.6 Item dan interaksi

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-INT-01 | Satu slot tangan per koki. Item yang dibawa tampil sebagai sprite 16x16 di atas kepala | P0 |
| FR-INT-02 | `interact` mengambil atau menaruh pada target di depan. Prioritas: stasiun, item di lantai, kursi | P0 |
| FR-INT-03 | `work` menjalankan aksi kerja selama ditahan, dengan bar progres 16x3 px di atas stasiun | P0 |
| FR-INT-04 | Item di lantai bisa dipungut. Item yang jatuh ke air hanyut (stage 2) atau lava hangus (stage 3) | P0 |
| FR-INT-05 | Piring menampung hingga 3 komponen (nampan tumpeng 8). Validasi lewat tanda tangan komponen tanpa urutan | P0 |
| FR-INT-06 | Menyerahkan hidangan dengan jalan kaki (samperin) selalu aman. Lihat §9 | P0 |

### 8.7 Piring dan cuci piring

Piring jumlahnya terbatas, dan itu membuat cuci piring bermakna. Semua wadah memakai satu pool `Plate` dan hanya beda tampilan lewat `ItemData.vessel`. Keadaan piring: `CLEAN` (rak), `HELD`, `SERVED` (di kursi), `DIRTY` (di kursi), `WASHING`, `LOST` (hancur, kembali bersih di rak setelah 10 detik).

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-WSH-01 | `LevelData.plate_count` menentukan jumlah piring, dan **minimal `max_open_tickets + 1`** (tabel §9.5). Rak piring dimulai penuh | P0 |
| FR-WSH-02 | Piring menjadi `DIRTY` di kursi 2 detik setelah monster di kursi itu pergi | P0 |
| FR-WSH-03 | Piring kotor diambil dengan `interact` dari kursi. Satu tumpukan hingga 3 piring kotor dibawa sebagai satu item | P0 |
| FR-WSH-04 | Tempat Cuci adalah stasiun manual: taruh tumpukan lalu tahan `work`, 1 piring per 2 detik. Progres tersimpan | P0 |
| FR-WSH-05 | Piring selesai dicuci langsung masuk Rak Piring yang tertaut (`StationData.linked_rack`) | P0 |
| FR-WSH-06 | Rak kosong menampilkan ikon "tidak ada piring" saat koki mencoba mengambil. Tanpa hukuman | P0 |
| FR-WSH-07 | `LevelData.washing_enabled`. Bila `false` (1-1 dan tutorial), piring kotor langsung hilang dan piring bersih kembali 6 detik setelah monster pergi. Cuci diperkenalkan di 1-2 lewat pop-up sekali | P0 |
| FR-WSH-08 | `LevelData.dirty_blocks_seat` (awal `false`). Bila `true`, kursi berpiring kotor tidak diberi monster baru | P1 |
| FR-WSH-09 | Piring kotor, kuali, dan bahan mentah tidak bisa dilempar | P0 |

| Stasiun pendukung | Fungsi | State |
| --- | --- | --- |
| Rak Piring | Menyimpan piring bersih | `FULL`, `LOW`, `EMPTY` |
| Tempat Cuci | Mencuci tumpukan piring kotor | `EMPTY`, `WASHING`, `DONE` |
| Tempat Sampah | Membuang isi item di tangan | `IDLE` |
| Meja Alas | Menaruh item atau piring | `EMPTY`, `HOLDING` |

### 8.8 Resep awal

Semua durasi adalah nilai awal di `.tres`. Yang sudah ada sebelumnya (pepes 12 detik, rendang 24 detik, ulek 6 ketukan 90 BPM, sate balik 6 detik) tidak diubah.

| Stage | Menu | Langkah | Piring akhir |
| --- | --- | --- | --- |
| 1 | Nasi goreng jamur | Potong jamur (3 s) dan bawang (2 s). Kuali: nasi + jamur iris + bawang iris `COOK` 10 s, aduk tiap 4 s | Nasi goreng |
| 1 | Tempe mendoan | Potong tempe (3 s). Meja kerja: tempe iris + tepung + daun bawang `MIX` 3 s. Kuali `FRY` 8 s | Mendoan |
| 1 | Bubur singkong | Cobek: parut singkong `POUND` 3 s (tahan biasa). Kuali: singkong parut + santan + gula merah `BOIL` 12 s | Bubur |
| 2 | Pepes ikan | Layukan daun pisang di tungku 4 s (`WILT`). Meja kerja: ikan + bumbu + daun layu `WRAP` 3 s. Dandang `STEAM` 12 s | Bungkusan pepes |
| 2 | Ikan bakar | Meja kerja: ikan + bumbu `MIX` 2 s. Anglo `GRILL` 10 s, balik tiap 6 s | Ikan bakar |
| 2 | Sayur asem | Potong sayuran 3 s. Panci: sayuran iris + asam + air (dari Kendi) `BOIL` 10 s | Mangkuk sayur asem |
| 2 | Nasi liwet | Kuali: beras + santan + daun salam `COOK` 14 s | Nasi liwet |
| 3 | Sate | Potong daging 3 s. Meja kerja: daging iris + tusuk `ASSEMBLE` 2 s. Anglo `GRILL` 12 s, balik tiap 6 s | Piring: sate + `bumbu_kacang` |
| 3 | Iga bakar sambal | Meja kerja: iga + bumbu `MIX` 2 s. Anglo `GRILL` 14 s | Piring: iga + sambal |
| 3 | Sambal ulek | Cobek `POUND` ritme: cabai + bawang + tomat, 6 ketukan 90 BPM (sekitar 4 s) | Sambal |
| 3 | Rendang kilat | Potong daging 3 s. Kuali: daging iris + santan + rempah `COOK` 24 s (Buff Api 2x) | Rendang |
| 4 | Wedang jahe | Cobek: geprek jahe `POUND` 2 s. Panci: jahe + gula merah + air `BOIL` 8 s | Cangkir wedang |
| 4 | Wedang ronde | Meja kerja: tepung ketan + kacang + jahe `MIX` 3 s (bentuk bola). Panci `BOIL` 8 s | Mangkuk ronde |
| 4 | Bubur sumsum | Kuali: tepung beras + santan + gula merah `BOIL` 10 s, aduk tiap 3 s | Bubur sumsum |
| 5 | Sup pembuka (boss fase 1) | Potong sayuran 3 s. Panci: sayuran iris + daging iris + air `BOIL` 10 s | Mangkuk sup |
| 5 | Tumpeng lengkap | Cetakan Tumpeng: cetak nasi kuning 3 s. Susun di nampan: nasi kuning cetak, mendoan (lauk), urap (sayur), sambal. Lalu 4 Bahan Langka di puncak | Nampan tumpeng |

Isi "lauk" dan "sayur" tumpeng adalah usulan (mendoan dan urap sederhana: potong dan rebus) dan masih terbuka (§26).

### 8.9 Flag stasiun

| Flag | Asal | Efek |
| --- | --- | --- |
| `NEEDS_ATTENTION` | FR-STA-04 | Ikon aduk atau balik muncul |
| `DISABLED` | FR-MON-05 | Stasiun rusak 8 detik |
| `NO_COOKWARE` | FR-CMB-02 | Tungku tanpa kuali |
| `COOKWARE_LOCKED` | FR-CMB-04 | Kuali tidak bisa dipakai memasak 4 detik setelah memukul |
| `FROZEN_INPUT` | ICE\_FLOOR | Item beku butuh 3 detik di tungku |

Setiap state dan flag punya satu `view_state` di tabel visual stasiun, supaya placeholder dan sprite final memakai kunci yang sama.

## 9. Lapak, Kursi, Menyajikan, dan Lempar

### 9.1 Lapak kaki lima

Dapur bukan ruangan di dalam gerobak (skalanya tidak masuk akal: gerobak 24x32 px hampir setinggi koki). Konsepnya **lapak kaki lima**: gerobak diparkir sebagai prop di tepi kiri, dan peralatan digelar di sekitarnya di atas tikar. Sisi kiri (kolom 0 sampai 11) adalah lapak dan hampir sama di tiap level. Sisi kanan (kolom 13 sampai 29) adalah dungeon dan berubah tiap stage.

| Objek | Ukuran | Catatan |
| --- | --- | --- |
| Koki | 16x24 px (kanvas 32x32) | Acuan skala |
| Gerobak | 24x32 px (2x2 tile) | Prop di tepi kiri, jendela saji menghadap kanan. Bukan tempat memasak |
| Stasiun | 16x16, beberapa 32x16 atau 32x32 | Perabot lepas di atas tikar |
| Meja panjang | 1 tile lebar, 10 tile panjang | Di kolom 12 |
| Meja kecil | 2x1 tile + 2 kursi | Di sisi dungeon |

### 9.2 Denah dasar (30x14 tile)

```
        x: 0         1         2
           012345678901234567890123456789
   r0      #####################D########
   r1      :PPCCMMKK:::=o................
   r2      ::::::::::::=o................
   r3      ::::::::::::=o.ommo...........
   r4      GG::::TT::::=o................
   r5      GG::::TT::::=o.........ommo...
   r6      ::::::::::::=o................
   r7      ::::::::::::=o................
   r8      ::::AA::AA::=o................
   r9      ::::::::::::=o.ommo...........
   r10     ::::::::::::=.................
   r11     :::::::::::::..........ommo...
   r12     :RRWWSS:::::..................
   r13     ##############################
```

| Simbol | Arti |
| --- | --- |
| `#` | Dinding gua |
| `:` | Tikar lapak |
| `G` | Gerobak (2x2) |
| `P` `C` `M` `K` | Peti bahan, meja potong, meja kerja, cobek |
| `T` | Tungku dengan kuali (2x2) |
| `R` `W` `S` | Rak piring, tempat cuci, tempat sampah |
| `A` | Meja Alas |
| `=` | Meja panjang (kursi di kolom 13) |
| `o` | Kursi monster |
| `mm` | Meja kecil dengan 2 kursi |
| `.` | Lantai dungeon. Kolom 12 pada r11 dan r12 adalah gerbang lapak (2 tile) |
| `D` | Terowongan masuk monster |

Stasiun lain (anglo, dandang, panci, Kendi, Cetakan Tumpeng, Peti Nasi, Peti Bumbu Kacang) dipasang di area tikar bebas lewat `LevelData` sesuai stage. Meja kecil **"dekat"** ada di kolom 15 sampai 18 (r3 dan r9), berjarak maksimal 7 tile dari tikar sehingga terjangkau lempar. Meja kecil **"jauh"** ada di kolom 23 sampai 26 (r5 dan r11) dan hanya terjangkau lewat gerbang.

### 9.3 Layout

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-LAY-01 | Level terdiri dari `LapakModule` (tikar, gerobak, titik pasang stasiun) dan sisi dungeon (`TileMapLayer`). `LevelData` menyebut modul lapak lalu menempatkan stasiun, meja, dan hazard | P0 |
| FR-LAY-02 | Gerobak selalu di tepi kiri sebagai prop statis. Kondisi visual (`_clean`, `_dusty`, `_loaded`) mengikuti progres peta | P0 |
| FR-LAY-03 | Level muat di 30x14 tile tanpa scroll. Lapak maksimal 12 tile lebar | P0 |
| FR-LAY-04 | Koki tidak bisa berjalan menembus meja panjang. Satu-satunya jalan ke sisi dungeon adalah gerbang. Item tetap bisa dilempar melintasi meja | P0 |
| FR-LAY-05 | Posisi stasiun bisa digeser per level. Stasiun yang belum dibuka di stage itu tidak dipasang | P0 |
| FR-LAY-06 | Placeholder: tikar krem polos, gerobak `box_brown` 24x32 berlabel, stasiun `box_brown` berlabel ID | P0 |

### 9.4 Kursi dan meja

| Entitas | Isi |
| --- | --- |
| `Seat` | `id`, `table_id`, posisi, arah hadap, `seat_type` (`BENCH`, `STOOL`, `MAT`), zona saji, status piring (`CLEAN`, `SERVED`, `DIRTY`), jangkar balon dan emoticon |
| `SeatingTable` | `kind` (`LONG`, `SMALL`, `ALTAR`) dan kumpulan kursi |
| `SeatingData` (di `LevelData`) | `long_seats`, `small_tables`, `max_active_monsters`, `max_open_tickets`, `long_table_bias`, `seat_patience_scale` |

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-SEAT-01 | Meja panjang di kolom 12, kursi di kolom 13, jarak antar kursi 18 px. `long_seats` 5 sampai 7 per level | P0 |
| FR-SEAT-02 | Meja kecil 2x1 tile dengan 2 kursi (kiri dan kanan). Jumlah dan posisi dari `LevelData`. Maksimal 2 dekat dan 2 jauh | P0 |
| FR-SEAT-03 | Spawner mengisi kursi bebas dengan RNG ber-seed. `long_table_bias` (nilai awal 0,6 di Stage 1, 0,5 di Stage 2, 0,4 di Stage 3 sampai 5) menentukan peluang meja panjang. **Porsi meja kecil minimal 40 persen** pada level yang punya meja kecil | P0 |
| FR-SEAT-04 | Goblin, Kadal, dan Hantu boleh di semua kursi. Ogre dan monster besar hanya di meja kecil (`allowed_seat_types`). Pose duduk monster kecil maksimal 18 px lebar | P0 |
| FR-SEAT-05 | Tiap monster memilih `sit_a` atau `sit_b` (RNG tampilan), posisi diacak ±2 px, dan fase animasi diacak | P0 |
| FR-SEAT-06 | Monster yang duduk tapi belum memesan berada di state `BROWSING` (emoticon menu, kesabaran belum berjalan). Pesanan diambil saat tiket terbuka di bawah `max_open_tickets` | P0 |
| FR-SEAT-07 | Piring kotor muncul per kursi 2 detik setelah monster di kursi itu pergi | P0 |
| FR-SEAT-08 | `seat_patience_scale` mengalikan waktu tunggu. Nilai awal 1,0 untuk meja panjang dan **0,85 untuk meja kecil**, sehingga meja yang jauh menuntut kecepatan | P0 |
| FR-SEAT-09 | Balon pesanan kursi meja panjang berjangkar di **sisi kanan** monster, supaya tidak menimpa tetangga yang berjarak 18 px. Jangkar disimpan per kursi di `SeatingData` | P0 |
| FR-SEAT-10 | Gambar monster diurutkan berdasarkan koordinat y agar tumpang tindih tetangga benar | P0 |

### 9.5 Parameter per level

| Level | Tiket terbuka | Monster aktif | Piring | Kursi panjang | Meja kecil (dekat / jauh) |
| --- | --- | --- | --- | --- | --- |
| 1-1 | 2 | 4 | 3 | 5 | 0 / 0 |
| 1-2 | 3 | 5 | 4 | 5 | 0 / 0 |
| 1-3 | 3 | 5 | 4 | 5 | 1 / 0 |
| 1-4 | 4 | 6 | 5 | 5 | 2 / 0 |
| 2-1 | 3 | 6 | 4 | 5 | 2 / 1 |
| 2-2 | 3 | 6 | 4 | 5 | 2 / 1 |
| 2-3 | 3 | 6 | 4 | 5 | 2 / 2 |
| 2-4 | 4 | 8 | 5 | 6 | 2 / 2 |
| 3-1 | 3 | 6 | 4 | 5 | 2 / 2 |
| 3-2 | 3 | 6 | 4 | 5 | 2 / 2 |
| 3-3 | 3 | 7 | 4 | 6 | 2 / 2 |
| 3-4 | 4 | 8 | 5 | 6 | 2 / 2 |
| 4-1 | 3 | 6 | 4 | 5 | 2 / 2 |
| 4-2 | 3 | 7 | 4 | 6 | 2 / 2 |
| 4-3 | 4 | 8 | 5 | 6 | 2 / 2 |
| 4-4 | 4 | 8 | 5 | 7 | 2 / 2 |
| 5-1 | 5 | 10 | 6 | 7 | 2 / 2 |
| 5-2 | 4 | 8 | 5 | 7 | 2 / 2 |
| 5-3 | Altar Sang Ageng |  |  |  |  |

"Tiket terbuka" sama dengan "maksimal sekaligus" di Dokumen Gambaran Game. Tutorial memakai orang-orangan sawah 1 sampai 2 sekaligus.

### 9.6 Menyajikan: samperin atau lempar

**Samperin** adalah cara aman. **Lempar** adalah jalan pintas untuk menghemat waktu berjalan ke meja yang jauh, dan sepenuhnya opsional. Lempar baru menguntungkan bila bidikannya hampir selalu berhasil, karena meleset berarti hidangan hancur dan harus dimasak ulang.

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-SRV-01 | **Samperin:** `interact` dengan hidangan di tangan. Dari kursi yang masuk probe (radius 14 px), simulasi memilih kursi yang **pesanannya cocok**. Bila ada: tersaji tanpa risiko. Bila tidak: ikon "bukan pesanan" dan tidak ada hukuman | P0 |
| FR-SRV-02 | Meja panjang dijangkau dari tikar: koki berdiri di kolom 11 dan `interact` ke kursi di kolom 13 (jarak 2 tile) | P0 |
| FR-SRV-03 | Meja kecil dekat berjarak 4 sampai 7 tile dari tikar dan bisa dilempari. Meja jauh hanya bisa dilempari dari sisi dungeon atau didatangi | P0 |
| FR-SRV-04 | Pukulan sutil dan kuali hanya mengenai monster `ENRAGED` atau `ATTACKING`. Monster duduk lain di dalam hitbox diabaikan | P0 |
| FR-SRV-05 | Koki boleh lewat gerbang ke sisi dungeon. Hazard stage membuat berjalan berisiko, jadi melempar lebih menarik | P0 |
| FR-SRV-06 | Altar Sang Ageng (3x3) adalah `SeatingTable` varian `ALTAR` untuk boss, dengan zona saji 3x3 tile | P0 |

**Aturan lempar:**

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-THR-01 | **Lempar cepat:** ketuk `throw` melempar **bahan** sejauh tetap 4 tile ke arah `Facing8` | P0 |
| FR-THR-02 | **Lempar bidik:** tahan `throw`, arahkan, lepas. Hidangan jadi hanya bisa dilempar dengan mode bidik | P0 |
| FR-THR-03 | Garis busur putus-putus dan penanda titik jatuh digambar lewat kode. Penanda dibedakan bentuk: lingkaran penuh (Jitu), setengah lingkaran (Tersaji), silang (Meleset). Tidak bergantung warna saja | P0 |
| FR-THR-04 | Jarak naik dari 2 sampai 8 tile dalam 1,2 detik lalu turun lagi. Arah dari stik (sudut bebas) atau 8 arah dari keyboard | P0 |
| FR-THR-05 | Koki berjalan 50 persen lebih lambat saat membidik dan tidak bisa memukul. Kuali dan sutil tidak bisa dilempar | P0 |
| FR-THR-06 | Waktu terbang 0,4 detik pada 2 tile sampai 0,9 detik pada 8 tile | P0 |
| FR-THR-07 | **Zona saji:** lingkaran radius 12 px di pusat tiap kursi (altar boss 3x3 tile) | P0 |
| FR-THR-08 | Hasil lemparan hidangan: **Jitu** (titik jatuh dalam 6 px dari pusat kursi yang pesanannya cocok: tersaji, +25, kepuasan +5). **Tersaji** (dalam 12 px dari kursi cocok: tersaji normal). **Meja salah** (dalam 12 px dari kursi berpesanan beda dan tidak ada kursi cocok di dalam 12 px: hidangan hilang, -50, kesabaran -10). **Meleset** (di lantai: hancur, -25, dan kesabaran -15 bagi monster kursi cocok terdekat dalam 40 px bila ada). **Mengenai monster** (mendarat di monster yang tidak duduk, misalnya antre atau mengamuk: hancur, -25, kesabaran -25) | P0 |
| FR-THR-09 | Tiga Jitu berturut-turut memberi +50 poin. Hasil selain Jitu mereset hitungan | P0 |
| FR-THR-10 | Bahan yang mendarat dalam 16 px dari rekan bertangan kosong ditangkap otomatis. Stasiun yang area terimanya terkena titik jatuh menerima bahan bila cocok. Bahan yang jatuh di lantai bisa dipungut | P0 |
| FR-THR-11 | Pengubah per stage lewat `HazardData`: Stage 3 menggeser titik jatuh dengan angin uap, Stage 5 menggetarkan penanda 0,3 detik tiap 20 detik | P0 |
| FR-THR-12 | **Bantuan bidik:** titik jatuh menempel ke kursi cocok terdekat dalam 20 px. **Default aktif untuk keyboard**, mati untuk gamepad, dan bisa diubah di pengaturan. Hasilnya dihitung Tersaji, kecuali titik **mentah** dalam 6 px yang tetap dihitung Jitu | P0 |
| FR-THR-13 | Cooldown lempar 0,3 detik. Piring dari hidangan yang hancur kembali ke rak setelah 10 detik | P0 |
| FR-THR-14 | Lemparan jarak di bawah 3 tile tidak mendapat bonus Jitu | P0 |
| FR-THR-15 | Hasil lemparan tampil sebagai `Label` melayang (kunci terjemahan). Item terbang memakai sprite item yang sama dengan item di dunia, ditambah bayangan lingkaran gelap yang digambar kode | P0 |
| FR-THR-16 | Target playtest: pemain baru menyajikan sekitar 70 persen lemparan, pemain mahir sekitar 90 persen. Bila lebih rendah, perbesar radius lewat data | P0 |

**Rumus bersama** (`sim/systems/throw_math.gd`, dipakai klien untuk pratinjau dan server untuk hasil):

```gdscript
const TILE := 16.0
const MIN_R := 2.0
const MAX_R := 8.0
const RAMP_TIME := 1.2          # detik dari 2 ke 8 tile
const SERVE_RADIUS := 12.0      # px dari pusat kursi
const JITU_RADIUS := 6.0
const ASSIST_RADIUS := 20.0

static func range_at(hold_time: float) -> float:
	var phase := fposmod(hold_time / RAMP_TIME, 2.0)
	var t := phase if phase <= 1.0 else 2.0 - phase   # gelombang segitiga 0..1
	return lerpf(MIN_R, MAX_R, t)

static func flight_time(r_tiles: float) -> float:
	return 0.4 + (r_tiles - MIN_R) / (MAX_R - MIN_R) * 0.5

static func landing_point(origin: Vector2, dir: Vector2, r_tiles: float, wind: Vector2) -> Vector2:
	return origin + dir.normalized() * r_tiles * TILE + wind
```

Tinggi busur hanya tampilan: `tinggi = r_tiles * 4.0` px, lintasan parabola `4 * s * (1 - s)` dengan `s` waktu terbang ternormalisasi.

## 10. Monster, Pesanan, dan Kerumunan

### 10.1 Monster dan pesanan

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-MON-01 | Spawner mengikuti jadwal wave `LevelData`. Jumlah tiket terbuka dibatasi `max_open_tickets` dan jumlah monster aktif `max_active_monsters` | P0 |
| FR-MON-02 | State: `ARRIVING`, `SEATED`, `BROWSING`, `WAITING`, `EATING`, `SATISFIED`, `LEAVING`. Cabang amarah: `ENRAGED`, `ATTACKING`, `EXPELLED`. Goblin punya cabang `STEAL_RUN` | P0 |
| FR-MON-03 | Kesabaran turun linear dari 100 ke 0 selama waktu tunggu x `seat_patience_scale`: Goblin 40 detik, Kadal 50, Ogre 60, Hantu 60. Level 5-1 memakai 120 persen | P0 |
| FR-MON-04 | Tahap 1 (di atas 50 persen): menggerutu. Tahap 2 (50 sampai 0): bonus cepat berhenti dan bahan terdekat bergeser. Tahap 3 (0): mengamuk | P0 |
| FR-MON-05 | Mengamuk menyerang selama 10 detik. Bila tidak diusir: Hati Dapur -1, stasiun terdekat `DISABLED` 8 detik, lalu monster pergi | P0 |
| FR-MON-06 | Kepuasan akhir = 40 + (sisa kesabaran x 0,4) + bonus sambal (25, 15, 5) + bonus Jitu (5), maksimal 100. Angka awal untuk disetel | P0 |
| FR-MON-07 | Tamu istimewa (penanda di wave) dengan kepuasan 80 atau lebih menjatuhkan Bahan Langka stage itu dan menyimpannya ke save | P0 |
| FR-MON-08 | Pesanan salah (hasil "Meja salah" di §9.6): -50 poin, kesabaran -10, hidangan hilang | P0 |
| FR-MON-09 | Kerupuk (kategori SNACK) yang dilempar ke monster menahan penurunan kesabaran 8 detik. Efek tambahan per monster di `MonsterData` | P0 |
| FR-MON-10 | Hantu: transparan dan tidak bisa dipukul sampai tahap 3. Di 4-3, hantu hanya terlihat dan memesan saat awan aroma wedang aktif (15 detik per seduhan) | P0 |
| FR-MON-11 | Pelanggan manusia (5-2) tidak menyerang. Jika kesabaran habis, mereka pergi dan Hati Dapur -1 | P0 |
| FR-MON-12 | `BROWSING`: monster sudah duduk tapi belum memesan. Emoticon `emote_menu`, kesabaran belum berjalan. Mendapat tiket saat tiket terbuka kurang dari `max_open_tickets` | P0 |
| FR-MON-13 | **Goblin `STEAL_RUN`:** di tahap 3 (bukan tahap 2) Goblin berdiri lalu mengambil satu item terdekat di permukaan atau lantai (bukan yang dipegang koki), lalu berlari 3 tile per detik ke terowongan `D`. Item hilang dan Hati Dapur -1 bila Goblin sampai. Ia bisa dihentikan dengan pukulan sutil, Dash, atau **kerupuk yang dilempar mendarat dalam 24 px** (Goblin berhenti makan 2 detik, item jatuh di tempat) | P0 |
| FR-MON-14 | Ogre dan monster besar hanya duduk di meja kecil (`allowed_seat_types`) | P0 |
| FR-MON-15 | Serangan lain: Kadal `TAIL_SWEEP` (telegraf garis 1,5 detik, koki terpental dan menjatuhkan item). Ogre `SHOCKWAVE` (hentakan, item di sekitar terlempar). Hantu menyentuh dan membekukan stasiun terdekat 5 detik. Pola dibaca dari `MonsterData.attack_pattern` | P0 |

### 10.2 Kerumunan (hanya tampilan)

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-CRD-01 | `CrowdController` di `view/` menampilkan monster latar (antre di terowongan, berjalan lewat, berkumpul). Mereka **bukan entitas `sim/`**: tidak punya state, tabrakan, atau pesanan | P0 |
| FR-CRD-02 | Monster latar memakai sprite dan tag yang sama dengan monster sim (`walk`, `sit_a`, `eat`) dan bereaksi lewat emoticon pada event (tamu istimewa puas, tetangga mengamuk) | P0 |
| FR-CRD-03 | Kepadatan diatur di `Settings`: mati, rendah, normal. Batas jumlah ditentukan performa web | P0 |
| FR-CRD-04 | Kerumunan memakai RNG tampilan dan tidak dikirim lewat jaringan. Server tidak menjalankannya | P0 |

## 11. Pertarungan, Skill, dan Combo

### 11.1 Sutil dan Kuali Dua Mode

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-CMB-01 | **Sutil:** hitbox 1,2 tile, aktif 0,12 detik, cooldown 0,4 detik. Tiga pukulan mengusir monster mengamuk. Bisa mendorong monster kecil | P0 |
| FR-CMB-02 | **Kuali:** saat diangkat dari tungku menjadi item `COOKWARE`. Pukulan kuali hitbox 1,6 tile, cooldown 0,8 detik, satu pukulan mengusir. Tungku menjadi `NO_COOKWARE` | P0 |
| FR-CMB-03 | **Aturan tumpah:** jika kuali berisi apa pun dipakai memukul, isinya hilang, muncul noda tumpah, dan -25 poin | P0 |
| FR-CMB-04 | Setelah dipakai memukul, kuali `COOKWARE_LOCKED` selama 4 detik | P0 |
| FR-CMB-05 | Ikon peringatan di atas kuali berisi saat koki mengangkatnya dan monster ada dalam jarak 3 tile | P1 |
| FR-CMB-06 | Hit-stop 60 ms dan guncangan kamera kecil saat mengenai. Guncangan bisa dimatikan di pengaturan | P1 |
| FR-CMB-07 | Monster yang diusir terpental, pergi, dan tidak memberi drop | P0 |
| FR-CMB-08 | `strike` punya prioritas atas `work`. Memukul menghentikan pekerjaan yang sedang ditahan | P0 |

### 11.2 Skill dan combo

Tiap koki punya dua skill. `skill_1` dan `skill_2` adalah aksi terpisah.

| Koki | skill\_1 | skill\_2 |
| --- | --- | --- |
| Rangga | Dash | Buff Kecepatan |
| Sekar | Teleport | Buff Api |

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-SKL-01 | **Dash:** 4 tile dalam 0,15 detik, cooldown 6 detik, arah `Facing8`. Mendorong monster kecil. Item di tangan tidak jatuh | P0 |
| FR-SKL-02 | **Buff Kecepatan:** kecepatan kedua koki +40 persen selama 5 detik, cooldown 15 detik. Memperpendek ramp bidik 20 persen | P0 |
| FR-SKL-03 | **Teleport:** tahan `skill_1` 0,5 detik untuk memasang penanda (maksimal 2, penanda ketiga menggantikan yang tertua). Ketuk untuk berpindah ke penanda terbaru. Ketuk dua kali dalam 0,3 detik untuk bertukar tempat dengan rekan. Cooldown 8 detik | P0 |
| FR-SKL-04 | **Buff Api:** stasiun masak di depan koki bekerja 2x lebih cepat selama 8 detik, cooldown 20 detik. Laju gosong tidak ikut dipercepat | P0 |
| FR-SKL-05 | **Combo:** dua skill pasangan yang diaktifkan dalam 3 detik membentuk combo. Cooldown combo 30 detik, +50 poin | P0 |
| FR-SKL-06 | **Antar Kilat:** Dash membawa piring lalu Teleport ke penanda di dekat kursi. Hidangan langsung tersaji ke kursi cocok terdekat | P0 |
| FR-SKL-07 | **Dapur Membara:** Buff Kecepatan dan Buff Api bersamaan. Satu masakan di stasiun target selesai seketika | P0 |
| FR-SKL-08 | **Tendangan Kuali:** Teleport tukar tempat ke dekat monster mengamuk lalu Dash. Monster terpental jauh dan pergi tanpa memakai kuali | P0 |
| FR-SKL-09 | Skill dibuka bertahap lewat `LevelData.skills_unlocked`: Dash 1-3, Teleport 2-1, Antar Kilat 2-2, Buff Kecepatan 2-3, Buff Api 3-1, Dapur Membara 3-2, Tendangan Kuali 3-3 | P0 |
| FR-SKL-10 | Mode 1 pemain: skill dimiliki koki yang dikendalikan. Cooldown berjalan terpisah per koki | P0 |

## 12. Skor, Hazard, Boss, dan Telegraf

### 12.1 Skor dan Hati Dapur

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-SCR-01 | Poin: pesanan benar +100, bonus cepat +50 (disajikan sebelum tahap 2), combo +50, Jitu +25, tiga Jitu beruntun +50, pesanan salah -50, masakan gosong, tumpah, atau hancur -25 | P0 |
| FR-SCR-02 | Bintang dari tiga batas di `LevelData`. Satu bintang membuka level berikutnya | P0 |
| FR-SCR-03 | Tim punya 5 Hati Dapur. Level gagal bila hati habis atau skor akhir di bawah batas bintang 1 | P0 |
| FR-SCR-04 | Level 5-3: 1 bintang bila selesai, 2 bila sisa 3 hati atau lebih, 3 bila sisa 4 hati atau lebih dan kepuasan Naga di atas 80 | P0 |
| FR-SCR-05 | Layar hasil menampilkan skor, bintang, rincian bonus, dan Bahan Langka. Skor terbaik disimpan per level | P0 |

### 12.2 Hazard

Hazard diimplementasikan sebagai node `HazardController` dari `HazardData`, bukan kode khusus per level.

| Hazard | Parameter awal | Efek | Level |
| --- | --- | --- | --- |
| `MUSHROOM_SPORES` | Tiap 25 detik | Spora menutupi sebagian layar 1 detik | 1-3, 1-4 |
| `TIDE` | Periode 20 detik | Air naik, item di papan rendah hanyut | 2-1 sampai 2-4 |
| `TAIL_SWEEP` | Telegraf 1,5 detik | Sapuan ekor | 2-3, 2-4 |
| `LAVA` | Periode 15 detik, 3 tile | Koki terpental ke titik awal dan menjatuhkan item | 3-1 sampai 3-4 |
| `HOT_STOVE` | Kecepatan +30 persen | Waktu gosong x 0,7 | 3-1 |
| `SHOCKWAVE` | Dipicu serangan Ogre | Item di sekitar terlempar | 3-3, 3-4 |
| `EXPLOSION` | Tiap 45 detik | Layar bergetar, item bergeser 1 tile | 3-4 |
| `STEAM_WIND` | Tiap 10 detik | Titik jatuh lempar bergeser, panah uap terlihat | Stage 3 |
| `ICE_FLOOR` | Percepatan 0,35 detik | Gerak licin. Item beku butuh 3 detik di tungku | 4-1 sampai 4-4 |
| `BLACKOUT` | Tiap 30 detik selama 8 detik | Hanya lingkaran 3 tile di sekitar koki dan stasiun yang menyala. Garis bidik tetap bersinar | 4-2 sampai 4-4 |
| `AROMA` | 15 detik per seduhan | Hantu terlihat dan memesan hanya saat aroma aktif | 4-3, 4-4 |
| `HEARTBEAT` | Tiap 20 detik | Item bergeser 1 tile, penanda bidik bergetar 0,3 detik | 5-1 |
| `DRAGON_BREATH` | Tiap 30 detik | Api kecil ke satu sudut dengan telegraf 1,5 detik | 5-2 |

### 12.3 Boss: Sang Ageng

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-BOS-01 | Tiga fase berurutan. Fase berganti saat hidangan fase itu tersaji. Hati Dapur tidak pulih antar fase | P0 |
| FR-BOS-02 | Fase 1 (sup pembuka): tiap 30 detik Naga meniup api ke satu sudut acak dengan telegraf 1,5 detik | P0 |
| FR-BOS-03 | Fase 2 (sate dan rendang kilat): sapuan ekor tiap 30 detik dengan telegraf garis. Bisa dihindari dengan Dash atau berpindah | P0 |
| FR-BOS-04 | Fase 3 (tumpeng): napas api menyapu satu baris lantai tiap 20 detik dengan telegraf 2 detik. Perakitan tumpeng dilakukan di sela serangan | P0 |
| FR-BOS-05 | Meter kepuasan Naga mulai 60, turun 0,5 per detik, naik +30 tiap hidangan tersaji (+5 bila Jitu). Level gagal bila habis | P0 |
| FR-BOS-06 | Altar persembahan 3x3 tile sebagai zona saji. Naga tidak bisa dibunuh | P0 |

### 12.4 Telegraf

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-TEL-01 | Telegraf (garis sapuan, lingkaran api, baris napas) **digambar lewat kode** dari data serangan, jadi berfungsi tanpa aset | P0 |
| FR-TEL-02 | Telegraf dibedakan oleh **pola dan bentuk**, bukan hanya warna: garis putus-putus untuk sapuan, lingkaran bergaris untuk api, pita bergaris untuk napas | P0 |
| FR-TEL-03 | Durasi telegraf tertulis di `AttackData` dan tidak boleh kurang dari 1,0 detik pada level normal | P0 |
| FR-TEL-04 | Opsi kurangi gerak: guncangan layar dan kedipan dimatikan, telegraf tetap tampil | P1 |

## 13. Animasi Universal dan Emoticon

Banyak aksi tidak punya animasi sendiri. Koki hanya punya satu animasi kerja `work`, dan jenis pekerjaannya ditunjukkan oleh **emoticon**. Item yang dibawa digambar sebagai sprite terpisah di atas kepala, sehingga tidak ada animasi membawa.

### 13.1 Tag animasi minimum

| Prefix | Tag | Arah | Frame | fps | Catatan |
| --- | --- | --- | --- | --- | --- |
| `cook` | `idle` | `down`, `up`, `side` | 2 | 4 |  |
| `cook` | `walk` | `down`, `up`, `side` | 6 | 10 | Dipakai juga saat membawa item |
| `cook` | `work` | `down`, `up`, `side` | 3 | 8 | Satu animasi untuk potong, campur, ulek, aduk, cuci |
| `cook` | `strike` | `down`, `up`, `side` | 4 | 14 | Sekali |
| `cook` | `throw` | `down`, `up`, `side` | 3 | 12 | Membidik (frame 1 ditahan) dan melempar |
| `cook` | `knocked` | tanpa arah | 2 | 8 | Terpental |
| `cook_rangga` | `dash` | `down`, `up`, `side` | 3 | 12 | Sekali |
| `cook_sekar` | `teleport_out`, `teleport_in` | tanpa arah | 4 | 12 | Sekali |
| `mon` | `walk` | `down`, `up`, `side` | 4 | 8 |  |
| `mon` | `sit_a`, `sit_b` | tanpa arah | 2 | 3 | Dua pose duduk bervariasi |
| `mon` | `eat` | tanpa arah | 3 | 6 |  |
| `mon` | `rage` | tanpa arah | 2 | 8 | Dipakai juga oleh Goblin saat berdiri mencuri |
| `mon` | `expelled` | tanpa arah | 3 | 10 | Sekali |
| `mon_ageng` | `idle`, `breathe`, `sweep`, `satisfied`, `angry` | tanpa arah | 2 sampai 4 | 4 sampai 10 | Bagian naga (kepala, badan, ekor) terpisah |
| `station` | `empty`, `working`, `done`, `burning`, `burnt`, `disabled`, `frozen` | tanpa arah | 1 sampai 4 | 4 sampai 8 | Tungku juga punya `no_cookware` |
| `vfx`, `emote`, `tile` hazard | `loop` atau `play` | tanpa arah | 3 sampai 6 | 6 sampai 12 | Satu file per ID bila hanya satu animasi |

Tanpa tag `carry_*`, `run`, `catch`, `arrive`, `leave`, `wait`, atau `grumble`. Tampilan menggantinya dengan `walk`, `idle`, `sit_*`, dan emoticon.

### 13.2 Emoticon

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-EMO-01 | Ada **19 emoticon** 16x16 px (1 sampai 4 frame, loop). Koki (9): `emote_chop`, `emote_mix`, `emote_pound`, `emote_stir`, `emote_wash`, `emote_burn`, `emote_panic`, `emote_cheer`, `emote_no`. Monster (10): `emote_menu`, `emote_hungry`, `emote_grumble`, `emote_rage`, `emote_yum`, `emote_happy`, `emote_scared`, `emote_chat`, `emote_music`, `emote_envy` | P0 |
| FR-EMO-02 | `EmoteMapData` memetakan event `sim/` ke emoticon: `work` pada meja potong menjadi `emote_chop`, state `NEEDS_ATTENTION` menjadi `emote_stir`, tahap kesabaran 1 sampai 3 menjadi `emote_hungry`, `emote_grumble`, `emote_rage`, dan seterusnya | P0 |
| FR-EMO-03 | Satu entitas menampilkan satu emoticon sekaligus. Emoticon kegiatan koki tampil selama `work` ditahan dan 0,3 detik sesudahnya. Emoticon monster mengikuti tahap kesabaran | P0 |
| FR-EMO-04 | Jangkar emoticon di kanan-atas kepala. Untuk kursi meja panjang, balon pesanan di sisi kanan dan emoticon di atas kepala, dengan jangkar per kursi di `SeatingData` | P0 |
| FR-EMO-05 | Emoticon digambar di atas entitas tetangga (lapis tampilan tersendiri). Emoticon tidak menghalangi balon pesanan | P0 |
| FR-EMO-06 | Emoticon murni tampilan. Server tidak mengirim emoticon, klien menurunkannya dari state dan event | P0 |

## 14. UI dan HUD

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-UI-01 | HUD atas 30 px: sampai 6 tiket (40x26 px, ikon hidangan 24x24 px) di kiri, skor dan timer di kanan. Tiket menampilkan bar waktu | P0 |
| FR-UI-02 | HUD bawah 16 px: 5 ikon Hati Dapur (12x12), ikon `skill_1` dan `skill_2` tiap koki (16x16) dengan cooldown yang digambar kode, indikator combo | P0 |
| FR-UI-03 | Balon pesanan di atas monster (ikon 24x24) dengan bar kesabaran 16x3 px. Bar berwarna hijau, kuning, merah **dan** selalu disertai emoticon tahap | P0 |
| FR-UI-04 | Indikator bidik: bar jarak kecil dekat koki saat `throw` ditahan | P0 |
| FR-UI-05 | Teks memakai `Label` dan font pixel 8 px (teks) dan 16 px (judul). Tidak ada teks di dalam sprite | P0 |
| FR-UI-06 | Layar: menu utama, menu Latihan, peta, jeda, hasil, pengaturan (volume, bahasa, bantuan bidik, jendela aduk, kepadatan kerumunan, kurangi gerak, remap tombol) | P0 |
| FR-UI-07 | Elemen UI memakai ID aset (`ui_*`). `ui_*` nine-patch menyimpan margin di manifest. Tanpa aset final, UI memakai kotak `box_green` berlabel | P0 |
| FR-UI-08 | `ui/theme.tres` menjadi satu-satunya tempat gaya dasar (font, warna, nine-patch) | P0 |

## 15. Tutorial

Lima level latihan (T-1 sampai T-5) berlangsung di halaman rumah Mbok Laras. Pelanggannya orang-orangan sawah (`mon_scarecrow`). **Tutorial tidak ada di peta dunia**: ia berjalan otomatis sekali pada permainan pertama, lalu bisa diulang dari menu **Latihan**.

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-TUT-01 | `TutorialRunner` membaca `TutorialData`: tiap langkah punya id, kunci teks, target sorotan (grup node), pemicu mulai, syarat selesai (hitungan event), dan input yang diblokir | P0 |
| FR-TUT-02 | Syarat selesai: T-1 tiga hidangan tersaji (samperin). T-2 tiga nasi goreng jamur tersaji, termasuk satu gosong sengaja. T-3 lima bahan terlempar ke stasiun. T-4 lima lemparan tersaji dengan minimal 2 Jitu. T-5 tiga monster diusir dengan sutil, satu dengan kuali kosong, satu kerupuk terlempar, satu tumpah disengaja | P0 |
| FR-TUT-03 | Level tutorial tanpa timer, Hati Dapur, atau bintang (flag di `LevelData`) | P0 |
| FR-TUT-04 | Tutorial wajib sekali di pemakaian pertama. Tombol **Lewati Tutorial** (dengan konfirmasi). Menu **Latihan** mengulang tiap level T | P0 |
| FR-TUT-05 | Dalam co-op, syarat selesai dihitung gabungan kedua pemain | P0 |
| FR-TUT-06 | Ikon tombol pada petunjuk menyesuaikan perangkat aktif | P0 |
| FR-TUT-07 | Pop-up Kuali Dua Mode muncul sekali di T-5 dan sekali di 1-3. Pop-up cuci piring muncul sekali di 1-2 | P0 |
| FR-TUT-08 | Setelah 3 kali meleset beruntun di T-4, radius zona saji latihan membesar 25 persen | P1 |
| FR-TUT-09 | Tutorial memakai `LapakModule` variasi halaman dan tema tile `halaman`. T-4 punya tiga meja: dekat, 6 petak, dan seberang sungai kecil | P0 |
| FR-TUT-10 | Skill tidak diajarkan di tutorial. Skill dibuka bertahap mulai level 1-3 | P0 |

## 16. Peta Dunia dan Alur Level

Peta dunia berupa penampang vertikal dungeon dengan **5 lapisan** (satu lapisan per stage). Gerobak kecil berjalan menuruni rel dari node ke node.

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-MAP-01 | Peta 480x270 px: header 20 px (nama stage) dan 5 lapisan setinggi 50 px (`map_layer_1` sampai `map_layer_5`). Tutorial tidak ada di peta | P0 |
| FR-MAP-02 | 19 node level (4, 4, 4, 4, 3 per lapisan). Posisi node, jalur rel (`Path2D`), dan urutan buka di `WorldMapData` | P0 |
| FR-MAP-03 | Node punya tiga keadaan: terkunci, terbuka, selesai (1 sampai 3 bintang). Tiap stage menampilkan ikon Bahan Langka yang sudah didapat | P0 |
| FR-MAP-04 | Gerobak (`cart_map_<kondisi>`) bergerak sepanjang `Path2D` dari node saat ini ke node tujuan selama 1,5 sampai 3 detik. Level dimuat di balik animasi itu. Pemain bisa melewatinya dengan menahan `interact`, dan tombol **Ulang** di layar hasil langsung memuat level tanpa animasi | P0 |
| FR-MAP-05 | Kondisi gerobak (`_clean`, `_dusty`, `_loaded`) mengikuti progres stage | P0 |
| FR-MAP-06 | Layar hasil menyediakan tombol Lanjut, Peta, dan Ulang | P0 |
| FR-MAP-07 | Peta memakai placeholder `box_green` berlabel `map_layer_N`, node berupa lingkaran berlabel `1-1` dan seterusnya | P0 |
| FR-MAP-08 | Gerak gerobak tidak memengaruhi simulasi. Kemajuan peta hanya diperbarui oleh hasil level lewat `Save` | P0 |

## 17. Penyimpanan dan Progres

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-SAV-01 | Progres di `user://save.json` dengan nomor versi skema. Penulisan atomik: tulis ke file sementara lalu ganti | P0 |
| FR-SAV-02 | Data: bintang dan skor terbaik per level, Bahan Langka, halaman Buku Resep, kostum, flag tutorial, kemajuan peta, pengaturan, opsi aksesibilitas | P0 |
| FR-SAV-03 | Web: `user://` tersimpan di IndexedDB dan bisa hilang bila pemain menghapus data situs. Tampilkan peringatan dan sediakan **ekspor dan impor kode save** | P1 |
| FR-SAV-04 | Migrasi otomatis antar versi skema | P0 |
| FR-SAV-05 | Satu profil per perangkat untuk Rilis 1.0 | P0 |
| FR-SAV-06 | Cloud save opsional via AWS | P2 |

## 18. Jaringan dan Online (Fase 2)

### 18.1 Arsitektur

```
Pemain (Windows atau browser di itch.io)
   |  HTTPS: login tamu, buat atau gabung ruangan      |  WSS: gameplay
   v                                                   v
API Gateway (HTTP API)                          ALB (TLS, aturan host per shard)
   |                                                   |
Lambda --- DynamoDB (Rooms, Shards, Guests)            v
   |  memilih shard                         ECS Fargate: shard s1, s2, ...
   +--------------------------------------> (Godot headless, banyak ruangan per proses)
                                                       |  heartbeat tiap 10 detik
                                                       v
                                          CloudWatch (log, metrik, alarm)
```

| Komponen | Tugas |
| --- | --- |
| Klien Godot | Mengirim input, menampilkan state, memprediksi gerak koki sendiri |
| Lobby API | Login tamu, buat dan gabung ruangan, memilih shard |
| Shard server | Satu task Fargate yang menjalankan Godot headless dan menampung banyak ruangan |
| DynamoDB | Daftar ruangan, status shard, profil tamu |

### 18.2 Otoritas dan sinkronisasi

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-NET-01 | Server otoritatif. Klien hanya mengirim **input**. Server menjalankan simulasi dan mengirim **snapshot** | P2 |
| FR-NET-02 | Input dikirim 30 kali per detik dengan nomor urut. Snapshot dikirim 20 kali per detik | P2 |
| FR-NET-03 | Klien memprediksi gerak koki miliknya dan merekonsiliasi dengan snapshot. Entitas lain diinterpolasi dengan buffer 100 ms | P2 |
| FR-NET-04 | Hasil lemparan, pukulan, skor, dan drop ditentukan server. Klien hanya menampilkan pratinjau bidik dengan `throw_math.gd` yang sama | P2 |
| FR-NET-05 | WebSocket berbasis TCP, jadi semua pesan efektif reliable dan berurutan. Mitigasi antrean: snapshot bernomor urut, klien membuang snapshot lama, server melewati snapshot bila buffer kirim penuh | P2 |
| FR-NET-06 | Snapshot dan event berformat biner (`PackedByteArray`) dengan posisi dikuantisasi (fixed-point 1/8 px). Target ukuran snapshot di bawah 400 byte | P2 |
| FR-NET-07 | Tidak memakai `MultiplayerSynchronizer` untuk gameplay. Serialisasi manual agar ukuran paket kecil dan kontrol per ruangan penuh | P2 |
| FR-NET-08 | Snapshot memuat koki, item, stasiun (state, progres, flag), kursi dan piring, monster (state, kesabaran), proyektil lempar, fase hazard, skor, dan Hati Dapur. **Kerumunan dan emoticon tidak dikirim** | P2 |

| Arah | Pesan |
| --- | --- |
| Klien ke server | AUTH, READY, INPUT, PING, LEAVE |
| Server ke klien | AUTH\_OK, ROOM\_STATE, START, SNAPSHOT, EVENT, RESULT, PONG, KICK |

### 18.3 Ruangan dan kapasitas

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-ROM-01 | Siklus: LOBBY, LOADING, PLAYING, RESULTS, CLOSED. Maksimal 2 pemain | P2 |
| FR-ROM-02 | Kode ruangan 6 karakter huruf besar dan angka tanpa karakter yang membingungkan (tanpa O, 0, I, 1). Dua karakter pertama menandai shard | P2 |
| FR-ROM-03 | Jendela sambung ulang 30 detik. Selama itu koki diam dan permainan dijeda setelah 10 detik | P2 |
| FR-ROM-04 | Ruangan kosong ditutup setelah 60 detik. Pemain tidak aktif 120 detik dikeluarkan | P2 |
| FR-ROM-05 | Versi build klien harus sama dengan server. Jika tidak, tampilkan "perlu memperbarui game" | P2 |
| FR-ROM-06 | Satu proses menampung banyak objek `Room` yang terisolasi. **Hipotesis awal:** 20 ruangan per task 1 vCPU dengan anggaran 0,4 ms per ruangan per tick. Wajib dibuktikan lewat uji beban | P2 |
| FR-ROM-07 | **Shard** adalah satu service ECS berisi satu task. Lobby API memilih shard aktif dengan muatan terendah. Tiap shard punya nama host sendiri lewat aturan host di ALB | P2 |

### 18.4 Lobby API, autentikasi, dan data

| Endpoint | Fungsi |
| --- | --- |
| `POST /v1/auth/guest` | Menukar `guest_id` dengan JWT (berlaku 24 jam) |
| `POST /v1/rooms` | Membuat ruangan. Mengembalikan `room_code`, `ws_url`, `ticket` |
| `POST /v1/rooms/{code}/join` | Bergabung. Mengembalikan `ws_url` dan `ticket` |
| `GET /v1/health` | Pemeriksaan kesehatan |

- Throttling API Gateway: awal 10 permintaan per menit per IP untuk pembuatan ruangan.
- CORS: izinkan origin tempat itch.io menyajikan game web (domain `itch.zone`). **Verifikasi di staging.**
- **Login tamu:** klien membuat `guest_id` (UUID v4) sekali, menyimpannya di save, menukarnya dengan JWT.
- **Ticket:** JWT pendek (60 detik) berisi `room_code`, `shard_id`, slot pemain. Server memverifikasinya pada pesan AUTH pertama dalam 5 detik, bukan di URL agar tidak masuk log. Kunci (HS256) di Secrets Manager.
- Server memvalidasi semua input (rentang, laju, kepemilikan item, bisa tidaknya dilempar). Skor online dihitung server. Pesan maksimal 1 KB, batas 90 pesan per detik per koneksi.

| Tabel DynamoDB (on-demand) | Kunci | Atribut utama |
| --- | --- | --- |
| `Rooms` | PK `room_code` | `shard_id`, `status`, `players`, `build_version`, `created_at`, `ttl` |
| `Shards` | PK `shard_id` | `status` (active, draining, offline), `host`, `rooms`, `players`, `capacity`, `updated_at`, `ttl` 30 detik |
| `Guests` | PK `guest_id` | `created_at`, `last_seen`, referensi cloud save (Fase 3) |

## 19. Infrastruktur AWS

| Layanan | Fungsi | Catatan |
| --- | --- | --- |
| Route 53 dan ACM | Domain dan sertifikat wildcard | Wajib untuk `wss://` |
| Application Load Balancer | TLS, WebSocket, aturan host per shard | Idle timeout di atas interval ping (klien ping tiap 20 detik) |
| ECS Fargate | Server Godot headless, satu service per shard | Awal 1 vCPU dan 2 GB (hipotesis) |
| ECR | Image server | Dipush CI |
| API Gateway dan Lambda | Lobby API | Node.js atau Python |
| DynamoDB | Ruangan, shard, tamu | On-demand |
| Secrets Manager | Kunci JWT | Tidak ada kredensial AWS di klien |
| CloudWatch | Log (JSON), metrik, alarm, dasbor |  |
| AWS Budgets | Alarm biaya 50, 80, 100 persen | Wajib sejak hari pertama |
| WAF | Perlindungan tambahan | P2 |

AWS Shield Standard sudah aktif otomatis untuk semua pelanggan.

- VPC 2 AZ, ALB di subnet publik. **Keputusan terbuka:** task di subnet publik dengan security group hanya dari ALB (hemat NAT) atau subnet privat dengan NAT atau VPC endpoint (lebih aman, lebih mahal).
- Lingkungan: **dev, staging, prod** sebagai stack CDK terpisah. Akun AWS terpisah per lingkungan disarankan (P1).
- Health check: Godot headless tidak melayani HTTP biasa di port WebSocket, jadi sediakan `GET /health` di port 8081 lewat `TCPServer` kecil.
- Deploy tanpa memutus pemain: shard ke `draining`, tunggu ruangan habis (maksimal 15 menit), lalu ganti task.
- Metrik wajib: `rooms_active`, `players_online`, `tick_ms_p95`, `rtt_ms_p50` dan `p95`, `disconnect_rate`, `error_rate`. Alarm bila `tick_ms_p95` melewati anggaran atau heartbeat hilang.
- Biaya: shard minimum 1 di luar jam ramai, evaluasi autoscaling setelah ada data.

## 20. Build, Rilis, dan itch.io

### 20.1 Preset ekspor

| Preset | Pengaturan penting | Hasil |
| --- | --- | --- |
| Windows 64-bit | x86\_64, PCK ditanam di .exe, ikon dan info versi | Zip berisi .exe |
| Web | Renderer Compatibility, `variant/thread_support=false`, Extensions Support mati, shell HTML kustom (kanvas pas layar, layar muat, gerbang "Klik untuk mulai") | Folder dengan `index.html` di level teratas, di-zip |
| Linux server | Export Mode **dedicated server** (aset visual dibuang, feature tag `dedicated_server`) | Binary untuk image Docker |

Sebelum ekspor mana pun, CI menjalankan `sync_assets` supaya `index.json` mutakhir.

### 20.2 Persyaratan khusus web

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-WEB-01 | Gerbang "Klik untuk mulai" sebelum audio diputar (browser memblokir audio otomatis) | P0 |
| FR-WEB-02 | Tombol layar penuh via API fullscreen. Layar "klik untuk fokus" agar Spasi dan panah tidak menggulir halaman | P0 |
| FR-WEB-03 | Tidak memakai fitur yang tak ada di web: TCP/UDP mentah, ENet, `OS.execute`, GDExtension native | P0 |
| FR-WEB-04 | Audio dalam Ogg Vorbis. Jumlah file total di bawah 1.000 | P0 |
| FR-WEB-05 | Target internal ukuran build web 100 MB atau kurang. Ukur sejak M0 | P0 |
| FR-WEB-06 | Perangkat seluler tidak didukung. Tampilkan pesan jelas | P1 |
| FR-WEB-07 | Uji di halaman itch.io yang sudah terbit, minimal Chrome, Firefox, Edge, Safari desktop | P0 |

### 20.3 Alur rilis ke itch.io

1. Buat halaman proyek. Build web diset **HTML** (dimainkan di browser), build Windows file unduhan.
2. Dorong lewat **butler** ke channel terpisah (`windows`, `web`) dengan nomor versi.
3. Ukuran tampilan web kelipatan viewport dasar, awal 960x540 dengan tombol layar penuh.
4. Untuk uji, halaman diset **Restricted** dengan kata sandi atau draf.
5. Versi `major.minor.patch+build`, tampil di menu utama dan dicek server online.

### 20.4 Pipeline CI/CD (GitHub Actions)

| Tahap | Isi |
| --- | --- |
| 1. Lint | `gdlint` dan `gdformat --check` (gdtoolkit) |
| 2. Aset | `sync_assets` dan `asset_audit`. **Gagal bila ada `INVALID`.** Build rilis (`--release`) juga gagal bila ada ID milestone M4 atau lebih awal yang masih `box_*` |
| 3. Tes | Unit test dan tes simulasi headless (GUT atau gdUnit4) |
| 4. Export | Image Docker dengan Godot dan export template versi terkunci. Export Windows, Web, server |
| 5. Staging | Build web ke halaman itch.io terbatas. Fase 2: image server ke ECR dan deploy CDK |
| 6. Smoke test | Muat game dan buat ruangan (Fase 2) |
| 7. Produksi | Persetujuan manual, `butler push`. Fase 2: deploy shard dengan draining |

## 21. Persyaratan Non-Fungsional

| ID | Persyaratan | Target | Prio |
| --- | --- | --- | --- |
| NFR-PRF-01 | Frame rate desktop | 60 FPS di GPU terintegrasi, 1080p | P0 |
| NFR-PRF-02 | Frame rate web | 60 FPS di Chrome dan Firefox, laptop kelas menengah | P0 |
| NFR-PRF-03 | Memori web | 512 MB atau kurang | P0 |
| NFR-PRF-04 | Waktu muat | Web 15 detik atau kurang (20 Mbps). Desktop 5 detik ke menu | P0 |
| NFR-PRF-05 | Latensi input lokal | 3 frame (50 ms) atau kurang | P0 |
| NFR-PRF-06 | Anggaran tick server | 0,4 ms per ruangan per tick (hipotesis, diuji di M5) | P2 |
| NFR-CMP-01 | Kompatibilitas | Windows 10 dan 11 (64-bit), GPU OpenGL 3.3. Browser desktop modern dengan WebGL 2 | P0 |
| NFR-ACC-01 | Aksesibilitas | Remap tombol, Bantuan bidik, Tekan untuk bekerja, jendela aduk lebar, kurangi gerak, ukuran teks, kontras tinggi | P0 |
| NFR-ACC-02 | Penanda bidik dan telegraf tidak bergantung warna saja | Bentuk dan pola berbeda | P0 |
| NFR-ACC-03 | Suara penting (amarah, peringatan serangan) punya isyarat visual setara |  | P0 |
| NFR-LOC-01 | Semua teks lewat kunci terjemahan. Indonesia default, Inggris menyusul. Font pixel mendukung karakter Latin |  | P0 |
| NFR-SEC-01 | Hanya HTTPS dan WSS. Tidak ada rahasia atau kredensial AWS di klien |  | P2 |
| NFR-PRV-01 | Tidak mengumpulkan data pribadi. ID tamu acak. Telemetri hanya dengan persetujuan. Siapkan kebijakan privasi sederhana (sebaiknya ditinjau ahli hukum sehubungan UU Pelindungan Data Pribadi) |  | P0 |
| NFR-REL-01 | Crash tidak merusak save. Task server yang mati dijalankan ulang ECS |  | P0 |

## 22. Strategi Pengujian

| Lapisan | Isi |
| --- | --- |
| Unit test | Rumus lempar, skor, kesabaran, kuali tumpah, validasi resep, pool piring (jumlah piring selalu konstan), migrasi save |
| Tes simulasi headless | Replay rekaman input pada level tertentu, bandingkan skor dan state akhir (determinisme) |
| Tes kesetaraan lempar | Pratinjau klien dan hasil simulasi identik untuk ribuan kombinasi arah dan jarak |
| Tes aset | `sync_assets` pada folder uji berisi nama benar, nama salah, ukuran salah, dan file hilang. Placeholder harus muncul tanpa crash. `anim_gallery` memutar semua ID |
| Tes level | Bot sederhana memastikan tiap level bisa diselesaikan |
| Uji jaringan (Fase 2) | Bot klien headless, 20 ruangan paralel, latensi 50, 150, 300 ms dengan jitter, putus-sambung, deploy dengan draining |
| Matriks perangkat | Laptop spesifikasi rendah dan tinggi, Chrome, Firefox, Edge, Safari, gamepad bergaya Xbox dan PlayStation |
| Playtest | M2: rasa kuali dan lempar (target 70 sampai 90 persen berhasil). M3: kurva kesulitan. Beta: seluruh alur dan tutorial |

**Kriteria rilis:** tidak ada bug P0 terbuka, tutorial bisa diselesaikan pemain baru tanpa bantuan, semua level bisa diselesaikan, build web diuji di halaman itch.io terbit, tidak ada `INVALID` dan tidak ada `box_*` pada aset M4, tidak ada kehilangan save saat pembaruan.

## 23. Telemetri (opsional, dengan persetujuan)

| Peristiwa | Kegunaan |
| --- | --- |
| `level_start`, `level_end` (hasil, skor, bintang, durasi) | Kurva kesulitan |
| `fail_reason` (hati habis, skor kurang) | Level yang terlalu sulit |
| `throw_result` (Jitu, Tersaji, Meleset, Mengenai monster, Meja salah) | Menyetel radius dan jarak |
| `tutorial_step` (selesai, lewati, tersangkut) | Titik tutorial yang membingungkan |
| `spill_event` | Dampak Kuali Dua Mode |
| `plate_starved` (rak kosong saat dibutuhkan) | Menyetel `plate_count` |

Pipeline (P2): API Gateway, Lambda, Firehose, S3, Athena. Rilis 1.0 boleh tanpa telemetri.

## 24. Risiko

| Risiko | Dampak | Mitigasi |
| --- | --- | --- |
| Audio atau performa web tersendat (single-thread) | Pengalaman web buruk | Profil sejak M0, batasi partikel dan kerumunan, Ogg, uji di halaman itch.io |
| Lempar terasa tidak adil | Inti mekanik gagal | Radius sukses 12 px, bantuan bidik default keyboard, playtest M2, semua parameter berbasis data |
| Beban pemain (cuci piring, aduk, balik) terlalu tinggi | Frustrasi | `plate_count` minimal tiket + 1, jendela aduk lebar, telemetri `plate_starved`, playtest |
| Aset final terlambat atau salah nama | Tampilan belum final | Placeholder, `sync_assets` dengan status `INVALID`, gerbang rilis CI |
| AI agent mengganti aset dengan salah | Aset hilang atau kode rusak | Aturan agen (§5.8), laporan status, review diff, agen tidak menyentuh `sim/` dan `view/` |
| Latensi online di web (TCP) | Gerakan tersendat | Prediksi lokal, buang snapshot lama, uji RTT 150 sampai 300 ms |
| Aturan itch.io atau browser berubah | Build web gagal | Tetap single-thread, cek dokumentasi tiap milestone |
| Server multi-ruangan kelebihan beban | Tick melambat | Uji beban dini, anggaran tick, tambah shard |
| Ruang lingkup membengkak | Jadwal molor | Konten berbasis data, Stage 1 dulu, daftar potong disepakati sejak awal |
| Biaya AWS tak terduga | Anggaran | AWS Budgets, shard minimum 1, draining |
| Keyboard dua pemain (ghosting) | Co-op lokal bermasalah | Skema P2 diuji, sarankan gamepad |
| Fakta teknis berubah | Rencana usang | Cek ulang di awal tiap milestone |

## 25. Milestone dan Estimasi

Asumsi tim kecil: 2 programmer, 2 seniman pixel, 1 desainer atau QA paruh waktu. **Aset berjalan paralel dan tidak menjadi syarat milestone kode**: tiap milestone dikerjakan dengan placeholder, lalu aset final masuk bertahap lewat `sync_assets`.

| Milestone | Durasi | Isi | Kriteria selesai |
| --- | --- | --- | --- |
| M0 Persiapan | 3 minggu | Repo, CI, proyek Godot, layout 480x270, **sistem aset (`Assets`, placeholder, `sync_assets`, `anim_gallery`)**, ekspor uji Windows dan web ke itch.io, peta input | Build kosong jalan di itch.io. Semua ID M1 tampil sebagai `box_*` |
| M1 Prototipe Stage 1 | 8 minggu | Gerak 8 arah dan tabrakan buatan, item, stasiun, resep, kuali, piring, lapak, kursi, Goblin, 1 dan 2 pemain lokal, level 1-1 sampai 1-4 | Stage 1 bisa ditamatkan dengan placeholder |
| M2 Vertical slice | 5 minggu | Lempar, tutorial T-1 sampai T-5, Dash, HUD, emoticon, kerumunan dasar, playtest pertama | Pemain baru lolos tutorial tanpa bantuan |
| M3 Konten stage 2 sampai 5 | 12 minggu | Monster, resep, hazard, skill lain, combo, boss, cerita, peta dunia | Semua 19 level bisa ditamatkan |
| M4 Polish dan Rilis 1.0 | 5 minggu | Aset final menggantikan placeholder, audio, penyeimbangan, save, aksesibilitas, QA, halaman itch.io | Rilis 1.0 Windows dan web, tanpa `box_*` pada aset M4 |
| M5 Online beta | 6 minggu | Server headless, lobby API, CDK, uji beban | 20 ruangan paralel stabil di staging |
| M6 Online rilis | 4 minggu | Pengerasan, observabilitas, alarm | Co-op online terbuka |

Total sekitar 33 minggu sampai Rilis 1.0 dan 43 minggu sampai online. Angka ini lebih panjang dari v0.1 karena cuci piring, lapak, kursi, kerumunan, emoticon, dan sistem aset ikut dikerjakan.

## 26. Pertanyaan Terbuka

- [ ] Standar nama aset diterima: prefix, dua garis bawah, strip PNG, dan folder per ID (`assets/<prefix>/<ID>/`).
- [ ] Format animasi strip PNG, dengan GIF hanya sebagai masukan yang dikonversi.
- [ ] Siapa yang menjalankan `sync_assets`: manual, AI agent, atau CI.
- [ ] Wajan ditunda (FRY dan BOIL di kuali) untuk Rilis 1.0.
- [ ] Isi "lauk" dan "sayur" tumpeng (usulan: mendoan dan urap sederhana).
- [ ] Skema keyboard P2.
- [ ] Region AWS final dan hasil cek layanan di Jakarta, atau Singapura.
- [ ] Subnet publik atau privat untuk Fargate.
- [ ] Game gratis atau berbayar di itch.io, dan anggaran bulanan AWS.
- [ ] Login tamu cukup untuk online, atau akun diperlukan sebelum Fase 3.
- [ ] Telemetri di Rilis 1.0 atau ditunda.
- [ ] Ukuran tim dan jadwal sebenarnya.

## Lampiran A. Konstanta Awal

| Konstanta | Nilai awal |
| --- | --- |
| Tick simulasi | 60 Hz |
| Kecepatan koki | 5 tile per detik |
| Radius tabrakan koki | 6 px |
| Probe interaksi | Radius 9 px (kursi 14 px) di depan 12 px |
| Dash, cooldown | 4 tile, 6 detik |
| Buff Kecepatan | +40 persen, 5 detik, cooldown 15 detik |
| Teleport cooldown | 8 detik |
| Buff Api | 2x, 8 detik, cooldown 20 detik |
| Jendela combo, cooldown combo | 3 detik, 30 detik |
| Waktu tunggu monster | Goblin 40, Kadal 50, Ogre 60, Hantu 60 detik |
| Skala kesabaran meja kecil | 0,85 |
| Durasi amukan | 10 detik |
| Hati Dapur | 5 |
| Pukulan sutil dan kuali | Hitbox 1,2 dan 1,6 tile, cooldown 0,4 dan 0,8 detik |
| Kunci kuali setelah memukul | 4 detik |
| Waktu gosong, penalti lewat | 10 detik, dikali 0,3 |
| Jarak bidik, waktu naik | 2 sampai 8 tile, 1,2 detik |
| Waktu terbang lemparan | 0,4 sampai 0,9 detik |
| Radius zona saji, Jitu, bantuan bidik | 12 px, 6 px, 20 px |
| Hukuman meleset | -25 poin, kesabaran -15 (kursi cocok terdekat dalam 40 px) |
| Hukuman mengenai monster, meja salah | -25 dan kesabaran -25, -50 dan kesabaran -10 |
| Piring minimal | Tiket terbuka + 1 |
| Cuci piring | 2 detik per piring, tumpukan maksimal 3 |
| Piring kotor muncul | 2 detik setelah monster pergi |
| Goblin lari | 3 tile per detik |
| Input, snapshot online | 30 Hz, 20 Hz |
| Jendela sambung ulang | 30 detik |
