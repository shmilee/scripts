#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Python3 Program to check whether the given number
# is Lychrel Number or not with given limit on number of iterations.
# This code is contributed by mits.
# ref https://www.geeksforgeeks.org/lychrel-number-implementation/

# Max Iterations
MAX_ITERATIONS = 200

# Function to check whether number is Lychrel Number
def isLychrel(number):
    if (isPalindrome(number)):
        return "No"
    for i in range(1, MAX_ITERATIONS+1):
        rev = reverse(number)
        new = number + rev
        print(f'{i}): {number} + {rev} = {new}')
        if (isPalindrome(new)):
            return "No"
        number = new
    return "Maybe"

# Function to check whether the number is Palindrome
def isPalindrome(number):
    return number == reverse(number)

# Function to reverse the number
reverse_cache = {}
def reverse(number):
    if number in reverse_cache:
        #  print(f'using cache for {number}')
        return reverse_cache[number]
    reverse = 0
    num = number
    while (num > 0):
        remainder = num % 10
        reverse = (reverse * 10) + remainder
        num = int(num / 10)
    reverse_cache[number] = reverse
    reverse_cache[reverse] = number
    return reverse

if __name__ == '__main__':
    import sys
    if len(sys.argv) >= 3:
        n1, n2 = int(sys.argv[1]), int(sys.argv[2])
        for number in range(n1, n2+1):
            print('\n'+'='*16)
            ans = isLychrel(number)
            print(f"==> {number} is lychrel? {ans}")
    elif len(sys.argv) >= 2:
        number = int(sys.argv[1])
        ans = isLychrel(number)
        print(f"==> {number} is lychrel? {ans}")
    else:
        ans =  isLychrel(196)
        print(f"==> 196 is lychrel? {ans}")
