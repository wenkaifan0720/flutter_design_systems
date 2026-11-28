((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,D,A={
iRa(d,e){var x,w,v,u
if(d===e)return!0
if(d.Q!=null)x=!(d.b&&C.c.cQ(d.gel(),B.fj()))||d.gkj()
else x=!0
if(x)return!1
for(x=d.gel(),w=x.length,v=0;v<x.length;x.length===w||(0,B.F)(x),++v){u=x[v]
if(u instanceof B.nM&&u.gkj()&&u!==e&&!C.c.m(e.gel(),u))return!1}return!0},
jit(d){var x=d.e
if(x==null)x=null
else{x=x.cl(y.o)
x=x==null?null:x.w}return x===C.H},
hY:function hY(d,e,f){this.c=d
this.a=e
this.$ti=f},
ba2:function ba2(d){var _=this
_.d=null
_.e=$
_.c=_.a=null
_.$ti=d},
ftf:function ftf(d,e,f){this.a=d
this.b=e
this.c=f},
ftg:function ftg(d){this.a=d},
fth:function fth(d){this.a=d},
cCV:function cCV(d,e,f,g,h){var _=this
_.d=d
_.e=e
_.nY$=f
_.a=g
_.$ti=h},
hc_:function hc_(d,e,f){this.a=d
this.b=e
this.c=f},
hc1:function hc1(d,e,f){this.a=d
this.b=e
this.c=f},
hc2:function hc2(d){this.a=d},
hc0:function hc0(d){this.a=d},
ayu:function ayu(d,e,f,g){var _=this
_.y=d
_.b=e
_.c=null
_.N$=0
_.P$=f
_.aq$=_.au$=0
_.$ti=g},
ead:function ead(d){this.a=d},
eac:function eac(d,e){this.a=d
this.b=e}}
J=c[1]
B=c[0]
C=c[2]
D=c[256]
A=a.updateHolder(c[240],A)
A.hY.prototype={
p(){return new A.ba2(this.$ti.k("ba2<1>"))}}
A.ba2.prototype={
gaum(){var x,w=this,v=w.e
if(v===$){x=new A.ayu(w,C.DM,$.S(),w.$ti.k("ayu<1>"))
x.szd(B.bD([C.iM,new D.ur(x.gbHI()),C.iN,new D.ur(x.gbHQ()),C.fc,new D.ur(x.gbDV()),C.fD,new D.ur(x.gbDX())],y.x,y.v))
w.e!==$&&B.aK()
w.e=x
v=x}return v},
l(){var x=this.gaum()
x.P$=$.S()
x.N$=0
this.L()},
gaf5(){var x=this,w=x.d,v=B.aA(x.$ti.k("mM<1>"))
if(w==null||x.c==null)return v
x.c.d9(new A.ftf(x,w,v))
return v},
h(d){var x,w=this,v=w.$ti
w.d=D.m3(d,v.c)
x=w.gaum()
return B.ivH(B.jJ(w.a.c,null,new A.cCV(new A.ftg(w),new A.fth(w),B.an(y.y,y.g),B.cMk(),v.k("cCV<1>"))),null,x)}}
A.cCV.prototype={
Bo(d,e){var x,w,v,u,t=this,s={},r=t.NI(d,e),q=t.d.$0(),p=t.e.$0()
s.a=null
for(x=q.gb4(q);x.A();){w=x.gK()
if(J.B(w.gDS(),p)){s.a=w
break}}x=s.a
if(x!=null&&!A.iRa(x.gcY(),e))if(!q.cA(0,new A.hc_(t,B.nQ(d,B.aC(d).c),e)))s.a=null
if(s.a==null){v=B.an(y.c,t.$ti.k("mM<1>"))
for(x=q.gb4(q);x.A();){w=x.gK()
v.S(0,w.gcY(),w)}for(x=J.a2(r);x.A();){u=v.q(0,x.gK())
s.a=u
if(u!=null)break}}if(s.a==null)return r
return t.NI(new B.aT(d,new A.hc0(q.mk(0,new A.hc1(s,t,e)).o4(0,new A.hc2(t),y.c).mi(0)),B.aC(d).k("aT<1>")),e)}}
A.ayu.prototype={
a3O(d,e){if(!this.y.gaf5().cA(0,new A.ead(this)))return C.ah
return this.ath(d,e)},
bDW(){return this.aHo(!0)},
bDY(){return this.aHo(!1)},
bHJ(){return this.af4(!1,!0)},
bHR(){return this.af4(!0,!0)},
af4(d,e){var x,w,v,u,t,s,r,q,p,o={},n=this.y,m=n.gaf5(),l=n.d
if(m.a<2||l==null)return
n=B.a0(m).c
w=B.eP(m,m.r,n)
v=w.$ti.c
for(;;){if(!w.A()){x=null
break}u=w.d
x=u==null?v.a(u):u
if(x.gcY().gbm())break}if(x==null)return
t=x.gcY()
w=B.a([],y.k)
for(n=B.eP(m,m.r,n),v=n.$ti.c;n.A();){u=n.d
if(u==null)u=v.a(u)
if(u.gl9())w.push(u.gcY())}if(w.length===0)return
s=e&&C.c.cQ(w,A.jB6())
if(s&&!x.gl9())w.push(t)
r=J.Bb(B.bLs(w))
q=(s?!d:d)?r:new B.cI(r,B.aC(r).k("cI<1>"))
n=J.hS(q)
p=n.gb4(q)
o.a=null
while(p.A())if(p.gK()===t){if(p.A())o.a=p.gK()
break}if(o.a==null)o.a=n.gaf(q)
n=m.nv(0,new A.eac(o,this)).gDS()
l.a.d.$1(n)
o.a.bF()},
aHo(d){return this.af4(d,!1)}}
var z=a.updateTypes(["~()","x(bG)"])
A.ftf.prototype={
$1(d){var x,w,v,u=this
if(d instanceof B.pB){x=d.ok
x.toString
w=u.a.$ti.k("mM<1>")
v=w.b(x)?w.a(x):null
if(v!=null&&v.wI$===u.b)u.c.H(0,v)}d.d9(u)},
$S:66}
A.ftg.prototype={
$0(){return this.a.gaf5()},
$S(){return this.a.$ti.k("Z<mM<1>>()")}}
A.fth.prototype={
$0(){var x=this.a.d
return x==null?null:x.a.c},
$S(){return this.a.$ti.k("1?()")}}
A.hc_.prototype={
$1(d){return!this.b.m(0,d.gcY())&&A.iRa(d.gcY(),this.c)},
$S(){return this.a.$ti.k("x(mM<1>)")}}
A.hc1.prototype={
$1(d){return this.a.a!==d&&d.gcY()!==this.c},
$S(){return this.b.$ti.k("x(mM<1>)")}}
A.hc2.prototype={
$1(d){return d.gcY()},
$S(){return this.a.$ti.k("bG(mM<1>)")}}
A.hc0.prototype={
$1(d){return!this.a.m(0,d)},
$S:45}
A.ead.prototype={
$1(d){return d.gcY().gbm()},
$S(){return this.a.$ti.k("x(mM<1>)")}}
A.eac.prototype={
$1(d){return d.gcY()===this.a.a},
$S(){return this.b.$ti.k("x(mM<1>)")}};(function installTearOffs(){var x=a._static_1,w=a._instance_0u
x(A,"jB6","jit",1)
var v
w(v=A.ayu.prototype,"gbDV","bDW",0)
w(v,"gbDX","bDY",0)
w(v,"gbHI","bHJ",0)
w(v,"gbHQ","bHR",0)})();(function inheritance(){var x=a.inherit,w=a.inheritMany
x(A.hY,B.l)
x(A.ba2,B.m)
w(B.cp,[A.ftf,A.hc_,A.hc1,A.hc2,A.hc0,A.ead,A.eac])
w(B.da,[A.ftg,A.fth])
x(A.cCV,B.a96)
x(A.ayu,B.KF)})()
B.bP(b.typeUniverse,JSON.parse('{"hY":{"l":[],"b":[]},"ba2":{"m":["hY<1>"]},"ayu":{"a7":[]}}'))
var y={o:B.G("dv"),c:B.G("bG"),y:B.G("nM"),v:B.G("bA"),k:B.G("o<bG>"),x:B.G("f0"),g:B.G("QY")}};
(a=>{a["l2re6a2Lq96og2NnSpH2lmQ+cBw="]=a.current})($__dart_deferred_initializers__);