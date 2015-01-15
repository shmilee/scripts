% 这是说明
% 这是作者
% 这是时间

\newpage

简介
====

我要用markdown xelatex pandoc 写文档。  

准备
====

* 安装[texlive](http://www.latex-project.org/)，[pandoc](http://johnmacfarlane.net/pandoc/)。  

* 寻找一个文本编辑器,[gvim](http://www.vim.org)不错。  

* 写个测试的[markdown](http://daringfireball.net/projects/markdown/)文本，就像本文这样。  

使用举例
========

* 本文的生成：  
        `pandoc -N --template=xelatex-cjk.tex --latex-engine=xelatex \  
            -V cjk=yes --toc README.md -o README.pdf`

FAQ
===

xelatex-cjk.tex是怎么来的
-------------------------

1.输出默认模板,在安装好pandoc之后，运行  
        `pandoc -D latex >xelatex-cjk.tex`

2.编辑xelatex-cjk.tex,添加  
`$if(cjk)$`  
`      \usepackage[BoldFont,SlantFont,CJKchecksingle]{xeCJK}`  
`      \setCJKmainfont{你的字体}`  
`      \setCJKsansfont{你的字体}`  
`      \setCJKmonofont{你的字体}`  
`      \punctstyle{quanjiao}`  
`      \ExplSyntaxOn`  
`      \tl_put_right:Nn \fontspec_init: { \cs_set_eq:NN \CJKfamily \use_none:n }`  
`      \ExplSyntaxOff`  
`    $endif$`

注：md文本此处的代码被拆成一行行，是为了方便本文生成pdf，莫怪。  
后面三句来自[google ctex issues 92](https://code.google.com/p/ctex-kit/issues/detail?id=92)

TODO
====

计划:有需求才有改变。

* 模板须简化，只为xelatex

pandoc -f rst -t beamer neoclassical-polarization.rst -o neoclassical-polarization.pdf --latex-engine=xelatex -V theme=nirma --template=beamer-cjk.tex

pandoc -N --template=beamer-cjk.tex --latex-engine=xelatex neoclassical-polarization.rst   -t beamer -o a.pdf -V theme=m -V date='\today'

pandoc -N --template=../beamer-cjk.tex --latex-engine=xelatex neoclassical-polarization.rst   -t beamer -o a.pdf -V colortheme=solarized -V date='\today'
