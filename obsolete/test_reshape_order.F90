!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                            !
!   fortran-reshape-n-dimensional-transpose
!   https://stackoverflow.com/questions/37442346/
!                                                                            !
!  Copyright (c) 2023 shmilee
!  Licensed under GNU General Public License v3
!                                                                            !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


program test_reshape4d
    implicit none
    integer :: nf,j,i,k
    real, dimension(:,:,:,:), allocatable :: zp3d

    allocate(zp3d(5, 2, 4, 3))
    zp3d(:,:,:,:)=0.0
    do nf=1,3
        do j=1,4
            do i=1,2
                do k=1,5
                    if (nf==1) then
                        zp3d(k,i,j,nf) = 1.0
                    else if (nf==2) then
                        zp3d(k,i,j,nf) = real(i)*sin(real(k*k+j))
                    else if (nf==3) then
                        zp3d(k,i,j,nf) = real(i)*exp(real(k*j))
                    end if
                end do
            end do
        end do
    end do

    WRITE(*,*) SHAPE(zp3d)
    WRITE(*,*) SHAPE(RESHAPE(zp3d, (/5*2*4*3/)))

    WRITE(*,*) 'shape=(5, 2, 4, 3), F order'
    ! np.array(list(map(float, out1.split()))).reshape((5, 2, 4, 3),order='F')
    WRITE(*,*) RESHAPE(zp3d, (/5*2*4*3/))

    WRITE(*,*) 'shape=(3, 4, 2, 5).T, like C order'
    ! np.array(list(map(float, out2.split()))).reshape((5, 2, 4, 3),order='C')
    WRITE(*,*) RESHAPE(zp3d, (/3, 4, 2, 5/), order=[4, 3, 2, 1])
end program
