((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var C,B,A={
rs(d){var x=d.gSy()/255,w=d.gLD()/255,v=d.gPN()/255,u=Math.max(x,Math.max(w,v)),t=u-Math.min(x,Math.min(w,v)),s=d.gjl(),r=D.i2z(x,w,v,u,t),q=u===0?0:t/u
return new A.cK(s/255,r,q,u)},
cK:function cK(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
i4d(d,e,f){var x,w
switch(e.a){case 0:x=d.a
w=B.i.I(f,0,360)
d.sq(new A.cK(x.a,w,x.c,x.d))
break
case 1:x=d.a
w=B.i.I(f,0,1)
d.sq(new A.cK(x.a,x.b,w,x.d))
break
case 2:x=d.a
w=B.i.I(f,0,1)
d.sq(new A.cK(x.a,x.b,x.c,w))
break
case 3:x=d.a
d.sq(new A.cK(B.i.I(f,0,1),x.b,x.c,x.d))
break}},
ifS(d,e,f,g){return new A.aC8(e,d,g,f,null)},
zz(d,e,f,g,h,i,j,k){return new A.biC(g,d,f,k,j,!1,e,h,null)},
rg:function rg(d,e){var _=this
_.a=d
_.N$=0
_.P$=e
_.aq$=_.ar$=0},
cHo:function cHo(){},
hj:function hj(d,e){this.a=d
this.b=e},
aC7:function aC7(d,e,f,g){var _=this
_.c=d
_.d=e
_.e=f
_.a=g},
aTl:function aTl(){var _=this
_.d=!1
_.e=$
_.r=_.f=!1
_.c=_.a=null},
ebw:function ebw(d){this.a=d},
ebv:function ebv(d,e){this.a=d
this.b=e},
ebt:function ebt(d,e,f){this.a=d
this.b=e
this.c=f},
ebu:function ebu(d,e){this.a=d
this.b=e},
ebs:function ebs(d,e){this.a=d
this.b=e},
ebr:function ebr(d,e){this.a=d
this.b=e},
ebq:function ebq(d){this.a=d},
ebj:function ebj(d,e){this.a=d
this.b=e},
ebp:function ebp(d,e,f){this.a=d
this.b=e
this.c=f},
ebl:function ebl(d,e){this.a=d
this.b=e},
ebn:function ebn(d){this.a=d},
ebg:function ebg(d){this.a=d},
ebo:function ebo(d,e){this.a=d
this.b=e},
ebm:function ebm(d){this.a=d},
ebh:function ebh(d){this.a=d},
ebk:function ebk(d){this.a=d},
ebi:function ebi(d){this.a=d},
aC8:function aC8(d,e,f,g,h){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.a=h},
bR6:function bR6(){this.d=!1
this.c=this.a=null},
ebJ:function ebJ(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},
ebH:function ebH(d,e,f,g,h,i,j){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i
_.r=j},
ebI:function ebI(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
ebD:function ebD(d){this.a=d},
ebF:function ebF(d){this.a=d},
ebx:function ebx(d){this.a=d},
ebG:function ebG(d){this.a=d},
ebE:function ebE(d){this.a=d},
eby:function eby(d){this.a=d},
ebC:function ebC(d){this.a=d},
ebz:function ebz(d){this.a=d},
ebA:function ebA(d){this.a=d},
ebB:function ebB(d,e){this.a=d
this.b=e},
biC:function biC(d,e,f,g,h,i,j,k,l){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.r=h
_.w=i
_.x=j
_.y=k
_.a=l}},F,I,D,E,G,H,K
C=c[0]
B=c[2]
A=a.updateHolder(c[126],A)
F=c[582]
I=c[261]
D=c[242]
E=c[229]
G=c[264]
H=c[244]
K=c[426]
A.cK.prototype={
bN(){var x=this,w=x.d,v=x.c*w,u=x.b
return C.i1I(x.a,u,v,v*(1-Math.abs(B.i.a3(u/60,2)-1)),w-v)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
return e instanceof A.cK&&e.a===x.a&&e.b===x.b&&e.c===x.c&&e.d===x.d},
gY(d){var x=this
return C.aK(x.a,x.b,x.c,x.d,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a)},
v(d){var x=this
return"HSVColor("+C.al(x.a)+", "+C.al(x.b)+", "+C.al(x.c)+", "+C.al(x.d)+")"}}
A.rg.prototype={
sfK(d){var x=A.rs(d),w=x.c
this.sq(w===0||x.d===0?new A.cK(x.a,this.a.b,w,x.d):x)},
gmV(){var x=this.a.bN(),w=new A.cHo(),v="#"+C.al(w.$1(x.b))+C.al(w.$1(x.c))+C.al(w.$1(x.d)),u=x.a
return u>=1?v:v+C.al(w.$1(u))},
LQ(d){var x,w,v,u,t,s,r=B.q.c8(d)
if(B.q.fL(r,"#"))r=B.q.fT(r,1)
x=C.ex("^[0-9a-fA-F]+$",!0,!1)
if(!x.b.test(r))return!1
if(r.length===3){x=C.a([],y.x)
for(w=r.split(""),v=w.length,u=0;u<v;++u){t=w[u]
x.push(t+t)}r=B.c.lE(x)}if(r.length===6)r+="FF"
if(r.length!==8)return!1
s=C.ob(r,16)
this.sfK(C.eo(((s&255)<<24|B.o.mK(s,8))>>>0))
return!0}}
A.hj.prototype={}
A.aC7.prototype={
n(){return new A.aTl()},
fG(d,e){return this.d.$2(d,e)},
alL(d,e){return this.e.$2(d,e)}}
A.aTl.prototype={
ap(){var x=this
x.aA()
E.WG()
x.e!==$&&C.cQ()
x.e=new E.zA(new A.ebw(x))},
k(){var x=this.e
x===$&&C.i()
$.Bz().af(0,x.gys())
this.L()},
aq8(d,e){var x,w,v=e.a
if(v<=0||e.b<=0)return
x=this.a.c
w=x.a
v=B.i.I(d.a/v,0,1)
x.sq(new A.cK(w.a,w.b,v,B.i.I(1-d.b/e.b,0,1)))},
b7W(d,e){var x,w,v,u,t,s,r=this
if(!(e instanceof C.dm)&&!(e instanceof C.fm))return B.ab
r.a.toString
x=$.eu.fN$
x===$&&C.i()
x=x.a
w=C.W(x).j("ba<2>")
v=0.01*(new C.ba(x,w).l(0,B.iX)||new C.ba(x,w).l(0,B.jE)?10:1)
u=r.a.c.a
t=e.b
if(t.i(0,B.bB)){x=r.a.c
w=u.c
s=x.a
w=B.i.I(w+v,0,1)
x.sq(new A.cK(s.a,s.b,w,s.d))}else if(t.i(0,B.bN)){x=r.a.c
w=u.c
s=x.a
w=B.i.I(w-v,0,1)
x.sq(new A.cK(s.a,s.b,w,s.d))}else if(t.i(0,B.bs)){x=r.a.c
w=u.d
s=x.a
w=B.i.I(w+v,0,1)
x.sq(new A.cK(s.a,s.b,s.c,w))}else if(t.i(0,B.bh)){x=r.a.c
w=u.d
s=x.a
w=B.i.I(w-v,0,1)
x.sq(new A.cK(s.a,s.b,s.c,w))}else return B.ab
return B.aD},
h(d){var x,w=C.Z(d,G.P,y.w)
if(w==null)w=B.N
x=C.cW(d)
return C.fE(new D.ea(this.a.c,new A.ebt(this,w,x),null,null,y.q),B.K)}}
A.aC8.prototype={
n(){return new A.bR6()},
bWE(d,e,f){return this.e.$3(d,e,f)}}
A.bR6.prototype={
h(d){var x,w=this.a,v=w.d,u=w.c
w=C.Z(d,G.P,y.w)
if(w==null)w=B.N
x=d.t(y.o).w
this.a.toString
return new D.ea(u,new A.ebJ(this,K.kr,x===B.J,u,v,w),null,null,y.q)}}
A.biC.prototype={
h(d){var x,w=this,v=null,u=w.c
u=C.a([new C.t(v,w.x,new A.aC7(u,w.d,w.e,v),v),A.ifS(B.AF,u,w.r,w.f)],y.u)
x=w.y
x=x==null?v:x.$2(d,u)
return x==null?C.h(u,B.n,v,B.b,B.f,0,B.d):x}}
var z=a.updateTypes(["w(m)","e5(bp,dA)","ak(c,cK,b?)"])
A.cHo.prototype={
$1(d){return B.q.cA(B.o.lX(B.i.ah(d*255),16),2,"0").toUpperCase()},
$S:13}
A.ebw.prototype={
$1(d){var x=this.a
return x.m(new A.ebv(x,d))},
$S:3}
A.ebv.prototype={
$0(){return this.a.d=this.b},
$S:0}
A.ebt.prototype={
$3(d,e,f){var x,w,v,u,t,s=null,r=C.aC(y.k),q=this.a
if(q.d)r.G(0,B.A)
if(q.f)r.G(0,B.a2)
if(q.r)r.G(0,B.G)
x=this.b
w=new A.ebu(x,e)
q.a.toString
x=x.gagm()
v=e.d
u=w.$1(v)
t=w.$1(B.i.I(v+0.1,0,1))
v=w.$1(B.i.I(v-0.1,0,1))
q.a.toString
w=q.e
w===$&&C.i()
return C.C(s,s,s,C.d1(!1,!1,D.nS(s,!1,new H.ak(new A.ebp(q,new A.hj(e,r),e),s),!0,s,!0,F.auV,s,w.gR1(),new A.ebq(q),s),s,s,s,s,!1,s,s,s,q.gb7V(),s,!0),!0,s,s,s,v,s,!1,s,!1,s,s,s,s,s,s,s,s,t,s,s,x,s,s,s,s,s,s,s,s,s,s,s,s,new A.ebr(q,e),s,s,s,s,s,new A.ebs(q,e),s,s,s,s,s,s,s,s,s,!0,s,s,this.c,s,s,s,s,B.l,u)},
$S:1023}
A.ebu.prototype={
$1(d){var x=this.a
return B.c.aK(C.a([x.PX(B.ba4)+" "+C.aeQ(this.b.c,C.dv(x.gbW()),0),x.PX(B.ba5)+" "+C.aeQ(d,C.dv(x.gbW()),0)],y.x),x.gru())},
$S:13}
A.ebs.prototype={
$0(){var x=this.a.a.c,w=this.b.d+0.1,v=x.a,u=B.i.I(w,0,1)
x.sq(new A.cK(v.a,v.b,v.c,u))
return w},
$S:0}
A.ebr.prototype={
$0(){var x=this.a.a.c,w=this.b.d-0.1,v=x.a,u=B.i.I(w,0,1)
x.sq(new A.cK(v.a,v.b,v.c,u))
return w},
$S:0}
A.ebq.prototype={
$1(d){var x=this.a
return x.m(new A.ebj(x,d))},
$S:3}
A.ebj.prototype={
$0(){return this.a.f=this.b},
$S:0}
A.ebp.prototype={
$2(d,e){var x=null,w=e.b,v=e.d,u=new C.H(w,v),t=this.a,s=this.b,r=this.c
return C.cE(B.aE,new C.aB(B.Q,x,B.Y,B.w,C.a([C.de(0,t.a.fG(d,s),0,0,0),C.ef(x,C.S(t.a.alL(d,s),x,x),44,x,r.c*w-22,x,(1-r.d)*v-22,44)],y.u),x),B.r,!1,x,x,x,x,x,x,x,x,x,x,x,x,new A.ebk(t),new A.ebl(t,u),new A.ebm(t),new A.ebn(t),new A.ebo(t,u),x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x)},
$S:130}
A.ebl.prototype={
$1(d){return this.a.aq8(d.b,this.b)},
$S:177}
A.ebn.prototype={
$1(d){var x=this.a
return x.m(new A.ebg(x))},
$S:45}
A.ebg.prototype={
$0(){return this.a.r=!0},
$S:0}
A.ebo.prototype={
$1(d){return this.a.aq8(d.b,this.b)},
$S:33}
A.ebm.prototype={
$1(d){var x=this.a
return x.m(new A.ebh(x))},
$S:38}
A.ebh.prototype={
$0(){return this.a.r=!1},
$S:0}
A.ebk.prototype={
$0(){var x=this.a
return x.m(new A.ebi(x))},
$S:0}
A.ebi.prototype={
$0(){return this.a.r=!1},
$S:0}
A.ebJ.prototype={
$3(d,e,f){var x=this
return new H.ak(new A.ebH(x.a,x.b,x.c,x.d,x.e,e,x.f),null)},
$S:z+2}
A.ebH.prototype={
$2(a2,a3){var x,w,v,u,t,s,r,q,p,o=this,n=null,m=a3.b,l=o.b,k=l.a,j=m-k,i=o.c,h=o.d,g=o.e,f=new A.ebI(j,l,i,h,g),e=o.f,d=g.b1(e),a0=g===B.AF,a1=d/(a0?360:1)
d=o.a
x=d.d?I.mT:B.aV
w=l.b
v=k/2
v=C.ef(0,C.S(new C.t(1/0,n,new C.a3(!0,d.a.bWE(a2,g,e),n),n),n,n),n,n,v,v,0,n)
i=i?1-a1:a1
e=g.b1(e)
u=a0?360:1
t=a0?1:0.01
s=a0?10:0.1
r=d.d
d.a.toString
q=o.r
p=q.PX(g)
a0=a0?new A.ebA(q):q.gbNW()
return C.cl(C.cE(B.aE,new C.t(m,w,new C.aB(B.Q,n,B.Y,B.w,C.a([v,C.ef(n,E.Cm(!1,B.E,d.a.f,n,n,r,n,B.ky,u,0,l,n,n,n,new A.ebB(h,g),n,s,a0,p,t,e),w,n,i*j,n,0,k)],y.u),n),n),B.r,!1,n,n,new A.ebC(d),new A.ebD(f),new A.ebE(d),new A.ebF(d),new A.ebG(f),n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n),x,n,n,n,n,n,!0)},
$S:197}
A.ebI.prototype={
$1(d){var x,w,v=this,u=v.a
if(u<=0)return
x=B.i.I((d-v.b.a/2)/u,0,1)
if(v.c)x=1-x
u=v.e
w=u===B.AF?360:1
A.i4d(v.d,u,x*w)},
$S:19}
A.ebD.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:177}
A.ebF.prototype={
$1(d){var x=this.a
return x.m(new A.ebx(x))},
$S:45}
A.ebx.prototype={
$0(){return this.a.d=!0},
$S:0}
A.ebG.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:33}
A.ebE.prototype={
$1(d){var x=this.a
return x.m(new A.eby(x))},
$S:38}
A.eby.prototype={
$0(){return this.a.d=!1},
$S:0}
A.ebC.prototype={
$0(){var x=this.a
return x.m(new A.ebz(x))},
$S:0}
A.ebz.prototype={
$0(){return this.a.d=!1},
$S:0}
A.ebA.prototype={
$1(d){return C.e6(B.i.ah(d),C.dv(this.a.gbW()),null,null)+"\xb0"},
$S:13}
A.ebB.prototype={
$1(d){return A.i4d(this.a,this.b,d)},
$S:19};(function installTearOffs(){var x=a._instance_1u,w=a._instance_2u
x(A.rg.prototype,"gaUp","LQ",0)
w(A.aTl.prototype,"gb7V","b7W",1)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(C.V,[A.cK,A.hj])
w(A.rg,C.bF)
x(C.cn,[A.cHo,A.ebw,A.ebt,A.ebu,A.ebq,A.ebl,A.ebn,A.ebo,A.ebm,A.ebJ,A.ebI,A.ebD,A.ebF,A.ebG,A.ebE,A.ebA,A.ebB])
x(C.k,[A.aC7,A.aC8])
x(C.l,[A.aTl,A.bR6])
x(C.cS,[A.ebv,A.ebs,A.ebr,A.ebj,A.ebg,A.ebh,A.ebk,A.ebi,A.ebx,A.eby,A.ebC,A.ebz])
x(C.d8,[A.ebp,A.ebH])
w(A.biC,C.j)})()
C.bN(b.typeUniverse,JSON.parse('{"aC7":{"k":[],"b":[]},"aC8":{"k":[],"b":[]},"rg":{"bF":["cK"],"a4":[]},"aTl":{"l":["aC7"]},"bR6":{"l":["aC8"]},"biC":{"j":[],"b":[]}}'))
var y={w:C.D("e3"),o:C.D("di"),x:C.D("n<m>"),u:C.D("n<b>"),q:C.D("ea<cK>"),k:C.D("U")};(function constants(){F.auV=new C.q_("precise")})()};
(a=>{a["auxKehcsYaSrLDrqig7gnWn0vjY="]=a.current})($__dart_deferred_initializers__);