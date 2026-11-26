((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var A,C,E,B={
aSe(d,e,f,g,h,i){var x,w,v,u,t,s,r=Math.min(g,f),q=Math.max(g,f)
if(e){r=Math.min(r,0)
q=Math.max(q,0)}x=r===q
if(x&&e&&r===0){w=Math.max(1,i-1)
for(;;){x=B.hOs(0,w,i)
if(!(x<1))break;++w}return new B.C2(0,w,null,h,d)}if(x){--r;++q}for(v=null,u=0;u<10;++u,v=t){t=B.hOs(r,q,i)
if(t===v)break
s=D.ajP(t)
r=A.ajY(Math.floor(r/t)*t,s)
q=A.ajY(Math.ceil(q/t)*t,s)}return new B.C2(r,q,null,h,d)},
hOs(d,e,f){var x,w,v=(e-d)/Math.max(1,f),u=C.i.cL(Math.log(v)/2.302585092994046),t=Math.pow(10,u),s=v/t
if(s>=7.071)x=10
else if(s>=3.162)x=5
else{w=s>=1.414?2:1
x=w}return A.ajY(x*t,Math.max(0,-u))},
bIU:function bIU(){},
C2:function C2(d,e,f,g,h){var _=this
_.c=d
_.d=e
_.e=f
_.a=g
_.b=h}},D
A=c[0]
C=c[2]
E=c[204]
B=a.updateHolder(c[199],B)
D=c[230]
B.bIU.prototype={}
B.C2.prototype={
ku(d,e){var x,w=this,v=w.d,u=w.c
if(v===u)return(w.a+w.b)/2
x=w.a
return x+(e-u)/(v-u)*(w.b-x)},
AZ(d,e){var x,w,v,u,t,s,r=this,q=r.d,p=r.c
if(q<=p)return A.a([new E.kK(p,r.ku(0,p),A.cv(p,A.c3(d.gba()),null,null),D.ajP(p))],y.d)
x=B.hOs(p,q,e)
w=D.ajP(x)
v=C.i.ff(p/x-1e-9)
u=C.i.cL(q/x+1e-9)
q=A.a([],y.d)
for(t=v;t<=u;++t){s=A.ajY(t*x,w)
q.push(new E.kK(s,r.ku(0,s),A.cv(s,A.c3(d.gba()),w,null),w))}return q},
jf(d){return this.AZ(d,5)},
C(d){var x=this
return"RawLinearScale("+A.al(x.c)+"\u2013"+A.al(x.d)+" \u2192 "+A.al(x.a)+"\u2013"+A.al(x.b)+")"}}
var z=a.updateTypes([]);(function inheritance(){var x=a.inherit
x(B.bIU,A.Y)
x(B.C2,B.bIU)})()
var y={d:A.E("o<kK>")}};
(a=>{a["Y343P/eRSJWqBlscWgvhQcbR7L8="]=a.current})($__dart_deferred_initializers__);