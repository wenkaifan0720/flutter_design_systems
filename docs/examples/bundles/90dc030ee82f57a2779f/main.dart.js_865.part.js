((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,A={
jw(d,e,f,g,h,i,j,k,l,m,n,o){var x,w,v=null
if(i==null)x=f!=null?new B.ag(f,v,v,v,v,v,v,C.M):v
else x=i
if(o!=null||l!=null){w=g==null?v:g.GI(l,o)
if(w==null)w=B.dE(l,o)}else w=g
return new A.BK(e,d,n,x,k,w,h,j,v,m)},
R1:function R1(d,e){this.a=d
this.b=e},
a0K:function a0K(d,e){this.a=d
this.b=e},
BK:function BK(d,e,f,g,h,i,j,k,l,m){var _=this
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
bGz:function bGz(d,e){var _=this
_.fx=_.fr=_.dy=_.dx=_.db=_.cy=_.cx=_.CW=null
_.e=_.d=$
_.c9$=d
_.ak$=e
_.c=_.a=null},
dFK:function dFK(){},
dFL:function dFL(){},
dFM:function dFM(){},
dFN:function dFN(){},
dFO:function dFO(){},
dFP:function dFP(){},
dFQ:function dFQ(){},
dFR:function dFR(){},
hZc(){var x=new Float64Array(4)
x[3]=1
return new A.HD(x)},
HD:function HD(d){this.a=d}},D,E
B=c[0]
C=c[2]
A=a.updateHolder(c[140],A)
D=c[162]
E=c[163]
A.R1.prototype={
jd(d){var x=B.vy(this.a,this.b,d)
x.toString
return x}}
A.a0K.prototype={
jd(a8){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2=new B.oU(new Float64Array(3)),a3=new B.oU(new Float64Array(3)),a4=A.hZc(),a5=A.hZc(),a6=new B.oU(new Float64Array(3)),a7=new B.oU(new Float64Array(3))
this.a.aMY(a2,a4,a6)
this.b.aMY(a3,a5,a7)
x=1-a8
w=a2.yc(x).aA(0,a3.yc(a8))
v=a4.yc(x).aA(0,a5.yc(a8))
u=new Float64Array(4)
t=new A.HD(u)
t.iB(v)
t.bTq()
s=a6.yc(x).aA(0,a7.yc(a8))
x=new Float64Array(16)
v=new B.eK(x)
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
v.qL(x[0],x[1],x[2],1)
return v}}
A.BK.prototype={
n(){return new A.bGz(null,null)}}
A.bGz.prototype={
mW(d){var x,w,v=this,u=y.b
v.CW=u.a(d.$3(v.CW,v.a.w,new A.dFK()))
x=y.f
v.cx=x.a(d.$3(v.cx,v.a.x,new A.dFL()))
w=y.d
v.cy=w.a(d.$3(v.cy,v.a.y,new A.dFM()))
v.db=w.a(d.$3(v.db,v.a.z,new A.dFN()))
v.dx=y.e.a(d.$3(v.dx,v.a.Q,new A.dFO()))
w=v.dy
v.a.toString
v.dy=x.a(d.$3(w,null,new A.dFP()))
w=v.fr
v.a.toString
v.fr=y.w.a(d.$3(w,null,new A.dFQ()))
w=v.fx
v.a.toString
v.fx=u.a(d.$3(w,null,new A.dFR()))},
h(d){var x,w,v,u,t,s,r,q=this,p=null,o=q.giD(),n=q.CW
n=n==null?p:n.b5(o.gq())
x=q.cx
x=x==null?p:x.b5(o.gq())
w=q.cy
w=w==null?p:w.b5(o.gq())
v=q.db
v=v==null?p:v.b5(o.gq())
u=q.dx
u=u==null?p:u.b5(o.gq())
t=q.dy
t=t==null?p:t.b5(o.gq())
s=q.fr
s=s==null?p:s.b5(o.gq())
r=q.fx
r=r==null?p:r.b5(o.gq())
return B.aL(n,q.a.r,C.v,p,u,w,v,p,p,t,x,s,r,p)}}
A.HD.prototype={
iB(d){var x=d.a,w=this.a,v=x[0]
w.$flags&2&&B.cV(w)
w[0]=v
w[1]=x[1]
w[2]=x[2]
w[3]=x[3]},
aVg(d){var x,w,v,u,t,s=d.a,r=s[0],q=s[4],p=s[8],o=0+r+q+p
if(o>0){x=Math.sqrt(o+1)
r=this.a
r.$flags&2&&B.cV(r)
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
t.$flags&2&&B.cV(t)
t[w]=x*0.5
x=0.5/x
t[3]=(s[q+u]-s[p+v])*x
t[v]=(s[r+v]+s[q+w])*x
t[u]=(s[r+u]+s[p+w])*x}},
bTq(){var x,w,v,u=Math.sqrt(this.gRO())
if(u===0)return 0
x=1/u
w=this.a
v=w[0]
w.$flags&2&&B.cV(w)
w[0]=v*x
w[1]=w[1]*x
w[2]=w[2]*x
w[3]=w[3]*x
return u},
gRO(){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return w*w+v*v+u*u+t*t},
ga6(d){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return Math.sqrt(w*w+v*v+u*u+t*t)},
yc(d){var x=new Float64Array(4),w=new A.HD(x)
w.iB(this)
x[3]=x[3]*d
x[2]=x[2]*d
x[1]=x[1]*d
x[0]=x[0]*d
return w},
bd(a5,a6){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h=this.a,g=h[3],f=h[2],e=h[1],d=h[0],a0=a6.gbYJ(),a1=a0[3],a2=a0[2],a3=a0[1],a4=a0[0]
h=C.i.bd(g,a4)
x=C.i.bd(d,a1)
w=C.i.bd(e,a2)
v=C.i.bd(f,a3)
u=C.i.bd(g,a3)
t=C.i.bd(e,a1)
s=C.i.bd(f,a4)
r=C.i.bd(d,a2)
q=C.i.bd(g,a2)
p=C.i.bd(f,a1)
o=C.i.bd(d,a3)
n=C.i.bd(e,a4)
m=C.i.bd(g,a1)
l=C.i.bd(d,a4)
k=C.i.bd(e,a3)
j=C.i.bd(f,a2)
i=new Float64Array(4)
i[0]=h+x+w-v
i[1]=u+t+s-r
i[2]=q+p+o-n
i[3]=m-l-k-j
return new A.HD(i)},
i(d,e){var x,w,v
if(e==null)return!1
if(e instanceof A.HD){x=this.a
w=x[3]
v=e.a
x=w===v[3]&&x[2]===v[2]&&x[1]===v[1]&&x[0]===v[0]}else x=!1
return x},
gY(d){return B.cz(this.a)},
aA(d,e){var x,w=new Float64Array(4),v=new A.HD(w)
v.iB(this)
x=e.a
w[0]=w[0]+x[0]
w[1]=w[1]+x[1]
w[2]=w[2]+x[2]
w[3]=w[3]+x[3]
return v},
aQ(d,e){var x,w=new Float64Array(4),v=new A.HD(w)
v.iB(this)
x=e.a
w[0]=w[0]-x[0]
w[1]=w[1]-x[1]
w[2]=w[2]-x[2]
w[3]=w[3]-x[3]
return v},
p(d,e){return this.a[e]},
M(d,e,f){var x=this.a
x.$flags&2&&B.cV(x)
x[e]=f},
v(d){var x=this.a
return B.ak(x[0])+", "+B.ak(x[1])+", "+B.ak(x[2])+" @ "+B.ak(x[3])}}
var z=a.updateTypes(["r9(@)","xk(@)","R1(@)","a0K(@)"])
A.dFK.prototype={
$1(d){return new D.r9(y.k.a(d),null)},
$S:z+0}
A.dFL.prototype={
$1(d){return new E.xk(y.m.a(d),null)},
$S:z+1}
A.dFM.prototype={
$1(d){return new B.ur(y.r.a(d),null)},
$S:251}
A.dFN.prototype={
$1(d){return new B.ur(y.r.a(d),null)},
$S:251}
A.dFO.prototype={
$1(d){return new A.R1(y.a.a(d),null)},
$S:z+2}
A.dFP.prototype={
$1(d){return new E.xk(y.m.a(d),null)},
$S:z+1}
A.dFQ.prototype={
$1(d){return new A.a0K(y.E.a(d),null)},
$S:z+3}
A.dFR.prototype={
$1(d){return new D.r9(y.k.a(d),null)},
$S:z+0};(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.b4,[A.R1,A.a0K])
w(A.BK,B.qC)
w(A.bGz,B.pF)
x(B.ck,[A.dFK,A.dFL,A.dFM,A.dFN,A.dFO,A.dFP,A.dFQ,A.dFR])
w(A.HD,B.W)})()
B.bN(b.typeUniverse,JSON.parse('{"R1":{"b4":["A"],"bb":["A"],"bb.T":"A","b4.T":"A"},"a0K":{"b4":["eK"],"bb":["eK"],"bb.T":"eK","b4.T":"eK"},"BK":{"i":[],"b":[]},"bGz":{"k":["BK"]}}'))
var y=(function rtii(){var x=B.E
return{k:x("nm"),a:x("A"),r:x("ib"),m:x("es"),E:x("eK"),b:x("r9?"),e:x("R1?"),d:x("ur?"),f:x("xk?"),w:x("a0K?")}})()};
(a=>{a["sQdyhNUferLPnL6oNcZkSgBMxHo="]=a.current})($__dart_deferred_initializers__);