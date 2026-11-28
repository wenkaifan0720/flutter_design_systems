((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,A={
wI(d,e,f,g,h,i){return new A.bKS(i,h,d,f,g,e,null)},
bKS:function bKS(d,e,f,g,h,i,j){var _=this
_.e=d
_.f=e
_.r=f
_.w=g
_.x=h
_.c=i
_.a=j},
Gt:function Gt(d,e,f){this.dn$=d
this.a5$=e
this.a=f},
aCP:function aCP(d,e,f,g,h,i,j,k,l,m,n){var _=this
_.C=d
_.R=e
_.a4=f
_.ac=g
_.ag=h
_.aG=i
_.aC=null
_.bX$=j
_.T$=k
_.bh$=l
_.dy=m
_.b=_.fy=null
_.c=0
_.y=_.d=null
_.z=!0
_.Q=null
_.as=!1
_.at=null
_.ay=$
_.ch=n
_.CW=!1
_.cx=$
_.cy=!0
_.db=!1
_.dx=$},
fFe:function fFe(){},
fFD:function fFD(){},
fFf:function fFf(){},
fFg:function fFg(d){this.a=d},
fFu:function fFu(d){this.a=d},
fFl:function fFl(){},
fFm:function fFm(){},
fFn:function fFn(d,e){this.a=d
this.b=e},
cJl:function cJl(){},
cJo:function cJo(){}},D
J=c[1]
B=c[0]
C=c[2]
A=a.updateHolder(c[237],A)
D=c[283]
A.bKS.prototype={
aA(d){var x=this,w=new A.aCP(x.e,x.f,x.r,x.w,d.t(y.n).w,x.x,0,null,null,new B.aY(),B.aN())
w.az()
return w},
aI(d,e){var x=this
y.r.a(e)
e.sog(x.e)
e.saoE(x.f)
e.sjW(x.r)
e.sSU(x.w)
e.aG=x.x
e.sbB(d.t(y.n).w)}}
A.Gt.prototype={}
A.aCP.prototype={
sog(d){if(d===this.C)return
this.C=d
this.a6()},
saoE(d){if(d===this.R)return
this.R=d
this.a6()},
sjW(d){if(d===this.a4)return
this.a4=d
this.a6()},
sSU(d){if(d===this.ac)return
this.ac=d
this.a6()},
sbB(d){if(d===this.ag)return
this.ag=d
this.a6()},
eH(d){if(!(d.b instanceof A.Gt))d.b=new A.Gt(null,null,C.K)},
gafS(){var x,w,v,u,t,s,r=this.hr(),q=r.length
if(q===0)return 0
for(x=0,w=0,v=0;u=r.length,v<u;r.length===q||(0,B.F)(r),++v){t=r[v]
s=C.ak.dc(t.dy,1/0,t.gaw())
x+=s
w=Math.max(w,s)}q=this.ac?w*u:x
return q+this.C*Math.max(0,u-1)},
gawR(){return C.c.b8(this.hr(),0,new A.fFe())},
aT(d){return C.c.b8(this.hr(),0,new A.fFD())},
aJ(d){return this.gafS()},
aH(d){return this.atA(d)},
aK(d){return this.atA(d)},
atA(d){var x,w,v=this,u=v.hr()
if(u.length===0)return 0
if(v.gafS()<=d)return C.c.b8(u,0,new A.fFf())
x=C.c.b8(u,0,new A.fFg(isFinite(d)?d:v.gawR()))
w=u.length
return x+v.R*Math.max(0,w-1)},
hN(d){return this.tf(d)},
bT(d){return this.atB(d,!0)},
bp(){this.fy=this.atB(y.a.a(B.H.prototype.gW.call(this)),!1)},
atB(b2,b3){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9=this,b0=null,b1=a9.hr()
if(b1.length===0)return new B.I(B.a8(0,b2.a,b2.b),B.a8(0,b2.c,b2.d))
x=b2.b
w=a9.gafS()
v=w>x+1e-10
u=new A.fFu(b3)
t=a9.ag===C.H
s=!v
if(s){r=isFinite(x)?x:w
if(a9.ac){q=b1.length
p=(r-a9.C*Math.max(0,q-1))/q}else p=b0
q=B.a([],y.A)
for(o=b1.length,n=p!=null,m=0;m<b1.length;b1.length===o||(0,B.F)(b1),++m){l=b1[m]
if(n)k=B.dA(b0,p)
else{j=C.ak.dc(l.dy,1/0,l.gaw())
k=new B.y(0,j,0,1/0)}q.push(u.$2(l,k))}i=b2.aR(new B.I(r,C.c.b8(q,0,new A.fFl())))
if(!b3){o=C.c.b8(q,0,new A.fFm())
k=b1.length
h=a9.C
g=k-1
f=i.a
e=Math.max(0,f-(o+h*Math.max(0,g)))
if(n)d=new B.z(0,h)
else{switch(a9.a4.a){case 0:o=new B.z(0,h)
break
case 1:o=new B.z(e,h)
break
case 2:o=new B.z(e/2,h)
break
case 3:o=k>1?new B.z(0,h+e/g):new B.z(0,h)
break
case 4:o=e/k
o=new B.z(o/2,h+o)
break
case 5:o=e/(k+1)
o=new B.z(o,h+o)
break
default:o=b0}d=o}a0=d.a
a1=d.b
for(o=D.ar(b1,0,y.g),n=J.a2(o.a),o=o.b,k=new D.ap(n,o),h=i.b,g=y.o,a2=a0;k.A();){a3=k.c
a3=a3>=0?new B.z(o+a3,n.gK()):B.O(B.ah())
a4=q[a3.a]
a3=a3.b.b
a3.toString
g.a(a3)
a5=t?f-a2-a4.a:a2
a3.a=new B.u(a5,(h-a4.b)/2)
a2+=a4.a+a1}b3=!1}}else{r=isFinite(x)?x:a9.gawR()
a6=B.dA(b0,r)
for(q=B.aC(b1).k("cI<1>"),o=new B.cI(b1,q),o=new B.cG(o,o.gaa(0),q.k("cG<bS.E>")),n=!b3,q=q.k("bS.E"),k=y.o,a7=0;o.A();){h=o.d
if(h==null)h=q.a(h)
a4=u.$2(h,a6)
if(n){h=h.b
h.toString
k.a(h).a=new B.u(0,a7)}a7+=a4.b+a9.R}i=b2.aR(new B.I(r,a7-a9.R))}if(!b3&&a9.aC!==v){q=a9.aC
a9.aC=v
a8=a9.aG
if(a8!=null)s=!s||q!=null
else s=!1
if(s)$.dM.ok$.push(new A.fFn(a8,v))}return i},
U(d,e){return this.hn(d,e)},
cI(d,e){return this.hw(d,e)}}
A.cJl.prototype={
aD(d){var x,w,v
this.dC(d)
x=this.T$
for(w=y.o;x!=null;){x.aD(d)
v=x.b
v.toString
x=w.a(v).a5$}},
al(){var x,w,v
this.dv()
x=this.T$
for(w=y.o;x!=null;){x.al()
v=x.b
v.toString
x=w.a(v).a5$}}}
A.cJo.prototype={}
var z=a.updateTypes(["q(q)"])
A.fFe.prototype={
$2(d,e){return Math.max(d,e.Y(C.ak,1/0,e.gaw()))},
$S:27}
A.fFD.prototype={
$2(d,e){return Math.max(d,e.Y(C.aV,1/0,e.gb2()))},
$S:27}
A.fFf.prototype={
$2(d,e){return Math.max(d,e.Y(C.aZ,1/0,e.gb6()))},
$S:27}
A.fFg.prototype={
$2(d,e){return d+e.Y(C.aZ,this.a,e.gb6())},
$S:27}
A.fFu.prototype={
$2(d,e){var x
if(this.a)x=d.Y(C.ar,e,d.gc3())
else{d.bi(e,!0)
x=d.gE()}return x},
$S:38}
A.fFl.prototype={
$2(d,e){return Math.max(d,e.b)},
$S:151}
A.fFm.prototype={
$2(d,e){return d+e.a},
$S:151}
A.fFn.prototype={
$1(d){return this.a.$1(this.b)},
$S:3};(function installTearOffs(){var x=a._instance_1u
var w
x(w=A.aCP.prototype,"gb2","aT",0)
x(w,"gaw","aJ",0)
x(w,"gba","aH",0)
x(w,"gb6","aK",0)})();(function inheritance(){var x=a.mixinHard,w=a.mixin,v=a.inherit,u=a.inheritMany
v(A.bKS,B.d2)
v(A.Gt,B.ds)
v(A.cJl,B.w)
v(A.cJo,A.cJl)
v(A.aCP,A.cJo)
u(B.db,[A.fFe,A.fFD,A.fFf,A.fFg,A.fFu,A.fFl,A.fFm])
v(A.fFn,B.cp)
x(A.cJl,B.ai)
w(A.cJo,B.ba)})()
B.bP(b.typeUniverse,JSON.parse('{"Gt":{"ds":["w"],"dy":[],"ey":["w"],"e1":[]},"bKS":{"d2":[],"aQ":[],"b":[]},"aCP":{"ba":["w","Gt"],"w":[],"ai":["w","Gt"],"H":[],"aS":[],"ai.1":"Gt","ba.1":"Gt","ba.0":"w","ai.0":"w"}}'))
var y={a:B.G("y"),n:B.G("dv"),A:B.G("o<I>"),g:B.G("w"),o:B.G("Gt"),r:B.G("aCP")}};
(a=>{a["nq1wetmGkZ0GFj6IYje2eQCHnK4="]=a.current})($__dart_deferred_initializers__);