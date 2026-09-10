# v0.1.1 optimization measurement

Baseline: 85226422aead02d2cd792bf87c48e129bba71977. Linux CPU reference, g++ -O3 (no fast-math), OpenMP 8 threads. Original attached image 1536×1152, no downscaling. Each kernel warmed once, three timed renders, alternating order, median reported. These are CPU reference results, **not YMM4 GPU benchmarks**.

|Interference preset|Before (s)|After (s)|Speedup|Max float error|Changed 8-bit channels|
|---|---:|---:|---:|---:|---:|
|07 Edge halo|2.664|1.561|1.71×|0.0|0|
|08 Spectral echoes|2.744|1.625|1.69×|0.0|0|
|09 Interference field|3.126|1.826|1.71×|0.0|0|
|10 Neon engraving|2.633|1.563|1.68×|0.0|0|
|11 Electric fog|2.768|1.635|1.69×|0.0|0|
|12 Wave catastrophe|2.851|1.700|1.68×|0.0|0|

All 12 presets had identical CPU output. Strata was not meaningfully accelerated; its original angle expression was restored after the measurement (all 12 presets rechecked for equality). The raw JSON also retains the unhelpful strata timing results rather than suppressing them. Measurements do not include image encoding or I/O, but do include table preparation in the reference wrapper.

The shader now reads 16 direction vectors and 16 wave coefficient vectors from a 560-byte constant buffer, populated and cached by the host. It retains the 256 neighborhood samples, source sample, radial differencing, summation order, edge extension and original alpha. No reduced resolution, sample reduction, or temporal approximation.

GPU MathF/ALU transcendental differences may introduce small rounding differences; GPU visual equivalence and speed require YMM4 hardware validation. CPU bit equality alone does not establish GPU bit equality.

Reproduce from repository root:

```bash
g++ -O3 -std=c++17 -fopenmp -shared -fPIC tests/reference.cpp -o tests/reference.so
g++ -O3 -std=c++17 -fopenmp -shared -fPIC -DROMAN_BASELINE tests/reference.cpp -o tests/baseline.so
OMP_NUM_THREADS=8 python tests/compare_optimization.py input.png measurement.json
```
