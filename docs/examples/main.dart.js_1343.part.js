((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,H,A={
ze(d,e,f,g,h,i){var x=B.aI(h,i),w=g==null?new A.dB0(i):g
return new A.vS(d,e,w,x,f,C.ex,B.az(y.K),$.S(),i.j("vS<0>"))},
j_k(d,e){return J.ajg(d,e)},
up(d,e,f,g,h,i,j,k,l){return new A.asa(e,f,d,i,g,j,h,k,null,l.j("asa<0>"))},
cP:function cP(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.$ti=h},
aRt:function aRt(d,e){this.a=d
this.b=e},
vS:function vS(d,e,f,g,h,i,j,k,l){var _=this
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
dB0:function dB0(d){this.a=d},
dB3:function dB3(d,e){this.a=d
this.b=e},
dB1:function dB1(d,e){this.a=d
this.b=e},
dB2:function dB2(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
pv:function pv(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
asa:function asa(d,e,f,g,h,i,j,k,l,m){var _=this
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
PU:function PU(){},
axn:function axn(d,e){var _=this
_.d=d
_.e=0
_.c=_.a=null
_.$ti=e},
ey_:function ey_(){},
ey2:function ey2(d,e){this.a=d
this.b=e},
ey3:function ey3(d,e){this.a=d
this.b=e},
ey1:function ey1(d,e){this.a=d
this.b=e},
ey0:function ey0(d,e,f){this.a=d
this.b=e
this.c=f},
ey6:function ey6(d,e,f){this.a=d
this.b=e
this.c=f},
ey5:function ey5(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
ey4:function ey4(d,e,f){this.a=d
this.b=e
this.c=f},
ey7:function ey7(d,e){this.a=d
this.b=e},
u7(){return b.G.document.createElement("input")}},D,E,F,I,G,K
J=c[1]
B=c[0]
C=c[2]
H=c[352]
A=a.updateHolder(c[153],A)
D=c[320]
E=c[321]
F=c[264]
I=c[377]
G=c[251]
K=c[272]
A.cP.prototype={}
A.aRt.prototype={
X(){return"RawDataTableSelection."+this.b}}
A.vS.prototype={
sLT(d){var x,w,v,u,t=this,s=B.aI(d,B.Y(t).c)
t.e=s
x=B.az(y.K)
for(w=s.length,v=t.d,u=0;u<s.length;s.length===w||(0,B.D)(s),++u)x.G(0,v.$1(s[u]))
t.z.Ej(x.gmO(x),!1)
t.a8o(!0)},
su8(d){if(d===this.w)return
this.w=d
this.VZ()},
iv(d,e){var x=this
if(C.c.mV(x.a,new A.dB3(x,e)).c==null)return
if(x.x!==e){x.x=e
x.y=C.ex}else if(x.y===C.ex)x.y=H.pt
else{x.x=null
x.y=C.ex}x.VZ()},
gxW(){var x,w,v,u,t,s,r,q,p,o,n,m=this,l=m.as
if(l!=null)return l
x=m.b
w=B.Y(m)
v=B.a([],w.j("o<1>"))
for(u=m.e,t=u.length,s=x!=null,r=0;r<u.length;u.length===t||(0,B.D)(u),++r){q=u[r]
p=m.w
if(p.length===0||!s||x.$2(q,p))v.push(q)}o=m.x
if(o!=null){u=C.c.mV(m.a,new A.dB1(m,o)).c
u.toString
t=B.ao(y.K,y.S)
for(s=m.d,n=0;n<v.length;++n)t.O(0,s.$1(v[n]),n)
C.c.iv(v,new A.dB2(m,u,m.y===C.ex?1:-1,t))}return m.as=B.pq(v,w.c)},
gkQ(){var x=this.f
if(x==null||this.gxW().length===0)return 1
return C.o.jb(this.gxW().length+x-1,x)},
ud(d){var x=this,w=C.o.I(d,0,x.gkQ()-1)
if(w===x.r)return
x.r=w
x.U()},
goK(){var x,w=this,v=w.f
if(v==null)return w.gxW()
x=w.r*v
if(x>=w.gxW().length)return I.jc
return C.c.iQ(w.gxW(),x,C.o.I(x+v,0,w.gxW().length))},
bVG(d){return this.z.l(0,this.d.$1(d))},
c0A(d,e){var x,w,v,u,t,s,r,q=this,p=q.d,o=p.$1(d),n=q.Q
if(e&&n!=null){x=B.a([],y.f)
for(w=q.gxW(),v=w.length,u=0;u<v;++u)x.push(p.$1(w[u]))
t=C.c.fB(x,n)
s=C.c.fB(x,o)
if(t>=0&&s>=0){p=t<s
r=p?t:s
q.z.E(0,C.c.iQ(x,r,(p?s:t)+1))
q.U()
return}}p=q.z
if(!p.aj(0,o))p.G(0,o)
q.Q=o
q.U()},
gpu(){var x=this.goK(),w=new B.aR(x,this.ga2E(),B.aE(x).j("aR<1>")).ga8(0)
if(w===0)return D.Xl
return w===x.length?D.mj:D.Dc},
ys(){var x,w,v,u,t=this,s=B.a([],y.f)
for(x=t.goK(),w=x.length,v=t.d,u=0;u<x.length;x.length===w||(0,B.D)(x),++u)s.push(v.$1(x[u]))
x=t.z
if(t.gpu()===D.mj)x.u9(s)
else x.E(0,s)
t.U()},
a8o(d){var x=this
x.as=null
x.r=d?C.o.I(x.r,0,x.gkQ()-1):0
x.U()},
VZ(){return this.a8o(!1)}}
A.pv.prototype={}
A.asa.prototype={
n(){return new A.axn(B.a([],y.J),this.$ti.j("axn<1>"))}}
A.PU.prototype={}
A.axn.prototype={
ar(){this.az()
this.a.c.ad(this.ga8n())},
ae(d){var x,w,v=this
v.am(d)
x=d.c
if(x!==v.a.c){w=v.ga8n()
x.S(w)
v.a.c.ad(w)}},
k(){var x,w,v,u,t,s=this
s.a.c.S(s.ga8n())
for(x=s.d,w=x.length,v=0;v<x.length;x.length===w||(0,B.D)(x),++v){u=x[v]
t=u.ax
if(t!=null)t.al()
u.cW()}s.K()},
VZ(){return this.m(new A.ey_())},
bH2(d){var x,w,v,u,t=this
for(x=t.d;w=x.length,w<d;)x.push(B.bG(!0,"RawDataTable row "+w,!0,!0,null,null,!1))
while(x.length>d){w=x.pop()
v=w.ax
if(v!=null)v.al()
w.cW()}if(t.e>=d)t.e=d===0?0:d-1
for(u=0;u<x.length;++u){w=x[u]
v=u!==t.e
if(v!==w.a){w.a=v
v=w.w
if(v!=null){v.vH()
v.d.G(0,w)}}}},
W_(d){var x,w=this.d,v=w.length
if(v===0)return
x=C.o.I(d,0,v-1)
this.m(new A.ey2(this,x))
w[x].bC()},
avH(d,e,f){var x,w,v
this.m(new A.ey3(this,e))
x=this.a
if(x.w){x=x.c
if(f==null){w=$.ep.fl$
w===$&&B.l()
w=w.a
v=B.Y(w).j("bd<2>")
w=new B.bd(w,v).l(0,C.jN)||new B.bd(w,v).l(0,C.kh)}else w=f
x.c0A(d,w)}},
avG(d,e){return this.avH(d,e,null)},
bd6(d,e){var x,w,v,u,t=this
if(!(e instanceof B.dp)&&!(e instanceof B.fF))return C.ad
x=e.b
w=t.a.c.goK()
if(x.i(0,C.bl))t.W_(t.e+1)
else if(x.i(0,C.bC))t.W_(t.e-1)
else if(x.i(0,C.cu))t.W_(0)
else if(x.i(0,C.cF))t.W_(t.d.length-1)
else{if(x.i(0,C.fL)){v=$.ep.fl$
v===$&&B.l()
v=v.a
u=B.Y(v).j("bd<2>")
v=(new B.bd(v,u).l(0,C.jN)||new B.bd(v,u).l(0,C.kh))&&t.a.w&&t.e<w.length}else v=!1
if(v){v=t.e
t.avH(w[v],v,!0)}else return C.ad}return C.aH},
bp5(d,e){var x=null,w=this.a,v=w.c,u=e.a===v.x?v.y:x
if(e.c==null)return B.B(x,x,x,w.d.$4(d,e,x,C.y),!0,x,x,x,x,x,!1,x,!1,x,x,!0,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,C.l,x)
if(u==null)w=x
else{w=w.y
if(w==null){w=B.X(d,K.M,y.r)
w=(w==null?C.L:w).gaOW()}w=w.$1(u)}return new B.cr(B.B(x,x,x,G.bX(x,!1,new A.ey0(this,e,u),!0,x,x,!0,x,!0,x,x,!1,!1,x,!1,C.z,!1,x,x,x,new A.ey1(v,e),x,!1,x,e.b,x,w,x,x,!1,x),!1,x,x,x,x,x,!1,x,!1,x,x,!0,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,C.l,x),x)},
bCd(d,e,f){var x,w=this,v=null,u=w.a.c,t=u.z.l(0,u.d.$1(e)),s=w.a,r=w.d[f]
s=s.w
x=s?t:v
s=s?t:v
return G.bX(v,!1,new A.ey5(w,e,f,t,u),!1,s,v,!0,v,!1,v,r,!1,!1,new B.ax(e,y.x),!1,C.z,!1,v,v,v,new A.ey6(w,e,f),v,t,v,v,x,v,v,v,!1,v)},
h(d){var x,w,v,u,t,s,r=this,q=null,p=r.a.c,o=p.goK()
r.bH2(o.length)
x=y.p
w=B.a([],x)
for(v=p.a,u=v.length,t=0;t<v.length;v.length===u||(0,B.D)(v),++t)w.push(r.bp5(d,v[t]))
v=r.a.r.$2(d,w)
if(v==null){v=B.a([],x)
for(u=w.length,t=0;t<w.length;w.length===u||(0,B.D)(w),++t)v.push(new F.bl(1,C.aa,w[t],q))
w=F.y(v,C.h,q,C.b,C.j,0,q,q)}else w=v
v=B.bB([D.dnM,new B.d6(new A.ey7(r,p),new B.ci(B.a([],y.k),y.j),y.u)],y.n,y.V)
u=B.a([],x)
for(s=0;s<o.length;++s)u.push(r.bCd(d,o[s],s))
return B.h(B.a([w,B.n8(B.lP(v,B.d3(!1,!1,B.jK(B.h(u,C.n,q,C.b,C.f,0,C.d),q,q),q,q,q,q,!1,q,q,q,r.gbd5(),q,!0)),q,!1,D.cHK)],x),C.n,q,C.b,C.f,0,C.d)}}
var z=a.updateTypes(["~()","~(u)","w(W?)","dW(bF,dh)","~(PU)"])
A.dB0.prototype={
$1(d){return d},
$S(){return this.a.j("W(0)")}}
A.dB3.prototype={
$1(d){return d.a===this.b},
$S(){return B.Y(this.a).j("w(cP<1>)")}}
A.dB1.prototype={
$1(d){return d.a===this.b},
$S(){return B.Y(this.a).j("w(cP<1>)")}}
A.dB2.prototype={
$2(d,e){var x,w,v=this,u=v.b,t=A.j_k(u.$1(d),u.$1(e))*v.c
if(t!==0)u=t
else{u=v.d
x=v.a.d
w=u.p(0,x.$1(d))
w.toString
x=u.p(0,x.$1(e))
x.toString
x=C.o.ef(w,x)
u=x}return u},
$S(){return B.Y(this.a).j("u(1,1)")}}
A.ey_.prototype={
$0(){},
$S:0}
A.ey2.prototype={
$0(){return this.a.e=this.b},
$S:0}
A.ey3.prototype={
$0(){return this.a.e=this.b},
$S:0}
A.ey1.prototype={
$0(){return this.a.iv(0,this.b.a)},
$S:0}
A.ey0.prototype={
$3(d,e,f){return this.a.a.d.$4(d,this.b,this.c,e)},
$S:31}
A.ey6.prototype={
$0(){return this.a.avG(this.b,this.c)},
$S:0}
A.ey5.prototype={
$3(d,e,f){var x,w,v,u,t,s,r,q=this,p=q.a,o=p.a
o.toString
x=q.b
w=q.c
v=B.a([],y.p)
for(u=q.e.a,t=u.length,s=0;s<u.length;u.length===t||(0,B.D)(u),++s){r=u[s]
v.push(p.a.e.$3(d,x,r))}return o.f.$3(d,new A.pv(x,w,q.d,e,new A.ey4(p,x,w)),v)},
$S:31}
A.ey4.prototype={
$0(){return this.a.avG(this.b,this.c)},
$S:0}
A.ey7.prototype={
$1(d){return this.a.a.w?this.b.ys():null},
$S:z+4};(function installTearOffs(){var x=a._instance_1u,w=a._instance_0u,v=a._instance_2u
var u
x(u=A.vS.prototype,"gHB","ud",1)
x(u,"ga2E","bVG",2)
w(u,"gHh","ys",0)
w(u=A.axn.prototype,"ga8n","VZ",0)
v(u,"gbd5","bd6",3)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.W,[A.cP,A.pv])
w(A.aRt,B.em)
w(A.vS,B.k5)
x(B.cl,[A.dB0,A.dB3,A.dB1,A.ey0,A.ey5,A.ey7])
w(A.dB2,B.dg)
w(A.asa,B.i)
w(A.PU,B.bu)
w(A.axn,B.k)
x(B.d_,[A.ey_,A.ey2,A.ey3,A.ey1,A.ey6,A.ey4])})()
B.bM(b.typeUniverse,JSON.parse('{"asa":{"i":[],"b":[]},"PU":{"bu":[]},"vS":{"a6":[]},"axn":{"k":["asa<1>"]}}'))
B.iT(b.typeUniverse,JSON.parse('{"pv":1}'))
var y=(function rtii(){var x=B.F
return{V:x("cd<bu>"),u:x("d6<PU>"),J:x("o<bF>"),f:x("o<W>"),p:x("o<b>"),k:x("o<~(cd<bu>)>"),K:x("W"),j:x("ci<~(cd<bu>)>"),r:x("dE"),n:x("ja"),x:x("ax<W?>"),S:x("u")}})();(function constants(){var x=a.makeConstList
D.ke=x(["Field notes","Reading list","Trip plan"],B.F("o<m>"))
D.kf=x([E.avs,E.Nn,E.avv],B.F("o<+(m,u)>"))
D.a0n=new A.PU()
D.cHK=new B.cm([C.NX,D.a0n,C.Yi,D.a0n],B.F("cm<eR,bu>"))
D.Xl=new A.aRt(0,"none")
D.Dc=new A.aRt(1,"some")
D.mj=new A.aRt(2,"all")
D.kr=new B.ai("Drafts folder",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.ek=new B.ai("Planning notes",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.kt=new B.ai("A Field Guide",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.ku=new B.ai("Borrow a book for up to three weeks.",null,null,null,C.a4,null,null,null,null,null,null,null,null,null)
D.dnM=B.cK("PU")})()};
(a=>{a["g3LH8uuhqe7BCD5WUKw49qhj5Mk="]=a.current})($__dart_deferred_initializers__);