((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,C,D,E,B={
hJG(d,e,f){var x,w,v,u,t,s
if(d==e)return d
if(d==null)return e.ah(f)
if(e==null)return d.ah(1-f)
x=D.hwe(d.a,d.y6(),e.a,e.y6(),f)
w=A.B2(d.d,e.d,f)
w.toString
v=A.bl(d.e,e.e,f)
v.toString
v=Math.max(0,v)
u=A.bl(d.f,e.f,f)
u.toString
u=Math.max(0,u)
t=f<0.5
s=t?d.r:e.r
t=t?d.c:e.c
return new B.D7(w,v,u,s,x.a,x.b,t)},
aEY:function aEY(d){this.a=d},
D7:function D7(d,e,f,g,h,i,j){var _=this
_.d=d
_.e=e
_.f=f
_.r=g
_.a=h
_.b=i
_.c=j},
drI:function drI(d){this.a=d}}
J=c[1]
A=c[0]
C=c[2]
D=c[203]
E=c[77]
B=a.updateHolder(c[64],B)
B.aEY.prototype={
al2(d,e){var x=this.a,w=Math.sin(x),v=1-Math.cos(x),u=d.gbH(),t=u.b,s=u.a,r=A.k1()
r.i1(w*t+v*s,-w*s+v*t,0,1)
r.a2y(x)
return r},
i(d,e){if(e==null)return!1
if(this===e)return!0
if(J.bz(e)!==A.ar(this))return!1
return e instanceof B.aEY&&e.a===this.a},
gY(d){return C.i.gY(this.a)},
v(d){return"GradientRotation(radians: "+A.p3(this.a)+")"}}
B.D7.prototype={
wG(d,e){var x=this,w=x.d.J(e).Cz(d),v=x.a,u=x.y6(),t=x.abu(d,e)
$.I()
t=t!=null?A.Ir(t):null
t=new A.bcj(w,v,u,x.r,x.e,x.f,t)
t.Tr()
if(v.length!==u.length)A.T(A.fu('"colors" and "colorStops" arguments must have equal length.',null))
return t},
fH(d){return this.wG(d,null)},
ah(d){var x=this,w=x.a,v=A.aB(w).j("aR<1,e>")
w=A.aJ(new A.aR(w,new B.drI(d),v),v.j("bq.E"))
return new B.D7(x.d,x.e,x.f,x.r,w,x.b,x.c)},
a0g(d){var x=this
return new B.D7(x.d,x.e,x.f,x.r,A.ds(x.a.length,d,!1,y.o),x.b,x.c)},
hY(d,e){if(y.j.b(d))return B.hJG(d,this,e)
return this.a4x(d,e)},
hZ(d,e){if(y.j.b(d))return B.hJG(this,d,e)
return this.a4y(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bz(e)!==A.ar(x))return!1
return e instanceof B.D7&&e.d.i(0,x.d)&&e.e===x.e&&e.f===x.f&&e.r===x.r&&J.x(e.c,x.c)&&A.c7(e.a,x.a)&&A.c7(e.b,x.b)},
gY(d){var x=this,w=A.cs(x.a),v=x.b
v=v==null?null:A.cs(v)
return A.aA(x.d,x.e,x.f,x.r,x.c,w,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
v(d){var x=this,w=A.a(["center: "+x.d.v(0),"startAngle: "+A.p3(x.e),"endAngle: "+A.p3(x.f),"colors: "+A.ae(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+A.ae(v))
w.push("tileMode: "+x.r.v(0))
v=x.c
if(v!=null)w.push("transform: "+v.v(0))
return"SweepGradient("+C.c.aZ(w,", ")+")"}}
var z=a.updateTypes([])
B.drI.prototype={
$1(d){var x=A.F(null,d,this.a)
x.toString
return x},
$S:47};(function inheritance(){var x=a.inherit
x(B.aEY,E.bmF)
x(B.D7,D.zm)
x(B.drI,A.ck)})()
A.bE(b.typeUniverse,JSON.parse('{"D7":{"zm":[]}}'))
var y={o:A.C("e"),h:A.C("m<p>"),j:A.C("D7?")}};
(a=>{a["0ZWV2pbszAJgj3eCde0Tr+nt2Ck="]=a.current})($__dart_deferred_initializers__);