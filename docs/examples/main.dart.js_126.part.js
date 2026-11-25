((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,D,A={
ive(d,e){return new A.amw(e,d,null)},
amw:function amw(d,e,f){this.w=d
this.b=e
this.a=f},
nT:function nT(d,e,f,g,h,i){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.r=h
_.a=i},
dDm:function dDm(d,e){this.a=d
this.b=e},
dDl:function dDl(d){this.a=d},
Kv:function Kv(d,e){this.a=d
this.b=e},
cAa:function cAa(d,e,f,g,h){var _=this
_.d=d
_.e=e
_.f=f
_.r=g
_.a=h},
bao:function bao(d,e,f,g,h,i){var _=this
_.D=d
_.S=e
_.a4=f
_.d3$=g
_.dy=h
_.b=_.fy=null
_.c=0
_.y=_.d=null
_.z=!0
_.Q=null
_.as=!1
_.at=null
_.ay=$
_.ch=i
_.CW=!1
_.cx=$
_.cy=!0
_.db=!1
_.dx=$},
fCf:function fCf(d){this.a=d},
fCh:function fCh(d,e){this.a=d
this.b=e},
fCg:function fCg(d){this.a=d},
cH3:function cH3(){}},C,E
B=c[0]
D=c[2]
A=a.updateHolder(c[158],A)
C=c[906]
E=c[268]
A.amw.prototype={
bf(d){return!this.w.i(0,d.w)},
jY(d,e){return A.ive(e,this.w)}}
A.nT.prototype={
h(d){var x,w=new A.dDm(this,d)
if(this.e==null)return w.$1$showHint(!1)
x=this.d
x.toString
return new E.eo(x,new A.dDl(w),null,null,y.D)}}
A.Kv.prototype={
Y(){return"_Slot."+this.b}}
A.cAa.prototype={
gvR(){return C.cBW},
wh(d){var x
switch(d.a){case 0:x=this.f
break
case 1:x=this.r
break
default:x=null}return x},
az(d){var x=new A.bao(this.d,this.e,d.u(y.o).w,B.am(y.y,y.g),new B.aY(),B.aM())
x.aw()
return x},
aJ(d,e){e.sTp(this.d)
e.sbZB(this.e)
e.sbL(d.u(y.o).w)}}
A.bao.prototype={
sTp(d){if(d===this.D)return
this.D=d
this.a6()},
sbZB(d){if(d===this.S)return
this.S=d
this.a6()},
sbL(d){if(d===this.a4)return
this.a4=d
this.a6()},
gaw1(){var x,w={}
w.a=null
x=this.d3$.q(0,C.nJ)
x.toString
new A.fCf(w).$1(x)
w=w.a
return w==null?null:w.bH.iX().gbI()},
ga7I(){var x=this.gaw1()
if(this.S||x==null)return 0
return Math.max(0,(this.D-x)/2)},
a95(d,e){var x,w,v,u,t=this,s=t.ga7I(),r=2*s,q=new B.B(d.a,d.b,0,Math.max(0,d.d-r)),p=t.d3$.q(0,C.nJ)
p.toString
x=e.$2(p,q)
p=x.a
w=t.D
v=x.b
u=d.b0(new B.I(p,Math.max(w,v+r)))
return new B.clP([u,x,q,t.S?(u.b-v)/2:s])},
c0(d){return this.a95(d,B.kr()).a[0]},
h_(d,e){var x,w,v=this.a95(d,B.kr()),u=this.d3$.q(0,C.nJ)
u.toString
x=v.a
w=u.hL(x[2],e)
return w==null?null:w+x[3]},
i_(d){var x,w=this.d3$.q(0,C.nJ)
w.toString
x=w.nv(d)
if(x==null)return null
w=w.b
w.toString
return x+y.d.a(w).a.b},
b1(d){var x=this.d3$.q(0,C.nJ)
x.toString
return x.a0(D.aY,d,x.gba())},
aQ(d){var x=this.d3$.q(0,C.nJ)
x.toString
return x.a0(D.al,d,x.gaA())},
aG(d){var x=this.D,w=this.d3$.q(0,C.nJ)
w.toString
return Math.max(x,w.a0(D.b6,d,w.gbe())+2*this.ga7I())},
aM(d){var x=this.D,w=this.d3$.q(0,C.nJ)
w.toString
return Math.max(x,w.a0(D.b0,d,w.gb7())+2*this.ga7I())},
bu(){var x,w,v,u,t,s,r,q,p,o=this,n=o.a95(y.a.a(B.H.prototype.gX.call(o)),B.o5()).a
o.fy=n[0]
x=o.d3$
w=x.q(0,C.nJ)
w.toString
v=n[3]
n=w.b
n.toString
u=y.d
u.a(n)
t=o.gE()
s=w.gE()
n.a=new B.u(o.a4===D.I?t.a-s.a:0,v)
n=x.q(0,C.a_x)
if(n==null)return
n.bm(new B.B(0,w.gE().a,0,1/0),!0)
r=w.vK(D.aq,!0)
q=n.vK(D.aq,!0)
p=o.gaw1()
if(p==null)p=w.gE().b
x=n.b
x.toString
u.a(x)
u=o.gE()
w=n.gE()
w=o.a4===D.I?u.a-w.a:0
x.a=new B.u(w,r!=null&&q!=null?v+r-q:v+(p-n.gE().b)/2)},
U(d,e){var x=new A.fCh(d,e),w=this.d3$
x.$1(w.q(0,C.a_x))
w=w.q(0,C.nJ)
w.toString
x.$1(w)},
cQ(d,e){var x,w,v,u=this.d3$.q(0,C.nJ)
u.toString
x=u.b
x.toString
w=y.d.a(x).a
x=w.a
v=w.b
return d.iw(new A.fCg(u),w,new B.u(Math.min(Math.max(e.a,x),x+u.gE().a-1),Math.min(Math.max(e.b,v),v+u.gE().b-1)))}}
A.cH3.prototype={
aD(d){var x
this.dX(d)
for(x=this.d3$,x=new B.fC(x,x.r,x.e);x.A();)x.d.aD(d)},
am(){this.dU()
for(var x=this.d3$,x=new B.fC(x,x.r,x.e);x.A();)x.d.am()}}
var z=a.updateTypes(["q(q)"])
A.dDm.prototype={
$1$showHint(d){var x,w,v,u,t=null,s=this.a
if(d){x=s.e
x.toString
x=new B.a2(!0,x,t)}else x=t
w=B.aIT(this.b)
v=w==null
u=v?t:w.a
v=v?t:w.b
return A.ive(new A.cAa(s.c,s.f===1,s.r,x,t),new B.aet(u!==!1,v!==!1,D.aU))},
$S:1166}
A.dDl.prototype={
$3(d,e,f){return this.a.$1$showHint(e.a.length===0)},
$S:1167}
A.fCf.prototype={
$1(d){var x=this.a
if(x.a!=null)return
if(d instanceof E.m2)x.a=d
else d.dT(this)},
$S:26}
A.fCh.prototype={
$1(d){var x
if(d==null)return
x=d.b
x.toString
this.a.ff(d,this.b.aC(0,y.d.a(x).a))},
$S:373}
A.fCg.prototype={
$2(d,e){return this.a.cY(d,e)},
$S:17};(function installTearOffs(){var x=a._instance_1u
var w
x(w=A.bao.prototype,"gba","b1",0)
x(w,"gaA","aQ",0)
x(w,"gbe","aG",0)
x(w,"gb7","aM",0)})();(function inheritance(){var x=a.mixinHard,w=a.inherit,v=a.inheritMany
w(A.amw,B.dP)
w(A.nT,B.k)
v(B.cl,[A.dDm,A.dDl,A.fCf,A.fCh])
w(A.Kv,B.eh)
w(A.cAa,E.EQ)
w(A.cH3,B.w)
w(A.bao,A.cH3)
w(A.fCg,B.di)
x(A.cH3,E.m4)})()
B.bO(b.typeUniverse,JSON.parse('{"amw":{"dP":[],"aK":[],"aT":[],"b":[]},"nT":{"k":[],"b":[]},"cAa":{"iQ":["Kv","w"],"aP":[],"b":[],"iQ.0":"Kv","iQ.1":"w"},"bao":{"w":[],"m4":["Kv","w"],"H":[],"aQ":[]}}'))
var y={a:B.G("B"),d:B.G("dB"),o:B.G("dv"),g:B.G("w"),D:B.G("eo<cQ>"),y:B.G("Kv")};(function constants(){var x=a.makeConstList
C.nJ=new A.Kv(0,"editable")
C.a_x=new A.Kv(1,"hint")
C.cBW=x([C.nJ,C.a_x],B.G("o<Kv>"))})()};
(a=>{a["uj3Uk1oxd3KB/DzfXk0tiM3zHYs="]=a.current})($__dart_deferred_initializers__);