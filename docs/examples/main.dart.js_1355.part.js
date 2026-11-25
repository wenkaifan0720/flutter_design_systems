((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,H,A={
zo(d,e,f,g,h,i){var x=B.aH(h,i),w=g==null?new A.dBG(i):g
return new A.w0(d,e,w,x,f,C.ez,B.az(y.K),$.T(),i.k("w0<0>"))},
j2P(d,e){return J.ajC(d,e)},
uw(d,e,f,g,h,i,j,k,l){return new A.ass(e,f,d,i,g,j,h,k,null,l.k("ass<0>"))},
cR:function cR(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.$ti=h},
aRI:function aRI(d,e){this.a=d
this.b=e},
w0:function w0(d,e,f,g,h,i,j,k,l){var _=this
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
dBG:function dBG(d){this.a=d},
dBJ:function dBJ(d,e){this.a=d
this.b=e},
dBH:function dBH(d,e){this.a=d
this.b=e},
dBI:function dBI(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
pB:function pB(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
ass:function ass(d,e,f,g,h,i,j,k,l,m){var _=this
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
Qe:function Qe(){},
axN:function axN(d,e){var _=this
_.d=d
_.e=0
_.c=_.a=null
_.$ti=e},
ezO:function ezO(){},
ezR:function ezR(d,e){this.a=d
this.b=e},
ezS:function ezS(d,e){this.a=d
this.b=e},
ezQ:function ezQ(d,e){this.a=d
this.b=e},
ezP:function ezP(d,e,f){this.a=d
this.b=e
this.c=f},
ezV:function ezV(d,e,f){this.a=d
this.b=e
this.c=f},
ezU:function ezU(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
ezT:function ezT(d,e,f){this.a=d
this.b=e
this.c=f},
ezW:function ezW(d,e){this.a=d
this.b=e},
ue(){return b.G.document.createElement("input")}},D,E,I,F,G,K
J=c[1]
B=c[0]
C=c[2]
H=c[357]
A=a.updateHolder(c[155],A)
D=c[324]
E=c[325]
I=c[382]
F=c[254]
G=c[268]
K=c[276]
A.cR.prototype={}
A.aRI.prototype={
Y(){return"RawDataTableSelection."+this.b}}
A.w0.prototype={
sMm(d){var x,w,v,u,t=this,s=B.aH(d,B.a_(t).c)
t.e=s
x=B.az(y.K)
for(w=s.length,v=t.d,u=0;u<s.length;s.length===w||(0,B.F)(s),++u)x.H(0,v.$1(s[u]))
t.z.EK(x.gn8(x),!1)
t.a9t(!0)},
suv(d){if(d===this.w)return
this.w=d
this.WE()},
il(d,e){var x=this
if(C.c.ni(x.a,new A.dBJ(x,e)).c==null)return
if(x.x!==e){x.x=e
x.y=C.ez}else if(x.y===C.ez)x.y=H.py
else{x.x=null
x.y=C.ez}x.WE()},
gyk(){var x,w,v,u,t,s,r,q,p,o,n,m=this,l=m.as
if(l!=null)return l
x=m.b
w=B.a_(m)
v=B.a([],w.k("o<1>"))
for(u=m.e,t=u.length,s=x!=null,r=0;r<u.length;u.length===t||(0,B.F)(u),++r){q=u[r]
p=m.w
if(p.length===0||!s||x.$2(q,p))v.push(q)}o=m.x
if(o!=null){u=C.c.ni(m.a,new A.dBH(m,o)).c
u.toString
t=B.am(y.K,y.S)
for(s=m.d,n=0;n<v.length;++n)t.R(0,s.$1(v[n]),n)
C.c.il(v,new A.dBI(m,u,m.y===C.ez?1:-1,t))}return m.as=B.pu(v,w.c)},
gkY(){var x=this.f
if(x==null||this.gyk().length===0)return 1
return C.o.ji(this.gyk().length+x-1,x)},
uz(d){var x=this,w=C.o.J(d,0,x.gkY()-1)
if(w===x.r)return
x.r=w
x.V()},
gpg(){var x,w=this,v=w.f
if(v==null)return w.gyk()
x=w.r*v
if(x>=w.gyk().length)return I.je
return C.c.iW(w.gyk(),x,C.o.J(x+v,0,w.gyk().length))},
bWK(d){return this.z.m(0,this.d.$1(d))},
c1G(d,e){var x,w,v,u,t,s,r,q=this,p=q.d,o=p.$1(d),n=q.Q
if(e&&n!=null){x=B.a([],y.f)
for(w=q.gyk(),v=w.length,u=0;u<v;++u)x.push(p.$1(w[u]))
t=C.c.fJ(x,n)
s=C.c.fJ(x,o)
if(t>=0&&s>=0){p=t<s
r=p?t:s
q.z.F(0,C.c.iW(x,r,(p?s:t)+1))
q.V()
return}}p=q.z
if(!p.ai(0,o))p.H(0,o)
q.Q=o
q.V()},
gpX(){var x=this.gpg(),w=new B.aR(x,this.ga3A(),B.aE(x).k("aR<1>")).gaa(0)
if(w===0)return D.Y0
return w===x.length?D.mm:D.Do},
yO(){var x,w,v,u,t=this,s=B.a([],y.f)
for(x=t.gpg(),w=x.length,v=t.d,u=0;u<x.length;x.length===w||(0,B.F)(x),++u)s.push(v.$1(x[u]))
x=t.z
if(t.gpX()===D.mm)x.uw(s)
else x.F(0,s)
t.V()},
a9t(d){var x=this
x.as=null
x.r=d?C.o.J(x.r,0,x.gkY()-1):0
x.V()},
WE(){return this.a9t(!1)}}
A.pB.prototype={}
A.ass.prototype={
p(){return new A.axN(B.a([],y.J),this.$ti.k("axN<1>"))}}
A.Qe.prototype={}
A.axN.prototype={
au(){this.aB()
this.a.c.ae(this.ga9s())},
af(d){var x,w,v=this
v.an(d)
x=d.c
if(x!==v.a.c){w=v.ga9s()
x.T(w)
v.a.c.ae(w)}},
l(){var x,w,v,u,t,s=this
s.a.c.T(s.ga9s())
for(x=s.d,w=x.length,v=0;v<x.length;x.length===w||(0,B.F)(x),++v){u=x[v]
t=u.ax
if(t!=null)t.am()
u.cZ()}s.L()},
WE(){return this.n(new A.ezO())},
bHT(d){var x,w,v,u,t=this
for(x=t.d;w=x.length,w<d;)x.push(B.bH(!0,"RawDataTable row "+w,!0,!0,null,null,!1))
while(x.length>d){w=x.pop()
v=w.ax
if(v!=null)v.am()
w.cZ()}if(t.e>=d)t.e=d===0?0:d-1
for(u=0;u<x.length;++u){w=x[u]
v=u!==t.e
if(v!==w.a){w.a=v
v=w.w
if(v!=null){v.w1()
v.d.H(0,w)}}}},
WF(d){var x,w=this.d,v=w.length
if(v===0)return
x=C.o.J(d,0,v-1)
this.n(new A.ezR(this,x))
w[x].bG()},
awq(d,e,f){var x,w,v
this.n(new A.ezS(this,e))
x=this.a
if(x.w){x=x.c
if(f==null){w=$.es.fq$
w===$&&B.m()
w=w.a
v=B.a_(w).k("bc<2>")
w=new B.bc(w,v).m(0,C.jO)||new B.bc(w,v).m(0,C.ki)}else w=f
x.c1G(d,w)}},
awp(d,e){return this.awq(d,e,null)},
bdR(d,e){var x,w,v,u,t=this
if(!(e instanceof B.dt)&&!(e instanceof B.fJ))return C.ae
x=e.b
w=t.a.c.gpg()
if(x.i(0,C.bk))t.WF(t.e+1)
else if(x.i(0,C.bA))t.WF(t.e-1)
else if(x.i(0,C.cu))t.WF(0)
else if(x.i(0,C.cE))t.WF(t.d.length-1)
else{if(x.i(0,C.fP)){v=$.es.fq$
v===$&&B.m()
v=v.a
u=B.a_(v).k("bc<2>")
v=(new B.bc(v,u).m(0,C.jO)||new B.bc(v,u).m(0,C.ki))&&t.a.w&&t.e<w.length}else v=!1
if(v){v=t.e
t.awq(w[v],v,!0)}else return C.ae}return C.aH},
bpS(d,e){var x=null,w=this.a,v=w.c,u=e.a===v.x?v.y:x
if(e.c==null)return B.C(x,x,x,w.d.$4(d,e,x,C.z),!0,x,x,x,x,x,!1,x,!1,x,x,!0,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,C.l,x)
if(u==null)w=x
else{w=w.y
if(w==null){w=B.X(d,K.M,y.r)
w=(w==null?C.K:w).gaPQ()}w=w.$1(u)}return new B.ct(B.C(x,x,x,F.bY(x,!1,new A.ezP(this,e,u),!0,x,x,!0,x,!0,x,x,!1,!1,x,!1,C.y,!1,x,x,x,new A.ezQ(v,e),x,!1,x,e.b,x,w,x,x,!1,x),!1,x,x,x,x,x,!1,x,!1,x,x,!0,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,C.l,x),x)},
bD2(d,e,f){var x,w=this,v=null,u=w.a.c,t=u.z.m(0,u.d.$1(e)),s=w.a,r=w.d[f]
s=s.w
x=s?t:v
s=s?t:v
return F.bY(v,!1,new A.ezU(w,e,f,t,u),!1,s,v,!0,v,!1,v,r,!1,!1,new B.aw(e,y.x),!1,C.y,!1,v,v,v,new A.ezV(w,e,f),v,t,v,v,x,v,v,v,!1,v)},
h(d){var x,w,v,u,t,s,r=this,q=null,p=r.a.c,o=p.gpg()
r.bHT(o.length)
x=y.p
w=B.a([],x)
for(v=p.a,u=v.length,t=0;t<v.length;v.length===u||(0,B.F)(v),++t)w.push(r.bpS(d,v[t]))
v=r.a.r.$2(d,w)
if(v==null){v=B.a([],x)
for(u=w.length,t=0;t<w.length;w.length===u||(0,B.F)(w),++t)v.push(new G.bn(1,C.ab,w[t],q))
w=G.y(v,C.h,q,C.b,C.j,0,q,q)}else w=v
v=B.bC([D.doJ,new B.da(new A.ezW(r,p),new B.ci(B.a([],y.k),y.j),y.u)],y.n,y.V)
u=B.a([],x)
for(s=0;s<o.length;++s)u.push(r.bD2(d,o[s],s))
return B.i(B.a([w,B.nb(B.lU(v,B.d7(!1,!1,B.jQ(B.i(u,C.n,q,C.b,C.f,0,C.d),q,q),q,q,q,q,!1,q,q,q,r.gbdQ(),q,!0)),q,!1,D.cHX)],x),C.n,q,C.b,C.f,0,C.d)}}
var z=a.updateTypes(["~()","~(v)","x(Y?)","dZ(bG,dl)","~(Qe)"])
A.dBG.prototype={
$1(d){return d},
$S(){return this.a.k("Y(0)")}}
A.dBJ.prototype={
$1(d){return d.a===this.b},
$S(){return B.a_(this.a).k("x(cR<1>)")}}
A.dBH.prototype={
$1(d){return d.a===this.b},
$S(){return B.a_(this.a).k("x(cR<1>)")}}
A.dBI.prototype={
$2(d,e){var x,w,v=this,u=v.b,t=A.j2P(u.$1(d),u.$1(e))*v.c
if(t!==0)u=t
else{u=v.d
x=v.a.d
w=u.q(0,x.$1(d))
w.toString
x=u.q(0,x.$1(e))
x.toString
x=C.o.ed(w,x)
u=x}return u},
$S(){return B.a_(this.a).k("v(1,1)")}}
A.ezO.prototype={
$0(){},
$S:0}
A.ezR.prototype={
$0(){return this.a.e=this.b},
$S:0}
A.ezS.prototype={
$0(){return this.a.e=this.b},
$S:0}
A.ezQ.prototype={
$0(){return this.a.il(0,this.b.a)},
$S:0}
A.ezP.prototype={
$3(d,e,f){return this.a.a.d.$4(d,this.b,this.c,e)},
$S:31}
A.ezV.prototype={
$0(){return this.a.awp(this.b,this.c)},
$S:0}
A.ezU.prototype={
$3(d,e,f){var x,w,v,u,t,s,r,q=this,p=q.a,o=p.a
o.toString
x=q.b
w=q.c
v=B.a([],y.p)
for(u=q.e.a,t=u.length,s=0;s<u.length;u.length===t||(0,B.F)(u),++s){r=u[s]
v.push(p.a.e.$3(d,x,r))}return o.f.$3(d,new A.pB(x,w,q.d,e,new A.ezT(p,x,w)),v)},
$S:31}
A.ezT.prototype={
$0(){return this.a.awp(this.b,this.c)},
$S:0}
A.ezW.prototype={
$1(d){return this.a.a.w?this.b.yO():null},
$S:z+4};(function installTearOffs(){var x=a._instance_1u,w=a._instance_0u,v=a._instance_2u
var u
x(u=A.w0.prototype,"gHY","uz",1)
x(u,"ga3A","bWK",2)
w(u,"gHE","yO",0)
w(u=A.axN.prototype,"ga9s","WE",0)
v(u,"gbdQ","bdR",3)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.Y,[A.cR,A.pB])
w(A.aRI,B.eh)
w(A.w0,B.jN)
x(B.cl,[A.dBG,A.dBJ,A.dBH,A.ezP,A.ezU,A.ezW])
w(A.dBI,B.di)
w(A.ass,B.j)
w(A.Qe,B.bw)
w(A.axN,B.l)
x(B.d1,[A.ezO,A.ezR,A.ezS,A.ezQ,A.ezV,A.ezT])})()
B.bO(b.typeUniverse,JSON.parse('{"ass":{"j":[],"b":[]},"Qe":{"bw":[]},"w0":{"a6":[]},"axN":{"l":["ass<1>"]}}'))
B.j1(b.typeUniverse,JSON.parse('{"pB":1}'))
var y=(function rtii(){var x=B.G
return{V:x("cf<bw>"),u:x("da<Qe>"),J:x("o<bG>"),f:x("o<Y>"),p:x("o<b>"),k:x("o<~(cf<bw>)>"),K:x("Y"),j:x("ci<~(cf<bw>)>"),r:x("dD"),n:x("jg"),x:x("aw<Y?>"),S:x("v")}})();(function constants(){var x=a.makeConstList
D.kf=x(["Field notes","Reading list","Trip plan"],B.G("o<n>"))
D.kg=x([E.awa,E.NO,E.awd],B.G("o<+(n,v)>"))
D.a14=new A.Qe()
D.cHX=new B.cr([C.On,D.a14,C.Z3,D.a14],B.G("cr<eW,bw>"))
D.Y0=new A.aRI(0,"none")
D.Do=new A.aRI(1,"some")
D.mm=new A.aRI(2,"all")
D.ku=new B.ai("Drafts folder",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.el=new B.ai("Planning notes",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.kw=new B.ai("A Field Guide",null,null,null,null,null,null,null,null,null,null,null,null,null)
D.kx=new B.ai("Borrow a book for up to three weeks.",null,null,null,C.a5,null,null,null,null,null,null,null,null,null)
D.doJ=B.cN("Qe")})()};
(a=>{a["m4+yyk1Ekh0p0G5bIxfcbZ0pJmY="]=a.current})($__dart_deferred_initializers__);