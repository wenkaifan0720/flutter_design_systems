((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,D,A={
vR(d,e,f,g,h,i){return new A.bHb(i,h,d,f,g,e,null)},
bHb:function bHb(d,e,f,g,h,i,j){var _=this
_.e=d
_.f=e
_.r=f
_.w=g
_.x=h
_.c=i
_.a=j},
Fd:function Fd(d,e,f){this.dH$=d
this.a4$=e
this.a=f},
aAu:function aAu(d,e,f,g,h,i,j,k,l,m,n){var _=this
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
fvq:function fvq(){},
fvP:function fvP(){},
fvr:function fvr(){},
fvs:function fvs(d){this.a=d},
fvG:function fvG(d){this.a=d},
fvx:function fvx(){},
fvy:function fvy(){},
fvz:function fvz(d,e){this.a=d
this.b=e},
cEP:function cEP(){},
cES:function cES(){}}
J=c[1]
B=c[0]
C=c[2]
D=c[264]
A=a.updateHolder(c[217],A)
A.bHb.prototype={
aw(d){var x=this,w=new A.aAu(x.e,x.f,x.r,x.w,d.t(y.n).w,x.x,0,null,null,new B.aX(),B.aM())
w.av()
return w},
aH(d,e){var x=this
y.r.a(e)
e.sqk(x.e)
e.samo(x.f)
e.sk5(x.r)
e.sRL(x.w)
e.aI=x.x
e.sbI(d.t(y.n).w)}}
A.Fd.prototype={}
A.aAu.prototype={
sqk(d){if(d===this.C)return
this.C=d
this.a6()},
samo(d){if(d===this.P)return
this.P=d
this.a6()},
sk5(d){if(d===this.a3)return
this.a3=d
this.a6()},
sRL(d){if(d===this.ac)return
this.ac=d
this.a6()},
sbI(d){if(d===this.ai)return
this.ai=d
this.a6()},
eZ(d){if(!(d.b instanceof A.Fd))d.b=new A.Fd(null,null,C.K)},
gadJ(){var x,w,v,u,t,s,r=this.ib(),q=r.length
if(q===0)return 0
for(x=0,w=0,v=0;u=r.length,v<u;r.length===q||(0,B.D)(r),++v){t=r[v]
s=C.ak.d5(t.dy,1/0,t.gaz())
x+=s
w=Math.max(w,s)}q=this.ac?w*u:x
return q+this.C*Math.max(0,u-1)},
gauJ(){return C.c.b7(this.ib(),0,new A.fvq())},
b0(d){return C.c.b7(this.ib(),0,new A.fvP())},
aP(d){return this.gadJ()},
aF(d){return this.aru(d)},
aK(d){return this.aru(d)},
aru(d){var x,w,v=this,u=v.ib()
if(u.length===0)return 0
if(v.gadJ()<=d)return C.c.b7(u,0,new A.fvr())
x=C.c.b7(u,0,new A.fvs(isFinite(d)?d:v.gauJ()))
w=u.length
return x+v.P*Math.max(0,w-1)},
hR(d){return this.w3(d)},
bY(d){return this.arv(d,!0)},
bs(){this.fy=this.arv(y.a.a(B.G.prototype.gW.call(this)),!1)},
arv(b2,b3){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9=this,b0=null,b1=a9.ib()
if(b1.length===0)return new B.H(B.a7(0,b2.a,b2.b),B.a7(0,b2.c,b2.d))
x=b2.b
w=a9.gadJ()
v=w>x+1e-10
u=new A.fvG(b3)
t=a9.ai===C.I
s=!v
if(s){r=isFinite(x)?x:w
if(a9.ac){q=b1.length
p=(r-a9.C*Math.max(0,q-1))/q}else p=b0
q=B.a([],y.A)
for(o=b1.length,n=p!=null,m=0;m<b1.length;b1.length===o||(0,B.D)(b1),++m){l=b1[m]
if(n)k=B.dG(b0,p)
else{j=C.ak.d5(l.dy,1/0,l.gaz())
k=new B.A(0,j,0,1/0)}q.push(u.$2(l,k))}i=b2.b_(new B.H(r,C.c.b7(q,0,new A.fvx())))
if(!b3){o=C.c.b7(q,0,new A.fvy())
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
a3=a3>=0?new B.x(o+a3,n.gJ()):B.N(B.ah())
a4=q[a3.a]
a3=a3.b.b
a3.toString
g.a(a3)
a5=t?f-a2-a4.a:a2
a3.a=new B.t(a5,(h-a4.b)/2)
a2+=a4.a+a1}b3=!1}}else{r=isFinite(x)?x:a9.gauJ()
a6=B.dG(b0,r)
for(q=B.aE(b1).j("cB<1>"),o=new B.cB(b1,q),o=new B.cy(o,o.ga8(0),q.j("cy<bR.E>")),n=!b3,q=q.j("bR.E"),k=y.o,a7=0;o.v();){h=o.d
if(h==null)h=q.a(h)
a4=u.$2(h,a6)
if(n){h=h.b
h.toString
k.a(h).a=new B.t(0,a7)}a7+=a4.b+a9.P}i=b2.b_(new B.H(r,a7-a9.P))}if(!b3&&a9.aE!==v){q=a9.aE
a9.aE=v
a8=a9.aI
if(a8!=null)s=!s||q!=null
else s=!1
if(s)$.dM.ok$.push(new A.fvz(a8,v))}return i},
T(d,e){return this.hp(d,e)},
cL(d,e){return this.hF(d,e)}}
A.cEP.prototype={
aC(d){var x,w,v
this.dU(d)
x=this.V$
for(w=y.o;x!=null;){x.aC(d)
v=x.b
v.toString
x=w.a(v).a4$}},
al(){var x,w,v
this.dR()
x=this.V$
for(w=y.o;x!=null;){x.al()
v=x.b
v.toString
x=w.a(v).a4$}}}
A.cES.prototype={}
var z=a.updateTypes(["p(p)"])
A.fvq.prototype={
$2(d,e){return Math.max(d,e.a_(C.ak,1/0,e.gaz()))},
$S:29}
A.fvP.prototype={
$2(d,e){return Math.max(d,e.a_(C.aY,1/0,e.gb9()))},
$S:29}
A.fvr.prototype={
$2(d,e){return Math.max(d,e.a_(C.b_,1/0,e.gb6()))},
$S:29}
A.fvs.prototype={
$2(d,e){return d+e.a_(C.b_,this.a,e.gb6())},
$S:29}
A.fvG.prototype={
$2(d,e){var x
if(this.a)x=d.a_(C.av,e,d.gc4())
else{d.bi(e,!0)
x=d.gD()}return x},
$S:51}
A.fvx.prototype={
$2(d,e){return Math.max(d,e.b)},
$S:143}
A.fvy.prototype={
$2(d,e){return d+e.a},
$S:143}
A.fvz.prototype={
$1(d){return this.a.$1(this.b)},
$S:4};(function installTearOffs(){var x=a._instance_1u
var w
x(w=A.aAu.prototype,"gb9","b0",0)
x(w,"gaz","aP",0)
x(w,"gbc","aF",0)
x(w,"gb6","aK",0)})();(function inheritance(){var x=a.mixinHard,w=a.mixin,v=a.inherit,u=a.inheritMany
v(A.bHb,B.dh)
v(A.Fd,B.dx)
v(A.cEP,B.v)
v(A.cES,A.cEP)
v(A.aAu,A.cES)
u(B.dj,[A.fvq,A.fvP,A.fvr,A.fvs,A.fvG,A.fvx,A.fvy])
v(A.fvz,B.cm)
x(A.cEP,B.al)
w(A.cES,B.b9)})()
B.bM(b.typeUniverse,JSON.parse('{"Fd":{"dx":["v"],"dA":[],"ey":["v"],"e7":[]},"bHb":{"dh":[],"aP":[],"b":[]},"aAu":{"b9":["v","Fd"],"v":[],"al":["v","Fd"],"G":[],"aQ":[],"al.1":"Fd","b9.1":"Fd","b9.0":"v","al.0":"v"}}'))
var y={a:B.F("A"),n:B.F("du"),A:B.F("o<H>"),g:B.F("v"),o:B.F("Fd"),r:B.F("aAu")}};
(a=>{a["pRirc91lTm+rCZp13FUd9K2V6Ug="]=a.current})($__dart_deferred_initializers__);