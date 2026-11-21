((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,C,B={
i_G(d,e,f){var x,w,v,u,t,s
if(d==e)return d
if(d==null)return e.a8(f)
if(e==null)return d.a8(1-f)
x=D.hN9(d.a,d.yB(),e.a,e.yB(),f)
w=A.BJ(d.d,e.d,f)
w.toString
v=A.bo(d.e,e.e,f)
v.toString
v=Math.max(0,v)
u=A.bo(d.f,e.f,f)
u.toString
u=Math.max(0,u)
t=f<0.5
s=t?d.r:e.r
t=t?d.c:e.c
return new B.DY(w,v,u,s,x.a,x.b,t)},
aGH:function aGH(d){this.a=d},
DY:function DY(d,e,f,g,h,i,j){var _=this
_.d=d
_.e=e
_.f=f
_.r=g
_.a=h
_.b=i
_.c=j},
dxy:function dxy(d){this.a=d}},D,E
J=c[1]
A=c[0]
C=c[2]
B=a.updateHolder(c[64],B)
D=c[209]
E=c[77]
B.aGH.prototype={
ams(d,e){var x=this.a,w=Math.sin(x),v=1-Math.cos(x),u=d.gbH(),t=u.b,s=u.a,r=A.ki()
r.i8(w*t+v*s,-w*s+v*t,0,1)
r.a3a(x)
return r},
i(d,e){if(e==null)return!1
if(this===e)return!0
if(J.bK(e)!==A.az(this))return!1
return e instanceof B.aGH&&e.a===this.a},
gY(d){return C.i.gY(this.a)},
v(d){return"GradientRotation(radians: "+A.py(this.a)+")"}}
B.DY.prototype={
xa(d,e){var x=this,w=x.d.K(e).D2(d),v=x.a,u=x.yB(),t=x.acs(d,e)
$.J()
t=t!=null?A.Jt(t):null
t=new A.bfK(w,v,u,x.r,x.e,x.f,t)
t.U8()
if(v.length!==u.length)A.O(A.fA('"colors" and "colorStops" arguments must have equal length.',null))
return t},
fI(d){return this.xa(d,null)},
a8(d){var x=this,w=x.a,v=A.aB(w).j("aR<1,e>")
w=A.aH(new A.aR(w,new B.dxy(d),v),v.j("bP.E"))
return new B.DY(x.d,x.e,x.f,x.r,w,x.b,x.c)},
a0Y(d){var x=this
return new B.DY(x.d,x.e,x.f,x.r,A.dz(x.a.length,d,!1,y.o),x.b,x.c)},
i4(d,e){if(y.j.b(d))return B.i_G(d,this,e)
return this.a58(d,e)},
i5(d,e){if(y.j.b(d))return B.i_G(this,d,e)
return this.a59(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bK(e)!==A.az(x))return!1
return e instanceof B.DY&&e.d.i(0,x.d)&&e.e===x.e&&e.f===x.f&&e.r===x.r&&J.y(e.c,x.c)&&A.c5(e.a,x.a)&&A.c5(e.b,x.b)},
gY(d){var x=this,w=A.cz(x.a),v=x.b
v=v==null?null:A.cz(v)
return A.aK(x.d,x.e,x.f,x.r,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
v(d){var x=this,w=A.a(["center: "+x.d.v(0),"startAngle: "+A.py(x.e),"endAngle: "+A.py(x.f),"colors: "+A.ak(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+A.ak(v))
w.push("tileMode: "+x.r.v(0))
v=x.c
if(v!=null)w.push("transform: "+v.v(0))
return"SweepGradient("+C.c.aL(w,", ")+")"}}
var z=a.updateTypes([])
B.dxy.prototype={
$1(d){var x=A.G(null,d,this.a)
x.toString
return x},
$S:44};(function inheritance(){var x=a.inherit
x(B.aGH,E.bq5)
x(B.DY,D.A2)
x(B.dxy,A.ck)})()
A.bN(b.typeUniverse,JSON.parse('{"DY":{"A2":[]}}'))
var y={o:A.E("e"),h:A.E("n<m>"),j:A.E("DY?")}};
(a=>{a["cyDc7KlKR9Yw79z9tCubqLCmSPo="]=a.current})($__dart_deferred_initializers__);