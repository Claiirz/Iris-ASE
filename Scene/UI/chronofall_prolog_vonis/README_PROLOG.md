# CHRONOFALL — Prolog Storyboard & Layar Vonis Pack v0.1

Basis: GDD v0.7.6 section 2 (Naskah Prolog, Vonis) + section 7 (Checklist Balancing). Status: **placeholder / target komposisi**. Art final tetap di Game Artist; nama file & ukuran (640×360) dipertahankan supaya bisa ditimpa langsung.

## 1. Urutan tampil
Panel 1 → 2 → 3 → 4 → 5 (fade to black) → **Layar Vonis** → Panel 6 → Hub (run #1)

## 2. Panel (sprites/, semua 640×360, art bersih tanpa teks)
| File | Isi | Caption (dirender Godot, bukan dibakar ke gambar) |
|---|---|---|
| panel_01.png | Bengkel malam, Nael sendirian, rangka cincin (calon portal) di belakang | — |
| panel_02.png | Close-up alat, cahaya cyan bocor ke jendela | "Ia pikir tak ada yang melihat." |
| panel_03.png | POV luar: aparat di pintu, Nael berlutut diborgol, alat dibawa pergi | — |
| panel_04.png | Ruang sidang, hakim raksasa backlit, Nael kecil di bawah sorot cahaya | Hakim: "Riset ilegal manipulasi waktu. Vonis: pengasingan." |
| panel_05.png | Nael tertunduk, kepalan terborgol, patch bengkel di coverall | — (lalu fade to black) |
| panel_06.png | Digiring ke cincin portal, siluet larut ke cahaya | — |
| letterbox_overlay.png | Bar hitam atas 28 px, bawah 40 px | Caption ditaruh di bar bawah |

Kenapa caption tidak dibakar ke gambar: supaya teks bisa diedit, diterjemahkan, atau diberi efek ketik tanpa menggambar ulang panel.

### Saran implementasi (keputusan akhir di programmer)
- 1 scene `Prolog.tscn`: `TextureRect` (panel) + `TextureRect` (letterbox) + `Label` (caption, pixel font) + `ColorRect` hitam untuk fade.
- `AnimationPlayer`: tiap panel fade-in 0.4 s → tahan 2.5–3.5 s → lanjut; tombol Enter/klik = skip ke panel berikutnya; tombol Esc = skip seluruh prolog.
- Efek murah opsional: zoom pelan 100% → 103% di panel 2 & 6 (Ken Burns), shake kecil 2 px di panel 3, glow portal "bernapas" di panel 6.
- Panel 5 → fade to black → ganti scene ke Layar Vonis; setelah vonis dipilih → Panel 6 → Hub.

## 3. Layar Vonis (sprites/)
| File | Ukuran | Pakai |
|---|---|---|
| vonis_bg.png | 640×360 | Background (panel 4 digelapkan, hakim tetap membayangi) |
| vonis_card.png | 164×214 | Kertas putusan kosong, teks & ikon diisi Godot |
| vonis_card_focus.png | 174×224 | Braket cyan kartu terpilih, posisi (-5, -5) dari kartu |
| stamp_ringan / sedang / berat.png | ±60×60 | Cap merah angka romawi I / II / III, pojok kanan bawah kartu |
| icon_enemy_swarm.png | 16×16 | Baris "Musuh" (spawn rate) |
| pip_on.png / pip_off.png | 7×7 | Indikator 1–3 tingkat |
| tag_ribbon.png | 70×13 | Pita "DISARANKAN" di kartu Sedang |

Ikon lain dipakai ulang dari HUD pack: icon_hp, icon_nemesis_hunting, icon_echo. Tombol "TERIMA VONIS" pakai btn_*_9slice dari Main Menu pack.

### Isi kartu (sinkron dengan Checklist Balancing section 7)
| Baris | Ringan | Sedang | Berat | Sumber angka |
|---|---|---|---|---|
| Nyawa awal | 130 | 100 | 75 | HP Awal |
| Nemesis (pip) | 1 | 2 | 3 | Threat Meter +0.7 / +1 / +1.4 per detik |
| Musuh (pip) | 1 | 2 | 3 | Spawn 1/10 s, 1/8 s, 1/6 s |
| Bonus Echo | +0 | +5 | +10 | Vonis Bonus (SCRUM-114) |

Prinsip: pemain lihat angka yang langsung dia rasakan (HP, bonus), sedangkan parameter teknis (kecepatan Threat, spawn rate) ditampilkan sebagai tingkat relatif, bukan angka desimal.

### Perilaku
| Kondisi | Perilaku |
|---|---|
| Masuk layar | Fokus default di Sedang (pita DISARANKAN) |
| A/D atau ←/→ | Pindah kartu; kartu terpilih naik 6 px + braket cyan, sisanya diredupkan |
| Enter / TERIMA VONIS | Simpan vonis → Panel 6 |
| Setelah dipilih | Vonis tetap sampai New Game (sesuai E.4 node #1–#2) |

## 4. Regenerate
`python3 build_prolog.py` (butuh Pillow; memakai build_hud.py, dan tombol dari menu/ kalau ada).
