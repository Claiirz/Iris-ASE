"""CHRONOFALL — HUD placeholder asset generator (pixel art, 1x).
Semua sprite digambar di resolusi 1x; di Godot di-scale integer (2x) dengan filter Nearest.
"""
from PIL import Image, ImageDraw, ImageFont
import math, random, os

ROOT = os.path.dirname(os.path.abspath(__file__))
SPR = os.path.join(ROOT, "sprites")
MOCK = os.path.join(ROOT, "mockup")
os.makedirs(SPR, exist_ok=True); os.makedirs(MOCK, exist_ok=True)

def C(h, a=255):
    h = h.lstrip('#'); return (int(h[0:2],16), int(h[2:4],16), int(h[4:6],16), a)

# ---------------- PALETTE (sesuai GDD section 4) ----------------
K      = C('14110f')          # outline
ST_HI  = C('9a8462'); ST_HI2 = C('766449')   # batu terang
ST_LO  = C('3a3128'); ST_LO2 = C('4c4033')   # batu gelap
MOSS   = C('4f6e33'); MOSS_D = C('34482a')
LAVA   = C('e0702a'); LAVA_H = C('ffb15a'); LAVA_D = C('a8321e')
CY     = C('39e0e8'); CY_H = C('d8ffff'); CY_D = C('1b8fa3'); CY_DD = C('0e4f5c'); CY_BG = C('0b2b33')
HP     = C('c23a2b'); HP_H = C('ee6a4e'); HP_D = C('7a2018'); HP_BG = C('2a1412')
TH_BG  = C('1d1612')
BOSS   = C('8a1f3d'); BOSS_H = C('c8456a'); BOSS_D = C('4e0f22'); BOSS_BG = C('1e0c12')
BR_HI  = C('6e3a40'); BR_LO = C('2e161a')    # bingkai bos (batu kemerahan)
SLOT_BG= C('1a1613')
TRANSP = (0,0,0,0)

def new(w,h,fill=TRANSP): return Image.new('RGBA',(w,h),fill)

def px(img,x,y,c):
    if 0<=x<img.width and 0<=y<img.height: img.putpixel((x,y),c)

def from_ascii(rows,cmap):
    w=max(len(r) for r in rows); img=new(w,len(rows))
    for y,r in enumerate(rows):
        for x,ch in enumerate(r):
            if ch!='.': img.putpixel((x,y),cmap[ch])
    return img

def add_outline(img,col=K):
    src=img.load(); out=img.copy(); o=out.load()
    for y in range(img.height):
        for x in range(img.width):
            if src[x,y][3]==0:
                for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
                    nx,ny=x+dx,y+dy
                    if 0<=nx<img.width and 0<=ny<img.height and src[nx,ny][3]>0 and src[nx,ny]!=col:
                        o[x,y]=col; break
    return out

def add_glow(img,col):
    src=img.load(); out=img.copy(); o=out.load()
    for y in range(img.height):
        for x in range(img.width):
            if src[x,y][3]==0:
                for dx in (-1,0,1):
                    for dy in (-1,0,1):
                        nx,ny=x+dx,y+dy
                        if 0<=nx<img.width and 0<=ny<img.height and src[nx,ny][3]==255:
                            o[x,y]=col
    return out

def lerp(a,b,t): return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(4))
def shade(c,f): return (min(255,int(c[0]*f)),min(255,int(c[1]*f)),min(255,int(c[2]*f)),c[3])

# ---------------- FRAME (bevel batu) ----------------
def bevel_frame(w,h,rings,inner_k=True):
    """rings: list of (hi, lo) per kedalaman (1..n). Area isi mulai di n+2."""
    img=new(w,h)
    d=ImageDraw.Draw(img)
    d.rectangle([0,0,w-1,h-1],outline=K)
    for i,(hi,lo) in enumerate(rings, start=1):
        for x in range(i,w-i):
            px(img,x,i,hi); px(img,x,h-1-i,lo)
        for y in range(i,h-i):
            px(img,i,y,hi); px(img,w-1-i,y,lo)
        px(img,w-1-i,i,lo); px(img,i,h-1-i,lo)
    n=len(rings)
    if inner_k: d.rectangle([n+1,n+1,w-2-n,h-2-n],outline=K)
    # sudut membulat
    for (x,y) in ((0,0),(w-1,0),(0,h-1),(w-1,h-1)): px(img,x,y,TRANSP)
    for (x,y) in ((1,1),(w-2,1),(1,h-2),(w-2,h-2)): px(img,x,y,K)
    return img

