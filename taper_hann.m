n=100;
r=randn(n,1);
hannwin=.5*(1-cos(2*pi*(0:n-1)/(n-1)));
plot(r),hold on
figure(2)
plot(r.*hannwin,'r')