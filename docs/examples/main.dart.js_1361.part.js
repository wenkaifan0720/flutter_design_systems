((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,H,A={
zn(d,e,f,g,h,i){var x=B.aH(h,i),w=g==null?new A.dC_(i):g
return new A.w1(d,e,w,x,f,C.ez,B.az(y.K),$.T(),i.k("w1<0>"))},
j3L(d,e){return J.ajM(d,e)},
uz(d,e,f,g,h,i,j,k,l){return new A.asB(e,f,d,i,g,j,h,k,null,l.k("asB<0>"))},
cS:function cS(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.$ti=h},
aRM:function aRM(d,e){this.a=d
this.b=e},
w1:function w1(d,e,f,g,h,i,j,k,l){var _=this
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
_.ar$=_.av$=0
_.$ti=l},
dC_:function dC_(d){this.a=d},
dC2:function dC2(d,e){this.a=d
this.b=e},
dC0:function dC0(d,e){this.a=d
this.b=e},
dC1:function dC1(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
pC:function pC(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
asB:function asB(d,e,f,g,h,i,j,k,l,m){var _=this
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
Qs:function Qs(){},
axY:function axY(d,e){var _=this
_.d=d
_.e=0
_.c=_.a=null
_.$ti=e},
eAl:function eAl(){},
eAo:function eAo(d,e){this.a=d
this.b=e},
eAp:function eAp(d,e){this.a=d
this.b=e},
eAn:function eAn(d,e){this.a=d
this.b=e},
eAm:function eAm(d,e,f){this.a=d
this.b=e
this.c=f},
eAs:function eAs(d,e,f){this.a=d
this.b=e
this.c=f},
eAr:function eAr(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
eAq:function eAq(d,e,f){this.a=d
this.b=e
this.c=f},
eAt:function eAt(d,e){this.a=d
this.b=e},
uh(){return b.G.document.createElement("input")}},D,E,I,F,G,K
J=c[1]
B=c[0]
C=c[2]
H=c[363]
A=a.updateHolder(c[160],A)
D=c[330]
E=c[331]
I=c[388]
F=c[274]
G=c[260]
K=c[282]
A.cS.prototype={}
A.aRM.prototype={
Y(){return"RawDataTableSelection."+this.b}}
A.w1.prototype={
sMq(d){var x,w,v,u,t=this,s=B.aH(d,B.a_(t).c)
t.e=s
x=B.az(y.K)
for(w=s.length,v=t.d,u=0;u<s.length;s.length===w||(0,B.F)(s),++u)x.H(0,v.$1(s[u]))
t.z.EN(x.gn9(x),!1)
t.a9A(!0)},
suw(d){if(d===this.w)return
this.w=d
this.WK()},
io(d,e){var x=this
if(C.c.nj(x.a,new A.dC2(x,e)).c==null)return
if(x.x!==e){x.x=e
x.y=C.ez}else if(x.y===C.ez)x.y=H.pA
else{x.x=null
x.y=C.ez}x.WK()},
gyo(){var x,w,v,u,t,s,r,q,p,o,n,m=this,l=m.as
if(l!=null)return l
x=m.b
w=B.a_(m)
v=B.a([],w.k("o<1>"))
for(u=m.e,t=u.length,s=x!=null,r=0;r<u.length;u.length===t||(0,B.F)(u),++r){q=u[r]
p=m.w
if(p.length===0||!s||x.$2(q,p))v.push(q)}o=m.x
if(o!=null){u=C.c.nj(m.a,new A.dC0(m,o)).c
u.toString
t=B.am(y.K,y.S)
for(s=m.d,n=0;n<v.length;++n)t.S(0,s.$1(v[n]),n)
C.c.io(v,new A.dC1(m,u,m.y===C.ez?1:-1,t))}return m.as=B.pv(v,w.c)},
gkZ(){var x=this.f
if(x==null||this.gyo().length===0)return 1
return C.o.jj(this.gyo().length+x-1,x)},
uA(d){var x=this,w=C.o.J(d,0,x.gkZ()-1)
if(w===x.r)return
x.r=w
x.V()},
gph(){var x,w=this,v=w.f
if(v==null)return w.gyo()
x=w.r*v
if(x>=w.gyo().length)return I.je
return C.c.iX(w.gyo(),x,C.o.J(x+v,0,w.gyo().length))},
bWY(d){return this.z.m(0,this.d.$1(d))},
c1U(d,e){var x,w,v,u,t,s,r,q=this,p=q.d,o=p.$1(d),n=q.Q
if(e&&n!=null){x=B.a([],y.f)
for(w=q.gyo(),v=w.length,u=0;u<v;++u)x.push(p.$1(w[u]))
t=C.c.fJ(x,n)
s=C.c.fJ(x,o)
if(t>=0&&s>=0){p=t<s
r=p?t:s
q.z.F(0,C.c.iX(x,r,(p?s:t)+1))
q.V()
return}}p=q.z
if(!p.aj(0,o))p.H(0,o)
q.Q=o
q.V()},
gpZ(){var x=this.gph(),w=new B.aR(x,this.ga3H(),B.aA(x).k("aR<1>")).ga9(0)
if(w===0)return D.Y_
return w===x.length?D.mn:D.Dr},
yT(){var x,w,v,u,t=this,s=B.a([],y.f)
for(x=t.gph(),w=x.length,v=t.d,u=0;u<x.length;x.length===w||(0,B.F)(x),++u)s.push(v.$1(x[u]))
x=t.z
if(t.gpZ()===D.mn)x.ux(s)
else x.F(0,s)
t.V()},
a9A(d){var x=this
x.as=null
x.r=d?C.o.J(x.r,0,x.gkZ()-1):0
x.V()},
WK(){return this.a9A(!1)}}
A.pC.prototype={}
A.asB.prototype={
p(){return new A.axY(B.a([],y.J),this.$ti.k("axY<1>"))}}
A.Qs.prototype={}
A.axY.prototype={
au(){this.aB()
this.a.c.ae(this.ga9z())},
ag(d){var x,w,v=this
v.ao(d)
x=d.c
if(x!==v.a.c){w=v.ga9z()
x.T(w)
v.a.c.ae(w)}},
l(){var x,w,v,u,t,s=this
s.a.c.T(s.ga9z())
for(x=s.d,w=x.length,v=0;v<x.length;x.length===w||(0,B.F)(x),++v){u=x[v]
t=u.ax
if(t!=null)t.an()
u.cZ()}s.L()},
WK(){return this.n(new A.eAl())},
bI9(d){var x,w,v,u,t=this
for(x=t.d;w=x.length,w<d;)x.push(B.bH(!0,"RawDataTable row "+w,!0,!0,null,null,!1))
while(x.length>d){w=x.pop()
v=w.ax
if(v!=null)v.an()
w.cZ()}if(t.e>=d)t.e=d===0?0:d-1
for(u=0;u<x.length;++u){w=x[u]
v=u!==t.e
if(v!==w.a){w.a=v
v=w.w
if(v!=null){v.w6()
v.d.H(0,w)}}}},
WL(d){var x,w=this.d,v=w.length
if(v===0)return
x=C.o.J(d,0,v-1)
this.n(new A.eAo(this,x))
w[x].bG()},
awz(d,e,f){var x,w,v
this.n(new A.eAp(this,e))
x=this.a
if(x.w){x=x.c
if(f==null){w=$.es.fq$
w===$&&B.m()
w=w.a
v=B.a_(w).k("bd<2>")
w=new B.bd(w,v).m(0,C.jO)||new B.bd(w,v).m(0,C.kj)}else w=f
x.c1U(d,w)}},
awy(d,e){return this.awz(d,e,null)},
be4(d,e){var x,w,v,u,t=this
if(!(e instanceof B.du)&&!(e instanceof B.fL))return C.ae
x=e.b
w=t.a.c.gph()
if(x.i(0,C.bk))t.WL(t.e+1)
else if(x.i(0,C.bA))t.WL(t.e-1)
else if(x.i(0,C.cu))t.WL(0)
else if(x.i(0,C.cE))t.WL(t.d.length-1)
else{if(x.i(0,C.fP)){v=$.es.fq$
v===$&&B.m()
v=v.a
u=B.a_(v).k("bd<2>")
v=(new B.bd(v,u).m(0,C.jO)||new B.bd(v,u).m(0,C.kj))&&t.a.w&&t.e<w.length}else v=!1
if(v){v=t.e
t.awz(w[v],v,!0)}else return C.ae}return C.aH},
bq5(d,e){var x=null,w=this.a,v=w.c,u=e.a===v.x?v.y:x
if(e.c==null)return B.C(x,x,x,w.d.$4(d,e,x,C.z),!0,x,x,x,x,x,!1,x,!1,x,x,!0,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,C.l,x)
if(u==null)w=x
else{w=w.y
if(w==null){w=B.X(d,K.M,y.r)
w=(w==null?C.K:w).gaQ0()}w=w.$1(u)}return new B.ct(B.C(x,x,x,G.bY(x,!1,new A.eAm(this,e,u),!0,x,x,!0,x,!0,x,x,!1,!1,x,!1,C.y,!1,x,x,x,new A.eAn(v,e),x,!1,x,e.b,x,w,x,x,!1,x),!1,x,x,x,x,x,!1,x,!1,x,x,!0,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,C.l,x),x)},
bDi(d,e,f){var x,w=this,v=null,u=w.a.c,t=u.z.m(0,u.d.$1(e)),s=w.a,r=w.d[f]
s=s.w
x=s?t:v
s=s?t:v
return G.bY(v,!1,new A.eAr(w,e,f,t,u),!1,s,v,!0,v,!1,v,r,!1,!1,new B.aw(e,y.x),!1,C.y,!1,v,v,v,new A.eAs(w,e,f),v,t,v,v,x,v,v,v,!1,v)},
h(d){var x,w,v,u,t,s,r=this,q=null,p=r.a.c,o=p.gph()
r.bI9(o.length)
x=y.p
w=B.a([],x)
for(v=p.a,u=v.length,t=0;t<v.length;v.length===u||(0,B.F)(v),++t)w.push(r.bq5(d,v[t]))
v=r.a.r.$2(d,w)
if(v==null){v=B.a([],x)
for(u=w.length,t=0;t<w.length;w.length===u||(0,B.F)(w),++t)v.push(new F.bo(1,C.ab,w[t],q))
w=F.A(v,C.h,q,C.b,C.j,0,q,q)}else w=v
v=B.bA([D.doO,new B.db(new A.eAt(r,p),new B.cj(B.a([],y.k),y.j),y.u)],y.n,y.V)
u=B.a([],x)
for(s=0;s<o.length;++s)u.push(r.bDi(d,o[s],s))
return B.i(B.a([w,B.nb(B.lU(v,B.d7(!1,!1,B.jS(B.i(u,C.n,q,C.b,C.f,0,C.d),q,q),q,q,q,q,!1,q,q,q,r.gbe3(),q,!0)),q,!1,D.cHY)],x),C.n,q,C.b,C.f,0,C.d)}}
var z=a.updateTypes(["~()","~(v)","x(Y?)","dZ(bG,dl)","~(Qs)"])
A.dC_.prototype={
$1(d){return d},
$S(){return this.a.k("Y(0)")}}
A.dC2.prototype={
$1(d){return d.a===this.b},
$S(){return B.a_(this.a).k("x(cS<1>)")}}
A.dC0.prototype={
$1(d){return d.a===this.b},
$S(){return B.a_(this.a).k("x(cS<1>)")}}
A.dC1.prototype={
$2(d,e){var x,w,v=this,u=v.b,t=A.j3L(u.$1(d),u.$1(e))*v.c
if(t!==0)u=t
else{u=v.d
x=v.a.d
w=u.q(0,x.$1(d))
w.toString
x=u.q(0,x.$1(e))
x.toString
x=C.o.ed(w,x)
u=x}return u},
$S(){return B.a_(this.a).k("v(1,1)")}}
A.eAl.prototype={
$0(){},
$S:0}
A.eAo.prototype={
$0(){return this.a.e=this.b},
$S:0}
A.eAp.prototype={
$0(){return this.a.e=this.b},
$S:0}
A.eAn.prototype={
$0(){return this.a.io(0,this.b.a)},
$S:0}
A.eAm.prototype={
$3(d,e,f){return this.a.a.d.$4(d,this.b,this.c,e)},
$S:31}
A.eAs.prototype={
$0(){return this.a.awy(this.b,this.c)},
$S:0}
A.eAr.prototype={
$3(d,e,f){var x,w,v,u,t,s,r,q=this,p=q.a,o=p.a
o.toString
x=q.b
w=q.c
v=B.a([],y.p)
for(u=q.e.a,t=u.length,s=0;s<u.length;u.length===t||(0,B.F)(u),++s){r=u[s]
v.push(p.a.e.$3(d,x,r))}return o.f.$3(d,new A.pC(x,w,q.d,e,new A.eAq(p,x,w)),v)},
$S:31}
A.eAq.prototype={
$0(){return this.a.awy(this.b,this.c)},
$S:0}
A.eAt.prototype={
$1(d){return this.a.a.w?this.b.yT():null},
$S:z+4};(function installTearOffs(){var x=a._instance_1u,w=a._instance_0u,v=a._instance_2u
var u
x(u=A.w1.prototype,"gI1","uA",1)
x(u,"ga3H","bWY",2)
w(u,"gHI","yT",0)
w(u=A.axY.prototype,"ga9z","WK",0)
v(u,"gbe3","be4",3)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.Y,[A.cS,A.pC])
w(A.aRM,B.eh)
w(A.w1,B.jO)
x(B.cf,[A.dC_,A.dC2,A.dC0,A.eAm,A.eAr,A.eAt])
w(A.dC1,B.di)
w(A.asB,B.j)
w(A.Qs,B.bw)
w(A.axY,B.l)
x(B.d2,[A.eAl,A.eAo,A.eAp,A.eAn,A.eAs,A.eAq])})()
B.bN(b.typeUniverse,JSON.parse('{"asB":{"j":[],"b":[]},"Qs":{"bw":[]},"w1":{"a6":[]},"axY":{"l":["asB<1>"]}}'))
B.j3(b.typeUniverse,JSON.parse('{"pC":1}'))
var y=(function rtii(){var x=B.G
return{V:x("cg<bw>"),u:x("db<Qs>"),J:x("o<bG>"),f:x("o<Y>"),p:x("o<b>"),k:x("o<~(cg<bw>)>"),K:x("Y"),j:x("cj<~(cg<bw>)>"),r:x("dE"),n:x("ji"),x:x("aw<Y?>"),S:x("v")}})();(function constants(){var x=a.makeConstList
D.kg=x(["Field notes","Reading list","Trip plan"],B.G("o<n>"))
D.kh=x([E.awb,E.NR,E.awe],B.G("o<+(n,v)>"))
D.a13=new A.Qs()
D.cHY=new B.cr([C.Oq,D.a13,C.Z2,D.a13],B.G("cr<eW,bw>"))
D.Y_=new A.aRM(0,"none")
D.Dr=new A.aRM(1,"some")
D.mn=new A.aRM(2,"all")
D.kv=new B.ai("Drafts folder",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.em=new B.ai("Planning notes",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.kx=new B.ai("A Field Guide",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.ky=new B.ai("Borrow a book for up to three weeks.",null,null,null,C.a5,null,null,null,null,null,null,null,null,null)
D.doO=B.cN("Qs")})()};
(a=>{a["k/FwETtcE3vdo02zyiM//Mk7OKM="]=a.current})($__dart_deferred_initializers__);