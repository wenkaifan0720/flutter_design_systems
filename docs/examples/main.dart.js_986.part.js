((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,D,A={
js(d,e,f,g,h,i,j,k,l,m,n,o){var x,w,v=null
if(i==null)x=f!=null?new B.ag(f,v,v,v,v,v,v,C.N):v
else x=i
if(o!=null||l!=null){w=g==null?v:g.Hd(l,o)
if(w==null)w=B.dO(l,o)}else w=g
return new A.CK(e,d,n,x,k,w,h,j,v,m)},
Ss:function Ss(d,e){this.a=d
this.b=e},
a37:function a37(d,e){this.a=d
this.b=e},
CK:function CK(d,e,f,g,h,i,j,k,l,m){var _=this
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
bQp:function bQp(d,e){var _=this
_.fx=_.fr=_.dy=_.dx=_.db=_.cy=_.cx=_.CW=null
_.e=_.d=$
_.c7$=d
_.ai$=e
_.c=_.a=null},
dYi:function dYi(){},
dYj:function dYj(){},
dYk:function dYk(){},
dYl:function dYl(){},
dYm:function dYm(){},
dYn:function dYn(){},
dYo:function dYo(){},
dYp:function dYp(){},
ixB(){var x=new Float64Array(4)
x[3]=1
return new A.IO(x)},
IO:function IO(d){this.a=d}},E
B=c[0]
C=c[2]
D=c[190]
A=a.updateHolder(c[151],A)
E=c[175]
A.Ss.prototype={
ji(d){var x=B.ww(this.a,this.b,d)
x.toString
return x}}
A.a37.prototype={
ji(a8){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2=new B.pE(new Float64Array(3)),a3=new B.pE(new Float64Array(3)),a4=A.ixB(),a5=A.ixB(),a6=new B.pE(new Float64Array(3)),a7=new B.pE(new Float64Array(3))
this.a.aP7(a2,a4,a6)
this.b.aP7(a3,a5,a7)
x=1-a8
w=a2.yE(x).aB(0,a3.yE(a8))
v=a4.yE(x).aB(0,a5.yE(a8))
u=new Float64Array(4)
t=new A.IO(u)
t.iJ(v)
t.bXl()
s=a6.yE(x).aB(0,a7.yE(a8))
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
v.r6(x[0],x[1],x[2],1)
return v}}
A.CK.prototype={
n(){return new A.bQp(null,null)}}
A.bQp.prototype={
mA(d){var x,w,v=this,u=y.b
v.CW=u.a(d.$3(v.CW,v.a.w,new A.dYi()))
x=y.f
v.cx=x.a(d.$3(v.cx,v.a.x,new A.dYj()))
w=y.d
v.cy=w.a(d.$3(v.cy,v.a.y,new A.dYk()))
v.db=w.a(d.$3(v.db,v.a.z,new A.dYl()))
v.dx=y.e.a(d.$3(v.dx,v.a.Q,new A.dYm()))
w=v.dy
v.a.toString
v.dy=x.a(d.$3(w,null,new A.dYn()))
w=v.fr
v.a.toString
v.fr=y.w.a(d.$3(w,null,new A.dYo()))
w=v.fx
v.a.toString
v.fx=u.a(d.$3(w,null,new A.dYp()))},
h(d){var x,w,v,u,t,s,r,q=this,p=null,o=q.giB(),n=q.CW
n=n==null?p:n.b7(o.gq())
x=q.cx
x=x==null?p:x.b7(o.gq())
w=q.cy
w=w==null?p:w.b7(o.gq())
v=q.db
v=v==null?p:v.b7(o.gq())
u=q.dx
u=u==null?p:u.b7(o.gq())
t=q.dy
t=t==null?p:t.b7(o.gq())
s=q.fr
s=s==null?p:s.b7(o.gq())
r=q.fx
r=r==null?p:r.b7(o.gq())
return B.aN(n,q.a.r,C.u,p,u,w,v,p,p,t,x,s,r,p)}}
A.IO.prototype={
iJ(d){var x=d.a,w=this.a,v=x[0]
w.$flags&2&&B.dc(w)
w[0]=v
w[1]=x[1]
w[2]=x[2]
w[3]=x[3]},
aXr(d){var x,w,v,u,t,s=d.a,r=s[0],q=s[4],p=s[8],o=0+r+q+p
if(o>0){x=Math.sqrt(o+1)
r=this.a
r.$flags&2&&B.dc(r)
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
t.$flags&2&&B.dc(t)
t[w]=x*0.5
x=0.5/x
t[3]=(s[q+u]-s[p+v])*x
t[v]=(s[r+v]+s[q+w])*x
t[u]=(s[r+u]+s[p+w])*x}},
bXl(){var x,w,v,u=Math.sqrt(this.gSF())
if(u===0)return 0
x=1/u
w=this.a
v=w[0]
w.$flags&2&&B.dc(w)
w[0]=v*x
w[1]=w[1]*x
w[2]=w[2]*x
w[3]=w[3]*x
return u},
gSF(){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return w*w+v*v+u*u+t*t},
ga8(d){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return Math.sqrt(w*w+v*v+u*u+t*t)},
yE(d){var x=new Float64Array(4),w=new A.IO(x)
w.iJ(this)
x[3]=x[3]*d
x[2]=x[2]*d
x[1]=x[1]*d
x[0]=x[0]*d
return w},
bi(a5,a6){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h=this.a,g=h[3],f=h[2],e=h[1],d=h[0],a0=a6.gc1P(),a1=a0[3],a2=a0[2],a3=a0[1],a4=a0[0]
h=C.i.bi(g,a4)
x=C.i.bi(d,a1)
w=C.i.bi(e,a2)
v=C.i.bi(f,a3)
u=C.i.bi(g,a3)
t=C.i.bi(e,a1)
s=C.i.bi(f,a4)
r=C.i.bi(d,a2)
q=C.i.bi(g,a2)
p=C.i.bi(f,a1)
o=C.i.bi(d,a3)
n=C.i.bi(e,a4)
m=C.i.bi(g,a1)
l=C.i.bi(d,a4)
k=C.i.bi(e,a3)
j=C.i.bi(f,a2)
i=new Float64Array(4)
i[0]=h+x+w-v
i[1]=u+t+s-r
i[2]=q+p+o-n
i[3]=m-l-k-j
return new A.IO(i)},
i(d,e){var x,w,v
if(e==null)return!1
if(e instanceof A.IO){x=this.a
w=x[3]
v=e.a
x=w===v[3]&&x[2]===v[2]&&x[1]===v[1]&&x[0]===v[0]}else x=!1
return x},
ga2(d){return B.cz(this.a)},
aB(d,e){var x,w=new Float64Array(4),v=new A.IO(w)
v.iJ(this)
x=e.a
w[0]=w[0]+x[0]
w[1]=w[1]+x[1]
w[2]=w[2]+x[2]
w[3]=w[3]+x[3]
return v},
aQ(d,e){var x,w=new Float64Array(4),v=new A.IO(w)
v.iJ(this)
x=e.a
w[0]=w[0]-x[0]
w[1]=w[1]-x[1]
w[2]=w[2]-x[2]
w[3]=w[3]-x[3]
return v},
p(d,e){return this.a[e]},
O(d,e,f){var x=this.a
x.$flags&2&&B.dc(x)
x[e]=f},
A(d){var x=this.a
return B.am(x[0])+", "+B.am(x[1])+", "+B.am(x[2])+" @ "+B.am(x[3])}}
var z=a.updateTypes(["rS(@)","yu(@)","Ss(@)","a37(@)"])
A.dYi.prototype={
$1(d){return new E.rS(y.k.a(d),null)},
$S:z+0}
A.dYj.prototype={
$1(d){return new D.yu(y.m.a(d),null)},
$S:z+1}
A.dYk.prototype={
$1(d){return new B.vg(y.r.a(d),null)},
$S:246}
A.dYl.prototype={
$1(d){return new B.vg(y.r.a(d),null)},
$S:246}
A.dYm.prototype={
$1(d){return new A.Ss(y.a.a(d),null)},
$S:z+2}
A.dYn.prototype={
$1(d){return new D.yu(y.m.a(d),null)},
$S:z+1}
A.dYo.prototype={
$1(d){return new A.a37(y.E.a(d),null)},
$S:z+3}
A.dYp.prototype={
$1(d){return new E.rS(y.k.a(d),null)},
$S:z+0};(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.b8,[A.Ss,A.a37])
w(A.CK,B.pW)
w(A.bQp,B.pc)
x(B.cl,[A.dYi,A.dYj,A.dYk,A.dYl,A.dYm,A.dYn,A.dYo,A.dYp])
w(A.IO,B.W)})()
B.bM(b.typeUniverse,JSON.parse('{"Ss":{"b8":["A"],"be":["A"],"be.T":"A","b8.T":"A"},"a37":{"b8":["eX"],"be":["eX"],"be.T":"eX","b8.T":"eX"},"CK":{"i":[],"b":[]},"bQp":{"k":["CK"]}}'))
var y=(function rtii(){var x=B.F
return{k:x("o3"),a:x("A"),r:x("iC"),m:x("ez"),E:x("eX"),b:x("rS?"),e:x("Ss?"),d:x("vg?"),f:x("yu?"),w:x("a37?")}})()};
(a=>{a["5pjQbh9d9LQnYFeLwfGEq8GhHEM="]=a.current})($__dart_deferred_initializers__);