((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var A,C,E,B={
aRO(d,e,f,g,h,i){var x,w,v,u,t,s,r=Math.min(g,f),q=Math.max(g,f)
if(e){r=Math.min(r,0)
q=Math.max(q,0)}x=r===q
if(x&&e&&r===0){w=Math.max(1,i-1)
for(;;){x=B.hMx(0,w,i)
if(!(x<1))break;++w}return new B.BH(0,w,null,h,d)}if(x){--r;++q}for(v=null,u=0;u<10;++u,v=t){t=B.hMx(r,q,i)
if(t===v)break
s=D.aji(t)
r=A.ajr(Math.floor(r/t)*t,s)
q=A.ajr(Math.ceil(q/t)*t,s)}return new B.BH(r,q,null,h,d)},
hMx(d,e,f){var x,w,v=(e-d)/Math.max(1,f),u=C.i.cM(Math.log(v)/2.302585092994046),t=Math.pow(10,u),s=v/t
if(s>=7.071)x=10
else if(s>=3.162)x=5
else{w=s>=1.414?2:1
x=w}return A.ajr(x*t,Math.max(0,-u))},
bI5:function bI5(){},
BH:function BH(d,e,f,g,h){var _=this
_.c=d
_.d=e
_.e=f
_.a=g
_.b=h}},D
A=c[0]
C=c[2]
E=c[191]
B=a.updateHolder(c[185],B)
D=c[218]
B.bI5.prototype={}
B.BH.prototype={
ks(d,e){var x,w=this,v=w.d,u=w.c
if(v===u)return(w.a+w.b)/2
x=w.a
return x+(e-u)/(v-u)*(w.b-x)},
AX(d,e){var x,w,v,u,t,s,r=this,q=r.d,p=r.c
if(q<=p)return A.a([new E.kE(p,r.ks(0,p),A.cC(p,A.cc(d.gbc()),null,null),D.aji(p))],y.d)
x=B.hMx(p,q,e)
w=D.aji(x)
v=C.i.fn(p/x-1e-9)
u=C.i.cM(q/x+1e-9)
q=A.a([],y.d)
for(t=v;t<=u;++t){s=A.ajr(t*x,w)
q.push(new E.kE(s,r.ks(0,s),A.cC(s,A.cc(d.gbc()),w,null),w))}return q},
je(d){return this.AX(d,5)},
B(d){var x=this
return"RawLinearScale("+A.an(x.c)+"\u2013"+A.an(x.d)+" \u2192 "+A.an(x.a)+"\u2013"+A.an(x.b)+")"}}
var z=a.updateTypes([]);(function inheritance(){var x=a.inherit
x(B.bI5,A.Y)
x(B.BH,B.bI5)})()
var y={d:A.G("o<kE>")}};
(a=>{a["B+WmRmtImaXRG0k+Id63WLzmiKg="]=a.current})($__dart_deferred_initializers__);