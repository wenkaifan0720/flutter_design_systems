((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,A={
i41(d,e,f){var x,w,v,u,t
if(f<=C.c.gae(e))return C.c.gae(d)
if(f>=C.c.gb0(e))return C.c.gb0(d)
x=C.c.Cm(e,new A.h9Y(f))
w=d[x]
v=x+1
u=d[v]
t=e[x]
t=B.G(w,u,(f-t)/(e[v]-t))
t.toString
return t},
hJY(d,e,f,g,h){var x,w,v=D.bzD(null,null,y.b)
v.E(0,e)
v.E(0,g)
x=B.aG(v,v.$ti.c)
x.$flags=1
w=x
x=B.aE(w).j("aS<1,e>")
x=B.aG(new B.aS(w,new A.h81(d,e,f,g,h),x),x.j("bP.E"))
x.$flags=1
return new A.e_8(x,w)},
hUc(d,e,f){var x,w,v,u,t
if(d==e)return d
if(d==null)return e.a8(f)
if(e==null)return d.a8(1-f)
x=A.hJY(d.a,d.yu(),e.a,e.yu(),f)
w=B.BC(d.d,e.d,f)
w.toString
v=B.BC(d.e,e.e,f)
v.toString
u=f<0.5
t=u?d.f:e.f
u=u?d.c:e.c
return new A.ds(w,v,t,x.a,x.b,u)},
e_8:function e_8(d,e){this.a=d
this.b=e},
h9Y:function h9Y(d){this.a=d},
h81:function h81(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
A_:function A_(){},
ds:function ds(d,e,f,g,h,i){var _=this
_.d=d
_.e=e
_.f=f
_.a=g
_.b=h
_.c=i},
d7c:function d7c(d){this.a=d}},D
J=c[1]
B=c[0]
C=c[2]
A=a.updateHolder(c[202],A)
D=c[242]
A.e_8.prototype={}
A.A_.prototype={
yu(){var x,w,v,u=this.b
if(u!=null)return u
u=this.a.length
x=1/(u-1)
w=J.Lq(u,y.b)
for(v=0;v<u;++v)w[v]=v*x
return w},
i3(d,e){if(d==null)return this.a8(e)
return null},
i4(d,e){if(d==null)return this.a8(1-e)
return null},
ac5(d,e){var x=this.c
if(x==null)x=null
else x=x.am_(d,e).a
return x}}
A.ds.prototype={
x3(d,e){var x=this
return B.nV(x.d.K(e).CZ(d),x.e.K(e).CZ(d),x.a,x.yu(),x.f,x.ac5(d,e))},
fH(d){return this.x3(d,null)},
a8(d){var x=this,w=x.a,v=B.aE(w).j("aS<1,e>")
w=B.aG(new B.aS(w,new A.d7c(d),v),v.j("bP.E"))
return new A.ds(x.d,x.e,x.f,w,x.b,x.c)},
a0P(d){var x=this
return new A.ds(x.d,x.e,x.f,B.dt(x.a.length,d,!1,y.o),x.b,x.c)},
i3(d,e){if(y.m.b(d))return A.hUc(d,this,e)
return this.a4Z(d,e)},
i4(d,e){if(y.m.b(d))return A.hUc(this,d,e)
return this.a5_(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bI(e)!==B.az(x))return!1
return e instanceof A.ds&&e.d.i(0,x.d)&&e.e.i(0,x.e)&&e.f===x.f&&J.x(e.c,x.c)&&B.c5(e.a,x.a)&&B.c5(e.b,x.b)},
gY(d){var x=this,w=B.cz(x.a),v=x.b
v=v==null?null:B.cz(v)
return B.aK(x.d,x.e,x.f,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
v(d){var x=this,w=B.a(["begin: "+x.d.v(0),"end: "+x.e.v(0),"colors: "+B.al(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+B.al(v))
w.push("tileMode: "+x.f.v(0))
v=x.c
if(v!=null)w.push("transform: "+v.v(0))
return"LinearGradient("+C.c.aK(w,", ")+")"}}
var z=a.updateTypes([])
A.h9Y.prototype={
$1(d){return d<=this.a},
$S:46}
A.h81.prototype={
$1(d){var x=this,w=B.G(A.i41(x.a,x.b,d),A.i41(x.c,x.d,d),x.e)
w.toString
return w},
$S:202}
A.d7c.prototype={
$1(d){var x=B.G(null,d,this.a)
x.toString
return x},
$S:44};(function aliases(){var x=A.A_.prototype
x.a4Z=x.i3
x.a5_=x.i4})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.V,[A.e_8,A.A_])
x(B.cn,[A.h9Y,A.h81,A.d7c])
w(A.ds,A.A_)})()
B.bN(b.typeUniverse,JSON.parse('{"ds":{"A_":[]}}'))
var y={o:B.D("e"),h:B.D("n<m>"),b:B.D("p"),m:B.D("ds?")}};
(a=>{a["Fqc/kzcXknc9thGId7SBtWxthjE="]=a.current})($__dart_deferred_initializers__);