"""CHRONOFALL — Item icons + Enemy sprites (placeholder pixel art 1x).
Semua musuh digambar top-down menghadap KANAN (+X, rotasi 0 di Godot) supaya bisa dirotasi via kode.
"""
import runpy, os, math, random
from PIL import Image, ImageDraw, ImageFont
ROOT = os.path.dirname(os.path.abspath(__file__))
H = runpy.run_path(os.path.join(ROOT, 'build_hud.py'))
C, new, px, add_outline, add_glow, shade, lerp = (H[k] for k in ('C','new','px','add_outline','add_glow','shade','lerp'))
K, CY, CY_H, CY_D = H['K'], H['CY'], H['CY_H'], H['CY_D']
T = (0, 0, 0, 0)
OUT = os.path.join(ROOT, 'items_enemies'); SPR = os.path.join(OUT, 'sprites')
for sub in ('items', 'enemies'): os.makedirs(os.path.join(SPR, sub), exist_ok=True)
S = {}
def save(sub, n, img): img.save(os.path.join(SPR, sub, n + '.png')); S[n] = img; return img

# ---------------- helper: mask + bevel shading (cahaya dari kiri-atas) ----------------
def M(w, h, fn):
    m = Image.new('L', (w, h), 0); fn(ImageDraw.Draw(m)); p = m.load()
    return {(x, y) for y in range(h) for x in range(w) if p[x, y] > 127}
def paint(img, pix, base, hi, lo, tex=None):
    p = img.load()
    for (x, y) in pix:
        if not (0 <= x < img.width and 0 <= y < img.height): continue
        tl = ((x-1, y) not in pix) or ((x, y-1) not in pix)
        br = ((x+1, y) not in pix) or ((x, y+1) not in pix)
        c = base
        if tex and (x + y) % 2 == 0: c = tex
        if br: c = lo
        if tl: c = hi
        p[x, y] = c
def pal(base, hi, lo): return (C(base), C(hi), C(lo))
def thick(d, p0, p1, w):
    d.line([p0, p1], fill=255, width=w)
    for (x, y) in (p0, p1): d.ellipse([x-w/2+0.5, y-w/2+0.5, x+w/2-0.5, y+w/2-0.5], fill=255)

# =====================================================================
# ITEMS (32x32 ikon UI)
# =====================================================================
STEEL = pal('5a6068', '9aa2aa', '34383e')
def anvil():
    im = new(32, 32); W = 32
    base = M(W, W, lambda d: (d.polygon([(9,21),(27,21),(30,26),(6,26)], fill=255), d.rectangle([6,26,12,28], fill=255), d.rectangle([24,26,30,28], fill=255)))
    waist = M(W, W, lambda d: d.polygon([(12,15),(24,15),(22,21),(14,21)], fill=255))
    top = M(W, W, lambda d: (d.rectangle([9,9,28,14], fill=255), d.polygon([(9,9),(4,10),(1,11),(3,12),(9,15)], fill=255)))
    paint(im, base, *STEEL); paint(im, waist, *pal('4a5058','6a727a','2c3036')); paint(im, top, *STEEL)
    for x in range(10, 28): px(im, x, 9, C('d4dade'))          # permukaan kerja mengkilap
    px(im, 25, 11, C('1e2226')); px(im, 25, 12, C('1e2226'))   # hardy hole
    px(im, 22, 11, C('1e2226'))                                # pritchel hole
    for (x, y) in ((10,23),(11,24),(26,22),(20,25),(16,23)): px(im, x, y, C('8a4a2a'))   # karat
    px(im, 27, 24, C('6a3a20'))
    return add_outline(im)

