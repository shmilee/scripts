:Title: sdjkfhksjfh
:subtitle: ghfghfgh
:Author: Richard Jones; John MacFarlane
:Date: \today

.. role:: latex(raw)
   :format: latex

Introduction&Background
=======================

粒子和热量的径向输运: 实验 > 新经典理论

新经典理论:
~~~~~~~~~~~

-  碰撞扩散 --> 输运 (minimal)

-  不稳定性 (ITG, TEM; ETG, TIM): 小尺度, 低频 (:math:`\omega_{ci}`) -->
   微湍流 --> 带状流

-  带状流

   -  减小湍流输运
   -  ITG 湍流的阈值 增加

--------

带状流阻尼模拟
~~~~~~~~~~~~~~

-  残留: Gyrokinetic > Gyrofluid

-  Gyrokinetic 轴对称的带状流,不能被线性无碰撞阻尼掉 -> Gyrofluid
   的阻尼项不合适

-  R-H: 残留带状流 反比于 等离子体径向的极化 <-- (磁漂移,bounce motion >
   回旋运动)

   -  无碰撞: 极化主要是 捕获和通行离子 偏离 流表面
   -  有碰撞:

      -  driving frequency << :math:`v_{ii}`;
      -  :math:`v_{ii}` << driving frequency

-  新经典极化 > 经典极化 : :math:`\frac{B_T^2}{B_p^2}`

计算新经典极化(H-R)
~~~~~~~~~~~~~~~~~~~

-  drift kinetic equation

--------

Neoclassical Polarization
=========================

R-H collisionless polarization
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:math:`\varepsilon_k^{pol}(p) = \frac{\omega_{pi}^2}{\omega_{ci}^2}(1+1.6\frac{q^2}{\sqrt{\epsilon}})`

R-H collisional polarization
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  high frequency,low collisionality (:math:`p\tau_{ii} \gg 1`)

:math:`\varepsilon_{k,nc}^{pol}(p) = \frac{\omega_{pi}^2}{\omega_{ci}^2}\frac{q^2}{\sqrt{\epsilon}}(1.6+\frac{3 \sqrt 2 \pi}{\gamma\Lambda})`,
where :math:`\gamma\Lambda \gg 1`

-  low frequency, collisional (:math:`p\tau_{ii} \ll 1`)

:math:`\varepsilon_{k,nc}^{pol}(p) = \frac{\omega_{pi}^2}{\omega_{ci}^2}\frac{q^2}{\epsilon^2}[1-\frac{8p\tau_{ii}}{\sqrt{\pi}}(1-1.461\sqrt{\epsilon})]`

--------

Collisional Neoclassical Polarization
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:math:`\varepsilon_{k,nc}^{pol}(p) = \frac{\omega_{pi}^2}{\omega_{ci}^2}\frac{q^2}{\epsilon^2}(1-P_1)`

:math:`P_1 = \frac{3}{2}\int_0^{1-\epsilon}d\lambda\langle G_k\rangle_E`
==>
:math:`P_1=(1-1.6\epsilon^{3/2})\frac{\gamma_0}{\gamma_0+\frac{\sqrt\pi}{8}\mu_1}`

:math:`\varepsilon_{k,nc}^{pol}(p) = \frac{\omega_{pi}^2}{\omega_{ci}^2}\frac{q^2}{\epsilon^2}\frac{1.6\epsilon^{3/2}+\frac{\sqrt\pi}{8}\mu_1}{\gamma_0+\frac{\sqrt\pi}{8}\mu_1}`,
where :math:`\gamma_0=p\tau_{ii}`, and
:math:`\mu_1=1+1.46\sqrt{\epsilon}`

--------

Zonal Flow Damping
==================

:math:`\phi_k(t)=A_1\exp^{-\gamma t}\cos(\omega t + \alpha)+A_2`

Zonal Flow Potential (R-H collisionless polarization)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:math:`\frac{\phi_k(t=\infty)}{\phi_k(t=0)} = \frac{\varepsilon_{k,cl}^{pol}(p)}{\varepsilon_{k,cl}^{pol}(p)+\varepsilon_{k,nc}^{pol}(p)} = \frac{1}{1+1.6*q^2/\sqrt{\epsilon}}`

--------

.. code:: python

    import numpy as np
    import matplotlib.pyplot as plt
    figsize(16,10)
.. code:: python

    q = np.linspace(1.0, 3.2)
    epsl=0.01
    line, = plt.plot(q, 1/(1+1.6*q*q/np.sqrt(epsl)), '--', linewidth=1)
    epsl=0.05
    line, = plt.plot(q, 1/(1+1.6*q*q/np.sqrt(epsl)), '--', linewidth=2)
    epsl=0.1
    line, = plt.plot(q, 1/(1+1.6*q*q/np.sqrt(epsl)), '--', linewidth=3)
    
    dashes = [10, 5, 100, 5] # 10 points on, 5 off, 100 on, 5 off
    line.set_dashes(dashes)
    
    plt.show()
    ## r/R =0.01,0.05,0.1, residual level with q(r)

--------

.. image:: output_8_0.png

--------

.. code:: python

    epsl = np.linspace(0.0, 0.1)
    q=1.6
    line, = plt.plot(epsl, 1/(1+1.6*q*q/np.sqrt(epsl)), '--', linewidth=1)
    q=2.0
    line, = plt.plot(epsl, 1/(1+1.6*q*q/np.sqrt(epsl)), '--', linewidth=2)
    q=3.0
    line, = plt.plot(epsl, 1/(1+1.6*q*q/np.sqrt(epsl)), '--', linewidth=3)
    
    dashes = [10, 5, 100, 5] # 10 points on, 5 off, 100 on, 5 off
    line.set_dashes(dashes)
    
    plt.show()
    ## q(r) =1.6,2.0,3.0, residual level with r/R

--------

.. image:: output_9_1.png

--------

Today's date is :latex:`\today`.
=====================================

.. raw:: latex

    \begin{columns}[onlytextwidth]
    \begin{column}{.5\textwidth}
    \resizebox{!}{0.4\textheight}{  
    \includegraphics{output_8_0.png}
    }
    \end{column}
    \begin{column}{.5\textwidth}
    \resizebox{!}{0.4\textheight}{  
    \includegraphics{output_9_1.png}
    }
    \end{column}
    \end{columns}
