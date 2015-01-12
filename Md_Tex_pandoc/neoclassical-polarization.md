Introduction&Background
=======================

粒子和热量的径向输运: 实验 \> 新经典理论

新经典理论:
-----------

-   碰撞扩散 --\> 输运 (minimal)
-   不稳定性 (ITG, TEM; ETG, TIM): 小尺度, 低频 ($\omega_{ci}$) --\>
    微湍流 --\> 带状流
-   带状流
    -   减小湍流输运
    -   ITG 湍流的阈值 增加

------------------------------------------------------------------------

带状流阻尼模拟
--------------

-   残留: Gyrokinetic \> Gyrofluid
-   Gyrokinetic 轴对称的带状流,不能被线性无碰撞阻尼掉 -\> Gyrofluid
    的阻尼项不合适
-   R-H: 残留带状流 反比于 等离子体径向的极化 \<-- (磁漂移,bounce
    motion \> 回旋运动)
    -   无碰撞: 极化主要是 捕获和通行离子 偏离 流表面
    -   有碰撞:
        -   driving frequency \<\< $v_{ii}$;
        -   $v_{ii}$ \<\< driving frequency
-   新经典极化 \> 经典极化 : $\frac{B_T^2}{B_p^2}$

计算新经典极化(H-R)
-------------------

-   drift kinetic equation

Neoclassical Polarization
=========================

------------------------------------------------------------------------

R-H collisionless polarization
------------------------------

$\varepsilon_k^{pol}(p) = \frac{\omega_{pi}^2}{\omega_{ci}^2}(1+1.6\frac{q^2}{\sqrt{\epsilon}})$

R-H collisional polarization
----------------------------

-   high frequency,low collisionality ($p\tau_{ii} \gg 1$)

$\varepsilon_{k,nc}^{pol}(p) = \frac{\omega_{pi}^2}{\omega_{ci}^2}\frac{q^2}{\sqrt{\epsilon}}(1.6+\frac{3 \sqrt 2 \pi}{\gamma\Lambda})$,
where $\gamma\Lambda \gg 1$

-   low frequency, collisional ($p\tau_{ii} \ll 1$)

$\varepsilon_{k,nc}^{pol}(p) = \frac{\omega_{pi}^2}{\omega_{ci}^2}\frac{q^2}{\epsilon^2}[1-\frac{8p\tau_{ii}}{\sqrt{\pi}}(1-1.461\sqrt{\epsilon})]$

------------------------------------------------------------------------

Collisional Neoclassical Polarization
-------------------------------------

$\varepsilon_{k,nc}^{pol}(p) = \frac{\omega_{pi}^2}{\omega_{ci}^2}\frac{q^2}{\epsilon^2}(1-P_1)$

$P_1 = \frac{3}{2}\int_0^{1-\epsilon}d\lambda\langle G_k\rangle_E$ ==\>
$P_1=(1-1.6\epsilon^{3/2})\frac{\gamma_0}{\gamma_0+\frac{\sqrt\pi}{8}\mu_1}$

$\varepsilon_{k,nc}^{pol}(p) = \frac{\omega_{pi}^2}{\omega_{ci}^2}\frac{q^2}{\epsilon^2}\frac{1.6\epsilon^{3/2}+\frac{\sqrt\pi}{8}\mu_1}{\gamma_0+\frac{\sqrt\pi}{8}\mu_1}$,
where $\gamma_0=p\tau_{ii}$, and $\mu_1=1+1.46\sqrt{\epsilon}$

Zonal Flow Damping
==================

potential
---------
