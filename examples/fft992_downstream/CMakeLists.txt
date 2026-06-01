cmake_minimum_required(VERSION 3.20)

project(fft992_downstream LANGUAGES Fortran)

find_package(fft992 CONFIG REQUIRED)

add_executable(fft992_mod_smoke fft992_mod_smoke.F90)
target_link_libraries(fft992_mod_smoke PRIVATE fft992::fft992)

add_executable(bluestein_mod_smoke bluestein_mod_smoke.F90)
target_link_libraries(bluestein_mod_smoke PRIVATE fft992::fft992)
