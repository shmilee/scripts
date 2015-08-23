#include <stdio.h>

int main(){
    short m=2;
    int n;
    scanf("%d",&n);
    short stack[34]={0},top=0;
    if(n==0){
        stack[top++]=0;
    }
    while(n!=0){
        stack[top++]=n%m;
        n=n/m;
    }
    while(top!=0){
        top-=1;
        printf("%d",stack[top]);
    }
    return 0;
}
