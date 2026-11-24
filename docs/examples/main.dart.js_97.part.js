((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,D,A={
vQ(d,e,f,g,h,i){return new A.bHi(i,h,d,f,g,e,null)},
bHi:function bHi(d,e,f,g,h,i,j){var _=this
_.e=d
_.f=e
_.r=f
_.w=g
_.x=h
_.c=i
_.a=j},
F9:function F9(d,e,f){this.dN$=d
this.a4$=e
this.a=f},
aAm:function aAm(d,e,f,g,h,i,j,k,l,m,n){var _=this
_.D=d
_.R=e
_.a3=f
_.ac=g
_.ah=h
_.aH=i
_.aD=null
_.c_$=j
_.W$=k
_.bv$=l
_.dy=m
_.b=_.fy=null
_.c=0
_.y=_.d=null
_.z=!0
_.Q=null
_.as=!1
_.at=null
_.ay=$
_.ch=n
_.CW=!1
_.cx=$
_.cy=!0
_.db=!1
_.dx=$},
fuW:function fuW(){},
fvk:function fvk(){},
fuX:function fuX(){},
fuY:function fuY(d){this.a=d},
fvb:function fvb(d){this.a=d},
fv2:function fv2(){},
fv3:function fv3(){},
fv4:function fv4(d,e){this.a=d
this.b=e},
cEy:function cEy(){},
cEB:function cEB(){}}
J=c[1]
B=c[0]
C=c[2]
D=c[264]
A=a.updateHolder(c[217],A)
A.bHi.prototype={
aw(d){var x=this,w=new A.aAm(x.e,x.f,x.r,x.w,d.t(y.n).w,x.x,0,null,null,new B.aX(),B.aM())
w.av()
return w},
aI(d,e){var x=this
y.r.a(e)
e.sqk(x.e)
e.samo(x.f)
e.sk5(x.r)
e.sRL(x.w)
e.aH=x.x
e.sbI(d.t(y.n).w)}}
A.F9.prototype={}
A.aAm.prototype={
sqk(d){if(d===this.D)return
this.D=d
this.a6()},
samo(d){if(d===this.R)return
this.R=d
this.a6()},
sk5(d){if(d===this.a3)return
this.a3=d
this.a6()},
sRL(d){if(d===this.ac)return
this.ac=d
this.a6()},
sbI(d){if(d===this.ah)return
this.ah=d
this.a6()},
f7(d){if(!(d.b instanceof A.F9))d.b=new A.F9(null,null,C.K)},
gadJ(){var x,w,v,u,t,s,r=this.ia(),q=r.length
if(q===0)return 0
for(x=0,w=0,v=0;u=r.length,v<u;r.length===q||(0,B.D)(r),++v){t=r[v]
s=C.al.d5(t.dy,1/0,t.gaA())
x+=s
w=Math.max(w,s)}q=this.ac?w*u:x
return q+this.D*Math.max(0,u-1)},
gauJ(){return C.c.b6(this.ia(),0,new A.fuW())},
b1(d){return C.c.b6(this.ia(),0,new A.fvk())},
aR(d){return this.gadJ()},
aF(d){return this.aru(d)},
aM(d){return this.aru(d)},
aru(d){var x,w,v=this,u=v.ia()
if(u.length===0)return 0
if(v.gadJ()<=d)return C.c.b6(u,0,new A.fuX())
x=C.c.b6(u,0,new A.fuY(isFinite(d)?d:v.gauJ()))
w=u.length
return x+v.R*Math.max(0,w-1)},
hV(d){return this.w4(d)},
bZ(d){return this.arv(d,!0)},
br(){this.fy=this.arv(y.a.a(B.G.prototype.gV.call(this)),!1)},
arv(b2,b3){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9=this,b0=null,b1=a9.ia()
if(b1.length===0)return new B.H(B.a7(0,b2.a,b2.b),B.a7(0,b2.c,b2.d))
x=b2.b
w=a9.gadJ()
v=w>x+1e-10
u=new A.fvb(b3)
t=a9.ah===C.I
s=!v
if(s){r=isFinite(x)?x:w
if(a9.ac){q=b1.length
p=(r-a9.D*Math.max(0,q-1))/q}else p=b0
q=B.a([],y.A)
for(o=b1.length,n=p!=null,m=0;m<b1.length;b1.length===o||(0,B.D)(b1),++m){l=b1[m]
if(n)k=B.dO(b0,p)
else{j=C.al.d5(l.dy,1/0,l.gaA())
k=new B.A(0,j,0,1/0)}q.push(u.$2(l,k))}i=b2.b_(new B.H(r,C.c.b6(q,0,new A.fv2())))
if(!b3){o=C.c.b6(q,0,new A.fv3())
k=b1.length
h=a9.D
g=k-1
f=i.a
e=Math.max(0,f-(o+h*Math.max(0,g)))
if(n)d=new B.x(0,h)
else{switch(a9.a3.a){case 0:o=new B.x(0,h)
break
case 1:o=new B.x(e,h)
break
case 2:o=new B.x(e/2,h)
break
case 3:o=k>1?new B.x(0,h+e/g):new B.x(0,h)
break
case 4:o=e/k
o=new B.x(o/2,h+o)
break
case 5:o=e/(k+1)
o=new B.x(o,h+o)
break
default:o=b0}d=o}a0=d.a
a1=d.b
for(o=D.aq(b1,0,y.g),n=J.a0(o.a),o=o.b,k=new D.ap(n,o),h=i.b,g=y.o,a2=a0;k.v();){a3=k.c
a3=a3>=0?new B.x(o+a3,n.gJ()):B.N(B.ah())
a4=q[a3.a]
a3=a3.b.b
a3.toString
g.a(a3)
a5=t?f-a2-a4.a:a2
a3.a=new B.t(a5,(h-a4.b)/2)
a2+=a4.a+a1}b3=!1}}else{r=isFinite(x)?x:a9.gauJ()
a6=B.dO(b0,r)
for(q=B.aE(b1).j("cD<1>"),o=new B.cD(b1,q),o=new B.cx(o,o.ga8(0),q.j("cx<bQ.E>")),n=!b3,q=q.j("bQ.E"),k=y.o,a7=0;o.v();){h=o.d
if(h==null)h=q.a(h)
a4=u.$2(h,a6)
if(n){h=h.b
h.toString
k.a(h).a=new B.t(0,a7)}a7+=a4.b+a9.R}i=b2.b_(new B.H(r,a7-a9.R))}if(!b3&&a9.aD!==v){q=a9.aD
a9.aD=v
a8=a9.aH
if(a8!=null)s=!s||q!=null
else s=!1
if(s)$.dK.ok$.push(new A.fv4(a8,v))}return i},
T(d,e){return this.hx(d,e)},
cO(d,e){return this.hM(d,e)}}
A.cEy.prototype={
aE(d){var x,w,v
this.dX(d)
x=this.W$
for(w=y.o;x!=null;){x.aE(d)
v=x.b
v.toString
x=w.a(v).a4$}},
al(){var x,w,v
this.dT()
x=this.W$
for(w=y.o;x!=null;){x.al()
v=x.b
v.toString
x=w.a(v).a4$}}}
A.cEB.prototype={}
var z=a.updateTypes(["p(p)"])
A.fuW.prototype={
$2(d,e){return Math.max(d,e.a1(C.al,1/0,e.gaA()))},
$S:29}
A.fvk.prototype={
$2(d,e){return Math.max(d,e.a1(C.b2,1/0,e.gbb()))},
$S:29}
A.fuX.prototype={
$2(d,e){return Math.max(d,e.a1(C.aZ,1/0,e.gb8()))},
$S:29}
A.fuY.prototype={
$2(d,e){return d+e.a1(C.aZ,this.a,e.gb8())},
$S:29}
A.fvb.prototype={
$2(d,e){var x
if(this.a)x=d.a1(C.aw,e,d.gc4())
else{d.bl(e,!0)
x=d.gC()}return x},
$S:54}
A.fv2.prototype={
$2(d,e){return Math.max(d,e.b)},
$S:143}
A.fv3.prototype={
$2(d,e){return d+e.a},
$S:143}
A.fv4.prototype={
$1(d){return this.a.$1(this.b)},
$S:4};(function installTearOffs(){var x=a._instance_1u
var w
x(w=A.aAm.prototype,"gbb","b1",0)
x(w,"gaA","aR",0)
x(w,"gbc","aF",0)
x(w,"gb8","aM",0)})();(function inheritance(){var x=a.mixinHard,w=a.mixin,v=a.inherit,u=a.inheritMany
v(A.bHi,B.di)
v(A.F9,B.dy)
v(A.cEy,B.v)
v(A.cEB,A.cEy)
v(A.aAm,A.cEB)
u(B.dg,[A.fuW,A.fvk,A.fuX,A.fuY,A.fvb,A.fv2,A.fv3])
v(A.fv4,B.cl)
x(A.cEy,B.al)
w(A.cEB,B.bb)})()
B.bM(b.typeUniverse,JSON.parse('{"F9":{"dy":["v"],"dC":[],"eD":["v"],"ef":[]},"bHi":{"di":[],"aP":[],"b":[]},"aAm":{"bb":["v","F9"],"v":[],"al":["v","F9"],"G":[],"aQ":[],"al.1":"F9","bb.1":"F9","bb.0":"v","al.0":"v"}}'))
var y={a:B.F("A"),n:B.F("dt"),A:B.F("o<H>"),g:B.F("v"),o:B.F("F9"),r:B.F("aAm")}};
(a=>{a["WHrYovjv6QT5lMBH3f4YeZIVkFo="]=a.current})($__dart_deferred_initializers__);