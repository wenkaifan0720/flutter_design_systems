((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var C,B,F,I,A={
qI(d){var x=d.gU5()/255,w=d.gMR()/255,v=d.gRh()/255,u=Math.max(x,Math.max(w,v)),t=u-Math.min(x,Math.min(w,v)),s=d.gjP(),r=D.iJs(x,w,v,u,t),q=u===0?0:t/u
return new A.cV(s/255,r,q,u)},
cV:function cV(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
iLi(d,e,f){var x,w
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
iB5(d,e,f){return new A.aRG(e,d,f,null)},
j2O(d,e,f,g,h){return new A.asq(e,d,h,f,g,null)},
rx:function rx(d,e){var _=this
_.a=d
_.M$=0
_.O$=e
_.ar$=_.av$=0},
dBE:function dBE(){},
hp:function hp(d,e){this.a=d
this.b=e},
aRG:function aRG(d,e,f,g){var _=this
_.c=d
_.d=e
_.e=f
_.a=g},
b0b:function b0b(){var _=this
_.d=!1
_.e=$
_.r=_.f=!1
_.c=_.a=null},
ez1:function ez1(d){this.a=d},
ez0:function ez0(d,e){this.a=d
this.b=e},
eyZ:function eyZ(d,e,f){this.a=d
this.b=e
this.c=f},
ez_:function ez_(d,e){this.a=d
this.b=e},
eyY:function eyY(d,e){this.a=d
this.b=e},
eyX:function eyX(d,e){this.a=d
this.b=e},
eyW:function eyW(d){this.a=d},
eyP:function eyP(d,e){this.a=d
this.b=e},
eyV:function eyV(d,e,f){this.a=d
this.b=e
this.c=f},
eyR:function eyR(d,e){this.a=d
this.b=e},
eyT:function eyT(d){this.a=d},
eyM:function eyM(d){this.a=d},
eyU:function eyU(d,e){this.a=d
this.b=e},
eyS:function eyS(d){this.a=d},
eyN:function eyN(d){this.a=d},
eyQ:function eyQ(d){this.a=d},
eyO:function eyO(d){this.a=d},
asq:function asq(d,e,f,g,h,i){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.w=h
_.a=i},
c2M:function c2M(){this.d=!1
this.c=this.a=null},
eze:function eze(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},
ezc:function ezc(d,e,f,g,h,i,j){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i
_.r=j},
ezd:function ezd(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
ez8:function ez8(d){this.a=d},
eza:function eza(d){this.a=d},
ez2:function ez2(d){this.a=d},
ezb:function ezb(d){this.a=d},
ez9:function ez9(d){this.a=d},
ez3:function ez3(d){this.a=d},
ez7:function ez7(d){this.a=d},
ez4:function ez4(d){this.a=d},
ez5:function ez5(d){this.a=d},
ez6:function ez6(d,e){this.a=d
this.b=e}},E,K,G,D,H
C=c[0]
B=c[2]
F=c[270]
I=c[252]
A=a.updateHolder(c[141],A)
E=c[331]
K=c[291]
G=c[254]
D=c[268]
H=c[276]
A.cV.prototype={
bA(){var x=this,w=x.d,v=x.c*w,u=x.b
return C.iIp(x.a,u,v,v*(1-Math.abs(B.i.a7(u/60,2)-1)),w-v)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
return e instanceof A.cV&&e.a===x.a&&e.b===x.b&&e.c===x.c&&e.d===x.d},
ga3(d){var x=this
return C.aN(x.a,x.b,x.c,x.d,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a)},
B(d){var x=this
return"HSVColor("+C.an(x.a)+", "+C.an(x.b)+", "+C.an(x.c)+", "+C.an(x.d)+")"}}
A.rx.prototype={
sfZ(d){var x=A.qI(d),w=x.c
this.st(w===0||x.d===0?new A.cV(x.a,this.a.b,w,x.d):x)},
gnk(){var x=this.a.bA(),w=new A.dBE(),v="#"+C.an(w.$1(x.b))+C.an(w.$1(x.c))+C.an(w.$1(x.d)),u=x.a
return u>=1?v:v+C.an(w.$1(u))},
N1(d){var x,w,v,u,t,s,r=B.t.c5(d)
if(B.t.fU(r,"#"))r=B.t.h5(r,1)
x=C.eH("^[0-9a-fA-F]+$",!0,!1)
if(!x.b.test(r))return!1
if(r.length===3){x=C.a([],y.x)
for(w=r.split(""),v=w.length,u=0;u<v;++u){t=w[u]
x.push(t+t)}r=B.c.m2(x)}if(r.length===6)r+="FF"
if(r.length!==8)return!1
s=C.pd(r,16)
this.sfZ(C.em(((s&255)<<24|B.o.nz(s,8))>>>0))
return!0}}
A.hp.prototype={}
A.aRG.prototype={
p(){return new A.b0b()},
e6(d,e){return this.d.$2(d,e)},
aox(d,e){return this.e.$2(d,e)}}
A.b0b.prototype={
au(){var x,w=this
w.aB()
x=G.Es()
w.e!==$&&C.dg()
w.e=new G.BF(new A.ez1(w),x)},
l(){var x=this.e
x===$&&C.m()
x.l()
this.L()},
at_(d,e){var x,w,v=e.a
if(v<=0||e.b<=0)return
x=this.a.c
w=x.a
v=B.i.J(d.a/v,0,1)
x.st(new A.cV(w.a,w.b,v,B.i.J(1-d.b/e.b,0,1)))},
bcc(d,e){var x,w,v,u,t,s,r=this
if(!(e instanceof C.dt)&&!(e instanceof C.fJ))return B.ae
r.a.toString
x=$.es.fq$
x===$&&C.m()
x=x.a
w=C.a_(x).k("bc<2>")
v=0.01*(new C.bc(x,w).m(0,B.jO)||new C.bc(x,w).m(0,B.ki)?10:1)
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
return C.h6(new D.eo(this.a.c,new A.eyZ(this,w,x),null,null,y.q),B.O)}}
A.asq.prototype={
p(){return new A.c2M()},
c20(d,e,f){return this.e.$3(d,e,f)}}
A.c2M.prototype={
h(d){var x,w=this.a,v=w.d,u=w.c
w=C.X(d,H.M,y.t)
if(w==null)w=B.K
x=d.u(y.o).w
return new D.eo(u,new A.eze(this,this.a.w,x===B.I,u,v,w),null,null,y.q)}}
var z=a.updateTypes(["x(n)","dZ(bG,dl)","a9(c,cV,b?)"])
A.dBE.prototype={
$1(d){return B.t.dQ(B.o.n0(B.i.ah(d*255),16),2,"0").toUpperCase()},
$S:16}
A.ez1.prototype={
$1(d){var x=this.a
return x.n(new A.ez0(x,d))},
$S:3}
A.ez0.prototype={
$0(){return this.a.d=this.b},
$S:0}
A.eyZ.prototype={
$3(d,e,f){var x,w,v,u,t=null,s=y.k,r=C.az(s),q=this.a
if(q.d)r.H(0,B.x)
if(q.f)r.H(0,B.Z)
if(q.r)r.F(0,C.cM([B.D,B.dC],s))
s=this.b
x=new A.ez_(s,e)
q.a.toString
s=s.gajc()
w=e.d
v=x.$1(w)
u=x.$1(B.i.J(w+0.1,0,1))
w=x.$1(B.i.J(w-0.1,0,1))
q.a.toString
x=q.e
x===$&&C.m()
return C.C(t,t,t,C.d7(!1,!1,D.oJ(t,!1,new F.a9(new A.eyV(q,new A.hp(e,r),e),t),!0,t,!0,E.axY,t,x.gSF(),new A.eyW(q),t),t,t,t,t,!1,t,t,t,q.gbcb(),t,!0),!0,t,t,t,w,t,!1,t,!1,t,t,t,t,t,t,t,t,u,t,t,t,s,t,t,t,t,t,t,t,t,t,t,t,t,new A.eyX(q,e),t,t,t,t,t,new A.eyY(q,e),t,t,t,t,t,t,t,t,t,!0,t,t,this.c,t,t,t,t,B.l,v)},
$S:1052}
A.ez_.prototype={
$1(d){var x=this.a
return B.c.aK(C.a([x.Ru(B.cWI)+" "+C.Ae(this.b.c,C.cc(x.gbc()),0),x.Ru(B.cWJ)+" "+C.Ae(d,C.cc(x.gbc()),0)],y.x),x.gwH())},
$S:16}
A.eyY.prototype={
$0(){var x=this.a.a.c,w=this.b.d+0.1,v=x.a,u=B.i.J(w,0,1)
x.st(new A.cV(v.a,v.b,v.c,u))
return w},
$S:0}
A.eyX.prototype={
$0(){var x=this.a.a.c,w=this.b.d-0.1,v=x.a,u=B.i.J(w,0,1)
x.st(new A.cV(v.a,v.b,v.c,u))
return w},
$S:0}
A.eyW.prototype={
$1(d){var x=this.a
return x.n(new A.eyP(x,d))},
$S:3}
A.eyP.prototype={
$0(){return this.a.f=this.b},
$S:0}
A.eyV.prototype={
$2(d,e){var x=null,w=e.b,v=e.d,u=new C.I(w,v),t=this.a,s=this.b,r=this.c
return C.cw(B.ap,new C.ay(B.P,x,B.X,B.v,C.a([C.d3(0,t.a.e6(d,s),0,0,0),C.dT(x,C.P(t.a.aox(d,s),x,x),44,x,r.c*w-22,x,(1-r.d)*v-22,44)],y.u),x),B.q,!1,x,x,x,x,x,x,x,x,x,x,x,x,new A.eyQ(t),new A.eyR(t,u),new A.eyS(t),new A.eyT(t),new A.eyU(t,u),x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x)},
$S:161}
A.eyR.prototype={
$1(d){return this.a.at_(d.b,this.b)},
$S:192}
A.eyT.prototype={
$1(d){var x=this.a
return x.n(new A.eyM(x))},
$S:46}
A.eyM.prototype={
$0(){return this.a.r=!0},
$S:0}
A.eyU.prototype={
$1(d){return this.a.at_(d.b,this.b)},
$S:34}
A.eyS.prototype={
$1(d){var x=this.a
return x.n(new A.eyN(x))},
$S:40}
A.eyN.prototype={
$0(){return this.a.r=!1},
$S:0}
A.eyQ.prototype={
$0(){var x=this.a
return x.n(new A.eyO(x))},
$S:0}
A.eyO.prototype={
$0(){return this.a.r=!1},
$S:0}
A.eze.prototype={
$3(d,e,f){var x=this
return new F.a9(new A.ezc(x.a,x.b,x.c,x.d,x.e,e,x.f),null)},
$S:z+2}
A.ezc.prototype={
$2(a2,a3){var x,w,v,u,t,s,r,q,p,o=this,n=null,m=a3.b,l=o.b,k=l.a,j=m-k,i=o.c,h=o.d,g=o.e,f=new A.ezd(j,l,i,h,g),e=o.f,d=g.b5(e),a0=g===B.zq,a1=d/(a0?360:1)
d=o.a
x=d.d?K.lN:B.aW
w=l.b
v=k/2
v=C.dT(0,C.P(new C.t(1/0,n,new C.a2(!0,d.a.c20(a2,g,e),n),n),n,n),n,n,v,v,0,n)
i=i?1-a1:a1
e=g.b5(e)
u=a0?360:1
t=a0?1:0.01
s=a0?10:0.1
r=d.d
d.a.toString
q=o.r
p=q.Ru(g)
a0=a0?new A.ez5(q):q.gbU4()
return C.c6(C.cw(B.ap,new C.t(m,w,new C.ay(B.P,n,B.X,B.v,C.a([v,C.dT(n,I.BO(!1,B.F,d.a.f,n,n,r,n,B.lT,u,0,l,n,n,n,new A.ez6(h,g),n,s,a0,p,t,e),w,n,i*j,n,0,k)],y.u),n),n),B.q,!1,n,n,new A.ez7(d),new A.ez8(f),new A.ez9(d),new A.eza(d),new A.ezb(f),n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n),x,n,n,n,n,n,!0)},
$S:180}
A.ezd.prototype={
$1(d){var x,w,v=this,u=v.a
if(u<=0)return
x=B.i.J((d-v.b.a/2)/u,0,1)
if(v.c)x=1-x
u=v.e
w=u===B.zq?360:1
A.iLi(v.d,u,x*w)},
$S:18}
A.ez8.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:192}
A.eza.prototype={
$1(d){var x=this.a
return x.n(new A.ez2(x))},
$S:46}
A.ez2.prototype={
$0(){return this.a.d=!0},
$S:0}
A.ezb.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:34}
A.ez9.prototype={
$1(d){var x=this.a
return x.n(new A.ez3(x))},
$S:40}
A.ez3.prototype={
$0(){return this.a.d=!1},
$S:0}
A.ez7.prototype={
$0(){var x=this.a
return x.n(new A.ez4(x))},
$S:0}
A.ez4.prototype={
$0(){return this.a.d=!1},
$S:0}
A.ez5.prototype={
$1(d){return C.cC(B.i.ah(d),C.cc(this.a.gbc()),null,null)+"\xb0"},
$S:16}
A.ez6.prototype={
$1(d){return A.iLi(this.a,this.b,d)},
$S:18};(function installTearOffs(){var x=a._instance_1u,w=a._instance_2u
x(A.rx.prototype,"gaY9","N1",0)
w(A.b0b.prototype,"gbcb","bcc",1)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(C.Y,[A.cV,A.hp])
w(A.rx,C.bq)
x(C.cl,[A.dBE,A.ez1,A.eyZ,A.ez_,A.eyW,A.eyR,A.eyT,A.eyU,A.eyS,A.eze,A.ezd,A.ez8,A.eza,A.ezb,A.ez9,A.ez5,A.ez6])
x(C.j,[A.aRG,A.asq])
x(C.l,[A.b0b,A.c2M])
x(C.d1,[A.ez0,A.eyY,A.eyX,A.eyP,A.eyM,A.eyN,A.eyQ,A.eyO,A.ez2,A.ez3,A.ez7,A.ez4])
x(C.di,[A.eyV,A.ezc])})()
C.bO(b.typeUniverse,JSON.parse('{"aRG":{"j":[],"b":[]},"asq":{"j":[],"b":[]},"rx":{"bq":["cV"],"a6":[]},"b0b":{"l":["aRG"]},"c2M":{"l":["asq"]}}'))
var y={o:C.G("dv"),x:C.G("o<n>"),u:C.G("o<b>"),t:C.G("dD"),q:C.G("eo<cV>"),k:C.G("U")};(function constants(){E.m1=new C.f(1,0.19607843137254902,0.3843137254901961,0.5490196078431373,B.e)
E.axY=new C.qX("precise")})()};
(a=>{a["ast9Xl2zIHxMDWjzVPXMBJtrK/M="]=a.current})($__dart_deferred_initializers__);