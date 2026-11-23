((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var C,A,B={
aId(d,e,f,g,h,i){var x,w,v,u,t,s,r=Math.min(g,f),q=Math.max(g,f)
if(e){r=Math.min(r,0)
q=Math.max(q,0)}x=r===q
if(x&&e&&r===0){w=Math.max(1,i-1)
for(;;){x=B.hI8(0,w,i)
if(!(x<1))break;++w}return new B.AC(0,w,null,h,d)}if(x){--r;++q}for(v=null,u=0;u<10;++u,v=t){t=B.hI8(r,q,i)
if(t===v)break
s=D.aD7(t)
r=C.aiV(Math.floor(r/t)*t,s)
q=C.aiV(Math.ceil(q/t)*t,s)}return new B.AC(r,q,null,h,d)},
hI8(d,e,f){var x,w,v=(e-d)/Math.max(1,f),u=A.i.cP(Math.log(v)/2.302585092994046),t=Math.pow(10,u),s=v/t
if(s>=7.071)x=10
else if(s>=3.162)x=5
else{w=s>=1.414?2:1
x=w}return C.aiV(x*t,Math.max(0,-u))},
qr:function qr(d,e,f){this.a=d
this.b=e
this.c=f},
bs_:function bs_(){},
AC:function AC(d,e,f,g,h){var _=this
_.c=d
_.d=e
_.e=f
_.a=g
_.b=h}},D
C=c[0]
A=c[2]
B=a.updateHolder(c[182],B)
D=c[213]
B.qr.prototype={
i(d,e){if(e==null)return!1
return e instanceof B.qr&&e.a===this.a&&e.b===this.b&&e.c===this.c},
ga2(d){return C.aL(this.a,this.b,this.c,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a,A.a)},
A(d){return"DesignScaleTick("+this.c+" at "+C.am(this.b)+")"}}
B.bs_.prototype={}
B.AC.prototype={
ki(d,e){var x,w=this,v=w.d,u=w.c
if(v===u)return(w.a+w.b)/2
x=w.a
return x+(e-u)/(v-u)*(w.b-x)},
Az(d,e){var x,w,v,u,t,s,r=this,q=r.d,p=r.c
if(q<=p)return C.a([new B.qr(p,r.ki(0,p),C.dg(p,C.cM(d.gby()),null,null))],y.c)
x=B.hI8(p,q,e)
w=D.aD7(x)
v=A.i.fh(p/x-1e-9)
u=A.i.cP(q/x+1e-9)
q=C.a([],y.c)
for(t=v;t<=u;++t){s=C.aiV(t*x,w)
q.push(new B.qr(s,r.ki(0,s),C.dg(s,C.cM(d.gby()),w,null)))}return q},
j4(d){return this.Az(d,5)},
A(d){var x=this
return"DesignLinearScale("+C.am(x.c)+"\u2013"+C.am(x.d)+" \u2192 "+C.am(x.a)+"\u2013"+C.am(x.b)+")"}}
var z=a.updateTypes([]);(function inheritance(){var x=a.inheritMany,w=a.inherit
x(C.W,[B.qr,B.bs_])
w(B.AC,B.bs_)})()
var y={c:C.E("o<qr>")}};
(a=>{a["E2IRFS8ZhX1xdd6qzFa6DLbeJic="]=a.current})($__dart_deferred_initializers__);