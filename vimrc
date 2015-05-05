"==============================
" my vim configure
"==============================
set nu! "显示行号
set fenc=utf-8 "设定默认解码
set fencs=utf-8,usc-bom,euc-jp,gb18030,gbk,gb2312,cp936
set guifont=Monaco\ 10 "设定字体
set guifontwide=YaHei\ Consolas\ Hybrid\ 10 "中文字体
set nocompatible "不要使用vi的键盘模式,而是vim自己的
set ruler "开启右下角光标位置显示
set cursorline "高亮光标所在行
set hlsearch "搜索关键词高亮
set confirm "在处理未保存或只读文件的时候,弹出确认
"set foldlevelstart=99 "文件打开后所有折叠都自动展开
set foldmethod=marker "代码折叠
set backup "修改文件时备份
set noswapfile "不要缓存
set autoindent "自动缩进,继承前一行的缩进方式,特别适用于多行注释
set expandtab "在缩进和遇到Tab键时使用空格 替代;使用noexpandtab取消设置
set shiftwidth=4 "缩进的空格数
set tabstop=4 "制表符的宽度,等于几个空格
"set softtabstop=4 "按下tab键，插入的是空格和tab制表符的混合
"set cindent "使用C语言的缩进方式,使用nocindent取消设置

"配置主题 /usr/share/vim/vim73/colors/
if has ("gui_running")
    colorscheme desert "lucius
else
    colorscheme desert
endif

syntax on "语法高亮
filetype plugin indent on "侦测文件类型，载入文件类型plugin脚本，使用缩进定义文件

"===========================
" winManager setting
"===========================
let g:winManagerWindowLayout = 'BufExplorer,FileExplorer|TagList'
let g:winManagerWidth = 30
let g:defaultExplorer = 0
nmap <C-W><C-F> :FirstExplorerWindow<CR>
nmap <C-W><C-B> :BottomExplorerWindow<CR>
nmap <silent> <leader>wm :WMToggle<CR>

"==========================
" ctags setting
"==========================
let Tlist_Sort_Type = "name" " order by 
let Tlist_Use_Right_Window = 1 " split to the right side of the screen
let Tlist_Compart_Format = 1 " show small meny
let Tlist_Exist_OnlyWindow = 1 " if you are the last, kill yourself
let Tlist_File_Fold_Auto_Close = 1 " Do not close tags for other files
let Tlist_Enable_Fold_Column = 0 " Do not show folding tree
let Tlist_WinHeight = 40
"nnoremap <silent> <F8> :TlistToggle<CR>

"===========================
" latex设置
"===========================
set grepprg=grep\ -nH\ $*
let g:tex_flavor = "latex"
" disable conceal feature
let g:tex_conceal= ''

"===========================
" Fortran配置
"===========================
let s:extfname = expand("%:e")
if s:extfname ==? "f90"
    let fortran_free_source=1
    unlet! fortran_fixed_source
else
    let fortran_fixed_source=1
    unlet! fortran_free_source
endif

"Fortran 文件的语法折叠
let fortran_fold=1
"为 do 循环、if 块和 select case 构造定义折叠区域,注意定义折叠区域会使大文件变慢
"let fortran_fold_conditionals=1
"为三行或更多连续的注释定义折叠区域
"let fortran_fold_multilinecomments=1
"设置代码折叠的方式
"set foldmethod=syntax

"更精确的Fortran语法
let fortran_more_precise=1
let fortran_do_enddo=1

"去掉固定格式每行开头的红色填充
let fortran_have_tabs=1

