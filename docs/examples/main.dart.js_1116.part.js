((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var C,B,A={
r6(d){var x=d.gVx()/255,w=d.gMj()/255,v=d.gSk()/255,u=Math.max(x,Math.max(w,v)),t=u-Math.min(x,Math.min(w,v)),s=d.gkd(),r=D.hk6(x,w,v,u,t),q=u===0?0:t/u
return new A.cN(s/255,r,q,u)},
cN:function cN(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
hlH(d,e,f){var x,w
switch(e.a){case 0:x=d.a
w=B.h.I(f,0,360)
d.st(new A.cN(x.a,w,x.c,x.d))
break
case 1:x=d.a
w=B.h.I(f,0,1)
d.st(new A.cN(x.a,x.b,w,x.d))
break
case 2:x=d.a
w=B.h.I(f,0,1)
d.st(new A.cN(x.a,x.b,x.c,w))
break
case 3:x=d.a
d.st(new A.cN(B.h.I(f,0,1),x.b,x.c,x.d))
break}},
hCf(d,e,f,g){return new A.aC4(e,d,g,f,null)},
Bg(d,e,f,g,h,i,j,k){return new A.bk0(g,d,f,k,j,!1,e,h,null)},
rq:function rq(d,e){var _=this
_.a=d
_.P$=0
_.T$=e
_.aG$=_.b_$=0},
cY2:function cY2(){},
hf:function hf(d,e){this.a=d
this.b=e},
aC3:function aC3(d,e,f,g){var _=this
_.c=d
_.d=e
_.e=f
_.a=g},
aJH:function aJH(){var _=this
_.d=!1
_.e=$
_.r=_.f=!1
_.c=_.a=null},
dK7:function dK7(d){this.a=d},
dK6:function dK6(d,e){this.a=d
this.b=e},
dK4:function dK4(d,e,f){this.a=d
this.b=e
this.c=f},
dK5:function dK5(d,e){this.a=d
this.b=e},
dK3:function dK3(d,e){this.a=d
this.b=e},
dK2:function dK2(d,e){this.a=d
this.b=e},
dK1:function dK1(d){this.a=d},
dJV:function dJV(d,e){this.a=d
this.b=e},
dK0:function dK0(d,e,f){this.a=d
this.b=e
this.c=f},
dJX:function dJX(d,e){this.a=d
this.b=e},
dJZ:function dJZ(d){this.a=d},
dJS:function dJS(d){this.a=d},
dK_:function dK_(d,e){this.a=d
this.b=e},
dJY:function dJY(d){this.a=d},
dJT:function dJT(d){this.a=d},
dJW:function dJW(d){this.a=d},
dJU:function dJU(d){this.a=d},
aC4:function aC4(d,e,f,g,h){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.a=h},
bCS:function bCS(){this.d=!1
this.c=this.a=null},
dKk:function dKk(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},
dKi:function dKi(d,e,f,g,h,i,j){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i
_.r=j},
dKj:function dKj(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
dKe:function dKe(d){this.a=d},
dKg:function dKg(d){this.a=d},
dK8:function dK8(d){this.a=d},
dKh:function dKh(d){this.a=d},
dKf:function dKf(d){this.a=d},
dK9:function dK9(d){this.a=d},
dKd:function dKd(d){this.a=d},
dKa:function dKa(d){this.a=d},
dKb:function dKb(d){this.a=d},
dKc:function dKc(d,e){this.a=d
this.b=e},
bk0:function bk0(d,e,f,g,h,i,j,k,l){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.r=h
_.w=i
_.x=j
_.y=k
_.a=l}},E,H,I,D,F,G
C=c[0]
B=c[2]
A=a.updateHolder(c[109],A)
E=c[261]
H=c[207]
I=c[227]
D=c[209]
F=c[219]
G=c[210]
A.cN.prototype={
bN(){var x=this,w=x.d,v=x.c*w,u=x.b
return C.hjh(x.a,u,v,v*(1-Math.abs(B.h.a4(u/60,2)-1)),w-v)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
return e instanceof A.cN&&e.a===x.a&&e.b===x.b&&e.c===x.c&&e.d===x.d},
gU(d){var x=this
return C.aF(x.a,x.b,x.c,x.d,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a)},
v(d){var x=this
return"HSVColor("+C.a7(x.a)+", "+C.a7(x.b)+", "+C.a7(x.c)+", "+C.a7(x.d)+")"}}
A.rq.prototype={
shm(d){var x=A.r6(d),w=x.c
this.st(w===0||x.d===0?new A.cN(x.a,this.a.b,w,x.d):x)},
gkI(){var x=this.a.bN(),w=new A.cY2(),v="#"+C.a7(w.$1(x.b))+C.a7(w.$1(x.c))+C.a7(w.$1(x.d)),u=x.a
return u>=1?v:v+C.a7(w.$1(u))},
Gm(d){var x,w,v,u,t,s,r=B.p.bQ(d)
if(B.p.e8(r,"#"))r=B.p.ei(r,1)
x=C.et("^[0-9a-fA-F]+$",!0,!1)
if(!x.b.test(r))return!1
if(r.length===3){x=C.a([],y.x)
for(w=r.split(""),v=w.length,u=0;u<v;++u){t=w[u]
x.push(t+t)}r=B.c.k6(x)}if(r.length===6)r+="FF"
if(r.length!==8)return!1
s=C.nV(r,16)
this.shm(C.el(((s&255)<<24|B.n.kx(s,8))>>>0))
return!0}}
A.hf.prototype={}
A.aC3.prototype={
n(){return new A.aJH()},
dE(d,e){return this.d.$2(d,e)},
aba(d,e){return this.e.$2(d,e)}}
A.aJH.prototype={
aH(){var x=this
x.aX()
D.So()
x.e!==$&&C.d1()
x.e=new D.xT(new A.dK7(x))},
k(){var x=this.e
x===$&&C.p()
$.zE().ad(0,x.gvc())
this.M()},
afb(d,e){var x,w,v=e.a
if(v<=0||e.b<=0)return
x=this.a.c
w=x.a
v=B.h.I(d.a/v,0,1)
x.st(new A.cN(w.a,w.b,v,B.h.I(1-d.b/e.b,0,1)))},
aRy(d,e){var x,w,v,u,t,s,r=this
if(!(e instanceof C.cY)&&!(e instanceof C.fe))return B.a6
r.a.toString
x=$.e0.bI$
x===$&&C.p()
x=x.a
w=C.V(x).j("b_<2>")
v=0.01*(new C.b_(x,w).l(0,B.ig)||new C.b_(x,w).l(0,B.iM)?10:1)
u=r.a.c.a
t=e.b
if(t.i(0,B.bu)){x=r.a.c
w=u.c
s=x.a
w=B.h.I(w+v,0,1)
x.st(new A.cN(s.a,s.b,w,s.d))}else if(t.i(0,B.bJ)){x=r.a.c
w=u.c
s=x.a
w=B.h.I(w-v,0,1)
x.st(new A.cN(s.a,s.b,w,s.d))}else if(t.i(0,B.bk)){x=r.a.c
w=u.d
s=x.a
w=B.h.I(w+v,0,1)
x.st(new A.cN(s.a,s.b,s.c,w))}else if(t.i(0,B.b5)){x=r.a.c
w=u.d
s=x.a
w=B.h.I(w-v,0,1)
x.st(new A.cN(s.a,s.b,s.c,w))}else return B.a6
return B.ax},
h(d){var x,w=C.a1(d,F.L,y.t)
if(w==null)w=B.J
x=C.cX(d)
return C.fv(new D.er(this.a.c,new A.dK4(this,w,x),null,null,y.q),B.H)}}
A.aC4.prototype={
n(){return new A.bCS()},
bwn(d,e,f){return this.e.$3(d,e,f)}}
A.bCS.prototype={
h(d){var x,w=this.a,v=w.d,u=w.c
w=C.a1(d,F.L,y.t)
if(w==null)w=B.J
x=d.q(y.o).w
this.a.toString
return new D.er(u,new A.dKk(this,F.kk,x===B.C,u,v,w),null,null,y.q)}}
A.bk0.prototype={
h(d){var x,w=this,v=null,u=w.c
u=C.a([new C.t(v,w.x,new A.aC3(u,w.d,w.e,v),v),A.hCf(B.zW,u,w.r,w.f)],y.u)
x=w.y
x=x==null?v:x.$2(d,u)
return x==null?C.h(u,B.k,v,B.b,B.e,0):x}}
var z=a.updateTypes(["w(l)","ds(bs,cT)","a8(c,cN,b?)"])
A.cY2.prototype={
$1(d){return B.p.cr(B.n.kt(B.h.aj(d*255),16),2,"0").toUpperCase()},
$S:14}
A.dK7.prototype={
$1(d){var x=this.a
return x.m(new A.dK6(x,d))},
$S:4}
A.dK6.prototype={
$0(){return this.a.d=this.b},
$S:0}
A.dK4.prototype={
$3(d,e,f){var x,w,v,u,t=null,s=y.k,r=C.aG(s),q=this.a
if(q.d)r.G(0,B.y)
if(q.f)r.G(0,B.a8)
if(q.r)r.E(0,C.cy([B.D,B.eV],s))
s=this.b
x=new A.dK5(s,e)
q.a.toString
s=s.ga6e()
w=e.d
v=x.$1(w)
u=x.$1(B.h.I(w+0.1,0,1))
w=x.$1(B.h.I(w-0.1,0,1))
q.a.toString
x=q.e
x===$&&C.p()
return C.D(t,t,C.cV(!1,!1,D.r3(t,!1,new G.a8(new A.dK0(q,new A.hf(e,r),e),t),!0,t,!0,E.anY,t,x.gKI(),new A.dK1(q),t),t,t,t,t,!1,t,t,t,q.gaRx(),t,!0),!0,t,t,t,w,t,!1,t,!1,t,t,t,t,t,t,t,u,t,t,s,t,t,t,t,t,t,t,t,t,t,t,new A.dK2(q,e),t,t,t,t,new A.dK3(q,e),t,t,t,t,t,t,t,t,t,!0,t,t,this.c,t,t,t,t,B.l,v)},
$S:992}
A.dK5.prototype={
$1(d){var x=this.a
return B.c.aC(C.a([x.JT(B.cAQ)+" "+C.aZy(this.b.c,C.dA(x.gbU()),0),x.JT(B.cAR)+" "+C.aZy(d,C.dA(x.gbU()),0)],y.x),x.gyv())},
$S:14}
A.dK3.prototype={
$0(){var x=this.a.a.c,w=this.b.d+0.1,v=x.a,u=B.h.I(w,0,1)
x.st(new A.cN(v.a,v.b,v.c,u))
return w},
$S:0}
A.dK2.prototype={
$0(){var x=this.a.a.c,w=this.b.d-0.1,v=x.a,u=B.h.I(w,0,1)
x.st(new A.cN(v.a,v.b,v.c,u))
return w},
$S:0}
A.dK1.prototype={
$1(d){var x=this.a
return x.m(new A.dJV(x,d))},
$S:4}
A.dJV.prototype={
$0(){return this.a.f=this.b},
$S:0}
A.dK0.prototype={
$2(d,e){var x=null,w=e.b,v=e.d,u=new C.H(w,v),t=this.a,s=this.b,r=this.c
return C.cu(B.ar,new C.aE(B.O,x,B.Y,B.w,C.a([C.cZ(0,t.a.dE(d,s),0,0,0),C.ek(x,C.R(t.a.aba(d,s),x,x),44,x,r.c*w-22,x,(1-r.d)*v-22,44)],y.u),x),B.ad,!1,x,x,x,x,x,x,x,x,x,x,x,x,new A.dJW(t),new A.dJX(t,u),new A.dJY(t),new A.dJZ(t),new A.dK_(t,u),x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x)},
$S:128}
A.dJX.prototype={
$1(d){return this.a.afb(d.b,this.b)},
$S:174}
A.dJZ.prototype={
$1(d){var x=this.a
return x.m(new A.dJS(x))},
$S:44}
A.dJS.prototype={
$0(){return this.a.r=!0},
$S:0}
A.dK_.prototype={
$1(d){return this.a.afb(d.b,this.b)},
$S:32}
A.dJY.prototype={
$1(d){var x=this.a
return x.m(new A.dJT(x))},
$S:35}
A.dJT.prototype={
$0(){return this.a.r=!1},
$S:0}
A.dJW.prototype={
$0(){var x=this.a
return x.m(new A.dJU(x))},
$S:0}
A.dJU.prototype={
$0(){return this.a.r=!1},
$S:0}
A.dKk.prototype={
$3(d,e,f){var x=this
return new G.a8(new A.dKi(x.a,x.b,x.c,x.d,x.e,e,x.f),null)},
$S:z+2}
A.dKi.prototype={
$2(a2,a3){var x,w,v,u,t,s,r,q,p,o=this,n=null,m=a3.b,l=o.b,k=l.a,j=m-k,i=o.c,h=o.d,g=o.e,f=new A.dKj(j,l,i,h,g),e=o.f,d=g.aK(e),a0=g===B.zW,a1=d/(a0?360:1)
d=o.a
x=d.d?I.n3:B.aV
w=l.b
v=k/2
v=C.ek(0,C.R(new C.t(1/0,n,new C.Y(!0,d.a.bwn(a2,g,e),n),n),n,n),n,n,v,v,0,n)
i=i?1-a1:a1
e=g.aK(e)
u=a0?360:1
t=a0?1:0.01
s=a0?10:0.1
r=d.d
d.a.toString
q=o.r
p=q.JT(g)
a0=a0?new A.dKb(q):q.gboU()
return C.ch(C.cu(B.ar,new C.t(m,w,new C.aE(B.O,n,B.Y,B.w,C.a([v,C.ek(n,H.DN(!1,B.A,d.a.f,n,n,r,n,B.m9,u,0,l,n,n,n,new A.dKc(h,g),n,s,a0,p,t,e),w,n,i*j,n,0,k)],y.u),n),n),B.ad,!1,n,n,new A.dKd(d),new A.dKe(f),new A.dKf(d),new A.dKg(d),new A.dKh(f),n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n),x,n,n,n,n,n,!0)},
$S:172}
A.dKj.prototype={
$1(d){var x,w,v=this,u=v.a
if(u<=0)return
x=B.h.I((d-v.b.a/2)/u,0,1)
if(v.c)x=1-x
u=v.e
w=u===B.zW?360:1
A.hlH(v.d,u,x*w)},
$S:20}
A.dKe.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:174}
A.dKg.prototype={
$1(d){var x=this.a
return x.m(new A.dK8(x))},
$S:44}
A.dK8.prototype={
$0(){return this.a.d=!0},
$S:0}
A.dKh.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:32}
A.dKf.prototype={
$1(d){var x=this.a
return x.m(new A.dK9(x))},
$S:35}
A.dK9.prototype={
$0(){return this.a.d=!1},
$S:0}
A.dKd.prototype={
$0(){var x=this.a
return x.m(new A.dKa(x))},
$S:0}
A.dKa.prototype={
$0(){return this.a.d=!1},
$S:0}
A.dKb.prototype={
$1(d){return C.e9(B.h.aj(d),C.dA(this.a.gbU()),null,null)+"\xb0"},
$S:14}
A.dKc.prototype={
$1(d){return A.hlH(this.a,this.b,d)},
$S:20};(function installTearOffs(){var x=a._instance_1u,w=a._instance_2u
x(A.rq.prototype,"gaFG","Gm",0)
w(A.aJH.prototype,"gaRx","aRy",1)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(C.T,[A.cN,A.hf])
w(A.rq,C.bB)
x(C.cq,[A.cY2,A.dK7,A.dK4,A.dK5,A.dK1,A.dJX,A.dJZ,A.dK_,A.dJY,A.dKk,A.dKj,A.dKe,A.dKg,A.dKh,A.dKf,A.dKb,A.dKc])
x(C.j,[A.aC3,A.aC4])
x(C.k,[A.aJH,A.bCS])
x(C.db,[A.dK6,A.dK3,A.dK2,A.dJV,A.dJS,A.dJT,A.dJW,A.dJU,A.dK8,A.dK9,A.dKd,A.dKa])
x(C.df,[A.dK0,A.dKi])
w(A.bk0,C.i)})()
C.c_(b.typeUniverse,JSON.parse('{"aC3":{"j":[],"b":[]},"aC4":{"j":[],"b":[]},"rq":{"bB":["cN"],"a5":[]},"aJH":{"k":["aC3"]},"bCS":{"k":["aC4"]},"bk0":{"i":[],"b":[]}}'))
var y={o:C.G("di"),x:C.G("m<l>"),u:C.G("m<b>"),t:C.G("dF"),q:C.G("er<cN>"),k:C.G("P")};(function constants(){E.mm=new C.e(1,0.19607843137254902,0.3843137254901961,0.5490196078431373,B.d)
E.anY=new C.oX("precise")})()};
(a=>{a["j2c6qkfH/+C91QgAqSAvc+m+Dbk="]=a.current})($__dart_deferred_initializers__);