def clear_fill(img,x0,y0,fw,fh):
    for y in range(y0,y0+fh):
        for x in range(x0,x0+fw): px(img,x,y,TRANSP)

def under_tex(w,h,x0,y0,fw,fh,bg):
    img=new(w,h)
    for y in range(y0,y0+fh):
        for x in range(x0,x0+fw):
            c=bg
            if y==y0: c=shade(bg,0.6)               # inner shadow atas
            if (x+y)%7==0 and y>y0: c=shade(bg,1.25)  # tekstur halus
            px(img,x,y,c)
    return img

def progress_tex(fw,fh,color_fn):
    img=new(fw,fh)
    for y in range(fh):
        for x in range(fw):
            base=color_fn(x/(fw-1))
            if y==0: c=lerp(base,(255,255,255,255),0.35)
            elif y==1: c=lerp(base,(255,255,255,255),0.12)
            elif y==fh-1: c=shade(base,0.55)
            elif y==fh-2: c=shade(base,0.8)
            else: c=base
            px(img,x,y,c)
    return img

def moss_top(img,xs):
    for x in xs:
        px(img,x,0,MOSS_D); px(img,x,1,MOSS)
        if x%2==0: px(img,x+1,0,MOSS_D)

saved={}
def save(name,img):
    img.save(os.path.join(SPR,name+'.png')); saved[name]=img; return img

# =============== 1. HEALTH BAR ===============
HP_W,HP_H_=102,14; HP_FX,HP_FY,HP_FW,HP_FH=3,3,96,8
f=bevel_frame(HP_W,HP_H_,[(ST_HI,ST_LO)]); clear_fill(f,HP_FX,HP_FY,HP_FW,HP_FH)
moss_top(f,[4,5,6,11,12,30,31])
save('hp_bar_over',f)
save('hp_bar_under',under_tex(HP_W,HP_H_,HP_FX,HP_FY,HP_FW,HP_FH,HP_BG))
save('hp_bar_progress',progress_tex(HP_FW,HP_FH,lambda t:HP))

heart=["..kkk...kkk..",".krrrk.krrrk.","krwrrrkrrrrrk","krwrrrrrrrrrk","krrrrrrrrrrrk",
       ".krrrrrrrrdk.","..krrrrrrdk..","...krrrrdk...","....krrdk....",".....kdk.....","......k......"]
ic=new(16,16); ic.alpha_composite(from_ascii(heart,{'k':K,'r':HP,'w':C('f2b8a0'),'d':HP_D}),(1,3))
save('icon_hp',ic)

# =============== 2. THREAT METER ===============
TH_W,TH_H=172,18; TH_FX,TH_FY,TH_FW,TH_FH=4,4,164,10
def threat_frame(hot=False):
    rings=[(ST_HI,ST_LO),(ST_HI2,ST_LO2)] if not hot else [(C('ff8a4a'),C('8a2414')),(C('d8502a'),C('6e1a10'))]
    f=bevel_frame(TH_W,TH_H,rings); clear_fill(f,TH_FX,TH_FY,TH_FW,TH_FH)
    # tick fase 33% & 66% (spawn table: Awal/Tengah/Akhir)
    for t in (0.33,0.66):
        x=TH_FX+round(TH_FW*t)
        for y in range(TH_FY,TH_FY+TH_FH): px(f,x,y,(20,17,15,170))
        px(f,x,1,C('d8c8a0') if not hot else C('ffe0a0')); px(f,x,2,K); px(f,x,TH_H-2,K)
    # ukiran "gigi" tribal di ring atas
    for x in range(10,TH_W-10,12):
        px(f,x,1,K); px(f,x+1,2,K)
    if not hot:
        moss_top(f,[3,4,5,9,10,62,63])
        for x,y in ((TH_W-4,4),(TH_W-3,5),(TH_W-4,6),(TH_W-3,9),(TH_W-4,10),(TH_W-3,11)):   # retakan lava di ujung kanan
            px(f,x,y,LAVA)
        px(f,TH_W-3,7,LAVA_H)
    return f
