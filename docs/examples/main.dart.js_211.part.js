((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var A,C,E,B={aSK:function aSK(d,e,f,g,h,i,j){var _=this
_.I=null
_.a8=d
_.ap=e
_.bF=f
_.cD=_.ci=null
_.eV=g
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
_.dx=$},dGR:function dGR(d){this.a=d},
dD(d,e,f){return new B.oG(f,d,e,null)},
oG:function oG(d,e,f,g){var _=this
_.e=d
_.f=e
_.c=f
_.a=g}},D
A=c[0]
C=c[2]
E=c[273]
B=a.updateHolder(c[263],B)
D=c[468]
B.aSK.prototype={
ayt(d){switch(d.a){case 6:return!0
case 1:case 2:case 0:case 4:case 3:case 5:return!1}},
syp(d){var x=this,w=x.a8
if(w===d)return
x.a8=d
if(x.ayt(w)||x.ayt(d))x.a6()
else{x.cD=x.ci=null
x.bs()}},
skc(d){var x=this
if(x.ap.i(0,d))return
x.ap=d
x.I=x.cD=x.ci=null
x.bs()},
sbK(d){var x=this
if(x.bF==d)return
x.bF=d
x.I=x.cD=x.ci=null
x.bs()},
bZ(d){var x,w=this.G$
if(w!=null){x=w.a_(C.av,D.eC,w.gc3())
switch(this.a8.a){case 6:return d.aT(new A.z(0,d.b,0,d.d).KB(x))
case 1:case 2:case 0:case 4:case 3:case 5:return d.KB(x)}}else return new A.I(A.a7(0,d.a,d.b),A.a7(0,d.c,d.d))},
h_(d,e){var x=this.G$
return x==null?null:x.hP(D.eC,e)},
bu(){var x,w,v=this,u=v.G$
if(u!=null){u.bk(D.eC,!0)
switch(v.a8.a){case 6:u=y.a
x=u.a(A.H.prototype.gX.call(v))
w=new A.z(0,x.b,0,x.d).KB(v.G$.gE())
v.fy=u.a(A.H.prototype.gX.call(v)).aT(w)
break
case 1:case 2:case 0:case 4:case 3:case 5:v.fy=y.a.a(A.H.prototype.gX.call(v)).KB(v.G$.gE())
break}v.cD=v.ci=null}else{u=y.a.a(A.H.prototype.gX.call(v))
v.fy=new A.I(A.a7(0,u.a,u.b),A.a7(0,u.c,u.d))}},
ahJ(){var x,w,v,u,t,s,r,q,p,o,n=this
if(n.cD!=null)return
if(n.G$==null){n.ci=!1
n.cD=A.kR()}else{x=n.I
if(x==null)x=n.I=n.ap.N(n.bF)
w=n.G$.gE()
v=E.iqd(n.a8,w,n.gE())
u=v.b
t=v.a
s=w.a
r=w.b
q=x.Lt(t,new A.D(0,0,0+s,0+r))
p=n.gE()
o=x.Lt(u,new A.D(0,0,0+p.a,0+p.b))
p=q.a
n.ci=q.c-p<s||q.d-q.b<r
r=A.oQ(o.a,o.b,0)
r.rw(u.a/t.a,u.b/t.b,1,1)
r.iw(-p,-q.b,0,1)
n.cD=r}},
aEv(d,e){var x,w,v,u,t=this,s=t.cD
s.toString
x=A.NF(s)
if(x==null){s=t.cx
s===$&&A.m()
w=t.cD
w.toString
v=A.n7.prototype.gl_.call(t)
u=t.ch.a
return d.yH(s,e,w,v,u instanceof A.zJ?u:null)}else t.kR(d,e.aD(0,x))
return null},
U(d,e){var x,w,v,u,t=this
if(t.G$==null||t.gE().gbi(0)||t.G$.gE().gbi(0))return
t.ahJ()
x=t.ci
x.toString
if(x&&t.eV!==C.v){x=t.cx
x===$&&A.m()
w=t.gE()
v=t.ch
u=v.a
u=u instanceof A.alN?u:null
v.scs(d.tk(x,e,new A.D(0,0,0+w.a,0+w.b),t.gbyz(),t.eV,u))}else t.ch.scs(t.aEv(d,e))},
cO(d,e){var x,w=this
if(!w.gE().gbi(0)){x=w.G$
x=x==null?null:x.gE().gbi(0)
x=x===!0}else x=!0
if(x)return!1
w.ahJ()
return d.zR(new B.dGR(w),e,w.cD)},
Dw(d){return!this.gE().gbi(0)&&!d.gE().gbi(0)},
hU(d,e){var x
if(!(!this.gE().gbi(0)&&!d.gE().gbi(0)))e.a6E()
else{this.ahJ()
x=this.cD
x.toString
e.j5(x)}}}
B.oG.prototype={
az(d){var x=new B.aSK(this.e,this.f,A.cX(d),C.v,null,new A.aY(),A.aM())
x.aw()
x.sbj(null)
return x},
aH(d,e){e.syp(this.e)
e.skc(this.f)
e.sbK(A.cX(d))
if(C.v!==e.eV){e.eV=C.v
e.bs()
e.co()}}}
var z=a.updateTypes(["zJ?(qe,u)"])
B.dGR.prototype={
$2(d,e){return this.a.Ip(d,e)},
$S:17};(function installTearOffs(){var x=a._instance_2u
x(B.aSK.prototype,"gbyz","aEv",0)})();(function inheritance(){var x=a.inherit
x(B.aSK,A.iQ)
x(B.dGR,A.di)
x(B.oG,A.aZ)})()
A.bN(b.typeUniverse,JSON.parse('{"aSK":{"w":[],"bi":["w"],"H":[],"aQ":[]},"oG":{"aZ":[],"aP":[],"b":[]}}'))
var y={a:A.G("z")}};
(a=>{a["GiqlQP/PcWsWPXr5XY2zY27rnlY="]=a.current})($__dart_deferred_initializers__);