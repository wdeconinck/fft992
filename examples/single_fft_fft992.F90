program single_fft_fft992

use, intrinsic :: iso_fortran_env, only : int32, real64
use fft992_mod, only : fft992, set99b
implicit none

integer(kind=int32), parameter :: n = 12
integer(kind=int32), parameter :: nfreq = n / 2 + 1
integer(kind=int32), parameter :: direction_r2c = -1
integer(kind=int32), parameter :: direction_c2r = 1
real(kind=real64),   parameter :: scale_r2c = 1.0_real64 / real(n, real64)
real(kind=real64),   parameter :: scale_c2r = 1.0_real64
integer(kind=int32), parameter :: lot = 1

real(kind=real64) :: signal(n)
real(kind=real64) :: work(nfreq * 2)
real(kind=real64) :: trigs(n)
integer(kind=int32) :: ifax(10)
integer(kind=int32) :: inc, jump, i
logical :: lusefft992

call initialize_signal_harmonic(harmonic=2, cos_amplitude=0.8_real64, sin_amplitude=0.6_real64)

! Copy the signal into an oversized work array
work = 0.0_real64
work(1:n) = signal(:)

! Initialize the FFT992 trigonometric tables for size N.
call set99b(trigs, ifax, n, lusefft992)
if (.not. lusefft992) stop "N not supported by fft992 (outside factorization 2,3,5)"

inc  = 1_int32 ! stride = 1 for contiguous signal data
jump = 1_int32 ! not used for single FFT.

call fft992(work, trigs, ifax, inc, jump, n, lot, direction_r2c, scale_r2c)
call print_spectrum(work)
call validate_spectrum_harmonic(harmonic=2, cos_amplitude=0.8_real64, sin_amplitude=0.6_real64)
call fft992(work, trigs, ifax, inc, jump, n, lot, direction_c2r, scale_c2r)

call validate_roundtrip()

contains

  subroutine initialize_signal_harmonic(harmonic, cos_amplitude, sin_amplitude)
    integer(kind=int32), intent(in) :: harmonic
    real(kind=real64), intent(in) :: cos_amplitude, sin_amplitude
    real(kind=real64) :: angle, pi

    pi = acos(-1.0_real64)
    do i = 1, n
      angle = 2.0_real64 * pi * real(harmonic * (i - 1), kind=real64) / real(n, kind=real64)
      signal(i) = cos_amplitude * cos(angle) + sin_amplitude * sin(angle)
    end do
  end subroutine initialize_signal_harmonic

  subroutine print_spectrum(values)
    real(kind=real64), intent(in) :: values(:)
    real(kind=real64), parameter :: print_tolerance = 1000.0_real64 * epsilon(1.0_real64)
    real(kind=real64) :: real_part, imag_part
    integer(kind=int32) :: k

    write(*,'(a)') 'single_fft_fft992 spectrum:'
    do k = 0, nfreq - 1
      real_part = values(2 * k + 1)
      imag_part = values(2 * k + 2)
      if (abs(real_part) < print_tolerance) real_part = 0.0_real64
      if (abs(imag_part) < print_tolerance) imag_part = 0.0_real64
      write(*,'(a,i0,a,1x,es12.4,a,1x,es12.4)') '  k=', k, ': real=', &
        real_part, ', imag=', imag_part
    end do
  end subroutine print_spectrum

  subroutine validate_spectrum_harmonic(harmonic, cos_amplitude, sin_amplitude)
    integer(kind=int32), intent(in) :: harmonic
    real(kind=real64), intent(in) :: cos_amplitude, sin_amplitude
    real(kind=real64), parameter :: tolerance = 2000.0_real64 * epsilon(1.0_real64)
    real(kind=real64) :: expected_real, expected_imag, max_error
    integer(kind=int32) :: k

    max_error = 0.0_real64
    do k = 0, nfreq - 1
      expected_real = 0.0_real64
      expected_imag = 0.0_real64
      if (k == harmonic) then
        expected_real = 0.5_real64 * cos_amplitude
        expected_imag = -0.5_real64 * sin_amplitude
      end if

      max_error = max(max_error, abs(work(2 * k + 1) - expected_real))
      max_error = max(max_error, abs(work(2 * k + 2) - expected_imag))
    end do

    if (max_error > tolerance) then
      write(*,'(a,1x,es12.4)') 'single_fft_fft992 spectrum validation failed; max error =', max_error
      stop 1
    end if

    write(*,'(a,1x,es12.4)') 'single_fft_fft992 spectrum validation passed; max error =', max_error
  end subroutine validate_spectrum_harmonic

  subroutine validate_roundtrip
    real(kind=real64), parameter :: tolerance = 500.0_real64 * epsilon(1.0_real64)
    real(kind=real64) :: max_error

    max_error = maxval(abs(work(1:n) - signal(:)))
    if (max_error > tolerance) then
      write(*,'(a,1x,es12.4)') 'single_fft_fft992 validation failed; max error =', max_error
      stop 1
    end if

    write(*,'(a,1x,es12.4)') 'single_fft_fft992 validation passed; max error =', max_error
  end subroutine validate_roundtrip

end program single_fft_fft992