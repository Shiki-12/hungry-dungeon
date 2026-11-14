# PRD Teknis: Koki Dungeon (Working Title)

Nov 13, 2026 · @Glooms Sarpy

Dokumen ini mengubah Dokumen Gambaran Game yang sudah disetujui menjadi spesifikasi teknis untuk developer. Teknologi: **Godot** untuk game, **AWS** untuk layanan online, rilis di **itch.io** sebagai build **Windows** dan **web**. Ini versi 0.1 untuk ditinjau tim developer.

**Konvensi dokumen**

- ID persyaratan: **FR** (fungsional) dan **NFR** (non-fungsional), contoh FR-THR-03.
- Prioritas: **P0** wajib untuk Rilis 1.0, **P1** dikerjakan bila waktu cukup, **P2** untuk fase online dan pasca-rilis.
- Semua angka adalah **nilai awal** dan disimpan di file data (`.tres`), bukan ditulis langsung di kode, supaya bisa disetel saat playtest.
- Nama identifier di kode memakai bahasa Inggris. Teks untuk pemain memakai Bahasa Indonesia lewat file terjemahan.

## 1. Ringkasan Produk dan Tujuan Teknis

*Koki Dungeon* adalah game memasak co-op 1 sampai 2 pemain bergaya Overcooked dengan pixel art 2D. Pelanggannya monster yang bisa mengamuk, kuali berfungsi ganda sebagai alat masak dan senjata, dan hidangan bisa **dilempar** ke meja monster dengan bidikan berbentuk busur.

**Tujuan teknis:**

1. Rilis 1.0 berjalan mulus di **Windows** dan **browser** (itch.io) dengan satu basis kode.
2. Mode 1 pemain, 2 pemain lokal, dan (Fase 2) 2 pemain online memakai **jalur kode simulasi yang sama**.
3. Semua konten (level, resep, monster, hazard) berbasis **data**, sehingga desainer bisa menambah dan menyetel tanpa mengubah kode.
4. Online memakai server otoritatif di AWS agar pemain web dan Windows bisa bermain bersama.

**Bukan tujuan:** versi 3D, mobile, konsol, voice chat, matchmaking publik berperingkat, pembelian dalam game, dan login akun sosial di Rilis 1.0.

**Kriteria sukses teknis:**

| Ukuran | Target |
| --- | --- |
| Frame rate desktop | 60 FPS stabil di laptop dengan GPU terintegrasi |
| Frame rate web | 60 FPS di Chrome dan Firefox pada laptop kelas menengah |
| Waktu muat web | 15 detik atau kurang pada koneksi 20 Mbps |
| Konsistensi simulasi | Replay input yang sama menghasilkan skor yang sama |
| Online (Fase 2) | Bermain nyaman sampai RTT 150 ms, tanpa desync yang terlihat |

## 2. Keputusan Teknis Utama

| Area | Keputusan | Alasan |
| --- | --- | --- |
| Engine | **Godot 4.7.x stable** (4.7.2 rilis 18 Agustus 2026). Kunci versi minor di awal proyek, upgrade hanya patch | Stabilitas selama produksi |
| Bahasa | **GDScript** dengan static typing. **Tanpa C#** | Godot 4 tidak bisa mengekspor proyek C# ke web |
| Renderer | **Compatibility** (WebGL 2) | Wajib untuk web, cukup untuk 2D pixel art |
| Platform rilis | Windows 64-bit dan Web (HTML5) di itch.io. Linux opsional | Sesuai kebutuhan rilis |
| Web export | **Single-thread** (Thread Support mati) | Default sejak Godot 4.3, tidak butuh header khusus, lebih kompatibel dengan itch.io |
| Arsitektur | Simulasi dipisah dari tampilan. Mode offline memakai jalur kode yang sama dengan online | Fase 2 tidak perlu menulis ulang |
| Transport online | **WebSocketMultiplayerPeer** (wss) untuk semua platform | ENet (UDP) tidak tersedia di web export. WebSocket jalan di Windows maupun browser |
| Otoritas online | **Server dedicated** (Godot headless) otoritatif | Browser tidak bisa menjadi host. Server otoritatif juga mencegah curang |
| Hosting game server | **AWS ECS Fargate + Application Load Balancer** dengan TLS | WebSocket didukung, sederhana, tanpa SDK khusus |
| Lobby dan auth | API Gateway (HTTP API) + Lambda + DynamoDB, **login tamu** dengan token JWT | Serverless, murah untuk skala kecil |
| Infrastruktur sebagai kode | **AWS CDK** (TypeScript) | Mudah diulang antar lingkungan |
| CI/CD | GitHub Actions: export Godot, build image server, deploy ke AWS, push ke itch.io dengan **butler** | Otomatis dan bisa diulang |
| Region AWS | Asia Pasifik (Jakarta) bila semua layanan yang dipakai tersedia, cadangan Singapura | Latensi rendah untuk pemain Indonesia. **Perlu dicek** ketersediaan layanan |

**Kenapa bukan Amazon GameLift:** server SDK GameLift tersedia untuk C++, C#, dan Go, tidak untuk GDScript, sehingga butuh jembatan tambahan. Untuk game 2 pemain, orkestrasi GameLift juga berlebihan. Evaluasi ulang bila jumlah pemain bersamaan sudah besar.

**Fakta yang dicek per 13 November 2026 dan perlu dicek ulang saat mulai produksi:**

- Godot web export single-thread adalah default sejak 4.3 dan memakai renderer Compatibility.
- itch.io membatasi build web sekitar 500 MB setelah diekstrak, 1.000 file, dan 200 MB per file (angka dari panduan komunitas, cek dokumentasi itch.io).
- Mode threaded butuh SharedArrayBuffer, yang di itch.io masih berstatus eksperimental. Karena itu proyek ini memilih single-thread.

## 3. Fase Rilis

| Fase | Isi | Teknologi |
| --- | --- | --- |
| **Fase 1: Rilis 1.0** | Tutorial 5 level, 19 level utama, 1 pemain, 2 pemain lokal, mekanik lempar, skill dan combo | Godot, build Windows dan web di itch.io. **Tanpa AWS saat berjalan** |
| **Fase 2: Online beta** | Co-op online 2 pemain lewat kode ruangan | Server Godot headless di AWS, lobby API |
| **Fase 3: Pasca-rilis** | Mode Warung, bahasa tambahan, kostum, papan skor, akun | Perluasan AWS |

Kode Fase 1 **sudah dibuat siap online**: input dikirim sebagai perintah, simulasi memegang seluruh state, tampilan hanya membaca state. Dengan begitu Fase 2 tidak perlu menulis ulang gameplay.

## 4. Arsitektur Klien Godot

### 4.1 Pengaturan proyek

