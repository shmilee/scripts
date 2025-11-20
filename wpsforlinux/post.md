* 问题1：[WPS Office overriding or breaking mime](https://wiki.archlinux.org/title/WPS_Office#WPS_Office_overriding_or_breaking_mime)
```
common\do_not_detect_file_association_while_startup=true
```

* 问题2：[双击无法打开文件](https://aur.archlinux.org/packages/wps-office-cn#comment-1044131)
```
wpsoffice\Application%20Settings\AppComponentMode=prome_fushion
```

FIX:

```
[$] tail .config/Kingsoft/Office.conf
...
common\do_not_detect_file_association_while_startup=true
wpsoffice\Application%20Settings\AppComponentMode=prome_fushion

[kdcsdk]
...
```
