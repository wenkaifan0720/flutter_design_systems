((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,C,E,B={
iES(d,e,f){var x,w,v,u,t,s
if(d==e)return d
if(d==null)return e.aa(f)
if(e==null)return d.aa(1-f)
x=D.iqb(d.a,d.zm(),e.a,e.zm(),f)
w=A.Db(d.d,e.d,f)
w.toString
v=A.bs(d.e,e.e,f)
v.toString
v=Math.max(0,v)
u=A.bs(d.f,e.f,f)
u.toString
u=Math.max(0,u)
t=f<0.5
s=t?d.r:e.r
t=t?d.c:e.c
return new B.Fp(w,v,u,s,x.a,x.b,t)},
aNn:function aNn(d){this.a=d},
Fp:function Fp(d,e,f,g,h,i,j){var _=this
_.d=d
_.e=e
_.f=f
_.r=g
_.a=h
_.b=i
_.c=j},
dSW:function dSW(d){this.a=d}},D
J=c[1]
A=c[0]
C=c[2]
E=c[84]
B=a.updateHolder(c[71],B)
D=c[241]
B.aNn.prototype={
ap3(d,e){var x=this.a,w=Math.sin(x),v=1-Math.cos(x),u=d.gc0(),t=u.b,s=u.a,r=A.kV()
r.it(w*t+v*s,-w*s+v*t,0,1)
r.a5o(x)
return r},
i(d,e){if(e==null)return!1
if(this===e)return!0
if(J.bR(e)!==A.aF(this))return!1
return e instanceof B.aNn&&e.a===this.a},
ga3(d){return C.i.ga3(this.a)},
C(d){return"GradientRotation(radians: "+A.qJ(this.a)+")"}}
B.Fp.prototype={
y4(d,e){var x=this,w=x.d.N(e).DW(d),v=x.a,u=x.zm(),t=x.aeT(d,e)
$.K()
t=t!=null?A.Ll(t):null
t=new A.boF(w,v,u,x.r,x.e,x.f,t)
t.VP()
if(v.length!==u.length)A.N(A.fV('"colors" and "colorStops" arguments must have equal length.',null))
return t},
fp(d){return this.y4(d,null)},
aa(d){var x=this,w=x.a,v=A.aA(w).k("aV<1,e>")
w=A.aH(new A.aV(w,new B.dSW(d),v),v.k("bQ.E"))
return new B.Fp(x.d,x.e,x.f,x.r,w,x.b,x.c)},
a34(d){var x=this
return new B.Fp(x.d,x.e,x.f,x.r,A.dO(x.a.length,d,!1,y.o),x.b,x.c)},
iy(d,e){if(y.j.b(d))return B.iES(d,this,e)
return this.a7k(d,e)},
iz(d,e){if(y.j.b(d))return B.iES(this,d,e)
return this.a7l(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bR(e)!==A.aF(x))return!1
return e instanceof B.Fp&&e.d.i(0,x.d)&&e.e===x.e&&e.f===x.f&&e.r===x.r&&J.A(e.c,x.c)&&A.bY(e.a,x.a)&&A.bY(e.b,x.b)},
ga3(d){var x=this,w=A.cA(x.a),v=x.b
v=v==null?null:A.cA(v)
return A.aN(x.d,x.e,x.f,x.r,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
C(d){var x=this,w=A.a(["center: "+x.d.C(0),"startAngle: "+A.qJ(x.e),"endAngle: "+A.qJ(x.f),"colors: "+A.al(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+A.al(v))
w.push("tileMode: "+x.r.C(0))
v=x.c
if(v!=null)w.push("transform: "+v.C(0))
return"SweepGradient("+C.d.aM(w,", ")+")"}}
var z=a.updateTypes([])
B.dSW.prototype={
$1(d){var x=A.H(null,d,this.a)
x.toString
return x},
$S:33};(function inheritance(){var x=a.inherit
x(B.aNn,E.bA_)
x(B.Fp,D.Bo)
x(B.dSW,A.ce)})()
A.bM(b.typeUniverse,JSON.parse('{"Fp":{"Bo":[]}}'))
var y={o:A.E("e"),h:A.E("o<n>"),j:A.E("Fp?")}};
(a=>{a["7wamiTr/vSrmmG+rtwB6Fxp3VqM="]=a.current})($__dart_deferred_initializers__);