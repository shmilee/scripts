#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2024 shmilee
# TOCHECK https://en.wikipedia.org/wiki/Rosetta_orbit
# TODO 3 circles: large, small, tiny

import sys
import random
import numpy as np
from gdpy3 import get_visplter
import matplotlib.animation as animation
pi, sin, cos = np.pi, np.sin, np.cos


class Hypocycloid(object):
    '''
    The curve of Hypocycloid, Hypotrochoid, Epitrochoid and more.
    Trace a point attached to a rolling circle that rolls around a fixed circle.

    Ref
    ----
    1. https://en.wikipedia.org/wiki/Hypocycloid
    2. https://en.wikipedia.org/wiki/Hypotrochoid
    3. https://en.wikipedia.org/wiki/Epicycloid
    4. https://en.wikipedia.org/wiki/Epitrochoid

    Parameter
    ---------
    p, q: int, >0
        k=p/q, the ratio of fixed circle radius(R) to rolling circle radius(r)
        k>1, fixed circle larger than rolling circle.
    sigma: 1 or -1, default 1
        rolling around the inside(1) or outside(-1) of the fixed circle
    dr: float, >0, default 1.0
        the ratio of *d* to *r*, where
        d is the distance of fixed point from the rolling circle center
    n: int, >=LCM(p,q)/p, default LCM(p,q)/p+1
        How many 2pi-angle(theta) of the center of the rolling circle rolls?
        at least LCM(p,q)/p
    nexample: int, >=180, default 180
        number of theta examples of one 2pi
    theta0: float
        initial angle of the center of the rolling circle
    alpha0: float
        initial angle of the fixed point radius line
        0, the point is on the attached side
    color_r: str, color of the rolling circle
    color_p: str, color of the fixed point radius line
    color_t: str, color of the trace
    '''
    plotter = get_visplter("mpl::Hypotrochoid")
    plotter.style = ['gdpy3-notebook', {'axes.grid': False}]
    plt_lws = 1.0  # line width scale
    arr_2pi = np.linspace(0, 2*pi, 360)
    Ux_circle, Uy_circle = cos(arr_2pi), sin(arr_2pi)  # of Unit circle
    R, color_R = 1.0, 'k'  # of the fixed circle
    R_circle = (R*Ux_circle, R*Uy_circle)
    color_a = 'b'  # of auxiliary lines

    def __init__(self, p=2, q=1, sigma=1, dr=1, n=0, nexample=180,
                 theta0=0, alpha0=0, color_r='k', color_p='r', color_t='r'):
        p, q = int(abs(p)), int(abs(q))
        sigma = -1 if sigma == -1 else 1
        k = sigma*p/q
        r = self.R/k
        d = float(abs(dr))*r
        lstn = np.lcm(p, q)//p
        n = int(n) if int(n) >= lstn else (lstn+1)
        theta0 = float(theta0)
        default_nexample = 180*(p//q//5) if (lstn == 1 and p/q >= 10) else 180
        if default_nexample > nexample:  # more nexample
            nexample = default_nexample
            print('Warnning: more examples %d for 2pi theta.' % nexample)
        theta = np.linspace(theta0, theta0+n*2*pi, n*nexample)
        alpha0 = float(alpha0)
        # start point, k*theta0 -> back to attached side, then alpha0
        tracex = r*(k-1.0)*cos(theta) + d*cos((k-1.0)*theta - k*theta0-alpha0)
        tracey = r*(k-1.0)*sin(theta) - d*sin((k-1.0)*theta - k*theta0-alpha0)
        self.p, self.q, self.sigma, self.k = p, q, sigma, k
        self.r, self.d, self.n = r, d, n
        self.theta0, self.alpha0 = theta0, alpha0
        self.theta, self.tracex, self.tracey = theta, tracex, tracey
        # cache info, array
        if sigma == 1:
            self.curve = 'Hypocycloid' if d == r else 'Hypotrochoid'
        elif sigma == -1:
            self.curve = 'Epicycloid' if d == r else 'Epitrochoid'
        info = 'R={0:.1f}, p={1}, q={2}, r={3:.3f}, d={4:.3f}r'.format(
            self.R, p, q, r, d/r)
        self.info = '{0}, n={1}, t0={2:.2f}pi, a0={3:.2f}pi'.format(
            info, n, theta0/pi, alpha0/pi)
        self._rx_circle = self.r*self.Ux_circle
        self._ry_circle = self.r*self.Uy_circle
        self._tracex, self._tracey = 1.0*tracex, 1.0*tracey
        # for animation
        if sigma == 1:  # R>0, r>0, d>0
            self.Rlim = 1.1*max(self.R-r+d, self.R, r-self.R+d)
        elif sigma == -1:  # R>0, r<0, d<0
            self.Rlim = 1.1*max(self.R-r-d, self.R-2*r)
        self.color_r = color_r
        self.color_p = color_p
        self.color_t = color_t
        print('Curve:', self)

    def __repr__(self):
        return '<{0} object for {1}.>'.format(self.curve, self.info)

    def r_circle(self, dtheta):
        '''
        Get x, y array of the rolling circle.
        *dtheta* is the angle of the center of the rolling circle.
        '''
        cox = (self.R-self.r)*cos(dtheta)
        coy = (self.R-self.r)*sin(dtheta)
        return cox + self._rx_circle, coy + self._ry_circle

    def rp_line(self, dtheta, deltad):
        '''
        Get the line of the rolling circle center to the fixed point.
        *dtheta* is the angle of the center of the rolling circle.
        *deltad* is a perturbation on :attr:`d` of the fixed point.
        Return line-x, line-y, dx, dy
        '''
        cox = (self.R-self.r)*cos(dtheta)
        coy = (self.R-self.r)*sin(dtheta)
        # fixed point R*dtheta = r*(-dalpha + dtheta), and k*theta0
        dalpha = - (self.k-1.0)*dtheta + self.k*self.theta0 + self.alpha0
        pox = cox + self.d*cos(dalpha)
        poy = coy + self.d*sin(dalpha)
        dx = deltad*cos(dalpha)
        dy = deltad*sin(dalpha)
        return (cox, pox+dx), (coy, poy+dy), dx, dy

    def animation(self, *othercurves, speedup=1, perturbation=0, **kwargs):
        '''
        Plot this curve and other curves.

        Parameter
        ---------
        othercurves: list of other Hypocycloid instance to plot together
        speedup: int
            how many trace points updated in one frame
        perturbation: float, 0-1
            perturbation on fixed point radius :attr:`d`
        kwargs: dict, passed to `animation.FuncAnimation`
        '''
        # othercurves = [c for c in othercurves if isinstance(c, Hypocycloid)]
        curves = [self]
        for c in othercurves:
            if isinstance(c, Hypocycloid) and c not in curves:
                curves.append(c)
        _kwargs = dict(interval=10, repeat_delay=1000)  # default 10ms, 1s
        _kwargs.update(kwargs)
        _kwargs['blit'] = True
        Rlim = max(c.Rlim for c in curves)
        uniqR_r = set(abs(self.R-c.r) for c in curves)  # for R-r, R-2r circles
        uniqR_r.update(abs(self.R-2*c.r) for c in curves)
        lws = self.plt_lws
        axes = {
            'layout': [111, dict(
                xlim=[-Rlim, Rlim],
                ylim=[-Rlim, Rlim],
                aspect='equal',
            )],
            'data': [
                [1, 'revise', 'arrow_spines', dict(arrow_size=10*lws)],
                [3, 'plot', self.R_circle, dict(color=self.color_R, lw=2*lws)],
                *[[4+i, 'plot', (ur*self.Ux_circle, ur*self.Uy_circle, '--'),
                   dict(color=self.color_a, lw=0.8)]
                  for i, ur in enumerate(uniqR_r)],
                *[[100+10*i+1, 'plot', c.r_circle(c.theta0),
                   dict(label='circle', color=c.color_r, lw=1.5*lws)]
                  for i, c in enumerate(curves)],
                *[[100+10*i+2, 'plot', c.rp_line(c.theta0, 0)[:2],
                   dict(label='line', color=c.color_p, lw=1.5*lws,
                        marker='o', ms=4*lws)]
                  for i, c in enumerate(curves)],
                *[[100+10*i+3, 'plot', (c.tracex[:1], c.tracey[:1]),
                   dict(label='trace', color=c.color_t, lw=2*lws)]
                  for i, c in enumerate(curves)],
                [2, 'revise', self.animation_revise,
                 dict(curves=curves, speedup=int(speedup),
                      perturbation=perturbation, **_kwargs)],
            ]
        }
        figlabel = ['%s-%s-%s' % (c.curve, hex(id(c)), c.info.replace(' ', ''))
                    for c in curves]
        fig = self.plotter.create_figure(';'.join(figlabel), axes)
        fig.show()
        input('[I] Enter to continue: ')
        # fig.animation.save('a.mp4')  # time=n*nexample/speedup/fps s
        return fig

    def animation_revise(self, fig, axesdict, artistdict, **kwargs):
        '''Animation function for matplotlib'''
        curves = kwargs.pop('curves')
        speedup = kwargs.pop('speedup')
        perturbation = min(0.99, abs(kwargs.pop('perturbation')))
        L = max(c.theta.size for c in curves)
        frames = list(range(0, L-1, speedup)) + [L-1]

        def update(num):
            # num: 0 -> L-1; frame-number
            arts = []
            for i, curv in enumerate(curves):
                if num >= curv.theta.size:
                    tnum = curv.theta.size-1
                    perturb = 0  # stop perturbation of this curve
                    # continue  # still update arts as blit=True
                else:
                    tnum = num
                    perturb = 1 if perturbation > 0 else 0
                idx = 100+10*i
                dtheta = curv.theta[tnum]
                circle = artistdict[idx+1][0]  # update circle
                cx, cy = curv.r_circle(dtheta)
                circle.set_data(cx, cy)
                pline = artistdict[idx+2][0]  # update fixed point
                trace = artistdict[idx+3][0]  # update trace
                if perturb == 1:
                    deltad = perturb*perturbation*curv.d*random.random()
                    lx, ly, dx, dy = curv.rp_line(dtheta, deltad)
                    pline.set_data(lx, ly)
                    curv._tracex[tnum] = curv.tracex[tnum] + dx
                    curv._tracey[tnum] = curv.tracey[tnum] + dy
                    trace.set_data(
                        curv._tracex[:tnum+1], curv._tracey[:tnum+1])
                else:
                    lx, ly, dx, dy = curv.rp_line(dtheta, 0)
                    pline.set_data(lx, ly)
                    trace.set_data(curv.tracex[:tnum+1], curv.tracey[:tnum+1])
                arts.extend([circle, pline, trace])
            return arts  # return a list of updated artists, as blit=True

        fig.animation = animation.FuncAnimation(fig, update, frames, **kwargs)
        fig.animation_paused = False

        def toggle_pause(event):
            if fig.animation_paused:
                fig.animation.resume()
            else:
                fig.animation.pause()
            fig.animation_paused = not fig.animation_paused
        fig.canvas.mpl_connect('button_press_event', toggle_pause)


if __name__ == '__main__':
    test_keys = [1, 11, 2, 21, 22, 3, 5, 51, 'T']
    test = 21
    if len(sys.argv) > 1:
        arg = sys.argv[1]
        test = int(arg) if arg.isdigit() else arg
        if test not in test_keys:
            print('[Err] Test %s out of valid tests: %s' % (test, test_keys))
            sys.exit()
    print("Test: %s\n" % test)
    if test == 1:  # multi
        h11 = Hypocycloid()
        h11.animation(speedup=3)
        h12 = Hypocycloid(p=34, q=11)
        h12.animation(speedup=2, perturbation=0.05)
        h13 = Hypocycloid(p=94, q=31, color_t='g', color_p='g')
        h13.animation(h12, speedup=5)
    elif test == 11:  # dr
        h104 = Hypocycloid(p=119, q=17, dr=0.4, color_t='r', nexample=160)
        h106 = Hypocycloid(p=119, q=17, dr=0.6, color_t='orange', nexample=220)
        h108 = Hypocycloid(p=119, q=17, dr=0.8, color_t='y', nexample=260)
        h11 = Hypocycloid(p=119, q=17, dr=1.0, color_t='g', nexample=300)
        h12 = Hypocycloid(p=119, q=17, dr=1.2, color_t='b', nexample=340)
        h13 = Hypocycloid(p=119, q=17, dr=1.4, color_t='c', nexample=380)
        h14 = Hypocycloid(p=119, q=17, dr=1.6, color_t='m', nexample=420)
        fig = h104.animation(h106, h108, h11, h12, h13, h14, speedup=2)
        fig.animation.save('h11-fps14.mp4', fps=14)  # n*420/speedup/14=30s
    elif test == 2:  # ellipse
        h210 = Hypocycloid(p=2, q=1, dr=0.2/1, color_t='k', color_p='k')
        h211 = Hypocycloid(p=2, q=1, dr=1/1, color_t='b', color_p='b')
        h212 = Hypocycloid(p=2, q=1, dr=2/1, color_t='r', color_p='r')
        h215 = Hypocycloid(p=2, q=1, dr=5/1, color_t='g', color_p='g')
        h210.animation(h211, h212, h215)
    elif test == 21:  # ellipse
        h2101 = Hypocycloid(p=2, q=1, dr=0.5, theta0=pi/4,
                            alpha0=0, color_t='k', color_p='k')
        h2131 = Hypocycloid(p=2, q=1, dr=3/1, theta0=pi/4,
                            alpha0=pi/2, color_t='b', color_p='b')
        h2141 = Hypocycloid(p=2, q=1, dr=4/1, theta0=pi/4,
                            alpha0=-pi/2, color_t='r', color_p='r')
        h2151 = Hypocycloid(p=2, q=1, dr=5/1, theta0=pi/4,
                            alpha0=pi, color_t='g', color_p='g')
        h2101.animation(h2131, h2141, h2151, h2101, h2151,
                        perturbation=0.01, repeat_delay=10000)
    elif test == 22:  # non ellipse
        h21a = Hypocycloid(p=2, q=1, dr=1/1, sigma=-1, alpha0=0,
                           color_t='r', color_p='r')
        h21b = Hypocycloid(p=2, q=1, dr=1/2, sigma=-1, alpha0=pi/2,
                           color_t='b', color_p='b')
        h21c = Hypocycloid(p=2, q=1, dr=1/4, sigma=-1, alpha0=pi,
                           color_t='g', color_p='g')
        h21a.animation(h21b, h21c)
    elif test == 3:  # p<q, so r>R
        h341 = Hypocycloid(p=3, q=4, n=4, nexample=180)
        h342 = Hypocycloid(p=3, q=5, sigma=-1, color_t='#008800')
        h341.animation(h342, speedup=2)
        print('==> 3/4 vs 3/1, -3/1')
        h3410 = Hypocycloid(p=3, q=1, sigma=+1, color_t='g', color_p='g',
                            n=1, nexample=180*4)  # slow down
        h3411 = Hypocycloid(p=3, q=1, sigma=-1, color_t='b', color_p='b',
                            n=1, nexample=180*4)
        h3411.animation(h3410, h341, speedup=2, repeat_delay=5*1000)
    elif test == 5:  # stars
        h51 = Hypocycloid(p=5, q=1, theta0=pi/2, color_t='y')
        h52 = Hypocycloid(p=5, q=2, theta0=pi/2, color_t='orange')
        h53 = Hypocycloid(p=5, q=3, theta0=pi/2, color_t='orange')
        h54 = Hypocycloid(p=5, q=4, theta0=pi/2, color_t='y')
        h51.animation(h52, speedup=5)
        h53.animation(h54, speedup=5)
        print('==> 5/1 vs 5/4')
        h51.animation(h54, speedup=2)
    elif test == 51:  # star, dr
        h530 = Hypocycloid(p=5, q=3, dr=0.3/3, theta0=pi/2, color_t='k')
        h531 = Hypocycloid(p=5, q=3, dr=1/3, theta0=pi/2, color_t='k')
        h532 = Hypocycloid(p=5, q=3, dr=2/3, theta0=pi/2, color_t='r')
        h53L = Hypocycloid(p=5, q=3, dr=2.5/3, theta0=pi/2, color_t='b')
        h533 = Hypocycloid(p=5, q=3, dr=3/3, theta0=pi/2, color_t='g')
        h534 = Hypocycloid(p=5, q=3, dr=4/3, theta0=pi/2, color_t='y')
        h535 = Hypocycloid(p=5, q=3, dr=5/3, theta0=pi/2, color_t='orange')
        h536 = Hypocycloid(p=5, q=3, dr=6/3, theta0=pi/2, color_t='gold')
        h536.animation(
            # h535,
            h534,
            h533,
            # h53L,
            h532,
            h531,  # h530,
            speedup=3)
    elif test == 'T':  # trace only
        Hypocycloid.color_R = 'w'
        Hypocycloid.color_a = 'w'
        color_kws = dict(color_r='w', color_p='w', color_t='gold')
        h511 = Hypocycloid(p=5, q=1, theta0=pi/2, **color_kws)
        h521 = Hypocycloid(p=5, q=2, theta0=pi/2, **color_kws)
        h531 = Hypocycloid(p=5, q=3, dr=4/3, theta0=pi/2, **color_kws)
        h511.animation(h521, h531, speedup=10, repeat_delay=10*1000)
