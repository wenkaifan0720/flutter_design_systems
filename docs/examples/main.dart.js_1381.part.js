((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var C,B,F,I,A={
qG(d){var x=d.gTU()/255,w=d.gMH()/255,v=d.gR4()/255,u=Math.max(x,Math.max(w,v)),t=u-Math.min(x,Math.min(w,v)),s=d.gjO(),r=D.iHW(x,w,v,u,t),q=u===0?0:t/u
return new A.cU(s/255,r,q,u)},
cU:function cU(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
iJM(d,e,f){var x,w
switch(e.a){case 0:x=d.a
w=B.i.J(f,0,360)
d.st(new A.cU(x.a,w,x.c,x.d))
break
case 1:x=d.a
w=B.i.J(f,0,1)
d.st(new A.cU(x.a,x.b,w,x.d))
break
case 2:x=d.a
w=B.i.J(f,0,1)
d.st(new A.cU(x.a,x.b,x.c,w))
break
case 3:x=d.a
d.st(new A.cU(B.i.J(f,0,1),x.b,x.c,x.d))
break}},
izC(d,e,f){return new A.aRr(e,d,f,null)},
j1k(d,e,f,g,h){return new A.ase(e,d,h,f,g,null)},
ru:function ru(d,e){var _=this
_.a=d
_.M$=0
_.O$=e
_.ar$=_.av$=0},
dAZ:function dAZ(){},
ho:function ho(d,e){this.a=d
this.b=e},
aRr:function aRr(d,e,f,g){var _=this
_.c=d
_.d=e
_.e=f
_.a=g},
b0_:function b0_(){var _=this
_.d=!1
_.e=$
_.r=_.f=!1
_.c=_.a=null},
eyk:function eyk(d){this.a=d},
eyj:function eyj(d,e){this.a=d
this.b=e},
eyh:function eyh(d,e,f){this.a=d
this.b=e
this.c=f},
eyi:function eyi(d,e){this.a=d
this.b=e},
eyg:function eyg(d,e){this.a=d
this.b=e},
eyf:function eyf(d,e){this.a=d
this.b=e},
eye:function eye(d){this.a=d},
ey7:function ey7(d,e){this.a=d
this.b=e},
eyd:function eyd(d,e,f){this.a=d
this.b=e
this.c=f},
ey9:function ey9(d,e){this.a=d
this.b=e},
eyb:function eyb(d){this.a=d},
ey4:function ey4(d){this.a=d},
eyc:function eyc(d,e){this.a=d
this.b=e},
eya:function eya(d){this.a=d},
ey5:function ey5(d){this.a=d},
ey8:function ey8(d){this.a=d},
ey6:function ey6(d){this.a=d},
ase:function ase(d,e,f,g,h,i){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.w=h
_.a=i},
c2x:function c2x(){this.d=!1
this.c=this.a=null},
eyx:function eyx(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},
eyv:function eyv(d,e,f,g,h,i,j){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i
_.r=j},
eyw:function eyw(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
eyr:function eyr(d){this.a=d},
eyt:function eyt(d){this.a=d},
eyl:function eyl(d){this.a=d},
eyu:function eyu(d){this.a=d},
eys:function eys(d){this.a=d},
eym:function eym(d){this.a=d},
eyq:function eyq(d){this.a=d},
eyn:function eyn(d){this.a=d},
eyo:function eyo(d){this.a=d},
eyp:function eyp(d,e){this.a=d
this.b=e}},E,K,G,D,H
C=c[0]
B=c[2]
F=c[268]
I=c[250]
A=a.updateHolder(c[139],A)
E=c[329]
K=c[289]
G=c[252]
D=c[266]
H=c[274]
A.cU.prototype={
bK(){var x=this,w=x.d,v=x.c*w,u=x.b
return C.iGU(x.a,u,v,v*(1-Math.abs(B.i.a6(u/60,2)-1)),w-v)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
return e instanceof A.cU&&e.a===x.a&&e.b===x.b&&e.c===x.c&&e.d===x.d},
ga3(d){var x=this
return C.aO(x.a,x.b,x.c,x.d,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a)},
B(d){var x=this
return"HSVColor("+C.am(x.a)+", "+C.am(x.b)+", "+C.am(x.c)+", "+C.am(x.d)+")"}}
A.ru.prototype={
sfW(d){var x=A.qG(d),w=x.c
this.st(w===0||x.d===0?new A.cU(x.a,this.a.b,w,x.d):x)},
gnf(){var x=this.a.bK(),w=new A.dAZ(),v="#"+C.am(w.$1(x.b))+C.am(w.$1(x.c))+C.am(w.$1(x.d)),u=x.a
return u>=1?v:v+C.am(w.$1(u))},
MS(d){var x,w,v,u,t,s,r=B.r.c3(d)
if(B.r.fR(r,"#"))r=B.r.h0(r,1)
x=C.eF("^[0-9a-fA-F]+$",!0,!1)
if(!x.b.test(r))return!1
if(r.length===3){x=C.a([],y.x)
for(w=r.split(""),v=w.length,u=0;u<v;++u){t=w[u]
x.push(t+t)}r=B.c.lZ(x)}if(r.length===6)r+="FF"
if(r.length!==8)return!1
s=C.pb(r,16)
this.sfW(C.er(((s&255)<<24|B.o.nu(s,8))>>>0))
return!0}}
A.ho.prototype={}
A.aRr.prototype={
p(){return new A.b0_()},
e4(d,e){return this.d.$2(d,e)},
aok(d,e){return this.e.$2(d,e)}}
A.b0_.prototype={
au(){var x,w=this
w.aB()
x=G.Ep()
w.e!==$&&C.df()
w.e=new G.BE(new A.eyk(w),x)},
l(){var x=this.e
x===$&&C.m()
x.l()
this.L()},
asO(d,e){var x,w,v=e.a
if(v<=0||e.b<=0)return
x=this.a.c
w=x.a
v=B.i.J(d.a/v,0,1)
x.st(new A.cU(w.a,w.b,v,B.i.J(1-d.b/e.b,0,1)))},
bbV(d,e){var x,w,v,u,t,s,r=this
if(!(e instanceof C.dt)&&!(e instanceof C.fI))return B.ae
r.a.toString
x=$.es.fp$
x===$&&C.m()
x=x.a
w=C.Z(x).k("bd<2>")
v=0.01*(new C.bd(x,w).m(0,B.jN)||new C.bd(x,w).m(0,B.kh)?10:1)
u=r.a.c.a
t=e.b
if(t.i(0,B.bH)){x=r.a.c
w=u.c
s=x.a
w=B.i.J(w+v,0,1)
x.st(new A.cU(s.a,s.b,w,s.d))}else if(t.i(0,B.bT)){x=r.a.c
w=u.c
s=x.a
w=B.i.J(w-v,0,1)
x.st(new A.cU(s.a,s.b,w,s.d))}else if(t.i(0,B.bB)){x=r.a.c
w=u.d
s=x.a
w=B.i.J(w+v,0,1)
x.st(new A.cU(s.a,s.b,s.c,w))}else if(t.i(0,B.bl)){x=r.a.c
w=u.d
s=x.a
w=B.i.J(w-v,0,1)
x.st(new A.cU(s.a,s.b,s.c,w))}else return B.ae
return B.aH},
h(d){var x,w=C.X(d,H.M,y.t)
if(w==null)w=B.L
x=C.cW(d)
return C.hl(new D.en(this.a.c,new A.eyh(this,w,x),null,null,y.q),B.O)}}
A.ase.prototype={
p(){return new A.c2x()},
c1x(d,e,f){return this.e.$3(d,e,f)}}
A.c2x.prototype={
h(d){var x,w=this.a,v=w.d,u=w.c
w=C.X(d,H.M,y.t)
if(w==null)w=B.L
x=d.u(y.o).w
return new D.en(u,new A.eyx(this,this.a.w,x===B.I,u,v,w),null,null,y.q)}}
var z=a.updateTypes(["x(n)","dZ(bG,dl)","a9(c,cU,b?)"])
A.dAZ.prototype={
$1(d){return B.r.d_(B.o.mZ(B.i.ah(d*255),16),2,"0").toUpperCase()},
$S:15}
A.eyk.prototype={
$1(d){var x=this.a
return x.n(new A.eyj(x,d))},
$S:3}
A.eyj.prototype={
$0(){return this.a.d=this.b},
$S:0}
A.eyh.prototype={
$3(d,e,f){var x,w,v,u,t=null,s=y.k,r=C.az(s),q=this.a
if(q.d)r.H(0,B.x)
if(q.f)r.H(0,B.Z)
if(q.r)r.F(0,C.cL([B.D,B.dz],s))
s=this.b
x=new A.eyi(s,e)
q.a.toString
s=s.gaiS()
w=e.d
v=x.$1(w)
u=x.$1(B.i.J(w+0.1,0,1))
w=x.$1(B.i.J(w-0.1,0,1))
q.a.toString
x=q.e
x===$&&C.m()
return C.C(t,t,t,C.d5(!1,!1,D.oI(t,!1,new F.a9(new A.eyd(q,new A.ho(e,r),e),t),!0,t,!0,E.axh,t,x.gSs(),new A.eye(q),t),t,t,t,t,!1,t,t,t,q.gbbU(),t,!0),!0,t,t,t,w,t,!1,t,!1,t,t,t,t,t,t,t,t,u,t,t,t,s,t,t,t,t,t,t,t,t,t,t,t,t,new A.eyf(q,e),t,t,t,t,t,new A.eyg(q,e),t,t,t,t,t,t,t,t,t,!0,t,t,this.c,t,t,t,t,B.l,v)},
$S:1046}
A.eyi.prototype={
$1(d){var x=this.a
return B.c.aK(C.a([x.Ri(B.cVE)+" "+C.A9(this.b.c,C.cH(x.gbu()),0),x.Ri(B.cVF)+" "+C.A9(d,C.cH(x.gbu()),0)],y.x),x.gwB())},
$S:15}
A.eyg.prototype={
$0(){var x=this.a.a.c,w=this.b.d+0.1,v=x.a,u=B.i.J(w,0,1)
x.st(new A.cU(v.a,v.b,v.c,u))
return w},
$S:0}
A.eyf.prototype={
$0(){var x=this.a.a.c,w=this.b.d-0.1,v=x.a,u=B.i.J(w,0,1)
x.st(new A.cU(v.a,v.b,v.c,u))
return w},
$S:0}
A.eye.prototype={
$1(d){var x=this.a
return x.n(new A.ey7(x,d))},
$S:3}
A.ey7.prototype={
$0(){return this.a.f=this.b},
$S:0}
A.eyd.prototype={
$2(d,e){var x=null,w=e.b,v=e.d,u=new C.I(w,v),t=this.a,s=this.b,r=this.c
return C.cv(B.ao,new C.ay(B.P,x,B.X,B.u,C.a([C.d1(0,t.a.e4(d,s),0,0,0),C.dT(x,C.P(t.a.aok(d,s),x,x),44,x,r.c*w-22,x,(1-r.d)*v-22,44)],y.u),x),B.q,!1,x,x,x,x,x,x,x,x,x,x,x,x,new A.ey8(t),new A.ey9(t,u),new A.eya(t),new A.eyb(t),new A.eyc(t,u),x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x)},
$S:154}
A.ey9.prototype={
$1(d){return this.a.asO(d.b,this.b)},
$S:205}
A.eyb.prototype={
$1(d){var x=this.a
return x.n(new A.ey4(x))},
$S:44}
A.ey4.prototype={
$0(){return this.a.r=!0},
$S:0}
A.eyc.prototype={
$1(d){return this.a.asO(d.b,this.b)},
$S:33}
A.eya.prototype={
$1(d){var x=this.a
return x.n(new A.ey5(x))},
$S:39}
A.ey5.prototype={
$0(){return this.a.r=!1},
$S:0}
A.ey8.prototype={
$0(){var x=this.a
return x.n(new A.ey6(x))},
$S:0}
A.ey6.prototype={
$0(){return this.a.r=!1},
$S:0}
A.eyx.prototype={
$3(d,e,f){var x=this
return new F.a9(new A.eyv(x.a,x.b,x.c,x.d,x.e,e,x.f),null)},
$S:z+2}
A.eyv.prototype={
$2(a2,a3){var x,w,v,u,t,s,r,q,p,o=this,n=null,m=a3.b,l=o.b,k=l.a,j=m-k,i=o.c,h=o.d,g=o.e,f=new A.eyw(j,l,i,h,g),e=o.f,d=g.b5(e),a0=g===B.zl,a1=d/(a0?360:1)
d=o.a
x=d.d?K.lJ:B.aW
w=l.b
v=k/2
v=C.dT(0,C.P(new C.t(1/0,n,new C.a2(!0,d.a.c1x(a2,g,e),n),n),n,n),n,n,v,v,0,n)
i=i?1-a1:a1
e=g.b5(e)
u=a0?360:1
t=a0?1:0.01
s=a0?10:0.1
r=d.d
d.a.toString
q=o.r
p=q.Ri(g)
a0=a0?new A.eyo(q):q.gbTC()
return C.c6(C.cv(B.ao,new C.t(m,w,new C.ay(B.P,n,B.X,B.u,C.a([v,C.dT(n,I.BN(!1,B.F,d.a.f,n,n,r,n,B.lP,u,0,l,n,n,n,new A.eyp(h,g),n,s,a0,p,t,e),w,n,i*j,n,0,k)],y.u),n),n),B.q,!1,n,n,new A.eyq(d),new A.eyr(f),new A.eys(d),new A.eyt(d),new A.eyu(f),n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n),x,n,n,n,n,n,!0)},
$S:180}
A.eyw.prototype={
$1(d){var x,w,v=this,u=v.a
if(u<=0)return
x=B.i.J((d-v.b.a/2)/u,0,1)
if(v.c)x=1-x
u=v.e
w=u===B.zl?360:1
A.iJM(v.d,u,x*w)},
$S:18}
A.eyr.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:205}
A.eyt.prototype={
$1(d){var x=this.a
return x.n(new A.eyl(x))},
$S:44}
A.eyl.prototype={
$0(){return this.a.d=!0},
$S:0}
A.eyu.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:33}
A.eys.prototype={
$1(d){var x=this.a
return x.n(new A.eym(x))},
$S:39}
A.eym.prototype={
$0(){return this.a.d=!1},
$S:0}
A.eyq.prototype={
$0(){var x=this.a
return x.n(new A.eyn(x))},
$S:0}
A.eyn.prototype={
$0(){return this.a.d=!1},
$S:0}
A.eyo.prototype={
$1(d){return C.d8(B.i.ah(d),C.cH(this.a.gbu()),null,null)+"\xb0"},
$S:15}
A.eyp.prototype={
$1(d){return A.iJM(this.a,this.b,d)},
$S:18};(function installTearOffs(){var x=a._instance_1u,w=a._instance_2u
x(A.ru.prototype,"gaXS","MS",0)
w(A.b0_.prototype,"gbbU","bbV",1)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(C.Y,[A.cU,A.ho])
w(A.ru,C.bq)
x(C.cl,[A.dAZ,A.eyk,A.eyh,A.eyi,A.eye,A.ey9,A.eyb,A.eyc,A.eya,A.eyx,A.eyw,A.eyr,A.eyt,A.eyu,A.eys,A.eyo,A.eyp])
x(C.j,[A.aRr,A.ase])
x(C.l,[A.b0_,A.c2x])
x(C.d0,[A.eyj,A.eyg,A.eyf,A.ey7,A.ey4,A.ey5,A.ey8,A.ey6,A.eyl,A.eym,A.eyq,A.eyn])
x(C.dk,[A.eyd,A.eyv])})()
C.bO(b.typeUniverse,JSON.parse('{"aRr":{"j":[],"b":[]},"ase":{"j":[],"b":[]},"ru":{"bq":["cU"],"a6":[]},"b0_":{"l":["aRr"]},"c2x":{"l":["ase"]}}'))
var y={o:C.G("dv"),x:C.G("o<n>"),u:C.G("o<b>"),t:C.G("dF"),q:C.G("en<cU>"),k:C.G("U")};(function constants(){E.lY=new C.h(1,0.19607843137254902,0.3843137254901961,0.5490196078431373,B.e)
E.axh=new C.qT("precise")})()};
(a=>{a["68BBz+rQjZWwUGCegdB5BkquA2E="]=a.current})($__dart_deferred_initializers__);