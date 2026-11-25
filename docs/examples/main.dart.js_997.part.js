((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,D,A={
jy(d,e,f,g,h,i,j,k,l,m,n,o){var x,w,v=null
if(i==null)x=f!=null?new B.ah(f,v,v,v,v,v,v,C.N):v
else x=i
if(o!=null||l!=null){w=g==null?v:g.HA(l,o)
if(w==null)w=B.dI(l,o)}else w=g
return new A.CP(e,d,n,x,k,w,h,j,v,m)},
SP:function SP(d,e){this.a=d
this.b=e},
a3m:function a3m(d,e){this.a=d
this.b=e},
CP:function CP(d,e,f,g,h,i,j,k,l,m){var _=this
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
bR7:function bR7(d,e){var _=this
_.fx=_.fr=_.dy=_.dx=_.db=_.cy=_.cx=_.CW=null
_.e=_.d=$
_.ca$=d
_.al$=e
_.c=_.a=null},
e_a:function e_a(){},
e_b:function e_b(){},
e_c:function e_c(){},
e_d:function e_d(){},
e_e:function e_e(){},
e_f:function e_f(){},
e_g:function e_g(){},
e_h:function e_h(){},
iB0(){var x=new Float64Array(4)
x[3]=1
return new A.IW(x)},
IW:function IW(d){this.a=d}},E
B=c[0]
C=c[2]
D=c[193]
A=a.updateHolder(c[153],A)
E=c[178]
A.SP.prototype={
jn(d){var x=B.wF(this.a,this.b,d)
x.toString
return x}}
A.a3m.prototype={
jn(a8){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2=new B.pJ(new Float64Array(3)),a3=new B.pJ(new Float64Array(3)),a4=A.iB0(),a5=A.iB0(),a6=new B.pJ(new Float64Array(3)),a7=new B.pJ(new Float64Array(3))
this.a.aQ1(a2,a4,a6)
this.b.aQ1(a3,a5,a7)
x=1-a8
w=a2.yZ(x).aC(0,a3.yZ(a8))
v=a4.yZ(x).aC(0,a5.yZ(a8))
u=new Float64Array(4)
t=new A.IW(u)
t.iO(v)
t.bYp()
s=a6.yZ(x).aC(0,a7.yZ(a8))
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
v.rt(x[0],x[1],x[2],1)
return v}}
A.CP.prototype={
p(){return new A.bR7(null,null)}}
A.bR7.prototype={
mT(d){var x,w,v=this,u=y.b
v.CW=u.a(d.$3(v.CW,v.a.w,new A.e_a()))
x=y.f
v.cx=x.a(d.$3(v.cx,v.a.x,new A.e_b()))
w=y.d
v.cy=w.a(d.$3(v.cy,v.a.y,new A.e_c()))
v.db=w.a(d.$3(v.db,v.a.z,new A.e_d()))
v.dx=y.e.a(d.$3(v.dx,v.a.Q,new A.e_e()))
w=v.dy
v.a.toString
v.dy=x.a(d.$3(w,null,new A.e_f()))
w=v.fr
v.a.toString
v.fr=y.w.a(d.$3(w,null,new A.e_g()))
w=v.fx
v.a.toString
v.fx=u.a(d.$3(w,null,new A.e_h()))},
h(d){var x,w,v,u,t,s,r,q=this,p=null,o=q.giH(),n=q.CW
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
return B.aO(n,q.a.r,C.v,p,u,w,v,p,p,t,x,s,r,p)}}
A.IW.prototype={
iO(d){var x=d.a,w=this.a,v=x[0]
w.$flags&2&&B.dh(w)
w[0]=v
w[1]=x[1]
w[2]=x[2]
w[3]=x[3]},
aY8(d){var x,w,v,u,t,s=d.a,r=s[0],q=s[4],p=s[8],o=0+r+q+p
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
bYp(){var x,w,v,u=Math.sqrt(this.gTb())
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
gTb(){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return w*w+v*v+u*u+t*t},
gaa(d){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return Math.sqrt(w*w+v*v+u*u+t*t)},
yZ(d){var x=new Float64Array(4),w=new A.IW(x)
w.iO(this)
x[3]=x[3]*d
x[2]=x[2]*d
x[1]=x[1]*d
x[0]=x[0]*d
return w},
bn(a5,a6){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h=this.a,g=h[3],f=h[2],e=h[1],d=h[0],a0=a6.gc2V(),a1=a0[3],a2=a0[2],a3=a0[1],a4=a0[0]
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
return new A.IW(i)},
i(d,e){var x,w,v
if(e==null)return!1
if(e instanceof A.IW){x=this.a
w=x[3]
v=e.a
x=w===v[3]&&x[2]===v[2]&&x[1]===v[1]&&x[0]===v[0]}else x=!1
return x},
ga3(d){return B.cD(this.a)},
aC(d,e){var x,w=new Float64Array(4),v=new A.IW(w)
v.iO(this)
x=e.a
w[0]=w[0]+x[0]
w[1]=w[1]+x[1]
w[2]=w[2]+x[2]
w[3]=w[3]+x[3]
return v},
aS(d,e){var x,w=new Float64Array(4),v=new A.IW(w)
v.iO(this)
x=e.a
w[0]=w[0]-x[0]
w[1]=w[1]-x[1]
w[2]=w[2]-x[2]
w[3]=w[3]-x[3]
return v},
q(d,e){return this.a[e]},
R(d,e,f){var x=this.a
x.$flags&2&&B.dh(x)
x[e]=f},
B(d){var x=this.a
return B.an(x[0])+", "+B.an(x[1])+", "+B.an(x[2])+" @ "+B.an(x[3])}}
var z=a.updateTypes(["rY(@)","yE(@)","SP(@)","a3m(@)"])
A.e_a.prototype={
$1(d){return new E.rY(y.k.a(d),null)},
$S:z+0}
A.e_b.prototype={
$1(d){return new D.yE(y.m.a(d),null)},
$S:z+1}
A.e_c.prototype={
$1(d){return new B.vp(y.r.a(d),null)},
$S:278}
A.e_d.prototype={
$1(d){return new B.vp(y.r.a(d),null)},
$S:278}
A.e_e.prototype={
$1(d){return new A.SP(y.a.a(d),null)},
$S:z+2}
A.e_f.prototype={
$1(d){return new D.yE(y.m.a(d),null)},
$S:z+1}
A.e_g.prototype={
$1(d){return new A.a3m(y.E.a(d),null)},
$S:z+3}
A.e_h.prototype={
$1(d){return new E.rY(y.k.a(d),null)},
$S:z+0};(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.b9,[A.SP,A.a3m])
w(A.CP,B.q4)
w(A.bR7,B.ph)
x(B.cl,[A.e_a,A.e_b,A.e_c,A.e_d,A.e_e,A.e_f,A.e_g,A.e_h])
w(A.IW,B.Y)})()
B.bO(b.typeUniverse,JSON.parse('{"SP":{"b9":["B"],"bf":["B"],"bf.T":"B","b9.T":"B"},"a3m":{"b9":["eV"],"bf":["eV"],"bf.T":"eV","b9.T":"eV"},"CP":{"j":[],"b":[]},"bR7":{"l":["CP"]}}'))
var y=(function rtii(){var x=B.G
return{k:x("o7"),a:x("B"),r:x("iK"),m:x("eD"),E:x("eV"),b:x("rY?"),e:x("SP?"),d:x("vp?"),f:x("yE?"),w:x("a3m?")}})()};
(a=>{a["lkek9yVNHlcvltVUjmlMtDXl3rc="]=a.current})($__dart_deferred_initializers__);