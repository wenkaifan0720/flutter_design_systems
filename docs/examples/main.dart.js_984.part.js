((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,D,A={
jq(d,e,f,g,h,i,j,k,l,m,n,o){var x,w,v=null
if(i==null)x=f!=null?new B.ah(f,v,v,v,v,v,v,C.N):v
else x=i
if(o!=null||l!=null){w=g==null?v:g.H7(l,o)
if(w==null)w=B.dE(l,o)}else w=g
return new A.CK(e,d,n,x,k,w,h,j,v,m)},
SA:function SA(d,e){this.a=d
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
bPN:function bPN(d,e){var _=this
_.fx=_.fr=_.dy=_.dx=_.db=_.cy=_.cx=_.CW=null
_.e=_.d=$
_.c4$=d
_.ah$=e
_.c=_.a=null},
dXu:function dXu(){},
dXv:function dXv(){},
dXw:function dXw(){},
dXx:function dXx(){},
dXy:function dXy(){},
dXz:function dXz(){},
dXA:function dXA(){},
dXB:function dXB(){},
iwq(){var x=new Float64Array(4)
x[3]=1
return new A.IX(x)},
IX:function IX(d){this.a=d}},E
B=c[0]
C=c[2]
D=c[188]
A=a.updateHolder(c[150],A)
E=c[174]
A.SA.prototype={
jd(d){var x=B.ww(this.a,this.b,d)
x.toString
return x}}
A.a37.prototype={
jd(a8){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2=new B.py(new Float64Array(3)),a3=new B.py(new Float64Array(3)),a4=A.iwq(),a5=A.iwq(),a6=new B.py(new Float64Array(3)),a7=new B.py(new Float64Array(3))
this.a.aOT(a2,a4,a6)
this.b.aOT(a3,a5,a7)
x=1-a8
w=a2.yB(x).aC(0,a3.yB(a8))
v=a4.yB(x).aC(0,a5.yB(a8))
u=new Float64Array(4)
t=new A.IX(u)
t.iN(v)
t.bWG()
s=a6.yB(x).aC(0,a7.yB(a8))
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
v.r2(x[0],x[1],x[2],1)
return v}}
A.CK.prototype={
n(){return new A.bPN(null,null)}}
A.bPN.prototype={
ms(d){var x,w,v=this,u=y.b
v.CW=u.a(d.$3(v.CW,v.a.w,new A.dXu()))
x=y.f
v.cx=x.a(d.$3(v.cx,v.a.x,new A.dXv()))
w=y.d
v.cy=w.a(d.$3(v.cy,v.a.y,new A.dXw()))
v.db=w.a(d.$3(v.db,v.a.z,new A.dXx()))
v.dx=y.e.a(d.$3(v.dx,v.a.Q,new A.dXy()))
w=v.dy
v.a.toString
v.dy=x.a(d.$3(w,null,new A.dXz()))
w=v.fr
v.a.toString
v.fr=y.w.a(d.$3(w,null,new A.dXA()))
w=v.fx
v.a.toString
v.fx=u.a(d.$3(w,null,new A.dXB()))},
h(d){var x,w,v,u,t,s,r,q=this,p=null,o=q.giw(),n=q.CW
n=n==null?p:n.b9(o.gq())
x=q.cx
x=x==null?p:x.b9(o.gq())
w=q.cy
w=w==null?p:w.b9(o.gq())
v=q.db
v=v==null?p:v.b9(o.gq())
u=q.dx
u=u==null?p:u.b9(o.gq())
t=q.dy
t=t==null?p:t.b9(o.gq())
s=q.fr
s=s==null?p:s.b9(o.gq())
r=q.fx
r=r==null?p:r.b9(o.gq())
return B.aK(n,q.a.r,C.u,p,u,w,v,p,p,t,x,s,r,p)}}
A.IX.prototype={
iN(d){var x=d.a,w=this.a,v=x[0]
w.$flags&2&&B.dd(w)
w[0]=v
w[1]=x[1]
w[2]=x[2]
w[3]=x[3]},
aXb(d){var x,w,v,u,t,s=d.a,r=s[0],q=s[4],p=s[8],o=0+r+q+p
if(o>0){x=Math.sqrt(o+1)
r=this.a
r.$flags&2&&B.dd(r)
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
t.$flags&2&&B.dd(t)
t[w]=x*0.5
x=0.5/x
t[3]=(s[q+u]-s[p+v])*x
t[v]=(s[r+v]+s[q+w])*x
t[u]=(s[r+u]+s[p+w])*x}},
bWG(){var x,w,v,u=Math.sqrt(this.gSt())
if(u===0)return 0
x=1/u
w=this.a
v=w[0]
w.$flags&2&&B.dd(w)
w[0]=v*x
w[1]=w[1]*x
w[2]=w[2]*x
w[3]=w[3]*x
return u},
gSt(){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return w*w+v*v+u*u+t*t},
ga7(d){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return Math.sqrt(w*w+v*v+u*u+t*t)},
yB(d){var x=new Float64Array(4),w=new A.IX(x)
w.iN(this)
x[3]=x[3]*d
x[2]=x[2]*d
x[1]=x[1]*d
x[0]=x[0]*d
return w},
bh(a5,a6){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h=this.a,g=h[3],f=h[2],e=h[1],d=h[0],a0=a6.gc1h(),a1=a0[3],a2=a0[2],a3=a0[1],a4=a0[0]
h=C.i.bh(g,a4)
x=C.i.bh(d,a1)
w=C.i.bh(e,a2)
v=C.i.bh(f,a3)
u=C.i.bh(g,a3)
t=C.i.bh(e,a1)
s=C.i.bh(f,a4)
r=C.i.bh(d,a2)
q=C.i.bh(g,a2)
p=C.i.bh(f,a1)
o=C.i.bh(d,a3)
n=C.i.bh(e,a4)
m=C.i.bh(g,a1)
l=C.i.bh(d,a4)
k=C.i.bh(e,a3)
j=C.i.bh(f,a2)
i=new Float64Array(4)
i[0]=h+x+w-v
i[1]=u+t+s-r
i[2]=q+p+o-n
i[3]=m-l-k-j
return new A.IX(i)},
i(d,e){var x,w,v
if(e==null)return!1
if(e instanceof A.IX){x=this.a
w=x[3]
v=e.a
x=w===v[3]&&x[2]===v[2]&&x[1]===v[1]&&x[0]===v[0]}else x=!1
return x},
ga2(d){return B.cB(this.a)},
aC(d,e){var x,w=new Float64Array(4),v=new A.IX(w)
v.iN(this)
x=e.a
w[0]=w[0]+x[0]
w[1]=w[1]+x[1]
w[2]=w[2]+x[2]
w[3]=w[3]+x[3]
return v},
aQ(d,e){var x,w=new Float64Array(4),v=new A.IX(w)
v.iN(this)
x=e.a
w[0]=w[0]-x[0]
w[1]=w[1]-x[1]
w[2]=w[2]-x[2]
w[3]=w[3]-x[3]
return v},
p(d,e){return this.a[e]},
P(d,e,f){var x=this.a
x.$flags&2&&B.dd(x)
x[e]=f},
A(d){var x=this.a
return B.am(x[0])+", "+B.am(x[1])+", "+B.am(x[2])+" @ "+B.am(x[3])}}
var z=a.updateTypes(["rO(@)","yt(@)","SA(@)","a37(@)"])
A.dXu.prototype={
$1(d){return new E.rO(y.k.a(d),null)},
$S:z+0}
A.dXv.prototype={
$1(d){return new D.yt(y.m.a(d),null)},
$S:z+1}
A.dXw.prototype={
$1(d){return new B.vh(y.r.a(d),null)},
$S:261}
A.dXx.prototype={
$1(d){return new B.vh(y.r.a(d),null)},
$S:261}
A.dXy.prototype={
$1(d){return new A.SA(y.a.a(d),null)},
$S:z+2}
A.dXz.prototype={
$1(d){return new D.yt(y.m.a(d),null)},
$S:z+1}
A.dXA.prototype={
$1(d){return new A.a37(y.E.a(d),null)},
$S:z+3}
A.dXB.prototype={
$1(d){return new E.rO(y.k.a(d),null)},
$S:z+0};(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.b8,[A.SA,A.a37])
w(A.CK,B.pQ)
w(A.bPN,B.p4)
x(B.cj,[A.dXu,A.dXv,A.dXw,A.dXx,A.dXy,A.dXz,A.dXA,A.dXB])
w(A.IX,B.W)})()
B.bM(b.typeUniverse,JSON.parse('{"SA":{"b8":["A"],"be":["A"],"be.T":"A","b8.T":"A"},"a37":{"b8":["f_"],"be":["f_"],"be.T":"f_","b8.T":"f_"},"CK":{"i":[],"b":[]},"bPN":{"k":["CK"]}}'))
var y=(function rtii(){var x=B.E
return{k:x("nV"),a:x("A"),r:x("iz"),m:x("ez"),E:x("f_"),b:x("rO?"),e:x("SA?"),d:x("vh?"),f:x("yt?"),w:x("a37?")}})()};
(a=>{a["F9lJAs8e2ftpimAaWRCby9fCPKA="]=a.current})($__dart_deferred_initializers__);