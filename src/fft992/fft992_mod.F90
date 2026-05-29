module fft992_mod

use, intrinsic :: iso_fortran_env, only : int32, real32, real64
implicit none
private

public :: set99b, fft992, fft992_cc

interface
  module subroutine set99b_sp(trigs, ifax, n, ldusefft992)
    implicit none
    integer(kind=int32), intent(in) :: n
    real(kind=real32), intent(out) :: trigs(n)
    integer(kind=int32), intent(out) :: ifax(:)
    logical, intent(out) :: ldusefft992
  end subroutine set99b_sp

  module subroutine set99b_dp(trigs, ifax, n, ldusefft992)
    implicit none
    integer(kind=int32), intent(in) :: n
    real(kind=real64), intent(out) :: trigs(n)
    integer(kind=int32), intent(out) :: ifax(:)
    logical, intent(out) :: ldusefft992
  end subroutine set99b_dp

  module subroutine fft992_cc_sp_1d(a, kinc, kjump, kn, klot, ksign)
    implicit none
    real(kind=real32), intent(inout) :: a(:)
    integer(kind=int32), intent(in) :: kinc, kjump, kn, klot, ksign
  end subroutine fft992_cc_sp_1d

  module subroutine fft992_cc_sp_2d(a, kinc, kjump, kn, klot, ksign)
    implicit none
    real(kind=real32), intent(inout), contiguous, target :: a(:,:)
    integer(kind=int32), intent(in) :: kinc, kjump, kn, klot, ksign
  end subroutine fft992_cc_sp_2d

  module subroutine fft992_cc_dp_1d(a, kinc, kjump, kn, klot, ksign)
    implicit none
    real(kind=real64), intent(inout) :: a(:)
    integer(kind=int32), intent(in) :: kinc, kjump, kn, klot, ksign
  end subroutine fft992_cc_dp_1d

  module subroutine fft992_cc_dp_2d(a, kinc, kjump, kn, klot, ksign)
    implicit none
    real(kind=real64), intent(inout), contiguous, target :: a(:,:)
    integer(kind=int32), intent(in) :: kinc, kjump, kn, klot, ksign
  end subroutine fft992_cc_dp_2d

  module subroutine fft992_sp_1d(a, trigs, ifax, inc, jump, n, lot, isign, pscale)
    implicit none
    integer(kind=int32), intent(in) :: inc, jump, n, lot, isign
    real(kind=real32), intent(in) :: pscale
    real(kind=real32), intent(inout) :: a(:)
    real(kind=real32), intent(in) :: trigs(n)
    integer(kind=int32), intent(in) :: ifax(:)
  end subroutine fft992_sp_1d

  module subroutine fft992_sp_2d(a, trigs, ifax, inc, jump, n, lot, isign, pscale)
    implicit none
    integer(kind=int32), intent(in) :: inc, jump, n, lot, isign
    real(kind=real32), intent(in) :: pscale
    real(kind=real32), intent(inout), contiguous, target :: a(:,:)
    real(kind=real32), intent(in) :: trigs(n)
    integer(kind=int32), intent(in) :: ifax(:)
  end subroutine fft992_sp_2d

  module subroutine fft992_dp_1d(a, trigs, ifax, inc, jump, n, lot, isign, pscale)
    implicit none
    integer(kind=int32), intent(in) :: inc, jump, n, lot, isign
    real(kind=real64), intent(in) :: pscale
    real(kind=real64), intent(inout) :: a(:)
    real(kind=real64), intent(in) :: trigs(n)
    integer(kind=int32), intent(in) :: ifax(:)
  end subroutine fft992_dp_1d

  module subroutine fft992_dp_2d(a, trigs, ifax, inc, jump, n, lot, isign, pscale)
    implicit none
    integer(kind=int32), intent(in) :: inc, jump, n, lot, isign
    real(kind=real64), intent(in) :: pscale
    real(kind=real64), intent(inout), contiguous, target :: a(:,:)
    real(kind=real64), intent(in) :: trigs(n)
    integer(kind=int32), intent(in) :: ifax(:)
  end subroutine fft992_dp_2d
end interface

interface set99b
  module procedure set99b_sp
  module procedure set99b_dp
end interface

interface fft992
  module procedure fft992_sp_1d
  module procedure fft992_sp_2d
  module procedure fft992_dp_1d
  module procedure fft992_dp_2d
end interface

interface fft992_cc
  module procedure fft992_cc_sp_1d
  module procedure fft992_cc_sp_2d
  module procedure fft992_cc_dp_1d
  module procedure fft992_cc_dp_2d
end interface

interface fft992_sp
  module procedure fft992_sp_1d
  module procedure fft992_sp_2d
end interface

interface fft992_dp
  module procedure fft992_dp_1d
  module procedure fft992_dp_2d
end interface

interface fft992_cc_sp
  module procedure fft992_cc_sp_1d
  module procedure fft992_cc_sp_2d
end interface

interface fft992_cc_dp
  module procedure fft992_cc_dp_1d
  module procedure fft992_cc_dp_2d
end interface

end module fft992_mod
