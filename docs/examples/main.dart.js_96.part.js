((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,D,A={
vT(d,e,f,g,h,i){return new A.bHk(i,h,d,f,g,e,null)},
bHk:function bHk(d,e,f,g,h,i,j){var _=this
_.e=d
_.f=e
_.r=f
_.w=g
_.x=h
_.c=i
_.a=j},
Fe:function Fe(d,e,f){this.dJ$=d
this.a4$=e
this.a=f},
aAv:function aAv(d,e,f,g,h,i,j,k,l,m,n){var _=this
_.C=d
_.P=e
_.a3=f
_.ac=g
_.ai=h
_.aI=i
_.aE=null
_.bZ$=j
_.V$=k
_.bq$=l
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
fvW:function fvW(){},
fwk:function fwk(){},
fvX:function fvX(){},
fvY:function fvY(d){this.a=d},
fwb:function fwb(d){this.a=d},
fw2:function fw2(){},
fw3:function fw3(){},
fw4:function fw4(d,e){this.a=d
this.b=e},
cEY:function cEY(){},
cF0:function cF0(){}}
J=c[1]
B=c[0]
C=c[2]
D=c[264]
A=a.updateHolder(c[217],A)
A.bHk.prototype={
aw(d){var x=this,w=new A.aAv(x.e,x.f,x.r,x.w,d.t(y.n).w,x.x,0,null,null,new B.aX(),B.aM())
w.av()
return w},
aH(d,e){var x=this
y.r.a(e)
e.sqm(x.e)
e.samr(x.f)
e.sk7(x.r)
e.sRN(x.w)
e.aI=x.x
e.sbI(d.t(y.n).w)}}
A.Fe.prototype={}
A.aAv.prototype={
sqm(d){if(d===this.C)return
this.C=d
this.a6()},
samr(d){if(d===this.P)return
this.P=d
this.a6()},
sk7(d){if(d===this.a3)return
this.a3=d
this.a6()},
sRN(d){if(d===this.ac)return
this.ac=d
this.a6()},
sbI(d){if(d===this.ai)return
this.ai=d
this.a6()},
f0(d){if(!(d.b instanceof A.Fe))d.b=new A.Fe(null,null,C.K)},
gadN(){var x,w,v,u,t,s,r=this.ig(),q=r.length
if(q===0)return 0
for(x=0,w=0,v=0;u=r.length,v<u;r.length===q||(0,B.D)(r),++v){t=r[v]
s=C.ak.d4(t.dy,1/0,t.gaz())
x+=s
w=Math.max(w,s)}q=this.ac?w*u:x
return q+this.C*Math.max(0,u-1)},
gauM(){return C.c.b7(this.ig(),0,new A.fvW())},
b0(d){return C.c.b7(this.ig(),0,new A.fwk())},
aP(d){return this.gadN()},
aF(d){return this.arx(d)},
aK(d){return this.arx(d)},
arx(d){var x,w,v=this,u=v.ig()
if(u.length===0)return 0
if(v.gadN()<=d)return C.c.b7(u,0,new A.fvX())
x=C.c.b7(u,0,new A.fvY(isFinite(d)?d:v.gauM()))
w=u.length
return x+v.P*Math.max(0,w-1)},
hT(d){return this.w6(d)},
bY(d){return this.ary(d,!0)},
bs(){this.fy=this.ary(y.a.a(B.G.prototype.gW.call(this)),!1)},
ary(b2,b3){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9=this,b0=null,b1=a9.ig()
if(b1.length===0)return new B.H(B.a7(0,b2.a,b2.b),B.a7(0,b2.c,b2.d))
x=b2.b
w=a9.gadN()
v=w>x+1e-10
u=new A.fwb(b3)
t=a9.ai===C.I
s=!v
if(s){r=isFinite(x)?x:w
if(a9.ac){q=b1.length
p=(r-a9.C*Math.max(0,q-1))/q}else p=b0
q=B.a([],y.A)
for(o=b1.length,n=p!=null,m=0;m<b1.length;b1.length===o||(0,B.D)(b1),++m){l=b1[m]
if(n)k=B.dG(b0,p)
else{j=C.ak.d4(l.dy,1/0,l.gaz())
k=new B.A(0,j,0,1/0)}q.push(u.$2(l,k))}i=b2.b_(new B.H(r,C.c.b7(q,0,new A.fw2())))
if(!b3){o=C.c.b7(q,0,new A.fw3())
k=b1.length
h=a9.C
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
a3=a3>=0?new B.x(o+a3,n.gJ()):B.N(B.ag())
a4=q[a3.a]
a3=a3.b.b
a3.toString
g.a(a3)
a5=t?f-a2-a4.a:a2
a3.a=new B.t(a5,(h-a4.b)/2)
a2+=a4.a+a1}b3=!1}}else{r=isFinite(x)?x:a9.gauM()
a6=B.dG(b0,r)
for(q=B.aE(b1).j("cB<1>"),o=new B.cB(b1,q),o=new B.cy(o,o.ga9(0),q.j("cy<bR.E>")),n=!b3,q=q.j("bR.E"),k=y.o,a7=0;o.v();){h=o.d
if(h==null)h=q.a(h)
a4=u.$2(h,a6)
if(n){h=h.b
h.toString
k.a(h).a=new B.t(0,a7)}a7+=a4.b+a9.P}i=b2.b_(new B.H(r,a7-a9.P))}if(!b3&&a9.aE!==v){q=a9.aE
a9.aE=v
a8=a9.aI
if(a8!=null)s=!s||q!=null
else s=!1
if(s)$.dM.ok$.push(new A.fw4(a8,v))}return i},
T(d,e){return this.hr(d,e)},
cL(d,e){return this.hH(d,e)}}
A.cEY.prototype={
aC(d){var x,w,v
this.dV(d)
x=this.V$
for(w=y.o;x!=null;){x.aC(d)
v=x.b
v.toString
x=w.a(v).a4$}},
al(){var x,w,v
this.dS()
x=this.V$
for(w=y.o;x!=null;){x.al()
v=x.b
v.toString
x=w.a(v).a4$}}}
A.cF0.prototype={}
var z=a.updateTypes(["p(p)"])
A.fvW.prototype={
$2(d,e){return Math.max(d,e.a_(C.ak,1/0,e.gaz()))},
$S:30}
A.fwk.prototype={
$2(d,e){return Math.max(d,e.a_(C.aY,1/0,e.gb9()))},
$S:30}
A.fvX.prototype={
$2(d,e){return Math.max(d,e.a_(C.b_,1/0,e.gb6()))},
$S:30}
A.fvY.prototype={
$2(d,e){return d+e.a_(C.b_,this.a,e.gb6())},
$S:30}
A.fwb.prototype={
$2(d,e){var x
if(this.a)x=d.a_(C.av,e,d.gc4())
else{d.bi(e,!0)
x=d.gD()}return x},
$S:52}
A.fw2.prototype={
$2(d,e){return Math.max(d,e.b)},
$S:151}
A.fw3.prototype={
$2(d,e){return d+e.a},
$S:151}
A.fw4.prototype={
$1(d){return this.a.$1(this.b)},
$S:4};(function installTearOffs(){var x=a._instance_1u
var w
x(w=A.aAv.prototype,"gb9","b0",0)
x(w,"gaz","aP",0)
x(w,"gbc","aF",0)
x(w,"gb6","aK",0)})();(function inheritance(){var x=a.mixinHard,w=a.mixin,v=a.inherit,u=a.inheritMany
v(A.bHk,B.di)
v(A.Fe,B.dx)
v(A.cEY,B.v)
v(A.cF0,A.cEY)
v(A.aAv,A.cF0)
u(B.dj,[A.fvW,A.fwk,A.fvX,A.fvY,A.fwb,A.fw2,A.fw3])
v(A.fw4,B.cm)
x(A.cEY,B.al)
w(A.cF0,B.b9)})()
B.bN(b.typeUniverse,JSON.parse('{"Fe":{"dx":["v"],"dA":[],"ey":["v"],"e5":[]},"bHk":{"di":[],"aP":[],"b":[]},"aAv":{"b9":["v","Fe"],"v":[],"al":["v","Fe"],"G":[],"aQ":[],"al.1":"Fe","b9.1":"Fe","b9.0":"v","al.0":"v"}}'))
var y={a:B.F("A"),n:B.F("du"),A:B.F("o<H>"),g:B.F("v"),o:B.F("Fe"),r:B.F("aAv")}};
(a=>{a["cgU5UC7/SuKJ0vWLUVvXUlOe+Yk="]=a.current})($__dart_deferred_initializers__);