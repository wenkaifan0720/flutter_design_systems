((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,D,A={
vZ(d,e,f,g,h,i){return new A.bHI(i,h,d,f,g,e,null)},
bHI:function bHI(d,e,f,g,h,i,j){var _=this
_.e=d
_.f=e
_.r=f
_.w=g
_.x=h
_.c=i
_.a=j},
Fj:function Fj(d,e,f){this.d9$=d
this.a5$=e
this.a=f},
aAN:function aAN(d,e,f,g,h,i,j,k,l,m,n){var _=this
_.D=d
_.S=e
_.a4=f
_.ad=g
_.ak=h
_.aI=i
_.aF=null
_.bW$=j
_.W$=k
_.bq$=l
_.dy=m
_.b=_.fy=null
_.c=0
_.y=_.d=null
_.z=!0
_.Q=null
_.as=!1
_.at=null
_.ay=$
_.ch=n
_.CW=!1
_.cx=$
_.cy=!0
_.db=!1
_.dx=$},
fwS:function fwS(){},
fxg:function fxg(){},
fwT:function fwT(){},
fwU:function fwU(d){this.a=d},
fx7:function fx7(d){this.a=d},
fwZ:function fwZ(){},
fx_:function fx_(){},
fx0:function fx0(d,e){this.a=d
this.b=e},
cFw:function cFw(){},
cFz:function cFz(){}}
J=c[1]
B=c[0]
C=c[2]
D=c[268]
A=a.updateHolder(c[220],A)
A.bHI.prototype={
az(d){var x=this,w=new A.aAN(x.e,x.f,x.r,x.w,d.u(y.n).w,x.x,0,null,null,new B.aY(),B.aM())
w.aw()
return w},
aJ(d,e){var x=this
y.r.a(e)
e.sqF(x.e)
e.sanj(x.f)
e.skb(x.r)
e.sSi(x.w)
e.aI=x.x
e.sbL(d.u(y.n).w)}}
A.Fj.prototype={}
A.aAN.prototype={
sqF(d){if(d===this.D)return
this.D=d
this.a6()},
sanj(d){if(d===this.S)return
this.S=d
this.a6()},
skb(d){if(d===this.a4)return
this.a4=d
this.a6()},
sSi(d){if(d===this.ad)return
this.ad=d
this.a6()},
sbL(d){if(d===this.ak)return
this.ak=d
this.a6()},
f5(d){if(!(d.b instanceof A.Fj))d.b=new A.Fj(null,null,C.L)},
gaeQ(){var x,w,v,u,t,s,r=this.ik(),q=r.length
if(q===0)return 0
for(x=0,w=0,v=0;u=r.length,v<u;r.length===q||(0,B.F)(r),++v){t=r[v]
s=C.al.d4(t.dy,1/0,t.gaA())
x+=s
w=Math.max(w,s)}q=this.ad?w*u:x
return q+this.D*Math.max(0,u-1)},
gavt(){return C.c.b8(this.ik(),0,new A.fwS())},
b1(d){return C.c.b8(this.ik(),0,new A.fxg())},
aQ(d){return this.gaeQ()},
aG(d){return this.asd(d)},
aM(d){return this.asd(d)},
asd(d){var x,w,v=this,u=v.ik()
if(u.length===0)return 0
if(v.gaeQ()<=d)return C.c.b8(u,0,new A.fwT())
x=C.c.b8(u,0,new A.fwU(isFinite(d)?d:v.gavt()))
w=u.length
return x+v.S*Math.max(0,w-1)},
i_(d){return this.wo(d)},
c0(d){return this.ase(d,!0)},
bu(){this.fy=this.ase(y.a.a(B.H.prototype.gX.call(this)),!1)},
ase(b2,b3){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9=this,b0=null,b1=a9.ik()
if(b1.length===0)return new B.I(B.a7(0,b2.a,b2.b),B.a7(0,b2.c,b2.d))
x=b2.b
w=a9.gaeQ()
v=w>x+1e-10
u=new A.fx7(b3)
t=a9.ak===C.I
s=!v
if(s){r=isFinite(x)?x:w
if(a9.ad){q=b1.length
p=(r-a9.D*Math.max(0,q-1))/q}else p=b0
q=B.a([],y.A)
for(o=b1.length,n=p!=null,m=0;m<b1.length;b1.length===o||(0,B.F)(b1),++m){l=b1[m]
if(n)k=B.dI(b0,p)
else{j=C.al.d4(l.dy,1/0,l.gaA())
k=new B.B(0,j,0,1/0)}q.push(u.$2(l,k))}i=b2.b0(new B.I(r,C.c.b8(q,0,new A.fwZ())))
if(!b3){o=C.c.b8(q,0,new A.fx_())
k=b1.length
h=a9.D
g=k-1
f=i.a
e=Math.max(0,f-(o+h*Math.max(0,g)))
if(n)d=new B.A(0,h)
else{switch(a9.a4.a){case 0:o=new B.A(0,h)
break
case 1:o=new B.A(e,h)
break
case 2:o=new B.A(e/2,h)
break
case 3:o=k>1?new B.A(0,h+e/g):new B.A(0,h)
break
case 4:o=e/k
o=new B.A(o/2,h+o)
break
case 5:o=e/(k+1)
o=new B.A(o,h+o)
break
default:o=b0}d=o}a0=d.a
a1=d.b
for(o=D.aq(b1,0,y.g),n=J.a1(o.a),o=o.b,k=new D.ap(n,o),h=i.b,g=y.o,a2=a0;k.A();){a3=k.c
a3=a3>=0?new B.A(o+a3,n.gK()):B.O(B.ag())
a4=q[a3.a]
a3=a3.b.b
a3.toString
g.a(a3)
a5=t?f-a2-a4.a:a2
a3.a=new B.u(a5,(h-a4.b)/2)
a2+=a4.a+a1}b3=!1}}else{r=isFinite(x)?x:a9.gavt()
a6=B.dI(b0,r)
for(q=B.aE(b1).k("cE<1>"),o=new B.cE(b1,q),o=new B.cy(o,o.gaa(0),q.k("cy<bS.E>")),n=!b3,q=q.k("bS.E"),k=y.o,a7=0;o.A();){h=o.d
if(h==null)h=q.a(h)
a4=u.$2(h,a6)
if(n){h=h.b
h.toString
k.a(h).a=new B.u(0,a7)}a7+=a4.b+a9.S}i=b2.b0(new B.I(r,a7-a9.S))}if(!b3&&a9.aF!==v){q=a9.aF
a9.aF=v
a8=a9.aI
if(a8!=null)s=!s||q!=null
else s=!1
if(s)$.dN.ok$.push(new A.fx0(a8,v))}return i},
U(d,e){return this.hw(d,e)},
cQ(d,e){return this.hM(d,e)}}
A.cFw.prototype={
aD(d){var x,w,v
this.dX(d)
x=this.W$
for(w=y.o;x!=null;){x.aD(d)
v=x.b
v.toString
x=w.a(v).a5$}},
am(){var x,w,v
this.dU()
x=this.W$
for(w=y.o;x!=null;){x.am()
v=x.b
v.toString
x=w.a(v).a5$}}}
A.cFz.prototype={}
var z=a.updateTypes(["q(q)"])
A.fwS.prototype={
$2(d,e){return Math.max(d,e.a0(C.al,1/0,e.gaA()))},
$S:28}
A.fxg.prototype={
$2(d,e){return Math.max(d,e.a0(C.aY,1/0,e.gba()))},
$S:28}
A.fwT.prototype={
$2(d,e){return Math.max(d,e.a0(C.b0,1/0,e.gb7()))},
$S:28}
A.fwU.prototype={
$2(d,e){return d+e.a0(C.b0,this.a,e.gb7())},
$S:28}
A.fx7.prototype={
$2(d,e){var x
if(this.a)x=d.a0(C.ay,e,d.gc7())
else{d.bm(e,!0)
x=d.gE()}return x},
$S:52}
A.fwZ.prototype={
$2(d,e){return Math.max(d,e.b)},
$S:160}
A.fx_.prototype={
$2(d,e){return d+e.a},
$S:160}
A.fx0.prototype={
$1(d){return this.a.$1(this.b)},
$S:4};(function installTearOffs(){var x=a._instance_1u
var w
x(w=A.aAN.prototype,"gba","b1",0)
x(w,"gaA","aQ",0)
x(w,"gbe","aG",0)
x(w,"gb7","aM",0)})();(function inheritance(){var x=a.mixinHard,w=a.mixin,v=a.inherit,u=a.inheritMany
v(A.bHI,B.dk)
v(A.Fj,B.dy)
v(A.cFw,B.w)
v(A.cFz,A.cFw)
v(A.aAN,A.cFz)
u(B.di,[A.fwS,A.fxg,A.fwT,A.fwU,A.fx7,A.fwZ,A.fx_])
v(A.fx0,B.cl)
x(A.cFw,B.al)
w(A.cFz,B.ba)})()
B.bO(b.typeUniverse,JSON.parse('{"Fj":{"dy":["w"],"dB":[],"eB":["w"],"e8":[]},"bHI":{"dk":[],"aP":[],"b":[]},"aAN":{"ba":["w","Fj"],"w":[],"al":["w","Fj"],"H":[],"aQ":[],"al.1":"Fj","ba.1":"Fj","ba.0":"w","al.0":"w"}}'))
var y={a:B.G("B"),n:B.G("dv"),A:B.G("o<I>"),g:B.G("w"),o:B.G("Fj"),r:B.G("aAN")}};
(a=>{a["1sikbbiOshIxnJbHmc9L9OhASW0="]=a.current})($__dart_deferred_initializers__);