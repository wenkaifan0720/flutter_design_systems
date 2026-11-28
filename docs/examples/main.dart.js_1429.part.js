((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var C,B,F,A={
rb(d){var x=d.gUL()/255,w=d.gNl()/255,v=d.gRQ()/255,u=Math.max(x,Math.max(w,v)),t=u-Math.min(x,Math.min(w,v)),s=d.gjX(),r=D.iUq(x,w,v,u,t),q=u===0?0:t/u
return new A.cY(s/255,r,q,u)},
cY:function cY(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
iWh(d,e,f){var x,w
switch(e.a){case 0:x=d.a
w=B.i.J(f,0,360)
d.su(new A.cY(x.a,w,x.c,x.d))
break
case 1:x=d.a
w=B.i.J(f,0,1)
d.su(new A.cY(x.a,x.b,w,x.d))
break
case 2:x=d.a
w=B.i.J(f,0,1)
d.su(new A.cY(x.a,x.b,x.c,w))
break
case 3:x=d.a
d.su(new A.cY(B.i.J(f,0,1),x.b,x.c,x.d))
break}},
iLO(d,e,f){return new A.aU3(e,d,f,null)},
jfd(d,e,f,g,h){return new A.a84(e,d,h,f,g,null)},
t5:function t5(d,e){var _=this
_.a=d
_.N$=0
_.P$=e
_.aq$=_.au$=0},
dHf:function dHf(){},
hz:function hz(d,e){this.a=d
this.b=e},
aU3:function aU3(d,e,f,g){var _=this
_.c=d
_.d=e
_.e=f
_.a=g},
bak:function bak(){var _=this
_.d=!1
_.e=$
_.r=_.f=!1
_.c=_.a=null},
fxj:function fxj(d){this.a=d},
fxi:function fxi(d,e){this.a=d
this.b=e},
fxg:function fxg(d,e,f){this.a=d
this.b=e
this.c=f},
fxh:function fxh(d,e){this.a=d
this.b=e},
fxf:function fxf(d,e){this.a=d
this.b=e},
fxe:function fxe(d,e){this.a=d
this.b=e},
fxc:function fxc(d){this.a=d},
fx5:function fx5(d){this.a=d},
fxd:function fxd(d){this.a=d},
fx4:function fx4(d){this.a=d},
fxb:function fxb(d,e,f){this.a=d
this.b=e
this.c=f},
fx7:function fx7(d,e){this.a=d
this.b=e},
fx9:function fx9(d){this.a=d},
fx1:function fx1(d){this.a=d},
fxa:function fxa(d,e){this.a=d
this.b=e},
fx8:function fx8(d){this.a=d},
fx2:function fx2(d){this.a=d},
fx6:function fx6(d){this.a=d},
fx3:function fx3(d){this.a=d},
a84:function a84(d,e,f,g,h,i){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.w=h
_.a=i},
cnf:function cnf(){this.d=!1
this.c=this.a=null},
fxw:function fxw(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},
fxu:function fxu(d,e,f,g,h,i,j){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i
_.r=j},
fxv:function fxv(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
fxq:function fxq(d){this.a=d},
fxs:function fxs(d){this.a=d},
fxk:function fxk(d){this.a=d},
fxt:function fxt(d){this.a=d},
fxr:function fxr(d){this.a=d},
fxl:function fxl(d){this.a=d},
fxp:function fxp(d){this.a=d},
fxm:function fxm(d){this.a=d},
fxn:function fxn(d){this.a=d},
fxo:function fxo(d,e){this.a=d
this.b=e}},E,I,K,G,D,H
C=c[0]
B=c[2]
F=c[285]
A=a.updateHolder(c[153],A)
E=c[347]
I=c[268]
K=c[307]
G=c[270]
D=c[283]
H=c[291]
A.cY.prototype={
bY(){var x=this,w=x.d,v=x.c*w,u=x.b
return C.iTl(x.a,u,v,v*(1-Math.abs(B.i.a8(u/60,2)-1)),w-v)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
return e instanceof A.cY&&e.a===x.a&&e.b===x.b&&e.c===x.c&&e.d===x.d},
ga2(d){var x=this
return C.aP(x.a,x.b,x.c,x.d,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a)},
D(d){var x=this
return"HSVColor("+C.am(x.a)+", "+C.am(x.b)+", "+C.am(x.c)+", "+C.am(x.d)+")"}}
A.t5.prototype={
sh1(d){var x=A.rb(d),w=x.c
this.su(w===0||x.d===0?new A.cY(x.a,this.a.b,w,x.d):x)},
gnx(){var x=this.a.bY(),w=new A.dHf(),v="#"+C.am(w.$1(x.b))+C.am(w.$1(x.c))+C.am(w.$1(x.d)),u=x.a
return u>=1?v:v+C.am(w.$1(u))},
Nw(d){var x,w,v,u,t,s,r=B.r.c6(d)
if(B.r.fV(r,"#"))r=B.r.h0(r,1)
x=C.eQ("^[0-9a-fA-F]+$",!0,!1)
if(!x.b.test(r))return!1
if(r.length===3){x=C.a([],y.x)
for(w=r.split(""),v=w.length,u=0;u<v;++u){t=w[u]
x.push(t+t)}r=B.c.mf(x)}if(r.length===6)r+="FF"
if(r.length!==8)return!1
s=C.pN(r,16)
this.sh1(C.dC(((s&255)<<24|B.o.nM(s,8))>>>0))
return!0}}
A.hz.prototype={}
A.aU3.prototype={
p(){return new A.bak()},
e7(d,e){return this.d.$2(d,e)},
apR(d,e){return this.e.$2(d,e)}}
A.bak.prototype={
ar(){var x,w=this
w.aB()
x=G.p0()
w.e!==$&&C.dd()
w.e=new G.on(new A.fxj(w),x)},
l(){var x=this.e
x===$&&C.i()
x.l()
this.L()},
auo(d,e){var x,w,v=e.a
if(v<=0||e.b<=0)return
x=this.a.c
w=x.a
v=B.i.J(d.a/v,0,1)
x.su(new A.cY(w.a,w.b,v,B.i.J(1-d.b/e.b,0,1)))},
beP(d,e){var x,w,v,u,t,s,r=this
if(!(e instanceof C.dB)&&!(e instanceof C.fT))return B.ah
r.a.toString
x=$.ez.fu$
x===$&&C.i()
x=x.a
w=C.a0(x).k("be<2>")
v=0.01*(new C.be(x,w).m(0,B.k_)||new C.be(x,w).m(0,B.kv)?10:1)
u=r.a.c.a
t=e.b
if(t.i(0,B.bP)){x=r.a.c
w=u.c
s=x.a
w=B.i.J(w+v,0,1)
x.su(new A.cY(s.a,s.b,w,s.d))}else if(t.i(0,B.bZ)){x=r.a.c
w=u.c
s=x.a
w=B.i.J(w-v,0,1)
x.su(new A.cY(s.a,s.b,w,s.d))}else if(t.i(0,B.bE)){x=r.a.c
w=u.d
s=x.a
w=B.i.J(w+v,0,1)
x.su(new A.cY(s.a,s.b,s.c,w))}else if(t.i(0,B.bl)){x=r.a.c
w=u.d
s=x.a
w=B.i.J(w-v,0,1)
x.su(new A.cY(s.a,s.b,s.c,w))}else return B.ah
return B.aI},
h(d){var x,w=C.X(d,H.L,y.t)
if(w==null)w=B.J
x=C.cM(d)
return C.h4(new D.ew(this.a.c,new A.fxg(this,w,x),null,null,y.q),B.N)}}
A.a84.prototype={
p(){return new A.cnf()},
c62(d,e,f){return this.e.$3(d,e,f)}}
A.cnf.prototype={
h(d){var x,w=this.a,v=w.d,u=w.c
w=C.X(d,H.L,y.t)
if(w==null)w=B.J
x=d.t(y.o).w
return new D.ew(u,new A.fxw(this,this.a.w,x===B.H,u,v,w),null,null,y.q)}}
var z=a.updateTypes(["x(n)","e6(bG,dt)","a5(c,cY,b?)"])
A.dHf.prototype={
$1(d){return B.r.e0(B.o.mY(B.i.ah(d*255),16),2,"0").toUpperCase()},
$S:17}
A.fxj.prototype={
$1(d){var x=this.a
return x.n(new A.fxi(x,d))},
$S:4}
A.fxi.prototype={
$0(){return this.a.d=this.b},
$S:0}
A.fxg.prototype={
$3(d,e,f){var x,w,v,u,t=null,s=y.k,r=C.aA(s),q=this.a
if(q.d)r.H(0,B.z)
if(q.f)r.H(0,B.a3)
if(q.r)r.F(0,C.cR([B.F,B.dG],s))
s=this.b
x=new A.fxh(s,e)
q.a.toString
s=s.gakj()
w=e.d
v=x.$1(w)
u=x.$1(B.i.J(w+0.1,0,1))
w=x.$1(B.i.J(w-0.1,0,1))
q.a.toString
x=q.e
x===$&&C.i()
return C.D(t,t,t,C.dc(!1,!1,D.pi(t,!1,C.ce(new F.a5(new A.fxb(q,new A.hz(e,r),e),t),B.aj,t,t,new A.fxc(q),new A.fxd(q),t,!0),!0,t,!0,E.aCx,x.gqK(),t,t,t),t,t,t,t,!1,t,t,t,q.gbeO(),t,!0),!0,t,t,t,w,t,!1,t,!1,t,t,t,t,t,t,t,t,u,t,t,t,s,t,t,t,t,t,t,t,t,t,t,t,t,new A.fxe(q,e),t,t,t,t,t,new A.fxf(q,e),t,t,t,t,t,t,t,t,t,!0,t,t,this.c,t,t,t,t,B.l,v)},
$S:1067}
A.fxh.prototype={
$1(d){var x=this.a
return B.c.aM(C.a([x.S5(B.d9J)+" "+C.z_(this.b.c,C.c9(x.gbb()),0),x.S5(B.d9K)+" "+C.z_(d,C.c9(x.gbb()),0)],y.x),x.gwV())},
$S:17}
A.fxf.prototype={
$0(){var x=this.a.a.c,w=this.b.d+0.1,v=x.a,u=B.i.J(w,0,1)
x.su(new A.cY(v.a,v.b,v.c,u))
return w},
$S:0}
A.fxe.prototype={
$0(){var x=this.a.a.c,w=this.b.d-0.1,v=x.a,u=B.i.J(w,0,1)
x.su(new A.cY(v.a,v.b,v.c,u))
return w},
$S:0}
A.fxc.prototype={
$1(d){var x=this.a
return x.n(new A.fx5(x))},
$S:19}
A.fx5.prototype={
$0(){return this.a.f=!0},
$S:0}
A.fxd.prototype={
$1(d){var x=this.a
return x.n(new A.fx4(x))},
$S:21}
A.fx4.prototype={
$0(){return this.a.f=!1},
$S:0}
A.fxb.prototype={
$2(d,e){var x=null,w=e.b,v=e.d,u=new C.I(w,v),t=this.a,s=this.b,r=this.c
return C.cF(B.aq,new C.ay(B.O,x,B.X,B.u,C.a([C.d3(0,t.a.e7(d,s),0,0,0),C.dZ(x,C.P(t.a.apR(d,s),x,x),40,x,r.c*w-20,x,(1-r.d)*v-20,40)],y.u),x),B.q,!1,x,x,x,x,x,x,x,x,x,x,x,x,new A.fx6(t),new A.fx7(t,u),new A.fx8(t),new A.fx9(t),new A.fxa(t,u),x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x)},
$S:158}
A.fx7.prototype={
$1(d){return this.a.auo(d.b,this.b)},
$S:207}
A.fx9.prototype={
$1(d){var x=this.a
return x.n(new A.fx1(x))},
$S:49}
A.fx1.prototype={
$0(){return this.a.r=!0},
$S:0}
A.fxa.prototype={
$1(d){return this.a.auo(d.b,this.b)},
$S:37}
A.fx8.prototype={
$1(d){var x=this.a
return x.n(new A.fx2(x))},
$S:42}
A.fx2.prototype={
$0(){return this.a.r=!1},
$S:0}
A.fx6.prototype={
$0(){var x=this.a
return x.n(new A.fx3(x))},
$S:0}
A.fx3.prototype={
$0(){return this.a.r=!1},
$S:0}
A.fxw.prototype={
$3(d,e,f){var x=this
return new F.a5(new A.fxu(x.a,x.b,x.c,x.d,x.e,e,x.f),null)},
$S:z+2}
A.fxu.prototype={
$2(a2,a3){var x,w,v,u,t,s,r,q,p,o=this,n=null,m=a3.b,l=o.b,k=l.a,j=m-k,i=o.c,h=o.d,g=o.e,f=new A.fxv(j,l,i,h,g),e=o.f,d=g.b9(e),a0=g===B.A8,a1=d/(a0?360:1)
d=o.a
x=d.d?K.lU:B.b0
w=l.b
v=k/2
v=C.dZ(0,C.P(new C.t(1/0,n,new C.a1(!0,d.a.c62(a2,g,e),n),n),n,n),n,n,v,v,0,n)
i=i?1-a1:a1
e=g.b9(e)
u=a0?360:1
t=a0?1:0.01
s=a0?10:0.1
r=d.d
d.a.toString
q=o.r
p=q.S5(g)
a0=a0?new A.fxn(q):q.gbXX()
return C.ce(C.cF(B.aq,new C.t(m,w,new C.ay(B.O,n,B.X,B.u,C.a([v,C.dZ(n,I.CN(!1,B.M,d.a.f,n,n,r,n,B.kI,u,0,l,n,n,n,new A.fxo(h,g),n,s,a0,p,t,e),w,n,i*j,n,0,k)],y.u),n),n),B.q,!1,n,n,new A.fxp(d),new A.fxq(f),new A.fxr(d),new A.fxs(d),new A.fxt(f),n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n),x,n,n,n,n,n,!0)},
$S:206}
A.fxv.prototype={
$1(d){var x,w,v=this,u=v.a
if(u<=0)return
x=B.i.J((d-v.b.a/2)/u,0,1)
if(v.c)x=1-x
u=v.e
w=u===B.A8?360:1
A.iWh(v.d,u,x*w)},
$S:18}
A.fxq.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:207}
A.fxs.prototype={
$1(d){var x=this.a
return x.n(new A.fxk(x))},
$S:49}
A.fxk.prototype={
$0(){return this.a.d=!0},
$S:0}
A.fxt.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:37}
A.fxr.prototype={
$1(d){var x=this.a
return x.n(new A.fxl(x))},
$S:42}
A.fxl.prototype={
$0(){return this.a.d=!1},
$S:0}
A.fxp.prototype={
$0(){var x=this.a
return x.n(new A.fxm(x))},
$S:0}
A.fxm.prototype={
$0(){return this.a.d=!1},
$S:0}
A.fxn.prototype={
$1(d){return C.cD(B.i.ah(d),C.c9(this.a.gbb()),null,null)+"\xb0"},
$S:17}
A.fxo.prototype={
$1(d){return A.iWh(this.a,this.b,d)},
$S:18};(function installTearOffs(){var x=a._instance_1u,w=a._instance_2u
x(A.t5.prototype,"gb_l","Nw",0)
w(A.bak.prototype,"gbeO","beP",1)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(C.a_,[A.cY,A.hz])
w(A.t5,C.bo)
x(C.cp,[A.dHf,A.fxj,A.fxg,A.fxh,A.fxc,A.fxd,A.fx7,A.fx9,A.fxa,A.fx8,A.fxw,A.fxv,A.fxq,A.fxs,A.fxt,A.fxr,A.fxn,A.fxo])
x(C.l,[A.aU3,A.a84])
x(C.m,[A.bak,A.cnf])
x(C.da,[A.fxi,A.fxf,A.fxe,A.fx5,A.fx4,A.fx1,A.fx2,A.fx6,A.fx3,A.fxk,A.fxl,A.fxp,A.fxm])
x(C.db,[A.fxb,A.fxu])})()
C.bP(b.typeUniverse,JSON.parse('{"aU3":{"l":[],"b":[]},"a84":{"l":[],"b":[]},"t5":{"bo":["cY"],"a7":[]},"bak":{"m":["aU3"]},"cnf":{"m":["a84"]}}'))
var y={o:C.G("dv"),x:C.G("o<n>"),u:C.G("o<b>"),t:C.G("dK"),q:C.G("ew<cY>"),k:C.G("V")};(function constants(){E.m9=new C.e(1,0.19607843137254902,0.3843137254901961,0.5490196078431373,B.d)
E.aCx=new C.rw("precise")})()};
(a=>{a["Jo9o53h8N6maqHqg4DB7eUNOLcc="]=a.current})($__dart_deferred_initializers__);