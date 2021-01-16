module tttt
  integer, public, protected :: num

  interface test_opt_size
    module procedure test_opt_size
  end interface test_opt_size

  interface show
    module procedure nshow
    module procedure rshow
  end interface

contains

  subroutine init_num(n)
      integer :: n
      num = n
      write(*,*) '    -> init num: ', num
  end subroutine

  subroutine dec_num(dn)
      integer :: dn
      write(*,*) '    -> dn: ', dn
      num = num - dn
      write(*,*) '    -> dec num: ', num
  end subroutine

  subroutine test_opt_size(N, nresults, rresults, parents)
        integer :: idx, mtest, Nr
        integer, intent(in) :: N
        integer, intent(out), dimension(:), allocatable, optional :: nresults ! defult
        real, intent(out), dimension(:), allocatable, optional :: rresults
        character(len=*), intent(in), dimension(:), optional :: parents
        integer, dimension(:), allocatable :: thandle

        if (present(parents)) then
            Nr = size(parents)
            allocate(thandle(Nr), STAT=mtest)
            if(mtest /= 0) then
                write(*,*) N, 'call. Cannot allocate thandle: mtest=', mtest
                STOP 1
            end if
            write(*,*) N, 'call.', Nr, 'parents.'
            do idx=1, Nr
                write(*,*) N, 'call. Index', idx, parents(idx)
                thandle(idx) = idx
            end do
        else
            Nr = 3
            write(*,*) N, 'call. No present parents'
        end if
        if (present(rresults)) then
            allocate(rresults(Nr), STAT=mtest)
        else
            allocate(nresults(Nr), STAT=mtest)
        end if
        do idx=1, Nr
            if (present(rresults)) then
                rresults(idx) = real(mod(N,10)*10 + idx**2) + 0.01
            else
                nresults(idx) = mod(N,10)*10 + idx**2
            end if
        end do
  end subroutine

  subroutine nshow(results)
        integer :: idx
        integer, intent(in), dimension(:) :: results
        write(*,*) '  ==integer==='
        do idx=1, size(results)
            write(*,*) '    ->', idx, results(idx)
        end do
        write(*,*) '  ============='
  end subroutine
  subroutine rshow(results)
        integer :: idx
        real, intent(in), dimension(:) :: results
        write(*,*) '  ====real===='
        do idx=1, size(results)
            write(*,*) '    ->', idx, results(idx)
        end do
        write(*,*) '  ============='
  end subroutine
end module

program test
  use tttt
  implicit none
  character(len=10) :: path(2) = (/'group', 'keys'/)
  character(len=10) :: p1(1) = (/'group2'/)
  integer :: outtype
  integer, dimension(:), allocatable :: nresults  
  real, dimension(:), allocatable :: rresults  

  call test_opt_size(11, nresults=nresults, parents=path)
  call show(nresults)
  call test_opt_size(N=25, rresults=rresults)
  call show(rresults)
  call test_opt_size(78, nresults=nresults)
  call show(nresults)
  call test_opt_size(39, rresults=rresults, parents=p1)
  call show(rresults)
  call test_opt_size(532,rresults=rresults, parents=(/'asdsf'/))
  call show(rresults)

  write(*,*) '    -> before init, num: ', num
  call init_num(100)
  call dec_num(10)
  call dec_num(13)
  call dec_num(25)
  write(*,*) '    -> final, num: ', num

end program

