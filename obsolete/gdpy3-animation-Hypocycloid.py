#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2024 shmilee

# ref: https://en.wikipedia.org/wiki/Hypocycloid
#      https://en.wikipedia.org/wiki/Hypotrochoid
#      https://en.wikipedia.org/wiki/Epicycloid
# TOCHECK https://en.wikipedia.org/wiki/Rosetta_orbit
# TODO 3: large, small, tiny

import numpy as np
from gdpy3 import get_visplter
import matplotlib.animation as animation

pi, sin, cos = np.pi, np.sin, np.cos
plotter = get_visplter("mpl::Hypocycloid")
#plotter.style = ['gdpy3-paper-aip']
plotter.style = ['gdpy3-notebook']
lws = 1.0  # line width scale

p, q = 5, 3  # TODO parameter
#p, q = 19, 17
#p, q = 34, 11
#p, q = 94, 31
sigma = 1  # TODO parameter, 1: inside; -1: outside
k = sigma*p/q  # abs()>=1.0

R = 1.0
r = R/k  # small circle
#d = r   # TODO parameter: distance of fixed point from the circle center
d = 1.1*r

# trace
N = q + 1
pi2 = np.linspace(0, 2*pi, 360)
t0 = -pi/2  # TODO parameter: initial theta0
theta = np.linspace(t0, t0+N*2*pi, int(180*N))
tx = r*(k-1.0)*cos(theta) + d*cos((k-1.0)*theta + k*t0)
ty = r*(k-1.0)*sin(theta) - d*sin((k-1.0)*theta + k*t0)

print(' R = %.2f\n r = %s%d/%dR = %.4f\n d = %.4fr = %.4f'
      % (R, '-' if sigma == -1 else '', q, p, r, d/r, d))
print(' N = theta/2pi = %d\n theta_0 = %.4fpi\n' % (N, t0/pi))

# small circle
def get_circle(dtheta):
    cx = (R-r)*cos(dtheta) + r*cos(pi2)
    cy = (R-r)*sin(dtheta) + r*sin(pi2)
    return cx, cy

# fixed point line
def get_pline(dtheta):
    dalpha = - (k-1.0)*dtheta - k*t0  # R*dtheta = r*(-dalpha + dtheta)
    cox = (R-r)*cos(dtheta)
    coy = (R-r)*sin(dtheta)
    px = cox + d*cos(dalpha)
    py = coy + d*sin(dalpha)
    return [cox, px], [coy, py]

def add_ani(fig, axesdict, artistdict, **fkwargs):

    def update_lines(num):
        # num: 0 -> theta.size-1; frame-number
        line = artistdict[10][0]  # update trace
        line.set_data(tx[:num+1], ty[:num+1])

        dtheta = theta[num]
        circle = artistdict[20][0]  # update circle
        cx, cy = get_circle(dtheta)
        circle.set_data(cx, cy)

        pline = artistdict[30][0]  # update fixed point
        lx, ly = get_pline(dtheta)
        pline.set_data(lx, ly)
        return line, circle, pline  #  returns a list of artists to be updated

    L = tx.size
    fig.gdpy3_animation = animation.FuncAnimation(
        fig, update_lines, np.arange(0, L), interval=10, blit=True)
    fig.gdpy3_animation_paused = False

    def toggle_pause(event):
        if fig.gdpy3_animation_paused:
            fig.gdpy3_animation.resume()
        else:
            fig.gdpy3_animation.pause()
        fig.gdpy3_animation_paused = not fig.gdpy3_animation_paused
    fig.canvas.mpl_connect('button_press_event', toggle_pause)

if sigma == 1:
    Rlim = 1.1*max(R-r+d, R)
elif sigma == -1:  # R>0, r<0, d<0
    Rlim = 1.1*max(R-r-d, R-2*r)
fig = plotter.create_figure(
    'Hypocycloid',
    {
        'layout': [111, dict(
            xlim=[-Rlim, Rlim],
            ylim=[-Rlim, Rlim],
            aspect='equal',
        )],
        'data': [
            [1, 'plot', (R*cos(pi2), R*sin(pi2), 'k'), dict(lw=2*lws)],
            [2, 'plot', ((R-r)*cos(pi2), (R-r)*sin(pi2), '--b'), dict(lw=0.8)],
            [3, 'plot', ((R-2*r)*cos(pi2), (R-2*r)*sin(pi2), '--b'), dict(lw=0.8)],
            [10, 'plot', (tx[0], ty[0], 'k'), dict(label='trace', lw=2*lws)],
            [20, 'plot', (*get_circle(0), 'k'), dict(label='circle', lw=1.5*lws)],
            [30, 'plot', (*get_pline(0), 'ro-'), dict(ms=4*lws, lw=1.5*lws)],
            [100, 'revise', 'arrow_spines', dict(arrow_size=10*lws)],
            [101, 'grid', (False,), {}],
            [110, 'revise', add_ani, {}],
        ]
    })

# long time mins?
#fig.gdpy3_animation.save('a.mp4')

fig.show()
input('Enter')

# next projection='polar'
