((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,C,E,B={
iBa(d,e,f){var x,w,v,u,t,s
if(d==e)return d
if(d==null)return e.a9(f)
if(e==null)return d.a9(1-f)
x=D.imS(d.a,d.zc(),e.a,e.zc(),f)
w=A.CN(d.d,e.d,f)
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
return new B.EX(w,v,u,s,x.a,x.b,t)},
aMC:function aMC(d){this.a=d},
EX:function EX(d,e,f,g,h,i,j){var _=this
_.d=d
_.e=e
_.f=f
_.r=g
_.a=h
_.b=i
_.c=j},
dQO:function dQO(d){this.a=d}},D
J=c[1]
A=c[0]
C=c[2]
E=c[82]
B=a.updateHolder(c[70],B)
D=c[226]
B.aMC.prototype={
aoy(d,e){var x=this.a,w=Math.sin(x),v=1-Math.cos(x),u=d.gbX(),t=u.b,s=u.a,r=A.kO()
r.ir(w*t+v*s,-w*s+v*t,0,1)
r.a5_(x)
return r},
i(d,e){if(e==null)return!1
if(this===e)return!0
if(J.bQ(e)!==A.aG(this))return!1
return e instanceof B.aMC&&e.a===this.a},
ga3(d){return C.i.ga3(this.a)},
B(d){return"GradientRotation(radians: "+A.qv(this.a)+")"}}
B.EX.prototype={
xU(d,e){var x=this,w=x.d.N(e).DN(d),v=x.a,u=x.zc(),t=x.aeo(d,e)
$.K()
t=t!=null?A.KQ(t):null
t=new A.bnK(w,v,u,x.r,x.e,x.f,t)
t.Vu()
if(v.length!==u.length)A.O(A.fU('"colors" and "colorStops" arguments must have equal length.',null))
return t},
fs(d){return this.xU(d,null)},
a9(d){var x=this,w=x.a,v=A.aE(w).k("aV<1,h>")
w=A.aI(new A.aV(w,new B.dQO(d),v),v.k("bS.E"))
return new B.EX(x.d,x.e,x.f,x.r,w,x.b,x.c)},
a2E(d){var x=this
return new B.EX(x.d,x.e,x.f,x.r,A.dJ(x.a.length,d,!1,y.o),x.b,x.c)},
ix(d,e){if(y.j.b(d))return B.iBa(d,this,e)
return this.a6U(d,e)},
iy(d,e){if(y.j.b(d))return B.iBa(this,d,e)
return this.a6V(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bQ(e)!==A.aG(x))return!1
return e instanceof B.EX&&e.d.i(0,x.d)&&e.e===x.e&&e.f===x.f&&e.r===x.r&&J.z(e.c,x.c)&&A.c_(e.a,x.a)&&A.c_(e.b,x.b)},
ga3(d){var x=this,w=A.cB(x.a),v=x.b
v=v==null?null:A.cB(v)
return A.aO(x.d,x.e,x.f,x.r,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
B(d){var x=this,w=A.a(["center: "+x.d.B(0),"startAngle: "+A.qv(x.e),"endAngle: "+A.qv(x.f),"colors: "+A.am(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+A.am(v))
w.push("tileMode: "+x.r.B(0))
v=x.c
if(v!=null)w.push("transform: "+v.B(0))
return"SweepGradient("+C.c.aK(w,", ")+")"}}
var z=a.updateTypes([])
B.dQO.prototype={
$1(d){var x=A.F(null,d,this.a)
x.toString
return x},
$S:51};(function inheritance(){var x=a.inherit
x(B.aMC,E.bz7)
x(B.EX,D.AY)
x(B.dQO,A.cl)})()
A.bO(b.typeUniverse,JSON.parse('{"EX":{"AY":[]}}'))
var y={o:A.G("h"),h:A.G("o<n>"),j:A.G("EX?")}};
(a=>{a["cLlW/slUNvaLWyB69tlhQAM3l+Q="]=a.current})($__dart_deferred_initializers__);