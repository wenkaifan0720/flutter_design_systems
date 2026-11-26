((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,A={bLW:function bLW(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},bLX:function bLX(){},aV6:function aV6(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},aV5:function aV5(){},avo:function avo(d,e,f){var _=this
_.b=_.w=null
_.c=!1
_.Lg$=d
_.dw$=e
_.a5$=f
_.a=null},bJA:function bJA(d,e,f,g,h,i,j){var _=this
_.eA=d
_.y1=e
_.y2=f
_.c1$=g
_.W$=h
_.br$=i
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
iA8(d,e,f,g,h,i){var x=null,w=d==null
w=w?F.hf:x
return new A.aNq(f,new G.Fc(g,h,!0,!0,!0,0,D.aEO(),x),i,C.w,!1,d,x,w,x,!1,x,0,x,x,h,F.A9,e,x,x,C.m,C.aq,x)},
aNq:function aNq(d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,a0){var _=this
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
bLV:function bLV(d,e,f){this.f=d
this.d=e
this.a=f}},E,G,D,F
B=c[0]
C=c[2]
A=a.updateHolder(c[88],A)
E=c[901]
G=c[271]
D=c[283]
F=c[296]
A.bLW.prototype={
aX0(d){var x=this.c
return d.Kt(this.d,x,x)},
C(d){var x=this
return"SliverGridGeometry("+C.d.aM(B.a(["scrollOffset: "+B.al(x.a),"crossAxisOffset: "+B.al(x.b),"mainAxisExtent: "+B.al(x.c),"crossAxisExtent: "+B.al(x.d)],y.x),", ")+")"}}
A.bLX.prototype={}
A.aV6.prototype={
apX(d){var x=this.b
return x>1e-10?this.a*C.i.j8(d,x):0},
apW(d){var x=this.b
if(x>0)return Math.max(0,this.a*C.i.ff(d/x)-1)
return 0},
bke(d){var x,w,v=this
if(v.f){x=v.c
w=v.e
return v.a*x-d-w-(x-w)}return d},
UV(d){var x=this,w=x.a,v=C.o.a7(d,w)
return new A.bLW(C.o.j8(d,w)*x.b,x.bke(v*x.c),x.d,x.e)},
ajs(d){var x
if(d===0)return 0
x=this.b
return x*(C.o.j8(d-1,this.a)+1)-(x-this.d)}}
A.aV5.prototype={}
A.avo.prototype={
C(d){return"crossAxisOffset="+B.al(this.w)+"; "+this.b1o(0)}}
A.bJA.prototype={
eS(d){if(!(d.b instanceof A.avo))d.b=new A.avo(!1,null,null)},
saXI(d){var x=this
if(x.eA===d)return
if(B.aF(d)!==B.aF(x.eA)||d.ji(x.eA))x.a6()
x.eA=d},
KC(d){var x=d.b
x.toString
x=y.t.a(x).w
x.toString
return x},
bo(){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4,a5,a6=this,a7=null,a8=y.z.a(B.G.prototype.gX.call(a6)),a9=a6.y1
a9.R8=!1
x=a8.d
w=x+a8.z
v=w+a8.Q
u=a6.eA.MN(a8)
t=u.apX(w)
s=isFinite(v)?u.apW(v):a7
if(a6.W$!=null){r=a6.aj1(t)
a6.zY(r,s!=null?a6.aj2(s):0)}else a6.zY(0,0)
q=u.UV(t)
if(a6.W$==null)if(!a6.a0O(t,q.a)){p=u.ajs(a9.gzV())
a6.dy=D.oA(a7,!1,a7,a7,p,0,0,0,p,a7)
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
for(;k>=t;--k){i=u.UV(k)
h=i.c
g=a6.amf(a8.Kt(i.d,h,h))
f=g.b
f.toString
m.a(f)
e=i.a
f.a=e
f.w=i.b
if(j==null)j=g
n=Math.max(n,e+h)}if(j==null){h=a6.W$
h.toString
h.jF(q.aX0(a8))
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
break}i=u.UV(k)
e=i.c
a0=a8.Kt(i.d,e,e)
a1=j.b
a1.toString
g=h.a(a1).a5$
if(g!=null){a1=g.b
a1.toString
a1=l.a(a1).b
a1.toString
a1=a1!==k}else a1=!0
if(a1){g=a6.ame(a0,j)
if(g==null){d=!0
break}}else g.jF(a0)
a1=g.b
a1.toString
m.a(a1)
a2=i.a
a1.a=a2
a1.w=i.b
n=Math.max(n,a2+e);++k
j=g}m=a6.br$
m.toString
m=m.b
m.toString
m=l.a(m).b
m.toString
a3=d?n:a9.Lb(a8,t,m,o,n)
a4=a6.zQ(a8,Math.min(x,o),n)
a5=a6.Cs(a8,o,n)
a6.dy=D.oA(a5,a3>a4||x>0||a8.f!==0,a7,a7,a3,0,a4,0,a3,a7)
if(a3===n)a9.R8=!0
a9.A5()}}
A.aNq.prototype={
aOc(d){return new A.bLV(this.to,this.x1,null)}}
A.bLV.prototype={
az(d){var x=new A.bJA(this.f,y.v.a(d),B.an(y.e,y.g),0,null,null,B.aL())
x.aw()
return x},
aH(d,e){e.saXI(this.f)},
akY(d,e,f,g,h){var x,w
this.b1p(d,e,f,g,h)
x=this.f.MN(d)
w=this.d.gmW()
w.toString
w=x.ajs(w)
return w}}
var z=a.updateTypes([]);(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.Y,[A.bLW,A.bLX,A.aV5])
w(A.aV6,A.bLX)
w(A.avo,D.mB)
w(A.bJA,D.y_)
w(A.aNq,D.aFZ)
w(A.bLV,D.tS)})()
B.bM(b.typeUniverse,JSON.parse('{"avo":{"mB":[],"JS":[],"ez":["w"],"Bu":[],"e4":[]},"bJA":{"y_":[],"fv":[],"ak":["w","mB"],"G":[],"aQ":[],"ak.1":"mB","ak.0":"w"},"aNq":{"l":[],"b":[]},"bLV":{"tS":[],"aO":[],"b":[]}}'))
var y={x:B.E("o<n>"),g:B.E("w"),z:B.E("pb"),t:B.E("avo"),v:B.E("JU"),c:B.E("mB"),e:B.E("v")};(function constants(){E.a8Y=new B.ja(0.4,0,1,1)
E.arS=new B.cs([C.f7,C.GZ,C.fA,C.GY],B.E("cs<eW,bx>"))
E.dil=new B.I(0,40)
E.Eh=new B.U(5,"scrolledUnder")})()};
(a=>{a["tdHJ4pt2uK3kqmo2Wx9TCmCXrgc="]=a.current})($__dart_deferred_initializers__);