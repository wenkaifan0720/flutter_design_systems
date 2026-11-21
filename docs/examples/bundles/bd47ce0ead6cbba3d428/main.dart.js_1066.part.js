((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,A={bzr:function bzr(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},bzs:function bzs(){},aNd:function aNd(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},aNc:function aNc(){},apm:function apm(d,e,f){var _=this
_.b=_.w=null
_.c=!1
_.K2$=d
_.dC$=e
_.a2$=f
_.a=null},bx5:function bx5(d,e,f,g,h,i,j){var _=this
_.fo=d
_.y1=e
_.y2=f
_.bU$=g
_.X$=h
_.bz$=i
_.b=_.dy=null
_.c=0
_.y=_.d=null
_.z=!0
_.Q=null
_.as=!1
_.at=null
_.ay=$
_.ch=j
_.CW=!1
_.cx=$
_.cy=!0
_.db=!1
_.dx=$},
hTi(d,e,f,g,h,i){var x=null,w=d==null
w=w?F.hw:x
return new A.aGE(f,new G.DA(g,h,!0,!0,!0,0,D.axO(),x),i,C.v,!1,d,x,w,x,!1,x,0,x,x,h,F.yV,e,x,x,C.m,C.aE,x)},
aGE:function aGE(d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,a0){var _=this
_.to=d
_.x1=e
_.dx=f
_.c=g
_.d=h
_.e=i
_.f=j
_.r=k
_.w=l
_.x=m
_.y=n
_.z=o
_.Q=p
_.as=q
_.at=r
_.ax=s
_.ay=t
_.ch=u
_.CW=v
_.cx=w
_.cy=x
_.a=a0},
bzq:function bzq(d,e,f){this.f=d
this.d=e
this.a=f}},E,D,F,G
B=c[0]
C=c[2]
A=a.updateHolder(c[80],A)
E=c[808]
D=c[242]
F=c[253]
G=c[235]
A.bzr.prototype={
aST(d){var x=this.c
return d.Jd(this.d,x,x)},
v(d){var x=this
return"SliverGridGeometry("+C.c.aK(B.a(["scrollOffset: "+B.al(x.a),"crossAxisOffset: "+B.al(x.b),"mainAxisExtent: "+B.al(x.c),"crossAxisExtent: "+B.al(x.d)],y.x),", ")+")"}}
A.bzs.prototype={}
A.aNd.prototype={
amP(d){var x=this.b
return x>1e-10?this.a*C.i.jC(d,x):0},
amO(d){var x=this.b
if(x>0)return Math.max(0,this.a*C.i.fi(d/x)-1)
return 0},
beU(d){var x,w,v=this
if(v.f){x=v.c
w=v.e
return v.a*x-d-w-(x-w)}return d},
Tb(d){var x=this,w=x.a,v=C.o.a3(d,w)
return new A.bzr(C.o.jC(d,w)*x.b,x.beU(v*x.c),x.d,x.e)},
ags(d){var x
if(d===0)return 0
x=this.b
return x*(C.o.jC(d-1,this.a)+1)-(x-this.d)}}
A.aNc.prototype={}
A.apm.prototype={
v(d){return"crossAxisOffset="+B.al(this.w)+"; "+this.aYd(0)}}
A.bx5.prototype={
fb(d){if(!(d.b instanceof A.apm))d.b=new A.apm(!1,null,null)},
saTz(d){var x=this
if(x.fo===d)return
if(B.az(d)!==B.az(x.fo)||d.j_(x.fo))x.a6()
x.fo=d},
Jl(d){var x=d.b
x.toString
x=y.t.a(x).w
x.toString
return x},
bn(){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4,a5,a6=this,a7=null,a8=y.z.a(B.F.prototype.gU.call(a6)),a9=a6.y1
a9.R8=!1
x=a8.d
w=x+a8.z
v=w+a8.Q
u=a6.fo.Ls(a8)
t=u.amP(w)
s=isFinite(v)?u.amO(v):a7
if(a6.X$!=null){r=a6.ag_(t)
a6.z3(r,s!=null?a6.ag0(s):0)}else a6.z3(0,0)
q=u.Tb(t)
if(a6.X$==null)if(!a6.ZO(t,q.a)){p=u.ags(a9.gz0())
a6.dy=D.nu(a7,!1,a7,a7,p,0,0,0,p,a7)
a9.zc()
return}o=q.a
n=o+q.c
m=a6.X$
m.toString
m=m.b
m.toString
l=y.c
m=l.a(m).b
m.toString
k=m-1
m=y.t
j=a7
for(;k>=t;--k){i=u.Tb(k)
h=i.c
g=a6.aj7(a8.Jd(i.d,h,h))
f=g.b
f.toString
m.a(f)
e=i.a
f.a=e
f.w=i.b
if(j==null)j=g
n=Math.max(n,e+h)}if(j==null){h=a6.X$
h.toString
h.j9(q.aST(a8))
j=a6.X$
h=j.b
h.toString
m.a(h)
h.a=o
h.w=q.b}h=j.b
h.toString
h=l.a(h).b
h.toString
k=h+1
h=B.W(a6).j("am.1")
f=s!=null
for(;;){if(!(!f||k<=s)){d=!1
break}i=u.Tb(k)
e=i.c
a0=a8.Jd(i.d,e,e)
a1=j.b
a1.toString
g=h.a(a1).a2$
if(g!=null){a1=g.b
a1.toString
a1=l.a(a1).b
a1.toString
a1=a1!==k}else a1=!0
if(a1){g=a6.aj6(a0,j)
if(g==null){d=!0
break}}else g.j9(a0)
a1=g.b
a1.toString
m.a(a1)
a2=i.a
a1.a=a2
a1.w=i.b
n=Math.max(n,a2+e);++k
j=g}m=a6.bz$
m.toString
m=m.b
m.toString
m=l.a(m).b
m.toString
a3=d?n:a9.JW(a8,t,m,o,n)
a4=a6.yX(a8,Math.min(x,o),n)
a5=a6.Bx(a8,o,n)
a6.dy=D.nu(a5,a3>a4||x>0||a8.f!==0,a7,a7,a3,0,a4,0,a3,a7)
if(a3===n)a9.R8=!0
a9.zc()}}
A.aGE.prototype={
aJX(d){return new A.bzq(this.to,this.x1,null)}}
A.bzq.prototype={
av(d){var x=new A.bx5(this.f,y.v.a(d),B.aj(y.e,y.g),0,null,null,B.aO())
x.au()
return x},
aH(d,e){e.saTz(this.f)},
ahV(d,e,f,g,h){var x,w
this.aYe(d,e,f,g,h)
x=this.f.Ls(d)
w=this.d.gm8()
w.toString
w=x.ags(w)
return w}}
var z=a.updateTypes([]);(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.V,[A.bzr,A.bzs,A.aNc])
w(A.aNd,A.bzs)
w(A.apm,D.lI)
w(A.bx5,D.wk)
w(A.aGE,D.ayZ)
w(A.bzq,D.rI)})()
B.bN(b.typeUniverse,JSON.parse('{"apm":{"lI":[],"HK":[],"et":["v"],"A5":[],"e0":[]},"bx5":{"wk":[],"f6":[],"am":["v","lI"],"F":[],"aQ":[],"am.1":"lI","am.0":"v"},"aGE":{"j":[],"b":[]},"bzq":{"rI":[],"aP":[],"b":[]}}'))
var y={x:B.D("n<m>"),g:B.D("v"),z:B.D("o2"),t:B.D("apm"),v:B.D("HL"),c:B.D("lI"),e:B.D("u")};(function constants(){E.a4y=new B.is(0.4,0,1,1)
E.d2C=new B.H(0,40)
E.D0=new B.U(5,"scrolledUnder")})()};
(a=>{a["gDit+CtaBnj4Ez744isxzJ5SugU="]=a.current})($__dart_deferred_initializers__);