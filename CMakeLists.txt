cmake_minimum_required(VERSION 3.20)

project(fft992 LANGUAGES Fortran CXX VERSION 0.0.0 )

set(CMAKE_Fortran_STANDARD 2008)
set(CMAKE_Fortran_STANDARD_REQUIRED ON)
set(CMAKE_Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/mod)


#### fiat dependency

# If fiat is not found, just compile a dummy fiat
find_package(fiat)

if (NOT fiat_FOUND)
  add_library(fiat_dummy
    src/fiat_dummy/yomhook.F90
    src/fiat_dummy/abor1.F90
  )
  set_target_properties(fiat_dummy PROPERTIES
    Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/module/fiat_dummy
    POSITION_INDEPENDENT_CODE ON)
  target_include_directories(fiat_dummy PUBLIC
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src/fiat_dummy>
    $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/module/fiat_dummy>)
  add_library( fiat ALIAS fiat_dummy )
endif()

#### fft992 library

add_library(fft992 STATIC
  src/fft992/fft992_mod.F90
  src/fft992/bluestein_mod.F90
  src/fft992/internal/fft992_dp_smod.F90
  src/fft992/internal/fft992_sp_smod.F90
  src/fft992/internal/bluestein_sp_smod.F90
  src/fft992/internal/bluestein_dp_smod.F90
)
target_link_libraries(fft992 PUBLIC fiat)
set_target_properties(fft992 PROPERTIES
  Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/module/fft992
  POSITION_INDEPENDENT_CODE ON
)

target_include_directories(fft992 PUBLIC
   $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src/fft992/internal>
   $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/module/fft992>
)


#### Example


add_executable(fft992_example
  examples/fft992_example.F90
)
target_link_libraries(fft992_example PRIVATE fft992)

add_executable(simple_fft992
  examples/simple_fft992.F90
)
target_link_libraries(simple_fft992 PRIVATE fft992)

add_executable(simple_bluestein
  examples/simple_bluestein.F90
)
target_link_libraries(simple_bluestein PRIVATE fft992)


#### Testing

include(CTest)
enable_testing()
add_test( test_fft992_example fft992_example )
add_test( test_simple_fft992 simple_fft992 )
add_test( test_simple_bluestein simple_bluestein )

# Prohibit installation if fiat was not found
install(CODE "
  if(NOT \"\${fiat_FOUND}\")
    message(FATAL_ERROR \"Installation aborted: fiat must be a third-party dependency, and this project was built with a fiat_dummy for development/testing\")
  endif()
")
