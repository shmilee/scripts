#include <stdio.h>
#include <math.h>
int main()
{
        int a,b,k;
        while(1)
        {
                scanf("%d %d %d",&a,&b,&k);
                if((a==0)&&(b==0))
                {
                        return 0;
                }
                k=pow(10,k);
                if((a%k)==(b%k))
                {
                        printf("-1\n");
                }
                else
                {
                        printf("%d\n",a+b);
                }
        }
        return 0;
}
