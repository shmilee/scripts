import numpy as np
from gdpy3 import get_visplter
import matplotlib.animation as animation

plotter = get_visplter("mpl::Hypocycloid")
plotter.style = ['gdpy3-paper-aip']
pi, sin, cos = np.pi, np.sin, np.cos

# ref: https://en.wikipedia.org/wiki/Hypocycloid
#p, q = 4, 1
p, q = 48, 17
p, q = 32, 17
k = p/q  # >1.0
R = 1.0
r = R/k  # small circle
N = q + 1
pi2 = np.linspace(0, 2*pi, 360)

# trace
theta = np.linspace(0, N*2*pi, int(180*N))
tx = r*(k-1.0)*cos(theta) + r*cos((k-1.0)*theta)
ty = r*(k-1.0)*sin(theta) - r*sin((k-1.0)*theta)

# small circle
def get_circle(dtheta):
    cx = (R-r)*cos(dtheta) + r*cos(pi2)
    cy = (R-r)*sin(dtheta) + r*sin(pi2)
    return cx, cy

# fixed point line
def get_pline(dtheta):
    dalpha = - (k-1.0)*dtheta  # R*dtheta = r*(-dalpha + dtheta)
    cox = (R-r)*cos(dtheta)
    coy = (R-r)*sin(dtheta)
    px = cox + r*cos(dalpha)
    py = coy + r*sin(dalpha)
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


fig = plotter.create_figure(
    'Hypocycloid',
    {
        'layout': [111, dict(
            xlim=[-R, R],
            ylim=[-R, R],
            aspect='equal',
        )],
        'data': [
            [1, 'plot', (R*cos(pi2), R*sin(pi2), 'k'), dict(lw=0.5)],
            [2, 'plot', ((R-r)*cos(pi2), (R-r)*sin(pi2), '--b'), dict(lw=0.2)],
            [3, 'plot', ((R-2*r)*cos(pi2), (R-2*r)*sin(pi2), '--b'), dict(lw=0.2)],
            [10, 'plot', (tx[0], ty[0], 'k'), dict(label='trace', lw=0.5)],
            [20, 'plot', (*get_circle(0), 'k'), dict(label='circle', lw=0.3)],
            [30, 'plot', (*get_pline(0), 'ro-'), dict(ms=0.5, lw=0.4)],
            [50, 'revise', add_ani, {}],
        ]
    })

# long time mins?
#fig.gdpy3_animation.save('a.mp4')

fig.show()
input('Enter')

# next projection='polar'
