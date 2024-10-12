"==============================
" my vim configure
"==============================
set nu! "显示行号
set fenc=utf-8 "设定默认解码
set fencs=utf-8,usc-bom,euc-jp,gb18030,gbk,gb2312,cp936
if has('nvim') 
    if exists(':GuiFont')
        " Use GuiFont! to ignore font errors
        GuiFont! Monaco:h10 "设定字体
    endif
else
    set guifont=Monaco\ 10 "设定字体
endif
set guifontwide=Consolas-with-Yahei\ 10 "中文字体
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

" GUI 标题 title
" https://vimhelp.org/cmdline.txt.html#filename-modifiers
if has("gui_running")
    set title
    "set titlelen=0 "do not shorten title
    set titlelen=160 "shorten title
    "lua vim.opt.titlestring = [[%f %h%m%r%w %{v:progname} (%{tabpagenr()} of %{tabpagenr('$')})]]
    "set titlestring=%t%(\ %M%)%(\ (%{expand(\"%:~:.:h\")})%)%(\ %a%)
    "set titlestring=%t%(\ (%{expand(\"%:~:h\")})%)\ -\ %{v:progname}
endif

"配置主题 /usr/share/vim/vim82/colors/
if has("gui_running")
    colorscheme desert "lucius
"else
"    colorscheme desert
endif

filetype plugin indent on "侦测文件类型，载入文件类型plugin脚本，使用缩进定义文件
syntax on "语法高亮
"https://stackoverflow.com/questions/41083829/
autocmd VimEnter,WinEnter * match Todo /\<\(TOCHECK\|TOTEST\|TOFIX\)\>/

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

"if has ('python3')
"    let g:jedi#force_py_version=3
"endif
"if has ('python')
"    let g:jedi#force_py_version=2
"endif
let g:jedi#completions_command = "<C-N>"
let g:jedi#show_call_signatures = 0

"===========================
" latex设置
"===========================
set grepprg=grep\ -nH\ $*
let g:tex_flavor = "latex"
" disable conceal feature
let g:tex_conceal= ''

let g:markdown_syntax_conceal = 0

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
"let fortran_fold=1
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

" 自动补全配置
set completeopt=longest,menu	"让Vim的补全菜单行为与一般IDE一致(参考VimTip1228)
autocmd InsertLeave * if pumvisible() == 0|pclose|endif	"离开插入模式后自动关闭预览窗口
inoremap <expr> <CR>       pumvisible() ? "\<C-y>" : "\<CR>"	"回车即选中当前项
"上下左右键的行为 会显示其他信息
inoremap <expr> <Down>     pumvisible() ? "\<C-n>" : "\<Down>"
inoremap <expr> <Up>       pumvisible() ? "\<C-p>" : "\<Up>"
inoremap <expr> <PageDown> pumvisible() ? "\<PageDown>\<C-p>\<C-n>" : "\<PageDown>"
inoremap <expr> <PageUp>   pumvisible() ? "\<PageUp>\<C-p>\<C-n>" : "\<PageUp>"

""youcompleteme  默认tab  s-tab 和自动补全冲突
""let g:ycm_server_python_interpreter='/usr/bin/python'
"let g:ycm_global_ycm_extra_conf = '/usr/share/vim/vimfiles/third_party/ycmd/cpp/ycm/.ycm_extra_conf.py'
""let g:ycm_key_list_select_completion=['<c-n>']
"let g:ycm_key_list_select_completion = ['<Down>']
""let g:ycm_key_list_previous_completion=['<c-p>']
"let g:ycm_key_list_previous_completion = ['<Up>']
"let g:ycm_confirm_extra_conf=0 "关闭加载.ycm_extra_conf.py提示
"
"let g:ycm_collect_identifiers_from_tags_files=1	" 开启 YCM 基于标签引擎
"let g:ycm_min_num_of_chars_for_completion=2	" 从第2个键入字符就开始罗列匹配项
"let g:ycm_cache_omnifunc=0	" 禁止缓存匹配项,每次都重新生成匹配项
"let g:ycm_seed_identifiers_with_syntax=1	" 语法关键字补全
"nnoremap <F5> :YcmForceCompileAndDiagnostics<CR>	"force recomile with syntastic
""nnoremap <leader>lo :lopen<CR>	"open locationlist
""nnoremap <leader>lc :lclose<CR>	"close locationlist
"inoremap <leader><leader> <C-x><C-o>
""在注释输入中也能补全
"let g:ycm_complete_in_comments = 1
""在字符串输入中也能补全
"let g:ycm_complete_in_strings = 1
""注释和字符串中的文字也会被收入补全
"let g:ycm_collect_identifiers_from_comments_and_strings = 0
"
"nnoremap <leader>jd :YcmCompleter GoToDefinitionElseDeclaration<CR> "跳转到定义处
