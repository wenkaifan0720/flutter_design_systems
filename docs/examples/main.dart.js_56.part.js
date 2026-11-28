((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,D,A={
a55(d){if(d<0)return-1
else if(d===0)return 0
else return 1},
jdw(d,e,f){return(1-f)*d+f*e},
jdv(d,e,f){if(f<d)return d
else if(f>e)return e
return f},
iuk(d,e){var x,w,v,u,t=d[0],s=e[0],r=s[0],q=d[1],p=s[1],o=d[2]
s=s[2]
x=e[1]
w=x[0]
v=x[1]
x=x[2]
u=e[2]
return B.a([t*r+q*p+o*s,t*w+q*v+o*x,t*u[0]+q*u[1]+o*u[2]],y.h)},
iEP(d,e,f){return((d&255)<<16|(e&255)<<8|f&255|4278190080)>>>0},
iEN(d){return A.iEP(A.cZa(d[0]),A.cZa(d[1]),A.cZa(d[2]))},
lU(d){return A.iuk(B.a([A.irx(d>>>16&255),A.irx(d>>>8&255),A.irx(d&255)],y.h),C.ahX)},
irw(d){var x=A.cZa(A.cZb(d))
return A.iEP(x,x,x)},
cZb(d){return 100*A.j7L((d+16)/116)},
irx(d){var x=d/255
if(x<=0.040449936)return x/12.92*100
else return Math.pow((x+0.055)/1.055,2.4)*100},
cZa(d){var x=d/100
return A.jdv(0,255,C.i.ah((x<=0.0031308?x*12.92:1.055*Math.pow(x,0.4166666666666667)-0.055)*255))},
mB(d){if(d>0.008856451679035631)return Math.pow(d,0.3333333333333333)
else return(903.2962962962963*d+16)/116},
j7L(d){var x=d*d*d
if(x>0.008856451679035631)return x
else return(116*d-16)/903.2962962962963},
n6(a4,a5){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g=A.lU(a4),f=g[0],e=g[1],d=g[2],a0=a5.as,a1=a0[0]*(0.401288*f+0.650173*e-0.051461*d),a2=a0[1]*(-0.250268*f+1.204414*e+0.045854*d),a3=a0[2]*(-0.002079*f+0.048952*e+0.953127*d)
a0=a5.at
x=Math.pow(a0*Math.abs(a1)/100,0.42)
w=Math.pow(a0*Math.abs(a2)/100,0.42)
v=Math.pow(a0*Math.abs(a3)/100,0.42)
u=A.a55(a1)*400*x/(x+27.13)
t=A.a55(a2)*400*w/(w+27.13)
s=A.a55(a3)*400*v/(v+27.13)
r=(11*u+-12*t+s)/11
q=(u+t-2*s)/9
a0=20*t
p=Math.atan2(q,r)*180/3.141592653589793
if(p<0)o=p+360
else o=p>=360?p-360:p
n=o*3.141592653589793/180
m=a5.r
l=a5.y
k=100*Math.pow((40*u+a0+s)/20*a5.w/m,l*a5.ay)
j=k/100
Math.sqrt(j)
i=Math.pow(3846.153846153846*(0.25*(Math.cos((o<20.14?o+360:o)*3.141592653589793/180+2)+3.8))*a5.z*a5.x*Math.sqrt(r*r+q*q)/((20*u+a0+21*s)/20+0.305),0.9)*Math.pow(1.64-Math.pow(0.29,a5.f),0.73)
h=i*Math.sqrt(j)
Math.sqrt(i*l/(m+4))
Math.log(1+0.0228*(h*a5.ax))
Math.cos(n)
Math.sin(n)
return new A.cTT(o,h,k,B.a([0,0,0],y.h))},
dn7(d){var x=d/100
return(x<=0.0031308?x*12.92:1.055*Math.pow(x,0.4166666666666667)-0.055)*255},
itB(d){var x=Math.pow(Math.abs(d),0.42)
return A.a55(d)*400*x/(x+27.13)},
itD(d){var x=A.iuk(d,C.aor),w=A.itB(x[0]),v=A.itB(x[1]),u=A.itB(x[2])
return Math.atan2((w+v-2*u)/9,(11*w+-12*v+u)/11)},
jcd(d,e){var x,w,v,u,t,s=C.o.a8(e,4)<=1?0:100,r=(e&1)===0?0:100
if(e<4){x=(d-s*0.7152-r*0.0722)/0.2126
w=0<=x&&x<=100
v=y.h
if(w)return B.a([x,s,r],v)
else return B.a([-1,-1,-1],v)}else if(e<8){u=(d-r*0.2126-s*0.0722)/0.7152
w=0<=u&&u<=100
v=y.h
if(w)return B.a([r,u,s],v)
else return B.a([-1,-1,-1],v)}else{t=(d-s*0.2126-r*0.7152)/0.0722
w=0<=t&&t<=100
v=y.h
if(w)return B.a([s,r,t],v)
else return B.a([-1,-1,-1],v)}},
jc9(d,e){var x,w,v,u,t,s,r,q,p=B.a([-1,-1,-1],y.h)
for(x=p,w=0,v=0,u=!1,t=!0,s=0;s<12;++s){r=A.jcd(d,s)
if(r[0]<0)continue
q=A.itD(r)
if(!u){v=q
w=v
x=r
p=x
u=!0
continue}if(t||C.i.a8(q-w+25.132741228718345,6.283185307179586)<C.i.a8(v-w+25.132741228718345,6.283185307179586)){if(C.i.a8(e-w+25.132741228718345,6.283185307179586)<C.i.a8(q-w+25.132741228718345,6.283185307179586)){v=q
x=r}else{w=q
p=r}t=!1}}return B.a([p,x],y.d)},
jc7(d,e){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i=A.jc9(d,e),h=i[0],g=A.itD(h),f=i[1]
for(x=y.h,w=0;w<3;++w){v=h[w]
u=f[w]
if(v!==u){if(v<u){t=C.i.cJ(A.dn7(v)-0.5)
s=C.i.fj(A.dn7(f[w])-0.5)}else{t=C.i.fj(A.dn7(v)-0.5)
s=C.i.cJ(A.dn7(f[w])-0.5)}for(r=0;r<8;++r)if(Math.abs(s-t)<=1)break
else{q=C.i.cJ((t+s)/2)
p=C.app[q]
v=h[w]
o=(p-v)/(f[w]-v)
v=h[0]
u=f[0]
n=h[1]
m=f[1]
l=h[2]
k=B.a([v+(u-v)*o,n+(m-n)*o,l+(f[2]-l)*o],x)
j=A.itD(k)
if(C.i.a8(e-g+25.132741228718345,6.283185307179586)<C.i.a8(j-g+25.132741228718345,6.283185307179586)){s=q
f=k}else{t=q
g=j
h=k}}}}return B.a([(h[0]+f[0])/2,(h[1]+f[1])/2,(h[2]+f[2])/2],x)},
itF(d){var x=Math.abs(d),w=Math.max(0,27.13*x/(400-x))
return A.a55(d)*Math.pow(w,2.380952380952381)},
jcb(a2,a3,a4){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g=Math.sqrt(a4)*11,f=$.j2v(),e=1/Math.pow(1.64-Math.pow(0.29,f.f),0.73),d=Math.cos(a2+2),a0=Math.sin(a2),a1=Math.cos(a2)
for(x=f.r,w=1/f.y/f.ay,v=f.w,d=23*(0.25*(d+3.8)*3846.153846153846*f.z*f.x),u=y.h,t=a3!==0,s=0;s<5;++s){r=g/100
q=Math.pow((!t||g===0?0:a3/Math.sqrt(r))*e,1.1111111111111112)
p=x*Math.pow(r,w)/v
o=23*(p+0.305)*q/(d+11*q*a1+108*q*a0)
n=o*a1
m=o*a0
l=460*p
k=A.iuk(B.a([A.itF((l+451*n+288*m)/1403),A.itF((l-891*n-261*m)/1403),A.itF((l-220*n-6300*m)/1403)],u),C.ahr)
l=k[0]
if(l<0||k[1]<0||k[2]<0)return 0
j=k[1]
i=k[2]
h=0.2126*l+0.7152*j+0.0722*i
if(h<=0)return 0
if(s===4||Math.abs(h-a4)<0.002){if(l>100.01||j>100.01||i>100.01)return 0
return A.iEN(k)}g-=(h-a4)*g/(2*h)}return 0},
lZ(d,e,f){var x,w,v,u
if(e<0.0001||f<0.0001||f>99.9999)return A.irw(f)
x=C.i.a8(d,360)
w=(x<0?x+360:x)/180*3.141592653589793
v=A.cZb(f)
u=A.jcb(w,e,v)
if(u!==0)return u
return A.iEN(A.jc7(v,w))},
eI(a5){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4=new A.bCw()
a4.d=a5
x=$.nG()
w=A.lU(a5)
v=w[0]
u=w[1]
t=w[2]
s=x.as
r=s[0]*(0.401288*v+0.650173*u-0.051461*t)
q=s[1]*(-0.250268*v+1.204414*u+0.045854*t)
p=s[2]*(-0.002079*v+0.048952*u+0.953127*t)
s=x.at
o=Math.pow(s*Math.abs(r)/100,0.42)
n=Math.pow(s*Math.abs(q)/100,0.42)
m=Math.pow(s*Math.abs(p)/100,0.42)
l=A.a55(r)*400*o/(o+27.13)
k=A.a55(q)*400*n/(n+27.13)
j=A.a55(p)*400*m/(m+27.13)
i=(11*l+-12*k+j)/11
h=(l+k-2*j)/9
s=20*k
g=Math.atan2(h,i)*180/3.141592653589793
if(g<0)f=g+360
else f=g>=360?g-360:g
e=f*3.141592653589793/180
d=x.r
a0=x.y
a1=100*Math.pow((40*l+s+j)/20*x.w/d,a0*x.ay)/100
Math.sqrt(a1)
a2=Math.pow(3846.153846153846*(0.25*(Math.cos((f<20.14?f+360:f)*3.141592653589793/180+2)+3.8))*x.z*x.x*Math.sqrt(i*i+h*h)/((20*l+s+21*j)/20+0.305),0.9)*Math.pow(1.64-Math.pow(0.29,x.f),0.73)
a3=a2*Math.sqrt(a1)
Math.sqrt(a2*a0/(d+4))
Math.log(1+0.0228*(a3*x.ax))
Math.cos(e)
Math.sin(e)
a4.a=f
a4.b=a3
a4.c=116*A.mB(A.lU(a5)[1]/100)-16
return a4},
e3d:function e3d(d,e,f,g,h,i,j,k,l,m){var _=this
_.f=d
_.r=e
_.w=f
_.x=g
_.y=h
_.z=i
_.as=j
_.at=k
_.ax=l
_.ay=m},
cTT:function cTT(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.y=g},
bCw:function bCw(){var _=this
_.d=_.c=_.b=_.a=$},
cz(d,e,f){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j=J.j5Z(e,!1)
if(j.length===0||A.aUj(d,j)>=f)return d
x=A.eI(d.B(1).bv())
w=new A.dHT(x,d)
v=new A.dHV(x,new A.dHU(w,j,f))
u=v.$1(0)
t=v.$1(100)
s=u==null
if(s&&t==null){s=x.c
s===$&&B.i()
r=A.aUj(w.$1(s),j)
for(q=s,p=0;p<=100;p+=0.5){o=A.aUj(w.$1(p),j)
if(o>r){r=o
q=p}}return w.$1(q)}if(s){t.toString
return w.$1(t)}if(t==null)return w.$1(u)
s=x.c
s===$&&B.i()
n=s-u
m=t-s
if(n!==m)return w.$1(n<m?u:t)
l=w.$1(u)
k=w.$1(t)
return A.aUj(l,j)>=A.aUj(k,j)?l:k},
aUj(d,e){return new B.aV(e,new A.dHR(d),B.aC(e).k("aV<1,q>")).cR(0,E.e9)},
dHT:function dHT(d,e){this.a=d
this.b=e},
dHU:function dHU(d,e,f){this.a=d
this.b=e
this.c=f},
dHV:function dHV(d,e){this.a=d
this.b=e},
dHR:function dHR(d){this.a=d}},E
J=c[1]
B=c[0]
C=c[2]
D=c[270]
A=a.updateHolder(c[246],A)
E=c[297]
A.e3d.prototype={}
A.cTT.prototype={}
A.bCw.prototype={
i(d,e){var x,w
if(e==null)return!1
if(!(e instanceof A.bCw))return!1
x=e.d
x===$&&B.i()
w=this.d
w===$&&B.i()
return x===w},
ga2(d){var x=this.d
x===$&&B.i()
return C.o.ga2(x)},
D(d){var x,w,v=this.a
v===$&&B.i()
v=C.o.D(C.i.ah(v))
x=this.b
x===$&&B.i()
x=C.i.ah(x)
w=this.c
w===$&&B.i()
return"H"+v+" C"+x+" T"+C.o.D(C.i.ah(w))}}
var z=a.updateTypes([])
A.dHT.prototype={
$1(d){var x=this.a,w=x.a
w===$&&B.i()
x=x.b
x===$&&B.i()
x=A.eI(A.lZ(w,x,d)).d
x===$&&B.i()
return B.dC(x).B(this.b.gcs())},
$S:168}
A.dHU.prototype={
$1(d){return A.aUj(this.a.$1(d),this.b)>=this.c},
$S:51}
A.dHV.prototype={
$1(d){var x,w,v,u,t,s,r,q=this.a.c
q===$&&B.i()
x=d<q?-1:1
for(w=this.b,v=q;q=d-v,q*x>0;v=u){u=Math.abs(q)<1?d:v+x
if(w.$1(u)){for(t=u,s=0;s<7;++s){r=(v+t)/2
if(w.$1(r))t=r
else v=r}return t}}return null},
$S:478}
A.dHR.prototype={
$1(d){return D.h7(this.a,d)},
$S:159};(function inheritance(){var x=a.inheritMany
x(B.a_,[A.e3d,A.cTT,A.bCw])
x(B.cp,[A.dHT,A.dHU,A.dHV,A.dHR])})()
var y={d:B.G("o<U<q>>"),h:B.G("o<q>")};(function lazyInitializers(){var x=a.lazyFinal
x($,"jHa","j2v",()=>$.nG())
x($,"jH8","nG",()=>{var w,v,u,t,s,r,q,p,o,n,m,l,k,j=63.66197723675813*A.cZb(50)/100,i=B.ikQ(0.1,50),h=A.jdw(0.59,0.69,0.9999999999999998),g=1-0.2777777777777778*B.iY9((-j-42)/92)
if(g>1)g=1
else if(g<0)g=0
w=B.a([g*1.0250597119338924+1-g,g*0.9837978481337839+1-g,g*0.9218550445387449+1-g],y.h)
v=5*j
u=1/(v+1)
t=u*u*u*u
s=1-t
r=t*j+0.1*s*s*B.B8(v,0.3333333333333333)
q=A.cZb(i)/100
v=B.j_X(q)
p=0.725/B.B8(q,0.2)
o=[B.B8(r*w[0]*97.555292473/100,0.42),B.B8(r*w[1]*101.64689848600003/100,0.42),B.B8(r*w[2]*108.47692442799999/100,0.42)]
n=o[0]
m=o[1]
l=o[2]
k=[400*n/(n+27.13),400*m/(m+27.13),400*l/(l+27.13)]
return new A.e3d(q,(40*k[0]+20*k[1]+k[2])/20*p,p,p,h,1,w,r,B.B8(r,0.25),1.48+v)})})()};
(a=>{a["hmBJVqlaSZmFCMNXLZ3MJGBq4IY="]=a.current})($__dart_deferred_initializers__);