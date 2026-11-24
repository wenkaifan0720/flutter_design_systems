((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var A,C,E,B={
aRz(d,e,f,g,h,i){var x,w,v,u,t,s,r=Math.min(g,f),q=Math.max(g,f)
if(e){r=Math.min(r,0)
q=Math.max(q,0)}x=r===q
if(x&&e&&r===0){w=Math.max(1,i-1)
for(;;){x=B.hLk(0,w,i)
if(!(x<1))break;++w}return new B.BG(0,w,null,h,d)}if(x){--r;++q}for(v=null,u=0;u<10;++u,v=t){t=B.hLk(r,q,i)
if(t===v)break
s=D.aj6(t)
r=A.ajf(Math.floor(r/t)*t,s)
q=A.ajf(Math.ceil(q/t)*t,s)}return new B.BG(r,q,null,h,d)},
hLk(d,e,f){var x,w,v=(e-d)/Math.max(1,f),u=C.i.cL(Math.log(v)/2.302585092994046),t=Math.pow(10,u),s=v/t
if(s>=7.071)x=10
else if(s>=3.162)x=5
else{w=s>=1.414?2:1
x=w}return A.ajf(x*t,Math.max(0,-u))},
bHT:function bHT(){},
BG:function BG(d,e,f,g,h){var _=this
_.c=d
_.d=e
_.e=f
_.a=g
_.b=h}},D
A=c[0]
C=c[2]
E=c[189]
B=a.updateHolder(c[183],B)
D=c[216]
B.bHT.prototype={}
B.BG.prototype={
kr(d,e){var x,w=this,v=w.d,u=w.c
if(v===u)return(w.a+w.b)/2
x=w.a
return x+(e-u)/(v-u)*(w.b-x)},
AQ(d,e){var x,w,v,u,t,s,r=this,q=r.d,p=r.c
if(q<=p)return A.a([new E.kC(p,r.kr(0,p),A.d8(p,A.cH(d.gbu()),null,null),D.aj6(p))],y.d)
x=B.hLk(p,q,e)
w=D.aj6(x)
v=C.i.fl(p/x-1e-9)
u=C.i.cL(q/x+1e-9)
q=A.a([],y.d)
for(t=v;t<=u;++t){s=A.ajf(t*x,w)
q.push(new E.kC(s,r.kr(0,s),A.d8(s,A.cH(d.gbu()),w,null),w))}return q},
jc(d){return this.AQ(d,5)},
B(d){var x=this
return"RawLinearScale("+A.am(x.c)+"\u2013"+A.am(x.d)+" \u2192 "+A.am(x.a)+"\u2013"+A.am(x.b)+")"}}
var z=a.updateTypes([]);(function inheritance(){var x=a.inherit
x(B.bHT,A.Y)
x(B.BG,B.bHT)})()
var y={d:A.G("o<kC>")}};
(a=>{a["OU8fYhfqpPIn9hGPZA8viYbEwpg="]=a.current})($__dart_deferred_initializers__);