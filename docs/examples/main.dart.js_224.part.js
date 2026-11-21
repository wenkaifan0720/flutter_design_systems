((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,A,C={
atG(d,e,f,g,h,i){var x,w,v,u,t=Math.min(g,f),s=Math.max(g,f)
if(e){t=Math.min(t,0)
s=Math.max(s,0)}if(t===s){--t;++s}for(x=null,w=0;w<10;++w,x=v){v=C.h2H(t,s,i)
if(v===x)break
u=D.apL(v)
t=B.a97(Math.floor(t/v)*v,u)
s=B.a97(Math.ceil(s/v)*v,u)}return new C.Ag(t,s,null,h,d)},
h2H(d,e,f){var x,w,v=(e-d)/Math.max(1,f),u=A.h.cn(Math.log(v)/2.302585092994046),t=Math.pow(10,u),s=v/t
if(s>=7.071)x=10
else if(s>=3.162)x=5
else{w=s>=1.414?2:1
x=w}return B.a97(x*t,Math.max(0,-u))},
oF:function oF(d,e,f){this.a=d
this.b=e
this.c=f},
b6s:function b6s(){},
Ag:function Ag(d,e,f,g,h){var _=this
_.c=d
_.d=e
_.e=f
_.a=g
_.b=h}},D
B=c[0]
A=c[2]
C=a.updateHolder(c[140],C)
D=c[173]
C.oF.prototype={
i(d,e){if(e==null)return!1
return e instanceof C.oF&&e.a===this.a&&e.b===this.b&&e.c===this.c},
gU(d){return B.aF(this.a,this.b,this.c,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a)},
v(d){return"DesignScaleTick("+this.c+" at "+B.a7(this.b)+")"}}
C.b6s.prototype={}
C.Ag.prototype={
k7(d,e){var x,w=this,v=w.d,u=w.c
if(v===u)return(w.a+w.b)/2
x=w.a
return x+(e-u)/(v-u)*(w.b-x)},
yP(d,e){var x,w,v,u,t,s,r=this,q=r.d,p=r.c
if(q<=p)return B.a([new C.oF(p,r.k7(0,p),B.e9(p,B.dA(d.gbU()),null,null))],y.c)
x=C.h2H(p,q,e)
w=D.apL(x)
v=A.h.dV(p/x-1e-9)
u=A.h.cn(q/x+1e-9)
q=B.a([],y.c)
for(t=v;t<=u;++t){s=B.a97(t*x,w)
q.push(new C.oF(s,r.k7(0,s),B.e9(s,B.dA(d.gbU()),w,null)))}return q},
hR(d){return this.yP(d,5)},
v(d){var x=this
return"DesignLinearScale("+B.a7(x.c)+"\u2013"+B.a7(x.d)+" \u2192 "+B.a7(x.a)+"\u2013"+B.a7(x.b)+")"}}
var z=a.updateTypes([]);(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.T,[C.oF,C.b6s])
w(C.Ag,C.b6s)})()
var y={c:B.G("m<oF>")}};
(a=>{a["GknjGTwhZdsh8Wnu1kgE/N2PKZQ="]=a.current})($__dart_deferred_initializers__);