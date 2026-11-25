((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,C,E,B={
iDD(d,e,f){var x,w,v,u,t,s
if(d==e)return d
if(d==null)return e.ab(f)
if(e==null)return d.ab(1-f)
x=D.ipb(d.a,d.zr(),e.a,e.zr(),f)
w=A.CS(d.d,e.d,f)
w.toString
v=A.br(d.e,e.e,f)
v.toString
v=Math.max(0,v)
u=A.br(d.f,e.f,f)
u.toString
u=Math.max(0,u)
t=f<0.5
s=t?d.r:e.r
t=t?d.c:e.c
return new B.F5(w,v,u,s,x.a,x.b,t)},
aMZ:function aMZ(d){this.a=d},
F5:function F5(d,e,f,g,h,i,j){var _=this
_.d=d
_.e=e
_.f=f
_.r=g
_.a=h
_.b=i
_.c=j},
dS0:function dS0(d){this.a=d}},D
J=c[1]
A=c[0]
C=c[2]
E=c[82]
B=a.updateHolder(c[70],B)
D=c[234]
B.aMZ.prototype={
aoR(d,e){var x=this.a,w=Math.sin(x),v=1-Math.cos(x),u=d.gbY(),t=u.b,s=u.a,r=A.kR()
r.iw(w*t+v*s,-w*s+v*t,0,1)
r.a5p(x)
return r},
i(d,e){if(e==null)return!1
if(this===e)return!0
if(J.bS(e)!==A.aF(this))return!1
return e instanceof B.aMZ&&e.a===this.a},
ga3(d){return C.i.ga3(this.a)},
B(d){return"GradientRotation(radians: "+A.qy(this.a)+")"}}
B.F5.prototype={
y6(d,e){var x=this,w=x.d.N(e).DX(d),v=x.a,u=x.zr(),t=x.aeQ(d,e)
$.K()
t=t!=null?A.L1(t):null
t=new A.bo7(w,v,u,x.r,x.e,x.f,t)
t.VM()
if(v.length!==u.length)A.O(A.fV('"colors" and "colorStops" arguments must have equal length.',null))
return t},
fs(d){return this.y6(d,null)},
ab(d){var x=this,w=x.a,v=A.aA(w).k("aV<1,f>")
w=A.aH(new A.aV(w,new B.dS0(d),v),v.k("bR.E"))
return new B.F5(x.d,x.e,x.f,x.r,w,x.b,x.c)},
a33(d){var x=this
return new B.F5(x.d,x.e,x.f,x.r,A.dM(x.a.length,d,!1,y.o),x.b,x.c)},
iz(d,e){if(y.j.b(d))return B.iDD(d,this,e)
return this.a7k(d,e)},
iA(d,e){if(y.j.b(d))return B.iDD(this,d,e)
return this.a7l(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bS(e)!==A.aF(x))return!1
return e instanceof B.F5&&e.d.i(0,x.d)&&e.e===x.e&&e.f===x.f&&e.r===x.r&&J.y(e.c,x.c)&&A.c_(e.a,x.a)&&A.c_(e.b,x.b)},
ga3(d){var x=this,w=A.cE(x.a),v=x.b
v=v==null?null:A.cE(v)
return A.aN(x.d,x.e,x.f,x.r,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
B(d){var x=this,w=A.a(["center: "+x.d.B(0),"startAngle: "+A.qy(x.e),"endAngle: "+A.qy(x.f),"colors: "+A.an(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+A.an(v))
w.push("tileMode: "+x.r.B(0))
v=x.c
if(v!=null)w.push("transform: "+v.B(0))
return"SweepGradient("+C.c.aK(w,", ")+")"}}
var z=a.updateTypes([])
B.dS0.prototype={
$1(d){var x=A.E(null,d,this.a)
x.toString
return x},
$S:34};(function inheritance(){var x=a.inherit
x(B.aMZ,E.bzs)
x(B.F5,D.B5)
x(B.dS0,A.cf)})()
A.bN(b.typeUniverse,JSON.parse('{"F5":{"B5":[]}}'))
var y={o:A.G("f"),h:A.G("o<n>"),j:A.G("F5?")}};
(a=>{a["XnX0FOZz9PR5dRFRJ+LriIJwZBI="]=a.current})($__dart_deferred_initializers__);