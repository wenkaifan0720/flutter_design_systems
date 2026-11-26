((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,A={
wh(d,e,f,g,h,i){return new A.bIs(i,h,d,f,g,e,null)},
bIs:function bIs(d,e,f,g,h,i,j){var _=this
_.e=d
_.f=e
_.r=f
_.w=g
_.x=h
_.c=i
_.a=j},
FK:function FK(d,e,f){this.dw$=d
this.a5$=e
this.a=f},
aBg:function aBg(d,e,f,g,h,i,j,k,l,m,n){var _=this
_.E=d
_.R=e
_.a4=f
_.ac=g
_.al=h
_.aI=i
_.aE=null
_.c1$=j
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
fyA:function fyA(){},
fyZ:function fyZ(){},
fyB:function fyB(){},
fyC:function fyC(d){this.a=d},
fyQ:function fyQ(d){this.a=d},
fyH:function fyH(){},
fyI:function fyI(){},
fyJ:function fyJ(d,e){this.a=d
this.b=e},
cGw:function cGw(){},
cGz:function cGz(){}},D
J=c[1]
B=c[0]
C=c[2]
A=a.updateHolder(c[232],A)
D=c[283]
A.bIs.prototype={
az(d){var x=this,w=new A.aBg(x.e,x.f,x.r,x.w,d.u(y.n).w,x.x,0,null,null,new B.aZ(),B.aL())
w.aw()
return w},
aH(d,e){var x=this
y.r.a(e)
e.so2(x.e)
e.sanD(x.f)
e.sjQ(x.r)
e.sSq(x.w)
e.aI=x.x
e.sbG(d.u(y.n).w)}}
A.FK.prototype={}
A.aBg.prototype={
so2(d){if(d===this.E)return
this.E=d
this.a6()},
sanD(d){if(d===this.R)return
this.R=d
this.a6()},
sjQ(d){if(d===this.a4)return
this.a4=d
this.a6()},
sSq(d){if(d===this.ac)return
this.ac=d
this.a6()},
sbG(d){if(d===this.al)return
this.al=d
this.a6()},
eS(d){if(!(d.b instanceof A.FK))d.b=new A.FK(null,null,C.M)},
gaf_(){var x,w,v,u,t,s,r=this.hj(),q=r.length
if(q===0)return 0
for(x=0,w=0,v=0;u=r.length,v<u;r.length===q||(0,B.F)(r),++v){t=r[v]
s=C.al.d7(t.dy,1/0,t.gaA())
x+=s
w=Math.max(w,s)}q=this.ac?w*u:x
return q+this.E*Math.max(0,u-1)},
gavQ(){return C.d.b8(this.hj(),0,new A.fyA())},
aU(d){return C.d.b8(this.hj(),0,new A.fyZ())},
aJ(d){return this.gaf_()},
aG(d){return this.asz(d)},
aL(d){return this.asz(d)},
asz(d){var x,w,v=this,u=v.hj()
if(u.length===0)return 0
if(v.gaf_()<=d)return C.d.b8(u,0,new A.fyB())
x=C.d.b8(u,0,new A.fyC(isFinite(d)?d:v.gavQ()))
w=u.length
return x+v.R*Math.max(0,w-1)},
hW(d){return this.v9(d)},
bV(d){return this.asA(d,!0)},
bo(){this.fy=this.asA(y.a.a(B.G.prototype.gX.call(this)),!1)},
asA(b2,b3){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9=this,b0=null,b1=a9.hj()
if(b1.length===0)return new B.I(B.a7(0,b2.a,b2.b),B.a7(0,b2.c,b2.d))
x=b2.b
w=a9.gaf_()
v=w>x+1e-10
u=new A.fyQ(b3)
t=a9.al===C.H
s=!v
if(s){r=isFinite(x)?x:w
if(a9.ac){q=b1.length
p=(r-a9.E*Math.max(0,q-1))/q}else p=b0
q=B.a([],y.A)
for(o=b1.length,n=p!=null,m=0;m<b1.length;b1.length===o||(0,B.F)(b1),++m){l=b1[m]
if(n)k=B.dF(b0,p)
else{j=C.al.d7(l.dy,1/0,l.gaA())
k=new B.y(0,j,0,1/0)}q.push(u.$2(l,k))}i=b2.aT(new B.I(r,C.d.b8(q,0,new A.fyH())))
if(!b3){o=C.d.b8(q,0,new A.fyI())
k=b1.length
h=a9.E
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
for(o=D.ar(b1,0,y.g),n=J.a1(o.a),o=o.b,k=new D.ap(n,o),h=i.b,g=y.o,a2=a0;k.A();){a3=k.c
a3=a3>=0?new B.z(o+a3,n.gK()):B.N(B.ah())
a4=q[a3.a]
a3=a3.b.b
a3.toString
g.a(a3)
a5=t?f-a2-a4.a:a2
a3.a=new B.u(a5,(h-a4.b)/2)
a2+=a4.a+a1}b3=!1}}else{r=isFinite(x)?x:a9.gavQ()
a6=B.dF(b0,r)
for(q=B.aA(b1).k("cE<1>"),o=new B.cE(b1,q),o=new B.cz(o,o.ga9(0),q.k("cz<bQ.E>")),n=!b3,q=q.k("bQ.E"),k=y.o,a7=0;o.A();){h=o.d
if(h==null)h=q.a(h)
a4=u.$2(h,a6)
if(n){h=h.b
h.toString
k.a(h).a=new B.u(0,a7)}a7+=a4.b+a9.R}i=b2.aT(new B.I(r,a7-a9.R))}if(!b3&&a9.aE!==v){q=a9.aE
a9.aE=v
a8=a9.aI
if(a8!=null)s=!s||q!=null
else s=!1
if(s)$.dP.ok$.push(new A.fyJ(a8,v))}return i},
U(d,e){return this.hw(d,e)},
cI(d,e){return this.hK(d,e)}}
A.cGw.prototype={
aC(d){var x,w,v
this.dS(d)
x=this.W$
for(w=y.o;x!=null;){x.aC(d)
v=x.b
v.toString
x=w.a(v).a5$}},
am(){var x,w,v
this.dP()
x=this.W$
for(w=y.o;x!=null;){x.am()
v=x.b
v.toString
x=w.a(v).a5$}}}
A.cGz.prototype={}
var z=a.updateTypes(["q(q)"])
A.fyA.prototype={
$2(d,e){return Math.max(d,e.a_(C.al,1/0,e.gaA()))},
$S:27}
A.fyZ.prototype={
$2(d,e){return Math.max(d,e.a_(C.aU,1/0,e.gb6()))},
$S:27}
A.fyB.prototype={
$2(d,e){return Math.max(d,e.a_(C.aZ,1/0,e.gb7()))},
$S:27}
A.fyC.prototype={
$2(d,e){return d+e.a_(C.aZ,this.a,e.gb7())},
$S:27}
A.fyQ.prototype={
$2(d,e){var x
if(this.a)x=d.a_(C.av,e,d.gc4())
else{d.bk(e,!0)
x=d.gD()}return x},
$S:48}
A.fyH.prototype={
$2(d,e){return Math.max(d,e.b)},
$S:156}
A.fyI.prototype={
$2(d,e){return d+e.a},
$S:156}
A.fyJ.prototype={
$1(d){return this.a.$1(this.b)},
$S:4};(function installTearOffs(){var x=a._instance_1u
var w
x(w=A.aBg.prototype,"gb6","aU",0)
x(w,"gaA","aJ",0)
x(w,"gbc","aG",0)
x(w,"gb7","aL",0)})();(function inheritance(){var x=a.mixinHard,w=a.mixin,v=a.inherit,u=a.inheritMany
v(A.bIs,B.da)
v(A.FK,B.dv)
v(A.cGw,B.w)
v(A.cGz,A.cGw)
v(A.aBg,A.cGz)
u(B.di,[A.fyA,A.fyZ,A.fyB,A.fyC,A.fyQ,A.fyH,A.fyI])
v(A.fyJ,B.ce)
x(A.cGw,B.ak)
w(A.cGz,B.ba)})()
B.bM(b.typeUniverse,JSON.parse('{"FK":{"dv":["w"],"dy":[],"ez":["w"],"e4":[]},"bIs":{"da":[],"aO":[],"b":[]},"aBg":{"ba":["w","FK"],"w":[],"ak":["w","FK"],"G":[],"aQ":[],"ak.1":"FK","ba.1":"FK","ba.0":"w","ak.0":"w"}}'))
var y={a:B.E("y"),n:B.E("dw"),A:B.E("o<I>"),g:B.E("w"),o:B.E("FK"),r:B.E("aBg")}};
(a=>{a["tMR88yvQJ8Hhaqw7KgH7dFXlzbc="]=a.current})($__dart_deferred_initializers__);