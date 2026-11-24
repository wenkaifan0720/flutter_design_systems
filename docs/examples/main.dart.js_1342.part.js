((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,H,A={
zh(d,e,f,g,h,i){var x=B.aI(h,i),w=g==null?new A.dAL(i):g
return new A.vV(d,e,w,x,f,C.ey,B.az(y.K),$.S(),i.j("vV<0>"))},
j0w(d,e){return J.ajn(d,e)},
ur(d,e,f,g,h,i,j,k,l){return new A.asd(e,f,d,i,g,j,h,k,null,l.j("asd<0>"))},
cP:function cP(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.$ti=h},
aRr:function aRr(d,e){this.a=d
this.b=e},
vV:function vV(d,e,f,g,h,i,j,k,l){var _=this
_.a=d
_.b=e
_.d=f
_.e=g
_.f=h
_.r=0
_.w=""
_.x=null
_.y=i
_.z=j
_.as=_.Q=null
_.L$=0
_.N$=k
_.aq$=_.au$=0
_.$ti=l},
dAL:function dAL(d){this.a=d},
dAO:function dAO(d,e){this.a=d
this.b=e},
dAM:function dAM(d,e){this.a=d
this.b=e},
dAN:function dAN(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
px:function px(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
asd:function asd(d,e,f,g,h,i,j,k,l,m){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.r=h
_.w=i
_.x=j
_.y=k
_.a=l
_.$ti=m},
Q2:function Q2(){},
axw:function axw(d,e){var _=this
_.d=d
_.e=0
_.c=_.a=null
_.$ti=e},
eyU:function eyU(){},
eyX:function eyX(d,e){this.a=d
this.b=e},
eyY:function eyY(d,e){this.a=d
this.b=e},
eyW:function eyW(d,e){this.a=d
this.b=e},
eyV:function eyV(d,e,f){this.a=d
this.b=e
this.c=f},
ez0:function ez0(d,e,f){this.a=d
this.b=e
this.c=f},
ez_:function ez_(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
eyZ:function eyZ(d,e,f){this.a=d
this.b=e
this.c=f},
ez1:function ez1(d,e){this.a=d
this.b=e},
u9(){return b.G.document.createElement("input")}},D,E,F,I,G,K
J=c[1]
B=c[0]
C=c[2]
H=c[353]
A=a.updateHolder(c[153],A)
D=c[320]
E=c[321]
F=c[264]
I=c[378]
G=c[251]
K=c[272]
A.cP.prototype={}
A.aRr.prototype={
Y(){return"RawDataTableSelection."+this.b}}
A.vV.prototype={
sLV(d){var x,w,v,u,t=this,s=B.aI(d,B.Y(t).c)
t.e=s
x=B.az(y.K)
for(w=s.length,v=t.d,u=0;u<s.length;s.length===w||(0,B.D)(s),++u)x.G(0,v.$1(s[u]))
t.z.Em(x.gmQ(x),!1)
t.a8s(!0)},
sud(d){if(d===this.w)return
this.w=d
this.W0()},
iy(d,e){var x=this
if(C.c.mX(x.a,new A.dAO(x,e)).c==null)return
if(x.x!==e){x.x=e
x.y=C.ey}else if(x.y===C.ey)x.y=H.pt
else{x.x=null
x.y=C.ey}x.W0()},
gxY(){var x,w,v,u,t,s,r,q,p,o,n,m=this,l=m.as
if(l!=null)return l
x=m.b
w=B.Y(m)
v=B.a([],w.j("o<1>"))
for(u=m.e,t=u.length,s=x!=null,r=0;r<u.length;u.length===t||(0,B.D)(u),++r){q=u[r]
p=m.w
if(p.length===0||!s||x.$2(q,p))v.push(q)}o=m.x
if(o!=null){u=C.c.mX(m.a,new A.dAM(m,o)).c
u.toString
t=B.ao(y.K,y.S)
for(s=m.d,n=0;n<v.length;++n)t.O(0,s.$1(v[n]),n)
C.c.iy(v,new A.dAN(m,u,m.y===C.ey?1:-1,t))}return m.as=B.q2(v,w.c)},
gkS(){var x=this.f
if(x==null||this.gxY().length===0)return 1
return C.o.je(this.gxY().length+x-1,x)},
uh(d){var x=this,w=C.o.I(d,0,x.gkS()-1)
if(w===x.r)return
x.r=w
x.U()},
goO(){var x,w=this,v=w.f
if(v==null)return w.gxY()
x=w.r*v
if(x>=w.gxY().length)return I.jc
return C.c.iT(w.gxY(),x,C.o.I(x+v,0,w.gxY().length))},
bVT(d){return this.z.l(0,this.d.$1(d))},
c0O(d,e){var x,w,v,u,t,s,r,q=this,p=q.d,o=p.$1(d),n=q.Q
if(e&&n!=null){x=B.a([],y.f)
for(w=q.gxY(),v=w.length,u=0;u<v;++u)x.push(p.$1(w[u]))
t=C.c.fD(x,n)
s=C.c.fD(x,o)
if(t>=0&&s>=0){p=t<s
r=p?t:s
q.z.E(0,C.c.iT(x,r,(p?s:t)+1))
q.U()
return}}p=q.z
if(!p.aj(0,o))p.G(0,o)
q.Q=o
q.U()},
gpw(){var x=this.goO(),w=new B.aT(x,this.ga2I(),B.aE(x).j("aT<1>")).ga9(0)
if(w===0)return D.Xe
return w===x.length?D.mi:D.D9},
yt(){var x,w,v,u,t=this,s=B.a([],y.f)
for(x=t.goO(),w=x.length,v=t.d,u=0;u<x.length;x.length===w||(0,B.D)(x),++u)s.push(v.$1(x[u]))
x=t.z
if(t.gpw()===D.mi)x.ue(s)
else x.E(0,s)
t.U()},
a8s(d){var x=this
x.as=null
x.r=d?C.o.I(x.r,0,x.gkS()-1):0
x.U()},
W0(){return this.a8s(!1)}}
A.px.prototype={}
A.asd.prototype={
n(){return new A.axw(B.a([],y.J),this.$ti.j("axw<1>"))}}
A.Q2.prototype={}
A.axw.prototype={
ar(){this.aA()
this.a.c.ad(this.ga8r())},
ae(d){var x,w,v=this
v.am(d)
x=d.c
if(x!==v.a.c){w=v.ga8r()
x.S(w)
v.a.c.ad(w)}},
k(){var x,w,v,u,t,s=this
s.a.c.S(s.ga8r())
for(x=s.d,w=x.length,v=0;v<x.length;x.length===w||(0,B.D)(x),++v){u=x[v]
t=u.ax
if(t!=null)t.al()
u.cY()}s.K()},
W0(){return this.m(new A.eyU())},
bHe(d){var x,w,v,u,t=this
for(x=t.d;w=x.length,w<d;)x.push(B.bG(!0,"RawDataTable row "+w,!0,!0,null,null,!1))
while(x.length>d){w=x.pop()
v=w.ax
if(v!=null)v.al()
w.cY()}if(t.e>=d)t.e=d===0?0:d-1
for(u=0;u<x.length;++u){w=x[u]
v=u!==t.e
if(v!==w.a){w.a=v
v=w.w
if(v!=null){v.vJ()
v.d.G(0,w)}}}},
W1(d){var x,w=this.d,v=w.length
if(v===0)return
x=C.o.I(d,0,v-1)
this.m(new A.eyX(this,x))
w[x].bC()},
avK(d,e,f){var x,w,v
this.m(new A.eyY(this,e))
x=this.a
if(x.w){x=x.c
if(f==null){w=$.eq.fn$
w===$&&B.l()
w=w.a
v=B.Y(w).j("bc<2>")
w=new B.bc(w,v).l(0,C.jN)||new B.bc(w,v).l(0,C.kh)}else w=f
x.c0O(d,w)}},
avJ(d,e){return this.avK(d,e,null)},
bdg(d,e){var x,w,v,u,t=this
if(!(e instanceof B.ds)&&!(e instanceof B.fF))return C.ad
x=e.b
w=t.a.c.goO()
if(x.i(0,C.bm))t.W1(t.e+1)
else if(x.i(0,C.bC))t.W1(t.e-1)
else if(x.i(0,C.cv))t.W1(0)
else if(x.i(0,C.cF))t.W1(t.d.length-1)
else{if(x.i(0,C.fM)){v=$.eq.fn$
v===$&&B.l()
v=v.a
u=B.Y(v).j("bc<2>")
v=(new B.bc(v,u).l(0,C.jN)||new B.bc(v,u).l(0,C.kh))&&t.a.w&&t.e<w.length}else v=!1
if(v){v=t.e
t.avK(w[v],v,!0)}else return C.ad}return C.aH},
bpg(d,e){var x=null,w=this.a,v=w.c,u=e.a===v.x?v.y:x
if(e.c==null)return B.B(x,x,x,w.d.$4(d,e,x,C.y),!0,x,x,x,x,x,!1,x,!1,x,x,!0,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,C.l,x)
if(u==null)w=x
else{w=w.y
if(w==null){w=B.W(d,K.M,y.r)
w=(w==null?C.L:w).gaP2()}w=w.$1(u)}return new B.cr(B.B(x,x,x,G.bX(x,!1,new A.eyV(this,e,u),!0,x,x,!0,x,!0,x,x,!1,!1,x,!1,C.z,!1,x,x,x,new A.eyW(v,e),x,!1,x,e.b,x,w,x,x,!1,x),!1,x,x,x,x,x,!1,x,!1,x,x,!0,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,C.l,x),x)},
bCp(d,e,f){var x,w=this,v=null,u=w.a.c,t=u.z.l(0,u.d.$1(e)),s=w.a,r=w.d[f]
s=s.w
x=s?t:v
s=s?t:v
return G.bX(v,!1,new A.ez_(w,e,f,t,u),!1,s,v,!0,v,!1,v,r,!1,!1,new B.av(e,y.x),!1,C.z,!1,v,v,v,new A.ez0(w,e,f),v,t,v,v,x,v,v,v,!1,v)},
h(d){var x,w,v,u,t,s,r=this,q=null,p=r.a.c,o=p.goO()
r.bHe(o.length)
x=y.p
w=B.a([],x)
for(v=p.a,u=v.length,t=0;t<v.length;v.length===u||(0,B.D)(v),++t)w.push(r.bpg(d,v[t]))
v=r.a.r.$2(d,w)
if(v==null){v=B.a([],x)
for(u=w.length,t=0;t<w.length;w.length===u||(0,B.D)(w),++t)v.push(new F.bm(1,C.aa,w[t],q))
w=F.y(v,C.h,q,C.b,C.j,0,q,q)}else w=v
v=B.bB([D.dnO,new B.d8(new A.ez1(r,p),new B.cg(B.a([],y.k),y.j),y.u)],y.n,y.V)
u=B.a([],x)
for(s=0;s<o.length;++s)u.push(r.bCp(d,o[s],s))
return B.h(B.a([w,B.n9(B.lR(v,B.d3(!1,!1,B.jK(B.h(u,C.n,q,C.b,C.f,0,C.d),q,q),q,q,q,q,!1,q,q,q,r.gbdf(),q,!0)),q,!1,D.cH8)],x),C.n,q,C.b,C.f,0,C.d)}}
var z=a.updateTypes(["~()","~(u)","w(X?)","dW(bF,dk)","~(Q2)"])
A.dAL.prototype={
$1(d){return d},
$S(){return this.a.j("X(0)")}}
A.dAO.prototype={
$1(d){return d.a===this.b},
$S(){return B.Y(this.a).j("w(cP<1>)")}}
A.dAM.prototype={
$1(d){return d.a===this.b},
$S(){return B.Y(this.a).j("w(cP<1>)")}}
A.dAN.prototype={
$2(d,e){var x,w,v=this,u=v.b,t=A.j0w(u.$1(d),u.$1(e))*v.c
if(t!==0)u=t
else{u=v.d
x=v.a.d
w=u.p(0,x.$1(d))
w.toString
x=u.p(0,x.$1(e))
x.toString
x=C.o.eh(w,x)
u=x}return u},
$S(){return B.Y(this.a).j("u(1,1)")}}
A.eyU.prototype={
$0(){},
$S:0}
A.eyX.prototype={
$0(){return this.a.e=this.b},
$S:0}
A.eyY.prototype={
$0(){return this.a.e=this.b},
$S:0}
A.eyW.prototype={
$0(){return this.a.iy(0,this.b.a)},
$S:0}
A.eyV.prototype={
$3(d,e,f){return this.a.a.d.$4(d,this.b,this.c,e)},
$S:31}
A.ez0.prototype={
$0(){return this.a.avJ(this.b,this.c)},
$S:0}
A.ez_.prototype={
$3(d,e,f){var x,w,v,u,t,s,r,q=this,p=q.a,o=p.a
o.toString
x=q.b
w=q.c
v=B.a([],y.p)
for(u=q.e.a,t=u.length,s=0;s<u.length;u.length===t||(0,B.D)(u),++s){r=u[s]
v.push(p.a.e.$3(d,x,r))}return o.f.$3(d,new A.px(x,w,q.d,e,new A.eyZ(p,x,w)),v)},
$S:31}
A.eyZ.prototype={
$0(){return this.a.avJ(this.b,this.c)},
$S:0}
A.ez1.prototype={
$1(d){return this.a.a.w?this.b.yt():null},
$S:z+4};(function installTearOffs(){var x=a._instance_1u,w=a._instance_0u,v=a._instance_2u
var u
x(u=A.vV.prototype,"gHF","uh",1)
x(u,"ga2I","bVT",2)
w(u,"gHl","yt",0)
w(u=A.axw.prototype,"ga8r","W0",0)
v(u,"gbdf","bdg",3)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.X,[A.cP,A.px])
w(A.aRr,B.em)
w(A.vV,B.k6)
x(B.cm,[A.dAL,A.dAO,A.dAM,A.eyV,A.ez_,A.ez1])
w(A.dAN,B.dj)
w(A.asd,B.i)
w(A.Q2,B.bv)
w(A.axw,B.k)
x(B.d_,[A.eyU,A.eyX,A.eyY,A.eyW,A.ez0,A.eyZ])})()
B.bN(b.typeUniverse,JSON.parse('{"asd":{"i":[],"b":[]},"Q2":{"bv":[]},"vV":{"a6":[]},"axw":{"k":["asd<1>"]}}'))
B.iT(b.typeUniverse,JSON.parse('{"px":1}'))
var y=(function rtii(){var x=B.F
return{V:x("cd<bv>"),u:x("d8<Q2>"),J:x("o<bF>"),f:x("o<X>"),p:x("o<b>"),k:x("o<~(cd<bv>)>"),K:x("X"),j:x("cg<~(cd<bv>)>"),r:x("dE"),n:x("jb"),x:x("av<X?>"),S:x("u")}})();(function constants(){var x=a.makeConstList
D.ke=x(["Field notes","Reading list","Trip plan"],B.F("o<m>"))
D.kf=x([E.avs,E.Nn,E.avv],B.F("o<+(m,u)>"))
D.a0m=new A.Q2()
D.cH8=new B.cn([C.NX,D.a0m,C.Yh,D.a0m],B.F("cn<eS,bv>"))
D.Xe=new A.aRr(0,"none")
D.D9=new A.aRr(1,"some")
D.mi=new A.aRr(2,"all")
D.ks=new B.ai("Drafts folder",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.el=new B.ai("Planning notes",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.ku=new B.ai("A Field Guide",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.kv=new B.ai("Borrow a book for up to three weeks.",null,null,null,C.a5,null,null,null,null,null,null,null,null,null)
D.dnO=B.cL("Q2")})()};
(a=>{a["puQWkecjAeh9Cngp/Yh2R9OXNwE="]=a.current})($__dart_deferred_initializers__);