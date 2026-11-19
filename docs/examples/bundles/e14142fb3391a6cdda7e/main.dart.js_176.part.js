((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var A,C,B={aJA:function aJA(d,e,f,g,h,i,j){var _=this
_.H=null
_.a4=d
_.au=e
_.bV=f
_.cQ=_.cP=null
_.fV=g
_.E$=h
_.dy=i
_.b=_.fy=null
_.c=0
_.y=_.d=null
_.z=!0
_.Q=null
_.as=!1
_.at=null
_.ay=$
_.ch=j
_.CW=!1
_.cx=$
_.cy=!0
_.db=!1
_.dx=$},dhc:function dhc(d){this.a=d},
eX(d,e,f){return new B.wT(f,d,e,null)},
wT:function wT(d,e,f,g){var _=this
_.e=d
_.f=e
_.c=f
_.a=g}},E,D
A=c[0]
C=c[2]
B=a.updateHolder(c[219],B)
E=c[235]
D=c[421]
B.aJA.prototype={
aud(d){switch(d.a){case 6:return!0
case 1:case 2:case 0:case 4:case 3:case 5:return!1}},
sx0(d){var x=this,w=x.a4
if(w===d)return
x.a4=d
if(x.aud(w)||x.aud(d))x.a6()
else{x.cQ=x.cP=null
x.bm()}},
sjQ(d){var x=this
if(x.au.i(0,d))return
x.au=d
x.H=x.cQ=x.cP=null
x.bm()},
sbF(d){var x=this
if(x.bV==d)return
x.bV=d
x.H=x.cQ=x.cP=null
x.bm()},
bW(d){var x,w=this.E$
if(w!=null){x=w.Z(C.au,D.es,w.gbT())
switch(this.a4.a){case 6:return d.b2(new A.B(0,d.b,0,d.d).IZ(x))
case 1:case 2:case 0:case 4:case 3:case 5:return d.IZ(x)}}else return new A.H(A.a_(0,d.a,d.b),A.a_(0,d.c,d.d))},
fQ(d,e){var x=this.E$
return x==null?null:x.hq(D.es,e)},
bq(){var x,w,v=this,u=v.E$
if(u!=null){u.bg(D.es,!0)
switch(v.a4.a){case 6:u=y.a
x=u.a(A.E.prototype.gT.call(v))
w=new A.B(0,x.b,0,x.d).IZ(v.E$.gA())
v.fy=u.a(A.E.prototype.gT.call(v)).b2(w)
break
case 1:case 2:case 0:case 4:case 3:case 5:v.fy=y.a.a(A.E.prototype.gT.call(v)).IZ(v.E$.gA())
break}v.cQ=v.cP=null}else{u=y.a.a(A.E.prototype.gT.call(v))
v.fy=new A.H(A.a_(0,u.a,u.b),A.a_(0,u.c,u.d))}},
ae7(){var x,w,v,u,t,s,r,q,p,o,n=this
if(n.cQ!=null)return
if(n.E$==null){n.cP=!1
n.cQ=A.k1()}else{x=n.H
if(x==null)x=n.H=n.au.J(n.bV)
w=n.E$.gA()
v=E.hx4(n.a4,w,n.gA())
u=v.b
t=v.a
s=w.a
r=w.b
q=x.JM(t,new A.z(0,0,0+s,0+r))
p=n.gA()
o=x.JM(u,new A.z(0,0,0+p.a,0+p.b))
p=q.a
n.cP=q.c-p<s||q.d-q.b<r
r=A.nA(o.a,o.b,0)
r.qj(u.a/t.a,u.b/t.b,1,1)
r.i1(-p,-q.b,0,1)
n.cQ=r}},
azV(d,e){var x,w,v,u,t=this,s=t.cQ
s.toString
x=A.a_E(s)
if(x==null){s=t.cx
s===$&&A.h()
w=t.cQ
w.toString
v=A.mu.prototype.gkv.call(t)
u=t.ch.a
return d.xk(s,e,w,v,u instanceof A.xP?u:null)}else t.kY(d,e.av(0,x))
return null},
R(d,e){var x,w,v,u,t=this
if(t.E$==null||t.gA().gbc(0)||t.E$.gA().gbc(0))return
t.ae7()
x=t.cP
x.toString
if(x&&t.fV!==C.v){x=t.cx
x===$&&A.h()
w=t.gA()
v=t.ch
u=v.a
u=u instanceof A.afz?u:null
v.sbZ(d.r2(x,e,new A.z(0,0,0+w.a,0+w.b),t.gbrI(),t.fV,u))}else t.ch.sbZ(t.azV(d,e))},
d1(d,e){var x,w=this
if(!w.gA().gbc(0)){x=w.E$
x=x==null?null:x.gA().gbc(0)
x=x===!0}else x=!0
if(x)return!1
w.ae7()
return d.ys(new B.dhc(w),e,w.cQ)},
Ca(d){return!this.gA().gbc(0)&&!d.gA().gbc(0)},
hr(d,e){var x
if(!(!this.gA().gbc(0)&&!d.gA().gbc(0)))e.a3R()
else{this.ae7()
x=this.cQ
x.toString
e.iz(x)}}}
B.wT.prototype={
aA(d){var x=new B.aJA(this.e,this.f,A.cY(d),C.v,null,new A.aY(),A.aL())
x.az()
x.sbi(null)
return x},
aR(d,e){e.sx0(this.e)
e.sjQ(this.f)
e.sbF(A.cY(d))
if(C.v!==e.fV){e.fV=C.v
e.bm()
e.c3()}}}
var z=a.updateTypes(["xP?(oO,q)"])
B.dhc.prototype={
$2(d,e){return this.a.GS(d,e)},
$S:13};(function installTearOffs(){var x=a._instance_2u
x(B.aJA.prototype,"gbrI","azV",0)})();(function inheritance(){var x=a.inherit
x(B.aJA,A.iV)
x(B.dhc,A.d_)
x(B.wT,A.aX)})()
A.bE(b.typeUniverse,JSON.parse('{"aJA":{"w":[],"bi":["w"],"E":[],"aP":[]},"wT":{"aX":[],"aO":[],"b":[]}}'))
var y={a:A.C("B")}};
(a=>{a["E1hXQnJJf70mMw7rWbDIAhtYB1g="]=a.current})($__dart_deferred_initializers__);