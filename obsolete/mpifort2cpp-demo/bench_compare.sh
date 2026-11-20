#!/usr/bin/env bash
# Performance benchmark: same algorithm, same problem size, same optimization
# level (-O3 + -march=native for all three). Measures the compute loop with
# MPI_Wtime, so MPI startup overhead is excluded.
#
#   ./bench_compare.sh                      # N=2,000,000, ITER=500
#   JACOBI_N=5000000 JACOBI_ITER=1000 ./bench_compare.sh
set -euo pipefail

export PATH="$HOME/.cargo/bin:$PATH"
if [ -d /tmp/clangvenv/lib/python3.14/site-packages/clang/native ]; then
  export LIBCLANG_PATH=/tmp/clangvenv/lib/python3.14/site-packages/clang/native
fi
export BINDGEN_EXTRA_CLANG_ARGS="-I$(gcc -print-file-name=include)"

N=${JACOBI_N:-2000000}
ITER=${JACOBI_ITER:-500}

# Build all three at the SAME optimization level: -O3 + native SIMD
mpif90 -O3 -march=native jacobi.f90 -o jacobi_f90_bench
g++ -std=c++17 -O3 -march=native jacobi.cpp -o jacobi_cpp_bench \
    $(mpic++ --showme:compile) $(mpic++ --showme:link)
(cd rust && RUSTFLAGS="-C opt-level=3 -C target-cpu=native" cargo build --release --quiet)

echo "Problem: N=$N cells, ITER=$ITER iterations, 2*N*ITER = $(python3 -c "print(f'{2*$N*$ITER/1e9:.0f}')") GFLOP"
echo
for p in 1 2 4 8; do
  out_f=$(JACOBI_N=$N JACOBI_ITER=$ITER mpirun -n "$p" ./jacobi_f90_bench)
  out_c=$(JACOBI_N=$N JACOBI_ITER=$ITER mpirun -n "$p" ./jacobi_cpp_bench)
  out_r=$(JACOBI_N=$N JACOBI_ITER=$ITER mpirun -n "$p" ./rust/target/release/jacobi_rust)
  python3 - "$p" "$N" "$ITER" <<EOF
import re, sys
p, N, ITER = sys.argv[1], float(sys.argv[2]), float(sys.argv[3])
out_f = """$out_f"""
out_c = """$out_c"""
out_r = """$out_r"""
def get(out, name):
    m = re.search(rf"{name}\s+compute_time_s =\s*([0-9.eE+-]+)", out)
    return float(m.group(1))
tf, tc, tr = get(out_f, "fortran"), get(out_c, "cpp"), get(out_r, "rust")
flops = 2.0 * N * ITER / 1e9
print(f"p={p:<2}  fortran={tf:7.4f}s  cpp={tc:7.4f}s  rust={tr:7.4f}s   |   "
      f"GFLOP/s  F={flops/tf:6.1f}  C={flops/tc:6.1f}  R={flops/tr:6.1f}   |   "
      f"relative: F={tc/tf:.3f}  C={tr/tf:.3f}  R=1.000")
EOF
done