LEATHER = pal('8a5a30', 'b8824a', '5a3a1e')
def boots():
    im = new(32, 32); W = 32
    shaft = M(W, W, lambda d: d.polygon([(9,6),(18,6),(19,18),(9,18)], fill=255))
    foot = M(W, W, lambda d: d.polygon([(9,15),(21,15),(26,17),(29,20),(29,24),(9,24)], fill=255))
    toe = M(W, W, lambda d: d.polygon([(23,17),(26,17),(29,20),(29,24),(23,24)], fill=255))
    sole = M(W, W, lambda d: d.rectangle([8,24,30,27], fill=255))
    collar = M(W, W, lambda d: d.rectangle([8,3,19,6], fill=255))
    paint(im, shaft, *LEATHER); paint(im, foot, *LEATHER); paint(im, toe, *pal('7a4a26','a8743e','4e3018'))
    paint(im, collar, *pal('4a3020','6a4630','2e1c12')); paint(im, sole, *pal('2e2822','4a4038','1a1612'))
    for x in range(9, 30): px(im, x, 27, C('4a4038') if x % 2 else C('1a1612'))    # tapak bergerigi
    for y in range(8, 17, 2):                                                      # tali sepatu
        px(im, 17, y, C('d8c8a0')); px(im, 18, y+1, C('d8c8a0')); px(im, 16, y+1, C('2a1c12'))
    for x in range(11, 23, 2): px(im, x, 21, C('4a2e16'))                          # jahitan
    px(im, 9, 1, K); px(im, 10, 1, K); px(im, 9, 2, C('6a4630')); px(im, 10, 2, C('6a4630'))  # pull tab
    px(im, 27, 20, C('d8a870')); px(im, 26, 19, C('c89a62'))                        # gores di ujung
    return add_outline(im)

PAINT = pal('c23a2b', 'ee6a4e', '7a2018')
def crowbar():
    im = new(32, 32); W = 32
    bar = M(W, W, lambda d: thick(d, (7, 25), (22, 9), 3))
    chisel = M(W, W, lambda d: (thick(d, (7, 25), (4, 27), 3), d.polygon([(2,26),(4,25),(4,29),(2,28)], fill=255)))
    hook = M(W, W, lambda d: (d.arc([20,2,30,12], 180, 360, fill=255, width=3), d.arc([20,2,30,12], 0, 55, fill=255, width=3)))
    paint(im, bar, *PAINT); paint(im, hook, *PAINT); paint(im, chisel, *STEEL)
    tip = {(x, y) for (x, y) in hook if x >= 27 and y >= 8}
    paint(im, tip, *STEEL)
    px(im, 27, 11, T); px(im, 28, 10, T)                     # celah cakar
    for (x, y) in ((12,20),(16,15),(19,12),(23,4)): px(im, x, y, C('9aa2aa'))   # cat terkelupas
    return add_outline(im)

KNIT = pal('b8bcc0', 'e6e9ec', '7a8088'); KNIT_T = C('a8acb0')
COAT = pal('4e5c6c', '72808e', '323c48'); CUFF = pal('d8b030', 'f2d468', '9a7a18')
def glove(im, ox, oy, dark=False):
    W = 32; f = (lambda p: tuple(tuple(int(c*0.72) if i < 3 else c for i, c in enumerate(col)) for col in p)) if dark else (lambda p: p)
    fingers = [(ox+4, oy+5), (ox+7, oy+3), (ox+10, oy+4), (ox+13, oy+7)]
    thumb = M(W, W, lambda d: d.polygon([(ox+5,oy+16),(ox+0,oy+11),(ox+1,oy+9),(ox+3,oy+9),(ox+7,oy+14)], fill=255))
    palm = M(W, W, lambda d: d.rounded_rectangle([ox+4,oy+12,ox+16,oy+23], radius=2, fill=255))
    cuff = M(W, W, lambda d: d.rectangle([ox+3,oy+23,ox+17,oy+28], fill=255))
    kn = f(KNIT); kt = f((KNIT_T,))[0]
    paint(im, thumb, *kn, tex=kt); paint(im, palm, *kn, tex=kt)
    for (fx, fy) in fingers:
        fm = M(W, W, lambda d, fx=fx, fy=fy: d.rounded_rectangle([fx, fy, fx+2, oy+14], radius=1, fill=255))
        paint(im, fm, *kn, tex=kt)
        paint(im, {(x, y) for (x, y) in fm if y <= fy+2}, *f(COAT))       # ujung jari berlapis grip
    paint(im, {(x, y) for (x, y) in thumb if x <= ox+2}, *f(COAT))
    paint(im, cuff, *f(CUFF))
    for x in range(ox+5, ox+17, 2):
        for y in range(oy+24, oy+28): px(im, x, y, f(CUFF)[2])           # rib manset
