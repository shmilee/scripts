#include <stdio.h>
#include <math.h>
#include <inttypes.h>
#include <complex.h>
#include <string.h>
#define HI "Hello world!"

int main(void) {
    //开始
    printf("Hello ");
    printf("World!\n");
    printf("----------------------\n");

    //整数
    short int i=pow(2,8*sizeof(short)-1)-1;
    int j=pow(2,8*sizeof(int)-1)-1;
    long k=pow(2,8*sizeof(long)-1)-1;
    long long kk=pow(2,8*sizeof(long long)-1)-1;
    int8_t i8=pow(2,8*sizeof(int8_t)-1)-1;
    intmax_t im=pow(2,8*sizeof(intmax_t)-1)-1;
    printf("int DT\t\tSize\tMax\t\t\tMin\n");
    printf("short\t\t%u\t%hd\t\t\t%d\n",sizeof(i),i,i+1);
    printf("int\t\t%u\t%d\t\t%d\n",sizeof(j),j,j+1);
    printf("long\t\t%u\t%ld\t%ld\n",sizeof(k),k,k+1);
    printf("long long\t%u\t%lld\t%lld\n",sizeof(kk),kk,kk+1);
    printf("int8_t\t\t%u\t%"PRId8"\t\t\t%"PRId8"\n",sizeof(i8),i8,-i8-1);
    printf("intmax_t\t%u\t%lld\t%lld\n",sizeof(im),im,im+1);
    printf("----------------------\n");

    /*字符*/
    char c='ABCDE';
    j='ABCDE';
    printf("Set c='ABCDE', then c='%c'\nsizeof('ABCDE')=%d, sizeof(c)=%d\ncode of 'ABCDE' is %d, code of c is %d\n",c,sizeof('ABCDE'),sizeof(c),j,c);
    printf("explain the code of 'ABCDE':\n");
    printf("1)%d != %d + %d*2^%d + %d*2^%d + %d*2^%d + %d*2^%d\n",j,'E','D',8*sizeof(c),'C',2*8*sizeof(c),'B',3*8*sizeof(c),'A',4*8*sizeof(c));
    printf("2)%d == %d + %d*2^%d + %d*2^%d + %d*2^%d\n",j,'E','D',8*sizeof(c),'C',2*8*sizeof(c),'B',3*8*sizeof(c));
    printf("----------------------\n");

    //浮点数
    float f=M_PI;
    long double lf=M_PI;
    printf("size of float is %d\nsize of 3.14 is %d\nsize of 3.14f is %d\nsize of 3.14L is %d\n",sizeof(f),sizeof(3.14),sizeof(3.14f),sizeof(3.14L));
    printf("Set pi=%.22lf, then\n",M_PI);
    printf("float pi is %.22f = %.22e = %.22a\n",f,f,f);
    printf("long double pi is %.22Lf\n",lf);
    f=2.0e20;
    float ff=2.0e20 + 1.0;
    printf("overflow: 2.0e20 + 1.0 - 2.0e20 = %f\n",ff-f);
    printf("----------------------\n");
    
    //复数 
    float _Complex Z=3.145+315*I;
    printf("size of _Complex %f+%fi is %d\n",creal(Z),cimag(Z),sizeof(Z));
    printf("----------------------\n");

    //字符串
    printf("%s\n",HI);
    char str[20];
    return 0;
}