| Pengaturan | Nilai |
| --- | --- |
| Viewport dasar | 480x270 piksel |
| Stretch mode | viewport, aspect keep, scale mode **integer** |
| Filter tekstur default | Nearest |
| Snap transform 2D ke piksel | Aktif |
| Renderer | Compatibility |
| Physics ticks per detik | 60 |
| Ukuran jendela default | 1920x1080 (skala 4x), minimum 960x540 (skala 2x) |
| Fullscreen | Tombol dan menu pengaturan |

**Tata letak layar** (menyelesaikan masalah tinggi 270 px yang tidak habis dibagi tile 16 px):

| Area | Ukuran |
| --- | --- |
| HUD atas (tiket pesanan, skor, timer) | 480x30 px |
| Area dapur | 30x14 tile = 480x224 px |
| HUD bawah (Hati Dapur, ikon skill) | 480x16 px |
| Total | 480x270 px |

Semua level wajib muat di area dapur 30x14 tile, tanpa scroll kamera.

### 4.2 Struktur folder

```
res://
  autoload/        # singleton global
  sim/             # simulasi: tanpa node visual, dipakai klien dan server
    entities/      # cook, monster, item, station, projectile
    systems/       # orders, scoring, hazards, throw, skills
  view/            # sprite, animasi, VFX, audio, kamera
  ui/              # HUD, menu, peta dunia, dialog
  data/            # file .tres: levels, recipes, monsters, skills
  levels/          # scene level (TileMapLayer + penempatan)
  net/             # klien jaringan dan server (Fase 2)
  tutorial/        # data dan runner tutorial
  tests/           # unit test dan test simulasi
  locale/          # file terjemahan
```

### 4.3 Autoload

| Singleton | Tugas |
| --- | --- |
| `Game` | Alur level, mode permainan, pause, transisi scene |
| `Net` | Abstraksi sesi: offline, lokal, online (Fase 2) |
| `Save` | Baca dan tulis progres dan pengaturan |
| `Audio` | Bus musik, SFX, UI, dan pemutar |
| `Events` | Bus sinyal global (pesanan selesai, monster puas, dan sebagainya) |
| `Settings` | Input, volume, bahasa, bantuan bidik, offset audio |

### 4.4 Pemisahan simulasi dan tampilan

Aturan wajib agar server headless bisa menjalankan game:

- Folder `sim/` **tidak boleh** memuat node yang bergantung pada render, audio, atau UI.
- Simulasi berjalan pada **tick tetap 60 Hz** (`_physics_process`). Tampilan membaca state dan melakukan interpolasi.
- Seluruh aksi pemain masuk lewat **struktur Input** per tick: arah gerak, tombol aksi, tombol kerja, tombol pukul, tombol skill, dan data bidik lempar.
- Perubahan state penting memancarkan **event** (misalnya `order_served`, `throw_resolved`) yang dibaca tampilan untuk memainkan efek dan suara.
- Fungsi acak memakai **RNG ber-seed** milik simulasi, bukan `randf()` global, agar replay dan server konsisten.
- Mode offline dan lokal menjalankan simulasi di proses yang sama dengan `OfflineMultiplayerPeer`. Mode online memasang peer jaringan di tempat yang sama.

### 4.5 Konten berbasis data

Semua konten berupa Resource kustom di `data/`:

| Resource | Isi utama |
| --- | --- |
| `LevelData` | id, stage, durasi, scene layout, titik awal koki, stasiun, menu aktif, jadwal monster, hazard, batas 3 bintang, tamu istimewa, skill terbuka |
| `RecipeData` | id, nama, langkah, ikon, nilai poin, waktu gosong |
| `StepData` | tipe (CHOP, COOK, STEAM, GRILL, FRY, BOIL, POUND, WRAP, ASSEMBLE), input, output, durasi, stasiun |
| `ItemData` | id, sprite, kategori (INGREDIENT, DISH, COOKWARE, PLATE, SNACK), bisa dilempar |
| `StationData` | id, tipe, ukuran, item yang diterima, durasi gosong, mode kerja otomatis atau manual |
| `MonsterData` | id, sprite, ukuran, waktu tunggu dasar, selera, pola serang, efek kerupuk, drop langka |
| `SkillData` | id, pemilik, cooldown, durasi, parameter |
| `HazardData` | tipe, periode, durasi, parameter |
| `TutorialData` | daftar langkah tutorial |

### 4.6 Input

| Aksi | Keyboard (P1) | Gamepad |
| --- | --- | --- |
| `move_*` | WASD | Stik kiri |
| `interact` | E | A |
| `work` | F | X |
| `strike` | Spasi | B |
| `skill` | Q | Y |
| `throw` | C (ketuk atau tahan) | Bumper kanan (ketuk atau tahan) |
| `swap_cook` | Tab | Bumper kiri |
| `pause` | Esc | Start |
| skill\_2 (skill kedua koki) | R | Trigger kanan |

- P1 dan P2 memakai set aksi terpisah (`p1_*`, `p2_*`). Skema keyboard P2 (tombol panah dan tombol di sekitarnya) ditetapkan pada tahap M1.
- Pemain bisa memetakan ulang tombol. Pengaturan disimpan di `Save`.
- Bidik lempar di gamepad memakai stik kanan.
- Web: Gamepad API browser didukung Godot, tapi harus diuji di Chrome dan Firefox.

### 4.7 Konvensi kode

- Static typing wajib di GDScript (`var x: int`, tipe return).
- Satu tanggung jawab per script. Sinyal dipakai untuk komunikasi antar sistem, bukan referensi node langsung.
- Git dengan Git LFS untuk aset gambar dan audio. Cabang `main` selalu bisa dibuild.
- Setiap fitur sim wajib punya minimal satu unit test.

## 5. Spesifikasi Sistem Gameplay

### 5.1 Koki dan gerak

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-MOV-01 | Koki bergerak 8 arah dengan kecepatan awal 5 tile per detik dan percepatan singkat (0,06 detik ke kecepatan penuh) | P0 |
| FR-MOV-02 | Koki bertabrakan dengan dinding, stasiun, dan koki lain. Tidak ada tembus-menembus | P0 |
| FR-MOV-03 | Lantai licin (stage 4): gerak berbasis momentum dengan percepatan 0,35 detik dan gesekan rendah | P0 |
| FR-MOV-04 | Koki menghadap arah gerak terakhir. Arah hadap menentukan target interaksi (area 1 tile di depan) | P0 |
| FR-MOV-05 | Mode 1 pemain: `swap_cook` memindahkan kendali ke koki lain, koki yang ditinggal diam | P0 |

### 5.2 Item dan interaksi

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-INT-01 | Satu slot tangan per koki. Item yang dibawa tampil di atas kepala | P0 |
| FR-INT-02 | `interact` mengambil atau menaruh pada target di depan. Prioritas target: stasiun, item di lantai, monster (untuk menyerahkan hidangan) | P0 |
| FR-INT-03 | `work` menjalankan aksi kerja (potong, aduk, ulek) selama ditahan, dengan bar progres | P0 |
| FR-INT-04 | Item di lantai bisa dipungut. Item yang jatuh ke air hanyut (stage 2) atau lava hangus (stage 3) | P0 |
| FR-INT-05 | Piring menampung hingga 3 komponen. Validasi terhadap resep memakai tanda tangan komponen, urutan tidak berpengaruh | P0 |
| FR-INT-06 | Menyerahkan hidangan dengan jalan kaki (jarak 1 tile dari meja saji) selalu tersaji tanpa risiko | P0 |

