#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Python3 Program to check whether the given number
# is Lychrel Number or not with given limit on number of iterations.
# This code is contributed by mits.
# ref https://www.geeksforgeeks.org/lychrel-number-implementation/

# Max Iterations
MAX_ITERATIONS = 1000

# Function to check whether number is Lychrel Number
def isLychrel(number):
    if (isPalindrome(number)):
        return "No"
    for i in range(1, MAX_ITERATIONS+1):
        rev = reverse(number)
        new = number + rev
        print(f'i={i}): {number} + {rev} = {new}')
        #print(f'i={i}')
        if (isPalindrome(new)):
            return "No"
        number = new
    return "Maybe"

# Function to check whether the number is Palindrome
def isPalindrome(number):
    return number == reverse(number)

# %timeit !python ./lychrel.py 196677 # Iterations=10000
# 43s vs 84s => 48.8%
cache_on, reverse_cache = True, {}

# Function to reverse the number
def reverse(number):
    if cache_on:
        if number in reverse_cache:
            #  print(f'using cache for {number}')
            return reverse_cache[number]
    reverse = 0
    num = number
    while (num > 0):
        remainder = num % 10
        reverse = (reverse * 10) + remainder
        num = num // 10  # int(num / 10)
    if cache_on:
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
