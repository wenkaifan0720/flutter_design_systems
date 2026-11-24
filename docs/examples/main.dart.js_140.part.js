((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,A={
iIN(d,e,f){var x,w,v,u,t
if(f<=C.c.gaf(e))return C.c.gaf(d)
if(f>=C.c.gb4(e))return C.c.gb4(d)
x=C.c.Ah(e,new A.hKb(f))
w=d[x]
v=x+1
u=d[v]
t=e[x]
t=B.E(w,u,(f-t)/(e[v]-t))
t.toString
return t},
im3(d,e,f,g,h){var x,w,v=D.bKW(null,null,y.b)
v.E(0,e)
v.E(0,g)
x=B.aI(v,v.$ti.c)
x.$flags=1
w=x
x=B.aE(w).j("aU<1,f>")
x=B.aI(new B.aU(w,new A.hHK(d,e,f,g,h),x),x.j("bR.E"))
x.$flags=1
return new A.ela(x,w)},
ix_(d,e,f){var x,w,v,u,t
if(d==e)return d
if(d==null)return e.a8(f)
if(e==null)return d.a8(1-f)
x=A.im3(d.a,d.z2(),e.a,e.z2(),f)
w=B.CL(d.d,e.d,f)
w.toString
v=B.CL(d.e,e.e,f)
v.toString
u=f<0.5
t=u?d.f:e.f
u=u?d.c:e.c
return new A.dm(w,v,t,x.a,x.b,u)},
ela:function ela(d,e){this.a=d
this.b=e},
hKb:function hKb(d){this.a=d},
hHK:function hHK(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
AW:function AW(){},
dm:function dm(d,e,f,g,h,i){var _=this
_.d=d
_.e=e
_.f=f
_.a=g
_.b=h
_.c=i},
dp_:function dp_(d){this.a=d}},D
J=c[1]
B=c[0]
C=c[2]
A=a.updateHolder(c[225],A)
D=c[264]
A.ela.prototype={}
A.AW.prototype={
z2(){var x,w,v,u=this.b
if(u!=null)return u
u=this.a.length
x=1/(u-1)
w=J.MS(u,y.b)
for(v=0;v<u;++v)w[v]=v*x
return w},
it(d,e){if(d==null)return this.a8(e)
return null},
iu(d,e){if(d==null)return this.a8(1-e)
return null},
adG(d,e){var x=this.c
if(x==null)x=null
else x=x.anV(d,e).a
return x}}
A.dm.prototype={
xJ(d,e){var x=this
return B.nG(x.d.M(e).Dx(d),x.e.M(e).Dx(d),x.a,x.z2(),x.f,x.adG(d,e))},
fp(d){return this.xJ(d,null)},
a8(d){var x=this,w=x.a,v=B.aE(w).j("aU<1,f>")
w=B.aI(new B.aU(w,new A.dp_(d),v),v.j("bR.E"))
return new A.dm(x.d,x.e,x.f,w,x.b,x.c)},
a24(d){var x=this
return new A.dm(x.d,x.e,x.f,B.dI(x.a.length,d,!1,y.o),x.b,x.c)},
it(d,e){if(y.m.b(d))return A.ix_(d,this,e)
return this.a6c(d,e)},
iu(d,e){if(y.m.b(d))return A.ix_(this,d,e)
return this.a6d(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bP(e)!==B.aG(x))return!1
return e instanceof A.dm&&e.d.i(0,x.d)&&e.e.i(0,x.e)&&e.f===x.f&&J.z(e.c,x.c)&&B.bZ(e.a,x.a)&&B.bZ(e.b,x.b)},
ga2(d){var x=this,w=B.cA(x.a),v=x.b
v=v==null?null:B.cA(v)
return B.aO(x.d,x.e,x.f,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
A(d){var x=this,w=B.a(["begin: "+x.d.A(0),"end: "+x.e.A(0),"colors: "+B.an(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+B.an(v))
w.push("tileMode: "+x.f.A(0))
v=x.c
if(v!=null)w.push("transform: "+v.A(0))
return"LinearGradient("+C.c.aM(w,", ")+")"}}
var z=a.updateTypes([])
A.hKb.prototype={
$1(d){return d<=this.a},
$S:49}
A.hHK.prototype={
$1(d){var x=this,w=B.E(A.iIN(x.a,x.b,d),A.iIN(x.c,x.d,d),x.e)
w.toString
return w},
$S:229}
A.dp_.prototype={
$1(d){var x=B.E(null,d,this.a)
x.toString
return x},
$S:48};(function aliases(){var x=A.AW.prototype
x.a6c=x.it
x.a6d=x.iu})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.X,[A.ela,A.AW])
x(B.cm,[A.hKb,A.hHK,A.dp_])
w(A.dm,A.AW)})()
B.bN(b.typeUniverse,JSON.parse('{"dm":{"AW":[]}}'))
var y={o:B.F("f"),h:B.F("o<m>"),b:B.F("p"),m:B.F("dm?")}};
(a=>{a["pvoMwieB7ZJiXzBWmP2mBTGnBzU="]=a.current})($__dart_deferred_initializers__);