### 5.3 Stasiun dan resep

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-STA-01 | Stasiun adalah state machine: EMPTY, WORKING, DONE, BURNING, BURNT, dengan sinyal tiap perubahan | P0 |
| FR-STA-02 | Stasiun otomatis (tungku, dandang, anglo, wajan, panci) bekerja sendiri sampai DONE. Stasiun manual (meja potong, cobek) hanya bekerja selama `work` ditahan | P0 |
| FR-STA-03 | Setelah DONE, timer gosong (awal 10 detik) mengubah state ke BURNING (asap) lalu BURNT. Item gosong tidak valid dan stasiun harus dikosongkan | P0 |
| FR-STA-04 | Resep didefinisikan sebagai urutan `StepData`. Menu yang butuh beberapa stasiun (pepes: layu daun, bungkus, kukus) dimodelkan sebagai langkah berantai | P0 |
| FR-STA-05 | Pepes: daun dilayukan di api, dibungkus bersama ikan dan bumbu, dikukus 12 detik di dandang | P0 |
| FR-STA-06 | Sate di anglo harus dibalik tiap 6 detik. Jika terlewat, timer gosong dipercepat menjadi 3 detik | P0 |
| FR-STA-07 | Rendang kilat: durasi dasar 24 detik, Buff Api menggandakan kecepatan | P0 |
| FR-STA-08 | **Ulek ritme:** bar irama 90 BPM, 6 ketukan per sambal. Jendela waktu Sempurna ±60 ms, Bagus ±120 ms, selain itu Meleset. Kualitas sambal menaikkan kepuasan 25, 15, atau 5 poin | P0 |
| FR-STA-09 | Layar kalibrasi **offset audio** untuk mengimbangi latensi suara di web dan perangkat berbeda | P1 |
| FR-STA-10 | **Tumpeng:** tiga sub-langkah (cetak nasi, susun lauk dan sayur, letakkan 4 Bahan Langka). Urutan salah meruntuhkan tumpeng dan mengulang sub-langkah itu | P0 |

### 5.4 Monster dan pesanan

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-MON-01 | Spawner mengikuti jadwal wave dari `LevelData`, dibatasi jumlah maksimal sekaligus per level | P0 |
| FR-MON-02 | State monster: ARRIVING, SEATED, WAITING, EATING, SATISFIED, LEAVING. Cabang amarah: ENRAGED, ATTACKING, EXPELLED, LEAVING | P0 |
| FR-MON-03 | Kesabaran turun linear dari 100 ke 0 sesuai waktu tunggu: Goblin 40 detik, Kadal 50, Ogre 60, Hantu 60. Level 5-1 memakai 120 persen | P0 |
| FR-MON-04 | Tahap 1 (di atas 50 persen): menggerutu. Tahap 2 (50 sampai 0): bonus cepat berhenti dan bahan terdekat bergeser. Tahap 3 (0): mengamuk | P0 |
| FR-MON-05 | Mengamuk menyerang selama 10 detik. Bila tidak diusir: Hati Dapur berkurang 1 dan stasiun terdekat rusak 8 detik, lalu monster pergi | P0 |
| FR-MON-06 | Kepuasan awal 40. Kepuasan akhir = 40 + (sisa kesabaran x 0,4) + bonus sambal (25, 15, 5) + bonus Jitu (5), maksimal 100. Angka awal untuk disetel | P0 |
| FR-MON-07 | Tamu istimewa (penanda di wave) dengan kepuasan 80 atau lebih menjatuhkan Bahan Langka stage tersebut dan menyimpannya ke save | P0 |
| FR-MON-08 | Pesanan salah: -50 poin, kesabaran -10, hidangan hilang | P0 |
| FR-MON-09 | Kerupuk (kategori SNACK) yang dilempar ke monster menahan penurunan kesabaran 8 detik. Efek tambahan per monster dari `MonsterData` | P0 |
| FR-MON-10 | Hantu stage 4: transparan dan tidak bisa dipukul sampai tahap 3. Di level 4-3, hantu hanya terlihat saat awan aroma wedang aktif (15 detik per seduhan) | P0 |
| FR-MON-11 | Pelanggan manusia (level 5-2) tidak menyerang. Jika kesabaran habis, mereka pergi dan Hati Dapur berkurang 1 | P0 |

### 5.5 Sutil dan Kuali Dua Mode

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-CMB-01 | **Sutil:** hitbox persegi 1,2 tile di depan koki, aktif 0,12 detik, cooldown 0,4 detik. Tiga pukulan mengusir monster mengamuk. Bisa mendorong monster kecil | P0 |
| FR-CMB-02 | **Kuali:** saat diangkat dari tungku menjadi item COOKWARE. Pukulan kuali punya hitbox 1,6 tile, cooldown 0,8 detik, satu pukulan mengusir monster | P0 |
| FR-CMB-03 | **Aturan tumpah:** jika kuali berisi apa pun (bahan, masakan setengah matang, atau matang) dipakai memukul, isinya hilang, muncul noda tumpah, dan -25 poin | P0 |
| FR-CMB-04 | Setelah dipakai memukul, kuali tidak bisa dipakai memasak selama 4 detik | P0 |
| FR-CMB-05 | Ikon peringatan di atas kuali berisi saat koki mengangkatnya dan monster ada dalam jarak 3 tile | P1 |
| FR-CMB-06 | Efek hit-stop 60 ms dan guncangan kamera kecil saat pukulan mengenai | P1 |
| FR-CMB-07 | Monster yang diusir terpental, pergi, dan tidak memberi drop | P0 |

### 5.6 Lempar bahan dan hidangan

