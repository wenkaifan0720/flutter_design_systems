((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var C,B,A={
qV(d){var x=d.gRV()/255,w=d.gLc()/255,v=d.gPd()/255,u=Math.max(x,Math.max(w,v)),t=u-Math.min(x,Math.min(w,v)),s=d.gji(),r=D.hPF(x,w,v,u,t),q=u===0?0:t/u
return new A.cI(s/255,r,q,u)},
cI:function cI(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
hRa(d,e,f){var x,w
switch(e.a){case 0:x=d.a
w=B.i.I(f,0,360)
d.sq(new A.cI(x.a,w,x.c,x.d))
break
case 1:x=d.a
w=B.i.I(f,0,1)
d.sq(new A.cI(x.a,x.b,w,x.d))
break
case 2:x=d.a
w=B.i.I(f,0,1)
d.sq(new A.cI(x.a,x.b,x.c,w))
break
case 3:x=d.a
d.sq(new A.cI(B.i.I(f,0,1),x.b,x.c,x.d))
break}},
ijT(d){return""+B.i.ac(d*100)+"%"},
i1Z(d,e,f,g){return new A.aAq(e,d,g,f,null)},
yR(d,e,f,g,h,i,j,k){return new A.bgr(g,d,f,k,j,!1,e,h,null)},
qK:function qK(d,e){var _=this
_.a=d
_.N$=0
_.O$=e
_.aq$=_.ar$=0},
cDF:function cDF(){},
hd:function hd(d,e){this.a=d
this.b=e},
aAp:function aAp(d,e,f,g){var _=this
_.c=d
_.d=e
_.e=f
_.a=g},
aRC:function aRC(){var _=this
_.d=!1
_.e=$
_.r=_.f=!1
_.c=_.a=null},
e5v:function e5v(d){this.a=d},
e5u:function e5u(d,e){this.a=d
this.b=e},
e5s:function e5s(d){this.a=d},
e5t:function e5t(d){this.a=d},
e5r:function e5r(d,e){this.a=d
this.b=e},
e5q:function e5q(d,e){this.a=d
this.b=e},
e5p:function e5p(d){this.a=d},
e5i:function e5i(d,e){this.a=d
this.b=e},
e5o:function e5o(d,e,f){this.a=d
this.b=e
this.c=f},
e5k:function e5k(d,e){this.a=d
this.b=e},
e5m:function e5m(d){this.a=d},
e5f:function e5f(d){this.a=d},
e5n:function e5n(d,e){this.a=d
this.b=e},
e5l:function e5l(d){this.a=d},
e5g:function e5g(d){this.a=d},
e5j:function e5j(d){this.a=d},
e5h:function e5h(d){this.a=d},
aAq:function aAq(d,e,f,g,h){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.a=h},
bOr:function bOr(){this.d=!1
this.c=this.a=null},
e5I:function e5I(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
e5G:function e5G(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},
e5H:function e5H(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
e5C:function e5C(d){this.a=d},
e5E:function e5E(d){this.a=d},
e5w:function e5w(d){this.a=d},
e5F:function e5F(d){this.a=d},
e5D:function e5D(d){this.a=d},
e5x:function e5x(d){this.a=d},
e5B:function e5B(d){this.a=d},
e5y:function e5y(d){this.a=d},
e5z:function e5z(){},
e5A:function e5A(d,e){this.a=d
this.b=e},
bgr:function bgr(d,e,f,g,h,i,j,k,l){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.r=h
_.w=i
_.x=j
_.y=k
_.a=l}},F,I,D,E,G,K,H
C=c[0]
B=c[2]
A=a.updateHolder(c[130],A)
F=c[579]
I=c[257]
D=c[238]
E=c[226]
G=c[260]
K=c[423]
H=c[240]
A.cI.prototype={
bJ(){var x=this,w=x.d,v=x.c*w,u=x.b
return C.hOO(x.a,u,v,v*(1-Math.abs(B.i.a1(u/60,2)-1)),w-v)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
return e instanceof A.cI&&e.a===x.a&&e.b===x.b&&e.c===x.c&&e.d===x.d},
gY(d){var x=this
return C.aA(x.a,x.b,x.c,x.d,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a)},
v(d){var x=this
return"HSVColor("+C.ae(x.a)+", "+C.ae(x.b)+", "+C.ae(x.c)+", "+C.ae(x.d)+")"}}
A.qK.prototype={
sfJ(d){var x=A.qV(d),w=x.c
this.sq(w===0||x.d===0?new A.cI(x.a,this.a.b,w,x.d):x)},
gmJ(){var x=this.a.bJ(),w=new A.cDF(),v="#"+C.ae(w.$1(x.b))+C.ae(w.$1(x.c))+C.ae(w.$1(x.d)),u=x.a
return u>=1?v:v+C.ae(w.$1(u))},
Ln(d){var x,w,v,u,t,s,r=B.q.c8(d)
if(B.q.fG(r,"#"))r=B.q.fT(r,1)
x=C.ey("^[0-9a-fA-F]+$",!0,!1)
if(!x.b.test(r))return!1
if(r.length===3){x=C.a([],y.x)
for(w=r.split(""),v=w.length,u=0;u<v;++u){t=w[u]
x.push(t+t)}r=B.c.ml(x)}if(r.length===6)r+="FF"
if(r.length!==8)return!1
s=C.nO(r,16)
this.sfJ(C.eg(((s&255)<<24|B.n.mv(s,8))>>>0))
return!0}}
A.hd.prototype={}
A.aAp.prototype={
n(){return new A.aRC()},
fI(d,e){return this.d.$2(d,e)},
akR(d,e){return this.e.$2(d,e)}}
A.aRC.prototype={
ao(){var x=this
x.aw()
E.VB()
x.e!==$&&C.cN()
x.e=new E.yS(new A.e5v(x))},
k(){var x=this.e
x===$&&C.h()
$.AY().ad(0,x.gy4())
this.K()},
apa(d,e){var x,w,v=e.a
if(v<=0||e.b<=0)return
x=this.a.c
w=x.a
v=B.i.I(d.a/v,0,1)
x.sq(new A.cI(w.a,w.b,v,B.i.I(1-d.b/e.b,0,1)))},
b6C(d,e){var x,w,v,u,t,s,r=this
if(!(e instanceof C.df)&&!(e instanceof C.fj))return B.aa
r.a.toString
x=$.er.fO$
x===$&&C.h()
x=x.a
w=C.U(x).j("b6<2>")
v=0.01*(new C.b6(x,w).l(0,B.jk)||new C.b6(x,w).l(0,B.jY)?10:1)
u=r.a.c.a
t=e.b
if(t.i(0,B.bp)){x=r.a.c
w=u.c
s=x.a
w=B.i.I(w+v,0,1)
x.sq(new A.cI(s.a,s.b,w,s.d))}else if(t.i(0,B.by)){x=r.a.c
w=u.c
s=x.a
w=B.i.I(w-v,0,1)
x.sq(new A.cI(s.a,s.b,w,s.d))}else if(t.i(0,B.bm)){x=r.a.c
w=u.d
s=x.a
w=B.i.I(w+v,0,1)
x.sq(new A.cI(s.a,s.b,s.c,w))}else if(t.i(0,B.b9)){x=r.a.c
w=u.d
s=x.a
w=B.i.I(w-v,0,1)
x.sq(new A.cI(s.a,s.b,s.c,w))}else return B.aa
return B.ax},
h(d){return C.fp(new D.e0(this.a.c,new A.e5s(this),null,null,y.q),B.K)}}
A.aAq.prototype={
n(){return new A.bOr()},
bUS(d,e,f){return this.e.$3(d,e,f)}}
A.bOr.prototype={
h(d){var x=this.a,w=x.d,v=x.c
x=d.t(y.o).w
this.a.toString
return new D.e0(v,new A.e5I(this,K.k3,x===B.E,v,w),null,null,y.q)}}
A.bgr.prototype={
h(d){var x,w=this,v=null,u=w.c
u=C.a([new C.t(v,w.x,new A.aAp(u,w.d,w.e,v),v),A.i1Z(B.zR,u,w.r,w.f)],y.u)
x=w.y
x=x==null?v:x.$2(d,u)
return x==null?C.l(u,B.o,v,B.b,B.f,0,B.d):x}}
var z=a.updateTypes(["v(p)","dS(bA,dk)","fw(c,cI,b?)","p(o)"])
A.cDF.prototype={
$1(d){return B.q.cs(B.n.lQ(B.i.ac(d*255),16),2,"0").toUpperCase()},
$S:12}
A.e5v.prototype={
$1(d){var x=this.a
return x.m(new A.e5u(x,d))},
$S:3}
A.e5u.prototype={
$0(){return this.a.d=this.b},
$S:0}
A.e5s.prototype={
$3(d,e,f){var x,w,v,u,t,s=null,r=C.av(y.k),q=this.a
if(q.d)r.F(0,B.x)
if(q.f)r.F(0,B.a4)
if(q.r)r.F(0,B.D)
x=new A.e5t(e)
q.a.toString
w=C.X(d,G.N,y.w)
w=(w==null?B.M:w).gafH()
v=e.d
u=x.$1(v)
t=x.$1(B.i.I(v+0.1,0,1))
v=x.$1(B.i.I(v-0.1,0,1))
q.a.toString
x=q.e
x===$&&C.h()
return C.D(s,s,s,C.cW(!1,!1,D.nv(s,!1,H.aE(new A.e5o(q,new A.hd(e,r),e)),!0,s,!0,F.asT,s,x.gQs(),new A.e5p(q),s),s,s,s,s,!1,s,s,s,q.gb6B(),s,!0),!0,s,s,s,v,s,!1,s,!1,s,s,s,s,s,s,s,s,t,s,s,w,s,s,s,s,s,s,s,s,s,s,s,s,new A.e5q(q,e),s,s,s,s,s,new A.e5r(q,e),s,s,s,s,s,s,s,s,s,!0,s,s,s,s,s,s,s,B.l,u)},
$S:991}
A.e5t.prototype={
$1(d){return"saturation "+(""+B.i.ac(this.a.c*100)+"%")+", brightness "+(""+B.i.ac(d*100)+"%")},
$S:12}
A.e5r.prototype={
$0(){var x=this.a.a.c,w=this.b.d+0.1,v=x.a,u=B.i.I(w,0,1)
x.sq(new A.cI(v.a,v.b,v.c,u))
return w},
$S:0}
A.e5q.prototype={
$0(){var x=this.a.a.c,w=this.b.d-0.1,v=x.a,u=B.i.I(w,0,1)
x.sq(new A.cI(v.a,v.b,v.c,u))
return w},
$S:0}
A.e5p.prototype={
$1(d){var x=this.a
return x.m(new A.e5i(x,d))},
$S:3}
A.e5i.prototype={
$0(){return this.a.f=this.b},
$S:0}
A.e5o.prototype={
$2(d,e){var x=null,w=e.b,v=e.d,u=new C.H(w,v),t=this.a,s=this.b,r=this.c
return C.cC(B.aB,new C.az(B.Q,x,B.a_,B.v,C.a([C.db(0,t.a.fI(d,s),0,0,0),C.ei(x,C.R(t.a.akR(d,s),x,x),44,x,r.c*w-22,x,(1-r.d)*v-22,44)],y.u),x),B.r,!1,x,x,x,x,x,x,x,x,x,x,x,x,new A.e5j(t),new A.e5k(t,u),new A.e5l(t),new A.e5m(t),new A.e5n(t,u),x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x)},
$S:119}
A.e5k.prototype={
$1(d){return this.a.apa(d.b,this.b)},
$S:209}
A.e5m.prototype={
$1(d){var x=this.a
return x.m(new A.e5f(x))},
$S:42}
A.e5f.prototype={
$0(){return this.a.r=!0},
$S:0}
A.e5n.prototype={
$1(d){return this.a.apa(d.b,this.b)},
$S:31}
A.e5l.prototype={
$1(d){var x=this.a
return x.m(new A.e5g(x))},
$S:35}
A.e5g.prototype={
$0(){return this.a.r=!1},
$S:0}
A.e5j.prototype={
$0(){var x=this.a
return x.m(new A.e5h(x))},
$S:0}
A.e5h.prototype={
$0(){return this.a.r=!1},
$S:0}
A.e5I.prototype={
$3(d,e,f){var x=this
return H.aE(new A.e5G(x.a,x.b,x.c,x.d,x.e,e))},
$S:z+2}
A.e5G.prototype={
$2(a1,a2){var x,w,v,u,t,s,r,q,p=this,o=null,n=a2.b,m=p.b,l=m.a,k=n-l,j=p.c,i=p.d,h=p.e,g=new A.e5H(k,m,j,i,h),f=p.f,e=h.b9(f),d=h===B.zR,a0=e/(d?360:1)
e=p.a
x=e.d?I.mp:B.aR
w=m.b
v=l/2
v=C.ei(0,C.R(new C.t(1/0,o,new C.a4(!0,e.a.bUS(a1,h,f),o),o),o,o),o,o,v,v,0,o)
j=j?1-a0:a0
f=h.b9(f)
u=d?360:1
t=d?1:0.01
s=d?10:0.1
r=e.d
e.a.toString
q=C.X(a1,G.N,y.w)
q=(q==null?B.M:q).afI(h)
d=d?new A.e5z():A.im9()
return C.cl(C.cC(B.aB,new C.t(n,w,new C.az(B.Q,o,B.a_,B.v,C.a([v,C.ei(o,E.BH(!1,B.C,e.a.f,o,r,o,B.k7,u,0,m,o,o,o,new A.e5A(i,h),o,s,d,q,t,f),w,o,j*k,o,0,l)],y.u),o),o),B.r,!1,o,o,new A.e5B(e),new A.e5C(g),new A.e5D(e),new A.e5E(e),new A.e5F(g),o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o),x,o,o,o,o,o,!0)},
$S:170}
A.e5H.prototype={
$1(d){var x,w,v=this,u=v.a
if(u<=0)return
x=B.i.I((d-v.b.a/2)/u,0,1)
if(v.c)x=1-x
u=v.e
w=u===B.zR?360:1
A.hRa(v.d,u,x*w)},
$S:17}
A.e5C.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:209}
A.e5E.prototype={
$1(d){var x=this.a
return x.m(new A.e5w(x))},
$S:42}
A.e5w.prototype={
$0(){return this.a.d=!0},
$S:0}
A.e5F.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:31}
A.e5D.prototype={
$1(d){var x=this.a
return x.m(new A.e5x(x))},
$S:35}
A.e5x.prototype={
$0(){return this.a.d=!1},
$S:0}
A.e5B.prototype={
$0(){var x=this.a
return x.m(new A.e5y(x))},
$S:0}
A.e5y.prototype={
$0(){return this.a.d=!1},
$S:0}
A.e5z.prototype={
$1(d){return""+B.i.ac(d)+" degrees"},
$S:12}
A.e5A.prototype={
$1(d){return A.hRa(this.a,this.b,d)},
$S:17};(function installTearOffs(){var x=a._static_1,w=a._instance_1u,v=a._instance_2u
x(A,"im9","ijT",3)
w(A.qK.prototype,"gaTp","Ln",0)
v(A.aRC.prototype,"gb6B","b6C",1)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(C.Q,[A.cI,A.hd])
w(A.qK,C.bx)
x(C.ck,[A.cDF,A.e5v,A.e5s,A.e5t,A.e5p,A.e5k,A.e5m,A.e5n,A.e5l,A.e5I,A.e5H,A.e5C,A.e5E,A.e5F,A.e5D,A.e5z,A.e5A])
x(C.j,[A.aAp,A.aAq])
x(C.i,[A.aRC,A.bOr])
x(C.cS,[A.e5u,A.e5r,A.e5q,A.e5i,A.e5f,A.e5g,A.e5j,A.e5h,A.e5w,A.e5x,A.e5B,A.e5y])
x(C.d_,[A.e5o,A.e5G])
w(A.bgr,C.k)})()
C.bE(b.typeUniverse,JSON.parse('{"aAp":{"j":[],"b":[]},"aAq":{"j":[],"b":[]},"qK":{"bx":["cI"],"a1":[]},"aRC":{"i":["aAp"]},"bOr":{"i":["aAq"]},"bgr":{"k":[],"b":[]}}'))
var y={w:C.C("dZ"),o:C.C("dp"),x:C.C("m<p>"),u:C.C("m<b>"),q:C.C("e0<cI>"),k:C.C("S")};(function constants(){F.asT=new C.pA("precise")})()};
(a=>{a["Bar853To6ZDVKbe1VqrKwZc89zg="]=a.current})($__dart_deferred_initializers__);