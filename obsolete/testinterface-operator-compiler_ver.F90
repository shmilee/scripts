MODULE concatenate

    !! Fortran 90 standard: https://wg5-fortran.org/N001-N1100/N692.pdf
    !!  12.3.2.1.1 Defined operations
    !!  If the operator is an intrinsic-operator (R310), the number of function arguments must be consistent with the intrinsic uses of that operator.

    !! Fortran 2008 standard: https://j3-fortran.org/doc/year/10/10-007r1.pdf
    !!  12.4.3.4.2 Deﬁned operations
    !!  If the operator is an intrinsic-operator (R309), the number of function arguments shall be consistent with the intrinsic uses of that operator,
    !!  and the types, kind type parameters, or ranks of the dummy arguments shall diﬀer from those required for the intrinsic operation (7.1.5).

    !! Intel https://www.intel.com/content/www/us/en/docs/fortran-compiler/developer-guide-reference/2025-0/define-generic-operators.html
    !!  //  An extended intrinsic operator (number of arguments must be consistent with the intrinsic uses of that operator)

    ! operator(.join.) ; operator(.concat.)
    !interface operator(.join.)
    interface operator(//)
        !module procedure str_add_str
        module procedure str_add_int, int_add_str
        !module procedure str_add_real, str_add_double
        module procedure str_add_arr1d
    end interface

    ! public :: operator(.join.)

CONTAINS

    function int2str(i) result(str)
        integer, intent(in) :: i
        character(len=12) :: str
        write(str, '(I12)') i
        str = adjustl(str)
    end function

    function str_add_str(s1,s2) result (res)
        character(len=*), intent(in) :: s1, s2
        character(len=:), allocatable :: res

        res = s1//s2
    end function

    function str_add_int(s,i) result (res)
        character(len=*), intent(in) :: s
        integer, intent(in) :: i
        character(len=:), allocatable :: res

        res = s//trim(int2str(i))
    end function

    function int_add_str(i,s) result (res)
        integer, intent(in) :: i
        character(len=*), intent(in) :: s
        character(len=:), allocatable :: res

        res = trim(int2str(i))//s
    end function

    function str_add_arr1d(s, arr)  result (res)
        integer, intent(in), dimension(:) :: arr
        character(len=*), intent(in) :: s
        integer :: i, N
        character(len=:), allocatable :: res

        N = size(arr)
        if (N>1) then
            res = s//'['
            do i=1,size(arr)-1
                res = res//trim(int2str(arr(i)))//', '
            enddo
            res = res//trim(int2str(arr(N)))//']'
        elseif (N==1) then
            res = s//'['//trim(int2str(arr(1)))//']'
        else
            res = s//'[]'
        endif
    end function

end module

program main
    use, intrinsic :: iso_fortran_env, only : compiler_version,compiler_options
    use concatenate
    implicit none

    character(len=*), parameter :: build_date = __DATE__
    character(len=*), parameter :: build_time = __TIME__
    character(len=256) :: compl_version
    character(len=1024) :: compl_options

    compl_version = compiler_version()
    compl_options = compiler_options()
    print '(A)', compl_version
    print '(A)', compl_options

    write(*,'(A)') '--------'
    write(*,'(A)') 'CVER=',     compl_version

    write(*,'(A)') '--------'
    write(*,'(2A)') 'CVER=',     trim(compl_version)
    write(*,901) 'Compiler Options = ',            trim(compl_options)
    write(*,'(A)') '--------'

    !write(*, 901) 777 .join. 'TYU |', "LLDF " .join. 75 .Join. 999.join.' --- END'
    !write(*, 901) 123 .join. 'POI | ' .join. (/5/) .join. (/8,7,6/)

    !! for intel 18.0.1.148 Build 20170928: need ( ) as it is a binary operator
    !write(*, 901) (123 .join. 'OIU | ') .join. (/8,7,6/)

    write(*, 901) 999 // 'ASE |', "SKNU " // 21 // ' --- END'
    write(*, 901) 123 // 'ILU | ' // (/8/) // (/2,9,6/)

901 format((2A))
end program
