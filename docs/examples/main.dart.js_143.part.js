((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,A={
iJA(d,e,f){var x,w,v,u,t
if(f<=C.c.gag(e))return C.c.gag(d)
if(f>=C.c.gb6(e))return C.c.gb6(d)
x=C.c.At(e,new A.hKS(f))
w=d[x]
v=x+1
u=d[v]
t=e[x]
t=B.F(w,u,(f-t)/(e[v]-t))
t.toString
return t},
imS(d,e,f,g,h){var x,w,v=D.bL6(null,null,y.b)
v.F(0,e)
v.F(0,g)
x=B.aI(v,v.$ti.c)
x.$flags=1
w=x
x=B.aE(w).k("aV<1,h>")
x=B.aI(new B.aV(w,new A.hIl(d,e,f,g,h),x),x.k("bS.E"))
x.$flags=1
return new A.elm(x,w)},
ixO(d,e,f){var x,w,v,u,t
if(d==e)return d
if(d==null)return e.a9(f)
if(e==null)return d.a9(1-f)
x=A.imS(d.a,d.zc(),e.a,e.zc(),f)
w=B.CN(d.d,e.d,f)
w.toString
v=B.CN(d.e,e.e,f)
v.toString
u=f<0.5
t=u?d.f:e.f
u=u?d.c:e.c
return new A.dn(w,v,t,x.a,x.b,u)},
elm:function elm(d,e){this.a=d
this.b=e},
hKS:function hKS(d){this.a=d},
hIl:function hIl(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
AY:function AY(){},
dn:function dn(d,e,f,g,h,i){var _=this
_.d=d
_.e=e
_.f=f
_.a=g
_.b=h
_.c=i},
dpf:function dpf(d){this.a=d}},D
J=c[1]
B=c[0]
C=c[2]
A=a.updateHolder(c[226],A)
D=c[266]
A.elm.prototype={}
A.AY.prototype={
zc(){var x,w,v,u=this.b
if(u!=null)return u
u=this.a.length
x=1/(u-1)
w=J.MW(u,y.b)
for(v=0;v<u;++v)w[v]=v*x
return w},
ix(d,e){if(d==null)return this.a9(e)
return null},
iy(d,e){if(d==null)return this.a9(1-e)
return null},
aeo(d,e){var x=this.c
if(x==null)x=null
else x=x.aoy(d,e).a
return x}}
A.dn.prototype={
xU(d,e){var x=this
return B.nI(x.d.N(e).DN(d),x.e.N(e).DN(d),x.a,x.zc(),x.f,x.aeo(d,e))},
fs(d){return this.xU(d,null)},
a9(d){var x=this,w=x.a,v=B.aE(w).k("aV<1,h>")
w=B.aI(new B.aV(w,new A.dpf(d),v),v.k("bS.E"))
return new A.dn(x.d,x.e,x.f,w,x.b,x.c)},
a2E(d){var x=this
return new A.dn(x.d,x.e,x.f,B.dJ(x.a.length,d,!1,y.o),x.b,x.c)},
ix(d,e){if(y.m.b(d))return A.ixO(d,this,e)
return this.a6U(d,e)},
iy(d,e){if(y.m.b(d))return A.ixO(this,d,e)
return this.a6V(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bQ(e)!==B.aG(x))return!1
return e instanceof A.dn&&e.d.i(0,x.d)&&e.e.i(0,x.e)&&e.f===x.f&&J.z(e.c,x.c)&&B.c_(e.a,x.a)&&B.c_(e.b,x.b)},
ga3(d){var x=this,w=B.cB(x.a),v=x.b
v=v==null?null:B.cB(v)
return B.aO(x.d,x.e,x.f,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
B(d){var x=this,w=B.a(["begin: "+x.d.B(0),"end: "+x.e.B(0),"colors: "+B.am(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+B.am(v))
w.push("tileMode: "+x.f.B(0))
v=x.c
if(v!=null)w.push("transform: "+v.B(0))
return"LinearGradient("+C.c.aK(w,", ")+")"}}
var z=a.updateTypes([])
A.hKS.prototype={
$1(d){return d<=this.a},
$S:50}
A.hIl.prototype={
$1(d){var x=this,w=B.F(A.iJA(x.a,x.b,d),A.iJA(x.c,x.d,d),x.e)
w.toString
return w},
$S:216}
A.dpf.prototype={
$1(d){var x=B.F(null,d,this.a)
x.toString
return x},
$S:51};(function aliases(){var x=A.AY.prototype
x.a6U=x.ix
x.a6V=x.iy})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.Y,[A.elm,A.AY])
x(B.cl,[A.hKS,A.hIl,A.dpf])
w(A.dn,A.AY)})()
B.bO(b.typeUniverse,JSON.parse('{"dn":{"AY":[]}}'))
var y={o:B.G("h"),h:B.G("o<n>"),b:B.G("q"),m:B.G("dn?")}};
(a=>{a["Vnbakei/qYn5HPedeWV+nJczO3g="]=a.current})($__dart_deferred_initializers__);