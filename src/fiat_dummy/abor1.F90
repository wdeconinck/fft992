subroutine abor1(cdtext)

use, intrinsic :: iso_fortran_env, only : error_unit

implicit none

character(len=*), intent(in) :: cdtext

write(error_unit,'(a)') trim(cdtext)
error stop 1

end subroutine abor1
