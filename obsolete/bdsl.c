/*读完这个题，我的第一感觉是：这是个dp问题。如果用普通方法做，时间复杂度是O(n^2),会超时。
  后来想了一下，只需要判断是递增或递减就行了，O(n)时间复杂度。
  即：对于当前的点，1、如果要找递增序列：如果下一个点比当前的点大，序列长度加1，更新下一个点为当前点；
                如果下一个点比当前点小，长度不变，同样更新下一个点为当前点，而且有利于找出递增序列
                找递减序列的方法与找递增序列的方法一致。*/
#include<stdio.h>
int a[30003];
int main()
{
    int T,N,i,flag,len,now;
    scanf("%d",&T);
    while(T--)
    {
        scanf("%d",&N);
        for(i=0;i<N;i++)
            scanf("%d",&a[i]);
        now=a[0];
        flag=1;/*flag=0表示要找递增序列，flag=1表示要找递减序列*/
        len=1;
        for(i=1;i<N;i++)
        {
            if(!flag&&a[i]>now)
            {
                flag=1;
                len++;
            }
            else if(flag&&a[i]<now)
            {
                flag=0;
                len++;
            }
            now=a[i];
        }
        printf("%d\n",len);
    }
    return 0;
}
