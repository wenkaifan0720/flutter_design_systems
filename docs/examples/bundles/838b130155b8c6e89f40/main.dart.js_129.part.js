((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,A={
i7E(d,e,f){var x,w,v,u,t
if(f<=C.c.gad(e))return C.c.gad(d)
if(f>=C.c.gb1(e))return C.c.gb1(d)
x=C.c.Co(e,new A.hdr(f))
w=d[x]
v=x+1
u=d[v]
t=e[x]
t=B.G(w,u,(f-t)/(e[v]-t))
t.toString
return t},
hNl(d,e,f,g,h){var x,w,v=D.bAV(null,null,y.b)
v.F(0,e)
v.F(0,g)
x=B.aH(v,v.$ti.c)
x.$flags=1
w=x
x=B.aB(w).j("aR<1,e>")
x=B.aH(new B.aR(w,new A.hbt(d,e,f,g,h),x),x.j("bP.E"))
x.$flags=1
return new A.e0w(x,w)},
hXG(d,e,f){var x,w,v,u,t
if(d==e)return d
if(d==null)return e.a8(f)
if(e==null)return d.a8(1-f)
x=A.hNl(d.a,d.yB(),e.a,e.yB(),f)
w=B.BJ(d.d,e.d,f)
w.toString
v=B.BJ(d.e,e.e,f)
v.toString
u=f<0.5
t=u?d.f:e.f
u=u?d.c:e.c
return new A.dv(w,v,t,x.a,x.b,u)},
e0w:function e0w(d,e){this.a=d
this.b=e},
hdr:function hdr(d){this.a=d},
hbt:function hbt(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
A2:function A2(){},
dv:function dv(d,e,f,g,h,i){var _=this
_.d=d
_.e=e
_.f=f
_.a=g
_.b=h
_.c=i},
d7s:function d7s(d){this.a=d}},D
J=c[1]
B=c[0]
C=c[2]
A=a.updateHolder(c[209],A)
D=c[250]
A.e0w.prototype={}
A.A2.prototype={
yB(){var x,w,v,u=this.b
if(u!=null)return u
u=this.a.length
x=1/(u-1)
w=J.Lx(u,y.b)
for(v=0;v<u;++v)w[v]=v*x
return w},
i4(d,e){if(d==null)return this.a8(e)
return null},
i5(d,e){if(d==null)return this.a8(1-e)
return null},
acs(d,e){var x=this.c
if(x==null)x=null
else x=x.ams(d,e).a
return x}}
A.dv.prototype={
xa(d,e){var x=this
return B.nV(x.d.K(e).D2(d),x.e.K(e).D2(d),x.a,x.yB(),x.f,x.acs(d,e))},
fI(d){return this.xa(d,null)},
a8(d){var x=this,w=x.a,v=B.aB(w).j("aR<1,e>")
w=B.aH(new B.aR(w,new A.d7s(d),v),v.j("bP.E"))
return new A.dv(x.d,x.e,x.f,w,x.b,x.c)},
a0Y(d){var x=this
return new A.dv(x.d,x.e,x.f,B.dz(x.a.length,d,!1,y.o),x.b,x.c)},
i4(d,e){if(y.m.b(d))return A.hXG(d,this,e)
return this.a58(d,e)},
i5(d,e){if(y.m.b(d))return A.hXG(this,d,e)
return this.a59(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bK(e)!==B.az(x))return!1
return e instanceof A.dv&&e.d.i(0,x.d)&&e.e.i(0,x.e)&&e.f===x.f&&J.x(e.c,x.c)&&B.c5(e.a,x.a)&&B.c5(e.b,x.b)},
gY(d){var x=this,w=B.cz(x.a),v=x.b
v=v==null?null:B.cz(v)
return B.aK(x.d,x.e,x.f,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
v(d){var x=this,w=B.a(["begin: "+x.d.v(0),"end: "+x.e.v(0),"colors: "+B.ak(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+B.ak(v))
w.push("tileMode: "+x.f.v(0))
v=x.c
if(v!=null)w.push("transform: "+v.v(0))
return"LinearGradient("+C.c.aL(w,", ")+")"}}
var z=a.updateTypes([])
A.hdr.prototype={
$1(d){return d<=this.a},
$S:46}
A.hbt.prototype={
$1(d){var x=this,w=B.G(A.i7E(x.a,x.b,d),A.i7E(x.c,x.d,d),x.e)
w.toString
return w},
$S:206}
A.d7s.prototype={
$1(d){var x=B.G(null,d,this.a)
x.toString
return x},
$S:44};(function aliases(){var x=A.A2.prototype
x.a58=x.i4
x.a59=x.i5})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.W,[A.e0w,A.A2])
x(B.ck,[A.hdr,A.hbt,A.d7s])
w(A.dv,A.A2)})()
B.bN(b.typeUniverse,JSON.parse('{"dv":{"A2":[]}}'))
var y={o:B.E("e"),h:B.E("n<m>"),b:B.E("p"),m:B.E("dv?")}};
(a=>{a["nSm7xEhfhiOMipCnR+3e+WQSGmA="]=a.current})($__dart_deferred_initializers__);