((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,D,A={
js(d,e,f,g,h,i,j,k,l,m,n,o){var x,w,v=null
if(i==null)x=f!=null?new B.ah(f,v,v,v,v,v,v,C.N):v
else x=i
if(o!=null||l!=null){w=g==null?v:g.Hh(l,o)
if(w==null)w=B.dG(l,o)}else w=g
return new A.CM(e,d,n,x,k,w,h,j,v,m)},
SB:function SB(d,e){this.a=d
this.b=e},
a38:function a38(d,e){this.a=d
this.b=e},
CM:function CM(d,e,f,g,h,i,j,k,l,m){var _=this
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
bQJ:function bQJ(d,e){var _=this
_.fx=_.fr=_.dy=_.dx=_.db=_.cy=_.cx=_.CW=null
_.e=_.d=$
_.c8$=d
_.ak$=e
_.c=_.a=null},
dZc:function dZc(){},
dZd:function dZd(){},
dZe:function dZe(){},
dZf:function dZf(){},
dZg:function dZg(){},
dZh:function dZh(){},
dZi:function dZi(){},
dZj:function dZj(){},
iyJ(){var x=new Float64Array(4)
x[3]=1
return new A.IR(x)},
IR:function IR(d){this.a=d}},E
B=c[0]
C=c[2]
D=c[190]
A=a.updateHolder(c[151],A)
E=c[175]
A.SB.prototype={
jk(d){var x=B.wB(this.a,this.b,d)
x.toString
return x}}
A.a38.prototype={
jk(a8){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2=new B.pF(new Float64Array(3)),a3=new B.pF(new Float64Array(3)),a4=A.iyJ(),a5=A.iyJ(),a6=new B.pF(new Float64Array(3)),a7=new B.pF(new Float64Array(3))
this.a.aPe(a2,a4,a6)
this.b.aPe(a3,a5,a7)
x=1-a8
w=a2.yF(x).aB(0,a3.yF(a8))
v=a4.yF(x).aB(0,a5.yF(a8))
u=new Float64Array(4)
t=new A.IR(u)
t.iM(v)
t.bXy()
s=a6.yF(x).aB(0,a7.yF(a8))
x=new Float64Array(16)
v=new B.eX(x)
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
v.ra(x[0],x[1],x[2],1)
return v}}
A.CM.prototype={
n(){return new A.bQJ(null,null)}}
A.bQJ.prototype={
mC(d){var x,w,v=this,u=y.b
v.CW=u.a(d.$3(v.CW,v.a.w,new A.dZc()))
x=y.f
v.cx=x.a(d.$3(v.cx,v.a.x,new A.dZd()))
w=y.d
v.cy=w.a(d.$3(v.cy,v.a.y,new A.dZe()))
v.db=w.a(d.$3(v.db,v.a.z,new A.dZf()))
v.dx=y.e.a(d.$3(v.dx,v.a.Q,new A.dZg()))
w=v.dy
v.a.toString
v.dy=x.a(d.$3(w,null,new A.dZh()))
w=v.fr
v.a.toString
v.fr=y.w.a(d.$3(w,null,new A.dZi()))
w=v.fx
v.a.toString
v.fx=u.a(d.$3(w,null,new A.dZj()))},
h(d){var x,w,v,u,t,s,r,q=this,p=null,o=q.giE(),n=q.CW
n=n==null?p:n.b8(o.gq())
x=q.cx
x=x==null?p:x.b8(o.gq())
w=q.cy
w=w==null?p:w.b8(o.gq())
v=q.db
v=v==null?p:v.b8(o.gq())
u=q.dx
u=u==null?p:u.b8(o.gq())
t=q.dy
t=t==null?p:t.b8(o.gq())
s=q.fr
s=s==null?p:s.b8(o.gq())
r=q.fx
r=r==null?p:r.b8(o.gq())
return B.aN(n,q.a.r,C.u,p,u,w,v,p,p,t,x,s,r,p)}}
A.IR.prototype={
iM(d){var x=d.a,w=this.a,v=x[0]
w.$flags&2&&B.dg(w)
w[0]=v
w[1]=x[1]
w[2]=x[2]
w[3]=x[3]},
aXy(d){var x,w,v,u,t,s=d.a,r=s[0],q=s[4],p=s[8],o=0+r+q+p
if(o>0){x=Math.sqrt(o+1)
r=this.a
r.$flags&2&&B.dg(r)
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
t.$flags&2&&B.dg(t)
t[w]=x*0.5
x=0.5/x
t[3]=(s[q+u]-s[p+v])*x
t[v]=(s[r+v]+s[q+w])*x
t[u]=(s[r+u]+s[p+w])*x}},
bXy(){var x,w,v,u=Math.sqrt(this.gSH())
if(u===0)return 0
x=1/u
w=this.a
v=w[0]
w.$flags&2&&B.dg(w)
w[0]=v*x
w[1]=w[1]*x
w[2]=w[2]*x
w[3]=w[3]*x
return u},
gSH(){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return w*w+v*v+u*u+t*t},
ga9(d){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return Math.sqrt(w*w+v*v+u*u+t*t)},
yF(d){var x=new Float64Array(4),w=new A.IR(x)
w.iM(this)
x[3]=x[3]*d
x[2]=x[2]*d
x[1]=x[1]*d
x[0]=x[0]*d
return w},
bk(a5,a6){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h=this.a,g=h[3],f=h[2],e=h[1],d=h[0],a0=a6.gc22(),a1=a0[3],a2=a0[2],a3=a0[1],a4=a0[0]
h=C.i.bk(g,a4)
x=C.i.bk(d,a1)
w=C.i.bk(e,a2)
v=C.i.bk(f,a3)
u=C.i.bk(g,a3)
t=C.i.bk(e,a1)
s=C.i.bk(f,a4)
r=C.i.bk(d,a2)
q=C.i.bk(g,a2)
p=C.i.bk(f,a1)
o=C.i.bk(d,a3)
n=C.i.bk(e,a4)
m=C.i.bk(g,a1)
l=C.i.bk(d,a4)
k=C.i.bk(e,a3)
j=C.i.bk(f,a2)
i=new Float64Array(4)
i[0]=h+x+w-v
i[1]=u+t+s-r
i[2]=q+p+o-n
i[3]=m-l-k-j
return new A.IR(i)},
i(d,e){var x,w,v
if(e==null)return!1
if(e instanceof A.IR){x=this.a
w=x[3]
v=e.a
x=w===v[3]&&x[2]===v[2]&&x[1]===v[1]&&x[0]===v[0]}else x=!1
return x},
ga2(d){return B.cA(this.a)},
aB(d,e){var x,w=new Float64Array(4),v=new A.IR(w)
v.iM(this)
x=e.a
w[0]=w[0]+x[0]
w[1]=w[1]+x[1]
w[2]=w[2]+x[2]
w[3]=w[3]+x[3]
return v},
aR(d,e){var x,w=new Float64Array(4),v=new A.IR(w)
v.iM(this)
x=e.a
w[0]=w[0]-x[0]
w[1]=w[1]-x[1]
w[2]=w[2]-x[2]
w[3]=w[3]-x[3]
return v},
p(d,e){return this.a[e]},
O(d,e,f){var x=this.a
x.$flags&2&&B.dg(x)
x[e]=f},
A(d){var x=this.a
return B.an(x[0])+", "+B.an(x[1])+", "+B.an(x[2])+" @ "+B.an(x[3])}}
var z=a.updateTypes(["rT(@)","yx(@)","SB(@)","a38(@)"])
A.dZc.prototype={
$1(d){return new E.rT(y.k.a(d),null)},
$S:z+0}
A.dZd.prototype={
$1(d){return new D.yx(y.m.a(d),null)},
$S:z+1}
A.dZe.prototype={
$1(d){return new B.vj(y.r.a(d),null)},
$S:256}
A.dZf.prototype={
$1(d){return new B.vj(y.r.a(d),null)},
$S:256}
A.dZg.prototype={
$1(d){return new A.SB(y.a.a(d),null)},
$S:z+2}
A.dZh.prototype={
$1(d){return new D.yx(y.m.a(d),null)},
$S:z+1}
A.dZi.prototype={
$1(d){return new A.a38(y.E.a(d),null)},
$S:z+3}
A.dZj.prototype={
$1(d){return new E.rT(y.k.a(d),null)},
$S:z+0};(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.b8,[A.SB,A.a38])
w(A.CM,B.pY)
w(A.bQJ,B.pe)
x(B.cm,[A.dZc,A.dZd,A.dZe,A.dZf,A.dZg,A.dZh,A.dZi,A.dZj])
w(A.IR,B.X)})()
B.bN(b.typeUniverse,JSON.parse('{"SB":{"b8":["A"],"be":["A"],"be.T":"A","b8.T":"A"},"a38":{"b8":["eX"],"be":["eX"],"be.T":"eX","b8.T":"eX"},"CM":{"i":[],"b":[]},"bQJ":{"k":["CM"]}}'))
var y=(function rtii(){var x=B.F
return{k:x("o4"),a:x("A"),r:x("iD"),m:x("eA"),E:x("eX"),b:x("rT?"),e:x("SB?"),d:x("vj?"),f:x("yx?"),w:x("a38?")}})()};
(a=>{a["TzINk0W5DgK7v45Fv8i8+lDAPuE="]=a.current})($__dart_deferred_initializers__);