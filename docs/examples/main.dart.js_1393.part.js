((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var C,B,F,A={
qK(d){var x=d.gUb()/255,w=d.gMV()/255,v=d.gRm()/255,u=Math.max(x,Math.max(w,v)),t=u-Math.min(x,Math.min(w,v)),s=d.gjQ(),r=D.iKp(x,w,v,u,t),q=u===0?0:t/u
return new A.cV(s/255,r,q,u)},
cV:function cV(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
iMf(d,e,f){var x,w
switch(e.a){case 0:x=d.a
w=B.i.J(f,0,360)
d.st(new A.cV(x.a,w,x.c,x.d))
break
case 1:x=d.a
w=B.i.J(f,0,1)
d.st(new A.cV(x.a,x.b,w,x.d))
break
case 2:x=d.a
w=B.i.J(f,0,1)
d.st(new A.cV(x.a,x.b,x.c,w))
break
case 3:x=d.a
d.st(new A.cV(B.i.J(f,0,1),x.b,x.c,x.d))
break}},
iC3(d,e,f){return new A.aRK(e,d,f,null)},
j3K(d,e,f,g,h){return new A.asz(e,d,h,f,g,null)},
rx:function rx(d,e){var _=this
_.a=d
_.M$=0
_.O$=e
_.ar$=_.av$=0},
dBY:function dBY(){},
ho:function ho(d,e){this.a=d
this.b=e},
aRK:function aRK(d,e,f,g){var _=this
_.c=d
_.d=e
_.e=f
_.a=g},
b0e:function b0e(){var _=this
_.d=!1
_.e=$
_.r=_.f=!1
_.c=_.a=null},
ezz:function ezz(d){this.a=d},
ezy:function ezy(d,e){this.a=d
this.b=e},
ezw:function ezw(d,e,f){this.a=d
this.b=e
this.c=f},
ezx:function ezx(d,e){this.a=d
this.b=e},
ezv:function ezv(d,e){this.a=d
this.b=e},
ezu:function ezu(d,e){this.a=d
this.b=e},
ezt:function ezt(d){this.a=d},
ezm:function ezm(d,e){this.a=d
this.b=e},
ezs:function ezs(d,e,f){this.a=d
this.b=e
this.c=f},
ezo:function ezo(d,e){this.a=d
this.b=e},
ezq:function ezq(d){this.a=d},
ezj:function ezj(d){this.a=d},
ezr:function ezr(d,e){this.a=d
this.b=e},
ezp:function ezp(d){this.a=d},
ezk:function ezk(d){this.a=d},
ezn:function ezn(d){this.a=d},
ezl:function ezl(d){this.a=d},
asz:function asz(d,e,f,g,h,i){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.w=h
_.a=i},
c2X:function c2X(){this.d=!1
this.c=this.a=null},
ezM:function ezM(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},
ezK:function ezK(d,e,f,g,h,i,j){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i
_.r=j},
ezL:function ezL(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
ezG:function ezG(d){this.a=d},
ezI:function ezI(d){this.a=d},
ezA:function ezA(d){this.a=d},
ezJ:function ezJ(d){this.a=d},
ezH:function ezH(d){this.a=d},
ezB:function ezB(d){this.a=d},
ezF:function ezF(d){this.a=d},
ezC:function ezC(d){this.a=d},
ezD:function ezD(d){this.a=d},
ezE:function ezE(d,e){this.a=d
this.b=e}},E,I,K,D,G,H
C=c[0]
B=c[2]
F=c[276]
A=a.updateHolder(c[147],A)
E=c[337]
I=c[258]
K=c[297]
D=c[274]
G=c[260]
H=c[282]
A.cV.prototype={
bA(){var x=this,w=x.d,v=x.c*w,u=x.b
return C.iJm(x.a,u,v,v*(1-Math.abs(B.i.a7(u/60,2)-1)),w-v)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
return e instanceof A.cV&&e.a===x.a&&e.b===x.b&&e.c===x.c&&e.d===x.d},
ga3(d){var x=this
return C.aN(x.a,x.b,x.c,x.d,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a)},
B(d){var x=this
return"HSVColor("+C.an(x.a)+", "+C.an(x.b)+", "+C.an(x.c)+", "+C.an(x.d)+")"}}
A.rx.prototype={
sfZ(d){var x=A.qK(d),w=x.c
this.st(w===0||x.d===0?new A.cV(x.a,this.a.b,w,x.d):x)},
gnl(){var x=this.a.bA(),w=new A.dBY(),v="#"+C.an(w.$1(x.b))+C.an(w.$1(x.c))+C.an(w.$1(x.d)),u=x.a
return u>=1?v:v+C.an(w.$1(u))},
N5(d){var x,w,v,u,t,s,r=B.t.c6(d)
if(B.t.fU(r,"#"))r=B.t.h6(r,1)
x=C.eH("^[0-9a-fA-F]+$",!0,!1)
if(!x.b.test(r))return!1
if(r.length===3){x=C.a([],y.x)
for(w=r.split(""),v=w.length,u=0;u<v;++u){t=w[u]
x.push(t+t)}r=B.c.m3(x)}if(r.length===6)r+="FF"
if(r.length!==8)return!1
s=C.pe(r,16)
this.sfZ(C.em(((s&255)<<24|B.o.nA(s,8))>>>0))
return!0}}
A.ho.prototype={}
A.aRK.prototype={
p(){return new A.b0e()},
e6(d,e){return this.d.$2(d,e)},
aoE(d,e){return this.e.$2(d,e)}}
A.b0e.prototype={
au(){var x,w=this
w.aB()
x=G.Ey()
w.e!==$&&C.dh()
w.e=new G.BJ(new A.ezz(w),x)},
l(){var x=this.e
x===$&&C.m()
x.l()
this.L()},
at6(d,e){var x,w,v=e.a
if(v<=0||e.b<=0)return
x=this.a.c
w=x.a
v=B.i.J(d.a/v,0,1)
x.st(new A.cV(w.a,w.b,v,B.i.J(1-d.b/e.b,0,1)))},
bcq(d,e){var x,w,v,u,t,s,r=this
if(!(e instanceof C.du)&&!(e instanceof C.fL))return B.ae
r.a.toString
x=$.es.fq$
x===$&&C.m()
x=x.a
w=C.a_(x).k("bd<2>")
v=0.01*(new C.bd(x,w).m(0,B.jO)||new C.bd(x,w).m(0,B.kj)?10:1)
u=r.a.c.a
t=e.b
if(t.i(0,B.bG)){x=r.a.c
w=u.c
s=x.a
w=B.i.J(w+v,0,1)
x.st(new A.cV(s.a,s.b,w,s.d))}else if(t.i(0,B.bS)){x=r.a.c
w=u.c
s=x.a
w=B.i.J(w-v,0,1)
x.st(new A.cV(s.a,s.b,w,s.d))}else if(t.i(0,B.bA)){x=r.a.c
w=u.d
s=x.a
w=B.i.J(w+v,0,1)
x.st(new A.cV(s.a,s.b,s.c,w))}else if(t.i(0,B.bk)){x=r.a.c
w=u.d
s=x.a
w=B.i.J(w-v,0,1)
x.st(new A.cV(s.a,s.b,s.c,w))}else return B.ae
return B.aH},
h(d){var x,w=C.X(d,H.M,y.t)
if(w==null)w=B.K
x=C.cX(d)
return C.h5(new D.eo(this.a.c,new A.ezw(this,w,x),null,null,y.q),B.O)}}
A.asz.prototype={
p(){return new A.c2X()},
c2e(d,e,f){return this.e.$3(d,e,f)}}
A.c2X.prototype={
h(d){var x,w=this.a,v=w.d,u=w.c
w=C.X(d,H.M,y.t)
if(w==null)w=B.K
x=d.u(y.o).w
return new D.eo(u,new A.ezM(this,this.a.w,x===B.I,u,v,w),null,null,y.q)}}
var z=a.updateTypes(["x(n)","dZ(bG,dl)","a8(c,cV,b?)"])
A.dBY.prototype={
$1(d){return B.t.e_(B.o.n1(B.i.ai(d*255),16),2,"0").toUpperCase()},
$S:16}
A.ezz.prototype={
$1(d){var x=this.a
return x.n(new A.ezy(x,d))},
$S:3}
A.ezy.prototype={
$0(){return this.a.d=this.b},
$S:0}
A.ezw.prototype={
$3(d,e,f){var x,w,v,u,t=null,s=y.k,r=C.az(s),q=this.a
if(q.d)r.H(0,B.x)
if(q.f)r.H(0,B.a0)
if(q.r)r.F(0,C.cM([B.D,B.dC],s))
s=this.b
x=new A.ezx(s,e)
q.a.toString
s=s.gajj()
w=e.d
v=x.$1(w)
u=x.$1(B.i.J(w+0.1,0,1))
w=x.$1(B.i.J(w-0.1,0,1))
q.a.toString
x=q.e
x===$&&C.m()
return C.C(t,t,t,C.d7(!1,!1,D.oJ(t,!1,new F.a8(new A.ezs(q,new A.ho(e,r),e),t),!0,t,!0,E.axZ,t,x.gSL(),new A.ezt(q),t),t,t,t,t,!1,t,t,t,q.gbcp(),t,!0),!0,t,t,t,w,t,!1,t,!1,t,t,t,t,t,t,t,t,u,t,t,t,s,t,t,t,t,t,t,t,t,t,t,t,t,new A.ezu(q,e),t,t,t,t,t,new A.ezv(q,e),t,t,t,t,t,t,t,t,t,!0,t,t,this.c,t,t,t,t,B.l,v)},
$S:1054}
A.ezx.prototype={
$1(d){var x=this.a
return B.c.aK(C.a([x.Rz(B.cWJ)+" "+C.Ah(this.b.c,C.c4(x.gba()),0),x.Rz(B.cWK)+" "+C.Ah(d,C.c4(x.gba()),0)],y.x),x.gwM())},
$S:16}
A.ezv.prototype={
$0(){var x=this.a.a.c,w=this.b.d+0.1,v=x.a,u=B.i.J(w,0,1)
x.st(new A.cV(v.a,v.b,v.c,u))
return w},
$S:0}
A.ezu.prototype={
$0(){var x=this.a.a.c,w=this.b.d-0.1,v=x.a,u=B.i.J(w,0,1)
x.st(new A.cV(v.a,v.b,v.c,u))
return w},
$S:0}
A.ezt.prototype={
$1(d){var x=this.a
return x.n(new A.ezm(x,d))},
$S:3}
A.ezm.prototype={
$0(){return this.a.f=this.b},
$S:0}
A.ezs.prototype={
$2(d,e){var x=null,w=e.b,v=e.d,u=new C.I(w,v),t=this.a,s=this.b,r=this.c
return C.cx(B.ap,new C.ay(B.P,x,B.X,B.v,C.a([C.d5(0,t.a.e6(d,s),0,0,0),C.dV(x,C.P(t.a.aoE(d,s),x,x),44,x,r.c*w-22,x,(1-r.d)*v-22,44)],y.u),x),B.q,!1,x,x,x,x,x,x,x,x,x,x,x,x,new A.ezn(t),new A.ezo(t,u),new A.ezp(t),new A.ezq(t),new A.ezr(t,u),x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x)},
$S:160}
A.ezo.prototype={
$1(d){return this.a.at6(d.b,this.b)},
$S:215}
A.ezq.prototype={
$1(d){var x=this.a
return x.n(new A.ezj(x))},
$S:44}
A.ezj.prototype={
$0(){return this.a.r=!0},
$S:0}
A.ezr.prototype={
$1(d){return this.a.at6(d.b,this.b)},
$S:33}
A.ezp.prototype={
$1(d){var x=this.a
return x.n(new A.ezk(x))},
$S:41}
A.ezk.prototype={
$0(){return this.a.r=!1},
$S:0}
A.ezn.prototype={
$0(){var x=this.a
return x.n(new A.ezl(x))},
$S:0}
A.ezl.prototype={
$0(){return this.a.r=!1},
$S:0}
A.ezM.prototype={
$3(d,e,f){var x=this
return new F.a8(new A.ezK(x.a,x.b,x.c,x.d,x.e,e,x.f),null)},
$S:z+2}
A.ezK.prototype={
$2(a2,a3){var x,w,v,u,t,s,r,q,p,o=this,n=null,m=a3.b,l=o.b,k=l.a,j=m-k,i=o.c,h=o.d,g=o.e,f=new A.ezL(j,l,i,h,g),e=o.f,d=g.b7(e),a0=g===B.zp,a1=d/(a0?360:1)
d=o.a
x=d.d?K.lN:B.aW
w=l.b
v=k/2
v=C.dV(0,C.P(new C.t(1/0,n,new C.a2(!0,d.a.c2e(a2,g,e),n),n),n,n),n,n,v,v,0,n)
i=i?1-a1:a1
e=g.b7(e)
u=a0?360:1
t=a0?1:0.01
s=a0?10:0.1
r=d.d
d.a.toString
q=o.r
p=q.Rz(g)
a0=a0?new A.ezD(q):q.gbUi()
return C.c8(C.cx(B.ap,new C.t(m,w,new C.ay(B.P,n,B.X,B.v,C.a([v,C.dV(n,I.BS(!1,B.F,d.a.f,n,n,r,n,B.lU,u,0,l,n,n,n,new A.ezE(h,g),n,s,a0,p,t,e),w,n,i*j,n,0,k)],y.u),n),n),B.q,!1,n,n,new A.ezF(d),new A.ezG(f),new A.ezH(d),new A.ezI(d),new A.ezJ(f),n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n),x,n,n,n,n,n,!0)},
$S:181}
A.ezL.prototype={
$1(d){var x,w,v=this,u=v.a
if(u<=0)return
x=B.i.J((d-v.b.a/2)/u,0,1)
if(v.c)x=1-x
u=v.e
w=u===B.zp?360:1
A.iMf(v.d,u,x*w)},
$S:18}
A.ezG.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:215}
A.ezI.prototype={
$1(d){var x=this.a
return x.n(new A.ezA(x))},
$S:44}
A.ezA.prototype={
$0(){return this.a.d=!0},
$S:0}
A.ezJ.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:33}
A.ezH.prototype={
$1(d){var x=this.a
return x.n(new A.ezB(x))},
$S:41}
A.ezB.prototype={
$0(){return this.a.d=!1},
$S:0}
A.ezF.prototype={
$0(){var x=this.a
return x.n(new A.ezC(x))},
$S:0}
A.ezC.prototype={
$0(){return this.a.d=!1},
$S:0}
A.ezD.prototype={
$1(d){return C.cv(B.i.ai(d),C.c4(this.a.gba()),null,null)+"\xb0"},
$S:16}
A.ezE.prototype={
$1(d){return A.iMf(this.a,this.b,d)},
$S:18};(function installTearOffs(){var x=a._instance_1u,w=a._instance_2u
x(A.rx.prototype,"gaYl","N5",0)
w(A.b0e.prototype,"gbcp","bcq",1)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(C.Y,[A.cV,A.ho])
w(A.rx,C.bq)
x(C.cf,[A.dBY,A.ezz,A.ezw,A.ezx,A.ezt,A.ezo,A.ezq,A.ezr,A.ezp,A.ezM,A.ezL,A.ezG,A.ezI,A.ezJ,A.ezH,A.ezD,A.ezE])
x(C.j,[A.aRK,A.asz])
x(C.l,[A.b0e,A.c2X])
x(C.d2,[A.ezy,A.ezv,A.ezu,A.ezm,A.ezj,A.ezk,A.ezn,A.ezl,A.ezA,A.ezB,A.ezF,A.ezC])
x(C.di,[A.ezs,A.ezK])})()
C.bN(b.typeUniverse,JSON.parse('{"aRK":{"j":[],"b":[]},"asz":{"j":[],"b":[]},"rx":{"bq":["cV"],"a6":[]},"b0e":{"l":["aRK"]},"c2X":{"l":["asz"]}}'))
var y={o:C.G("dt"),x:C.G("o<n>"),u:C.G("o<b>"),t:C.G("dE"),q:C.G("eo<cV>"),k:C.G("U")};(function constants(){E.m2=new C.f(1,0.19607843137254902,0.3843137254901961,0.5490196078431373,B.e)
E.axZ=new C.qY("precise")})()};
(a=>{a["HFFj6XGEiEWyPyzqkHTWPJ/F1lg="]=a.current})($__dart_deferred_initializers__);