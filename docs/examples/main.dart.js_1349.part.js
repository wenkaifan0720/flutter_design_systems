((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,H,A={
zj(d,e,f,g,h,i){var x=B.aI(h,i),w=g==null?new A.dB0(i):g
return new A.vY(d,e,w,x,f,C.ex,B.az(y.K),$.T(),i.k("vY<0>"))},
j1l(d,e){return J.ajq(d,e)},
uv(d,e,f,g,h,i,j,k,l){return new A.asg(e,f,d,i,g,j,h,k,null,l.k("asg<0>"))},
cQ:function cQ(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.$ti=h},
aRt:function aRt(d,e){this.a=d
this.b=e},
vY:function vY(d,e,f,g,h,i,j,k,l){var _=this
_.a=d
_.b=e
_.d=f
_.e=g
_.f=h
_.r=0
_.w=""
_.x=null
_.y=i
_.z=j
_.as=_.Q=null
_.M$=0
_.O$=k
_.ar$=_.av$=0
_.$ti=l},
dB0:function dB0(d){this.a=d},
dB3:function dB3(d,e){this.a=d
this.b=e},
dB1:function dB1(d,e){this.a=d
this.b=e},
dB2:function dB2(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
py:function py(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
asg:function asg(d,e,f,g,h,i,j,k,l,m){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.r=h
_.w=i
_.x=j
_.y=k
_.a=l
_.$ti=m},
Q8:function Q8(){},
axz:function axz(d,e){var _=this
_.d=d
_.e=0
_.c=_.a=null
_.$ti=e},
ez6:function ez6(){},
ez9:function ez9(d,e){this.a=d
this.b=e},
eza:function eza(d,e){this.a=d
this.b=e},
ez8:function ez8(d,e){this.a=d
this.b=e},
ez7:function ez7(d,e,f){this.a=d
this.b=e
this.c=f},
ezd:function ezd(d,e,f){this.a=d
this.b=e
this.c=f},
ezc:function ezc(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
ezb:function ezb(d,e,f){this.a=d
this.b=e
this.c=f},
eze:function eze(d,e){this.a=d
this.b=e},
uc(){return b.G.document.createElement("input")}},D,E,I,F,G,K
J=c[1]
B=c[0]
C=c[2]
H=c[355]
A=a.updateHolder(c[154],A)
D=c[322]
E=c[323]
I=c[380]
F=c[252]
G=c[266]
K=c[274]
A.cQ.prototype={}
A.aRt.prototype={
Z(){return"RawDataTableSelection."+this.b}}
A.vY.prototype={
sMc(d){var x,w,v,u,t=this,s=B.aI(d,B.Z(t).c)
t.e=s
x=B.az(y.K)
for(w=s.length,v=t.d,u=0;u<s.length;s.length===w||(0,B.E)(s),++u)x.H(0,v.$1(s[u]))
t.z.EC(x.gn6(x),!1)
t.a99(!0)},
suq(d){if(d===this.w)return
this.w=d
this.Ws()},
it(d,e){var x=this
if(C.c.nd(x.a,new A.dB3(x,e)).c==null)return
if(x.x!==e){x.x=e
x.y=C.ex}else if(x.y===C.ex)x.y=H.pw
else{x.x=null
x.y=C.ex}x.Ws()},
gya(){var x,w,v,u,t,s,r,q,p,o,n,m=this,l=m.as
if(l!=null)return l
x=m.b
w=B.Z(m)
v=B.a([],w.k("o<1>"))
for(u=m.e,t=u.length,s=x!=null,r=0;r<u.length;u.length===t||(0,B.E)(u),++r){q=u[r]
p=m.w
if(p.length===0||!s||x.$2(q,p))v.push(q)}o=m.x
if(o!=null){u=C.c.nd(m.a,new A.dB1(m,o)).c
u.toString
t=B.ao(y.K,y.S)
for(s=m.d,n=0;n<v.length;++n)t.P(0,s.$1(v[n]),n)
C.c.it(v,new A.dB2(m,u,m.y===C.ex?1:-1,t))}return m.as=B.q5(v,w.c)},
gkW(){var x=this.f
if(x==null||this.gya().length===0)return 1
return C.o.jg(this.gya().length+x-1,x)},
uu(d){var x=this,w=C.o.J(d,0,x.gkW()-1)
if(w===x.r)return
x.r=w
x.V()},
gpc(){var x,w=this,v=w.f
if(v==null)return w.gya()
x=w.r*v
if(x>=w.gya().length)return I.jd
return C.c.iW(w.gya(),x,C.o.J(x+v,0,w.gya().length))},
bWh(d){return this.z.m(0,this.d.$1(d))},
c1c(d,e){var x,w,v,u,t,s,r,q=this,p=q.d,o=p.$1(d),n=q.Q
if(e&&n!=null){x=B.a([],y.f)
for(w=q.gya(),v=w.length,u=0;u<v;++u)x.push(p.$1(w[u]))
t=C.c.fG(x,n)
s=C.c.fG(x,o)
if(t>=0&&s>=0){p=t<s
r=p?t:s
q.z.F(0,C.c.iW(x,r,(p?s:t)+1))
q.V()
return}}p=q.z
if(!p.ai(0,o))p.H(0,o)
q.Q=o
q.V()},
gpP(){var x=this.gpc(),w=new B.aR(x,this.ga3h(),B.aE(x).k("aR<1>")).gaa(0)
if(w===0)return D.Xk
return w===x.length?D.mi:D.Dh},
yE(){var x,w,v,u,t=this,s=B.a([],y.f)
for(x=t.gpc(),w=x.length,v=t.d,u=0;u<x.length;x.length===w||(0,B.E)(x),++u)s.push(v.$1(x[u]))
x=t.z
if(t.gpP()===D.mi)x.ur(s)
else x.F(0,s)
t.V()},
a99(d){var x=this
x.as=null
x.r=d?C.o.J(x.r,0,x.gkW()-1):0
x.V()},
Ws(){return this.a99(!1)}}
A.py.prototype={}
A.asg.prototype={
p(){return new A.axz(B.a([],y.J),this.$ti.k("axz<1>"))}}
A.Q8.prototype={}
A.axz.prototype={
au(){this.aB()
this.a.c.ae(this.ga98())},
af(d){var x,w,v=this
v.an(d)
x=d.c
if(x!==v.a.c){w=v.ga98()
x.T(w)
v.a.c.ae(w)}},
l(){var x,w,v,u,t,s=this
s.a.c.T(s.ga98())
for(x=s.d,w=x.length,v=0;v<x.length;x.length===w||(0,B.E)(x),++v){u=x[v]
t=u.ax
if(t!=null)t.am()
u.cZ()}s.L()},
Ws(){return this.n(new A.ez6())},
bHB(d){var x,w,v,u,t=this
for(x=t.d;w=x.length,w<d;)x.push(B.bH(!0,"RawDataTable row "+w,!0,!0,null,null,!1))
while(x.length>d){w=x.pop()
v=w.ax
if(v!=null)v.am()
w.cZ()}if(t.e>=d)t.e=d===0?0:d-1
for(u=0;u<x.length;++u){w=x[u]
v=u!==t.e
if(v!==w.a){w.a=v
v=w.w
if(v!=null){v.vV()
v.d.H(0,w)}}}},
Wt(d){var x,w=this.d,v=w.length
if(v===0)return
x=C.o.J(d,0,v-1)
this.n(new A.ez9(this,x))
w[x].bD()},
awe(d,e,f){var x,w,v
this.n(new A.eza(this,e))
x=this.a
if(x.w){x=x.c
if(f==null){w=$.es.fp$
w===$&&B.m()
w=w.a
v=B.Z(w).k("bd<2>")
w=new B.bd(w,v).m(0,C.jN)||new B.bd(w,v).m(0,C.kh)}else w=f
x.c1c(d,w)}},
awd(d,e){return this.awe(d,e,null)},
bdz(d,e){var x,w,v,u,t=this
if(!(e instanceof B.dt)&&!(e instanceof B.fI))return C.ae
x=e.b
w=t.a.c.gpc()
if(x.i(0,C.bl))t.Wt(t.e+1)
else if(x.i(0,C.bB))t.Wt(t.e-1)
else if(x.i(0,C.cu))t.Wt(0)
else if(x.i(0,C.cE))t.Wt(t.d.length-1)
else{if(x.i(0,C.fL)){v=$.es.fp$
v===$&&B.m()
v=v.a
u=B.Z(v).k("bd<2>")
v=(new B.bd(v,u).m(0,C.jN)||new B.bd(v,u).m(0,C.kh))&&t.a.w&&t.e<w.length}else v=!1
if(v){v=t.e
t.awe(w[v],v,!0)}else return C.ae}return C.aH},
bpA(d,e){var x=null,w=this.a,v=w.c,u=e.a===v.x?v.y:x
if(e.c==null)return B.C(x,x,x,w.d.$4(d,e,x,C.z),!0,x,x,x,x,x,!1,x,!1,x,x,!0,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,C.l,x)
if(u==null)w=x
else{w=w.y
if(w==null){w=B.X(d,K.M,y.r)
w=(w==null?C.L:w).gaPy()}w=w.$1(u)}return new B.cs(B.C(x,x,x,F.bY(x,!1,new A.ez7(this,e,u),!0,x,x,!0,x,!0,x,x,!1,!1,x,!1,C.y,!1,x,x,x,new A.ez8(v,e),x,!1,x,e.b,x,w,x,x,!1,x),!1,x,x,x,x,x,!1,x,!1,x,x,!0,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,C.l,x),x)},
bCL(d,e,f){var x,w=this,v=null,u=w.a.c,t=u.z.m(0,u.d.$1(e)),s=w.a,r=w.d[f]
s=s.w
x=s?t:v
s=s?t:v
return F.bY(v,!1,new A.ezc(w,e,f,t,u),!1,s,v,!0,v,!1,v,r,!1,!1,new B.aw(e,y.x),!1,C.y,!1,v,v,v,new A.ezd(w,e,f),v,t,v,v,x,v,v,v,!1,v)},
h(d){var x,w,v,u,t,s,r=this,q=null,p=r.a.c,o=p.gpc()
r.bHB(o.length)
x=y.p
w=B.a([],x)
for(v=p.a,u=v.length,t=0;t<v.length;v.length===u||(0,B.E)(v),++t)w.push(r.bpA(d,v[t]))
v=r.a.r.$2(d,w)
if(v==null){v=B.a([],x)
for(u=w.length,t=0;t<w.length;w.length===u||(0,B.E)(w),++t)v.push(new G.bn(1,C.ab,w[t],q))
w=G.y(v,C.h,q,C.b,C.j,0,q,q)}else w=v
v=B.bC([D.dns,new B.d9(new A.eze(r,p),new B.ch(B.a([],y.k),y.j),y.u)],y.n,y.V)
u=B.a([],x)
for(s=0;s<o.length;++s)u.push(r.bCL(d,o[s],s))
return B.i(B.a([w,B.nb(B.lU(v,B.d5(!1,!1,B.jP(B.i(u,C.n,q,C.b,C.f,0,C.d),q,q),q,q,q,q,!1,q,q,q,r.gbdy(),q,!0)),q,!1,D.cGT)],x),C.n,q,C.b,C.f,0,C.d)}}
var z=a.updateTypes(["~()","~(v)","x(Y?)","dZ(bG,dl)","~(Q8)"])
A.dB0.prototype={
$1(d){return d},
$S(){return this.a.k("Y(0)")}}
A.dB3.prototype={
$1(d){return d.a===this.b},
$S(){return B.Z(this.a).k("x(cQ<1>)")}}
A.dB1.prototype={
$1(d){return d.a===this.b},
$S(){return B.Z(this.a).k("x(cQ<1>)")}}
A.dB2.prototype={
$2(d,e){var x,w,v=this,u=v.b,t=A.j1l(u.$1(d),u.$1(e))*v.c
if(t!==0)u=t
else{u=v.d
x=v.a.d
w=u.q(0,x.$1(d))
w.toString
x=u.q(0,x.$1(e))
x.toString
x=C.o.ei(w,x)
u=x}return u},
$S(){return B.Z(this.a).k("v(1,1)")}}
A.ez6.prototype={
$0(){},
$S:0}
A.ez9.prototype={
$0(){return this.a.e=this.b},
$S:0}
A.eza.prototype={
$0(){return this.a.e=this.b},
$S:0}
A.ez8.prototype={
$0(){return this.a.it(0,this.b.a)},
$S:0}
A.ez7.prototype={
$3(d,e,f){return this.a.a.d.$4(d,this.b,this.c,e)},
$S:31}
A.ezd.prototype={
$0(){return this.a.awd(this.b,this.c)},
$S:0}
A.ezc.prototype={
$3(d,e,f){var x,w,v,u,t,s,r,q=this,p=q.a,o=p.a
o.toString
x=q.b
w=q.c
v=B.a([],y.p)
for(u=q.e.a,t=u.length,s=0;s<u.length;u.length===t||(0,B.E)(u),++s){r=u[s]
v.push(p.a.e.$3(d,x,r))}return o.f.$3(d,new A.py(x,w,q.d,e,new A.ezb(p,x,w)),v)},
$S:31}
A.ezb.prototype={
$0(){return this.a.awd(this.b,this.c)},
$S:0}
A.eze.prototype={
$1(d){return this.a.a.w?this.b.yE():null},
$S:z+4};(function installTearOffs(){var x=a._instance_1u,w=a._instance_0u,v=a._instance_2u
var u
x(u=A.vY.prototype,"gHU","uu",1)
x(u,"ga3h","bWh",2)
w(u,"gHA","yE",0)
w(u=A.axz.prototype,"ga98","Ws",0)
v(u,"gbdy","bdz",3)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.Y,[A.cQ,A.py])
w(A.aRt,B.el)
w(A.vY,B.jM)
x(B.cl,[A.dB0,A.dB3,A.dB1,A.ez7,A.ezc,A.eze])
w(A.dB2,B.dk)
w(A.asg,B.j)
w(A.Q8,B.bw)
w(A.axz,B.l)
x(B.d0,[A.ez6,A.ez9,A.eza,A.ez8,A.ezd,A.ezb])})()
B.bO(b.typeUniverse,JSON.parse('{"asg":{"j":[],"b":[]},"Q8":{"bw":[]},"vY":{"a6":[]},"axz":{"l":["asg<1>"]}}'))
B.j_(b.typeUniverse,JSON.parse('{"py":1}'))
var y=(function rtii(){var x=B.G
return{V:x("ce<bw>"),u:x("d9<Q8>"),J:x("o<bG>"),f:x("o<Y>"),p:x("o<b>"),k:x("o<~(ce<bw>)>"),K:x("Y"),j:x("ch<~(ce<bw>)>"),r:x("dF"),n:x("jf"),x:x("aw<Y?>"),S:x("v")}})();(function constants(){var x=a.makeConstList
D.ke=x(["Field notes","Reading list","Trip plan"],B.G("o<n>"))
D.kf=x([E.avv,E.Nu,E.avy],B.G("o<+(n,v)>"))
D.a0r=new A.Q8()
D.cGT=new B.cq([C.O3,D.a0r,C.Yn,D.a0r],B.G("cq<eW,bw>"))
D.Xk=new A.aRt(0,"none")
D.Dh=new A.aRt(1,"some")
D.mi=new A.aRt(2,"all")
D.kt=new B.ai("Drafts folder",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.ek=new B.ai("Planning notes",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.kv=new B.ai("A Field Guide",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.kw=new B.ai("Borrow a book for up to three weeks.",null,null,null,C.a5,null,null,null,null,null,null,null,null,null)
D.dns=B.cM("Q8")})()};
(a=>{a["6htj+IPCaUrAC8t9ZxVgHiP4RG0="]=a.current})($__dart_deferred_initializers__);