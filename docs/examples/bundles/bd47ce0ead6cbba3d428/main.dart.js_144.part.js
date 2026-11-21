((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,D,B={
hEt(d,e,f,g,h,i,j,k){return new B.aCI(e,f,j,g,k,i,d,h)},
vG:function vG(d,e){this.a=d
this.b=e},
aCI:function aCI(d,e,f,g,h,i,j,k){var _=this
_.c=d
_.f=e
_.w=f
_.x=g
_.y=h
_.Q=i
_.ax=j
_.a=k},
aVw:function aVw(d,e){this.a=d
this.b=e},
aTR:function aTR(d,e,f,g){var _=this
_.e=_.d=$
_.r=_.f=null
_.w=0
_.y=_.x=!1
_.z=null
_.Q=!1
_.as=d
_.ni$=e
_.f1$=f
_.ba$=g
_.c=_.a=null},
ehK:function ehK(d){this.a=d},
ehL:function ehL(d){this.a=d},
ehM:function ehM(d){this.a=d},
ehN:function ehN(d){this.a=d},
b7A:function b7A(){},
b7B:function b7B(){},
hWP(d,e,f,g){return new B.bze(e,d,f,g,null)},
bze:function bze(d,e,f,g,h){var _=this
_.e=d
_.r=e
_.x=f
_.c=g
_.a=h}},C,E
J=c[1]
A=c[0]
D=c[2]
B=a.updateHolder(c[217],B)
C=c[275]
E=c[244]
B.vG.prototype={
W(){return"DismissDirection."+this.b}}
B.aCI.prototype={
n(){var x=null
return new B.aTR(new A.aN(x,y.z),x,x,x)}}
B.aVw.prototype={
W(){return"_FlingGestureKind."+this.b}}
B.aTR.prototype={
ap(){var x,w,v=this
v.b_S()
x=v.gvc()
x.dK()
w=x.hs$
w.b=!0
w.a.push(v.gbgk())
x.dK()
x.fa$.G(0,v.gbgm())
v.aeI()},
gvc(){var x,w=this,v=w.d
if(v===$){x=A.ck(null,w.a.Q,null,1,null,w)
w.d!==$&&A.aH()
w.d=x
v=x}return v},
gAa(){var x=this.gvc().r
if(!(x!=null&&x.a!=null)){x=this.f
if(x==null)x=null
else{x=x.r
x=x!=null&&x.a!=null}x=x===!0}else x=!0
return x},
k(){this.gvc().k()
var x=this.f
if(x!=null)x.k()
this.b_R()},
gu0(){var x=this.a.x
return x===C.lD||x===C.a57||x===C.Rl},
DJ(d){var x,w,v,u
if(d===0)return C.Rn
if(this.gu0()){x=this.c.t(y.o).w
A:{w=D.J===x
if(w&&d<0){v=C.Rl
break A}u=D.K===x
if(u&&d>0){v=C.Rl
break A}if(!w)v=u
else v=!0
if(v){v=C.a57
break A}v=null}return v}return d>0?C.Rm:C.bbm},
ga7C(){this.a.toString
C.cGv.p(0,this.DJ(this.w))
return 0.4},
gaAB(){var x=this.c.gB()
x.toString
return this.gu0()?x.a:x.b},
bb7(d){var x,w,v=this
if(v.x)return
v.y=!0
x=v.gvc()
w=x.r
if(w!=null&&w.a!=null){w=x.x
w===$&&A.i()
v.w=w*v.gaAB()*J.lq(v.w)
x.fj()}else{v.w=0
x.sq(0)}v.m(new B.ehK(v))},
bb8(d){var x,w,v,u=this
if(u.y){x=u.gvc().r
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
break}if(J.lq(w)!==J.lq(u.w))u.m(new B.ehL(u))
x=u.gvc()
v=x.r
if(!(v!=null&&v.a!=null))x.sq(Math.abs(u.w)/u.gaAB())},
bgn(){this.a.toString},
aeI(){var x=this,w=J.lq(x.w),v=x.gvc(),u=x.gu0(),t=x.a
if(u){t.toString
u=new A.q(w,0)}else{t.toString
u=new A.q(0,w)}t=y.A
x.e=new A.aR(y.v.a(v),new A.b3(D.I,u,t),t.j("aR<bb.T>"))},
baC(d){var x,w,v,u,t=this
if(t.w===0)return C.XT
x=d.a
w=x.a
v=x.b
if(t.gu0()){x=Math.abs(w)
if(x-Math.abs(v)<400||x<700)return C.XT
u=t.DJ(w)}else{x=Math.abs(v)
if(x-Math.abs(w)<400||x<700)return C.XT
u=t.DJ(v)}if(u===t.DJ(t.w))return C.dmw
return C.dmx},
bb6(d){var x,w,v,u,t=this
if(t.y){x=t.gvc().r
x=x!=null&&x.a!=null}else x=!0
if(x)return
t.y=!1
x=t.gvc()
if(x.gbO()===D.cn){t.Nl()
return}w=d.c
v=w.a
u=t.gu0()?v.a:v.b
switch(t.baC(w).a){case 1:if(t.ga7C()>=1){x.fS()
break}t.w=J.lq(u)
x.R0(Math.abs(u)*0.0033333333333333335)
break
case 2:t.w=J.lq(u)
x.R0(-Math.abs(u)*0.0033333333333333335)
break
case 0:if(x.gbO()!==D.bv){w=x.x
w===$&&A.i()
if(w>t.ga7C())x.f2()
else x.fS()}break}},
VV(d){return this.bgl(d)},
bgl(d){var x=0,w=A.ae(y.q),v=this
var $async$VV=A.af(function(e,f){if(e===1)return A.ab(f,w)
for(;;)switch(x){case 0:x=d===D.cn&&!v.y?2:3
break
case 2:x=4
return A.a1(v.Nl(),$async$VV)
case 4:case 3:if(v.c!=null)v.xX()
return A.ac(null,w)}})
return A.ad($async$VV,w)},
Nl(){var x=0,w=A.ae(y.q),v,u=this,t
var $async$Nl=A.af(function(d,e){if(d===1)return A.ab(e,w)
for(;;)switch(x){case 0:if(u.ga7C()>=1){u.gvc().fS()
x=1
break}x=3
return A.a1(u.US(),$async$Nl)
case 3:t=e
if(u.c!=null)if(t)u.bBg()
else u.gvc().fS()
case 1:return A.ac(v,w)}})
return A.ad($async$Nl,w)},
US(){var x=0,w=A.ae(y.e),v,u=2,t=[],s=[],r=this,q,p
var $async$US=A.af(function(d,e){if(d===1){t.push(e)
x=u}for(;;)switch(x){case 0:x=r.a.f!=null?3:4
break
case 3:r.x=!0
q=r.DJ(r.w)
u=5
x=8
return A.a1(r.a.f.$1(q),$async$US)
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
case 1:return A.ac(v,w)
case 2:return A.ab(t.at(-1),w)}})
return A.ad($async$US,w)},
bBg(){var x,w,v=this,u=v.a.y
if(u==null){x=v.DJ(v.w)
v.a.w.$1(x)}else{u=A.ck(null,u,null,1,null,v)
u.dK()
u.fa$.G(0,v.gbj0())
u.dK()
w=u.hs$
w.b=!0
w.a.push(new B.ehM(v))
v.f=u
u.f2()
v.m(new B.ehN(v))}},
bj1(){var x=this,w=x.f.gbO(),v=x.a
if(w===D.cn)v.w.$1(x.DJ(x.w))
else v.toString},
h(d){var x,w,v,u,t,s,r,q,p=this,o=null
p.LY(d)
x=p.a
x.toString
w=p.r
if(w!=null){x=p.gu0()?D.v:D.E
v=p.z
return B.hWP(o,x,new A.t(v.a,v.b,o,o),w)}w=p.e
w===$&&A.i()
u=A.mM(new E.dr(x.c,p.as),w,o,!0)
if(x.x===C.Rn)return u
w=p.gu0()?p.gatP():o
v=p.gu0()?p.gatQ():o
t=p.gu0()?p.gatO():o
s=p.gu0()?o:p.gatP()
r=p.gu0()?o:p.gatQ()
q=p.gu0()?o:p.gatO()
return A.cE(x.ax,u,D.r,!1,o,o,o,o,t,w,v,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,q,s,r,o)}}
B.b7A.prototype={
bq(){this.bC()
this.bB()
this.fF()},
k(){var x=this,w=x.ba$
if(w!=null)w.S(x.gfD())
x.ba$=null
x.L()}}
B.b7B.prototype={
ap(){this.aA()
if(this.gAa())this.DG()},
kx(){var x=this.ni$
if(x!=null){x.V()
x.du()
this.ni$=null}this.rQ()}}
B.bze.prototype={
h(d){var x,w,v=this,u=null,t=v.r
if(t==null)switch(v.e.a){case 0:t=new A.iD(0,-1)
break
case 1:t=new A.iD(-1,0)
break
default:t=u}x=v.e
w=x===D.v?Math.max(y.v.a(v.c).gq(),0):u
x=x===D.E?Math.max(y.v.a(v.c).gq(),0):u
return A.ey(new A.ah(t,x,w,v.x,u),D.m,u)}}
var z=a.updateTypes(["~()","~(je)","~(ld)","~(i7)","b8<~>(ig)"])
B.ehK.prototype={
$0(){this.a.aeI()},
$S:0}
B.ehL.prototype={
$0(){this.a.aeI()},
$S:0}
B.ehM.prototype={
$1(d){return this.a.xX()},
$S:47}
B.ehN.prototype={
$0(){var x,w,v,u=this.a
u.z=u.c.gB()
x=u.f
x.toString
w=y.v
v=y.g
u.r=new A.aR(w.a(new A.aR(w.a(x),new A.eX(C.aa8),y.n.j("aR<bb.T>"))),new A.b3(1,0,v),v.j("aR<bb.T>"))},
$S:0};(function aliases(){var x=B.b7A.prototype
x.b_R=x.k
x=B.b7B.prototype
x.b_S=x.ap})();(function installTearOffs(){var x=a._instance_1u,w=a._instance_0u
var v
x(v=B.aTR.prototype,"gatP","bb7",1)
x(v,"gatQ","bb8",2)
w(v,"gbgm","bgn",0)
x(v,"gatO","bb6",3)
x(v,"gbgk","VV",4)
w(v,"gbj0","bj1",0)})();(function inheritance(){var x=a.mixinHard,w=a.inheritMany,v=a.inherit
w(A.ek,[B.vG,B.aVw])
v(B.aCI,A.k)
v(B.b7A,A.l)
v(B.b7B,B.b7A)
v(B.aTR,B.b7B)
w(A.cS,[B.ehK,B.ehL,B.ehN])
v(B.ehM,A.cn)
v(B.bze,A.nf)
x(B.b7A,A.eD)
x(B.b7B,A.BK)})()
A.bN(b.typeUniverse,JSON.parse('{"aCI":{"k":[],"b":[]},"aTR":{"l":["aCI"]},"bze":{"nf":[],"k":[],"b":[]}}'))
var y={v:A.D("bT<p>"),n:A.D("eX"),o:A.D("di"),z:A.D("aN<l<k>>"),A:A.D("b3<q>"),g:A.D("b3<p>"),e:A.D("w"),q:A.D("~")};(function constants(){C.h9=new A.A(0,560,0,1/0)
C.lD=new B.vG(1,"horizontal")
C.a57=new B.vG(2,"endToStart")
C.Rl=new B.vG(3,"startToEnd")
C.bbm=new B.vG(4,"up")
C.Rm=new B.vG(5,"down")
C.Rn=new B.vG(6,"none")
C.aa8=new A.fl(0.4,1,D.bx)
C.cGv=new A.a6(D.fl,[],A.D("a6<vG,p>"))
C.XT=new B.aVw(0,"none")
C.dmw=new B.aVw(1,"forward")
C.dmx=new B.aVw(2,"reverse")})()};
(a=>{a["3y2CxEiAaxZQmVH/zSSaoOsgmWQ="]=a.current})($__dart_deferred_initializers__);