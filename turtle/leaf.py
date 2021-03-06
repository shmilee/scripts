#!/usr/bin/env python

# -*- coding:utf-8 -*-

from numpy import *
from random import random
import matplotlib.pyplot as plt

p = [0.85,0.91,0.99,1.00]
A1 = array([[.83,  0.03],[-0.03,.86]])
B1 = array([0,1.5])
A2 = array([[0.20,-0.25],[0.21,0.23]])
B2 = array([0,1.5])
A3 = array([[-0.15,0.27],[0.25,0.26]])
B3 = array([0,0.45])
A4 = array([[0,0],[0,0.17]])
B4 = array([0,0])

i = 0
X = []
Y = []
x = array([0,0])
while i < 500000:
    i += 1
    r = random()
    if r < p[0]:
        x = dot(A1 , x) + B1
    elif r < p[1]:
        x = dot(A2 , x) + B2
    elif r < p[2]:
        x = dot(A3 , x) + B3
    else:
        x = dot(A4 , x) + B4
    X += [x[0]*120]
    Y += [x[1]*60-240]

plt.plot(X, Y, 'g.', markersize = 1)
plt.show()
