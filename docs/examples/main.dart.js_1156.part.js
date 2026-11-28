((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,C,E,B={
iNu(d,e,f){var x,w,v,u,t,s
if(d==e)return d
if(d==null)return e.a7(f)
if(e==null)return d.a7(1-f)
x=D.iyf(d.a,d.zx(),e.a,e.zx(),f)
w=A.DS(d.d,e.d,f)
w.toString
v=A.bm(d.e,e.e,f)
v.toString
v=Math.max(0,v)
u=A.bm(d.f,e.f,f)
u.toString
u=Math.max(0,u)
t=f<0.5
s=t?d.r:e.r
t=t?d.c:e.c
return new B.Ga(w,v,u,s,x.a,x.b,t)},
aPb:function aPb(d){this.a=d},
Ga:function Ga(d,e,f,g,h,i,j){var _=this
_.d=d
_.e=e
_.f=f
_.r=g
_.a=h
_.b=i
_.c=j},
dY_:function dY_(d){this.a=d}},D
J=c[1]
A=c[0]
C=c[2]
E=c[85]
B=a.updateHolder(c[70],B)
D=c[243]
B.aPb.prototype={
aq4(d,e){var x=this.a,w=Math.sin(x),v=1-Math.cos(x),u=d.gc4(),t=u.b,s=u.a,r=A.l9()
r.iw(w*t+v*s,-w*s+v*t,0,1)
r.a64(x)
return r},
i(d,e){if(e==null)return!1
if(this===e)return!0
if(J.bT(e)!==A.aI(this))return!1
return e instanceof B.aPb&&e.a===this.a},
ga2(d){return C.i.ga2(this.a)},
D(d){return"GradientRotation(radians: "+A.r0(this.a)+")"}}
B.Ga.prototype={
yd(d,e){var x=this,w=x.d.M(e).Eb(d),v=x.a,u=x.zx(),t=x.afL(d,e)
$.K()
t=t!=null?A.Md(t):null
t=new A.br3(w,v,u,x.r,x.e,x.f,t)
t.Wk()
if(v.length!==u.length)A.O(A.h0('"colors" and "colorStops" arguments must have equal length.',null))
return t},
ft(d){return this.yd(d,null)},
a7(d){var x=this,w=x.a,v=A.aC(w).k("aV<1,e>")
w=A.aG(new A.aV(w,new B.dY_(d),v),v.k("bS.E"))
return new B.Ga(x.d,x.e,x.f,x.r,w,x.b,x.c)},
a3G(d){var x=this
return new B.Ga(x.d,x.e,x.f,x.r,A.dQ(x.a.length,d,!1,y.o),x.b,x.c)},
is(d,e){if(y.j.b(d))return B.iNu(d,this,e)
return this.a84(d,e)},
it(d,e){if(y.j.b(d))return B.iNu(this,d,e)
return this.a85(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bT(e)!==A.aI(x))return!1
return e instanceof B.Ga&&e.d.i(0,x.d)&&e.e===x.e&&e.f===x.f&&e.r===x.r&&J.B(e.c,x.c)&&A.bZ(e.a,x.a)&&A.bZ(e.b,x.b)},
ga2(d){var x=this,w=A.cC(x.a),v=x.b
v=v==null?null:A.cC(v)
return A.aP(x.d,x.e,x.f,x.r,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
D(d){var x=this,w=A.a(["center: "+x.d.D(0),"startAngle: "+A.r0(x.e),"endAngle: "+A.r0(x.f),"colors: "+A.am(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+A.am(v))
w.push("tileMode: "+x.r.D(0))
v=x.c
if(v!=null)w.push("transform: "+v.D(0))
return"SweepGradient("+C.c.aM(w,", ")+")"}}
var z=a.updateTypes([])
B.dY_.prototype={
$1(d){var x=A.C(null,d,this.a)
x.toString
return x},
$S:32};(function inheritance(){var x=a.inherit
x(B.aPb,E.bCt)
x(B.Ga,D.C_)
x(B.dY_,A.cp)})()
A.bP(b.typeUniverse,JSON.parse('{"Ga":{"C_":[]}}'))
var y={o:A.G("e"),h:A.G("o<n>"),j:A.G("Ga?")}};
(a=>{a["NrspEJ5egHisiiBP/f4HbD+ugow="]=a.current})($__dart_deferred_initializers__);