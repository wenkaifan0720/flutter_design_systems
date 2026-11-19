((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,C,E,D,B={
hIf(d,e,f){var x,w,v,u,t,s,r
if(d==e)return d
if(d==null)return e.ah(f)
if(e==null)return d.ah(1-f)
x=D.hwe(d.a,d.y6(),e.a,e.y6(),f)
w=A.B2(d.d,e.d,f)
w.toString
v=A.bl(d.e,e.e,f)
v.toString
v=Math.max(0,v)
u=f<0.5
t=u?d.f:e.f
s=A.B2(d.r,e.r,f)
r=A.bl(d.w,e.w,f)
r.toString
r=Math.max(0,r)
u=u?d.c:e.c
return new B.vH(w,v,t,s,r,x.a,x.b,u)},
vH:function vH(d,e,f,g,h,i,j,k){var _=this
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.a=i
_.b=j
_.c=k},
den:function den(d){this.a=d}}
J=c[1]
A=c[0]
C=c[2]
E=c[128]
D=c[203]
B=a.updateHolder(c[86],B)
B.vH.prototype={
wG(d,e){var x=this,w=x.d.J(e).Cz(d),v=d.gcf(),u=x.y6(),t=x.abu(d,e),s=x.r
s=s==null?null:s.J(e).Cz(d)
return E.ajj(w,x.e*v,x.a,u,x.f,t,s,x.w*d.gcf())},
fH(d){return this.wG(d,null)},
ah(d){var x=this,w=x.a,v=A.aB(w).j("aR<1,e>")
w=A.aJ(new A.aR(w,new B.den(d),v),v.j("bq.E"))
return new B.vH(x.d,x.e,x.f,x.r,x.w,w,x.b,x.c)},
a0g(d){var x=this
return new B.vH(x.d,x.e,x.f,x.r,x.w,A.ds(x.a.length,d,!1,y.o),x.b,x.c)},
hY(d,e){if(y.a.b(d))return B.hIf(d,this,e)
return this.a4x(d,e)},
hZ(d,e){if(y.a.b(d))return B.hIf(this,d,e)
return this.a4y(d,e)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
if(J.bz(e)!==A.ar(x))return!1
return e instanceof B.vH&&e.d.i(0,x.d)&&e.e===x.e&&e.f===x.f&&J.x(e.c,x.c)&&A.c7(e.a,x.a)&&A.c7(e.b,x.b)&&J.x(e.r,x.r)&&e.w===x.w},
gY(d){var x=this,w=A.cs(x.a),v=x.b
v=v==null?null:A.cs(v)
return A.aA(x.d,x.e,x.f,x.c,w,v,x.r,x.w,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
v(d){var x=this,w=A.a(["center: "+x.d.v(0),"radius: "+A.p3(x.e),"colors: "+A.ae(x.a)],y.h),v=x.b
if(v!=null)w.push("stops: "+A.ae(v))
w.push("tileMode: "+x.f.v(0))
v=x.r
if(v!=null)w.push("focal: "+v.v(0))
w.push("focalRadius: "+A.p3(x.w))
v=x.c
if(v!=null)w.push("transform: "+v.v(0))
return"RadialGradient("+C.c.aZ(w,", ")+")"}}
var z=a.updateTypes([])
B.den.prototype={
$1(d){var x=A.F(null,d,this.a)
x.toString
return x},
$S:47};(function inheritance(){var x=a.inherit
x(B.vH,D.zm)
x(B.den,A.ck)})()
A.bE(b.typeUniverse,JSON.parse('{"vH":{"zm":[]}}'))
var y={o:A.C("e"),h:A.C("m<p>"),a:A.C("vH?")}};
(a=>{a["bqE8bk3LaDuOXp4Y0kwOBOyMwls="]=a.current})($__dart_deferred_initializers__);