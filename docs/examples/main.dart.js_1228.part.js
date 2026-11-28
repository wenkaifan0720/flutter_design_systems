((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,A={bOn:function bOn(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},bOo:function bOo(){},aX3:function aX3(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},aX2:function aX2(){},awS:function awS(d,e,f){var _=this
_.b=_.w=null
_.c=!1
_.LC$=d
_.dn$=e
_.a5$=f
_.a=null},bM_:function bM_(d,e,f,g,h,i,j){var _=this
_.eC=d
_.y1=e
_.y2=f
_.bX$=g
_.T$=h
_.bh$=i
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
iIM(d,e,f,g,h,i){var x=null,w=d==null
w=w?F.hl:x
return new A.aPe(f,new G.FW(g,h,!0,!0,!0,0,D.aGu(),x),i,C.w,!1,d,x,w,x,!1,x,0,x,x,h,F.Ar,e,x,x,C.m,C.aq,x)},
aPe:function aPe(d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,a0){var _=this
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
bOm:function bOm(d,e,f){this.f=d
this.d=e
this.a=f}},E,G,D,F
B=c[0]
C=c[2]
A=a.updateHolder(c[89],A)
E=c[918]
G=c[271]
D=c[283]
F=c[296]
A.bOn.prototype={
aYN(d){var x=this.c
return d.KO(this.d,x,x)},
D(d){var x=this
return"SliverGridGeometry("+C.c.aM(B.a(["scrollOffset: "+B.am(x.a),"crossAxisOffset: "+B.am(x.b),"mainAxisExtent: "+B.am(x.c),"crossAxisExtent: "+B.am(x.d)],y.x),", ")+")"}}
A.bOo.prototype={}
A.aX3.prototype={
aqY(d){var x=this.b
return x>1e-10?this.a*C.i.jb(d,x):0},
aqX(d){var x=this.b
if(x>0)return Math.max(0,this.a*C.i.fj(d/x)-1)
return 0},
bmC(d){var x,w,v=this
if(v.f){x=v.c
w=v.e
return v.a*x-d-w-(x-w)}return d},
Vp(d){var x=this,w=x.a,v=C.o.a8(d,w)
return new A.bOn(C.o.jb(d,w)*x.b,x.bmC(v*x.c),x.d,x.e)},
ako(d){var x
if(d===0)return 0
x=this.b
return x*(C.o.jb(d-1,this.a)+1)-(x-this.d)}}
A.aX2.prototype={}
A.awS.prototype={
D(d){return"crossAxisOffset="+B.am(this.w)+"; "+this.b3a(0)}}
A.bM_.prototype={
eH(d){if(!(d.b instanceof A.awS))d.b=new A.awS(!1,null,null)},
saZv(d){var x=this
if(x.eC===d)return
if(B.aI(d)!==B.aI(x.eC)||d.jn(x.eC))x.a6()
x.eC=d},
KY(d){var x=d.b
x.toString
x=y.t.a(x).w
x.toString
return x},
bp(){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4,a5,a6=this,a7=null,a8=y.z.a(B.H.prototype.gW.call(a6)),a9=a6.y1
a9.R8=!1
x=a8.d
w=x+a8.z
v=w+a8.Q
u=a6.eC.Na(a8)
t=u.aqY(w)
s=isFinite(v)?u.aqX(v):a7
if(a6.T$!=null){r=a6.ajY(t)
a6.Aa(r,s!=null?a6.ajZ(s):0)}else a6.Aa(0,0)
q=u.Vp(t)
if(a6.T$==null)if(!a6.a1j(t,q.a)){p=u.ako(a9.gA6())
a6.dy=D.p2(a7,!1,a7,a7,p,0,0,0,p,a7)
a9.Ai()
return}o=q.a
n=o+q.c
m=a6.T$
m.toString
m=m.b
m.toString
l=y.c
m=l.a(m).b
m.toString
k=m-1
m=y.t
j=a7
for(;k>=t;--k){i=u.Vp(k)
h=i.c
g=a6.anf(a8.KO(i.d,h,h))
f=g.b
f.toString
m.a(f)
e=i.a
f.a=e
f.w=i.b
if(j==null)j=g
n=Math.max(n,e+h)}if(j==null){h=a6.T$
h.toString
h.jN(q.aYN(a8))
j=a6.T$
h=j.b
h.toString
m.a(h)
h.a=o
h.w=q.b}h=j.b
h.toString
h=l.a(h).b
h.toString
k=h+1
h=B.a0(a6).k("ai.1")
f=s!=null
for(;;){if(!(!f||k<=s)){d=!1
break}i=u.Vp(k)
e=i.c
a0=a8.KO(i.d,e,e)
a1=j.b
a1.toString
g=h.a(a1).a5$
if(g!=null){a1=g.b
a1.toString
a1=l.a(a1).b
a1.toString
a1=a1!==k}else a1=!0
if(a1){g=a6.ane(a0,j)
if(g==null){d=!0
break}}else g.jN(a0)
a1=g.b
a1.toString
m.a(a1)
a2=i.a
a1.a=a2
a1.w=i.b
n=Math.max(n,a2+e);++k
j=g}m=a6.bh$
m.toString
m=m.b
m.toString
m=l.a(m).b
m.toString
a3=d?n:a9.Ly(a8,t,m,o,n)
a4=a6.A1(a8,Math.min(x,o),n)
a5=a6.CG(a8,o,n)
a6.dy=D.p2(a5,a3>a4||x>0||a8.f!==0,a7,a7,a3,0,a4,0,a3,a7)
if(a3===n)a9.R8=!0
a9.Ai()}}
A.aPe.prototype={
aPR(d){return new A.bOm(this.to,this.x1,null)}}
A.bOm.prototype={
aA(d){var x=new A.bM_(this.f,y.v.a(d),B.an(y.e,y.g),0,null,null,B.aN())
x.az()
return x},
aI(d,e){e.saZv(this.f)},
am1(d,e,f,g,h){var x,w
this.b3b(d,e,f,g,h)
x=this.f.Na(d)
w=this.d.gn7()
w.toString
w=x.ako(w)
return w}}
var z=a.updateTypes([]);(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.a_,[A.bOn,A.bOo,A.aX2])
w(A.aX3,A.bOo)
w(A.awS,D.mT)
w(A.bM_,D.yu)
w(A.aPe,D.aHG)
w(A.bOm,D.uj)})()
B.bP(b.typeUniverse,JSON.parse('{"awS":{"mT":[],"KI":[],"ey":["w"],"C6":[],"e1":[]},"bM_":{"yu":[],"fD":[],"ai":["w","mT"],"H":[],"aS":[],"ai.1":"mT","ai.0":"w"},"aPe":{"k":[],"b":[]},"bOm":{"uj":[],"aQ":[],"b":[]}}'))
var y={x:B.G("o<n>"),g:B.G("w"),z:B.G("pA"),t:B.G("awS"),v:B.G("KK"),c:B.G("mT"),e:B.G("v")};(function constants(){E.ab9=new B.jq(0.4,0,1,1)
E.auj=new B.cA([C.fc,C.Hs,C.fD,C.Hr],B.G("cA<f0,bA>"))
E.dq1=new B.I(0,40)
E.EJ=new B.V(5,"scrolledUnder")})()};
(a=>{a["k96hnfUh567x4wUvYv0AdbbEtCs="]=a.current})($__dart_deferred_initializers__);