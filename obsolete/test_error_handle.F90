!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                            !
!   module mm for Fortran/error handling
!   https://en.wikibooks.org/wiki/Fortran/error_handling                     !
!                                                                            !
!  Copyright (c) 2023 shmilee
!  Licensed under GNU General Public License v3
!                                                                            !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

module mm
    implicit none
contains

    subroutine test_open_file(path)
        character(len=*), intent(in) :: path
        integer :: my_iostat
        character (256) :: my_iomsg

        open(file=trim(path), unit=10, iostat=my_iostat, iomsg=my_iomsg, status='replace')
        if (my_iostat/=0) then
            write (*,*) 'Open(replace) ', trim(path), ' failed with iostat = ', my_iostat, ' iomsg = '//trim(my_iomsg)
        else
            write(10,101)1
            close(10)
        end if
    101 format(i6)    
    end subroutine

end module

program XX
    use mm
    implicit none

    write(*,*) 'Permission'
    call test_open_file('/root/a')

    write(*,*) 'path error'
    call test_open_file('/tmp/aaaaaa/b/c')

    write(*,*) 'here ./abcde'
    call test_open_file('./abcde')
end program
