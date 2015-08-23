close all;clear all; clc;

x=-5:0.1:5;

A=-2*ones(1,length(x));
B=ones(1,length(x)-1);
D=diag(A)+diag(B,1)+diag(B,-1);
V=diag(x.*x);
H=V-2*D;
[PHI,E]=eig(H);

plot(x,diag(V),'LineWidth',2);
hold on;
plot(x,PHI(:,1)'+10*E(1,1),'r','LineWidth',2)
for i=2:1:7
    plot(x,(-1)^i*PHI(:,i)'+10*E(i,i),'r','LineWidth',2)
end
xlabel('x[a.u.]');
ylabel('E[a.u.]');
filename=['v-x2-',datestr(now,30),'.png'];
print(gcf,'-dpng',filename);
