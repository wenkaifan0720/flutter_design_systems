((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,D,A={
kE(d,e,f,g,h,i,j,k,l,m,n){var x,w,v=null
if(i==null)x=f!=null?new B.ak(f,v,v,v,v,v,v,C.L):v
else x=i
if(n!=null||l!=null){w=g==null?v:g.Ge(l,n)
if(w==null)w=B.dT(l,n)}else w=g
return new A.Ix(e,d,m,x,k,w,h,j,v,v)},
PJ:function PJ(d,e){this.a=d
this.b=e},
a_D:function a_D(d,e){this.a=d
this.b=e},
Ix:function Ix(d,e,f,g,h,i,j,k,l,m){var _=this
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
bCO:function bCO(d,e){var _=this
_.fx=_.fr=_.dy=_.dx=_.db=_.cy=_.cx=_.CW=null
_.e=_.d=$
_.cd$=d
_.ap$=e
_.c=_.a=null},
dzQ:function dzQ(){},
dzR:function dzR(){},
dzS:function dzS(){},
dzT:function dzT(){},
dzU:function dzU(){},
dzV:function dzV(){},
dzW:function dzW(){},
dzX:function dzX(){},
hIc(){var x=new Float64Array(4)
x[3]=1
return new A.GH(x)},
GH:function GH(d){this.a=d}},E
B=c[0]
C=c[2]
D=c[167]
A=a.updateHolder(c[150],A)
E=c[168]
A.PJ.prototype={
j2(d){var x=B.uS(this.a,this.b,d)
x.toString
return x}}
A.a_D.prototype={
j2(a8){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2=new B.oq(new Float64Array(3)),a3=new B.oq(new Float64Array(3)),a4=A.hIc(),a5=A.hIc(),a6=new B.oq(new Float64Array(3)),a7=new B.oq(new Float64Array(3))
this.a.aL4(a2,a4,a6)
this.b.aL4(a3,a5,a7)
x=1-a8
w=a2.xE(x).av(0,a3.xE(a8))
v=a4.xE(x).av(0,a5.xE(a8))
u=new Float64Array(4)
t=new A.GH(u)
t.ip(v)
t.bQs()
s=a6.xE(x).av(0,a7.xE(a8))
x=new Float64Array(16)
v=new B.eE(x)
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
v.qj(x[0],x[1],x[2],1)
return v}}
A.Ix.prototype={
n(){return new A.bCO(null,null)}}
A.bCO.prototype={
mH(d){var x,w,v=this,u=y.b
v.CW=u.a(d.$3(v.CW,v.a.w,new A.dzQ()))
x=y.f
v.cx=x.a(d.$3(v.cx,v.a.x,new A.dzR()))
w=y.d
v.cy=w.a(d.$3(v.cy,v.a.y,new A.dzS()))
v.db=w.a(d.$3(v.db,v.a.z,new A.dzT()))
v.dx=y.e.a(d.$3(v.dx,v.a.Q,new A.dzU()))
w=v.dy
v.a.toString
v.dy=x.a(d.$3(w,null,new A.dzV()))
w=v.fr
v.a.toString
v.fr=y.w.a(d.$3(w,null,new A.dzW()))
w=v.fx
v.a.toString
v.fx=u.a(d.$3(w,null,new A.dzX()))},
h(d){var x,w,v,u,t,s,r,q=this,p=null,o=q.gir(),n=q.CW
n=n==null?p:n.b1(o.gq())
x=q.cx
x=x==null?p:x.b1(o.gq())
w=q.cy
w=w==null?p:w.b1(o.gq())
v=q.db
v=v==null?p:v.b1(o.gq())
u=q.dx
u=u==null?p:u.b1(o.gq())
t=q.dy
t=t==null?p:t.b1(o.gq())
s=q.fr
s=s==null?p:s.b1(o.gq())
r=q.fx
r=r==null?p:r.b1(o.gq())
return B.aH(n,q.a.r,C.v,p,u,w,v,p,p,t,x,s,r,p)}}
A.GH.prototype={
ip(d){var x=d.a,w=this.a,v=x[0]
w.$flags&2&&B.cQ(w)
w[0]=v
w[1]=x[1]
w[2]=x[2]
w[3]=x[3]},
aTo(d){var x,w,v,u,t,s=d.a,r=s[0],q=s[4],p=s[8],o=0+r+q+p
if(o>0){x=Math.sqrt(o+1)
r=this.a
r.$flags&2&&B.cQ(r)
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
t.$flags&2&&B.cQ(t)
t[w]=x*0.5
x=0.5/x
t[3]=(s[q+u]-s[p+v])*x
t[v]=(s[r+v]+s[q+w])*x
t[u]=(s[r+u]+s[p+w])*x}},
bQs(){var x,w,v,u=Math.sqrt(this.gR4())
if(u===0)return 0
x=1/u
w=this.a
v=w[0]
w.$flags&2&&B.cQ(w)
w[0]=v*x
w[1]=w[1]*x
w[2]=w[2]*x
w[3]=w[3]*x
return u},
gR4(){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return w*w+v*v+u*u+t*t},
ga2(d){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return Math.sqrt(w*w+v*v+u*u+t*t)},
xE(d){var x=new Float64Array(4),w=new A.GH(x)
w.ip(this)
x[3]=x[3]*d
x[2]=x[2]*d
x[1]=x[1]*d
x[0]=x[0]*d
return w},
b8(a5,a6){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h=this.a,g=h[3],f=h[2],e=h[1],d=h[0],a0=a6.gbVG(),a1=a0[3],a2=a0[2],a3=a0[1],a4=a0[0]
h=C.i.b8(g,a4)
x=C.i.b8(d,a1)
w=C.i.b8(e,a2)
v=C.i.b8(f,a3)
u=C.i.b8(g,a3)
t=C.i.b8(e,a1)
s=C.i.b8(f,a4)
r=C.i.b8(d,a2)
q=C.i.b8(g,a2)
p=C.i.b8(f,a1)
o=C.i.b8(d,a3)
n=C.i.b8(e,a4)
m=C.i.b8(g,a1)
l=C.i.b8(d,a4)
k=C.i.b8(e,a3)
j=C.i.b8(f,a2)
i=new Float64Array(4)
i[0]=h+x+w-v
i[1]=u+t+s-r
i[2]=q+p+o-n
i[3]=m-l-k-j
return new A.GH(i)},
i(d,e){var x,w,v
if(e==null)return!1
if(e instanceof A.GH){x=this.a
w=x[3]
v=e.a
x=w===v[3]&&x[2]===v[2]&&x[1]===v[1]&&x[0]===v[0]}else x=!1
return x},
gY(d){return B.cs(this.a)},
av(d,e){var x,w=new Float64Array(4),v=new A.GH(w)
v.ip(this)
x=e.a
w[0]=w[0]+x[0]
w[1]=w[1]+x[1]
w[2]=w[2]+x[2]
w[3]=w[3]+x[3]
return v},
aM(d,e){var x,w=new Float64Array(4),v=new A.GH(w)
v.ip(this)
x=e.a
w[0]=w[0]-x[0]
w[1]=w[1]-x[1]
w[2]=w[2]-x[2]
w[3]=w[3]-x[3]
return v},
p(d,e){return this.a[e]},
M(d,e,f){var x=this.a
x.$flags&2&&B.cQ(x)
x[e]=f},
v(d){var x=this.a
return B.ae(x[0])+", "+B.ae(x[1])+", "+B.ae(x[2])+" @ "+B.ae(x[3])}}
var z=a.updateTypes(["qy(@)","wN(@)","PJ(@)","a_D(@)"])
A.dzQ.prototype={
$1(d){return new D.qy(y.k.a(d),null)},
$S:z+0}
A.dzR.prototype={
$1(d){return new E.wN(y.m.a(d),null)},
$S:z+1}
A.dzS.prototype={
$1(d){return new B.tM(y.r.a(d),null)},
$S:222}
A.dzT.prototype={
$1(d){return new B.tM(y.r.a(d),null)},
$S:222}
A.dzU.prototype={
$1(d){return new A.PJ(y.a.a(d),null)},
$S:z+2}
A.dzV.prototype={
$1(d){return new E.wN(y.m.a(d),null)},
$S:z+1}
A.dzW.prototype={
$1(d){return new A.a_D(y.E.a(d),null)},
$S:z+3}
A.dzX.prototype={
$1(d){return new D.qy(y.k.a(d),null)},
$S:z+0};(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.b0,[A.PJ,A.a_D])
w(A.Ix,B.qc)
w(A.bCO,B.p9)
x(B.ck,[A.dzQ,A.dzR,A.dzS,A.dzT,A.dzU,A.dzV,A.dzW,A.dzX])
w(A.GH,B.Q)})()
B.bE(b.typeUniverse,JSON.parse('{"PJ":{"b0":["B"],"b2":["B"],"b2.T":"B","b0.T":"B"},"a_D":{"b0":["eE"],"b2":["eE"],"b2.T":"eE","b0.T":"eE"},"Ix":{"j":[],"b":[]},"bCO":{"i":["Ix"]}}'))
var y=(function rtii(){var x=B.C
return{k:x("mX"),a:x("B"),r:x("im"),m:x("el"),E:x("eE"),b:x("qy?"),e:x("PJ?"),d:x("tM?"),f:x("wN?"),w:x("a_D?")}})()};
(a=>{a["mIVBtuO8w5rKV0cvx0LPnE1Lw8o="]=a.current})($__dart_deferred_initializers__);