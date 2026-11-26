((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,H,A={
zE(d,e,f,g,h,i){var x=B.aH(h,i),w=g==null?new A.dCL(i):g
return new A.wj(d,e,w,x,f,C.eD,B.az(y.K),$.T(),i.k("wj<0>"))},
j5S(d,e){return J.ak9(d,e)},
uP(d,e,f,g,h,i,j,k,l){return new A.asS(e,f,d,i,g,j,h,k,null,l.k("asS<0>"))},
cT:function cT(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.$ti=h},
aS8:function aS8(d,e){this.a=d
this.b=e},
wj:function wj(d,e,f,g,h,i,j,k,l){var _=this
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
_.M$=0
_.O$=k
_.au$=_.av$=0
_.$ti=l},
dCL:function dCL(d){this.a=d},
dCO:function dCO(d,e){this.a=d
this.b=e},
dCM:function dCM(d,e){this.a=d
this.b=e},
dCN:function dCN(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
pN:function pN(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
asS:function asS(d,e,f,g,h,i,j,k,l,m){var _=this
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
QQ:function QQ(){},
aAW:function aAW(d,e){var _=this
_.d=d
_.e=0
_.c=_.a=null
_.$ti=e},
frr:function frr(){},
fru:function fru(d,e){this.a=d
this.b=e},
frv:function frv(d,e){this.a=d
this.b=e},
frt:function frt(d,e){this.a=d
this.b=e},
frs:function frs(d,e,f){this.a=d
this.b=e
this.c=f},
fry:function fry(d,e,f){this.a=d
this.b=e
this.c=f},
frx:function frx(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
frw:function frw(d,e,f){this.a=d
this.b=e
this.c=f},
frz:function frz(d,e){this.a=d
this.b=e},
uw(){return b.G.document.createElement("input")}},D,E,I,F,G,K
J=c[1]
B=c[0]
C=c[2]
H=c[373]
A=a.updateHolder(c[167],A)
D=c[340]
E=c[341]
I=c[398]
F=c[269]
G=c[283]
K=c[291]
A.cT.prototype={}
A.aS8.prototype={
Y(){return"RawDataTableSelection."+this.b}}
A.wj.prototype={
sMt(d){var x,w,v,u,t=this,s=B.aH(d,B.a_(t).c)
t.e=s
x=B.az(y.K)
for(w=s.length,v=t.d,u=0;u<s.length;s.length===w||(0,B.F)(s),++u)x.H(0,v.$1(s[u]))
t.z.EM(x.gnb(x),!1)
t.a9z(!0)},
suu(d){if(d===this.w)return
this.w=d
this.WM()},
iv(d,e){var x=this
if(C.d.ni(x.a,new A.dCO(x,e)).c==null)return
if(x.x!==e){x.x=e
x.y=C.eD}else if(x.y===C.eD)x.y=H.pA
else{x.x=null
x.y=C.eD}x.WM()},
gyj(){var x,w,v,u,t,s,r,q,p,o,n,m=this,l=m.as
if(l!=null)return l
x=m.b
w=B.a_(m)
v=B.a([],w.k("o<1>"))
for(u=m.e,t=u.length,s=x!=null,r=0;r<u.length;u.length===t||(0,B.F)(u),++r){q=u[r]
p=m.w
if(p.length===0||!s||x.$2(q,p))v.push(q)}o=m.x
if(o!=null){u=C.d.ni(m.a,new A.dCM(m,o)).c
u.toString
t=B.an(y.K,y.S)
for(s=m.d,n=0;n<v.length;++n)t.S(0,s.$1(v[n]),n)
C.d.iv(v,new A.dCN(m,u,m.y===C.eD?1:-1,t))}return m.as=B.pH(v,w.c)},
gl_(){var x=this.f
if(x==null||this.gyj().length===0)return 1
return C.o.j8(this.gyj().length+x-1,x)},
uy(d){var x=this,w=C.o.J(d,0,x.gl_()-1)
if(w===x.r)return
x.r=w
x.V()},
gpj(){var x,w=this,v=w.f
if(v==null)return w.gyj()
x=w.r*v
if(x>=w.gyj().length)return I.jh
return C.d.iY(w.gyj(),x,C.o.J(x+v,0,w.gyj().length))},
bXo(d){return this.z.m(0,this.d.$1(d))},
c2m(d,e){var x,w,v,u,t,s,r,q=this,p=q.d,o=p.$1(d),n=q.Q
if(e&&n!=null){x=B.a([],y.f)
for(w=q.gyj(),v=w.length,u=0;u<v;++u)x.push(p.$1(w[u]))
t=C.d.fG(x,n)
s=C.d.fG(x,o)
if(t>=0&&s>=0){p=t<s
r=p?t:s
q.z.F(0,C.d.iY(x,r,(p?s:t)+1))
q.V()
return}}p=q.z
if(!p.aj(0,o))p.H(0,o)
q.Q=o
q.V()},
gpZ(){var x=this.gpj(),w=new B.aR(x,this.ga3H(),B.aA(x).k("aR<1>")).ga9(0)
if(w===0)return D.YH
return w===x.length?D.mk:D.DH},
yO(){var x,w,v,u,t=this,s=B.a([],y.f)
for(x=t.gpj(),w=x.length,v=t.d,u=0;u<x.length;x.length===w||(0,B.F)(x),++u)s.push(v.$1(x[u]))
x=t.z
if(t.gpZ()===D.mk)x.uv(s)
else x.F(0,s)
t.V()},
a9z(d){var x=this
x.as=null
x.r=d?C.o.J(x.r,0,x.gl_()-1):0
x.V()},
WM(){return this.a9z(!1)}}
A.pN.prototype={}
A.asS.prototype={
p(){return new A.aAW(B.a([],y.J),this.$ti.k("aAW<1>"))}}
A.QQ.prototype={}
A.aAW.prototype={
ar(){this.aB()
this.a.c.ae(this.ga9y())},
ag(d){var x,w,v=this
v.ao(d)
x=d.c
if(x!==v.a.c){w=v.ga9y()
x.T(w)
v.a.c.ae(w)}},
l(){var x,w,v,u,t,s=this
s.a.c.T(s.ga9y())
for(x=s.d,w=x.length,v=0;v<x.length;x.length===w||(0,B.F)(x),++v){u=x[v]
t=u.ax
if(t!=null)t.am()
u.d2()}s.L()},
WM(){return this.n(new A.frr())},
bIw(d){var x,w,v,u,t=this
for(x=t.d;w=x.length,w<d;)x.push(B.bH(!0,"RawDataTable row "+w,!0,!0,null,null,!1))
while(x.length>d){w=x.pop()
v=w.ax
if(v!=null)v.am()
w.d2()}if(t.e>=d)t.e=d===0?0:d-1
for(u=0;u<x.length;++u){w=x[u]
v=u!==t.e
if(v!==w.a){w.a=v
v=w.w
if(v!=null){v.w6()
v.d.H(0,w)}}}},
WN(d){var x,w=this.d,v=w.length
if(v===0)return
x=C.o.J(d,0,v-1)
this.n(new A.fru(this,x))
w[x].bF()},
awN(d,e,f){var x,w,v
this.n(new A.frv(this,e))
x=this.a
if(x.w){x=x.c
if(f==null){w=$.eu.fq$
w===$&&B.i()
w=w.a
v=B.a_(w).k("be<2>")
w=new B.be(w,v).m(0,C.jP)||new B.be(w,v).m(0,C.kj)}else w=f
x.c2m(d,w)}},
awM(d,e){return this.awN(d,e,null)},
bek(d,e){var x,w,v,u,t=this
if(!(e instanceof B.dx)&&!(e instanceof B.fL))return C.ag
x=e.b
w=t.a.c.gpj()
if(x.i(0,C.bk))t.WN(t.e+1)
else if(x.i(0,C.bA))t.WN(t.e-1)
else if(x.i(0,C.cu))t.WN(0)
else if(x.i(0,C.cF))t.WN(t.d.length-1)
else{if(x.i(0,C.fN)){v=$.eu.fq$
v===$&&B.i()
v=v.a
u=B.a_(v).k("be<2>")
v=(new B.be(v,u).m(0,C.jP)||new B.be(v,u).m(0,C.kj))&&t.a.w&&t.e<w.length}else v=!1
if(v){v=t.e
t.awN(w[v],v,!0)}else return C.ag}return C.aG},
bqp(d,e){var x=null,w=this.a,v=w.c,u=e.a===v.x?v.y:x
if(e.c==null)return B.C(x,x,x,w.d.$4(d,e,x,C.z),!0,x,x,x,x,x,!1,x,!1,x,x,!0,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,C.l,x)
if(u==null)w=x
else{w=w.y
if(w==null){w=B.W(d,K.L,y.r)
w=(w==null?C.J:w).gaQg()}w=w.$1(u)}return new B.cu(B.C(x,x,x,F.bZ(x,!1,new A.frs(this,e,u),!0,x,x,!0,x,!0,x,x,!1,!1,x,!1,C.x,!1,x,x,x,new A.frt(v,e),x,!1,x,e.b,x,w,x,x,!1,x),!1,x,x,x,x,x,!1,x,!1,x,x,!0,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,C.l,x),x)},
bDE(d,e,f){var x,w=this,v=null,u=w.a.c,t=u.z.m(0,u.d.$1(e)),s=w.a,r=w.d[f]
s=s.w
x=s?t:v
s=s?t:v
return F.bZ(v,!1,new A.frx(w,e,f,t,u),!1,s,v,!0,v,!1,v,r,!1,!1,new B.ax(e,y.x),!1,C.x,!1,v,v,v,new A.fry(w,e,f),v,t,v,v,x,v,v,v,!1,v)},
h(d){var x,w,v,u,t,s,r=this,q=null,p=r.a.c,o=p.gpj()
r.bIw(o.length)
x=y.p
w=B.a([],x)
for(v=p.a,u=v.length,t=0;t<v.length;v.length===u||(0,B.F)(v),++t)w.push(r.bqp(d,v[t]))
v=r.a.r.$2(d,w)
if(v==null){v=B.a([],x)
for(u=w.length,t=0;t<w.length;w.length===u||(0,B.F)(w),++t)v.push(new G.bp(1,C.ac,w[t],q))
w=G.B(v,C.h,q,C.b,C.j,0,q,q)}else w=v
v=B.bC([D.dxu,new B.de(new A.frz(r,p),new B.ck(B.a([],y.k),y.j),y.u)],y.n,y.V)
u=B.a([],x)
for(s=0;s<o.length;++s)u.push(r.bDE(d,o[s],s))
return B.j(B.a([w,B.nh(B.m_(v,B.d8(!1,!1,B.jV(B.j(u,C.n,q,C.b,C.f,0,C.e),q,q),q,q,q,q,!1,q,q,q,r.gbej(),q,!0)),q,!1,D.cQf)],x),C.n,q,C.b,C.f,0,C.e)}}
var z=a.updateTypes(["~()","~(v)","x(Y?)","e_(bG,dm)","~(QQ)"])
A.dCL.prototype={
$1(d){return d},
$S(){return this.a.k("Y(0)")}}
A.dCO.prototype={
$1(d){return d.a===this.b},
$S(){return B.a_(this.a).k("x(cT<1>)")}}
A.dCM.prototype={
$1(d){return d.a===this.b},
$S(){return B.a_(this.a).k("x(cT<1>)")}}
A.dCN.prototype={
$2(d,e){var x,w,v=this,u=v.b,t=A.j5S(u.$1(d),u.$1(e))*v.c
if(t!==0)u=t
else{u=v.d
x=v.a.d
w=u.q(0,x.$1(d))
w.toString
x=u.q(0,x.$1(e))
x.toString
x=C.o.ei(w,x)
u=x}return u},
$S(){return B.a_(this.a).k("v(1,1)")}}
A.frr.prototype={
$0(){},
$S:0}
A.fru.prototype={
$0(){return this.a.e=this.b},
$S:0}
A.frv.prototype={
$0(){return this.a.e=this.b},
$S:0}
A.frt.prototype={
$0(){return this.a.iv(0,this.b.a)},
$S:0}
A.frs.prototype={
$3(d,e,f){return this.a.a.d.$4(d,this.b,this.c,e)},
$S:31}
A.fry.prototype={
$0(){return this.a.awM(this.b,this.c)},
$S:0}
A.frx.prototype={
$3(d,e,f){var x,w,v,u,t,s,r,q=this,p=q.a,o=p.a
o.toString
x=q.b
w=q.c
v=B.a([],y.p)
for(u=q.e.a,t=u.length,s=0;s<u.length;u.length===t||(0,B.F)(u),++s){r=u[s]
v.push(p.a.e.$3(d,x,r))}return o.f.$3(d,new A.pN(x,w,q.d,e,new A.frw(p,x,w)),v)},
$S:31}
A.frw.prototype={
$0(){return this.a.awM(this.b,this.c)},
$S:0}
A.frz.prototype={
$1(d){return this.a.a.w?this.b.yO():null},
$S:z+4};(function installTearOffs(){var x=a._instance_1u,w=a._instance_0u,v=a._instance_2u
var u
x(u=A.wj.prototype,"gI6","uy",1)
x(u,"ga3H","bXo",2)
w(u,"gHN","yO",0)
w(u=A.aAW.prototype,"ga9y","WM",0)
v(u,"gbej","bek",3)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.Y,[A.cT,A.pN])
w(A.aS8,B.ed)
w(A.wj,B.jR)
x(B.ce,[A.dCL,A.dCO,A.dCM,A.frs,A.frx,A.frz])
w(A.dCN,B.di)
w(A.asS,B.k)
w(A.QQ,B.bx)
w(A.aAW,B.m)
x(B.d2,[A.frr,A.fru,A.frv,A.frt,A.fry,A.frw])})()
B.bM(b.typeUniverse,JSON.parse('{"asS":{"k":[],"b":[]},"QQ":{"bx":[]},"wj":{"a6":[]},"aAW":{"m":["asS<1>"]}}'))
B.j6(b.typeUniverse,JSON.parse('{"pN":1}'))
var y=(function rtii(){var x=B.E
return{V:x("ch<bx>"),u:x("de<QQ>"),J:x("o<bG>"),f:x("o<Y>"),p:x("o<b>"),k:x("o<~(ch<bx>)>"),K:x("Y"),j:x("ck<~(ch<bx>)>"),r:x("dC"),n:x("jn"),x:x("ax<Y?>"),S:x("v")}})();(function constants(){var x=a.makeConstList
D.kg=x(["Field notes","Reading list","Trip plan"],B.E("o<n>"))
D.kh=x([E.axZ,E.O7,E.ay1],B.E("o<+(n,v)>"))
D.a1R=new A.QQ()
D.cQf=new B.cs([C.OH,D.a1R,C.ZJ,D.a1R],B.E("cs<eW,bx>"))
D.YH=new A.aS8(0,"none")
D.DH=new A.aS8(1,"some")
D.mk=new A.aS8(2,"all")
D.ku=new B.aj("Drafts folder",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.eq=new B.aj("Planning notes",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.kw=new B.aj("A Field Guide",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.kx=new B.aj("Borrow a book for up to three weeks.",null,null,null,C.a6,null,null,null,null,null,null,null,null,null)
D.dxu=B.cP("QQ")})()};
(a=>{a["Na/x97Bw6WY/axhvbVzubM7iWIE="]=a.current})($__dart_deferred_initializers__);