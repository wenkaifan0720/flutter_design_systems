((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,C,E,B={
iAl(d,e,f){var x,w,v,u,t,s
if(d==e)return d
if(d==null)return e.a8(f)
if(e==null)return d.a8(1-f)
x=D.im3(d.a,d.z2(),e.a,e.z2(),f)
w=A.CL(d.d,e.d,f)
w.toString
v=A.bp(d.e,e.e,f)
v.toString
v=Math.max(0,v)
u=A.bp(d.f,e.f,f)
u.toString
u=Math.max(0,u)
t=f<0.5
s=t?d.r:e.r
t=t?d.c:e.c
return new B.EV(w,v,u,s,x.a,x.b,t)},
aMA:function aMA(d){this.a=d},
EV:function EV(d,e,f,g,h,i,j){var _=this
_.d=d
_.e=e
_.f=f
_.r=g
_.a=h
_.b=i
_.c=j},
dQw:function dQw(d){this.a=d}},D
J=c[1]
A=c[0]
C=c[2]
E=c[82]
B=a.updateHolder(c[70],B)
D=c[225]
B.aMA.prototype={
anV(d,e){var x=this.a,w=Math.sin(x),v=1-Math.cos(x),u=d.gbW(),t=u.b,s=u.a,r=A.kJ()
r.io(w*t+v*s,-w*s+v*t,0,1)
r.a4j(x)
return r},
i(d,e){if(e==null)return!1
if(this===e)return!0
if(J.bP(e)!==A.aG(this))return!1
return e instanceof B.aMA&&e.a===this.a},
ga2(d){return C.i.ga2(this.a)},
A(d){return"GradientRotation(radians: "+A.qr(this.a)+")"}}
B.EV.prototype={
xJ(d,e){var x=this,w=x.d.M(e).Dx(d),v=x.a,u=x.z2(),t=x.adG(d,e)
$.J()
t=t!=null?A.KN(t):null
t=new A.bnz(w,v,u,x.r,x.e,x.f,t)
t.V2()
if(v.length!==u.length)A.N(A.fQ('"colors" and "colorStops" arguments must have equal length.',null))
return t},
fp(d){return this.xJ(d,null)},
a8(d){var x=this,w=x.a,v=A.aE(w).j("aU<1,f>")
w=A.aI(new A.aU(w,new B.dQw(d),v),v.j("bR.E"))
return new B.EV(x.d,x.e,x.f,x.r,w,x.b,x.c)},
a24(d){var x=this
return new B.EV(x.d,x.e,x.f,x.r,A.dI(x.a.length,d,!1,y.o),x.b,x.c)},
it(d,e){if(y.j.b(d))return B.iAl(d,this,e)
return this.a6c(d,e)},
iu(d,e){if(y.j.b(d))return B.iAl(this,d,e)
return this.a6d(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bP(e)!==A.aG(x))return!1
return e instanceof B.EV&&e.d.i(0,x.d)&&e.e===x.e&&e.f===x.f&&e.r===x.r&&J.z(e.c,x.c)&&A.bZ(e.a,x.a)&&A.bZ(e.b,x.b)},
ga2(d){var x=this,w=A.cA(x.a),v=x.b
v=v==null?null:A.cA(v)
return A.aO(x.d,x.e,x.f,x.r,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
A(d){var x=this,w=A.a(["center: "+x.d.A(0),"startAngle: "+A.qr(x.e),"endAngle: "+A.qr(x.f),"colors: "+A.an(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+A.an(v))
w.push("tileMode: "+x.r.A(0))
v=x.c
if(v!=null)w.push("transform: "+v.A(0))
return"SweepGradient("+C.c.aM(w,", ")+")"}}
var z=a.updateTypes([])
B.dQw.prototype={
$1(d){var x=A.E(null,d,this.a)
x.toString
return x},
$S:48};(function inheritance(){var x=a.inherit
x(B.aMA,E.byX)
x(B.EV,D.AW)
x(B.dQw,A.cm)})()
A.bN(b.typeUniverse,JSON.parse('{"EV":{"AW":[]}}'))
var y={o:A.F("f"),h:A.F("o<m>"),j:A.F("EV?")}};
(a=>{a["8Vks6WUJ/ggcGj3ToP89j2IDhZg="]=a.current})($__dart_deferred_initializers__);