Sistem ini dipakai klien (untuk pratinjau) dan server (untuk hasil), jadi rumusnya harus **satu file bersama** di `sim/systems/throw_math.gd`.

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-THR-01 | **Lempar cepat:** ketuk tombol lempar melempar bahan sejauh tetap 4 tile ke arah hadap | P0 |
| FR-THR-02 | **Lempar bidik:** tahan tombol untuk membidik, lepas untuk melempar. Hidangan jadi hanya bisa dilempar dengan mode bidik | P0 |
| FR-THR-03 | Selama membidik, tampilkan garis busur putus-putus dan penanda titik jatuh berbentuk lingkaran. Warna hijau di area Jitu, kuning di zona saji, merah di luar zona | P0 |
| FR-THR-04 | Jarak membidik naik dari 2 sampai 8 tile dalam 1,2 detik, lalu turun lagi dan berulang. Arah mengikuti stik atau tombol arah | P0 |
| FR-THR-05 | Koki berjalan 50 persen lebih lambat saat membidik dan tidak bisa memukul. Kuali dan sutil tidak bisa dilempar | P0 |
| FR-THR-06 | Waktu terbang 0,4 detik pada 2 tile sampai 0,9 detik pada 8 tile (interpolasi linear) | P0 |
| FR-THR-07 | Zona saji tiap meja monster seluas 2x1 tile (altar Sang Ageng 3x3). Area Jitu adalah 16x16 piksel di tengah zona | P0 |
| FR-THR-08 | Hasil hidangan: **Jitu** (di area Jitu: tersaji, +25 poin, kepuasan +5), **Tersaji** (di zona: tersaji normal), **Meleset** (di lantai: hancur, -25 poin, kesabaran monster tujuan -15), **Mengenai monster** (hancur, -25, kesabaran -25), **Meja salah** (dihitung pesanan salah, kesabaran monster itu -10) | P0 |
| FR-THR-09 | Tiga Jitu berturut-turut memberi +50 poin. Penghitung direset oleh hasil selain Jitu | P0 |
| FR-THR-10 | Bahan yang mendarat dalam jarak 16 piksel dari rekan bertangan kosong ditangkap otomatis. Stasiun yang titik jatuhnya masuk area terimanya menerima bahan bila cocok | P0 |
| FR-THR-11 | Pengubah per stage lewat `HazardData`: stage 3 menggeser titik jatuh oleh angin uap, stage 5 menggetarkan penanda 0,3 detik tiap 20 detik | P0 |
| FR-THR-12 | Opsi **Bantuan bidik**: titik jatuh menempel ke zona saji terdekat, bonus Jitu dinonaktifkan | P1 |
| FR-THR-13 | Cooldown lempar 0,3 detik. Piring dari hidangan yang hancur kembali ke rak piring setelah 10 detik | P0 |

**Rumus bersama (acuan implementasi):**

```gdscript
# sim/systems/throw_math.gd
const TILE := 16.0
const MIN_R := 2.0
const MAX_R := 8.0
const RAMP_TIME := 1.2  # detik dari 2 ke 8 tile

static func range_at(hold_time: float) -> float:
	var phase := fposmod(hold_time / RAMP_TIME, 2.0)
	var t := phase if phase <= 1.0 else 2.0 - phase  # gelombang segitiga 0..1
	return lerpf(MIN_R, MAX_R, t)

static func flight_time(r_tiles: float) -> float:
	return 0.4 + (r_tiles - MIN_R) / (MAX_R - MIN_R) * 0.5

static func landing_point(origin: Vector2, dir: Vector2, r_tiles: float, wind: Vector2) -> Vector2:
	return origin + dir.normalized() * r_tiles * TILE + wind
```

Tinggi busur hanya untuk tampilan: `tinggi = r_tiles * 4.0` piksel, dengan lintasan parabola `4 * s * (1 - s)` dengan `s` adalah waktu terbang ternormalisasi 0 sampai 1.

**Alur lempar:** klien mengirim `hold_time` (dibulatkan ke milidetik), arah (sudut 16-bit), dan item yang dipegang. Simulasi menghitung titik jatuh dengan rumus yang sama, menjadwalkan hasil pada `t + flight_time`, lalu memancarkan event `throw_resolved` berisi hasil. Pratinjau di klien dan hasil di simulasi **harus identik**.

### 5.7 Skill dan combo

Tiap koki punya dua skill, jadi input dipecah: `skill` (di tabel input) berfungsi sebagai **skill\_1**, dan **skill\_2** ditambahkan sebagai aksi terpisah. Catatan: tabel kontrol di Dokumen Gambaran Game hanya memuat satu tombol skill, jadi ini penyesuaian yang perlu disetujui.

| Koki | skill\_1 | skill\_2 |
| --- | --- | --- |
| Rangga | Dash | Buff Kecepatan |
| Sekar | Teleport | Buff Api |

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-SKL-01 | **Dash:** melesat 4 tile dalam 0,15 detik, cooldown 6 detik. Mendorong monster kecil. Item yang dibawa tidak jatuh | P0 |
| FR-SKL-02 | **Buff Kecepatan:** kecepatan kedua koki +40 persen selama 5 detik, cooldown 15 detik. Memperpendek ramp bidik lempar 20 persen | P0 |
| FR-SKL-03 | **Teleport:** tahan skill\_1 0,5 detik untuk memasang penanda (maksimal 2, penanda ketiga menggantikan yang tertua). Ketuk skill\_1 untuk berpindah ke penanda terbaru. Ketuk dua kali dalam 0,3 detik untuk bertukar tempat dengan rekan. Cooldown 8 detik | P0 |
| FR-SKL-04 | **Buff Api:** stasiun masak di depan koki bekerja 2x lebih cepat selama 8 detik, cooldown 20 detik | P0 |
| FR-SKL-05 | **Combo:** dua skill pasangan yang diaktifkan dalam jendela 3 detik membentuk combo. Cooldown combo 30 detik, bonus +50 poin | P0 |
| FR-SKL-06 | **Antar Kilat:** Dash sambil membawa piring lalu Teleport ke penanda di meja saji. Hidangan langsung tersaji | P0 |
| FR-SKL-07 | **Dapur Membara:** Buff Kecepatan dan Buff Api bersamaan. Satu masakan di stasiun target selesai seketika | P0 |
| FR-SKL-08 | **Tendangan Kuali:** Teleport tukar tempat ke dekat monster mengamuk lalu Dash. Monster terpental jauh dan pergi tanpa memakai kuali | P0 |
| FR-SKL-09 | Skill dan combo dibuka bertahap sesuai `LevelData.skills_unlocked`: Dash 1-3, Teleport 2-1, Antar Kilat 2-2, Buff Kecepatan 2-3, Buff Api 3-1, Dapur Membara 3-2, Tendangan Kuali 3-3 | P0 |
| FR-SKL-10 | Mode 1 pemain: skill dimiliki koki yang sedang dikendalikan. Cooldown berjalan terpisah per koki | P0 |

### 5.8 Skor, bintang, dan Hati Dapur

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-SCR-01 | Poin: pesanan benar +100, bonus cepat +50 (disajikan sebelum tahap 2), combo +50, Jitu +25, tiga Jitu beruntun +50, pesanan salah -50, masakan gosong atau tumpah atau hancur -25 | P0 |
| FR-SCR-02 | Bintang dihitung dari tiga batas di `LevelData`. Satu bintang membuka level berikutnya | P0 |
| FR-SCR-03 | Tim punya 5 Hati Dapur. Level gagal bila Hati Dapur habis atau skor akhir di bawah batas bintang 1 | P0 |
| FR-SCR-04 | Level 5-3 (boss): 1 bintang bila selesai, 2 bila sisa 3 hati atau lebih, 3 bila sisa 4 hati atau lebih dan kepuasan Naga di atas 80 | P0 |
| FR-SCR-05 | Layar hasil menampilkan skor, bintang, rincian bonus, dan Bahan Langka yang didapat. Skor terbaik disimpan per level | P0 |

