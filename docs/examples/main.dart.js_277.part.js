((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var A,C,E,B={
aIx(d,e,f,g,h,i){var x,w,v,u,t,s,r=Math.min(g,f),q=Math.max(g,f)
if(e){r=Math.min(r,0)
q=Math.max(q,0)}x=r===q
if(x&&e&&r===0){w=Math.max(1,i-1)
for(;;){x=B.hJt(0,w,i)
if(!(x<1))break;++w}return new B.AC(0,w,null,h,d)}if(x){--r;++q}for(v=null,u=0;u<10;++u,v=t){t=B.hJt(r,q,i)
if(t===v)break
s=D.aiX(t)
r=A.aj5(Math.floor(r/t)*t,s)
q=A.aj5(Math.ceil(q/t)*t,s)}return new B.AC(r,q,null,h,d)},
hJt(d,e,f){var x,w,v=(e-d)/Math.max(1,f),u=C.i.cI(Math.log(v)/2.302585092994046),t=Math.pow(10,u),s=v/t
if(s>=7.071)x=10
else if(s>=3.162)x=5
else{w=s>=1.414?2:1
x=w}return A.aj5(x*t,Math.max(0,-u))},
bsE:function bsE(){},
AC:function AC(d,e,f,g,h){var _=this
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
B.bsE.prototype={}
B.AC.prototype={
kn(d,e){var x,w=this,v=w.d,u=w.c
if(v===u)return(w.a+w.b)/2
x=w.a
return x+(e-u)/(v-u)*(w.b-x)},
AB(d,e){var x,w,v,u,t,s,r=this,q=r.d,p=r.c
if(q<=p)return A.a([new E.ko(p,r.kn(0,p),A.dk(p,A.cN(d.gby()),null,null),D.aiX(p))],y.c)
x=B.hJt(p,q,e)
w=D.aiX(x)
v=C.i.fh(p/x-1e-9)
u=C.i.cI(q/x+1e-9)
q=A.a([],y.c)
for(t=v;t<=u;++t){s=A.aj5(t*x,w)
q.push(new E.ko(s,r.kn(0,s),A.dk(s,A.cN(d.gby()),w,null),w))}return q},
j7(d){return this.AB(d,5)},
A(d){var x=this
return"DesignLinearScale("+A.am(x.c)+"\u2013"+A.am(x.d)+" \u2192 "+A.am(x.a)+"\u2013"+A.am(x.b)+")"}}
var z=a.updateTypes([]);(function inheritance(){var x=a.inherit
x(B.bsE,A.W)
x(B.AC,B.bsE)})()
var y={c:A.F("o<ko>")}};
(a=>{a["SwdizeThiff270mqyKUFFxTUlMY="]=a.current})($__dart_deferred_initializers__);