def gloves():
    im = new(32, 32)
    glove(im, 13, 2, dark=True); im = add_outline(im)
    glove(im, 2, 3)
    return add_outline(im)

WOOD = pal('d08a3a', 'f0b060', '9a5a20')
def guitar():
    im = new(32, 32); W = 32
    body = M(W, W, lambda d: (d.ellipse([7,17,25,30], fill=255), d.ellipse([9,10,23,21], fill=255)))
    neck = M(W, W, lambda d: d.rectangle([15,4,17,15], fill=255))
    head = M(W, W, lambda d: d.polygon([(14,1),(18,1),(18,4),(17,5),(15,5),(14,4)], fill=255))
    paint(im, body, *WOOD); paint(im, neck, *pal('6a4428','8a5a34','4a2e1a')); paint(im, head, *pal('3a2416','5a3a22','24160c'))
    d = ImageDraw.Draw(im)
    d.ellipse([12,15,20,23], outline=C('6a3a14')); d.ellipse([13,16,19,22], fill=C('24140a'))
    d.rectangle([12,25,20,26], fill=C('3a2010'))
    for x in (14, 16, 18): px(im, x, 25, C('e8dcc0'))
    for y in range(2, 26):
        for x in (15, 17):
            if (x, y) not in head or y > 3: px(im, x, y, C('d8d4c8') if y < 16 or y > 22 else C('8a8478'))
    for y in (7, 9, 11, 13): px(im, 16, y, C('b0aca0'))
    for (x, y) in ((13,2),(13,4),(19,2),(19,4)): px(im, x, y, C('c0c4c8'))
    px(im, 22, 27, C('f8d090')); px(im, 21, 28, C('f8d090'))           # kilap pernis
    return add_outline(im)

ITEMS = [('item_anvil', anvil), ('item_boots', boots), ('item_crowbar', crowbar), ('item_cutter_gloves', gloves), ('item_guitar', guitar)]
for n, fn in ITEMS: save('items', n, fn())

# =====================================================================
# ENEMIES
# =====================================================================
# --- Serangga Purba 16x16, 2 frame jalan ---
CARA = pal('7a5530', 'a8784a', '4a3220')
def bug(f):
    im = new(16, 16); W = 16; LEG = C('7a5a34'); LEGD = C('4a3220')
    d = ImageDraw.Draw(im)
    # kaki panjang 3 pasang, digambar dulu (di bawah badan)
    for i, bx in enumerate((5, 7, 9)):
        s = 1 if (i + f) % 2 else -1
        for side in (-1, 1):
            by = 7 if side < 0 else 8
            kx, ky = bx + s, (4 if side < 0 else 11)
            tx, ty = bx + s*2 + (i - 1), (1 if side < 0 else 14)
            d.line([(bx, by), (kx, ky)], fill=LEG); d.line([(kx, ky), (tx, ty)], fill=LEGD)
    ab = M(W, W, lambda d: d.ellipse([1, 5, 7, 10], fill=255))
    th = M(W, W, lambda d: d.ellipse([7, 5, 10, 10], fill=255))
    hd = M(W, W, lambda d: d.ellipse([10, 6, 12, 9], fill=255))
    paint(im, ab, *CARA); paint(im, th, *CARA); paint(im, hd, *pal('5a3a20','7a5230','36220f'))
    for x in range(2, 7): px(im, x, 7, CARA[2])                       # garis belah sayap (elytra)
    px(im, 3, 6, C('d8b080')); px(im, 8, 6, C('d8b080'))              # kilap cangkang
    px(im, 11, 7, C('ffb040')); px(im, 11, 8, C('ffb040'))            # mata
    body = add_outline(new(16, 16).copy())
    tmp = new(16, 16); tp = tmp.load(); ip = im.load()
    for (x, y) in ab | th | hd: tp[x, y] = ip[x, y]
    tmp = add_outline(tmp)
    im.alpha_composite(tmp)
    for (x, y) in ((13,6),(14,6),(15,7),(13,9),(14,9),(15,8)): px(im, x, y, C('e0c890'))   # mandibel
    px(im, 13, 7, K); px(im, 13, 8, K)
    for pts in (((12,5),(13,4),(14,3),(15,3)), ((12,10),(13,11),(14,12),(15,12))): d.line(pts, fill=LEG)
    return im

