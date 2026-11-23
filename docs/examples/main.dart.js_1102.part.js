((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,C,E,B={
ixT(d,e,f){var x,w,v,u,t,s
if(d==e)return d
if(d==null)return e.a9(f)
if(e==null)return d.a9(1-f)
x=D.ijB(d.a,d.yZ(),e.a,e.yZ(),f)
w=A.CJ(d.d,e.d,f)
w.toString
v=A.bt(d.e,e.e,f)
v.toString
v=Math.max(0,v)
u=A.bt(d.f,e.f,f)
u.toString
u=Math.max(0,u)
t=f<0.5
s=t?d.r:e.r
t=t?d.c:e.c
return new B.ET(w,v,u,s,x.a,x.b,t)},
aMm:function aMm(d){this.a=d},
ET:function ET(d,e,f,g,h,i,j){var _=this
_.d=d
_.e=e
_.f=f
_.r=g
_.a=h
_.b=i
_.c=j},
dOY:function dOY(d){this.a=d}},D
J=c[1]
A=c[0]
C=c[2]
E=c[82]
B=a.updateHolder(c[70],B)
D=c[222]
B.aMm.prototype={
anD(d,e){var x=this.a,w=Math.sin(x),v=1-Math.cos(x),u=d.gbY(),t=u.b,s=u.a,r=A.kL()
r.ip(w*t+v*s,-w*s+v*t,0,1)
r.a46(x)
return r},
i(d,e){if(e==null)return!1
if(this===e)return!0
if(J.bP(e)!==A.aF(this))return!1
return e instanceof B.aMm&&e.a===this.a},
ga2(d){return C.i.ga2(this.a)},
A(d){return"GradientRotation(radians: "+A.qj(this.a)+")"}}
B.ET.prototype={
xE(d,e){var x=this,w=x.d.L(e).Dr(d),v=x.a,u=x.yZ(),t=x.adr(d,e)
$.J()
t=t!=null?A.KQ(t):null
t=new A.bmO(w,v,u,x.r,x.e,x.f,t)
t.UN()
if(v.length!==u.length)A.N(A.fP('"colors" and "colorStops" arguments must have equal length.',null))
return t},
fm(d){return this.xE(d,null)},
a9(d){var x=this,w=x.a,v=A.aD(w).j("aT<1,f>")
w=A.aI(new A.aT(w,new B.dOY(d),v),v.j("bL.E"))
return new B.ET(x.d,x.e,x.f,x.r,w,x.b,x.c)},
a1R(d){var x=this
return new B.ET(x.d,x.e,x.f,x.r,A.dF(x.a.length,d,!1,y.o),x.b,x.c)},
il(d,e){if(y.j.b(d))return B.ixT(d,this,e)
return this.a6_(d,e)},
im(d,e){if(y.j.b(d))return B.ixT(this,d,e)
return this.a60(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bP(e)!==A.aF(x))return!1
return e instanceof B.ET&&e.d.i(0,x.d)&&e.e===x.e&&e.f===x.f&&e.r===x.r&&J.z(e.c,x.c)&&A.bZ(e.a,x.a)&&A.bZ(e.b,x.b)},
ga2(d){var x=this,w=A.cB(x.a),v=x.b
v=v==null?null:A.cB(v)
return A.aL(x.d,x.e,x.f,x.r,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
A(d){var x=this,w=A.a(["center: "+x.d.A(0),"startAngle: "+A.qj(x.e),"endAngle: "+A.qj(x.f),"colors: "+A.am(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+A.am(v))
w.push("tileMode: "+x.r.A(0))
v=x.c
if(v!=null)w.push("transform: "+v.A(0))
return"SweepGradient("+C.c.aM(w,", ")+")"}}
var z=a.updateTypes([])
B.dOY.prototype={
$1(d){var x=A.F(null,d,this.a)
x.toString
return x},
$S:51};(function inheritance(){var x=a.inherit
x(B.aMm,E.byf)
x(B.ET,D.AY)
x(B.dOY,A.cj)})()
A.bM(b.typeUniverse,JSON.parse('{"ET":{"AY":[]}}'))
var y={o:A.E("f"),h:A.E("o<m>"),j:A.E("ET?")}};
(a=>{a["feXjHjS3xSrrikqhc5KLpS60+Q8="]=a.current})($__dart_deferred_initializers__);