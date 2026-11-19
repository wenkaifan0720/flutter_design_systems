((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,A,C={
bgw(d,e,f,g,h,i){var x,w,v,u,t=Math.min(g,f),s=Math.max(g,f)
if(e){t=Math.min(t,0)
s=Math.max(s,0)}if(t===s){--t;++s}for(x=null,w=0;w<10;++w,x=v){v=C.hwZ(t,s,i)
if(v===x)break
u=D.avR(v)
t=B.adN(Math.floor(t/v)*v,u)
s=B.adN(Math.ceil(s/v)*v,u)}return new C.BD(t,s,null,h,d)},
hwZ(d,e,f){var x,w,v=(e-d)/Math.max(1,f),u=A.i.cE(Math.log(v)/2.302585092994046),t=Math.pow(10,u),s=v/t
if(s>=7.071)x=10
else if(s>=3.162)x=5
else{w=s>=1.414?2:1
x=w}return B.adN(x*t,Math.max(0,-u))},
rE:function rE(d,e,f){this.a=d
this.b=e
this.c=f},
bgC:function bgC(){},
BD:function BD(d,e,f,g,h){var _=this
_.c=d
_.d=e
_.e=f
_.a=g
_.b=h}},D
B=c[0]
A=c[2]
C=a.updateHolder(c[164],C)
D=c[199]
C.rE.prototype={
i(d,e){if(e==null)return!1
return e instanceof C.rE&&e.a===this.a&&e.b===this.b&&e.c===this.c},
gY(d){return B.aA(this.a,this.b,this.c,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a)},
v(d){return"DesignScaleTick("+this.c+" at "+B.ae(this.b)+")"}}
C.bgC.prototype={}
C.BD.prototype={
iU(d,e){var x,w=this,v=w.d,u=w.c
if(v===u)return(w.a+w.b)/2
x=w.a
return x+(e-u)/(v-u)*(w.b-x)},
Gd(d,e){var x,w,v,u,t,s,r=this,q=r.d,p=r.c
if(q<=p)return B.a([new C.rE(p,r.iU(0,p),B.ec(p,B.dH(d.gco()),null,null))],y.c)
x=C.hwZ(p,q,e)
w=D.avR(x)
v=A.i.fe(p/x-1e-9)
u=A.i.cE(q/x+1e-9)
q=B.a([],y.c)
for(t=v;t<=u;++t){s=B.adN(t*x,w)
q.push(new C.rE(s,r.iU(0,s),B.ec(s,B.dH(d.gco()),w,null)))}return q},
aQM(d){return this.Gd(d,5)},
v(d){var x=this
return"DesignLinearScale("+B.ae(x.c)+"\u2013"+B.ae(x.d)+" \u2192 "+B.ae(x.a)+"\u2013"+B.ae(x.b)+")"}}
var z=a.updateTypes([]);(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.Q,[C.rE,C.bgC])
w(C.BD,C.bgC)})()
var y={c:B.C("m<rE>")}};
(a=>{a["SqxdI2iO0YK62gsPxpAj803eZng="]=a.current})($__dart_deferred_initializers__);