program simple_fft992

use, intrinsic :: iso_fortran_env, only : int32, real64
use fft992_mod, only : fft992, set99b
implicit none

integer(kind=int32), parameter :: n = 12
integer(kind=int32), parameter :: nfreq = n / 2 + 1
integer(kind=int32), parameter :: direction_r2c = -1
integer(kind=int32), parameter :: direction_c2r = 1
real(kind=real64),   parameter :: scale_r2c = 1.0_real64 / real(n, real64)
real(kind=real64),   parameter :: scale_c2r = 1.0_real64
real(kind=real64),   parameter :: tolerance = 500.0_real64 * epsilon(1.0_real64)
integer(kind=int32), parameter :: lot = 1

real(kind=real64) :: signal(n)
real(kind=real64) :: work(nfreq * 2)
real(kind=real64) :: max_error
real(kind=real64) :: trigs(n)
integer(kind=int32) :: ifax(10)
integer(kind=int32) :: inc, jump, i
logical :: lusefft992

! Initialize the input real signal
do i = 1, n
  signal(i) = real(i, kind=real64)
end do

! Copy the signal into an oversized work array
work = 0.0_real64
work(1:n) = signal(:)

! Initialize the FFT992 trigonometric tables for size N.
call set99b(trigs, ifax, n, lusefft992)
if (.not. lusefft992) stop "N not supported by fft992 (outside factorization 2,3,5)"

inc  = 1_int32 ! stride = 1 for contiguous signal data
jump = 1_int32 ! not used for single FFT.

call fft992(work, trigs, ifax, inc, jump, n, lot, direction_r2c, scale_r2c)
call fft992(work, trigs, ifax, inc, jump, n, lot, direction_c2r, scale_c2r)

max_error = maxval(abs(work(1:n) - signal(:)))
if (max_error > tolerance) then
  write(*,'(a,1x,es12.4)') 'simple_fft992 validation failed; max error =', max_error
  stop 1
end if

write(*,'(a,1x,es12.4)') 'simple_fft992 validation passed; max error =', max_error

end program simple_fft992