((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,C,D,E,B={
hef(d,e,f){var x,w,v,u,t,s
if(d==e)return d
if(d==null)return e.aa(f)
if(e==null)return d.aa(1-f)
x=D.h1V(d.a,d.ve(),e.a,e.ve(),f)
w=A.zJ(d.d,e.d,f)
w.toString
v=A.bG(d.e,e.e,f)
v.toString
v=Math.max(0,v)
u=A.bG(d.f,e.f,f)
u.toString
u=Math.max(0,u)
t=f<0.5
s=t?d.r:e.r
t=t?d.c:e.c
return new B.BH(w,v,u,s,x.a,x.b,t)},
axR:function axR(d){this.a=d},
BH:function BH(d,e,f,g,h,i,j){var _=this
_.d=d
_.e=e
_.f=f
_.r=g
_.a=h
_.b=i
_.c=j},
dai:function dai(d){this.a=d}}
J=c[1]
A=c[0]
C=c[2]
D=c[169]
E=c[69]
B=a.updateHolder(c[58],B)
B.axR.prototype={
abk(d,e){var x=this.a,w=Math.sin(x),v=1-Math.cos(x),u=d.gbH(),t=u.b,s=u.a,r=A.jQ()
r.fg(w*t+v*s,-w*s+v*t,0,1)
r.VK(x)
return r},
i(d,e){if(e==null)return!1
if(this===e)return!0
if(J.bH(e)!==A.at(this))return!1
return e instanceof B.axR&&e.a===this.a},
gU(d){return C.h.gU(this.a)},
v(d){return"GradientRotation(radians: "+A.oz(this.a)+")"}}
B.BH.prototype={
u0(d,e){var x=this,w=x.d.L(e).M8(d),v=x.a,u=x.ve(),t=x.a2s(d,e)
$.K()
t=t!=null?A.GF(t):null
t=new A.b2v(w,v,u,x.r,x.e,x.f,t)
t.MZ()
if(v.length!==u.length)A.N(A.fl('"colors" and "colorStops" arguments must have equal length.',null))
return t},
ec(d){return this.u0(d,null)},
aa(d){var x=this,w=x.a,v=A.aw(w).j("aN<1,e>")
w=A.aC(new A.aN(w,new B.dai(d),v),v.j("bM.E"))
return new B.BH(x.d,x.e,x.f,x.r,w,x.b,x.c)},
TM(d){var x=this
return new B.BH(x.d,x.e,x.f,x.r,A.dx(x.a.length,d,!1,y.o),x.b,x.c)},
ft(d,e){if(y.j.b(d))return B.hef(d,this,e)
return this.Xf(d,e)},
fu(d,e){if(y.j.b(d))return B.hef(this,d,e)
return this.Xg(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bH(e)!==A.at(x))return!1
return e instanceof B.BH&&e.d.i(0,x.d)&&e.e===x.e&&e.f===x.f&&e.r===x.r&&J.z(e.c,x.c)&&A.bY(e.a,x.a)&&A.bY(e.b,x.b)},
gU(d){var x=this,w=A.ci(x.a),v=x.b
v=v==null?null:A.ci(v)
return A.aF(x.d,x.e,x.f,x.r,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
v(d){var x=this,w=A.a(["center: "+x.d.v(0),"startAngle: "+A.oz(x.e),"endAngle: "+A.oz(x.f),"colors: "+A.a7(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+A.a7(v))
w.push("tileMode: "+x.r.v(0))
v=x.c
if(v!=null)w.push("transform: "+v.v(0))
return"SweepGradient("+C.c.aC(w,", ")+")"}}
var z=a.updateTypes([])
B.dai.prototype={
$1(d){var x=A.E(null,d,this.a)
x.toString
return x},
$S:42};(function inheritance(){var x=a.inherit
x(B.axR,E.bcu)
x(B.BH,D.ye)
x(B.dai,A.cq)})()
A.c_(b.typeUniverse,JSON.parse('{"BH":{"ye":[]}}'))
var y={o:A.G("e"),h:A.G("m<l>"),j:A.G("BH?")}};
(a=>{a["uDdJhPl0Iw/e5ANZkD6wgBCmCFg="]=a.current})($__dart_deferred_initializers__);