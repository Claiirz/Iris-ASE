"""CHRONOFALL — Pause Menu placeholder (pixel art 1x, layar logis 640x360)."""
import runpy, os, math
from PIL import Image, ImageDraw, ImageFont
ROOT = os.path.dirname(os.path.abspath(__file__))
H = runpy.run_path(os.path.join(ROOT, 'build_hud.py'))
C, new, px, add_outline, add_glow, shade, bevel_frame, nine, text, FONT = (H[k] for k in
    ('C','new','px','add_outline','add_glow','shade','bevel_frame','nine','text','FONT'))
K, ST_HI, ST_LO, ST_HI2, ST_LO2, CY, CY_H, CY_D = (H[k] for k in ('K','ST_HI','ST_LO','ST_HI2','ST_LO2','CY','CY_H','CY_D'))
HS = H['saved']; FONT['?'] = "111001011000010"; FONT[','] = "000000000010100"
OUT = os.path.join(ROOT, 'pause'); SPR = os.path.join(OUT, 'sprites'); MOCK = os.path.join(OUT, 'mockup')
os.makedirs(SPR, exist_ok=True); os.makedirs(MOCK, exist_ok=True)
MS = os.path.join(ROOT, 'menu', 'sprites')
def LM(n): return Image.open(os.path.join(MS, n + '.png')).convert('RGBA')
BTN = {s: LM(f'btn_{s}_9slice') for s in ('normal', 'hover', 'pressed', 'disabled', 'focus')}
ARROW = LM('selector_arrow')
VW, VH = 640, 360
S = {}
def save(n, img): img.save(os.path.join(SPR, n + '.png')); S[n] = img; return img

def text2(img, x, y, s, col, sh=True):
    for i, ch in enumerate(s.upper()):
        g = FONT.get(ch, FONT[' '])
        for r in range(5):
            for c in range(3):
                if g[r*3+c] == '1':
                    bx, by = x + i*8 + c*2, y + r*2
                    for dx in range(2):
                        for dy in range(2):
                            if sh: px(img, bx+dx+1, by+dy+1, K)
                            px(img, bx+dx, by+dy, col)
def t2w(s): return len(s)*8 - 2
def t1w(s): return len(s)*4 - 1

# ================= ASET =================
# Panel jeda 24x24 (9-slice margin 6): bingkai batu 2 ring + rune cyan di sudut
pp = bevel_frame(24, 24, [(ST_HI, ST_LO), (ST_HI2, ST_LO2)])
for y in range(4, 20):
    for x in range(4, 20): px(pp, x, y, (22, 19, 16, 236))
for (x, y) in ((4, 4), (5, 4), (4, 5), (19, 4), (18, 4), (19, 5), (4, 19), (5, 19), (4, 18), (19, 19), (18, 19), (19, 18)):
    px(pp, x, y, CY_D)
save('pause_panel_9slice', pp)
# Plat judul 16x16 (9-slice margin 4): lintel batu dengan titik rune cyan
tp = bevel_frame(16, 16, [(C('6a5a44'), C('2a231c'))])
for y in range(3, 13):
    for x in range(3, 13): px(tp, x, y, C('3a3128') if (x + y) % 5 else C('443a2e'))
for x in range(3, 13, 3): px(tp, x, 12, CY)
save('pause_title_plate_9slice', tp)
# Pembatas 64x3
dv = new(64, 3)
for x in range(2, 62): px(dv, x, 1, C('4c4033') if x % 2 else C('3a3128'))
for (x, y) in ((31, 0), (32, 0), (30, 1), (31, 1), (32, 1), (33, 1), (31, 2), (32, 2)): px(dv, x, y, CY)
save('pause_divider', dv)

# Ikon 16x16
def icon_pause():
    im = new(16, 16); d = ImageDraw.Draw(im)
    for x0 in (4, 9):
        d.rectangle([x0, 3, x0 + 2, 12], fill=C('e8dcc0')); d.line([x0, 3, x0, 12], fill=C('fff6e0')); d.line([x0 + 2, 3, x0 + 2, 12], fill=C('a89e84'))
    return add_outline(im)