save('threat_bar_over',threat_frame())
save('threat_bar_over_hunting',threat_frame(hot=True))
save('threat_bar_under',under_tex(TH_W,TH_H,TH_FX,TH_FY,TH_FW,TH_FH,TH_BG))
stops=[(0.0,C('b89a3a')),(0.33,C('d9a02e')),(0.34,C('e0882a')),(0.66,C('e0602a')),(0.67,C('d8402a')),(1.0,C('b81e2a'))]
def grad(t):
    for i in range(len(stops)-1):
        a,ca=stops[i]; b,cb=stops[i+1]
        if a<=t<=b: return lerp(ca,cb,(t-a)/(b-a) if b>a else 0)
    return stops[-1][1]
save('threat_bar_progress',progress_tex(TH_FW,TH_FH,grad))
for nm,col in (('awal',C('d9a02e')),('tengah',C('e0702a')),('akhir',C('c8282a'))):
    save('threat_bar_progress_'+nm,progress_tex(TH_FW,TH_FH,lambda t,c=col:c))

# Ikon mata Nemesis: dormant / tracking / hunting
EYE=["................","................","................",".....kkkkkk.....","...kkoaaaaokk...",
     "..koaaaaaaaaok..",".koaaaappaaaaok.","koaaaaappaaaaaok","koaaaaappaaaaaok",".koaaaappaaaaok.",
     "..koaaaaaaaaok..","...kkoaaaaokk...",".....kkkkkk.....","................","................","................"]
LID,LID_D=C('4b5a33'),C('2e3a20')
def eye(state):
    rows=[list(r) for r in EYE]
    if state=='dormant':
        for y,r in enumerate(rows):
            for x,ch in enumerate(r):
                if ch in 'oap': r[x]='l'
        for x in range(2,14): rows[8][x]='k' if rows[8][x]!='.' else '.'
        rows[7][1]='k'; rows[7][14]='k'
        cmap={'k':K,'l':LID}
    else:
        if state=='tracking':
            for y in range(3,8):
                for x,ch in enumerate(rows[y]):
                    if ch in 'oap': rows[y][x]='l'
            for x,ch in enumerate(rows[7]):
                if ch=='l': rows[7][x]='d'
            cmap={'k':K,'l':LID,'d':LID_D,'o':C('7a4a12'),'a':C('d8a030'),'p':C('0a0806'),'h':C('fff0c0')}
        else:
            cmap={'k':K,'o':C('6e1414'),'a':C('e0402a'),'p':C('0a0806'),'h':C('ffe0b0')}
            rows[6][5]='h'
    img=from_ascii([''.join(r) for r in rows],cmap)
    if state=='hunting': img=add_glow(img,(230,50,30,120))
    # duri alis (siluet predator)
    for x in (4,7,10):
        if state!='dormant' or True: px(img,x,2,K); px(img,x+1,1 if state=='hunting' else 2,K)
    return img
for s in ('dormant','tracking','hunting'): save('icon_nemesis_'+s,eye(s))

# =============== 3. FRAGMENT PIPS (0/8) ===============
SHARD=["...k...","..kwk..",".kwcck.",".kwcck.","kwccdck","kwccddk","kcccddk",".kccdk.",".kcddk.","..kdk..","...k..."]
full=new(9,13); full.alpha_composite(from_ascii(SHARD,{'k':K,'w':CY_H,'c':CY,'d':CY_D}),(1,1))
full=add_glow(full,(57,224,232,90))
save('fragment_pip_full',full)
empty=new(9,13); empty.alpha_composite(from_ascii(SHARD,{'k':CY_DD,'w':CY_BG,'c':CY_BG,'d':CY_BG}),(1,1))
save('fragment_pip_empty',empty)
ic=new(16,16); ic.alpha_composite(from_ascii(SHARD,{'k':K,'w':CY_H,'c':CY,'d':CY_D}),(4,2)); ic=add_glow(ic,(57,224,232,90))
save('icon_fragment',ic)

# =============== 4. SLOT SENJATA & SKILL ===============
def slot(size,ring,rivet=None,glow=None):
    f=bevel_frame(size,size,[ring])
    for y in range(3,size-3):
        for x in range(3,size-3): px(f,x,y,SLOT_BG if (x+y)%5 else shade(SLOT_BG,1.4))
    if rivet:
        for (x,y) in ((3,3),(size-4,3),(3,size-4),(size-4,size-4)): px(f,x,y,rivet)
    if glow:
        for i in range(1,size-1):
            px(f,i,1,glow); px(f,1,i,glow)
            px(f,i,size-2,shade(glow,0.6)); px(f,size-2,i,shade(glow,0.6))
    return f
