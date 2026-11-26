((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,A={
iNk(d,e,f){var x,w,v,u,t
if(f<=C.d.gaf(e))return C.d.gaf(d)
if(f>=C.d.gb3(e))return C.d.gb3(d)
x=C.d.AC(e,new A.hNZ(f))
w=d[x]
v=x+1
u=d[v]
t=e[x]
t=B.H(w,u,(f-t)/(e[v]-t))
t.toString
return t},
iqb(d,e,f,g,h){var x,w,v=D.bM7(null,null,y.b)
v.F(0,e)
v.F(0,g)
x=B.aH(v,v.$ti.c)
x.$flags=1
w=x
x=B.aA(w).k("aV<1,e>")
x=B.aH(new B.aV(w,new A.hLo(d,e,f,g,h),x),x.k("bQ.E"))
x.$flags=1
return new A.enE(x,w)},
iBs(d,e,f){var x,w,v,u,t
if(d==e)return d
if(d==null)return e.aa(f)
if(e==null)return d.aa(1-f)
x=A.iqb(d.a,d.zm(),e.a,e.zm(),f)
w=B.Db(d.d,e.d,f)
w.toString
v=B.Db(d.e,e.e,f)
v.toString
u=f<0.5
t=u?d.f:e.f
u=u?d.c:e.c
return new A.dp(w,v,t,x.a,x.b,u)},
enE:function enE(d,e){this.a=d
this.b=e},
hNZ:function hNZ(d){this.a=d},
hLo:function hLo(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
Bo:function Bo(){},
dp:function dp(d,e,f,g,h,i){var _=this
_.d=d
_.e=e
_.f=f
_.a=g
_.b=h
_.c=i},
dqU:function dqU(d){this.a=d}},D
J=c[1]
B=c[0]
C=c[2]
A=a.updateHolder(c[241],A)
D=c[283]
A.enE.prototype={}
A.Bo.prototype={
zm(){var x,w,v,u=this.b
if(u!=null)return u
u=this.a.length
x=1/(u-1)
w=J.Nv(u,y.b)
for(v=0;v<u;++v)w[v]=v*x
return w},
iy(d,e){if(d==null)return this.aa(e)
return null},
iz(d,e){if(d==null)return this.aa(1-e)
return null},
aeT(d,e){var x=this.c
if(x==null)x=null
else x=x.ap3(d,e).a
return x}}
A.dp.prototype={
y4(d,e){var x=this
return B.nQ(x.d.N(e).DW(d),x.e.N(e).DW(d),x.a,x.zm(),x.f,x.aeT(d,e))},
fp(d){return this.y4(d,null)},
aa(d){var x=this,w=x.a,v=B.aA(w).k("aV<1,e>")
w=B.aH(new B.aV(w,new A.dqU(d),v),v.k("bQ.E"))
return new A.dp(x.d,x.e,x.f,w,x.b,x.c)},
a34(d){var x=this
return new A.dp(x.d,x.e,x.f,B.dO(x.a.length,d,!1,y.o),x.b,x.c)},
iy(d,e){if(y.m.b(d))return A.iBs(d,this,e)
return this.a7k(d,e)},
iz(d,e){if(y.m.b(d))return A.iBs(this,d,e)
return this.a7l(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bR(e)!==B.aF(x))return!1
return e instanceof A.dp&&e.d.i(0,x.d)&&e.e.i(0,x.e)&&e.f===x.f&&J.A(e.c,x.c)&&B.bY(e.a,x.a)&&B.bY(e.b,x.b)},
ga3(d){var x=this,w=B.cA(x.a),v=x.b
v=v==null?null:B.cA(v)
return B.aN(x.d,x.e,x.f,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
C(d){var x=this,w=B.a(["begin: "+x.d.C(0),"end: "+x.e.C(0),"colors: "+B.al(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+B.al(v))
w.push("tileMode: "+x.f.C(0))
v=x.c
if(v!=null)w.push("transform: "+v.C(0))
return"LinearGradient("+C.d.aM(w,", ")+")"}}
var z=a.updateTypes([])
A.hNZ.prototype={
$1(d){return d<=this.a},
$S:50}
A.hLo.prototype={
$1(d){var x=this,w=B.H(A.iNk(x.a,x.b,d),A.iNk(x.c,x.d,d),x.e)
w.toString
return w},
$S:160}
A.dqU.prototype={
$1(d){var x=B.H(null,d,this.a)
x.toString
return x},
$S:33};(function aliases(){var x=A.Bo.prototype
x.a7k=x.iy
x.a7l=x.iz})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.Y,[A.enE,A.Bo])
x(B.ce,[A.hNZ,A.hLo,A.dqU])
w(A.dp,A.Bo)})()
B.bM(b.typeUniverse,JSON.parse('{"dp":{"Bo":[]}}'))
var y={o:B.E("e"),h:B.E("o<n>"),b:B.E("q"),m:B.E("dp?")}};
(a=>{a["X8K3V5is2HITqvoEq8HffFN8edg="]=a.current})($__dart_deferred_initializers__);