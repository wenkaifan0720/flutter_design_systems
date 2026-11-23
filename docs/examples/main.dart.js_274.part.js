((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,I,E,A={
jez(d){var x,w,v,u,t,s,r
for(x=d.length,w=1/0,v=0;v<x;++v)for(u=d[v].b,t=u.length,s=1;s<t;++s){r=Math.abs(u[s].a-u[s-1].a)
if(r>0)w=Math.min(w,r)}return w},
jeA(d,e,f,g,h,i){var x,w,v,u,t=null
if(h!=null)return h.$1(d)
switch(f.a){case 0:return B.dg(d,B.cM(e.gby()),t,t)
case 2:x=C.i.ag(d)
return g!=null&&x>=0&&x<g.length?g[x]:B.dg(x+1,B.cM(e.gby()),t,t)
case 1:w=new B.bj(B.YN(C.i.ag(d),0,!1),0,!1)
if(i==1/0||i==-1/0)return e.ic(w)
if(i>=31536e6){v=e.gby()
u=e.gby()
return B.mq(v.go,w,e.gb0(),u,e.gb1())}if(i>=24192e5)return e.lO(w)
if(i>=864e5)return e.ic(w)
v=e.gby()
u=e.gby()
return B.mq(v.fx,w,e.gb0(),u,e.gb1())+e.gwj()+e.aQa(new F.lA(B.eA(w),B.hH(w),B.En(w)))}},
Hr(d,e,f,g,h,i,j,k,l,m,n,o,p,q,r){return new A.YS(n,d,l,q,e,k,r,p,h,i,m,j,g,f,o,null)},
izC(d){var x=d.r
x=x==null?null:x.length
return x==null?C.c.aW(d.c,0,new A.evO()):x},
izD(d){var x,w,v,u,t,s,r,q,p,o,n,m,l
for(x=d.c,w=x.length,v=1/0,u=-1/0,t=1/0,s=-1/0,r=0;r<w;++r)for(q=x[r].b,p=q.length,o=0;o<p;++o){n=q[o]
m=n.a
v=Math.min(v,m)
u=Math.max(u,m)
l=n.b
if(l==null)continue
t=Math.min(t,l)
s=Math.max(s,l)}if(d.f===D.ry){u=Math.max(0,A.izC(d)-1)
v=0}if(v>u){v=0
u=1}if(t>s){t=0
s=1}l=E.aId(1,d.x,s,t,0,d.y)
return new A.c1Z(v,u,l.c,l.d)},
kD:function kD(d,e){this.a=d
this.b=e},
kE:function kE(d,e){this.a=d
this.b=e},
brR:function brR(d,e){this.a=d
this.b=e},
Dq:function Dq(d,e){this.a=d
this.b=e},
ls:function ls(d,e,f,g,h,i,j,k,l,m,n){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i
_.r=j
_.w=k
_.x=l
_.y=m
_.z=n},
YS:function YS(d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s){var _=this
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
_.ay=p
_.CW=q
_.cx=r
_.a=s},
c1Z:function c1Z(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
azq:function azq(){},
fjr:function fjr(){},
fjD:function fjD(d){this.a=d},
fjC:function fjC(d){this.a=d},
fjB:function fjB(d){this.a=d},
fjy:function fjy(d){this.a=d},
fjt:function fjt(d){this.a=d},
fjA:function fjA(d,e){this.a=d
this.b=e},
fjz:function fjz(d){this.a=d},
fjs:function fjs(d){this.a=d},
fjx:function fjx(d,e){this.a=d
this.b=e},
fjv:function fjv(d,e){this.a=d
this.b=e},
fjw:function fjw(d,e){this.a=d
this.b=e},
fju:function fju(d){this.a=d},
b_c:function b_c(d,e,f,g,h,i,j,k){var _=this
_.d=$
_.e=d
_.w=_.r=_.f=null
_.RO$=e
_.RP$=f
_.xP$=g
_.a1A$=h
_.w8$=i
_.c4$=j
_.ah$=k
_.c=_.a=null},
evR:function evR(d){this.a=d},
evQ:function evQ(){},
evO:function evO(){},
evS:function evS(d,e,f){this.a=d
this.b=e
this.c=f},
evP:function evP(){},
evW:function evW(d){this.a=d},
evT:function evT(d,e){this.a=d
this.b=e},
evU:function evU(d,e){this.a=d
this.b=e},
evV:function evV(d,e){this.a=d
this.b=e},
bg1:function bg1(){},
cCX:function cCX(){},
iDg(d,e){var x
switch(d.a){case 0:x=1000
break
case 1:x=6e4
break
case 2:x=36e5
break
case 3:x=864e5
break
case 4:x=6048e5
break
case 5:x=2629746e3
break
case 6:x=31556952e3
break
default:x=null}return e*x},
iST(d,e,f){var x,w
A:{if(D.E7===f){x=d.bSr(new F.lA(B.eA(e),B.hH(e),B.En(e)),!0)
break A}if(D.E8===f||D.E9===f){x=d.aQa(new F.lA(B.eA(e),B.hH(e),B.En(e)))
break A}if(D.ZI===f||D.aAs===f){x=d.gby()
w=d.gby()
w=B.mq(x.fx,e,d.gb0(),w,d.gb1())
x=w
break A}if(D.P9===f){if(B.a8(e)===1){x=d.gby()
w=d.gby()
w=B.mq(x.go,e,d.gb0(),w,d.gb1())
x=w}else{x=d.gby()
w=d.gby()
w=B.mq(x.fy,e,d.gb0(),w,d.gb1())
x=w}break A}if(D.Pa===f){x=d.gby()
w=d.gby()
w=B.mq(x.go,e,d.gb0(),w,d.gb1())
x=w
break A}x=null}return x},
iSU(d,e,f){var x,w,v,u,t=(e.a-d.a)/Math.max(1,f)
for(x=0;x<19;++x){w=D.cyC[x]
v=w.a
u=w.b
if(A.iDg(v,u)>=t)return new B.x(v,u)}return new B.x(D.Pa,Math.max(1,C.i.ag(E.hI8(0,t/A.iDg(D.Pa,1),1))))},
iSS(d,e,f){var x
switch(e.a){case 0:x=B.P(B.a4(d),B.a8(d),B.av(d),B.eA(d),B.hH(d),B.En(d)-C.o.a5(B.En(d),f),0)
break
case 1:x=B.P(B.a4(d),B.a8(d),B.av(d),B.eA(d),B.hH(d)-C.o.a5(B.hH(d),f),0,0)
break
case 2:x=B.P(B.a4(d),B.a8(d),B.av(d),B.eA(d)-C.o.a5(B.eA(d),f),0,0,0)
break
case 3:x=B.P(B.a4(d),B.a8(d),B.av(d)-C.o.a5(B.av(d)-1,f),0,0,0,0)
break
case 4:x=B.P(B.a4(d),B.a8(d),B.av(d)-(B.b0(d)-1),0,0,0,0)
break
case 5:x=B.P(B.a4(d),B.a8(d)-C.o.a5(B.a8(d)-1,f),1,0,0,0,0)
break
case 6:x=B.P(B.a4(d)-C.o.a5(B.a4(d),f),1,1,0,0,0,0)
break
default:x=null}return x},
iqK(d,e,f){var x
switch(e.a){case 0:x=B.P(B.a4(d),B.a8(d),B.av(d),B.eA(d),B.hH(d),B.En(d)+f,0)
break
case 1:x=B.P(B.a4(d),B.a8(d),B.av(d),B.eA(d),B.hH(d)+f,0,0)
break
case 2:x=B.P(B.a4(d),B.a8(d),B.av(d),B.eA(d)+f,0,0,0)
break
case 3:x=B.P(B.a4(d),B.a8(d),B.av(d)+f,0,0,0,0)
break
case 4:x=B.P(B.a4(d),B.a8(d),B.av(d)+7*f,0,0,0,0)
break
case 5:x=B.P(B.a4(d),B.a8(d)+f,1,0,0,0,0)
break
case 6:x=B.P(B.a4(d)+f,1,1,0,0,0,0)
break
default:x=null}return x},
Gp:function Gp(d,e){this.a=d
this.b=e},
cY1:function cY1(d,e,f,g,h){var _=this
_.c=d
_.d=e
_.e=f
_.a=g
_.b=h},
LO:function LO(d,e,f,g){var _=this
_.c=d
_.f=e
_.a=f
_.b=g}},D,F,G,H,K,L
J=c[1]
B=c[0]
C=c[2]
I=c[264]
E=c[182]
A=a.updateHolder(c[125],A)
D=c[438]
F=c[143]
G=c[251]
H=c[272]
K=c[437]
L=c[266]
A.kD.prototype={
i(d,e){if(e==null)return!1
return e instanceof A.kD&&e.a===this.a&&e.b==this.b},
ga2(d){return B.aL(this.a,this.b,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
A(d){return"DesignChartPoint("+B.am(this.a)+", "+B.am(this.b)+")"}}
A.kE.prototype={
i(d,e){if(e==null)return!1
return e instanceof A.kE&&e.a===this.a&&B.bZ(e.b,this.b)},
ga2(d){return B.aL(this.a,B.cB(this.b),C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
A(d){return"DesignChartSeries("+this.a+", "+this.b.length+" points)"}}
A.brR.prototype={
X(){return"DesignChartXAxis."+this.b}}
A.Dq.prototype={
i(d,e){if(e==null)return!1
return e instanceof A.Dq&&e.a===this.a&&e.b===this.b},
ga2(d){return B.aL(this.a,this.b,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
A(d){return"DesignChartPointRef("+this.a+", "+this.b+")"}}
A.ls.prototype={
amz(d){var x=this.r[d.a].b[d.b],w=this.c.ki(0,x.a),v=this.d,u=x.b
return new B.t(w,v.ki(0,u==null?v.c:u))}}
A.YS.prototype={
n(){var x=null
return new A.b_c(D.ahG,x,!1,!1,!1,x,x,x)},
e0(d,e){return this.d.$2(d,e)}}
A.c1Z.prototype={}
A.azq.prototype={
sMR(d){var x,w,v=d==null
if(this.w8$==null!==v){x=$.au
w=this.gben()
if(v)x.an$.d.a.e.ak(0,w)
else x.an$.d.a.e.G(0,w)}this.w8$=d},
beo(d){var x,w,v,u,t,s=this,r=null
if(!(d instanceof B.dr)||!d.b.i(0,C.fc)||s.w8$==null||s.c==null)return C.ad
x=s.c
x.toString
w=B.hR(x,r,y.X)
x=y.F
v=y.g
while(w!=null){if(!w.giX())return C.ad
u=w.b
if(u==null)w=r
else{t=u.c
t.toString
t=B.Q(t,r,v)
w=x.a(t==null?r:t.Q)}}s.K1()
return C.aH},
gEB(){var x=this.ga4X()
if(x==null){x=this.RO$
if(x==null){x=B.bF(!0,null,!0,!0,null,null,!1)
this.RO$=x}}return x},
aUW(d){var x,w=this
if(d==w.ga4X())return
x=d==null?w.RO$:d
if(x!=null)x.S(w.gNR())
w.gEB().ad(w.gNR())},
aPg(){var x,w=this
w.sMR(null)
w.gEB().S(w.gNR())
x=w.RO$
if(x!=null)x.k()},
bhu(){var x=this
if(x.c==null)return
if(!x.gEB().gbj()&&x.gakk()&&x.w8$==null)x.K1()
else x.m(new A.fjr())},
gaTj(){var x=B.az(y.C)
if(this.gEB().gbj())x.G(0,C.x)
if(this.RP$)x.G(0,C.a_)
return x},
aTi(d,e,f,g,h,i,j,k,l,m,n){var x,w=this,v=null,u=w.c
u.toString
B.X(u,H.M,y.r)
u=new A.fjD(w)
x=w.gEB()
return B.B(v,v,v,B.d6(!1,v,I.xF(B.c4(B.ct(C.an,new B.a0(!0,e,v),C.q,!0,v,v,u,v,new A.fju(u),new A.fjv(w,l),new A.fjw(w,l),v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,new A.fjx(w,l),v,v,v,v,v,v,v,v),C.af,v,v,new A.fjy(w),new A.fjz(w),new A.fjA(w,l),!0),!1,v,!0,v,v,v,new A.fjB(w),v,v),v,v,v,x,!0,v,v,v,new A.fjC(h),v,v),!0,v,v,v,m,v,!1,v,!1,v,v,v,v,v,v,v,v,g,v,v,f,v,v,v,v,v,v,v,v,v,v,v,v,j,v,v,v,v,v,i,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,C.l,n)}}
A.b_c.prototype={
gEv(){var x,w=this,v=w.d
if(v===$){x=B.fk(null,1,w)
x.dR()
x.fd$.G(0,new A.evR(w))
w.d!==$&&B.aH()
w.d=x
v=x}return v},
ga4X(){return this.a.ay},
gakk(){return this.r!=null},
K1(){return this.EW(null,null)},
aq(){this.aA()
this.gEB().ad(this.gNR())},
af(d){var x,w,v,u,t,s=this
s.am(d)
s.aUW(d.ay)
if(B.bZ(d.c,s.a.c)){x=s.a
x=d.f===x.f&&d.x===x.x&&d.y===x.y}else x=!1
if(x)return
x=s.gEv()
w=x.x
w===$&&B.l()
s.e=s.Ny(w,d)
s.f=s.awf(w,d)
x.sq(0)
w=s.c
w.toString
w=G.bG(w)
v=s.a
u=v.CW
v=v.cx
G.ec(x,1,B.io(1,w?1:u,v),K.b0,null)
t=s.r
if(t!=null){x=t.a
w=!1
if(x>=0){v=s.a.c
if(x<v.length){u=t.b
if(u>=0){x=v[x].b
x=u<x.length&&x[u].b!=null}else x=w}else x=w}else x=w
x=!x}else x=!1
if(x){s.r=null
s.sMR(null)
s.xP$=!1
s.a.toString}},
k(){this.gEv().k()
this.aPg()
this.b2I()},
awf(d,e){var x,w,v,u,t=A.izD(e),s=this.f
if(s==null||d>=1)return t
x=B.bt(s.a,t.a,d)
x.toString
w=B.bt(s.b,t.b,d)
w.toString
v=B.bt(s.c,t.c,d)
v.toString
u=B.bt(s.d,t.d,d)
u.toString
return new A.c1Z(x,w,v,u)},
Ny(d,e){var x,w,v,u,t,s,r,q,p,o,n,m,l,k
if(d>=1||this.e.length===0)return e.c
x=A.izD(e)
w=C.o.I(0,x.c,x.d)
v=B.a([],y.t)
for(u=e.c,t=y.A,s=0;s<u.length;++s){r=u[s]
q=B.a([],t)
for(p=0;o=u[s].b,p<o.length;++p){n=this.e
m=s<n.length&&p<n[s].b.length?n[s].b[p]:null
l=o[p]
o=l.b
if(o==null)o=l
else{n=m==null
k=n?null:m.a
if(k==null)k=l.a
k=B.bt(k,l.a,d)
k.toString
n=n?null:m.b
o=new A.kD(k,B.bt(n==null?w:n,o,d))}q.push(o)}v.push(new A.kE(r.a,q))}return v},
agH(d,e){var x=this.a
return A.jeA(d,e,x.f,x.r,x.z,A.jez(x.c))},
agI(d,e){var x=this.a.Q
x=x==null?null:x.$1(d)
return x==null?B.dg(d,B.cM(e.gby()),null,null):x},
Yi(d,e){var x=this.a.c[d.a],w=x.b[d.b],v=this.agH(w.a,e),u=w.b
u.toString
return e.a0d(v,x.a,this.agI(u,e))},
aff(d){var x,w,v,u,t,s,r,q,p,o,n,m,l=this,k=l.a,j=k.as
if(j!=null)return j
x=B.az(y.i)
for(k=k.c,w=k.length,v=1/0,u=-1/0,t=0;t<k.length;k.length===w||(0,B.D)(k),++t)for(s=k[t].b,r=s.length,q=0;q<s.length;s.length===r||(0,B.D)(s),++q){p=s[q]
o=p.b
if(o==null)continue
x.G(0,p.a)
v=Math.min(v,o)
u=Math.max(u,o)}k=y.s
n=B.a([d.ahE(l.a.c.length)],k)
if(x.a!==0){m=B.aI(x,x.$ti.c)
C.c.l8(m)
C.c.E(n,B.a([d.ahD(m.length),d.JZ(l.agH(C.c.gae(m),d),l.agH(C.c.gb6(m),d)),d.QG(l.agI(v,d),l.agI(u,d))],k))}return C.c.aM(n,d.gwj())},
zc(d,e,f){var x,w=this,v=d==null
if(v)w.xP$=!1
x=J.z(d,w.r)
if(x&&e==w.w8$)return
w.m(new A.evS(w,d,e))
if(x)return
w.a.toString
if(f&&!v){v=w.c
v.toString
x=B.X(v,H.M,y.r)
G.y_(v,w.Yi(d,x==null?C.L:x))}},
EW(d,e){return this.zc(d,e,!1)},
bub(d){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h=null,g=this.w
if(g==null)return h
x=g.c
w=x instanceof A.LO
v=w?x.bUf(d.a):h
if(w&&v==null)return h
for(w=d.a,u=g.d,t=d.b,s=g.r,r=h,q=1/0,p=1/0,o=0;o<this.a.c.length;++o){n=s[o].b
for(m=0;m<n.length;++m){l=n[m]
k=l.b
if(k==null)continue
if(v!=null&&C.i.ag(l.a)!==v)continue
j=Math.abs(x.ki(0,l.a)-w)
i=Math.abs(u.ki(0,k)-t)
if(!(j<q-0.5))l=j<=q+0.5&&i<p
else l=!0
if(l){r=new A.Dq(o,m)
q=Math.min(j,q)
p=i}}}return r},
UZ(d,e){var x=d.a,w=this.a.c[x].b,v=d.b+e,u=w.length
for(;;){if(!(v>=0&&v<u))break
if(w[v].b!=null)return new A.Dq(x,v)
v+=e}return null},
a7d(d,e){var x,w,v,u,t
for(x=d;w=this.a.c,x<w.length;++x){v=w[x].b.length
w=e?v:-1
u=e?-1:1
t=this.UZ(new A.Dq(x,w),u)
if(t!=null)return t}return null},
aI6(d){var x,w,v,u,t=this,s=t.r,r=s==null,q=r?null:t.UZ(s,d)
if(q!=null)return q
if(r)x=d>0?-1:t.a.c.length
else x=s.a
w=x+d
r=d>0
for(;;){if(!(w>=0&&w<t.a.c.length))break
v=t.a.c[w].b.length
u=t.UZ(new A.Dq(w,r?-1:v),d)
if(u!=null)return u
w+=d}return null},
b6g(d,e){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j=this.a.c,i=d.a,h=j[i].b[d.b],g=h.b
g.toString
for(x=j.length,w=e>0,v=h.a,u=null,t=null,s=0;s<x;++s){if(s===i)continue
r=j[s].b
for(q=r.length,p=s<i,o=s>i,n=0;n<q;++n){m=r[n]
l=m.b
if(l==null||m.a!==v)continue
k=!0
if(w){if(!(l>g)){m=l===g&&o
k=m}}else if(!(l<g)){m=l===g&&p
k=m}if(k)if(t!=null)m=w?l<t:l>t
else m=!0
else m=!1
if(m){u=new A.Dq(s,n)
t=l}}}return u},
abP(d){var x,w,v=this,u=null,t=v.c.t(y.I).w,s=v.r
if(d.i(0,C.fc)){if(s==null)return C.ad
v.EW(u,u)
return C.aH}else if(d.i(0,C.bI)||d.i(0,C.bU)){x=d.i(0,C.bI)!==(t===C.I)?1:-1
if(s==null)w=v.a7d(0,x<0)
else{t=v.UZ(s,x)
w=t==null?s:t}}else if(d.i(0,C.bD)||d.i(0,C.bn)){x=d.i(0,C.bD)?1:-1
if(s==null)w=v.a7d(0,!1)
else{t=v.b6g(s,x)
w=t==null?s:t}}else if(d.i(0,C.cu)||d.i(0,C.cE)){t=s==null?u:s.a
if(t==null)t=0
w=v.a7d(t,d.i(0,C.cE))}else return C.ad
if(w!=null)v.zc(w,u,!0)
return C.aH},
b9P(d,e){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i=this,h=null,g=i.gEv().x
g===$&&B.l()
x=i.a
x.toString
w=i.awf(g,x)
v=i.c.t(y.I).w
u=v===C.I
t=i.a.w.L(v).ou(new B.C(0,0,0+d.a,0+d.b))
s=u?t.c:t.a
r=u?t.a:t.c
x=i.a
switch(x.f.a){case 0:q=new E.AC(w.a,w.b,h,s,r)
p=q
q=x
x=p
break
case 1:q=B.YN(C.i.ag(w.a),0,!1)
o=B.YN(C.i.ag(w.b),0,!1)
o=new A.cY1(new B.bj(q,0,!1),new B.bj(o,0,!1),new E.AC(q,o,h,s,r),s,r)
q=x
x=o
break
case 2:x=A.izC(x)
q=i.a
x=new A.LO(x,q.r,s,r)
break
default:q=x
x=h}n=new E.AC(w.c,w.d,h,t.d,t.b)
o=new A.evP()
m=i.Ny(g,q)
l=i.r
k=l==null?h:m[l.a].b[l.b]
g=o.$2(x.Az(e,i.a.y),i.a.z)
o=o.$2(n.Az(e,i.a.y),i.a.Q)
if(k==null)q=h
else{q=x.ki(0,k.a)
j=k.b
j.toString
j=new B.t(q,n.ki(0,j))
q=j}return new A.ls(d,t,x,n,g,o,m,l,q,i.w8$,i.gaTj())},
h(d){var x,w,v,u,t,s,r,q,p,o=this,n=null,m=B.X(d,H.M,y.r)
if(m==null)m=C.L
x=o.r
w=o.aI6(1)
v=o.aI6(-1)
u=o.a.e
t=x==null?o.aff(m):o.Yi(x,m)
o.a.toString
s=w==null
r=s?n:new A.evT(o,w)
q=v==null
p=q?n:new A.evU(o,v)
s=s?n:o.Yi(w,m)
q=q?n:o.Yi(v,m)
o.a.toString
return o.aTi(!1,new L.a9(new A.evV(o,m),n),u,s,o.gabO(),r,p,n,new A.evW(o),q,t)}}
A.bg1.prototype={
k(){var x=this,w=x.ah$
if(w!=null)w.S(x.gcK())
x.ah$=null
x.K()},
br(){this.bB()
this.bA()
this.cL()}}
A.cCX.prototype={}
A.Gp.prototype={
X(){return"_Unit."+this.b}}
A.cY1.prototype={
ki(d,e){return this.e.ki(0,e)},
Az(d,e){var x,w,v,u=this.c,t=this.d,s=A.iSU(u,t,e),r=s.a,q=s.b,p=B.a([],y.z),o=A.iSS(u,r,q)
if(o.ft(u))o=A.iqK(o,r,q)
u=this.e
x=t.a
t=t.b
for(;;){w=o.a
if(w<=x)v=w===x&&o.b>t
else v=!0
if(!(!v&&p.length<1000))break
p.push(new E.qr(w,u.ki(0,w),A.iST(d,o,r)))
o=A.iqK(o,r,q)}return p},
A(d){var x=this
return"DesignTimeScale("+x.c.A(0)+"\u2013"+x.d.A(0)+" \u2192 "+B.am(x.a)+"\u2013"+B.am(x.b)+")"}}
A.LO.prototype={
gm0(){return(this.b-this.a)/Math.max(1,this.c-0.1+0.1)},
gahg(){return Math.abs(this.gm0()*0.9)},
gatn(){return this.a+this.gm0()*0.05},
ki(d,e){var x=this
return x.gatn()+x.gm0()*e+J.lJ(x.gm0())*x.gahg()/2},
bUC(d){var x=this
if(x.gm0()===0)return 0
return(d-x.gatn()-J.lJ(x.gm0())*x.gahg()/2)/x.gm0()},
bUf(d){var x,w=this,v=w.c
if(v===0||w.gm0()===0)return null
x=C.i.ag(w.bUC(d))
if(x<0||x>=v)return null
return Math.abs(w.ki(0,x)-d)<=Math.abs(w.gm0())/2?x:null},
Az(d,e){var x,w,v,u,t,s,r,q,p,o,n=this,m=B.a([],y.z)
for(x=n.c,w=n.f,v=w!=null,u=n.a,t=0;t<x;++t){s=n.gm0()
r=n.gm0()
q=J.lJ(n.gm0())
p=n.gm0()
o=v&&t<w.length?w[t]:B.dg(t+1,B.cM(d.gby()),null,null)
m.push(new E.qr(t,u+s*0.05+r*t+q*Math.abs(p*0.9)/2,o))}return m},
A(d){return"DesignBandScale("+this.c+" bands, "+B.am(this.a)+"\u2013"+B.am(this.b)+")"}}
var z=a.updateTypes(["dU(di)","~()","dU(ar)","u(u,kE)","U<qr>(U<qr>,m(p)?)"])
A.fjr.prototype={
$0(){},
$S:0}
A.fjD.prototype={
$0(){var x,w=this.a
if(!w.a1A$)return
x=w.a1A$=!1
if(!(w.RP$?w.w8$===C.fP:x))w.K1()},
$S:0}
A.fjC.prototype={
$2(d,e){return e instanceof B.dr||e instanceof B.fG?this.a.$1(e.b):C.ad},
$S:25}
A.fjB.prototype={
$1(d){var x=this.a
if(!x.xP$)return
x.xP$=!1
x.K1()},
$S:54}
A.fjy.prototype={
$1(d){var x=this.a
return x.m(new A.fjt(x))},
$S:19}
A.fjt.prototype={
$0(){return this.a.RP$=!0},
$S:0}
A.fjA.prototype={
$1(d){if(!this.a.xP$)this.b.$2(d.gie(),C.fP)},
$S:48}
A.fjz.prototype={
$1(d){var x=this.a
x.m(new A.fjs(x))
if(x.w8$===C.fP)x.K1()},
$S:20}
A.fjs.prototype={
$0(){return this.a.RP$=!1},
$S:0}
A.fjx.prototype={
$1(d){var x=d.c
if(x===C.fP)return
this.b.$2(d.b,x)
x=this.a
x.xP$=x.gakk()},
$S:60}
A.fjv.prototype={
$1(d){var x=this.a
x.xP$=!1
x.a1A$=!0
x=d.d
if(x==null)x=C.eU
this.b.$2(d.b,x)},
$S:45}
A.fjw.prototype={
$1(d){var x=this.a.w8$
if(x==null)x=C.eU
return this.b.$2(d.b,x)},
$S:33}
A.fju.prototype={
$1(d){return this.a.$0()},
$S:40}
A.evR.prototype={
$0(){return this.a.m(new A.evQ())},
$S:0}
A.evQ.prototype={
$0(){},
$S:0}
A.evO.prototype={
$2(d,e){return Math.max(d,e.b.length)},
$S:z+3}
A.evS.prototype={
$0(){var x=this.a,w=this.b
x.r=w
x.sMR(w==null?null:this.c)},
$S:0}
A.evP.prototype={
$2(d,e){var x,w,v,u,t
if(e==null)x=d
else{x=B.a([],y.z)
for(w=d.length,v=0;v<d.length;d.length===w||(0,B.D)(d),++v){u=d[v]
t=u.a
x.push(new E.qr(t,u.b,e.$1(t)))}}return x},
$S:z+4}
A.evW.prototype={
$2(d,e){var x=this.a
return x.EW(x.bub(d),e)},
$S:578}
A.evT.prototype={
$0(){return this.a.zc(this.b,null,!0)},
$S:0}
A.evU.prototype={
$0(){return this.a.zc(this.b,null,!0)},
$S:0}
A.evV.prototype={
$2(d,e){var x,w,v,u=e.b
u=isFinite(u)?u:300
x=e.d
x=isFinite(x)?x:u/2
w=this.a
v=w.w=w.b9P(new B.H(u,x),this.b)
return I.mE(w.a.e0(d,v),v.a)},
$S:62};(function aliases(){var x=A.bg1.prototype
x.b2I=x.k})();(function installTearOffs(){var x=a._instance_1u,w=a._instance_0u
var v
x(v=A.azq.prototype,"gben","beo",0)
w(v,"gNR","bhu",1)
x(A.b_c.prototype,"gabO","abP",2)})();(function inheritance(){var x=a.mixinHard,w=a.mixin,v=a.inheritMany,u=a.inherit
v(B.W,[A.kD,A.kE,A.Dq,A.ls,A.c1Z,A.azq])
v(B.eg,[A.brR,A.Gp])
u(A.YS,B.i)
v(B.cU,[A.fjr,A.fjD,A.fjt,A.fjs,A.evR,A.evQ,A.evS,A.evT,A.evU])
v(B.de,[A.fjC,A.evO,A.evP,A.evW,A.evV])
v(B.cj,[A.fjB,A.fjy,A.fjA,A.fjz,A.fjx,A.fjv,A.fjw,A.fju])
u(A.bg1,B.k)
u(A.cCX,A.bg1)
u(A.b_c,A.cCX)
v(E.bs_,[A.cY1,A.LO])
x(A.bg1,B.cW)
w(A.cCX,A.azq)})()
B.bM(b.typeUniverse,JSON.parse('{"YS":{"i":[],"b":[]},"b_c":{"k":["YS"]}}'))
B.jn(b.typeUniverse,JSON.parse('{"azq":1}'))
var y=(function rtii(){var x=B.E
return{I:x("dt"),A:x("o<kD>"),t:x("o<kE>"),z:x("o<qr>"),s:x("o<m>"),r:x("dN"),C:x("S"),g:x("ahm"),i:x("p"),F:x("dp<W?>?"),X:x("W?")}})();(function constants(){var x=a.makeConstList
D.oX=new A.brR(0,"linear")
D.ry=new A.brR(2,"band")
D.E7=new A.Gp(0,"second")
D.d_b=new B.x(D.E7,1)
D.d_e=new B.x(D.E7,5)
D.d_c=new B.x(D.E7,15)
D.d_d=new B.x(D.E7,30)
D.E8=new A.Gp(1,"minute")
D.d_f=new B.x(D.E8,1)
D.d_i=new B.x(D.E8,5)
D.d_g=new B.x(D.E8,15)
D.d_h=new B.x(D.E8,30)
D.E9=new A.Gp(2,"hour")
D.d_j=new B.x(D.E9,1)
D.d_l=new B.x(D.E9,3)
D.d_m=new B.x(D.E9,6)
D.d_k=new B.x(D.E9,12)
D.ZI=new A.Gp(3,"day")
D.d_n=new B.x(D.ZI,1)
D.d_o=new B.x(D.ZI,2)
D.aAs=new A.Gp(4,"week")
D.d_p=new B.x(D.aAs,1)
D.P9=new A.Gp(5,"month")
D.d_q=new B.x(D.P9,1)
D.d_r=new B.x(D.P9,3)
D.d_s=new B.x(D.P9,6)
D.Pa=new A.Gp(6,"year")
D.d_t=new B.x(D.Pa,1)
D.cyC=x([D.d_b,D.d_e,D.d_c,D.d_d,D.d_f,D.d_i,D.d_g,D.d_h,D.d_j,D.d_l,D.d_m,D.d_k,D.d_n,D.d_o,D.d_p,D.d_q,D.d_r,D.d_s,D.d_t],B.E("o<+(Gp,u)>"))
D.ahG=x([],y.t)})()};
(a=>{a["IaKzjwONFNs+XOIoMA9KwCgy8q4="]=a.current})($__dart_deferred_initializers__);