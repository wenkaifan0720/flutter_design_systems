((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,A={
iL6(d,e,f){var x,w,v,u,t
if(f<=C.c.gag(e))return C.c.gag(d)
if(f>=C.c.gb6(e))return C.c.gb6(d)
x=C.c.AA(e,new A.hM2(f))
w=d[x]
v=x+1
u=d[v]
t=e[x]
t=B.E(w,u,(f-t)/(e[v]-t))
t.toString
return t},
ioe(d,e,f,g,h){var x,w,v=D.bLk(null,null,y.b)
v.F(0,e)
v.F(0,g)
x=B.aH(v,v.$ti.c)
x.$flags=1
w=x
x=B.aE(w).k("aV<1,f>")
x=B.aH(new B.aV(w,new A.hJq(d,e,f,g,h),x),x.k("bS.E"))
x.$flags=1
return new A.em3(x,w)},
izi(d,e,f){var x,w,v,u,t
if(d==e)return d
if(d==null)return e.a9(f)
if(e==null)return d.a9(1-f)
x=A.ioe(d.a,d.zm(),e.a,e.zm(),f)
w=B.CO(d.d,e.d,f)
w.toString
v=B.CO(d.e,e.e,f)
v.toString
u=f<0.5
t=u?d.f:e.f
u=u?d.c:e.c
return new A.dn(w,v,t,x.a,x.b,u)},
em3:function em3(d,e){this.a=d
this.b=e},
hM2:function hM2(d){this.a=d},
hJq:function hJq(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
B1:function B1(){},
dn:function dn(d,e,f,g,h,i){var _=this
_.d=d
_.e=e
_.f=f
_.a=g
_.b=h
_.c=i},
dpS:function dpS(d){this.a=d}},D
J=c[1]
B=c[0]
C=c[2]
A=a.updateHolder(c[228],A)
D=c[268]
A.em3.prototype={}
A.B1.prototype={
zm(){var x,w,v,u=this.b
if(u!=null)return u
u=this.a.length
x=1/(u-1)
w=J.N0(u,y.b)
for(v=0;v<u;++v)w[v]=v*x
return w},
iy(d,e){if(d==null)return this.a9(e)
return null},
iz(d,e){if(d==null)return this.a9(1-e)
return null},
aeJ(d,e){var x=this.c
if(x==null)x=null
else x=x.aoK(d,e).a
return x}}
A.dn.prototype={
y0(d,e){var x=this
return B.nJ(x.d.N(e).DV(d),x.e.N(e).DV(d),x.a,x.zm(),x.f,x.aeJ(d,e))},
ft(d){return this.y0(d,null)},
a9(d){var x=this,w=x.a,v=B.aE(w).k("aV<1,f>")
w=B.aH(new B.aV(w,new A.dpS(d),v),v.k("bS.E"))
return new A.dn(x.d,x.e,x.f,w,x.b,x.c)},
a2X(d){var x=this
return new A.dn(x.d,x.e,x.f,B.dK(x.a.length,d,!1,y.o),x.b,x.c)},
iy(d,e){if(y.m.b(d))return A.izi(d,this,e)
return this.a7d(d,e)},
iz(d,e){if(y.m.b(d))return A.izi(this,d,e)
return this.a7e(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bQ(e)!==B.aG(x))return!1
return e instanceof A.dn&&e.d.i(0,x.d)&&e.e.i(0,x.e)&&e.f===x.f&&J.z(e.c,x.c)&&B.c_(e.a,x.a)&&B.c_(e.b,x.b)},
ga3(d){var x=this,w=B.cD(x.a),v=x.b
v=v==null?null:B.cD(v)
return B.aN(x.d,x.e,x.f,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
B(d){var x=this,w=B.a(["begin: "+x.d.B(0),"end: "+x.e.B(0),"colors: "+B.an(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+B.an(v))
w.push("tileMode: "+x.f.B(0))
v=x.c
if(v!=null)w.push("transform: "+v.B(0))
return"LinearGradient("+C.c.aK(w,", ")+")"}}
var z=a.updateTypes([])
A.hM2.prototype={
$1(d){return d<=this.a},
$S:50}
A.hJq.prototype={
$1(d){var x=this,w=B.E(A.iL6(x.a,x.b,d),A.iL6(x.c,x.d,d),x.e)
w.toString
return w},
$S:185}
A.dpS.prototype={
$1(d){var x=B.E(null,d,this.a)
x.toString
return x},
$S:33};(function aliases(){var x=A.B1.prototype
x.a7d=x.iy
x.a7e=x.iz})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.Y,[A.em3,A.B1])
x(B.cl,[A.hM2,A.hJq,A.dpS])
w(A.dn,A.B1)})()
B.bO(b.typeUniverse,JSON.parse('{"dn":{"B1":[]}}'))
var y={o:B.G("f"),h:B.G("o<n>"),b:B.G("q"),m:B.G("dn?")}};
(a=>{a["+C6j/GUiW4KurHBR78BxfCP+5So="]=a.current})($__dart_deferred_initializers__);