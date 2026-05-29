module yomhook

use iso_fortran_env, only : real64

implicit none

logical, parameter :: lhook = .false.
integer, parameter :: jphook = real64

contains

subroutine dr_hook(cdname, kmode, phandle)

character(len=*), intent(in) :: cdname
integer, intent(in) :: kmode
real(kind=jphook), intent(inout) :: phandle

phandle = 0.0_jphook

end subroutine dr_hook

end module yomhook