# --- Reptil Kecil 24x24: walk0, walk1, telegraph, attack ---
SCALE = pal('5f6e3a', '8a9a52', '3c4826')
def lizard(f):
    im = new(24, 24); W = 24
    dx = {0: 0, 1: 0, 2: -1, 3: 2}[f]; ty = {0: 11, 1: 13, 2: 12, 3: 12}[f]
    tele = f == 2
    ph = {0: 1, 1: -1, 2: 0, 3: -2}[f]
    legs = set()
    for (lx, sgn) in ((13+dx, 1), (9+dx, -1)):
        o = ph * sgn
        legs |= M(W, W, lambda d, lx=lx, o=o: (d.ellipse([lx+o-1, 5, lx+o+2, 8], fill=255), d.ellipse([lx-o-1, 16, lx-o+2, 19], fill=255)))
    paint(im, legs, *pal('4e5a30','6e7c42','2e3a1c'))
    tail = M(W, W, lambda d: d.polygon([(1+dx, ty), (2+dx, ty), (9+dx, 10), (9+dx, 14)], fill=255))
    body = M(W, W, lambda d: d.ellipse([7+dx, 8, 16+dx, 16], fill=255))
    head = M(W, W, lambda d: d.ellipse([14+dx, 9, 20+dx, 15], fill=255))
    paint(im, tail, *SCALE); paint(im, body, *SCALE)
    if tele:   # rahang terbuka
        mouth = M(W, W, lambda d: d.polygon([(19+dx,11),(23+dx,10),(23+dx,14),(19+dx,13)], fill=255))
        paint(im, mouth, *pal('c83a2a','e8604a','7a1a12'))
        up = M(W, W, lambda d: d.polygon([(18+dx,9),(22+dx,8),(23+dx,9),(19+dx,11)], fill=255))
        lo = M(W, W, lambda d: d.polygon([(18+dx,15),(22+dx,16),(23+dx,15),(19+dx,13)], fill=255))
        paint(im, up, *SCALE); paint(im, lo, *SCALE)
        for (x, y) in ((21+dx,10),(21+dx,14)): px(im, x, y, C('f0ecdc'))
    else:
        snout = M(W, W, lambda d: d.polygon([(19+dx,10),(22+dx,11),(22+dx,13),(19+dx,14)], fill=255))
        paint(im, snout, *SCALE)
    paint(im, head, *SCALE)
    for x in range(9+dx, 16+dx, 2): px(im, x, 12, C('2e3a1c'))           # pola tulang punggung
    for x in range(4+dx, 9+dx, 2): px(im, x, 12, C('2e3a1c'))
    eye = C('ff3a2a') if tele else C('ffd040')
    px(im, 18+dx, 10, eye); px(im, 18+dx, 14, eye)
    im = add_outline(im, C('6a0e0e') if tele else K)
    if f == 3:   # garis gerak lunge
        for y in (9, 15): ImageDraw.Draw(im).line([(1, y), (4, y)], fill=(230, 230, 210, 140))
    return im

