##http://coolshell.cn/articles/3790.html

%:
	@echo '$*=$($*)'
 
d-%:
	@echo '$*=$($*)'
	@echo '  origin = $(origin $*)'
	@echo '   value = $(value  $*)'
	@echo '  flavor = $(flavor $*)'
