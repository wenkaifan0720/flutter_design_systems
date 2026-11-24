((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,D,A={
vW(d,e,f,g,h,i){return new A.bHv(i,h,d,f,g,e,null)},
bHv:function bHv(d,e,f,g,h,i,j){var _=this
_.e=d
_.f=e
_.r=f
_.w=g
_.x=h
_.c=i
_.a=j},
Fg:function Fg(d,e,f){this.dK$=d
this.a5$=e
this.a=f},
aAy:function aAy(d,e,f,g,h,i,j,k,l,m,n){var _=this
_.D=d
_.R=e
_.a4=f
_.ad=g
_.ak=h
_.aJ=i
_.aF=null
_.c_$=j
_.W$=k
_.br$=l
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
fwa:function fwa(){},
fwz:function fwz(){},
fwb:function fwb(){},
fwc:function fwc(d){this.a=d},
fwq:function fwq(d){this.a=d},
fwh:function fwh(){},
fwi:function fwi(){},
fwj:function fwj(d,e){this.a=d
this.b=e},
cFh:function cFh(){},
cFk:function cFk(){}}
J=c[1]
B=c[0]
C=c[2]
D=c[266]
A=a.updateHolder(c[218],A)
A.bHv.prototype={
az(d){var x=this,w=new A.aAy(x.e,x.f,x.r,x.w,d.u(y.n).w,x.x,0,null,null,new B.aY(),B.aM())
w.aw()
return w},
aI(d,e){var x=this
y.r.a(e)
e.sqD(x.e)
e.san6(x.f)
e.sk9(x.r)
e.sS6(x.w)
e.aJ=x.x
e.sbJ(d.u(y.n).w)}}
A.Fg.prototype={}
A.aAy.prototype={
sqD(d){if(d===this.D)return
this.D=d
this.a7()},
san6(d){if(d===this.R)return
this.R=d
this.a7()},
sk9(d){if(d===this.a4)return
this.a4=d
this.a7()},
sS6(d){if(d===this.ad)return
this.ad=d
this.a7()},
sbJ(d){if(d===this.ak)return
this.ak=d
this.a7()},
f3(d){if(!(d.b instanceof A.Fg))d.b=new A.Fg(null,null,C.K)},
gaev(){var x,w,v,u,t,s,r=this.ii(),q=r.length
if(q===0)return 0
for(x=0,w=0,v=0;u=r.length,v<u;r.length===q||(0,B.E)(r),++v){t=r[v]
s=C.al.d5(t.dy,1/0,t.gaA())
x+=s
w=Math.max(w,s)}q=this.ad?w*u:x
return q+this.D*Math.max(0,u-1)},
gavh(){return C.c.b8(this.ii(),0,new A.fwa())},
b1(d){return C.c.b8(this.ii(),0,new A.fwz())},
aQ(d){return this.gaev()},
aG(d){return this.as1(d)},
aM(d){return this.as1(d)},
as1(d){var x,w,v=this,u=v.ii()
if(u.length===0)return 0
if(v.gaev()<=d)return C.c.b8(u,0,new A.fwb())
x=C.c.b8(u,0,new A.fwc(isFinite(d)?d:v.gavh()))
w=u.length
return x+v.R*Math.max(0,w-1)},
hW(d){return this.wh(d)},
bZ(d){return this.as2(d,!0)},
bt(){this.fy=this.as2(y.a.a(B.H.prototype.gX.call(this)),!1)},
as2(b2,b3){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9=this,b0=null,b1=a9.ii()
if(b1.length===0)return new B.I(B.a7(0,b2.a,b2.b),B.a7(0,b2.c,b2.d))
x=b2.b
w=a9.gaev()
v=w>x+1e-10
u=new A.fwq(b3)
t=a9.ak===C.I
s=!v
if(s){r=isFinite(x)?x:w
if(a9.ad){q=b1.length
p=(r-a9.D*Math.max(0,q-1))/q}else p=b0
q=B.a([],y.A)
for(o=b1.length,n=p!=null,m=0;m<b1.length;b1.length===o||(0,B.E)(b1),++m){l=b1[m]
if(n)k=B.dH(b0,p)
else{j=C.al.d5(l.dy,1/0,l.gaA())
k=new B.B(0,j,0,1/0)}q.push(u.$2(l,k))}i=b2.b0(new B.I(r,C.c.b8(q,0,new A.fwh())))
if(!b3){o=C.c.b8(q,0,new A.fwi())
k=b1.length
h=a9.D
g=k-1
f=i.a
e=Math.max(0,f-(o+h*Math.max(0,g)))
if(n)d=new B.A(0,h)
else{switch(a9.a4.a){case 0:o=new B.A(0,h)
break
case 1:o=new B.A(e,h)
break
case 2:o=new B.A(e/2,h)
break
case 3:o=k>1?new B.A(0,h+e/g):new B.A(0,h)
break
case 4:o=e/k
o=new B.A(o/2,h+o)
break
case 5:o=e/(k+1)
o=new B.A(o,h+o)
break
default:o=b0}d=o}a0=d.a
a1=d.b
for(o=D.aq(b1,0,y.g),n=J.a1(o.a),o=o.b,k=new D.ap(n,o),h=i.b,g=y.o,a2=a0;k.A();){a3=k.c
a3=a3>=0?new B.A(o+a3,n.gK()):B.O(B.ag())
a4=q[a3.a]
a3=a3.b.b
a3.toString
g.a(a3)
a5=t?f-a2-a4.a:a2
a3.a=new B.u(a5,(h-a4.b)/2)
a2+=a4.a+a1}b3=!1}}else{r=isFinite(x)?x:a9.gavh()
a6=B.dH(b0,r)
for(q=B.aE(b1).k("cC<1>"),o=new B.cC(b1,q),o=new B.cz(o,o.gaa(0),q.k("cz<bS.E>")),n=!b3,q=q.k("bS.E"),k=y.o,a7=0;o.A();){h=o.d
if(h==null)h=q.a(h)
a4=u.$2(h,a6)
if(n){h=h.b
h.toString
k.a(h).a=new B.u(0,a7)}a7+=a4.b+a9.R}i=b2.b0(new B.I(r,a7-a9.R))}if(!b3&&a9.aF!==v){q=a9.aF
a9.aF=v
a8=a9.aJ
if(a8!=null)s=!s||q!=null
else s=!1
if(s)$.dN.ok$.push(new A.fwj(a8,v))}return i},
U(d,e){return this.ht(d,e)},
cO(d,e){return this.hJ(d,e)}}
A.cFh.prototype={
aD(d){var x,w,v
this.dX(d)
x=this.W$
for(w=y.o;x!=null;){x.aD(d)
v=x.b
v.toString
x=w.a(v).a5$}},
am(){var x,w,v
this.dU()
x=this.W$
for(w=y.o;x!=null;){x.am()
v=x.b
v.toString
x=w.a(v).a5$}}}
A.cFk.prototype={}
var z=a.updateTypes(["q(q)"])
A.fwa.prototype={
$2(d,e){return Math.max(d,e.a0(C.al,1/0,e.gaA()))},
$S:30}
A.fwz.prototype={
$2(d,e){return Math.max(d,e.a0(C.aY,1/0,e.gba()))},
$S:30}
A.fwb.prototype={
$2(d,e){return Math.max(d,e.a0(C.b0,1/0,e.gb7()))},
$S:30}
A.fwc.prototype={
$2(d,e){return d+e.a0(C.b0,this.a,e.gb7())},
$S:30}
A.fwq.prototype={
$2(d,e){var x
if(this.a)x=d.a0(C.ax,e,d.gc6())
else{d.bk(e,!0)
x=d.gE()}return x},
$S:52}
A.fwh.prototype={
$2(d,e){return Math.max(d,e.b)},
$S:153}
A.fwi.prototype={
$2(d,e){return d+e.a},
$S:153}
A.fwj.prototype={
$1(d){return this.a.$1(this.b)},
$S:4};(function installTearOffs(){var x=a._instance_1u
var w
x(w=A.aAy.prototype,"gba","b1",0)
x(w,"gaA","aQ",0)
x(w,"gbd","aG",0)
x(w,"gb7","aM",0)})();(function inheritance(){var x=a.mixinHard,w=a.mixin,v=a.inherit,u=a.inheritMany
v(A.bHv,B.dj)
v(A.Fg,B.dy)
v(A.cFh,B.w)
v(A.cFk,A.cFh)
v(A.aAy,A.cFk)
u(B.dk,[A.fwa,A.fwz,A.fwb,A.fwc,A.fwq,A.fwh,A.fwi])
v(A.fwj,B.cl)
x(A.cFh,B.al)
w(A.cFk,B.ba)})()
B.bO(b.typeUniverse,JSON.parse('{"Fg":{"dy":["w"],"dB":[],"eB":["w"],"e8":[]},"bHv":{"dj":[],"aP":[],"b":[]},"aAy":{"ba":["w","Fg"],"w":[],"al":["w","Fg"],"H":[],"aQ":[],"al.1":"Fg","ba.1":"Fg","ba.0":"w","al.0":"w"}}'))
var y={a:B.G("B"),n:B.G("dv"),A:B.G("o<I>"),g:B.G("w"),o:B.G("Fg"),r:B.G("aAy")}};
(a=>{a["ysqDo3zqgbEImbNxugIIvEMWtaY="]=a.current})($__dart_deferred_initializers__);