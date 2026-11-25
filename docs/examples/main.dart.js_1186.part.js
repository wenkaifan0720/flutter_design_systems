((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,A={bL8:function bL8(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},bL9:function bL9(){},aUD:function aUD(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},aUC:function aUC(){},auX:function auX(d,e,f){var _=this
_.b=_.w=null
_.c=!1
_.La$=d
_.d9$=e
_.a5$=f
_.a=null},bIM:function bIM(d,e,f,g,h,i,j){var _=this
_.ev=d
_.y1=e
_.y2=f
_.bW$=g
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
iy3(d,e,f,g,h,i){var x=null,w=d==null
w=w?F.hg:x
return new A.aMV(f,new G.EO(g,h,!0,!0,!0,0,D.aEh(),x),i,C.w,!1,d,x,w,x,!1,x,0,x,x,h,F.zK,e,x,x,C.m,C.ap,x)},
aMV:function aMV(d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,a0){var _=this
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
bL7:function bL7(d,e,f){this.f=d
this.d=e
this.a=f}},E,G,D,F
B=c[0]
C=c[2]
A=a.updateHolder(c[86],A)
E=c[882]
G=c[256]
D=c[268]
F=c[281]
A.bL8.prototype={
aWA(d){var x=this.c
return d.Ki(this.d,x,x)},
B(d){var x=this
return"SliverGridGeometry("+C.c.aK(B.a(["scrollOffset: "+B.an(x.a),"crossAxisOffset: "+B.an(x.b),"mainAxisExtent: "+B.an(x.c),"crossAxisExtent: "+B.an(x.d)],y.x),", ")+")"}}
A.bL9.prototype={}
A.aUD.prototype={
apB(d){var x=this.b
return x>1e-10?this.a*C.i.ji(d,x):0},
apA(d){var x=this.b
if(x>0)return Math.max(0,this.a*C.i.fn(d/x)-1)
return 0},
bjH(d){var x,w,v=this
if(v.f){x=v.c
w=v.e
return v.a*x-d-w-(x-w)}return d},
UL(d){var x=this,w=x.a,v=C.o.a7(d,w)
return new A.bL8(C.o.ji(d,w)*x.b,x.bjH(v*x.c),x.d,x.e)},
aji(d){var x
if(d===0)return 0
x=this.b
return x*(C.o.ji(d-1,this.a)+1)-(x-this.d)}}
A.aUC.prototype={}
A.auX.prototype={
B(d){return"crossAxisOffset="+B.an(this.w)+"; "+this.b0X(0)}}
A.bIM.prototype={
f5(d){if(!(d.b instanceof A.auX))d.b=new A.auX(!1,null,null)},
saXh(d){var x=this
if(x.ev===d)return
if(B.aG(d)!==B.aG(x.ev)||d.jh(x.ev))x.a6()
x.ev=d},
Kr(d){var x=d.b
x.toString
x=y.t.a(x).w
x.toString
return x},
bu(){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4,a5,a6=this,a7=null,a8=y.z.a(B.H.prototype.gX.call(a6)),a9=a6.y1
a9.R8=!1
x=a8.d
w=x+a8.z
v=w+a8.Q
u=a6.ev.MG(a8)
t=u.apB(w)
s=isFinite(v)?u.apA(v):a7
if(a6.W$!=null){r=a6.aiS(t)
a6.zY(r,s!=null?a6.aiT(s):0)}else a6.zY(0,0)
q=u.UL(t)
if(a6.W$==null)if(!a6.a0A(t,q.a)){p=u.aji(a9.gzV())
a6.dy=D.os(a7,!1,a7,a7,p,0,0,0,p,a7)
a9.A5()
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
for(;k>=t;--k){i=u.UL(k)
h=i.c
g=a6.alX(a8.Ki(i.d,h,h))
f=g.b
f.toString
m.a(f)
e=i.a
f.a=e
f.w=i.b
if(j==null)j=g
n=Math.max(n,e+h)}if(j==null){h=a6.W$
h.toString
h.jE(q.aWA(a8))
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
h=B.a_(a6).k("al.1")
f=s!=null
for(;;){if(!(!f||k<=s)){d=!1
break}i=u.UL(k)
e=i.c
a0=a8.Ki(i.d,e,e)
a1=j.b
a1.toString
g=h.a(a1).a5$
if(g!=null){a1=g.b
a1.toString
a1=l.a(a1).b
a1.toString
a1=a1!==k}else a1=!0
if(a1){g=a6.alW(a0,j)
if(g==null){d=!0
break}}else g.jE(a0)
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
a3=d?n:a9.L_(a8,t,m,o,n)
a4=a6.zQ(a8,Math.min(x,o),n)
a5=a6.Co(a8,o,n)
a6.dy=D.os(a5,a3>a4||x>0||a8.f!==0,a7,a7,a3,0,a4,0,a3,a7)
if(a3===n)a9.R8=!0
a9.A5()}}
A.aMV.prototype={
aNM(d){return new A.bL7(this.to,this.x1,null)}}
A.bL7.prototype={
az(d){var x=new A.bIM(this.f,y.v.a(d),B.am(y.e,y.g),0,null,null,B.aM())
x.aw()
return x},
aJ(d,e){e.saXh(this.f)},
akR(d,e,f,g,h){var x,w
this.b0Y(d,e,f,g,h)
x=this.f.MG(d)
w=this.d.gmP()
w.toString
w=x.aji(w)
return w}}
var z=a.updateTypes([]);(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.Y,[A.bL8,A.bL9,A.aUC])
w(A.aUD,A.bL9)
w(A.auX,D.mu)
w(A.bIM,D.xG)
w(A.aMV,D.aFs)
w(A.bL7,D.tC)})()
B.bO(b.typeUniverse,JSON.parse('{"auX":{"mu":[],"Jo":[],"eB":["w"],"B8":[],"e8":[]},"bIM":{"xG":[],"fu":[],"al":["w","mu"],"H":[],"aQ":[],"al.1":"mu","al.0":"w"},"aMV":{"k":[],"b":[]},"bL7":{"tC":[],"aP":[],"b":[]}}'))
var y={x:B.G("o<n>"),g:B.G("w"),z:B.G("p0"),t:B.G("auX"),v:B.G("Jq"),c:B.G("mu"),e:B.G("v")};(function constants(){E.a6X=new B.j5(0.4,0,1,1)
E.aq6=new B.cr([C.f9,C.Gw,C.fC,C.Gv],B.G("cr<eW,bw>"))
E.d9G=new B.I(0,40)
E.DY=new B.U(5,"scrolledUnder")})()};
(a=>{a["aS820r2IKKxtrWFzTqq51EDdghA="]=a.current})($__dart_deferred_initializers__);