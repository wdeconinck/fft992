program batch_fft_fft992_field_contiguous

use, intrinsic :: iso_fortran_env, only : int32, real64
use fft992_mod, only : fft992, set99b
implicit none

integer(kind=int32), parameter :: n = 12
integer(kind=int32), parameter :: nfreq = n / 2 + 1
integer(kind=int32), parameter :: batch = 3
integer(kind=int32), parameter :: harmonic = 2
integer(kind=int32), parameter :: direction_r2c = -1
integer(kind=int32), parameter :: direction_c2r = 1
real(kind=real64), parameter :: cos_amplitude(batch) = [0.8_real64, 0.6_real64, 0.4_real64]
real(kind=real64), parameter :: sin_amplitude(batch) = [0.6_real64, 0.4_real64, 0.2_real64]
real(kind=real64), parameter :: scale_r2c = 1.0_real64 / real(n, real64)
real(kind=real64), parameter :: scale_c2r = 1.0_real64

real(kind=real64) :: signal(batch, n)
real(kind=real64) :: work(batch, nfreq * 2)
real(kind=real64) :: trigs(n)
integer(kind=int32) :: ifax(10)
integer(kind=int32) :: inc, jump, i, j
logical :: lusefft992

call initialize_signal_harmonic(harmonic, cos_amplitude, sin_amplitude)

work(:,1:n) = signal(:,:)

call set99b(trigs, ifax, n, lusefft992)
if (.not. lusefft992) stop "N not supported by fft992 (outside factorization 2,3,5)"

! batch-contiguous layout: work(field, point)
inc = batch
jump = 1_int32

call fft992(work, trigs, ifax, inc, jump, n, batch, direction_r2c, scale_r2c)
call print_spectrum(work)
call validate_spectrum_harmonic(harmonic, cos_amplitude, sin_amplitude)
call fft992(work, trigs, ifax, inc, jump, n, batch, direction_c2r, scale_c2r)

call validate_roundtrip()

contains

  subroutine initialize_signal_harmonic(harmonic, cos_amplitude, sin_amplitude)
    integer(kind=int32), intent(in) :: harmonic
    real(kind=real64), intent(in) :: cos_amplitude(:), sin_amplitude(:)
    real(kind=real64) :: angle, pi

    pi = acos(-1.0_real64)
    do j = 1, batch
      do i = 1, n
        angle = 2.0_real64 * pi * real(harmonic * (i - 1), kind=real64) / real(n, kind=real64)
        signal(j, i) = cos_amplitude(j) * cos(angle) + sin_amplitude(j) * sin(angle)
      end do
    end do
  end subroutine initialize_signal_harmonic

  subroutine print_spectrum(values)
    real(kind=real64), intent(in) :: values(:,:)
    real(kind=real64), parameter :: print_tolerance = 1000.0_real64 * epsilon(1.0_real64)
    real(kind=real64) :: real_part, imag_part
    integer(kind=int32) :: field, k

    write(*,'(a)') 'batch_fft_fft992_field_contiguous spectra:'
    do field = 1, batch
      write(*,'(a,i0)') '  field=', field
      do k = 0, nfreq - 1
        real_part = values(field, 2 * k + 1)
        imag_part = values(field, 2 * k + 2)
        if (abs(real_part) < print_tolerance) real_part = 0.0_real64
        if (abs(imag_part) < print_tolerance) imag_part = 0.0_real64
        write(*,'(a,i0,a,1x,es12.4,a,1x,es12.4)') '    k=', k, ': real=', real_part, ', imag=', imag_part
      end do
    end do
  end subroutine print_spectrum

  subroutine validate_spectrum_harmonic(harmonic, cos_amplitude, sin_amplitude)
    integer(kind=int32), intent(in) :: harmonic
    real(kind=real64), intent(in) :: cos_amplitude(:), sin_amplitude(:)
    real(kind=real64), parameter :: tolerance = 2000.0_real64 * epsilon(1.0_real64)
    real(kind=real64) :: expected_real, expected_imag, max_error
    integer(kind=int32) :: field, k

    max_error = 0.0_real64
    do field = 1, batch
      do k = 0, nfreq - 1
        expected_real = 0.0_real64
        expected_imag = 0.0_real64
        if (k == harmonic) then
          expected_real = 0.5_real64 * cos_amplitude(field)
          expected_imag = -0.5_real64 * sin_amplitude(field)
        end if

        max_error = max(max_error, abs(work(field, 2 * k + 1) - expected_real))
        max_error = max(max_error, abs(work(field, 2 * k + 2) - expected_imag))
      end do
    end do

    if (max_error > tolerance) then
      write(*,'(a,1x,es12.4)') 'batch_fft_fft992_field_contiguous spectrum validation failed; max error =', max_error
      stop 1
    end if

    write(*,'(a,1x,es12.4)') 'batch_fft_fft992_field_contiguous spectrum validation passed; max error =', max_error
  end subroutine validate_spectrum_harmonic

  subroutine validate_roundtrip
    real(kind=real64), parameter :: tolerance = 500.0_real64 * epsilon(1.0_real64)
    real(kind=real64) :: max_error

    max_error = maxval(abs(work(:,1:n) - signal(:,:)))
    if (max_error > tolerance) then
      write(*,'(a,1x,es12.4)') 'batch_fft_fft992_field_contiguous validation failed; max error =', max_error
      stop 1
    end if

    write(*,'(a,1x,es12.4)') 'batch_fft_fft992_field_contiguous validation passed; max error =', max_error
  end subroutine validate_roundtrip

end program batch_fft_fft992_field_contiguous