### 5.9 Hazard per stage

Hazard diimplementasikan sebagai node `HazardController` yang dibuat dari `HazardData`, bukan kode khusus di tiap level.

| Hazard | Parameter awal | Efek | Level |
| --- | --- | --- | --- |
| TIDE | Periode 20 detik | Air naik, item di papan rendah hanyut | 2-1 sampai 2-4 |
| TAIL\_SWEEP | Telegraf garis 1,5 detik | Sapuan ekor melempar koki dan menjatuhkan item | 2-3, 2-4 |
| LAVA | Periode 15 detik, 3 tile | Koki yang menginjak terpental ke titik awal dan menjatuhkan item | 3-1 sampai 3-4 |
| HOT\_STOVE | Kecepatan masak +30 persen | Waktu gosong dikalikan 0,7 | 3-1 |
| SHOCKWAVE | Dipicu serangan Ogre | Gelombang kejut melempar item di sekitar | 3-3, 3-4 |
| EXPLOSION | Tiap 45 detik | Layar bergetar, item bergeser 1 tile | 3-4 |
| STEAM\_WIND | Tiap 10 detik | Titik jatuh lempar bergeser ke samping, tampak sebagai panah uap | Stage 3 |
| ICE\_FLOOR | Percepatan 0,35 detik | Gerak licin. Item beku butuh 3 detik di tungku sebelum diproses | 4-1 sampai 4-4 |
| BLACKOUT | Tiap 30 detik selama 8 detik | Layar gelap, hanya lingkaran 3 tile di sekitar koki dan stasiun yang menyala. Garis bidik tetap bersinar | 4-2 sampai 4-4 |
| AROMA | 15 detik per seduhan | Hantu terlihat dan memesan hanya saat awan aroma aktif | 4-3, 4-4 |
| HEARTBEAT | Tiap 20 detik | Item bergeser 1 tile, penanda bidik bergetar 0,3 detik | 5-1 |
| DRAGON\_BREATH | Tiap 30 detik | Api kecil ke satu sudut dapur dengan telegraf 1,5 detik | 5-2 |

### 5.10 Boss: Sang Ageng

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-BOS-01 | Tiga fase berurutan. Fase berganti saat hidangan fase itu tersaji. Hati Dapur tidak pulih antar fase | P0 |
| FR-BOS-02 | Fase 1 (sup pembuka): tiap 30 detik Naga meniup api ke satu sudut acak dengan telegraf 1,5 detik | P0 |
| FR-BOS-03 | Fase 2 (sate dan rendang kilat): sapuan ekor tiap 30 detik dengan telegraf garis. Bisa dihindari dengan Dash atau berpindah | P0 |
| FR-BOS-04 | Fase 3 (tumpeng): napas api menyapu satu baris lantai tiap 20 detik dengan telegraf 2 detik. Perakitan tumpeng harus dilakukan di sela serangan | P0 |
| FR-BOS-05 | Meter kepuasan Naga mulai 60, turun 0,5 poin per detik, naik +30 tiap hidangan tersaji (+5 bila Jitu). Level gagal bila habis | P0 |
| FR-BOS-06 | Altar persembahan 3x3 tile sebagai zona saji. Naga tidak bisa dibunuh | P0 |

### 5.11 Tutorial

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-TUT-01 | `TutorialRunner` membaca `TutorialData`: tiap langkah berisi id, kunci teks, target sorotan (grup node), pemicu mulai, syarat selesai (hitungan event), dan input yang diblokir | P0 |
| FR-TUT-02 | Syarat selesai: T-1 tiga hidangan tersaji. T-2 tiga nasi goreng jamur tersaji (termasuk satu gosong sengaja). T-3 lima bahan terlempar ke stasiun. T-4 lima lemparan tersaji dengan minimal 2 Jitu. T-5 tiga monster diusir dengan sutil, satu dengan kuali kosong, satu kerupuk terlempar, satu tumpah disengaja | P0 |
| FR-TUT-03 | Level tutorial tanpa timer, Hati Dapur, dan bintang (flag di `LevelData`) | P0 |
| FR-TUT-04 | Tutorial wajib sekali di pemakaian pertama. Tersedia tombol **Lewati Tutorial** dengan konfirmasi dan menu **Latihan** untuk mengulang tiap level T | P0 |
| FR-TUT-05 | Dalam co-op, syarat selesai dihitung gabungan kedua pemain | P0 |
| FR-TUT-06 | Ikon tombol pada petunjuk menyesuaikan perangkat aktif (keyboard atau gamepad) | P0 |
| FR-TUT-07 | Pop-up penjelasan Kuali Dua Mode muncul sekali di T-5 dan sekali lagi di 1-3 | P0 |
| FR-TUT-08 | Setelah 3 kali meleset beruntun di T-4, zona saji latihan membesar 25 persen | P1 |

Skill tidak diajarkan di tutorial. Skill dibuka bertahap mulai level 1-3.

### 5.12 Progres dan penyimpanan

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-SAV-01 | Progres disimpan di `user://save.json` dengan nomor versi skema. Penulisan atomik: tulis ke file sementara lalu ganti | P0 |
| FR-SAV-02 | Data yang disimpan: bintang dan skor terbaik per level, Bahan Langka, halaman Buku Resep, kostum, flag tutorial, pengaturan, dan opsi aksesibilitas | P0 |
| FR-SAV-03 | Web: `user://` tersimpan di IndexedDB browser dan bisa hilang jika pemain menghapus data situs. Tampilkan peringatan dan sediakan **ekspor dan impor kode save** | P1 |
| FR-SAV-04 | Migrasi otomatis antar versi skema save | P0 |
| FR-SAV-05 | Satu profil per perangkat untuk Rilis 1.0 | P0 |
| FR-SAV-06 | Cloud save opsional via AWS | P2 |

## 6. Jaringan dan Online (Fase 2)

### 6.1 Arsitektur

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
| Klien Godot | Mengirim input, menampilkan state, prediksi gerak koki sendiri |
| Lobby API | Login tamu, membuat dan menggabung ruangan, memilih shard |
| Shard server | Satu task Fargate yang menjalankan Godot headless dan menampung banyak ruangan |
| DynamoDB | Daftar ruangan, status dan muatan shard, profil tamu |

### 6.2 Model otoritas dan sinkronisasi

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-NET-01 | Server otoritatif. Klien hanya mengirim **input**. Server menjalankan simulasi dan mengirim **snapshot** | P2 |
| FR-NET-02 | Input dikirim 30 kali per detik dengan nomor urut. Snapshot dikirim 20 kali per detik | P2 |
| FR-NET-03 | Klien memprediksi gerak koki miliknya dan merekonsiliasi dengan snapshot server. Entitas lain diinterpolasi dengan buffer 100 ms | P2 |
| FR-NET-04 | Hasil lemparan, pukulan, skor, dan drop ditentukan server. Klien hanya menampilkan pratinjau bidik | P2 |
| FR-NET-05 | WebSocket berbasis TCP, sehingga semua pesan efektif reliable dan berurutan. Mitigasi antrean: snapshot ber-nomor urut, klien membuang snapshot lama, server melewati snapshot bila buffer kirim penuh | P2 |
| FR-NET-06 | Snapshot dan event memakai format biner (`PackedByteArray`) dengan posisi dikuantisasi (fixed-point 1/8 piksel). Target ukuran snapshot di bawah 400 byte | P2 |
| FR-NET-07 | Tidak memakai `MultiplayerSynchronizer` untuk gameplay. Serialisasi manual agar kontrol per ruangan penuh dan ukuran paket kecil | P2 |

