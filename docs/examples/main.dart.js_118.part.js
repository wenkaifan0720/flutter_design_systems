((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,A={
hlw(d,e,f){var x,w,v,u,t
if(f<=C.c.gac(e))return C.c.gac(d)
if(f>=C.c.gaV(e))return C.c.gaV(d)
x=C.c.yr(e,new A.fwe(f))
w=d[x]
v=x+1
u=d[v]
t=e[x]
t=B.E(w,u,(f-t)/(e[v]-t))
t.toString
return t},
h1V(d,e,f,g,h){var x,w,v=D.bne(null,null,y.b)
v.E(0,e)
v.E(0,g)
x=B.aC(v,v.$ti.c)
x.$flags=1
w=x
x=B.aw(w).j("aN<1,e>")
x=B.aC(new B.aN(w,new A.fuq(d,e,f,g,h),x),x.j("bM.E"))
x.$flags=1
return new A.dAh(x,w)},
hbh(d,e,f){var x,w,v,u,t
if(d==e)return d
if(d==null)return e.aa(f)
if(e==null)return d.aa(1-f)
x=A.h1V(d.a,d.ve(),e.a,e.ve(),f)
w=B.zJ(d.d,e.d,f)
w.toString
v=B.zJ(d.e,e.e,f)
v.toString
u=f<0.5
t=u?d.f:e.f
u=u?d.c:e.c
return new A.dd(w,v,t,x.a,x.b,u)},
dAh:function dAh(d,e){this.a=d
this.b=e},
fwe:function fwe(d){this.a=d},
fuq:function fuq(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
ye:function ye(){},
dd:function dd(d,e,f,g,h,i){var _=this
_.d=d
_.e=e
_.f=f
_.a=g
_.b=h
_.c=i},
cML:function cML(d){this.a=d}},D
J=c[1]
B=c[0]
C=c[2]
A=a.updateHolder(c[169],A)
D=c[209]
A.dAh.prototype={}
A.ye.prototype={
ve(){var x,w,v,u=this.b
if(u!=null)return u
u=this.a.length
x=1/(u-1)
w=J.bdb(u,y.b)
for(v=0;v<u;++v)w[v]=v*x
return w},
ft(d,e){if(d==null)return this.aa(e)
return null},
fu(d,e){if(d==null)return this.aa(1-e)
return null},
a2s(d,e){var x=this.c
if(x==null)x=null
else x=x.abk(d,e).a
return x}}
A.dd.prototype={
u0(d,e){var x=this
return B.n_(x.d.L(e).M8(d),x.e.L(e).M8(d),x.a,x.ve(),x.f,x.a2s(d,e))},
ec(d){return this.u0(d,null)},
aa(d){var x=this,w=x.a,v=B.aw(w).j("aN<1,e>")
w=B.aC(new B.aN(w,new A.cML(d),v),v.j("bM.E"))
return new A.dd(x.d,x.e,x.f,w,x.b,x.c)},
TM(d){var x=this
return new A.dd(x.d,x.e,x.f,B.dx(x.a.length,d,!1,y.o),x.b,x.c)},
ft(d,e){if(y.m.b(d))return A.hbh(d,this,e)
return this.Xf(d,e)},
fu(d,e){if(y.m.b(d))return A.hbh(this,d,e)
return this.Xg(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bH(e)!==B.at(x))return!1
return e instanceof A.dd&&e.d.i(0,x.d)&&e.e.i(0,x.e)&&e.f===x.f&&J.z(e.c,x.c)&&B.bY(e.a,x.a)&&B.bY(e.b,x.b)},
gU(d){var x=this,w=B.ci(x.a),v=x.b
v=v==null?null:B.ci(v)
return B.aF(x.d,x.e,x.f,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
v(d){var x=this,w=B.a(["begin: "+x.d.v(0),"end: "+x.e.v(0),"colors: "+B.a7(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+B.a7(v))
w.push("tileMode: "+x.f.v(0))
v=x.c
if(v!=null)w.push("transform: "+v.v(0))
return"LinearGradient("+C.c.aC(w,", ")+")"}}
var z=a.updateTypes([])
A.fwe.prototype={
$1(d){return d<=this.a},
$S:61}
A.fuq.prototype={
$1(d){var x=this,w=B.E(A.hlw(x.a,x.b,d),A.hlw(x.c,x.d,d),x.e)
w.toString
return w},
$S:210}
A.cML.prototype={
$1(d){var x=B.E(null,d,this.a)
x.toString
return x},
$S:42};(function aliases(){var x=A.ye.prototype
x.Xf=x.ft
x.Xg=x.fu})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.T,[A.dAh,A.ye])
x(B.cq,[A.fwe,A.fuq,A.cML])
w(A.dd,A.ye)})()
B.c_(b.typeUniverse,JSON.parse('{"dd":{"ye":[]}}'))
var y={o:B.G("e"),h:B.G("m<l>"),b:B.G("o"),m:B.G("dd?")}};
(a=>{a["dzaPQhEztLIh5dVa3SVfcOYKi1M="]=a.current})($__dart_deferred_initializers__);