"""CHRONOFALL — Main Menu placeholder asset generator (pixel art 1x, layar logis 640x360)."""
import runpy, os, math, random
from PIL import Image, ImageDraw
H = runpy.run_path(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'build_hud.py'))
C,new,px,from_ascii,add_outline,add_glow,lerp,shade,bevel_frame,nine,text,FONT = (H[k] for k in
    ('C','new','px','from_ascii','add_outline','add_glow','lerp','shade','bevel_frame','nine','text','FONT'))
K,ST_HI,ST_LO,CY,CY_H,CY_D,CY_DD,LAVA,LAVA_H,LAVA_D = (H[k] for k in ('K','ST_HI','ST_LO','CY','CY_H','CY_D','CY_DD','LAVA','LAVA_H','LAVA_D'))
TRANSP=(0,0,0,0)
FONT['?']="111001011000010"; FONT[',']="000000000010100"; FONT['!']="010010010000010"

ROOT=os.path.dirname(os.path.abspath(__file__))
OUT=os.path.join(ROOT,'menu'); SPR=os.path.join(OUT,'sprites'); MOCK=os.path.join(OUT,'mockup')
os.makedirs(SPR,exist_ok=True); os.makedirs(MOCK,exist_ok=True)
VW,VH=640,360
S={}
def save(n,img): img.save(os.path.join(SPR,n+'.png')); S[n]=img; return img

def text2(img,x,y,s,col,sh=True):
    """font 3x5 di-scale 2x (6x10 per huruf)."""
    for i,ch in enumerate(s.upper()):
        g=FONT.get(ch,FONT[' '])
        for r in range(5):
            for c in range(3):
                if g[r*3+c]=='1':
                    bx,by=x+i*8+c*2,y+r*2
                    for dx in range(2):
                        for dy in range(2):
                            if sh: px(img,bx+dx+1,by+dy+1,K)
                    for dx in range(2):
                        for dy in range(2): px(img,bx+dx,by+dy,col)
def text2_w(s): return len(s)*8-2
def text_w(s): return len(s)*4-1

# ================= 1. TITLE LOGO =================
G57={'C':["01110","10001","10000","10000","10000","10001","01110"],'H':["10001","10001","10001","11111","10001","10001","10001"],
     'R':["11110","10001","10001","11110","10100","10010","10001"],'O':["01110","10001","10001","10001","10001","10001","01110"],
     'N':["10001","11001","10101","10011","10001","10001","10001"],'F':["11111","10000","10000","11110","10000","10000","10000"],
     'A':["01110","10001","10001","11111","10001","10001","10001"],'L':["10000","10000","10000","10000","10000","10000","11111"]}