**Jenis pesan:**

| Arah | Pesan |
| --- | --- |
| Klien ke server | AUTH, READY, INPUT, PING, LEAVE |
| Server ke klien | AUTH\_OK, ROOM\_STATE, START, SNAPSHOT, EVENT, RESULT, PONG, KICK |

### 6.3 Ruangan dan kapasitas

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-ROM-01 | Siklus ruangan: LOBBY, LOADING, PLAYING, RESULTS, CLOSED. Maksimal 2 pemain | P2 |
| FR-ROM-02 | Kode ruangan 6 karakter dari huruf besar dan angka tanpa karakter yang membingungkan (tanpa O, 0, I, 1). Dua karakter pertama menandai shard | P2 |
| FR-ROM-03 | Pemain yang terputus punya jendela sambung ulang 30 detik. Selama itu kokinya diam dan permainan dijeda setelah 10 detik | P2 |
| FR-ROM-04 | Ruangan kosong ditutup setelah 60 detik. Pemain tidak aktif 120 detik dikeluarkan | P2 |
| FR-ROM-05 | Versi build klien harus sama dengan server. Jika tidak, tampilkan pesan "perlu memperbarui game" | P2 |
| FR-ROM-06 | Satu proses server menampung banyak objek `Room` yang terisolasi (simulasi, RNG, dan peer masing-masing). **Hipotesis awal:** 20 ruangan per task 1 vCPU dengan anggaran 0,4 ms per ruangan per tick. Angka ini wajib dibuktikan lewat uji beban | P2 |
| FR-ROM-07 | **Shard** adalah satu service ECS berisi satu task. Lobby API memilih shard aktif dengan muatan terendah. Tiap shard punya nama host sendiri (misalnya `s1.game.example.com`) lewat aturan host di ALB | P2 |

### 6.4 Lobby API

| Endpoint | Fungsi |
| --- | --- |
| `POST /v1/auth/guest` | Menukar `guest_id` dengan token JWT (berlaku 24 jam) |
| `POST /v1/rooms` | Membuat ruangan. Mengembalikan `room_code`, `ws_url`, dan `ticket` |
| `POST /v1/rooms/{code}/join` | Bergabung. Mengembalikan `ws_url` dan `ticket` |
| `GET /v1/health` | Pemeriksaan kesehatan |

- Pembatasan laju lewat throttling API Gateway: awal 10 permintaan per menit per IP untuk pembuatan ruangan.
- CORS: izinkan origin tempat itch.io menyajikan game web (domain `itch.zone`). **Verifikasi di staging.**

### 6.5 Autentikasi

- **Login tamu:** klien membuat `guest_id` (UUID v4) sekali, menyimpannya di save, dan menukarnya dengan JWT.
- **Ticket:** JWT pendek (60 detik) berisi `room_code`, `shard_id`, dan slot pemain. Server memverifikasinya pada pesan **AUTH pertama** dalam 5 detik. Ticket tidak ditaruh di URL agar tidak muncul di log.
- Kunci penandatanganan (HS256) disimpan di Secrets Manager. Akun dan login sosial menyusul di Fase 3.

### 6.6 Model data (DynamoDB, kapasitas on-demand)

| Tabel | Kunci | Atribut utama |
| --- | --- | --- |
| `Rooms` | PK `room_code` | `shard_id`, `status`, `players`, `build_version`, `created_at`, `ttl` |
| `Shards` | PK `shard_id` | `status` (active, draining, offline), `host`, `rooms`, `players`, `capacity`, `updated_at`, `ttl` 30 detik |
| `Guests` | PK `guest_id` | `created_at`, `last_seen`, referensi cloud save (Fase 3) |

### 6.7 Validasi dan anti-curang

- Server memvalidasi semua input: rentang nilai, laju, kepemilikan item, kemampuan melempar item tertentu.
- Skor di mode online dihitung server. Skor mode offline dipercaya dari klien dan tidak dipakai untuk papan skor.
- Ukuran pesan maksimal 1 KB. Batas 90 pesan per detik per koneksi. Koneksi yang melanggar diputus.

## 7. Infrastruktur AWS

### 7.1 Layanan

| Layanan | Fungsi | Catatan |
| --- | --- | --- |
| Route 53 dan ACM | Domain dan sertifikat TLS wildcard | Wajib untuk `wss://` |
| Application Load Balancer | Terminasi TLS, WebSocket, aturan host per shard | Atur idle timeout di atas interval ping (klien ping tiap 20 detik) |
| ECS Fargate | Menjalankan server Godot headless, satu service per shard | Awal 1 vCPU dan 2 GB sebagai hipotesis, atur dari hasil uji beban |
| ECR | Menyimpan image server | Dipush CI |
| API Gateway dan Lambda | Lobby API | Node.js atau Python |
| DynamoDB | Ruangan, shard, tamu | On-demand |
| Secrets Manager | Kunci JWT | Tidak ada kredensial AWS di klien |
| CloudWatch | Log, metrik, alarm, dasbor | Log berformat JSON |
| AWS Budgets | Alarm biaya di 50, 80, 100 persen | Wajib sejak hari pertama |
| WAF | Perlindungan tambahan di ALB dan API | P2 |

Perlindungan DDoS dasar AWS Shield Standard sudah aktif otomatis untuk semua pelanggan AWS.

### 7.2 Jaringan dan lingkungan

- VPC di 2 Availability Zone. ALB di subnet publik.
- **Keputusan terbuka:** task di subnet publik dengan security group yang hanya menerima trafik dari ALB (lebih hemat, tanpa NAT) atau di subnet privat dengan NAT atau VPC endpoint (lebih aman, lebih mahal).
- Lingkungan: **dev, staging, prod** sebagai stack CDK terpisah. Akun AWS terpisah per lingkungan disarankan (P1).

### 7.3 Operasional shard

- Godot headless tidak melayani HTTP biasa di port WebSocket. Sediakan **endpoint kesehatan** terpisah (`GET /health` di port 8081 lewat `TCPServer` kecil) untuk health check ALB dan ECS.
- **Deploy tanpa memutus pemain:** set shard ke `draining` (tidak menerima ruangan baru), tunggu ruangan habis (maksimal 15 menit), lalu ganti task.
- Metrik wajib: `rooms_active`, `players_online`, `tick_ms_p95`, `rtt_ms_p50` dan `p95`, `disconnect_rate`, `error_rate`. Alarm bila `tick_ms_p95` melewati anggaran atau shard kehilangan heartbeat.
- Biaya dikendalikan dengan jumlah shard minimum 1 di luar jam ramai dan evaluasi autoscaling setelah ada data pemakaian nyata.

