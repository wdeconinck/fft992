program single_fft_bluestein

use, intrinsic :: iso_fortran_env, only : int32, real64
use bluestein_mod, only : fftb_type, bluestein_init, bluestein_plan_fft, &
                          bluestein_fft, bluestein_release
implicit none

integer(kind=int32), parameter :: n = 7
integer(kind=int32), parameter :: nfreq = n / 2 + 1
integer(kind=int32), parameter :: direction_r2c = -1
integer(kind=int32), parameter :: direction_c2r = 1
real(kind=real64),   parameter :: scale_r2c = 1.0_real64 / real(n, real64)
integer(kind=int32), parameter :: lot = 1

integer(kind=int32) :: i
type(fftb_type) :: tb
real(kind=real64) :: work(nfreq * 2)
real(kind=real64) :: signal(n)

! Initialize a new Bluestein context.
call bluestein_init(tb, real64)

! Plan size N explicitly (OPTIONAL, otherwise it is planned on first use).
call bluestein_plan_fft(tb, real64, n)

call initialize_signal_harmonic(harmonic=2, cos_amplitude=0.8_real64, sin_amplitude=0.6_real64)

work(1:n) = signal(:)

call bluestein_fft(tb, n, direction_r2c, lot, work)
! Bluestein follows an unnormalized convention; apply normalization explicitly.
work(:) = work(:) * scale_r2c

call print_spectrum(work)
call validate_spectrum_harmonic(harmonic=2, cos_amplitude=0.8_real64, sin_amplitude= 0.6_real64)

call bluestein_fft(tb, n, direction_c2r, lot, work)

call validate_roundtrip()

call bluestein_release(tb)

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

    write(*,'(a)') 'single_fft_bluestein spectrum:'
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
        write(*,'(a,1x,es12.4)') 'single_fft_bluestein spectrum validation failed; max error =', max_error
        stop 1
    end if

    write(*,'(a,1x,es12.4)') 'single_fft_bluestein spectrum validation passed; max error =', max_error
  end subroutine validate_spectrum_harmonic

  subroutine validate_roundtrip
    real(kind=real64), parameter :: tolerance = 500.0_real64 * epsilon(1.0_real64)
    real(kind=real64) :: max_error

    max_error = maxval(abs(work(1:n) - signal(:)))
    if (max_error > tolerance) then
        write(*,'(a,1x,es12.4)') 'single_fft_bluestein validation failed; max error =', max_error
        stop 1
    end if

    write(*,'(a,1x,es12.4)') 'single_fft_bluestein validation passed; max error =', max_error
  end subroutine validate_roundtrip

end program single_fft_bluestein