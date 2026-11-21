((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,D,C={bzH:function bzH(d,e,f,g,h,i,j){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.f=h
_.r=i
_.w=j},
iG5(){var x=new B.apu()
$.axZ()
x.tU()
return new C.hCh(x)},
iFm(){var x,w,v,u,t,s,r,q,p,o,n,m,l,k=J.ia(40,y.G)
for(x=y.H,w=y.T,v=0;v<40;++v){u=A.UF[v]
t=D.o.a3(v,3)
s=A.cuj[t]
r=A.br[t]
q=D.o.a3(v,5)
p=A.bW[q]
if(v===38)o=$.dk()
else{o=$.dk()
n=D.o.cq(v,3)
m=v>=30?16:0
m=B.P(B.a2(o),B.a7(o),B.at(o)+(n-m),0,0,0,0)
o=m}q=[45,90,30,60,120][q]
n=D.o.a3(v,4)
m=[A.at2,A.W1,A.at1,A.W1][n]
t=B.cJ([A.iW[t]],x)
l=B.pP(x)
l.E(0,t)
k[v]=new C.eY("ST-"+(101+v),u,s,r.a,p.a,o,q,m,new E.Nn(l,w),v>=30,n===0,570)}return k},
iFl(){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j=$.dk(),i=B.P(B.a2(j),B.a7(j),B.at(j)+(1-B.b4(j)),0,0,0,0),h=B.a([],y.X)
for(j=[-7,0],x=0;x<2;++x){w=j[x]
for(v=w===0,u=0;u<5;++u)for(t=w+u,s=u*3,r=u===4,q=0;q<2;++q){p=v?0:14
o=s+q+p
if(q===0)n=540
else n=v&&r?420:810
p=h.length
m=B.P(B.a2(i),B.a7(i),B.at(i)+t,0,0,0,0)
l=[90,60,135,105,75,45,120][o%7]
k=A.br[o%3]
h.push(new B.b_P([m,n+l,"log-"+(p+1),A.UF[o],k.a,n]))}}return h},
iFk(){var x,w,v,u,t,s,r,q,p,o=B.a([],y._)
for(x=[A.cXp,A.cXm,A.cXs,A.cXq,A.cXo,A.cXr,A.cXn],w=0;w<7;++w){v=x[w].a
u=v[0]
t=v[1]
s=v[2]
r=v[3]
q=v[4]
v=A.UF[s]
p=$.dk()
o.push(new B.b_N([B.P(B.a2(p),B.a7(p),B.at(p),D.o.cq(r,60),D.o.a3(r,60),0,0),t,q,u,v]))}return o},
hCh:function hCh(d){this.a=d},
axv(d,e){return B.P(B.a2(d),B.a7(d),B.at(d),D.o.cq(e,60),D.o.a3(e,60),0,0)},
eg:function eg(d,e){this.a=d
this.b=e},
p5:function p5(d,e){this.a=d
this.b=e},
e7:function e7(d,e){this.a=d
this.b=e},
n1:function n1(d,e){this.a=d
this.b=e},
eY:function eY(d,e,f,g,h,i,j,k,l,m,n,o){var _=this
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
my:function my(d,e){this.a=d
this.b=e},
inp(d,e,f){var x,w,v,u,t=C.iG5(),s=d?null:$.ide(),r=d?B.a([],y._):C.iFk(),q=B.aj(y.N,y.G)
if(!d){for(x=C.iFm(),w=x.length,v=0;v<x.length;x.length===w||(0,B.E)(x),++v){u=x[v]
q.M(0,u.a,u)}d=!1}return new C.dtM(f,e,q,d?B.a([],y.X):C.iFl(),t,s,r)},
dtM:function dtM(d,e,f,g,h,i,j){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i
_.r=j
_.w=1},
dtN:function dtN(d){this.a=d},
aNz:function aNz(){}},A,E
J=c[1]
B=c[0]
D=c[2]
C=a.updateHolder(c[174],C)
A=c[628]
E=c[243]
C.bzH.prototype={
pl(){var x=this.w
return C.inp(x==="empty",x==="error",B.kF(0,0,x==="loading"?3000:220,0,0))}}
C.eg.prototype={
W(){return"Priority."+this.b}}
C.p5.prototype={
W(){return"Label."+this.b}}
C.e7.prototype={
W(){return"Appearance."+this.b}}
C.n1.prototype={
W(){return"Place."+this.b}}
C.eY.prototype={
uh(d,e,f,g,h,i,j,k,l,a0,a1){var x,w,v,u=this,t=a1==null?u.b:a1,s=i==null?u.c:i,r=k==null?u.d:k,q=d==null?u.e:d,p=f==null?u.f:f,o=g==null?u.r:g,n=j==null?u.w:j,m=h==null?u.x:h
m=E.f1(m,y.H)
x=e==null?u.y:e
w=l==null?u.z:l
v=a0==null?u.Q:a0
return new C.eY(u.a,t,s,r,q,p,o,n,m,x,w,v)},
pj(d){var x=null
return this.uh(x,x,x,x,x,x,x,x,x,d,x)},
pi(d){var x=null
return this.uh(x,x,x,x,x,x,x,x,d,x,x)},
pc(d){var x=null
return this.uh(x,d,x,x,x,x,x,x,x,x,x)},
agQ(d){var x=null
return this.uh(x,x,x,x,d,x,x,x,x,x,x)},
pg(d){var x=null
return this.uh(x,x,x,x,x,x,d,x,x,x,x)},
pd(d){var x=null
return this.uh(x,x,x,d,x,x,x,x,x,x,x)},
bJ5(d){var x=null
return this.uh(x,x,d,x,x,x,x,x,x,x,x)},
pa(d){var x=null
return this.uh(d,x,x,x,x,x,x,x,x,x,x)},
ph(d){var x=null
return this.uh(x,x,x,x,x,x,x,d,x,x,x)},
bJF(d){var x=null
return this.uh(x,x,x,x,x,d,x,x,x,x,x)},
bJQ(d){var x=null
return this.uh(x,x,x,x,x,x,x,x,x,x,d)},
bK7(d,e){var x=null
return this.uh(x,d,x,x,x,x,x,e,x,x,x)}}
C.my.prototype={
W(){return"ActivityKind."+this.b}}
C.dtM.prototype={
gih(){var x,w,v=this,u=v.c
u=B.lD(new B.ba(u,B.W(u).j("ba<2>")),y.G)
x=B.lD(v.d,y.d)
w=v.f
return new B.b_F([B.lD(v.r,y.g),x,u,w])},
jy(){var x=0,w=B.ae(y.J),v,u=this,t
var $async$jy=B.af(function(d,e){if(d===1)return B.ab(e,w)
for(;;)switch(x){case 0:t=u.b
u.b=!1
x=3
return B.a1(B.oo(u.a,y.n),$async$jy)
case 3:if(t)throw B.ap(A.aFT)
v=u.gih()
x=1
break
case 1:return B.ac(v,w)}})
return B.ad($async$jy,w)},
aQS(d){var x,w,v,u,t=this
if(d.y){x=t.c.p(0,d.a)
w=(x==null?null:x.y)===!1}else w=!1
x=d.a
t.c.M(0,x,d)
if(w){v=t.e.$0()
u=t.f
if((u==null?null:u.b)===x)t.Os(v)
t.aCo(A.Yk,d.b,v)}},
af(d,e){var x,w,v,u,t,s,r,q=this,p=B.a([],y.u)
for(x=e.length,w=q.c,v=q.e,u=0;u<e.length;e.length===x||(0,B.E)(e),++u){t=e[u]
s=q.f
if(t===(s==null?null:s.b))q.Os(v.$0())
r=w.af(0,t)
if(r!=null)p.push(r)}return p},
o1(d){var x,w=this,v=w.c.p(0,d),u=!0
if(v!=null)if(!v.y){u=w.f
u=(u==null?null:u.b)===d}if(u)return
x=w.e.$0()
w.Os(x)
w.f=new B.b_A(x,d)
w.aCo(A.Dl,v.b,x)},
Os(d){var x,w,v,u,t,s,r,q,p,o,n=this,m=n.f
if(m==null)return
x=n.c.p(0,m.b)
x.toString
n.f=null
w=m.a
v=B.P(B.a2(w),B.a7(w),B.at(w),0,0,0,0)
u=B.eC(w)*60+B.hO(w)
t=C.axv(v,u)
s=C.axv(d,B.eC(d)*60+B.hO(d))
r=s.ht(t)?s:t.Mf(6e7)
w=x.d
x=x.b
q=0
do{p=B.P(B.a2(v),B.a7(v),B.at(v)+1,0,0,0,0)
o=r.fR(p)?B.eC(r)*60+B.hO(r):1440
n.aq_(v,u,o,w,x)
q+=o-u
if(p.fR(r)){v=p
u=0
continue}else break}while(!0)
n.abO(A.n3,x,d,q)},
abO(d,e,f,g){var x=this.r
D.c.iH(x,0,new B.b_N([f,d,g,"maya",e]))
if(x.length>8)x.pop()},
aCo(d,e,f){return this.abO(d,e,f,0)},
pD(d){var x,w,v,u
for(x=d.length,w=this.c,v=0;v<d.length;d.length===x||(0,B.E)(d),++v){u=d[v]
w.fm(u.a,new C.dtN(u))}},
aq_(d,e,f,g,h){var x=this.w++
return this.d.push(new B.b_P([B.P(B.a2(d),B.a7(d),B.at(d),0,0,0,0),f,"new-"+x,h,g,e]))}}
C.aNz.prototype={$iiv:1}
var z=a.updateTypes(["eY()"])
C.hCh.prototype={
$0(){return $.idg().Mf(B.kF(0,this.a.gaMF(),0,0,0).a)},
$S:447}
C.dtN.prototype={
$0(){return this.a},
$S:z+0};(function inheritance(){var x=a.inheritMany
x(B.V,[C.bzH,C.eY,C.dtM,C.aNz])
x(B.cS,[C.hCh,C.dtN])
x(B.ek,[C.eg,C.p5,C.e7,C.n1,C.my])})()
B.bN(b.typeUniverse,JSON.parse('{"aNz":{"iv":[]}}'))
var y=(function rtii(){var x=B.D
return{L:x("n<+(m,m)>"),B:x("n<+id,name(m,+(m,m))>"),_:x("n<+at,kind,minutes,person,subject(bj,my,u,m,+(m,m))>"),X:x("n<+date,end,id,note,project,start(bj,u,m,+(m,m),m,u)>"),u:x("n<eY>"),H:x("p5"),J:x("+activity,entries,tasks,timer(T<+at,kind,minutes,person,subject(bj,my,u,m,+(m,m))>,T<+date,end,id,note,project,start(bj,u,m,+(m,m),m,u)>,T<eY>,+start,taskId(bj,m)?)"),g:x("+at,kind,minutes,person,subject(bj,my,u,m,+(m,m))"),d:x("+date,end,id,note,project,start(bj,u,m,+(m,m),m,u)"),N:x("m"),G:x("eY"),T:x("Nn<p5>"),n:x("~")}})();(function constants(){var x=a.makeConstList
A.Yk=new C.my(0,"finished")
A.Dl=new C.my(1,"started")
A.n3=new C.my(3,"logged")
A.Do=new C.e7(0,"system")
A.Yp=new C.e7(1,"day")
A.Oi=new C.e7(2,"night")
A.aFT=new C.aNz()
A.jn=new B.ct(6e7)
A.cVI=new B.y("Use the courtyard entrance on the public copy. Check the step-free route with Sam before sending it to print.","\u0623\u0638\u0647\u0631 \u0645\u062f\u062e\u0644 \u0627\u0644\u0641\u0646\u0627\u0621 \u0641\u064a \u0646\u0633\u062e\u0629 \u0627\u0644\u0632\u0648\u0627\u0631. \u0631\u0627\u062c\u0639 \u0627\u0644\u0645\u0633\u0627\u0631 \u0627\u0644\u062e\u0627\u0644\u064a \u0645\u0646 \u0627\u0644\u062f\u0631\u062c \u0645\u0639 \u0633\u0627\u0645 \u0642\u0628\u0644 \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0645\u0644\u0641 \u0644\u0644\u0637\u0628\u0627\u0639\u0629.")
A.cTb=new B.y("Compare the latest draft with the marked-up copy on the studio table.","\u0642\u0627\u0631\u0646 \u0627\u0644\u0645\u0633\u0648\u062f\u0629 \u0627\u0644\u0623\u062e\u064a\u0631\u0629 \u0628\u0627\u0644\u0646\u0633\u062e\u0629 \u0627\u0644\u0645\u0635\u062d\u062d\u0629 \u0639\u0644\u0649 \u0637\u0627\u0648\u0644\u0629 \u0627\u0644\u0627\u0633\u062a\u0648\u062f\u064a\u0648.")
A.cVD=new B.y("Confirm the details with the teaching team and add them to the shared schedule.","\u0623\u0643\u0651\u062f \u0627\u0644\u062a\u0641\u0627\u0635\u064a\u0644 \u0645\u0639 \u0641\u0631\u064a\u0642 \u0627\u0644\u062a\u062f\u0631\u064a\u0633 \u0648\u0623\u0636\u0641\u0647\u0627 \u0625\u0644\u0649 \u0627\u0644\u062c\u062f\u0648\u0644 \u0627\u0644\u0645\u0634\u062a\u0631\u0643.")
A.cuj=x([A.cVI,A.cTb,A.cVD],y.L)
A.dq=new C.n1(0,"today")
A.dt=new C.n1(1,"tasks")
A.ko=new C.n1(2,"time")
A.cQG=new C.n1(3,"settings")
A.bA=x([A.dq,A.dt,A.ko,A.cQG],B.D("n<n1>"))
A.cTQ=new B.y("Proof the studio map","\u0645\u0631\u0627\u062c\u0639\u0629 \u062e\u0631\u064a\u0637\u0629 \u0627\u0644\u0627\u0633\u062a\u0648\u062f\u064a\u0648")
A.cTm=new B.y("Edit the walking route","\u062a\u062d\u0631\u064a\u0631 \u0645\u0633\u0627\u0631 \u0627\u0644\u0645\u0634\u064a")
A.cVJ=new B.y("Confirm the print workshop","\u062a\u0623\u0643\u064a\u062f \u0648\u0631\u0634\u0629 \u0627\u0644\u0637\u0628\u0627\u0639\u0629")
A.cVd=new B.y("Frame the entryway prints","\u062a\u0623\u0637\u064a\u0631 \u0645\u0637\u0628\u0648\u0639\u0627\u062a \u0627\u0644\u0645\u062f\u062e\u0644")
A.cUQ=new B.y("Check the specimen captions","\u062a\u062f\u0642\u064a\u0642 \u0634\u0631\u0648\u062d \u0627\u0644\u0639\u064a\u0646\u0627\u062a")
A.cUd=new B.y("Send the materials list","\u0625\u0631\u0633\u0627\u0644 \u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u0645\u0648\u0627\u062f")
A.cTw=new B.y("Hang the courtyard signs","\u062a\u0639\u0644\u064a\u0642 \u0644\u0627\u0641\u062a\u0627\u062a \u0627\u0644\u0641\u0646\u0627\u0621")
A.cVB=new B.y("Sequence the photographs","\u062a\u0631\u062a\u064a\u0628 \u0627\u0644\u0635\u0648\u0631")
A.cTz=new B.y("Book the teaching space","\u062d\u062c\u0632 \u0645\u0633\u0627\u062d\u0629 \u0627\u0644\u062a\u062f\u0631\u064a\u0633")
A.cV7=new B.y("Pack the welcome table","\u062a\u062c\u0647\u064a\u0632 \u0637\u0627\u0648\u0644\u0629 \u0627\u0644\u0627\u0633\u062a\u0642\u0628\u0627\u0644")
A.cUh=new B.y("Draw the footbridge detail","\u0631\u0633\u0645 \u062a\u0641\u0627\u0635\u064a\u0644 \u0627\u0644\u062c\u0633\u0631")
A.cUN=new B.y("Test the clay samples","\u0627\u062e\u062a\u0628\u0627\u0631 \u0639\u064a\u0646\u0627\u062a \u0627\u0644\u0637\u064a\u0646")
A.cVe=new B.y("Check the evening lighting","\u0641\u062d\u0635 \u0627\u0644\u0625\u0636\u0627\u0621\u0629 \u0627\u0644\u0645\u0633\u0627\u0626\u064a\u0629")
A.cTG=new B.y("Write the introduction","\u0643\u062a\u0627\u0628\u0629 \u0627\u0644\u0645\u0642\u062f\u0645\u0629")
A.cUn=new B.y("Set the workshop dates","\u062a\u062d\u062f\u064a\u062f \u0645\u0648\u0627\u0639\u064a\u062f \u0627\u0644\u0648\u0631\u0634")
A.cUk=new B.y("Label the display shelves","\u0648\u0636\u0639 \u0628\u0637\u0627\u0642\u0627\u062a \u0639\u0644\u0649 \u0627\u0644\u0631\u0641\u0648\u0641")
A.cV9=new B.y("Choose the cover stock","\u0627\u062e\u062a\u064a\u0627\u0631 \u0648\u0631\u0642 \u0627\u0644\u063a\u0644\u0627\u0641")
A.cTO=new B.y("Prepare the sign-up form","\u062a\u062c\u0647\u064a\u0632 \u0627\u0633\u062a\u0645\u0627\u0631\u0629 \u0627\u0644\u062a\u0633\u062c\u064a\u0644")
A.cVG=new B.y("Plan the room rotation","\u062a\u062e\u0637\u064a\u0637 \u062a\u0631\u062a\u064a\u0628 \u0627\u0644\u063a\u0631\u0641")
A.cU8=new B.y("Review the foldout proof","\u0645\u0631\u0627\u062c\u0639\u0629 \u0646\u0645\u0648\u0630\u062c \u0627\u0644\u0645\u0637\u0648\u064a\u0629")
A.cVs=new B.y("Reserve the drying racks","\u062d\u062c\u0632 \u0631\u0641\u0648\u0641 \u0627\u0644\u062a\u062c\u0641\u064a\u0641")
A.cTy=new B.y("Order clips for the wall","\u0637\u0644\u0628 \u0645\u0634\u0627\u0628\u0643 \u0644\u0644\u062d\u0627\u0626\u0637")
A.cUl=new B.y("Credit the contributors","\u0625\u0636\u0627\u0641\u0629 \u0623\u0633\u0645\u0627\u0621 \u0627\u0644\u0645\u0633\u0627\u0647\u0645\u064a\u0646")
A.cVl=new B.y("Prepare the tool kits","\u062a\u062c\u0647\u064a\u0632 \u062d\u0642\u0627\u0626\u0628 \u0627\u0644\u0623\u062f\u0648\u0627\u062a")
A.cTS=new B.y("Mark the accessible route","\u062a\u062d\u062f\u064a\u062f \u0627\u0644\u0645\u0633\u0627\u0631 \u0627\u0644\u0645\u064a\u0633\u0651\u0631")
A.cUO=new B.y("Index the plant names","\u0641\u0647\u0631\u0633\u0629 \u0623\u0633\u0645\u0627\u0621 \u0627\u0644\u0646\u0628\u0627\u062a\u0627\u062a")
A.cTN=new B.y("Invite the guest tutor","\u062f\u0639\u0648\u0629 \u0627\u0644\u0645\u062f\u0631\u0651\u0633 \u0627\u0644\u0636\u064a\u0641")
A.cTI=new B.y("Update the visitor list","\u062a\u062d\u062f\u064a\u062b \u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u0632\u0648\u0627\u0631")
A.cVb=new B.y("Scan the notebook pages","\u0645\u0633\u062d \u0635\u0641\u062d\u0627\u062a \u0627\u0644\u062f\u0641\u062a\u0631")
A.cVw=new B.y("Cut the paper bundles","\u0642\u0635 \u0631\u0632\u0645 \u0627\u0644\u0648\u0631\u0642")
A.cUs=new B.y("Collect the loan frames","\u062c\u0645\u0639 \u0627\u0644\u0625\u0637\u0627\u0631\u0627\u062a \u0627\u0644\u0645\u0633\u062a\u0639\u0627\u0631\u0629")
A.cU6=new B.y("Number the map stops","\u062a\u0631\u0642\u064a\u0645 \u0645\u062d\u0637\u0627\u062a \u0627\u0644\u062e\u0631\u064a\u0637\u0629")
A.cV2=new B.y("Count the spare aprons","\u0639\u062f\u0651 \u0627\u0644\u0645\u0631\u0627\u064a\u0644 \u0627\u0644\u0627\u062d\u062a\u064a\u0627\u0637\u064a\u0629")
A.cTl=new B.y("File the installation plan","\u0623\u0631\u0634\u0641\u0629 \u062e\u0637\u0629 \u0627\u0644\u062a\u0631\u0643\u064a\u0628")
A.cTE=new B.y("Approve the spine type","\u0627\u0639\u062a\u0645\u0627\u062f \u062e\u0637 \u0643\u0639\u0628 \u0627\u0644\u0643\u062a\u0627\u0628")
A.cUR=new B.y("Share the class outline","\u0645\u0634\u0627\u0631\u0643\u0629 \u0645\u062e\u0637\u0637 \u0627\u0644\u062f\u0631\u0633")
A.cVp=new B.y("Confirm the steward rota","\u062a\u0623\u0643\u064a\u062f \u0645\u0646\u0627\u0648\u0628\u0627\u062a \u0627\u0644\u0645\u0634\u0631\u0641\u064a\u0646")
A.cV3=new B.y("Check the archive dates","\u0645\u0631\u0627\u062c\u0639\u0629 \u062a\u0648\u0627\u0631\u064a\u062e \u0627\u0644\u0623\u0631\u0634\u064a\u0641")
A.cVx=new B.y("Print attendance sheets","\u0637\u0628\u0627\u0639\u0629 \u0623\u0648\u0631\u0627\u0642 \u0627\u0644\u062d\u0636\u0648\u0631")
A.cUY=new B.y("Return the sample boards","\u0625\u0639\u0627\u062f\u0629 \u0623\u0644\u0648\u0627\u062d \u0627\u0644\u0639\u064a\u0646\u0627\u062a")
A.UF=x([A.cTQ,A.cTm,A.cVJ,A.cVd,A.cUQ,A.cUd,A.cTw,A.cVB,A.cTz,A.cV7,A.cUh,A.cUN,A.cVe,A.cTG,A.cUn,A.cUk,A.cV9,A.cTO,A.cVG,A.cU8,A.cVs,A.cTy,A.cUl,A.cVl,A.cTS,A.cUO,A.cTN,A.cTI,A.cVb,A.cVw,A.cUs,A.cU6,A.cV2,A.cTl,A.cTE,A.cUR,A.cVp,A.cV3,A.cVx,A.cUY],y.L)
A.cTj=new B.y("Maya Reed","\u0645\u0627\u064a\u0627 \u0631\u064a\u062f")
A.cVa=new B.Bo("maya",A.cTj)
A.cTP=new B.y("Sam Okafor","\u0633\u0627\u0645 \u0623\u0648\u0643\u0627\u0641\u0648\u0631")
A.cTr=new B.Bo("sam",A.cTP)
A.cV4=new B.y("Noor Haddad","\u0646\u0648\u0631 \u062d\u062f\u0627\u062f")
A.cVf=new B.Bo("noor",A.cV4)
A.cVo=new B.y("Inez Park","\u0625\u064a\u0646\u064a\u0632 \u0628\u0627\u0631\u0643")
A.cVH=new B.Bo("inez",A.cVo)
A.cTt=new B.y("Leo Silva","\u0644\u064a\u0648 \u0633\u064a\u0644\u0641\u0627")
A.cUe=new B.Bo("leo",A.cTt)
A.bW=x([A.cVa,A.cTr,A.cVf,A.cVH,A.cUe],y.B)
A.at1=new C.eg(0,"low")
A.W1=new C.eg(1,"normal")
A.at2=new C.eg(2,"high")
A.cUc=new B.y("Open studio","\u0627\u0644\u0627\u0633\u062a\u0648\u062f\u064a\u0648 \u0627\u0644\u0645\u0641\u062a\u0648\u062d")
A.cV8=new B.Bo("studio",A.cUc)
A.cVF=new B.y("Field guide","\u0627\u0644\u062f\u0644\u064a\u0644 \u0627\u0644\u0645\u064a\u062f\u0627\u0646\u064a")
A.cVh=new B.Bo("guide",A.cVF)
A.cTH=new B.y("Workshop series","\u0633\u0644\u0633\u0644\u0629 \u0627\u0644\u0648\u0631\u0634")
A.cTp=new B.Bo("workshops",A.cTH)
A.br=x([A.cV8,A.cVh,A.cTp],y.B)
A.cpW=new C.p5(0,"planning")
A.cpX=new C.p5(1,"review")
A.cpY=new C.p5(2,"fieldwork")
A.iW=x([A.cpW,A.cpX,A.cpY],B.D("n<p5>"))
A.Yl=new C.my(2,"commented")
A.cXm=new B.Bq(["leo",A.Yl,4,585,0])
A.cXn=new B.Bq(["maya",A.Dl,0,498,0])
A.cXo=new B.Bq(["noor",A.Dl,2,544,0])
A.cXp=new B.Bq(["inez",A.n3,13,600,120])
A.cXq=new B.Bq(["inez",A.Yk,38,565,0])
A.cXr=new B.Bq(["sam",A.Yl,1,521,0])
A.cXs=new B.Bq(["inez",A.Dl,3,577,0])})();(function lazyInitializers(){var x=a.lazyFinal
x($,"iOZ","dk",()=>B.P(2026,11,20,0,0,0,0))
x($,"iOY","idg",()=>C.axv($.dk(),600))
x($,"iOW","ide",()=>new B.b_A(C.axv($.dk(),498),"ST-101"))})()};
(a=>{a["aZqJB8OyaT1zWsgvtamAcVpmutA="]=a.current})($__dart_deferred_initializers__);