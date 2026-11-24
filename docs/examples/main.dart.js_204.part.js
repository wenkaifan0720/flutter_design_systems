((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var A,C,E,B={aSr:function aSr(d,e,f,g,h,i,j){var _=this
_.I=null
_.a8=d
_.ap=e
_.bF=f
_.cD=_.ci=null
_.ff=g
_.G$=h
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
_.dx=$},dFR:function dFR(d){this.a=d},
dC(d,e,f){return new B.oF(f,d,e,null)},
oF:function oF(d,e,f,g){var _=this
_.e=d
_.f=e
_.c=f
_.a=g}},D
A=c[0]
C=c[2]
E=c[265]
B=a.updateHolder(c[255],B)
D=c[460]
B.aSr.prototype={
ay7(d){switch(d.a){case 6:return!0
case 1:case 2:case 0:case 4:case 3:case 5:return!1}},
syb(d){var x=this,w=x.a8
if(w===d)return
x.a8=d
if(x.ay7(w)||x.ay7(d))x.a7()
else{x.cD=x.ci=null
x.bq()}},
sk9(d){var x=this
if(x.ap.i(0,d))return
x.ap=d
x.I=x.cD=x.ci=null
x.bq()},
sbJ(d){var x=this
if(x.bF==d)return
x.bF=d
x.I=x.cD=x.ci=null
x.bq()},
bZ(d){var x,w=this.G$
if(w!=null){x=w.a0(C.ax,D.eA,w.gc6())
switch(this.a8.a){case 6:return d.b0(new A.B(0,d.b,0,d.d).Kt(x))
case 1:case 2:case 0:case 4:case 3:case 5:return d.Kt(x)}}else return new A.I(A.a7(0,d.a,d.b),A.a7(0,d.c,d.d))},
fX(d,e){var x=this.G$
return x==null?null:x.hI(D.eA,e)},
bt(){var x,w,v=this,u=v.G$
if(u!=null){u.bk(D.eA,!0)
switch(v.a8.a){case 6:u=y.a
x=u.a(A.H.prototype.gX.call(v))
w=new A.B(0,x.b,0,x.d).Kt(v.G$.gE())
v.fy=u.a(A.H.prototype.gX.call(v)).b0(w)
break
case 1:case 2:case 0:case 4:case 3:case 5:v.fy=y.a.a(A.H.prototype.gX.call(v)).Kt(v.G$.gE())
break}v.cD=v.ci=null}else{u=y.a.a(A.H.prototype.gX.call(v))
v.fy=new A.I(A.a7(0,u.a,u.b),A.a7(0,u.c,u.d))}},
ahh(){var x,w,v,u,t,s,r,q,p,o,n=this
if(n.cD!=null)return
if(n.G$==null){n.ci=!1
n.cD=A.kO()}else{x=n.I
if(x==null)x=n.I=n.ap.N(n.bF)
w=n.G$.gE()
v=E.inT(n.a8,w,n.gE())
u=v.b
t=v.a
s=w.a
r=w.b
q=x.Lf(t,new A.D(0,0,0+s,0+r))
p=n.gE()
o=x.Lf(u,new A.D(0,0,0+p.a,0+p.b))
p=q.a
n.ci=q.c-p<s||q.d-q.b<r
r=A.oP(o.a,o.b,0)
r.rq(u.a/t.a,u.b/t.b,1,1)
r.ir(-p,-q.b,0,1)
n.cD=r}},
aE9(d,e){var x,w,v,u,t=this,s=t.cD
s.toString
x=A.No(s)
if(x==null){s=t.cx
s===$&&A.m()
w=t.cD
w.toString
v=A.n7.prototype.gkX.call(t)
u=t.ch.a
return d.ys(s,e,w,v,u instanceof A.zC?u:null)}else t.kQ(d,e.aC(0,x))
return null},
U(d,e){var x,w,v,u,t=this
if(t.G$==null||t.gE().gbh(0)||t.G$.gE().gbh(0))return
t.ahh()
x=t.ci
x.toString
if(x&&t.ff!==C.u){x=t.cx
x===$&&A.m()
w=t.gE()
v=t.ch
u=v.a
u=u instanceof A.alq?u:null
v.scs(d.tf(x,e,new A.D(0,0,0+w.a,0+w.b),t.gby2(),t.ff,u))}else t.ch.scs(t.aE9(d,e))},
cO(d,e){var x,w=this
if(!w.gE().gbh(0)){x=w.G$
x=x==null?null:x.gE().gbh(0)
x=x===!0}else x=!0
if(x)return!1
w.ahh()
return d.zE(new B.dFR(w),e,w.cD)},
Dm(d){return!this.gE().gbh(0)&&!d.gE().gbh(0)},
hL(d,e){var x
if(!(!this.gE().gbh(0)&&!d.gE().gbh(0)))e.a6d()
else{this.ahh()
x=this.cD
x.toString
e.j3(x)}}}
B.oF.prototype={
az(d){var x=new B.aSr(this.e,this.f,A.cW(d),C.u,null,new A.aY(),A.aM())
x.aw()
x.sbi(null)
return x},
aI(d,e){e.syb(this.e)
e.sk9(this.f)
e.sbJ(A.cW(d))
if(C.u!==e.ff){e.ff=C.u
e.bq()
e.co()}}}
var z=a.updateTypes(["zC?(qa,u)"])
B.dFR.prototype={
$2(d,e){return this.a.Ih(d,e)},
$S:17};(function installTearOffs(){var x=a._instance_2u
x(B.aSr.prototype,"gby2","aE9",0)})();(function inheritance(){var x=a.inherit
x(B.aSr,A.iN)
x(B.dFR,A.dk)
x(B.oF,A.aZ)})()
A.bO(b.typeUniverse,JSON.parse('{"aSr":{"w":[],"bi":["w"],"H":[],"aQ":[]},"oF":{"aZ":[],"aP":[],"b":[]}}'))
var y={a:A.G("B")}};
(a=>{a["9cruCCKDItDPoOiG7NsnWUJNlwY="]=a.current})($__dart_deferred_initializers__);