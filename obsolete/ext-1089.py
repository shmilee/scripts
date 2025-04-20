#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Python3 Program to check the given number for my 1089 trick.
# more like:
#   https://arxiv.org/html/2410.11784v2
#   https://oeis.org/A008919

# Max Iterations
MAX_ITERATIONS = 20

PM_ORDER = ('+', '-')

def checking(number):
    #if (isPalindrome(number)):
    #    return "No"
    sig = '+'
    for i in range(1, MAX_ITERATIONS+1):
        rev = reverse(number)
        if sig == PM_ORDER[0]:
            new = number + rev
            print(f'i={i}): {number} + {rev} = {new}')
        else:
            new = number - rev
            print(f'i={i}): {number} - {rev} = {new}')
        #print(f'i={i}')
        #if (isPalindrome(new)):
        #    return "No"
        number = new
        sig = '-' if sig == '+' else '+'
    return "Maybe"

# Function to check whether the number is Palindrome
def isPalindrome(number):
    return number == reverse(number)

cache_on, reverse_cache = True, {}

# Function to reverse the number
def reverse(number):
    if cache_on:
        if number in reverse_cache:
            #  print(f'using cache for {number}')
            return reverse_cache[number]
    reverse = 0
    num = -number if number < 0 else number
    while (abs(num) > 0):
        remainder = num % 10
        reverse = (reverse * 10) + remainder
        num = num // 10  # int(num / 10)
    if number < 0:
        reverse = -reverse
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
            ans = checking(number)
    elif len(sys.argv) >= 2:
        number = int(sys.argv[1])
        ans = checking(number)
    else:
        ans =  checking(21078)
