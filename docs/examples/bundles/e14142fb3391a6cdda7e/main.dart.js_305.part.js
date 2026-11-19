((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,D,A={
hQZ(d,e,f){var x,w,v,u,t
if(f<=C.c.gag(e))return C.c.gag(d)
if(f>=C.c.gb0(e))return C.c.gb0(d)
x=C.c.FG(e,new A.fXE(f))
w=d[x]
v=x+1
u=d[v]
t=e[x]
t=B.F(w,u,(f-t)/(e[v]-t))
t.toString
return t},
hwe(d,e,f,g,h){var x,w,v=D.bxf(null,null,y.b)
v.G(0,e)
v.G(0,g)
x=B.aJ(v,v.$ti.c)
x.$flags=1
w=x
x=B.aB(w).j("aR<1,e>")
x=B.aJ(new B.aR(w,new A.fW0(d,e,f,g,h),x),x.j("bq.E"))
x.$flags=1
return new A.dVe(x,w)},
hGr(d,e,f){var x,w,v,u,t
if(d==e)return d
if(d==null)return e.ah(f)
if(e==null)return d.ah(1-f)
x=A.hwe(d.a,d.y6(),e.a,e.y6(),f)
w=B.B2(d.d,e.d,f)
w.toString
v=B.B2(d.e,e.e,f)
v.toString
u=f<0.5
t=u?d.f:e.f
u=u?d.c:e.c
return new A.dw(w,v,t,x.a,x.b,u)},
dVe:function dVe(d,e){this.a=d
this.b=e},
fXE:function fXE(d){this.a=d},
fW0:function fW0(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
zm:function zm(){},
dw:function dw(d,e,f,g,h,i){var _=this
_.d=d
_.e=e
_.f=f
_.a=g
_.b=h
_.c=i},
d30:function d30(d){this.a=d}}
J=c[1]
B=c[0]
C=c[2]
D=c[238]
A=a.updateHolder(c[203],A)
A.dVe.prototype={}
A.zm.prototype={
y6(){var x,w,v,u=this.b
if(u!=null)return u
u=this.a.length
x=1/(u-1)
w=J.Kj(u,y.b)
for(v=0;v<u;++v)w[v]=v*x
return w},
hY(d,e){if(d==null)return this.ah(e)
return null},
hZ(d,e){if(d==null)return this.ah(1-e)
return null},
abu(d,e){var x=this.c
if(x==null)x=null
else x=x.al2(d,e).a
return x}}
A.dw.prototype={
wG(d,e){var x=this
return B.oF(x.d.J(e).Cz(d),x.e.J(e).Cz(d),x.a,x.y6(),x.f,x.abu(d,e))},
fH(d){return this.wG(d,null)},
ah(d){var x=this,w=x.a,v=B.aB(w).j("aR<1,e>")
w=B.aJ(new B.aR(w,new A.d30(d),v),v.j("bq.E"))
return new A.dw(x.d,x.e,x.f,w,x.b,x.c)},
a0g(d){var x=this
return new A.dw(x.d,x.e,x.f,B.ds(x.a.length,d,!1,y.o),x.b,x.c)},
hY(d,e){if(y.m.b(d))return A.hGr(d,this,e)
return this.a4x(d,e)},
hZ(d,e){if(y.m.b(d))return A.hGr(this,d,e)
return this.a4y(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bz(e)!==B.ar(x))return!1
return e instanceof A.dw&&e.d.i(0,x.d)&&e.e.i(0,x.e)&&e.f===x.f&&J.x(e.c,x.c)&&B.c7(e.a,x.a)&&B.c7(e.b,x.b)},
gY(d){var x=this,w=B.cs(x.a),v=x.b
v=v==null?null:B.cs(v)
return B.aA(x.d,x.e,x.f,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
v(d){var x=this,w=B.a(["begin: "+x.d.v(0),"end: "+x.e.v(0),"colors: "+B.ae(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+B.ae(v))
w.push("tileMode: "+x.f.v(0))
v=x.c
if(v!=null)w.push("transform: "+v.v(0))
return"LinearGradient("+C.c.aZ(w,", ")+")"}}
var z=a.updateTypes([])
A.fXE.prototype={
$1(d){return d<=this.a},
$S:49}
A.fW0.prototype={
$1(d){var x=this,w=B.F(A.hQZ(x.a,x.b,d),A.hQZ(x.c,x.d,d),x.e)
w.toString
return w},
$S:208}
A.d30.prototype={
$1(d){var x=B.F(null,d,this.a)
x.toString
return x},
$S:47};(function aliases(){var x=A.zm.prototype
x.a4x=x.hY
x.a4y=x.hZ})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.Q,[A.dVe,A.zm])
x(B.ck,[A.fXE,A.fW0,A.d30])
w(A.dw,A.zm)})()
B.bE(b.typeUniverse,JSON.parse('{"dw":{"zm":[]}}'))
var y={o:B.C("e"),h:B.C("m<p>"),b:B.C("o"),m:B.C("dw?")}};
(a=>{a["3sb8w7mkbGdP7IIt4+xMsdelw0w="]=a.current})($__dart_deferred_initializers__);