## 8. Build, Rilis, dan itch.io

### 8.1 Preset ekspor

| Preset | Pengaturan penting | Hasil |
| --- | --- | --- |
| Windows 64-bit | x86\_64, PCK ditanam di .exe, ikon dan info versi diisi | Zip berisi .exe |
| Web | Renderer Compatibility, `variant/thread_support=false`, Extensions Support mati, shell HTML kustom (kanvas pas layar, layar muat, gerbang "Klik untuk mulai") | Folder berisi `index.html` yang di-zip dengan `index.html` di level teratas |
| Linux server | Export Mode **dedicated server** (aset visual dibuang, feature tag `dedicated_server`) | Binary untuk image Docker (Fase 2) |

### 8.2 Persyaratan khusus web

| ID | Persyaratan | Prio |
| --- | --- | --- |
| FR-WEB-01 | Gerbang "Klik untuk mulai" sebelum audio diputar, karena browser memblokir audio otomatis | P0 |
| FR-WEB-02 | Tombol layar penuh memakai API fullscreen browser. Layar "klik untuk fokus" agar tombol Spasi dan panah tidak menggulir halaman | P0 |
| FR-WEB-03 | Kode tidak boleh memakai fitur yang tidak ada di web: raw TCP/UDP, ENet, `OS.execute`, GDExtension native | P0 |
| FR-WEB-04 | Audio dalam format Ogg Vorbis. Jumlah file total di bawah 1.000 | P0 |
| FR-WEB-05 | Target internal ukuran build web 100 MB atau kurang (batas itch.io lebih longgar, tapi muat lebih cepat). **Ukur sejak M0** | P0 |
| FR-WEB-06 | Perangkat seluler tidak didukung. Tampilkan pesan jelas bila halaman dibuka di ponsel | P1 |
| FR-WEB-07 | Game wajib diuji pada halaman itch.io yang **sudah terbit** (bukan hanya server lokal), minimal di Chrome, Firefox, Edge, dan Safari desktop | P0 |

### 8.3 Alur rilis ke itch.io

1. Buat halaman proyek. Build web diset sebagai **HTML** ("dimainkan di browser"), build Windows sebagai file unduhan.
2. Dorong build lewat **butler** ke channel terpisah, misalnya `windows` dan `web`, dengan nomor versi (`--userversion`).
3. Ukuran tampilan web diset kelipatan viewport dasar, awal 960x540 dengan tombol layar penuh.
4. Untuk uji, atur halaman ke **Restricted** dengan kata sandi atau mode draf sebelum dipublikasikan.
5. Versi memakai pola `major.minor.patch+build`. Versi tampil di menu utama dan dicek oleh server online.

### 8.4 Pipeline CI/CD (GitHub Actions)

| Tahap | Isi |
| --- | --- |
| 1. Lint | `gdlint` dan `gdformat --check` (gdtoolkit) |
| 2. Tes | Unit test dan tes simulasi headless (GUT atau gdUnit4) |
| 3. Export | Image Docker dengan Godot dan export template **versi terkunci**, lalu export Windows, Web, dan server |
| 4. Artefak | Simpan hasil build per commit |
| 5. Deploy staging | Build web ke halaman itch.io terbatas. Fase 2: image server ke ECR dan deploy CDK ke staging |
| 6. Smoke test | Tes otomatis muat game dan buat ruangan (Fase 2) |
| 7. Rilis prod | Persetujuan manual, lalu `butler push` ke channel produksi. Fase 2: deploy shard dengan alur draining |

## 9. Persyaratan Non-Fungsional

| ID | Persyaratan | Target | Prio |
| --- | --- | --- | --- |
| NFR-PRF-01 | Frame rate desktop | 60 FPS di GPU terintegrasi, 1080p | P0 |
| NFR-PRF-02 | Frame rate web | 60 FPS di Chrome dan Firefox, laptop kelas menengah | P0 |
| NFR-PRF-03 | Memori web | 512 MB atau kurang | P0 |
| NFR-PRF-04 | Waktu muat | Web 15 detik atau kurang (20 Mbps). Desktop 5 detik ke menu utama | P0 |
| NFR-PRF-05 | Latensi input lokal | 3 frame (50 ms) atau kurang dari tombol ke layar | P0 |
| NFR-PRF-06 | Anggaran tick server | 0,4 ms atau kurang per ruangan per tick (hipotesis, diuji di M5) | P2 |
| NFR-CMP-01 | Kompatibilitas | Windows 10 dan 11 (64-bit) dengan GPU yang mendukung OpenGL 3.3. Browser desktop modern dengan WebGL 2 | P0 |
| NFR-ACC-01 | Aksesibilitas | Remap tombol, Bantuan bidik, opsi mematikan guncangan layar, ukuran teks, kontras tinggi | P0 |
| NFR-ACC-02 | Penanda bidik tidak bergantung warna saja: hijau, kuning, merah juga dibedakan bentuk (lingkaran penuh, setengah, silang) | P0 |  |
| NFR-ACC-03 | Suara penting (monster marah, peringatan serangan) punya isyarat visual yang setara | P0 |  |
| NFR-LOC-01 | Semua teks lewat kunci terjemahan. Bahasa Indonesia default, Inggris menyusul. Font pixel harus mendukung karakter Latin | P0 |  |
| NFR-SEC-01 | Hanya HTTPS dan WSS. Tidak ada rahasia atau kredensial AWS di klien. Kunci di Secrets Manager | P2 |  |
| NFR-PRV-01 | Tidak mengumpulkan data pribadi. ID tamu acak. Telemetri hanya dengan persetujuan. Siapkan kebijakan privasi sederhana (sebaiknya ditinjau ahli hukum sehubungan UU Pelindungan Data Pribadi) | P0 |  |
| NFR-REL-01 | Crash tidak merusak save. Task server yang mati dijalankan ulang otomatis oleh ECS | P0 |  |

## 10. Strategi Pengujian

| Lapisan | Isi |
| --- | --- |
| Unit test | Sim: rumus lempar, skor, kesabaran, kuali tumpah, validasi resep, migrasi save |
| Tes simulasi headless | Replay rekaman input pada level tertentu dan bandingkan skor dan state akhir (uji determinisme) |
| Tes kesetaraan lempar | Pratinjau klien dan hasil simulasi harus identik untuk ribuan kombinasi arah dan jarak |
| Tes level | Tiap level dimainkan oleh bot sederhana untuk memastikan bisa diselesaikan |
| Uji jaringan (Fase 2) | Bot klien headless, 20 ruangan paralel, latensi buatan 50, 150, 300 ms dengan jitter, putus-sambung, deploy dengan draining |
| Matriks perangkat | Laptop spesifikasi rendah dan tinggi, Chrome, Firefox, Edge, Safari, gamepad bergaya Xbox dan PlayStation |
| Playtest | M2: rasa kuali dan lempar. M3: kurva kesulitan. Beta: seluruh alur dan tutorial |

