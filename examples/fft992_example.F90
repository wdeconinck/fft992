program ectrans_algor_fft_example

use iso_fortran_env, only : jpim => int32, jprb => real64

use bluestein_mod, only : fftb_type, bluestein_init, bluestein_fft, bluestein_release, bluestein_plan_fft
use fft992_mod, only : fft992, set99b
implicit none

integer(kind=jpim), parameter :: n_fft992 = 12
integer(kind=jpim), parameter :: n_bluestein = 7
integer(kind=jpim), parameter :: batch = 3
integer(kind=jpim), parameter :: layout_field_contiguous = 1
integer(kind=jpim), parameter :: layout_fft_contiguous = 2
real(kind=jprb), parameter :: tolerance = 500._jprb*epsilon(1._jprb)
real(kind=jprb), parameter :: spectrum_tolerance = 2000._jprb*epsilon(1._jprb)

call demo_fft992_batch(n_fft992, batch, layout_field_contiguous)
call demo_fft992_batch(n_fft992, batch, layout_fft_contiguous)
call demo_bluestein_batch(n_bluestein, batch, layout_field_contiguous)
call demo_bluestein_batch(n_bluestein, batch, layout_fft_contiguous)

contains

integer(kind=jpim) function signal_max_harmonic(n)

integer(kind=jpim), intent(in) :: n

signal_max_harmonic = max(1_jpim, min(n/2_jpim, 4_jpim))

end function signal_max_harmonic


real(kind=jprb) function signal_sine_weight(field0, harmonic)

integer(kind=jpim), intent(in) :: field0, harmonic

signal_sine_weight = (0.7_jprb + 0.1_jprb*real(field0, jprb)) / &
                     real(harmonic, jprb)

end function signal_sine_weight


real(kind=jprb) function signal_cosine_weight(field0, harmonic)

integer(kind=jpim), intent(in) :: field0, harmonic
integer(kind=jpim) :: phase_index

phase_index = modulo(field0 + harmonic, 3_jpim)
signal_cosine_weight = (0.2_jprb + 0.05_jprb*real(phase_index, jprb)) / &
                       real(harmonic + 1_jpim, jprb)

end function signal_cosine_weight


real(kind=jprb) function packed_value(values, field, point, layout)

real(kind=jprb), intent(in) :: values(:,:)
integer(kind=jpim), intent(in) :: field, point, layout

select case (layout)
case (layout_field_contiguous)
  packed_value = values(field, point)
case (layout_fft_contiguous)
  packed_value = values(point, field)
case default
  write(*,'(a,i0)') 'Unsupported layout mode in packed_value: ', layout
  stop 1
end select

end function packed_value


real(kind=jprb) function max_normalized_spectrum_error(values, n, lot, layout)

real(kind=jprb), intent(in) :: values(:,:)
integer(kind=jpim), intent(in) :: n, lot, layout

integer(kind=jpim) :: field, field0, freq, nfreq, max_harmonic
real(kind=jprb) :: got_real, got_imag, expected_real, expected_imag

nfreq = n/2_jpim + 1_jpim
max_harmonic = signal_max_harmonic(n)
max_normalized_spectrum_error = 0._jprb

do field = 1, lot
  field0 = field - 1_jpim
  do freq = 0, nfreq - 1
    got_real = packed_value(values, field, 2*freq + 1, layout)
    got_imag = packed_value(values, field, 2*freq + 2, layout)

    expected_real = 0._jprb
    expected_imag = 0._jprb
    if (freq >= 1 .and. freq <= max_harmonic) then
      expected_real = 0.5_jprb*signal_cosine_weight(field0, freq)
      expected_imag = -0.5_jprb*signal_sine_weight(field0, freq)
    endif

    max_normalized_spectrum_error = max(max_normalized_spectrum_error, &
                                        abs(got_real - expected_real))
    max_normalized_spectrum_error = max(max_normalized_spectrum_error, &
                                        abs(got_imag - expected_imag))
  enddo
enddo

end function max_normalized_spectrum_error


subroutine demo_fft992_batch(n, lot, layout)

integer(kind=jpim), intent(in) :: n, lot, layout

real(kind=jprb) :: trigs(n)
integer(kind=jpim) :: ifax(10)
logical :: lusefft992
real(kind=jprb), allocatable :: work(:,:)
real(kind=jprb), allocatable :: original(:,:)
real(kind=jprb) :: max_error
real(kind=jprb) :: spectrum_error
integer(kind=jpim) :: inc, jump

call set99b(trigs, ifax, n, lusefft992)
if (.not. lusefft992) then
  write(*,'(a,i0,a)') 'FFT992 does not support N=', n, ' in this configuration.'
  stop 1
