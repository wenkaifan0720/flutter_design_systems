((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,A={
js(d,e,f,g,h,i,j,k,l,m,n,o){var x,w,v=null
if(i==null)x=f!=null?new B.ag(f,v,v,v,v,v,v,C.M):v
else x=i
if(o!=null||l!=null){w=g==null?v:g.GC(l,o)
if(w==null)w=B.dE(l,o)}else w=g
return new A.BD(e,d,n,x,k,w,h,j,v,m)},
QO:function QO(d,e){this.a=d
this.b=e},
a0F:function a0F(d,e){this.a=d
this.b=e},
BD:function BD(d,e,f,g,h,i,j,k,l,m){var _=this
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
bFg:function bFg(d,e){var _=this
_.fx=_.fr=_.dy=_.dx=_.db=_.cy=_.cx=_.CW=null
_.e=_.d=$
_.cf$=d
_.ao$=e
_.c=_.a=null},
dEq:function dEq(){},
dEr:function dEr(){},
dEs:function dEs(){},
dEt:function dEt(){},
dEu:function dEu(){},
dEv:function dEv(){},
dEw:function dEw(){},
dEx:function dEx(){},
hVS(){var x=new Float64Array(4)
x[3]=1
return new A.Ht(x)},
Ht:function Ht(d){this.a=d}},D,E
B=c[0]
C=c[2]
A=a.updateHolder(c[137],A)
D=c[158]
E=c[159]
A.QO.prototype={
ja(d){var x=B.vs(this.a,this.b,d)
x.toString
return x}}
A.a0F.prototype={
ja(a8){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2=new B.oK(new Float64Array(3)),a3=new B.oK(new Float64Array(3)),a4=A.hVS(),a5=A.hVS(),a6=new B.oK(new Float64Array(3)),a7=new B.oK(new Float64Array(3))
this.a.aM4(a2,a4,a6)
this.b.aM4(a3,a5,a7)
x=1-a8
w=a2.y5(x).az(0,a3.y5(a8))
v=a4.y5(x).az(0,a5.y5(a8))
u=new Float64Array(4)
t=new A.Ht(u)
t.iy(v)
t.bSf()
s=a6.y5(x).az(0,a7.y5(a8))
x=new Float64Array(16)
v=new B.eB(x)
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
v.qK(x[0],x[1],x[2],1)
return v}}
A.BD.prototype={
n(){return new A.bFg(null,null)}}
A.bFg.prototype={
mU(d){var x,w,v=this,u=y.b
v.CW=u.a(d.$3(v.CW,v.a.w,new A.dEq()))
x=y.f
v.cx=x.a(d.$3(v.cx,v.a.x,new A.dEr()))
w=y.d
v.cy=w.a(d.$3(v.cy,v.a.y,new A.dEs()))
v.db=w.a(d.$3(v.db,v.a.z,new A.dEt()))
v.dx=y.e.a(d.$3(v.dx,v.a.Q,new A.dEu()))
w=v.dy
v.a.toString
v.dy=x.a(d.$3(w,null,new A.dEv()))
w=v.fr
v.a.toString
v.fr=y.w.a(d.$3(w,null,new A.dEw()))
w=v.fx
v.a.toString
v.fx=u.a(d.$3(w,null,new A.dEx()))},
h(d){var x,w,v,u,t,s,r,q=this,p=null,o=q.giA(),n=q.CW
n=n==null?p:n.b3(o.gq())
x=q.cx
x=x==null?p:x.b3(o.gq())
w=q.cy
w=w==null?p:w.b3(o.gq())
v=q.db
v=v==null?p:v.b3(o.gq())
u=q.dx
u=u==null?p:u.b3(o.gq())
t=q.dy
t=t==null?p:t.b3(o.gq())
s=q.fr
s=s==null?p:s.b3(o.gq())
r=q.fx
r=r==null?p:r.b3(o.gq())
return B.aL(n,q.a.r,C.w,p,u,w,v,p,p,t,x,s,r,p)}}
A.Ht.prototype={
iy(d){var x=d.a,w=this.a,v=x[0]
w.$flags&2&&B.cU(w)
w[0]=v
w[1]=x[1]
w[2]=x[2]
w[3]=x[3]},
aUo(d){var x,w,v,u,t,s=d.a,r=s[0],q=s[4],p=s[8],o=0+r+q+p
if(o>0){x=Math.sqrt(o+1)
r=this.a
r.$flags&2&&B.cU(r)
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
t.$flags&2&&B.cU(t)
t[w]=x*0.5
x=0.5/x
t[3]=(s[q+u]-s[p+v])*x
t[v]=(s[r+v]+s[q+w])*x
t[u]=(s[r+u]+s[p+w])*x}},
bSf(){var x,w,v,u=Math.sqrt(this.gRE())
if(u===0)return 0
x=1/u
w=this.a
v=w[0]
w.$flags&2&&B.cU(w)
w[0]=v*x
w[1]=w[1]*x
w[2]=w[2]*x
w[3]=w[3]*x
return u},
gRE(){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return w*w+v*v+u*u+t*t},
ga5(d){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return Math.sqrt(w*w+v*v+u*u+t*t)},
y5(d){var x=new Float64Array(4),w=new A.Ht(x)
w.iy(this)
x[3]=x[3]*d
x[2]=x[2]*d
x[1]=x[1]*d
x[0]=x[0]*d
return w},
bc(a5,a6){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h=this.a,g=h[3],f=h[2],e=h[1],d=h[0],a0=a6.gbXw(),a1=a0[3],a2=a0[2],a3=a0[1],a4=a0[0]
h=C.i.bc(g,a4)
x=C.i.bc(d,a1)
w=C.i.bc(e,a2)
v=C.i.bc(f,a3)
u=C.i.bc(g,a3)
t=C.i.bc(e,a1)
s=C.i.bc(f,a4)
r=C.i.bc(d,a2)
q=C.i.bc(g,a2)
p=C.i.bc(f,a1)
o=C.i.bc(d,a3)
n=C.i.bc(e,a4)
m=C.i.bc(g,a1)
l=C.i.bc(d,a4)
k=C.i.bc(e,a3)
j=C.i.bc(f,a2)
i=new Float64Array(4)
i[0]=h+x+w-v
i[1]=u+t+s-r
i[2]=q+p+o-n
i[3]=m-l-k-j
return new A.Ht(i)},
i(d,e){var x,w,v
if(e==null)return!1
if(e instanceof A.Ht){x=this.a
w=x[3]
v=e.a
x=w===v[3]&&x[2]===v[2]&&x[1]===v[1]&&x[0]===v[0]}else x=!1
return x},
gY(d){return B.cz(this.a)},
az(d,e){var x,w=new Float64Array(4),v=new A.Ht(w)
v.iy(this)
x=e.a
w[0]=w[0]+x[0]
w[1]=w[1]+x[1]
w[2]=w[2]+x[2]
w[3]=w[3]+x[3]
return v},
aQ(d,e){var x,w=new Float64Array(4),v=new A.Ht(w)
v.iy(this)
x=e.a
w[0]=w[0]-x[0]
w[1]=w[1]-x[1]
w[2]=w[2]-x[2]
w[3]=w[3]-x[3]
return v},
p(d,e){return this.a[e]},
M(d,e,f){var x=this.a
x.$flags&2&&B.cU(x)
x[e]=f},
v(d){var x=this.a
return B.al(x[0])+", "+B.al(x[1])+", "+B.al(x[2])+" @ "+B.al(x[3])}}
var z=a.updateTypes(["r2(@)","xp(@)","QO(@)","a0F(@)"])
A.dEq.prototype={
$1(d){return new D.r2(y.k.a(d),null)},
$S:z+0}
A.dEr.prototype={
$1(d){return new E.xp(y.m.a(d),null)},
$S:z+1}
A.dEs.prototype={
$1(d){return new B.uk(y.r.a(d),null)},
$S:249}
A.dEt.prototype={
$1(d){return new B.uk(y.r.a(d),null)},
$S:249}
A.dEu.prototype={
$1(d){return new A.QO(y.a.a(d),null)},
$S:z+2}
A.dEv.prototype={
$1(d){return new E.xp(y.m.a(d),null)},
$S:z+1}
A.dEw.prototype={
$1(d){return new A.a0F(y.E.a(d),null)},
$S:z+3}
A.dEx.prototype={
$1(d){return new D.r2(y.k.a(d),null)},
$S:z+0};(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.b3,[A.QO,A.a0F])
w(A.BD,B.qB)
w(A.bFg,B.pw)
x(B.cn,[A.dEq,A.dEr,A.dEs,A.dEt,A.dEu,A.dEv,A.dEw,A.dEx])
w(A.Ht,B.V)})()
B.bN(b.typeUniverse,JSON.parse('{"QO":{"b3":["A"],"bb":["A"],"bb.T":"A","b3.T":"A"},"a0F":{"b3":["eB"],"bb":["eB"],"bb.T":"eB","b3.T":"eB"},"BD":{"k":[],"b":[]},"bFg":{"l":["BD"]}}'))
var y=(function rtii(){var x=B.D
return{k:x("ne"),a:x("A"),r:x("i5"),m:x("ep"),E:x("eB"),b:x("r2?"),e:x("QO?"),d:x("uk?"),f:x("xp?"),w:x("a0F?")}})()};
(a=>{a["Yl9Tp9djVCcVd97oan1Oyl76U6Y="]=a.current})($__dart_deferred_initializers__);