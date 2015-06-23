#!/usr/bin/env bash

## petsc
## http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-${Ver}.tar.gz
## depends=('python2' 'openmpi' 'boost' 'lapack')
## ignore boost, use lapack of ${lapack_dir}

Ver=3.5.3
file=./petsc-${Ver}.tar.gz

MYAPP=$HOME/myapp ## /usr

lapack_dir=$MYAPP
mpi_intel=/usr/local/mpi.intel
_mpis=('openmpi1.6.4') ##'mvapi2_1.8') ##'mpich2_1.5')

W_DIR=$(pwd)
if [[ -n "$1" ]];then
    if [ $1 == extract -o $1 == e ]; then
        tar zxvf ${file}
    elif [ $1 == build -o $1 == b ]; then
        cd petsc-${Ver}/
        for i_mpi in ${_mpis[@]}; do
            i_arch=linux-$(echo $i_mpi | sed 's/.\..\..//g;s/_.\..//g')-intel
            echo "==> PETSC_ARCH=${i_arch}"
            ./configure --prefix=$MYAPP/petsc-${Ver}/${i_arch} \
                --PETSC_ARCH=${i_arch} \
                --with-blas-lapack-dir=${lapack_dir} \
                --with-mpi-dir=${mpi_intel}/${i_mpi} || exit 1
            make PETSC_DIR=${W_DIR}/petsc-${Ver} PETSC_ARCH=${i_arch} all || exit 2
            echo "==> Done."
        done
    elif [ $1 == install -o $1 == i ]; then
        cd petsc-${Ver}/
        for i_mpi in ${_mpis[@]}; do
            i_arch=linux-$(echo $i_mpi | sed 's/.\..\..//g;s/_.\..//g')-intel
            echo "==> PETSC_ARCH=${i_arch}"
            make PETSC_DIR=${W_DIR}/petsc-${Ver} PETSC_ARCH=${i_arch} install ||exit 3
            echo "==> Done."
        done
    else
        echo "Usage: $0 [extract|build|install]"
    fi
else
    echo "Usage: $0 [extract|build|install]"
fi
