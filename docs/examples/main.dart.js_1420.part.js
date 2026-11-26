((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var C,B,F,A={
qV(d){var x=d.gUf()/255,w=d.gMY()/255,v=d.gRn()/255,u=Math.max(x,Math.max(w,v)),t=u-Math.min(x,Math.min(w,v)),s=d.gjR(),r=D.iLF(x,w,v,u,t),q=u===0?0:t/u
return new A.cX(s/255,r,q,u)},
cX:function cX(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
iNw(d,e,f){var x,w
switch(e.a){case 0:x=d.a
w=B.i.J(f,0,360)
d.st(new A.cX(x.a,w,x.c,x.d))
break
case 1:x=d.a
w=B.i.J(f,0,1)
d.st(new A.cX(x.a,x.b,w,x.d))
break
case 2:x=d.a
w=B.i.J(f,0,1)
d.st(new A.cX(x.a,x.b,x.c,w))
break
case 3:x=d.a
d.st(new A.cX(B.i.J(f,0,1),x.b,x.c,x.d))
break}},
iDf(d,e,f){return new A.aS6(e,d,f,null)},
j5R(d,e,f,g,h){return new A.a6Z(e,d,h,f,g,null)},
rM:function rM(d,e){var _=this
_.a=d
_.M$=0
_.O$=e
_.au$=_.av$=0},
dCJ:function dCJ(){},
hr:function hr(d,e){this.a=d
this.b=e},
aS6:function aS6(d,e,f,g){var _=this
_.c=d
_.d=e
_.e=f
_.a=g},
b88:function b88(){var _=this
_.d=!1
_.e=$
_.r=_.f=!1
_.c=_.a=null},
fqF:function fqF(d){this.a=d},
fqE:function fqE(d,e){this.a=d
this.b=e},
fqC:function fqC(d,e,f){this.a=d
this.b=e
this.c=f},
fqD:function fqD(d,e){this.a=d
this.b=e},
fqB:function fqB(d,e){this.a=d
this.b=e},
fqA:function fqA(d,e){this.a=d
this.b=e},
fqz:function fqz(d){this.a=d},
fqs:function fqs(d,e){this.a=d
this.b=e},
fqy:function fqy(d,e,f){this.a=d
this.b=e
this.c=f},
fqu:function fqu(d,e){this.a=d
this.b=e},
fqw:function fqw(d){this.a=d},
fqp:function fqp(d){this.a=d},
fqx:function fqx(d,e){this.a=d
this.b=e},
fqv:function fqv(d){this.a=d},
fqq:function fqq(d){this.a=d},
fqt:function fqt(d){this.a=d},
fqr:function fqr(d){this.a=d},
a6Z:function a6Z(d,e,f,g,h,i){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.w=h
_.a=i},
ckI:function ckI(){this.d=!1
this.c=this.a=null},
fqS:function fqS(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},
fqQ:function fqQ(d,e,f,g,h,i,j){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i
_.r=j},
fqR:function fqR(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
fqM:function fqM(d){this.a=d},
fqO:function fqO(d){this.a=d},
fqG:function fqG(d){this.a=d},
fqP:function fqP(d){this.a=d},
fqN:function fqN(d){this.a=d},
fqH:function fqH(d){this.a=d},
fqL:function fqL(d){this.a=d},
fqI:function fqI(d){this.a=d},
fqJ:function fqJ(d){this.a=d},
fqK:function fqK(d,e){this.a=d
this.b=e}},E,I,K,G,D,H
C=c[0]
B=c[2]
F=c[285]
A=a.updateHolder(c[153],A)
E=c[347]
I=c[267]
K=c[307]
G=c[269]
D=c[283]
H=c[291]
A.cX.prototype={
bY(){var x=this,w=x.d,v=x.c*w,u=x.b
return C.iKD(x.a,u,v,v*(1-Math.abs(B.i.a7(u/60,2)-1)),w-v)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
return e instanceof A.cX&&e.a===x.a&&e.b===x.b&&e.c===x.c&&e.d===x.d},
ga3(d){var x=this
return C.aN(x.a,x.b,x.c,x.d,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a)},
C(d){var x=this
return"HSVColor("+C.al(x.a)+", "+C.al(x.b)+", "+C.al(x.c)+", "+C.al(x.d)+")"}}
A.rM.prototype={
sfW(d){var x=A.qV(d),w=x.c
this.st(w===0||x.d===0?new A.cX(x.a,this.a.b,w,x.d):x)},
gnk(){var x=this.a.bY(),w=new A.dCJ(),v="#"+C.al(w.$1(x.b))+C.al(w.$1(x.c))+C.al(w.$1(x.d)),u=x.a
return u>=1?v:v+C.al(w.$1(u))},
N8(d){var x,w,v,u,t,s,r=B.r.c8(d)
if(B.r.fR(r,"#"))r=B.r.h_(r,1)
x=C.eI("^[0-9a-fA-F]+$",!0,!1)
if(!x.b.test(r))return!1
if(r.length===3){x=C.a([],y.x)
for(w=r.split(""),v=w.length,u=0;u<v;++u){t=w[u]
x.push(t+t)}r=B.d.m3(x)}if(r.length===6)r+="FF"
if(r.length!==8)return!1
s=C.pp(r,16)
this.sfW(C.dI(((s&255)<<24|B.o.nB(s,8))>>>0))
return!0}}
A.hr.prototype={}
A.aS6.prototype={
p(){return new A.b88()},
e5(d,e){return this.d.$2(d,e)},
aoR(d,e){return this.e.$2(d,e)}}
A.b88.prototype={
ar(){var x,w=this
w.aB()
x=G.ES()
w.e!==$&&C.dh()
w.e=new G.C0(new A.fqF(w),x)},
l(){var x=this.e
x===$&&C.i()
x.l()
this.L()},
atl(d,e){var x,w,v=e.a
if(v<=0||e.b<=0)return
x=this.a.c
w=x.a
v=B.i.J(d.a/v,0,1)
x.st(new A.cX(w.a,w.b,v,B.i.J(1-d.b/e.b,0,1)))},
bcG(d,e){var x,w,v,u,t,s,r=this
if(!(e instanceof C.dx)&&!(e instanceof C.fL))return B.ag
r.a.toString
x=$.eu.fq$
x===$&&C.i()
x=x.a
w=C.a_(x).k("be<2>")
v=0.01*(new C.be(x,w).m(0,B.jP)||new C.be(x,w).m(0,B.kj)?10:1)
u=r.a.c.a
t=e.b
if(t.i(0,B.bG)){x=r.a.c
w=u.c
s=x.a
w=B.i.J(w+v,0,1)
x.st(new A.cX(s.a,s.b,w,s.d))}else if(t.i(0,B.bT)){x=r.a.c
w=u.c
s=x.a
w=B.i.J(w-v,0,1)
x.st(new A.cX(s.a,s.b,w,s.d))}else if(t.i(0,B.bA)){x=r.a.c
w=u.d
s=x.a
w=B.i.J(w+v,0,1)
x.st(new A.cX(s.a,s.b,s.c,w))}else if(t.i(0,B.bk)){x=r.a.c
w=u.d
s=x.a
w=B.i.J(w-v,0,1)
x.st(new A.cX(s.a,s.b,s.c,w))}else return B.ag
return B.aG},
h(d){var x,w=C.W(d,H.L,y.t)
if(w==null)w=B.J
x=C.cU(d)
return C.h7(new D.er(this.a.c,new A.fqC(this,w,x),null,null,y.q),B.O)}}
A.a6Z.prototype={
p(){return new A.ckI()},
c2H(d,e,f){return this.e.$3(d,e,f)}}
A.ckI.prototype={
h(d){var x,w=this.a,v=w.d,u=w.c
w=C.W(d,H.L,y.t)
if(w==null)w=B.J
x=d.u(y.o).w
return new D.er(u,new A.fqS(this,this.a.w,x===B.H,u,v,w),null,null,y.q)}}
var z=a.updateTypes(["x(n)","e_(bG,dm)","a8(c,cX,b?)"])
A.dCJ.prototype={
$1(d){return B.r.dX(B.o.mN(B.i.ah(d*255),16),2,"0").toUpperCase()},
$S:15}
A.fqF.prototype={
$1(d){var x=this.a
return x.n(new A.fqE(x,d))},
$S:3}
A.fqE.prototype={
$0(){return this.a.d=this.b},
$S:0}
A.fqC.prototype={
$3(d,e,f){var x,w,v,u,t=null,s=y.k,r=C.az(s),q=this.a
if(q.d)r.H(0,B.y)
if(q.f)r.H(0,B.a3)
if(q.r)r.F(0,C.cO([B.D,B.dF],s))
s=this.b
x=new A.fqD(s,e)
q.a.toString
s=s.gajn()
w=e.d
v=x.$1(w)
u=x.$1(B.i.J(w+0.1,0,1))
w=x.$1(B.i.J(w-0.1,0,1))
q.a.toString
x=q.e
x===$&&C.i()
return C.C(t,t,t,C.d8(!1,!1,D.oR(t,!1,new F.a8(new A.fqy(q,new A.hr(e,r),e),t),!0,t,!0,E.azJ,t,x.gSM(),new A.fqz(q),t),t,t,t,t,!1,t,t,t,q.gbcF(),t,!0),!0,t,t,t,w,t,!1,t,!1,t,t,t,t,t,t,t,t,u,t,t,t,s,t,t,t,t,t,t,t,t,t,t,t,t,new A.fqA(q,e),t,t,t,t,t,new A.fqB(q,e),t,t,t,t,t,t,t,t,t,!0,t,t,this.c,t,t,t,t,B.l,v)},
$S:1054}
A.fqD.prototype={
$1(d){var x=this.a
return B.d.aM(C.a([x.RB(B.d4b)+" "+C.yt(this.b.c,C.c3(x.gba()),0),x.RB(B.d4c)+" "+C.yt(d,C.c3(x.gba()),0)],y.x),x.gwL())},
$S:15}
A.fqB.prototype={
$0(){var x=this.a.a.c,w=this.b.d+0.1,v=x.a,u=B.i.J(w,0,1)
x.st(new A.cX(v.a,v.b,v.c,u))
return w},
$S:0}
A.fqA.prototype={
$0(){var x=this.a.a.c,w=this.b.d-0.1,v=x.a,u=B.i.J(w,0,1)
x.st(new A.cX(v.a,v.b,v.c,u))
return w},
$S:0}
A.fqz.prototype={
$1(d){var x=this.a
return x.n(new A.fqs(x,d))},
$S:3}
A.fqs.prototype={
$0(){return this.a.f=this.b},
$S:0}
A.fqy.prototype={
$2(d,e){var x=null,w=e.b,v=e.d,u=new C.I(w,v),t=this.a,s=this.b,r=this.c
return C.cy(B.aq,new C.ay(B.P,x,B.X,B.u,C.a([C.d6(0,t.a.e5(d,s),0,0,0),C.e0(x,C.P(t.a.aoR(d,s),x,x),40,x,r.c*w-20,x,(1-r.d)*v-20,40)],y.u),x),B.q,!1,x,x,x,x,x,x,x,x,x,x,x,x,new A.fqt(t),new A.fqu(t,u),new A.fqv(t),new A.fqw(t),new A.fqx(t,u),x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x)},
$S:149}
A.fqu.prototype={
$1(d){return this.a.atl(d.b,this.b)},
$S:209}
A.fqw.prototype={
$1(d){var x=this.a
return x.n(new A.fqp(x))},
$S:47}
A.fqp.prototype={
$0(){return this.a.r=!0},
$S:0}
A.fqx.prototype={
$1(d){return this.a.atl(d.b,this.b)},
$S:36}
A.fqv.prototype={
$1(d){var x=this.a
return x.n(new A.fqq(x))},
$S:41}
A.fqq.prototype={
$0(){return this.a.r=!1},
$S:0}
A.fqt.prototype={
$0(){var x=this.a
return x.n(new A.fqr(x))},
$S:0}
A.fqr.prototype={
$0(){return this.a.r=!1},
$S:0}
A.fqS.prototype={
$3(d,e,f){var x=this
return new F.a8(new A.fqQ(x.a,x.b,x.c,x.d,x.e,e,x.f),null)},
$S:z+2}
A.fqQ.prototype={
$2(a2,a3){var x,w,v,u,t,s,r,q,p,o=this,n=null,m=a3.b,l=o.b,k=l.a,j=m-k,i=o.c,h=o.d,g=o.e,f=new A.fqR(j,l,i,h,g),e=o.f,d=g.b9(e),a0=g===B.zQ,a1=d/(a0?360:1)
d=o.a
x=d.d?K.lJ:B.aW
w=l.b
v=k/2
v=C.e0(0,C.P(new C.t(1/0,n,new C.a2(!0,d.a.c2H(a2,g,e),n),n),n,n),n,n,v,v,0,n)
i=i?1-a1:a1
e=g.b9(e)
u=a0?360:1
t=a0?1:0.01
s=a0?10:0.1
r=d.d
d.a.toString
q=o.r
p=q.RB(g)
a0=a0?new A.fqJ(q):q.gbUK()
return C.ca(C.cy(B.aq,new C.t(m,w,new C.ay(B.P,n,B.X,B.u,C.a([v,C.e0(n,I.Cb(!1,B.K,d.a.f,n,n,r,n,B.kA,u,0,l,n,n,n,new A.fqK(h,g),n,s,a0,p,t,e),w,n,i*j,n,0,k)],y.u),n),n),B.q,!1,n,n,new A.fqL(d),new A.fqM(f),new A.fqN(d),new A.fqO(d),new A.fqP(f),n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n),x,n,n,n,n,n,!0)},
$S:197}
A.fqR.prototype={
$1(d){var x,w,v=this,u=v.a
if(u<=0)return
x=B.i.J((d-v.b.a/2)/u,0,1)
if(v.c)x=1-x
u=v.e
w=u===B.zQ?360:1
A.iNw(v.d,u,x*w)},
$S:18}
A.fqM.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:209}
A.fqO.prototype={
$1(d){var x=this.a
return x.n(new A.fqG(x))},
$S:47}
A.fqG.prototype={
$0(){return this.a.d=!0},
$S:0}
A.fqP.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:36}
A.fqN.prototype={
$1(d){var x=this.a
return x.n(new A.fqH(x))},
$S:41}
A.fqH.prototype={
$0(){return this.a.d=!1},
$S:0}
A.fqL.prototype={
$0(){var x=this.a
return x.n(new A.fqI(x))},
$S:0}
A.fqI.prototype={
$0(){return this.a.d=!1},
$S:0}
A.fqJ.prototype={
$1(d){return C.cv(B.i.ah(d),C.c3(this.a.gba()),null,null)+"\xb0"},
$S:15}
A.fqK.prototype={
$1(d){return A.iNw(this.a,this.b,d)},
$S:18};(function installTearOffs(){var x=a._instance_1u,w=a._instance_2u
x(A.rM.prototype,"gaYA","N8",0)
w(A.b88.prototype,"gbcF","bcG",1)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(C.Y,[A.cX,A.hr])
w(A.rM,C.br)
x(C.ce,[A.dCJ,A.fqF,A.fqC,A.fqD,A.fqz,A.fqu,A.fqw,A.fqx,A.fqv,A.fqS,A.fqR,A.fqM,A.fqO,A.fqP,A.fqN,A.fqJ,A.fqK])
x(C.k,[A.aS6,A.a6Z])
x(C.m,[A.b88,A.ckI])
x(C.d2,[A.fqE,A.fqB,A.fqA,A.fqs,A.fqp,A.fqq,A.fqt,A.fqr,A.fqG,A.fqH,A.fqL,A.fqI])
x(C.di,[A.fqy,A.fqQ])})()
C.bM(b.typeUniverse,JSON.parse('{"aS6":{"k":[],"b":[]},"a6Z":{"k":[],"b":[]},"rM":{"br":["cX"],"a6":[]},"b88":{"m":["aS6"]},"ckI":{"m":["a6Z"]}}'))
var y={o:C.E("dw"),x:C.E("o<n>"),u:C.E("o<b>"),t:C.E("dC"),q:C.E("er<cX>"),k:C.E("U")};(function constants(){E.lY=new C.e(1,0.19607843137254902,0.3843137254901961,0.5490196078431373,B.c)
E.azJ=new C.ra("precise")})()};
(a=>{a["5e/xJ6sdeW/MiD2tVjy32bHkTaI="]=a.current})($__dart_deferred_initializers__);