endif

call get_fft992_layout(layout, n + 2, lot, inc, jump)

select case (layout)
case (layout_field_contiguous)
  allocate(work(lot, n + 2))
  allocate(original(lot, n))
case (layout_fft_contiguous)
  allocate(work(n + 2, lot))
  allocate(original(n, lot))
case default
  write(*,'(a,i0)') 'Unsupported FFT992 layout mode: ', layout
  stop 1
end select

call fill_fft992_batch_signal(original, n, lot, layout)
work(:,:) = 0._jprb

select case (layout)
case (layout_field_contiguous)
  work(:,1:n) = original(:,:)
case (layout_fft_contiguous)
  work(1:n,:) = original(:,:)
end select

write(*,'(a)') 'FFT992 example'
write(*,'(a)') '  Layout mode: '//trim(fft992_layout_name(layout))
write(*,'(a,i0,a,i0,a)') '  Supported length N=', n, ', LOT=', lot, ' batched vectors.'
write(*,'(a)') '  '//trim(fft992_layout_description(layout))

call print_fft_field('  Packed gridpoint coefficients for field 1:', original, n, layout)
call fft992(work, trigs, ifax, inc, jump, n, lot, -1_jpim, 1.0_jprb/real(n, kind=jprb))
spectrum_error = max_normalized_spectrum_error(work, n, lot, layout)
write(*,'(a,1x,es12.4)') '  Max normalized spectrum error:', spectrum_error
if (spectrum_error > spectrum_tolerance) then
  write(*,'(a)') '  FFT992 spectrum check failed.'
  stop 1
endif
call print_fft_field('  Packed spectral coefficients for field 1:', work, n + 2, layout)

call fft992(work, trigs, ifax, inc, jump, n, lot, 1_jpim, 1.0_jprb)
select case (layout)
case (layout_field_contiguous)
  max_error = maxval(abs(work(:,1:n) - original(:,:)))
case (layout_fft_contiguous)
  max_error = maxval(abs(work(1:n,:) - original(:,:)))
end select

write(*,'(a,1x,es12.4)') '  Max round-trip error:', max_error
if (max_error > tolerance) then
  write(*,'(a)') '  FFT992 round-trip check failed.'
  stop 1
endif

deallocate(original)
deallocate(work)

end subroutine demo_fft992_batch


subroutine get_fft992_layout(layout, npoints, lot, inc, jump)

integer(kind=jpim), intent(in) :: layout, npoints, lot
integer(kind=jpim), intent(out) :: inc, jump

select case (layout)
case (layout_field_contiguous)
  inc = lot
  jump = 1_jpim
case (layout_fft_contiguous)
  inc = 1_jpim
  jump = npoints
case default
  write(*,'(a,i0)') 'Unsupported FFT992 layout mode: ', layout
  stop 1
end select

end subroutine get_fft992_layout


subroutine fill_fft992_batch_signal(values, n, lot, layout)

real(kind=jprb), intent(out) :: values(:,:)
integer(kind=jpim), intent(in) :: n, lot, layout

integer(kind=jpim) :: jf, jj, field0, harmonic, max_harmonic
real(kind=jprb) :: angle, harmonic_angle, pi, value

pi = acos(-1._jprb)
max_harmonic = signal_max_harmonic(n)

do jf = 1, lot
  field0 = jf - 1_jpim
  do jj = 1, n
    angle = 2._jprb*pi*real(jj - 1, jprb)/real(n, jprb)
    value = 0._jprb
    do harmonic = 1, max_harmonic
      harmonic_angle = real(harmonic, jprb)*angle
      value = value + signal_sine_weight(field0, harmonic)*sin(harmonic_angle)
      value = value + signal_cosine_weight(field0, harmonic)*cos(harmonic_angle)
    enddo
    select case (layout)
    case (layout_field_contiguous)
      values(jf,jj) = value
    case (layout_fft_contiguous)
      values(jj,jf) = value
    end select
  enddo
enddo

end subroutine fill_fft992_batch_signal


subroutine print_fft_field(title, values, klen, layout)

character(len=*), intent(in) :: title
real(kind=jprb), intent(in) :: values(:,:)
integer(kind=jpim), intent(in) :: klen, layout

select case (layout)
case (layout_field_contiguous)
  call print_vector(title, values(1,1:klen))
case (layout_fft_contiguous)
  call print_vector(title, values(1:klen,1))
end select

end subroutine print_fft_field


character(len=32) function fft992_layout_name(layout)

integer(kind=jpim), intent(in) :: layout

select case (layout)
case (layout_field_contiguous)
  fft992_layout_name = 'lot-contiguous'
