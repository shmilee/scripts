// jacobi_bad.cpp — deliberately WRONG version of jacobi.cpp for demo purposes.
// The bug: the update loop reads u[i+2] instead of u[i+1].
// At i == m this reads u[m+2] — one element PAST the end of the vector.
// This is exactly the kind of "compiles fine, runs fine at -O2, silently wrong"
// bug that AI-generated C++ can contain and that you cannot spot by eye.

#include <cmath>
#include <cstdio>
#include <vector>
#include <mpi.h>

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    int rank = 0, nprocs = 0;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &nprocs);

    const int N    = 1000;
    const int ITER = 100;
    const int m    = N / nprocs;
    const int TAG_A = 1, TAG_B = 2;

    std::vector<double> u(m + 2), u_new(m + 2);

    const double PI = 3.14159265358979323846;
    for (int i = 0; i <= m + 1; ++i) {
        double x = static_cast<double>(rank * m + i - 1) / static_cast<double>(N - 1);
        u[i] = std::sin(PI * x);
    }

    const int left  = (rank + nprocs - 1) % nprocs;
    const int right = (rank + 1) % nprocs;

    for (int iter = 0; iter < ITER; ++iter) {
        MPI_Status status;
        MPI_Sendrecv(&u[m],         1, MPI_DOUBLE, right, TAG_A,
                     &u_new[0],     1, MPI_DOUBLE, left,  TAG_A,
                     MPI_COMM_WORLD, &status);
        MPI_Sendrecv(&u[1],         1, MPI_DOUBLE, left,  TAG_B,
                     &u_new[m + 1], 1, MPI_DOUBLE, right, TAG_B,
                     MPI_COMM_WORLD, &status);

        for (int i = 1; i <= m; ++i) {
            u_new[i] = 0.5 * (u[i] + u[i + 2]);   // BUG: should be u[i-1] + u[i+1]
        }

        u = u_new;
    }

    double local_sum = 0.0;
    for (int i = 1; i <= m; ++i) local_sum += u[i];

    double global_sum = 0.0;
    MPI_Reduce(&local_sum, &global_sum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        FILE* f = fopen("result_cpp.txt", "w");
        fprintf(f, "%.17g\n", global_sum);
        fclose(f);
        printf("cpp   global_sum = %.17g\n", global_sum);
    }

    MPI_Finalize();
    return 0;
}
