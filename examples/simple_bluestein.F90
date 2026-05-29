program simple_bluestein

use, intrinsic :: iso_fortran_env, only : int32, real64
use bluestein_mod, only : fftb_type, bluestein_init, bluestein_plan_fft, &
                          bluestein_fft, bluestein_release
implicit none

integer(kind=int32), parameter :: n = 7
integer(kind=int32), parameter :: nfreq = n / 2 + 1
integer(kind=int32), parameter :: direction_r2c = -1
integer(kind=int32), parameter :: direction_c2r = 1
real(kind=real64), parameter :: scale_r2c = 1.0_real64 / real(n, real64)
real(kind=real64), parameter :: tolerance = 500.0_real64 * epsilon(1.0_real64)
integer(kind=int32), parameter :: lot = 1

integer(kind=int32) :: i
type(fftb_type) :: tb
real(kind=real64) :: work(nfreq * 2)
real(kind=real64) :: signal(n)
real(kind=real64) :: max_error

! Initialize a new Bluestein context.
call bluestein_init(tb, real64)

! Plan size N explicitly (otherwise it is planned on first use).
call bluestein_plan_fft(tb, real64, n)

do i = 1, n
  signal(i) = real(i, kind=real64)
end do

work = 0.0_real64
work(1:n) = signal(:)

call bluestein_fft(tb, n, direction_r2c, lot, work)

! Bluestein follows an unnormalized convention; apply normalization explicitly.
work(:) = work(:) * scale_r2c
call bluestein_fft(tb, n, direction_c2r, lot, work)

max_error = maxval(abs(work(1:n) - signal(:)))
if (max_error > tolerance) then
  write(*,'(a,1x,es12.4)') 'simple_bluestein validation failed; max error =', max_error
  stop 1
end if

write(*,'(a,1x,es12.4)') 'simple_bluestein validation passed; max error =', max_error

call bluestein_release(tb)

end program simple_bluestein