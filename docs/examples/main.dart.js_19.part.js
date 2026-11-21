((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,C,B,A={
h2L(d,e,f){var x,w,v,u,t,s,r=e.b
if(r<=0||e.a<=0||f.b<=0||f.a<=0)return E.b7C
switch(d.a){case 0:x=f
w=e
break
case 1:v=f.a
u=f.b
t=e.a
x=v/u>t/r?new C.H(t*u/r,u):new C.H(v,r*v/t)
w=e
break
case 2:v=f.a
u=f.b
t=e.a
w=v/u>t/r?new C.H(t,t*u/v):new C.H(r*v/u,r)
x=f
break
case 3:v=f.a
u=f.b
t=e.a
if(v/u>t/r){w=new C.H(t,t*u/v)
x=f}else{x=new C.H(v,r*v/t)
w=e}break
case 4:v=f.a
u=f.b
t=e.a
if(v/u>t/r){x=new C.H(t*u/r,u)
w=e}else{w=new C.H(r*v/u,r)
x=f}break
case 5:w=new C.H(Math.min(e.a,f.a),Math.min(r,f.b))
x=w
break
case 6:s=e.a/r
v=f.b
x=r>v?new C.H(v*s,v):e
r=f.a
if(x.a>r)x=new C.H(r,r/s)
w=e
break
default:w=null
x=null}return new A.b8p(w,x)},
a9N:function a9N(d,e){this.a=d
this.b=e},
b8p:function b8p(d,e){this.a=d
this.b=e},
hdT(d,e,f,g){return new A.d6X(!0,!0,g,d,C.bz([null,0],y.g,y.e))},
d6X:function d6X(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.f=g
_.r=h},
Af(d){d.q(y.h)
return E.avp},
hkD(){switch(C.bu().a){case 0:case 1:C.bcx()
break
case 2:C.axU()
break
case 3:case 4:case 5:break}},
b6m:function b6m(){},
DN(d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x){return new A.atN(x,r,f,m,l,w,t,h,g,e,k,q,p,i,v,u,j,!1,o,n,s,null)},
atN:function atN(d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,a0){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.r=h
_.w=i
_.x=j
_.y=k
_.z=l
_.Q=m
_.as=n
_.at=o
_.ax=p
_.ay=q
_.ch=r
_.CW=s
_.cx=t
_.cy=u
_.db=v
_.dx=w
_.dy=x
_.a=a0},
aJV:function aJV(){var _=this
_.d=null
_.f=_.e=!1
_.r=$
_.c=_.a=null},
dOo:function dOo(d){this.a=d},
dOg:function dOg(){},
dOh:function dOh(d){this.a=d},
dOm:function dOm(d){this.a=d},
dOn:function dOn(d,e){this.a=d
this.b=e},
dOi:function dOi(d,e){this.a=d
this.b=e},
dOj:function dOj(d,e){this.a=d
this.b=e},
dOk:function dOk(d){this.a=d},
dOl:function dOl(d){this.a=d},
axT(){var x=0,w=C.ai(y.v)
var $async$axT=C.aj(function(d,e){if(d===1)return C.af(e,w)
for(;;)switch(x){case 0:x=2
return C.a4(B.hc.hb("HapticFeedback.vibrate","HapticFeedbackType.lightImpact",y.v),$async$axT)
case 2:return C.ag(null,w)}})
return C.ah($async$axT,w)},
lY(d,e,f,g,h){var x,w=null,v=A.hdT(d,!0,!0,!0),u=d.length
if(g==null){x=e==null
x=x?F.jH:w}else x=g
return new D.azh(w,v,f,B.u,!1,e,w,x,w,h,w,0,w,w,u,F.Ac,B.ad,w,w,B.m,B.ar,w)}},E,D,F,G
J=c[1]
C=c[0]
B=c[2]
A=a.updateHolder(c[207],A)
E=c[227]
D=c[209]
F=c[219]
G=c[210]
A.a9N.prototype={
V(){return"BoxFit."+this.b}}
A.b8p.prototype={}
A.d6X.prototype={
aWh(d){var x,w,v,u,t=null,s=this.r
if(!s.bC(d)){x=s.p(0,t)
x.toString
for(w=this.f,v=J.cc(w),u=x;u<v.ga3(w);){x=v.p(w,u).a
if(x!=null)s.K(0,x,u)
if(J.z(x,d)){s.K(0,t,u+1)
return u}++u}s.K(0,t,u)}else return s.p(0,d)
return t},
az5(d){return this.aWh(d instanceof D.a8h?d.a:d)},
xE(d,e){var x,w,v,u,t=null
if(e<0||e>=J.f1(this.f))return t
x=J.lo(this.f,e)
w=x.a
v=w!=null?new D.a8h(w):t
x=new C.fy(x,t)
if(this.c){u=D.hkq(x,e)
if(u!=null)x=new D.Vv(u,x,t)}return new G.dU(new D.a9H(new D.ao0(x,t),t),v)},
gmR(){return J.f1(this.f)},
z_(d){return this.f!==d.f}}
A.b6m.prototype={
i(d,e){if(e==null)return!1
return e instanceof A.b6m},
gU(d){return C.aF(D.hSV(),A.hSW(),A.hSU(),B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a)}}
A.atN.prototype={
n(){return new A.aJV()},
dE(d,e){return this.e.$2(d,e)}}
A.aJV.prototype={
gtN(){this.a.toString
var x=this.d
if(x==null){x=C.vf()
this.d=x}return x},
aH(){var x=this
x.aX()
D.So()
x.r!==$&&C.d1()
x.r=new D.xT(new A.dOo(x))
x.gtN().af(x.gav_())
x.av0(null)},
k(){var x=this,w=x.r
w===$&&C.p()
$.zE().ad(0,w.gvc())
x.gtN().W(x.gav_())
w=x.d
if(w!=null){w.T$=$.X()
w.P$=0}x.M()},
bhI(){if(this.c!=null)this.m(new A.dOg())},
a1R(d,e){if(J.m6(this.gtN().a,d)!==e)this.gtN().fM(d,e)},
av0(d){var x,w=this,v=new A.dOh(w.gtN().a),u=w.a.d==null,t=!u,s=d==null
if(s||d.d!=null!==t){v.$2(B.U,u)
v.$2(B.a8,t&&w.e)
v.$2(B.y,t&&w.f)}x=t&&w.a.ay
if(s)u=x
else u=(d.d!=null&&d.ay)!==x
if(u){v.$2(B.D,x)
v.$2(B.eV,x)}},
gE6(){var x,w,v=this.a,u=v.w
if(u!=null)return u
x=v.y
w=x!=null&&x>0
v=v.r-v.f
return w?v/x:v/100},
gao5(){var x=this.a,w=x.x
if(w==null)w=(x.r-x.f)/10
return w<this.gE6()?this.gE6():w},
al(d){var x,w,v,u,t=this
t.an(d)
t.a.toString
x=C.bh(t.gtN().a,y.k)
t.av0(d)
if(!C.nX(x,t.gtN().a))$.au.ok$.push(new A.dOm(t))
w=t.a
v=w.y
if(!w.ay||v==null||w.r-w.f===0)return
u=new A.dOn(t,v)
if(!J.z(u.$1(w.c),u.$1(d.c))){w=t.c
w.toString
A.Af(w)
D.nu()}},
a0Z(d){var x,w,v,u,t,s=this.a,r=B.h.I(d,s.f,s.r)
s=this.a
x=s.y
if(x!=null&&x>0&&s.r-s.f>0){w=s.r
v=s.f
u=(w-v)/x
t=v+B.h.aj((r-v)/u)*u}else t=r
s=s.z
s=s==null?null:s.$1(t)
if(s==null)s=t
w=this.a
return J.D5(s,w.f,w.r)},
a54(d){var x=this.a,w=x.d
if(w==null||d===x.c)return
w.$1(d)
this.a.toString},
a2C(d){var x,w,v=this.a.CW
v=v==null?null:v.$1(d)
if(v==null){v=this.c
v.toString
v=C.a1(v,F.L,y.t)
if(v==null)v=B.J
x=this.a
w=x.r
x=x.f
w-=x
x=w===0?0:(d-x)/w
v=C.aZy(x,C.dA(v.gbU()),0)}return v},
bhK(d,e){var x,w,v,u,t,s,r,q,p=this
if(!(e instanceof C.cY)&&!(e instanceof C.fe))return B.a6
if(p.a.d==null)return B.a6
x=e.b
w=p.c.q(y.o).w===B.C
v=p.a
u=v.Q===B.A
if(u){t=w?B.bJ:B.bu
s=w?B.bu:B.bJ}else if(v.as===B.m9){t=B.bk
s=B.b5}else{t=B.b5
s=B.bk}r=v.c
if(!x.i(0,t))v=u&&x.i(0,B.bk)
else v=!0
if(v)q=r+p.gE6()
else{if(!x.i(0,s))v=u&&x.i(0,B.b5)
else v=!0
if(v)q=r-p.gE6()
else if(x.i(0,B.fU))q=r+p.gao5()
else if(x.i(0,B.hv))q=r-p.gao5()
else if(x.i(0,B.cc))q=p.a.f
else{v=x.i(0,B.ch)
u=p.a
if(v)q=u.r
else{v=u.dy
v=v==null?null:v.$2(d,e)
return v==null?B.a6:v}}}p.a54(p.a0Z(q))
return B.ax},
h(d){var x,w,v,u,t,s,r,q,p,o=this,n=null,m=o.a,l=m.d==null,k=!l,j=m.c,i=o.a0Z(j+o.gE6()),h=o.a0Z(j-o.gE6()),g=G.eW(o.gtN().a,y.k)
m=o.a
x=m.db
if(x==null)if(l)x=B.cR
else{l=m.ay?E.n3:E.jx
x=l}m=m.ch
l=o.a2C(j)
w=i>j
v=w?o.a2C(i):n
u=h<j
t=u?o.a2C(h):n
w=k&&w?new A.dOi(o,i):n
u=k&&u?new A.dOj(o,h):n
s=o.a
r=s.cx
q=o.r
q===$&&C.p()
p=s.dx
return C.D(n,n,C.cV(!1,!1,D.r3(n,!1,C.ch(new C.q(new C.A(p.a,1/0,p.b,1/0),C.R(s.dE(d,g),1,1),n),B.ae,n,n,new A.dOk(o),new A.dOl(o),n,!0),k,r,!0,x,n,q.gKI(),n,n),n,n,n,n,!1,n,n,n,o.gbhJ(),n,!0),!0,n,n,n,t,k,!1,n,!1,n,n,n,n,n,n,n,v,n,n,m,n,n,n,n,n,n,n,n,n,n,n,u,n,n,n,n,w,n,n,n,n,n,n,n,n,n,!0,n,n,n,n,n,n,n,B.l,l)}}
var z=a.updateTypes(["~()","ds(bs,cT)","b5<~>()"])
A.dOo.prototype={
$1(d){var x=this.a,w=x.f=d
x.a1R(B.y,x.a.d!=null&&w)},
$S:4}
A.dOg.prototype={
$0(){},
$S:0}
A.dOh.prototype={
$2(d,e){var x=this.a
return e?x.G(0,d):x.ad(0,d)},
$S:991}
A.dOm.prototype={
$1(d){var x=this.a
if(x.c!=null)x.gtN().st(C.bh(x.gtN().a,y.k))},
$S:3}
A.dOn.prototype={
$1(d){var x=this.a.a,w=x.f
return B.h.aj((d-w)/((x.r-w)/this.b))},
$S:77}
A.dOi.prototype={
$0(){return this.a.a54(this.b)},
$S:0}
A.dOj.prototype={
$0(){return this.a.a54(this.b)},
$S:0}
A.dOk.prototype={
$1(d){var x=this.a
x.e=!0
x.a1R(B.a8,x.a.d!=null)},
$S:17}
A.dOl.prototype={
$1(d){var x=this.a
x.e=!1
x.a1R(B.a8,!1)},
$S:18};(function installTearOffs(){var x=a._static_0,w=a._instance_0u,v=a._instance_2u
x(A,"hSW","hkD",0)
var u
w(u=A.aJV.prototype,"gav_","bhI",0)
v(u,"gbhJ","bhK",1)
x(A,"hSU","axT",2)})();(function inheritance(){var x=a.inherit,w=a.inheritMany
x(A.a9N,C.ef)
w(C.T,[A.b8p,A.b6m])
x(A.d6X,D.bn_)
x(A.atN,C.j)
x(A.aJV,C.k)
w(C.cq,[A.dOo,A.dOm,A.dOn,A.dOk,A.dOl])
w(C.db,[A.dOg,A.dOi,A.dOj])
x(A.dOh,C.df)})()
C.c_(b.typeUniverse,JSON.parse('{"hwy":{"aP":[],"aW":[],"b":[]},"atN":{"j":[],"b":[]},"aJV":{"k":["atN"]}}'))
var y={h:C.G("hwy"),o:C.G("di"),t:C.G("dF"),k:C.G("P"),e:C.G("u"),g:C.G("jp?"),v:C.G("~")};(function constants(){E.atn=new A.a9N(0,"fill")
E.L_=new A.a9N(1,"contain")
E.xo=new A.a9N(2,"cover")
E.b9=new A.a9N(6,"scaleDown")
E.avp=new A.b6m()
E.b7C=new A.b8p(B.t,B.t)
E.jx=new C.oX("grab")
E.n3=new C.oX("grabbing")})()};
(a=>{a["OTOBAcbNJvYtQcutVjovJguJ0Xw="]=a.current})($__dart_deferred_initializers__);