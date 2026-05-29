# fft992

A standalone extraction of FFT-related code from the ECMWF ectrans repository:
<https://github.com/ecmwf-ifs/ectrans>

## Status

This repository is a **work in progress**.

- It is extracted from `ectrans` and being refactored in isolation.
- It **does not yet support installation** as a library/package.

## Current Direction

The code is being adapted around a Fortran module API with generic overloads for:

- single precision (`real32`)
- double precision (`real64`)

Current public entry points are exposed from `fft992_mod` (for example `set99b`, `fft992`, and `fft992_cc`).

## FFT Size Support

- `fft992` supports only specific FFT sizes whose length factorization is composed of 2, 3, 5.
- The Bluestein algorithm can be used for arbitrary FFT lengths, including cases outside the `fft992` factorization set.

## A single FFT transform

For a single transform of length `n`, `signal` contains real data typically stored as:

```fortran
real(real64) :: signal(n)
```

The spectrum consists of `nfreq = n/2 + 1` complex values, typically stored as `2 * nfreq` real values.

```fortran
integer(int32) :: nfreq = n/2+1
real(real64)   :: spectrum(nfreq * 2) ! Last factor 2 because of real and imaginary parts!
```

In `fft992` and Bluestein, a single `work` array is used as an in-place transform.
This `work` array must be appropriately sized to hold both the real input and the packed complex output.
  - `n` even : `nfreq * 2 == n + 2`
  - `n` odd  : `nfreq * 2 == n + 1`

```fortran
real(real64) :: work(nfreq * 2)
```

### FFT992 example

`fft992` requires the transform length to be supported by `set99b`.

See [examples/simple_fft992.F90](examples/simple_fft992.F90).

The scaling factor `SCALE_R2C = 1/n` normalizes the spectrum. Note that other libraries like **FFTW** do **not** apply
this scaling factor. The original implementation of `fft992` did not have this argument.
The `scale` argument has been added to allow for integration in algorithms that use the FFTW convention.

### Bluestein example

Bluestein can be used for arbitrary `n`, including lengths outside the `fft992` factorization support.
Unlike `fft992`, a `scale` argument is not present; and the FFTW convention is used (unnormalized).

See [examples/simple_bluestein.F90](examples/simple_bluestein.F90).


## Lot-Contiguous Memory Layout

In the IFS, the FFT992 and Bluestein paths are using the **lot-contiguous** layout, where the batch index is the first array dimension (contiguous) and the point/frequency index is the second dimension (strided).

For `lot` transforms of length `n`, real data (signal) is typically stored as:

```fortran
real(real64) :: values(lot, n)
```

The complex data (spectrum) is typically stored as:

```fortran
real(real64) :: values(lot, (n/2+1) * 2) ! Last factor 2 because of real and imaginary parts!
```
```

In `fft992` and Bluestein, a single `work` array is used as an in-place transform. This `work` array must be appropriately sized to encapsulate real and complex data.

```fortran
real(real64) :: work(lot, (n/2+1) * 2)
```

The packed coefficients are stored as interleaved real and imaginary parts along the second dimension:

- `work(field, 1)` is the real part of frequency `0`
- `work(field, 2)` is the imaginary part of frequency `0`
- `work(field, 3)` is the real part of frequency `1`
- `work(field, 4)` is the imaginary part of frequency `1`

More generally, for frequency `k`, the packed locations are `2*k+1` for the real part and `2*k+2` for the imaginary part.

For `fft992`, the same buffer is used for both the real input and the packed spectral output, so examples often allocate `(n/2+1) * 2` values per transform.

With `lot = 1`, this degenerates to a single row, but the indexing convention is the same as the batched `work(lot, (n/2+1) * 2)` layout.

## FFT-Contiguous Memory Layout

The other supported organization is the **FFT-contiguous** layout, where the point or frequency index is the first array dimension and the batch index is the second dimension.

For `lot` transforms of length `n`, real input data is typically stored as:

```fortran
real(real64) :: values(n, lot)
```

In that layout, `values(point, field)` accesses one grid-point value for one transform in the batch.

For real-to-complex transforms, the packed spectral output uses the same packed length as in the lot-contiguous case:

```fortran
real(real64) :: work((n/2+1) * 2, lot)
```

The packed coefficients are still stored as interleaved real and imaginary parts, but now along the first dimension:

- `work(1, field)` is the real part of frequency `0`
- `work(2, field)` is the imaginary part of frequency `0`
- `work(3, field)` is the real part of frequency `1`
- `work(4, field)` is the imaginary part of frequency `1`

More generally, for frequency `k`, the packed locations are `2*k+1` for the real part and `2*k+2` for the imaginary part in the first dimension.

For `fft992`, this layout corresponds to `inc = 1` and `jump = (n/2+1) * 2` when using the in-place packed real work array.

This is the layout described in the example program as `WORK(point,field)`, in contrast to the lot-contiguous `WORK(field,point)` organization.

## Roadmap

Planned improvements include:

- C bindings for interoperability with C/C++ and other languages
- an FFTW-compatible API layer to ease migration and integration

## Simple Fortran Example

- FFT992 single-transform example: [examples/simple_fft992.F90](examples/simple_fft992.F90)
- Bluestein single-transform example: [examples/simple_bluestein.F90](examples/simple_bluestein.F90)
- Extended batched/layout example: [examples/fft992_example.F90](examples/fft992_example.F90)