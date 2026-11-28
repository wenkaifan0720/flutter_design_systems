((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var A,C,E,B={
aUb(d,e,f,g,h,i){var x,w,v,u,t,s,r=Math.min(g,f),q=Math.max(g,f)
if(e){r=Math.min(r,0)
q=Math.max(q,0)}x=r===q
if(x&&e&&r===0){w=Math.max(1,i-1)
for(;;){x=B.hVS(0,w,i)
if(!(x<1))break;++w}return new B.CE(0,w,null,h,d)}if(x){--r;++q}for(v=null,u=0;u<10;++u,v=t){t=B.hVS(r,q,i)
if(t===v)break
s=D.al5(t)
r=A.alf(Math.floor(r/t)*t,s)
q=A.alf(Math.ceil(q/t)*t,s)}return new B.CE(r,q,null,h,d)},
hVS(d,e,f){var x,w,v=(e-d)/Math.max(1,f),u=C.i.cJ(Math.log(v)/2.302585092994046),t=Math.pow(10,u),s=v/t
if(s>=7.071)x=10
else if(s>=3.162)x=5
else{w=s>=1.414?2:1
x=w}return A.alf(x*t,Math.max(0,-u))},
bLk:function bLk(){},
CE:function CE(d,e,f,g,h){var _=this
_.c=d
_.d=e
_.e=f
_.a=g
_.b=h}},D
A=c[0]
C=c[2]
E=c[204]
B=a.updateHolder(c[199],B)
D=c[235]
B.bLk.prototype={}
B.CE.prototype={
kC(d,e){var x,w=this,v=w.d,u=w.c
if(v===u)return(w.a+w.b)/2
x=w.a
return x+(e-u)/(v-u)*(w.b-x)},
B8(d,e){var x,w,v,u,t,s,r=this,q=r.d,p=r.c
if(q<=p)return A.a([new E.kY(p,r.kC(0,p),A.cD(p,A.c9(d.gbb()),null,null),D.al5(p))],y.d)
x=B.hVS(p,q,e)
w=D.al5(x)
v=C.i.fj(p/x-1e-9)
u=C.i.cJ(q/x+1e-9)
q=A.a([],y.d)
for(t=v;t<=u;++t){s=A.alf(t*x,w)
q.push(new E.kY(s,r.kC(0,s),A.cD(s,A.c9(d.gbb()),w,null),w))}return q},
ji(d){return this.B8(d,5)},
D(d){var x=this
return"RawLinearScale("+A.am(x.c)+"\u2013"+A.am(x.d)+" \u2192 "+A.am(x.a)+"\u2013"+A.am(x.b)+")"}}
var z=a.updateTypes([]);(function inheritance(){var x=a.inherit
x(B.bLk,A.a_)
x(B.CE,B.bLk)})()
var y={d:A.G("o<kY>")}};
(a=>{a["KHE/iPGz8ilWkMjCFjdnNJB/0VM="]=a.current})($__dart_deferred_initializers__);