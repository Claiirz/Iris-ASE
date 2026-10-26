# CHRONOFALL — Item, Enemy & Pause Menu Pack v0.1

Status: **placeholder / target gaya**. Art final tetap di Game Artist; nama file & ukuran dipertahankan supaya bisa ditimpa langsung.
Semua sprite 1x, untuk layar logis 640×360 yang di-scale 2x (setting project sama dengan HUD pack: filter Nearest).

---

## 1. Item (items_enemies/sprites/items/, semua 32×32)

| File | Isi |
|---|---|
| item_anvil.png | Landasan besi, ada sedikit karat |
| item_boots.png | Sepatu kerja kulit (steel-toe), tali krem |
| item_crowbar.png | Linggis cat merah, ujung besi terkelupas |
| item_cutter_gloves.png | Sepasang sarung tangan anti-potong: rajutan abu-abu, ujung jari berlapis grip, manset kuning |
| item_guitar.png | Gitar akustik kayu |

**Catatan desain:** kelima item ini **belum ada di GDD v0.7.6**. Ukuran 32×32 dipilih untuk ikon UI (Hub / inventory / pause). Kalau item juga muncul sebagai pickup di arena, versi 16×16 sebaiknya dibuat setelah ukuran sprite Nael di-lock.

---

## 2. Musuh (items_enemies/sprites/enemies/)

**Aturan penting untuk programmer:** semua musuh digambar **top-down menghadap KANAN (+X)**, yaitu arah rotasi 0 di Godot. Sesuai Lampiran B GDD, sprite tunggal dirotasi lewat kode (`rotation = velocity.angle()`), bukan digambar 4 arah. Death cukup fade-out/scale-down via kode.

| Musuh | Ukuran | Frame (file `_sheet.png` = semua frame berjajar horizontal) | Data GDD |
|---|---|---|---|
| Serangga Purba | 16×16 | walk_0, walk_1 | 20 HP, 10 dmg, 1.3× speed, swarm |
| Reptil Kecil | 24×24 | walk_0, walk_1, **telegraph** (rahang terbuka, mata merah, outline merah), attack (lunge) | 45 HP, 18 dmg, 0.7× speed, ada telegraph |
| Nemesis | 64×64 | walk_0, walk_1, **telegraph** (mandibel terbuka lebar, pendar merah) | HP 100, 22 dmg, interval ±1.8 s |

Saran animasi (`AnimatedSprite2D` + `SpriteFrames`):
- walk: 2 frame, ±6 fps
- Reptil: telegraph ditahan ±0.4 s sebelum attack, supaya pemain sempat bereaksi
- Nemesis: telegraph ditahan sebelum tiap serangan (interval 1.8 s)
- Hit flash: `modulate` putih 0.08 s via kode, tanpa frame tambahan

### Mutasi Nemesis per era (visual-only, sesuai arahan mentor v0.7.0)
| File | Era | Perubahan |
|---|---|---|
| nemesis_era1_* | 1 | Palet dasar: ungu gelap + pelat merah tua |
| nemesis_era2_* | 2 | Palette swap: teal + pelat amber |
| nemesis_era3_* | 3 | Palette swap: arang + pelat oranye lava |
| nemesis_era4_* | 4 | Palette swap: abu tulang + pelat ungu |
| nemesis_era5_final_* | 5 (Ending) | **Siluet berubah**: duri samping, duri punggung lebih besar, urat energi cyan, **borgol karatan menyatu di kaki depan** (payoff twist Ending section 2) |

Era 1–4 cukup palette swap, jadi Game Artist hanya perlu menggambar 1 set frame + 1 varian final.

---

## 3. Pause Menu (pause/)

### Aset baru (pause/sprites/)
| File | Ukuran | Pakai |
|---|---|---|
| pause_panel_9slice.png | 24×24 | `NinePatchRect`, **margin 6** semua sisi |
| pause_title_plate_9slice.png | 16×16 | Plat judul "PAUSED", margin 4 |
| pause_divider.png | 64×3 | Pembatas di panel Run Info (stretch horizontal) |
| icon_pause / icon_clock / icon_vonis / icon_era.png | 16×16 | Ikon judul & baris statistik |

Dipakai ulang: tombol `btn_*_9slice` + `selector_arrow` (Main Menu pack), `icon_fragment` + `icon_echo` (HUD pack).

### Perilaku (usulan, belum ada di GDD)
| Aksi | Perilaku |
|---|---|
| ESC saat run | Buka pause, `get_tree().paused = true`. **Threat Meter, spawn, dan cooldown ikut beku** |
| RESUME / ESC lagi | Tutup pause |
| SETTINGS | Buka layar Settings yang sama dengan Main Menu |
| ABANDON RUN | Dialog konfirmasi, **default focus di CANCEL** |
| Konfirmasi YES | Run dihitung **Kalah** → Run End → Hub. Echo tetap dihitung pakai formula SCRUM-114 |

**Kenapa tidak ada "Quit to Main Menu" langsung:** run tidak punya save di tengah jalan (GDD section 7: save Echo terpisah dari state run). Keluar di tengah run = run hilang. Jadi pilihannya dibuat eksplisit sebagai "Abandon Run", dan pemain tetap dapat Echo-nya (selaras pilar *Nothing Is Permanent*). Dari Hub pemain bisa kembali ke Main Menu (E.4 node #3).

**Panel Run Info:** Vonis, Era, Waktu, Fragment x/8, dan "Echo jika berakhir" (dihitung live dari formula SCRUM-114). Contoh di mockup: 134 detik, 3 Fragment, Sedang → max(5, 13 + 6) + 5 = **24**. Angka ini membantu pemain memutuskan apakah layak menyerah atau lanjut.

Teknis: node Pause Menu perlu `process_mode = PROCESS_MODE_ALWAYS` supaya tetap jalan saat tree di-pause.

---

## 4. Regenerate
`python3 build_items_enemies.py` dan `python3 build_pause.py` (butuh Pillow; memakai build_hud.py dan menu/sprites dari pack sebelumnya).