def icon_clock():
    im = new(16, 16); d = ImageDraw.Draw(im)
    d.ellipse([2, 2, 13, 13], fill=C('c8bca0')); d.ellipse([3, 3, 12, 12], fill=C('2a2420'))
    for (x, y) in ((7, 3), (12, 7), (7, 12), (3, 7)): px(im, x, y, C('c8bca0'))
    d.line([7, 7, 7, 4], fill=CY); d.line([7, 7, 10, 9], fill=CY_H); px(im, 7, 7, C('ffffff'))
    return add_outline(im)
def icon_gavel():
    im = new(16, 16); d = ImageDraw.Draw(im)
    d.line([4, 12, 10, 6], fill=C('8a5a30'), width=2)
    d.polygon([(7, 3), (10, 0 + 1), (14, 5), (11, 8)], fill=C('b8824a')); d.line([7, 3, 11, 8], fill=C('5a3a1e')); d.line([10, 1, 14, 5], fill=C('e0b070'))
    d.rectangle([1, 13, 8, 14], fill=C('5a3a1e'))
    return add_outline(im)
def icon_era():
    im = new(16, 16); p = im.load()
    for y in range(16):
        for x in range(16):
            dd = math.hypot((x - 7.5) / 5.6, (y - 7.5) / 6.8)
            if 0.78 < dd < 1.0: p[x, y] = C('6a6250')
            elif dd <= 0.78: p[x, y] = CY_H if dd < 0.3 else (CY if dd < 0.55 else CY_D)
    return add_outline(im)
for n, fn in (('icon_pause', icon_pause), ('icon_clock', icon_clock), ('icon_vonis', icon_gavel), ('icon_era', icon_era)): save(n, fn())

# ================= MOCKUP =================
BG = Image.open(os.path.join(ROOT, 'mockup', 'mockup_A_explore_fase_tengah_640x360.png')).convert('RGBA')
def dimmed():
    g = BG.copy(); p = g.load()
    for y in range(VH):
        for x in range(VW):
            r, gg, b, a = p[x, y]; v = int(r*.3 + gg*.59 + b*.11)
            p[x, y] = (int(r*.35 + v*.65), int(gg*.35 + v*.65), int(b*.35 + v*.65), 255)
    g.alpha_composite(new(VW, VH, (6, 6, 8, 165)))
    return g
TXT = {'normal': C('d8ccb0'), 'hover': C('ffffff'), 'pressed': C('b8ac90')}
def button(img, x, y, w, label, state, focus=False, danger=False):
    img.alpha_composite(nine(BTN[state], w, 22, 4), (x, y))
    if focus: img.alpha_composite(nine(BTN['focus'], w + 4, 26, 4), (x - 2, y - 2))
    col = TXT[state] if not danger else (C('ffb0a0') if state == 'hover' else C('e08a7a'))
    text2(img, x + 14, y + 6, label, col)
    if state == 'hover': img.alpha_composite(ARROW, (x - 12, y + 7))