save('weapon_slot',slot(28,(ST_HI,ST_LO),rivet=CY_D))
save('skill_slot',slot(24,(ST_HI,ST_LO)))
save('skill_slot_ready',slot(24,(ST_HI,ST_LO),glow=CY))
co=new(18,18,(6,5,4,150)); save('skill_cooldown_overlay',co)

# Ikon Sword
sw=new(16,16); W_,G_,Y_,YD,L_=C('e8e4d8'),C('9a968c'),C('d0a040'),C('8a6018'),C('5a3a22')
px(sw,13,1,W_)
for i in range(8):
    y=2+i; px(sw,12-i,y,W_); px(sw,13-i,y,G_)
for j,(x,y) in enumerate(((3,8),(4,9),(5,10),(6,11),(7,12))): px(sw,x,y,Y_ if j<3 else YD)
px(sw,4,11,L_); px(sw,3,12,shade(L_,1.3))
for (x,y) in ((1,13),(2,13),(1,14),(2,14)): px(sw,x,y,Y_)
px(sw,2,14,YD)
save('icon_sword',add_outline(sw))

# Ikon Bow (stretch goal) + varian terkunci
bw=new(16,16); WD,WDH=C('8a5a30'),C('b8824a')
for a in range(118,243):
    r=math.radians(a); x=round(12+7*math.cos(r)); y=round(8+7*math.sin(r)); px(bw,x,y,WDH if a<180 else WD)
    x2=round(12+6*math.cos(r)); px(bw,x2,y,WD)
for y in range(2,15): px(bw,9,y,C('d8d0b8'))
for x in range(3,14): px(bw,x,8,C('c8b890'))
px(bw,2,8,C('dcdcdc')); px(bw,3,7,C('dcdcdc')); px(bw,3,9,C('dcdcdc'))
for (x,y) in ((13,7),(14,7),(13,9),(14,9)): px(bw,x,y,HP)
bow=add_outline(bw); save('icon_bow',bow)
lk=bow.copy(); p=lk.load()
for y in range(16):
    for x in range(16):
        r,g,b,a=p[x,y]
        if a: v=int((r*.3+g*.59+b*.11)*0.55); p[x,y]=(v,v,v,a)
LOCK=["..kkk..",".kgggk.",".kg.gk.","kkkkkkk","kyyyyyk","kyykyyk","kyyyyyk","kkkkkkk"]
lk.alpha_composite(from_ascii(LOCK,{'k':K,'g':C('8a8a8a'),'y':Y_}),(9,8))
save('icon_bow_locked',lk)

# Ikon Riposte Slash (bulan sabit tebasan)
rs=new(16,16); c1=(7.5,8.5); c2=(9.3,6.4)
for y in range(16):
    for x in range(16):
        d1=math.dist((x,y),c1); d2=math.dist((x,y),c2)
        if d1<=6.6 and d2>5.4:
            px(rs,x,y,C('fff2c8') if d1>5.4 else (LAVA_H if d1>4.6 else LAVA))
for (x,y) in ((12,12),(13,12),(12,13)): px(rs,x,y,CY)  # kilau timing dodge
save('icon_skill_riposte_slash',add_outline(rs))

# Ikon Flicker Step (chevron + afterimage)
fs=new(16,16)
for x0,col in ((1,CY_DD),(5,CY_D),(9,CY)):
    for dy in range(-4,5):
        x=x0+4-abs(dy); y=8+dy
        px(fs,x,y,col); px(fs,x+1,y,col if x0<9 else CY_H if abs(dy)<2 else col)
save('icon_skill_flicker_step',add_outline(fs))

# Ikon Echo (hub / resource counter)
ec=new(16,16); EC,ECD=C('b0a8ff'),C('5a4fb0')
for y in range(16):
    for x in range(16):
        d=math.dist((x,y),(7.5,7.5)); ang=math.degrees(math.atan2(y-7.5,x-7.5))%360
        if abs(d-6.2)<0.55 and not (20<ang<70 or 200<ang<250): px(ec,x,y,ECD)
        if abs(d-3.6)<0.55 and not (110<ang<160 or 290<ang<340): px(ec,x,y,EC)
        if d<1.3: px(ec,x,y,C('ecebff'))
save('icon_echo',add_outline(ec))

