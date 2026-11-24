((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,A={bKK:function bKK(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},bKL:function bKL(){},aUm:function aUm(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},aUl:function aUl(){},auI:function auI(d,e,f){var _=this
_.b=_.w=null
_.c=!1
_.KL$=d
_.dJ$=e
_.a4$=f
_.a=null},bIo:function bIo(d,e,f,g,h,i,j){var _=this
_.ey=d
_.y1=e
_.y2=f
_.bZ$=g
_.V$=h
_.bq$=i
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
ivN(d,e,f,g,h,i){var x=null,w=d==null
w=w?F.hc:x
return new A.aMD(f,new G.EJ(g,h,!0,!0,!0,0,D.aDZ(),x),i,C.w,!1,d,x,w,x,!1,x,0,x,x,h,F.zv,e,x,x,C.m,C.an,x)},
aMD:function aMD(d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,a0){var _=this
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
bKJ:function bKJ(d,e,f){this.f=d
this.d=e
this.a=f}},E,D,F,G
B=c[0]
C=c[2]
A=a.updateHolder(c[86],A)
E=c[875]
D=c[264]
F=c[277]
G=c[253]
A.bKK.prototype={
aW_(d){var x=this.c
return d.JY(this.d,x,x)},
A(d){var x=this
return"SliverGridGeometry("+C.c.aM(B.a(["scrollOffset: "+B.an(x.a),"crossAxisOffset: "+B.an(x.b),"mainAxisExtent: "+B.an(x.c),"crossAxisExtent: "+B.an(x.d)],y.x),", ")+")"}}
A.bKL.prototype={}
A.aUm.prototype={
aoM(d){var x=this.b
return x>1e-10?this.a*C.i.je(d,x):0},
aoL(d){var x=this.b
if(x>0)return Math.max(0,this.a*C.i.fj(d/x)-1)
return 0},
bj5(d){var x,w,v=this
if(v.f){x=v.c
w=v.e
return v.a*x-d-w-(x-w)}return d},
Ud(d){var x=this,w=x.a,v=C.o.a5(d,w)
return new A.bKK(C.o.je(d,w)*x.b,x.bj5(v*x.c),x.d,x.e)},
aie(d){var x
if(d===0)return 0
x=this.b
return x*(C.o.je(d-1,this.a)+1)-(x-this.d)}}
A.aUl.prototype={}
A.auI.prototype={
A(d){return"crossAxisOffset="+B.an(this.w)+"; "+this.b0m(0)}}
A.bIo.prototype={
f0(d){if(!(d.b instanceof A.auI))d.b=new A.auI(!1,null,null)},
saWH(d){var x=this
if(x.ey===d)return
if(B.aG(d)!==B.aG(x.ey)||d.jd(x.ey))x.a6()
x.ey=d},
K6(d){var x=d.b
x.toString
x=y.t.a(x).w
x.toString
return x},
bs(){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4,a5,a6=this,a7=null,a8=y.z.a(B.G.prototype.gW.call(a6)),a9=a6.y1
a9.R8=!1
x=a8.d
w=x+a8.z
v=w+a8.Q
u=a6.ey.Me(a8)
t=u.aoM(w)
s=isFinite(v)?u.aoL(v):a7
if(a6.V$!=null){r=a6.ahN(t)
a6.zF(r,s!=null?a6.ahO(s):0)}else a6.zF(0,0)
q=u.Ud(t)
if(a6.V$==null)if(!a6.a_Y(t,q.a)){p=u.aie(a9.gzC())
a6.dy=D.op(a7,!1,a7,a7,p,0,0,0,p,a7)
a9.zN()
return}o=q.a
n=o+q.c
m=a6.V$
m.toString
m=m.b
m.toString
l=y.c
m=l.a(m).b
m.toString
k=m-1
m=y.t
j=a7
for(;k>=t;--k){i=u.Ud(k)
h=i.c
g=a6.al0(a8.JY(i.d,h,h))
f=g.b
f.toString
m.a(f)
e=i.a
f.a=e
f.w=i.b
if(j==null)j=g
n=Math.max(n,e+h)}if(j==null){h=a6.V$
h.toString
h.jB(q.aW_(a8))
j=a6.V$
h=j.b
h.toString
m.a(h)
h.a=o
h.w=q.b}h=j.b
h.toString
h=l.a(h).b
h.toString
k=h+1
h=B.Y(a6).j("al.1")
f=s!=null
for(;;){if(!(!f||k<=s)){d=!1
break}i=u.Ud(k)
e=i.c
a0=a8.JY(i.d,e,e)
a1=j.b
a1.toString
g=h.a(a1).a4$
if(g!=null){a1=g.b
a1.toString
a1=l.a(a1).b
a1.toString
a1=a1!==k}else a1=!0
if(a1){g=a6.al_(a0,j)
if(g==null){d=!0
break}}else g.jB(a0)
a1=g.b
a1.toString
m.a(a1)
a2=i.a
a1.a=a2
a1.w=i.b
n=Math.max(n,a2+e);++k
j=g}m=a6.bq$
m.toString
m=m.b
m.toString
m=l.a(m).b
m.toString
a3=d?n:a9.KG(a8,t,m,o,n)
a4=a6.zx(a8,Math.min(x,o),n)
a5=a6.C4(a8,o,n)
a6.dy=D.op(a5,a3>a4||x>0||a8.f!==0,a7,a7,a3,0,a4,0,a3,a7)
if(a3===n)a9.R8=!0
a9.zN()}}
A.aMD.prototype={
aN2(d){return new A.bKJ(this.to,this.x1,null)}}
A.bKJ.prototype={
aw(d){var x=new A.bIo(this.f,y.v.a(d),B.ao(y.e,y.g),0,null,null,B.aM())
x.av()
return x},
aH(d,e){e.saWH(this.f)},
ajM(d,e,f,g,h){var x,w
this.b0n(d,e,f,g,h)
x=this.f.Me(d)
w=this.d.gmz()
w.toString
w=x.aie(w)
return w}}
var z=a.updateTypes([]);(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.X,[A.bKK,A.bKL,A.aUl])
w(A.aUm,A.bKL)
w(A.auI,D.mr)
w(A.bIo,D.xA)
w(A.aMD,D.aFa)
w(A.bKJ,D.ty)})()
B.bN(b.typeUniverse,JSON.parse('{"auI":{"mr":[],"Jj":[],"ey":["v"],"B2":[],"e5":[]},"bIo":{"xA":[],"fq":[],"al":["v","mr"],"G":[],"aQ":[],"al.1":"mr","al.0":"v"},"aMD":{"j":[],"b":[]},"bKJ":{"ty":[],"aP":[],"b":[]}}'))
var y={x:B.F("o<m>"),g:B.F("v"),z:B.F("oY"),t:B.F("auI"),v:B.F("Jl"),c:B.F("mr"),e:B.F("u")};(function constants(){E.a6m=new B.iZ(0.4,0,1,1)
E.apr=new B.cn([C.f5,C.Gd,C.fy,C.Gc],B.F("cn<eS,bv>"))
E.d8O=new B.H(0,40)
E.DN=new B.T(5,"scrolledUnder")})()};
(a=>{a["BV2/cgaOwKW2FnbJFkBH4lVJs7k="]=a.current})($__dart_deferred_initializers__);