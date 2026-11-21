((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var C,B,A={
biM(d,e,f,g,h,i,j,k,l,m){return new A.aCm(m,d,k,j,g,f,l,h,i,e,null)},
ipG(d){return Math.max(0,d.b)},
ql:function ql(d,e){this.a=d
this.b=e},
G1:function G1(d,e,f){this.c=d
this.d=e
this.e=f},
vC:function vC(d,e,f,g,h,i,j){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i
_.x=j},
aCm:function aCm(d,e,f,g,h,i,j,k,l,m,n){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.r=h
_.w=i
_.x=j
_.y=k
_.z=l
_.Q=m
_.a=n},
aTt:function aTt(d,e,f,g,h,i,j,k){var _=this
_.d=$
_.e=d
_.r=_.f=null
_.QW$=e
_.QX$=f
_.xi$=g
_.a0z$=h
_.vH$=i
_.cf$=j
_.ao$=k
_.c=_.a=null},
edq:function edq(d){this.a=d},
edp:function edp(){},
eds:function eds(){},
edr:function edr(d,e,f){this.a=d
this.b=e
this.c=f},
edo:function edo(){},
edw:function edw(d){this.a=d},
edt:function edt(d,e){this.a=d
this.b=e},
edu:function edu(d,e){this.a=d
this.b=e},
edv:function edv(d){this.a=d},
b7v:function b7v(){},
cpe:function cpe(){}},G,E,H,I,D,F,K,L
C=c[0]
B=c[2]
A=a.updateHolder(c[82],A)
G=c[242]
E=c[253]
H=c[99]
I=c[254]
D=c[229]
F=c[264]
K=c[562]
L=c[244]
A.ql.prototype={
i(d,e){if(e==null)return!1
return e instanceof A.ql&&e.a===this.a&&e.b===this.b},
gY(d){return C.aK(this.a,this.b,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a)},
v(d){return"DesignPieSlice("+this.a+", "+C.al(this.b)+")"}}
A.G1.prototype={}
A.vC.prototype={}
A.aCm.prototype={
n(){var x=null
return new A.aTt(E.b8,x,!1,!1,!1,x,x,x)},
fG(d,e){return this.d.$2(d,e)}}
A.aTt.prototype={
gDZ(){var x,w=this,v=w.d
if(v===$){x=C.fh(null,1,w)
x.dK()
x.fa$.G(0,new A.edq(w))
w.d!==$&&C.aH()
w.d=x
v=x}return v},
ga3T(){return this.a.Q},
gaiJ(){return this.f!=null},
Jm(){return this.Em(null,null)},
ap(){this.aA()
this.gE3().ac(this.gN9())},
ag(d){var x,w,v,u=this
u.am(d)
u.aSf(d.Q)
if(C.c5(d.c,u.a.c))return
x=u.gDZ()
w=x.x
w===$&&C.i()
u.e=u.MS(w,d)
x.sq(0)
w=u.c
w.toString
D.bL(w)
u.a.toString
D.eA(x,1,C.jH(1,1,400),K.bf,null)
v=u.f
if(v!=null&&!u.bnE(v)){u.f=null
u.sMc(null)
u.xi$=!1
x=u.a.y
if(x!=null)x.$1(null)}},
k(){this.gDZ().k()
this.aMt()
this.b_M()},
bnE(d){var x
if(d>=0){x=this.a.c
x=d<x.length&&Math.max(0,x[d].b)>0}else x=!1
return x},
MS(d,e){var x,w,v,u,t=C.a([],y.k)
for(x=e.c,w=d>=1,v=0;v<x.length;++v){if(w)u=Math.max(0,x[v].b)
else{u=this.e
u=v<u.length?u[v]:0
u=C.bo(u,Math.max(0,x[v].b),d)
u.toString}t.push(u)}return t},
af_(d,e){var x=this.a.w.$1(d)
return x==null?C.e6(d,C.dv(e.gbW()),null,null):x},
Yi(d,e){var x=B.c.b9(this.a.c,0,new A.eds()),w=this.a.c[d],v=x===0?0:Math.max(0,w.b)/x
return e.a_g(C.aeQ(v,C.dv(e.gbW()),0),w.a,this.af_(Math.max(0,w.b),e))},
adW(d){var x,w,v=this,u=v.a,t=u.x
if(t!=null)return t
x=C.a([d.agb(u.c.length)],y.h)
u=v.a.c
if(u.length!==0){w=new C.aS(u,A.iBI(),C.aE(u).j("aS<1,p>"))
x.push(d.a_f(v.af_(w.cm(0,I.e1),d),v.af_(w.cm(0,E.be),d)))}return B.c.aK(x,d.gru())},
yJ(d,e,f){var x,w=this,v=d==null
if(v)w.xi$=!1
x=d==w.f
if(x&&e==w.vH$)return
w.m(new A.edr(w,d,e))
if(x)return
x=w.a.y
if(x!=null)x.$1(d)
if(f&&!v){v=w.c
v.toString
x=C.Z(v,F.P,y.g)
D.vh(v,w.Yi(d,x==null?B.N:x))}},
Em(d,e){return this.yJ(d,e,!1)},
bAg(d){var x,w,v,u,t,s,r,q,p,o=this.r
if(o==null)return null
x=d.aQ(0,o.b)
w=x.gh4()
if(w>o.c||w<o.d)return null
v=Math.atan2(x.a,-x.b)
if(v<0)v+=6.283185307179586
if(this.c.t(y.o).w===B.J)v=B.i.a3(6.283185307179586-v,6.283185307179586)
for(u=o.e,t=u.length,s=0,r=0;r<t;++r,s=p){q=u[r].c
p=s+q*2*3.141592653589793
if(q>0&&v>=s&&v<p)return r}return null},
Au(d,e){var x,w=d+e,v=this.a
for(;;){x=w>=0
if(!(x&&w<v.c.length))break
if(x){x=v.c
x=w<x.length&&Math.max(0,x[w].b)>0}else x=!1
if(x)return w
w+=e}return null},
aaM(d){var x,w,v,u=this,t=u.c.t(y.o).w,s=u.f,r=u.a.c.length
if(d.i(0,B.f6)){if(s==null)return B.ab
u.Em(null,null)
return B.aD}else if(d.i(0,B.bB)||d.i(0,B.bN)||d.i(0,B.bs)||d.i(0,B.bh)){if(!d.i(0,B.bh))x=d.i(0,B.bB)!==(t===B.J)&&!d.i(0,B.bs)
else x=!0
w=x?1:-1
if(s==null)v=u.Au(w>0?-1:r,w)
else{t=u.Au(s,w)
v=t==null?s:t}}else if(d.i(0,B.ce))v=u.Au(-1,1)
else if(d.i(0,B.cp))v=u.Au(r,-1)
else return B.ab
if(v!=null)u.yJ(v,null,!0)
return B.aD},
b6D(d){var x,w,v,u,t,s,r,q,p,o,n=this,m=n.c.t(y.o).w===B.J,l=n.a.f.pn(new C.B(0,0,0+d.a,0+d.b)),k=Math.max(0,Math.min(l.c-l.a,l.d-l.b)/2),j=n.gDZ().x
j===$&&C.i()
x=n.a
x.toString
w=n.MS(j,x)
v=B.c.b9(w,0,new A.edo())
u=C.a([],y.e)
for(j=v===0,t=0,s=0;s<w.length;++s){r=j?0:w[s]/v
q=m?-1:1
n.a.toString
u.push(new A.G1(r,-1.5707963267948966+q*t*2*3.141592653589793,q*r*2*3.141592653589793))
t+=r}p=n.f
if(p==null)o=null
else{j=u[p]
o=j.d+j.e/2}j=l.gbH()
x=n.a.r
if(o!=null)l.gbH().az(0,new C.q(Math.cos(o),Math.sin(o)).bc(0,k))
return new A.vC(d,j,k,k*x,u,p,n.gaQC())},
h(d){var x,w,v,u,t,s,r,q,p,o,n=this,m=null,l=C.Z(d,F.P,y.g)
if(l==null)l=B.N
x=n.f
w=n.a.c.length
v=x==null
u=v?n.Au(-1,1):n.Au(x,1)
t=v?n.Au(w,-1):n.Au(x,-1)
s=n.a.e
v=v?n.adW(l):n.Yi(x,l)
n.a.toString
r=u==null
q=r?m:new A.edt(n,u)
p=t==null
o=p?m:new A.edu(n,t)
r=r?m:n.Yi(u,l)
l=p?m:n.Yi(t,l)
return n.aQB(!1,new L.ak(new A.edv(n),m),s,r,n.gaaL(),q,o,n.a.z,new A.edw(n),l,v)}}
A.b7v.prototype={
k(){var x=this,w=x.ao$
if(w!=null)w.S(x.gdv())
x.ao$=null
x.L()},
bq(){this.bC()
this.bB()
this.dw()}}
A.cpe.prototype={}
var z=a.updateTypes(["e5(ao)","p(p,ql)","p(ql)"])
A.edq.prototype={
$0(){return this.a.m(new A.edp())},
$S:0}
A.edp.prototype={
$0(){},
$S:0}
A.eds.prototype={
$2(d,e){return d+Math.max(0,e.b)},
$S:z+1}
A.edr.prototype={
$0(){var x=this.a,w=this.b
x.f=w
x.sMc(w==null?null:this.c)},
$S:0}
A.edo.prototype={
$2(d,e){return d+e},
$S:12}
A.edw.prototype={
$2(d,e){var x=this.a
return x.Em(x.bAg(d),e)},
$S:506}
A.edt.prototype={
$0(){return this.a.yJ(this.b,null,!0)},
$S:0}
A.edu.prototype={
$0(){return this.a.yJ(this.b,null,!0)},
$S:0}
A.edv.prototype={
$2(d,e){var x,w,v,u=e.b
u=isFinite(u)?u:300
x=e.d
x=isFinite(x)?x:u
w=this.a
v=w.r=w.b6D(new C.H(u,x))
return G.ms(w.a.fG(d,v),v.a)},
$S:62};(function aliases(){var x=A.b7v.prototype
x.b_M=x.k})();(function installTearOffs(){var x=a._static_1,w=a._instance_1u
x(A,"iBI","ipG",2)
w(A.aTt.prototype,"gaaL","aaM",0)})();(function inheritance(){var x=a.mixinHard,w=a.mixin,v=a.inheritMany,u=a.inherit
v(C.V,[A.ql,A.G1,A.vC])
u(A.aCm,C.k)
u(A.b7v,C.l)
u(A.cpe,A.b7v)
u(A.aTt,A.cpe)
v(C.cS,[A.edq,A.edp,A.edr,A.edt,A.edu])
v(C.d8,[A.eds,A.edo,A.edw,A.edv])
x(A.b7v,C.dg)
w(A.cpe,H.aul)})()
C.bN(b.typeUniverse,JSON.parse('{"aCm":{"k":[],"b":[]},"aTt":{"l":["aCm"]}}'))
var y={g:C.D("e3"),o:C.D("di"),e:C.D("n<G1>"),h:C.D("n<m>"),k:C.D("n<p>")}};
(a=>{a["U7WHL0yCigLiC3WKFS5+P05RWGU="]=a.current})($__dart_deferred_initializers__);