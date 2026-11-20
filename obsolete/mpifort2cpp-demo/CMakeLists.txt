cmake_minimum_required(VERSION 3.16)
project(jacobi_cpp CXX)          # MPI is NOT a CMake language; it is a package

find_package(MPI REQUIRED)       # this is how CMake finds MPI (finds mpic++ and friends)

add_executable(jacobi_cpp jacobi.cpp)
target_link_libraries(jacobi_cpp PRIVATE MPI::MPI_CXX)

# These warnings are your external "eyes" while you are still learning C++:
# -Wall -Wextra        : the standard set
# -Wconversion         : catches implicit int->double etc. — very useful coming from Fortran
target_compile_options(jacobi_cpp PRIVATE -Wall -Wextra -Wconversion -O2)

# ---- Sanitizer recipes, VERIFIED on this machine (OpenMPI 5.0.11 + GCC 16) ----
#
# UBSan — works fine under mpirun. Catches null deref, signed overflow,
# misaligned access, etc.:
#   cmake -B build-ubsan -DUBSAN=ON && cmake --build build-ubsan && mpirun -n 4 ./build-ubsan/jacobi_cpp
option(UBSAN "Enable UndefinedBehaviorSanitizer" OFF)
if(UBSAN)
  target_compile_options(jacobi_cpp PRIVATE -O1 -g -fsanitize=undefined -fno-omit-frame-pointer)
  target_link_options(jacobi_cpp PRIVATE -fsanitize=undefined)
endif()

# STL bounds checking — std::vector loudly aborts on out-of-bounds indexing.
# This is your ASan substitute for catching off-by-one bugs in MPI runs:
#   cmake -B build-dbg -DDBG_CHECKS=ON && cmake --build build-dbg && mpirun -n 4 ./build-dbg/jacobi_cpp
option(DBG_CHECKS "Enable libstdc++ debug mode (_GLIBCXX_DEBUG)" OFF)
if(DBG_CHECKS)
  target_compile_options(jacobi_cpp PRIVATE -O1 -g -D_GLIBCXX_DEBUG)
endif()

# NOTE about ASan: on this machine, AddressSanitizer crashes at process startup
# when linked with OpenMPI 5.0.x — a known upstream toolchain conflict, NOT a bug
# in jacobi.cpp (verified by trying plain, preload and detect_leaks=0 variants).
# Practical rules:
#   * ASan works cleanly with MPICH / Intel MPI / OpenMPI 4 — use it there.
#   * With OpenMPI 5: use UBSAN + DBG_CHECKS above, plus the differential test.
