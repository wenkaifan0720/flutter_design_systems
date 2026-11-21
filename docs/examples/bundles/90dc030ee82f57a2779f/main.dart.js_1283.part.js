((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var C,B,A={
rw(d){var x=d.gSH()/255,w=d.gLK()/255,v=d.gPV()/255,u=Math.max(x,Math.max(w,v)),t=u-Math.min(x,Math.min(w,v)),s=d.gjo(),r=D.i60(x,w,v,u,t),q=u===0?0:t/u
return new A.cL(s/255,r,q,u)},
cL:function cL(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
i7G(d,e,f){var x,w
switch(e.a){case 0:x=d.a
w=B.i.I(f,0,360)
d.sq(new A.cL(x.a,w,x.c,x.d))
break
case 1:x=d.a
w=B.i.I(f,0,1)
d.sq(new A.cL(x.a,x.b,w,x.d))
break
case 2:x=d.a
w=B.i.I(f,0,1)
d.sq(new A.cL(x.a,x.b,x.c,w))
break
case 3:x=d.a
d.sq(new A.cL(B.i.I(f,0,1),x.b,x.c,x.d))
break}},
ipt(d,e,f,g){return new A.aL_(e,d,g,f,null)},
AE(d,e,f,g,h,i,j,k){return new A.bxC(g,d,f,k,j,!1,e,h,null)},
rH:function rH(d,e){var _=this
_.a=d
_.N$=0
_.P$=e
_.aq$=_.av$=0},
djc:function djc(){},
ho:function ho(d,e){this.a=d
this.b=e},
aKZ:function aKZ(d,e,f,g){var _=this
_.c=d
_.d=e
_.e=f
_.a=g},
aTR:function aTR(){var _=this
_.d=!1
_.e=$
_.r=_.f=!1
_.c=_.a=null},
ecV:function ecV(d){this.a=d},
ecU:function ecU(d,e){this.a=d
this.b=e},
ecS:function ecS(d,e,f){this.a=d
this.b=e
this.c=f},
ecT:function ecT(d,e){this.a=d
this.b=e},
ecR:function ecR(d,e){this.a=d
this.b=e},
ecQ:function ecQ(d,e){this.a=d
this.b=e},
ecP:function ecP(d){this.a=d},
ecI:function ecI(d,e){this.a=d
this.b=e},
ecO:function ecO(d,e,f){this.a=d
this.b=e
this.c=f},
ecK:function ecK(d,e){this.a=d
this.b=e},
ecM:function ecM(d){this.a=d},
ecF:function ecF(d){this.a=d},
ecN:function ecN(d,e){this.a=d
this.b=e},
ecL:function ecL(d){this.a=d},
ecG:function ecG(d){this.a=d},
ecJ:function ecJ(d){this.a=d},
ecH:function ecH(d){this.a=d},
aL_:function aL_(d,e,f,g,h){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.a=h},
bSp:function bSp(){this.d=!1
this.c=this.a=null},
ed7:function ed7(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},
ed5:function ed5(d,e,f,g,h,i,j){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i
_.r=j},
ed6:function ed6(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
ed1:function ed1(d){this.a=d},
ed3:function ed3(d){this.a=d},
ecW:function ecW(d){this.a=d},
ed4:function ed4(d){this.a=d},
ed2:function ed2(d){this.a=d},
ecX:function ecX(d){this.a=d},
ed0:function ed0(d){this.a=d},
ecY:function ecY(d){this.a=d},
ecZ:function ecZ(d){this.a=d},
ed_:function ed_(d,e){this.a=d
this.b=e},
bxC:function bxC(d,e,f,g,h,i,j,k,l){var _=this
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
A=a.updateHolder(c[129],A)
F=c[590]
I=c[269]
D=c[250]
E=c[237]
G=c[272]
H=c[252]
K=c[434]
A.cL.prototype={
bQ(){var x=this,w=x.d,v=x.c*w,u=x.b
return C.i58(x.a,u,v,v*(1-Math.abs(B.i.a4(u/60,2)-1)),w-v)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
return e instanceof A.cL&&e.a===x.a&&e.b===x.b&&e.c===x.c&&e.d===x.d},
gY(d){var x=this
return C.aK(x.a,x.b,x.c,x.d,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a)},
v(d){var x=this
return"HSVColor("+C.ak(x.a)+", "+C.ak(x.b)+", "+C.ak(x.c)+", "+C.ak(x.d)+")"}}
A.rH.prototype={
sfK(d){var x=A.rw(d),w=x.c
this.sq(w===0||x.d===0?new A.cL(x.a,this.a.b,w,x.d):x)},
gmX(){var x=this.a.bQ(),w=new A.djc(),v="#"+C.ak(w.$1(x.b))+C.ak(w.$1(x.c))+C.ak(w.$1(x.d)),u=x.a
return u>=1?v:v+C.ak(w.$1(u))},
LX(d){var x,w,v,u,t,s,r=B.q.ca(d)
if(B.q.fM(r,"#"))r=B.q.fU(r,1)
x=C.ez("^[0-9a-fA-F]+$",!0,!1)
if(!x.b.test(r))return!1
if(r.length===3){x=C.a([],y.x)
for(w=r.split(""),v=w.length,u=0;u<v;++u){t=w[u]
x.push(t+t)}r=B.c.lI(x)}if(r.length===6)r+="FF"
if(r.length!==8)return!1
s=C.ol(r,16)
this.sfK(C.ep(((s&255)<<24|B.o.mL(s,8))>>>0))
return!0}}
A.ho.prototype={}
A.aKZ.prototype={
n(){return new A.aTR()},
ev(d,e){return this.d.$2(d,e)},
ame(d,e){return this.e.$2(d,e)}}
A.aTR.prototype={
ap(){var x=this
x.aw()
E.WQ()
x.e!==$&&C.cQ()
x.e=new E.zG(new A.ecV(x))},
k(){var x=this.e
x===$&&C.j()
$.BG().af(0,x.gyz())
this.L()},
aqI(d,e){var x,w,v=e.a
if(v<=0||e.b<=0)return
x=this.a.c
w=x.a
v=B.i.I(d.a/v,0,1)
x.sq(new A.cL(w.a,w.b,v,B.i.I(1-d.b/e.b,0,1)))},
b8R(d,e){var x,w,v,u,t,s,r=this
if(!(e instanceof C.dn)&&!(e instanceof C.fH))return B.ab
r.a.toString
x=$.en.fL$
x===$&&C.j()
x=x.a
w=C.T(x).j("ba<2>")
v=0.01*(new C.ba(x,w).l(0,B.iZ)||new C.ba(x,w).l(0,B.jD)?10:1)
u=r.a.c.a
t=e.b
if(t.i(0,B.bG)){x=r.a.c
w=u.c
s=x.a
w=B.i.I(w+v,0,1)
x.sq(new A.cL(s.a,s.b,w,s.d))}else if(t.i(0,B.bU)){x=r.a.c
w=u.c
s=x.a
w=B.i.I(w-v,0,1)
x.sq(new A.cL(s.a,s.b,w,s.d))}else if(t.i(0,B.bv)){x=r.a.c
w=u.d
s=x.a
w=B.i.I(w+v,0,1)
x.sq(new A.cL(s.a,s.b,s.c,w))}else if(t.i(0,B.bh)){x=r.a.c
w=u.d
s=x.a
w=B.i.I(w-v,0,1)
x.sq(new A.cL(s.a,s.b,s.c,w))}else return B.ab
return B.aG},
h(d){var x,w=C.Z(d,G.O,y.t)
if(w==null)w=B.N
x=C.cW(d)
return C.fE(new D.ea(this.a.c,new A.ecS(this,w,x),null,null,y.q),B.K)}}
A.aL_.prototype={
n(){return new A.bSp()},
bXR(d,e,f){return this.e.$3(d,e,f)}}
A.bSp.prototype={
h(d){var x,w=this.a,v=w.d,u=w.c
w=C.Z(d,G.O,y.t)
if(w==null)w=B.N
x=d.t(y.o).w
this.a.toString
return new D.ea(u,new A.ed7(this,K.kr,x===B.J,u,v,w),null,null,y.q)}}
A.bxC.prototype={
h(d){var x,w=this,v=null,u=w.c
u=C.a([new C.t(v,w.x,new A.aKZ(u,w.d,w.e,v),v),A.ipt(B.Cy,u,w.r,w.f)],y.u)
x=w.y
x=x==null?v:x.$2(d,u)
return x==null?C.h(u,B.m,v,B.b,B.f,0,B.d):x}}
var z=a.updateTypes(["w(m)","dY(bB,ds)","al(c,cL,b?)"])
A.djc.prototype={
$1(d){return B.q.cC(B.o.m2(B.i.ah(d*255),16),2,"0").toUpperCase()},
$S:13}
A.ecV.prototype={
$1(d){var x=this.a
return x.m(new A.ecU(x,d))},
$S:3}
A.ecU.prototype={
$0(){return this.a.d=this.b},
$S:0}
A.ecS.prototype={
$3(d,e,f){var x,w,v,u,t=null,s=y.k,r=C.aA(s),q=this.a
if(q.d)r.E(0,B.z)
if(q.f)r.E(0,B.a_)
if(q.r)r.F(0,C.cE([B.D,B.dr],s))
s=this.b
x=new A.ecT(s,e)
q.a.toString
s=s.gagS()
w=e.d
v=x.$1(w)
u=x.$1(B.i.I(w+0.1,0,1))
w=x.$1(B.i.I(w-0.1,0,1))
q.a.toString
x=q.e
x===$&&C.j()
return C.C(t,t,t,C.d4(!1,!1,D.nS(t,!1,new H.al(new A.ecO(q,new A.ho(e,r),e),t),!0,t,!0,F.av_,t,x.gRb(),new A.ecP(q),t),t,t,t,t,!1,t,t,t,q.gb8Q(),t,!0),!0,t,t,t,w,t,!1,t,!1,t,t,t,t,t,t,t,t,u,t,t,s,t,t,t,t,t,t,t,t,t,t,t,t,new A.ecQ(q,e),t,t,t,t,t,new A.ecR(q,e),t,t,t,t,t,t,t,t,t,!0,t,t,this.c,t,t,t,t,B.l,v)},
$S:1028}
A.ecT.prototype={
$1(d){var x=this.a
return B.c.aL(C.a([x.Q4(B.cQR)+" "+C.af5(this.b.c,C.dx(x.gbW()),0),x.Q4(B.cQS)+" "+C.af5(d,C.dx(x.gbW()),0)],y.x),x.grv())},
$S:13}
A.ecR.prototype={
$0(){var x=this.a.a.c,w=this.b.d+0.1,v=x.a,u=B.i.I(w,0,1)
x.sq(new A.cL(v.a,v.b,v.c,u))
return w},
$S:0}
A.ecQ.prototype={
$0(){var x=this.a.a.c,w=this.b.d-0.1,v=x.a,u=B.i.I(w,0,1)
x.sq(new A.cL(v.a,v.b,v.c,u))
return w},
$S:0}
A.ecP.prototype={
$1(d){var x=this.a
return x.m(new A.ecI(x,d))},
$S:3}
A.ecI.prototype={
$0(){return this.a.f=this.b},
$S:0}
A.ecO.prototype={
$2(d,e){var x=null,w=e.b,v=e.d,u=new C.H(w,v),t=this.a,s=this.b,r=this.c
return C.cG(B.at,new C.aD(B.Q,x,B.Y,B.v,C.a([C.dj(0,t.a.ev(d,s),0,0,0),C.ef(x,C.Q(t.a.ame(d,s),x,x),44,x,r.c*w-22,x,(1-r.d)*v-22,44)],y.u),x),B.r,!1,x,x,x,x,x,x,x,x,x,x,x,x,new A.ecJ(t),new A.ecK(t,u),new A.ecL(t),new A.ecM(t),new A.ecN(t,u),x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x)},
$S:134}
A.ecK.prototype={
$1(d){return this.a.aqI(d.b,this.b)},
$S:185}
A.ecM.prototype={
$1(d){var x=this.a
return x.m(new A.ecF(x))},
$S:45}
A.ecF.prototype={
$0(){return this.a.r=!0},
$S:0}
A.ecN.prototype={
$1(d){return this.a.aqI(d.b,this.b)},
$S:32}
A.ecL.prototype={
$1(d){var x=this.a
return x.m(new A.ecG(x))},
$S:38}
A.ecG.prototype={
$0(){return this.a.r=!1},
$S:0}
A.ecJ.prototype={
$0(){var x=this.a
return x.m(new A.ecH(x))},
$S:0}
A.ecH.prototype={
$0(){return this.a.r=!1},
$S:0}
A.ed7.prototype={
$3(d,e,f){var x=this
return new H.al(new A.ed5(x.a,x.b,x.c,x.d,x.e,e,x.f),null)},
$S:z+2}
A.ed5.prototype={
$2(a2,a3){var x,w,v,u,t,s,r,q,p,o=this,n=null,m=a3.b,l=o.b,k=l.a,j=m-k,i=o.c,h=o.d,g=o.e,f=new A.ed6(j,l,i,h,g),e=o.f,d=g.b4(e),a0=g===B.Cy,a1=d/(a0?360:1)
d=o.a
x=d.d?I.mU:B.aU
w=l.b
v=k/2
v=C.ef(0,C.Q(new C.t(1/0,n,new C.a0(!0,d.a.bXR(a2,g,e),n),n),n,n),n,n,v,v,0,n)
i=i?1-a1:a1
e=g.b4(e)
u=a0?360:1
t=a0?1:0.01
s=a0?10:0.1
r=d.d
d.a.toString
q=o.r
p=q.Q4(g)
a0=a0?new A.ecZ(q):q.gbP6()
return C.ch(C.cG(B.at,new C.t(m,w,new C.aD(B.Q,n,B.Y,B.v,C.a([v,C.ef(n,E.Cq(!1,B.F,d.a.f,n,n,r,n,B.ln,u,0,l,n,n,n,new A.ed_(h,g),n,s,a0,p,t,e),w,n,i*j,n,0,k)],y.u),n),n),B.r,!1,n,n,new A.ed0(d),new A.ed1(f),new A.ed2(d),new A.ed3(d),new A.ed4(f),n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n),x,n,n,n,n,n,!0)},
$S:201}
A.ed6.prototype={
$1(d){var x,w,v=this,u=v.a
if(u<=0)return
x=B.i.I((d-v.b.a/2)/u,0,1)
if(v.c)x=1-x
u=v.e
w=u===B.Cy?360:1
A.i7G(v.d,u,x*w)},
$S:21}
A.ed1.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:185}
A.ed3.prototype={
$1(d){var x=this.a
return x.m(new A.ecW(x))},
$S:45}
A.ecW.prototype={
$0(){return this.a.d=!0},
$S:0}
A.ed4.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:32}
A.ed2.prototype={
$1(d){var x=this.a
return x.m(new A.ecX(x))},
$S:38}
A.ecX.prototype={
$0(){return this.a.d=!1},
$S:0}
A.ed0.prototype={
$0(){var x=this.a
return x.m(new A.ecY(x))},
$S:0}
A.ecY.prototype={
$0(){return this.a.d=!1},
$S:0}
A.ecZ.prototype={
$1(d){return C.e6(B.i.ah(d),C.dx(this.a.gbW()),null,null)+"\xb0"},
$S:13}
A.ed_.prototype={
$1(d){return A.i7G(this.a,this.b,d)},
$S:21};(function installTearOffs(){var x=a._instance_1u,w=a._instance_2u
x(A.rH.prototype,"gaVh","LX",0)
w(A.aTR.prototype,"gb8Q","b8R",1)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(C.W,[A.cL,A.ho])
w(A.rH,C.br)
x(C.ck,[A.djc,A.ecV,A.ecS,A.ecT,A.ecP,A.ecK,A.ecM,A.ecN,A.ecL,A.ed7,A.ed6,A.ed1,A.ed3,A.ed4,A.ed2,A.ecZ,A.ed_])
x(C.i,[A.aKZ,A.aL_])
x(C.k,[A.aTR,A.bSp])
x(C.cS,[A.ecU,A.ecR,A.ecQ,A.ecI,A.ecF,A.ecG,A.ecJ,A.ecH,A.ecW,A.ecX,A.ed0,A.ecY])
x(C.dh,[A.ecO,A.ed5])
w(A.bxC,C.l)})()
C.bN(b.typeUniverse,JSON.parse('{"aKZ":{"i":[],"b":[]},"aL_":{"i":[],"b":[]},"rH":{"br":["cL"],"a4":[]},"aTR":{"k":["aKZ"]},"bSp":{"k":["aL_"]},"bxC":{"l":[],"b":[]}}'))
var y={o:C.E("dm"),x:C.E("n<m>"),u:C.E("n<b>"),t:C.E("e5"),q:C.E("ea<cL>"),k:C.E("U")};(function constants(){F.av_=new C.q6("precise")})()};
(a=>{a["5ArosPsFBArTGXXOxyOHkSrWzSQ="]=a.current})($__dart_deferred_initializers__);