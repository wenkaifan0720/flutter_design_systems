((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,D,A={
jx(d,e,f,g,h,i,j,k,l,m,n,o){var x,w,v=null
if(i==null)x=f!=null?new B.ah(f,v,v,v,v,v,v,C.N):v
else x=i
if(o!=null||l!=null){w=g==null?v:g.Hw(l,o)
if(w==null)w=B.dH(l,o)}else w=g
return new A.CO(e,d,n,x,k,w,h,j,v,m)},
SH:function SH(d,e){this.a=d
this.b=e},
a3c:function a3c(d,e){this.a=d
this.b=e},
CO:function CO(d,e,f,g,h,i,j,k,l,m){var _=this
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
bQT:function bQT(d,e){var _=this
_.fx=_.fr=_.dy=_.dx=_.db=_.cy=_.cx=_.CW=null
_.e=_.d=$
_.ca$=d
_.al$=e
_.c=_.a=null},
dZt:function dZt(){},
dZu:function dZu(){},
dZv:function dZv(){},
dZw:function dZw(){},
dZx:function dZx(){},
dZy:function dZy(){},
dZz:function dZz(){},
dZA:function dZA(){},
izx(){var x=new Float64Array(4)
x[3]=1
return new A.IT(x)},
IT:function IT(d){this.a=d}},E
B=c[0]
C=c[2]
D=c[191]
A=a.updateHolder(c[152],A)
E=c[176]
A.SH.prototype={
jm(d){var x=B.wC(this.a,this.b,d)
x.toString
return x}}
A.a3c.prototype={
jm(a8){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2=new B.pG(new Float64Array(3)),a3=new B.pG(new Float64Array(3)),a4=A.izx(),a5=A.izx(),a6=new B.pG(new Float64Array(3)),a7=new B.pG(new Float64Array(3))
this.a.aPK(a2,a4,a6)
this.b.aPK(a3,a5,a7)
x=1-a8
w=a2.yP(x).aC(0,a3.yP(a8))
v=a4.yP(x).aC(0,a5.yP(a8))
u=new Float64Array(4)
t=new A.IT(u)
t.iO(v)
t.bXX()
s=a6.yP(x).aC(0,a7.yP(a8))
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
v.rq(x[0],x[1],x[2],1)
return v}}
A.CO.prototype={
p(){return new A.bQT(null,null)}}
A.bQT.prototype={
mR(d){var x,w,v=this,u=y.b
v.CW=u.a(d.$3(v.CW,v.a.w,new A.dZt()))
x=y.f
v.cx=x.a(d.$3(v.cx,v.a.x,new A.dZu()))
w=y.d
v.cy=w.a(d.$3(v.cy,v.a.y,new A.dZv()))
v.db=w.a(d.$3(v.db,v.a.z,new A.dZw()))
v.dx=y.e.a(d.$3(v.dx,v.a.Q,new A.dZx()))
w=v.dy
v.a.toString
v.dy=x.a(d.$3(w,null,new A.dZy()))
w=v.fr
v.a.toString
v.fr=y.w.a(d.$3(w,null,new A.dZz()))
w=v.fx
v.a.toString
v.fx=u.a(d.$3(w,null,new A.dZA()))},
h(d){var x,w,v,u,t,s,r,q=this,p=null,o=q.giG(),n=q.CW
n=n==null?p:n.b9(o.gt())
x=q.cx
x=x==null?p:x.b9(o.gt())
w=q.cy
w=w==null?p:w.b9(o.gt())
v=q.db
v=v==null?p:v.b9(o.gt())
u=q.dx
u=u==null?p:u.b9(o.gt())
t=q.dy
t=t==null?p:t.b9(o.gt())
s=q.fr
s=s==null?p:s.b9(o.gt())
r=q.fx
r=r==null?p:r.b9(o.gt())
return B.aN(n,q.a.r,C.u,p,u,w,v,p,p,t,x,s,r,p)}}
A.IT.prototype={
iO(d){var x=d.a,w=this.a,v=x[0]
w.$flags&2&&B.dh(w)
w[0]=v
w[1]=x[1]
w[2]=x[2]
w[3]=x[3]},
aXR(d){var x,w,v,u,t,s=d.a,r=s[0],q=s[4],p=s[8],o=0+r+q+p
if(o>0){x=Math.sqrt(o+1)
r=this.a
r.$flags&2&&B.dh(r)
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
t.$flags&2&&B.dh(t)
t[w]=x*0.5
x=0.5/x
t[3]=(s[q+u]-s[p+v])*x
t[v]=(s[r+v]+s[q+w])*x
t[u]=(s[r+u]+s[p+w])*x}},
bXX(){var x,w,v,u=Math.sqrt(this.gT_())
if(u===0)return 0
x=1/u
w=this.a
v=w[0]
w.$flags&2&&B.dh(w)
w[0]=v*x
w[1]=w[1]*x
w[2]=w[2]*x
w[3]=w[3]*x
return u},
gT_(){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return w*w+v*v+u*u+t*t},
gaa(d){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return Math.sqrt(w*w+v*v+u*u+t*t)},
yP(d){var x=new Float64Array(4),w=new A.IT(x)
w.iO(this)
x[3]=x[3]*d
x[2]=x[2]*d
x[1]=x[1]*d
x[0]=x[0]*d
return w},
bl(a5,a6){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h=this.a,g=h[3],f=h[2],e=h[1],d=h[0],a0=a6.gc2r(),a1=a0[3],a2=a0[2],a3=a0[1],a4=a0[0]
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
return new A.IT(i)},
i(d,e){var x,w,v
if(e==null)return!1
if(e instanceof A.IT){x=this.a
w=x[3]
v=e.a
x=w===v[3]&&x[2]===v[2]&&x[1]===v[1]&&x[0]===v[0]}else x=!1
return x},
ga3(d){return B.cB(this.a)},
aC(d,e){var x,w=new Float64Array(4),v=new A.IT(w)
v.iO(this)
x=e.a
w[0]=w[0]+x[0]
w[1]=w[1]+x[1]
w[2]=w[2]+x[2]
w[3]=w[3]+x[3]
return v},
aS(d,e){var x,w=new Float64Array(4),v=new A.IT(w)
v.iO(this)
x=e.a
w[0]=w[0]-x[0]
w[1]=w[1]-x[1]
w[2]=w[2]-x[2]
w[3]=w[3]-x[3]
return v},
q(d,e){return this.a[e]},
P(d,e,f){var x=this.a
x.$flags&2&&B.dh(x)
x[e]=f},
B(d){var x=this.a
return B.am(x[0])+", "+B.am(x[1])+", "+B.am(x[2])+" @ "+B.am(x[3])}}
var z=a.updateTypes(["rV(@)","yB(@)","SH(@)","a3c(@)"])
A.dZt.prototype={
$1(d){return new E.rV(y.k.a(d),null)},
$S:z+0}
A.dZu.prototype={
$1(d){return new D.yB(y.m.a(d),null)},
$S:z+1}
A.dZv.prototype={
$1(d){return new B.vn(y.r.a(d),null)},
$S:251}
A.dZw.prototype={
$1(d){return new B.vn(y.r.a(d),null)},
$S:251}
A.dZx.prototype={
$1(d){return new A.SH(y.a.a(d),null)},
$S:z+2}
A.dZy.prototype={
$1(d){return new D.yB(y.m.a(d),null)},
$S:z+1}
A.dZz.prototype={
$1(d){return new A.a3c(y.E.a(d),null)},
$S:z+3}
A.dZA.prototype={
$1(d){return new E.rV(y.k.a(d),null)},
$S:z+0};(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.b9,[A.SH,A.a3c])
w(A.CO,B.q0)
w(A.bQT,B.pf)
x(B.cl,[A.dZt,A.dZu,A.dZv,A.dZw,A.dZx,A.dZy,A.dZz,A.dZA])
w(A.IT,B.Y)})()
B.bO(b.typeUniverse,JSON.parse('{"SH":{"b9":["B"],"bf":["B"],"bf.T":"B","b9.T":"B"},"a3c":{"b9":["eV"],"bf":["eV"],"bf.T":"eV","b9.T":"eV"},"CO":{"j":[],"b":[]},"bQT":{"l":["CO"]}}'))
var y=(function rtii(){var x=B.G
return{k:x("o6"),a:x("B"),r:x("iH"),m:x("eD"),E:x("eV"),b:x("rV?"),e:x("SH?"),d:x("vn?"),f:x("yB?"),w:x("a3c?")}})()};
(a=>{a["i1NaFfLLP4zLDpS26KTm6FrWGYw="]=a.current})($__dart_deferred_initializers__);