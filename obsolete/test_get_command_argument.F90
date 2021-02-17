program test_get_command_argument
  integer :: i
  character(len=255) :: arg
  character(len=255) :: conf
  logical :: ex

  !! https://gcc.gnu.org/onlinedocs/gfortran/GET_005fCOMMAND_005fARGUMENT.html#GET_005fCOMMAND_005fARGUMENT

  i = command_argument_count()
  write (*,*) '=> count: ', i
  i = 0
  do
    call get_command_argument(i, arg)
    if (len_trim(arg) == 0) exit

    write (*,*) trim(arg)
    i = i+1
  end do
  call get_command(arg)
  write (*,*) '=> cmd: ', trim(arg)
  i = len(trim(arg))
  write (*,*) '=> len(cmd): ', i

  call get_command_argument(0, arg)
  i = len(trim(arg))
  write (*,*) '=> len(arg(0)): ', i
  if (command_argument_count() > 0) then
    call get_command_argument(1, conf)
    conf = trim(arg(1:i-len('a.out')))//trim(conf)
  else
    conf = trim(arg(1:i-len('a.out')))//'.conf/input'
  endif
  !! https://software.intel.com/content/www/us/en/develop/documentation/fortran-compiler-oneapi-dev-guide-and-reference/top/language-reference/a-to-z-reference/h-to-i/inquire.html#inquire
  inquire(file=conf, exist=ex)
  if (.not. ex) then
    write (*,'(2A/)') '>> Cannot find conf file: ', trim(conf)
  else
    write (*,'(2A/)') '=> Use conf file: ', trim(conf)
  endif

end program