# =============== 5. NEMESIS BOSS BAR ===============
BB_W,BB_H=216,14; BB_FX,BB_FY,BB_FW,BB_FH=4,4,208,6
f=bevel_frame(BB_W,BB_H,[(BR_HI,BR_LO),(C('52282e'),C('3a1c20'))]); clear_fill(f,BB_FX,BB_FY,BB_FW,BB_FH)
for x in range(8,BB_W-8,8): px(f,x,1,K)           # sisik
for xs in ((1,2,3),(BB_W-4,BB_W-3,BB_W-2)):       # taring di ujung
    for x in xs: px(f,x,BB_H-1,K)
px(f,2,BB_H-1,C('d8d0b8')); px(f,BB_W-3,BB_H-1,C('d8d0b8'))
save('boss_bar_over',f)
save('boss_bar_under',under_tex(BB_W,BB_H,BB_FX,BB_FY,BB_FW,BB_FH,BOSS_BG))
save('boss_bar_progress',progress_tex(BB_FW,BB_FH,lambda t:BOSS))

# =============== 6. 9-SLICE UMUM ===============
kb=bevel_frame(9,9,[(ST_HI,ST_LO)],inner_k=False)
for y in range(2,7):
    for x in range(2,7): px(kb,x,y,C('2b2620'))
save('key_badge_9slice',kb)
pn=bevel_frame(16,16,[(ST_HI,ST_LO)])
for y in range(3,13):
    for x in range(3,13): px(pn,x,y,(28,24,20,215))
save('panel_stone_9slice',pn)

# ---------------- 3x5 PIXEL FONT (hanya untuk mockup) ----------------
FONT={'0':"111101101101111",'1':"010110010010111",'2':"111001111100111",'3':"111001111001111",'4':"101101111001001",
'5':"111100111001111",'6':"111100111101111",'7':"111001001010010",'8':"111101111101111",'9':"111101111001111",
'/':"001001010100100",'.':"000000000000010",':':"000010000010000",'-':"000000111000000",' ':"000000000000000",
'A':"010101111101101",'B':"110101110101110",'C':"011100100100011",'D':"110101101101110",'E':"111100110100111",
'F':"111100110100100",'G':"011100101101011",'H':"101101111101101",'I':"111010010010111",'J':"001001001101010",
'K':"101101110101101",'L':"100100100100111",'M':"101111111101101",'N':"110101101101101",'O':"010101101101010",
'P':"110101110100100",'Q':"010101101110011",'R':"110101110101101",'S':"011100010001110",'T':"111010010010010",
'U':"101101101101111",'V':"101101101101010",'W':"101101111111101",'X':"101101010101101",'Y':"101101010010010",'Z':"111001010100111"}
def text(img,x,y,s,col,sh=True):
    for i,ch in enumerate(s.upper()):
        g=FONT.get(ch,FONT[' '])
        for r in range(5):
            for c in range(3):
                if g[r*3+c]=='1':
                    if sh: px(img,x+i*4+c+1,y+r+1,K)
                    px(img,x+i*4+c,y+r,col)
def text_w(s): return len(s)*4-1