def title_logo():
    word="CHRONOFALL"; sc=4; adv=5*sc+4; drop=[0,0,0,0,0,0,1,2,3,4]   # "FALL" sedikit jatuh
    W=len(word)*adv-4+8; Hh=7*sc+8+6
    fill=new(W,Hh); portal=new(W,Hh)
    for i,ch in enumerate(word):
        g=G57[ch]; ox=4+i*adv; oy=3+drop[i]
        for r in range(7):
            for c in range(5):
                if g[r][c]=='1':
                    for dy in range(sc):
                        for dx in range(sc):
                            yy=r*sc+dy; t=yy/(7*sc-1)
                            if i==3:   # huruf O = portal waktu (cyan)
                                col=lerp(CY_H,CY_D,t)
                                px(portal,ox+c*sc+dx,oy+yy,col)
                            else:
                                col=lerp(C('e8dcb8'),C('7a6648'),t)
                                if dy==0 and (r==0 or g[r-1][c]=='0'): col=C('fff4d8')
                                px(fill,ox+c*sc+dx,oy+yy,col)
    # retakan cyan menyilang (ancient tech bocor)
    crack=[(0,9),(1,9),(2,10),(3,10),(4,11),(5,11),(6,12),(7,12),(8,12),(9,13),(10,13),(11,14),(12,14),(13,15),(14,15),(15,15),(16,16),(17,16)]
    fp=fill.load()
    for k in range(0,W,18):
        for (dx,dy) in crack:
            x=k+dx; y=dy+(k//18)%3
            if 0<=x<W and fp[x,y][3]: fp[x,y]=CY if (x+y)%3 else CY_H
    logo=new(W,Hh)
    logo.alpha_composite(fill); logo.alpha_composite(portal)
    logo=add_outline(add_outline(logo,K),K)
    shadow=new(W,Hh+3); sp=shadow.load(); lp=logo.load()
    for y in range(Hh):
        for x in range(W):
            if lp[x,y][3] and y+3<Hh+3 and x+2<W: sp[x+2,y+3]=(0,0,0,150)
    out=new(W,Hh+3); out.alpha_composite(shadow)
    pg=add_glow(add_glow(portal,(57,224,232,110)),(57,224,232,50))
    out.alpha_composite(pg); out.alpha_composite(logo)
    return out
save('title_logo',title_logo())

# ================= 2. BUTTON STYLEBOX (9-slice 16x16, margin 4) =================
def btn(ring,fill,accent=None,inv=False,alpha=255):
    hi,lo=ring
    f=bevel_frame(16,16,[(lo,hi) if inv else (hi,lo)])
    for y in range(3,13):
        for x in range(3,13):
            c=fill if (x*3+y)%7 else shade(fill,1.2)
            px(f,x,y,c)
    if accent:
        for y in range(3,13): px(f,3,y,accent)
        px(f,4,3,accent)
    if alpha<255:
        p=f.load()
        for y in range(16):
            for x in range(16):
                r,g,b,a=p[x,y]
                if a: p[x,y]=(r,g,b,int(a*alpha/255))
    return f
save('btn_normal_9slice',btn((ST_HI,ST_LO),C('231e19')))
save('btn_hover_9slice',btn((C('b8a47e'),C('4a3f33')),C('2e2a24'),accent=CY))
save('btn_pressed_9slice',btn((ST_HI,ST_LO),C('17130f'),accent=CY_D,inv=True))
save('btn_disabled_9slice',btn((C('4a4540'),C('2a2723')),C('1a1816'),alpha=210))
fo=new(16,16)
for i in range(16):
    for (x,y) in ((i,0),(i,15),(0,i),(15,i)):
        if i<4 or i>11: px(fo,x,y,CY)   # sudut braket
save('btn_focus_9slice',fo)
SEL=["k.....","kck...","kcck..","kccck.","kcck..","kck...","k....."]
save('selector_arrow',add_glow(from_ascii(SEL,{'k':K,'c':CY}),(57,224,232,90)))
save('dialog_panel_9slice',H['saved']['panel_stone_9slice'])

# ================= 3. BACKGROUND LAYERS =================
rnd=random.Random(42)
def sky():
    img=new(VW,VH); d=ImageDraw.Draw(img)
    for y in range(VH):
        t=min(1,y/250); col=lerp(C('0a1215'),C('1f2c26'),t)
        if 180<y<260: col=lerp(col,C('3a2a20'),(1-abs(y-225)/45)*0.45)   # pendaran lava di horizon
        d.line([0,y,VW,y],fill=col)
    for _ in range(70):
        x,y=rnd.randrange(VW),rnd.randrange(150); px(img,x,y,rnd.choice([C('5a6a66'),C('8a9a90'),C('3a4844')]))
    return img
def mountains():
    img=new(VW,VH); d=ImageDraw.Draw(img); y=210; pts=[(0,VH)]
    for x in range(0,VW+8,8):
        y+=rnd.randint(-6,6); y=max(185,min(235,y))
        if 500<x<580: y=int(150+abs(x-540)*1.6)  # gunung berapi
        pts.append((x,y))
    pts.append((VW,VH)); d.polygon(pts,fill=C('182219'))
    for i in range(30):   # asap & lava di kawah
        px(img,536+rnd.randint(-5,5),148+rnd.randint(0,3),rnd.choice([LAVA,LAVA_H,LAVA_D]))
    gl=new(VW,VH); g=ImageDraw.Draw(gl)
    for r,a in ((40,18),(24,30),(12,45)): g.ellipse([540-r,148-r,540+r,148+r],fill=(224,112,42,a))
    out=new(VW,VH); out.alpha_composite(gl); out.alpha_composite(img); return out
def jungle():
    img=new(VW,VH); d=ImageDraw.Draw(img); base=C('101812'); top=C('17241a')
    for x in range(-20,VW+20,14):   # pakis raksasa purba
        h=rnd.randint(60,120); bx=x+rnd.randint(-5,5); gy=290
        d.line([bx,gy,bx+rnd.randint(-4,4),gy-h],fill=base,width=3)
        tx,ty=bx,gy-h
        for a in range(0,360,30):
            r=math.radians(a); L=rnd.randint(14,24)
            ex,ey=tx+math.cos(r)*L,ty+math.sin(r)*L*0.55+6
            d.line([tx,ty,ex,ey],fill=top if a>180 else base,width=2)
    d.rectangle([0,270,VW,VH],fill=base)
    return img
def ruins_portal():
    img=new(VW,VH); d=ImageDraw.Draw(img); cx=430; gy=300
    st,sth,std=C('4a4438'),C('6a6250'),C('2e2a22')
    for x0 in (cx-52,cx+34):   # pilar
        d.rectangle([x0,gy-96,x0+18,gy],fill=st,outline=K); d.line([x0+1,gy-95,x0+1,gy-1],fill=sth)
        d.line([x0+17,gy-95,x0+17,gy-1],fill=std)
        for y in range(gy-86,gy-6,10):
            d.line([x0+5,y,x0+12,y],fill=CY_D); px(img,x0+8,y+3,CY)
        for y in range(gy-90,gy,14): d.line([x0+1,y,x0+16,y],fill=std)
    d.rectangle([cx-60,gy-112,cx+60,gy-96],fill=st,outline=K); d.line([cx-59,gy-111,cx+59,gy-111],fill=sth)
    for x in range(cx-50,cx+50,7): px(img,x,gy-104,CY)
    d.polygon([(cx+44,gy-112),(cx+60,gy-112),(cx+60,gy-104)],fill=TRANSP)  # retak lintel
    for (x,y,w,h) in ((cx-80,gy-10,16,10),(cx+60,gy-7,12,7),(cx-30,gy-4,9,4)):
        d.rectangle([x,y,x+w,y+h],fill=st,outline=K)
    d.rectangle([0,gy,VW,VH],fill=C('15130e'))
    for x in range(0,VW,3):
        if rnd.random()<0.5: d.line([x,gy,x+rnd.randint(-1,1),gy-rnd.randint(1,4)],fill=C('1f2c18'))
    return img
def portal_layer():
    img=new(VW,VH); p=img.load(); cx,cy=430,248
    for y in range(cy-46,cy+48):
        for x in range(cx-34,cx+35):
            dx,dy=(x-cx)/32,(y-cy)/46; d=math.hypot(dx,dy)
            if d<1:
                ang=math.atan2(dy,dx); sw=math.sin(ang*3+d*9)
                if d>0.88: c=CY_H
                elif sw>0.4: c=CY if d>0.3 else CY_H
                elif sw>-0.3: c=CY_D
                else: c=CY_DD
                if (x+y)%2 and d<0.55 and sw<0: c=CY_D
                p[x,y]=c
    return img
def portal_glow():
    img=new(VW,VH); g=ImageDraw.Draw(img); cx,cy=430,248
    for r,a in ((90,14),(66,22),(48,34)): g.ellipse([cx-r*0.8,cy-r,cx+r*0.8,cy+r],fill=(57,224,232,a))
    g.ellipse([cx-60,292,cx+60,312],fill=(57,224,232,40))
    return img
def nael_sil():
    N=["...kkkk...","..kkkkkk..","..kkkkkk..","...kkkk...","..kkkkkkg.",".kkkkkkkg.","kkkkkkkkkk","kkkkkkkkkk",
       "kckkkkkkck",".kkkkkkkk.","..kkkkkk..","..kkk.kkk.","..kk...kk.","..kk...kk.",".kkk...kkk"]
    img=from_ascii(N,{'k':C('0a0c0b'),'c':C('5a5a5a'),'g':C('3a3a3a')})
    p=img.load()   # rim light cyan dari portal
    for y in range(img.height):
        for x in range(img.width-1,-1,-1):
            if p[x,y][3]: p[x,y]=CY_D; break
    return img
def nemesis_eyes(open_=True):
    img=new(18,8)
    for ex in (2,12):
        if open_:
            for (x,y,c) in ((ex,3,C('ff3a2a')),(ex+1,3,C('ff3a2a')),(ex+2,3,C('ff8a4a')),(ex+1,4,C('a8201a'))): px(img,x,y,c)
        else: px(img,ex,4,C('5a1410')); px(img,ex+1,4,C('5a1410')); px(img,ex+2,4,C('5a1410'))
    return add_glow(img,(255,58,42,60)) if open_ else img
def foreground():
    img=new(VW,VH); d=ImageDraw.Draw(img); col=C('060807')
    for (bx,by,flip) in ((0,360,1),(640,360,-1),(600,0,-1)):
        for i in range(7):
            a=math.radians(rnd.randint(-80,-10) if flip==1 else rnd.randint(190,260))
            if by==0: a=math.radians(rnd.randint(100,170))
            L=rnd.randint(60,120); ex,ey=bx+math.cos(a)*L,by+math.sin(a)*L
            nx,ny=-math.sin(a),math.cos(a)
            pts=[(bx,by)]
            for t in range(1,9):
                tt=t/8; w=math.sin(tt*math.pi)*rnd.randint(8,12)
                pts.append((bx+(ex-bx)*tt+nx*w,by+(ey-by)*tt+ny*w))
            pts.append((ex,ey))
            for t in range(7,0,-1):
                tt=t/8; w=math.sin(tt*math.pi)*9
                pts.append((bx+(ex-bx)*tt-nx*w,by+(ey-by)*tt-ny*w))
            d.polygon(pts,fill=col)
    return img
def legibility():
    img=new(VW,VH); p=img.load()
    for x in range(VW):
        a=int(max(0,1-x/330)**1.4*190)
        for y in range(VH): p[x,y]=(6,6,5,a)
    for y in range(VH):   # vignette atas-bawah
        e=max(0,(abs(y-VH/2)-130)/50)
        for x in range(VW):
            r,g,b,a=p[x,y]; p[x,y]=(6,6,5,min(255,a+int(e*120)))
    return img

save('bg_01_sky',sky()); save('bg_02_mountains',mountains()); save('bg_03_jungle',jungle())
save('bg_04_ruins',ruins_portal()); save('bg_05_portal',portal_layer()); save('bg_05b_portal_glow',portal_glow())
save('nael_silhouette',nael_sil()); save('nemesis_eyes_open',nemesis_eyes(True)); save('nemesis_eyes_closed',nemesis_eyes(False))
save('bg_06_foreground',foreground()); save('bg_07_legibility_gradient',legibility())

def background(eyes=True):
    bg=new(VW,VH)
    for n in ('bg_01_sky','bg_02_mountains','bg_03_jungle','bg_05b_portal_glow','bg_04_ruins','bg_05_portal'): bg.alpha_composite(S[n])
    fog=new(VW,VH); ImageDraw.Draw(fog).rectangle([0,262,VW,292],fill=(120,160,150,18)); bg.alpha_composite(fog)
    bg.alpha_composite(S['nael_silhouette'],(425,286))
    bg.alpha_composite(S['nemesis_eyes_open' if eyes else 'nemesis_eyes_closed'],(560,258))
    for n in ('bg_06_foreground','bg_07_legibility_gradient'): bg.alpha_composite(S[n])
    return bg
bgfull=background(); bgfull.save(os.path.join(SPR,'bg_full_flattened.png'))

# ================= 4. MOCKUP =================
TX,TY=40,46; BX,BY,BW,BH,GAP=52,138,128,22,6
TXT={'normal':C('d8ccb0'),'hover':C('ffffff'),'pressed':C('b8ac90'),'disabled':C('5e574e')}
def button(img,y,label,state,focus=False):
    st={'normal':'btn_normal_9slice','hover':'btn_hover_9slice','pressed':'btn_pressed_9slice','disabled':'btn_disabled_9slice'}[state]
    img.alpha_composite(nine(S[st],BW,BH,4),(BX,y))
    if focus: img.alpha_composite(nine(S['btn_focus_9slice'],BW+4,BH+4,4),(BX-2,y-2))
    off=1 if state=='pressed' else 0
    text2(img,BX+14+off,y+6+off,label,TXT[state])
    if state in('hover','pressed'): img.alpha_composite(S['selector_arrow'],(BX-12,y+7))
def menu(states,dialog=False,eyes=True):
    img=background(eyes)
    img.alpha_composite(S['title_logo'],(TX,TY))
    text(img,TX+6,TY+S['title_logo'].height+5,"NOTHING IS PERMANENT.",C('8a8270'))
    for i,(label,state,focus) in enumerate(states):
        button(img,BY+i*(BH+GAP),label,state,focus)
    text(img,10,VH-12,"V0.1  KELOMPOK IRIS - ASE LAB",C('6a6458'))
    hint="W/S PILIH   ENTER OK"; text(img,VW-10-text_w(hint),VH-12,hint,C('6a6458'))
    if dialog:
        dim=new(VW,VH,(4,4,3,170)); img.alpha_composite(dim)
        DW,DH=260,110; dx,dy=(VW-DW)//2,(VH-DH)//2
        img.alpha_composite(nine(S['dialog_panel_9slice'],DW,DH,4),(dx,dy))
        t="START NEW GAME?"; text2(img,dx+(DW-text2_w(t))//2,dy+14,t,C('ffffff'))
        for i,l in enumerate(("SAVE LAMA AKAN DIHAPUS:","ECHO POINTS DAN VONIS DIRESET.")):
            text(img,dx+(DW-text_w(l))//2,dy+36+i*9,l,C('e8b040') if i==0 else C('c8bca0'))
        bw=90
        for j,(l,stt) in enumerate((("CANCEL",'hover'),("YES",'normal'))):
            x=dx+20+j*(bw+40); y=dy+DH-34
            img.alpha_composite(nine(S['btn_hover_9slice' if stt=='hover' else 'btn_normal_9slice'],bw,22,4),(x,y))
            text2(img,x+(bw-text2_w(l))//2,y+6,l,TXT[stt])
        img.alpha_composite(S['selector_arrow'],(dx+8,dy+DH-27))
    return img
A=menu([("START",'hover',True),("CONTINUE",'disabled',False),("SETTINGS",'normal',False),("QUIT",'normal',False)])
B=menu([("START",'normal',False),("CONTINUE",'hover',True),("SETTINGS",'normal',False),("QUIT",'normal',False)],eyes=False)
Cc=menu([("START",'pressed',True),("CONTINUE",'normal',False),("SETTINGS",'normal',False),("QUIT",'normal',False)],dialog=True)
for n,img in (('A_belum_ada_save',A),('B_sudah_ada_save',B),('C_konfirmasi_new_game',Cc)):
    img.save(os.path.join(MOCK,f'menu_{n}_640x360.png')); img.resize((1280,720),Image.NEAREST).save(os.path.join(MOCK,f'menu_{n}_1280x720.png'))
print({k:v.size for k,v in S.items()})
