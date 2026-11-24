((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var A,C,B={aSk:function aSk(d,e,f,g,h,i,j){var _=this
_.H=null
_.a7=d
_.ao=e
_.bE=f
_.cA=_.cf=null
_.fb=g
_.F$=h
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
_.dx=$},dFb:function dFb(d){this.a=d},
dD(d,e,f){return new B.oC(f,d,e,null)},
oC:function oC(d,e,f,g){var _=this
_.e=d
_.f=e
_.c=f
_.a=g}},D,E
A=c[0]
C=c[2]
B=a.updateHolder(c[254],B)
D=c[457]
E=c[263]
B.aSk.prototype={
axA(d){switch(d.a){case 6:return!0
case 1:case 2:case 0:case 4:case 3:case 5:return!1}},
sxX(d){var x=this,w=x.a7
if(w===d)return
x.a7=d
if(x.axA(w)||x.axA(d))x.a6()
else{x.cA=x.cf=null
x.bp()}},
sk5(d){var x=this
if(x.ao.i(0,d))return
x.ao=d
x.H=x.cA=x.cf=null
x.bp()},
sbI(d){var x=this
if(x.bE==d)return
x.bE=d
x.H=x.cA=x.cf=null
x.bp()},
bY(d){var x,w=this.F$
if(w!=null){x=w.a_(C.av,D.eB,w.gc4())
switch(this.a7.a){case 6:return d.b_(new A.A(0,d.b,0,d.d).K8(x))
case 1:case 2:case 0:case 4:case 3:case 5:return d.K8(x)}}else return new A.H(A.a7(0,d.a,d.b),A.a7(0,d.c,d.d))},
fT(d,e){var x=this.F$
return x==null?null:x.hD(D.eB,e)},
bs(){var x,w,v=this,u=v.F$
if(u!=null){u.bi(D.eB,!0)
switch(v.a7.a){case 6:u=y.a
x=u.a(A.G.prototype.gW.call(v))
w=new A.A(0,x.b,0,x.d).K8(v.F$.gD())
v.fy=u.a(A.G.prototype.gW.call(v)).b_(w)
break
case 1:case 2:case 0:case 4:case 3:case 5:v.fy=y.a.a(A.G.prototype.gW.call(v)).K8(v.F$.gD())
break}v.cA=v.cf=null}else{u=y.a.a(A.G.prototype.gW.call(v))
v.fy=new A.H(A.a7(0,u.a,u.b),A.a7(0,u.c,u.d))}},
agu(){var x,w,v,u,t,s,r,q,p,o,n=this
if(n.cA!=null)return
if(n.F$==null){n.cf=!1
n.cA=A.kI()}else{x=n.H
if(x==null)x=n.H=n.ao.M(n.bE)
w=n.F$.gD()
v=E.ims(n.a7,w,n.gD())
u=v.b
t=v.a
s=w.a
r=w.b
q=x.KY(t,new A.C(0,0,0+s,0+r))
p=n.gD()
o=x.KY(u,new A.C(0,0,0+p.a,0+p.b))
p=q.a
n.cf=q.c-p<s||q.d-q.b<r
r=A.oN(o.a,o.b,0)
r.r7(u.a/t.a,u.b/t.b,1,1)
r.ik(-p,-q.b,0,1)
n.cA=r}},
aDA(d,e){var x,w,v,u,t=this,s=t.cA
s.toString
x=A.Ng(s)
if(x==null){s=t.cx
s===$&&A.l()
w=t.cA
w.toString
v=A.n4.prototype.gkR.call(t)
u=t.ch.a
return d.yf(s,e,w,v,u instanceof A.zy?u:null)}else t.kK(d,e.aB(0,x))
return null},
T(d,e){var x,w,v,u,t=this
if(t.F$==null||t.gD().gbg(0)||t.F$.gD().gbg(0))return
t.agu()
x=t.cf
x.toString
if(x&&t.fb!==C.u){x=t.cx
x===$&&A.l()
w=t.gD()
v=t.ch
u=v.a
u=u instanceof A.alm?u:null
v.scq(d.t_(x,e,new A.C(0,0,0+w.a,0+w.b),t.gbxC(),t.fb,u))}else t.ch.scq(t.aDA(d,e))},
cL(d,e){var x,w=this
if(!w.gD().gbg(0)){x=w.F$
x=x==null?null:x.gD().gbg(0)
x=x===!0}else x=!0
if(x)return!1
w.agu()
return d.zr(new B.dFb(w),e,w.cA)},
D4(d){return!this.gD().gbg(0)&&!d.gD().gbg(0)},
hH(d,e){var x
if(!(!this.gD().gbg(0)&&!d.gD().gbg(0)))e.a5s()
else{this.agu()
x=this.cA
x.toString
e.iZ(x)}}}
B.oC.prototype={
aw(d){var x=new B.aSk(this.e,this.f,A.cU(d),C.u,null,new A.aX(),A.aM())
x.av()
x.sbh(null)
return x},
aH(d,e){e.sxX(this.e)
e.sk5(this.f)
e.sbI(A.cU(d))
if(C.u!==e.fb){e.fb=C.u
e.bp()
e.cj()}}}
var z=a.updateTypes(["zy?(q6,t)"])
B.dFb.prototype={
$2(d,e){return this.a.HX(d,e)},
$S:17};(function installTearOffs(){var x=a._instance_2u
x(B.aSk.prototype,"gbxC","aDA",0)})();(function inheritance(){var x=a.inherit
x(B.aSk,A.iI)
x(B.dFb,A.dj)
x(B.oC,A.aY)})()
A.bM(b.typeUniverse,JSON.parse('{"aSk":{"v":[],"bg":["v"],"G":[],"aQ":[]},"oC":{"aY":[],"aP":[],"b":[]}}'))
var y={a:A.F("A")}};
(a=>{a["LGVyvpCsbN+rbb9JdRAiLKSD0Ak="]=a.current})($__dart_deferred_initializers__);