def title_plate(img, cx, y, s):
    w = t2w(s) + 40; img.alpha_composite(nine(S['pause_title_plate_9slice'], w, 22, 4), (cx - w//2, y))
    img.alpha_composite(S['icon_pause'], (cx - w//2 + 6, y + 3)); text2(img, cx - w//2 + 26, y + 6, s, C('ffffff'))

LX, LY, LW, PH = 132, 96, 168, 168
RX, RW = LX + LW + 12, 196
STATS = [('icon_vonis', 'VONIS', 'SEDANG', C('e8dcc0')), ('icon_era', 'ERA', '2', C('e8dcc0')), ('icon_clock', 'WAKTU', '02:14', C('e8dcc0')),
         ('icon_fragment', 'FRAGMENT', '3/8', CY_H), ('icon_echo', 'ECHO JIKA BERAKHIR', '24', C('c8c0ff'))]
def pause_screen(sel=0, dialog=False):
    img = dimmed()
    img.alpha_composite(nine(S['pause_panel_9slice'], LW, PH, 6), (LX, LY))
    title_plate(img, LX + LW//2, LY - 11, "PAUSED")
    labels = ("RESUME", "SETTINGS", "ABANDON RUN")
    for i, l in enumerate(labels):
        st = 'pressed' if (dialog and i == 2) else ('hover' if i == sel and not dialog else 'normal')
        button(img, LX + 20, LY + (PH - 82)//2 + 6 + i*30, LW - 40, l, st, focus=(i == sel), danger=(i == 2))
    img.alpha_composite(nine(S['pause_panel_9slice'], RW, PH, 6), (RX, LY))
    text(img, RX + 14, LY + 14, "RUN INFO", C('a89e84'))
    img.alpha_composite(nine(S['pause_divider'], RW - 28, 3, 2) if False else S['pause_divider'].resize((RW - 28, 3), Image.NEAREST), (RX + 14, LY + 22))
    for i, (ic, lab, val, col) in enumerate(STATS):
        y = LY + 32 + i*25
        src = S.get(ic) or HS[ic]; img.alpha_composite(src, (RX + 12, y))
        text(img, RX + 32, y + 6, lab, C('a89e84'))
        text2(img, RX + RW - 14 - t2w(val), y + 3, val, col)
    text(img, RX + 14, LY + PH - 14, "THREAT METER DIBEKUKAN SELAMA JEDA.", C('6a6458'))
    hint = "ESC RESUME   W/S PILIH   ENTER OK"; text(img, (VW - t1w(hint))//2, LY + PH + 12, hint, C('8a8270'))
    if dialog:
        img.alpha_composite(new(VW, VH, (4, 4, 3, 150)))
        DW, DH = 268, 110; dx, dy = (VW - DW)//2, (VH - DH)//2
        img.alpha_composite(nine(S['pause_panel_9slice'], DW, DH, 6), (dx, dy))
        t = "ABANDON RUN?"; text2(img, dx + (DW - t2w(t))//2, dy + 14, t, C('ffb0a0'))
        for i, (l, c) in enumerate((("RUN DIHITUNG KALAH, KEMBALI KE HUB.", C('c8bca0')), ("ECHO TETAP DIDAPAT: 24", C('c8c0ff')))):
            text(img, dx + (DW - t1w(l))//2, dy + 36 + i*10, l, c)
        bw = 92
        for j, (l, st) in enumerate((("CANCEL", 'hover'), ("YES", 'normal'))):
            x = dx + 22 + j*(bw + 40); y = dy + DH - 34
            img.alpha_composite(nine(BTN[st], bw, 22, 4), (x, y))
            text2(img, x + (bw - t2w(l))//2, y + 6, l, TXT[st])
        img.alpha_composite(ARROW, (dx + 10, dy + DH - 27))
    return img
A = pause_screen(0); B = pause_screen(2, dialog=True)
for n, im in (('pause_A_utama', A), ('pause_B_konfirmasi_abandon', B)):
    im.save(os.path.join(MOCK, n + '_640x360.png')); im.resize((1280, 720), Image.NEAREST).save(os.path.join(MOCK, n + '_1280x720.png'))

# preview aset
FB = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 20); FT = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 15)
items = [('pause_panel_9slice', 6), ('pause_title_plate_9slice', 6), ('pause_divider', 6), ('icon_pause', 6), ('icon_clock', 6), ('icon_vonis', 6), ('icon_era', 6)]
W = 1400; sh = Image.new('RGBA', (W, 330), C('171411')); d = ImageDraw.Draw(sh)
d.text((20, 16), "CHRONOFALL — Pause Menu: aset baru (placeholder)", font=FB, fill=C('39e0e8')); x = 20
for n, s in items:
    im = S[n].resize((S[n].width*s, S[n].height*s), Image.NEAREST)
    ck = Image.new('RGBA', im.size, C('2a2622')); ck.alpha_composite(im); sh.alpha_composite(ck, (x, 60))
    d.text((x, 60 + im.height + 6), f"{n}.png", font=FT, fill=C('c8bca0')); d.text((x, 80 + im.height + 6), f"{S[n].width}x{S[n].height}", font=FT, fill=C('8a8070'))
    x += max(im.width, 150) + 30
sh.save(os.path.join(OUT, 'preview_pause_assets.png'))
print('ok')
