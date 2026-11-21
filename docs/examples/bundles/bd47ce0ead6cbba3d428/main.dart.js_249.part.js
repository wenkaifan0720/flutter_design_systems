((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,A,C={
aCd(d,e,f,g,h,i){var x,w,v,u,t=Math.min(g,f),s=Math.max(g,f)
if(e){t=Math.min(t,0)
s=Math.max(s,0)}if(t===s){--t;++s}for(x=null,w=0;w<10;++w,x=v){v=C.hKM(t,s,i)
if(v===x)break
u=D.axx(v)
t=B.aeX(Math.floor(t/v)*v,u)
s=B.aeX(Math.ceil(s/v)*v,u)}return new C.Ch(t,s,null,h,d)},
hKM(d,e,f){var x,w,v=(e-d)/Math.max(1,f),u=A.i.cB(Math.log(v)/2.302585092994046),t=Math.pow(10,u),s=v/t
if(s>=7.071)x=10
else if(s>=3.162)x=5
else{w=s>=1.414?2:1
x=w}return B.aeX(x*t,Math.max(0,-u))},
oZ:function oZ(d,e,f){this.a=d
this.b=e
this.c=f},
biN:function biN(){},
Ch:function Ch(d,e,f,g,h){var _=this
_.c=d
_.d=e
_.e=f
_.a=g
_.b=h}},D
B=c[0]
A=c[2]
C=a.updateHolder(c[154],C)
D=c[192]
C.oZ.prototype={
i(d,e){if(e==null)return!1
return e instanceof C.oZ&&e.a===this.a&&e.b===this.b&&e.c===this.c},
gY(d){return B.aK(this.a,this.b,this.c,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a)},
v(d){return"DesignScaleTick("+this.c+" at "+B.al(this.b)+")"}}
C.biN.prototype={}
C.Ch.prototype={
iu(d,e){var x,w=this,v=w.d,u=w.c
if(v===u)return(w.a+w.b)/2
x=w.a
return x+(e-u)/(v-u)*(w.b-x)},
CO(d,e){var x,w,v,u,t,s,r=this,q=r.d,p=r.c
if(q<=p)return B.a([new C.oZ(p,r.iu(0,p),B.e6(p,B.dv(d.gbW()),null,null))],y.c)
x=C.hKM(p,q,e)
w=D.axx(x)
v=A.i.fi(p/x-1e-9)
u=A.i.cB(q/x+1e-9)
q=B.a([],y.c)
for(t=v;t<=u;++t){s=B.aeX(t*x,w)
q.push(new C.oZ(s,r.iu(0,s),B.e6(s,B.dv(d.gbW()),w,null)))}return q},
jd(d){return this.CO(d,5)},
v(d){var x=this
return"DesignLinearScale("+B.al(x.c)+"\u2013"+B.al(x.d)+" \u2192 "+B.al(x.a)+"\u2013"+B.al(x.b)+")"}}
var z=a.updateTypes([]);(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.V,[C.oZ,C.biN])
w(C.Ch,C.biN)})()
var y={c:B.D("n<oZ>")}};
(a=>{a["nKLb40C4nCLY2pzNUXZmFUswmiQ="]=a.current})($__dart_deferred_initializers__);