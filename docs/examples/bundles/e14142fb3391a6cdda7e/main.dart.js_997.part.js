((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,D,F,G,A={bx1:function bx1(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},bx2:function bx2(){},aLr:function aLr(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},aLq:function aLq(){},anX:function anX(d,e,f){var _=this
_.b=_.w=null
_.c=!1
_.Jv$=d
_.dK$=e
_.a3$=f
_.a=null},buD:function buD(d,e,f,g,h,i,j){var _=this
_.fk=d
_.y1=e
_.y2=f
_.bX$=g
_.X$=h
_.bE$=i
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
hFw(d,e,f,g,h,i){var x=null,w=d==null
w=w?F.hk:x
return new A.aF_(f,new G.H0(g,h,!0,!0,!0,0,x),i,C.w,!1,d,x,w,x,!1,x,0,x,x,h,F.y7,e,x,x,C.m,C.aB,x)},
aF_:function aF_(d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,a0){var _=this
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
bx0:function bx0(d,e,f){this.f=d
this.d=e
this.a=f}},E
B=c[0]
C=c[2]
D=c[238]
F=c[249]
G=c[237]
A=a.updateHolder(c[81],A)
E=c[772]
A.bx1.prototype={
aRU(d){var x=this.c
return d.IN(this.d,x,x)},
v(d){var x=this
return"SliverGridGeometry("+C.c.aZ(B.a(["scrollOffset: "+B.ae(x.a),"crossAxisOffset: "+B.ae(x.b),"mainAxisExtent: "+B.ae(x.c),"crossAxisExtent: "+B.ae(x.d)],y.x),", ")+")"}}
A.bx2.prototype={}
A.aLr.prototype={
alU(d){var x=this.b
return x>1e-10?this.a*C.i.jq(d,x):0},
alT(d){var x=this.b
if(x>0)return Math.max(0,this.a*C.i.fe(d/x)-1)
return 0},
bdz(d){var x,w,v=this
if(v.f){x=v.c
w=v.e
return v.a*x-d-w-(x-w)}return d},
Sw(d){var x=this,w=x.a,v=C.n.a1(d,w)
return new A.bx1(C.n.jq(d,w)*x.b,x.bdz(v*x.c),x.d,x.e)},
afP(d){var x
if(d===0)return 0
x=this.b
return x*(C.n.jq(d-1,this.a)+1)-(x-this.d)}}
A.aLq.prototype={}
A.anX.prototype={
v(d){return"crossAxisOffset="+B.ae(this.w)+"; "+this.aX9(0)}}
A.buD.prototype={
fq(d){if(!(d.b instanceof A.anX))d.b=new A.anX(!1,null,null)},
saSz(d){var x=this
if(x.fk===d)return
if(B.ar(d)!==B.ar(x.fk)||d.iV(x.fk))x.a6()
x.fk=d},
IT(d){var x=d.b
x.toString
x=y.t.a(x).w
x.toString
return x},
bq(){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4,a5,a6=this,a7=null,a8=y.z.a(B.E.prototype.gT.call(a6)),a9=a6.y1
a9.R8=!1
x=a8.d
w=x+a8.z
v=w+a8.Q
u=a6.fk.L1(a8)
t=u.alU(w)
s=isFinite(v)?u.alT(v):a7
if(a6.X$!=null){r=a6.afk(t)
a6.yC(r,s!=null?a6.afl(s):0)}else a6.yC(0,0)
q=u.Sw(t)
if(a6.X$==null)if(!a6.Zd(t,q.a)){p=u.afP(a9.gyz())
a6.dy=D.na(a7,!1,a7,a7,p,0,0,0,p,a7)
a9.yO()
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
for(;k>=t;--k){i=u.Sw(k)
h=i.c
g=a6.aik(a8.IN(i.d,h,h))
f=g.b
f.toString
m.a(f)
e=i.a
f.a=e
f.w=i.b
if(j==null)j=g
n=Math.max(n,e+h)}if(j==null){h=a6.X$
h.toString
h.j1(q.aRU(a8))
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
h=B.U(a6).j("ap.1")
f=s!=null
for(;;){if(!(!f||k<=s)){d=!1
break}i=u.Sw(k)
e=i.c
a0=a8.IN(i.d,e,e)
a1=j.b
a1.toString
g=h.a(a1).a3$
if(g!=null){a1=g.b
a1.toString
a1=l.a(a1).b
a1.toString
a1=a1!==k}else a1=!0
if(a1){g=a6.aij(a0,j)
if(g==null){d=!0
break}}else g.j1(a0)
a1=g.b
a1.toString
m.a(a1)
a2=i.a
a1.a=a2
a1.w=i.b
n=Math.max(n,a2+e);++k
j=g}m=a6.bE$
m.toString
m=m.b
m.toString
m=l.a(m).b
m.toString
a3=d?n:a9.Jq(a8,t,m,o,n)
a4=a6.yv(a8,Math.min(x,o),n)
a5=a6.Bi(a8,o,n)
a6.dy=D.na(a5,a3>a4||x>0||a8.f!==0,a7,a7,a3,0,a4,0,a3,a7)
if(a3===n)a9.R8=!0
a9.yO()}}
A.aF_.prototype={
aJ_(d){return new A.bx0(this.to,this.x1,null)}}
A.bx0.prototype={
aA(d){var x=new A.buD(this.f,y.v.a(d),B.aj(y.e,y.g),0,null,null,B.aL())
x.az()
return x},
aR(d,e){e.saSz(this.f)},
ahb(d,e,f,g,h){var x,w
this.aXa(d,e,f,g,h)
x=this.f.L1(d)
w=this.d.gm1()
w.toString
w=x.afP(w)
return w}}
var z=a.updateTypes([]);(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.Q,[A.bx1,A.bx2,A.aLq])
w(A.aLr,A.bx2)
w(A.anX,D.lu)
w(A.buD,D.vL)
w(A.aF_,D.axh)
w(A.bx0,D.ra)})()
B.bE(b.typeUniverse,JSON.parse('{"anX":{"lu":[],"H1":[],"eF":["w"],"zs":[],"ef":[]},"buD":{"vL":[],"fs":[],"ap":["w","lu"],"E":[],"aP":[],"ap.1":"lu","ap.0":"w"},"aF_":{"k":[],"b":[]},"bx0":{"ra":[],"aO":[],"b":[]}}'))
var y={x:B.C("m<p>"),g:B.C("w"),z:B.C("om"),t:B.C("anX"),v:B.C("H2"),c:B.C("lu"),e:B.C("u")};(function constants(){E.a3e=new B.il(0.4,0,1,1)
E.d_h=new B.H(0,40)
E.Cd=new B.S(5,"scrolledUnder")})()};
(a=>{a["QkZvJgvPDWxL+1h81wA2HZ13fHk="]=a.current})($__dart_deferred_initializers__);