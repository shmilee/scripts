#include <iostream>

int main() {
    char c;
    std::cout << "Mission One : Compare 2 numbers ? (y/n)" << std::endl;
    std::cin >> c;
    while(c == 'y' || c == 'Y') {
        std::cout << "Enter a number: " << std::endl;
        double n;
        std::cin >> n;
        std::cout << "Your first number is " << n << "." << std::endl;
        std::cout << "Enter another number: " << std::endl;
        double m;
        std::cin >> m;
        std::cout << "Your second number is " << m << "." << std::endl;
        std::cout << "Set n= " << n << ", m= " << m << ". So" << std::endl;
        if (n>m) {
            std::cout << "n>m." << std::endl;
        } else if (n<m) {
            std::cout << "n<m." << std::endl;
        } else {
            std::cout << "n=m." << std::endl;
        }
        c='N';
        std::cout << "Continue comparing ? (y/n)" << std::endl;
        std::cin >> c;
    }

    std::cout << "Mission Two : Sort numbers ? (y/n)" << std::endl;
    std::cin >> c;
    while(c == 'y' || c == 'Y') {
        std::cout << "Enter less than 100 numbers one by one and end with 'E'.\nFor example, 2 3 56 4.6 78 E  " << std::endl;
        double arr[100];
        std::cout << arr << std::endl;

        c='N';
    }

    return 0;
}
