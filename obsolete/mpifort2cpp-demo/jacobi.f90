! jacobi.f90 — baseline implementation (the "ground truth" for differential testing)
! 1D Jacobi iteration: u_new(i) = 0.5 * (u(i-1) + u(i+1))
! Domain of N cells split across all MPI ranks; periodic halo exchange.
! Local index i (0..m+1) <-> global index rank*m + i - 1
! u(0) and u(m+1) are ghost (halo) cells.
program jacobi
  use mpi
  use iso_fortran_env
  implicit none

  integer, parameter :: TAG_A = 1, TAG_B = 2

  integer :: N, NITER                          ! overridable for benchmarking
  integer :: rank, nprocs, ierr
  integer :: it, i, m, left, right
  real(8), allocatable :: u(:), u_new(:)
  real(8) :: x, local_sum, global_sum
  real(8) :: t0, t1
  character(len=32) :: envstr

  call MPI_Init(ierr)
  call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
  call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)

  N = 1000
  NITER = 100
  call get_environment_variable('JACOBI_N', envstr)
  if (len_trim(envstr) > 0) read(envstr, *) N
  call get_environment_variable('JACOBI_ITER', envstr)
  if (len_trim(envstr) > 0) read(envstr, *) NITER
  if (mod(N, nprocs) /= 0) stop 'JACOBI_N must be divisible by nprocs'

  m = N / nprocs                              ! owned cells per rank
  allocate(u(0:m+1), u_new(0:m+1))

  ! initial condition: u(x) = sin(pi * x), x in [0,1]
  do i = 0, m+1
     x = real(rank*m + i - 1, 8) / real(N - 1, 8)
     u(i) = sin(3.14159265358979323846d0 * x)
  end do

  left  = mod(rank - 1 + nprocs, nprocs)
  right = mod(rank + 1, nprocs)

  t0 = MPI_Wtime()
  do it = 1, NITER
     ! halo exchange:
     !  - my u(m)   fills right neighbor's left ghost
     !  - left  neighbor's u(m) fills my left ghost
     call MPI_Sendrecv(u(m),    1, MPI_DOUBLE_PRECISION, right, TAG_A, &
                       u_new(0), 1, MPI_DOUBLE_PRECISION, left,  TAG_A, &
                       MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
     !  - my u(1)     fills left neighbor's right ghost
     !  - right neighbor's u(1) fills my right ghost
     call MPI_Sendrecv(u(1),    1, MPI_DOUBLE_PRECISION, left,  TAG_B, &
                       u_new(m+1), 1, MPI_DOUBLE_PRECISION, right, TAG_B, &
                       MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)

     do i = 1, m
        u_new(i) = 0.5d0 * (u(i-1) + u(i+1))
     end do

     u = u_new                                ! whole-array assignment
  end do
  t1 = MPI_Wtime()

  local_sum = sum(u(1:m))
  call MPI_Reduce(local_sum, global_sum, 1, MPI_DOUBLE_PRECISION, MPI_SUM, &
                  0, MPI_COMM_WORLD, ierr)

  if (rank == 0) then
     open(unit=10, file='result_fortran.txt')
     write(10, '(G0.17)') global_sum
     close(10)
     write(*,'(A,G0.17)') 'fortran global_sum = ', global_sum
     write(*,'(A,G0.6,A,G0.6)') 'fortran  compute_time_s = ', t1 - t0, &
          '  GFLOP/s = ', (2.0d0 * N * NITER) / 1.0d9 / max(1.0d-6, t1 - t0)
  end if

  deallocate(u, u_new)
  call MPI_Finalize(ierr)
end program jacobi
