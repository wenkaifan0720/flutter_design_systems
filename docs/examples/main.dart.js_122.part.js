((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,A={
w_(d,e,f,g,h,i){return new A.bHT(i,h,d,f,g,e,null)},
bHT:function bHT(d,e,f,g,h,i,j){var _=this
_.e=d
_.f=e
_.r=f
_.w=g
_.x=h
_.c=i
_.a=j},
Fp:function Fp(d,e,f){this.d3$=d
this.a5$=e
this.a=f},
aAY:function aAY(d,e,f,g,h,i,j,k,l,m,n){var _=this
_.D=d
_.R=e
_.a4=f
_.ad=g
_.al=h
_.aJ=i
_.aF=null
_.bV$=j
_.W$=k
_.bq$=l
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
fxu:function fxu(){},
fxT:function fxT(){},
fxv:function fxv(){},
fxw:function fxw(d){this.a=d},
fxK:function fxK(d){this.a=d},
fxB:function fxB(){},
fxC:function fxC(){},
fxD:function fxD(d,e){this.a=d
this.b=e},
cFL:function cFL(){},
cFO:function cFO(){}},D
J=c[1]
B=c[0]
C=c[2]
A=a.updateHolder(c[226],A)
D=c[274]
A.bHT.prototype={
az(d){var x=this,w=new A.aAY(x.e,x.f,x.r,x.w,d.u(y.n).w,x.x,0,null,null,new B.aY(),B.aM())
w.aw()
return w},
aH(d,e){var x=this
y.r.a(e)
e.spz(x.e)
e.sanr(x.f)
e.skc(x.r)
e.sSo(x.w)
e.aJ=x.x
e.sbK(d.u(y.n).w)}}
A.Fp.prototype={}
A.aAY.prototype={
spz(d){if(d===this.D)return
this.D=d
this.a6()},
sanr(d){if(d===this.R)return
this.R=d
this.a6()},
skc(d){if(d===this.a4)return
this.a4=d
this.a6()},
sSo(d){if(d===this.ad)return
this.ad=d
this.a6()},
sbK(d){if(d===this.al)return
this.al=d
this.a6()},
eZ(d){if(!(d.b instanceof A.Fp))d.b=new A.Fp(null,null,C.L)},
gaeX(){var x,w,v,u,t,s,r=this.hi(),q=r.length
if(q===0)return 0
for(x=0,w=0,v=0;u=r.length,v<u;r.length===q||(0,B.F)(r),++v){t=r[v]
s=C.al.d5(t.dy,1/0,t.gaA())
x+=s
w=Math.max(w,s)}q=this.ad?w*u:x
return q+this.D*Math.max(0,u-1)},
gavC(){return C.c.b6(this.hi(),0,new A.fxu())},
b_(d){return C.c.b6(this.hi(),0,new A.fxT())},
aN(d){return this.gaeX()},
aG(d){return this.ask(d)},
aM(d){return this.ask(d)},
ask(d){var x,w,v=this,u=v.hi()
if(u.length===0)return 0
if(v.gaeX()<=d)return C.c.b6(u,0,new A.fxv())
x=C.c.b6(u,0,new A.fxw(isFinite(d)?d:v.gavC()))
w=u.length
return x+v.R*Math.max(0,w-1)},
i1(d){return this.wu(d)},
bZ(d){return this.asl(d,!0)},
bu(){this.fy=this.asl(y.a.a(B.H.prototype.gX.call(this)),!1)},
asl(b2,b3){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9=this,b0=null,b1=a9.hi()
if(b1.length===0)return new B.I(B.a7(0,b2.a,b2.b),B.a7(0,b2.c,b2.d))
x=b2.b
w=a9.gaeX()
v=w>x+1e-10
u=new A.fxK(b3)
t=a9.al===C.I
s=!v
if(s){r=isFinite(x)?x:w
if(a9.ad){q=b1.length
p=(r-a9.D*Math.max(0,q-1))/q}else p=b0
q=B.a([],y.A)
for(o=b1.length,n=p!=null,m=0;m<b1.length;b1.length===o||(0,B.F)(b1),++m){l=b1[m]
if(n)k=B.dC(b0,p)
else{j=C.al.d5(l.dy,1/0,l.gaA())
k=new B.z(0,j,0,1/0)}q.push(u.$2(l,k))}i=b2.aT(new B.I(r,C.c.b6(q,0,new A.fxB())))
if(!b3){o=C.c.b6(q,0,new A.fxC())
k=b1.length
h=a9.D
g=k-1
f=i.a
e=Math.max(0,f-(o+h*Math.max(0,g)))
if(n)d=new B.B(0,h)
else{switch(a9.a4.a){case 0:o=new B.B(0,h)
break
case 1:o=new B.B(e,h)
break
case 2:o=new B.B(e/2,h)
break
case 3:o=k>1?new B.B(0,h+e/g):new B.B(0,h)
break
case 4:o=e/k
o=new B.B(o/2,h+o)
break
case 5:o=e/(k+1)
o=new B.B(o,h+o)
break
default:o=b0}d=o}a0=d.a
a1=d.b
for(o=D.ar(b1,0,y.g),n=J.a1(o.a),o=o.b,k=new D.aq(n,o),h=i.b,g=y.o,a2=a0;k.A();){a3=k.c
a3=a3>=0?new B.B(o+a3,n.gK()):B.O(B.ag())
a4=q[a3.a]
a3=a3.b.b
a3.toString
g.a(a3)
a5=t?f-a2-a4.a:a2
a3.a=new B.u(a5,(h-a4.b)/2)
a2+=a4.a+a1}b3=!1}}else{r=isFinite(x)?x:a9.gavC()
a6=B.dC(b0,r)
for(q=B.aA(b1).k("cB<1>"),o=new B.cB(b1,q),o=new B.cy(o,o.ga9(0),q.k("cy<bR.E>")),n=!b3,q=q.k("bR.E"),k=y.o,a7=0;o.A();){h=o.d
if(h==null)h=q.a(h)
a4=u.$2(h,a6)
if(n){h=h.b
h.toString
k.a(h).a=new B.u(0,a7)}a7+=a4.b+a9.R}i=b2.aT(new B.I(r,a7-a9.R))}if(!b3&&a9.aF!==v){q=a9.aF
a9.aF=v
a8=a9.aJ
if(a8!=null)s=!s||q!=null
else s=!1
if(s)$.dN.ok$.push(new A.fxD(a8,v))}return i},
U(d,e){return this.hz(d,e)},
cO(d,e){return this.hQ(d,e)}}
A.cFL.prototype={
aC(d){var x,w,v
this.dU(d)
x=this.W$
for(w=y.o;x!=null;){x.aC(d)
v=x.b
v.toString
x=w.a(v).a5$}},
an(){var x,w,v
this.dR()
x=this.W$
for(w=y.o;x!=null;){x.an()
v=x.b
v.toString
x=w.a(v).a5$}}}
A.cFO.prototype={}
var z=a.updateTypes(["q(q)"])
A.fxu.prototype={
$2(d,e){return Math.max(d,e.a_(C.al,1/0,e.gaA()))},
$S:27}
A.fxT.prototype={
$2(d,e){return Math.max(d,e.a_(C.aX,1/0,e.gb9()))},
$S:27}
A.fxv.prototype={
$2(d,e){return Math.max(d,e.a_(C.b_,1/0,e.gb8()))},
$S:27}
A.fxw.prototype={
$2(d,e){return d+e.a_(C.b_,this.a,e.gb8())},
$S:27}
A.fxK.prototype={
$2(d,e){var x
if(this.a)x=d.a_(C.av,e,d.gc3())
else{d.bk(e,!0)
x=d.gE()}return x},
$S:54}
A.fxB.prototype={
$2(d,e){return Math.max(d,e.b)},
$S:159}
A.fxC.prototype={
$2(d,e){return d+e.a},
$S:159}
A.fxD.prototype={
$1(d){return this.a.$1(this.b)},
$S:4};(function installTearOffs(){var x=a._instance_1u
var w
x(w=A.aAY.prototype,"gb9","b_",0)
x(w,"gaA","aN",0)
x(w,"gbd","aG",0)
x(w,"gb8","aM",0)})();(function inheritance(){var x=a.mixinHard,w=a.mixin,v=a.inherit,u=a.inheritMany
v(A.bHT,B.dd)
v(A.Fp,B.dw)
v(A.cFL,B.w)
v(A.cFO,A.cFL)
v(A.aAY,A.cFO)
u(B.di,[A.fxu,A.fxT,A.fxv,A.fxw,A.fxK,A.fxB,A.fxC])
v(A.fxD,B.cf)
x(A.cFL,B.ak)
w(A.cFO,B.ba)})()
B.bN(b.typeUniverse,JSON.parse('{"Fp":{"dw":["w"],"dA":[],"ey":["w"],"e6":[]},"bHT":{"dd":[],"aP":[],"b":[]},"aAY":{"ba":["w","Fp"],"w":[],"ak":["w","Fp"],"H":[],"aQ":[],"ak.1":"Fp","ba.1":"Fp","ba.0":"w","ak.0":"w"}}'))
var y={a:B.G("z"),n:B.G("dt"),A:B.G("o<I>"),g:B.G("w"),o:B.G("Fp"),r:B.G("aAY")}};
(a=>{a["92mHwMN5qEYPGArDfCu0cXfniVI="]=a.current})($__dart_deferred_initializers__);