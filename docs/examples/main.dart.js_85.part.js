((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,D,B,A={jV:function jV(){},
igJ(d){d.t(y.b)
return B.B},
J0:function J0(d,e){this.a=d
this.b=e},
aRg:function aRg(d,e){this.a=d
this.b=e},
h7:function h7(d,e,f,g,h,i,j){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.f=h
_.r=i
_.w=j},
Hq:function Hq(d){this.a=d
this.b=null},
cWT:function cWT(d){this.a=d},
cWU:function cWU(d,e){this.a=d
this.b=e},
ck7:function ck7(){},
iI_(d,e,f,g){var x,w,v,u,t=g==null,s=t?null:g.r
if(s==null)s=B.B
x=t?null:g.f
if(x==null)x=B.B
w=Math.max(s.a,x.a)+f.a+d
v=Math.max(s.b,x.b)+f.b+d
t=Math.max(s.c,x.c)
u=Math.max(s.d,x.d)
return new D.C(w,v,Math.max(w,e.a-(t+f.c+d)),Math.max(v,e.b-(u+f.d+d)))},
ikU(d,e,f,g,h){var x=f.a,w=f.c,v=A.cGq(d,e,x,w,g),u=A.cGq(d,e,x.ga3o(),w,g),t=f.f
return v<(h==null?t:Math.min(h,t))&&u>v?x.ga3o():x},
cGq(d,e,f,g,h){var x,w=h===B.O
switch(f.a){case 0:x=e.d-d.d-g
break
case 1:x=d.b-e.b-g
break
case 2:x=w?d.a-e.a-g:e.c-d.c-g
break
case 3:x=w?e.c-d.c-g:d.a-e.a-g
break
default:x=null}return J.y4(x,0,1/0)},
ikT(d,e,f,g,h){var x=A.cGq(d,e,f,g,h)
return f===C.cm||f===C.dj?new D.H(e.c-e.a,x):new D.H(x,e.d-e.b)},
jfW(d,e,f,g,h,i,j,a0){var x,w,v,u,t,s,r,q=a0===B.O,p=e.c,o=e.a,n=e.d,m=e.b,l=new D.H(p-o,n-m).i(0,B.z),k=i===C.cm
if(k||i===C.dj){x=k?n+h:m-h-j.b
w=q?o:p-j.a
if(q)o=p-j.a
switch(d.a){case 0:p=w
break
case 1:p=e.gbY().a-j.a/2
break
case 2:p=o
break
default:p=null}if((l||g)&&d!==C.ol){n=f.a
v=p>=n&&p+j.a<=f.c
m=p===w?o:w
u=!v&&m>=n&&m+j.a<=f.c?m:p}else u=p}else{u=i===C.Xk===q?o-h-j.a:p+h
switch(d.a){case 0:p=m
break
case 1:p=e.gbY().b-j.b/2
break
case 2:p=n-j.b
break
default:p=null}if(l&&d!==C.ol){k=f.b
v=p>=k&&p+j.b<=f.d
if(d===C.du)m=n-j.b
x=!v&&m>=k&&m+j.b<=f.d?m:p}else x=p}t=f.c-j.a
s=f.d-j.b
p=f.a
if(t<p)u=q?p:t
else u=B.i.I(u,p,t)
r=f.b
return new D.t(u,s<r?r:B.i.I(x,r,s))},
aIg:function aIg(d,e,f,g,h,i,j){var _=this
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
A=a.updateHolder(c[248],A)
C=c[308]
A.jV.prototype={
v4(d,e){return null},
A(d){return"PopEntry canPop: false, onPopInvoked: "+D.am(this.gbXj())}}
A.J0.prototype={
X(){return"RawPopoverSide."+this.b},
ga3o(){switch(this.a){case 0:var x=C.dj
break
case 1:x=C.cm
break
case 2:x=C.Na
break
case 3:x=C.Xk
break
default:x=null}return x}}
A.aRg.prototype={
X(){return"RawPopoverAlign."+this.b}}
A.h7.prototype={
i(d,e){var x=this
if(e==null)return!1
return e instanceof A.h7&&e.a===x.a&&e.b===x.b&&e.c===x.c&&e.d===x.d&&e.f===x.f&&e.r===x.r&&e.w===x.w},
ga2(d){var x=this
return D.aL(x.a,x.b,x.c,x.d,!0,x.f,x.r,x.w,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a)}}
A.Hq.prototype={
oB(d){var x=this
if(d==x.b)return
x.nU()
if(d==null)return
d.aTM(x)
x.b=d
$.idG.push(x)},
nU(){var x=this,w=x.b
if(w!=null)w.anG(x)
x.b=null
B.c.ak($.idG,x)},
ga07(){return C.aJB},
v4(d,e){var x=this.b
if(d||x==null)return
if(B.c.alm($.idG,new A.cWT(x))!==this)return
D.iJ(new A.cWU(this,x))}}
A.ck7.prototype={
gq(){return!1},
ad(d){},
S(d){},
$ia7:1}
A.aIg.prototype={
lG(d){var x,w,v,u,t=this,s=t.e
if(s.r){x=t.d
x=x===C.cm||x===C.dj}else x=!1
if(!x){s=t.r
return new D.A(0,s.a,0,s.b)}x=t.b
x=x.c-x.a
w=t.r
v=w.a
u=B.i.I(x,0,v)
return new D.A(u,B.i.I(Math.max(x,s.w),u,v),0,w.b)},
l7(d,e){var x,w,v,u=this,t=u.e
t=t.r&&t.b===C.du
x=u.e
w=A.jfW(x.b,u.b,u.c,t,x.c,u.d,e,u.f)
x=u.w
if(x!=null){t=w.a
v=w.b
x.sq(new D.C(t,v,t+e.a,v+e.b))}return w},
j7(d){var x=this
return!x.b.i(0,d.b)||!x.c.i(0,d.c)||x.d!==d.d||!x.e.i(0,d.e)||x.f!==d.f||!x.r.i(0,d.r)||x.w!=d.w}}
var z=a.updateTypes(["~(w,W?)","w(Hq)"])
A.cWT.prototype={
$1(d){return d.b===this.a},
$S:z+1}
A.cWU.prototype={
$0(){var x=this.a
if(x.b===this.b)x.a.$0()},
$S:0};(function installTearOffs(){var x=a._instance_2u
x(A.Hq.prototype,"gbXj","v4",0)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(D.W,[A.jV,A.h7,A.ck7])
x(D.eg,[A.J0,A.aRg])
w(A.Hq,A.jV)
w(A.cWT,D.cj)
w(A.cWU,D.cU)
w(A.aIg,D.rw)})()
D.bM(b.typeUniverse,JSON.parse('{"iZ0":{"aO":[],"aU":[],"b":[]},"Hq":{"jV":["W?"]},"ck7":{"a7":[]}}'))
D.jn(b.typeUniverse,JSON.parse('{"jV":1}'))
var y={b:D.E("iZ0")};(function constants(){C.aJB=new A.ck7()
C.du=new A.aRg(0,"start")
C.ol=new A.aRg(1,"center")
C.vW=new A.aRg(2,"end")
C.cm=new A.J0(0,"below")
C.dj=new A.J0(1,"above")
C.Na=new A.J0(3,"end")
C.Xk=new A.J0(2,"start")})();(function staticFields(){$.idG=D.a([],D.E("o<Hq>"))})()};
(a=>{a["FBTomY1Y6LcO+w6UPk5blGnQTpQ="]=a.current})($__dart_deferred_initializers__);