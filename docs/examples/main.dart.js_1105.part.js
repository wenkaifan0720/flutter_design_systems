((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,C,E,B={
iz4(d,e,f){var x,w,v,u,t,s
if(d==e)return d
if(d==null)return e.a9(f)
if(e==null)return d.a9(1-f)
x=D.ikU(d.a,d.z1(),e.a,e.z1(),f)
w=A.CJ(d.d,e.d,f)
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
return new B.EQ(w,v,u,s,x.a,x.b,t)},
aMC:function aMC(d){this.a=d},
EQ:function EQ(d,e,f,g,h,i,j){var _=this
_.d=d
_.e=e
_.f=f
_.r=g
_.a=h
_.b=i
_.c=j},
dPE:function dPE(d){this.a=d}},D
J=c[1]
A=c[0]
C=c[2]
E=c[82]
B=a.updateHolder(c[70],B)
D=c[225]
B.aMC.prototype={
anS(d,e){var x=this.a,w=Math.sin(x),v=1-Math.cos(x),u=d.gbW(),t=u.b,s=u.a,r=A.kL()
r.ij(w*t+v*s,-w*s+v*t,0,1)
r.a4f(x)
return r},
i(d,e){if(e==null)return!1
if(this===e)return!0
if(J.bO(e)!==A.aG(this))return!1
return e instanceof B.aMC&&e.a===this.a},
ga2(d){return C.i.ga2(this.a)},
A(d){return"GradientRotation(radians: "+A.qq(this.a)+")"}}
B.EQ.prototype={
xH(d,e){var x=this,w=x.d.M(e).Du(d),v=x.a,u=x.z1(),t=x.adC(d,e)
$.J()
t=t!=null?A.KG(t):null
t=new A.bnm(w,v,u,x.r,x.e,x.f,t)
t.V0()
if(v.length!==u.length)A.N(A.fR('"colors" and "colorStops" arguments must have equal length.',null))
return t},
fn(d){return this.xH(d,null)},
a9(d){var x=this,w=x.a,v=A.aE(w).j("aU<1,f>")
w=A.aI(new A.aU(w,new B.dPE(d),v),v.j("bQ.E"))
return new B.EQ(x.d,x.e,x.f,x.r,w,x.b,x.c)},
a20(d){var x=this
return new B.EQ(x.d,x.e,x.f,x.r,A.dH(x.a.length,d,!1,y.o),x.b,x.c)},
iq(d,e){if(y.j.b(d))return B.iz4(d,this,e)
return this.a68(d,e)},
ir(d,e){if(y.j.b(d))return B.iz4(this,d,e)
return this.a69(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bO(e)!==A.aG(x))return!1
return e instanceof B.EQ&&e.d.i(0,x.d)&&e.e===x.e&&e.f===x.f&&e.r===x.r&&J.z(e.c,x.c)&&A.bZ(e.a,x.a)&&A.bZ(e.b,x.b)},
ga2(d){var x=this,w=A.cz(x.a),v=x.b
v=v==null?null:A.cz(v)
return A.aO(x.d,x.e,x.f,x.r,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
A(d){var x=this,w=A.a(["center: "+x.d.A(0),"startAngle: "+A.qq(x.e),"endAngle: "+A.qq(x.f),"colors: "+A.am(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+A.am(v))
w.push("tileMode: "+x.r.A(0))
v=x.c
if(v!=null)w.push("transform: "+v.A(0))
return"SweepGradient("+C.c.aL(w,", ")+")"}}
var z=a.updateTypes([])
B.dPE.prototype={
$1(d){var x=A.E(null,d,this.a)
x.toString
return x},
$S:48};(function inheritance(){var x=a.inherit
x(B.aMC,E.byX)
x(B.EQ,D.AZ)
x(B.dPE,A.cl)})()
A.bM(b.typeUniverse,JSON.parse('{"EQ":{"AZ":[]}}'))
var y={o:A.F("f"),h:A.F("o<m>"),j:A.F("EQ?")}};
(a=>{a["Y34LBIjnwH+B+X/CRGPlY6iTmqY="]=a.current})($__dart_deferred_initializers__);