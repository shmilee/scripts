#include <stdio.h>
#include <math.h>

int main(){
    int N,i,j,step=1,is=1;
    printf("Input N: ");
    scanf("%d",&N);

    printf("2\n3\n");
    step=2;
    for (i=5;i<=N;i+=step) {
        for (j=3;j<=sqrt(i);j+=step) {
            if (i%j==0){
                is=0;
                break;
            }
        }
        if (is){
            printf("%d\n",i);
        }
        is=1;
    }
    return 0;
}