# --- Nemesis 64x64: walk0, walk1, telegraph; palet per era ---
ERAS = {
 'era1': dict(body=('3e2440','5e3a62','241428'), plate=('8a1f3d','c8456a','4e0f22'), eye='ff3a2a', spike='e8d6c8', leg=('2e1a30','4a2c4c','1a0e1c')),
 'era2': dict(body=('1e3a3a','2e5a56','10221f'), plate=('b8862a','e8b850','6a4a10'), eye='ff8a1a', spike='f0e2b0', leg=('163030','244a46','0c1c1a')),
 'era3': dict(body=('2a2624','46403a','161412'), plate=('c8501e','ff8a3a','6e2410'), eye='ffcf3a', spike='ffd8a0', leg=('201c1a','38322e','100e0c')),
 'era4': dict(body=('5a5048','8a7e70','3a322c'), plate=('6a2a8a','9a5ac8','3a1050'), eye='4affb0', spike='f4ecdc', leg=('463e38','6a5e54','2a2420')),
 'era5_final': dict(body=('1c1020','34203a','0e0810'), plate=('6a0e24','a8203a','3a0612'), eye='ff2a2a', spike='f0e0e0', leg=('160c18','2c1830','0a060c'), final=True),
}
def nemesis(f, P):
    im = new(64, 64); W = 64; fin = P.get('final', False); tele = f == 2
    dx = -2 if tele else 0; ph = {0: 1, 1: -1, 2: 0}[f]; sw = {0: -1, 1: 1, 2: 0}[f]
    BODY = pal(*P['body']); PLATE = pal(*P['plate']); LEGC = pal(*P['leg'])
    d0 = ImageDraw.Draw(im)
    # kaki serangga (tipis, berbuku) — digambar dulu supaya tertutup badan
    ins = set()
    for side in (-1, 1):
        o = ph * side
        k = (31+dx+o, 32 + side*18); t = (25+dx+o*2, 32 + side*24)
        ins |= M(W, W, lambda d, k=k, t=t, side=side: (d.line([(29+dx, 32+side*9), k], fill=255, width=2), d.line([k, t], fill=255, width=2)))
    paint(im, ins, *LEGC)
    # kaki reptil (tebal)
    rl = set()
    for (hx, s0) in ((38+dx, 1), (22+dx, -1)):
        for side in (-1, 1):
            o = ph * s0 * side
            foot = (hx + 3 + o*2, 32 + side*17)
            rl |= M(W, W, lambda d, hx=hx, foot=foot, side=side: thick(d, (hx, 32+side*8), foot, 6))
    paint(im, rl, *LEGC)
    for (hx, s0) in ((38+dx, 1), (22+dx, -1)):
        for side in (-1, 1):
            o = ph * s0 * side; fx, fy = hx + 3 + o*2, 32 + side*17
            for c in (-2, 0, 2): px(im, fx + 3, fy + c*side//2 + side*2, C(P['spike']))
    tail = M(W, W, lambda d: d.polygon([(2, 31+sw), (5, 30+sw), (20+dx, 26), (20+dx, 38), (5, 34+sw), (2, 33+sw)], fill=255))
    body = M(W, W, lambda d: d.ellipse([16+dx, 19, 44+dx, 45], fill=255))
    paint(im, tail, *BODY); paint(im, body, *BODY)
    for x in range(6, 20, 4):
        for y in range(25, 40):
            if (x+dx if x > 15 else x, y) in tail: px(im, x, y, BODY[2])
    for box in ([19, 24, 29, 40], [26, 22, 36, 42], [33, 23, 43, 41]):
        pm = M(W, W, lambda d, b=box: d.ellipse([b[0]+dx, b[1], b[2]+dx, b[3]], fill=255))
        paint(im, pm, *PLATE)
    head = M(W, W, lambda d: (d.ellipse([38+dx, 22, 56+dx, 42], fill=255), d.polygon([(52+dx,25),(60+dx,29),(60+dx,35),(52+dx,39)], fill=255)))
    paint(im, head, *BODY)
    # mandibel serangga
    if tele: up = [(53,24),(55,17),(59,14),(62,16),(58,19),(56,25)]
    else:    up = [(53,24),(57,20),(61,21),(62,24),(59,23),(56,26)]
    for poly in (up, [(x, 64 - y) for (x, y) in up]):
        mm = M(W, W, lambda d, poly=poly: d.polygon([(x+dx, y) for (x, y) in poly], fill=255))
        paint(im, mm, *pal(P['spike'], 'ffffff', P['leg'][0]))
    # duri punggung
    big = 2 if fin else 1
    for sx in (22, 29, 36) + ((42,) if fin else ()):
        cx = sx + dx
        sp = M(W, W, lambda d, cx=cx: d.polygon([(cx+2, 30-big), (cx+2, 34+big), (cx-4-big*2, 32)], fill=255))
        sc = C(P['spike']); paint(im, sp, shade(sc, 0.72), sc, C(P['plate'][2]))
        px(im, cx+1, 31-big, C('ffffff'))
    if fin:   # duri samping ekstra + urat energi cyan (jejak ancient tech)
        for sx in (24, 31, 38):
            for side in (-1, 1):
                sp = M(W, W, lambda d, sx=sx, side=side: d.polygon([(sx+dx+1, 32+side*9), (sx+dx+3, 32+side*9), (sx+dx-2, 32+side*13)], fill=255))
                sc = C(P['spike']); paint(im, sp, shade(sc, 0.72), sc, C(P['plate'][2]))
        rnd = random.Random(5)
        for (x0, y0) in ((25, 27), (31, 36), (37, 28), (44, 33)):
            x, y = x0 + dx, y0
            for _ in range(4):
                px(im, x, y, CY if rnd.random() < 0.7 else CY_H); x += rnd.choice((1, 1, 0)); y += rnd.choice((-1, 0, 1))
    # alis + mata
    for side in (-1, 1):
        ey = 32 + side*5
        d0.line([(46+dx, ey - side*2), (51+dx, ey - side*1)], fill=BODY[2])
        e = C(P['eye'])
        pts = [(49+dx, ey), (50+dx, ey)] + ([(49+dx, ey+side), (50+dx, ey+side), (51+dx, ey)] if tele else [])
        for (x, y) in pts: px(im, x, y, e)
        px(im, 50+dx, ey, (255, 240, 220, 255))
    if fin:   # borgol karatan yang menyatu di kaki depan (payoff Ending)
        lx, ly = 38 + dx + 2, 32 - 12
        for y in (ly, ly + 1):
            for x in range(lx - 4, lx + 4): px(im, x, y, C('9a6440') if y == ly else C('5a3a22'))
        for (x, y) in ((lx + 5, ly + 1), (lx + 7, ly + 2), (lx + 9, ly + 2)):
            px(im, x, y, C('9a6440')); px(im, x + 1, y, C('5a3a22'))
    im = add_outline(im, C('6a0e0e') if tele else K)
    if tele:   # pendar merah sekitar kepala
        g = new(W, W); gd = ImageDraw.Draw(g)
        gd.ellipse([40+dx, 18, 64, 46], fill=(255, 40, 30, 46))
        out = new(W, W); out.alpha_composite(g); out.alpha_composite(im); im = out
    return im

FR = {}
FR['serangga_purba'] = [bug(0), bug(1)]
FR['reptil_kecil'] = [lizard(i) for i in range(4)]
for era, P in ERAS.items(): FR['nemesis_' + era] = [nemesis(i, P) for i in range(3)]

NAMES = {'serangga_purba': ['walk_0', 'walk_1'], 'reptil_kecil': ['walk_0', 'walk_1', 'telegraph', 'attack']}
for n, frames in FR.items():
    labels = NAMES.get(n, ['walk_0', 'walk_1', 'telegraph'])
    w, h = frames[0].size
    sheet = new(w * len(frames), h)
    for i, fr in enumerate(frames):
        sheet.alpha_composite(fr, (i * w, 0)); save('enemies', f'{n}_{labels[i]}', fr)
    save('enemies', n + '_sheet', sheet)

# =====================================================================
# PREVIEW: sheet PNG + GIF animasi
# =====================================================================
FB = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 22)
FT = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 15)
FH = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 30)
GROUND = C('2a281d')
def ground(w, h, seed=1):
    g = Image.new('RGBA', (w, h), GROUND); r = random.Random(seed)
    for _ in range(w * h // 40): px(g, r.randrange(w), r.randrange(h), r.choice([C('36332a'), C('201e16'), C('34452a')]))
    return g
def up(im, s): return im.resize((im.width * s, im.height * s), Image.NEAREST)
def on_ground(im, s, pad=4):
    g = ground(im.width + pad*2, im.height + pad*2, im.width); g.alpha_composite(im, (pad, pad)); return up(g, s)

groups = []
groups.append(("Item (ikon UI 32x32, ditampilkan 4x)", [(on_ground(S[n], 4), f"{n}.png  32x32") for n, _ in ITEMS]))
groups.append(("Serangga Purba (16x16, 6x)", [(on_ground(f, 6), f"serangga_purba_{l}") for f, l in zip(FR['serangga_purba'], ['walk_0', 'walk_1'])]
              + [(on_ground(FR['serangga_purba'][0].rotate(a, resample=Image.NEAREST), 6), f"rotasi via kode {a}°") for a in (45, 90, 180)]))
groups.append(("Reptil Kecil (24x24, 5x)", [(on_ground(f, 5), f"reptil_kecil_{l}") for f, l in zip(FR['reptil_kecil'], NAMES['reptil_kecil'])]))
groups.append(("Nemesis era 1 (64x64, 3x)", [(on_ground(f, 3), f"nemesis_era1_{l}") for f, l in zip(FR['nemesis_era1'], ['walk_0', 'walk_1', 'telegraph'])]))
groups.append(("Mutasi Nemesis per era (visual-only, palette swap + siluet final)", [(on_ground(FR['nemesis_' + e][0], 3), f"nemesis_{e}") for e in ERAS]))
# lineup skala
lin = ground(150, 76, 9); ld = ImageDraw.Draw(lin)
x = 6
for im in (FR['serangga_purba'][0], FR['reptil_kecil'][0]):
    lin.alpha_composite(im, (x, 70 - im.height)); x += im.width + 8
ld.rectangle([x, 70 - 24, x + 15, 69], outline=CY); x += 24
lin.alpha_composite(FR['nemesis_era1'][0], (x, 6))
groups.append(("Perbandingan skala (3x) — kotak cyan = Nael asumsi 16x24, belum di-lock", [(up(lin, 3), "serangga · reptil · Nael · Nemesis")]))

SW, pad = 1600, 24
rows = []
for title, items in groups:
    lines = []; cur = []; xx = pad
    for im, lab in items:
        w = max(im.width, 200) + 28
        if xx + w > SW - pad and cur: lines.append(cur); cur = []; xx = pad
        cur.append((im, lab)); xx += w
    lines.append(cur); rows.append((title, lines))
Ht = pad + 60 + sum(40 + sum(max(i.height for i, _ in l) + 40 for l in ls) for _, ls in rows) + pad
sheet = Image.new('RGBA', (SW, Ht), C('171411')); sd = ImageDraw.Draw(sheet)
sd.text((pad, pad), "CHRONOFALL — Item & Enemy Preview (placeholder)", font=FH, fill=C('39e0e8')); y = pad + 60
for title, ls in rows:
    sd.text((pad, y), title, font=FB, fill=C('e8b040')); y += 40
    for l in ls:
        xx = pad; rh = max(i.height for i, _ in l)
        for im, lab in l:
            sheet.alpha_composite(im, (xx, y)); sd.text((xx, y + im.height + 6), lab, font=FT, fill=C('c8bca0')); xx += max(im.width, 200) + 28
        y += rh + 40
sheet.save(os.path.join(OUT, 'preview_items_enemies.png'))

# GIF: baris atas jalan, baris bawah serangan (telegraph -> attack)
seq_r = [0, 1, 0, 1, 2, 2, 2, 3, 3, 0]
seq_n = [0, 1, 0, 1, 2, 2, 2, 2, 0, 1]
frames = []
for t in range(10):
    g = ground(200, 150, 3)
    g.alpha_composite(FR['serangga_purba'][t % 2], (14, 30))
    g.alpha_composite(FR['reptil_kecil'][t % 2], (44, 26))
    g.alpha_composite(FR['nemesis_era1'][t % 2], (80, 6))
    g.alpha_composite(FR['reptil_kecil'][seq_r[t]], (44, 104))
    g.alpha_composite(FR['nemesis_era1'][seq_n[t]], (80, 82))
    frames.append(up(g, 4).convert('P', palette=Image.ADAPTIVE, colors=255))
frames[0].save(os.path.join(OUT, 'preview_enemies_anim.gif'), save_all=True, append_images=frames[1:], duration=[180]*4 + [220]*6, loop=0, disposal=2)
print('ok', len(S))
