((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,A={
iGk(d,e,f){var x,w,v,u,t
if(f<=C.c.gae(e))return C.c.gae(d)
if(f>=C.c.gb6(e))return C.c.gb6(d)
x=C.c.Ae(e,new A.hHH(f))
w=d[x]
v=x+1
u=d[v]
t=e[x]
t=B.F(w,u,(f-t)/(e[v]-t))
t.toString
return t},
ijB(d,e,f,g,h){var x,w,v=D.bJZ(null,null,y.b)
v.E(0,e)
v.E(0,g)
x=B.aI(v,v.$ti.c)
x.$flags=1
w=x
x=B.aD(w).j("aT<1,f>")
x=B.aI(new B.aT(w,new A.hFo(d,e,f,g,h),x),x.j("bL.E"))
x.$flags=1
return new A.ejh(x,w)},
iuK(d,e,f){var x,w,v,u,t
if(d==e)return d
if(d==null)return e.a9(f)
if(e==null)return d.a9(1-f)
x=A.ijB(d.a,d.yZ(),e.a,e.yZ(),f)
w=B.CJ(d.d,e.d,f)
w.toString
v=B.CJ(d.e,e.e,f)
v.toString
u=f<0.5
t=u?d.f:e.f
u=u?d.c:e.c
return new A.dq(w,v,t,x.a,x.b,u)},
ejh:function ejh(d,e){this.a=d
this.b=e},
hHH:function hHH(d){this.a=d},
hFo:function hFo(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
AY:function AY(){},
dq:function dq(d,e,f,g,h,i){var _=this
_.d=d
_.e=e
_.f=f
_.a=g
_.b=h
_.c=i},
dop:function dop(d){this.a=d}},D
J=c[1]
B=c[0]
C=c[2]
A=a.updateHolder(c[222],A)
D=c[264]
A.ejh.prototype={}
A.AY.prototype={
yZ(){var x,w,v,u=this.b
if(u!=null)return u
u=this.a.length
x=1/(u-1)
w=J.N1(u,y.b)
for(v=0;v<u;++v)w[v]=v*x
return w},
il(d,e){if(d==null)return this.a9(e)
return null},
im(d,e){if(d==null)return this.a9(1-e)
return null},
adr(d,e){var x=this.c
if(x==null)x=null
else x=x.anD(d,e).a
return x}}
A.dq.prototype={
xE(d,e){var x=this
return B.nB(x.d.L(e).Dr(d),x.e.L(e).Dr(d),x.a,x.yZ(),x.f,x.adr(d,e))},
fm(d){return this.xE(d,null)},
a9(d){var x=this,w=x.a,v=B.aD(w).j("aT<1,f>")
w=B.aI(new B.aT(w,new A.dop(d),v),v.j("bL.E"))
return new A.dq(x.d,x.e,x.f,w,x.b,x.c)},
a1R(d){var x=this
return new A.dq(x.d,x.e,x.f,B.dF(x.a.length,d,!1,y.o),x.b,x.c)},
il(d,e){if(y.m.b(d))return A.iuK(d,this,e)
return this.a6_(d,e)},
im(d,e){if(y.m.b(d))return A.iuK(this,d,e)
return this.a60(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bP(e)!==B.aF(x))return!1
return e instanceof A.dq&&e.d.i(0,x.d)&&e.e.i(0,x.e)&&e.f===x.f&&J.z(e.c,x.c)&&B.bZ(e.a,x.a)&&B.bZ(e.b,x.b)},
ga2(d){var x=this,w=B.cB(x.a),v=x.b
v=v==null?null:B.cB(v)
return B.aL(x.d,x.e,x.f,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
A(d){var x=this,w=B.a(["begin: "+x.d.A(0),"end: "+x.e.A(0),"colors: "+B.am(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+B.am(v))
w.push("tileMode: "+x.f.A(0))
v=x.c
if(v!=null)w.push("transform: "+v.A(0))
return"LinearGradient("+C.c.aM(w,", ")+")"}}
var z=a.updateTypes([])
A.hHH.prototype={
$1(d){return d<=this.a},
$S:49}
A.hFo.prototype={
$1(d){var x=this,w=B.F(A.iGk(x.a,x.b,d),A.iGk(x.c,x.d,d),x.e)
w.toString
return w},
$S:210}
A.dop.prototype={
$1(d){var x=B.F(null,d,this.a)
x.toString
return x},
$S:51};(function aliases(){var x=A.AY.prototype
x.a6_=x.il
x.a60=x.im})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.W,[A.ejh,A.AY])
x(B.cj,[A.hHH,A.hFo,A.dop])
w(A.dq,A.AY)})()
B.bM(b.typeUniverse,JSON.parse('{"dq":{"AY":[]}}'))
var y={o:B.E("f"),h:B.E("o<m>"),b:B.E("p"),m:B.E("dq?")}};
(a=>{a["vA2UWwW2WjrapQNS2ChHI/F2kLg="]=a.current})($__dart_deferred_initializers__);