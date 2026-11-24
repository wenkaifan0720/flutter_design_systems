((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var A,C,E,B={
aRx(d,e,f,g,h,i){var x,w,v,u,t,s,r=Math.min(g,f),q=Math.max(g,f)
if(e){r=Math.min(r,0)
q=Math.max(q,0)}x=r===q
if(x&&e&&r===0){w=Math.max(1,i-1)
for(;;){x=B.hKD(0,w,i)
if(!(x<1))break;++w}return new B.BE(0,w,null,h,d)}if(x){--r;++q}for(v=null,u=0;u<10;++u,v=t){t=B.hKD(r,q,i)
if(t===v)break
s=D.aj3(t)
r=A.ajc(Math.floor(r/t)*t,s)
q=A.ajc(Math.ceil(q/t)*t,s)}return new B.BE(r,q,null,h,d)},
hKD(d,e,f){var x,w,v=(e-d)/Math.max(1,f),u=C.i.cJ(Math.log(v)/2.302585092994046),t=Math.pow(10,u),s=v/t
if(s>=7.071)x=10
else if(s>=3.162)x=5
else{w=s>=1.414?2:1
x=w}return A.ajc(x*t,Math.max(0,-u))},
bHI:function bHI(){},
BE:function BE(d,e,f,g,h){var _=this
_.c=d
_.d=e
_.e=f
_.a=g
_.b=h}},D
A=c[0]
C=c[2]
E=c[188]
B=a.updateHolder(c[183],B)
D=c[215]
B.bHI.prototype={}
B.BE.prototype={
kp(d,e){var x,w=this,v=w.d,u=w.c
if(v===u)return(w.a+w.b)/2
x=w.a
return x+(e-u)/(v-u)*(w.b-x)},
AD(d,e){var x,w,v,u,t,s,r=this,q=r.d,p=r.c
if(q<=p)return A.a([new E.kz(p,r.kp(0,p),A.d7(p,A.cG(d.gbt()),null,null),D.aj3(p))],y.d)
x=B.hKD(p,q,e)
w=D.aj3(x)
v=C.i.fj(p/x-1e-9)
u=C.i.cJ(q/x+1e-9)
q=A.a([],y.d)
for(t=v;t<=u;++t){s=A.ajc(t*x,w)
q.push(new E.kz(s,r.kp(0,s),A.d7(s,A.cG(d.gbt()),w,null),w))}return q},
ja(d){return this.AD(d,5)},
A(d){var x=this
return"RawLinearScale("+A.an(x.c)+"\u2013"+A.an(x.d)+" \u2192 "+A.an(x.a)+"\u2013"+A.an(x.b)+")"}}
var z=a.updateTypes([]);(function inheritance(){var x=a.inherit
x(B.bHI,A.X)
x(B.BE,B.bHI)})()
var y={d:A.F("o<kz>")}};
(a=>{a["KuR6bhgnY7KP5WMY9q6CY1UfsKI="]=a.current})($__dart_deferred_initializers__);