((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,C,E,B={
iCG(d,e,f){var x,w,v,u,t,s
if(d==e)return d
if(d==null)return e.a9(f)
if(e==null)return d.a9(1-f)
x=D.ioe(d.a,d.zm(),e.a,e.zm(),f)
w=A.CO(d.d,e.d,f)
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
return new B.F_(w,v,u,s,x.a,x.b,t)},
aMS:function aMS(d){this.a=d},
F_:function F_(d,e,f,g,h,i,j){var _=this
_.d=d
_.e=e
_.f=f
_.r=g
_.a=h
_.b=i
_.c=j},
dRv:function dRv(d){this.a=d}},D
J=c[1]
A=c[0]
C=c[2]
E=c[82]
B=a.updateHolder(c[70],B)
D=c[228]
B.aMS.prototype={
aoK(d,e){var x=this.a,w=Math.sin(x),v=1-Math.cos(x),u=d.gbY(),t=u.b,s=u.a,r=A.kQ()
r.iu(w*t+v*s,-w*s+v*t,0,1)
r.a5i(x)
return r},
i(d,e){if(e==null)return!1
if(this===e)return!0
if(J.bQ(e)!==A.aG(this))return!1
return e instanceof B.aMS&&e.a===this.a},
ga3(d){return C.i.ga3(this.a)},
B(d){return"GradientRotation(radians: "+A.qx(this.a)+")"}}
B.F_.prototype={
y0(d,e){var x=this,w=x.d.N(e).DV(d),v=x.a,u=x.zm(),t=x.aeJ(d,e)
$.K()
t=t!=null?A.KW(t):null
t=new A.bnX(w,v,u,x.r,x.e,x.f,t)
t.VG()
if(v.length!==u.length)A.O(A.fV('"colors" and "colorStops" arguments must have equal length.',null))
return t},
ft(d){return this.y0(d,null)},
a9(d){var x=this,w=x.a,v=A.aE(w).k("aV<1,f>")
w=A.aH(new A.aV(w,new B.dRv(d),v),v.k("bS.E"))
return new B.F_(x.d,x.e,x.f,x.r,w,x.b,x.c)},
a2X(d){var x=this
return new B.F_(x.d,x.e,x.f,x.r,A.dK(x.a.length,d,!1,y.o),x.b,x.c)},
iy(d,e){if(y.j.b(d))return B.iCG(d,this,e)
return this.a7d(d,e)},
iz(d,e){if(y.j.b(d))return B.iCG(this,d,e)
return this.a7e(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bQ(e)!==A.aG(x))return!1
return e instanceof B.F_&&e.d.i(0,x.d)&&e.e===x.e&&e.f===x.f&&e.r===x.r&&J.z(e.c,x.c)&&A.c_(e.a,x.a)&&A.c_(e.b,x.b)},
ga3(d){var x=this,w=A.cD(x.a),v=x.b
v=v==null?null:A.cD(v)
return A.aN(x.d,x.e,x.f,x.r,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
B(d){var x=this,w=A.a(["center: "+x.d.B(0),"startAngle: "+A.qx(x.e),"endAngle: "+A.qx(x.f),"colors: "+A.an(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+A.an(v))
w.push("tileMode: "+x.r.B(0))
v=x.c
if(v!=null)w.push("transform: "+v.B(0))
return"SweepGradient("+C.c.aK(w,", ")+")"}}
var z=a.updateTypes([])
B.dRv.prototype={
$1(d){var x=A.E(null,d,this.a)
x.toString
return x},
$S:33};(function inheritance(){var x=a.inherit
x(B.aMS,E.bzi)
x(B.F_,D.B1)
x(B.dRv,A.cl)})()
A.bO(b.typeUniverse,JSON.parse('{"F_":{"B1":[]}}'))
var y={o:A.G("f"),h:A.G("o<n>"),j:A.G("F_?")}};
(a=>{a["bvFyxOLKFe5c+MDS3oxTPQiHawU="]=a.current})($__dart_deferred_initializers__);