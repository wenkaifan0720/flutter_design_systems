((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,D,B={
hHz(d,e,f,g,h,i,j,k){return new B.aCN(e,f,j,g,k,i,d,h)},
vJ:function vJ(d,e){this.a=d
this.b=e},
aCN:function aCN(d,e,f,g,h,i,j,k){var _=this
_.c=d
_.f=e
_.w=f
_.x=g
_.y=h
_.Q=i
_.ax=j
_.a=k},
aVZ:function aVZ(d,e){this.a=d
this.b=e},
aUi:function aUi(d,e,f,g){var _=this
_.e=_.d=$
_.r=_.f=null
_.w=0
_.y=_.x=!1
_.z=null
_.Q=!1
_.as=d
_.nk$=e
_.f2$=f
_.bb$=g
_.c=_.a=null},
eiV:function eiV(d){this.a=d},
eiW:function eiW(d){this.a=d},
eiX:function eiX(d){this.a=d},
eiY:function eiY(d){this.a=d},
b8F:function b8F(){},
b8G:function b8G(){},
i_b(d,e,f,g){return new B.bAv(e,d,f,g,null)},
bAv:function bAv(d,e,f,g,h){var _=this
_.e=d
_.r=e
_.x=f
_.c=g
_.a=h}},C,E
J=c[1]
A=c[0]
D=c[2]
B=a.updateHolder(c[225],B)
C=c[283]
E=c[252]
B.vJ.prototype={
X(){return"DismissDirection."+this.b}}
B.aCN.prototype={
n(){var x=null
return new B.aUi(new A.aO(x,y.z),x,x,x)}}
B.aVZ.prototype={
X(){return"_FlingGestureKind."+this.b}}
B.aUi.prototype={
ap(){var x,w,v=this
v.b0I()
x=v.gvg()
x.dF()
w=x.he$
w.b=!0
w.a.push(v.gbhm())
x.dF()
x.fc$.E(0,v.gbho())
v.afd()},
gvg(){var x,w=this,v=w.d
if(v===$){x=A.ce(null,w.a.Q,null,1,null,w)
w.d!==$&&A.aG()
w.d=x
v=x}return v},
gAh(){var x=this.gvg().r
if(!(x!=null&&x.a!=null)){x=this.f
if(x==null)x=null
else{x=x.r
x=x!=null&&x.a!=null}x=x===!0}else x=!0
return x},
k(){this.gvg().k()
var x=this.f
if(x!=null)x.k()
this.b0H()},
gu1(){var x=this.a.x
return x===C.lD||x===C.a57||x===C.Rk},
DP(d){var x,w,v,u
if(d===0)return C.Rm
if(this.gu1()){x=this.c.t(y.o).w
A:{w=D.J===x
if(w&&d<0){v=C.Rk
break A}u=D.K===x
if(u&&d>0){v=C.Rk
break A}if(!w)v=u
else v=!0
if(v){v=C.a57
break A}v=null}return v}return d>0?C.Rl:C.baT},
ga7N(){this.a.toString
C.cFZ.p(0,this.DP(this.w))
return 0.4},
gaBi(){var x=this.c.gB()
x.toString
return this.gu1()?x.a:x.b},
bc1(d){var x,w,v=this
if(v.x)return
v.y=!0
x=v.gvg()
w=x.r
if(w!=null&&w.a!=null){w=x.x
w===$&&A.j()
v.w=w*v.gaBi()*J.lt(v.w)
x.fl()}else{v.w=0
x.sq(0)}v.m(new B.eiV(v))},
bc2(d){var x,w,v,u=this
if(u.y){x=u.gvg().r
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
break}if(J.lt(w)!==J.lt(u.w))u.m(new B.eiW(u))
x=u.gvg()
v=x.r
if(!(v!=null&&v.a!=null))x.sq(Math.abs(u.w)/u.gaBi())},
bhp(){this.a.toString},
afd(){var x=this,w=J.lt(x.w),v=x.gvg(),u=x.gu1(),t=x.a
if(u){t.toString
u=new A.q(w,0)}else{t.toString
u=new A.q(0,w)}t=y.A
x.e=new A.aS(y.v.a(v),new A.b4(D.H,u,t),t.j("aS<bb.T>"))},
bbw(d){var x,w,v,u,t=this
if(t.w===0)return C.Y_
x=d.a
w=x.a
v=x.b
if(t.gu1()){x=Math.abs(w)
if(x-Math.abs(v)<400||x<700)return C.Y_
u=t.DP(w)}else{x=Math.abs(v)
if(x-Math.abs(w)<400||x<700)return C.Y_
u=t.DP(v)}if(u===t.DP(t.w))return C.dmE
return C.dmF},
bc0(d){var x,w,v,u,t=this
if(t.y){x=t.gvg().r
x=x!=null&&x.a!=null}else x=!0
if(x)return
t.y=!1
x=t.gvg()
if(x.gbD()===D.cm){t.Ns()
return}w=d.c
v=w.a
u=t.gu1()?v.a:v.b
switch(t.bbw(w).a){case 1:if(t.ga7N()>=1){x.fT()
break}t.w=J.lt(u)
x.Ra(Math.abs(u)*0.0033333333333333335)
break
case 2:t.w=J.lt(u)
x.Ra(-Math.abs(u)*0.0033333333333333335)
break
case 0:if(x.gbD()!==D.bu){w=x.x
w===$&&A.j()
if(w>t.ga7N())x.f3()
else x.fT()}break}},
W6(d){return this.bhn(d)},
bhn(d){var x=0,w=A.ae(y.q),v=this
var $async$W6=A.af(function(e,f){if(e===1)return A.ab(f,w)
for(;;)switch(x){case 0:x=d===D.cm&&!v.y?2:3
break
case 2:x=4
return A.a2(v.Ns(),$async$W6)
case 4:case 3:if(v.c!=null)v.y5()
return A.ac(null,w)}})
return A.ad($async$W6,w)},
Ns(){var x=0,w=A.ae(y.q),v,u=this,t
var $async$Ns=A.af(function(d,e){if(d===1)return A.ab(e,w)
for(;;)switch(x){case 0:if(u.ga7N()>=1){u.gvg().fT()
x=1
break}x=3
return A.a2(u.V2(),$async$Ns)
case 3:t=e
if(u.c!=null)if(t)u.bCA()
else u.gvg().fT()
case 1:return A.ac(v,w)}})
return A.ad($async$Ns,w)},
V2(){var x=0,w=A.ae(y.e),v,u=2,t=[],s=[],r=this,q,p
var $async$V2=A.af(function(d,e){if(d===1){t.push(e)
x=u}for(;;)switch(x){case 0:x=r.a.f!=null?3:4
break
case 3:r.x=!0
q=r.DP(r.w)
u=5
x=8
return A.a2(r.a.f.$1(q),$async$V2)
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
return A.ad($async$V2,w)},
bCA(){var x,w,v=this,u=v.a.y
if(u==null){x=v.DP(v.w)
v.a.w.$1(x)}else{u=A.ce(null,u,null,1,null,v)
u.dF()
u.fc$.E(0,v.gbk2())
u.dF()
w=u.he$
w.b=!0
w.a.push(new B.eiX(v))
v.f=u
u.f3()
v.m(new B.eiY(v))}},
bk3(){var x=this,w=x.f.gbD(),v=x.a
if(w===D.cm)v.w.$1(x.DP(x.w))
else v.toString},
h(d){var x,w,v,u,t,s,r,q,p=this,o=null
p.M3(d)
x=p.a
x.toString
w=p.r
if(w!=null){x=p.gu1()?D.w:D.F
v=p.z
return B.i_b(o,x,new A.t(v.a,v.b,o,o),w)}w=p.e
w===$&&A.j()
u=A.mU(new E.dt(x.c,p.as),w,o,!0)
if(x.x===C.Rm)return u
w=p.gu1()?p.gauq():o
v=p.gu1()?p.gaur():o
t=p.gu1()?p.gaup():o
s=p.gu1()?o:p.gauq()
r=p.gu1()?o:p.gaur()
q=p.gu1()?o:p.gaup()
return A.cG(x.ax,u,D.r,!1,o,o,o,o,t,w,v,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,q,s,r,o)}}
B.b8F.prototype={
bo(){this.bx()
this.bw()
this.fH()},
k(){var x=this,w=x.bb$
if(w!=null)w.R(x.gfF())
x.bb$=null
x.L()}}
B.b8G.prototype={
ap(){this.aw()
if(this.gAh())this.DM()},
kD(){var x=this.nk$
if(x!=null){x.V()
x.cD()
this.nk$=null}this.rR()}}
B.bAv.prototype={
h(d){var x,w,v=this,u=null,t=v.r
if(t==null)switch(v.e.a){case 0:t=new A.iJ(0,-1)
break
case 1:t=new A.iJ(-1,0)
break
default:t=u}x=v.e
w=x===D.w?Math.max(y.v.a(v.c).gq(),0):u
x=x===D.F?Math.max(y.v.a(v.c).gq(),0):u
return A.eA(new A.ah(t,x,w,v.x,u),D.n,u)}}
var z=a.updateTypes(["~()","~(jj)","~(lj)","~(id)","b9<~>(fo)"])
B.eiV.prototype={
$0(){this.a.afd()},
$S:0}
B.eiW.prototype={
$0(){this.a.afd()},
$S:0}
B.eiX.prototype={
$1(d){return this.a.y5()},
$S:47}
B.eiY.prototype={
$0(){var x,w,v,u=this.a
u.z=u.c.gB()
x=u.f
x.toString
w=y.v
v=y.g
u.r=new A.aS(w.a(new A.aS(w.a(x),new A.eU(C.aa6),y.n.j("aS<bb.T>"))),new A.b4(1,0,v),v.j("aS<bb.T>"))},
$S:0};(function aliases(){var x=B.b8F.prototype
x.b0H=x.k
x=B.b8G.prototype
x.b0I=x.ap})();(function installTearOffs(){var x=a._instance_1u,w=a._instance_0u
var v
x(v=B.aUi.prototype,"gauq","bc1",1)
x(v,"gaur","bc2",2)
w(v,"gbho","bhp",0)
x(v,"gaup","bc0",3)
x(v,"gbhm","W6",4)
w(v,"gbk2","bk3",0)})();(function inheritance(){var x=a.mixinHard,w=a.inheritMany,v=a.inherit
w(A.eh,[B.vJ,B.aVZ])
v(B.aCN,A.i)
v(B.b8F,A.k)
v(B.b8G,B.b8F)
v(B.aUi,B.b8G)
w(A.cS,[B.eiV,B.eiW,B.eiY])
v(B.eiX,A.ck)
v(B.bAv,A.nn)
x(B.b8F,A.eE)
x(B.b8G,A.BR)})()
A.bN(b.typeUniverse,JSON.parse('{"aCN":{"i":[],"b":[]},"aUi":{"k":["aCN"]},"bAv":{"nn":[],"i":[],"b":[]}}'))
var y={v:A.E("bM<p>"),n:A.E("eU"),o:A.E("dm"),z:A.E("aO<k<i>>"),A:A.E("b4<q>"),g:A.E("b4<p>"),e:A.E("w"),q:A.E("~")};(function constants(){C.h8=new A.A(0,560,0,1/0)
C.lD=new B.vJ(1,"horizontal")
C.a57=new B.vJ(2,"endToStart")
C.Rk=new B.vJ(3,"startToEnd")
C.baT=new B.vJ(4,"up")
C.Rl=new B.vJ(5,"down")
C.Rm=new B.vJ(6,"none")
C.aa6=new A.fp(0.4,1,D.bw)
C.cFZ=new A.a6(D.fn,[],A.E("a6<vJ,p>"))
C.Y_=new B.aVZ(0,"none")
C.dmE=new B.aVZ(1,"forward")
C.dmF=new B.aVZ(2,"reverse")})()};
(a=>{a["3LbKhLuqj3UKOna472iiC5d1mtU="]=a.current})($__dart_deferred_initializers__);