((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,A={K3:function K3(d,e){this.a=d
this.$ti=e},bK8:function bK8(d){this.a=d
this.b=null},
jrd(d,e,f){var x
A:{if(D.hK===d||D.A9===d){x=e-f
break A}if(D.ZK===d){x=e-0.5857864376269049*f
break A}if(D.ZL===d||D.ZM===d){x=e
break A}if(D.ZN===d){x=Math.sqrt(Math.max(e*e+2*e*f,0))-f
break A}x=null}return x},
iyp(d,e){var x,w=B.m2(d,e,0.3333333333333333)
w.toString
x=B.m2(d,e,0.6666666666666666)
x.toString
return new B.dW([d,w,x,e])},
iSU(d,e,f){var x,w,v,u,t,s,r,q,p,o,n=1.5707963267948966/f,m=1.3333333333333333*Math.tan(n/4),l=B.a([],y.e)
for(x=0;x<f;){w=x*n
v=d.$1(w)
u=d.$1(w)
w=e.$1(w)
t=w.a
w=w.b
s=u.a
u=u.b;++x
r=x*n
q=d.$1(r)
p=e.$1(r)
o=p.a
p=p.b
l.push(new B.dW([v,new B.u(s+t*m,u+w*m),new B.u(q.a-o*m,q.b-p*m),d.$1(r)]))}return l},
iTq(d,e,f){var x,w,v,u,t,s,r,q,p,o,n
switch(d.a){case 0:return A.iSU(new A.hRb(),new A.hRc(),2)
case 5:return A.iSU(new A.hRd(),new A.hRe(),2)
case 1:return D.cN8
case 2:return B.a([A.iyp(C.js,C.cM)],y.e)
case 3:return B.a([A.iyp(C.js,F.w2),A.iyp(F.w2,C.cM)],y.e)
case 4:x=Math.max(e,f)
if(x<8)w=2
else w=x<=16?3:4
x=Math.min(w,Math.max(1,C.i.cJ(x)))
v=new A.hRf()
u=B.a([C.js],y.g)
for(t=1;t<=x;++t){s=t/x
r=v.$2(s,f)
u.push(new B.u(v.$2(1-(t-1)/x,e),r))
u.push(new B.u(v.$2(1-s,e),r))}x=B.a([],y.e)
for(q=0;q<u.length-1;){s=u[q];++q
p=u[q]
o=B.m2(s,p,0.3333333333333333)
o.toString
n=B.m2(s,p,0.6666666666666666)
n.toString
x.push(new B.dW([s,o,n,p]))}return x}},
jvg(d){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f=B.aG(d,y.S)
for(x=y.e;f.length<8;){for(w=0,v=-1,u=0;u<f.length;++u){t=f[u].a
s=t[3]
t=t[0]
r=s.a-t.a
t=s.b-t.b
q=Math.sqrt(r*r+t*t)
if(q>v+1e-9){v=q
w=u}}t=f[w].a
p=t[0]
o=t[1]
n=t[2]
m=t[3]
t=o.a
s=o.b
r=(p.a+t)/2
l=(p.b+s)/2
k=n.a
j=n.b
t=(t+k)/2
s=(s+j)/2
k=(k+m.a)/2
j=(j+m.b)/2
i=(r+t)/2
h=(l+s)/2
t=(t+k)/2
s=(s+j)/2
g=new B.u((i+t)/2,(h+s)/2)
C.c.kW(f,w)
C.c.TC(f,w,B.a([new B.dW([p,new B.u(r,l),new B.u(i,h),g]),new B.dW([g,new B.u(t,s),new B.u(k,j),m])],x))}return f},
jua(d,e,f){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i=B.dQ(8,D.diQ,!1,y.S)
for(x=y.e,w=0;w<6;++w){v=D.K3[w]
u=d[v.a]
if(u===0)continue
t=A.jvg(A.iTq(v,e,f))
s=B.a([],x)
for(r=0;r<8;++r){q=i[r].a
p=q[0]
o=t[r].a
n=o[0]
m=q[1]
l=o[1]
k=q[2]
j=o[2]
q=q[3]
o=o[3]
s.push(new B.dW([new B.u(p.a+n.a*u,p.b+n.b*u),new B.u(m.a+l.a*u,m.b+l.b*u),new B.u(k.a+j.a*u,k.b+j.b*u),new B.u(q.a+o.a*u,q.b+o.b*u)]))}i=s}return i},
iyy(d){var x,w=B.a([],y.n)
for(x=0;x<6;++x)w.push(D.K3[x]===d?1:0)
return w},
iUW(d,e,f){var x,w,v=B.a([],y.n)
for(x=0;x<d.length;++x){w=d[x]
v.push(w+(e[x]-w)*f)}return v},
iy0(d){var x,w,v
for(x=d.length,w=0,v=1;v<x;++v)if(d[v]>d[w])w=v
return D.K3[w]},
iV7(d){var x,w,v,u=A.iy0(d).a
for(x=d.length,w=0;w<x;++w){v=d[w]
if(Math.abs(v-(w===u?1:0))>1e-9)return d}return null},
ivc(d,e,f,g){return new A.q8(g,d,null,e?D.aAW:D.aAV,null,null,0,f)},
iLQ(d){var x,w,v
A:{if(d instanceof A.q8){x=d
break A}if(d instanceof B.cc){w=d.a
v=d.b
x=A.ivc(v,!1,w,D.hK)
break A}if(d instanceof G.qb){w=d.a
v=d.b
x=A.ivc(v,!1,w,D.A9)
break A}if(d instanceof B.ke){w=d.a
x=A.ivc(C.bG,!0,w,D.hK)
break A}x=null
break A}return x},
iLR(d,e,f){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i
if(d===e)return d
x=A.iUW(d.gaj6(),e.gaj6(),f)
w=B.ek(d.a,e.a,f)
v=A.iy0(x)
u=B.rM(d.c,e.c,f)
u.toString
t=d.e.a
s=t[0]
r=e.e.a
q=r[0]
p=t[1]
o=r[1]
n=t[2]
m=r[2]
t=t[3]
r=r[3]
l=d.d
if(l!=null&&e.d!=null)l=B.bm(l,e.d,f)
else l=f<0.5?l:e.d
k=A.iV7(x)
j=B.kC(d.r,e.r,f)
i=B.bm(d.w,e.w,f)
i.toString
return new A.q8(v,u,l,new B.dW([s+(q-s)*f,p+(o-p)*f,n+(m-n)*f,t+(r-t)*f]),k,j,i,w)},
iyx(d){return isFinite(d)&&d===C.i.ce(d)?""+C.i.ah(d):B.am(d)},
Ad:function Ad(d,e){this.a=d
this.b=e},
hRb:function hRb(){},
hRc:function hRc(){},
hRd:function hRd(){},
hRe:function hRe(){},
hRf:function hRf(){},
q8:function q8(d,e,f,g,h,i,j,k){var _=this
_.b=d
_.c=e
_.d=f
_.e=g
_.f=h
_.r=i
_.w=j
_.a=k},
dHl:function dHl(d){this.a=d},
dHi:function dHi(d,e){this.a=d
this.b=e},
dHk:function dHk(d,e,f){this.a=d
this.b=e
this.c=f},
dHj:function dHj(d,e){this.a=d
this.b=e},
dHh:function dHh(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
j4:function j4(d,e){this.a=d
this.b=e},
fP:function fP(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
rn:function rn(d,e,f,g,h,i,j,k){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i
_.r=j
_.w=k},
dHm:function dHm(d){this.a=d},
dHn:function dHn(){},
rp:function rp(d,e,f){this.a=d
this.b=e
this.c=f},
iQ:function iQ(d,e){this.a=d
this.b=e},
bKZ:function bKZ(d,e){this.a=d
this.b=e},
wQ:function wQ(d,e,f,g,h,i,j,k,l,m,n){var _=this
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
dIk:function dIk(d,e){this.a=d
this.b=e},
cng:function cng(){},
cnh:function cnh(){},
cnv:function cnv(){},
cnw:function cnw(){}},D,F,G,E,H
J=c[1]
B=c[0]
C=c[2]
A=a.updateHolder(c[230],A)
D=c[456]
F=c[667]
G=c[283]
E=c[296]
H=c[254]
A.K3.prototype={
gabs(){var x,w,v,u
for(x=this.a,w=x.length,v=0;v<w;++v){u=x[v]
if(u!=null)return u}return null},
gbd(d){return this.gabs()==null},
ghu(d){return this.gabs()!=null},
gaf(d){var x=this.gabs()
return x==null?B.O(B.ah()):x},
gb4(d){var x=this.a
return new A.bK8(new J.l2(x,x.length,B.aC(x).k("l2<1>")))}}
A.bK8.prototype={
A(){var x,w,v
this.b=null
for(x=this.a,w=x.$ti.c;x.A();){v=x.d
if(v==null)v=w.a(v)
if(v!=null){this.b=v
return!0}}return!1},
gK(){var x=this.b
return x==null?B.O(B.ah()):x}}
A.Ad.prototype={
a_(){return"RawCornerStyle."+this.b}}
A.q8.prototype={
gTm(){var x=this.e.a
return x[0]>=1&&x[1]>=1&&x[2]>=1&&x[3]>=1},
gaj6(){var x=this.f
return x==null?A.iyy(this.b):x},
TD(d){var x=this,w=x.r
return new A.q8(x.b,x.c,x.d,x.e,x.f,(w==null?C.C:w).H(0,d),Math.max(x.w,0),x.a)},
gee(){var x=this.a.gfC()
return new B.J(x,x,x,x)},
a7(d){var x,w=this,v=w.a.a7(d),u=w.c.bl(0,d),t=w.d
t=t==null?null:t*d
x=w.r
if(x==null)x=null
else x=x.bl(0,d)
return new A.q8(w.b,u,t,w.e,w.f,x,w.w*d,v)},
bD(d){var x=this,w=d==null?x.a:d
return new A.q8(x.b,x.c,x.d,x.e,x.f,x.r,x.w,w)},
is(d,e){var x=A.iLQ(d)
if(x!=null)return A.iLR(x,this,e)
return this.rS(d,e)},
it(d,e){var x=A.iLQ(d)
if(x!=null)return A.iLR(this,x,e)
return this.qY(d,e)},
aK3(d,e,f){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j=this,i=j.c.M(e),h=j.r,g=h==null?null:h.M(e)
if(g==null)g=C.C
x=d.br(-f)
h=new A.dHl(j.gaj6())
h=new A.dHj(new A.dHi(j,h),new A.dHk(j,Math.max(x.gcK()/2,0),h))
w=j.e.a
v=w[0]
u=w[1]
t=w[2]
s=w[3]
w=y.n
r=e===C.H?B.a([u,v,t,s],w):B.a([v,u,s,t],w)
q=g.a+f
p=g.c+f
o=g.b+f
n=g.d+f
m=[h.$4(i.a,q,o,r[0]),h.$4(i.b,p,o,r[1]),h.$4(i.d,p,n,r[2]),h.$4(i.c,q,n,r[3])]
h=m[0].nQ(0,C.af)
w=m[1].nQ(0,C.af)
l=m[2].nQ(0,C.af)
k=B.pt(x,m[3].nQ(0,C.af),l,h,w).Ek()
return new B.z(x,B.a([new B.aH(k.e,k.f),new B.aH(k.r,k.w),new B.aH(k.x,k.y),new B.aH(k.z,k.Q)],y.K))},
Qr(d,e,f){var x=this.aK3(d,e,f),w=x.b,v=w[0],u=w[1],t=w[2]
return B.pt(x.a,w[3],t,v,u)},
bII(a1,a2){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g=a1.a,f=a1.b,e=a1.c,d=a1.d,a0=B.a([new B.u(g,f),new B.u(e,f),new B.u(e,d),new B.u(g,d)],y.g)
d=$.K()
g=B.a([],y.v)
x=new B.b0(d.r,C.a7,null,null,g)
for(w=this.f,f=this.b,e=w==null,v=0;v<4;++v){d=(v&1)===1
if(d){u=a2[v]
t=u.a}else{u=a2[v]
t=u.b}s=d?u.b:u.a
r=new A.dHh(a0,v,t,s)
q=r.$1(C.js)
d=q.a
u=q.b
if(v===0){d=new B.cn(d,u)
g.push(d)
u=x.f
if(u!=null)d.cB(u)
d=x.e
if(d!=null)d.a.delete()
x.e=null}else{d=new B.b5(d,u)
g.push(d)
u=x.f
if(u!=null)d.cB(u)
d=x.e
if(d!=null)d.a.delete()
x.e=null}p=e?A.iTq(f,t,s):A.jua(w,t,s)
for(d=p.length,o=0;o<p.length;p.length===d||(0,B.F)(p),++o){u=p[o].a
n=u[1]
m=u[2]
l=u[3]
k=r.$1(n)
j=r.$1(m)
i=r.$1(l)
u=new B.uJ(k.a,k.b,j.a,j.b,i.a,i.b)
g.push(u)
h=x.f
if(h!=null)u.cB(h)
u=x.e
if(u!=null)u.a.delete()
x.e=null}}x.a1(new B.eZ())
return x},
QC(d,e,f){var x,w,v,u,t,s,r,q,p=this
if(p.f==null&&p.b===D.hK){x=new B.b0($.K().r,C.a7,null,null,B.a([],y.v))
x.a1(new B.eV(p.Qr(d,e,f)))
return x}x=$.j22()
B.jb(p)
w=x.a.get(p)
if(w==null){w=B.an(y.z,y.i)
x.S(0,p,w)}x=d.a
v=d.c-x
u=d.b
t=d.d-u
s=new B.bQ(new B.I(v,t),e,f)
r=w.q(0,s)
if(r==null){if(w.gaa(w)>=8)w.bo(0)
q=p.aK3(new B.E(0,0,0+v,0+t),e,f)
r=p.bII(q.a,q.b)
w.S(0,s,r)}return r.cp(new B.u(x,u))},
dQ(d,e){return this.QC(d,e,0)},
hs(d){return this.dQ(d,null)},
hZ(d,e){return this.QC(d,e,this.a.gfC())},
oG(d){return this.hZ(d,null)},
gne(){return!0},
kV(d,e,f,g){var x=this
if(x.f==null&&x.b===D.hK)d.cm(x.Qr(e,g,0),f)
else d.aF(x.QC(e,g,0),f)},
tu(d,e,f){return this.kV(d,e,f,null)},
hl(d,e,f){var x,w,v,u=this,t=u.a
if(t.c===C.cR)return
x=t.b
if(x===0){if(u.f==null&&u.b===D.hK)d.cm(u.Qr(e,f,0),t.jj())
else d.aF(u.QC(e,f,0),t.jj())
return}if(u.f==null&&u.b===D.hK){x=u.Qr(e,f,-t.gqW())
w=u.Qr(e,f,t.gfC())
$.K()
v=B.M()
v.r=t.a.gu()
d.tg(x,w,v)
return}d.aF(u.QC(e,f,-(x*t.d)/2),t.jj())},
U(d,e){return this.hl(d,e,null)},
i(d,e){var x=this
if(e==null)return!1
if(x===e)return!0
return e instanceof A.q8&&e.a.i(0,x.a)&&e.b===x.b&&e.c.i(0,x.c)&&e.e.i(0,x.e)&&e.d==x.d&&B.bZ(e.f,x.f)&&J.B(e.r,x.r)&&e.w===x.w},
ga2(d){var x=this,w=x.f
if(w==null)w=null
else w=B.cC(w)
return B.aP(x.a,x.b,x.c,x.e,x.d,w,x.r,x.w,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
D(d){var x,w,v=this,u=v.e.a,t=u[0],s=u[1],r=u[2],q=u[3]
u=B.a([],y.s)
if(t>=1)u.push("topStart")
if(s>=1)u.push("topEnd")
if(r>=1)u.push("bottomStart")
if(q>=1)u.push("bottomEnd")
if(v.gTm())x="full"
else{w=v.c
x=u.length===0?w.D(0):w.D(0)+", full at "+C.c.aM(u,", ")}return"RawCornerBorder("+v.b.b+", "+x+", "+v.a.D(0)+")"}}
A.j4.prototype={
a_(){return"RawCorner."+this.b}}
A.fP.prototype={
gaK2(){var x=this
return B.a([x.a,x.b,x.c,x.d],y.d)},
gbd(d){var x=this
return x.a==null&&x.b==null&&x.c==null&&x.d==null},
aoC(d){var x,w,v,u=this,t=u.a
if(t==null)t=d.a
x=u.b
if(x==null)x=d.b
w=u.c
if(w==null)w=d.c
v=u.d
return new A.fP(t,x,w,v==null?d.d:v)},
i(d,e){var x,w=this
if(e==null)return!1
if(w!==e)x=e instanceof A.fP&&e.a==w.a&&e.b==w.b&&e.c==w.c&&e.d==w.d
else x=!0
return x},
ga2(d){var x=this
return B.aP(x.a,x.b,x.c,x.d,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
ku(){var x,w,v,u,t=this,s=B.a([],y.s)
for(x=[new B.z("topStart",t.a),new B.z("topEnd",t.b),new B.z("bottomStart",t.c),new B.z("bottomEnd",t.d)],w=0;w<4;++w){v=x[w]
u=v.b
if(u!=null)s.push(v.a+": "+u.b)}return"RawCorners("+C.c.aM(s,", ")+")"},
D(d){return this.ku()}}
A.rn.prototype={
vT(d){var x,w=this
switch(d.a){case 0:x=0
break
case 1:x=w.b
break
case 2:x=w.c
break
case 3:x=w.d
break
case 4:x=w.e
break
case 5:x=w.f
break
case 6:x=1/0
break
default:x=null}return x},
aPM(d,e){var x,w,v,u=this,t=d===D.ca
if(t||d===D.fp)x=C.bG
else{x=u.vT(d)
x=B.e4(new B.aH(x,x))}w=t?D.aAW:D.aAV
v=t?u.r:null
return new A.q8(u.a,x,v,w,u.w,null,0,e)},
a1D(d){return this.aPM(d,C.p)},
aPN(d,e){var x,w,v,u,t,s,r,q,p,o,n,m,l,k=this,j=d.a
if(j==null)j=D.fp
x=d.b
if(x==null)x=D.fp
w=d.c
if(w==null)w=D.fp
v=d.d
if(v==null)v=D.fp
if(j===x&&x===w&&w===v)return k.aPM(j,e)
u=new A.dHm(k)
t=new A.dHn()
s=C.c.m(B.a([j,x,w,v],y.U),D.ca)
r=u.$1(j)
q=u.$1(x)
p=u.$1(w)
u=u.$1(v)
o=t.$1(j)
n=t.$1(x)
m=t.$1(w)
t=t.$1(v)
l=s?k.r:null
return new A.q8(k.a,new H.jU(r,q,p,u),l,new B.dW([o,n,m,t]),k.w,null,0,e)},
CB(d){return this.aPN(d,C.p)},
Lc(d,e,f,g,h){var x=this,w=e==null?x.b:e,v=h==null?x.c:h,u=g==null?x.d:g,t=f==null?x.e:f,s=d==null?x.f:d
return new A.rn(x.a,w,v,u,t,s,x.r,x.w)},
bSv(d){var x=null
return this.Lc(x,d,x,x,x)},
bTg(d){var x=null
return this.Lc(x,x,x,x,d)},
bT0(d){var x=null
return this.Lc(x,x,x,d,x)},
bSX(d){var x=null
return this.Lc(x,x,d,x,x)},
bSu(d){var x=null
return this.Lc(d,x,x,x,x)},
i(d,e){var x,w=this
if(e==null)return!1
if(w!==e)x=e instanceof A.rn&&e.a===w.a&&e.b===w.b&&e.c===w.c&&e.d===w.d&&e.e===w.e&&e.f===w.f&&e.r==w.r&&B.bZ(e.w,w.w)
else x=!0
return x},
ga2(d){var x=this,w=x.w
if(w==null)w=null
else w=B.cC(w)
return B.aP(x.a,x.b,x.c,x.d,x.e,x.f,x.r,w,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)}}
A.rp.prototype={
i(d,e){var x,w=this
if(e==null)return!1
if(w!==e)x=e instanceof A.rp&&e.a.i(0,w.a)&&e.b==w.b&&e.c==w.c
else x=!0
return x},
ga2(d){return B.aP(this.a,this.b,this.c,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)}}
A.iQ.prototype={
i(d,e){if(e==null)return!1
return e instanceof A.iQ&&e.a===this.a&&e.b===this.b},
ga2(d){return B.aP(this.a,this.b,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
D(d){var x=this.a,w=this.b
return x===w?"RawBand.fixed("+A.iyx(x)+")":"RawBand("+A.iyx(x)+", "+A.iyx(w)+")"}}
A.bKZ.prototype={
a_(){return"RawCornerFreedom."+this.b}}
A.wQ.prototype={
c1h(d){var x,w,v,u,t,s,r,q,p=this.z
if(p==null||p.m(0,d))return d
for(x=p.gb4(p),w=d.a,v=null;x.A();){u=x.gK()
if(v==null){v=u
continue}t=u.a
s=Math.abs(t-w)
r=v.a
q=Math.abs(r-w)
if(s>=q)t=s===q&&t>r
else t=!0
if(t)v=u}v.toString
return v},
vg(d,e,f){return this.bga(d,e).a},
bga(d,e){var x,w,v,u,t
if(d==null||d.gbd(0))return new B.z(e,D.Yq)
x=B.a([],y.L)
w=new A.dIk(this,x)
switch(this.y.a){case 0:if(d.aoC(e).i(0,e))return new B.z(e,D.Yq)
return new B.z(e,D.cKP)
case 1:v=d.aoC(e)
u=y.o
if(B.bu(new A.K3(v.gaK2(),u),u.k("aM.E")).a>1)return new B.z(e,D.cQS)
t=B.i4(new A.K3(v.gaK2(),u))
if(t==null||v.i(0,e))return new B.z(e,D.Yq)
w=w.$1(t)
w.toString
return new B.z(new A.fP(w,w,w,w),x)
case 2:return new B.z(new A.fP(w.$1(d.a),w.$1(d.b),w.$1(d.c),w.$1(d.d)).aoC(e),x)}},
c1i(d){var x,w,v,u,t=this.a
if(t.m(0,d))return d
for(x=0;x<3;++x){w=D.cRg[x]
if(!C.c.m(w,d))continue
for(v=C.c.gb4(w);v.A();){u=v.gK()
if(t.m(0,u))return u}}return t.gaf(0)},
A7(d,e,f){var x,w,v,u,t,s,r,q,p=this,o=e.a,n=p.c1i(o.a),m=p.b
m=C.i.J(Math.max(o.b,0),m.a,m.b)
x=p.c
x=C.i.J(Math.max(o.c,0),x.a,x.b)
w=p.d
w=C.i.J(Math.max(o.d,0),w.a,w.b)
v=p.e
v=C.i.J(Math.max(o.e,0),v.a,v.b)
u=p.f
u=C.i.J(Math.max(o.f,0),u.a,u.b)
t=o.r
if(!(t==null||p.r==null)){s=p.r
s=C.i.J(t,s.a,s.b)
t=s}s=p.w
if(s==null||e.b==null)s=null
else{r=e.b
r.toString
s=C.i.J(Math.max(r,0),s.a,s.b)}r=p.x
if(r==null||e.c==null)r=null
else{q=e.c
q.toString
r=C.i.J(Math.max(q,0),r.a,r.b)}return new A.rp(new A.rn(n,m,x,w,v,u,t,null),s,r)},
i(d,e){var x,w=this
if(e==null)return!1
if(w!==e)x=e instanceof A.wQ&&B.nF(e.a,w.a)&&e.b.i(0,w.b)&&e.c.i(0,w.c)&&e.d.i(0,w.d)&&e.e.i(0,w.e)&&e.f.i(0,w.f)&&J.B(e.r,w.r)&&J.B(e.w,w.w)&&J.B(e.x,w.x)&&e.y===w.y&&B.nF(e.z,w.z)
else x=!0
return x},
ga2(d){var x=this,w=B.dFk(x.a),v=x.z
v=v==null?null:B.dFk(v)
return B.aP(w,x.b,x.c,x.d,x.e,x.f,x.r,x.w,x.x,x.y,v,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)}}
A.cng.prototype={}
A.cnh.prototype={}
A.cnv.prototype={}
A.cnw.prototype={}
var z=a.updateTypes(["aH(j4)","q(j4)","j4?(j4?)"])
A.hRb.prototype={
$1(d){return new B.u(1-Math.sin(d),1-Math.cos(d))},
$S:292}
A.hRc.prototype={
$1(d){return new B.u(-Math.cos(d),Math.sin(d))},
$S:292}
A.hRd.prototype={
$1(d){return new B.u(Math.cos(d),Math.sin(d))},
$S:292}
A.hRe.prototype={
$1(d){return new B.u(-Math.sin(d),Math.cos(d))},
$S:292}
A.hRf.prototype={
$2(d,e){return d<=0||d>=1||e<1?d:C.i.ce(e*d)/e},
$S:13}
A.dHl.prototype={
$2(d,e){var x,w,v,u,t
for(x=this.a,w=0,v=0;v<6;++v){u=D.K3[v]
t=x[u.a]
if(t!==0)w+=t*A.jrd(u,d,e)}return w},
$S:13}
A.dHi.prototype={
$2(d,e){if(d<=0)return 0
return Math.max(Math.max(this.b.$2(d,e),Math.min(d,this.a.w)),0)},
$S:13}
A.dHk.prototype={
$1(d){var x=this.a.d,w=this.b
return x==null?w:Math.min(w,Math.max(B.eC(this.c.$2(x,d)),0))},
$S:5}
A.dHj.prototype={
$4(d,e,f,g){var x=this.a,w=new B.aH(x.$2(d.a,e),x.$2(d.b,f))
g=C.i.J(g,0,1)
if(g===0)return w
x=this.b
x=B.Kg(w,new B.aH(x.$1(e),x.$1(f)),g)
x.toString
return x},
$S:871}
A.dHh.prototype={
$1(d){var x=this,w=x.b
return x.a[w].aE(0,D.cSi[w].bl(0,d.a*x.c)).aE(0,D.cIH[w].bl(0,d.b*x.d))},
$S:229}
A.dHm.prototype={
$1(d){var x
if(d===D.fp||d===D.ca)x=C.af
else{x=this.a.vT(d)
x=new B.aH(x,x)}return x},
$S:z+0}
A.dHn.prototype={
$1(d){return d===D.ca?1:0},
$S:z+1}
A.dIk.prototype={
$1(d){var x,w
if(d==null)return null
x=this.a.c1h(d)
if(x!==d){w=d.b
this.b.push(new B.z("corner "+w,"holds corner "+w+" to "+x.b+", the nearest step it allows"))}return x},
$S:z+2};(function inheritance(){var x=a.mixin,w=a.inherit,v=a.inheritMany
w(A.K3,B.aM)
v(B.a_,[A.bK8,A.cnh,A.cng,A.cnw,A.iQ,A.cnv])
v(B.em,[A.Ad,A.j4,A.bKZ])
v(B.cp,[A.hRb,A.hRc,A.hRd,A.hRe,A.dHk,A.dHj,A.dHh,A.dHm,A.dHn,A.dIk])
v(B.db,[A.hRf,A.dHl,A.dHi])
w(A.q8,B.cx)
w(A.fP,A.cnh)
w(A.rn,A.cng)
w(A.rp,A.cnw)
w(A.wQ,A.cnv)
x(A.cng,B.bB)
x(A.cnh,B.bB)
x(A.cnv,B.bB)
x(A.cnw,B.bB)})()
B.bP(b.typeUniverse,JSON.parse('{"K3":{"aM":["1"],"aM.E":"1"},"q8":{"cx":[],"dL":[]}}'))
B.j8(b.typeUniverse,JSON.parse('{"bK8":1}'))
var y=(function rtii(){var x=B.G
return{g:x("o<u>"),v:x("o<ei>"),K:x("o<aH>"),U:x("o<j4>"),F:x("o<Ad>"),L:x("o<+(n,n)>"),e:x("o<+(u,u,u,u)>"),s:x("o<n>"),n:x("o<q>"),d:x("o<j4?>"),o:x("K3<j4>"),i:x("oj"),z:x("+(I,oB?,q)"),S:x("+(u,u,u,u)")}})();(function constants(){var x=a.makeConstList
D.cIH=x([C.js,C.cM,E.Oc,E.oE],y.g)
D.hK=new A.Ad(0,"round")
D.A9=new A.Ad(1,"continuous")
D.ZK=new A.Ad(2,"bevel")
D.ZL=new A.Ad(3,"notch")
D.ZM=new A.Ad(4,"step")
D.ZN=new A.Ad(5,"concave")
D.K3=x([D.hK,D.A9,D.ZK,D.ZL,D.ZM,D.ZN],y.F)
D.deQ=new B.z("corners fixed","ignores a corners override: its corners are fixed")
D.cKP=x([D.deQ],y.L)
D.d6l=new B.u(0.72,0)
D.d6I=new B.u(0.44,0)
D.aw2=new B.u(0.22,0.22)
D.diK=new B.dW([C.js,D.d6l,D.d6I,D.aw2])
D.d5D=new B.u(0,0.44)
D.d5S=new B.u(0,0.72)
D.diL=new B.dW([D.aw2,D.d5D,D.d5S,C.cM])
D.cN8=x([D.diK,D.diL],y.e)
D.Yq=x([],y.L)
D.dV=new A.j4(1,"extraSmall")
D.aB=new A.j4(2,"small")
D.aD=new A.j4(3,"medium")
D.cr=new A.j4(4,"large")
D.fY=new A.j4(5,"extraLarge")
D.deO=new B.z("corners mixed","ignores a corners override whose corners differ: it takes one step on every corner")
D.cQS=x([D.deO],y.L)
D.cMk=x([D.hK,D.A9],y.F)
D.cGY=x([D.ZK,D.ZL,D.ZM],y.F)
D.cMl=x([D.ZN],y.F)
D.cRg=x([D.cMk,D.cGY,D.cMl],B.G("o<U<Ad>>"))
D.cSi=x([C.cM,E.Oc,E.oE,C.js],y.g)
D.fp=new A.j4(0,"none")
D.ca=new A.j4(6,"full")
D.pM=new A.bKZ(2,"perCorner")
D.d9L=new A.bKZ(1,"uniform")
D.aAV=new B.dW([0,0,0,0])
D.aAW=new B.dW([1,1,1,1])
D.diQ=new B.dW([C.K,C.K,C.K,C.K])})();(function lazyInitializers(){var x=a.lazyFinal
x($,"jGj","j22",()=>B.lu("RawCornerBorder paths",B.G("eA<+(I,oB?,q),oj>")))})()};
(a=>{a["Yd+xJpWVow+TEun7UlKdRqxhQxU="]=a.current})($__dart_deferred_initializers__);