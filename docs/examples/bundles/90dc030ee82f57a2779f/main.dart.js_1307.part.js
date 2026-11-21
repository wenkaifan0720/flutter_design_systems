((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,A={
Kp(d,e,f,g,h){var x=B.aH(g,h)
return new A.zI(d,!1,x,B.bv(e,h),B.aA(h),$.R(),h.j("zI<0>"))},
zH(d,e,f,g,h,i,j){return new A.WU(d,h,e,g,f,i,null,j.j("WU<0>"))},
zI:function zI(d,e,f,g,h,i,j){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=null
_.N$=0
_.P$=i
_.aq$=_.av$=0
_.$ti=j},
cJK:function cJK(d,e){this.a=d
this.b=e},
zJ:function zJ(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.$ti=i},
rn:function rn(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},
WU:function WU(d,e,f,g,h,i,j,k){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.r=h
_.w=i
_.a=j
_.$ti=k},
ast:function ast(d,e){var _=this
_.d=d
_.c=_.a=_.e=null
_.$ti=e},
egU:function egU(){},
egX:function egX(){},
egV:function egV(d,e){this.a=d
this.b=e},
egW:function egW(d,e){this.a=d
this.b=e},
egY:function egY(d,e){this.a=d
this.b=e},
eh_:function eh_(d){this.a=d},
eh0:function eh0(d,e){this.a=d
this.b=e},
eh1:function eh1(d,e){this.a=d
this.b=e},
eh3:function eh3(d,e){this.a=d
this.b=e},
eh4:function eh4(d,e,f){this.a=d
this.b=e
this.c=f},
eh2:function eh2(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
egZ:function egZ(d,e){this.a=d
this.b=e}},D,E
J=c[1]
B=c[0]
C=c[2]
A=a.updateHolder(c[128],A)
D=c[237]
E=c[272]
A.zI.prototype={
Hb(d,e){var x,w=this
if(!J.hI(w.a.$1(d)))return
x=w.d
if(e?x.E(0,d):x.af(0,d)){w.f=null
w.V()}},
An(d){var x=this.e
x.bm(0)
x.E(0,d)
this.V()},
gLc(){var x,w,v=this,u=v.f
if(u!=null)return u
x=B.T(v)
w=B.a([],x.j("n<zJ<1>>"))
new A.cJK(v,w).$3(v.c,0,null)
return v.f=B.lF(w,x.j("zJ<1>"))}}
A.zJ.prototype={}
A.rn.prototype={}
A.WU.prototype={
n(){var x=this.$ti
return new A.ast(B.am(x.c,y.c),x.j("ast<1>"))}}
A.ast.prototype={
ap(){this.aw()
this.a.c.ac(this.gaf_())},
ag(d){var x,w,v=this
v.al(d)
x=d.c
if(x!==v.a.c){w=v.gaf_()
x.R(w)
v.a.c.ac(w)}},
k(){var x,w,v,u=this
u.a.c.R(u.gaf_())
for(x=u.d,x=new B.fh(x,x.r,x.e);x.A();){w=x.d
v=w.ax
if(v!=null)v.ai()
w.cD()}u.L()},
bFv(){return this.m(new A.egU())},
bFx(d){return this.d.fi(d,new A.egX())},
I2(d){this.m(new A.egV(this,d))
$.aq.ok$.push(new A.egW(this,d))},
bFy(d){var x,w,v=this,u=v.a.c
v.m(new A.egY(v,d))
x=d.a
u.An(x)
if(J.hI(u.a.$1(x)))u.Hb(x,!u.d.l(0,x))
else{w=v.a.f
if(w!=null)w.$1(x)}},
bFw(d,e,f){var x,w,v,u,t,s,r,q,p,o=this
if(!(f instanceof B.dn)&&!(f instanceof B.fH))return C.ab
x=o.a.c
w=x.gLc()
v=o.c.t(y.o).w===C.J
u=f.b
t=v?C.bU:C.bG
s=v?C.bG:C.bU
r=d.a
if(u.i(0,C.bh)){q=e+1
if(q<w.length)o.I2(w[q].a)}else if(u.i(0,C.bv)){if(e>0)o.I2(w[e-1].a)}else if(u.i(0,C.co))o.I2(C.c.gad(w).a)
else if(u.i(0,C.cA))o.I2(C.c.gb1(w).a)
else if(u.i(0,t)){if(!J.hI(x.a.$1(r)))return C.aG
if(!x.d.l(0,r))x.Hb(r,!0)
else o.I2(x.gLc()[e+1].a)}else if(u.i(0,s)){p=d.c
if(x.d.l(0,r))x.Hb(r,!1)
else if(p!=null)o.I2(p)}else if(u.i(0,C.eg)){q=o.a.f
if(q!=null)q.$1(r)
else x.Hb(r,!x.d.l(0,r))}else if(u.i(0,C.fA))x.An(r)
else if(f.c==="*"){p=d.c
for(q=J.a8(p==null?B.lF(x.c,B.T(x).c):x.a.$1(p));q.A();)x.Hb(q.gJ(),!0)}else return C.ab
return C.aG},
h(a5){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=this,a0=null,a1=d.a.c,a2=a1.gLc(),a3=d.$ti,a4=B.aA(a3.c)
for(x=a2.length,w=0;w<x;++w)a4.E(0,a2[w].a)
a3=B.a([],a3.j("n<eO<1,bB>>"))
for(v=d.d,u=new B.jm(v,B.T(v).j("jm<1,2>")).gb0(0);u.A();){t=u.d
if(!a4.l(0,t.a))a3.push(t)}u=a3.length
if(u!==0){for(w=0;w<a3.length;a3.length===u||(0,B.D)(a3),++w)v.af(0,a3[w].a)
$.aq.ok$.push(new A.eh_(a3))}s=d.e
if(s!=null&&a4.l(0,s))r=s
else r=x===0?a0:C.c.tv(a2,new A.eh0(d,a1),new A.eh1(d,a2)).a
q=B.a([],y.u)
for(a3=y.e,a4=a1.e,v=a1.a,u=a1.d,p=y.l,o=y.h,n=0;n<x;++n){m=a2[n]
l=m.a
k=d.bFx(l)
j=!J.y(l,r)
if(j!==k.a){k.a=j
j=k.w
if(j!=null){j.vf()
j.d.E(0,k)}}i=J.hI(v.$1(l))?u.l(0,l):a0
j=a4.l(0,l)
h=a4.l(0,l)
g=d.a.e.$1(l)
f=d.a.r
if(f==null){e=a5.t(o)
f=e==null?a0:p.a(e.r.e.p(0,E.O))
f=(f==null?C.N:f).gamt()}q.push(new D.it(new A.eh2(d,m,a1,l),a0,new A.eh3(d,m),a0,a0,j,!1,a0,k,!1,a0,C.x,a0,a0,new A.eh4(d,m,n),a0,g,a0,f.$3(m.b+1,m.d+1,m.e),!0,!1,!1,h,a0,!1,a0,i,!1,!0,!0,new B.au(l,a3)))}a3=d.a.w
return B.C(a0,a0,a0,B.jU(B.h(q,C.m,a0,C.b,C.f,0,C.d),a0,a0,a0),!0,a0,a0,a0,a0,a0,!1,a0,!0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a3,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,a0,C.l,a0)}}
var z=a.updateTypes(["~()"])
A.cJK.prototype={
$3(d,e,f){var x,w,v,u,t,s,r,q
for(x=J.cp(d),w=this.a,v=w.d,u=this.b,t=B.T(w).j("zJ<1>"),w=w.a,s=e+1,r=0;r<x.ga6(d);++r){q=x.p(d,r)
u.push(new A.zJ(q,e,f,r,x.ga6(d),t))
if(v.l(0,q))this.$3(w.$1(q),s,q)}},
$S(){return B.T(this.a).j("~(V<1>,u,1?)")}}
A.egU.prototype={
$0(){},
$S:0}
A.egX.prototype={
$0(){return B.bE(!0,"DesignTree row",!0,!0,null,null,!1)},
$S:154}
A.egV.prototype={
$0(){return this.a.e=this.b},
$S:0}
A.egW.prototype={
$1(d){var x=this.a
if(x.c!=null){x=x.d.p(0,this.b)
if(x!=null)x.bq()}},
$S:4}
A.egY.prototype={
$0(){return this.a.e=this.b.a},
$S:0}
A.eh_.prototype={
$1(d){var x,w,v,u,t
for(x=this.a,w=x.length,v=0;v<x.length;x.length===w||(0,B.D)(x),++v){u=x[v].b
t=u.ax
if(t!=null)t.ai()
u.cD()}},
$S:4}
A.eh0.prototype={
$1(d){return this.b.e.l(0,d.a)},
$S(){return this.a.$ti.j("w(zJ<1>)")}}
A.eh1.prototype={
$0(){return C.c.gad(this.b)},
$S(){return this.a.$ti.j("zJ<1>()")}}
A.eh3.prototype={
$0(){return this.a.bFy(this.b)},
$S:0}
A.eh4.prototype={
$2(d,e){return this.a.bFw(this.b,this.c,e)},
$S:24}
A.eh2.prototype={
$3(d,e,f){var x,w,v=this,u=v.a.a
u.toString
x=v.c
w=v.d
return u.d.$2(d,new A.rn(v.b,J.hI(x.a.$1(w)),x.d.l(0,w),x.e.l(0,w),e,new A.egZ(x,w)))},
$S:34}
A.egZ.prototype={
$0(){var x=this.a,w=this.b
return x.Hb(w,!x.d.l(0,w))},
$S:0};(function installTearOffs(){var x=a._instance_0u
x(A.ast.prototype,"gaf_","bFv",0)})();(function inheritance(){var x=a.inherit,w=a.inheritMany
x(A.zI,B.jP)
w(B.ck,[A.cJK,A.egW,A.eh_,A.eh0,A.eh2])
w(B.W,[A.zJ,A.rn])
x(A.WU,B.i)
x(A.ast,B.k)
w(B.cS,[A.egU,A.egX,A.egV,A.egY,A.eh1,A.eh3,A.egZ])
x(A.eh4,B.dh)})()
B.bN(b.typeUniverse,JSON.parse('{"WU":{"i":[],"b":[]},"zI":{"a4":[]},"ast":{"k":["WU<1>"]}}'))
B.jt(b.typeUniverse,JSON.parse('{"rn":1}'))
var y={o:B.E("dm"),c:B.E("bB"),u:B.E("n<b>"),e:B.E("au<W>"),h:B.E("wK"),l:B.E("e5?")}};
(a=>{a["TiM6Y+fRAqrG6uZVNEKT9MEVTWY="]=a.current})($__dart_deferred_initializers__);