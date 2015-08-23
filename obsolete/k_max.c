#include <stdio.h>
int main(){

    int N,K,i,j,len;
    int a[1000];
    scanf("%d %d",&N,&K);
    while(N!=0){
        for(i=0;i<N;i++)
            scanf("%d",&a[i]);
        //K组，长len,每组找出最大值，放到每组第一个位置
        len=N/K;
        for(i=0;i<N;i+=len){
            //a[i]~a[i+len-1]个，求最大值
            for(j=i+1;j<i+len;j++){
                if(a[i]<=a[j]){
                    a[i]=a[j];
                }
            }
        }
        for(i=len;i<N;i+=len){
            if(a[0]>a[i]) a[0]=a[i];
        }
        printf("%d",a[0]);
    }
    return 0;
}
