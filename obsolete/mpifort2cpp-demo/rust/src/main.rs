// jacobi.rs — Rust version of the same 1D Jacobi MPI program.
// Mirrors jacobi.f90 / jacobi.cpp exactly: same layout, same halo exchange.
//
// Local index i in [0, m+1] <-> global index rank*m + i - 1.
// u[0] and u[m+1] are ghost (halo) cells — same as Fortran u(0) / C++ u[0].
//
// Rust notes for a Fortran/C++ person:
//   * Vectors own their memory (no manual free); `vec!` is your `allocate`.
//   * `u = u_new` would *move* u_new out; use std::mem::swap to rotate buffers.
//   * Indexing is 0-based like C++; cast i32 -> usize explicitly.
//   * mpi::initialize() returns Option<Universe>; unwrap() replaces Fortran's ierr checks.

use mpi::traits::*;
use mpi::collective::SystemOperation;

fn main() {
    // MPI init/rank/size — this is what MPI_Init/MPI_Comm_rank/MPI_Comm_size do
    // mpi::initialize() returns Option<Universe>, so unwrap() like the rsmpi examples.
    let universe = mpi::initialize().unwrap();
    let world = universe.world();

    let rank = world.rank();     // i32  (Rank)
    let nprocs = world.size();   // i32  (Rank)

    let n: i32 = std::env::var("JACOBI_N").ok().and_then(|s| s.parse().ok()).unwrap_or(1000);
    let iter: i32 = std::env::var("JACOBI_ITER").ok().and_then(|s| s.parse().ok()).unwrap_or(100);
    if n % nprocs != 0 { eprintln!("JACOBI_N must be divisible by nprocs"); std::process::exit(1); }

    const TAG_A: i32 = 1;
    const TAG_B: i32 = 2;

    let m = n / nprocs;          // owned cells per rank (Fortran: m = N / nprocs)

    // Fortran: real(8), allocatable :: u(0:m+1)
    // Rust:    Vec<f64> with length m+2, zero-initialized, freed automatically.
    let mut u = vec![0.0f64; (m + 2) as usize];
    let mut u_new = vec![0.0f64; (m + 2) as usize];

    // initial condition: u(x) = sin(pi * x), x in [0, 1]
    let pi = std::f64::consts::PI;
    for i in 0..=m + 1 {
        let x = (rank * m + i - 1) as f64 / (n - 1) as f64;
        u[i as usize] = (pi * x).sin();
    }

    let left = (rank - 1 + nprocs) % nprocs;   // Fortran: mod(rank - 1 + nprocs, nprocs)
    let right = (rank + 1) % nprocs;

    let left_proc = world.process_at_rank(left);
    let right_proc = world.process_at_rank(right);

    let t0 = mpi::time();          // mpi::time() == MPI_Wtime()
    let copy_mode = std::env::var("JACOBI_COPY").ok().is_some();  // JACOBI_COPY=1 切换策略
    for _ in 0..iter {
        // halo exchange. send_receive_with_tags == MPI_Sendrecv.
        //  - send my u[m] to the right; receive from the left into u_new[0]
        let (v_left, _status) = mpi::point_to_point::send_receive_with_tags(
            &u[m as usize], &right_proc, TAG_A, &left_proc, TAG_A,
        );
        u_new[0] = v_left;

        //  - send my u[1] to the left; receive from the right into u_new[m+1]
        let (v_right, _status2) = mpi::point_to_point::send_receive_with_tags(
            &u[1], &left_proc, TAG_B, &right_proc, TAG_B,
        );
        u_new[(m + 1) as usize] = v_right;

        // update owned cells 1..m
        for i in 1..=m {
            u_new[i as usize] =
                0.5 * (u[(i - 1) as usize] + u[(i + 1) as usize]);
        }

        // Buffer rotation: two strategies, like the other languages
        if copy_mode {
            u = u_new.clone();        // Fortran-style whole-array copy (O(m) per iteration)
        } else {
            std::mem::swap(&mut u, &mut u_new);  // O(1) buffer rotation
        }
    }
    let t1 = mpi::time();

    // local sum over owned cells 1..m (ghosts excluded)
    let local_sum: f64 = u[1..(m + 1) as usize].iter().sum();

    // MPI_Reduce: root gets the sum; others just contribute.
    if rank == 0 {
        let mut global_sum = 0.0f64;
        world.process_at_rank(0).reduce_into_root(
            &local_sum, &mut global_sum, SystemOperation::sum(),
        );
        std::fs::write("result_rust.txt", format!("{:.17}\n", global_sum)).unwrap();
        println!("rust  global_sum = {:.17}", global_sum);
        let dt = (t1 - t0).max(1e-6);
        println!("rust  compute_time_s = {:?}  GFLOP/s = {:?}", t1 - t0, (2.0 * n as f64 * iter as f64) / 1e9 / dt);
    } else {
        world.process_at_rank(0).reduce_into(&local_sum, SystemOperation::sum());
    }
}
