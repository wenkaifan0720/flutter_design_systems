((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,A={
jC(d,e,f,g,h,i,j,k,l,m,n,o){var x,w,v=null
if(i==null)x=f!=null?new B.ai(f,v,v,v,v,v,v,C.N):v
else x=i
if(o!=null||l!=null){w=g==null?v:g.HK(l,o)
if(w==null)w=B.dF(l,o)}else w=g
return new A.Dc(e,d,n,x,k,w,h,j,v,m)},
To:function To(d,e){this.a=d
this.b=e},
a40:function a40(d,e){this.a=d
this.b=e},
Dc:function Dc(d,e,f,g,h,i,j,k,l,m){var _=this
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
bRW:function bRW(d,e){var _=this
_.fx=_.fr=_.dy=_.dx=_.db=_.cy=_.cx=_.CW=null
_.e=_.d=$
_.cd$=d
_.an$=e
_.c=_.a=null},
e0K:function e0K(){},
e0L:function e0L(){},
e0M:function e0M(){},
e0N:function e0N(){},
e0O:function e0O(){},
e0P:function e0P(){},
e0Q:function e0Q(){},
e0R:function e0R(){},
iDa(){var x=new Float64Array(4)
x[3]=1
return new A.Jp(x)},
Jp:function Jp(d){this.a=d}},D,E
B=c[0]
C=c[2]
A=a.updateHolder(c[165],A)
D=c[190]
E=c[212]
A.To.prototype={
jo(d){var x=B.x_(this.a,this.b,d)
x.toString
return x}}
A.a40.prototype={
jo(a8){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2=new B.pU(new Float64Array(3)),a3=new B.pU(new Float64Array(3)),a4=A.iDa(),a5=A.iDa(),a6=new B.pU(new Float64Array(3)),a7=new B.pU(new Float64Array(3))
this.a.aQs(a2,a4,a6)
this.b.aQs(a3,a5,a7)
x=1-a8
w=a2.yZ(x).aD(0,a3.yZ(a8))
v=a4.yZ(x).aD(0,a5.yZ(a8))
u=new Float64Array(4)
t=new A.Jp(u)
t.iQ(v)
t.bZ2()
s=a6.yZ(x).aD(0,a7.yZ(a8))
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
A.Dc.prototype={
p(){return new A.bRW(null,null)}}
A.bRW.prototype={
mZ(d){var x,w,v=this,u=y.b
v.CW=u.a(d.$3(v.CW,v.a.w,new A.e0K()))
x=y.f
v.cx=x.a(d.$3(v.cx,v.a.x,new A.e0L()))
w=y.d
v.cy=w.a(d.$3(v.cy,v.a.y,new A.e0M()))
v.db=w.a(d.$3(v.db,v.a.z,new A.e0N()))
v.dx=y.e.a(d.$3(v.dx,v.a.Q,new A.e0O()))
w=v.dy
v.a.toString
v.dy=x.a(d.$3(w,null,new A.e0P()))
w=v.fr
v.a.toString
v.fr=y.w.a(d.$3(w,null,new A.e0Q()))
w=v.fx
v.a.toString
v.fx=u.a(d.$3(w,null,new A.e0R()))},
h(d){var x,w,v,u,t,s,r,q=this,p=null,o=q.giH(),n=q.CW
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
return B.aP(n,q.a.r,C.u,p,u,w,v,p,p,t,x,s,r,p)}}
A.Jp.prototype={
iQ(d){var x=d.a,w=this.a,v=x[0]
w.$flags&2&&B.dk(w)
w[0]=v
w[1]=x[1]
w[2]=x[2]
w[3]=x[3]},
aYz(d){var x,w,v,u,t,s=d.a,r=s[0],q=s[4],p=s[8],o=0+r+q+p
if(o>0){x=Math.sqrt(o+1)
r=this.a
r.$flags&2&&B.dk(r)
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
t.$flags&2&&B.dk(t)
t[w]=x*0.5
x=0.5/x
t[3]=(s[q+u]-s[p+v])*x
t[v]=(s[r+v]+s[q+w])*x
t[u]=(s[r+u]+s[p+w])*x}},
bZ2(){var x,w,v,u=Math.sqrt(this.gTj())
if(u===0)return 0
x=1/u
w=this.a
v=w[0]
w.$flags&2&&B.dk(w)
w[0]=v*x
w[1]=w[1]*x
w[2]=w[2]*x
w[3]=w[3]*x
return u},
gTj(){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return w*w+v*v+u*u+t*t},
ga9(d){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return Math.sqrt(w*w+v*v+u*u+t*t)},
yZ(d){var x=new Float64Array(4),w=new A.Jp(x)
w.iQ(this)
x[3]=x[3]*d
x[2]=x[2]*d
x[1]=x[1]*d
x[0]=x[0]*d
return w},
bn(a5,a6){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h=this.a,g=h[3],f=h[2],e=h[1],d=h[0],a0=a6.gc3z(),a1=a0[3],a2=a0[2],a3=a0[1],a4=a0[0]
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
return new A.Jp(i)},
i(d,e){var x,w,v
if(e==null)return!1
if(e instanceof A.Jp){x=this.a
w=x[3]
v=e.a
x=w===v[3]&&x[2]===v[2]&&x[1]===v[1]&&x[0]===v[0]}else x=!1
return x},
ga3(d){return B.cA(this.a)},
aD(d,e){var x,w=new Float64Array(4),v=new A.Jp(w)
v.iQ(this)
x=e.a
w[0]=w[0]+x[0]
w[1]=w[1]+x[1]
w[2]=w[2]+x[2]
w[3]=w[3]+x[3]
return v},
aR(d,e){var x,w=new Float64Array(4),v=new A.Jp(w)
v.iQ(this)
x=e.a
w[0]=w[0]-x[0]
w[1]=w[1]-x[1]
w[2]=w[2]-x[2]
w[3]=w[3]-x[3]
return v},
q(d,e){return this.a[e]},
S(d,e,f){var x=this.a
x.$flags&2&&B.dk(x)
x[e]=f},
C(d){var x=this.a
return B.al(x[0])+", "+B.al(x[1])+", "+B.al(x[2])+" @ "+B.al(x[3])}}
var z=a.updateTypes(["td(@)","yX(@)","To(@)","a40(@)"])
A.e0K.prototype={
$1(d){return new D.td(y.k.a(d),null)},
$S:z+0}
A.e0L.prototype={
$1(d){return new E.yX(y.m.a(d),null)},
$S:z+1}
A.e0M.prototype={
$1(d){return new B.vH(y.r.a(d),null)},
$S:267}
A.e0N.prototype={
$1(d){return new B.vH(y.r.a(d),null)},
$S:267}
A.e0O.prototype={
$1(d){return new A.To(y.a.a(d),null)},
$S:z+2}
A.e0P.prototype={
$1(d){return new E.yX(y.m.a(d),null)},
$S:z+1}
A.e0Q.prototype={
$1(d){return new A.a40(y.E.a(d),null)},
$S:z+3}
A.e0R.prototype={
$1(d){return new D.td(y.k.a(d),null)},
$S:z+0};(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.bb,[A.To,A.a40])
w(A.Dc,B.qg)
w(A.bRW,B.pt)
x(B.ce,[A.e0K,A.e0L,A.e0M,A.e0N,A.e0O,A.e0P,A.e0Q,A.e0R])
w(A.Jp,B.Y)})()
B.bM(b.typeUniverse,JSON.parse('{"To":{"bb":["y"],"bh":["y"],"bh.T":"y","bb.T":"y"},"a40":{"bb":["eV"],"bh":["eV"],"bh.T":"eV","bb.T":"eV"},"Dc":{"k":[],"b":[]},"bRW":{"m":["Dc"]}}'))
var y=(function rtii(){var x=B.E
return{k:x("oe"),a:x("y"),r:x("iN"),m:x("eD"),E:x("eV"),b:x("td?"),e:x("To?"),d:x("vH?"),f:x("yX?"),w:x("a40?")}})()};
(a=>{a["GZJzQU2IVTJ1Cgn2gjXqChoZDY0="]=a.current})($__dart_deferred_initializers__);