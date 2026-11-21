((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,C,B={
hXj(d,e,f){var x,w,v,u,t,s
if(d==e)return d
if(d==null)return e.a8(f)
if(e==null)return d.a8(1-f)
x=D.hJY(d.a,d.yu(),e.a,e.yu(),f)
w=A.BC(d.d,e.d,f)
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
return new B.DL(w,v,u,s,x.a,x.b,t)},
aGB:function aGB(d){this.a=d},
DL:function DL(d,e,f,g,h,i,j){var _=this
_.d=d
_.e=e
_.f=f
_.r=g
_.a=h
_.b=i
_.c=j},
dw9:function dw9(d){this.a=d}},D,E
J=c[1]
A=c[0]
C=c[2]
B=a.updateHolder(c[63],B)
D=c[202]
E=c[76]
B.aGB.prototype={
am_(d,e){var x=this.a,w=Math.sin(x),v=1-Math.cos(x),u=d.gbH(),t=u.b,s=u.a,r=A.kd()
r.i7(w*t+v*s,-w*s+v*t,0,1)
r.a30(x)
return r},
i(d,e){if(e==null)return!1
if(this===e)return!0
if(J.bI(e)!==A.az(this))return!1
return e instanceof B.aGB&&e.a===this.a},
gY(d){return C.i.gY(this.a)},
v(d){return"GradientRotation(radians: "+A.pp(this.a)+")"}}
B.DL.prototype={
x3(d,e){var x=this,w=x.d.K(e).CZ(d),v=x.a,u=x.yu(),t=x.ac5(d,e)
$.J()
t=t!=null?A.Jl(t):null
t=new A.bex(w,v,u,x.r,x.e,x.f,t)
t.U0()
if(v.length!==u.length)A.O(A.fy('"colors" and "colorStops" arguments must have equal length.',null))
return t},
fH(d){return this.x3(d,null)},
a8(d){var x=this,w=x.a,v=A.aE(w).j("aS<1,e>")
w=A.aG(new A.aS(w,new B.dw9(d),v),v.j("bP.E"))
return new B.DL(x.d,x.e,x.f,x.r,w,x.b,x.c)},
a0P(d){var x=this
return new B.DL(x.d,x.e,x.f,x.r,A.dt(x.a.length,d,!1,y.o),x.b,x.c)},
i3(d,e){if(y.j.b(d))return B.hXj(d,this,e)
return this.a4Z(d,e)},
i4(d,e){if(y.j.b(d))return B.hXj(this,d,e)
return this.a5_(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bI(e)!==A.az(x))return!1
return e instanceof B.DL&&e.d.i(0,x.d)&&e.e===x.e&&e.f===x.f&&e.r===x.r&&J.x(e.c,x.c)&&A.c5(e.a,x.a)&&A.c5(e.b,x.b)},
gY(d){var x=this,w=A.cz(x.a),v=x.b
v=v==null?null:A.cz(v)
return A.aK(x.d,x.e,x.f,x.r,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
v(d){var x=this,w=A.a(["center: "+x.d.v(0),"startAngle: "+A.pp(x.e),"endAngle: "+A.pp(x.f),"colors: "+A.al(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+A.al(v))
w.push("tileMode: "+x.r.v(0))
v=x.c
if(v!=null)w.push("transform: "+v.v(0))
return"SweepGradient("+C.c.aK(w,", ")+")"}}
var z=a.updateTypes([])
B.dw9.prototype={
$1(d){var x=A.G(null,d,this.a)
x.toString
return x},
$S:44};(function inheritance(){var x=a.inherit
x(B.aGB,E.bp_)
x(B.DL,D.A_)
x(B.dw9,A.cn)})()
A.bN(b.typeUniverse,JSON.parse('{"DL":{"A_":[]}}'))
var y={o:A.D("e"),h:A.D("n<m>"),j:A.D("DL?")}};
(a=>{a["KSC9ty6kwghUbGXeuphr+lP3AKw="]=a.current})($__dart_deferred_initializers__);