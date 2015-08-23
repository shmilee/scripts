close all;clear all; clc;

x=-8:0.05:3;

A=-2*ones(1,length(x));
B=ones(1,length(x)-1);
D=diag(A)+diag(B,1)+diag(B,-1);
V=diag(x.*x-5*cos(x)+5*x);
H=V-2*D;
[PHI,E]=eig(H);

plot(x,diag(V),'b','LineWidth',2);
hold on;
plot(x,PHI(:,1)'+1*0.4+E(1,1),'r','LineWidth',2)
for i=2:1:10
    plot(x,PHI(:,i)'+i*0.4+E(i,i),'r','LineWidth',2)
end
for i=[35,36]
    plot(x,PHI(:,i)'+E(i,i),'g','LineWidth',2)
end
for i=[45,50,55,60,65]
    plot(x,PHI(:,i)'+E(i,i),'k','LineWidth',2)
end
xlim([-6,2]);
ylim([-8,3]);
filename=['v-x2_5cosx-',datestr(now,30),'.png'];
print(gcf,'-dpng',filename);
