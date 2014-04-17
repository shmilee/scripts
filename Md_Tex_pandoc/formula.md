常见数学公式排版命令
===================

行中数学公式状态命令
-------------------

\\begin{math}  数学公式 \\end{math}

简式1：  \\(  数学公式   \\)

简式2：  \$   数学公式  \$

独立数学公式状态命令
--------------------

\\begin{displaymath} 数学公式 \\end{displaymath}

简式1：  \\[  数学公式   \\]

简式2：  \$\$   数学公式   \$\$

数学公式的编辑示例
------------------

### 数学公式中的各种字体：

$$
\begin{array}{l}
\mathrm{ABCDEFGHIJKLMNOPQRSTUVWXYZ}\\%罗马字体
\mathtt{ABCDEFGHIJKLMNOPQRSTUVWXYZ}\\%打字机字体
\mathbf{ABCDEFGHIJKLMNOPQRSTUVWXYZ}\\%黑体
\mathsf{ABCDEFGHIJKLMNOPQRSTUVWXYZ}\\%等线体
\mathit{ABCDEFGHIJKLMNOPQRSTUVWXYZ}\\%意大利字体
\end{array}
$$

### 文中数学公式用$作为定界符，对于独立公式用$$作为定界符。上标用“^”，下标用“_”。

例如：
$ x^{y^{z^{w}}}=(1+{\rm e}^{x})^{-2xy^{w}} $，
$y_1'+y_2''+y_3'''$，
Su$^{\rm per}_{\rm b}$script等等。

### 数学中花体字母”\cal”命令

例如：

$\cal {ABCDEFGHIJKLMNOPQRSTUVW}$

大部分数学符号在WinEdt编辑器中的math工具中都能找到。

### 下面是方程环境的控制命令：

\begin{equation}
0.3x+y/2=4z
\end{equation}

### 至于多行的独立公式，可以用如下方式撰写：

\begin{eqnarray}
x^n+y^n &=& z^n \\
x+y &=& z \\
e^{i\pi}+1 &=& 0
\end{eqnarray}

### 求和与积分命令：

$$\sum_{i=1}^{n} x_{i}=\int_{0}^{1}f(x)\, {\rm d}x $$
$$\sum_{{1\le i\le n}\atop {1\le j\le n}}a_{ij}$$
$$\sum\limits_{i=1}^{n} x_{i}=\int_{0}^{1}f(x)\, {\rm d}x $$

### 数学公式中省略号：

  $$\cdots  \ldots \vdots  \ddots $$

### 求极限的命令：

$$\lim_{n \rightarrow \infty}\sin x_{n}=0$$

$$\lim_{n \rightarrow \infty}\sin x_{n}=0$$

### 分式的排版命令：

$$x=\frac{y+z/2}{y^2+\frac{y}{x+1}}$$

$$a_0+\frac 1{\displaystyle a_1
     +\frac 1{\displaystyle a_2
     +\frac 1{\displaystyle a_3
     +\frac 1{\displaystyle a_4
     +\frac 1{\displaystyle {a_5}}}}}}$$

### 根式排版命令：    

$$x=\sqrt{1+\sqrt{1+\sqrt[n]{1+\sqrt[m]{1+x^{p}}}}}$$

$$x_{\pm}=\frac{-b\pm \sqrt{b^2-4ac}}{2a}$$

### 取模命令：

$\gcd(m,n)=a\bmod b$

$$x\equiv y \pmod{a+b}$$

### 矩阵排版命令：

$$\begin{array}{clcr}x+y+z & uv    & a-b & 8\\x+y   & u+v   & a   & 88\\x     & 3u-vw & abc &888\\\end{array}$$

$$\left ( \begin{array}{c}
\left |\begin{array}{cc}
a+b&b+c\\c+d&d+a
\end{array}
\right |\\
y\\z
\end{array}\right )
$$

### 数学符号的修饰：

* 上划线命令

$$\overline{1+\overline{1+\overline{x}^3}}$$

* 下划线命令

$$\underline{1+\underline{1+\underline{x}^3}}$$

* 卧式花括号命令

$$\overbrace{x+y+z+w}$$

$$\overbrace{a+b+\cdots +y+z}^{26}_{=\alpha +\beta}$$

* 仰式花括号命令

$$a+\underbrace{b+\cdots +y}_{24}+z$$

* 戴帽命令

$$\hat{o}\ \ \check{o}\ \ \breve{o}$$

$$\widehat{A+B} \ \ \widetilde{a+b}$$

$$\vec{\imath}+\vec{\jmath}=\vec{k}$$

* 堆砌命令

$$y\stackrel{\rm def}{=} f(x) \stackrel{x\rightarrow 0}{\rightarrow} A$$
