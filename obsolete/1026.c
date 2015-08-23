#include <stdio.h>
/*题库[1026] 输入两个不超过整型定义的非负10进制整数A和B(<=2^31-1)，输出A+B的m (1 < m <10)进制数。*/
int main()
{
        unsigned int a,b,m,sum;
        while(1)
        {
                short stack[34] = {0},top = 0;
                scanf("%d",&m);
                if(m == 0)
                        break;
                scanf("%d%d",&a,&b);
                sum = a + b;
                if(sum == 0)
                {
                        stack[top++] = 0;
                }
                while(sum != 0)
                {
                        stack[top++] = sum%m;
                        sum /= m;
                }
                for(int i = top-1;i >= 0;i--)
                        printf("%d",stack[i]);
                printf("\n");
        }
}
