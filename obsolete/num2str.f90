program num2str
    implicit none

    write(*,*) '-i4= '//trim(int2str(-2**30-2**30-1))
    write(*,*) '+i4= '//trim(int2str(2**32))
    write(*,*) '-i8= '//trim(int82str(-2_8**62-2_8**62-1))
    write(*,*) '+i8= '//trim(int82str(2_8**64))
    write(*,*)
    write(*,*) '-i4= '//trim(int2str(-2**30-2**30))
    write(*,*) '+i4= '//trim(int2str(2**32-1))
    write(*,*) '-i8= '//trim(int82str(-2_8**62-2_8**62))
    write(*,*) '+i8= '//trim(int82str(2_8**64-1))
    write(*,*) '5r4= '//trim(real2str(5000.123456789))
    write(*,*) 'er4= '//trim(real2str(0.0000000000012345678))
    write(*,*) 'er4= '//trim(real2str(9.999**38.533))

contains

    function int2str(i) result(str)
        integer, intent(in) :: i
        character(len=12) :: str
        write(str, '(I12)') i
        str = adjustl(str)
    end function

    function int82str(i) result(str)
        integer(kind=8), intent(in) :: i
        character(len=22) :: str
        write(str, '(I22)') i
        str = adjustl(str)
    end function

    function real2str(r) result(str)
        real, intent(in) :: r
        character(len=20) :: str
        if (r<10000 .and. r>0.1) then
            write(str, '(F18.7)') r
        else
            write(str, '(E20.7)') r
        endif
        str = adjustl(str)
    end function

end program
