import numpy as np
from gdpy3 import get_visplter
import matplotlib.animation as animation

plotter = get_visplter("mpl::/test")
plotter.style = ['gdpy3-paper-aip']

cos = np.cos
sin = np.sin
pi = np.pi


def add_ani(fig, axesdict, artistdict, **fkwargs):
    line = artistdict[4][0]
    srcx, srcy = artistdict[13][0].get_data()

    def update_line(num):
        # line.set_marker('*')
        line.set_data(srcx[:num], srcy[:num])
        return line,
    L = srcx.size
    fig.gdpy3_animation = animation.FuncAnimation(
        fig, update_line, np.arange(0, L), interval=100, blit=True)
    fig.gdpy3_animation_paused = False

    def toggle_pause(event):
        if fig.gdpy3_animation_paused:
            fig.gdpy3_animation.resume()
        else:
            fig.gdpy3_animation.pause()
        fig.gdpy3_animation_paused = not fig.gdpy3_animation_paused
    fig.canvas.mpl_connect('button_press_event', toggle_pause)


x = np.linspace(-8, 8, 1000)

fig = plotter.create_figure('test', {'layout': [111, dict(xlim=[-8, 8], projection='polar')], 'data': [
    [1, 'plot', (x, 4*np.exp(-x**2/8)), dict()],
    [2, 'plot', (x, -4*np.exp(-x**2/8)), dict()],
    [-3, 'plot', (x, 2*np.exp(-x**2/16)), dict()],
    [4, 'plot', (x[0], 0, 'k'), dict(label='black', lw=1)],
    [13, 'plot', (x, 4*cos(2*pi*x)*np.exp(-x**2/8)), dict()],
    [-14, 'plot', (x, 2*sin(pi*x)*np.exp(-x**2/16)), dict()],
    [33, 'revise', add_ani, {}],
]})

# long time 15min?
# fig.gdpy3_animation.save('a.mp4')

fig.show()
input('Enter')
