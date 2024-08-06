split mpv scripts files & history to a new git repo

* https://github.com/shmilee/config-mpv

* [partial-git-clone-with-relevant-history](https://stackoverflow.com/questions/28357056/)

```bash
repo=~/project/scripts
subdir=mpv

mkdir -v /tmp/split-repo-test/
cd /tmp/split-repo-test/

git clone $repo copy-tmp-repo
cd /tmp/split-repo-test/copy-tmp-repo/
git subtree split -P $subdir -b split-$subdir
git branch | grep split-

git init --bare ../repo-split-$subdir
git push ../repo-split-$subdir split-$subdir:master

cd /tmp/split-repo-test/repo-split-$subdir/
git log

newrepo=~/project/config-mpv
git clone /tmp/split-repo-test/repo-split-$subdir/ $newrepo
```
