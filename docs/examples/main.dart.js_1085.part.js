((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,F,A={il:function il(d,e,f){this.a=d
this.b=e
this.c=f},
yI(d,e,f,g,h,i){var x=B.aC(h,i),w=g==null?new A.cY3(i):g
return new A.wB(d,e,w,x,f,C.en,B.aG(y.K),$.X(),i.j("wB<0>"))},
hCg(d,e){return J.aqe(d,e)},
v0(d,e,f,g,h,i,j,k,l){return new A.agp(e,f,d,i,g,j,h,k,null,l.j("agp<0>"))},
cD:function cD(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.$ti=h},
aC6:function aC6(d,e){this.a=d
this.b=e},
wB:function wB(d,e,f,g,h,i,j,k,l){var _=this
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
_.P$=0
_.T$=k
_.aG$=_.b_$=0
_.$ti=l},
cY3:function cY3(d){this.a=d},
cY6:function cY6(d,e){this.a=d
this.b=e},
cY4:function cY4(d,e){this.a=d
this.b=e},
cY5:function cY5(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
oR:function oR(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
agp:function agp(d,e,f,g,h,i,j,k,l,m){var _=this
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
Lf:function Lf(){},
akV:function akV(d,e){var _=this
_.d=d
_.e=0
_.c=_.a=null
_.$ti=e},
dKQ:function dKQ(){},
dKT:function dKT(d,e){this.a=d
this.b=e},
dKU:function dKU(d,e){this.a=d
this.b=e},
dKS:function dKS(d,e){this.a=d
this.b=e},
dKR:function dKR(d,e,f){this.a=d
this.b=e
this.c=f},
dKX:function dKX(d,e,f){this.a=d
this.b=e
this.c=f},
dKW:function dKW(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
dKV:function dKV(d,e,f){this.a=d
this.b=e
this.c=f},
dKY:function dKY(d,e){this.a=d
this.b=e},
uG(){return b.G.document.createElement("input")}},D,G,E,H
J=c[1]
B=c[0]
C=c[2]
F=c[264]
A=a.updateHolder(c[134],A)
D=c[255]
G=c[305]
E=c[209]
H=c[219]
A.il.prototype={}
A.cD.prototype={}
A.aC6.prototype={
V(){return"RawDataTableSelection."+this.b}}
A.wB.prototype={
sFM(d){var x,w,v,u,t=this,s=B.aC(d,B.V(t).c)
t.e=s
x=B.aG(y.K)
for(w=s.length,v=t.d,u=0;u<s.length;s.length===w||(0,B.C)(s),++u)x.G(0,v.$1(s[u]))
t.z.zy(x.gkA(x),!1)
t.Zb(!0)},
suA(d){if(d===this.w)return
this.w=d
this.NV()},
fo(d,e){var x=this
if(C.c.lA(x.a,new A.cY6(x,e)).c==null)return
if(x.x!==e){x.x=e
x.y=C.en}else if(x.y===C.en)x.y=F.p1
else{x.x=null
x.y=C.en}x.NV()},
gui(){var x,w,v,u,t,s,r,q,p,o,n,m=this,l=m.as
if(l!=null)return l
x=m.b
w=B.V(m)
v=B.a([],w.j("m<1>"))
for(u=m.e,t=u.length,s=x!=null,r=0;r<u.length;u.length===t||(0,B.C)(u),++r){q=u[r]
p=m.w
if(p.length===0||!s||x.$2(q,p))v.push(q)}o=m.x
if(o!=null){u=C.c.lA(m.a,new A.cY4(m,o)).c
u.toString
t=B.ap(y.K,y.S)
for(s=m.d,n=0;n<v.length;++n)t.K(0,s.$1(v[n]),n)
C.c.fo(v,new A.cY5(m,u,m.y===C.en?1:-1,t))}return m.as=B.kP(v,w.c)},
gjl(){var x=this.f
if(x==null||this.gui().length===0)return 1
return C.n.hV(this.gui().length+x-1,x)},
tb(d){var x=this,w=C.n.I(d,0,x.gjl()-1)
if(w===x.r)return
x.r=w
x.a0()},
gnF(){var x,w=this,v=w.f
if(v==null)return w.gui()
x=w.r*v
if(x>=w.gui().length)return G.iL
return C.c.h0(w.gui(),x,C.n.I(x+v,0,w.gui().length))},
br4(d){return this.z.l(0,this.d.$1(d))},
bwa(d,e){var x,w,v,u,t,s,r,q=this,p=q.d,o=p.$1(d),n=q.Q
if(e&&n!=null){x=B.a([],y.f)
for(w=q.gui(),v=w.length,u=0;u<v;++u)x.push(p.$1(w[u]))
t=C.c.e_(x,n)
s=C.c.e_(x,o)
if(t>=0&&s>=0){p=t<s
r=p?t:s
q.z.E(0,C.c.h0(x,r,(p?s:t)+1))
q.a0()
return}}p=q.z
if(!p.ad(0,o))p.G(0,o)
q.Q=o
q.a0()},
gnG(){var x=this.gnF(),w=new B.aO(x,this.gUk(),B.aw(x).j("aO<1>")).ga3(0)
if(w===0)return D.RO
return w===x.length?D.lY:D.zX},
wr(){var x,w,v,u,t=this,s=B.a([],y.f)
for(x=t.gnF(),w=x.length,v=t.d,u=0;u<x.length;x.length===w||(0,B.C)(x),++u)s.push(v.$1(x[u]))
x=t.z
if(t.gnG()===D.lY)x.pQ(s)
else x.E(0,s)
t.a0()},
Zb(d){var x=this
x.as=null
x.r=d?C.n.I(x.r,0,x.gjl()-1):0
x.a0()},
NV(){return this.Zb(!1)}}
A.oR.prototype={}
A.agp.prototype={
n(){return new A.akV(B.a([],y.J),this.$ti.j("akV<1>"))}}
A.Lf.prototype={}
A.akV.prototype={
aH(){this.aX()
this.a.c.af(this.gZa())},
al(d){var x,w,v=this
v.an(d)
x=d.c
if(x!==v.a.c){w=v.gZa()
x.W(w)
v.a.c.af(w)}},
k(){var x,w,v,u,t,s=this
s.a.c.W(s.gZa())
for(x=s.d,w=x.length,v=0;v<x.length;x.length===w||(0,B.C)(x),++v){u=x[v]
t=u.ax
if(t!=null)t.ah()
u.cp()}s.M()},
NV(){return this.m(new A.dKQ())},
beH(d){var x,w,v,u,t=this
for(x=t.d;w=x.length,w<d;)x.push(B.bN(!0,"RawDataTable row "+w,!0,!0,null,null,!1))
while(x.length>d){w=x.pop()
v=w.ax
if(v!=null)v.ah()
w.cp()}if(t.e>=d)t.e=d===0?0:d-1
for(u=0;u<x.length;++u){w=x[u]
v=u!==t.e
if(v!==w.a){w.a=v
v=w.w
if(v!=null){v.rh()
v.d.G(0,w)}}}},
NW(d){var x,w=this.d,v=w.length
if(v===0)return
x=C.n.I(d,0,v-1)
this.m(new A.dKT(this,x))
w[x].bp()},
ahJ(d,e,f){var x,w,v
this.m(new A.dKU(this,e))
x=this.a
if(x.w){x=x.c
if(f==null){w=$.e0.bI$
w===$&&B.p()
w=w.a
v=B.V(w).j("b_<2>")
w=new B.b_(w,v).l(0,C.ig)||new B.b_(w,v).l(0,C.iM)}else w=f
x.bwa(d,w)}},
ahI(d,e){return this.ahJ(d,e,null)},
aT3(d,e){var x,w,v,u,t=this
if(!(e instanceof B.cY)&&!(e instanceof B.fe))return C.a6
x=e.b
w=t.a.c.gnF()
if(x.i(0,C.b5))t.NW(t.e+1)
else if(x.i(0,C.bk))t.NW(t.e-1)
else if(x.i(0,C.cc))t.NW(0)
else if(x.i(0,C.ch))t.NW(t.d.length-1)
else{if(x.i(0,C.f3)){v=$.e0.bI$
v===$&&B.p()
v=v.a
u=B.V(v).j("b_<2>")
v=(new B.b_(v,u).l(0,C.ig)||new B.b_(v,u).l(0,C.iM))&&t.a.w&&t.e<w.length}else v=!1
if(v){v=t.e
t.ahJ(w[v],v,!0)}else return C.a6}return C.ax},
b0j(d,e){var x=null,w=this.a,v=w.c,u=e.a===v.x?v.y:x
if(e.c==null)return B.D(x,x,w.d.$4(d,e,x,C.v),!0,x,x,x,x,x,!1,x,!1,x,x,!0,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,C.l,x)
if(u==null)w=x
else{w=w.y
if(w==null){w=B.a1(d,H.L,y.r)
w=(w==null?C.J:w).gaxY()}w=w.$1(u)}return new B.cI(B.D(x,x,E.ca(x,!1,new A.dKR(this,e,u),!0,x,x,!0,x,!0,x,x,!1,!1,x,!1,C.t,!1,x,x,x,new A.dKS(v,e),x,!1,x,e.b,x,w,x,x,!1,x),!1,x,x,x,x,x,!1,x,!1,x,x,!0,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,C.l,x),x)},
bb8(d,e,f){var x,w=this,v=null,u=w.a.c,t=u.z.l(0,u.d.$1(e)),s=w.a,r=w.d[f]
s=s.w
x=s?t:v
s=s?t:v
return E.ca(v,!1,new A.dKW(w,e,f,t,u),!1,s,v,!0,v,!1,v,r,!1,!1,new B.aA(e,y.x),!1,C.t,!1,v,v,v,new A.dKX(w,e,f),v,t,v,v,x,v,v,v,!1,v)},
h(d){var x,w,v,u,t,s,r=this,q=null,p=r.a.c,o=p.gnF()
r.beH(o.length)
x=y.p
w=B.a([],x)
for(v=p.a,u=v.length,t=0;t<v.length;v.length===u||(0,B.C)(v),++t)w.push(r.b0j(d,v[t]))
v=r.a.r.$2(d,w)
if(v==null){v=B.a([],x)
for(u=w.length,t=0;t<w.length;w.length===u||(0,B.C)(w),++t)v.push(new E.bo(1,C.a9,w[t],q))
w=E.y(v,C.f,q,C.b,C.i,0,q,q)}else w=v
v=B.bz([D.cZ8,new B.dY(new A.dKY(r,p),new B.cz(B.a([],y.k),y.j),y.u)],y.n,y.V)
u=B.a([],x)
for(s=0;s<o.length;++s)u.push(r.bb8(d,o[s],s))
return B.h(B.a([w,B.pM(B.nm(v,B.cV(!1,!1,B.jO(B.h(u,C.k,q,C.b,C.e,0),q,q),q,q,q,q,!1,q,q,q,r.gaT2(),q,!0)),q,!0,D.cmY)],x),C.k,q,C.b,C.e,0)}}
var z=a.updateTypes(["~()","~(u)","w(T?)","ds(bs,cT)","~(Lf)"])
A.cY3.prototype={
$1(d){return d},
$S(){return this.a.j("T(0)")}}
A.cY6.prototype={
$1(d){return d.a===this.b},
$S(){return B.V(this.a).j("w(cD<1>)")}}
A.cY4.prototype={
$1(d){return d.a===this.b},
$S(){return B.V(this.a).j("w(cD<1>)")}}
A.cY5.prototype={
$2(d,e){var x,w,v=this,u=v.b,t=A.hCg(u.$1(d),u.$1(e))*v.c
if(t!==0)u=t
else{u=v.d
x=v.a.d
w=u.p(0,x.$1(d))
w.toString
x=u.p(0,x.$1(e))
x.toString
x=C.n.d9(w,x)
u=x}return u},
$S(){return B.V(this.a).j("u(1,1)")}}
A.dKQ.prototype={
$0(){},
$S:0}
A.dKT.prototype={
$0(){return this.a.e=this.b},
$S:0}
A.dKU.prototype={
$0(){return this.a.e=this.b},
$S:0}
A.dKS.prototype={
$0(){return this.a.fo(0,this.b.a)},
$S:0}
A.dKR.prototype={
$3(d,e,f){return this.a.a.d.$4(d,this.b,this.c,e)},
$S:33}
A.dKX.prototype={
$0(){return this.a.ahI(this.b,this.c)},
$S:0}
A.dKW.prototype={
$3(d,e,f){var x,w,v,u,t,s,r,q=this,p=q.a,o=p.a
o.toString
x=q.b
w=q.c
v=B.a([],y.p)
for(u=q.e.a,t=u.length,s=0;s<u.length;u.length===t||(0,B.C)(u),++s){r=u[s]
v.push(p.a.e.$3(d,x,r))}return o.f.$3(d,new A.oR(x,w,q.d,e,new A.dKV(p,x,w)),v)},
$S:33}
A.dKV.prototype={
$0(){return this.a.ahI(this.b,this.c)},
$S:0}
A.dKY.prototype={
$1(d){return this.a.a.w?this.b.wr():null},
$S:z+4};(function installTearOffs(){var x=a._instance_1u,w=a._instance_0u,v=a._instance_2u
var u
x(u=A.wB.prototype,"gCh","tb",1)
x(u,"gUk","br4",2)
w(u,"gFS","wr",0)
w(u=A.akV.prototype,"gZa","NV",0)
v(u,"gaT2","aT3",3)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.T,[A.il,A.cD,A.oR])
w(A.aC6,B.ef)
w(A.wB,B.k_)
x(B.cq,[A.cY3,A.cY6,A.cY4,A.dKR,A.dKW,A.dKY])
w(A.cY5,B.df)
w(A.agp,B.j)
w(A.Lf,B.bF)
w(A.akV,B.k)
x(B.db,[A.dKQ,A.dKT,A.dKU,A.dKS,A.dKX,A.dKV])})()
B.c_(b.typeUniverse,JSON.parse('{"agp":{"j":[],"b":[]},"Lf":{"bF":[]},"wB":{"a5":[]},"akV":{"k":["agp<1>"]}}'))
B.ki(b.typeUniverse,JSON.parse('{"oR":1}'))
var y=(function rtii(){var x=B.G
return{V:x("cj<bF>"),u:x("dY<Lf>"),J:x("m<bs>"),f:x("m<T>"),s:x("m<l>"),p:x("m<b>"),k:x("m<~(cj<bF>)>"),K:x("T"),j:x("cz<~(cj<bF>)>"),r:x("dF"),n:x("jj"),x:x("aA<T?>"),S:x("u")}})();(function constants(){var x=a.makeConstList
D.kt=new B.aq("Collect your parcel at the front desk.",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.eK=new B.A(0,460,0,1/0)
D.k3=x(["Field notes","Field guide","Travel diary"],y.s)
D.RX=new B.x("Paper",4)
D.k6=x(["Field notes","Reading list","Trip plan"],y.s)
D.cDq=new B.x("Ink",12)
D.cDR=new B.x("Pens",8)
D.k7=x([D.cDq,D.RX,D.cDR],B.G("m<+(l,u)>"))
D.V1=new A.Lf()
D.cmY=new B.cH([C.Jq,D.V1,C.Sv,D.V1],B.G("cH<eQ,bF>"))
D.RO=new A.aC6(0,"none")
D.zX=new A.aC6(1,"some")
D.lY=new A.aC6(2,"all")
D.kp=new B.aq("Drafts folder",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.kq=new B.aq("Subtotal \xa312",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.ey=new B.aq("Planning notes",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.kr=new B.aq("A Field Guide",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.ks=new B.aq("Borrow a book for up to three weeks.",null,null,null,C.Z,null,null,null,null,null,null,null,null,null)
D.cZ8=B.cr("Lf")})()};
(a=>{a["py/ntAYc+WEZqSp+f2R4+uh9Jw8="]=a.current})($__dart_deferred_initializers__);