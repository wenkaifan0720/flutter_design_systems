((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,D,B,A={k7:function k7(){},
h_l(d){d.q(y.b)
return B.G},
Fc:function Fc(d,e){this.a=d
this.b=e},
aCg:function aCg(d,e){this.a=d
this.b=e},
hg:function hg(d,e,f,g,h,i,j){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.f=h
_.r=i
_.w=j},
DK:function DK(d){this.a=d
this.b=null},
cnq:function cnq(d){this.a=d},
cnr:function cnr(d,e){this.a=d
this.b=e},
bSN:function bSN(){},
hn_(d,e,f,g){var x,w,v,u,t=g==null,s=t?null:g.r
if(s==null)s=B.G
x=t?null:g.f
if(x==null)x=B.G
w=Math.max(s.a,x.a)+f.a+d
v=Math.max(s.b,x.b)+f.b+d
t=Math.max(s.c,x.c)
u=Math.max(s.d,x.d)
return new D.B(w,v,Math.max(w,e.a-(t+f.c+d)),Math.max(v,e.b-(u+f.d+d)))},
hn1(d,e,f,g){var x=f.a,w=f.c,v=A.h2Y(d,e,x,w,g),u=A.h2Y(d,e,x.gaBO(),w,g)
return v<f.f&&u>v?x.gaBO():x},
h2Y(d,e,f,g,h){var x,w=h===B.H
switch(f.a){case 0:x=e.d-d.d-g
break
case 1:x=d.b-e.b-g
break
case 2:x=w?d.a-e.a-g:e.c-d.c-g
break
case 3:x=w?e.c-d.c-g:d.a-e.a-g
break
default:x=null}return J.D5(x,0,1/0)},
hn0(d,e,f,g,h){var x=A.h2Y(d,e,f,g,h)
return f===C.cF||f===C.dQ?new D.H(e.c-e.a,x):new D.H(x,e.d-e.b)},
hRZ(d,e,f,g,h,i,j,a0){var x,w,v,u,t,s,r,q=a0===B.H,p=e.c,o=e.a,n=e.d,m=e.b,l=new D.H(p-o,n-m).i(0,B.t),k=i===C.cF
if(k||i===C.dQ){x=k?n+h:m-h-j.b
w=q?o:p-j.a
if(q)o=p-j.a
switch(d.a){case 0:p=w
break
case 1:p=e.gbH().a-j.a/2
break
case 2:p=o
break
default:p=null}if((l||g)&&d!==C.mW){n=f.a
v=p>=n&&p+j.a<=f.c
m=p===w?o:w
u=!v&&m>=n&&m+j.a<=f.c?m:p}else u=p}else{u=i===C.RS===q?o-h-j.a:p+h
switch(d.a){case 0:p=m
break
case 1:p=e.gbH().b-j.b/2
break
case 2:p=n-j.b
break
default:p=null}if(l&&d!==C.mW){k=f.b
v=p>=k&&p+j.b<=f.d
if(d===C.dI)m=n-j.b
x=!v&&m>=k&&m+j.b<=f.d?m:p}else x=p}t=f.c-j.a
s=f.d-j.b
p=f.a
if(t<p)u=q?p:t
else u=B.h.I(u,p,t)
r=f.b
return new D.r(u,s<r?r:B.h.I(x,r,s))},
b6r:function b6r(d,e,f,g,h,i,j){var _=this
_.b=d
_.c=e
_.d=f
_.e=g
_.f=h
_.r=i
_.w=j}},C
J=c[1]
D=c[0]
B=c[2]
A=a.updateHolder(c[206],A)
C=c[246]
A.k7.prototype={
rX(d,e){return null},
v(d){return"PopEntry canPop: false, onPopInvoked: "+D.a7(this.gbt6())}}
A.Fc.prototype={
V(){return"RawPopoverSide."+this.b},
gaBO(){switch(this.a){case 0:var x=C.dQ
break
case 1:x=C.cF
break
case 2:x=C.IQ
break
case 3:x=C.RS
break
default:x=null}return x}}
A.aCg.prototype={
V(){return"RawPopoverAlign."+this.b}}
A.hg.prototype={
i(d,e){var x=this
if(e==null)return!1
return e instanceof A.hg&&e.a===x.a&&e.b===x.b&&e.c===x.c&&e.d===x.d&&e.f===x.f&&e.r===x.r&&e.w===x.w},
gU(d){var x=this
return D.aF(x.a,x.b,x.c,x.d,!0,x.f,x.r,x.w,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a)}}
A.DK.prototype={
lD(d){var x=this
if(d==x.b)return
x.pP()
if(d==null)return
d.aCC(x)
x.b=d
$.fXQ.push(x)},
pP(){var x=this,w=x.b
if(w!=null)w.abn(x)
x.b=null
B.c.ad($.fXQ,x)},
gSp(){return C.axe},
rX(d,e){var x=this.b
if(d||x==null)return
if(B.c.a9k($.fXQ,new A.cnq(x))!==this)return
D.ib(new A.cnr(this,x))}}
A.bSN.prototype={
gt(){return!1},
af(d){},
W(d){},
$ia5:1}
A.b6r.prototype={
le(d){var x,w,v,u,t=this,s=t.e
if(s.r){x=t.d
x=x===C.cF||x===C.dQ}else x=!1
if(!x){s=t.r
return new D.A(0,s.a,0,s.b)}x=t.b
x=x.c-x.a
w=t.r
v=w.a
u=B.h.I(x,0,v)
return new D.A(u,B.h.I(Math.max(x,s.w),u,v),0,w.b)},
kc(d,e){var x,w,v,u=this,t=u.e
t=t.r&&t.b===C.dI
x=u.e
w=A.hRZ(x.b,u.b,u.c,t,x.c,u.d,e,u.f)
x=u.w
if(x!=null){t=w.a
v=w.b
x.st(new D.B(t,v,t+e.a,v+e.b))}return w},
jq(d){var x=this
return!x.b.i(0,d.b)||!x.c.i(0,d.c)||x.d!==d.d||!x.e.i(0,d.e)||x.f!==d.f||!x.r.i(0,d.r)||x.w!=d.w}}
var z=a.updateTypes(["~(w,T?)","w(DK)"])
A.cnq.prototype={
$1(d){return d.b===this.a},
$S:z+1}
A.cnr.prototype={
$0(){var x=this.a
if(x.b===this.b)x.a.$0()},
$S:0};(function installTearOffs(){var x=a._instance_2u
x(A.DK.prototype,"gbt6","rX",0)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(D.T,[A.k7,A.hg,A.bSN])
x(D.ef,[A.Fc,A.aCg])
w(A.DK,A.k7)
w(A.cnq,D.cq)
w(A.cnr,D.db)
w(A.b6r,D.tG)})()
D.c_(b.typeUniverse,JSON.parse('{"hCj":{"aP":[],"aW":[],"b":[]},"DK":{"k7":["T?"]},"bSN":{"a5":[]}}'))
D.ki(b.typeUniverse,JSON.parse('{"k7":1}'))
var y={b:D.G("hCj")};(function constants(){C.axe=new A.bSN()
C.dI=new A.aCg(0,"start")
C.mW=new A.aCg(1,"center")
C.zZ=new A.aCg(2,"end")
C.cF=new A.Fc(0,"below")
C.dQ=new A.Fc(1,"above")
C.IQ=new A.Fc(3,"end")
C.RS=new A.Fc(2,"start")})();(function staticFields(){$.fXQ=D.a([],D.G("m<DK>"))})()};
(a=>{a["Pj6/CB4yCJK+kZcQUkUASV0gc/4="]=a.current})($__dart_deferred_initializers__);