# ---------------- MOCKUP ----------------
VW,VH=640,360
def arena(seed,lava_n,boss=False):
    rnd=random.Random(seed); bg=new(VW,VH,C('2a281d')); d=ImageDraw.Draw(bg)
    def shadow(kind,box):
        lay=new(VW,VH); g=ImageDraw.Draw(lay)
        (g.rectangle if kind=='r' else g.ellipse)(box,fill=(8,6,4,120)); bg.alpha_composite(lay)
    bases=[C('2a281d'),C('2e2b20'),C('27251b'),C('2c2a1f')]
    for ty in range(0,VH,16):
        for tx in range(0,VW,16):
            d.rectangle([tx,ty,tx+15,ty+15],fill=rnd.choice(bases))
            for _ in range(6): px(bg,tx+rnd.randrange(16),ty+rnd.randrange(16),rnd.choice([C('36332a'),C('201e16'),C('3a3a26')]))
    for _ in range(14):   # lumut
        cx,cy,r=rnd.randrange(VW),rnd.randrange(VH),rnd.randrange(10,30)
        for y in range(cy-r,cy+r):
            for x in range(cx-r,cx+r):
                dd=math.dist((x,y),(cx,cy))
                if dd<r and (dd<r-4 or (x+y)%2==0): px(bg,x,y,C('34452a') if (x*7+y*3)%11 else C('3f5530'))
    for _ in range(6):    # reruntuhan
        x,y=rnd.randrange(30,VW-60),rnd.randrange(40,VH-50); w,h=rnd.randrange(16,34),rnd.randrange(10,18)
        shadow('r',[x,y+3,x+w,y+h+3])
        d.rectangle([x,y,x+w,y+h],fill=C('4a4438'),outline=K); d.line([x+1,y+1,x+w-1,y+1],fill=C('6a6250'))
        if rnd.random()<0.4:
            for i in range(3,w-3,4): px(bg,x+i,y+h//2,CY)
    for _ in range(9):    # vegetasi lebat
        cx,cy,r=rnd.randrange(VW),rnd.randrange(VH),rnd.randrange(12,22)
        shadow('e',[cx-r,cy-r+4,cx+r,cy+r+4])
        d.ellipse([cx-r,cy-r,cx+r,cy+r],fill=C('1c2c16'),outline=C('10180c'))
        for _ in range(r*3):
            a=rnd.random()*6.28; rr=rnd.random()*r*0.8
            px(bg,int(cx+math.cos(a)*rr),int(cy+math.sin(a)*rr),rnd.choice([C('2d4521'),C('3a5a28'),C('24381a')]))
    lava_spots=[(rnd.randrange(60,VW-60),rnd.randrange(70,VH-60)) for _ in range(lava_n)]
    for cx,cy in lava_spots:
        glow=new(VW,VH); gd=ImageDraw.Draw(glow)
        for r,a in ((14,30),(10,55)): gd.ellipse([cx-r,cy-r,cx+r,cy+r],fill=(224,112,42,a))
        bg.alpha_composite(glow)
        d.ellipse([cx-6,cy-5,cx+6,cy+5],fill=LAVA_D,outline=K); d.ellipse([cx-4,cy-3,cx+4,cy+3],fill=LAVA); d.ellipse([cx-2,cy-1,cx+1,cy+1],fill=C('ffd27a'))
    # entitas
    bug=["k.....k",".k.k.k.","..bbb..",".kbBbk.","..bbb..",".k.k.k.","k.....k"]
    bugi=from_ascii(bug,{'k':K,'b':C('7a5530'),'B':C('a07040')})
    for _ in range(11 if not boss else 7):
        bg.alpha_composite(bugi,(rnd.randrange(VW//2-170,VW//2+170),rnd.randrange(VH//2-100,VH//2+100)))
    for _ in range(2 if not boss else 3):   # reptil kecil
        x,y=rnd.randrange(150,490),rnd.randrange(110,260)
        shadow('e',[x,y+2,x+13,y+9]); d.ellipse([x,y,x+13,y+7],fill=C('5f6e3a'),outline=K)
        d.line([x+12,y+3,x+17,y+4],fill=K); px(bg,x+3,y+2,C('ffd040'))
    # Nael (placeholder)
    NAEL=["...kkkk...","..khhhhk..","..khsshk..","..kssssk..","...kssk.g.","..kjjjjkg.",".kjjjjjjk.",".kjjbbjjk.",
          ".kcjjjjck.","..kjjjjk..","..kjkkjk..","..kk..kk.."]
    nael=from_ascii(NAEL,{'k':K,'h':C('3a2a1e'),'s':C('c89a72'),'j':C('7a6a52'),'b':C('3a2e22'),'c':C('9a9a9a'),'g':C('c8c4b8')})
    nx,ny=VW//2-5,VH//2-6
    shadow('e',[nx,ny+10,nx+10,ny+14]); bg.alpha_composite(nael,(nx,ny))
    if boss:   # siluet Nemesis
        bx,by=nx+44,ny-40
        sh=new(VW,VH); ImageDraw.Draw(sh).ellipse([bx-4,by+30,bx+60,by+52],fill=(0,0,0,110)); bg.alpha_composite(sh)
        d.ellipse([bx,by,bx+56,by+44],fill=C('2a1830'),outline=K)
        for i in range(5): d.polygon([(bx+8+i*10,by+6),(bx+13+i*10,by-6),(bx+18+i*10,by+6)],fill=C('3e2440'),outline=K)
        d.ellipse([bx+10,by+12,bx+46,by+34],fill=C('3e2440'))
        for cx in (bx-2,bx+46): d.polygon([(cx,by+30),(cx+12,by+36),(cx+2,by+46)],fill=C('2a1830'),outline=K)
        d.rectangle([bx+14,by+20,bx+16,by+21],fill=C('ff3a2a')); d.rectangle([bx+22,by+20,bx+24,by+21],fill=C('ff3a2a'))
        for r,a in ((60,30),): pass
    else:      # fragment pickup di tanah
        fx,fy=nx-90,ny+40
        bg.alpha_composite(saved['fragment_pip_full'],(fx,fy))
    # vignette
    vg=new(VW,VH); vp=vg.load()
    for y in range(VH):
        for x in range(VW):
            dd=math.dist((x/VW,y/VH),(0.5,0.5))
            if dd>0.32: vp[x,y]=(6,5,4,min(170,int((dd-0.32)*520)))
    bg.alpha_composite(vg)
    if boss:
        red=new(VW,VH,(120,10,10,28)); bg.alpha_composite(red)
    return bg

def bar(base,under,progress,over,off,value,pos):
    x,y=pos; base.alpha_composite(saved[under],(x,y))
    p=saved[progress]; w=round(p.width*value)
    if w>0: base.alpha_composite(p.crop((0,0,w,p.height)),(x+off[0],y+off[1]))
    base.alpha_composite(saved[over],(x,y))

def slotdraw(base,frame,icon,pos,cooldown=0.0,key=None,cd_text=None):
    x,y=pos; fr=saved[frame]; base.alpha_composite(fr,(x,y))
    ic=saved[icon]
    if cooldown>0:
        ic=ic.copy(); ip=ic.load()
        for yy in range(16):
            for xx in range(16):
                r,g,b,a=ip[xx,yy]
                if a: v=int((r*.3+g*.59+b*.11)*0.45); ip[xx,yy]=(v,v,v,a)
    base.alpha_composite(ic,(x+(fr.width-16)//2,y+(fr.height-16)//2))
    if cooldown>0:   # radial clockwise (simulasi TextureProgressBar FILL_CLOCKWISE)
        ov=new(fr.width-6,fr.height-6); op=ov.load(); cx=(ov.width-1)/2; cy=(ov.height-1)/2
        for yy in range(ov.height):
            for xx in range(ov.width):
                ang=(math.degrees(math.atan2(xx-cx,-(yy-cy)))+360)%360
                if ang<=cooldown*360: op[xx,yy]=(6,5,4,150)
        base.alpha_composite(ov,(x+3,y+3))
    if cd_text: text(base,x+(fr.width-text_w(cd_text))//2,y+fr.height//2-2,cd_text,C('ffffff'))
    if key:
        kw=text_w(key)+6; kbimg=nine(saved['key_badge_9slice'],kw,11,3)
        kx,ky=x+fr.width-kw+3,y-5; base.alpha_composite(kbimg,(kx,ky)); text(base,kx+3,ky+3,key,C('f0e6cc'),sh=False)

def nine(src,w,h,m):
    out=new(w,h); sw,sh=src.size
    xs=[(0,m,0,m),(m,sw-m,m,w-m),(sw-m,sw,w-m,w)]; ys=[(0,m,0,m),(m,sh-m,m,h-m),(sh-m,sh,h-m,h)]
    for sx0,sx1,dx0,dx1 in xs:
        for sy0,sy1,dy0,dy1 in ys:
            if dx1>dx0 and dy1>dy0:
                out.alpha_composite(src.crop((sx0,sy0,sx1,sy1)).resize((dx1-dx0,dy1-dy0),Image.NEAREST),(dx0,dy0))
    return out

def hud(base,hp,hpmax,threat,state,frag,riposte_cd,flicker_cd,boss_hp=None,hot=False):
    M=8
    base.alpha_composite(saved['icon_hp'],(M,M))
    bar(base,'hp_bar_under','hp_bar_progress','hp_bar_over',(HP_FX,HP_FY),hp/hpmax,(M+18,M+1))
    text(base,M+18+HP_W+4,M+5,f"{hp}/{hpmax}",C('e8dcc0'))
    for i in range(8):
        base.alpha_composite(saved['fragment_pip_full' if i<frag else 'fragment_pip_empty'],(M+18+i*10,M+17))
    tx=(VW-TH_W)//2
    base.alpha_composite(saved['icon_nemesis_'+state],(tx-19,M+1))
    bar(base,'threat_bar_under','threat_bar_progress','threat_bar_over_hunting' if hot else 'threat_bar_over',(TH_FX,TH_FY),threat/100,(tx,M))
    lbl={'dormant':'DORMANT','tracking':'TRACKING','hunting':'HUNTING'}[state]
    col={'dormant':C('9a9a8a'),'tracking':C('e8b040'),'hunting':C('ff5a3a')}[state]
    text(base,(VW-text_w(lbl))//2,M+TH_H+4,lbl,col)
    sx2=VW-M-24; sx1=sx2-28; wx=sx1-34; sy=VH-M-24
    slotdraw(base,'weapon_slot','icon_sword',(wx,VH-M-28))
    slotdraw(base,'skill_slot' if riposte_cd>0 else 'skill_slot_ready','icon_skill_riposte_slash',(sx1,sy),riposte_cd,'Q',
             f"{riposte_cd*3:.1f}" if riposte_cd>0 else None)
    slotdraw(base,'skill_slot' if flicker_cd>0 else 'skill_slot_ready','icon_skill_flicker_step',(sx2,sy),flicker_cd,'E',
             f"{flicker_cd*5:.1f}" if flicker_cd>0 else None)
    if boss_hp is not None:
        bx=(VW-BB_W)//2; by=VH-M-BB_H-2
        text(base,(VW-text_w('NEMESIS'))//2,by-8,'NEMESIS',C('ff8a8a'))
        bar(base,'boss_bar_under','boss_bar_progress','boss_bar_over',(BB_FX,BB_FY),boss_hp,(bx,by))

A=arena(7,3); hud(A,82,100,52,'tracking',3,0.40,0.0)
B=arena(11,5,boss=True); hud(B,46,100,100,'hunting',5,0.0,0.62,boss_hp=0.6,hot=True)
for nm,img in (('mockup_A_explore_fase_tengah',A),('mockup_B_miniboss_encounter',B)):
    img.save(os.path.join(MOCK,nm+'_640x360.png'))
    img.resize((1280,720),Image.NEAREST).save(os.path.join(MOCK,nm+'_1280x720.png'))

# ---------------- PREVIEW SHEET ----------------
S=4; pad=20
try: FNT=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',15); FNB=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',20)
except: FNT=FNB=ImageFont.load_default()
groups=[("Health Bar",['icon_hp','hp_bar_under','hp_bar_progress','hp_bar_over']),
        ("Threat Meter",['icon_nemesis_dormant','icon_nemesis_tracking','icon_nemesis_hunting','threat_bar_under','threat_bar_progress','threat_bar_over','threat_bar_over_hunting']),
        ("Fragment",['icon_fragment','fragment_pip_empty','fragment_pip_full']),
        ("Senjata & Skill",['weapon_slot','skill_slot','skill_slot_ready','skill_cooldown_overlay','icon_sword','icon_bow','icon_bow_locked','icon_skill_riposte_slash','icon_skill_flicker_step']),
        ("Nemesis Boss Bar",['boss_bar_under','boss_bar_progress','boss_bar_over']),
        ("Lain-lain",['icon_echo','key_badge_9slice','panel_stone_9slice'])]
SW=1500; rows=[];
for title,names in groups:
    line=[]; cur=[]; x=pad
    for n in names:
        w=saved[n].width*S+40
        if x+w>SW-pad and cur: line.append(cur); cur=[]; x=pad
        cur.append(n); x+=max(w,200)
    line.append(cur); rows.append((title,line))
H=pad
for title,line in rows:
    H+=34
    for l in line: H+=max(saved[n].height*S for n in l)+40
H+=pad
sheet=Image.new('RGBA',(SW,H),C('171411')); sd=ImageDraw.Draw(sheet); y=pad
sd.text((pad,4),"",font=FNB)
for title,line in rows:
    sd.text((pad,y),title,font=FNB,fill=C('39e0e8')); y+=34
    for l in line:
        x=pad; rh=max(saved[n].height*S for n in l)
        for n in l:
            im=saved[n].resize((saved[n].width*S,saved[n].height*S),Image.NEAREST)
            # checker bg utk transparansi
            ck=Image.new('RGBA',im.size,C('2a2622')); cp=ck.load()
            for yy in range(0,im.height,8):
                for xx in range(0,im.width,8):
                    if (xx//8+yy//8)%2:
                        for a in range(8):
                            for b in range(8):
                                if xx+b<im.width and yy+a<im.height: cp[xx+b,yy+a]=C('322d28')
            ck.alpha_composite(im); sheet.alpha_composite(ck,(x,y))
            sd.text((x,y+im.height+4),f"{n}.png  {saved[n].width}x{saved[n].height}",font=FNT,fill=C('c8bca0'))
            x+=max(im.width+40,200)
        y+=rh+40
sheet.save(os.path.join(ROOT,'preview_spritesheet_4x.png'))
print("sprites:",len(saved))
for n,i in saved.items(): print(f"{n}: {i.size}")
