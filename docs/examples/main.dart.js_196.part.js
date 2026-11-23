((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var A,C,B={aRP:function aRP(d,e,f,g,h,i,j){var _=this
_.H=null
_.a8=d
_.ao=e
_.bF=f
_.cA=_.ce=null
_.fj=g
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
_.dx=$},dE5:function dE5(d){this.a=d},
dD(d,e,f){return new B.ow(f,d,e,null)},
ow:function ow(d,e,f,g){var _=this
_.e=d
_.f=e
_.c=f
_.a=g}},D,E
A=c[0]
C=c[2]
B=a.updateHolder(c[254],B)
D=c[458]
E=c[263]
B.aRP.prototype={
axh(d){switch(d.a){case 6:return!0
case 1:case 2:case 0:case 4:case 3:case 5:return!1}},
sxU(d){var x=this,w=x.a8
if(w===d)return
x.a8=d
if(x.axh(w)||x.axh(d))x.a6()
else{x.cA=x.ce=null
x.bn()}},
skr(d){var x=this
if(x.ao.i(0,d))return
x.ao=d
x.H=x.cA=x.ce=null
x.bn()},
sbD(d){var x=this
if(x.bF==d)return
x.bF=d
x.H=x.cA=x.ce=null
x.bn()},
bU(d){var x,w=this.F$
if(w!=null){x=w.a_(C.ar,D.eX,w.gbZ())
switch(this.a8.a){case 6:return d.aV(new A.A(0,d.b,0,d.d).K6(x))
case 1:case 2:case 0:case 4:case 3:case 5:return d.K6(x)}}else return new A.H(A.a6(0,d.a,d.b),A.a6(0,d.c,d.d))},
fS(d,e){var x=this.F$
return x==null?null:x.hB(D.eX,e)},
bq(){var x,w,v=this,u=v.F$
if(u!=null){u.bg(D.eX,!0)
switch(v.a8.a){case 6:u=y.a
x=u.a(A.G.prototype.gV.call(v))
w=new A.A(0,x.b,0,x.d).K6(v.F$.gD())
v.fy=u.a(A.G.prototype.gV.call(v)).aV(w)
break
case 1:case 2:case 0:case 4:case 3:case 5:v.fy=y.a.a(A.G.prototype.gV.call(v)).K6(v.F$.gD())
break}v.cA=v.ce=null}else{u=y.a.a(A.G.prototype.gV.call(v))
v.fy=new A.H(A.a6(0,u.a,u.b),A.a6(0,u.c,u.d))}},
age(){var x,w,v,u,t,s,r,q,p,o,n=this
if(n.cA!=null)return
if(n.F$==null){n.ce=!1
n.cA=A.kL()}else{x=n.H
if(x==null)x=n.H=n.ao.L(n.bF)
w=n.F$.gD()
v=E.ikD(n.a8,w,n.gD())
u=v.b
t=v.a
s=w.a
r=w.b
q=x.KV(t,new A.C(0,0,0+s,0+r))
p=n.gD()
o=x.KV(u,new A.C(0,0,0+p.a,0+p.b))
p=q.a
n.ce=q.c-p<s||q.d-q.b<r
r=A.oG(o.a,o.b,0)
r.r2(u.a/t.a,u.b/t.b,1,1)
r.ip(-p,-q.b,0,1)
n.cA=r}},
aDf(d,e){var x,w,v,u,t=this,s=t.cA
s.toString
x=A.Nq(s)
if(x==null){s=t.cx
s===$&&A.l()
w=t.cA
w.toString
v=A.n2.prototype.gkM.call(t)
u=t.ch.a
return d.yd(s,e,w,v,u instanceof A.zv?u:null)}else t.l9(d,e.aC(0,x))
return null},
U(d,e){var x,w,v,u,t=this
if(t.F$==null||t.gD().gbf(0)||t.F$.gD().gbf(0))return
t.age()
x=t.ce
x.toString
if(x&&t.fj!==C.u){x=t.cx
x===$&&A.l()
w=t.gD()
v=t.ch
u=v.a
u=u instanceof A.al1?u:null
v.scm(d.rU(x,e,new A.C(0,0,0+w.a,0+w.b),t.gbx8(),t.fj,u))}else t.ch.scm(t.aDf(d,e))},
cH(d,e){var x,w=this
if(!w.gD().gbf(0)){x=w.F$
x=x==null?null:x.gD().gbf(0)
x=x===!0}else x=!0
if(x)return!1
w.age()
return d.zo(new B.dE5(w),e,w.cA)},
D0(d){return!this.gD().gbf(0)&&!d.gD().gbf(0)},
hI(d,e){var x
if(!(!this.gD().gbf(0)&&!d.gD().gbf(0)))e.a5j()
else{this.age()
x=this.cA
x.toString
e.iY(x)}}}
B.ow.prototype={
aw(d){var x=new B.aRP(this.e,this.f,A.d5(d),C.u,null,new A.aY(),A.aN())
x.av()
x.sbk(null)
return x},
aJ(d,e){e.sxU(this.e)
e.skr(this.f)
e.sbD(A.d5(d))
if(C.u!==e.fj){e.fj=C.u
e.bn()
e.cv()}}}
var z=a.updateTypes(["zv?(pZ,t)"])
B.dE5.prototype={
$2(d,e){return this.a.HR(d,e)},
$S:17};(function installTearOffs(){var x=a._instance_2u
x(B.aRP.prototype,"gbx8","aDf",0)})();(function inheritance(){var x=a.inherit
x(B.aRP,A.j3)
x(B.dE5,A.de)
x(B.ow,A.b1)})()
A.bM(b.typeUniverse,JSON.parse('{"aRP":{"v":[],"bk":["v"],"G":[],"aQ":[]},"ow":{"b1":[],"aP":[],"b":[]}}'))
var y={a:A.E("A")}};
(a=>{a["GkRfQ+N5CWwFxkahSuzCDKOZJyI="]=a.current})($__dart_deferred_initializers__);