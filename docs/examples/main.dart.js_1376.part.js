((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var C,B,I,A={
qC(d){var x=d.gTx()/255,w=d.gMn()/255,v=d.gQL()/255,u=Math.max(x,Math.max(w,v)),t=u-Math.min(x,Math.min(w,v)),s=d.gjJ(),r=D.iGt(x,w,v,u,t),q=u===0?0:t/u
return new A.cS(s/255,r,q,u)},
cS:function cS(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
iIj(d,e,f){var x,w
switch(e.a){case 0:x=d.a
w=B.i.I(f,0,360)
d.sq(new A.cS(x.a,w,x.c,x.d))
break
case 1:x=d.a
w=B.i.I(f,0,1)
d.sq(new A.cS(x.a,x.b,w,x.d))
break
case 2:x=d.a
w=B.i.I(f,0,1)
d.sq(new A.cS(x.a,x.b,x.c,w))
break
case 3:x=d.a
d.sq(new A.cS(B.i.I(f,0,1),x.b,x.c,x.d))
break}},
iy8(d,e,f){return new A.aRk(e,d,f,null)},
j_R(d,e,f,g,h){return new A.asa(e,d,h,f,g,null)},
rs:function rs(d,e){var _=this
_.a=d
_.L$=0
_.N$=e
_.aq$=_.au$=0},
dAj:function dAj(){},
hg:function hg(d,e){this.a=d
this.b=e},
aRk:function aRk(d,e,f,g){var _=this
_.c=d
_.d=e
_.e=f
_.a=g},
b_R:function b_R(){var _=this
_.d=!1
_.e=$
_.r=_.f=!1
_.c=_.a=null},
exH:function exH(d){this.a=d},
exG:function exG(d,e){this.a=d
this.b=e},
exE:function exE(d,e,f){this.a=d
this.b=e
this.c=f},
exF:function exF(d,e){this.a=d
this.b=e},
exD:function exD(d,e){this.a=d
this.b=e},
exC:function exC(d,e){this.a=d
this.b=e},
exB:function exB(d){this.a=d},
exu:function exu(d,e){this.a=d
this.b=e},
exA:function exA(d,e,f){this.a=d
this.b=e
this.c=f},
exw:function exw(d,e){this.a=d
this.b=e},
exy:function exy(d){this.a=d},
exr:function exr(d){this.a=d},
exz:function exz(d,e){this.a=d
this.b=e},
exx:function exx(d){this.a=d},
exs:function exs(d){this.a=d},
exv:function exv(d){this.a=d},
ext:function ext(d){this.a=d},
asa:function asa(d,e,f,g,h,i){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.w=h
_.a=i},
c2h:function c2h(){this.d=!1
this.c=this.a=null},
exU:function exU(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},
exS:function exS(d,e,f,g,h,i,j){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i
_.r=j},
exT:function exT(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
exO:function exO(d){this.a=d},
exQ:function exQ(d){this.a=d},
exI:function exI(d){this.a=d},
exR:function exR(d){this.a=d},
exP:function exP(d){this.a=d},
exJ:function exJ(d){this.a=d},
exN:function exN(d){this.a=d},
exK:function exK(d){this.a=d},
exL:function exL(d){this.a=d},
exM:function exM(d,e){this.a=d
this.b=e}},E,D,K,F,G,H
C=c[0]
B=c[2]
I=c[249]
A=a.updateHolder(c[138],A)
E=c[327]
D=c[264]
K=c[287]
F=c[251]
G=c[272]
H=c[266]
A.cS.prototype={
bJ(){var x=this,w=x.d,v=x.c*w,u=x.b
return C.iFr(x.a,u,v,v*(1-Math.abs(B.i.a5(u/60,2)-1)),w-v)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
return e instanceof A.cS&&e.a===x.a&&e.b===x.b&&e.c===x.c&&e.d===x.d},
ga2(d){var x=this
return C.aO(x.a,x.b,x.c,x.d,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a)},
A(d){var x=this
return"HSVColor("+C.an(x.a)+", "+C.an(x.b)+", "+C.an(x.c)+", "+C.an(x.d)+")"}}
A.rs.prototype={
sfS(d){var x=A.qC(d),w=x.c
this.sq(w===0||x.d===0?new A.cS(x.a,this.a.b,w,x.d):x)},
gmX(){var x=this.a.bJ(),w=new A.dAj(),v="#"+C.an(w.$1(x.b))+C.an(w.$1(x.c))+C.an(w.$1(x.d)),u=x.a
return u>=1?v:v+C.an(w.$1(u))},
Mx(d){var x,w,v,u,t,s,r=B.r.c2(d)
if(B.r.fM(r,"#"))r=B.r.fX(r,1)
x=C.eE("^[0-9a-fA-F]+$",!0,!1)
if(!x.b.test(r))return!1
if(r.length===3){x=C.a([],y.x)
for(w=r.split(""),v=w.length,u=0;u<v;++u){t=w[u]
x.push(t+t)}r=B.c.lP(x)}if(r.length===6)r+="FF"
if(r.length!==8)return!1
s=C.p9(r,16)
this.sfS(C.ep(((s&255)<<24|B.o.nc(s,8))>>>0))
return!0}}
A.hg.prototype={}
A.aRk.prototype={
n(){return new A.b_R()},
e1(d,e){return this.d.$2(d,e)},
anD(d,e){return this.e.$2(d,e)}}
A.b_R.prototype={
ar(){var x,w=this
w.aA()
x=F.Em()
w.e!==$&&C.db()
w.e=new F.BC(new A.exH(w),x)},
k(){var x=this.e
x===$&&C.l()
x.k()
this.K()},
asg(d,e){var x,w,v=e.a
if(v<=0||e.b<=0)return
x=this.a.c
w=x.a
v=B.i.I(d.a/v,0,1)
x.sq(new A.cS(w.a,w.b,v,B.i.I(1-d.b/e.b,0,1)))},
bbw(d,e){var x,w,v,u,t,s,r=this
if(!(e instanceof C.dq)&&!(e instanceof C.fF))return B.ad
r.a.toString
x=$.eq.fl$
x===$&&C.l()
x=x.a
w=C.Y(x).j("bc<2>")
v=0.01*(new C.bc(x,w).l(0,B.jN)||new C.bc(x,w).l(0,B.kh)?10:1)
u=r.a.c.a
t=e.b
if(t.i(0,B.bI)){x=r.a.c
w=u.c
s=x.a
w=B.i.I(w+v,0,1)
x.sq(new A.cS(s.a,s.b,w,s.d))}else if(t.i(0,B.bU)){x=r.a.c
w=u.c
s=x.a
w=B.i.I(w-v,0,1)
x.sq(new A.cS(s.a,s.b,w,s.d))}else if(t.i(0,B.bC)){x=r.a.c
w=u.d
s=x.a
w=B.i.I(w+v,0,1)
x.sq(new A.cS(s.a,s.b,s.c,w))}else if(t.i(0,B.bl)){x=r.a.c
w=u.d
s=x.a
w=B.i.I(w-v,0,1)
x.sq(new A.cS(s.a,s.b,s.c,w))}else return B.ad
return B.aH},
h(d){var x,w=C.W(d,G.M,y.t)
if(w==null)w=B.L
x=C.cU(d)
return C.he(new D.ek(this.a.c,new A.exE(this,w,x),null,null,y.q),B.O)}}
A.asa.prototype={
n(){return new A.c2h()},
c10(d,e,f){return this.e.$3(d,e,f)}}
A.c2h.prototype={
h(d){var x,w=this.a,v=w.d,u=w.c
w=C.W(d,G.M,y.t)
if(w==null)w=B.L
x=d.t(y.o).w
return new D.ek(u,new A.exU(this,this.a.w,x===B.I,u,v,w),null,null,y.q)}}
var z=a.updateTypes(["w(m)","dW(bF,dk)","a9(c,cS,b?)"])
A.dAj.prototype={
$1(d){return B.r.cZ(B.o.mH(B.i.ag(d*255),16),2,"0").toUpperCase()},
$S:12}
A.exH.prototype={
$1(d){var x=this.a
return x.m(new A.exG(x,d))},
$S:3}
A.exG.prototype={
$0(){return this.a.d=this.b},
$S:0}
A.exE.prototype={
$3(d,e,f){var x,w,v,u,t=null,s=y.k,r=C.az(s),q=this.a
if(q.d)r.G(0,B.x)
if(q.f)r.G(0,B.Z)
if(q.r)r.E(0,C.cJ([B.D,B.dz],s))
s=this.b
x=new A.exF(s,e)
q.a.toString
s=s.gai5()
w=e.d
v=x.$1(w)
u=x.$1(B.i.I(w+0.1,0,1))
w=x.$1(B.i.I(w-0.1,0,1))
q.a.toString
x=q.e
x===$&&C.l()
return C.B(t,t,t,C.d3(!1,!1,D.oF(t,!1,new H.a9(new A.exA(q,new A.hg(e,r),e),t),!0,t,!0,E.axg,t,x.gS6(),new A.exB(q),t),t,t,t,t,!1,t,t,t,q.gbbv(),t,!0),!0,t,t,t,w,t,!1,t,!1,t,t,t,t,t,t,t,t,u,t,t,t,s,t,t,t,t,t,t,t,t,t,t,t,t,new A.exC(q,e),t,t,t,t,t,new A.exD(q,e),t,t,t,t,t,t,t,t,t,!0,t,t,this.c,t,t,t,t,B.l,v)},
$S:1043}
A.exF.prototype={
$1(d){var x=this.a
return B.c.aM(C.a([x.QW(B.cVV)+" "+C.A5(this.b.c,C.cM(x.gbv()),0),x.QW(B.cVW)+" "+C.A5(d,C.cM(x.gbv()),0)],y.x),x.gwo())},
$S:12}
A.exD.prototype={
$0(){var x=this.a.a.c,w=this.b.d+0.1,v=x.a,u=B.i.I(w,0,1)
x.sq(new A.cS(v.a,v.b,v.c,u))
return w},
$S:0}
A.exC.prototype={
$0(){var x=this.a.a.c,w=this.b.d-0.1,v=x.a,u=B.i.I(w,0,1)
x.sq(new A.cS(v.a,v.b,v.c,u))
return w},
$S:0}
A.exB.prototype={
$1(d){var x=this.a
return x.m(new A.exu(x,d))},
$S:3}
A.exu.prototype={
$0(){return this.a.f=this.b},
$S:0}
A.exA.prototype={
$2(d,e){var x=null,w=e.b,v=e.d,u=new C.H(w,v),t=this.a,s=this.b,r=this.c
return C.cu(B.an,new C.ay(B.P,x,B.X,B.u,C.a([C.d1(0,t.a.e1(d,s),0,0,0),C.dR(x,C.O(t.a.anD(d,s),x,x),44,x,r.c*w-22,x,(1-r.d)*v-22,44)],y.u),x),B.q,!1,x,x,x,x,x,x,x,x,x,x,x,x,new A.exv(t),new A.exw(t,u),new A.exx(t),new A.exy(t),new A.exz(t,u),x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x)},
$S:151}
A.exw.prototype={
$1(d){return this.a.asg(d.b,this.b)},
$S:199}
A.exy.prototype={
$1(d){var x=this.a
return x.m(new A.exr(x))},
$S:42}
A.exr.prototype={
$0(){return this.a.r=!0},
$S:0}
A.exz.prototype={
$1(d){return this.a.asg(d.b,this.b)},
$S:33}
A.exx.prototype={
$1(d){var x=this.a
return x.m(new A.exs(x))},
$S:40}
A.exs.prototype={
$0(){return this.a.r=!1},
$S:0}
A.exv.prototype={
$0(){var x=this.a
return x.m(new A.ext(x))},
$S:0}
A.ext.prototype={
$0(){return this.a.r=!1},
$S:0}
A.exU.prototype={
$3(d,e,f){var x=this
return new H.a9(new A.exS(x.a,x.b,x.c,x.d,x.e,e,x.f),null)},
$S:z+2}
A.exS.prototype={
$2(a2,a3){var x,w,v,u,t,s,r,q,p,o=this,n=null,m=a3.b,l=o.b,k=l.a,j=m-k,i=o.c,h=o.d,g=o.e,f=new A.exT(j,l,i,h,g),e=o.f,d=g.b5(e),a0=g===B.zd,a1=d/(a0?360:1)
d=o.a
x=d.d?K.lI:B.aW
w=l.b
v=k/2
v=C.dR(0,C.O(new C.r(1/0,n,new C.a1(!0,d.a.c10(a2,g,e),n),n),n,n),n,n,v,v,0,n)
i=i?1-a1:a1
e=g.b5(e)
u=a0?360:1
t=a0?1:0.01
s=a0?10:0.1
r=d.d
d.a.toString
q=o.r
p=q.QW(g)
a0=a0?new A.exL(q):q.gbT4()
return C.c5(C.cu(B.an,new C.r(m,w,new C.ay(B.P,n,B.X,B.u,C.a([v,C.dR(n,I.BL(!1,B.F,d.a.f,n,n,r,n,B.lO,u,0,l,n,n,n,new A.exM(h,g),n,s,a0,p,t,e),w,n,i*j,n,0,k)],y.u),n),n),B.q,!1,n,n,new A.exN(d),new A.exO(f),new A.exP(d),new A.exQ(d),new A.exR(f),n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n),x,n,n,n,n,n,!0)},
$S:174}
A.exT.prototype={
$1(d){var x,w,v=this,u=v.a
if(u<=0)return
x=B.i.I((d-v.b.a/2)/u,0,1)
if(v.c)x=1-x
u=v.e
w=u===B.zd?360:1
A.iIj(v.d,u,x*w)},
$S:18}
A.exO.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:199}
A.exQ.prototype={
$1(d){var x=this.a
return x.m(new A.exI(x))},
$S:42}
A.exI.prototype={
$0(){return this.a.d=!0},
$S:0}
A.exR.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:33}
A.exP.prototype={
$1(d){var x=this.a
return x.m(new A.exJ(x))},
$S:40}
A.exJ.prototype={
$0(){return this.a.d=!1},
$S:0}
A.exN.prototype={
$0(){var x=this.a
return x.m(new A.exK(x))},
$S:0}
A.exK.prototype={
$0(){return this.a.d=!1},
$S:0}
A.exL.prototype={
$1(d){return C.di(B.i.ag(d),C.cM(this.a.gbv()),null,null)+"\xb0"},
$S:12}
A.exM.prototype={
$1(d){return A.iIj(this.a,this.b,d)},
$S:18};(function installTearOffs(){var x=a._instance_1u,w=a._instance_2u
x(A.rs.prototype,"gaXw","Mx",0)
w(A.b_R.prototype,"gbbv","bbw",1)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(C.X,[A.cS,A.hg])
w(A.rs,C.bs)
x(C.cm,[A.dAj,A.exH,A.exE,A.exF,A.exB,A.exw,A.exy,A.exz,A.exx,A.exU,A.exT,A.exO,A.exQ,A.exR,A.exP,A.exL,A.exM])
x(C.i,[A.aRk,A.asa])
x(C.k,[A.b_R,A.c2h])
x(C.d_,[A.exG,A.exD,A.exC,A.exu,A.exr,A.exs,A.exv,A.ext,A.exI,A.exJ,A.exN,A.exK])
x(C.dj,[A.exA,A.exS])})()
C.bM(b.typeUniverse,JSON.parse('{"aRk":{"i":[],"b":[]},"asa":{"i":[],"b":[]},"rs":{"bs":["cS"],"a6":[]},"b_R":{"k":["aRk"]},"c2h":{"k":["asa"]}}'))
var y={o:C.F("du"),x:C.F("o<m>"),u:C.F("o<b>"),t:C.F("dE"),q:C.F("ek<cS>"),k:C.F("T")};(function constants(){E.lY=new C.f(1,0.19607843137254902,0.3843137254901961,0.5490196078431373,B.e)
E.axg=new C.qO("precise")})()};
(a=>{a["c2iFBHzAusbUUn2HeC8gpJkCrqE="]=a.current})($__dart_deferred_initializers__);