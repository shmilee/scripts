# Fortran / C++ / Rust MPI 三语言对比示例：差分测试脚手架

同一个 1D Jacobi 模板程序（周期 halo 交换 + 全局 reduction）的三种实现，
用来演示"边学新语言边用 AI 转换"时如何搭建安全网。

## 文件

| 文件 | 作用 |
|---|---|
| `jacobi.f90` | Fortran 基准版（ground truth） |
| `jacobi.cpp` | C++ 转换版，逐行对应，带教学注释 |
| `jacobi_bad.cpp` | 故意植入 off-by-one bug 的 C++ 版，用于演示工具抓 bug |
| `rust/Cargo.toml` | Rust 项目配置（依赖 `mpi` 0.8.2，即 rsmpi） |
| `rust/src/main.rs` | Rust 转换版，逐行对应，带教学注释 |
| `jacobi_f90_swap.f90` | Fortran 指针交换版（零拷贝 buffer 轮换，用于基准对比） |
| `CMakeLists.txt` | C++ 警告开关 + 已验证的 sanitizer 配方 |
| `run_compare.sh` | 差分测试：Fortran / C++ / Rust 在 1、2、4、5、8 个进程下对比 |
| `bench_compare.sh` | 性能基准：同规模同 -O3 -march=native，MPI_Wtime 计时 |
| `README.md` | 本说明 |

## 快速使用

```bash
cd ~/mpifort2cpp-demo
./run_compare.sh
```

脚本自动编译三版、在多进程数下运行、并把 C++ 和 Rust 的结果与 Fortran 基准逐项比较。

## Rust 构建前置（本机实测）

rsmpi 的 `mpi` crate 用 bindgen 生成 MPI 绑定，需要 `libclang` 和 GCC 的 `stddef.h` 路径：

```bash
# cargo（已通过 rustup 安装在 ~/.cargo/bin）
python3 -m venv /tmp/clangvenv
/tmp/clangvenv/bin/pip install libclang
export LIBCLANG_PATH=/tmp/clangvenv/lib/python3.14/site-packages/clang/native
export BINDGEN_EXTRA_CLANG_ARGS="-I$(gcc -print-file-name=include)"
```

`run_compare.sh` 已把这些环境变量自动设好。

## 三语言对照要点（Rust 版）

```rust
mpi::initialize().unwrap()                       // 返回 Option<Universe>，不是 Result
world.rank(); world.size()                       // 对应 MPI_Comm_rank / MPI_Comm_size
mpi::point_to_point::send_receive_with_tags(...) // 对应 MPI_Sendrecv（含 tag 参数）
std::mem::swap(&mut u, &mut u_new)               // `u = u_new` 在 Rust 里是 move，不是复制
world.process_at_rank(0).reduce_into_root(...)   // 对应 MPI_Reduce（root / 非 root 分支）
```

## 实测结果（全部 MATCH）

```
p= 1  fortran=635.957606565283  cpp=635.957606565283  MATCH
p= 1  fortran=635.957606565283  rust=635.957606565283 MATCH
p= 2  ... MATCH (cpp/rust)
p= 4  ... MATCH (cpp/rust)
p= 5  rel_diff=1.79e-16  MATCH
p= 8  rel_diff=1.79e-16  MATCH
```

差异出现在 1.79e-16 级别，原因是 Fortran `sum()` 和 Rust/C++ 的累加顺序可能不同——所以对比用 1e-10 相对容差，而不是逐 bit 相等。

## 性能基准（`./bench_compare.sh`，N=2,000,000，ITER=500，-O3 -march=native）

同一算法、同一优化级别下三语言的 compute 时间（MPI_Wtime 计时）。
**关键变量不是语言，而是 buffer 轮换策略**，3×2 完整矩阵（p=4，各跑 3 次取最小）：

| 每轮迭代的 buffer 策略 | Fortran | C++ | Rust |
|---|---|---|---|
| 整数组拷贝（`u = u_new` / `clone()`） | 0.506s | 0.470s | 0.551s |
| O(1) 交换（指针 / `swap` / `mem::swap`） | 0.236s | 0.229s | 0.226s |

- **同一策略下三语言差 < 3%**（低于这台共享机的运行噪声，任何语言都可能"最慢"）；
- **同一语言下两种策略差 2.1×**——策略是真正的主导因素。
- 所以 demo 主文件（Fortran 整数组赋值 + C++ 早期照抄版本）里 Fortran/C++ 都慢、
  Rust 快，是写法差异的巧合呈现，不是语言差距。

`jacobi_f90_swap.f90` 是 Fortran 指针交换版；Rust 版用 `JACOBI_COPY=1` 可切回拷贝策略。

注意：C++ 翻译时若照抄 Fortran 的 `u = u_new`，会无声地多付一倍开销——
这正是只有跑基准测试才能发现的问题。

## 本目录实测中真实踩到的坑（都是转换过程会遇到的）

1. **Fortran 大小写不敏感**：`ITER` 和 `iter` 是同一个符号 → 编译错误。
2. **CMake 里 MPI 不是语言**：`project(x MPI CXX)` 报错；正确做法 `project(x CXX)` + `find_package(MPI REQUIRED)`。
3. **OpenMPI 5.0 + ASan 冲突**：ASan 进程启动即崩（上游已知问题，MPICH/OpenMPI4 无此问题）。
   本机验证可用的替代：`_GLIBCXX_DEBUG` + UBSan + 差分测试。
4. **Rust 的两个转换陷阱**：
   - `mpi::initialize()` 返回 `Option`，`.unwrap()` 而非 `?`；
   - `u = u_new` 是 move 语义，必须 `std::mem::swap`；
   - rsmpi 构建需要 libclang（bindgen），否则构建失败。

## 差分测试抓 bug 的实测效果

`jacobi_bad.cpp`（把 `u[i-1]+u[i+1]` 写成 `u[i]+u[i+2]`）：
- `-O2` 编译：不崩、"正常"退出，但结果 509.43 vs 635.96，差分测试报 MISMATCH。
- `-D_GLIBCXX_DEBUG` 编译：直接报 "subscript container with out-of-bounds index 252"。

AI 生成的 C++/Rust 最典型的失败模式就是：**能编译、能运行、结果是错的**。所以顺序永远是：先搭差分 harness，再开始翻译。
