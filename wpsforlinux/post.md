* 问题1：[WPS Office overriding or breaking mime](https://wiki.archlinux.org/title/WPS_Office#WPS_Office_overriding_or_breaking_mime)
```
common\do_not_detect_file_association_while_startup=true
```

* 问题2：双击无法打开文件
    - [ref1](https://aur.archlinux.org/packages/wps-office-cn#comment-1044131)
    - [ref2](https://aur.archlinux.org/packages/wps-office-cn#comment-1040495)
```
wpsoffice\Application%20Settings\AppComponentMode=prome_fushion
wpsoffice\Application%20Settings\AppComponentMode=prome_independ
```

FIX:

```
[$] tail .config/Kingsoft/Office.conf
...
common\do_not_detect_file_association_while_startup=true
wpsoffice\Application%20Settings\AppComponentMode=prome_independ

[kdcsdk]
...
```

* 问题3：wps 修改 docx 等文件的图标问题，主要原因，Override.xml 文件捣乱。

```
diff -Nur ～/.local/share/mime /media/Data/atb-userdata-backup/2025-11-19-182636/.local/share/mime|grep '\---'
```

修复还原：
    - 清空 `～/.local/share/mime/packages/Override.xml`
    - 更新 `update-mime-database ～/.local/share/mime`

