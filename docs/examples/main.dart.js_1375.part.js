((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var C,B,I,A={
qC(d){var x=d.gTx()/255,w=d.gMn()/255,v=d.gQL()/255,u=Math.max(x,Math.max(w,v)),t=u-Math.min(x,Math.min(w,v)),s=d.gjJ(),r=D.iFS(x,w,v,u,t),q=u===0?0:t/u
return new A.cS(s/255,r,q,u)},
cS:function cS(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
iHH(d,e,f){var x,w
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
ixG(d,e,f){return new A.aRr(e,d,f,null)},
j_j(d,e,f,g,h){return new A.as8(e,d,h,f,g,null)},
ru:function ru(d,e){var _=this
_.a=d
_.L$=0
_.N$=e
_.aq$=_.au$=0},
dAZ:function dAZ(){},
he:function he(d,e){this.a=d
this.b=e},
aRr:function aRr(d,e,f,g){var _=this
_.c=d
_.d=e
_.e=f
_.a=g},
b_L:function b_L(){var _=this
_.d=!1
_.e=$
_.r=_.f=!1
_.c=_.a=null},
exd:function exd(d){this.a=d},
exc:function exc(d,e){this.a=d
this.b=e},
exa:function exa(d,e,f){this.a=d
this.b=e
this.c=f},
exb:function exb(d,e){this.a=d
this.b=e},
ex9:function ex9(d,e){this.a=d
this.b=e},
ex8:function ex8(d,e){this.a=d
this.b=e},
ex7:function ex7(d){this.a=d},
ex0:function ex0(d,e){this.a=d
this.b=e},
ex6:function ex6(d,e,f){this.a=d
this.b=e
this.c=f},
ex2:function ex2(d,e){this.a=d
this.b=e},
ex4:function ex4(d){this.a=d},
ewY:function ewY(d){this.a=d},
ex5:function ex5(d,e){this.a=d
this.b=e},
ex3:function ex3(d){this.a=d},
ewZ:function ewZ(d){this.a=d},
ex1:function ex1(d){this.a=d},
ex_:function ex_(d){this.a=d},
as8:function as8(d,e,f,g,h,i){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.w=h
_.a=i},
c26:function c26(){this.d=!1
this.c=this.a=null},
exq:function exq(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},
exo:function exo(d,e,f,g,h,i,j){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i
_.r=j},
exp:function exp(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
exk:function exk(d){this.a=d},
exm:function exm(d){this.a=d},
exe:function exe(d){this.a=d},
exn:function exn(d){this.a=d},
exl:function exl(d){this.a=d},
exf:function exf(d){this.a=d},
exj:function exj(d){this.a=d},
exg:function exg(d){this.a=d},
exh:function exh(d){this.a=d},
exi:function exi(d,e){this.a=d
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
return C.iEQ(x.a,u,v,v*(1-Math.abs(B.i.a5(u/60,2)-1)),w-v)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
return e instanceof A.cS&&e.a===x.a&&e.b===x.b&&e.c===x.c&&e.d===x.d},
ga2(d){var x=this
return C.aO(x.a,x.b,x.c,x.d,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a)},
A(d){var x=this
return"HSVColor("+C.am(x.a)+", "+C.am(x.b)+", "+C.am(x.c)+", "+C.am(x.d)+")"}}
A.ru.prototype={
sfS(d){var x=A.qC(d),w=x.c
this.sq(w===0||x.d===0?new A.cS(x.a,this.a.b,w,x.d):x)},
gmX(){var x=this.a.bJ(),w=new A.dAZ(),v="#"+C.am(w.$1(x.b))+C.am(w.$1(x.c))+C.am(w.$1(x.d)),u=x.a
return u>=1?v:v+C.am(w.$1(u))},
Mx(d){var x,w,v,u,t,s,r=B.r.c2(d)
if(B.r.fM(r,"#"))r=B.r.fY(r,1)
x=C.eE("^[0-9a-fA-F]+$",!0,!1)
if(!x.b.test(r))return!1
if(r.length===3){x=C.a([],y.x)
for(w=r.split(""),v=w.length,u=0;u<v;++u){t=w[u]
x.push(t+t)}r=B.c.lO(x)}if(r.length===6)r+="FF"
if(r.length!==8)return!1
s=C.p7(r,16)
this.sfS(C.eo(((s&255)<<24|B.o.nc(s,8))>>>0))
return!0}}
A.he.prototype={}
A.aRr.prototype={
n(){return new A.b_L()},
e_(d,e){return this.d.$2(d,e)},
anD(d,e){return this.e.$2(d,e)}}
A.b_L.prototype={
ar(){var x,w=this
w.az()
x=F.Dp()
w.e!==$&&C.da()
w.e=new F.AB(new A.exd(w),x)},
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
bbs(d,e){var x,w,v,u,t,s,r=this
if(!(e instanceof C.dp)&&!(e instanceof C.fF))return B.ad
r.a.toString
x=$.ep.fl$
x===$&&C.l()
x=x.a
w=C.Y(x).j("bd<2>")
v=0.01*(new C.bd(x,w).l(0,B.jN)||new C.bd(x,w).l(0,B.kh)?10:1)
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
h(d){var x,w=C.X(d,G.M,y.t)
if(w==null)w=B.L
x=C.cW(d)
return C.hc(new D.ek(this.a.c,new A.exa(this,w,x),null,null,y.q),B.O)}}
A.as8.prototype={
n(){return new A.c26()},
c0V(d,e,f){return this.e.$3(d,e,f)}}
A.c26.prototype={
h(d){var x,w=this.a,v=w.d,u=w.c
w=C.X(d,G.M,y.t)
if(w==null)w=B.L
x=d.t(y.o).w
return new D.ek(u,new A.exq(this,this.a.w,x===B.I,u,v,w),null,null,y.q)}}
var z=a.updateTypes(["w(m)","dW(bF,dh)","a9(c,cS,b?)"])
A.dAZ.prototype={
$1(d){return B.r.cX(B.o.mH(B.i.ag(d*255),16),2,"0").toUpperCase()},
$S:12}
A.exd.prototype={
$1(d){var x=this.a
return x.m(new A.exc(x,d))},
$S:3}
A.exc.prototype={
$0(){return this.a.d=this.b},
$S:0}
A.exa.prototype={
$3(d,e,f){var x,w,v,u,t=null,s=y.k,r=C.az(s),q=this.a
if(q.d)r.G(0,B.x)
if(q.f)r.G(0,B.Z)
if(q.r)r.E(0,C.cJ([B.D,B.dx],s))
s=this.b
x=new A.exb(s,e)
q.a.toString
s=s.gai5()
w=e.d
v=x.$1(w)
u=x.$1(B.i.I(w+0.1,0,1))
w=x.$1(B.i.I(w-0.1,0,1))
q.a.toString
x=q.e
x===$&&C.l()
return C.B(t,t,t,C.d3(!1,!1,D.oE(t,!1,new H.a9(new A.ex6(q,new A.he(e,r),e),t),!0,t,!0,E.axe,t,x.gS6(),new A.ex7(q),t),t,t,t,t,!1,t,t,t,q.gbbr(),t,!0),!0,t,t,t,w,t,!1,t,!1,t,t,t,t,t,t,t,t,u,t,t,t,s,t,t,t,t,t,t,t,t,t,t,t,t,new A.ex8(q,e),t,t,t,t,t,new A.ex9(q,e),t,t,t,t,t,t,t,t,t,!0,t,t,this.c,t,t,t,t,B.l,v)},
$S:1042}
A.exb.prototype={
$1(d){var x=this.a
return B.c.aL(C.a([x.QW(B.cWy)+" "+C.A4(this.b.c,C.cN(x.gby()),0),x.QW(B.cWz)+" "+C.A4(d,C.cN(x.gby()),0)],y.x),x.gwo())},
$S:12}
A.ex9.prototype={
$0(){var x=this.a.a.c,w=this.b.d+0.1,v=x.a,u=B.i.I(w,0,1)
x.sq(new A.cS(v.a,v.b,v.c,u))
return w},
$S:0}
A.ex8.prototype={
$0(){var x=this.a.a.c,w=this.b.d-0.1,v=x.a,u=B.i.I(w,0,1)
x.sq(new A.cS(v.a,v.b,v.c,u))
return w},
$S:0}
A.ex7.prototype={
$1(d){var x=this.a
return x.m(new A.ex0(x,d))},
$S:3}
A.ex0.prototype={
$0(){return this.a.f=this.b},
$S:0}
A.ex6.prototype={
$2(d,e){var x=null,w=e.b,v=e.d,u=new C.H(w,v),t=this.a,s=this.b,r=this.c
return C.cu(B.an,new C.ay(B.P,x,B.X,B.u,C.a([C.d1(0,t.a.e_(d,s),0,0,0),C.dR(x,C.O(t.a.anD(d,s),x,x),44,x,r.c*w-22,x,(1-r.d)*v-22,44)],y.u),x),B.q,!1,x,x,x,x,x,x,x,x,x,x,x,x,new A.ex1(t),new A.ex2(t,u),new A.ex3(t),new A.ex4(t),new A.ex5(t,u),x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x)},
$S:150}
A.ex2.prototype={
$1(d){return this.a.asg(d.b,this.b)},
$S:199}
A.ex4.prototype={
$1(d){var x=this.a
return x.m(new A.ewY(x))},
$S:42}
A.ewY.prototype={
$0(){return this.a.r=!0},
$S:0}
A.ex5.prototype={
$1(d){return this.a.asg(d.b,this.b)},
$S:33}
A.ex3.prototype={
$1(d){var x=this.a
return x.m(new A.ewZ(x))},
$S:40}
A.ewZ.prototype={
$0(){return this.a.r=!1},
$S:0}
A.ex1.prototype={
$0(){var x=this.a
return x.m(new A.ex_(x))},
$S:0}
A.ex_.prototype={
$0(){return this.a.r=!1},
$S:0}
A.exq.prototype={
$3(d,e,f){var x=this
return new H.a9(new A.exo(x.a,x.b,x.c,x.d,x.e,e,x.f),null)},
$S:z+2}
A.exo.prototype={
$2(a2,a3){var x,w,v,u,t,s,r,q,p,o=this,n=null,m=a3.b,l=o.b,k=l.a,j=m-k,i=o.c,h=o.d,g=o.e,f=new A.exp(j,l,i,h,g),e=o.f,d=g.b5(e),a0=g===B.zd,a1=d/(a0?360:1)
d=o.a
x=d.d?K.lI:B.aW
w=l.b
v=k/2
v=C.dR(0,C.O(new C.r(1/0,n,new C.a1(!0,d.a.c0V(a2,g,e),n),n),n,n),n,n,v,v,0,n)
i=i?1-a1:a1
e=g.b5(e)
u=a0?360:1
t=a0?1:0.01
s=a0?10:0.1
r=d.d
d.a.toString
q=o.r
p=q.QW(g)
a0=a0?new A.exh(q):q.gbT_()
return C.c5(C.cu(B.an,new C.r(m,w,new C.ay(B.P,n,B.X,B.u,C.a([v,C.dR(n,I.AF(!1,B.F,d.a.f,n,n,r,n,B.lO,u,0,l,n,n,n,new A.exi(h,g),n,s,a0,p,t,e),w,n,i*j,n,0,k)],y.u),n),n),B.q,!1,n,n,new A.exj(d),new A.exk(f),new A.exl(d),new A.exm(d),new A.exn(f),n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n),x,n,n,n,n,n,!0)},
$S:174}
A.exp.prototype={
$1(d){var x,w,v=this,u=v.a
if(u<=0)return
x=B.i.I((d-v.b.a/2)/u,0,1)
if(v.c)x=1-x
u=v.e
w=u===B.zd?360:1
A.iHH(v.d,u,x*w)},
$S:18}
A.exk.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:199}
A.exm.prototype={
$1(d){var x=this.a
return x.m(new A.exe(x))},
$S:42}
A.exe.prototype={
$0(){return this.a.d=!0},
$S:0}
A.exn.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:33}
A.exl.prototype={
$1(d){var x=this.a
return x.m(new A.exf(x))},
$S:40}
A.exf.prototype={
$0(){return this.a.d=!1},
$S:0}
A.exj.prototype={
$0(){var x=this.a
return x.m(new A.exg(x))},
$S:0}
A.exg.prototype={
$0(){return this.a.d=!1},
$S:0}
A.exh.prototype={
$1(d){return C.dk(B.i.ag(d),C.cN(this.a.gby()),null,null)+"\xb0"},
$S:12}
A.exi.prototype={
$1(d){return A.iHH(this.a,this.b,d)},
$S:18};(function installTearOffs(){var x=a._instance_1u,w=a._instance_2u
x(A.ru.prototype,"gaXs","Mx",0)
w(A.b_L.prototype,"gbbr","bbs",1)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(C.W,[A.cS,A.he])
w(A.ru,C.bs)
x(C.cl,[A.dAZ,A.exd,A.exa,A.exb,A.ex7,A.ex2,A.ex4,A.ex5,A.ex3,A.exq,A.exp,A.exk,A.exm,A.exn,A.exl,A.exh,A.exi])
x(C.i,[A.aRr,A.as8])
x(C.k,[A.b_L,A.c26])
x(C.d_,[A.exc,A.ex9,A.ex8,A.ex0,A.ewY,A.ewZ,A.ex1,A.ex_,A.exe,A.exf,A.exj,A.exg])
x(C.dg,[A.ex6,A.exo])})()
C.bM(b.typeUniverse,JSON.parse('{"aRr":{"i":[],"b":[]},"as8":{"i":[],"b":[]},"ru":{"bs":["cS"],"a6":[]},"b_L":{"k":["aRr"]},"c26":{"k":["as8"]}}'))
var y={o:C.F("dt"),x:C.F("o<m>"),u:C.F("o<b>"),t:C.F("dE"),q:C.F("ek<cS>"),k:C.F("T")};(function constants(){E.lY=new C.f(1,0.19607843137254902,0.3843137254901961,0.5490196078431373,B.e)
E.axe=new C.qN("precise")})()};
(a=>{a["QuWXBy2YjcwyAEffMTzGIx7D9s8="]=a.current})($__dart_deferred_initializers__);