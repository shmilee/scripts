#!/usr/bin/env python
# -*- coding: utf-8 -*-

import numpy as np
import matplotlib.pyplot as plt

# 模拟参数
G = 1.0
M = 100.0
m = 0.01
r0 = 1.0
dt = 0.0005
T = 2 * np.pi * np.sqrt(r0**3 / (G * M))  # 轨道周期

with open('./2body.txt', 'r') as f:
    outdata = f.readlines()
outdata = np.array([[float(n) for n in l.split()] for l in outdata[1:]])
steps = outdata[:, 0]
t_norm = steps * dt / T  # 以轨道周期归一化的时间
pos_a_x = outdata[:, 1]
pos_a_y = outdata[:, 2]
pos_b_x = outdata[:, 3]
pos_b_y = outdata[:, 4]
ke = outdata[:, 5]
pe = outdata[:, 6]

# 相对位置：B 相对于 A
rel_x = pos_b_x - pos_a_x
rel_y = pos_b_y - pos_a_y

# 开始绘图
plt.figure(figsize=(12, 14))

# 子图 1: Body A 和 B 的绝对轨迹
plt.subplot(3, 2, 1)
plt.plot(pos_a_x, pos_a_y, 'bo-', label='Body A', markersize=3)
plt.plot(pos_b_x, pos_b_y, 'ro-', label='Body B', markersize=3)
plt.xlabel('X')
plt.ylabel('Y')
plt.title('Absolute Trajectories')
plt.legend(fontsize='small')
plt.grid(True)
plt.axis('equal')

# 子图 2: Body B 相对 Body A 的轨迹
plt.subplot(3, 2, 2)
plt.plot(0, 0, 'bs', label='Body A (origin)', markersize=8)
plt.plot(rel_x, rel_y, 'ro-', label='Body B (relative)', markersize=3)
plt.xlabel('X relative')
plt.ylabel('Y relative')
plt.title('Relative Orbit (B w.r.t. A)')
plt.legend(fontsize='small')
plt.grid(True)
plt.axis('equal')

# 子图 3: Body A 位置随时间变化
plt.subplot(3, 2, 3)
plt.plot(t_norm, pos_a_x, 'b--', label='A_x')
plt.plot(t_norm, pos_a_y, 'b:', label='A_y')
plt.xlabel(r'Normalized Time $t/T$')
plt.ylabel('Position')
plt.title('Body A Position vs Time')
plt.legend(fontsize='small')
plt.grid(True)

# 子图 4: Body B 位置随时间变化
plt.subplot(3, 2, 4)
plt.plot(t_norm, pos_b_x, 'r--', label='B_x')
plt.plot(t_norm, pos_b_y, 'r:', label='B_y')
plt.xlabel(r'Normalized Time $t/T$')
plt.ylabel('Position')
plt.title('Body B Position vs Time')
plt.legend(fontsize='small')
plt.grid(True)

# 子图 5: Body B 动能随时间变化
plt.subplot(3, 2, 5)
plt.plot(t_norm, ke, 'g-', label='Kinetic Energy')
plt.xlabel(r'Normalized Time $t/T$')
plt.ylabel('Energy')
plt.title('Body B Kinetic Energy vs Time')
plt.legend(fontsize='small')
plt.grid(True)

# 子图 6: Body B 势能随时间变化
plt.subplot(3, 2, 6)
plt.plot(t_norm, pe, 'm-', label='Potential Energy')
plt.xlabel(r'Normalized Time $t/T$')
plt.ylabel('Energy')
plt.title('Body B Potential Energy vs Time')
plt.legend(fontsize='small')
plt.grid(True)

plt.tight_layout()
plt.show()

