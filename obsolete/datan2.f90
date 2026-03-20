program test_datan2
  implicit none
  integer, parameter :: dp = kind(1.0d0)  ! 定义双精度 kind
  real(dp) :: x, y, result
  integer :: i

  ! 测试数据：全部使用双精度常数（用 _dp 后缀或 d0）
  real(dp), dimension(9) :: x_vals = [ 1.0_dp,  1.0_dp, -1.0_dp, -1.0_dp, &
                                        0.0_dp,  0.0_dp,  1.0_dp, -1.0_dp,  0.0_dp ]
  real(dp), dimension(9) :: y_vals = [ 1.0_dp, -1.0_dp,  1.0_dp, -1.0_dp, &
                                        1.0_dp, -1.0_dp,  0.0_dp,  0.0_dp,  0.0_dp ]

  print *, 'Testing DATAN2(y, x) function (double precision):'
  print *, '   x        y        atan2(y,x) (radians)'
  do i = 1, 9
     result = datan2(y_vals(i), x_vals(i))
     print '(F6.2,2X,F6.2,2X,F8.4)', x_vals(i), y_vals(i), result
  end do

  ! 额外测试：负零（需要编译器支持，行为可能不同）
  print *, ''
  print *, 'Additional test with negative zero (if supported):'
  x = -0.0_dp
  y =  1.0_dp
  result = datan2(y, x)
  print '(F6.2,2X,F6.2,2X,F8.4)', x, y, result

  x =  0.0_dp
  y = -1.0_dp
  result = datan2(y, x)
  print '(F6.2,2X,F6.2,2X,F8.4)', x, y, result

end program test_datan2