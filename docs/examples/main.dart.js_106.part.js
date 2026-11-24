((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var A,C,B={
j0R(d){var x,w,v
A:{if(d instanceof A.pz){x=d.C
w=x.r
v=x.w
v.toString
x=new A.ckH([w,v,x.x,x.Q,d.L,d.aE,x.z,x.as,x.at,x.ax,d.bZ$,y.a.a(A.G.prototype.gW.call(d)),d.gD()])
break A}if(d instanceof D.m_){x=d.bD
w=x.r
v=x.w
v.toString
x=new A.ckG([w,v,x.x,d.ds,x.z,x.as,x.at,x.ax,d.ao,y.a.a(A.G.prototype.gW.call(d)),d.gD()])
break A}x=new A.x(y.a.a(A.G.prototype.gW.call(d)),d.gD())
break A}return x},
b4:function b4(d,e,f){this.e=d
this.c=e
this.a=f},
bHY:function bHY(d,e,f,g,h){var _=this
_.H=d
_.cf=_.bE=_.ao=_.a7=null
_.tY$=e
_.F$=f
_.dy=g
_.b=_.fy=null
_.c=0
_.y=_.d=null
_.z=!0
_.Q=null
_.as=!1
_.at=null
_.ay=$
_.ch=h
_.CW=!1
_.cx=$
_.cy=!0
_.db=!1
_.dx=$},
dFc:function dFc(d){this.a=d},
clH:function clH(){},
jkp(d){var x,w={}
w.a=w.b=null
new B.hMF(w).$1(d)
x=w.b
return x==null?w.a:x},
jkg(d){var x=d instanceof A.pz
if(x&&d.bZ$>0)return!1
A:{if(x){x=d.aoE(C.tK)
break A}if(d instanceof D.m_){x=d.ds===1?d.bD.iU().gbF():0
break A}x=0
break A}return x>0&&d.gD().b<x*1.5},
jko(d){var x,w
A:{if(d instanceof A.pz){x=d.C
w=x.x
x=x.e
x.toString
x=B.iH_(x)
x=w.a8(x==null?14:x)
break A}if(d instanceof D.m_){x=d.bD
w=x.x
x=x.e
x=x==null?null:B.iH_(x)
x=w.a8(x==null?14:x)
break A}x=14
break A}return x},
jiX(d,e){var x,w,v=B.jkq(d)
if(v==null)return null
x=B.jko(d)
w=Math.floor(v+0.5)
return new A.ckM(w,w-e*x)},
jkq(d){var x,w,v,u,t,s,r,q,p,o,n,m,l,k=null,j=d instanceof A.pz
if(j&&d.bZ$>0||d.fy==null)return k
A:{if(j){j=d.C
w=j.e
w.toString
v=j.r
u=j.w
u.toString
t=j.x
s=j.Q
r=d.L===C.V?"\u2026":k
q=j.z
p=j.as
o=j.at
o=A.cU(r,q,s,p,w,v,u,j.ax,t,o)
t=y.a
j=t.a(A.G.prototype.gW.call(d))
w=d.aE||d.L===C.V?t.a(A.G.prototype.gW.call(d)).b:1/0
o.n2(w,j.a)
j=o
break A}n=d instanceof D.m_
m=k
if(n){m=d.bD.e
j=m
j=j!=null}else j=!1
if(j){l=n?m:d.bD.e
if(l==null)l=y.k.a(l)
j=d.bD
w=j.r
v=j.w
v.toString
u=j.x
t=d.ds===1?1:k
s=j.z
r=j.as
q=j.at
q=A.cU(k,s,t,r,l,w,v,j.ax,u,q)
q.n1(d.ds===1?1/0:Math.max(0,y.a.a(A.G.prototype.gW.call(d)).b-d.ao-1))
j=q
break A}j=k
break A}x=j
if(x==null)return d.hF(y.a.a(A.G.prototype.gW.call(d)),C.ao)
try{j=x.b.a.ms(C.ao)
return j}finally{x.k()}},
iH_(d){var x={}
x.a=null
new B.hHh(x).$2(d,null)
x=x.a
if(x==null){x=d.a
x=x==null?null:x.r}return x},
jkf(d){var x,w=A.aI(new A.lb(d),y.i.j("aJ.E"))
if(w.length!==1)return!1
x=C.c.gc9(w)
return x>=57344&&x<=63743||x>=983040},
hMF:function hMF(d){this.a=d},
hHh:function hHh(d){this.a=d}},E,D
A=c[0]
C=c[2]
B=a.updateHolder(c[238],B)
E=c[906]
D=c[264]
B.b4.prototype={
aw(d){var x=new B.bHY(this.e,!1,null,new A.aX(),A.aM())
x.av()
x.sbh(null)
return x},
aH(d,e){e.sbN8(this.e)}}
B.bHY.prototype={
sbN8(d){var x=this
if(d===x.H)return
x.H=d
x.atw()
x.bp()
x.ck()},
b9N(d){var x,w,v,u=this
A:{if(d instanceof A.pz){x=d.C.e
x.toString
break A}if(d instanceof D.m_){w=d.bD.e
x=w
break A}x=null
break A}v=B.j0R(d)
if(d===u.a7&&x==u.ao&&v.i(0,u.bE))return u.cf
u.a7=d
u.ao=x
u.bE=v
return u.cf=B.jiX(d,u.H)},
atw(){var x=this
x.cf=x.bE=x.ao=x.a7=null},
bs(){this.atw()
this.m7()},
gaev(){var x,w,v,u,t,s,r=this,q=r.F$
if(q==null||q.fy==null||r.fy==null)return 0
x=B.jkp(q)
if(x==null||!B.jkg(x))return 0
w=r.b9N(x)
if(w==null)return 0
v=x.bX(q)
u=A.dt(v,new A.t(0,w.b))
t=A.dt(v,new A.t(0,w.a))
s=r.gD().b/2-(u.b+t.b)/2
return isFinite(s)?s:0},
T(d,e){var x=this.F$
if(x!=null)d.f9(x,new A.t(e.a+0,e.b+this.gaev()))},
cL(d,e){var x=this.F$
if(x==null)return!1
return d.iq(new B.dFc(x),new A.t(0,this.gaev()),e)},
hJ(d,e){e.io(0,this.gaev(),0,1)}}
B.clH.prototype={
aC(d){this.qq(d)
$.hM.hZ$.a.G(0,this.grs())},
al(){$.hM.hZ$.a.aj(0,this.grs())
this.nc()}}
var z=a.updateTypes([])
B.dFc.prototype={
$2(d,e){return this.a.cV(d,e)},
$S:17}
B.hMF.prototype={
$1(d){var x=this.a
if(x.b!=null)return
if(d instanceof D.m_&&d.fy!=null){x.b=d
return}if(x.a==null&&d instanceof A.pz&&d.fy!=null&&!B.jkf(d.C.e.vo(!1)))x.a=d
d.dY(this)},
$S:26}
B.hHh.prototype={
$2(d,e){var x,w,v=d.a,u=v==null?null:v.r
if(u==null)u=e
if(d instanceof A.dr){v=d.b
v=v==null?null:v.length!==0
if(v===!0){this.a.a=u
return!1}v=d.c
if(v==null)v=E.cBX
x=v.length
w=0
for(;w<v.length;v.length===x||(0,A.D)(v),++w)if(!this.$2(v[w],u))return!1}return!0},
$S:1309};(function inheritance(){var x=a.mixinHard,w=a.inherit,v=a.inheritMany
w(B.b4,A.aY)
w(B.clH,A.iI)
w(B.bHY,B.clH)
v(A.dj,[B.dFc,B.hHh])
w(B.hMF,A.cm)
x(B.clH,A.BN)})()
A.bN(b.typeUniverse,JSON.parse('{"b4":{"aY":[],"aP":[],"b":[]},"bHY":{"v":[],"bh":["v"],"G":[],"aQ":[]}}'))
var y={a:A.F("A"),k:A.F("ho"),i:A.F("lb")};(function constants(){var x=a.makeConstList
E.cBX=x([],A.F("o<ho>"))})()};
(a=>{a["BCF3wBPjpUiGARJtaC8D9TanKLc="]=a.current})($__dart_deferred_initializers__);