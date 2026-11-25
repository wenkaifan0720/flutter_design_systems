((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,A={
iM3(d,e,f){var x,w,v,u,t
if(f<=C.c.gaf(e))return C.c.gaf(d)
if(f>=C.c.gb5(e))return C.c.gb5(d)
x=C.c.AF(e,new A.hN0(f))
w=d[x]
v=x+1
u=d[v]
t=e[x]
t=B.E(w,u,(f-t)/(e[v]-t))
t.toString
return t},
ipb(d,e,f,g,h){var x,w,v=D.bLv(null,null,y.b)
v.F(0,e)
v.F(0,g)
x=B.aH(v,v.$ti.c)
x.$flags=1
w=x
x=B.aA(w).k("aV<1,f>")
x=B.aH(new B.aV(w,new A.hKo(d,e,f,g,h),x),x.k("bR.E"))
x.$flags=1
return new A.emB(x,w)},
iAg(d,e,f){var x,w,v,u,t
if(d==e)return d
if(d==null)return e.ab(f)
if(e==null)return d.ab(1-f)
x=A.ipb(d.a,d.zr(),e.a,e.zr(),f)
w=B.CS(d.d,e.d,f)
w.toString
v=B.CS(d.e,e.e,f)
v.toString
u=f<0.5
t=u?d.f:e.f
u=u?d.c:e.c
return new A.dn(w,v,t,x.a,x.b,u)},
emB:function emB(d,e){this.a=d
this.b=e},
hN0:function hN0(d){this.a=d},
hKo:function hKo(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
B5:function B5(){},
dn:function dn(d,e,f,g,h,i){var _=this
_.d=d
_.e=e
_.f=f
_.a=g
_.b=h
_.c=i},
dq9:function dq9(d){this.a=d}},D
J=c[1]
B=c[0]
C=c[2]
A=a.updateHolder(c[234],A)
D=c[274]
A.emB.prototype={}
A.B5.prototype={
zr(){var x,w,v,u=this.b
if(u!=null)return u
u=this.a.length
x=1/(u-1)
w=J.Nb(u,y.b)
for(v=0;v<u;++v)w[v]=v*x
return w},
iz(d,e){if(d==null)return this.ab(e)
return null},
iA(d,e){if(d==null)return this.ab(1-e)
return null},
aeQ(d,e){var x=this.c
if(x==null)x=null
else x=x.aoR(d,e).a
return x}}
A.dn.prototype={
y6(d,e){var x=this
return B.nK(x.d.N(e).DX(d),x.e.N(e).DX(d),x.a,x.zr(),x.f,x.aeQ(d,e))},
fs(d){return this.y6(d,null)},
ab(d){var x=this,w=x.a,v=B.aA(w).k("aV<1,f>")
w=B.aH(new B.aV(w,new A.dq9(d),v),v.k("bR.E"))
return new A.dn(x.d,x.e,x.f,w,x.b,x.c)},
a33(d){var x=this
return new A.dn(x.d,x.e,x.f,B.dM(x.a.length,d,!1,y.o),x.b,x.c)},
iz(d,e){if(y.m.b(d))return A.iAg(d,this,e)
return this.a7k(d,e)},
iA(d,e){if(y.m.b(d))return A.iAg(this,d,e)
return this.a7l(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bS(e)!==B.aF(x))return!1
return e instanceof A.dn&&e.d.i(0,x.d)&&e.e.i(0,x.e)&&e.f===x.f&&J.y(e.c,x.c)&&B.c_(e.a,x.a)&&B.c_(e.b,x.b)},
ga3(d){var x=this,w=B.cE(x.a),v=x.b
v=v==null?null:B.cE(v)
return B.aN(x.d,x.e,x.f,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
B(d){var x=this,w=B.a(["begin: "+x.d.B(0),"end: "+x.e.B(0),"colors: "+B.an(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+B.an(v))
w.push("tileMode: "+x.f.B(0))
v=x.c
if(v!=null)w.push("transform: "+v.B(0))
return"LinearGradient("+C.c.aK(w,", ")+")"}}
var z=a.updateTypes([])
A.hN0.prototype={
$1(d){return d<=this.a},
$S:49}
A.hKo.prototype={
$1(d){var x=this,w=B.E(A.iM3(x.a,x.b,d),A.iM3(x.c,x.d,d),x.e)
w.toString
return w},
$S:180}
A.dq9.prototype={
$1(d){var x=B.E(null,d,this.a)
x.toString
return x},
$S:34};(function aliases(){var x=A.B5.prototype
x.a7k=x.iz
x.a7l=x.iA})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.Y,[A.emB,A.B5])
x(B.cf,[A.hN0,A.hKo,A.dq9])
w(A.dn,A.B5)})()
B.bN(b.typeUniverse,JSON.parse('{"dn":{"B5":[]}}'))
var y={o:B.G("f"),h:B.G("o<n>"),b:B.G("q"),m:B.G("dn?")}};
(a=>{a["2xFB/X6quB3jH/UeAvb87sWvUJg="]=a.current})($__dart_deferred_initializers__);