"""Tailored hood and pierced ceramic mask for the Eave Runner art pass."""
import math


def build(ctx):
    add, tube, braid = ctx['add'], ctx['tube'], ctx['braid']
    pi, tau = math.pi, math.tau
    # Every row follows a cut hood pattern. The front edges meet at a pointed
    # brow; the crown then sweeps backwards instead of forming a round helmet.
    rows = [(1.550,.087,.094,-.020,.91),(1.585,.096,.111,-.028,.74),
            (1.625,.101,.123,-.035,.69),(1.665,.106,.126,-.035,.66),
            (1.705,.109,.126,-.035,.64),(1.744,.110,.128,-.035,.57),
            (1.775,.104,.130,-.035,.42),(1.796,.090,.124,-.035,.00),
            (1.812,.061,.090,-.008,.00),(1.827,.024,.049,.015,.00),
            (1.835,.001,.002,.042,.00)]
    def hood(v,u,inset=0):
        r=min(len(rows)-2,int(v*(len(rows)-1))); f=v*(len(rows)-1)-r
        z,rx,ry,cy,g=[rows[r][j]*(1-f)+rows[r+1][j]*f for j in range(5)]
        a=(-pi+g)+(tau-2*g)*u; front=max(0,-math.cos(a))
        # Cut cloth has broad facets between angular folds, not the radial
        # smoothness of a helmet. Two stitched diagonal gathers break the dome.
        ridge=.002*math.cos(6*a+.5)*math.sin(pi*v)
        for centre in [.025+.065*v,.970-.080*v]:
            d=(u-centre)/.045
            ridge += .0072*math.exp(-d*d)-.0030*math.exp(-((d-1.4)/.75)**2)
        ridge*=math.sin(pi*min(.99,.05+v))
        sx=math.copysign(abs(math.sin(a))**.79,math.sin(a))
        sy=math.copysign(abs(math.cos(a))**.79,math.cos(a))
        brow_drop=.010*front**8*math.exp(-((v-.70)/.105)**2)
        ripple=(.003*math.sin(4*a+v*7)+.008*math.sin(a-.6))*math.sin(pi*v)
        y=cy+(ry+ridge-inset)*sy-.032*front**7
        if y>0: y*=.68
        return ((rx+ridge-inset)*sx-.029*v**4,y,
                min(1.835,z+ripple+.010*(1-front)*math.sin(pi*v)-brow_drop))
    # Six real tailored panels, each with lengthwise UVs and a fine centre seam.
    for panel in range(6):
        vs=[]; fs=[]; uv=[]; nx=12; ny=30
        for j in range(ny+1):
            for i in range(nx+1):
                vs.append(hood(j/ny,(panel+i/nx)/6)); uv.append((i/nx*.48,j/ny*1.7))
        for j in range(ny):
            for i in range(nx):
                q=j*(nx+1)+i;fs.append((q,q+1,q+nx+2,q+nx+1))
        add('Tailored hood panel %02d'%panel,'indigo',vs,fs,bone='head',uv=uv)
    # A close dark lining means the opening has depth without a giant black void.
    vs=[hood(j/24,i/48,.006) for j in range(25) for i in range(49)]
    fs=[(j*49+i,j*49+i+49,j*49+i+50,j*49+i+1) for j in range(24) for i in range(48)]
    add('Hood folded charcoal lining','navy',vs,fs,bone='head')
    for side,u in [('left',0),('right',1)]:
        lip=[hood(v*.70,u,-.001) for v in [i/48 for i in range(49)]]
        tube('Rolled dark face opening '+side,lip,.0042,'navy','head',sides=10)
        for i in range(17):
            v=.07+i*.034
            tube('Hand sewn opening stitch '+side,[hood(v,u*.992+.004,-.0018),hood(v+.009,u*.992+.004,-.0018)],.00065,'rope','head',sides=5)
    for p in [1,2,4,5]:
        u=p/6; path=[hood(.12+i*.82/35,u,-.0012) for i in range(36)]
        tube('Hood tailored crown seam %d'%p,path,.0014,'navy','head',sides=6)
        for k in range(10):
            v=.20+k*.055
            tube('Sparse crown topstitch',[hood(v,u-.005,-.002),hood(v+.012,u-.005,-.002)],.00055,'rope','head',sides=4)
    # Small offset repair, following the hood's surface rather than floating.
    patch=[hood(.35+j*.15/6,.615+i*.040/5,-.0018) for j in range(7) for i in range(6)]
    faces=[(j*6+i,j*6+i+1,j*6+i+7,j*6+i+6) for j in range(6) for i in range(5)]
    add('Hood old offset square repair','faded',patch,faces,bone='head',uv=[(i/5,j/6) for j in range(7) for i in range(6)])
    for j in range(7):
        for u in [.616,.654]:
            v=.35+j*.022
            tube('Hood patch fastening',[hood(v,u,-.003),hood(v+.010,u,-.003)],.00065,'rope','head',sides=4)

    # Pierced ceramic: eye holes are absent faces, with ceramic inner walls.
    # The irregular edge and central planar ridge survive a gameplay-sized view.
    mr=[(1.565,.0035),(1.579,.022),(1.598,.042),(1.619,.057),
        (1.647,.067),(1.671,.0715),(1.682,.0725),(1.697,.071),
        (1.718,.066),(1.739,.057),(1.756,.042),(1.771,.022),(1.775,.006)]
    def surface(x,z):
        r=next((i for i in range(len(mr)-1) if mr[i+1][0]>=z),len(mr)-2)
        f=max(0,min(1,(z-mr[r][0])/(mr[r+1][0]-mr[r][0])))
        half=mr[r][1]*(1-f)+mr[r+1][1]*f; t=max(-1,min(1,x/max(.001,half)))
        # Distinct bridge, shallow cheeks and receding temples, no oval balloon.
        return -.158-.012*max(0,1-abs(t)*3.2)+.026*abs(t)**1.65-.0015*math.cos(z*47)
    vs=[]; uv=[]; n=32
    for r,(z,w) in enumerate(mr):
        for j in range(n+1):
            t=j/n*2-1; x=t*w; zz=z
            if r in [5,6]:
                eyehalf=.0042*max(.12,min(1,(.80-abs(t))/.55))
                zz=1.669+.027*abs(t)+(-eyehalf if r==5 else eyehalf)
            if j==0 and r in [8,9]: x+=.0025
            if j==n and r==3: zz+=.005; x-=.003
            vs.append((x,surface(x,z),zz)); uv.append((j/n,(z-1.565)/.210))
    fs=[]
    for r in range(len(mr)-1):
        for j in range(n):
            if r==5 and j in list(range(4,12))+list(range(20,28)): continue
            q=r*(n+1)+j; fs.append((q,q+1,q+n+2,q+n+1))
    # Track every exposed boundary, including both eye apertures.
    edges={}
    for f in fs:
        for a,b in zip(f,f[1:]+f[:1]):
            key=tuple(sorted((a,b))); edges[key]=edges.get(key,0)+1
    edgeverts=[]; edgefaces=[]
    for (a,b),count in edges.items():
        if count!=1: continue
        pa,pb=vs[a],vs[b]; q=len(edgeverts)
        edgeverts += [pa,pb,(pb[0],pb[1]+.006,pb[2]),(pa[0],pa[1]+.006,pa[2])]
        edgefaces.append((q,q+1,q+2,q+3))
    add('Pierced ivory face with angled cheek planes','ivory',vs,fs,bone='head',uv=uv,smooth=True)
    add('Ceramic mask cut edge and eye recess walls','edge',edgeverts,edgefaces,bone='head',smooth=False)
    # Dark backing sits just behind ceramic; cyan is a narrow lower lid reflection.
    bv=[(x,y+.008,z) for x,y,z in vs]
    bf=[(r*(n+1)+j,r*(n+1)+j+1,(r+1)*(n+1)+j+1,(r+1)*(n+1)+j) for r in range(len(mr)-1) for j in range(n)]
    add('Dark recessed mask backing','dark',bv,bf,bone='head',uv=uv)
    for sign in [-1,1]:
        pts=[]
        for j in range(9):
            x=sign*(.023+j*.0031); t=abs(x/.0725)
            h=.0042*max(.12,min(1,(.80-t)/.55)); z=1.669+.027*t-h+.0009
            pts.append((x,surface(x,z)+.0055,z))
        tube('Restrained blue slit reflection',pts,.00055,'charge','head',sides=5)
    crack=[(.0025,1.759),(.0075,1.743),(.004,1.722),(.0145,1.703),(.0075,1.687),(.011,1.662),(.0035,1.639),(.010,1.617),(.005,1.593),(.0025,1.574)]
    path=[(x,surface(x,z)-.0010,z) for x,z in crack]
    tube('Fine broken ceramic fracture',path,.00115,'ink','head',sides=6)
    tube('Hairline indigo repaired fracture',[(x,y-.0006,z) for x,y,z in path],.00042,'charge','head',sides=5)
    for x,z in [crack[2],crack[5],crack[7]]:
        tube('Small bronze ceramic repair staple',[(x-.004,surface(x-.004,z)-.002,z-.001),(x+.004,surface(x+.004,z)-.002,z+.001)],.00075,'metal','head',sides=6)
    # The paired crest is intentionally bronze/ink, not a luminous forehead eye.
    for sign in [-1,1]:
        pts=[]
        for j in range(49):
            a=j*tau/48; x=sign*.0075+.010*math.cos(a); z=1.744+.011*math.sin(a)
            pts.append((x,surface(x,z)-.0035-.0014*math.sin(a*2),z))
        tube('Bronze paired thread forehead crest',pts,.0022,'metal','head',sides=8)
    for sign in [-1,1]:
        x=sign*.065; z=1.716
        braid('Ceramic side fastening cord',[(x,surface(x,z)+.002,z),(sign*.077,-.105,z+.004),(sign*.088,-.050,z+.008)],.0022,'rope','head',pitch=.023,strands=3,smooth=5)
