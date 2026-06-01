cmake_minimum_required(VERSION 3.20)

project(fft992 LANGUAGES Fortran CXX VERSION 0.0.0 )

include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

set(CMAKE_Fortran_STANDARD 2008)
set(CMAKE_Fortran_STANDARD_REQUIRED ON)

set(FFT992_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake/fft992")
set(FFT992_INSTALL_MODULEDIR "module/fft992")


#### fiat dependency

# If fiat is not found, just compile a dummy fiat
find_package(fiat)

set(FFT992_BUNDLED_FIAT OFF)

if (NOT fiat_FOUND)
  set(FIAT_DUMMY_INSTALL_MODULEDIR "module/fiat_dummy")
  add_library(fiat_dummy
    src/fiat_dummy/yomhook.F90
    src/fiat_dummy/abor1.F90
  )
  set_target_properties(fiat_dummy PROPERTIES
    EXPORT_NAME fiat
    Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/module/fiat_dummy
    POSITION_INDEPENDENT_CODE ON)
  target_include_directories(fiat_dummy PUBLIC
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src/fiat_dummy>
    $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/module/fiat_dummy>
    $<INSTALL_INTERFACE:${FIAT_DUMMY_INSTALL_MODULEDIR}>)
  add_library( fiat ALIAS fiat_dummy )
  set(FFT992_BUNDLED_FIAT ON)
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
  $<INSTALL_INTERFACE:${FFT992_INSTALL_MODULEDIR}>
)


#### Example


add_executable(fft992_example
  examples/fft992_example.F90
)
target_link_libraries(fft992_example PRIVATE fft992)

add_executable(single_fft_fft992
  examples/single_fft_fft992.F90
)
target_link_libraries(single_fft_fft992 PRIVATE fft992)

add_executable(single_fft_bluestein
  examples/single_fft_bluestein.F90
)
target_link_libraries(single_fft_bluestein PRIVATE fft992)

add_executable(batch_fft_fft992_field_contiguous
  examples/batch_fft_fft992_field_contiguous.F90
)
target_link_libraries(batch_fft_fft992_field_contiguous PRIVATE fft992)

add_executable(batch_fft_fft992_fft_contiguous
  examples/batch_fft_fft992_fft_contiguous.F90
)
target_link_libraries(batch_fft_fft992_fft_contiguous PRIVATE fft992)

add_executable(batch_fft_bluestein_field_contiguous
  examples/batch_fft_bluestein_field_contiguous.F90
)
target_link_libraries(batch_fft_bluestein_field_contiguous PRIVATE fft992)

add_executable(batch_fft_bluestein_fft_contiguous
  examples/batch_fft_bluestein_fft_contiguous.F90
)
target_link_libraries(batch_fft_bluestein_fft_contiguous PRIVATE fft992)


#### Testing

include(CTest)
enable_testing()
add_test( fft992_test_fft992_example fft992_example )
add_test( fft992_test_single_fft_fft992 single_fft_fft992 )
add_test( fft992_test_single_fft_bluestein single_fft_bluestein )
add_test( fft992_test_batch_fft_fft992_field_contiguous batch_fft_fft992_field_contiguous )
add_test( fft992_test_batch_fft_fft992_fft_contiguous batch_fft_fft992_fft_contiguous )
add_test( fft992_test_batch_fft_bluestein_field_contiguous batch_fft_bluestein_field_contiguous )
add_test( fft992_test_batch_fft_bluestein_fft_contiguous batch_fft_bluestein_fft_contiguous )
add_test(
  NAME fft992_test_install
  COMMAND ${CMAKE_COMMAND}
    -DFFT992_SOURCE_DIR=${CMAKE_SOURCE_DIR}
    -DFFT992_BUILD_DIR=${CMAKE_BINARY_DIR}
    -DFFT992_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/test/install
    -DFFT992_DOWNSTREAM_BUILD_DIR=${CMAKE_BINARY_DIR}/test/fft992_test_install
    -P ${CMAKE_SOURCE_DIR}/cmake/fft992_validate_downstream.cmake
)

#### Installation

if (FFT992_BUNDLED_FIAT)
  install(TARGETS fiat_dummy
    EXPORT fft992Targets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  )

  install(DIRECTORY ${CMAKE_BINARY_DIR}/module/fiat_dummy/
    DESTINATION ${FIAT_DUMMY_INSTALL_MODULEDIR}
    FILES_MATCHING PATTERN "*"
  )
endif()

install(TARGETS fft992
  EXPORT fft992Targets
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

install(DIRECTORY ${CMAKE_BINARY_DIR}/module/fft992/
  DESTINATION ${FFT992_INSTALL_MODULEDIR}
  FILES_MATCHING PATTERN "*"
)

install(EXPORT fft992Targets
  FILE fft992-targets.cmake
  NAMESPACE fft992::
  DESTINATION ${FFT992_INSTALL_CMAKEDIR}
)

configure_package_config_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/cmake/fft992-config.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/fft992-config.cmake
  INSTALL_DESTINATION ${FFT992_INSTALL_CMAKEDIR}
)

write_basic_package_version_file(
  ${CMAKE_CURRENT_BINARY_DIR}/fft992-config-version.cmake
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY AnyNewerVersion
)

install(FILES
  ${CMAKE_CURRENT_BINARY_DIR}/fft992-config.cmake
  ${CMAKE_CURRENT_BINARY_DIR}/fft992-config-version.cmake
  DESTINATION ${FFT992_INSTALL_CMAKEDIR}
)
