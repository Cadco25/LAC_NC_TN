/*********************************************************/
/******************** SAS MACROS  ************************/
/*********************************************************/

/*********************************************************/
/*************** CREATING PARAMETERS ESTIMATES************/
/*********************************************************/
%macro beta(par);
proc iml;
use _beta_;
	read all into b;
close _beta_;
n=nrow(b);
npar=&par+1;
%do i=0 %to &par;
	b&i=j(1,8,0);
	nome={"id" "geocod" "x" "y" "b" "sebi" "tstat" "probtstat"};
	create b&i from b&i[colname=nome];
	do i=1 to (n/npar);	* from i=1 to N;
		b&i[1,]=b[(i-1)*npar+&i+1,];
		append from b&i; 
	end;
%end;
quit;
%mend beta;


/*********************************************************/
/***** PARAMETERS FOR STATIONARITY TEST ******************/
/*********************************************************/
%macro vk(par);
proc iml;
use _beta_;
	read all into b;
close _beta_;

use _alpha_;
	read all var {alphai} into alpha;
close _alpha_;

n=nrow(b); 
npar=&par+1;
n=n/npar;
vk=0;
%do i=0 %to &par;
	b&i=j(n,1,0);
	do i=1 to n;
		b&i[i,1]=b[(i-1)*npar+&i+1,5];
	end;
	vk&i=sum((b&i - b&i[:] )##2)/n ;
	vk=vk||vk&i;
%end;
vka= sum((alpha - alpha[:] )##2)/n ;
vk=vk||vka;
idx = setdif(1:(npar+2),1);
vk = vk[,idx];
create vk from vk;
append from vk;
quit;
%mend vk;

/*********************************************************/
/***** PERMUTATION FOR STATIONARITY TEST *****************/
/*********************************************************/

%macro perm(data=,geocod=,x=,y=);
proc iml;
	use &data;
	read all var{&geocod &x &y} into tab;
	close &data;
	n=nrow(tab); 
    u = 1:n;                  
    call randgen(u, "Uniform"); 
    _u_=rank(u);   
	create perm var{_u_};
	append;
quit;
data perm; merge perm &data(drop= &geocod &x &y) ; run;
proc sort data=perm; by _u_; run;
data perm; merge perm &data(keep=&geocod &x &y); run;
%mend perm;

/*********************************************************/
/******************** STATIONARITY TEST ******************/
/*********************************************************/

%macro estac(data=,y=,x=,lat=,long=,h=,grid=,latg=,longg=,gwr=,method=,alphag=,offset=,geocod=,rep=);
%let nvar=0;
%do %while(%scan(%str(&x),&nvar+1)~=);
    %let nvar=%eval(&nvar+1);
%end;
%gwnbr(data=&data,y=&y,x=&x,lat=&lat,long=&long,h=&h,grid=&grid,
latg=&latg,longg=&longg,gwr=&gwr,method=&method,alphag=&alphag,
offset=&offset,geocod=&geocod);
%vk(&nvar);
data vk2; set vk; i=1; run;
%do it=2 %to (&rep+1);
	%perm(data=&data,geocod=&geocod,x=&long,y=&lat);
	%gwnbr(data=perm,y=&y,x=&x,lat=&lat,long=&long,h=&h,grid=&grid,
	latg=&latg,longg=&longg,gwr=&gwr,method=&method,alphag=&alphag,
	offset=&offset,geocod=&geocod);
	%vk(&nvar);
	data vk; set vk; i=&it; run;
	proc append base=vk2 data=vk force; run;
%end;

proc iml;
use vk2;
	read all into x;
close vk2;
nvar=ncol(x)-1;
n=nrow(x);
count=j(1,nvar,0);
do v=1 to nvar;
	do i=1 to n;
		if x[i,v]>=x[1,v] then count[v]=count[v]+1;
	end;
end;
count=count/n;
varnames="b0":"b&nvar"||"alpha";
print 'Stationarity Test - H0):All parameters are equal',,count[label='P-value' colname=varnames];
create pvalor_est from count [colname=varnames];
append from count;
quit;
%mend estac;



/*********************************************************/
/***************** GOLDEN SECTION SEARCH *****************/
/*********************************************************/
%macro golden(data=,y=,x=,lat=,long=,method=,type=,gwr=,offset=,out=);
proc iml;
use &data;
	read all var {&y} into y;
	read all var {&x} into x;
	read all var{&long &lat} into COORD;   
	n=nrow(y);
	%if &offset= %then %do; offset=j(n,1,0); %end;
	%else %do; read all var {&offset} into offset; %end;
close &data;
x=j(n,1,1)||x;
method= "&method"; *fixed, adaptive1 ou adaptiven;
type="&type"; *aic , cv ou dev ;
gwr="&gwr"; *global, local, poisson;
print method type gwr;

start dist(coord,n);
	d=j(1,3,0);
	nome={"idi" "idj" "d"};
	create _dist_ from d[colname=nome];
	do i=1 to n;
        do j=i+1 to n;
	        if abs(coord[,1])<180 then do;
	            dif=abs(COORD[i,1]-COORD[j,1]);
	            raio=arcos(-1)/180;
				ang=sin(COORD[i,2]*raio)*sin(COORD[j,2]*raio)+cos(COORD[i,2]*raio)*cos(COORD[j,2]*raio)*cos(dif*raio);
				arco=arcos(ang);
	        	d[1]=i;
	        	d[2]=j;
	        	d[3]=arco*6371 /*Earth's Radius = 6371 (approximately)*/;
	        	append from d;
	        end;
	        else do;
	            d[1]=i;
	            d[2]=j;
	            d[3]=sqrt((COORD[i,1]-COORD[j,1])**2+(COORD[i,2]-COORD[j,2])**2);
	            append from d;
	        end;
        end;
	end;
	close _dist_;
finish dist;
run dist(coord,n);
use _dist_;
	read all into d;
	maxd=int(max(d[,3])+1);
	free d;
close _dist_;
if	method= "adaptive1" then do;
	h0= 5 ; h3= n; 
end;
else if method= "adaptiven" | method= "fixed" then do;
	h0= 0 ; h3= maxd;
end;
r=0.61803399; c=1-r;
if method= "adaptive1" then tol=0.9; else tol=0.1;
h1=h0+(1-r)*(h3-h0);
h2=h0+r*(h3-h0);
print h0 h1 h2 h3;

start cv(h) global(method, n, coord, x, y, type, maxd, gwr, offset);
	alphaii= j(n,2,0);
	yhat=j(n,1,0);
	S=j(n,n,0);
	if gwr="global" then do;
		ym=sum(y)/nrow(y);
		u=(y+ym)/2;
		n=log(u);
		par=1; ddpar=1; j=0; aux2=0;
		do while (abs(ddpar)>0.00001);
			aux1=0; dpar=1; parold=par;
			do while (abs(dpar)>0.001);
				aux1=aux1+1;
				if par<0 then do;
					par=0.00001;
				end;
				par=choose(par<1E-10,1E-10,par);
		        g=sum(digamma(par+y)-digamma(par)+log(par)+1-log(par+u)-(par+y)/(par+u));
		        hess=sum(trigamma(par+y)-trigamma(par)+1/par-2/(par+u)+(y+par)/((par+u)#(par+u)));
				hess=choose(abs(hess)<1E-23,sign(hess)*1E-23,hess);
				hess=choose(hess=0,1E-23,hess);
		        par0=par;
		        par=par0-inv(hess)*g;
				if aux1>50 & par>1E5 then do;
					dpar= 0.0001;
					aux2=aux2+1;
					if aux2=1 then par=2 ;	
					else if aux2=2 then par=1E5;
					else if aux2=3 then par=0.0001; 
				end;
				else dpar=par-par0;
			end;
			a=1/par; dev=0; ddev=1; i=0;
			do while (abs(ddev)>0.00001);
				i=i+1;
		        w=(u/(1+a*u))+(y-u)#(a*u/(1+2*a*u+a*a*u#u));
		        z=n+(y-u)/(w#(1+a*u)) - offset;
		        b=inv((x#w)`*x)*(x#w)`*z;
		        n=x*b + offset;
		        u=exp(n);
		        olddev=dev;
				tt=y/u;
				tt=choose(tt=0,1E-10,tt);
		        dev=2*sum(y#log(tt)-(y+1/a)#log((1+a*y)/(1+a*u)));
		        ddev=dev-olddev;
			end;
			if aux2>4 then ddpar=1E-9; 
			else ddpar=par-parold;
		end;
		alpha=a;
	end;
	n=nrow(y);
	aux2=0;
	do i=1 to n; 
		d=j(1,3,0); 
		dist=d;
        do j=1 to n;
	        if abs(coord[,1])<180 then do;
                dif=abs(COORD[i,1]-COORD[j,1]);
                raio=arcos(-1)/180;
				ang=sin(COORD[i,2]*raio)*sin(COORD[j,2]*raio)+cos(COORD[i,2]*raio)*cos(COORD[j,2]*raio)*cos(dif*raio);
				if i=j then arco=0;
                else arco=arcos(ang);
                d1=arco*6371;
	        end;
	        else d1=sqrt((COORD[i,1]-COORD[j,1])**2+(COORD[i,2]-COORD[j,2])**2);      
			d[1]=i; d[2]=j; d[3]=d1;
			if j=1 then dist=d;
			else dist=dist//d;
		end;
		u=nrow(dist);
		w=j(u,1,0);
		if method= "fixed" then do;
			if type="cv" then do;
		        do jj=1 to u;
					if dist[jj,3]<=maxd*0.8 & dist[jj,3]^=0 then w[jj]=exp(-0.5*(dist[jj,3]/h)**2);
					else w[jj]=	0;
		        end;
			end;
			else do;
		        do jj=1 to u;
					if dist[jj,3]<=maxd*0.8 then w[jj]=exp(-0.5*(dist[jj,3]/h)**2);
					else w[jj]=	0;
		        end;
			end;
		end;
		else if method= "adaptiven" then do;
			if type="cv" then do;
		        do jj=1 to u;
					if dist[jj,3]<=h & dist[jj,3]^=0 then w[jj]=(1-(dist[jj,3]/h)**2)**2;
					else w[jj]=	0;
		        end;
			end;
			else do;
		        do jj=1 to u;
					if dist[jj,3]<=h then w[jj]=(1-(dist[jj,3]/h)**2)**2;
					else w[jj]=	0;
		        end;
			end;
		end;
		else if method= "adaptive1" then do;
			call sort(dist,{3});
			dist=dist||(1:n)`;
			w=j(n,2,0);	 
			hn=dist[h,3]; 
			if type="cv" then do;
				do jj=1 to n;
			 		if dist[jj,4]<= h & dist[jj,3]^=0 then w[jj,1]=(1-(dist[jj,3]/hn)**2)**2;
					else w[jj,1]=0;
					w[jj,2]=dist[jj,2];
				end;
			end;
			else do;
				do jj=1 to n;
			 		if dist[jj,4]<=h then w[jj,1]=(1-(dist[jj,3]/hn)**2)**2;
					else w[jj,1]=0;
					w[jj,2]=dist[jj,2];
				end;
			end;
			call sort(w,{2});
		end;
		wi=w[,1]; 
		ym=sum(y)/nrow(y);
		uj=(y+ym)/2;
		nj=log(uj);
		if i=1 | aux2=5 then par=1; else par=alphaii[i-1,2]; 
		ddpar=1; jj=0; count=0; aux2=0;
		do while (abs(ddpar)>0.000001);
			aux1=0;
			dpar=1;
			parold=par;
			if gwr="global" | gwr="poisson" then do;
				dpar=0.00001;
				if gwr=	"global" then par=1/a;		
			end;
			/* computing alpha=1/par, where par=theta */
			do while (abs(dpar)>0.001);
				aux1=aux1+1;
				if gwr="local" then do;
					par=choose(par<1E-10,1E-10,par);
        			g=sum((digamma(par+y)-digamma(par)+log(par)+1-log(par+uj)-(par+y)/(par+uj))#w[,1]);
        			hess=sum((trigamma(par+y)-trigamma(par)+1/par-2/(par+uj)+(y+par)/((par+uj)#(par+uj)))#w[,1]);
				end;
				hess=choose(abs(hess)<1E-23,sign(hess)*1E-23,hess);
				hess=choose(hess=0,1E-23,hess);
        		par0=par;
        		par=par0-inv(hess)*g;
				if par<=0 then do;
					count=count+1;
					if count<10 then par=0.000001;
					else par=abs(par);
				end;
				if aux1>50 & par>1E5 then do;
					dpar= 0.0001;
					aux2=aux2+1;
					if aux2=1 then par=2 ;	
					else if aux2=2 then par=1E5;
					else if aux2=3 then par=0.0001; 
				end;
				else do;
					dpar=par-par0;
					if par<1E-3 then dpar=dpar*100;
				end;
			end;
			if gwr=	"poisson" then alpha=0;		
			else alpha=1/par;
			dev=0; ddev=1; cont=0;
			/* computing beta */
			do while (abs(ddev)>0.000001);
				cont=cont+1;
				uj=choose(uj>1E100,1E100,uj);
				aux= (alpha*uj/(1+2*alpha*uj+alpha*alpha*uj#uj));
        		Ai=(uj/(1+alpha*uj))+(y-uj)#aux;
				Ai=choose(Ai<=0,1E-5,Ai);	
        		zj=nj+(y-uj)/(Ai#(1+alpha*uj)) - offset;
				if det(x`*(wi#Ai#x))=0 then bi=j(ncol(x),1,0);
				else bi=inv(x`*(wi#Ai#x))*x`*(wi#Ai#zj); 
        		nj=x*bi + offset;
				nj=choose(nj>1E2,1E2,nj);
        		uj=exp(nj);
        		olddev=dev;
				uj=choose(uj<1E-150,1E-150,uj);
				tt=y/uj;
				tt=choose(tt=0,1E-10,tt);
				if gwr=	"poisson" then dev=2*sum(y#log(tt)-(y-uj));
				else dev=2*sum(y#log(tt)-(y+1/alpha)#log((1+alpha*y)/(1+alpha*uj)));
				if cont>100 then ddev= 0.0000001;
        		else ddev=dev-olddev;
			end;
			jj=jj+1;
			if gwr="global" | gwr="poisson" | aux2>4 | jj>50 | ddpar=0.0000001 then ddpar=1E-9; 
			else do;
				ddpar=par-parold;
				if par<1E-3 then ddpar=ddpar*100;
			end;
		end;
		Ai2=(uj/(1+alpha*uj))+(y-uj)#(alpha*uj/(1+2*alpha*uj+alpha*alpha*uj#uj));
		if Ai2[><,]<1E-5 then Ai2=choose(Ai2<1E-5,1E-5,Ai2);
		Ai=Ai2;
		if det(x`*(wi#Ai#x))=0 then S[i,]=j(1,n,0);
		else S[i,]= x[i,]*inv(x`*(wi#Ai#x))*(x#wi#Ai)`;
		yhat[i]=uj[i];
		alphaii[i,1]=i;
		alphaii[i,2]= alpha;
	end;
	alpha= alphaii[,2];
	yhat=choose(yhat<1E-150,1E-150,yhat);
	tt=y/yhat;
	tt=choose(tt=0,1E-10,tt);
	if gwr=	"poisson" then dev=2*sum(y#log(tt)-(y-yhat));
	else dev=2*sum(y#log(tt)-(y+1/alpha)#log((1+alpha#y)/(1+alpha#yhat)));
	if gwr ^=	"poisson" then do;
	a2=y+1/alpha; b2=1/alpha; c2=y+1;
	end;
	else do;
	a2=y; b2=1/(alpha+1e-8); c2=y+1;
	a2=choose(a2=0,1E-10,a2);
	end;
	algamma=j(n,1,0); blgamma=j(n,1,0); clgamma=j(n,1,0);
	do i=1 to nrow(y);
		algamma[i]=lgamma(a2[i]); blgamma[i]=lgamma(b2[i]); clgamma[i]=lgamma(c2[i]);
	end;
	if gwr^="poisson" then do;
		ll=sum(y#log(alpha#yhat)-(y+1/alpha)#log(1+alpha#yhat)+ algamma - blgamma - clgamma );
		npar=trace(S)+1;
	end;
	else do;
		ll=sum(-yhat+y#log(yhat)-clgamma);
		npar=trace(S);
	end;
	/*AIC= 2*npar + dev;*/
	AIC= 2*npar -2*ll;
	AICC= AIC +(2*npar*(npar+1))/(n-npar-1);
	CV=(y-yhat)`*(y-yhat);
	res=cv||aicc||npar||dev;
	return (res);
finish;

if type="cv" then do;
	pos=1;
	create &out var{h1 res1 h2 res2};
end;
else do;
	if type="aic" then pos=2;
	else pos=4;
	create &out var{h1 res1 npar1 h2 res2 npar2};
end;
res1=cv(h1); npar1=res1[3]; res1=res1[pos];
res2=cv(h2); npar2=res2[3]; res2=res2[pos];
append;
do while(abs(h3-h0) > tol*2);
    if res2<res1 then do;
        h0=h1; 
		h1=h2;
        h2=c*h1+r*h3;
        res1=res2;
		npar1=npar2;
		res2=cv(h2);
		npar2=res2[3];
		res2=res2[pos];
    end;
    else do;
        h3=h2;
        h2=h1;
        h1=c*h2+r*h0;
        res2=res1; 
		npar2=npar1;
		res1=cv(h1);
		npar1=res1[3];
		res1=res1[pos];
    end;
	append;
end;
if method= "adaptive1" then do;
	xmin = (h3+h0)/2;
	h2=ceil(xmin);
	h1=floor(xmin);
	golden1 = cv(h1);
	g1= golden1[pos];
	golden2= cv(h2);
	g2= golden2[pos];
	npar1=golden1[3];
	res1=golden1[pos];
	npar2=golden2[3];
	res2=golden2[pos];
	append;
	if g1<g2 then do;
		xmin=h1;
		npar=golden1[3];
		golden=g1;
	end;
	else do;
		xmin=h2;
		npar=golden2[3];
		golden=g2;
	end;
end;
else do;
	xmin = (h3+h0)/2;
	golden = cv(xmin);
	npar=golden[3];
	golden=golden[pos];
end;
h1 = xmin;
res1 = golden;
npar1=npar;
h2 = .;
res2 = .;
npar2=.;
append;
if type="cv" then print golden xmin;
else print golden xmin npar;
quit;
%mend golden;



/*************************************************************/
/************************* GWNBR  ****************************/
/*************************************************************/

%macro gwnbr(data=,y=,x=,lat=,long=,h=,grid=,latg=,longg=,gwr=,method=,alphag=,offset=,geocod=,out=);
proc iml;
use &data;
	read all var {&y} into y;
	read all var {&x} into x;
	read all var{&long &lat} into COORD;   
	n=nrow(y);
	%if &offset= %then %do; offset=j(n,1,0); %end;
	%else %do; read all var {&offset} into offset; %end;
	%if &grid= %then %do;
		read all var{&long &lat} into POINTS;     
		read all var{&geocod} into geocod_; 
	%end;
close &data;
%if &grid^= %then %do;
	use &grid;                                                                                                                              
	read all var{&longg &latg} into POINTS;     
	close &grid;
	geocod_=nrow(points,1,0);
%end;
x=j(n,1,1)||x;
yhat=j(n,1,0);
h=&h;
gwr="&gwr"; *global,local, poisson;
method="&method"; *fixed, adaptive1, adaptiven;
m=nrow(POINTS);
bii=j(ncol(x)*m,2,0); alphaii= j(m,2,0);
xcoord=j(ncol(x)*m,1,0); ycoord=j(ncol(x)*m,1,0);
&geocod= j(ncol(x)*m,1,0);
sebi=j(ncol(x)*m,1,0); sealphai= j(m,1,0);
S=j(n,n,0);
yp=y-sum(y)/n;
probai=j(m,1,0); probbi=j(m,1,0);
yhat=j(m,1,0); 
res= j(m,1,0);
if gwr^="poisson" then do;
	ym=sum(y)/nrow(y);
	u=(y+ym)/2;
	n=log(u);
	par=1; ddpar=1; j=0; aux2=0;
	do while (abs(ddpar)>0.00001);
		aux1=0;
		dpar=1;
		parold=par;
		do while (abs(dpar)>0.001);
			aux1=aux1+1;
			if par<0 then par=0.00001;
			par=choose(par<1E-10,1E-10,par);
	        g=sum(digamma(par+y)-digamma(par)+log(par)+1-log(par+u)-(par+y)/(par+u));
	        hess=sum(trigamma(par+y)-trigamma(par)+1/par-2/(par+u)+(y+par)/((par+u)#(par+u)));
			hess=choose(abs(hess)<1E-23,sign(hess)*1E-23,hess); *CONFERIR!!!;
			hess=choose(hess=0,1E-23,hess);
	        par0=par;
	        par=par0-inv(hess)*g;
			if aux1>50 & par>1E5 then do;
				dpar= 0.0001;
				aux2=aux2+1;
				if aux2=1 then par=2 ;	
				else if aux2=2 then par=1E5;
				else if aux2=3 then par=0.0001; 
			end;
			else dpar=par-par0;
		end;
		a=1/par; dev=0; ddev=1; i=0;
		do while (abs(ddev)>0.00001);
			i=i+1;
	        w=(u/(1+a*u))+(y-u)#(a*u/(1+2*a*u+a*a*u#u));
			w=choose(w<=0,1E-5,w);
			z=n+(y-u)/(w#(1+a*u)) - offset;
	        b=inv((x#w)`*x)*(x#w)`*z;
	        n=x*b + offset;
			n=choose(n>1E2,1E2,n);
	        u=exp(n);
	        olddev=dev;
			tt=y/u;
			tt=choose(tt=0,1E-10,tt);
	        dev=2*sum(y#log(tt)-(y+1/a)#log((1+a*y)/(1+a*u)));
	        ddev=dev-olddev;
		end;
		if aux2>4 then ddpar=1E-9; 
		else ddpar=par-parold;
	end;
	%if &alphag= %then %do; alphag=a;%end;
	%else %if &alphag=0 %then %do; alphag=1e-8;%end;
	%else %do; alphag=&alphag;%end;
	bg=b;
	parg=par;
end;
if gwr="global" then print alphag aux2;
n=nrow(y);
aux2=0;
do i=1 to m;
	d=j(1,3,0);
	do j=1 to n; 
		if abs(COORD[,1])<180 then do;
        	dif=abs(POINTS[i,1]-COORD[j,1]);
        	raio=arcos(-1)/180;
			ang=sin(POINTS[i,2]*raio)*sin(COORD[j,2]*raio)+cos(POINTS[i,2]*raio)*cos(COORD[j,2]*raio)*cos(dif*raio);
			if round(ang,0.000000001)=1 then arco=0;
        	else arco=arcos(ang);
        	d1=arco*6371 /*Earth's Radius = 6371 (approximately)*/;
        end;
        else d1=sqrt((POINTS[i,1]-COORD[j,1])**2+(POINTS[i,2]-COORD[j,2])**2); 
		d[1]=i; d[2]=j; d[3]=d1;
		if j=1 then dist=d;	*cleaning dist where i value changes;
		else dist=dist//d;
	end;
	w=j(n,1,0);	 
	if method= "fixed" then do;
        do jj=1 to n;
			w[jj]=exp(-0.5*(dist[jj,3]/h)**2);
        end;
	end;
	else if method= "adaptiven" then do;
        do jj=1 to n;
			if dist[jj,3]<=h then w[jj]=(1-(dist[jj,3]/h)**2)**2;
			else w[jj]=	0;
        end;
	end;
	else if method= "adaptive1" then do;
		w=j(n,2,0);
		call sort(dist,{3});
		dist=dist||(1:n)`;
		hn=dist[h,3]; *bandwith for the point i;
		do jj=1 to n;
	 		if dist[jj,4]<=h then w[jj,1]=(1-(dist[jj,3]/hn)**2)**2;
			else w[jj,1]=0;
			w[jj,2]=dist[jj,2];
		end;
		call sort(w,{2});
	end;
	wi=w[,1];
	ym=sum(y)/nrow(y);
	uj=(y+ym)/2;
	nj=log(uj);
	ddpar=1; jj=0; count=0; aux2=0;
	if i=1 | aux2=5 | count=4 then par=1; else par=alphaii[i-1,2]; 
	do while (abs(ddpar)>0.000001);
		dpar=1;
		if ddpar=1 then parold=1.8139;
		else parold=par;
		aux1=0;
		if gwr="global" | gwr="poisson" then do;
			dpar=0.00001;
			if gwr=	"global" then par=1/alphag;	
		end;
		/* computing alpha=1/par, where par=theta=r */
		do while (abs(dpar)>0.001);
			aux1=aux1+1;
			if gwr="local" then do;
				par=choose(par<1E-10,1E-10,par);
        		g=sum((digamma(par+y)-digamma(par)+log(par)+1-log(par+uj)-(par+y)/(par+uj))#w[,1]);
        		hess=sum((trigamma(par+y)-trigamma(par)+1/par-2/(par+uj)+(y+par)/((par+uj)#(par+uj)))#w[,1]);
			end;
        	par0=par;
			hess=choose(abs(hess)<1E-23,sign(hess)*1E-23,hess);
			hess=choose(hess=0,1E-23,hess);
        	par=par0-inv(hess)*g;
			if par<=0 then do; 
				count=count+1;
				if count=1 then par=0.000001;
				else if count=2 then par=0.0001;
				else par=1/alphag;
			end;
			if aux1>100 & par>1E5 then do; *MAXINTA;
				dpar= 0.0001;
				if aux2=0 then par=1/alphag + 0.0011;
				if aux2=1 then par=2 ;	
				else if aux2=2 then par=1E5;
				else if aux2=3 then par=0.0001; 
				aux2=aux2+1;
			end;
			else do;
				dpar=par-par0;
				if par<1E-3 then dpar=dpar*100;
			end;
		end;
		if gwr=	"poisson" then alpha=0;		
		else alpha=1/par;
		dev=0; ddev=1; cont=0;
		/* computing beta */
		do while (abs(ddev)>0.000001);
			cont=cont+1;
        	Ai=(uj/(1+alpha*uj))+(y-uj)#(alpha*uj/(1+2*alpha*uj+alpha*alpha*uj#uj));
			Ai=choose(Ai<=0,1E-5,Ai);
        	zj=nj+(y-uj)/(Ai#(1+alpha*uj))-offset;
			if det(x`*(wi#Ai#x))=0 then bi=j(ncol(x),1,0);
			else bi=inv(x`*(wi#Ai#x))*x`*(wi#Ai#zj); 
        	nj=x*bi + offset;
			nj=choose(nj>1E2,1E2,nj);
        	uj=exp(nj);
        	olddev=dev;
			uj=choose(uj<1E-150,1E-150,uj);
			tt=y/uj;
			tt=choose(tt=0,1E-10,tt);
			if gwr=	"poisson" then dev=2*sum(y#log(tt)-(y-uj));
			else dev=2*sum(y#log(tt)-(y+1/alpha)#log((1+alpha*y)/(1+alpha*uj)));
			if cont>100 then ddev= 0.0000001; *MAXINTB;
        	else ddev=dev-olddev;
		end;
		jj=jj+1;
		*print jj bi;
		if gwr="global" | gwr="poisson" | aux2>4 | count>3 | jj>200 then ddpar=1E-9; 
		else do;
			ddpar=par-parold;
			if par<1E-3 then ddpar=ddpar*100;
		end;
    /* print j aux1 cont aux2 count parold par ddpar;*/
	end;
	if aux2>4 then probai[i]=1;
	if count>3 then probai[i]=2;
    Ai2=(uj/(1+alpha*uj))+(y-uj)#(alpha*uj/(1+2*alpha*uj+alpha*alpha*uj#uj));
	if Ai2[><,]<1E-5 then do;
		probbi[i]=1;
		Ai2=choose(Ai2<1E-5,1E-5,Ai2);
	end;
	Ai=Ai2;
	%if &grid= | &grid=&data %then %do;
		if det(x`*(wi#Ai#x))=0 then S[i,]=j(1,n,0);
		else S[i,]= x[i,]*inv(x`*(wi#Ai#x))*(x#wi#Ai)`;
	%end;
	C=inv(x`*(wi#Ai#x));
	varb= C;
	seb=sqrt(vecdiag(varb));
	if gwr^="poisson" then do;
		ser=sqrt(1/abs(hess)); 
		r=1/alpha;
		sealpha=ser/(r**2); 
		sealphai[i,1]=sealpha;
		alphaii[i,1]=i;
		alphaii[i,2]= alpha;
	end;
	m1=(i-1)*ncol(x)+1;
	m2=m1+(ncol(x)-1);
	sebi[m1:m2,1]=seb;
	bii[m1:m2,1]=i;
	bii[m1:m2,2]=bi;
	xcoord[m1:m2,1]= POINTS[i,1];
	ycoord[m1:m2,1]= POINTS[i,2];
	&geocod[m1:m2,1]= geocod_[i,1];
	%if &grid= | &grid=&data %then %do;
		yhat[i]=uj[i];
	%end;
end;
tstat= bii[,2]/sebi;
probtstat=2*(1-probnorm(abs(tstat)));
if gwr^="poisson" then do;
	atstat= alphaii[,2]/sealphai;
	aprobtstat=2*(1-probnorm(abs(atstat)));	*check for normality;
end;
else do;
	atstat=j(n,1,0);
	aprobtstat=j(n,1,1);
end;
b=bii[,2];
alphai=alphaii[,2];
_id_=	bii[,1];
_ida_=alphaii[,1];

_beta_=shape(bii[,1:2],n);
i=do(2,ncol(_beta_),2);
_beta_=_beta_[,i];
call qntl(qntl,_beta_);
qntl=qntl//(qntl[3,]-qntl[1,]);
descriptb=_beta_[:,]//_beta_[><,]//_beta_[<>,];

print qntl[label="Quantiles of GWNBR Parameter Estimates" 
rowname={"P25", "P50", "P75", "IQR"} colname={'Intercept' &x}],,
descriptb[label="Descriptive Statistics" rowname={"Mean", "Min", "Max"} 
colname={'Intercept' &x}];

_stdbeta_=shape(sebi,n);
call qntl(qntls,_stdbeta_);
qntls=qntls//(qntls[3,]-qntls[1,]);
descripts=_stdbeta_[:,]//_stdbeta_[><,]//_stdbeta_[<>,];

print qntls[label="Quantiles of GWNBR Standard Errors" 
rowname={"P25", "P50", "P75", "IQR"} colname={'Intercept' &x}],,
descripts[label="Descriptive Statistics of Standard Errors" rowname={"Mean", "Min", "Max"} 
colname={'Intercept' &x}];

%if &grid= | &grid=&data %then %do;
	yhat=choose(yhat<1E-150,1E-150,yhat);
	tt=y/yhat;
	tt=choose(tt=0,1E-10,tt);
	if gwr=	"poisson" then do;
		dev=2*sum(y#log(tt)-(y-yhat));
		tt2=y/y[:];tt2=choose(tt=0,1E-10,tt);
		devnull=2*sum(y#log(tt2)-(y-y[:]));
		pctdev=1-dev/devnull;
	end;
	else do;
		dev=2*sum(y#log(tt)-(y+1/alphai)#log((1+alphai#y)/(1+alphai#yhat)));
		tt=y/y[:];tt=choose(tt=0,1E-10,tt);
		devnull=2*sum(y#log(tt)-(y+1/alphai)#log((1+alphai#y)/(1+alphai#y[:])));
		pctdev=1-dev/devnull;
	end;
	if gwr^="poisson" then do;
		a2=y+1/alphai; b2=1/alphai;
		algamma=j(n,1,0); blgamma=j(n,1,0);
		do i=1 to nrow(y);
			algamma[i]=lgamma(a2[i]);
			blgamma[i]=lgamma(b2[i]);
		end;
	end;
	c2=y+1;
	clgamma=j(n,1,0);
	do i=1 to nrow(y);
		clgamma[i]=lgamma(c2[i]);
	end;
	if gwr^="poisson" then do;
		ll=sum(y#log(alphai#yhat)-(y+1/alphai)#log(1+alphai#yhat)+ algamma - blgamma - clgamma );
		if gwr="global" & alphai^=1/parg then npar=trace(S);
		else npar=trace(S)+1;
		tt=y/(alphai#yhat);tt=choose(tt=0,1E-10,tt);
		ll1=sum(y#log(tt)-y+(y+1/alphai)#log(1+alphai#yhat)-algamma+blgamma);
		tt=y/y[:];tt=choose(tt=0,1E-10,tt);
		llnull=sum(y#log(tt));
		pctll=1-ll1/llnull;
	end;
	else do;
		ll=sum(-yhat+y#log(yhat)-clgamma);
		npar=trace(S);
		pctll=pctdev;
	end;
	adjpctdev=1-((nrow(y)-1)/(nrow(y)-npar))*(1-pctdev);
	adjpctll=1-((nrow(y)-1)/(nrow(y)-npar))*(1-pctll);
	resord=y-yhat;
	sigma2=	(resord`*resord)/(n-npar);
	sii=vecdiag(S);
	res=resord/sqrt(sigma2#(1-sii));
	res=unique(_id_)`||COORD[,1]||COORD[,2]||y||yhat||res||resord;
	/*AIC= 2*npar + dev;*/
	AIC= 2*npar - 2*ll;
	AICC= AIC +(2*npar*(npar+1))/(n-npar-1);
	BIC= npar*log(n) - 2*ll ;
	_malpha_=0.05*(ncol(x)/npar);
	_t_critical_=abs(tinv(_malpha_/2,n-npar));

	print _malpha_[label="alpha-level=0.05"] _t_critical_[format=comma6.2 label="t-Critical"] npar;
	print gwr method ll dev pctdev adjpctdev pctll adjpctll npar aic aicc bic;
	create _res_ from res[colname={"_id_" "xcoord" "ycoord" "yobs" "yhat" "res" "resraw"}];
	append from res;
	stat=ll|| dev|| pctdev || adjpctdev|| pctll || adjpctll || npar|| aic|| aicc|| bic;
	create _stat_ from stat[colname={"l1" "dev" "pctdev" "adjpctdev" "pctll" "adjpctll" "npar" "aic" "aicc" "bic"}];
	append from stat;
%end;
%else %do; print gwr method; %end;

create _beta_ var{_id_ &geocod xcoord ycoord b sebi tstat probtstat}; * _beta_ has beta vector for each point i;
append;
xcoord=COORD[,1];ycoord=COORD[,2];
&geocod=unique(&geocod)`;
sig_alpha=j(n,1,"not significant at 90%");
v1=npar;
do i=1 to n;
if aprobtstat[i]<0.01*(ncol(x)/v1) then sig_alpha[i]="significant at 95%";
else if aprobtstat[i]<0.1*(ncol(x)/v1) then sig_alpha[i]="significant at 90%";
else sig_alpha[i]="not significant at 90%";
end;
create _alpha_ var{_ida_ &geocod xcoord ycoord alphai sealphai atstat aprobtstat sig_alpha probai probbi}; * _alpha_ has alpha vector for each point i;
append;
_tstat_=_beta_/_stdbeta_;
_probt_=2*(1-probnorm(abs(_tstat_)));
_bistdt_=geocod_||COORD||_beta_||_stdbeta_||_tstat_||_probt_;
_colname1_={"Intercept" &x};
_label_=repeat("std_",ncol(x))//repeat("tstat_",ncol(x))//repeat("probt_",ncol(x));
_colname_={"&geocod" "x" "y"}||_colname1_||concat(_label_,repeat(_colname1_`,3))`;
call change(_colname_, "_ ", "_");
call change(_colname_, "_ ", "_");
create _parameters_ from _bistdt_[colname=_colname_];
append from _bistdt_;
close _parameters_;

_sig_=j(n,ncol(x),"not significant at 90%");
v1=npar;
do i=1 to n;
do j=1 to ncol(x);
if _probt_[i,j]<0.01*(ncol(x)/v1) then _sig_[i,j]="significant at 99%";
else if _probt_[i,j]<0.05*(ncol(x)/v1) then _sig_[i,j]="significant at 95%";
else if _probt_[i,j]<0.1*(ncol(x)/v1) then _sig_[i,j]="significant at 90%";
else _sig_[i,j]="not significant at 90%";
end;
end;
_colname1_={"Intercept" &x};
_label_=repeat("sig_",ncol(x));
_colname_=concat(_label_,repeat(_colname1_`,1))`;
create _sig_parameters2_ from _sig_[colname=_colname_];
append from _sig_;
/*
%let nvar=0;
%do %while(%scan(%str(&x),&nvar+1)~=);
    %let nvar=%eval(&nvar+1);
%end;
use _beta_;
	read all into b;
close _beta_;
n=nrow(b);
npar=&nvar+1;
%do i=0 %to &nvar;
	b&i=j(1,8,0);
	nome={"_id_" "&geocod" "xcoord" "ycoord" "b" "sebi" "tstat" "probtstat"};
	create &out._b&i from b&i[colname=nome];
	do i=1 to (n/npar);
		b&i[1,]=b[(i-1)*npar+&i+1,];
		append from b&i; 
	end;
%end;
*/
quit;
%mend gwnbr;


