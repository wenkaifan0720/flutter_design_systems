((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,A={bAJ:function bAJ(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},bAK:function bAK(){},aNH:function aNH(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},aNG:function aNG(){},apE:function apE(d,e,f){var _=this
_.b=_.w=null
_.c=!1
_.K6$=d
_.dz$=e
_.a1$=f
_.a=null},byo:function byo(d,e,f,g,h,i,j){var _=this
_.fp=d
_.y1=e
_.y2=f
_.bP$=g
_.W$=h
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
hWL(d,e,f,g,h,i){var x=null,w=d==null
w=w?F.hv:x
return new A.aGL(f,new G.DM(g,h,!0,!0,!0,0,D.ayg(),x),i,C.w,!1,d,x,w,x,!1,x,0,x,x,h,F.yX,e,x,x,C.n,C.at,x)},
aGL:function aGL(d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,a0){var _=this
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
bAI:function bAI(d,e,f){this.f=d
this.d=e
this.a=f}},E,D,F,G
B=c[0]
C=c[2]
A=a.updateHolder(c[81],A)
E=c[818]
D=c[250]
F=c[261]
G=c[243]
A.bAJ.prototype={
aTK(d){var x=this.c
return d.Jh(this.d,x,x)},
v(d){var x=this
return"SliverGridGeometry("+C.c.aL(B.a(["scrollOffset: "+B.ak(x.a),"crossAxisOffset: "+B.ak(x.b),"mainAxisExtent: "+B.ak(x.c),"crossAxisExtent: "+B.ak(x.d)],y.x),", ")+")"}}
A.bAK.prototype={}
A.aNH.prototype={
ang(d){var x=this.b
return x>1e-10?this.a*C.i.jI(d,x):0},
anf(d){var x=this.b
if(x>0)return Math.max(0,this.a*C.i.fk(d/x)-1)
return 0},
bfU(d){var x,w,v=this
if(v.f){x=v.c
w=v.e
return v.a*x-d-w-(x-w)}return d},
Tj(d){var x=this,w=x.a,v=C.o.a4(d,w)
return new A.bAJ(C.o.jI(d,w)*x.b,x.bfU(v*x.c),x.d,x.e)},
agY(d){var x
if(d===0)return 0
x=this.b
return x*(C.o.jI(d-1,this.a)+1)-(x-this.d)}}
A.aNG.prototype={}
A.apE.prototype={
v(d){return"crossAxisOffset="+B.ak(this.w)+"; "+this.aZ3(0)}}
A.byo.prototype={
f7(d){if(!(d.b instanceof A.apE))d.b=new A.apE(!1,null,null)},
saUq(d){var x=this
if(x.fp===d)return
if(B.az(d)!==B.az(x.fp)||d.j2(x.fp))x.a5()
x.fp=d},
Jp(d){var x=d.b
x.toString
x=y.t.a(x).w
x.toString
return x},
bn(){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4,a5,a6=this,a7=null,a8=y.z.a(B.F.prototype.gU.call(a6)),a9=a6.y1
a9.R8=!1
x=a8.d
w=x+a8.z
v=w+a8.Q
u=a6.fp.Lz(a8)
t=u.ang(w)
s=isFinite(v)?u.anf(v):a7
if(a6.W$!=null){r=a6.agv(t)
a6.za(r,s!=null?a6.agw(s):0)}else a6.za(0,0)
q=u.Tj(t)
if(a6.W$==null)if(!a6.ZX(t,q.a)){p=u.agY(a9.gz7())
a6.dy=D.nB(a7,!1,a7,a7,p,0,0,0,p,a7)
a9.zj()
return}o=q.a
n=o+q.c
m=a6.W$
m.toString
m=m.b
m.toString
l=y.c
m=l.a(m).b
m.toString
k=m-1
m=y.t
j=a7
for(;k>=t;--k){i=u.Tj(k)
h=i.c
g=a6.ajB(a8.Jh(i.d,h,h))
f=g.b
f.toString
m.a(f)
e=i.a
f.a=e
f.w=i.b
if(j==null)j=g
n=Math.max(n,e+h)}if(j==null){h=a6.W$
h.toString
h.jc(q.aTK(a8))
j=a6.W$
h=j.b
h.toString
m.a(h)
h.a=o
h.w=q.b}h=j.b
h.toString
h=l.a(h).b
h.toString
k=h+1
h=B.T(a6).j("ai.1")
f=s!=null
for(;;){if(!(!f||k<=s)){d=!1
break}i=u.Tj(k)
e=i.c
a0=a8.Jh(i.d,e,e)
a1=j.b
a1.toString
g=h.a(a1).a1$
if(g!=null){a1=g.b
a1.toString
a1=l.a(a1).b
a1.toString
a1=a1!==k}else a1=!0
if(a1){g=a6.ajA(a0,j)
if(g==null){d=!0
break}}else g.jc(a0)
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
a3=d?n:a9.K_(a8,t,m,o,n)
a4=a6.z3(a8,Math.min(x,o),n)
a5=a6.BE(a8,o,n)
a6.dy=D.nB(a5,a3>a4||x>0||a8.f!==0,a7,a7,a3,0,a4,0,a3,a7)
if(a3===n)a9.R8=!0
a9.zj()}}
A.aGL.prototype={
aKQ(d){return new A.bAI(this.to,this.x1,null)}}
A.bAI.prototype={
au(d){var x=new A.byo(this.f,y.v.a(d),B.am(y.e,y.g),0,null,null,B.aN())
x.ar()
return x},
aH(d,e){e.saUq(this.f)},
air(d,e,f,g,h){var x,w
this.aZ4(d,e,f,g,h)
x=this.f.Lz(d)
w=this.d.gmc()
w.toString
w=x.agY(w)
return w}}
var z=a.updateTypes([]);(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.W,[A.bAJ,A.bAK,A.aNG])
w(A.aNH,A.bAK)
w(A.apE,D.lO)
w(A.byo,D.wr)
w(A.aGL,D.azr)
w(A.bAI,D.rN)})()
B.bN(b.typeUniverse,JSON.parse('{"apE":{"lO":[],"HZ":[],"eq":["v"],"A8":[],"dW":[]},"byo":{"wr":[],"f8":[],"ai":["v","lO"],"F":[],"aQ":[],"ai.1":"lO","ai.0":"v"},"aGL":{"l":[],"b":[]},"bAI":{"rN":[],"aP":[],"b":[]}}'))
var y={x:B.E("n<m>"),g:B.E("v"),z:B.E("oa"),t:B.E("apE"),v:B.E("I_"),c:B.E("lO"),e:B.E("u")};(function constants(){E.a4I=new B.iw(0.4,0,1,1)
E.d2w=new B.H(0,40)
E.D4=new B.U(5,"scrolledUnder")})()};
(a=>{a["I6jgAPjqqewFCeJVz22o+W+2kgk="]=a.current})($__dart_deferred_initializers__);