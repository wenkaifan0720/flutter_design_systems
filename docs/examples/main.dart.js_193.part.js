((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,A={
iW5(d,e,f){var x,w,v,u,t
if(f<=C.c.gaf(e))return C.c.gaf(d)
if(f>=C.c.gb7(e))return C.c.gb7(d)
x=C.c.AO(e,new A.hVl(f))
w=d[x]
v=x+1
u=d[v]
t=e[x]
t=B.C(w,u,(f-t)/(e[v]-t))
t.toString
return t},
iyf(d,e,f,g,h){var x,w,v=D.bOz(null,null,y.b)
v.F(0,e)
v.F(0,g)
x=B.aG(v,v.$ti.c)
x.$flags=1
w=x
x=B.aC(w).k("aV<1,e>")
x=B.aG(new B.aV(w,new A.hSA(d,e,f,g,h),x),x.k("bS.E"))
x.$flags=1
return new A.et5(x,w)},
iK5(d,e,f){var x,w,v,u,t
if(d==e)return d
if(d==null)return e.a7(f)
if(e==null)return d.a7(1-f)
x=A.iyf(d.a,d.zx(),e.a,e.zx(),f)
w=B.DS(d.d,e.d,f)
w.toString
v=B.DS(d.e,e.e,f)
v.toString
u=f<0.5
t=u?d.f:e.f
u=u?d.c:e.c
return new A.dw(w,v,t,x.a,x.b,u)},
et5:function et5(d,e){this.a=d
this.b=e},
hVl:function hVl(d){this.a=d},
hSA:function hSA(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
C_:function C_(){},
dw:function dw(d,e,f,g,h,i){var _=this
_.d=d
_.e=e
_.f=f
_.a=g
_.b=h
_.c=i},
dv9:function dv9(d){this.a=d}},D
J=c[1]
B=c[0]
C=c[2]
A=a.updateHolder(c[243],A)
D=c[283]
A.et5.prototype={}
A.C_.prototype={
zx(){var x,w,v,u=this.b
if(u!=null)return u
u=this.a.length
x=1/(u-1)
w=J.On(u,y.b)
for(v=0;v<u;++v)w[v]=v*x
return w},
is(d,e){if(d==null)return this.a7(e)
return null},
it(d,e){if(d==null)return this.a7(1-e)
return null},
afL(d,e){var x=this.c
if(x==null)x=null
else x=x.aq4(d,e).a
return x}}
A.dw.prototype={
yd(d,e){var x=this
return B.oc(x.d.M(e).Eb(d),x.e.M(e).Eb(d),x.a,x.zx(),x.f,x.afL(d,e))},
ft(d){return this.yd(d,null)},
a7(d){var x=this,w=x.a,v=B.aC(w).k("aV<1,e>")
w=B.aG(new B.aV(w,new A.dv9(d),v),v.k("bS.E"))
return new A.dw(x.d,x.e,x.f,w,x.b,x.c)},
a3G(d){var x=this
return new A.dw(x.d,x.e,x.f,B.dQ(x.a.length,d,!1,y.o),x.b,x.c)},
is(d,e){if(y.m.b(d))return A.iK5(d,this,e)
return this.a84(d,e)},
it(d,e){if(y.m.b(d))return A.iK5(this,d,e)
return this.a85(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bT(e)!==B.aI(x))return!1
return e instanceof A.dw&&e.d.i(0,x.d)&&e.e.i(0,x.e)&&e.f===x.f&&J.B(e.c,x.c)&&B.bZ(e.a,x.a)&&B.bZ(e.b,x.b)},
ga2(d){var x=this,w=B.cC(x.a),v=x.b
v=v==null?null:B.cC(v)
return B.aP(x.d,x.e,x.f,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
D(d){var x=this,w=B.a(["begin: "+x.d.D(0),"end: "+x.e.D(0),"colors: "+B.am(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+B.am(v))
w.push("tileMode: "+x.f.D(0))
v=x.c
if(v!=null)w.push("transform: "+v.D(0))
return"LinearGradient("+C.c.aM(w,", ")+")"}}
var z=a.updateTypes([])
A.hVl.prototype={
$1(d){return d<=this.a},
$S:51}
A.hSA.prototype={
$1(d){var x=this,w=B.C(A.iW5(x.a,x.b,d),A.iW5(x.c,x.d,d),x.e)
w.toString
return w},
$S:168}
A.dv9.prototype={
$1(d){var x=B.C(null,d,this.a)
x.toString
return x},
$S:32};(function aliases(){var x=A.C_.prototype
x.a84=x.is
x.a85=x.it})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.a_,[A.et5,A.C_])
x(B.cp,[A.hVl,A.hSA,A.dv9])
w(A.dw,A.C_)})()
B.bP(b.typeUniverse,JSON.parse('{"dw":{"C_":[]}}'))
var y={o:B.G("e"),h:B.G("o<n>"),b:B.G("q"),m:B.G("dw?")}};
(a=>{a["pkuhAxD2Oitg6llDr8C3hQsoPsc="]=a.current})($__dart_deferred_initializers__);