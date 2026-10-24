# CHRONOFALL — Main Menu Placeholder Pack v0.1

Basis: GDD v0.7.6 section 6 (Menu) + Lampiran E.4 node #1. Status: **placeholder / target gaya**. Art final tetap di Game Artist; nama file & ukuran dipertahankan supaya bisa ditimpa langsung.
Resolusi logis 640×360, scale 2x ke 1280×720 (setting project sama dengan HUD pack).

## 1. Daftar aset

### Logo & teks
| File | Ukuran | Pakai |
|---|---|---|
| title_logo.png | 244×45 | `TextureRect` di (40, 46). Huruf O pertama = portal waktu (cyan), "FALL" sedikit turun |

### Tombol — `StyleBoxTexture` di Theme (semua 9-slice 16×16, **texture margin 4 di semua sisi**)
| File | State Button |
|---|---|
| btn_normal_9slice.png | `normal` |
| btn_hover_9slice.png | `hover` (aksen cyan di kiri) |
| btn_pressed_9slice.png | `pressed` (bevel terbalik, terasa "ketekan") |
| btn_disabled_9slice.png | `disabled` (Continue saat belum ada save) |
| btn_focus_9slice.png | `focus` (braket cyan, untuk navigasi keyboard/gamepad) |
| selector_arrow.png (6×7) | Muncul di kiri tombol yang di-hover/focus |
| dialog_panel_9slice.png | `NinePatchRect` margin 4, panel konfirmasi |

Ukuran tombol di mockup: 128×22, jarak antar tombol 6 px, isi teks padding kiri 14 px. Warna teks: normal #d8ccb0, hover #ffffff, pressed #b8ac90, disabled #5e574e.

### Background — berlapis biar bisa dianimasikan (semua 640×360, kecuali disebut)
Urutan dari belakang ke depan:
1. bg_01_sky.png — langit malam + pendaran lava di horizon
2. bg_02_mountains.png — pegunungan + gunung berapi
3. bg_03_jungle.png — siluet pakis raksasa
4. bg_05b_portal_glow.png — glow portal (**CanvasItemMaterial blend = Add**, animasikan `modulate` alpha pelan = "napas" portal)
5. bg_04_ruins.png — gerbang reruntuhan + tanah
6. bg_05_portal.png — pusaran portal (bisa diputar pelan / di-shader)
7. nael_silhouette.png (10×15) — di (425, 286), Nael membelakangi pemain menatap portal
8. nemesis_eyes_open.png / _closed.png (18×8) — di (560, 258), kedip acak tiap beberapa detik (teaser pilar One Enemy)
9. bg_06_foreground.png — daun depan sebagai bingkai
10. bg_07_legibility_gradient.png — gelap di kiri supaya tombol terbaca

Bonus: bg_full_flattened.png = semua layer digabung (kalau belum mau animasi).

Ide animasi murah (opsional): parallax kecil ikut posisi mouse (layer 2–3 geser 1–3 px), glow portal "bernapas", mata Nemesis kedip. Semua bisa pakai `AnimationPlayer`, tanpa aset tambahan.

## 2. Perilaku menu (aturan desain)
| Kondisi | Perilaku |
|---|---|
| Belum ada save | Continue = disabled, focus awal di Start (mockup A) |
| Sudah ada save | Continue aktif, focus awal di Continue (mockup B) |
| Start saat save ada | Muncul dialog konfirmasi, default focus di CANCEL (mockup C) |
| Start saat belum ada save | Langsung ke Prolog → Layar Vonis (E.4 #2) |
| Continue | Langsung ke Hub (skip Vonis) |
| Quit | Tutup aplikasi (usulan tambahan, belum ada di GDD) |

## 3. Layout (koordinat logis)
| Elemen | Posisi |
|---|---|
| Logo | (40, 46) |
| Tagline "NOTHING IS PERMANENT." | di bawah logo |
| Kolom tombol | x 52, mulai y 138 |
| Versi + nama tim | kiri bawah |
| Hint kontrol | kanan bawah |
| Art portal | kanan (pusat x ≈ 430) |

## 4. Regenerate
`python3 build_menu.py` (butuh Pillow, memanggil build_hud.py untuk palet & helper).
