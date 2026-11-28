((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,A={
jE(d,e,f,g,h,i,j,k,l,m,n,o){var x,w,v=null
if(i==null)x=f!=null?new B.ak(f,v,v,v,v,v,v,C.P):v
else x=i
if(o!=null||l!=null){w=g==null?v:g.I6(l,o)
if(w==null)w=B.dA(l,o)}else w=g
return new A.DT(e,d,n,x,k,w,h,j,v,m)},
Un:function Un(d,e){this.a=d
this.b=e},
a57:function a57(d,e){this.a=d
this.b=e},
DT:function DT(d,e,f,g,h,i,j,k,l,m){var _=this
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
bUj:function bUj(d,e){var _=this
_.fx=_.fr=_.dy=_.dx=_.db=_.cy=_.cx=_.CW=null
_.e=_.d=$
_.cd$=d
_.an$=e
_.c=_.a=null},
e62:function e62(){},
e63:function e63(){},
e64:function e64(){},
e65:function e65(){},
e66:function e66(){},
e67:function e67(){},
e68:function e68(){},
e69:function e69(){},
iLJ(){var x=new Float64Array(4)
x[3]=1
return new A.Ke(x)},
Ke:function Ke(d){this.a=d}},D,E
B=c[0]
C=c[2]
A=a.updateHolder(c[166],A)
D=c[190]
E=c[213]
A.Un.prototype={
iO(d){var x=B.xr(this.a,this.b,d)
x.toString
return x}}
A.a57.prototype={
iO(a8){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2=new B.qg(new Float64Array(3)),a3=new B.qg(new Float64Array(3)),a4=A.iLJ(),a5=A.iLJ(),a6=new B.qg(new Float64Array(3)),a7=new B.qg(new Float64Array(3))
this.a.aS7(a2,a4,a6)
this.b.aS7(a3,a5,a7)
x=1-a8
w=a2.z9(x).aE(0,a3.z9(a8))
v=a4.z9(x).aE(0,a5.z9(a8))
u=new Float64Array(4)
t=new A.Ke(u)
t.iT(v)
t.c1l()
s=a6.z9(x).aE(0,a7.z9(a8))
x=new Float64Array(16)
v=new B.f_(x)
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
v.rP(x[0],x[1],x[2],1)
return v}}
A.DT.prototype={
p(){return new A.bUj(null,null)}}
A.bUj.prototype={
mr(d){var x,w,v=this,u=y.b
v.CW=u.a(d.$3(v.CW,v.a.w,new A.e62()))
x=y.f
v.cx=x.a(d.$3(v.cx,v.a.x,new A.e63()))
w=y.d
v.cy=w.a(d.$3(v.cy,v.a.y,new A.e64()))
v.db=w.a(d.$3(v.db,v.a.z,new A.e65()))
v.dx=y.e.a(d.$3(v.dx,v.a.Q,new A.e66()))
w=v.dy
v.a.toString
v.dy=x.a(d.$3(w,null,new A.e67()))
w=v.fr
v.a.toString
v.fr=y.w.a(d.$3(w,null,new A.e68()))
w=v.fx
v.a.toString
v.fx=u.a(d.$3(w,null,new A.e69()))},
h(d){var x,w,v,u,t,s,r,q=this,p=null,o=q.giy(),n=q.CW
n=n==null?p:n.bc(o.gu())
x=q.cx
x=x==null?p:x.bc(o.gu())
w=q.cy
w=w==null?p:w.bc(o.gu())
v=q.db
v=v==null?p:v.bc(o.gu())
u=q.dx
u=u==null?p:u.bc(o.gu())
t=q.dy
t=t==null?p:t.bc(o.gu())
s=q.fr
s=s==null?p:s.bc(o.gu())
r=q.fx
r=r==null?p:r.bc(o.gu())
return B.aR(n,q.a.r,C.u,p,u,w,v,p,p,t,x,s,r,p)}}
A.Ke.prototype={
iT(d){var x=d.a,w=this.a,v=x[0]
w.$flags&2&&B.dp(w)
w[0]=v
w[1]=x[1]
w[2]=x[2]
w[3]=x[3]},
b_k(d){var x,w,v,u,t,s=d.a,r=s[0],q=s[4],p=s[8],o=0+r+q+p
if(o>0){x=Math.sqrt(o+1)
r=this.a
r.$flags&2&&B.dp(r)
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
t.$flags&2&&B.dp(t)
t[w]=x*0.5
x=0.5/x
t[3]=(s[q+u]-s[p+v])*x
t[v]=(s[r+v]+s[q+w])*x
t[u]=(s[r+u]+s[p+w])*x}},
c1l(){var x,w,v,u=Math.sqrt(this.gTR())
if(u===0)return 0
x=1/u
w=this.a
v=w[0]
w.$flags&2&&B.dp(w)
w[0]=v*x
w[1]=w[1]*x
w[2]=w[2]*x
w[3]=w[3]*x
return u},
gTR(){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return w*w+v*v+u*u+t*t},
gaa(d){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return Math.sqrt(w*w+v*v+u*u+t*t)},
z9(d){var x=new Float64Array(4),w=new A.Ke(x)
w.iT(this)
x[3]=x[3]*d
x[2]=x[2]*d
x[1]=x[1]*d
x[0]=x[0]*d
return w},
bl(a5,a6){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h=this.a,g=h[3],f=h[2],e=h[1],d=h[0],a0=a6.gc6Y(),a1=a0[3],a2=a0[2],a3=a0[1],a4=a0[0]
h=C.i.bl(g,a4)
x=C.i.bl(d,a1)
w=C.i.bl(e,a2)
v=C.i.bl(f,a3)
u=C.i.bl(g,a3)
t=C.i.bl(e,a1)
s=C.i.bl(f,a4)
r=C.i.bl(d,a2)
q=C.i.bl(g,a2)
p=C.i.bl(f,a1)
o=C.i.bl(d,a3)
n=C.i.bl(e,a4)
m=C.i.bl(g,a1)
l=C.i.bl(d,a4)
k=C.i.bl(e,a3)
j=C.i.bl(f,a2)
i=new Float64Array(4)
i[0]=h+x+w-v
i[1]=u+t+s-r
i[2]=q+p+o-n
i[3]=m-l-k-j
return new A.Ke(i)},
i(d,e){var x,w,v
if(e==null)return!1
if(e instanceof A.Ke){x=this.a
w=x[3]
v=e.a
x=w===v[3]&&x[2]===v[2]&&x[1]===v[1]&&x[0]===v[0]}else x=!1
return x},
ga2(d){return B.cC(this.a)},
aE(d,e){var x,w=new Float64Array(4),v=new A.Ke(w)
v.iT(this)
x=e.a
w[0]=w[0]+x[0]
w[1]=w[1]+x[1]
w[2]=w[2]+x[2]
w[3]=w[3]+x[3]
return v},
aU(d,e){var x,w=new Float64Array(4),v=new A.Ke(w)
v.iT(this)
x=e.a
w[0]=w[0]-x[0]
w[1]=w[1]-x[1]
w[2]=w[2]-x[2]
w[3]=w[3]-x[3]
return v},
q(d,e){return this.a[e]},
S(d,e,f){var x=this.a
x.$flags&2&&B.dp(x)
x[e]=f},
D(d){var x=this.a
return B.am(x[0])+", "+B.am(x[1])+", "+B.am(x[2])+" @ "+B.am(x[3])}}
var z=a.updateTypes(["tx(@)","zv(@)","Un(@)","a57(@)"])
A.e62.prototype={
$1(d){return new D.tx(y.k.a(d),null)},
$S:z+0}
A.e63.prototype={
$1(d){return new E.zv(y.m.a(d),null)},
$S:z+1}
A.e64.prototype={
$1(d){return new B.wa(y.r.a(d),null)},
$S:268}
A.e65.prototype={
$1(d){return new B.wa(y.r.a(d),null)},
$S:268}
A.e66.prototype={
$1(d){return new A.Un(y.a.a(d),null)},
$S:z+2}
A.e67.prototype={
$1(d){return new E.zv(y.m.a(d),null)},
$S:z+1}
A.e68.prototype={
$1(d){return new A.a57(y.E.a(d),null)},
$S:z+3}
A.e69.prototype={
$1(d){return new D.tx(y.k.a(d),null)},
$S:z+0};(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.b8,[A.Un,A.a57])
w(A.DT,B.pm)
w(A.bUj,B.oK)
x(B.cp,[A.e62,A.e63,A.e64,A.e65,A.e66,A.e67,A.e68,A.e69])
w(A.Ke,B.a_)})()
B.bP(b.typeUniverse,JSON.parse('{"Un":{"b8":["y"],"bg":["y"],"bg.T":"y","b8.T":"y"},"a57":{"b8":["f_"],"bg":["f_"],"bg.T":"f_","b8.T":"f_"},"DT":{"l":[],"b":[]},"bUj":{"m":["DT"]}}'))
var y=(function rtii(){var x=B.G
return{k:x("oI"),a:x("y"),r:x("iZ"),m:x("eJ"),E:x("f_"),b:x("tx?"),e:x("Un?"),d:x("wa?"),f:x("zv?"),w:x("a57?")}})()};
(a=>{a["kGha9NggIJJggm7LHdXKbFzaFTU="]=a.current})($__dart_deferred_initializers__);