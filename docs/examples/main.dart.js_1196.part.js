((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,A={bLj:function bLj(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},bLk:function bLk(){},aUI:function aUI(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},aUH:function aUH(){},av5:function av5(d,e,f){var _=this
_.b=_.w=null
_.c=!1
_.Le$=d
_.d3$=e
_.a5$=f
_.a=null},bIX:function bIX(d,e,f,g,h,i,j){var _=this
_.ev=d
_.y1=e
_.y2=f
_.bV$=g
_.W$=h
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
iz1(d,e,f,g,h,i){var x=null,w=d==null
w=w?F.hg:x
return new A.aN1(f,new G.EU(g,h,!0,!0,!0,0,D.aEs(),x),i,C.w,!1,d,x,w,x,!1,x,0,x,x,h,F.zJ,e,x,x,C.m,C.ap,x)},
aN1:function aN1(d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,a0){var _=this
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
bLi:function bLi(d,e,f){this.f=d
this.d=e
this.a=f}},E,D,F,G
B=c[0]
C=c[2]
A=a.updateHolder(c[86],A)
E=c[888]
D=c[274]
F=c[287]
G=c[262]
A.bLj.prototype={
aWM(d){var x=this.c
return d.Km(this.d,x,x)},
B(d){var x=this
return"SliverGridGeometry("+C.c.aK(B.a(["scrollOffset: "+B.an(x.a),"crossAxisOffset: "+B.an(x.b),"mainAxisExtent: "+B.an(x.c),"crossAxisExtent: "+B.an(x.d)],y.x),", ")+")"}}
A.bLk.prototype={}
A.aUI.prototype={
apI(d){var x=this.b
return x>1e-10?this.a*C.i.jj(d,x):0},
apH(d){var x=this.b
if(x>0)return Math.max(0,this.a*C.i.fn(d/x)-1)
return 0},
bjV(d){var x,w,v=this
if(v.f){x=v.c
w=v.e
return v.a*x-d-w-(x-w)}return d},
US(d){var x=this,w=x.a,v=C.o.a7(d,w)
return new A.bLj(C.o.jj(d,w)*x.b,x.bjV(v*x.c),x.d,x.e)},
ajp(d){var x
if(d===0)return 0
x=this.b
return x*(C.o.jj(d-1,this.a)+1)-(x-this.d)}}
A.aUH.prototype={}
A.av5.prototype={
B(d){return"crossAxisOffset="+B.an(this.w)+"; "+this.b18(0)}}
A.bIX.prototype={
eZ(d){if(!(d.b instanceof A.av5))d.b=new A.av5(!1,null,null)},
saXt(d){var x=this
if(x.ev===d)return
if(B.aF(d)!==B.aF(x.ev)||d.ji(x.ev))x.a6()
x.ev=d},
Kv(d){var x=d.b
x.toString
x=y.t.a(x).w
x.toString
return x},
bu(){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4,a5,a6=this,a7=null,a8=y.z.a(B.H.prototype.gX.call(a6)),a9=a6.y1
a9.R8=!1
x=a8.d
w=x+a8.z
v=w+a8.Q
u=a6.ev.MK(a8)
t=u.apI(w)
s=isFinite(v)?u.apH(v):a7
if(a6.W$!=null){r=a6.aiZ(t)
a6.A2(r,s!=null?a6.aj_(s):0)}else a6.A2(0,0)
q=u.US(t)
if(a6.W$==null)if(!a6.a0I(t,q.a)){p=u.ajp(a9.gA_())
a6.dy=D.os(a7,!1,a7,a7,p,0,0,0,p,a7)
a9.Aa()
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
for(;k>=t;--k){i=u.US(k)
h=i.c
g=a6.am4(a8.Km(i.d,h,h))
f=g.b
f.toString
m.a(f)
e=i.a
f.a=e
f.w=i.b
if(j==null)j=g
n=Math.max(n,e+h)}if(j==null){h=a6.W$
h.toString
h.jF(q.aWM(a8))
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
h=B.a_(a6).k("ak.1")
f=s!=null
for(;;){if(!(!f||k<=s)){d=!1
break}i=u.US(k)
e=i.c
a0=a8.Km(i.d,e,e)
a1=j.b
a1.toString
g=h.a(a1).a5$
if(g!=null){a1=g.b
a1.toString
a1=l.a(a1).b
a1.toString
a1=a1!==k}else a1=!0
if(a1){g=a6.am3(a0,j)
if(g==null){d=!0
break}}else g.jF(a0)
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
a3=d?n:a9.L3(a8,t,m,o,n)
a4=a6.zV(a8,Math.min(x,o),n)
a5=a6.Ct(a8,o,n)
a6.dy=D.os(a5,a3>a4||x>0||a8.f!==0,a7,a7,a3,0,a4,0,a3,a7)
if(a3===n)a9.R8=!0
a9.Aa()}}
A.aN1.prototype={
aNW(d){return new A.bLi(this.to,this.x1,null)}}
A.bLi.prototype={
az(d){var x=new A.bIX(this.f,y.v.a(d),B.am(y.e,y.g),0,null,null,B.aM())
x.aw()
return x},
aH(d,e){e.saXt(this.f)},
akZ(d,e,f,g,h){var x,w
this.b19(d,e,f,g,h)
x=this.f.MK(d)
w=this.d.gmR()
w.toString
w=x.ajp(w)
return w}}
var z=a.updateTypes([]);(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.Y,[A.bLj,A.bLk,A.aUH])
w(A.aUI,A.bLk)
w(A.av5,D.mu)
w(A.bIX,D.xF)
w(A.aN1,D.aFD)
w(A.bLi,D.tC)})()
B.bN(b.typeUniverse,JSON.parse('{"av5":{"mu":[],"Jv":[],"ey":["w"],"Bc":[],"e6":[]},"bIX":{"xF":[],"fv":[],"ak":["w","mu"],"H":[],"aQ":[],"ak.1":"mu","ak.0":"w"},"aN1":{"k":[],"b":[]},"bLi":{"tC":[],"aP":[],"b":[]}}'))
var y={x:B.G("o<n>"),g:B.G("w"),z:B.G("p1"),t:B.G("av5"),v:B.G("Jx"),c:B.G("mu"),e:B.G("v")};(function constants(){E.a6W=new B.j7(0.4,0,1,1)
E.aq6=new B.cr([C.fa,C.Gy,C.fC,C.Gx],B.G("cr<eW,bw>"))
E.d9H=new B.I(0,40)
E.E_=new B.U(5,"scrolledUnder")})()};
(a=>{a["D2Kq0u8ASHF0NeV0w4LVmEh+Q5U="]=a.current})($__dart_deferred_initializers__);