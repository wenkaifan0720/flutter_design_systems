((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,A={
iHv(d,e,f){var x,w,v,u,t
if(f<=C.c.gaf(e))return C.c.gaf(d)
if(f>=C.c.gb4(e))return C.c.gb4(d)
x=C.c.Af(e,new A.hJ1(f))
w=d[x]
v=x+1
u=d[v]
t=e[x]
t=B.E(w,u,(f-t)/(e[v]-t))
t.toString
return t},
ikU(d,e,f,g,h){var x,w,v=D.bKC(null,null,y.b)
v.E(0,e)
v.E(0,g)
x=B.aI(v,v.$ti.c)
x.$flags=1
w=x
x=B.aE(w).j("aU<1,f>")
x=B.aI(new B.aU(w,new A.hGH(d,e,f,g,h),x),x.j("bQ.E"))
x.$flags=1
return new A.ekg(x,w)},
ivU(d,e,f){var x,w,v,u,t
if(d==e)return d
if(d==null)return e.a9(f)
if(e==null)return d.a9(1-f)
x=A.ikU(d.a,d.z1(),e.a,e.z1(),f)
w=B.CJ(d.d,e.d,f)
w.toString
v=B.CJ(d.e,e.e,f)
v.toString
u=f<0.5
t=u?d.f:e.f
u=u?d.c:e.c
return new A.dq(w,v,t,x.a,x.b,u)},
ekg:function ekg(d,e){this.a=d
this.b=e},
hJ1:function hJ1(d){this.a=d},
hGH:function hGH(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
AZ:function AZ(){},
dq:function dq(d,e,f,g,h,i){var _=this
_.d=d
_.e=e
_.f=f
_.a=g
_.b=h
_.c=i},
dpj:function dpj(d){this.a=d}},D
J=c[1]
B=c[0]
C=c[2]
A=a.updateHolder(c[225],A)
D=c[264]
A.ekg.prototype={}
A.AZ.prototype={
z1(){var x,w,v,u=this.b
if(u!=null)return u
u=this.a.length
x=1/(u-1)
w=J.MP(u,y.b)
for(v=0;v<u;++v)w[v]=v*x
return w},
iq(d,e){if(d==null)return this.a9(e)
return null},
ir(d,e){if(d==null)return this.a9(1-e)
return null},
adC(d,e){var x=this.c
if(x==null)x=null
else x=x.anS(d,e).a
return x}}
A.dq.prototype={
xH(d,e){var x=this
return B.nG(x.d.M(e).Du(d),x.e.M(e).Du(d),x.a,x.z1(),x.f,x.adC(d,e))},
fn(d){return this.xH(d,null)},
a9(d){var x=this,w=x.a,v=B.aE(w).j("aU<1,f>")
w=B.aI(new B.aU(w,new A.dpj(d),v),v.j("bQ.E"))
return new A.dq(x.d,x.e,x.f,w,x.b,x.c)},
a20(d){var x=this
return new A.dq(x.d,x.e,x.f,B.dH(x.a.length,d,!1,y.o),x.b,x.c)},
iq(d,e){if(y.m.b(d))return A.ivU(d,this,e)
return this.a68(d,e)},
ir(d,e){if(y.m.b(d))return A.ivU(this,d,e)
return this.a69(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bO(e)!==B.aG(x))return!1
return e instanceof A.dq&&e.d.i(0,x.d)&&e.e.i(0,x.e)&&e.f===x.f&&J.z(e.c,x.c)&&B.bZ(e.a,x.a)&&B.bZ(e.b,x.b)},
ga2(d){var x=this,w=B.cz(x.a),v=x.b
v=v==null?null:B.cz(v)
return B.aO(x.d,x.e,x.f,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
A(d){var x=this,w=B.a(["begin: "+x.d.A(0),"end: "+x.e.A(0),"colors: "+B.am(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+B.am(v))
w.push("tileMode: "+x.f.A(0))
v=x.c
if(v!=null)w.push("transform: "+v.A(0))
return"LinearGradient("+C.c.aL(w,", ")+")"}}
var z=a.updateTypes([])
A.hJ1.prototype={
$1(d){return d<=this.a},
$S:50}
A.hGH.prototype={
$1(d){var x=this,w=B.E(A.iHv(x.a,x.b,d),A.iHv(x.c,x.d,d),x.e)
w.toString
return w},
$S:221}
A.dpj.prototype={
$1(d){var x=B.E(null,d,this.a)
x.toString
return x},
$S:48};(function aliases(){var x=A.AZ.prototype
x.a68=x.iq
x.a69=x.ir})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.W,[A.ekg,A.AZ])
x(B.cl,[A.hJ1,A.hGH,A.dpj])
w(A.dq,A.AZ)})()
B.bM(b.typeUniverse,JSON.parse('{"dq":{"AZ":[]}}'))
var y={o:B.F("f"),h:B.F("o<m>"),b:B.F("p"),m:B.F("dq?")}};
(a=>{a["QdjteQYzdOvEyKXrSF0qJHyCwXg="]=a.current})($__dart_deferred_initializers__);