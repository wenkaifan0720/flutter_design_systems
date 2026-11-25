((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var A,C,E,B={
aRS(d,e,f,g,h,i){var x,w,v,u,t,s,r=Math.min(g,f),q=Math.max(g,f)
if(e){r=Math.min(r,0)
q=Math.max(q,0)}x=r===q
if(x&&e&&r===0){w=Math.max(1,i-1)
for(;;){x=B.hNv(0,w,i)
if(!(x<1))break;++w}return new B.BL(0,w,null,h,d)}if(x){--r;++q}for(v=null,u=0;u<10;++u,v=t){t=B.hNv(r,q,i)
if(t===v)break
s=D.ajs(t)
r=A.ajB(Math.floor(r/t)*t,s)
q=A.ajB(Math.ceil(q/t)*t,s)}return new B.BL(r,q,null,h,d)},
hNv(d,e,f){var x,w,v=(e-d)/Math.max(1,f),u=C.i.cM(Math.log(v)/2.302585092994046),t=Math.pow(10,u),s=v/t
if(s>=7.071)x=10
else if(s>=3.162)x=5
else{w=s>=1.414?2:1
x=w}return A.ajB(x*t,Math.max(0,-u))},
bIg:function bIg(){},
BL:function BL(d,e,f,g,h){var _=this
_.c=d
_.d=e
_.e=f
_.a=g
_.b=h}},D
A=c[0]
C=c[2]
E=c[197]
B=a.updateHolder(c[192],B)
D=c[224]
B.bIg.prototype={}
B.BL.prototype={
kt(d,e){var x,w=this,v=w.d,u=w.c
if(v===u)return(w.a+w.b)/2
x=w.a
return x+(e-u)/(v-u)*(w.b-x)},
B1(d,e){var x,w,v,u,t,s,r=this,q=r.d,p=r.c
if(q<=p)return A.a([new E.kG(p,r.kt(0,p),A.cv(p,A.c4(d.gba()),null,null),D.ajs(p))],y.d)
x=B.hNv(p,q,e)
w=D.ajs(x)
v=C.i.fn(p/x-1e-9)
u=C.i.cM(q/x+1e-9)
q=A.a([],y.d)
for(t=v;t<=u;++t){s=A.ajB(t*x,w)
q.push(new E.kG(s,r.kt(0,s),A.cv(s,A.c4(d.gba()),w,null),w))}return q},
jf(d){return this.B1(d,5)},
B(d){var x=this
return"RawLinearScale("+A.an(x.c)+"\u2013"+A.an(x.d)+" \u2192 "+A.an(x.a)+"\u2013"+A.an(x.b)+")"}}
var z=a.updateTypes([]);(function inheritance(){var x=a.inherit
x(B.bIg,A.Y)
x(B.BL,B.bIg)})()
var y={d:A.G("o<kG>")}};
(a=>{a["AY7vc/LCnn2eCRjIIMnYriZeDME="]=a.current})($__dart_deferred_initializers__);