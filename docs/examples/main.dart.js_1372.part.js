((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var C,B,I,A={
qw(d){var x=d.gTm()/255,w=d.gMg()/255,v=d.gQB()/255,u=Math.max(x,Math.max(w,v)),t=u-Math.min(x,Math.min(w,v)),s=d.gjE(),r=D.iEE(x,w,v,u,t),q=u===0?0:t/u
return new A.cS(s/255,r,q,u)},
cS:function cS(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
iGw(d,e,f){var x,w
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
iwv(d,e,f){return new A.aR3(e,d,f,null)},
iYV(d,e,f,g,h){return new A.arR(e,d,h,f,g,null)},
rq:function rq(d,e){var _=this
_.a=d
_.M$=0
_.N$=e
_.ar$=_.au$=0},
dAn:function dAn(){},
he:function he(d,e){this.a=d
this.b=e},
aR3:function aR3(d,e,f,g){var _=this
_.c=d
_.d=e
_.e=f
_.a=g},
b_d:function b_d(){var _=this
_.d=!1
_.e=$
_.r=_.f=!1
_.c=_.a=null},
ewc:function ewc(d){this.a=d},
ewb:function ewb(d,e){this.a=d
this.b=e},
ew9:function ew9(d,e,f){this.a=d
this.b=e
this.c=f},
ewa:function ewa(d,e){this.a=d
this.b=e},
ew8:function ew8(d,e){this.a=d
this.b=e},
ew7:function ew7(d,e){this.a=d
this.b=e},
ew6:function ew6(d){this.a=d},
ew_:function ew_(d,e){this.a=d
this.b=e},
ew5:function ew5(d,e,f){this.a=d
this.b=e
this.c=f},
ew1:function ew1(d,e){this.a=d
this.b=e},
ew3:function ew3(d){this.a=d},
evX:function evX(d){this.a=d},
ew4:function ew4(d,e){this.a=d
this.b=e},
ew2:function ew2(d){this.a=d},
evY:function evY(d){this.a=d},
ew0:function ew0(d){this.a=d},
evZ:function evZ(d){this.a=d},
arR:function arR(d,e,f,g,h,i){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.w=h
_.a=i},
c1p:function c1p(){this.d=!1
this.c=this.a=null},
ewp:function ewp(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},
ewn:function ewn(d,e,f,g,h,i,j){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i
_.r=j},
ewo:function ewo(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
ewj:function ewj(d){this.a=d},
ewl:function ewl(d){this.a=d},
ewd:function ewd(d){this.a=d},
ewm:function ewm(d){this.a=d},
ewk:function ewk(d){this.a=d},
ewe:function ewe(d){this.a=d},
ewi:function ewi(d){this.a=d},
ewf:function ewf(d){this.a=d},
ewg:function ewg(d){this.a=d},
ewh:function ewh(d,e){this.a=d
this.b=e}},E,D,K,F,G,H
C=c[0]
B=c[2]
I=c[249]
A=a.updateHolder(c[136],A)
E=c[325]
D=c[264]
K=c[285]
F=c[251]
G=c[272]
H=c[266]
A.cS.prototype={
bP(){var x=this,w=x.d,v=x.c*w,u=x.b
return C.iDF(x.a,u,v,v*(1-Math.abs(B.i.a5(u/60,2)-1)),w-v)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
return e instanceof A.cS&&e.a===x.a&&e.b===x.b&&e.c===x.c&&e.d===x.d},
ga2(d){var x=this
return C.aL(x.a,x.b,x.c,x.d,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a)},
A(d){var x=this
return"HSVColor("+C.am(x.a)+", "+C.am(x.b)+", "+C.am(x.c)+", "+C.am(x.d)+")"}}
A.rq.prototype={
sfR(d){var x=A.qw(d),w=x.c
this.sq(w===0||x.d===0?new A.cS(x.a,this.a.b,w,x.d):x)},
gmR(){var x=this.a.bP(),w=new A.dAn(),v="#"+C.am(w.$1(x.b))+C.am(w.$1(x.c))+C.am(w.$1(x.d)),u=x.a
return u>=1?v:v+C.am(w.$1(u))},
Mr(d){var x,w,v,u,t,s,r=B.r.c5(d)
if(B.r.fM(r,"#"))r=B.r.fY(r,1)
x=C.eD("^[0-9a-fA-F]+$",!0,!1)
if(!x.b.test(r))return!1
if(r.length===3){x=C.a([],y.x)
for(w=r.split(""),v=w.length,u=0;u<v;++u){t=w[u]
x.push(t+t)}r=B.c.lE(x)}if(r.length===6)r+="FF"
if(r.length!==8)return!1
s=C.p_(r,16)
this.sfR(C.eC(((s&255)<<24|B.o.n5(s,8))>>>0))
return!0}}
A.he.prototype={}
A.aR3.prototype={
n(){return new A.b_d()},
e0(d,e){return this.d.$2(d,e)},
ano(d,e){return this.e.$2(d,e)}}
A.b_d.prototype={
aq(){var x,w=this
w.aA()
x=F.LP()
w.e!==$&&C.db()
w.e=new F.AB(new A.ewc(w),x)},
k(){var x=this.e
x===$&&C.l()
x.k()
this.K()},
as_(d,e){var x,w,v=e.a
if(v<=0||e.b<=0)return
x=this.a.c
w=x.a
v=B.i.I(d.a/v,0,1)
x.sq(new A.cS(w.a,w.b,v,B.i.I(1-d.b/e.b,0,1)))},
bbd(d,e){var x,w,v,u,t,s,r=this
if(!(e instanceof C.dr)&&!(e instanceof C.fG))return B.ad
r.a.toString
x=$.ep.fn$
x===$&&C.l()
x=x.a
w=C.Y(x).j("bd<2>")
v=0.01*(new C.bd(x,w).l(0,B.jN)||new C.bd(x,w).l(0,B.kd)?10:1)
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
x.sq(new A.cS(s.a,s.b,w,s.d))}else if(t.i(0,B.bD)){x=r.a.c
w=u.d
s=x.a
w=B.i.I(w+v,0,1)
x.sq(new A.cS(s.a,s.b,s.c,w))}else if(t.i(0,B.bn)){x=r.a.c
w=u.d
s=x.a
w=B.i.I(w-v,0,1)
x.sq(new A.cS(s.a,s.b,s.c,w))}else return B.ad
return B.aH},
h(d){var x,w=C.X(d,G.M,y.t)
if(w==null)w=B.L
x=C.d5(d)
return C.hb(new D.es(this.a.c,new A.ew9(this,w,x),null,null,y.q),B.O)}}
A.arR.prototype={
n(){return new A.c1p()},
c0e(d,e,f){return this.e.$3(d,e,f)}}
A.c1p.prototype={
h(d){var x,w=this.a,v=w.d,u=w.c
w=C.X(d,G.M,y.t)
if(w==null)w=B.L
x=d.t(y.o).w
return new D.es(u,new A.ewp(this,this.a.w,x===B.I,u,v,w),null,null,y.q)}}
var z=a.updateTypes(["w(m)","dU(bE,di)","a9(c,cS,b?)"])
A.dAn.prototype={
$1(d){return B.r.cV(B.o.mx(B.i.ag(d*255),16),2,"0").toUpperCase()},
$S:12}
A.ewc.prototype={
$1(d){var x=this.a
return x.m(new A.ewb(x,d))},
$S:3}
A.ewb.prototype={
$0(){return this.a.d=this.b},
$S:0}
A.ew9.prototype={
$3(d,e,f){var x,w,v,u,t=null,s=y.k,r=C.az(s),q=this.a
if(q.d)r.G(0,B.x)
if(q.f)r.G(0,B.a_)
if(q.r)r.E(0,C.cJ([B.D,B.dx],s))
s=this.b
x=new A.ewa(s,e)
q.a.toString
s=s.gahR()
w=e.d
v=x.$1(w)
u=x.$1(B.i.I(w+0.1,0,1))
w=x.$1(B.i.I(w-0.1,0,1))
q.a.toString
x=q.e
x===$&&C.l()
return C.B(t,t,t,C.d6(!1,!1,D.oy(t,!1,new H.a9(new A.ew5(q,new A.he(e,r),e),t),!0,t,!0,E.axd,t,x.gRU(),new A.ew6(q),t),t,t,t,t,!1,t,t,t,q.gbbc(),t,!0),!0,t,t,t,w,t,!1,t,!1,t,t,t,t,t,t,t,t,u,t,t,s,t,t,t,t,t,t,t,t,t,t,t,t,new A.ew7(q,e),t,t,t,t,t,new A.ew8(q,e),t,t,t,t,t,t,t,t,t,!0,t,t,this.c,t,t,t,t,B.l,v)},
$S:1040}
A.ewa.prototype={
$1(d){var x=this.a
return B.c.aM(C.a([x.QM(B.cWt)+" "+C.A3(this.b.c,C.cM(x.gby()),0),x.QM(B.cWu)+" "+C.A3(d,C.cM(x.gby()),0)],y.x),x.gwj())},
$S:12}
A.ew8.prototype={
$0(){var x=this.a.a.c,w=this.b.d+0.1,v=x.a,u=B.i.I(w,0,1)
x.sq(new A.cS(v.a,v.b,v.c,u))
return w},
$S:0}
A.ew7.prototype={
$0(){var x=this.a.a.c,w=this.b.d-0.1,v=x.a,u=B.i.I(w,0,1)
x.sq(new A.cS(v.a,v.b,v.c,u))
return w},
$S:0}
A.ew6.prototype={
$1(d){var x=this.a
return x.m(new A.ew_(x,d))},
$S:3}
A.ew_.prototype={
$0(){return this.a.f=this.b},
$S:0}
A.ew5.prototype={
$2(d,e){var x=null,w=e.b,v=e.d,u=new C.H(w,v),t=this.a,s=this.b,r=this.c
return C.ct(B.an,new C.ay(B.P,x,B.X,B.u,C.a([C.cZ(0,t.a.e0(d,s),0,0,0),C.dV(x,C.O(t.a.ano(d,s),x,x),44,x,r.c*w-22,x,(1-r.d)*v-22,44)],y.u),x),B.q,!1,x,x,x,x,x,x,x,x,x,x,x,x,new A.ew0(t),new A.ew1(t,u),new A.ew2(t),new A.ew3(t),new A.ew4(t,u),x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x)},
$S:148}
A.ew1.prototype={
$1(d){return this.a.as_(d.b,this.b)},
$S:195}
A.ew3.prototype={
$1(d){var x=this.a
return x.m(new A.evX(x))},
$S:45}
A.evX.prototype={
$0(){return this.a.r=!0},
$S:0}
A.ew4.prototype={
$1(d){return this.a.as_(d.b,this.b)},
$S:33}
A.ew2.prototype={
$1(d){var x=this.a
return x.m(new A.evY(x))},
$S:40}
A.evY.prototype={
$0(){return this.a.r=!1},
$S:0}
A.ew0.prototype={
$0(){var x=this.a
return x.m(new A.evZ(x))},
$S:0}
A.evZ.prototype={
$0(){return this.a.r=!1},
$S:0}
A.ewp.prototype={
$3(d,e,f){var x=this
return new H.a9(new A.ewn(x.a,x.b,x.c,x.d,x.e,e,x.f),null)},
$S:z+2}
A.ewn.prototype={
$2(a2,a3){var x,w,v,u,t,s,r,q,p,o=this,n=null,m=a3.b,l=o.b,k=l.a,j=m-k,i=o.c,h=o.d,g=o.e,f=new A.ewo(j,l,i,h,g),e=o.f,d=g.b7(e),a0=g===B.zc,a1=d/(a0?360:1)
d=o.a
x=d.d?K.lH:B.aW
w=l.b
v=k/2
v=C.dV(0,C.O(new C.r(1/0,n,new C.a0(!0,d.a.c0e(a2,g,e),n),n),n,n),n,n,v,v,0,n)
i=i?1-a1:a1
e=g.b7(e)
u=a0?360:1
t=a0?1:0.01
s=a0?10:0.1
r=d.d
d.a.toString
q=o.r
p=q.QM(g)
a0=a0?new A.ewg(q):q.gbSm()
return C.c4(C.ct(B.an,new C.r(m,w,new C.ay(B.P,n,B.X,B.u,C.a([v,C.dV(n,I.AF(!1,B.F,d.a.f,n,n,r,n,B.ks,u,0,l,n,n,n,new A.ewh(h,g),n,s,a0,p,t,e),w,n,i*j,n,0,k)],y.u),n),n),B.q,!1,n,n,new A.ewi(d),new A.ewj(f),new A.ewk(d),new A.ewl(d),new A.ewm(f),n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n),x,n,n,n,n,n,!0)},
$S:180}
A.ewo.prototype={
$1(d){var x,w,v=this,u=v.a
if(u<=0)return
x=B.i.I((d-v.b.a/2)/u,0,1)
if(v.c)x=1-x
u=v.e
w=u===B.zc?360:1
A.iGw(v.d,u,x*w)},
$S:18}
A.ewj.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:195}
A.ewl.prototype={
$1(d){var x=this.a
return x.m(new A.ewd(x))},
$S:45}
A.ewd.prototype={
$0(){return this.a.d=!0},
$S:0}
A.ewm.prototype={
$1(d){return this.a.$1(d.b.a)},
$S:33}
A.ewk.prototype={
$1(d){var x=this.a
return x.m(new A.ewe(x))},
$S:40}
A.ewe.prototype={
$0(){return this.a.d=!1},
$S:0}
A.ewi.prototype={
$0(){var x=this.a
return x.m(new A.ewf(x))},
$S:0}
A.ewf.prototype={
$0(){return this.a.d=!1},
$S:0}
A.ewg.prototype={
$1(d){return C.dg(B.i.ag(d),C.cM(this.a.gby()),null,null)+"\xb0"},
$S:12}
A.ewh.prototype={
$1(d){return A.iGw(this.a,this.b,d)},
$S:18};(function installTearOffs(){var x=a._instance_1u,w=a._instance_2u
x(A.rq.prototype,"gaXc","Mr",0)
w(A.b_d.prototype,"gbbc","bbd",1)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(C.W,[A.cS,A.he])
w(A.rq,C.bs)
x(C.cj,[A.dAn,A.ewc,A.ew9,A.ewa,A.ew6,A.ew1,A.ew3,A.ew4,A.ew2,A.ewp,A.ewo,A.ewj,A.ewl,A.ewm,A.ewk,A.ewg,A.ewh])
x(C.i,[A.aR3,A.arR])
x(C.k,[A.b_d,A.c1p])
x(C.cU,[A.ewb,A.ew8,A.ew7,A.ew_,A.evX,A.evY,A.ew0,A.evZ,A.ewd,A.ewe,A.ewi,A.ewf])
x(C.de,[A.ew5,A.ewn])})()
C.bM(b.typeUniverse,JSON.parse('{"aR3":{"i":[],"b":[]},"arR":{"i":[],"b":[]},"rq":{"bs":["cS"],"a7":[]},"b_d":{"k":["aR3"]},"c1p":{"k":["arR"]}}'))
var y={o:C.E("dt"),x:C.E("o<m>"),u:C.E("o<b>"),t:C.E("dN"),q:C.E("es<cS>"),k:C.E("S")};(function constants(){E.lX=new C.f(1,0.19607843137254902,0.3843137254901961,0.5490196078431373,B.e)
E.axd=new C.qJ("precise")})()};
(a=>{a["u6JjpkZIJ/SOvkXF7N9pUeF+png="]=a.current})($__dart_deferred_initializers__);