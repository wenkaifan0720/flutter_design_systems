((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,A={bKA:function bKA(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},bKB:function bKB(){},aUh:function aUh(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},aUg:function aUg(){},auH:function auH(d,e,f){var _=this
_.b=_.w=null
_.c=!1
_.KI$=d
_.dH$=e
_.a4$=f
_.a=null},bIf:function bIf(d,e,f,g,h,i,j){var _=this
_.eu=d
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
iv7(d,e,f,g,h,i){var x=null,w=d==null
w=w?F.hd:x
return new A.aMy(f,new G.EI(g,h,!0,!0,!0,0,D.aDU(),x),i,C.w,!1,d,x,w,x,!1,x,0,x,x,h,F.zv,e,x,x,C.m,C.an,x)},
aMy:function aMy(d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,a0){var _=this
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
bKz:function bKz(d,e,f){this.f=d
this.d=e
this.a=f}},E,D,F,G
B=c[0]
C=c[2]
A=a.updateHolder(c[86],A)
E=c[876]
D=c[264]
F=c[277]
G=c[253]
A.bKA.prototype={
aVX(d){var x=this.c
return d.JU(this.d,x,x)},
A(d){var x=this
return"SliverGridGeometry("+C.c.aM(B.a(["scrollOffset: "+B.an(x.a),"crossAxisOffset: "+B.an(x.b),"mainAxisExtent: "+B.an(x.c),"crossAxisExtent: "+B.an(x.d)],y.x),", ")+")"}}
A.bKB.prototype={}
A.aUh.prototype={
aoJ(d){var x=this.b
return x>1e-10?this.a*C.i.jc(d,x):0},
aoI(d){var x=this.b
if(x>0)return Math.max(0,this.a*C.i.fh(d/x)-1)
return 0},
biZ(d){var x,w,v=this
if(v.f){x=v.c
w=v.e
return v.a*x-d-w-(x-w)}return d},
Ub(d){var x=this,w=x.a,v=C.o.a5(d,w)
return new A.bKA(C.o.jc(d,w)*x.b,x.biZ(v*x.c),x.d,x.e)},
aia(d){var x
if(d===0)return 0
x=this.b
return x*(C.o.jc(d-1,this.a)+1)-(x-this.d)}}
A.aUg.prototype={}
A.auH.prototype={
A(d){return"crossAxisOffset="+B.an(this.w)+"; "+this.b0i(0)}}
A.bIf.prototype={
eZ(d){if(!(d.b instanceof A.auH))d.b=new A.auH(!1,null,null)},
saWE(d){var x=this
if(x.eu===d)return
if(B.aG(d)!==B.aG(x.eu)||d.jb(x.eu))x.a6()
x.eu=d},
K2(d){var x=d.b
x.toString
x=y.t.a(x).w
x.toString
return x},
bs(){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4,a5,a6=this,a7=null,a8=y.z.a(B.G.prototype.gW.call(a6)),a9=a6.y1
a9.R8=!1
x=a8.d
w=x+a8.z
v=w+a8.Q
u=a6.eu.Mc(a8)
t=u.aoJ(w)
s=isFinite(v)?u.aoI(v):a7
if(a6.V$!=null){r=a6.ahJ(t)
a6.zD(r,s!=null?a6.ahK(s):0)}else a6.zD(0,0)
q=u.Ub(t)
if(a6.V$==null)if(!a6.a_V(t,q.a)){p=u.aia(a9.gzA())
a6.dy=D.oo(a7,!1,a7,a7,p,0,0,0,p,a7)
a9.zL()
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
for(;k>=t;--k){i=u.Ub(k)
h=i.c
g=a6.akY(a8.JU(i.d,h,h))
f=g.b
f.toString
m.a(f)
e=i.a
f.a=e
f.w=i.b
if(j==null)j=g
n=Math.max(n,e+h)}if(j==null){h=a6.V$
h.toString
h.jy(q.aVX(a8))
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
break}i=u.Ub(k)
e=i.c
a0=a8.JU(i.d,e,e)
a1=j.b
a1.toString
g=h.a(a1).a4$
if(g!=null){a1=g.b
a1.toString
a1=l.a(a1).b
a1.toString
a1=a1!==k}else a1=!0
if(a1){g=a6.akX(a0,j)
if(g==null){d=!0
break}}else g.jy(a0)
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
a3=d?n:a9.KD(a8,t,m,o,n)
a4=a6.zv(a8,Math.min(x,o),n)
a5=a6.C2(a8,o,n)
a6.dy=D.oo(a5,a3>a4||x>0||a8.f!==0,a7,a7,a3,0,a4,0,a3,a7)
if(a3===n)a9.R8=!0
a9.zL()}}
A.aMy.prototype={
aN_(d){return new A.bKz(this.to,this.x1,null)}}
A.bKz.prototype={
aw(d){var x=new A.bIf(this.f,y.v.a(d),B.ao(y.e,y.g),0,null,null,B.aM())
x.av()
return x},
aH(d,e){e.saWE(this.f)},
ajJ(d,e,f,g,h){var x,w
this.b0j(d,e,f,g,h)
x=this.f.Mc(d)
w=this.d.gmx()
w.toString
w=x.aia(w)
return w}}
var z=a.updateTypes([]);(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.X,[A.bKA,A.bKB,A.aUg])
w(A.aUh,A.bKB)
w(A.auH,D.mp)
w(A.bIf,D.xy)
w(A.aMy,D.aF5)
w(A.bKz,D.ty)})()
B.bM(b.typeUniverse,JSON.parse('{"auH":{"mp":[],"Jh":[],"ey":["v"],"B1":[],"e7":[]},"bIf":{"xy":[],"fr":[],"al":["v","mp"],"G":[],"aQ":[],"al.1":"mp","al.0":"v"},"aMy":{"j":[],"b":[]},"bKz":{"ty":[],"aP":[],"b":[]}}'))
var y={x:B.F("o<m>"),g:B.F("v"),z:B.F("oY"),t:B.F("auH"),v:B.F("Jj"),c:B.F("mp"),e:B.F("u")};(function constants(){E.a6o=new B.iZ(0.4,0,1,1)
E.aps=new B.cn([C.f5,C.Gd,C.fy,C.Gc],B.F("cn<eS,bv>"))
E.d8M=new B.H(0,40)
E.DN=new B.T(5,"scrolledUnder")})()};
(a=>{a["hfLkaEm7t5shrCSg1kUD0x2EuH8="]=a.current})($__dart_deferred_initializers__);