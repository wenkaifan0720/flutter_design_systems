((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,C,I,B={
ily(d){var x,w,v,u,t,s,r
for(x=d.length,w=1/0,v=0;v<x;++v)for(u=d[v].b,t=u.length,s=1;s<t;++s){r=Math.abs(u[s].a-u[s-1].a)
if(r>0)w=Math.min(w,r)}return w},
ilz(d,e,f,g,h,i){var x,w,v,u,t=null
if(h!=null)return h.$1(d)
switch(f.a){case 0:return A.ec(d,A.dH(e.gco()),t,t)
case 2:x=C.i.ac(d)
return g!=null&&x>=0&&x<g.length?g[x]:A.ec(x+1,A.dH(e.gco()),t,t)
case 1:w=new A.bQ(A.ago(C.i.ac(d),0,!1),0,!1)
if(i==1/0||i==-1/0)return e.iK(w)
if(i>=31536e6){v=e.gco()
u=e.gco()
return A.AU(v.go,w,e.gaX(),u,e.gaY())}if(i>=24192e5)return e.lF(w)
if(i>=864e5)return e.iK(w)
v=e.gco()
u=e.gco()
return A.AU(v.fx,w,e.gaX(),u,e.gaY())+e.gua()+e.aMp(new F.q_(A.eR(w),A.iD(w),A.CF(w)))}},
ags(d,e,f,g,h,i,j,k,l,m,n,o,p){return new B.Vy(m,d,k,o,e,j,p,n,g,h,l,i,f,null)},
hLm(d){var x=d.r
x=x==null?null:x.length
return x==null?C.c.bk(d.c,0,new B.e56()):x},
hLn(d){var x,w,v,u,t,s,r,q,p,o,n,m,l
for(x=d.c,w=x.length,v=1/0,u=-1/0,t=1/0,s=-1/0,r=0;r<w;++r)for(q=x[r].b,p=q.length,o=0;o<p;++o){n=q[o]
m=n.a
v=Math.min(v,m)
u=Math.max(u,m)
l=n.b
if(l==null)continue
t=Math.min(t,l)
s=Math.max(s,l)}if(d.f===D.w_){u=Math.max(0,B.hLm(d)-1)
v=0}if(v>u){v=0
u=1}if(t>s){t=0
s=1}l=E.bgw(1,d.x,s,t,0,d.y)
return new B.bP1(v,u,l.c,l.d)},
o_:function o_(d,e){this.a=d
this.b=e},
n0:function n0(d,e){this.a=d
this.b=e},
bgq:function bgq(d,e){this.a=d
this.b=e},
Jj:function Jj(d,e){this.a=d
this.b=e},
pV:function pV(d,e,f,g,h,i,j,k,l){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.f=h
_.r=i
_.w=j
_.y=k
_.z=l},
Vy:function Vy(d,e,f,g,h,i,j,k,l,m,n,o,p,q){var _=this
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
_.ax=o
_.ay=p
_.a=q},
bP1:function bP1(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
aRB:function aRB(d,e,f,g,h,i,j,k){var _=this
_.d=$
_.e=d
_.w=_.r=_.f=null
_.Qm$=e
_.Qn$=f
_.wV$=g
_.a00$=h
_.vi$=i
_.cd$=j
_.ap$=k
_.c=_.a=null},
e59:function e59(d){this.a=d},
e58:function e58(){},
e56:function e56(){},
e5a:function e5a(d,e,f){this.a=d
this.b=e
this.c=f},
e57:function e57(){},
e5e:function e5e(d){this.a=d},
e5b:function e5b(d,e){this.a=d
this.b=e},
e5c:function e5c(d,e){this.a=d
this.b=e},
e5d:function e5d(d,e){this.a=d
this.b=e},
b5h:function b5h(){},
clU:function clU(){},
hOr(d,e){var x
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
i29(d,e,f){var x,w
A:{if(D.Cv===f){x=d.bMe(new F.q_(A.eR(e),A.iD(e),A.CF(e)),!0)
break A}if(D.Cw===f||D.Cx===f){x=d.aMp(new F.q_(A.eR(e),A.iD(e),A.CF(e)))
break A}if(D.X2===f||D.avZ===f){x=d.gco()
w=d.gco()
w=A.AU(x.fx,e,d.gaX(),w,d.gaY())
x=w
break A}if(D.Ne===f){if(A.ad(e)===1){x=d.gco()
w=d.gco()
w=A.AU(x.go,e,d.gaX(),w,d.gaY())
x=w}else{x=d.gco()
w=d.gco()
w=A.AU(x.fy,e,d.gaX(),w,d.gaY())
x=w}break A}if(D.Nf===f){x=d.gco()
w=d.gco()
w=A.AU(x.go,e,d.gaX(),w,d.gaY())
x=w
break A}x=null}return x},
i2a(d,e,f){var x,w,v,u,t=(e.a-d.a)/Math.max(1,f)
for(x=0;x<19;++x){w=D.cqD[x]
v=w.a
u=w.b
if(B.hOr(v,u)>=t)return new A.y(v,u)}return new A.y(D.Nf,Math.max(1,C.i.ac(E.hwZ(0,t/B.hOr(D.Nf,1),1))))},
i28(d,e,f){var x
switch(e.a){case 0:x=A.O(A.a5(d),A.ad(d),A.aq(d),A.eR(d),A.iD(d),A.CF(d)-C.n.a1(A.CF(d),f),0)
break
case 1:x=A.O(A.a5(d),A.ad(d),A.aq(d),A.eR(d),A.iD(d)-C.n.a1(A.iD(d),f),0,0)
break
case 2:x=A.O(A.a5(d),A.ad(d),A.aq(d),A.eR(d)-C.n.a1(A.eR(d),f),0,0,0)
break
case 3:x=A.O(A.a5(d),A.ad(d),A.aq(d)-C.n.a1(A.aq(d)-1,f),0,0,0,0)
break
case 4:x=A.O(A.a5(d),A.ad(d),A.aq(d)-(A.bY(d)-1),0,0,0,0)
break
case 5:x=A.O(A.a5(d),A.ad(d)-C.n.a1(A.ad(d)-1,f),1,0,0,0,0)
break
case 6:x=A.O(A.a5(d)-C.n.a1(A.a5(d),f),1,1,0,0,0,0)
break
default:x=null}return x},
hCC(d,e,f){var x
switch(e.a){case 0:x=A.O(A.a5(d),A.ad(d),A.aq(d),A.eR(d),A.iD(d),A.CF(d)+f,0)
break
case 1:x=A.O(A.a5(d),A.ad(d),A.aq(d),A.eR(d),A.iD(d)+f,0,0)
break
case 2:x=A.O(A.a5(d),A.ad(d),A.aq(d),A.eR(d)+f,0,0,0)
break
case 3:x=A.O(A.a5(d),A.ad(d),A.aq(d)+f,0,0,0,0)
break
case 4:x=A.O(A.a5(d),A.ad(d),A.aq(d)+7*f,0,0,0,0)
break
case 5:x=A.O(A.a5(d),A.ad(d)+f,1,0,0,0,0)
break
case 6:x=A.O(A.a5(d)+f,1,1,0,0,0,0)
break
default:x=null}return x},
El:function El(d,e){this.a=d
this.b=e},
cFa:function cFa(d,e,f,g,h){var _=this
_.c=d
_.d=e
_.e=f
_.a=g
_.b=h},
aAn:function aAn(d,e,f,g){var _=this
_.c=d
_.f=e
_.a=f
_.b=g}},D,K,E,F,G,H,L,M
J=c[1]
A=c[0]
C=c[2]
I=c[238]
B=a.updateHolder(c[102],B)
D=c[402]
K=c[107]
E=c[164]
F=c[125]
G=c[226]
H=c[260]
L=c[563]
M=c[240]
B.o_.prototype={
i(d,e){if(e==null)return!1
return e instanceof B.o_&&e.a===this.a&&e.b==this.b},
gY(d){return A.aA(this.a,this.b,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
v(d){return"DesignChartPoint("+A.ae(this.a)+", "+A.ae(this.b)+")"}}
B.n0.prototype={
i(d,e){if(e==null)return!1
return e instanceof B.n0&&e.a===this.a&&A.c7(e.b,this.b)},
gY(d){return A.aA(this.a,A.cs(this.b),C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
v(d){return"DesignChartSeries("+this.a+", "+this.b.length+" points)"}}
B.bgq.prototype={
U(){return"DesignChartXAxis."+this.b}}
B.Jj.prototype={
i(d,e){if(e==null)return!1
return e instanceof B.Jj&&e.a===this.a&&e.b===this.b},
gY(d){return A.aA(this.a,this.b,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
v(d){return"DesignChartPointRef("+this.a+", "+this.b+")"}}
B.pV.prototype={}
B.Vy.prototype={
n(){var x=null
return new B.aRB(D.adV,x,!1,!1,!1,x,x,x)},
fI(d,e){return this.d.$2(d,e)}}
B.bP1.prototype={}
B.aRB.prototype={
gDA(){var x,w=this,v=w.d
if(v===$){x=A.fa(null,1,w)
x.dD()
x.f7$.F(0,new B.e59(w))
w.d!==$&&A.ay()
w.d=x
v=x}return v},
ga3r(){return this.a.ay},
gahX(){return this.r!=null},
IU(){return this.DZ(null,null)},
ao(){this.aw()
this.gDF().aa(this.gMD())},
af(d){var x,w,v,u,t,s=this
s.an(d)
s.aRf(d.ay)
if(A.c7(d.c,s.a.c)){x=s.a
x=d.f===x.f&&d.x===x.x&&d.y===x.y}else x=!1
if(x)return
x=s.gDA()
w=x.x
w===$&&A.h()
s.e=s.Ml(w,d)
s.f=s.atg(w,d)
x.sq(0)
w=s.c
w.toString
G.bW(w)
s.a.toString
G.eC(x,1,A.k4(1,1,400),L.bf,null)
v=s.r
if(v!=null){x=v.a
w=!1
if(x>=0){u=s.a.c
if(x<u.length){t=v.b
if(t>=0){x=u[x].b
x=t<x.length&&x[t].b!=null}else x=w}else x=w}else x=w
x=!x}else x=!1
if(x){s.r=null
s.sLJ(null)
s.wV$=!1
s.a.toString}},
k(){this.gDA().k()
this.aLt()
this.aZD()},
atg(d,e){var x,w,v,u,t=B.hLn(e),s=this.f
if(s==null||d>=1)return t
x=A.bl(s.a,t.a,d)
x.toString
w=A.bl(s.b,t.b,d)
w.toString
v=A.bl(s.c,t.c,d)
v.toString
u=A.bl(s.d,t.d,d)
u.toString
return new B.bP1(x,w,v,u)},
Ml(d,e){var x,w,v,u,t,s,r,q,p,o,n,m,l,k
if(d>=1||this.e.length===0)return e.c
x=B.hLn(e)
w=C.n.I(0,x.c,x.d)
v=A.a([],y.q)
for(u=e.c,t=y.j,s=0;s<u.length;++s){r=u[s]
q=A.a([],t)
for(p=0;o=u[s].b,p<o.length;++p){n=this.e
m=s<n.length&&p<n[s].b.length?n[s].b[p]:null
l=o[p]
o=l.b
if(o==null)o=l
else{n=m==null
k=n?null:m.a
if(k==null)k=l.a
k=A.bl(k,l.a,d)
k.toString
n=n?null:m.b
o=new B.o_(k,A.bl(n==null?w:n,o,d))}q.push(o)}v.push(new B.n0(r.a,q))}return v},
aey(d,e){var x=this.a
return B.ilz(d,e,x.f,x.r,x.z,B.ily(x.c))},
aez(d,e){var x=this.a.Q.$1(d)
return x==null?A.ec(d,A.dH(e.gco()),null,null):x},
WI(d,e){var x=this.a.c[d.a],w=x.b[d.b],v=this.aey(w.a,e),u=w.b
u.toString
return e.ZF(v,x.a,this.aez(u,e))},
adh(d){var x,w,v,u,t,s,r,q,p,o,n,m,l=this,k=l.a,j=k.as
if(j!=null)return j
x=A.av(y.b)
for(k=k.c,w=k.length,v=1/0,u=-1/0,t=0;t<k.length;k.length===w||(0,A.G)(k),++t)for(s=k[t].b,r=s.length,q=0;q<s.length;s.length===r||(0,A.G)(s),++q){p=s[q]
o=p.b
if(o==null)continue
x.F(0,p.a)
v=Math.min(v,o)
u=Math.max(u,o)}k=y.x
n=A.a([d.afv(l.a.c.length)],k)
if(x.a!==0){m=A.aJ(x,x.$ti.c)
C.c.kC(m)
C.c.G(n,A.a([d.afu(m.length),d.Pi(l.aey(C.c.gag(m),d),l.aey(C.c.gb0(m),d)),d.ZE(l.aez(v,d),l.aez(u,d))],k))}return C.c.aZ(n,d.gua())},
yi(d,e,f){var x,w=this,v=d==null
if(v)w.wV$=!1
x=J.x(d,w.r)
if(x&&e==w.vi$)return
w.m(new B.e5a(w,d,e))
if(x)return
w.a.toString
if(f&&!v){v=w.c
v.toString
x=A.X(v,H.N,y.w)
G.uJ(v,w.WI(d,x==null?C.M:x))}},
DZ(d,e){return this.yi(d,e,!1)},
boT(d){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h=null,g=this.w
if(g==null)return h
x=g.c
w=x instanceof B.aAn
v=w?x.bO3(d.a):h
if(w&&v==null)return h
for(w=d.a,u=g.d,t=d.b,s=g.r,r=h,q=1/0,p=1/0,o=0;o<this.a.c.length;++o){n=s[o].b
for(m=0;m<n.length;++m){l=n[m]
k=l.b
if(k==null)continue
if(v!=null&&C.i.ac(l.a)!==v)continue
j=Math.abs(x.iU(0,l.a)-w)
i=Math.abs(u.iU(0,k)-t)
if(!(j<q-0.5))l=j<=q+0.5&&i<p
else l=!0
if(l){r=new B.Jj(o,m)
q=Math.min(j,q)
p=i}}}return r},
TA(d,e){var x=d.a,w=this.a.c[x].b,v=d.b+e,u=w.length
for(;;){if(!(v>=0&&v<u))break
if(w[v].b!=null)return new B.Jj(x,v)
v+=e}return null},
a5I(d,e){var x,w,v,u,t
for(x=d;w=this.a.c,x<w.length;++x){v=w[x].b.length
w=e?v:-1
u=e?-1:1
t=this.TA(new B.Jj(x,w),u)
if(t!=null)return t}return null},
aEF(d){var x,w,v,u,t=this,s=t.r,r=s==null,q=r?null:t.TA(s,d)
if(q!=null)return q
if(r)x=d>0?-1:t.a.c.length
else x=s.a
w=x+d
r=d>0
for(;;){if(!(w>=0&&w<t.a.c.length))break
v=t.a.c[w].b.length
u=t.TA(new B.Jj(w,r?-1:v),d)
if(u!=null)return u
w+=d}return null},
b1V(d,e){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j=this.a.c,i=d.a,h=j[i].b[d.b],g=h.b
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
if(m){u=new B.Jj(s,n)
t=l}}}return u},
aad(d){var x,w,v=this,u=null,t=v.c.t(y.o).w,s=v.r
if(d.i(0,C.eW)){if(s==null)return C.aa
v.DZ(u,u)
return C.ax}else if(d.i(0,C.bp)||d.i(0,C.by)){x=d.i(0,C.bp)!==(t===C.E)?1:-1
if(s==null)w=v.a5I(0,x<0)
else{t=v.TA(s,x)
w=t==null?s:t}}else if(d.i(0,C.bm)||d.i(0,C.b9)){x=d.i(0,C.bm)?1:-1
if(s==null)w=v.a5I(0,!1)
else{t=v.b1V(s,x)
w=t==null?s:t}}else if(d.i(0,C.cp)||d.i(0,C.cv)){t=s==null?u:s.a
if(t==null)t=0
w=v.a5I(t,d.i(0,C.cv))}else return C.aa
if(w!=null)v.yi(w,u,!0)
return C.ax},
b5o(d,e){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j=this,i=null,h=j.gDA().x
h===$&&A.h()
x=j.a
x.toString
w=j.atg(h,x)
v=j.c.t(y.o).w
u=v===C.E
t=j.a.w.J(v).p0(new A.z(0,0,0+d.a,0+d.b))
s=u?t.c:t.a
r=u?t.a:t.c
x=j.a
switch(x.f.a){case 0:q=new E.BD(w.a,w.b,i,s,r)
p=q
q=x
x=p
break
case 1:q=A.ago(C.i.ac(w.a),0,!1)
o=A.ago(C.i.ac(w.b),0,!1)
o=new B.cFa(new A.bQ(q,0,!1),new A.bQ(o,0,!1),new E.BD(q,o,i,s,r),s,r)
q=x
x=o
break
case 2:x=B.hLm(x)
q=j.a
x=new B.aAn(x,q.r,s,r)
break
default:q=x
x=i}n=new E.BD(w.c,w.d,i,t.d,t.b)
o=new B.e57()
m=j.Ml(h,q)
l=j.r
k=l==null?i:m[l.a].b[l.b]
o.$2(x.Gd(e,j.a.y),j.a.z)
h=o.$2(n.Gd(e,j.a.y),j.a.Q)
if(k!=null){x.iU(0,k.a)
q=k.b
q.toString
n.iU(0,q)}return new B.pV(d,t,x,n,h,m,l,j.vi$,j.gaPB())},
h(d){var x,w,v,u,t,s,r,q,p,o,n=this,m=null,l=A.X(d,H.N,y.w)
if(l==null)l=C.M
x=n.r
w=n.aEF(1)
v=n.aEF(-1)
u=n.a.e
t=x==null?n.adh(l):n.WI(x,l)
n.a.toString
s=w==null
r=s?m:new B.e5b(n,w)
q=v==null
p=q?m:new B.e5c(n,v)
s=s?m:n.WI(w,l)
q=q?m:n.WI(v,l)
o=n.a.ax
return n.aPA(!1,M.aE(new B.e5d(n,l)),u,s,n.gaac(),r,p,o,new B.e5e(n),q,t)}}
B.b5h.prototype={
k(){var x=this,w=x.ap$
if(w!=null)w.P(x.gdA())
x.ap$=null
x.K()},
br(){this.bD()
this.bC()
this.dB()}}
B.clU.prototype={}
B.El.prototype={
U(){return"_Unit."+this.b}}
B.cFa.prototype={
iU(d,e){return this.e.iU(0,e)},
Gd(d,e){var x,w,v,u=this.c,t=this.d,s=B.i2a(u,t,e),r=s.a,q=s.b,p=A.a([],y.c),o=B.i28(u,r,q)
if(o.fZ(u))o=B.hCC(o,r,q)
u=this.e
x=t.a
t=t.b
for(;;){w=o.a
if(w<=x)v=w===x&&o.b>t
else v=!0
if(!(!v&&p.length<1000))break
p.push(new E.rE(w,u.iU(0,w),B.i29(d,o,r)))
o=B.hCC(o,r,q)}return p},
v(d){var x=this
return"DesignTimeScale("+x.c.v(0)+"\u2013"+x.d.v(0)+" \u2192 "+A.ae(x.a)+"\u2013"+A.ae(x.b)+")"}}
B.aAn.prototype={
gqm(){return(this.b-this.a)/Math.max(1,this.c-0.1+0.1)},
gaIS(){return Math.abs(this.gqm()*0.9)},
gaqw(){return this.a+this.gqm()*0.05},
iU(d,e){var x=this
return x.gaqw()+x.gqm()*e+J.le(x.gqm())*x.gaIS()/2},
bOq(d){var x=this
if(x.gqm()===0)return 0
return(d-x.gaqw()-J.le(x.gqm())*x.gaIS()/2)/x.gqm()},
bO3(d){var x,w=this,v=w.c
if(v===0||w.gqm()===0)return null
x=C.i.ac(w.bOq(d))
if(x<0||x>=v)return null
return Math.abs(w.iU(0,x)-d)<=Math.abs(w.gqm())/2?x:null},
Gd(d,e){var x,w,v,u,t,s,r,q,p,o,n=this,m=A.a([],y.c)
for(x=n.c,w=n.f,v=w!=null,u=n.a,t=0;t<x;++t){s=n.gqm()
r=n.gqm()
q=J.le(n.gqm())
p=n.gqm()
o=v&&t<w.length?w[t]:A.ec(t+1,A.dH(d.gco()),null,null)
m.push(new E.rE(t,u+s*0.05+r*t+q*Math.abs(p*0.9)/2,o))}return m},
v(d){return"DesignBandScale("+this.c+" bands, "+A.ae(this.a)+"\u2013"+A.ae(this.b)+")"}}
var z=a.updateTypes(["dS(af)","u(u,n0)","P<rE>(P<rE>,p(o)?)"])
B.e59.prototype={
$0(){return this.a.m(new B.e58())},
$S:0}
B.e58.prototype={
$0(){},
$S:0}
B.e56.prototype={
$2(d,e){return Math.max(d,e.b.length)},
$S:z+1}
B.e5a.prototype={
$0(){var x=this.a,w=this.b
x.r=w
x.sLJ(w==null?null:this.c)},
$S:0}
B.e57.prototype={
$2(d,e){var x,w,v,u,t
if(e==null)x=d
else{x=A.a([],y.c)
for(w=d.length,v=0;v<d.length;d.length===w||(0,A.G)(d),++v){u=d[v]
t=u.a
x.push(new E.rE(t,u.b,e.$1(t)))}}return x},
$S:z+2}
B.e5e.prototype={
$2(d,e){var x=this.a
return x.DZ(x.boT(d),e)},
$S:527}
B.e5b.prototype={
$0(){return this.a.yi(this.b,null,!0)},
$S:0}
B.e5c.prototype={
$0(){return this.a.yi(this.b,null,!0)},
$S:0}
B.e5d.prototype={
$2(d,e){var x,w,v,u=e.b
u=isFinite(u)?u:300
x=e.d
x=isFinite(x)?x:u/2
w=this.a
v=w.w=w.b5o(new A.H(u,x),this.b)
return I.mv(w.a.fI(d,v),v.a)},
$S:62};(function aliases(){var x=B.b5h.prototype
x.aZD=x.k})();(function installTearOffs(){var x=a._instance_1u
x(B.aRB.prototype,"gaac","aad",0)})();(function inheritance(){var x=a.mixinHard,w=a.mixin,v=a.inheritMany,u=a.inherit
v(A.Q,[B.o_,B.n0,B.Jj,B.pV,B.bP1])
v(A.e9,[B.bgq,B.El])
u(B.Vy,A.j)
u(B.b5h,A.i)
u(B.clU,B.b5h)
u(B.aRB,B.clU)
v(A.cS,[B.e59,B.e58,B.e5a,B.e5b,B.e5c])
v(A.d_,[B.e56,B.e57,B.e5e,B.e5d])
v(E.bgC,[B.cFa,B.aAn])
x(B.b5h,A.dj)
w(B.clU,K.asX)})()
A.bE(b.typeUniverse,JSON.parse('{"Vy":{"j":[],"b":[]},"aRB":{"i":["Vy"]}}'))
var y={w:A.C("dZ"),o:A.C("dp"),j:A.C("m<o_>"),q:A.C("m<n0>"),c:A.C("m<rE>"),x:A.C("m<p>"),b:A.C("o")};(function constants(){var x=a.makeConstList
D.vZ=new B.bgq(0,"linear")
D.w_=new B.bgq(2,"band")
D.Cv=new B.El(0,"second")
D.cRf=new A.y(D.Cv,1)
D.cRi=new A.y(D.Cv,5)
D.cRg=new A.y(D.Cv,15)
D.cRh=new A.y(D.Cv,30)
D.Cw=new B.El(1,"minute")
D.cRj=new A.y(D.Cw,1)
D.cRm=new A.y(D.Cw,5)
D.cRk=new A.y(D.Cw,15)
D.cRl=new A.y(D.Cw,30)
D.Cx=new B.El(2,"hour")
D.cRn=new A.y(D.Cx,1)
D.cRp=new A.y(D.Cx,3)
D.cRq=new A.y(D.Cx,6)
D.cRo=new A.y(D.Cx,12)
D.X2=new B.El(3,"day")
D.cRr=new A.y(D.X2,1)
D.cRs=new A.y(D.X2,2)
D.avZ=new B.El(4,"week")
D.cRt=new A.y(D.avZ,1)
D.Ne=new B.El(5,"month")
D.cRu=new A.y(D.Ne,1)
D.cRv=new A.y(D.Ne,3)
D.cRw=new A.y(D.Ne,6)
D.Nf=new B.El(6,"year")
D.cRx=new A.y(D.Nf,1)
D.cqD=x([D.cRf,D.cRi,D.cRg,D.cRh,D.cRj,D.cRm,D.cRk,D.cRl,D.cRn,D.cRp,D.cRq,D.cRo,D.cRr,D.cRs,D.cRt,D.cRu,D.cRv,D.cRw,D.cRx],A.C("m<+(El,u)>"))
D.adV=x([],y.q)})()};
(a=>{a["17ma9/ZWIajYha8oad8kvZOWShk="]=a.current})($__dart_deferred_initializers__);