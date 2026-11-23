((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,D,B={
idP(d,e,f,g,h,i,j,k){return new B.aIs(e,f,j,g,k,i,d,h)},
wF:function wF(d,e){this.a=d
this.b=e},
aIs:function aIs(d,e,f,g,h,i,j,k){var _=this
_.c=d
_.f=e
_.w=f
_.x=g
_.y=h
_.Q=i
_.ax=j
_.a=k},
b1u:function b1u(d,e){this.a=d
this.b=e},
b_F:function b_F(d,e,f,g){var _=this
_.e=_.d=$
_.r=_.f=null
_.w=0
_.y=_.x=!1
_.z=null
_.Q=!1
_.as=d
_.nP$=e
_.es$=f
_.bb$=g
_.c=_.a=null},
eCe:function eCe(d){this.a=d},
eCf:function eCf(d){this.a=d},
eCg:function eCg(d){this.a=d},
eCh:function eCh(d){this.a=d},
bg6:function bg6(){},
bg7:function bg7(){},
ixo(d,e,f,g){return new B.bJA(e,d,f,g,null)},
bJA:function bJA(d,e,f,g,h){var _=this
_.e=d
_.r=e
_.x=f
_.c=g
_.a=h}},C,E
J=c[1]
A=c[0]
D=c[2]
B=a.updateHolder(c[239],B)
C=c[792]
E=c[266]
B.wF.prototype={
X(){return"DismissDirection."+this.b}}
B.aIs.prototype={
n(){var x=null
return new B.b_F(new A.aM(x,y.z),x,x,x)}}
B.b1u.prototype={
X(){return"_FlingGestureKind."+this.b}}
B.b_F.prototype={
aq(){var x,w,v=this
v.b2O()
x=v.gvA()
x.dR()
w=x.hq$
w.b=!0
w.a.push(v.gbk6())
x.dR()
x.fd$.G(0,v.gbk8())
v.agb()},
gvA(){var x,w=this,v=w.d
if(v===$){x=A.cd(null,w.a.Q,null,1,null,w)
w.d!==$&&A.aH()
w.d=x
v=x}return v},
gAH(){var x=this.gvA().r
if(!(x!=null&&x.a!=null)){x=this.f
if(x==null)x=null
else{x=x.r
x=x!=null&&x.a!=null}x=x===!0}else x=!0
return x},
k(){this.gvA().k()
var x=this.f
if(x!=null)x.k()
this.b2N()},
gun(){var x=this.a.x
return x===C.kG||x===C.a6H||x===C.Sg},
Eg(d){var x,w,v,u
if(d===0)return C.Si
if(this.gun()){x=this.c.t(y.o).w
A:{w=D.I===x
if(w&&d<0){v=C.Sg
break A}u=D.O===x
if(u&&d>0){v=C.Sg
break A}if(!w)v=u
else v=!0
if(v){v=C.a6H
break A}v=null}return v}return d>0?C.Sh:C.bfJ},
ga8E(){this.a.toString
C.cLs.p(0,this.Eg(this.w))
return 0.4},
gaCT(){var x=this.c.gD()
x.toString
return this.gun()?x.a:x.b},
beq(d){var x,w,v=this
if(v.x)return
v.y=!0
x=v.gvA()
w=x.r
if(w!=null&&w.a!=null){w=x.x
w===$&&A.l()
v.w=w*v.gaCT()*J.lJ(v.w)
x.fw()}else{v.w=0
x.sq(0)}v.m(new B.eCe(v))},
ber(d){var x,w,v,u=this
if(u.y){x=u.gvA().r
x=x!=null&&x.a!=null}else x=!0
if(x)return
x=d.e
x.toString
w=u.w
switch(u.a.x.a){case 1:case 0:u.w=w+x
break
case 4:x=w+x
if(x<0)u.w=x
break
case 5:x=w+x
if(x>0)u.w=x
break
case 2:switch(u.c.t(y.o).w.a){case 0:x=u.w+x
if(x>0)u.w=x
break
case 1:x=u.w+x
if(x<0)u.w=x
break}break
case 3:switch(u.c.t(y.o).w.a){case 0:x=u.w+x
if(x<0)u.w=x
break
case 1:x=u.w+x
if(x>0)u.w=x
break}break
case 6:u.w=0
break}if(J.lJ(w)!==J.lJ(u.w))u.m(new B.eCf(u))
x=u.gvA()
v=x.r
if(!(v!=null&&v.a!=null))x.sq(Math.abs(u.w)/u.gaCT())},
bk9(){this.a.toString},
agb(){var x=this,w=J.lJ(x.w),v=x.gvA(),u=x.gun(),t=x.a
if(u){t.toString
u=new A.t(w,0)}else{t.toString
u=new A.t(0,w)}t=y.A
x.e=new A.aV(y.v.a(v),new A.b8(D.K,u,t),t.j("aV<be.T>"))},
bdV(d){var x,w,v,u,t=this
if(t.w===0)return C.Zg
x=d.a
w=x.a
v=x.b
if(t.gun()){x=Math.abs(w)
if(x-Math.abs(v)<400||x<700)return C.Zg
u=t.Eg(w)}else{x=Math.abs(v)
if(x-Math.abs(w)<400||x<700)return C.Zg
u=t.Eg(v)}if(u===t.Eg(t.w))return C.dt6
return C.dt7},
bep(d){var x,w,v,u,t=this
if(t.y){x=t.gvA().r
x=x!=null&&x.a!=null}else x=!0
if(x)return
t.y=!1
x=t.gvA()
if(x.gbN()===D.cx){t.O2()
return}w=d.c
v=w.a
u=t.gun()?v.a:v.b
switch(t.bdV(w).a){case 1:if(t.ga8E()>=1){x.fX()
break}t.w=J.lJ(u)
x.RT(Math.abs(u)*0.0033333333333333335)
break
case 2:t.w=J.lJ(u)
x.RT(-Math.abs(u)*0.0033333333333333335)
break
case 0:if(x.gbN()!==D.bE){w=x.x
w===$&&A.l()
if(w>t.ga8E())x.f8()
else x.fX()}break}},
WP(d){return this.bk7(d)},
bk7(d){var x=0,w=A.ad(y.q),v=this
var $async$WP=A.ae(function(e,f){if(e===1)return A.aa(f,w)
for(;;)switch(x){case 0:x=d===D.cx&&!v.y?2:3
break
case 2:x=4
return A.a3(v.O2(),$async$WP)
case 4:case 3:if(v.c!=null)v.yt()
return A.ab(null,w)}})
return A.ac($async$WP,w)},
O2(){var x=0,w=A.ad(y.q),v,u=this,t
var $async$O2=A.ae(function(d,e){if(d===1)return A.aa(e,w)
for(;;)switch(x){case 0:if(u.ga8E()>=1){u.gvA().fX()
x=1
break}x=3
return A.a3(u.VH(),$async$O2)
case 3:t=e
if(u.c!=null)if(t)u.bFF()
else u.gvA().fX()
case 1:return A.ab(v,w)}})
return A.ac($async$O2,w)},
VH(){var x=0,w=A.ad(y.e),v,u=2,t=[],s=[],r=this,q,p
var $async$VH=A.ae(function(d,e){if(d===1){t.push(e)
x=u}for(;;)switch(x){case 0:x=r.a.f!=null?3:4
break
case 3:r.x=!0
q=r.Eg(r.w)
u=5
x=8
return A.a3(r.a.f.$1(q),$async$VH)
case 8:p=e
if(p==null)p=!1
v=p
s=[1]
x=6
break
s.push(7)
x=6
break
case 5:s=[2]
case 6:u=2
r.x=!1
x=s.pop()
break
case 7:case 4:v=!0
x=1
break
case 1:return A.ab(v,w)
case 2:return A.aa(t.at(-1),w)}})
return A.ac($async$VH,w)},
bFF(){var x,w,v=this,u=v.a.y
if(u==null){x=v.Eg(v.w)
v.a.w.$1(x)}else{u=A.cd(null,u,null,1,null,v)
u.dR()
u.fd$.G(0,v.gbmQ())
u.dR()
w=u.hq$
w.b=!0
w.a.push(new B.eCg(v))
v.f=u
u.f8()
v.m(new B.eCh(v))}},
bmR(){var x=this,w=x.f.gbN(),v=x.a
if(w===D.cx)v.w.$1(x.Eg(x.w))
else v.toString},
h(d){var x,w,v,u,t,s,r,q,p=this,o=null
p.My(d)
x=p.a
x.toString
w=p.r
if(w!=null){x=p.gun()?D.w:D.F
v=p.z
return B.ixo(o,x,new A.r(v.a,v.b,o,o),w)}w=p.e
w===$&&A.l()
u=A.np(new E.dm(x.c,p.as),w,o,!0)
if(x.x===C.Si)return u
w=p.gun()?p.gavS():o
v=p.gun()?p.gavT():o
t=p.gun()?p.gavR():o
s=p.gun()?o:p.gavS()
r=p.gun()?o:p.gavT()
q=p.gun()?o:p.gavR()
return A.ct(x.ax,u,D.q,!1,o,o,o,o,t,w,v,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,q,s,r,o)}}
B.bg6.prototype={
br(){this.bB()
this.bA()
this.fJ()},
k(){var x=this,w=x.bb$
if(w!=null)w.S(x.gfF())
x.bb$=null
x.K()}}
B.bg7.prototype={
aq(){this.aA()
if(this.gAH())this.Ed()},
kW(){var x=this.nP$
if(x!=null){x.T()
x.cW()
this.nP$=null}this.tb()}}
B.bJA.prototype={
h(d){var x,w,v=this,u=null,t=v.r
if(t==null)switch(v.e.a){case 0:t=new A.jd(0,-1)
break
case 1:t=new A.jd(-1,0)
break
default:t=u}x=v.e
w=x===D.w?Math.max(y.v.a(v.c).gq(),0):u
x=x===D.F?Math.max(y.v.a(v.c).gq(),0):u
return A.ew(new A.af(t,x,w,v.x,u),D.n,u)}}
var z=a.updateTypes(["~()","~(jP)","~(lc)","~(ih)","bb<~>(fB)"])
B.eCe.prototype={
$0(){this.a.agb()},
$S:0}
B.eCf.prototype={
$0(){this.a.agb()},
$S:0}
B.eCg.prototype={
$1(d){return this.a.yt()},
$S:52}
B.eCh.prototype={
$0(){var x,w,v,u=this.a
u.z=u.c.gD()
x=u.f
x.toString
w=y.v
v=y.g
u.r=new A.aV(w.a(new A.aV(w.a(x),new A.f9(C.abV),y.n.j("aV<be.T>"))),new A.b8(1,0,v),v.j("aV<be.T>"))},
$S:0};(function aliases(){var x=B.bg6.prototype
x.b2N=x.k
x=B.bg7.prototype
x.b2O=x.aq})();(function installTearOffs(){var x=a._instance_1u,w=a._instance_0u
var v
x(v=B.b_F.prototype,"gavS","beq",1)
x(v,"gavT","ber",2)
w(v,"gbk8","bk9",0)
x(v,"gavR","bep",3)
x(v,"gbk6","WP",4)
w(v,"gbmQ","bmR",0)})();(function inheritance(){var x=a.mixinHard,w=a.inheritMany,v=a.inherit
w(A.eg,[B.wF,B.b1u])
v(B.aIs,A.i)
v(B.bg6,A.k)
v(B.bg7,B.bg6)
v(B.b_F,B.bg7)
w(A.cU,[B.eCe,B.eCf,B.eCh])
v(B.eCg,A.cj)
v(B.bJA,A.nW)
x(B.bg6,A.eQ)
x(B.bg7,A.CS)})()
A.bM(b.typeUniverse,JSON.parse('{"aIs":{"i":[],"b":[]},"b_F":{"k":["aIs"]},"bJA":{"nW":[],"i":[],"b":[]}}'))
var y={v:A.E("bK<p>"),n:A.E("f9"),o:A.E("dt"),z:A.E("aM<k<i>>"),A:A.E("b8<t>"),g:A.E("b8<p>"),e:A.E("w"),q:A.E("~")};(function constants(){C.kG=new B.wF(1,"horizontal")
C.a6H=new B.wF(2,"endToStart")
C.Sg=new B.wF(3,"startToEnd")
C.bfJ=new B.wF(4,"up")
C.Sh=new B.wF(5,"down")
C.Si=new B.wF(6,"none")
C.abV=new A.fv(0.4,1,D.bC)
C.cLs=new A.aj(D.fw,[],A.E("aj<wF,p>"))
C.Zg=new B.b1u(0,"none")
C.dt6=new B.b1u(1,"forward")
C.dt7=new B.b1u(2,"reverse")})()};
(a=>{a["d3QMokZP3fbFWf0SI023AX8dEHU="]=a.current})($__dart_deferred_initializers__);