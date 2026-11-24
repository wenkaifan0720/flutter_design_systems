((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var C,B,I,A={
qC(d){var x=d.gTz()/255,w=d.gMp()/255,v=d.gQN()/255,u=Math.max(x,Math.max(w,v)),t=u-Math.min(x,Math.min(w,v)),s=d.gjM(),r=D.iH8(x,w,v,u,t),q=u===0?0:t/u
return new A.cS(s/255,r,q,u)},
cS:function cS(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
iIZ(d,e,f){var x,w
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
iyO(d,e,f){return new A.aRp(e,d,f,null)},
j0v(d,e,f,g,h){return new A.asb(e,d,h,f,g,null)},
rs:function rs(d,e){var _=this
_.a=d
_.L$=0
_.N$=e
_.aq$=_.au$=0},
dAJ:function dAJ(){},
hh:function hh(d,e){this.a=d
this.b=e},
aRp:function aRp(d,e,f,g){var _=this
_.c=d
_.d=e
_.e=f
_.a=g},
b_W:function b_W(){var _=this
_.d=!1
_.e=$
_.r=_.f=!1
_.c=_.a=null},
ey7:function ey7(d){this.a=d},
ey6:function ey6(d,e){this.a=d
this.b=e},
ey4:function ey4(d,e,f){this.a=d
this.b=e
this.c=f},
ey5:function ey5(d,e){this.a=d
this.b=e},
ey3:function ey3(d,e){this.a=d
this.b=e},
ey2:function ey2(d,e){this.a=d
this.b=e},
ey1:function ey1(d){this.a=d},
exV:function exV(d,e){this.a=d
this.b=e},
ey0:function ey0(d,e,f){this.a=d
this.b=e
this.c=f},
exX:function exX(d,e){this.a=d
this.b=e},
exZ:function exZ(d){this.a=d},
exS:function exS(d){this.a=d},
ey_:function ey_(d,e){this.a=d
this.b=e},
exY:function exY(d){this.a=d},
exT:function exT(d){this.a=d},
exW:function exW(d){this.a=d},
exU:function exU(d){this.a=d},
asb:function asb(d,e,f,g,h,i){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.w=h
_.a=i},
c2r:function c2r(){this.d=!1
this.c=this.a=null},
eyk:function eyk(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},
eyi:function eyi(d,e,f,g,h,i,j){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i
_.r=j},
eyj:function eyj(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
eye:function eye(d){this.a=d},
eyg:function eyg(d){this.a=d},
ey8:function ey8(d){this.a=d},
eyh:function eyh(d){this.a=d},
eyf:function eyf(d){this.a=d},
ey9:function ey9(d){this.a=d},
eyd:function eyd(d){this.a=d},
eya:function eya(d){this.a=d},
eyb:function eyb(d){this.a=d},
eyc:function eyc(d,e){this.a=d
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
return C.iG6(x.a,u,v,v*(1-Math.abs(B.i.a5(u/60,2)-1)),w-v)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
return e instanceof A.cS&&e.a===x.a&&e.b===x.b&&e.c===x.c&&e.d===x.d},
ga2(d){var x=this
return C.aO(x.a,x.b,x.c,x.d,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a)},
A(d){var x=this
return"HSVColor("+C.an(x.a)+", "+C.an(x.b)+", "+C.an(x.c)+", "+C.an(x.d)+")"}}
A.rs.prototype={
sfU(d){var x=A.qC(d),w=x.c
this.sq(w===0||x.d===0?new A.cS(x.a,this.a.b,w,x.d):x)},
gmZ(){var x=this.a.bJ(),w=new A.dAJ(),v="#"+C.an(w.$1(x.b))+C.an(w.$1(x.c))+C.an(w.$1(x.d)),u=x.a
return u>=1?v:v+C.an(w.$1(u))},
Mz(d){var x,w,v,u,t,s,r=B.r.c2(d)
if(B.r.fO(r,"#"))r=B.r.fZ(r,1)
x=C.eE("^[0-9a-fA-F]+$",!0,!1)
if(!x.b.test(r))return!1
if(r.length===3){x=C.a([],y.x)
for(w=r.split(""),v=w.length,u=0;u<v;++u){t=w[u]
x.push(t+t)}r=B.c.lR(x)}if(r.length===6)r+="FF"
if(r.length!==8)return!1
s=C.p9(r,16)
this.sfU(C.ep(((s&255)<<24|B.o.ne(s,8))>>>0))
return!0}}
A.hh.prototype={}
A.aRp.prototype={
n(){return new A.b_W()},
e2(d,e){return this.d.$2(d,e)},
anG(d,e){return this.e.$2(d,e)}}
A.b_W.prototype={
ar(){var x,w=this
w.aA()
x=F.En()
w.e!==$&&C.dd()
w.e=new F.BC(new A.ey7(w),x)},
k(){var x=this.e
x===$&&C.l()
x.k()
this.K()},
asj(d,e){var x,w,v=e.a
if(v<=0||e.b<=0)return
x=this.a.c
w=x.a
v=B.i.I(d.a/v,0,1)
x.sq(new A.cS(w.a,w.b,v,B.i.I(1-d.b/e.b,0,1)))},
bbC(d,e){var x,w,v,u,t,s,r=this
if(!(e instanceof C.ds)&&!(e instanceof C.fF))return B.ad
r.a.toString
x=$.eq.fn$
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
x.sq(new A.cS(s.a,s.b,s.c,w))}else if(t.i(0,B.bm)){x=r.a.c
w=u.d
s=x.a
w=B.i.I(w-v,0,1)
x.sq(new A.cS(s.a,s.b,s.c,w))}else return B.ad
return B.aH},
h(d){var x,w=C.W(d,G.M,y.t)
if(w==null)w=B.L
x=C.cV(d)
return C.hf(new D.ek(this.a.c,new A.ey4(this,w,x),null,null,y.q),B.O)}}
A.asb.prototype={
n(){return new A.c2r()},
c18(d,e,f){return this.e.$3(d,e,f)}}
A.c2r.prototype={
h(d){var x,w=this.a,v=w.d,u=w.c
w=C.W(d,G.M,y.t)
if(w==null)w=B.L
x=d.t(y.o).w
return new D.ek(u,new A.eyk(this,this.a.w,x===B.I,u,v,w),null,null,y.q)}}
var z=a.updateTypes(["w(m)","dW(bF,dk)","a9(c,cS,b?)"])
A.dAJ.prototype={
$1(d){return B.r.cZ(B.o.mJ(B.i.ag(d*255),16),2,"0").toUpperCase()},
$S:13}
A.ey7.prototype={
$1(d){var x=this.a
return x.m(new A.ey6(x,d))},
$S:3}
A.ey6.prototype={
$0(){return this.a.d=this.b},
$S:0}
A.ey4.prototype={
$3(d,e,f){var x,w,v,u,t=null,s=y.k,r=C.az(s),q=this.a
if(q.d)r.G(0,B.x)
if(q.f)r.G(0,B.Z)
if(q.r)r.E(0,C.cK([B.D,B.dz],s))
s=this.b
x=new A.ey5(s,e)
q.a.toString
s=s.gai9()
w=e.d
v=x.$1(w)
u=x.$1(B.i.I(w+0.1,0,1))
w=x.$1(B.i.I(w-0.1,0,1))
q.a.toString
x=q.e
x===$&&C.l()
return C.B(t,t,t,C.d3(!1,!1,D.oG(t,!1,new H.a9(new A.ey0(q,new A.hh(e,r),e),t),!0,t,!0,E.axe,t,x.gS8(),new A.ey1(q),t),t,t,t,t,!1,t,t,t,q.gbbB(),t,!0),!0,t,t,t,w,t,!1,t,!1,t,t,t,t,t,t,t,t,u,t,t,t,s,t,t,t,t,t,t,t,t,t,t,t,t,new A.ey2(q,e),t,t,t,t,t,new A.ey3(q,e),t,t,t,t,t,t,t,t,t,!0,t,t,this.c,t,t,t,t,B.l,v)},
$S:1043}
A.ey5.prototype={
$1(d){var x=this.a
return B.c.aM(C.a([x.QY(B.cVX)+" "+C.A7(this.b.c,C.cG(x.gbt()),0),x.QY(B.cVY)+" "+C.A7(d,C.cG(x.gbt()),0)],y.x),x.gwq())},
$S:13}
A.ey3.prototype={
$0(){var x=this.a.a.c,w=this.b.d+0.1,v=x.a,u=B.i.I(w,0,1)
x.sq(new A.cS(v.a,v.b,v.c,u))
return w},
$S:0}
A.ey2.prototype={
$0(){var x=this.a.a.c,w=this.b.d-0.1,v=x.a,u=B.i.I(w,0,1)
x.sq(new A.cS(v.a,v.b,v.c,u))
return w},
$S:0}
A.ey1.prototype={
$1(d){var x=this.a
return x.m(new A.exV(x,d))},
$S:3}
A.exV.prototype={
$0(){return this.a.f=this.b},
$S:0}
A.ey0.prototype={
$2(d,e){var x=null,w=e.b,v=e.d,u=new C.H(w,v),t=this.a,s=this.b,r=this.c
return C.cu(B.an,new C.ay(B.P,x,B.X,B.u,C.a([C.d0(0,t.a.e2(d,s),0,0,0),C.dR(x,C.O(t.a.anG(d,s),x,x),44,x,r.c*w-22,x,(1-r.d)*v-22,44)],y.u),x),B.q,!1,x,x,x,x,x,x,x,x,x,x,x,x,new A.exW(t),new A.exX(t,u),new A.exY(t),new A.exZ(t),new A.ey_(t,u),x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x)},
$S:155}
A.exX.prototype={
$1(d){return this.a.asj(d.b,this.b)},
$S:191}
A.exZ.prototype={
$1(d){var x=this.a
return x.m(new A.exS(x))},
$S:42}
A.exS.prototype={
$0(){return this.a.r=!0},
$S:0}
A.ey_.prototype={
$1(d){return this.a.asj(d.b,this.b)},
$S:33}
A.exY.prototype={
$1(d){var x=this.a
return x.m(new A.exT(x))},
$S:39}
A.exT.prototype={
$0(){return this.a.r=!1},
$S:0}
A.exW.prototype={
$0(){var x=this.a
return x.m(new A.exU(x))},
$S:0}
A.exU.prototype={
$0(){return this.a.r=!1},
$S:0}
A.eyk.prototype={
$3(d,e,f){var x=this
return new H.a9(new A.eyi(x.a,x.b,x.c,x.d,x.e,e,x.f),null)},
$S:z+2}
A.eyi.prototype={
$2(a2,a3){var x,w,v,u,t,s,r,q,p,o=this,n=null,m=a3.b,l=o.b,k=l.a,j=m-k,i=o.c,h=o.d,g=o.e,f=new A.eyj(j,l,i,h,g),e=o.f,d=g.b5(e),a0=g===B.ze,a1=d/(a0?360:1)
d=o.a
x=d.d?K.lJ:B.aW
w=l.b
v=k/2
v=C.dR(0,C.O(new C.r(1/0,n,new C.a1(!0,d.a.c18(a2,g,e),n),n),n,n),n,n,v,v,0,n)
i=i?1-a1:a1
e=g.b5(e)
u=a0?360:1
t=a0?1:0.01
s=a0?10:0.1
r=d.d
d.a.toString
q=o.r
p=q.QY(g)
a0=a0?new A.eyb(q):q.gbTc()
return C.c5(C.cu(B.an,new C.r(m,w,new C.ay(B.P,n,B.X,B.u,C.a([v,C.dR(n,I.BL(!1,B.F,d.a.f,n,n,r,n,B.lP,u,0,l,n,n,n,new A.eyc(h,g),n,s,a0,p,t,e),w,n,i*j,n,0,k)],y.u),n),n),B.q,!1,n,n,new A.eyd(d),new A.eye(f),new A.eyf(d),new A.eyg(d),new A.eyh(f),n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n),x,n,n,n,n,n,!0)},
$S:176}
A.eyj.prototype={
$1(d){var x,w,v=this,u=v.a
if(u<=0)return
x=B.i.I((d-v.b.a/2)/u,0,1)
if(v.c)x=1-x
u=v.e
w=u===B.ze?360:1
A.iIZ(v.d,u,x*w)},
$S:18}
A.eye.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:191}
A.eyg.prototype={
$1(d){var x=this.a
return x.m(new A.ey8(x))},
$S:42}
A.ey8.prototype={
$0(){return this.a.d=!0},
$S:0}
A.eyh.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:33}
A.eyf.prototype={
$1(d){var x=this.a
return x.m(new A.ey9(x))},
$S:39}
A.ey9.prototype={
$0(){return this.a.d=!1},
$S:0}
A.eyd.prototype={
$0(){var x=this.a
return x.m(new A.eya(x))},
$S:0}
A.eya.prototype={
$0(){return this.a.d=!1},
$S:0}
A.eyb.prototype={
$1(d){return C.d7(B.i.ag(d),C.cG(this.a.gbt()),null,null)+"\xb0"},
$S:13}
A.eyc.prototype={
$1(d){return A.iIZ(this.a,this.b,d)},
$S:18};(function installTearOffs(){var x=a._instance_1u,w=a._instance_2u
x(A.rs.prototype,"gaXz","Mz",0)
w(A.b_W.prototype,"gbbB","bbC",1)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(C.X,[A.cS,A.hh])
w(A.rs,C.bs)
x(C.cm,[A.dAJ,A.ey7,A.ey4,A.ey5,A.ey1,A.exX,A.exZ,A.ey_,A.exY,A.eyk,A.eyj,A.eye,A.eyg,A.eyh,A.eyf,A.eyb,A.eyc])
x(C.i,[A.aRp,A.asb])
x(C.k,[A.b_W,A.c2r])
x(C.d_,[A.ey6,A.ey3,A.ey2,A.exV,A.exS,A.exT,A.exW,A.exU,A.ey8,A.ey9,A.eyd,A.eya])
x(C.dj,[A.ey0,A.eyi])})()
C.bN(b.typeUniverse,JSON.parse('{"aRp":{"i":[],"b":[]},"asb":{"i":[],"b":[]},"rs":{"bs":["cS"],"a6":[]},"b_W":{"k":["aRp"]},"c2r":{"k":["asb"]}}'))
var y={o:C.F("du"),x:C.F("o<m>"),u:C.F("o<b>"),t:C.F("dE"),q:C.F("ek<cS>"),k:C.F("T")};(function constants(){E.lY=new C.f(1,0.19607843137254902,0.3843137254901961,0.5490196078431373,B.e)
E.axe=new C.qO("precise")})()};
(a=>{a["kLKrIJwvwtiy7J9NLcpRMhyTwkc="]=a.current})($__dart_deferred_initializers__);