**Kriteria rilis:** tidak ada bug P0 yang terbuka, tutorial bisa diselesaikan pemain baru tanpa bantuan di playtest, semua level bisa diselesaikan, build web diuji di halaman itch.io terbit, dan tidak ada kehilangan save pada pembaruan.

## 11. Telemetri (opsional, dengan persetujuan)

| Peristiwa | Kegunaan |
| --- | --- |
| `level_start`, `level_end` (hasil, skor, bintang, durasi) | Kurva kesulitan |
| `fail_reason` (Hati Dapur habis, skor kurang) | Mencari level yang terlalu sulit |
| `throw_result` (Jitu, Tersaji, Meleset, Mengenai monster, Meja salah) | Menyetel zona saji dan jarak |
| `tutorial_step` (selesai, lewati, tersangkut) | Titik tutorial yang membingungkan |
| `spill_event` (kuali tumpah) | Mengukur dampak Kuali Dua Mode |

Pipeline (P2): API Gateway, Lambda, Firehose, S3, Athena. Rilis 1.0 boleh tanpa telemetri.

## 12. Risiko

| Risiko | Dampak | Mitigasi |
| --- | --- | --- |
| Audio atau performa web tersendat pada single-thread | Pengalaman web buruk | Profil sejak M0, batasi partikel, pakai Ogg, uji di halaman itch.io |
| Lempar terasa tidak adil atau sulit | Frustrasi, inti mekanik gagal | Playtest di M2, semua parameter berbasis data, Bantuan bidik, zona saji tutorial yang melebar |
| Latensi online di web (WebSocket berbasis TCP) | Gerakan tersendat | Prediksi lokal, buang snapshot lama, uji RTT 150 sampai 300 ms |
| Aturan itch.io atau browser berubah (SharedArrayBuffer, batas ukuran) | Build web gagal | Tetap single-thread, cek dokumentasi tiap milestone, uji halaman terbit |
| Server multi-ruangan kelebihan beban | Tick melambat | Uji beban dini, anggaran tick, penambahan shard |
| Ruang lingkup membengkak (19 level, 12 hazard, 5 monster) | Jadwal molor | Konten berbasis data, prototipe Stage 1 dulu, daftar potong disepakati sejak awal |
| Biaya AWS tak terduga | Anggaran | AWS Budgets, shard minimum 1, draining dan penjadwalan |
| Keyboard berbagi dua pemain (ghosting tombol) | Co-op lokal bermasalah | Skema P2 diuji, sarankan gamepad |
| Fakta teknis berubah (versi Godot, layanan AWS, kebijakan itch.io) | Rencana usang | Cek ulang di awal tiap milestone |

## 13. Milestone dan Estimasi

Estimasi memakai asumsi tim kecil: 2 programmer, 2 seniman pixel, dan 1 desainer atau QA paruh waktu. Sesuaikan dengan tim yang sebenarnya.

| Milestone | Durasi | Isi | Kriteria selesai |
| --- | --- | --- | --- |
| M0 Persiapan | 2 minggu | Repo, CI, proyek Godot, layout 480x270, ekspor uji Windows dan web ke itch.io, peta input | Build kosong berjalan di itch.io |
| M1 Prototipe Stage 1 | 6 minggu | Koki, item, stasiun dasar, Goblin, Kuali Dua Mode, 1 pemain dan 2 pemain lokal, level 1-1 sampai 1-4 | Stage 1 bisa dimainkan dan ditamatkan |
| M2 Vertical slice | 4 minggu | Mekanik lempar, T-1 sampai T-5, skill Dash, HUD, playtest pertama | Playtest: pemain baru lolos tutorial tanpa bantuan |
| M3 Konten stage 2 sampai 5 | 12 minggu | Monster, resep, hazard, skill lain, combo, boss, cerita | Semua 19 level bisa ditamatkan |
| M4 Polish dan Rilis 1.0 | 4 minggu | Audio, penyeimbangan, save, aksesibilitas, QA, halaman itch.io | Rilis 1.0 (Windows dan web) |
| M5 Online beta | 6 minggu | Server headless, lobby API, CDK, uji beban | 20 ruangan paralel stabil di staging |
| M6 Online rilis | 4 minggu | Pengerasan, observabilitas, alarm, rilis online | Co-op online terbuka untuk umum |

Total sekitar 28 minggu sampai Rilis 1.0 dan 38 minggu sampai online.

## 14. Pertanyaan Terbuka

- [ ] Skema keyboard untuk P2 pada co-op lokal.
- [ ] Persetujuan **skill\_2** (tombol R dan trigger kanan) sebagai penyesuaian dari tabel kontrol GDD.
- [ ] Ukuran piksel final: tetap tile 16x16 dengan 480x270 (usulan), atau 32x32 dengan 640x360.
- [ ] Region AWS final dan hasil pengecekan ketersediaan layanan di Jakarta, atau pakai Singapura.
- [ ] Subnet publik atau privat untuk task Fargate.
- [ ] Game gratis atau berbayar di itch.io, dan anggaran bulanan AWS yang boleh dipakai.
- [ ] Cukup login tamu untuk online, atau akun diperlukan sebelum Fase 3.
- [ ] Telemetri dipakai di Rilis 1.0 atau ditunda.
- [ ] Ukuran tim dan jadwal sebenarnya.

## Lampiran A. Konstanta Awal

Semua nilai ini disimpan di file data dan dapat disetel.

| Konstanta | Nilai awal |
| --- | --- |
| Tick simulasi | 60 Hz |
| Kecepatan koki | 5 tile per detik |
| Jarak Dash, cooldown | 4 tile, 6 detik |
| Buff Kecepatan | +40 persen, 5 detik, cooldown 15 detik |
| Teleport cooldown | 8 detik |
| Buff Api | 2x, 8 detik, cooldown 20 detik |
| Jendela combo, cooldown combo | 3 detik, 30 detik |
| Waktu tunggu monster | Goblin 40, Kadal 50, Ogre 60, Hantu 60 detik |
| Durasi amukan | 10 detik |
| Hati Dapur | 5 |
| Pukulan sutil, kuali | Hitbox 1,2 dan 1,6 tile, cooldown 0,4 dan 0,8 detik |
| Kunci kuali setelah memukul | 4 detik |
| Jarak bidik, waktu naik | 2 sampai 8 tile, 1,2 detik |
| Waktu terbang lemparan | 0,4 sampai 0,9 detik |
| Zona saji, area Jitu | 2x1 tile, 16x16 piksel |
| Hukuman meleset | Kesabaran -15 (lantai), -25 (mengenai monster), -10 (meja salah) |
| Kecepatan input, snapshot | 30 Hz, 20 Hz |
| Jendela sambung ulang | 30 detik |
