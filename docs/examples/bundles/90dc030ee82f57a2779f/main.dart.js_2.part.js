((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,D,C={bAY:function bAY(d,e,f,g,h,i,j){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.f=h
_.r=i
_.w=j},
iJU(){var x=new B.apM()
$.ayr()
x.tV()
return new C.hFq(x)},
iJa(){var x,w,v,u,t,s,r,q,p,o,n,m,l,k=J.ih(40,y.G)
for(x=y.H,w=y.T,v=0;v<40;++v){u=A.UE[v]
t=D.o.a4(v,3)
s=A.ctO[t]
r=A.br[t]
q=D.o.a4(v,5)
p=A.bO[q]
if(v===38)o=$.dg()
else{o=$.dg()
n=D.o.cr(v,3)
m=v>=30?16:0
m=B.P(B.a3(o),B.a7(o),B.at(o)+(n-m),0,0,0,0)
o=m}q=[45,90,30,60,120][q]
n=D.o.a4(v,4)
m=[A.at_,A.W0,A.asZ,A.W0][n]
t=B.cE([A.iY[t]],x)
l=B.pS(x)
l.F(0,t)
k[v]=new C.eZ("ST-"+(101+v),u,s,r.a,p.a,o,q,m,new E.Ny(l,w),v>=30,n===0,570)}return k},
iJ9(){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j=$.dg(),i=B.P(B.a3(j),B.a7(j),B.at(j)+(1-B.b5(j)),0,0,0,0),h=B.a([],y.X)
for(j=[-7,0],x=0;x<2;++x){w=j[x]
for(v=w===0,u=0;u<5;++u)for(t=w+u,s=u*3,r=u===4,q=0;q<2;++q){p=v?0:14
o=s+q+p
if(q===0)n=540
else n=v&&r?420:810
p=h.length
m=B.P(B.a3(i),B.a7(i),B.at(i)+t,0,0,0,0)
l=[90,60,135,105,75,45,120][o%7]
k=A.br[o%3]
h.push(new B.b0x([m,n+l,"log-"+(p+1),A.UE[o],k.a,n]))}}return h},
iJ8(){var x,w,v,u,t,s,r,q,p,o=B.a([],y._)
for(x=[A.cXj,A.cXg,A.cXm,A.cXk,A.cXi,A.cXl,A.cXh],w=0;w<7;++w){v=x[w].a
u=v[0]
t=v[1]
s=v[2]
r=v[3]
q=v[4]
v=A.UE[s]
p=$.dg()
o.push(new B.b0v([B.P(B.a3(p),B.a7(p),B.at(p),D.o.cr(r,60),D.o.a4(r,60),0,0),t,q,u,v]))}return o},
hFq:function hFq(d){this.a=d},
axZ(d,e){return B.P(B.a3(d),B.a7(d),B.at(d),D.o.cr(e,60),D.o.a4(e,60),0,0)},
eg:function eg(d,e){this.a=d
this.b=e},
pe:function pe(d,e){this.a=d
this.b=e},
e7:function e7(d,e){this.a=d
this.b=e},
n8:function n8(d,e){this.a=d
this.b=e},
eZ:function eZ(d,e,f,g,h,i,j,k,l,m,n,o){var _=this
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
_.z=n
_.Q=o},
mG:function mG(d,e){this.a=d
this.b=e},
ir3(d,e,f){var x,w,v,u,t=C.iJU(),s=d?null:$.igP(),r=d?B.a([],y._):C.iJ8(),q=B.am(y.N,y.G)
if(!d){for(x=C.iJa(),w=x.length,v=0;v<x.length;x.length===w||(0,B.D)(x),++v){u=x[v]
q.M(0,u.a,u)}d=!1}return new C.dv9(f,e,q,d?B.a([],y.X):C.iJ9(),t,s,r)},
dv9:function dv9(d,e,f,g,h,i,j){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i
_.r=j
_.w=1},
dva:function dva(d){this.a=d},
aO1:function aO1(){}},A,E
J=c[1]
B=c[0]
D=c[2]
C=a.updateHolder(c[179],C)
A=c[636]
E=c[251]
C.bAY.prototype={
pp(){var x=this.w
return C.ir3(x==="empty",x==="error",B.jA(0,0,x==="loading"?3000:220,0,0))}}
C.eg.prototype={
X(){return"Priority."+this.b}}
C.pe.prototype={
X(){return"Label."+this.b}}
C.e7.prototype={
X(){return"Appearance."+this.b}}
C.n8.prototype={
X(){return"Place."+this.b}}
C.eZ.prototype={
uj(d,e,f,g,h,i,j,k,l,a0,a1){var x,w,v,u=this,t=a1==null?u.b:a1,s=i==null?u.c:i,r=k==null?u.d:k,q=d==null?u.e:d,p=f==null?u.f:f,o=g==null?u.r:g,n=j==null?u.w:j,m=h==null?u.x:h
m=E.eX(m,y.H)
x=e==null?u.y:e
w=l==null?u.z:l
v=a0==null?u.Q:a0
return new C.eZ(u.a,t,s,r,q,p,o,n,m,x,w,v)},
pn(d){var x=null
return this.uj(x,x,x,x,x,x,x,x,x,d,x)},
pm(d){var x=null
return this.uj(x,x,x,x,x,x,x,x,d,x,x)},
pg(d){var x=null
return this.uj(x,d,x,x,x,x,x,x,x,x,x)},
ahl(d){var x=null
return this.uj(x,x,x,x,d,x,x,x,x,x,x)},
pk(d){var x=null
return this.uj(x,x,x,x,x,x,d,x,x,x,x)},
ph(d){var x=null
return this.uj(x,x,x,d,x,x,x,x,x,x,x)},
bKf(d){var x=null
return this.uj(x,x,d,x,x,x,x,x,x,x,x)},
pe(d){var x=null
return this.uj(d,x,x,x,x,x,x,x,x,x,x)},
pl(d){var x=null
return this.uj(x,x,x,x,x,x,x,d,x,x,x)},
bKP(d){var x=null
return this.uj(x,x,x,x,x,d,x,x,x,x,x)},
bL_(d){var x=null
return this.uj(x,x,x,x,x,x,x,x,x,x,d)},
bLh(d,e){var x=null
return this.uj(x,d,x,x,x,x,x,e,x,x,x)}}
C.mG.prototype={
X(){return"ActivityKind."+this.b}}
C.dv9.prototype={
gil(){var x,w,v=this,u=v.c
u=B.lF(new B.ba(u,B.T(u).j("ba<2>")),y.G)
x=B.lF(v.d,y.d)
w=v.f
return new B.b0n([B.lF(v.r,y.g),x,u,w])},
jC(){var x=0,w=B.ae(y.J),v,u=this,t
var $async$jC=B.af(function(d,e){if(d===1)return B.ab(e,w)
for(;;)switch(x){case 0:t=u.b
u.b=!1
x=3
return B.a2(B.oz(u.a,y.n),$async$jC)
case 3:if(t)throw B.ap(A.aFX)
v=u.gil()
x=1
break
case 1:return B.ac(v,w)}})
return B.ad($async$jC,w)},
aRL(d){var x,w,v,u,t=this
if(d.y){x=t.c.p(0,d.a)
w=(x==null?null:x.y)===!1}else w=!1
x=d.a
t.c.M(0,x,d)
if(w){v=t.e.$0()
u=t.f
if((u==null?null:u.b)===x)t.OB(v)
t.aDa(A.Yr,d.b,v)}},
af(d,e){var x,w,v,u,t,s,r,q=this,p=B.a([],y.u)
for(x=e.length,w=q.c,v=q.e,u=0;u<e.length;e.length===x||(0,B.D)(e),++u){t=e[u]
s=q.f
if(t===(s==null?null:s.b))q.OB(v.$0())
r=w.af(0,t)
if(r!=null)p.push(r)}return p},
o9(d){var x,w=this,v=w.c.p(0,d),u=!0
if(v!=null)if(!v.y){u=w.f
u=(u==null?null:u.b)===d}if(u)return
x=w.e.$0()
w.OB(x)
w.f=new B.b0i(x,d)
w.aDa(A.Dp,v.b,x)},
OB(d){var x,w,v,u,t,s,r,q,p,o,n=this,m=n.f
if(m==null)return
x=n.c.p(0,m.b)
x.toString
n.f=null
w=m.a
v=B.P(B.a3(w),B.a7(w),B.at(w),0,0,0,0)
u=B.eD(w)*60+B.hR(w)
t=C.axZ(v,u)
s=C.axZ(d,B.eD(d)*60+B.hR(d))
r=s.hw(t)?s:t.Mm(6e7)
w=x.d
x=x.b
q=0
do{p=B.P(B.a3(v),B.a7(v),B.at(v)+1,0,0,0,0)
o=r.fS(p)?B.eD(r)*60+B.hR(r):1440
n.aqy(v,u,o,w,x)
q+=o-u
if(p.fS(r)){v=p
u=0
continue}else break}while(!0)
n.aca(A.n4,x,d,q)},
aca(d,e,f,g){var x=this.r
D.c.iK(x,0,new B.b0v([f,d,g,"maya",e]))
if(x.length>8)x.pop()},
aDa(d,e,f){return this.aca(d,e,f,0)},
pH(d){var x,w,v,u
for(x=d.length,w=this.c,v=0;v<d.length;d.length===x||(0,B.D)(d),++v){u=d[v]
w.fi(u.a,new C.dva(u))}},
aqy(d,e,f,g,h){var x=this.w++
return this.d.push(new B.b0x([B.P(B.a3(d),B.a7(d),B.at(d),0,0,0,0),f,"new-"+x,h,g,e]))}}
C.aO1.prototype={$iiz:1}
var z=a.updateTypes(["eZ()"])
C.hFq.prototype={
$0(){return $.igR().Mm(B.jA(0,this.a.gaNy(),0,0,0).a)},
$S:479}
C.dva.prototype={
$0(){return this.a},
$S:z+0};(function inheritance(){var x=a.inheritMany
x(B.W,[C.bAY,C.eZ,C.dv9,C.aO1])
x(B.cS,[C.hFq,C.dva])
x(B.eh,[C.eg,C.pe,C.e7,C.n8,C.mG])})()
B.bN(b.typeUniverse,JSON.parse('{"aO1":{"iz":[]}}'))
var y=(function rtii(){var x=B.E
return{L:x("n<+(m,m)>"),B:x("n<+id,name(m,+(m,m))>"),_:x("n<+at,kind,minutes,person,subject(bj,mG,u,m,+(m,m))>"),X:x("n<+date,end,id,note,project,start(bj,u,m,+(m,m),m,u)>"),u:x("n<eZ>"),H:x("pe"),J:x("+activity,entries,tasks,timer(V<+at,kind,minutes,person,subject(bj,mG,u,m,+(m,m))>,V<+date,end,id,note,project,start(bj,u,m,+(m,m),m,u)>,V<eZ>,+start,taskId(bj,m)?)"),g:x("+at,kind,minutes,person,subject(bj,mG,u,m,+(m,m))"),d:x("+date,end,id,note,project,start(bj,u,m,+(m,m),m,u)"),N:x("m"),G:x("eZ"),T:x("Ny<pe>"),n:x("~")}})();(function constants(){var x=a.makeConstList
A.Yr=new C.mG(0,"finished")
A.Dp=new C.mG(1,"started")
A.n4=new C.mG(3,"logged")
A.Dt=new C.e7(0,"system")
A.Yw=new C.e7(1,"day")
A.Om=new C.e7(2,"night")
A.aFX=new C.aO1()
A.jm=new B.cu(6e7)
A.cVC=new B.x("Use the courtyard entrance on the public copy. Check the step-free route with Sam before sending it to print.","\u0623\u0638\u0647\u0631 \u0645\u062f\u062e\u0644 \u0627\u0644\u0641\u0646\u0627\u0621 \u0641\u064a \u0646\u0633\u062e\u0629 \u0627\u0644\u0632\u0648\u0627\u0631. \u0631\u0627\u062c\u0639 \u0627\u0644\u0645\u0633\u0627\u0631 \u0627\u0644\u062e\u0627\u0644\u064a \u0645\u0646 \u0627\u0644\u062f\u0631\u062c \u0645\u0639 \u0633\u0627\u0645 \u0642\u0628\u0644 \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0645\u0644\u0641 \u0644\u0644\u0637\u0628\u0627\u0639\u0629.")
A.cT5=new B.x("Compare the latest draft with the marked-up copy on the studio table.","\u0642\u0627\u0631\u0646 \u0627\u0644\u0645\u0633\u0648\u062f\u0629 \u0627\u0644\u0623\u062e\u064a\u0631\u0629 \u0628\u0627\u0644\u0646\u0633\u062e\u0629 \u0627\u0644\u0645\u0635\u062d\u062d\u0629 \u0639\u0644\u0649 \u0637\u0627\u0648\u0644\u0629 \u0627\u0644\u0627\u0633\u062a\u0648\u062f\u064a\u0648.")
A.cVx=new B.x("Confirm the details with the teaching team and add them to the shared schedule.","\u0623\u0643\u0651\u062f \u0627\u0644\u062a\u0641\u0627\u0635\u064a\u0644 \u0645\u0639 \u0641\u0631\u064a\u0642 \u0627\u0644\u062a\u062f\u0631\u064a\u0633 \u0648\u0623\u0636\u0641\u0647\u0627 \u0625\u0644\u0649 \u0627\u0644\u062c\u062f\u0648\u0644 \u0627\u0644\u0645\u0634\u062a\u0631\u0643.")
A.ctO=x([A.cVC,A.cT5,A.cVx],y.L)
A.dq=new C.n8(0,"today")
A.dt=new C.n8(1,"tasks")
A.kl=new C.n8(2,"time")
A.cQa=new C.n8(3,"settings")
A.bA=x([A.dq,A.dt,A.kl,A.cQa],B.E("n<n8>"))
A.cTK=new B.x("Proof the studio map","\u0645\u0631\u0627\u062c\u0639\u0629 \u062e\u0631\u064a\u0637\u0629 \u0627\u0644\u0627\u0633\u062a\u0648\u062f\u064a\u0648")
A.cTg=new B.x("Edit the walking route","\u062a\u062d\u0631\u064a\u0631 \u0645\u0633\u0627\u0631 \u0627\u0644\u0645\u0634\u064a")
A.cVD=new B.x("Confirm the print workshop","\u062a\u0623\u0643\u064a\u062f \u0648\u0631\u0634\u0629 \u0627\u0644\u0637\u0628\u0627\u0639\u0629")
A.cV7=new B.x("Frame the entryway prints","\u062a\u0623\u0637\u064a\u0631 \u0645\u0637\u0628\u0648\u0639\u0627\u062a \u0627\u0644\u0645\u062f\u062e\u0644")
A.cUK=new B.x("Check the specimen captions","\u062a\u062f\u0642\u064a\u0642 \u0634\u0631\u0648\u062d \u0627\u0644\u0639\u064a\u0646\u0627\u062a")
A.cU7=new B.x("Send the materials list","\u0625\u0631\u0633\u0627\u0644 \u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u0645\u0648\u0627\u062f")
A.cTq=new B.x("Hang the courtyard signs","\u062a\u0639\u0644\u064a\u0642 \u0644\u0627\u0641\u062a\u0627\u062a \u0627\u0644\u0641\u0646\u0627\u0621")
A.cVv=new B.x("Sequence the photographs","\u062a\u0631\u062a\u064a\u0628 \u0627\u0644\u0635\u0648\u0631")
A.cTt=new B.x("Book the teaching space","\u062d\u062c\u0632 \u0645\u0633\u0627\u062d\u0629 \u0627\u0644\u062a\u062f\u0631\u064a\u0633")
A.cV1=new B.x("Pack the welcome table","\u062a\u062c\u0647\u064a\u0632 \u0637\u0627\u0648\u0644\u0629 \u0627\u0644\u0627\u0633\u062a\u0642\u0628\u0627\u0644")
A.cUb=new B.x("Draw the footbridge detail","\u0631\u0633\u0645 \u062a\u0641\u0627\u0635\u064a\u0644 \u0627\u0644\u062c\u0633\u0631")
A.cUH=new B.x("Test the clay samples","\u0627\u062e\u062a\u0628\u0627\u0631 \u0639\u064a\u0646\u0627\u062a \u0627\u0644\u0637\u064a\u0646")
A.cV8=new B.x("Check the evening lighting","\u0641\u062d\u0635 \u0627\u0644\u0625\u0636\u0627\u0621\u0629 \u0627\u0644\u0645\u0633\u0627\u0626\u064a\u0629")
A.cTA=new B.x("Write the introduction","\u0643\u062a\u0627\u0628\u0629 \u0627\u0644\u0645\u0642\u062f\u0645\u0629")
A.cUh=new B.x("Set the workshop dates","\u062a\u062d\u062f\u064a\u062f \u0645\u0648\u0627\u0639\u064a\u062f \u0627\u0644\u0648\u0631\u0634")
A.cUe=new B.x("Label the display shelves","\u0648\u0636\u0639 \u0628\u0637\u0627\u0642\u0627\u062a \u0639\u0644\u0649 \u0627\u0644\u0631\u0641\u0648\u0641")
A.cV3=new B.x("Choose the cover stock","\u0627\u062e\u062a\u064a\u0627\u0631 \u0648\u0631\u0642 \u0627\u0644\u063a\u0644\u0627\u0641")
A.cTI=new B.x("Prepare the sign-up form","\u062a\u062c\u0647\u064a\u0632 \u0627\u0633\u062a\u0645\u0627\u0631\u0629 \u0627\u0644\u062a\u0633\u062c\u064a\u0644")
A.cVA=new B.x("Plan the room rotation","\u062a\u062e\u0637\u064a\u0637 \u062a\u0631\u062a\u064a\u0628 \u0627\u0644\u063a\u0631\u0641")
A.cU2=new B.x("Review the foldout proof","\u0645\u0631\u0627\u062c\u0639\u0629 \u0646\u0645\u0648\u0630\u062c \u0627\u0644\u0645\u0637\u0648\u064a\u0629")
A.cVm=new B.x("Reserve the drying racks","\u062d\u062c\u0632 \u0631\u0641\u0648\u0641 \u0627\u0644\u062a\u062c\u0641\u064a\u0641")
A.cTs=new B.x("Order clips for the wall","\u0637\u0644\u0628 \u0645\u0634\u0627\u0628\u0643 \u0644\u0644\u062d\u0627\u0626\u0637")
A.cUf=new B.x("Credit the contributors","\u0625\u0636\u0627\u0641\u0629 \u0623\u0633\u0645\u0627\u0621 \u0627\u0644\u0645\u0633\u0627\u0647\u0645\u064a\u0646")
A.cVf=new B.x("Prepare the tool kits","\u062a\u062c\u0647\u064a\u0632 \u062d\u0642\u0627\u0626\u0628 \u0627\u0644\u0623\u062f\u0648\u0627\u062a")
A.cTM=new B.x("Mark the accessible route","\u062a\u062d\u062f\u064a\u062f \u0627\u0644\u0645\u0633\u0627\u0631 \u0627\u0644\u0645\u064a\u0633\u0651\u0631")
A.cUI=new B.x("Index the plant names","\u0641\u0647\u0631\u0633\u0629 \u0623\u0633\u0645\u0627\u0621 \u0627\u0644\u0646\u0628\u0627\u062a\u0627\u062a")
A.cTH=new B.x("Invite the guest tutor","\u062f\u0639\u0648\u0629 \u0627\u0644\u0645\u062f\u0631\u0651\u0633 \u0627\u0644\u0636\u064a\u0641")
A.cTC=new B.x("Update the visitor list","\u062a\u062d\u062f\u064a\u062b \u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u0632\u0648\u0627\u0631")
A.cV5=new B.x("Scan the notebook pages","\u0645\u0633\u062d \u0635\u0641\u062d\u0627\u062a \u0627\u0644\u062f\u0641\u062a\u0631")
A.cVq=new B.x("Cut the paper bundles","\u0642\u0635 \u0631\u0632\u0645 \u0627\u0644\u0648\u0631\u0642")
A.cUm=new B.x("Collect the loan frames","\u062c\u0645\u0639 \u0627\u0644\u0625\u0637\u0627\u0631\u0627\u062a \u0627\u0644\u0645\u0633\u062a\u0639\u0627\u0631\u0629")
A.cU0=new B.x("Number the map stops","\u062a\u0631\u0642\u064a\u0645 \u0645\u062d\u0637\u0627\u062a \u0627\u0644\u062e\u0631\u064a\u0637\u0629")
A.cUX=new B.x("Count the spare aprons","\u0639\u062f\u0651 \u0627\u0644\u0645\u0631\u0627\u064a\u0644 \u0627\u0644\u0627\u062d\u062a\u064a\u0627\u0637\u064a\u0629")
A.cTf=new B.x("File the installation plan","\u0623\u0631\u0634\u0641\u0629 \u062e\u0637\u0629 \u0627\u0644\u062a\u0631\u0643\u064a\u0628")
A.cTy=new B.x("Approve the spine type","\u0627\u0639\u062a\u0645\u0627\u062f \u062e\u0637 \u0643\u0639\u0628 \u0627\u0644\u0643\u062a\u0627\u0628")
A.cUL=new B.x("Share the class outline","\u0645\u0634\u0627\u0631\u0643\u0629 \u0645\u062e\u0637\u0637 \u0627\u0644\u062f\u0631\u0633")
A.cVj=new B.x("Confirm the steward rota","\u062a\u0623\u0643\u064a\u062f \u0645\u0646\u0627\u0648\u0628\u0627\u062a \u0627\u0644\u0645\u0634\u0631\u0641\u064a\u0646")
A.cUY=new B.x("Check the archive dates","\u0645\u0631\u0627\u062c\u0639\u0629 \u062a\u0648\u0627\u0631\u064a\u062e \u0627\u0644\u0623\u0631\u0634\u064a\u0641")
A.cVr=new B.x("Print attendance sheets","\u0637\u0628\u0627\u0639\u0629 \u0623\u0648\u0631\u0627\u0642 \u0627\u0644\u062d\u0636\u0648\u0631")
A.cUS=new B.x("Return the sample boards","\u0625\u0639\u0627\u062f\u0629 \u0623\u0644\u0648\u0627\u062d \u0627\u0644\u0639\u064a\u0646\u0627\u062a")
A.UE=x([A.cTK,A.cTg,A.cVD,A.cV7,A.cUK,A.cU7,A.cTq,A.cVv,A.cTt,A.cV1,A.cUb,A.cUH,A.cV8,A.cTA,A.cUh,A.cUe,A.cV3,A.cTI,A.cVA,A.cU2,A.cVm,A.cTs,A.cUf,A.cVf,A.cTM,A.cUI,A.cTH,A.cTC,A.cV5,A.cVq,A.cUm,A.cU0,A.cUX,A.cTf,A.cTy,A.cUL,A.cVj,A.cUY,A.cVr,A.cUS],y.L)
A.cTd=new B.x("Maya Reed","\u0645\u0627\u064a\u0627 \u0631\u064a\u062f")
A.cV4=new B.Bv("maya",A.cTd)
A.cTJ=new B.x("Sam Okafor","\u0633\u0627\u0645 \u0623\u0648\u0643\u0627\u0641\u0648\u0631")
A.cTl=new B.Bv("sam",A.cTJ)
A.cUZ=new B.x("Noor Haddad","\u0646\u0648\u0631 \u062d\u062f\u0627\u062f")
A.cV9=new B.Bv("noor",A.cUZ)
A.cVi=new B.x("Inez Park","\u0625\u064a\u0646\u064a\u0632 \u0628\u0627\u0631\u0643")
A.cVB=new B.Bv("inez",A.cVi)
A.cTn=new B.x("Leo Silva","\u0644\u064a\u0648 \u0633\u064a\u0644\u0641\u0627")
A.cU8=new B.Bv("leo",A.cTn)
A.bO=x([A.cV4,A.cTl,A.cV9,A.cVB,A.cU8],y.B)
A.asZ=new C.eg(0,"low")
A.W0=new C.eg(1,"normal")
A.at_=new C.eg(2,"high")
A.cU6=new B.x("Open studio","\u0627\u0644\u0627\u0633\u062a\u0648\u062f\u064a\u0648 \u0627\u0644\u0645\u0641\u062a\u0648\u062d")
A.cV2=new B.Bv("studio",A.cU6)
A.cVz=new B.x("Field guide","\u0627\u0644\u062f\u0644\u064a\u0644 \u0627\u0644\u0645\u064a\u062f\u0627\u0646\u064a")
A.cVb=new B.Bv("guide",A.cVz)
A.cTB=new B.x("Workshop series","\u0633\u0644\u0633\u0644\u0629 \u0627\u0644\u0648\u0631\u0634")
A.cTj=new B.Bv("workshops",A.cTB)
A.br=x([A.cV2,A.cVb,A.cTj],y.B)
A.cpq=new C.pe(0,"planning")
A.cpr=new C.pe(1,"review")
A.cps=new C.pe(2,"fieldwork")
A.iY=x([A.cpq,A.cpr,A.cps],B.E("n<pe>"))
A.Ys=new C.mG(2,"commented")
A.cXg=new B.Bx(["leo",A.Ys,4,585,0])
A.cXh=new B.Bx(["maya",A.Dp,0,498,0])
A.cXi=new B.Bx(["noor",A.Dp,2,544,0])
A.cXj=new B.Bx(["inez",A.n4,13,600,120])
A.cXk=new B.Bx(["inez",A.Yr,38,565,0])
A.cXl=new B.Bx(["sam",A.Ys,1,521,0])
A.cXm=new B.Bx(["inez",A.Dp,3,577,0])})();(function lazyInitializers(){var x=a.lazyFinal
x($,"iSP","dg",()=>B.P(2026,11,20,0,0,0,0))
x($,"iSO","igR",()=>C.axZ($.dg(),600))
x($,"iSM","igP",()=>new B.b0i(C.axZ($.dg(),498),"ST-101"))})()};
(a=>{a["yZl0pz+q0QYFvHTOnAD5VDIYsVQ="]=a.current})($__dart_deferred_initializers__);