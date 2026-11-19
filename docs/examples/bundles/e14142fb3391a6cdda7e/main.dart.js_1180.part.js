((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var C,B,A={
wD(d,e,f,g,h,i,j,k,l,m,n,o,p,q){return new A.aAE(q,k,p,n,g,f,d,h,j,i,l,m,e,o,null)},
iR:function iR(d,e){this.a=d
this.b=e},
kL:function kL(d,e,f){this.a=d
this.b=e
this.c=f},
aAE:function aAE(d,e,f,g,h,i,j,k,l,m,n,o,p,q,r){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.r=h
_.w=i
_.x=j
_.y=k
_.as=l
_.at=m
_.ax=n
_.ay=o
_.ch=p
_.CW=q
_.a=r},
bOz:function bOz(){var _=this
_.d=null
_.e=1
_.c=_.a=null},
e7w:function e7w(d,e){this.a=d
this.b=e},
e7F:function e7F(d,e,f,g,h){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h},
e7H:function e7H(d,e,f){this.a=d
this.b=e
this.c=f},
e7G:function e7G(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},
e7D:function e7D(d,e){this.a=d
this.b=e},
e7E:function e7E(d,e){this.a=d
this.b=e},
e7z:function e7z(d,e){this.a=d
this.b=e},
e7y:function e7y(d,e){this.a=d
this.b=e},
e7A:function e7A(d,e){this.a=d
this.b=e},
e7B:function e7B(d){this.a=d},
e7x:function e7x(d){this.a=d},
e7C:function e7C(d,e){this.a=d
this.b=e},
wE(d,e,f,g,h,i,j,k,l,m,n,o){return new A.bgF(i,m,d,e,h,o,k,j,l,f,n,g,null)},
fo:function fo(d,e,f){this.a=d
this.b=e
this.c=f},
jE:function jE(d,e){this.a=d
this.b=e},
bgF:function bgF(d,e,f,g,h,i,j,k,l,m,n,o,p){var _=this
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
_.as=n
_.at=o
_.a=p},
cEl:function cEl(d){this.a=d},
cEn:function cEn(d){this.a=d},
cEj:function cEj(d,e){this.a=d
this.b=e},
cEk:function cEk(d,e){this.a=d
this.b=e},
cEm:function cEm(d){this.a=d},
cEh:function cEh(d,e){this.a=d
this.b=e},
cEi:function cEi(d,e){this.a=d
this.b=e}},D,F,I,K,L,M,N,E,G,O,H,P
C=c[0]
B=c[2]
A=a.updateHolder(c[135],A)
D=c[244]
F=c[257]
I=c[197]
K=c[279]
L=c[238]
M=c[172]
N=c[786]
E=c[226]
G=c[260]
O=c[222]
H=c[280]
P=c[240]
A.iR.prototype={
i(d,e){if(e==null)return!1
return e instanceof A.iR&&e.a===this.a&&e.b===this.b},
gY(d){return C.aA(this.a,this.b,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a,B.a)},
v(d){return"DesignRangeValues("+C.ae(this.a)+", "+C.ae(this.b)+")"}}
A.kL.prototype={}
A.aAE.prototype={
n(){return new A.bOz()},
bUR(d,e){return this.e.$2(d,e)},
bUd(d,e,f){return this.f.$3(d,e,f)}}
A.bOz.prototype={
ayR(d){if(this.e!==d)this.m(new A.e7w(this,d))},
ab4(d){var x=this.a,w=x.w
x=x.r
w-=x
return w===0?0:(d-x)/w},
aBf(d){var x,w,v,u=this.a,t=B.i.I(d,u.r,u.w)
u=this.a
x=u.x
if(x<=0)return t
w=u.w
u=u.r
v=(w-u)/x
return u+B.i.ac((t-u)/v)*v},
X3(d,e){var x,w,v,u,t,s,r=this,q=r.a,p=q.d
if(p==null)return
x=q.c
w=x.a
q=q.y
v=w+q
u=x.b
t=u-q
if(d===0){q=r.aBf(e)
w=r.a.r
s=new A.iR(B.i.I(q,w,t<w?w:t),u)}else{q=r.aBf(e)
u=r.a.w
s=new A.iR(w,B.i.I(q,v>u?u:v,u))}if(!s.i(0,x))p.$1(s)},
ab5(d,e){var x=this.c.t(y.o).w,w=this.a,v=w.CW.a,u=e-v,t=u<=0?0:(d-v/2)/u
if(x===B.E)t=1-t
x=w.r
w=B.i.I(t,0,1)
v=this.a
return x+w*(v.w-v.r)},
az2(d){var x=this.a.c,w=x.a,v=Math.abs(d-w),u=Math.abs(d-x.b)
if(v!==u)return v<u?0:1
return d<w?0:1},
h(d){var x=this.a,w=x.d,v=x.c
x=d.t(y.o).w
return P.aE(new A.e7F(this,this.a.CW,x===B.E,v,w!=null))}}
A.fo.prototype={}
A.jE.prototype={
U(){return"DesignSplitPart."+this.b}}
A.bgF.prototype={
h(d){var x=this
return I.h4(new A.cEl(x),!0,x.Q,1,!0,B.aP,K.ch,null,null,new A.cEm(x),x.as,x.x,1400,N.El,!1)}}
var z=a.updateTypes(["b(c,dn)","r(c,cz)"])
A.e7w.prototype={
$0(){return this.a.e=this.b},
$S:0}
A.e7F.prototype={
$2(d,e){var x,w,v,u,t,s=this,r=null,q=e.b,p=s.b,o=p.a,n=s.a,m=s.d,l=s.e,k=new A.e7G(n,new A.e7H(n,s.c,q-o),m,p,d,l),j=!l
if(j)x=B.cx
else x=n.d!=null?F.mp:B.aR
w=j?r:new A.e7z(n,q)
v=j?r:new A.e7A(n,q)
u=j?r:new A.e7B(n)
j=j?r:new A.e7C(n,q)
o/=2
t=n.a
t.toString
return C.cl(C.cC(B.aB,new C.t(q,p.b,new C.az(B.Q,r,B.a_,B.v,C.a([C.ei(0,C.R(new C.t(1/0,r,new C.a4(!0,t.bUR(d,new A.kL(n.ab4(m.a),n.ab4(m.b),l)),r),r),r,r),r,r,o,o,0,r),k.$1(1-n.e),k.$1(n.e)],y.e),r),r),B.r,!0,r,r,r,r,u,w,v,r,r,r,r,r,r,r,r,r,r,r,r,r,r,r,r,r,j,r,r,r,r,r,r,r,r),x,r,r,r,r,r,!0)},
$S:170}
A.e7H.prototype={
$1(d){var x=this.a.ab4(d),w=this.b?1-x:x
return w*this.c},
$S:5}
A.e7G.prototype={
$1(d){var x,w,v,u,t,s,r,q,p,o=this,n=null,m=d===0,l=o.c,k=m?l.a:l.b
k=o.b.$1(k)
x=o.d
l=m?l.a:l.b
w=o.a
v=w.a
u=v.r
t=v.w
s=v.x
r=w.d
q=r===d
r=r!=null&&!q?F.mp:n
if(m){m=v.ay
if(m==null){m=C.X(o.e,G.N,y.g)
m=(m==null?B.M:m).gFZ()}}else{m=v.ch
if(m==null){m=C.X(o.e,G.N,y.g)
m=(m==null?B.M:m).gFY()}}v=w.a.ax
p=o.f?new A.e7D(w,d):n
return C.ei(n,E.BH(!1,B.C,new A.e7E(w,d),s,q,n,B.k7,t,u,x,r,n,n,p,n,n,v,m,n,l),x.b,new C.bG(d,y.n),k,n,0,x.a)},
$S:33}
A.e7D.prototype={
$1(d){var x=this.a,w=this.b
x.ayR(w)
x.X3(w,d)},
$S:17}
A.e7E.prototype={
$2(d,e){return this.a.a.bUd(d,this.b,e)},
$S:30}
A.e7z.prototype={
$1(d){var x,w=this.a,v=w.ab5(d.b.a,this.b)
w.m(new A.e7y(w,w.az2(v)))
w.a.toString
x=w.d
x.toString
w.X3(x,v)},
$S:42}
A.e7y.prototype={
$0(){var x=this.a
x.e=x.d=this.b},
$S:0}
A.e7A.prototype={
$1(d){var x=this.a,w=x.d
if(w!=null)x.X3(w,x.ab5(d.b.a,this.b))},
$S:31}
A.e7B.prototype={
$1(d){var x=this.a
x.m(new A.e7x(x))
x.a.toString},
$S:35}
A.e7x.prototype={
$0(){return this.a.d=null},
$S:0}
A.e7C.prototype={
$1(d){var x=this.a,w=x.ab5(d.b.a,this.b),v=x.az2(w)
x.ayR(v)
x.X3(v,w)},
$S:57}
A.cEl.prototype={
$2(d,e){var x=null,w=new A.cEn(e),v=this.a,u=v.z,t=E.cg(x,!1,new A.cEj(v,e),!0,x,x,!0,x,!0,x,x,!1,!1,x,!1,u,!1,x,w,x,v.d,x,!1,x,v.c,x,x,x,x,!1,x),s=v.e.length===0?x:e.e,r=e.b,q=E.cg(x,!1,new A.cEk(v,e),!0,x,x,!0,x,!0,r,x,!1,!1,x,!1,u,!1,x,w,x,s,x,r,x,v.x,x,x,x,x,!1,x)
w=v.y
w=w==null?x:w.$3(d,t,q)
return w==null?L.A(C.a([t,q],y.e),B.h,x,B.b,B.f,0,x,x):w},
$S:z+0}
A.cEn.prototype={
$2(d,e){if(e instanceof C.df&&e.b.i(0,B.b9)&&!this.a.b){this.a.c.$0()
return B.ax}return B.aa},
$S:20}
A.cEj.prototype={
$3(d,e,f){return this.a.f.$4(d,D.jN,e,this.b.b)},
$S:32}
A.cEk.prototype={
$3(d,e,f){return this.a.f.$4(d,D.w2,e,this.b.b)},
$S:32}
A.cEm.prototype={
$2(d,e){var x,w,v,u,t,s,r,q,p=null,o=e.b
o=B.i.I(o.c-o.a,0,e.c.a)
x=C.a([],y.e)
for(w=this.a,v=w.e,u=v.length,t=w.at,s=0;s<v.length;v.length===u||(0,C.G)(v),++s){r=v[s]
q=r.b!=null?new A.cEh(e,r):p
x.push(new M.Fe(p,q,r.a,p,p,!1,p,t,p,new A.cEi(w,r),p))}return new C.r(new C.B(o,1/0,0,1/0),w.w.$3(d,e,x),p)},
$S:z+1}
A.cEh.prototype={
$0(){this.a.e.$0()
var x=this.b.b
if(x!=null)x.$0()},
$S:0}
A.cEi.prototype={
$2(d,e){return this.a.r.$3(d,this.b,e)},
$S:30};(function inheritance(){var x=a.inheritMany,w=a.inherit
x(C.Q,[A.iR,A.kL,A.fo])
w(A.aAE,C.j)
w(A.bOz,C.i)
x(C.cS,[A.e7w,A.e7y,A.e7x,A.cEh])
x(C.d_,[A.e7F,A.e7E,A.cEl,A.cEn,A.cEm,A.cEi])
x(C.ck,[A.e7H,A.e7G,A.e7D,A.e7z,A.e7A,A.e7B,A.e7C,A.cEj,A.cEk])
w(A.jE,C.e9)
w(A.bgF,C.k)})()
C.bE(b.typeUniverse,JSON.parse('{"aAE":{"j":[],"b":[]},"bOz":{"i":["aAE"]},"bgF":{"k":[],"b":[]}}'))
var y={g:C.C("dZ"),o:C.C("dp"),e:C.C("m<b>"),n:C.C("bG<u>")};(function constants(){D.mY=new O.ht(H.cy,H.w1,4,8,200,!0,320)
D.jN=new A.jE(0,"main")
D.w2=new A.jE(1,"toggle")})()};
(a=>{a["B3iZRzV2gT9JTJWfZcnlREA2D7M="]=a.current})($__dart_deferred_initializers__);