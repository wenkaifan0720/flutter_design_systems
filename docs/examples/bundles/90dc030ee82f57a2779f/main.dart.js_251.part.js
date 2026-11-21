((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,A,C={
aCz(d,e,f,g,h,i){var x,w,v,u,t=Math.min(g,f),s=Math.max(g,f)
if(e){t=Math.min(t,0)
s=Math.max(s,0)}if(t===s){--t;++s}for(x=null,w=0;w<10;++w,x=v){v=C.hNX(t,s,i)
if(v===x)break
u=D.ay0(v)
t=B.afc(Math.floor(t/v)*v,u)
s=B.afc(Math.ceil(s/v)*v,u)}return new C.Co(t,s,null,h,d)},
hNX(d,e,f){var x,w,v=(e-d)/Math.max(1,f),u=A.i.cE(Math.log(v)/2.302585092994046),t=Math.pow(10,u),s=v/t
if(s>=7.071)x=10
else if(s>=3.162)x=5
else{w=s>=1.414?2:1
x=w}return B.afc(x*t,Math.max(0,-u))},
p7:function p7(d,e,f){this.a=d
this.b=e
this.c=f},
bjW:function bjW(){},
Co:function Co(d,e,f,g,h){var _=this
_.c=d
_.d=e
_.e=f
_.a=g
_.b=h}},D
B=c[0]
A=c[2]
C=a.updateHolder(c[158],C)
D=c[196]
C.p7.prototype={
i(d,e){if(e==null)return!1
return e instanceof C.p7&&e.a===this.a&&e.b===this.b&&e.c===this.c},
gY(d){return B.aK(this.a,this.b,this.c,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a)},
v(d){return"DesignScaleTick("+this.c+" at "+B.ak(this.b)+")"}}
C.bjW.prototype={}
C.Co.prototype={
ix(d,e){var x,w=this,v=w.d,u=w.c
if(v===u)return(w.a+w.b)/2
x=w.a
return x+(e-u)/(v-u)*(w.b-x)},
CS(d,e){var x,w,v,u,t,s,r=this,q=r.d,p=r.c
if(q<=p)return B.a([new C.p7(p,r.ix(0,p),B.e6(p,B.dx(d.gbW()),null,null))],y.c)
x=C.hNX(p,q,e)
w=D.ay0(x)
v=A.i.fk(p/x-1e-9)
u=A.i.cE(q/x+1e-9)
q=B.a([],y.c)
for(t=v;t<=u;++t){s=B.afc(t*x,w)
q.push(new C.p7(s,r.ix(0,s),B.e6(s,B.dx(d.gbW()),w,null)))}return q},
jg(d){return this.CS(d,5)},
v(d){var x=this
return"DesignLinearScale("+B.ak(x.c)+"\u2013"+B.ak(x.d)+" \u2192 "+B.ak(x.a)+"\u2013"+B.ak(x.b)+")"}}
var z=a.updateTypes([]);(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.W,[C.p7,C.bjW])
w(C.Co,C.bjW)})()
var y={c:B.E("n<p7>")}};
(a=>{a["/lZ8IjqDO8ywjJu9abllaG1GVlc="]=a.current})($__dart_deferred_initializers__);