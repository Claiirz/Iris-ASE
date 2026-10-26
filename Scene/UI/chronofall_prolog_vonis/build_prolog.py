"""CHRONOFALL — Prolog storyboard panels + Layar Vonis (pixel art 1x, layar logis 640x360)."""
import runpy, os, math, random
from PIL import Image, ImageDraw, ImageFont
ROOT=os.path.dirname(os.path.abspath(__file__))
H=runpy.run_path(os.path.join(ROOT,'build_hud.py'))
C,new,px,from_ascii,add_outline,add_glow,lerp,shade,nine,FONT=(H[k] for k in ('C','new','px','from_ascii','add_outline','add_glow','lerp','shade','nine','FONT'))
K,CY,CY_H,CY_D,CY_DD,LAVA=(H[k] for k in ('K','CY','CY_H','CY_D','CY_DD','LAVA'))
HS=H['saved']
FONT['+']="000010111010000"; FONT[',']="000000000010100"; FONT['?']="111001011000010"; FONT['"']="101101000000000"
VW,VH=640,360; T=(0,0,0,0)
OUT=os.path.join(ROOT,'prolog'); SPR=os.path.join(OUT,'sprites'); MOCK=os.path.join(OUT,'mockup')
os.makedirs(SPR,exist_ok=True); os.makedirs(MOCK,exist_ok=True)
B4=[[0,8,2,10],[12,4,14,6],[3,11,1,9],[15,7,13,5]]
WHITE=C('ffffff')

# ---------------- helpers ----------------
def canvas(col=C('000000')): return Image.new('RGBA',(VW,VH),col)
def vgrad(img,box,cols):
    x0,y0,x1,y1=box; p=img.load(); n=len(cols)-1
    for y in range(max(0,y0),min(img.height,y1)):
        t=(y-y0)/max(1,(y1-y0-1))*n; i=min(int(t),n-1); f=t-i
        for x in range(max(0,x0),min(img.width,x1)):
            p[x,y]=cols[i+1] if f*16>B4[y%4][x%4] else cols[i]
def layer(img,fn):
    L=new(img.width,img.height); fn(ImageDraw.Draw(L),L); img.alpha_composite(L); return L
def glow(img,cx,cy,rx,ry,col,bands=((1.0,22),(0.75,34),(0.52,52),(0.32,80))):
    for f,a in bands:
        layer(img,lambda d,L:d.ellipse([cx-rx*f,cy-ry*f,cx+rx*f,cy+ry*f],fill=col[:3]+(a,)))
def apoly(img,pts,col,a): layer(img,lambda d,L:d.polygon(pts,fill=col[:3]+(a,)))
def rays(img,cx,cy,angles,length,spread,col,a):
    for ang in angles:
        r1,r2=math.radians(ang-spread),math.radians(ang+spread)
        apoly(img,[(cx,cy),(cx+math.cos(r1)*length,cy+math.sin(r1)*length),(cx+math.cos(r2)*length,cy+math.sin(r2)*length)],col,a)
def rim(L,dirs,col,width=1):
    p=L.load(); out=L.copy(); o=out.load(); w,h=L.size
    for y in range(h):
        for x in range(w):
            if p[x,y][3]==0: continue
            for dx,dy in dirs:
                hit=False
                for k in range(1,width+1):
                    nx,ny=x+dx*k,y+dy*k
                    if not(0<=nx<w and 0<=ny<h) or p[nx,ny][3]==0: hit=True;break
                if hit: o[x,y]=col;break
    return out
def limb(d,p0,p1,w,col):
    dx,dy=p1[0]-p0[0],p1[1]-p0[1]; L=math.hypot(dx,dy) or 1; nx,ny=-dy/L*w/2,dx/L*w/2
    d.polygon([(p0[0]+nx,p0[1]+ny),(p1[0]+nx,p1[1]+ny),(p1[0]-nx,p1[1]-ny),(p0[0]-nx,p0[1]-ny)],fill=col)
    for (x,y) in (p0,p1): d.ellipse([x-w/2,y-w/2,x+w/2,y+w/2],fill=col)
def figure(L,cx,fy,Hh,col,helmet=False,arms='down',pose='stand',tilt=0,face=1,hair=False):
    d=ImageDraw.Draw(L); r=Hh*0.075
    if pose=='kneel': hip=fy-Hh*0.30; sh=hip-Hh*0.33; hy=sh-Hh*0.06-r
    else: hip=fy-Hh*0.47; sh=fy-Hh*0.80; hy=fy-Hh+r
    w=Hh*0.135; hw=Hh*0.095; hr=r*1.18 if helmet else r
    hx=cx+tilt; hyy=hy+abs(tilt)*0.6
    d.ellipse([hx-hr,hyy-hr,hx+hr,hyy+hr],fill=col)
    if helmet: d.rectangle([hx-hr-1,hyy+1,hx+hr+1,hyy+3],fill=col)
    if hair:
        for i in range(-3,4): d.polygon([(hx+i*hr/3-2,hyy-hr*0.6),(hx+i*hr/3+2,hyy-hr*0.6),(hx+i*hr/3+face*2,hyy-hr-3-(i%2)*2)],fill=col)
    d.rectangle([cx-r*0.45,hyy+r*0.5,cx+r*0.45,sh+2],fill=col)
    d.polygon([(cx-w,sh),(cx+w,sh),(cx+hw,hip),(cx-hw,hip)],fill=col)
    for s in (-1,1): d.ellipse([cx+s*w-Hh*0.045,sh-Hh*0.015,cx+s*w+Hh*0.045,sh+Hh*0.075],fill=col)
    aw=Hh*0.05
    if pose=='stand':
        limb(d,(cx-hw*0.5,hip),(cx-hw*0.6,fy-2),Hh*0.07,col); limb(d,(cx+hw*0.5,hip),(cx+hw*0.6,fy-2),Hh*0.07,col)
        for s in (-1,1): d.rectangle([cx+s*hw*0.6-Hh*0.04,fy-3,cx+s*hw*0.6+Hh*0.04,fy],fill=col)
    else:
        knee=(cx+face*Hh*0.15,fy-Hh*0.05); foot=(cx-face*Hh*0.12,fy-1)
        limb(d,(cx,hip),knee,Hh*0.09,col); limb(d,knee,foot,Hh*0.07,col)
    S={-1:(cx-w,sh+Hh*0.02),1:(cx+w,sh+Hh*0.02)}
    for s in (-1,1):
        p0=S[s]
        if arms=='down': limb(d,p0,(cx+s*(w+Hh*0.01),hip+Hh*0.06),aw,col)
        elif arms=='front':
            el=(cx+s*(w+Hh*0.02),sh+Hh*0.2); limb(d,p0,el,aw,col); limb(d,el,(cx+s*Hh*0.025,hip+Hh*0.02),aw,col)
        elif arms=='behind':
            el=(cx+s*(w+Hh*0.03),sh+Hh*0.17); limb(d,p0,el,aw,col); limb(d,el,(cx+s*Hh*0.03,hip-Hh*0.03),aw,col)
        elif arms=='push':
            if s==face: limb(d,p0,(cx+face*Hh*0.36,sh+Hh*0.06),aw,col)
            else: limb(d,p0,(cx+s*(w+Hh*0.01),hip+Hh*0.06),aw,col)
        elif arms=='carry':
            limb(d,p0,(cx+s*w*0.6,sh+Hh*0.22),aw,col)
    return dict(hip=hip,sh=sh,head=(hx,hyy,hr),w=w)
