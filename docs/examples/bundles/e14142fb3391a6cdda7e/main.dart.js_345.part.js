((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,D,B={
hqU(d,e,f,g,h,i,j,k){return new B.aAY(e,f,j,g,k,i,d,h)},
v8:function v8(d,e){this.a=d
this.b=e},
aAY:function aAY(d,e,f,g,h,i,j,k){var _=this
_.c=d
_.f=e
_.w=f
_.x=g
_.y=h
_.Q=i
_.ax=j
_.a=k},
aTI:function aTI(d,e){this.a=d
this.b=e},
aS6:function aS6(d,e,f,g){var _=this
_.e=_.d=$
_.r=_.f=null
_.w=0
_.y=_.x=!1
_.z=null
_.Q=!1
_.as=d
_.n7$=e
_.eY$=f
_.b6$=g
_.c=_.a=null},
ebG:function ebG(d){this.a=d},
ebH:function ebH(d){this.a=d},
ebI:function ebI(d){this.a=d},
ebJ:function ebJ(d){this.a=d},
b5n:function b5n(){},
b5o:function b5o(){},
hJ9(d,e,f,g){return new B.bwP(e,d,f,g,null)},
bwP:function bwP(d,e,f,g,h){var _=this
_.e=d
_.r=e
_.x=f
_.c=g
_.a=h}},C,E
J=c[1]
A=c[0]
D=c[2]
B=a.updateHolder(c[215],B)
C=c[694]
E=c[240]
B.v8.prototype={
U(){return"DismissDirection."+this.b}}
B.aAY.prototype={
n(){var x=null
return new B.aS6(new A.aD(x,y.z),x,x,x)}}
B.aTI.prototype={
U(){return"_FlingGestureKind."+this.b}}
B.aS6.prototype={
ao(){var x,w,v=this
v.aZK()
x=v.guN()
x.dD()
w=x.ho$
w.b=!0
w.a.push(v.gbeY())
x.dD()
x.f7$.F(0,v.gbf_())
v.ae4()},
guN(){var x,w=this,v=w.d
if(v===$){x=A.cj(null,w.a.Q,null,1,null,w)
w.d!==$&&A.ay()
w.d=x
v=x}return v},
gzR(){var x=this.guN().r
if(!(x!=null&&x.a!=null)){x=this.f
if(x==null)x=null
else{x=x.r
x=x!=null&&x.a!=null}x=x===!0}else x=!0
return x},
k(){this.guN().k()
var x=this.f
if(x!=null)x.k()
this.aZJ()},
gty(){var x=this.a.x
return x===C.ld||x===C.a3L||x===C.Qn},
Dl(d){var x,w,v,u
if(d===0)return C.Qp
if(this.gty()){x=this.c.t(y.o).w
A:{w=D.E===x
if(w&&d<0){v=C.Qn
break A}u=D.K===x
if(u&&d>0){v=C.Qn
break A}if(!w)v=u
else v=!0
if(v){v=C.a3L
break A}v=null}return v}return d>0?C.Qo:C.b9b},
ga77(){this.a.toString
C.cDk.p(0,this.Dl(this.w))
return 0.4},
gazF(){var x=this.c.gA()
x.toString
return this.gty()?x.a:x.b},
b9O(d){var x,w,v=this
if(v.x)return
v.y=!0
x=v.guN()
w=x.r
if(w!=null&&w.a!=null){w=x.x
w===$&&A.h()
v.w=w*v.gazF()*J.le(v.w)
x.fc()}else{v.w=0
x.sq(0)}v.m(new B.ebG(v))},
b9P(d){var x,w,v,u=this
if(u.y){x=u.guN().r
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
break}if(J.le(w)!==J.le(u.w))u.m(new B.ebH(u))
x=u.guN()
v=x.r
if(!(v!=null&&v.a!=null))x.sq(Math.abs(u.w)/u.gazF())},
bf0(){this.a.toString},
ae4(){var x=this,w=J.le(x.w),v=x.guN(),u=x.gty(),t=x.a
if(u){t.toString
u=new A.q(w,0)}else{t.toString
u=new A.q(0,w)}t=y.A
x.e=new A.aN(y.v.a(v),new A.b0(D.F,u,t),t.j("aN<b2.T>"))},
b9i(d){var x,w,v,u,t=this
if(t.w===0)return C.WB
x=d.a
w=x.a
v=x.b
if(t.gty()){x=Math.abs(w)
if(x-Math.abs(v)<400||x<700)return C.WB
u=t.Dl(w)}else{x=Math.abs(v)
if(x-Math.abs(w)<400||x<700)return C.WB
u=t.Dl(v)}if(u===t.Dl(t.w))return C.diO
return C.diP},
b9N(d){var x,w,v,u,t=this
if(t.y){x=t.guN().r
x=x!=null&&x.a!=null}else x=!0
if(x)return
t.y=!1
x=t.guN()
if(x.gbM()===D.cf){t.MP()
return}w=d.c
v=w.a
u=t.gty()?v.a:v.b
switch(t.b9i(w).a){case 1:if(t.ga77()>=1){x.fP()
break}t.w=J.le(u)
x.Qr(Math.abs(u)*0.0033333333333333335)
break
case 2:t.w=J.le(u)
x.Qr(-Math.abs(u)*0.0033333333333333335)
break
case 0:if(x.gbM()!==D.bt){w=x.x
w===$&&A.h()
if(w>t.ga77())x.eZ()
else x.fP()}break}},
Vk(d){return this.beZ(d)},
beZ(d){var x=0,w=A.a9(y.q),v=this
var $async$Vk=A.aa(function(e,f){if(e===1)return A.a6(f,w)
for(;;)switch(x){case 0:x=d===D.cf&&!v.y?2:3
break
case 2:x=4
return A.a0(v.MP(),$async$Vk)
case 4:case 3:if(v.c!=null)v.xy()
return A.a7(null,w)}})
return A.a8($async$Vk,w)},
MP(){var x=0,w=A.a9(y.q),v,u=this,t
var $async$MP=A.aa(function(d,e){if(d===1)return A.a6(e,w)
for(;;)switch(x){case 0:if(u.ga77()>=1){u.guN().fP()
x=1
break}x=3
return A.a0(u.Uh(),$async$MP)
case 3:t=e
if(u.c!=null)if(t)u.bzV()
else u.guN().fP()
case 1:return A.a7(v,w)}})
return A.a8($async$MP,w)},
Uh(){var x=0,w=A.a9(y.e),v,u=2,t=[],s=[],r=this,q,p
var $async$Uh=A.aa(function(d,e){if(d===1){t.push(e)
x=u}for(;;)switch(x){case 0:x=r.a.f!=null?3:4
break
case 3:r.x=!0
q=r.Dl(r.w)
u=5
x=8
return A.a0(r.a.f.$1(q),$async$Uh)
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
case 1:return A.a7(v,w)
case 2:return A.a6(t.at(-1),w)}})
return A.a8($async$Uh,w)},
bzV(){var x,w,v=this,u=v.a.y
if(u==null){x=v.Dl(v.w)
v.a.w.$1(x)}else{u=A.cj(null,u,null,1,null,v)
u.dD()
u.f7$.F(0,v.gbhD())
u.dD()
w=u.ho$
w.b=!0
w.a.push(new B.ebI(v))
v.f=u
u.eZ()
v.m(new B.ebJ(v))}},
bhE(){var x=this,w=x.f.gbM(),v=x.a
if(w===D.cf)v.w.$1(x.Dl(x.w))
else v.toString},
h(d){var x,w,v,u,t,s,r,q,p=this,o=null
p.Lu(d)
x=p.a
x.toString
w=p.r
if(w!=null){x=p.gty()?D.w:D.C
v=p.z
return B.hJ9(o,x,new A.t(v.a,v.b,o,o),w)}w=p.e
w===$&&A.h()
u=A.mw(new E.eq(x.c,p.as),w,o,!0)
if(x.x===C.Qp)return u
w=p.gty()?p.gasS():o
v=p.gty()?p.gasT():o
t=p.gty()?p.gasR():o
s=p.gty()?o:p.gasS()
r=p.gty()?o:p.gasT()
q=p.gty()?o:p.gasR()
return A.cC(x.ax,u,D.r,!1,o,o,o,o,t,w,v,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,q,s,r,o)}}
B.b5n.prototype={
br(){this.bD()
this.bC()
this.fA()},
k(){var x=this,w=x.b6$
if(w!=null)w.P(x.gfz())
x.b6$=null
x.K()}}
B.b5o.prototype={
ao(){this.aw()
if(this.gzR())this.Di()},
ko(){var x=this.n7$
if(x!=null){x.W()
x.dq()
this.n7$=null}this.rl()}}
B.bwP.prototype={
h(d){var x,w,v=this,u=null,t=v.r
if(t==null)switch(v.e.a){case 0:t=new A.ix(0,-1)
break
case 1:t=new A.ix(-1,0)
break
default:t=u}x=v.e
w=x===D.w?Math.max(y.v.a(v.c).gq(),0):u
x=x===D.C?Math.max(y.v.a(v.c).gq(),0):u
return A.et(new A.ac(t,x,w,v.x,u),D.m,u)}}
var z=a.updateTypes(["~()","~(j3)","~(l1)","~(i_)","b_<~>(i8)"])
B.ebG.prototype={
$0(){this.a.ae4()},
$S:0}
B.ebH.prototype={
$0(){this.a.ae4()},
$S:0}
B.ebI.prototype={
$1(d){return this.a.xy()},
$S:43}
B.ebJ.prototype={
$0(){var x,w,v,u=this.a
u.z=u.c.gA()
x=u.f
x.toString
w=y.v
v=y.g
u.r=new A.aN(w.a(new A.aN(w.a(x),new A.eQ(C.a8k),y.n.j("aN<b2.T>"))),new A.b0(1,0,v),v.j("aN<b2.T>"))},
$S:0};(function aliases(){var x=B.b5n.prototype
x.aZJ=x.k
x=B.b5o.prototype
x.aZK=x.ao})();(function installTearOffs(){var x=a._instance_1u,w=a._instance_0u
var v
x(v=B.aS6.prototype,"gasS","b9O",1)
x(v,"gasT","b9P",2)
w(v,"gbf_","bf0",0)
x(v,"gasR","b9N",3)
x(v,"gbeY","Vk",4)
w(v,"gbhD","bhE",0)})();(function inheritance(){var x=a.mixinHard,w=a.inheritMany,v=a.inherit
w(A.e9,[B.v8,B.aTI])
v(B.aAY,A.j)
v(B.b5n,A.i)
v(B.b5o,B.b5n)
v(B.aS6,B.b5o)
w(A.cS,[B.ebG,B.ebH,B.ebJ])
v(B.ebI,A.ck)
v(B.bwP,A.mY)
x(B.b5n,A.eA)
x(B.b5o,A.B7)})()
A.bE(b.typeUniverse,JSON.parse('{"aAY":{"j":[],"b":[]},"aS6":{"i":["aAY"]},"bwP":{"mY":[],"j":[],"b":[]}}'))
var y={v:A.C("bK<o>"),n:A.C("eQ"),o:A.C("dp"),z:A.C("aD<i<j>>"),A:A.C("b0<q>"),g:A.C("b0<o>"),e:A.C("v"),q:A.C("~")};(function constants(){C.ld=new B.v8(1,"horizontal")
C.a3L=new B.v8(2,"endToStart")
C.Qn=new B.v8(3,"startToEnd")
C.b9b=new B.v8(4,"up")
C.Qo=new B.v8(5,"down")
C.Qp=new B.v8(6,"none")
C.a8k=new A.fe(0.4,1,D.bu)
C.cDk=new A.a2(D.fp,[],A.C("a2<v8,o>"))
C.WB=new B.aTI(0,"none")
C.diO=new B.aTI(1,"forward")
C.diP=new B.aTI(2,"reverse")})()};
(a=>{a["IFwHCVOHizWP8ueAHrqW4xkci0s="]=a.current})($__dart_deferred_initializers__);