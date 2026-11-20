#!/usr/bin/env bash
# Differential test: Fortran baseline vs C++ vs Rust, at several process counts.
# This is the safety net that compensates for unfamiliar-language traps.
set -euo pipefail

# Rust toolchain setup (this machine):
# - cargo is installed under ~/.cargo/bin
# - rsmpi/mpi-sys uses bindgen, which needs libclang + GCC's stddef.h include path
export PATH="$HOME/.cargo/bin:$PATH"
if [ -d /tmp/clangvenv/lib/python3.14/site-packages/clang/native ]; then
  export LIBCLANG_PATH=/tmp/clangvenv/lib/python3.14/site-packages/clang/native
fi
export BINDGEN_EXTRA_CLANG_ARGS="-I$(gcc -print-file-name=include)"

# 1. Build the Fortran baseline
mpif90 -O2 jacobi.f90 -o jacobi_f90

# 2. Build the C++ version
cmake -B build -DCMAKE_BUILD_TYPE=Release > /dev/null
cmake --build build > /dev/null

# 3. Build the Rust version
(cd rust && cargo build --release --quiet)

# 4. Run all implementations at several process counts and compare against Fortran.
fail=0
for p in 1 2 4 5 8; do
  mpirun -n "$p" ./jacobi_f90 > /dev/null
  mpirun -n "$p" ./build/jacobi_cpp > /dev/null
  mpirun -n "$p" ./rust/target/release/jacobi_rust > /dev/null
  python3 - "$p" <<'EOF' || fail=1
import sys
p = sys.argv[1]
f = float(open("result_fortran.txt").read())
vals = {
    "cpp":  float(open("result_cpp.txt").read()),
    "rust": float(open("result_rust.txt").read()),
}
ok = True
for name, v in vals.items():
    rel = abs(f - v) / max(1.0, abs(f))
    ok = ok and rel < 1e-10
    print(f"p={p:>2}  fortran={f:.12f}  {name}={v:.12f}  rel_diff={rel:.2e}  {'MATCH' if rel < 1e-10 else 'MISMATCH'}")
sys.exit(0 if ok else 1)
EOF
done
exit $fail
