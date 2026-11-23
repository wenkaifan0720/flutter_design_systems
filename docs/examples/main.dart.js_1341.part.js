((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,H,A={
za(d,e,f,g,h,i){var x=B.aI(h,i),w=g==null?new A.dAo(i):g
return new A.vS(d,e,w,x,f,C.eu,B.az(y.K),$.T(),i.j("vS<0>"))},
iYW(d,e){return J.aj2(d,e)},
up(d,e,f,g,h,i,j,k,l){return new A.arT(e,f,d,i,g,j,h,k,null,l.j("arT<0>"))},
cP:function cP(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.$ti=h},
aR5:function aR5(d,e){this.a=d
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
_.M$=0
_.N$=k
_.ar$=_.au$=0
_.$ti=l},
dAo:function dAo(d){this.a=d},
dAr:function dAr(d,e){this.a=d
this.b=e},
dAp:function dAp(d,e){this.a=d
this.b=e},
dAq:function dAq(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
pq:function pq(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
arT:function arT(d,e,f,g,h,i,j,k,l,m){var _=this
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
Q4:function Q4(){},
ax3:function ax3(d,e){var _=this
_.d=d
_.e=0
_.c=_.a=null
_.$ti=e},
ewX:function ewX(){},
ex_:function ex_(d,e){this.a=d
this.b=e},
ex0:function ex0(d,e){this.a=d
this.b=e},
ewZ:function ewZ(d,e){this.a=d
this.b=e},
ewY:function ewY(d,e,f){this.a=d
this.b=e
this.c=f},
ex3:function ex3(d,e,f){this.a=d
this.b=e
this.c=f},
ex2:function ex2(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
ex1:function ex1(d,e,f){this.a=d
this.b=e
this.c=f},
ex4:function ex4(d,e){this.a=d
this.b=e},
u6(){return b.G.document.createElement("input")}},D,E,F,I,G,K
J=c[1]
B=c[0]
C=c[2]
H=c[350]
A=a.updateHolder(c[153],A)
D=c[318]
E=c[319]
F=c[264]
I=c[377]
G=c[251]
K=c[272]
A.cP.prototype={}
A.aR5.prototype={
X(){return"RawDataTableSelection."+this.b}}
A.vS.prototype={
sLM(d){var x,w,v,u,t=this,s=B.aI(d,B.Y(t).c)
t.e=s
x=B.az(y.K)
for(w=s.length,v=t.d,u=0;u<s.length;s.length===w||(0,B.D)(s),++u)x.G(0,v.$1(s[u]))
t.z.Ei(x.gn8(x),!1)
t.a8f(!0)},
su3(d){if(d===this.w)return
this.w=d
this.VO()},
ir(d,e){var x=this
if(C.c.mP(x.a,new A.dAr(x,e)).c==null)return
if(x.x!==e){x.x=e
x.y=C.eu}else if(x.y===C.eu)x.y=H.pt
else{x.x=null
x.y=C.eu}x.VO()},
gxT(){var x,w,v,u,t,s,r,q,p,o,n,m=this,l=m.as
if(l!=null)return l
x=m.b
w=B.Y(m)
v=B.a([],w.j("o<1>"))
for(u=m.e,t=u.length,s=x!=null,r=0;r<u.length;u.length===t||(0,B.D)(u),++r){q=u[r]
p=m.w
if(p.length===0||!s||x.$2(q,p))v.push(q)}o=m.x
if(o!=null){u=C.c.mP(m.a,new A.dAp(m,o)).c
u.toString
t=B.an(y.K,y.S)
for(s=m.d,n=0;n<v.length;++n)t.P(0,s.$1(v[n]),n)
C.c.ir(v,new A.dAq(m,u,m.y===C.eu?1:-1,t))}return m.as=B.pl(v,w.c)},
gkL(){var x=this.f
if(x==null||this.gxT().length===0)return 1
return C.o.jg(this.gxT().length+x-1,x)},
u8(d){var x=this,w=C.o.I(d,0,x.gkL()-1)
if(w===x.r)return
x.r=w
x.T()},
goH(){var x,w=this,v=w.f
if(v==null)return w.gxT()
x=w.r*v
if(x>=w.gxT().length)return I.jb
return C.c.iO(w.gxT(),x,C.o.I(x+v,0,w.gxT().length))},
bV2(d){return this.z.l(0,this.d.$1(d))},
c_U(d,e){var x,w,v,u,t,s,r,q=this,p=q.d,o=p.$1(d),n=q.Q
if(e&&n!=null){x=B.a([],y.f)
for(w=q.gxT(),v=w.length,u=0;u<v;++u)x.push(p.$1(w[u]))
t=C.c.fC(x,n)
s=C.c.fC(x,o)
if(t>=0&&s>=0){p=t<s
r=p?t:s
q.z.E(0,C.c.iO(x,r,(p?s:t)+1))
q.T()
return}}p=q.z
if(!p.ak(0,o))p.G(0,o)
q.Q=o
q.T()},
gpp(){var x=this.goH(),w=new B.aR(x,this.ga2u(),B.aD(x).j("aR<1>")).ga7(0)
if(w===0)return D.Xe
return w===x.length?D.mh:D.Dg},
yp(){var x,w,v,u,t=this,s=B.a([],y.f)
for(x=t.goH(),w=x.length,v=t.d,u=0;u<x.length;x.length===w||(0,B.D)(x),++u)s.push(v.$1(x[u]))
x=t.z
if(t.gpp()===D.mh)x.u4(s)
else x.E(0,s)
t.T()},
a8f(d){var x=this
x.as=null
x.r=d?C.o.I(x.r,0,x.gkL()-1):0
x.T()},
VO(){return this.a8f(!1)}}
A.pq.prototype={}
A.arT.prototype={
n(){return new A.ax3(B.a([],y.J),this.$ti.j("ax3<1>"))}}
A.Q4.prototype={}
A.ax3.prototype={
aq(){this.aA()
this.a.c.ad(this.ga8e())},
af(d){var x,w,v=this
v.am(d)
x=d.c
if(x!==v.a.c){w=v.ga8e()
x.S(w)
v.a.c.ad(w)}},
k(){var x,w,v,u,t,s=this
s.a.c.S(s.ga8e())
for(x=s.d,w=x.length,v=0;v<x.length;x.length===w||(0,B.D)(x),++v){u=x[v]
t=u.ax
if(t!=null)t.ai()
u.cW()}s.K()},
VO(){return this.m(new A.ewX())},
bGx(d){var x,w,v,u,t=this
for(x=t.d;w=x.length,w<d;)x.push(B.bF(!0,"RawDataTable row "+w,!0,!0,null,null,!1))
while(x.length>d){w=x.pop()
v=w.ax
if(v!=null)v.ai()
w.cW()}if(t.e>=d)t.e=d===0?0:d-1
for(u=0;u<x.length;++u){w=x[u]
v=u!==t.e
if(v!==w.a){w.a=v
v=w.w
if(v!=null){v.vz()
v.d.G(0,w)}}}},
VP(d){var x,w=this.d,v=w.length
if(v===0)return
x=C.o.I(d,0,v-1)
this.m(new A.ex_(this,x))
w[x].bz()},
avj(d,e,f){var x,w,v
this.m(new A.ex0(this,e))
x=this.a
if(x.w){x=x.c
if(f==null){w=$.ep.fn$
w===$&&B.l()
w=w.a
v=B.Y(w).j("bd<2>")
w=new B.bd(w,v).l(0,C.jN)||new B.bd(w,v).l(0,C.kd)}else w=f
x.c_U(d,w)}},
avi(d,e){return this.avj(d,e,null)},
bcS(d,e){var x,w,v,u,t=this
if(!(e instanceof B.dr)&&!(e instanceof B.fG))return C.ad
x=e.b
w=t.a.c.goH()
if(x.i(0,C.bn))t.VP(t.e+1)
else if(x.i(0,C.bD))t.VP(t.e-1)
else if(x.i(0,C.cu))t.VP(0)
else if(x.i(0,C.cE))t.VP(t.d.length-1)
else{if(x.i(0,C.fM)){v=$.ep.fn$
v===$&&B.l()
v=v.a
u=B.Y(v).j("bd<2>")
v=(new B.bd(v,u).l(0,C.jN)||new B.bd(v,u).l(0,C.kd))&&t.a.w&&t.e<w.length}else v=!1
if(v){v=t.e
t.avj(w[v],v,!0)}else return C.ad}return C.aH},
boN(d,e){var x=null,w=this.a,v=w.c,u=e.a===v.x?v.y:x
if(e.c==null)return B.B(x,x,x,w.d.$4(d,e,x,C.y),!0,x,x,x,x,x,!1,x,!1,x,x,!0,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,C.l,x)
if(u==null)w=x
else{w=w.y
if(w==null){w=B.X(d,K.M,y.r)
w=(w==null?C.L:w).gaOH()}w=w.$1(u)}return new B.cv(B.B(x,x,x,G.bV(x,!1,new A.ewY(this,e,u),!0,x,x,!0,x,!0,x,x,!1,!1,x,!1,C.z,!1,x,x,x,new A.ewZ(v,e),x,!1,x,e.b,x,w,x,x,!1,x),!1,x,x,x,x,x,!1,x,!1,x,x,!0,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,C.l,x),x)},
bBM(d,e,f){var x,w=this,v=null,u=w.a.c,t=u.z.l(0,u.d.$1(e)),s=w.a,r=w.d[f]
s=s.w
x=s?t:v
s=s?t:v
return G.bV(v,!1,new A.ex2(w,e,f,t,u),!1,s,v,!0,v,!1,v,r,!1,!1,new B.ax(e,y.x),!1,C.z,!1,v,v,v,new A.ex3(w,e,f),v,t,v,v,x,v,v,v,!1,v)},
h(d){var x,w,v,u,t,s,r=this,q=null,p=r.a.c,o=p.goH()
r.bGx(o.length)
x=y.p
w=B.a([],x)
for(v=p.a,u=v.length,t=0;t<v.length;v.length===u||(0,B.D)(v),++t)w.push(r.boN(d,v[t]))
v=r.a.r.$2(d,w)
if(v==null){v=B.a([],x)
for(u=w.length,t=0;t<w.length;w.length===u||(0,B.D)(w),++t)v.push(new F.bl(1,C.aa,w[t],q))
w=F.y(v,C.h,q,C.b,C.j,0,q,q)}else w=v
v=B.bB([D.dnz,new B.d7(new A.ex4(r,p),new B.ce(B.a([],y.k),y.j),y.u)],y.n,y.V)
u=B.a([],x)
for(s=0;s<o.length;++s)u.push(r.bBM(d,o[s],s))
return B.h(B.a([w,B.n6(B.lK(v,B.d6(!1,!1,B.jH(B.h(u,C.m,q,C.b,C.f,0,C.d),q,q),q,q,q,q,!1,q,q,q,r.gbcR(),q,!0)),q,!0,D.cHF)],x),C.m,q,C.b,C.f,0,C.d)}}
var z=a.updateTypes(["~()","~(u)","w(W?)","dU(bE,di)","~(Q4)"])
A.dAo.prototype={
$1(d){return d},
$S(){return this.a.j("W(0)")}}
A.dAr.prototype={
$1(d){return d.a===this.b},
$S(){return B.Y(this.a).j("w(cP<1>)")}}
A.dAp.prototype={
$1(d){return d.a===this.b},
$S(){return B.Y(this.a).j("w(cP<1>)")}}
A.dAq.prototype={
$2(d,e){var x,w,v=this,u=v.b,t=A.iYW(u.$1(d),u.$1(e))*v.c
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
A.ewX.prototype={
$0(){},
$S:0}
A.ex_.prototype={
$0(){return this.a.e=this.b},
$S:0}
A.ex0.prototype={
$0(){return this.a.e=this.b},
$S:0}
A.ewZ.prototype={
$0(){return this.a.ir(0,this.b.a)},
$S:0}
A.ewY.prototype={
$3(d,e,f){return this.a.a.d.$4(d,this.b,this.c,e)},
$S:31}
A.ex3.prototype={
$0(){return this.a.avi(this.b,this.c)},
$S:0}
A.ex2.prototype={
$3(d,e,f){var x,w,v,u,t,s,r,q=this,p=q.a,o=p.a
o.toString
x=q.b
w=q.c
v=B.a([],y.p)
for(u=q.e.a,t=u.length,s=0;s<u.length;u.length===t||(0,B.D)(u),++s){r=u[s]
v.push(p.a.e.$3(d,x,r))}return o.f.$3(d,new A.pq(x,w,q.d,e,new A.ex1(p,x,w)),v)},
$S:31}
A.ex1.prototype={
$0(){return this.a.avi(this.b,this.c)},
$S:0}
A.ex4.prototype={
$1(d){return this.a.a.w?this.b.yp():null},
$S:z+4};(function installTearOffs(){var x=a._instance_1u,w=a._instance_0u,v=a._instance_2u
var u
x(u=A.vS.prototype,"gHv","u8",1)
x(u,"ga2u","bV2",2)
w(u,"gHb","yp",0)
w(u=A.ax3.prototype,"ga8e","VO",0)
v(u,"gbcR","bcS",3)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.W,[A.cP,A.pq])
w(A.aR5,B.eg)
w(A.vS,B.k4)
x(B.cj,[A.dAo,A.dAr,A.dAp,A.ewY,A.ex2,A.ex4])
w(A.dAq,B.de)
w(A.arT,B.i)
w(A.Q4,B.bn)
w(A.ax3,B.k)
x(B.cU,[A.ewX,A.ex_,A.ex0,A.ewZ,A.ex3,A.ex1])})()
B.bM(b.typeUniverse,JSON.parse('{"arT":{"i":[],"b":[]},"Q4":{"bn":[]},"vS":{"a7":[]},"ax3":{"k":["arT<1>"]}}'))
B.jn(b.typeUniverse,JSON.parse('{"pq":1}'))
var y=(function rtii(){var x=B.E
return{V:x("c6<bn>"),u:x("d7<Q4>"),J:x("o<bE>"),f:x("o<W>"),p:x("o<b>"),k:x("o<~(c6<bn>)>"),K:x("W"),j:x("ce<~(c6<bn>)>"),r:x("dN"),n:x("iH"),x:x("ax<W?>"),S:x("u")}})();(function constants(){var x=a.makeConstList
D.ka=x(["Field notes","Reading list","Trip plan"],B.E("o<m>"))
D.kb=x([E.ave,E.Nj,E.avh],B.E("o<+(m,u)>"))
D.a0b=new A.Q4()
D.cHF=new B.cm([C.NU,D.a0b,C.Y6,D.a0b],B.E("cm<eP,bn>"))
D.Xe=new A.aR5(0,"none")
D.Dg=new A.aR5(1,"some")
D.mh=new A.aR5(2,"all")
D.km=new B.ai("Drafts folder",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.ei=new B.ai("Planning notes",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.ko=new B.ai("A Field Guide",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.kp=new B.ai("Borrow a book for up to three weeks.",null,null,null,C.a4,null,null,null,null,null,null,null,null,null)
D.dnz=B.cK("Q4")})()};
(a=>{a["iHW9nijid05Lpf1MIEDaSfdtOoE="]=a.current})($__dart_deferred_initializers__);