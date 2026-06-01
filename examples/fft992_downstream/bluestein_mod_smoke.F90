program bluestein_mod_smoke

use, intrinsic :: iso_fortran_env, only : real64
use bluestein_mod, only : fftb_type, bluestein_init, bluestein_release
implicit none

type(fftb_type) :: tb

call bluestein_init(tb, real64)
call bluestein_release(tb)

end program bluestein_mod_smoke