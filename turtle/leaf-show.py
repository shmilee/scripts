#!/usr/bin/env python

# -*- coding:utf-8 -*-

from  numpy import *
from random import random
import turtle as tt

tt.reset()

x = array([0,0])

p = [0.85,0.91,0.99,1.00]

A1 = array([[.83,  0.03],[-0.03,.86]])
B1 = array([0,1.5])

A2 = array([[0.20,-0.25],[0.21,0.23]])
B2 = array([0,1.5])

A3 = array([[-0.15,0.27],[0.25,0.26]])
B3 = array([0,0.45])

A4 = array([[0,0],[0,0.17]])
B4 = array([0,0])

tt.speed(0)
tt.Turtle().screen.delay(0)
tt.color("black")
tt.penup()

i=0
while i < 50000:
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

    tt.goto(x[0]*120,x[1]*60-240)
    tt.dot(2)

input("Press <enter> to EXIT")
