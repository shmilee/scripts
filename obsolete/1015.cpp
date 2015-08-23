#include<iostream>
#include<string.h>
#include<math.h>
using namespace std;
 
bool is_Prime(int a){
    int i;
    if(a==0 || a==1) return false;
    for(i=2; i <= sqrt((double)a); i++){
        if( a%i == 0) return false;
    }
 
    return true;
}
 
int change(int n,int d){
    int total = 0;
    while(n != 0){
        total = total*d + n%d;
        n/=d;
    }
    return total;
}
 
int main()
{
    int N,D;
    while(cin>>N){
        if( N<0 ) break;
        cin>>D;
        cout<<"R:"<<change(N,D)<<endl;
        if( is_Prime(N) && is_Prime( change(N,D) )){
            cout<<"Yes"<<endl;    
        }
        else{
            cout<<"No"<<endl;
        }
    }
    return 0;
}
