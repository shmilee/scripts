#!/bin/bash
# Copyright (C) 2025 shmilee

export DOCKER_ENV=false
WORKDIR="$(dirname $(readlink -f "$0"))"
source "$WORKDIR/github-repos.conf"
mkdir -pv $"$WORKDIR"/{download,build,dist}

build_app() {
    local name="$1"
    local gituser="$(get_gituser $name)"
    local gitrepo="$(get_gitrepo $name)"
    local appdir="$(get_appdir $name)"
    local buildir="${WORKDIR}/build/${gituser}-${gitrepo}-${AppCommits[$name]}"
    local distdir="${WORKDIR}/dist/$appdir"

    if [ -d "$distdir" ]; then
        echo "Skip $name: $distdir exists."
        return
    fi

    local downurl="${AppUrls[$name]}/archive/${AppCommits[$name]}.tar.gz"
    local tarball="${WORKDIR}/download/${appdir}.tar.gz"
    if [ ! -f "$tarball" ]; then
        wget -c "$downurl" -O "$tarball" || return
        # rm screenshotX.png
        gzip -d "$tarball"
        tar -v -f "${tarball/.gz/}" --delete ${gitrepo}-${AppCommits[$name]}/public/screenshot{1,2,3}.png
        if [ "$gitrepo" == 'KatelyaTV' ]; then
            tar -v -f "${tarball/.gz/}" --delete ${gitrepo}-${AppCommits[$name]}/public/{screenshot4.png,wechat.jpg}
        fi
        gzip "${tarball/.gz/}"
    fi

    if [ ! -d "$buildir" ]; then
        tar zxf "$tarball" -C "${WORKDIR}/build/"
        mv -v "${WORKDIR}/build/${gitrepo}-${AppCommits[$name]}" "$buildir"
    fi
    # build, test w/ Node.js v24.7.0, Corepack 0.34.0, pnpm 10.15.1
    if [ ! -f "$buildir/.next/standalone/.next/BUILD_ID" ]; then
        printf "\n[I] Building %s in $buildir\n\n" "$name"
        cd "$buildir"
        # 确保 Next.js 在编译时即选择 Node Runtime 而不是 Edge Runtime
        find ./src -type f -name "route.ts" -print0 \
            | xargs -0 sed -i "s/export const runtime = 'edge';/export const runtime = 'nodejs';/g"
        (pnpm install --frozen-lockfile && pnpm run build) \
            | tee "${WORKDIR}/build/${appdir}-build.log"
        cd "${WORKDIR}/"
    else
        printf "\n[I] Found builded %s in $buildir\n\n" "$name"
    fi

    # install to $WORKDIR/dist/
    mkdir -pv "$distdir"
    (
        # copy .next/standalone, .next/static, public, scripts, and start.js
        echo "'$buildir/.next/standalone/{*,.*}' -> '$distdir'"
        cp -r "$buildir/.next/standalone/"* "$distdir/"
        cp -r "$buildir/.next/standalone/".* "$distdir/"
        echo "'$buildir/.next/static' -> '$distdir/.next/static'"
        cp -r "$buildir/.next/static" "$distdir/.next/static"
        cp -rv "$buildir/public" "$distdir/public"
        cp -rv "$buildir/scripts" "$distdir/scripts"
        cp -v "$buildir/start.js" "$distdir/start.js"
        # link manifest.json
        mv -v "$distdir/public/manifest.json" \
            "${distdir}-manifest.json"
        ln -sv ../../"${appdir}-manifest.json" \
            "$distdir/public/manifest.json"
        printf "\n[I] %s installed to ${distdir}\n\n" "$name"
    ) | tee "${distdir}-install.log"
    ls "$distdir/node_modules/.pnpm/" \
        | sort >"${distdir}-node_modules.txt"
    ls -l "$distdir/node_modules/" | awk '{print $9" -> "$11}' \
        | sort >>"${distdir}-node_modules.txt"

    # squashfs compress
    local appsqfs="${distdir}.squashfs"
    local modsqfs="${WORKDIR}/dist/$(get_nodemodsquashfs $name)"
    local mksqfsopts="-comp zstd -all-root"
    mksquashfs "${distdir}" "$appsqfs" $mksqfsopts \
        -e "$distdir/node_modules" | tee -a "${distdir}-install.log"
    if [ "$gitrepo" == 'KatelyaTV' ]; then
        local exclude="${distdir}-node_modules-exclude.txt"
        grep '\-linux' "${distdir}-node_modules.txt" \
            | sed "s|^|${distdir}/node_modules/.pnpm/|" >"$exclude"
        mksquashfs "${distdir}/node_modules" "$modsqfs" $mksqfsopts \
            -ef "$exclude" | tee -a "${distdir}-install.log"
    else
        mksquashfs "${distdir}/node_modules" "$modsqfs" $mksqfsopts \
            | tee -a "${distdir}-install.log"
    fi

    # check files
    cd "${WORKDIR}/dist/"
    find $appdir -maxdepth 2
    echo
    cd "${WORKDIR}/"
}

echo "=== ${AppNames[@]} ==="
for name in ${AppNames[@]}; do
    build_app "$name"
done