def vignette(img,strength=170,inner=0.36):
    L=new(VW,VH); p=L.load()
    for y in range(VH):
        for x in range(VW):
            d=math.hypot((x-VW/2)/VW,(y-VH/2)/VH*1.1)
            if d>inner:
                a=min(strength,int((d-inner)*strength*3.2)); a=(a//24)*24   # dibanding (banding) biar terasa pixel
                p[x,y]=(0,0,0,a)
    img.alpha_composite(L)
def txt(img,x,y,s,col,sc=1,sh=True,shcol=K):
    for i,ch in enumerate(s.upper()):
        g=FONT.get(ch,FONT[' '])
        for r in range(5):
            for c in range(3):
                if g[r*3+c]=='1':
                    bx,by=x+i*4*sc+c*sc,y+r*sc
                    if sh:
                        for dx in range(sc):
                            for dy in range(sc): px(img,bx+dx+max(1,sc//2),by+dy+max(1,sc//2),shcol)
                    for dx in range(sc):
                        for dy in range(sc): px(img,bx+dx,by+dy,col)
def tw(s,sc=1): return (len(s)*4-1)*sc
def noise_fill(img,box,cols,seed,density=0.08):
    r=random.Random(seed); x0,y0,x1,y1=box
    for _ in range(int((x1-x0)*(y1-y0)*density)): px(img,r.randrange(x0,x1),r.randrange(y0,y1),r.choice(cols))

S={}
def save(n,img): img.save(os.path.join(SPR,n+'.png')); S[n]=img; return img

# =================================================================
# PANEL 1 — Bengkel Nael, malam, sendirian
# =================================================================
def panel1():
    img=canvas(); rnd=random.Random(1); d=ImageDraw.Draw(img)
    vgrad(img,(0,0,VW,300),[C('0b1017'),C('111821'),C('17202b')])
    noise_fill(img,(0,0,VW,300),[C('0e141c'),C('19222e')],2,0.03)
    wx0,wy0,wx1,wy1=410,46,604,204
    vgrad(img,(wx0,wy0,wx1,wy1),[C('0a1222'),C('122036'),C('1e2e48')])
    for _ in range(25): px(img,rnd.randrange(wx0,wx1),rnd.randrange(wy0,wy0+60),C('6a7890'))
    d.ellipse([566,60,578,72],fill=C('c8d0d8')); d.ellipse([569,58,581,70],fill=C('0d1526'))
    x=wx0
    while x<wx1:
        bw=rnd.randint(14,30); top=wy1-rnd.randint(30,105)
        d.rectangle([x,top,min(wx1,x+bw),wy1],fill=C('070a11'))
        for yy in range(top+4,wy1-2,6):
            for xx in range(x+3,min(wx1-1,x+bw-2),5):
                if rnd.random()<0.18: d.rectangle([xx,yy,xx+1,yy+2],fill=rnd.choice([C('d8b860'),C('a89048'),C('7aa0c0')]))
        x+=bw+rnd.randint(0,3)
    FR=C('262e3a')
    d.rectangle([wx0-4,wy0-4,wx1+4,wy1+4],outline=FR,width=4)
    d.line([(wx0+wx1)//2,wy0,(wx0+wx1)//2,wy1],fill=FR,width=3); d.line([wx0,(wy0+wy1)//2,wx1,(wy0+wy1)//2],fill=FR,width=3)
    d.rectangle([wx0-8,wy1+4,wx1+8,wy1+8],fill=C('333c4a'))
    # rak kiri
    for sy in (84,136,188):
        d.rectangle([24,sy,170,sy+4],fill=C('2a2f38')); d.line([24,sy,170,sy],fill=C('3c4350'))
        x=28
        while x<160:
            bw=rnd.randint(8,22); bh=rnd.randint(10,34)
            d.rectangle([x,sy-bh,x+bw,sy-1],fill=rnd.choice([C('1e2430'),C('252a22'),C('2a2420'),C('1c2a2e')]),outline=C('0c0f14'))
            x+=bw+rnd.randint(1,4)
    # pegboard + sketsa yang ditempel
    d.rectangle([190,58,396,206],fill=C('1a212c'),outline=C('0d1118'))
    for yy in range(64,204,8):
        for xx in range(196,394,8): px(img,xx,yy,C('10151d'))
    for (x0,y0,w,h,rot) in ((206,72,40,30,0),(256,80,34,26,1),(300,68,44,34,0),(350,90,32,24,1)):
        d.rectangle([x0,y0,x0+w,y0+h],fill=C('8a8676'),outline=C('3a382e'))
        d.ellipse([x0+6,y0+5,x0+6+min(w,h)-12,y0+5+min(w,h)-12],outline=C('2a5a8a'))
        d.line([x0+4,y0+h-5,x0+w-4,y0+h-5],fill=C('2a5a8a'))
        px(img,x0+w//2,y0+1,C('c83a2a'))
    for (x0,y0,x1,y1) in ((214,120,214,170),(240,118,252,168),(280,124,280,176),(360,128,372,180)):
        d.line([x0,y0,x1,y1],fill=C('2c3440'),width=3)
    # rangka cincin (calon portal) di belakang
    RL=new(VW,VH); rd=ImageDraw.Draw(RL)
    rd.ellipse([458,146,582,318],outline=C('232a33'),width=10)
    rd.arc([458,146,582,318],200,290,fill=C('3a4554'),width=3)
    for a in range(0,360,30):
        r=math.radians(a); x=520+57*math.cos(r); y=232+81*math.sin(r); rd.rectangle([x-3,y-3,x+3,y+3],fill=C('2e3742'))
    rd.polygon([(586,240),(600,240),(596,318),(582,318)],fill=T)
    pr=RL.load()
    for y in range(150,318):            # bagian yang belum jadi
        for x in range(560,590):
            if pr[x,y][3] and y>236: pr[x,y]=T
    for i in range(4): rd.line([574,236+i*3,590+i*4,262+i*8],fill=C('6a3a2a') if i%2 else C('2a6a4a'),width=1)
    rd.rectangle([496,312,546,320],fill=C('1c2228'))
    img.alpha_composite(rim(RL,[(1,0)],C('2a4a66')))
    # meja kerja
    vgrad(img,(100,224,480,250),[C('3a3028'),C('2e2620')]); d.line([100,224,480,224],fill=C('5a4a3a'))
    vgrad(img,(100,250,480,300),[C('1a1612'),C('120f0c')])
    for x0 in (120,230,340): d.rectangle([x0,258,x0+90,282],outline=C('0a0806')); d.rectangle([x0+40,268,x0+50,271],fill=C('3a3028'))
    vgrad(img,(0,300,VW,VH),[C('0c1016'),C('07090c')])
    # monitor
    glow(img,400,204,90,60,C('3aa0c8'),((1,14),(0.7,22),(0.45,34)))
    d.rectangle([358,170,442,230],fill=C('171b22'),outline=K); d.rectangle([363,175,437,225],fill=C('09222e'))
    d.ellipse([382,182,416,216],outline=CY_D); d.ellipse([390,190,408,208],outline=CY)
    for i,yy in enumerate(range(184,222,5)): d.line([418,yy,432-(i%3)*3,yy],fill=CY_DD if i%2 else CY_D)
    d.line([366,214,380,198],fill=CY_DD); d.rectangle([394,230,406,236],fill=C('171b22')); d.rectangle([386,236,414,238],fill=C('171b22'))
    # benda di meja
    for pts in (((170,236),(206,231),(210,241),(174,246)),((250,240),(284,238),(285,247),(251,249)),((214,228),(240,227),(241,233),(215,234))):
        d.polygon(pts,fill=C('a8a08a'),outline=C('4a4638'))
    d.arc([180,234,196,244],0,360,fill=C('2a5a8a')); d.line([256,243,280,242],fill=C('2a5a8a'))
    for (x0,y0) in ((296,232),(316,240),(440,236)):
        d.rectangle([x0,y0,x0+14,y0+6],fill=C('234a32'),outline=K)
        for k in range(3): px(img,x0+3+k*4,y0+3,C('c8a040'))
    d.rectangle([330,220,340,234],fill=C('3a4048'),outline=K); d.line([341,224,344,224],fill=C('3a4048')); d.line([344,224,344,230],fill=C('3a4048'))
    for (a,b,c_) in (((404,238),(430,300),(470,336)),((360,238),(330,300),(280,330))):
        pts=[(a[0]+(c_[0]-a[0])*t+((b[0]-(a[0]+c_[0])/2)*4*t*(1-t)),a[1]+(c_[1]-a[1])*t+((b[1]-(a[1]+c_[1])/2)*4*t*(1-t))) for t in [i/20 for i in range(21)]]
        d.line(pts,fill=C('0a0c10'),width=2)
    # lampu kerja + cahaya hangat
    apoly(img,[(204,172),(226,168),(330,240),(150,240)],C('ffcf7a'),26)
    apoly(img,[(208,172),(222,170),(300,238),(176,238)],C('ffcf7a'),26)
    glow(img,236,238,80,8,C('ffcf7a'),((1,40),(0.6,60)))
    d.ellipse([128,232,152,240],fill=C('2a2a2a'),outline=K)
    d.line([140,234,170,182],fill=C('3a3a3a'),width=3); d.line([170,182,206,164],fill=C('3a3a3a'),width=3)
    d.polygon([(198,156),(222,160),(228,172),(204,174)],fill=C('4a4a4a'),outline=K); d.line([206,173,226,171],fill=C('ffe8a8'))
    # Nael (dari belakang, duduk, membungkuk)
    NL=new(VW,VH); nd=ImageDraw.Draw(NL); NC=C('15130f')
    nd.ellipse([248,158,276,186],fill=NC)
    for i in range(6): nd.polygon([(250+i*4,164),(254+i*4,164),(248+i*4+(i%2)*3,152+(i%3))],fill=NC)
    nd.rectangle([256,182,268,192],fill=NC)
    nd.polygon([(230,192),(294,194),(286,262),(240,262)],fill=NC)
    nd.ellipse([224,188,246,206],fill=NC); nd.ellipse([280,190,302,208],fill=NC)
    limb(nd,(232,200),(220,224),12,NC); limb(nd,(294,202),(306,222),12,NC)
    nd.rectangle([238,262,288,268],fill=C('1c1a18'))
    for x0 in (242,282): nd.line([x0,268,x0+(1 if x0>260 else -3),300],fill=C('1c1a18'),width=3)
    nd.line([262,268,262,300],fill=C('1c1a18'),width=3)
    NL=rim(NL,[(1,0)],C('2c5a7a'),2); NL=rim(NL,[(-1,0),(0,-1)],C('c8904a'))
    img.alpha_composite(NL)
    vignette(img,190,0.34)
    return img

# =================================================================
# PANEL 2 — Close-up alat, cahaya bocor sampai ke jendela
# =================================================================
def panel2():
    img=canvas(); d=ImageDraw.Draw(img); rnd=random.Random(2)
    vgrad(img,(0,0,VW,262),[C('090d13'),C('0f151e')])
    wx0,wy0,wx1,wy1=448,26,620,150
    vgrad(img,(wx0,wy0,wx1,wy1),[C('0a1424'),C('112138')])
    x=wx0
    while x<wx1:
        bw=rnd.randint(12,26); top=wy1-rnd.randint(20,70); d.rectangle([x,top,min(wx1,x+bw),wy1],fill=C('060910')); x+=bw+2
    d.rectangle([wx0-4,wy0-4,wx1+4,wy1+4],outline=C('222a36'),width=4); d.line([(wx0+wx1)//2,wy0,(wx0+wx1)//2,wy1],fill=C('222a36'),width=3)
    # pantulan cyan di kaca & sinar keluar jendela
    apoly(img,[(330,200),(wx0,wy0+10),(wx1,wy1-10)],CY,26)
    apoly(img,[(330,200),(wx0+30,wy0+30),(wx1-30,wy1-20)],CY_H,22)
    for i in range(5): d.line([wx0+10+i*30,wy1-6,wx0+30+i*30,wy0+6],fill=C('3aa0b8'))
    # meja
    vgrad(img,(0,262,VW,VH),[C('3a3028'),C('2a221c'),C('1c1612')]); d.line([0,262,VW,262],fill=C('5a4a3a'))
    glow(img,320,276,200,40,CY,((1,16),(0.7,26),(0.45,40)))
    rays(img,320,200,[-160,-130,-100,-60,-20,15,195,165,230,300],420,4,CY,18)
    glow(img,320,200,220,170,CY,((1,10),(0.7,16),(0.45,26),(0.25,40)))
    # badan alat (silinder)
    d.ellipse([206,256,434,282],fill=C('161b22'),outline=K)
    for x in range(236,405):
        t=(x-236)/168; f=0.55+0.6*math.sin(t*math.pi)
        for y in range(150,268):
            base=C('2a323c'); c=shade(base,f if (x+y)%2==0 else f*0.95)
            px(img,x,y,c)
    d.rectangle([236,150,404,268],outline=K)
    d.ellipse([236,138,404,162],fill=C('3a4450'),outline=K); d.ellipse([256,142,384,158],fill=C('232a33'))
    for a in range(0,360,24):
        r=math.radians(a); px(img,int(320+76*math.cos(r)),int(150+10*math.sin(r)),C('8a96a4'))
    # lensa inti
    d.ellipse([272,152,368,248],fill=C('11151b'),outline=K)
    for rr,c in ((42,CY_DD),(34,CY_D),(24,CY),(12,CY_H),(5,WHITE)): d.ellipse([320-rr,200-rr,320+rr,200+rr],fill=c)
    d.ellipse([272,152,368,248],outline=C('5a6674'),width=3)
    # sambungan yang bocor cahaya
    for y in (178,236):
        for x in range(238,404):
            if not (272<x<368 and 160<y<240): px(img,x,y,CY_H if (x//6)%3 else CY)
        glow(img,320,y,90,5,CY,((1,30),(0.6,50)))
    for (x0,y0) in ((246,190),(390,214),(258,246),(384,166)):
        pts=[(x0,y0)]
        for k in range(5): x0+=rnd.choice((-2,-1,1,2)); y0+=rnd.choice((2,3)); pts.append((x0,y0))
        d.line(pts,fill=CY_H)
    for _ in range(40): px(img,rnd.randint(220,420),rnd.randint(130,280),rnd.choice([CY,CY_H,WHITE]))
    # kabel
    for side in (-1,1):
        p0=(320+side*84,240); p1=(320+side*200,300); p2=(320+side*330,312)
        pts=[(p0[0]+(p2[0]-p0[0])*t+(p1[0]-(p0[0]+p2[0])/2)*4*t*(1-t),p0[1]+(p2[1]-p0[1])*t+(p1[1]-(p0[1]+p2[1])/2)*4*t*(1-t)) for t in [i/24 for i in range(25)]]
        d.line(pts,fill=K,width=7); d.line(pts,fill=C('1e242c'),width=5); d.line([(x,y-2) for x,y in pts],fill=C('2c5a6a'),width=1)
    # bahu & kepala Nael (over-the-shoulder, foreground)
    NL=new(VW,VH); nd=ImageDraw.Draw(NL); NC=C('06080b')
    nd.ellipse([10,140,130,262],fill=NC)
    for i in range(7): nd.polygon([(16+i*15,170),(30+i*15,166),(22+i*15+6,138-(i%3)*5)],fill=NC)
    nd.polygon([(-20,262),(60,236),(150,262),(214,330),(224,VH),(-20,VH)],fill=NC)
    NL=rim(NL,[(1,0),(1,-1)],CY_D,3); NL=rim(NL,[(1,0)],CY_H,1)
    img.alpha_composite(NL)
    vignette(img,160,0.38)
    return img

# =================================================================
# PANEL 3 — POV dari luar: aparat mendobrak, Nael diborgol
# =================================================================
def panel3():
    img=canvas(); d=ImageDraw.Draw(img); rnd=random.Random(3)
    vgrad(img,(0,0,VW,330),[C('0b0c11'),C('13141a')])
    for y in range(0,330,8):
        d.line([0,y,VW,y],fill=C('08090c'))
        for x in range((y//8%2)*10,VW,20): d.line([x,y,x,y+7],fill=C('08090c'))
    # interior lewat pintu
    DX0,DY0,DX1,DY1=214,58,426,330
    vgrad(img,(DX0,DY0,DX1,DY1),[C('141c22'),C('1c2830'),C('22303a')])
    d.rectangle([DX0+20,DY0+40,DX0+90,DY0+46],fill=C('10161c'))
    for x in range(DX0+22,DX0+88,9): d.rectangle([x,DY0+22,x+6,DY0+39],fill=C('0e1318'))
    d.rectangle([DX0+110,DY0+20,DX0+170,DY0+70],fill=C('0c1526'),outline=C('202833'),width=3)
    glow(img,392,206,120,90,CY,((1,18),(0.7,30),(0.45,46)))
    d.rectangle([DX0,250,DX1,DY1],fill=C('151a1e'))
    # figur di dalam (lebih kecil, rim cyan dari alat)
    IL=new(VW,VH); IC=C('0a0c10')
    figure(IL,370,252,74,IC,helmet=True,arms='carry'); figure(IL,414,252,72,IC,helmet=True,arms='carry')
    figure(IL,300,300,74,C('12100e'),arms='behind',pose='kneel',tilt=-3,face=1,hair=True)
    figure(IL,326,300,92,IC,helmet=True,arms='push',face=-1)
    IL=rim(IL,[(1,0),(0,-1)],CY_D)
    img.alpha_composite(IL)
    d.rectangle([380,202,404,218],fill=CY_D,outline=K); d.rectangle([384,205,400,214],fill=CY_H)
    for (x,y) in ((296,262),(300,262),(298,261)): px(img,x,y,C('e8eef2'))
    px(img,294,263,C('8a8e94')); px(img,302,263,C('8a8e94'))
    # senter dari aparat depan
    apoly(img,[(200,236),(290,210),(330,300)],C('e8f0f0'),26); apoly(img,[(452,232),(340,196),(380,280)],C('e8f0f0'),22)
    # pintu terlempar
    d.polygon([(426,62),(470,84),(470,322),(426,330)],fill=C('2a221c'),outline=K)
    d.line([430,66,430,326],fill=C('3e342a')); d.rectangle([460,190,466,200],fill=C('8a7a5a'))
    for i in range(6): d.polygon([(214+rnd.randint(0,30),58+i*40),(214+rnd.randint(-6,0),70+i*40),(214,78+i*40)],fill=C('2a221c'))
    d.rectangle([DX0-6,DY0-8,DX1+6,DY0],fill=C('1c1d22'))
    # tanah/trotoar
    vgrad(img,(0,330,VW,VH),[C('101114'),C('0a0a0c')])
    for i in range(8): d.rectangle([rnd.randint(150,480),rnd.randint(330,350),0,0] if False else [rnd.randint(180,460),rnd.randint(330,348),0,0],fill=None) if False else None
    for _ in range(8):
        x,y=rnd.randint(190,460),rnd.randint(326,348); d.polygon([(x,y),(x+rnd.randint(4,10),y+1),(x+3,y+3)],fill=C('3a2e24'))
    # lampu polisi (merah kiri, biru kanan)
    for i,(a,w_) in enumerate(((22,240),(30,170),(40,100))):
        layer(img,lambda dd,L,w_=w_,a=a:dd.rectangle([0,0,w_,VH],fill=(200,30,30,a)))
        layer(img,lambda dd,L,w_=w_,a=a:dd.rectangle([VW-w_,0,VW,VH],fill=(40,90,220,a)))
    # aparat foreground (membelakangi kamera)
    FL=new(VW,VH); FC=C('050608')
    figure(FL,176,382,270,FC,helmet=True,arms='down'); figure(FL,478,384,262,FC,helmet=True,arms='down')
    fd=ImageDraw.Draw(FL)
    for cx in (176,478): fd.rectangle([cx-22,382-270*0.62,cx+22,382-270*0.5],fill=C('0c0e12'))
    FL=rim(FL,[(-1,0)],C('c8282a'),2); FL=rim(FL,[(1,0)],C('3a6ae8'),2); FL=rim(FL,[(0,-1)],C('6a5a66'))
    img.alpha_composite(FL)
    vignette(img,150,0.40)
    return img

# =================================================================
# PANEL 4 — Ruang sidang (hakim raksasa, Nael kecil)
# =================================================================
def panel4():
    img=canvas(); d=ImageDraw.Draw(img)
    vgrad(img,(0,0,VW,262),[C('0a0c10'),C('14171d'),C('1c2028')])
    # jendela lengkung di belakang hakim
    WL=new(VW,VH); wd=ImageDraw.Draw(WL)
    wd.rectangle([236,40,404,170],fill=WHITE); wd.ellipse([236,-44,404,124],fill=WHITE)
    tmp=canvas(T); vgrad(tmp,(236,-44,404,170),[C('f0f6fa'),C('c8d8e4'),C('8aa0b4')])
    mask=WL.split()[3]; img.paste(tmp,(0,0),mask)
    for x in (278,320,362): d.line([x,0,x,170],fill=C('2a303a'),width=3)
    for y in (60,110): d.line([236,y,404,y],fill=C('2a303a'),width=3)
    glow(img,320,90,240,170,C('dce8f0'),((1,12),(0.7,18),(0.48,28)))
    # pilar
    for x0 in (36,116,490,570):
        for x in range(x0,x0+34):
            t=(x-x0)/33; c=lerp(C('3e4450'),C('1e2228'),t)
            for y in range(0,262): px(img,x,y,c if (x+y)%3 else shade(c,0.9))
        d.rectangle([x0-4,20,x0+38,30],fill=C('2a2e36'),outline=K); d.rectangle([x0-4,250,x0+38,262],fill=C('2a2e36'),outline=K)
    # lantai perspektif
    vgrad(img,(0,262,VW,VH),[C('181a20'),C('0e1014'),C('08090c')])
    for i in range(-12,13): d.line([320+i*14,190,320+i*70,VH],fill=C('20232a'))
    y=268; s=4
    while y<VH: d.line([0,y,VW,y],fill=C('20232a')); y+=s; s=int(s*1.45)+1
    # cahaya jatuh ke Nael
    apoly(img,[(262,170),(378,170),(410,326),(230,326)],C('e8eef2'),14)
    apoly(img,[(294,170),(346,170),(368,326),(272,326)],C('e8eef2'),16)
    glow(img,320,324,56,10,C('e8eef2'),((1,40),(0.6,60)))
    # hakim (siluet raksasa, backlit)
    JL=new(VW,VH); jd=ImageDraw.Draw(JL); JC=C('050608')
    jd.ellipse([292,42,348,104],fill=JC)
    jd.polygon([(306,96),(334,96),(410,124),(430,168),(210,168),(230,124)],fill=JC)
    limb(jd,(402,126),(438,88),12,JC); jd.line([438,88,452,72],fill=JC,width=4)
    jd.polygon([(440,66),(462,58),(468,70),(446,78)],fill=JC)
    JL=rim(JL,[(0,-1),(-1,0),(1,0)],C('f0f6fa')); img.alpha_composite(JL)
    d.rectangle([314,104,318,118],fill=C('c8ccd0')); d.rectangle([322,104,326,118],fill=C('c8ccd0'))
    px(img,310,72,WHITE); px(img,311,72,WHITE); px(img,329,72,WHITE); px(img,330,72,WHITE)
    # meja hakim
    vgrad(img,(150,160,490,264),[C('2a1e16'),C('1a120c'),C('0e0906')])
    d.polygon([(150,160),(140,264),(150,264)],fill=C('0e0906')); d.polygon([(490,160),(500,264),(490,264)],fill=C('0e0906'))
    d.rectangle([146,156,494,164],fill=C('4a3828'),outline=K)
    for x0 in (166,382): d.rectangle([x0,180,x0+92,248],outline=C('3a2a1c'))
    d.ellipse([294,184,346,236],outline=C('8a7040'),width=2); d.line([320,192,320,228],fill=C('8a7040'),width=2); d.line([302,200,338,200],fill=C('8a7040'),width=2)
    for cx in (304,336): d.polygon([(cx-7,212),(cx+7,212),(cx,200)],outline=C('8a7040'))
    # galeri pengunjung
    for side in (-1,1):
        x0,x1=(0,170) if side<0 else (470,VW)
        for row,y in enumerate((282,300)):
            for x in range(x0+6+row*8,x1-6,18): d.ellipse([x-7,y-8,x+7,y+8],fill=C('0b0c10')); d.rectangle([x-9,y+6,x+9,y+20],fill=C('0b0c10'))
        d.rectangle([x0,312,x1,316],fill=C('2a2018'))
        for x in range(x0,x1,8): d.line([x,316,x,VH],fill=C('1a140e'),width=2)
    # Nael & penjaga
    NL=new(VW,VH)
    figure(NL,320,324,58,C('14161a'),arms='front',tilt=0,hair=True)
    figure(NL,270,328,68,C('08090c'),helmet=True); figure(NL,370,328,68,C('08090c'),helmet=True)
    NL=rim(NL,[(0,-1)],C('dce4ea')); img.alpha_composite(NL)
    px(img,319,300,C('c8ccd0')); px(img,321,300,C('c8ccd0'))
    vignette(img,170,0.40)
    return img

# =================================================================
# PANEL 5 — Reaksi Nael (kepala tertunduk, kepalan tangan terborgol)
# =================================================================
def panel5():
    img=canvas(C('040405')); d=ImageDraw.Draw(img)
    glow(img,320,30,300,230,C('8a9098'),((1,10),(0.7,16),(0.45,24)))
    def topshade(L,y0,y1,cols):
        p=L.load()
        for y in range(VH):
            for x in range(VW):
                if p[x,y][3] and p[x,y]!=K:
                    t=max(0,min(1,(y-y0)/(y1-y0)))*(len(cols)-1); i=min(int(t),len(cols)-2); fr=t-i
                    p[x,y]=cols[i+1] if fr*16>B4[y%4][x%4] else cols[i]
    # badan (bahu membulat, satu siluet)
    BL=new(VW,VH); bd=ImageDraw.Draw(BL); CO=C('3a342c')
    bd.polygon([(256,164),(384,164),(428,174),(452,198),(466,VH),(174,VH),(188,198),(212,174)],fill=CO)
    topshade(BL,160,320,[C('5e5446'),C('3e372e'),C('26221c'),C('121110')])
    bd.polygon([(284,162),(320,204),(356,162),(344,160),(320,190),(296,160)],fill=C('4e463a'))
    for y in range(200,250,4): bd.rectangle([319,y,321,y+1],fill=C('6a6258'))
    bd.rectangle([372,206,398,224],fill=C('1c2226'),outline=K); bd.ellipse([378,209,392,222],outline=CY_D); px(BL,385,215,CY)
    BL=rim(BL,[(0,-1)],C('8a8070'),2); img.alpha_composite(BL)
    # lengan (layer terpisah + outline biar terbaca)
    AL=new(VW,VH); ad=ImageDraw.Draw(AL); AC=C('34302a')
    limb(ad,(206,198),(198,252),34,AC); limb(ad,(198,252),(286,266),28,AC)
    limb(ad,(434,198),(442,252),34,AC); limb(ad,(442,252),(354,266),28,AC)
    topshade(AL,180,290,[C('5a5042'),C('3a342c'),C('201d18')])
    for (x0,y0,x1,y1) in ((204,230,206,250),(436,230,434,250)): ad.line([x0,y0,x1,y1],fill=C('1c1a16'),width=2)
    AL=add_outline(AL,K); AL=rim(AL,[(0,-1)],C('8a8070')); img.alpha_composite(AL)
    # kepala tertunduk
    HL=new(VW,VH); hd=ImageDraw.Draw(HL)
    hd.ellipse([286,80,354,162],fill=C('2a201a'))
    hd.ellipse([288,72,352,134],fill=C('15110e'))
    for i in range(8): hd.polygon([(288+i*8,92),(297+i*8,88),(286+i*8+(i%3)*4,60-(i%2)*7)],fill=C('15110e'))
    hd.polygon([(296,136),(344,136),(336,160),(304,160)],fill=C('211813'))
    hd.line([302,142,314,144],fill=C('0c0907'),width=2); hd.line([326,144,338,142],fill=C('0c0907'),width=2)
    HL=rim(HL,[(0,-1),(-1,-1),(1,-1)],C('6a6256'),2); img.alpha_composite(HL)
    # kepalan + borgol + rantai
    SK,SKD,SKL=C('8a6a50'),C('5a4434'),C('b08a6a')
    for x0 in (284,322):
        d.rounded_rectangle([x0,248,x0+34,284],radius=8,fill=SK,outline=K)
        d.line([x0+4,250,x0+30,250],fill=SKL)
        for k in range(1,4): d.line([x0+k*8+1,252,x0+k*8+1,266],fill=SKD)
        d.line([x0+4,268,x0+30,268],fill=SKD)
    for x0 in (270,358):
        d.rectangle([x0,250,x0+12,282],fill=C('8a8e94'),outline=K); d.line([x0+2,252,x0+2,280],fill=C('c8ccd0')); d.line([x0+10,252,x0+10,280],fill=C('4a4e54'))
    for i in range(8):
        x=282+i*11; y=290+int(5*math.sin(i/7*math.pi)); d.ellipse([x-5,y-3,x+5,y+3],outline=C('9a9ea4'))
    for (x,y) in ((262,254),(258,266),(384,256),(388,268),(300,240),(340,240)):
        d.line([x,y,x+(4 if x>320 else -4),y],fill=C('c8ccd0'))
    vignette(img,200,0.30)
    return img

# =================================================================
# PANEL 6 — Dipaksa masuk portal, tertelan cahaya
# =================================================================
def panel6():
    img=canvas(); d=ImageDraw.Draw(img); rnd=random.Random(6)
    vgrad(img,(0,0,VW,300),[C('05080c'),C('0a1218'),C('0e1820')])
    for x in range(0,VW,48): d.line([x,0,x,300],fill=C('070b10'),width=2); d.rectangle([x+6,120,x+12,128],fill=C('111c24'))
    vgrad(img,(0,300,VW,VH),[C('0c161c'),C('060a0e')])
    for i in range(-10,11): d.line([420+i*20,300,420+i*90,VH],fill=C('0a1218'))
    cx,cy,rx,ry=420,182,96,128
    glow(img,cx,cy,300,260,CY,((1,12),(0.75,18),(0.55,26),(0.38,36)))
    rays(img,cx,cy,[a for a in range(0,360,26)],520,3,CY_H,16)
    for f,c in ((1.0,CY_DD),(0.88,CY_D),(0.72,CY),(0.52,CY_H),(0.3,WHITE)): d.ellipse([cx-rx*f,cy-ry*f,cx+rx*f,cy+ry*f],fill=c)
    d.ellipse([cx-rx-14,cy-ry-14,cx+rx+14,cy+ry+14],outline=C('1a2028'),width=16)
    d.arc([cx-rx-14,cy-ry-14,cx+rx+14,cy+ry+14],190,260,fill=C('4a5a68'),width=3)
    for a in range(0,360,45):
        r=math.radians(a); x=cx+(rx+6)*math.cos(r); y=cy+(ry+6)*math.sin(r); d.rectangle([x-6,y-6,x+6,y+6],fill=C('2a3440'),outline=K)
    glow(img,cx,322,170,16,CY,((1,30),(0.6,50)))
    # Nael larut ke cahaya
    NL=new(VW,VH); figure(NL,412,316,86,C('04060a'),arms='front',hair=True,tilt=2)
    np_=NL.load()
    for y in range(VH):
        for x in range(VW):
            if np_[x,y][3]:
                edge=any(not(0<=x+dx<VW) or np_[x+dx,y+dy][3]==0 for dx,dy in ((3,0),(-3,0),(0,-3)))
                if (edge and rnd.random()<0.55) or (y<250 and rnd.random()<0.12): np_[x,y]=rnd.choice([CY_H,WHITE,CY])
    img.alpha_composite(NL)
    for _ in range(80):
        x=rnd.randint(380,460); y=rnd.randint(220,320); px(img,x+rnd.randint(0,30),y-rnd.randint(0,40),rnd.choice([CY_H,WHITE]))
    # penjaga mendorong
    GL=new(VW,VH)
    figure(GL,300,322,100,C('030407'),helmet=True,arms='push',face=1); figure(GL,236,326,106,C('030407'),helmet=True,arms='down')
    GL=rim(GL,[(1,0)],CY,2); GL=rim(GL,[(0,-1)],CY_D); img.alpha_composite(GL)
    layer(img,lambda dd,L:dd.rectangle([0,0,VW,VH],fill=(57,224,232,14)))
    vignette(img,150,0.42)
    return img

panels=[panel1(),panel2(),panel3(),panel4(),panel5(),panel6()]
for i,p in enumerate(panels,1): save(f'panel_0{i}',p)

# letterbox overlay (bar atas 28 px, bawah 40 px)
lb=new(VW,VH); ImageDraw.Draw(lb).rectangle([0,0,VW,27],fill=C('000000')); ImageDraw.Draw(lb).rectangle([0,VH-40,VW,VH],fill=C('000000'))
save('letterbox_overlay',lb)

CAPS={1:[],2:[("IA PIKIR TAK ADA YANG MELIHAT.",C('e8dcc0'))],3:[],
      4:[("HAKIM: RISET ILEGAL MANIPULASI WAKTU.",C('e8dcc0')),("VONIS: PENGASINGAN.",C('ff8a6a'))],5:[],6:[]}
def with_caption(i):
    img=S[f'panel_0{i}'].copy(); img.alpha_composite(lb)
    lines=CAPS[i]; ys=[VH-26] if len(lines)==1 else [VH-36,VH-20]
    for (t,c),y in zip(lines,ys):
        if t.startswith("HAKIM:"):
            x=(VW-tw(t,2))//2; txt(img,x,y,"HAKIM:",C('e8b040'),2); txt(img,x+tw("HAKIM: ",2)+2,y,t[7:],c,2)
        else: txt(img,(VW-tw(t,2))//2,y,t,c,2)
    txt(img,VW-30,10,f"{i}/6",C('5a5448'))
    return img

# =================================================================
# LAYAR VONIS
# =================================================================
def stamp(numeral):
    s=new(52,52); d=ImageDraw.Draw(s); R=C('a8281e')
    d.ellipse([2,2,49,49],outline=R,width=3); d.ellipse([8,8,43,43],outline=R,width=1)
    n=len(numeral); total=n*6+(n-1)*4; x0=26-total//2
    for k in range(n):
        x=x0+k*10; d.rectangle([x,16,x+5,35],fill=R); d.rectangle([x-2,15,x+7,17],fill=R); d.rectangle([x-2,34,x+7,36],fill=R)
    for a in range(0,360,20):
        r=math.radians(a); px(s,int(26+19*math.cos(r)),int(26+19*math.sin(r)),R)
    rr=random.Random(len(numeral)); p=s.load()
    for _ in range(140):
        x,y=rr.randrange(52),rr.randrange(52)
        if p[x,y][3]: p[x,y]=T
    return s.rotate(-12,resample=Image.NEAREST)
for n,num in (('ringan','I'),('sedang','II'),('berat','III')): save('stamp_'+n,stamp(num))

def bug_icon():
    b=new(16,16); d=ImageDraw.Draw(b)
    for s in (-1,1):
        for k,yy in enumerate((6,9,12)): d.line([8+s*3,yy,8+s*6,yy-1+k],fill=C('4a3420'))
    d.ellipse([4,5,11,14],fill=C('7a5530')); d.ellipse([5,1,10,6],fill=C('3a2614'))
    d.line([7,6,7,13],fill=C('3a2614')); px(b,5,7,C('a07040')); px(b,6,6,C('a07040'))
    px(b,6,0,C('3a2614')); px(b,9,0,C('3a2614'))
    return add_outline(b)
save('icon_enemy_swarm',bug_icon())
PIP=["...k...","..kak..",".kaaak.","kaaaaak",".kaaak.","..kak..","...k..."]
save('pip_on',from_ascii(PIP,{'k':K,'a':C('c8282a')})); save('pip_off',from_ascii(PIP,{'k':C('7a7260'),'a':C('c8bea4')}))

CW,CH=164,214
def card_blank():
    c=new(CW,CH); d=ImageDraw.Draw(c)
    d.rectangle([0,0,CW-1,CH-1],fill=C('d6cdb4'),outline=K)
    noise_fill(c,(1,1,CW-1,CH-1),[C('cbc1a6'),C('ddd5be')],9,0.12)
    d.rectangle([4,4,CW-5,8],fill=C('5a1e1e')); d.line([4,11,CW-5,11],fill=C('5a1e1e'))
    d.polygon([(CW-14,0),(CW-1,13),(CW-14,13)],fill=C('b8ae94'),outline=K); d.polygon([(CW-13,0),(CW-1,0),(CW-1,12)],fill=T)
    for y in range(CH-10,CH-2): px(c,2+(y%3),y,C('bcb298'))
    d.line([2,CH-1,CW-1,CH-1],fill=C('6a604c')); d.line([CW-1,2,CW-1,CH-1],fill=C('6a604c'))
    return c
save('vonis_card',card_blank())
fb=new(CW+10,CH+10)
for i in range(CW+10):
    for (x,y) in ((i,0),(i,CH+9),(i,1),(i,CH+8)):
        if i<14 or i>CW-5: px(fb,x,y,CY)
for i in range(CH+10):
    for (x,y) in ((0,i),(CW+9,i),(1,i),(CW+8,i)):
        if i<14 or i>CH-5: px(fb,x,y,CY)
save('vonis_card_focus',fb)
RIB=new(70,13); rd=ImageDraw.Draw(RIB); rd.polygon([(0,0),(69,0),(64,6),(69,12),(0,12)],fill=CY_DD,outline=K); rd.line([1,1,66,1],fill=CY_D)
save('tag_ribbon',RIB)

VON=[('RINGAN','I',"HAKIM BERBELAS KASIHAN.",130,1,1,"+0"),
     ('SEDANG','II',"SESUAI KITAB HUKUM.",100,2,2,"+5"),
     ('BERAT','III',"JADIKAN DIA CONTOH.",75,3,3,"+10")]
INK,INK2=C('2a2420'),C('6a604c')
def card(level,focus):
    name,num,flav,hp,thr,spn,echo=level; c=S['vonis_card'].copy()
    txt(c,(CW-tw("PENGASINGAN"))//2,16,"PENGASINGAN",INK2,1,False)
    txt(c,(CW-tw(name,2))//2,25,name,INK,2,False)
    txt(c,(CW-tw(flav))//2,42,flav,INK2,1,False)
    ImageDraw.Draw(c).line([14,52,CW-15,52],fill=C('a89e84'))
    rows=[('icon_hp',"NYAWA AWAL",str(hp)),('icon_nemesis_hunting',"NEMESIS",thr),('icon_enemy_swarm',"MUSUH",spn),('icon_echo',"BONUS ECHO",echo)]
    for i,(ic,lab,val) in enumerate(rows):
        y=60+i*24; src=HS.get(ic) or S[ic]; c.alpha_composite(src,(12,y))
        txt(c,32,y+6,lab,INK,1,False)
        if isinstance(val,int):
            for k in range(3): c.alpha_composite(S['pip_on' if k<val else 'pip_off'],(CW-16-(2-k)*9-7,y+5))
        else: txt(c,CW-14-tw(val,2),y+3,val,INK,2,False)
    ImageDraw.Draw(c).line([14,158,74,158],fill=INK2);
    for k in range(5): px(c,20+k*9,156-(k%2)*2,INK)
    txt(c,14,162,"KETUA MAJELIS",INK2,1,False)
    st=S['stamp_'+name.lower()]; c.alpha_composite(st,(CW-st.width-6,CH-st.height-4))
    if not focus:
        dim=new(CW,CH,(8,8,10,110)); c.alpha_composite(dim,(0,0),) if False else None
        cp=c.load()
        for y in range(CH):
            for x in range(CW):
                r,g,b,a=cp[x,y]
                if a: cp[x,y]=(int(r*0.62),int(g*0.62),int(b*0.66),a)
    return c

def vonis_screen(sel):
    bg=S['panel_04'].copy(); layer(bg,lambda d,L:d.rectangle([0,0,VW,VH],fill=(4,5,8,190)))
    t="VONIS"; txt(bg,(VW-tw(t,4))//2,16,t,C('e8dcc0'),4)
    s="PILIH BERAT PENGASINGAN NAEL."; txt(bg,(VW-tw(s,2))//2,44,s,C('a89e84'),2)
    x0=(VW-(3*CW+2*22))//2; y0=78
    for i,lv in enumerate(VON):
        x=x0+i*(CW+22); y=y0-(6 if i==sel else 0)
        if i==sel: sh=new(CW,CH,(0,0,0,120)); bg.alpha_composite(sh,(x+4,y+8))
        bg.alpha_composite(card(lv,i==sel),(x,y))
        if i==sel: bg.alpha_composite(S['vonis_card_focus'],(x-5,y-5))
        if i==1:
            bg.alpha_composite(S['tag_ribbon'],(x+8,y-7)); txt(bg,x+12,y-4,"DISARANKAN",CY_H,1,False)
    bw,bh=156,22; bx=(VW-bw)//2; by=y0+CH+8
    bg.alpha_composite(nine(H['saved'].get('btn_hover_9slice') or HS['panel_stone_9slice'],bw,bh,4),(bx,by))
    t="TERIMA VONIS"; txt(bg,bx+(bw-tw(t,2))//2,by+6,t,WHITE,2)
    txt(bg,10,VH-12,"VONIS BERLAKU SAMPAI NEW GAME.",C('7a7262'))
    hint="A/D PILIH   ENTER TERIMA"; txt(bg,VW-10-tw(hint),VH-12,hint,C('7a7262'))
    return bg

# tombol hover dari menu pack (kalau ada) — kalau belum, pakai panel batu
mp=os.path.join(ROOT,'menu','sprites','btn_hover_9slice.png')
if os.path.exists(mp): H['saved']['btn_hover_9slice']=Image.open(mp).convert('RGBA')
vbg=S['panel_04'].copy(); layer(vbg,lambda d,L:d.rectangle([0,0,VW,VH],fill=(4,5,8,190))); save('vonis_bg',vbg)

out={}
for i in range(1,7): out[f'prolog_panel_0{i}']=with_caption(i)
out['vonis_A_fokus_sedang']=vonis_screen(1); out['vonis_B_fokus_berat']=vonis_screen(2)
for n,img in out.items():
    img.save(os.path.join(MOCK,n+'_640x360.png')); img.resize((1280,720),Image.NEAREST).save(os.path.join(MOCK,n+'_1280x720.png'))

# ---------------- STORYBOARD SHEET ----------------
seq=[('prolog_panel_01',"PANEL 1","Bengkel Nael, malam. Sendirian.","—"),
     ('prolog_panel_02',"PANEL 2","Alat selesai, cahaya bocor ke jendela.","\"Ia pikir tak ada yang melihat.\""),
     ('prolog_panel_03',"PANEL 3","POV luar: aparat mendobrak, Nael diborgol.","—"),
     ('prolog_panel_04',"PANEL 4","Ruang sidang, hakim membesar di atas Nael.","Hakim: \"Riset ilegal manipulasi waktu. Vonis: pengasingan.\""),
     ('prolog_panel_05',"PANEL 5","Reaksi: tertunduk, kepalan terborgol. Fade to black.","—"),
     ('vonis_A_fokus_sedang',"GAMEPLAY","Layar Vonis (pilih difficulty).","Ringan / Sedang / Berat"),
     ('prolog_panel_06',"PANEL 6","Digiring ke alatnya sendiri, tertelan cahaya portal.","—")]
TWm,THm=640,360; G=28; cols=4
FB=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',22); FR_=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',17)
FT=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',34)
SW=cols*TWm+(cols+1)*G; SH=110+2*(THm+100)+G
sheet=Image.new('RGBA',(SW,SH),C('141210')); sd=ImageDraw.Draw(sheet)
sd.text((G,30),"CHRONOFALL — Storyboard Prolog & Vonis (placeholder pixel art)",font=FT,fill=C('39e0e8'))
for i,(key,lab,desc,cap) in enumerate(seq+[(None,"→ HUB","Masuk Hub pertama kali (run #1).","")]):
    r,c=divmod(i,cols); x=G+c*(TWm+G); y=110+r*(THm+100)
    if key: sheet.alpha_composite(out[key],(x,y))
    else:
        sd.rectangle([x,y,x+TWm,y+THm],outline=C('39e0e8'),width=3)
        sd.text((x+TWm//2-70,y+THm//2-14),"→ HUB",font=FT,fill=C('39e0e8'))
    sd.text((x,y+THm+10),lab,font=FB,fill=C('e8b040') if lab!="GAMEPLAY" else C('39e0e8'))
    sd.text((x+sd.textlength(lab,font=FB)+16,y+THm+13),desc,font=FR_,fill=C('d8ccb0'))
    if cap: sd.text((x,y+THm+42),"Dialog/Caption: "+cap,font=FR_,fill=C('9a9080'))
sheet.save(os.path.join(OUT,'storyboard_sheet.png'))
print("ok",list(S))
