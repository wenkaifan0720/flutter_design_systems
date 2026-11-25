((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,A={
jA(d,e,f,g,h,i,j,k,l,m,n,o){var x,w,v=null
if(i==null)x=f!=null?new B.ah(f,v,v,v,v,v,v,C.N):v
else x=i
if(o!=null||l!=null){w=g==null?v:g.HE(l,o)
if(w==null)w=B.dC(l,o)}else w=g
return new A.CT(e,d,n,x,k,w,h,j,v,m)},
T2:function T2(d,e){this.a=d
this.b=e},
a3C:function a3C(d,e){this.a=d
this.b=e},
CT:function CT(d,e,f,g,h,i,j,k,l,m){var _=this
_.r=d
_.w=e
_.x=f
_.y=g
_.z=h
_.Q=i
_.c=j
_.d=k
_.e=l
_.a=m},
bRi:function bRi(d,e){var _=this
_.fx=_.fr=_.dy=_.dx=_.db=_.cy=_.cx=_.CW=null
_.e=_.d=$
_.ca$=d
_.am$=e
_.c=_.a=null},
e_I:function e_I(){},
e_J:function e_J(){},
e_K:function e_K(){},
e_L:function e_L(){},
e_M:function e_M(){},
e_N:function e_N(){},
e_O:function e_O(){},
e_P:function e_P(){},
iBZ(){var x=new Float64Array(4)
x[3]=1
return new A.J2(x)},
J2:function J2(d){this.a=d}},D,E
B=c[0]
C=c[2]
A=a.updateHolder(c[158],A)
D=c[183]
E=c[199]
A.T2.prototype={
jo(d){var x=B.wG(this.a,this.b,d)
x.toString
return x}}
A.a3C.prototype={
jo(a8){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2=new B.pJ(new Float64Array(3)),a3=new B.pJ(new Float64Array(3)),a4=A.iBZ(),a5=A.iBZ(),a6=new B.pJ(new Float64Array(3)),a7=new B.pJ(new Float64Array(3))
this.a.aQc(a2,a4,a6)
this.b.aQc(a3,a5,a7)
x=1-a8
w=a2.z3(x).aD(0,a3.z3(a8))
v=a4.z3(x).aD(0,a5.z3(a8))
u=new Float64Array(4)
t=new A.J2(u)
t.iQ(v)
t.bYE()
s=a6.z3(x).aD(0,a7.z3(a8))
x=new Float64Array(16)
v=new B.eV(x)
r=u[0]
q=u[1]
p=u[2]
o=u[3]
n=r+r
m=q+q
l=p+p
k=r*n
j=r*m
i=r*l
h=q*m
g=q*l
f=p*l
e=o*n
d=o*m
a0=o*l
a1=w.a
x[0]=1-(h+f)
x[1]=j+a0
x[2]=i-d
x[3]=0
x[4]=j-a0
x[5]=1-(k+f)
x[6]=g+e
x[7]=0
x[8]=i+d
x[9]=g-e
x[10]=1-(k+h)
x[11]=0
x[12]=a1[0]
x[13]=a1[1]
x[14]=a1[2]
x[15]=1
x=s.a
v.rw(x[0],x[1],x[2],1)
return v}}
A.CT.prototype={
p(){return new A.bRi(null,null)}}
A.bRi.prototype={
mV(d){var x,w,v=this,u=y.b
v.CW=u.a(d.$3(v.CW,v.a.w,new A.e_I()))
x=y.f
v.cx=x.a(d.$3(v.cx,v.a.x,new A.e_J()))
w=y.d
v.cy=w.a(d.$3(v.cy,v.a.y,new A.e_K()))
v.db=w.a(d.$3(v.db,v.a.z,new A.e_L()))
v.dx=y.e.a(d.$3(v.dx,v.a.Q,new A.e_M()))
w=v.dy
v.a.toString
v.dy=x.a(d.$3(w,null,new A.e_N()))
w=v.fr
v.a.toString
v.fr=y.w.a(d.$3(w,null,new A.e_O()))
w=v.fx
v.a.toString
v.fx=u.a(d.$3(w,null,new A.e_P()))},
h(d){var x,w,v,u,t,s,r,q=this,p=null,o=q.giJ(),n=q.CW
n=n==null?p:n.bb(o.gt())
x=q.cx
x=x==null?p:x.bb(o.gt())
w=q.cy
w=w==null?p:w.bb(o.gt())
v=q.db
v=v==null?p:v.bb(o.gt())
u=q.dx
u=u==null?p:u.bb(o.gt())
t=q.dy
t=t==null?p:t.bb(o.gt())
s=q.fr
s=s==null?p:s.bb(o.gt())
r=q.fx
r=r==null?p:r.bb(o.gt())
return B.aO(n,q.a.r,C.v,p,u,w,v,p,p,t,x,s,r,p)}}
A.J2.prototype={
iQ(d){var x=d.a,w=this.a,v=x[0]
w.$flags&2&&B.dj(w)
w[0]=v
w[1]=x[1]
w[2]=x[2]
w[3]=x[3]},
aYk(d){var x,w,v,u,t,s=d.a,r=s[0],q=s[4],p=s[8],o=0+r+q+p
if(o>0){x=Math.sqrt(o+1)
r=this.a
r.$flags&2&&B.dj(r)
r[3]=x*0.5
x=0.5/x
r[0]=(s[5]-s[7])*x
r[1]=(s[6]-s[2])*x
r[2]=(s[1]-s[3])*x}else{if(r<q)w=q<p?2:1
else w=r<p?2:0
v=(w+1)%3
u=(w+2)%3
r=w*3
q=v*3
p=u*3
x=Math.sqrt(s[r+w]-s[q+v]-s[p+u]+1)
t=this.a
t.$flags&2&&B.dj(t)
t[w]=x*0.5
x=0.5/x
t[3]=(s[q+u]-s[p+v])*x
t[v]=(s[r+v]+s[q+w])*x
t[u]=(s[r+u]+s[p+w])*x}},
bYE(){var x,w,v,u=Math.sqrt(this.gTh())
if(u===0)return 0
x=1/u
w=this.a
v=w[0]
w.$flags&2&&B.dj(w)
w[0]=v*x
w[1]=w[1]*x
w[2]=w[2]*x
w[3]=w[3]*x
return u},
gTh(){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return w*w+v*v+u*u+t*t},
ga9(d){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return Math.sqrt(w*w+v*v+u*u+t*t)},
z3(d){var x=new Float64Array(4),w=new A.J2(x)
w.iQ(this)
x[3]=x[3]*d
x[2]=x[2]*d
x[1]=x[1]*d
x[0]=x[0]*d
return w},
bn(a5,a6){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h=this.a,g=h[3],f=h[2],e=h[1],d=h[0],a0=a6.gc38(),a1=a0[3],a2=a0[2],a3=a0[1],a4=a0[0]
h=C.i.bn(g,a4)
x=C.i.bn(d,a1)
w=C.i.bn(e,a2)
v=C.i.bn(f,a3)
u=C.i.bn(g,a3)
t=C.i.bn(e,a1)
s=C.i.bn(f,a4)
r=C.i.bn(d,a2)
q=C.i.bn(g,a2)
p=C.i.bn(f,a1)
o=C.i.bn(d,a3)
n=C.i.bn(e,a4)
m=C.i.bn(g,a1)
l=C.i.bn(d,a4)
k=C.i.bn(e,a3)
j=C.i.bn(f,a2)
i=new Float64Array(4)
i[0]=h+x+w-v
i[1]=u+t+s-r
i[2]=q+p+o-n
i[3]=m-l-k-j
return new A.J2(i)},
i(d,e){var x,w,v
if(e==null)return!1
if(e instanceof A.J2){x=this.a
w=x[3]
v=e.a
x=w===v[3]&&x[2]===v[2]&&x[1]===v[1]&&x[0]===v[0]}else x=!1
return x},
ga3(d){return B.cE(this.a)},
aD(d,e){var x,w=new Float64Array(4),v=new A.J2(w)
v.iQ(this)
x=e.a
w[0]=w[0]+x[0]
w[1]=w[1]+x[1]
w[2]=w[2]+x[2]
w[3]=w[3]+x[3]
return v},
aS(d,e){var x,w=new Float64Array(4),v=new A.J2(w)
v.iQ(this)
x=e.a
w[0]=w[0]-x[0]
w[1]=w[1]-x[1]
w[2]=w[2]-x[2]
w[3]=w[3]-x[3]
return v},
q(d,e){return this.a[e]},
S(d,e,f){var x=this.a
x.$flags&2&&B.dj(x)
x[e]=f},
B(d){var x=this.a
return B.an(x[0])+", "+B.an(x[1])+", "+B.an(x[2])+" @ "+B.an(x[3])}}
var z=a.updateTypes(["rY(@)","yD(@)","T2(@)","a3C(@)"])
A.e_I.prototype={
$1(d){return new D.rY(y.k.a(d),null)},
$S:z+0}
A.e_J.prototype={
$1(d){return new E.yD(y.m.a(d),null)},
$S:z+1}
A.e_K.prototype={
$1(d){return new B.vq(y.r.a(d),null)},
$S:249}
A.e_L.prototype={
$1(d){return new B.vq(y.r.a(d),null)},
$S:249}
A.e_M.prototype={
$1(d){return new A.T2(y.a.a(d),null)},
$S:z+2}
A.e_N.prototype={
$1(d){return new E.yD(y.m.a(d),null)},
$S:z+1}
A.e_O.prototype={
$1(d){return new A.a3C(y.E.a(d),null)},
$S:z+3}
A.e_P.prototype={
$1(d){return new D.rY(y.k.a(d),null)},
$S:z+0};(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.b9,[A.T2,A.a3C])
w(A.CT,B.q4)
w(A.bRi,B.pi)
x(B.cf,[A.e_I,A.e_J,A.e_K,A.e_L,A.e_M,A.e_N,A.e_O,A.e_P])
w(A.J2,B.Y)})()
B.bN(b.typeUniverse,JSON.parse('{"T2":{"b9":["z"],"bg":["z"],"bg.T":"z","b9.T":"z"},"a3C":{"b9":["eV"],"bg":["eV"],"bg.T":"eV","b9.T":"eV"},"CT":{"j":[],"b":[]},"bRi":{"l":["CT"]}}'))
var y=(function rtii(){var x=B.G
return{k:x("o8"),a:x("z"),r:x("iL"),m:x("eD"),E:x("eV"),b:x("rY?"),e:x("T2?"),d:x("vq?"),f:x("yD?"),w:x("a3C?")}})()};
(a=>{a["mrmnjdsYw1qV9D03wgf+l2AFxr4="]=a.current})($__dart_deferred_initializers__);