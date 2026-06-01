program fft992_mod_smoke

use, intrinsic :: iso_fortran_env, only : int32, real64
use fft992_mod, only : set99b
implicit none

real(real64) :: trigs(12)
integer(int32) :: ifax(10)
logical :: lusefft992

call set99b(trigs, ifax, 12_int32, lusefft992)

if (.not. lusefft992) stop 1

end program fft992_mod_smoke