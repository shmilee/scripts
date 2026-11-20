// jacobi.cpp — mirrors jacobi.f90 line by line. Same algorithm, same layout.
// Local index i (0..m+1) <-> global index rank*m + i - 1.
// u[0] and u[m+1] are ghost (halo) cells — same as Fortran u(0) and u(m+1).
//
// NOTE FOR 2D/3D CODES: keep Fortran's column-major memory layout on purpose.
// A 2D Fortran array u(0:mx+1, 0:my+1) becomes a flat std::vector<double>
// accessed as u[i + j*(mx+2)] — then MPI buffers and BLAS calls translate 1:1.

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>
#include <mpi.h>          // use the C MPI API from C++: the old "C++ MPI bindings"
                          // (mpi++.h / MPI::Intracomm) were REMOVED in MPI-3. Do not use them.

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    int rank = 0, nprocs = 0;                // C++ variables MUST be initialized:
                                             // `int rank;` alone is a garbage value.
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &nprocs);

    int N     = 1000;                        // total cells
    int ITER  = 100;                          // JACOBI_N / JACOBI_ITER env vars
    if (const char* e = std::getenv("JACOBI_N")) N = std::stoi(e);   // override for
    if (const char* e = std::getenv("JACOBI_ITER")) ITER = std::stoi(e); // benchmarking
    if (N % nprocs != 0) { fprintf(stderr, "JACOBI_N must be divisible by nprocs\n"); return 1; }
    const int m     = N / nprocs;            // Fortran: m = N / nprocs
    const int TAG_A = 1, TAG_B = 2;
    double t0 = 0.0, t1 = 0.0;

    // Fortran: real(8), allocatable :: u(0:m+1)
    // C++:     std::vector<double> u(m+2)   — m+2 elements, all zero-initialized,
    // automatically freed at end of scope. No new/delete needed, ever.
    std::vector<double> u(m + 2), u_new(m + 2);

    const double PI = 3.14159265358979323846;
    for (int i = 0; i <= m + 1; ++i) {       // Fortran loop `do i = 0, m+1`
        double x = static_cast<double>(rank * m + i - 1)   // explicit conversion,
                 / static_cast<double>(N - 1);             // no implicit sloppiness
        u[i] = std::sin(PI * x);
    }

    const int left  = (rank + nprocs - 1) % nprocs;        // Fortran: mod(...)
    const int right = (rank + 1) % nprocs;

    t0 = MPI_Wtime();
    for (int iter = 0; iter < ITER; ++iter) {
        MPI_Status status;                   // MPI_Status is required in C (no
                                             // MPI_STATUS_IGNORE in the C API)
        MPI_Sendrecv(&u[m],          1, MPI_DOUBLE, right, TAG_A,
                     &u_new[0],      1, MPI_DOUBLE, left,  TAG_A,
                     MPI_COMM_WORLD, &status);
        MPI_Sendrecv(&u[1],          1, MPI_DOUBLE, left,  TAG_B,
                     &u_new[m + 1],  1, MPI_DOUBLE, right, TAG_B,
                     MPI_COMM_WORLD, &status);

        for (int i = 1; i <= m; ++i) {      // same 1..m range as Fortran's owned cells;
            u_new[i] = 0.5 * (u[i - 1] + u[i + 1]);   // ghosts still at [0] and [m+1]
        }

        // u = u_new;                        // == Fortran `u = u_new` — WARNING: copies the
                                             // whole array (O(m) memcpy per iteration)
                                           // WARNING: this COPIES the whole array (O(m) memcpy
                                           // per iteration). A performance-minded port uses:
        u.swap(u_new);                       // zero-cost buffer rotation == Rust mem::swap
    }
    t1 = MPI_Wtime();

    double local_sum = 0.0;
    for (int i = 1; i <= m; ++i) local_sum += u[i];

    double global_sum = 0.0;
    MPI_Reduce(&local_sum, &global_sum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        FILE* f = fopen("result_cpp.txt", "w");
        fprintf(f, "%.17g\n", global_sum);  // %.17g = enough digits for exact double
        fclose(f);
        printf("cpp   global_sum = %.17g\n", global_sum);
        printf("cpp   compute_time_s = %g  GFLOP/s = %g\n", t1 - t0,
               (2.0 * N * ITER) / 1.0e9 / ((t1 - t0) > 1e-6 ? (t1 - t0) : 1e-6));
    }

    MPI_Finalize();                          // no error code argument in the C API
    return 0;
}