case (layout_fft_contiguous)
  fft992_layout_name = 'fft-contiguous'
case default
  fft992_layout_name = 'unknown'
end select

end function fft992_layout_name


character(len=96) function fft992_layout_description(layout)

integer(kind=jpim), intent(in) :: layout

select case (layout)
case (layout_field_contiguous)
  fft992_layout_description = 'WORK(field,point), so INC=LOT and JUMP=1.'
case (layout_fft_contiguous)
  fft992_layout_description = 'WORK(point,field), so INC=1 and JUMP=N+2.'
case default
  fft992_layout_description = 'Unknown FFT992 layout.'
end select

end function fft992_layout_description


subroutine demo_bluestein_batch(n, klot, layout)

integer(kind=jpim), intent(in) :: n, klot, layout

type(fftb_type) :: tb
integer(kind=jpim) :: iclen, inc, jump
real(kind=jprb), allocatable :: work(:,:)
real(kind=jprb), allocatable :: original(:,:)
real(kind=jprb) :: max_error
real(kind=jprb) :: spectrum_error
integer(kind=jpim) :: nffts(5)

nffts = n
call bluestein_init(tb,jprb,nffts)

iclen = (n/2 + 1)*2
call get_fft992_layout(layout, iclen, klot, inc, jump)

select case (layout)
case (layout_field_contiguous)
  allocate(work(klot, iclen))
  allocate(original(klot, n))
case (layout_fft_contiguous)
  allocate(work(iclen, klot))
  allocate(original(n, klot))
case default
  write(*,'(a,i0)') 'Unsupported Bluestein layout mode: ', layout
  stop 1
end select

call fill_fft992_batch_signal(original, n, klot, layout)
work(:,:) = 0._jprb

select case (layout)
case (layout_field_contiguous)
  work(:,1:n) = original(:,:)
case (layout_fft_contiguous)
  work(1:n,:) = original(:,:)
end select

write(*,'(a)') 'BLUESTEIN_FFT example'
write(*,'(a)') '  Layout mode: '//trim(fft992_layout_name(layout))
write(*,'(a,i0,a,i0,a)') '  Arbitrary length N=', n, ', KLOT=', klot, ' batched vectors.'
select case (layout)
case (layout_field_contiguous)
  write(*,'(a)') '  Layout: WORK(field,packed_point) with packed spectral size ICLEN=(N/2+1)*2.'
case (layout_fft_contiguous)
  write(*,'(a)') '  Layout: WORK(packed_point,field) with packed spectral size ICLEN=(N/2+1)*2.'
end select

call print_fft_field('  Packed gridpoint coefficients for field 1:', original, n, layout)
call bluestein_plan_fft(tb, jprb, n)
call bluestein_fft(tb, n, -1, klot, work, inc=inc, jump=jump)

select case (layout)
case (layout_field_contiguous)
  work(:,1:iclen) = work(:,1:iclen) / real(n, jprb)
case (layout_fft_contiguous)
  work(1:iclen,:) = work(1:iclen,:) / real(n, jprb)
end select

spectrum_error = max_normalized_spectrum_error(work, n, klot, layout)
write(*,'(a,1x,es12.4)') '  Max normalized spectrum error:', spectrum_error
if (spectrum_error > spectrum_tolerance) then
  write(*,'(a)') '  BLUESTEIN_FFT spectrum check failed.'
  stop 1
endif

call print_fft_field('  Packed spectral coefficients for field 1:', work, iclen, layout)

call bluestein_fft(tb, n, 1, klot, work, inc=inc, jump=jump)

select case (layout)
case (layout_field_contiguous)
  max_error = maxval(abs(work(:,1:n) - original(:,:)))
case (layout_fft_contiguous)
  max_error = maxval(abs(work(1:n,:) - original(:,:)))
end select

write(*,'(a,1x,es12.4)') '  Max round-trip error:', max_error
if (max_error > tolerance) then
  write(*,'(a)') '  BLUESTEIN_FFT round-trip check failed.'
  stop 1
endif

call bluestein_release(tb)
deallocate(original)
deallocate(work)

end subroutine demo_bluestein_batch


subroutine print_vector(title, values)

character(len=*), intent(in) :: title
real(kind=jprb), intent(in) :: values(:)
real(kind=jprb) :: v

integer(kind=jpim) :: j

write(*,'(a)') trim(title)
do j = 1, size(values)
  v = values(j)
  if (abs(v) < 1000._jprb*tolerance) v = 0._jprb
  write(*,'(a,i0,a,1x,es18.10)') '    [', j, '] =', v
enddo

end subroutine print_vector

end program ectrans_algor_fft_example
