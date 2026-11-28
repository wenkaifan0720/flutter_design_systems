((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,H,A={
Ae(d,e,f,g,h,i){var x=B.aG(h,i),w=g==null?new A.dHo(i):g
return new A.wK(d,e,w,x,f,C.eM,B.aA(y.K),$.S(),i.k("wK<0>"))},
jff(d,e){return J.alt(d,e)},
vi(d,e,f,g,h,i,j,k,l){return new A.aui(e,f,d,i,g,j,h,k,null,l.k("aui<0>"))},
cU:function cU(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.$ti=h},
aU5:function aU5(d,e){this.a=d
this.b=e},
wK:function wK(d,e,f,g,h,i,j,k,l){var _=this
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
_.N$=0
_.P$=k
_.aq$=_.au$=0
_.$ti=l},
dHo:function dHo(d){this.a=d},
dHr:function dHr(d,e){this.a=d
this.b=e},
dHp:function dHp(d,e){this.a=d
this.b=e},
dHq:function dHq(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
q9:function q9(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
aui:function aui(d,e,f,g,h,i,j,k,l,m){var _=this
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
RO:function RO(){},
aCw:function aCw(d,e){var _=this
_.d=d
_.e=0
_.c=_.a=null
_.$ti=e},
fy5:function fy5(){},
fy8:function fy8(d,e){this.a=d
this.b=e},
fy9:function fy9(d,e){this.a=d
this.b=e},
fy7:function fy7(d,e){this.a=d
this.b=e},
fy6:function fy6(d,e,f){this.a=d
this.b=e
this.c=f},
fyc:function fyc(d,e,f){this.a=d
this.b=e
this.c=f},
fyb:function fyb(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
fya:function fya(d,e,f){this.a=d
this.b=e
this.c=f},
fyd:function fyd(d,e){this.a=d
this.b=e},
uY(){return b.G.document.createElement("input")}},D,E,I,F,G,K
J=c[1]
B=c[0]
C=c[2]
H=c[373]
A=a.updateHolder(c[167],A)
D=c[339]
E=c[340]
I=c[399]
F=c[270]
G=c[283]
K=c[291]
A.cU.prototype={}
A.aU5.prototype={
a_(){return"RawDataTableSelection."+this.b}}
A.wK.prototype={
sMP(d){var x,w,v,u,t=this,s=B.aG(d,B.a0(t).c)
t.e=s
x=B.aA(y.K)
for(w=s.length,v=t.d,u=0;u<s.length;s.length===w||(0,B.F)(s),++u)x.H(0,v.$1(s[u]))
t.z.F8(x.gnq(x),!1)
t.aak(!0)},
suE(d){if(d===this.w)return
this.w=d
this.Xi()},
iq(d,e){var x=this
if(C.c.nv(x.a,new A.dHr(x,e)).c==null)return
if(x.x!==e){x.x=e
x.y=C.eM}else if(x.y===C.eM)x.y=H.pP
else{x.x=null
x.y=C.eM}x.Xi()},
gyr(){var x,w,v,u,t,s,r,q,p,o,n,m=this,l=m.as
if(l!=null)return l
x=m.b
w=B.a0(m)
v=B.a([],w.k("o<1>"))
for(u=m.e,t=u.length,s=x!=null,r=0;r<u.length;u.length===t||(0,B.F)(u),++r){q=u[r]
p=m.w
if(p.length===0||!s||x.$2(q,p))v.push(q)}o=m.x
if(o!=null){u=C.c.nv(m.a,new A.dHp(m,o)).c
u.toString
t=B.an(y.K,y.S)
for(s=m.d,n=0;n<v.length;++n)t.S(0,s.$1(v[n]),n)
C.c.iq(v,new A.dHq(m,u,m.y===C.eM?1:-1,t))}return m.as=B.of(v,w.c)},
glf(){var x=this.f
if(x==null||this.gyr().length===0)return 1
return C.o.jb(this.gyr().length+x-1,x)},
uI(d){var x=this,w=C.o.J(d,0,x.glf()-1)
if(w===x.r)return
x.r=w
x.X()},
gpt(){var x,w=this,v=w.f
if(v==null)return w.gyr()
x=w.r*v
if(x>=w.gyr().length)return I.jo
return C.c.j2(w.gyr(),x,C.o.J(x+v,0,w.gyr().length))},
c_D(d){return this.z.m(0,this.d.$1(d))},
c5H(d,e){var x,w,v,u,t,s,r,q=this,p=q.d,o=p.$1(d),n=q.Q
if(e&&n!=null){x=B.a([],y.f)
for(w=q.gyr(),v=w.length,u=0;u<v;++u)x.push(p.$1(w[u]))
t=C.c.fJ(x,n)
s=C.c.fJ(x,o)
if(t>=0&&s>=0){p=t<s
r=p?t:s
q.z.F(0,C.c.j2(x,r,(p?s:t)+1))
q.X()
return}}p=q.z
if(!p.ak(0,o))p.H(0,o)
q.Q=o
q.X()},
gqb(){var x=this.gpt(),w=new B.aT(x,this.ga4i(),B.aC(x).k("aT<1>")).gaa(0)
if(w===0)return D.ZO
return w===x.length?D.mu:D.E6},
yZ(){var x,w,v,u,t=this,s=B.a([],y.f)
for(x=t.gpt(),w=x.length,v=t.d,u=0;u<x.length;x.length===w||(0,B.F)(x),++u)s.push(v.$1(x[u]))
x=t.z
if(t.gqb()===D.mu)x.uF(s)
else x.F(0,s)
t.X()},
aak(d){var x=this
x.as=null
x.r=d?C.o.J(x.r,0,x.glf()-1):0
x.X()},
Xi(){return this.aak(!1)}}
A.q9.prototype={}
A.aui.prototype={
p(){return new A.aCw(B.a([],y.J),this.$ti.k("aCw<1>"))}}
A.RO.prototype={}
A.aCw.prototype={
ar(){this.aB()
this.a.c.ae(this.gaaj())},
ai(d){var x,w,v=this
v.ao(d)
x=d.c
if(x!==v.a.c){w=v.gaaj()
x.V(w)
v.a.c.ae(w)}},
l(){var x,w,v,u,t,s=this
s.a.c.V(s.gaaj())
for(x=s.d,w=x.length,v=0;v<x.length;x.length===w||(0,B.F)(x),++v){u=x[v]
t=u.ax
if(t!=null)t.al()
u.cZ()}s.L()},
Xi(){return this.n(new A.fy5())},
bLi(d){var x,w,v,u,t=this
for(x=t.d;w=x.length,w<d;)x.push(B.bH(!0,"RawDataTable row "+w,!0,!0,null,null,!1))
while(x.length>d){w=x.pop()
v=w.ax
if(v!=null)v.al()
w.cZ()}if(t.e>=d)t.e=d===0?0:d-1
for(u=0;u<x.length;++u){w=x[u]
v=u!==t.e
if(v!==w.a){w.a=v
v=w.w
if(v!=null){v.wj()
v.d.H(0,w)}}}},
Xj(d){var x,w=this.d,v=w.length
if(v===0)return
x=C.o.J(d,0,v-1)
this.n(new A.fy8(this,x))
w[x].bF()},
axO(d,e,f){var x,w,v
this.n(new A.fy9(this,e))
x=this.a
if(x.w){x=x.c
if(f==null){w=$.ez.fu$
w===$&&B.i()
w=w.a
v=B.a0(w).k("be<2>")
w=new B.be(w,v).m(0,C.k_)||new B.be(w,v).m(0,C.kv)}else w=f
x.c5H(d,w)}},
axN(d,e){return this.axO(d,e,null)},
bgx(d,e){var x,w,v,u,t=this
if(!(e instanceof B.dB)&&!(e instanceof B.fT))return C.ah
x=e.b
w=t.a.c.gpt()
if(x.i(0,C.bl))t.Xj(t.e+1)
else if(x.i(0,C.bE))t.Xj(t.e-1)
else if(x.i(0,C.cC))t.Xj(0)
else if(x.i(0,C.cL))t.Xj(t.d.length-1)
else{if(x.i(0,C.fT)){v=$.ez.fu$
v===$&&B.i()
v=v.a
u=B.a0(v).k("be<2>")
v=(new B.be(v,u).m(0,C.k_)||new B.be(v,u).m(0,C.kv))&&t.a.w&&t.e<w.length}else v=!1
if(v){v=t.e
t.axO(w[v],v,!0)}else return C.ah}return C.aI},
bsN(d,e){var x=null,w=this.a,v=w.c,u=e.a===v.x?v.y:x
if(e.c==null)return B.D(x,x,x,w.d.$4(d,e,x,C.y),!0,x,x,x,x,x,!1,x,!1,x,x,!0,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,C.l,x)
if(u==null)w=x
else{w=w.y
if(w==null){w=B.X(d,K.L,y.r)
w=(w==null?C.J:w).gaRW()}w=w.$1(u)}return new B.cB(B.D(x,x,x,F.c3(x,!1,new A.fy6(this,e,u),!0,x,x,!0,x,!0,x,x,!1,!1,x,!1,!0,C.x,!1,x,x,x,new A.fy7(v,e),x,!1,x,e.b,x,w,x,x,!1,x),!1,x,x,x,x,x,!1,x,!1,x,x,!0,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,C.l,x),x)},
bGl(d,e,f){var x,w=this,v=null,u=w.a.c,t=u.z.m(0,u.d.$1(e)),s=w.a,r=w.d[f]
s=s.w
x=s?t:v
s=s?t:v
return F.c3(v,!1,new A.fyb(w,e,f,t,u),!1,s,v,!0,v,!1,v,r,!1,!1,new B.au(e,y.x),!1,!0,C.x,!1,v,v,v,new A.fyc(w,e,f),v,t,v,v,x,v,v,v,!1,v)},
h(d){var x,w,v,u,t,s,r=this,q=null,p=r.a.c,o=p.gpt()
r.bLi(o.length)
x=y.p
w=B.a([],x)
for(v=p.a,u=v.length,t=0;t<v.length;v.length===u||(0,B.F)(v),++t)w.push(r.bsN(d,v[t]))
v=r.a.r.$2(d,w)
if(v==null){v=B.a([],x)
for(u=w.length,t=0;t<w.length;w.length===u||(0,B.F)(w),++t)v.push(new G.bq(1,C.ac,w[t],q))
w=G.A(v,C.h,q,C.b,C.j,0,q,q)}else w=v
v=B.bD([D.dFr,new B.dk(new A.fyd(r,p),new B.cs(B.a([],y.k),y.j),y.u)],y.n,y.V)
u=B.a([],x)
for(s=0;s<o.length;++s)u.push(r.bGl(d,o[s],s))
return B.j(B.a([w,B.nA(B.me(v,B.dc(!1,!1,B.jJ(B.j(u,C.n,q,C.b,C.f,0,C.e),q,q),q,q,q,q,!1,q,q,q,r.gbgw(),q,!0)),q,!1,D.cV8)],x),C.n,q,C.b,C.f,0,C.e)}}
var z=a.updateTypes(["~()","~(v)","x(a_?)","e6(bG,dt)","~(RO)"])
A.dHo.prototype={
$1(d){return d},
$S(){return this.a.k("a_(0)")}}
A.dHr.prototype={
$1(d){return d.a===this.b},
$S(){return B.a0(this.a).k("x(cU<1>)")}}
A.dHp.prototype={
$1(d){return d.a===this.b},
$S(){return B.a0(this.a).k("x(cU<1>)")}}
A.dHq.prototype={
$2(d,e){var x,w,v=this,u=v.b,t=A.jff(u.$1(d),u.$1(e))*v.c
if(t!==0)u=t
else{u=v.d
x=v.a.d
w=u.q(0,x.$1(d))
w.toString
x=u.q(0,x.$1(e))
x.toString
x=C.o.em(w,x)
u=x}return u},
$S(){return B.a0(this.a).k("v(1,1)")}}
A.fy5.prototype={
$0(){},
$S:0}
A.fy8.prototype={
$0(){return this.a.e=this.b},
$S:0}
A.fy9.prototype={
$0(){return this.a.e=this.b},
$S:0}
A.fy7.prototype={
$0(){return this.a.iq(0,this.b.a)},
$S:0}
A.fy6.prototype={
$3(d,e,f){return this.a.a.d.$4(d,this.b,this.c,e)},
$S:31}
A.fyc.prototype={
$0(){return this.a.axN(this.b,this.c)},
$S:0}
A.fyb.prototype={
$3(d,e,f){var x,w,v,u,t,s,r,q=this,p=q.a,o=p.a
o.toString
x=q.b
w=q.c
v=B.a([],y.p)
for(u=q.e.a,t=u.length,s=0;s<u.length;u.length===t||(0,B.F)(u),++s){r=u[s]
v.push(p.a.e.$3(d,x,r))}return o.f.$3(d,new A.q9(x,w,q.d,e,new A.fya(p,x,w)),v)},
$S:31}
A.fya.prototype={
$0(){return this.a.axN(this.b,this.c)},
$S:0}
A.fyd.prototype={
$1(d){return this.a.a.w?this.b.yZ():null},
$S:z+4};(function installTearOffs(){var x=a._instance_1u,w=a._instance_0u,v=a._instance_2u
var u
x(u=A.wK.prototype,"gIq","uI",1)
x(u,"ga4i","c_D",2)
w(u,"gI9","yZ",0)
w(u=A.aCw.prototype,"gaaj","Xi",0)
v(u,"gbgw","bgx",3)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.a_,[A.cU,A.q9])
w(A.aU5,B.em)
w(A.wK,B.jV)
x(B.cp,[A.dHo,A.dHr,A.dHp,A.fy6,A.fyb,A.fyd])
w(A.dHq,B.db)
w(A.aui,B.l)
w(A.RO,B.bA)
w(A.aCw,B.m)
x(B.da,[A.fy5,A.fy8,A.fy9,A.fy7,A.fyc,A.fya])})()
B.bP(b.typeUniverse,JSON.parse('{"aui":{"l":[],"b":[]},"RO":{"bA":[]},"wK":{"a7":[]},"aCw":{"m":["aui<1>"]}}'))
B.j8(b.typeUniverse,JSON.parse('{"q9":1}'))
var y=(function rtii(){var x=B.G
return{V:x("cr<bA>"),u:x("dk<RO>"),J:x("o<bG>"),f:x("o<a_>"),p:x("o<b>"),k:x("o<~(cr<bA>)>"),K:x("a_"),j:x("cs<~(cr<bA>)>"),r:x("dK"),n:x("j7"),x:x("au<a_?>"),S:x("v")}})();(function constants(){var x=a.makeConstList
D.ks=x(["Field notes","Reading list","Trip plan"],B.G("o<n>"))
D.kt=x([E.aAM,E.OK,E.aAP],B.G("o<+(n,v)>"))
D.a2W=new A.RO()
D.cV8=new B.cA([C.Pk,D.a2W,C.a_Q,D.a2W],B.G("cA<f0,bA>"))
D.ZO=new A.aU5(0,"none")
D.E6=new A.aU5(1,"some")
D.mu=new A.aU5(2,"all")
D.kC=new B.aj("Drafts folder",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.ey=new B.aj("Planning notes",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.kE=new B.aj("A Field Guide",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.kF=new B.aj("Borrow a book for up to three weeks.",null,null,null,C.a6,null,null,null,null,null,null,null,null,null)
D.dFr=B.cO("RO")})()};
(a=>{a["jCm1LGkup2kkpHoYTqcnov+v6bU="]=a.current})($__dart_deferred_initializers__);