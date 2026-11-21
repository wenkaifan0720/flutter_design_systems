((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,A={
kn(d,e,f,g,h,i,j,k,l,m,n,o){var x,w,v=null
if(i==null)x=f!=null?new B.ae(f,v,v,v,v,v,v,C.M):v
else x=i
if(o!=null||l!=null){w=g==null?v:g.FO(l,o)
if(w==null)w=B.du(l,o)}else w=g
return new A.zK(e,d,n,x,k,w,h,j,v,m)},
Np:function Np(d,e){this.a=d
this.b=e},
Hw:function Hw(d,e){this.a=d
this.b=e},
WT:function WT(d,e){this.a=d
this.b=e},
zK:function zK(d,e,f,g,h,i,j,k,l,m){var _=this
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
bsH:function bsH(d,e){var _=this
_.fx=_.fr=_.dy=_.dx=_.db=_.cy=_.cx=_.CW=null
_.e=_.d=$
_.c3$=d
_.ak$=e
_.c=_.a=null},
di1:function di1(){},
di2:function di2(){},
di3:function di3(){},
di4:function di4(){},
di5:function di5(){},
di6:function di6(){},
di7:function di7(){},
di8:function di8(){},
hcR(){var x=new Float64Array(4)
x[3]=1
return new A.F8(x)},
F8:function F8(d){this.a=d}},D
B=c[0]
C=c[2]
A=a.updateHolder(c[113],A)
D=c[130]
A.Np.prototype={
i1(d){var x=B.ue(this.a,this.b,d)
x.toString
return x}}
A.Hw.prototype={
i1(d){var x=B.jN(this.a,this.b,d)
x.toString
return x}}
A.WT.prototype={
i1(a8){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2=new B.nR(new Float64Array(3)),a3=new B.nR(new Float64Array(3)),a4=A.hcR(),a5=A.hcR(),a6=new B.nR(new Float64Array(3)),a7=new B.nR(new Float64Array(3))
this.a.ay1(a2,a4,a6)
this.b.ay1(a3,a5,a7)
x=1-a8
w=a2.uT(x).aJ(0,a3.uT(a8))
v=a4.uT(x).aJ(0,a5.uT(a8))
u=new Float64Array(4)
t=new A.F8(u)
t.fF(v)
t.bsA()
s=a6.uT(x).aJ(0,a7.uT(a8))
x=new Float64Array(16)
v=new B.eA(x)
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
v.pc(x[0],x[1],x[2],1)
return v}}
A.zK.prototype={
n(){return new A.bsH(null,null)}}
A.bsH.prototype={
l1(d){var x,w,v=this,u=y.b
v.CW=u.a(d.$3(v.CW,v.a.w,new A.di1()))
x=y.f
v.cx=x.a(d.$3(v.cx,v.a.x,new A.di2()))
w=y.d
v.cy=w.a(d.$3(v.cy,v.a.y,new A.di3()))
v.db=w.a(d.$3(v.db,v.a.z,new A.di4()))
v.dx=y.e.a(d.$3(v.dx,v.a.Q,new A.di5()))
w=v.dy
v.a.toString
v.dy=x.a(d.$3(w,null,new A.di6()))
w=v.fr
v.a.toString
v.fr=y.w.a(d.$3(w,null,new A.di7()))
w=v.fx
v.a.toString
v.fx=u.a(d.$3(w,null,new A.di8()))},
h(d){var x,w,v,u,t,s,r,q=this,p=null,o=q.gfO(),n=q.CW
n=n==null?p:n.bt(o.gt())
x=q.cx
x=x==null?p:x.bt(o.gt())
w=q.cy
w=w==null?p:w.bt(o.gt())
v=q.db
v=v==null?p:v.bt(o.gt())
u=q.dx
u=u==null?p:u.bt(o.gt())
t=q.dy
t=t==null?p:t.bt(o.gt())
s=q.fr
s=s==null?p:s.bt(o.gt())
r=q.fx
r=r==null?p:r.bt(o.gt())
return B.aH(n,q.a.r,C.w,p,u,w,v,p,p,t,x,s,r,p)}}
A.F8.prototype={
fF(d){var x=d.a,w=this.a,v=x[0]
w.$flags&2&&B.cE(w)
w[0]=v
w[1]=x[1]
w[2]=x[2]
w[3]=x[3]},
aFF(d){var x,w,v,u,t,s=d.a,r=s[0],q=s[4],p=s[8],o=0+r+q+p
if(o>0){x=Math.sqrt(o+1)
r=this.a
r.$flags&2&&B.cE(r)
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
t.$flags&2&&B.cE(t)
t[w]=x*0.5
x=0.5/x
t[3]=(s[q+u]-s[p+v])*x
t[v]=(s[r+v]+s[q+w])*x
t[u]=(s[r+u]+s[p+w])*x}},
bsA(){var x,w,v,u=Math.sqrt(this.gL4())
if(u===0)return 0
x=1/u
w=this.a
v=w[0]
w.$flags&2&&B.cE(w)
w[0]=v*x
w[1]=w[1]*x
w[2]=w[2]*x
w[3]=w[3]*x
return u},
gL4(){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return w*w+v*v+u*u+t*t},
ga3(d){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return Math.sqrt(w*w+v*v+u*u+t*t)},
uT(d){var x=new Float64Array(4),w=new A.F8(x)
w.fF(this)
x[3]=x[3]*d
x[2]=x[2]*d
x[1]=x[1]*d
x[0]=x[0]*d
return w},
b6(a5,a6){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h=this.a,g=h[3],f=h[2],e=h[1],d=h[0],a0=a6.gbxh(),a1=a0[3],a2=a0[2],a3=a0[1],a4=a0[0]
h=C.h.b6(g,a4)
x=C.h.b6(d,a1)
w=C.h.b6(e,a2)
v=C.h.b6(f,a3)
u=C.h.b6(g,a3)
t=C.h.b6(e,a1)
s=C.h.b6(f,a4)
r=C.h.b6(d,a2)
q=C.h.b6(g,a2)
p=C.h.b6(f,a1)
o=C.h.b6(d,a3)
n=C.h.b6(e,a4)
m=C.h.b6(g,a1)
l=C.h.b6(d,a4)
k=C.h.b6(e,a3)
j=C.h.b6(f,a2)
i=new Float64Array(4)
i[0]=h+x+w-v
i[1]=u+t+s-r
i[2]=q+p+o-n
i[3]=m-l-k-j
return new A.F8(i)},
i(d,e){var x,w,v
if(e==null)return!1
if(e instanceof A.F8){x=this.a
w=x[3]
v=e.a
x=w===v[3]&&x[2]===v[2]&&x[1]===v[1]&&x[0]===v[0]}else x=!1
return x},
gU(d){return B.ci(this.a)},
aJ(d,e){var x,w=new Float64Array(4),v=new A.F8(w)
v.fF(this)
x=e.a
w[0]=w[0]+x[0]
w[1]=w[1]+x[1]
w[2]=w[2]+x[2]
w[3]=w[3]+x[3]
return v},
aR(d,e){var x,w=new Float64Array(4),v=new A.F8(w)
v.fF(this)
x=e.a
w[0]=w[0]-x[0]
w[1]=w[1]-x[1]
w[2]=w[2]-x[2]
w[3]=w[3]-x[3]
return v},
p(d,e){return this.a[e]},
K(d,e,f){var x=this.a
x.$flags&2&&B.cE(x)
x[e]=f},
v(d){var x=this.a
return B.a7(x[0])+", "+B.a7(x[1])+", "+B.a7(x[2])+" @ "+B.a7(x[3])}}
var z=a.updateTypes(["pZ(@)","Hw(@)","Np(@)","WT(@)"])
A.di1.prototype={
$1(d){return new D.pZ(y.k.a(d),null)},
$S:z+0}
A.di2.prototype={
$1(d){return new A.Hw(y.m.a(d),null)},
$S:z+1}
A.di3.prototype={
$1(d){return new B.t7(y.r.a(d),null)},
$S:244}
A.di4.prototype={
$1(d){return new B.t7(y.r.a(d),null)},
$S:244}
A.di5.prototype={
$1(d){return new A.Np(y.a.a(d),null)},
$S:z+2}
A.di6.prototype={
$1(d){return new A.Hw(y.m.a(d),null)},
$S:z+1}
A.di7.prototype={
$1(d){return new A.WT(y.E.a(d),null)},
$S:z+3}
A.di8.prototype={
$1(d){return new D.pZ(y.k.a(d),null)},
$S:z+0};(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.bf,[A.Np,A.Hw,A.WT])
w(A.zK,B.qp)
w(A.bsH,B.p8)
x(B.cq,[A.di1,A.di2,A.di3,A.di4,A.di5,A.di6,A.di7,A.di8])
w(A.F8,B.T)})()
B.c_(b.typeUniverse,JSON.parse('{"Np":{"bf":["A"],"bR":["A"],"bR.T":"A","bf.T":"A"},"Hw":{"bf":["ew"],"bR":["ew"],"bR.T":"ew","bf.T":"ew"},"WT":{"bf":["eA"],"bR":["eA"],"bR.T":"eA","bf.T":"eA"},"zK":{"j":[],"b":[]},"bsH":{"k":["zK"]}}'))
var y=(function rtii(){var x=B.G
return{k:x("o_"),a:x("A"),r:x("hT"),m:x("ew"),E:x("eA"),b:x("pZ?"),e:x("Np?"),d:x("t7?"),f:x("Hw?"),w:x("WT?")}})()};
(a=>{a["gp4aFk+W4G5unDEUs6vgfPIgB+A="]=a.current})($__dart_deferred_initializers__);