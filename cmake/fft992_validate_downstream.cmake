if(NOT DEFINED FFT992_SOURCE_DIR)
  message(FATAL_ERROR "FFT992_SOURCE_DIR is required")
endif()

if(NOT DEFINED FFT992_BUILD_DIR)
  message(FATAL_ERROR "FFT992_BUILD_DIR is required")
endif()

if(NOT DEFINED FFT992_INSTALL_PREFIX)
  message(FATAL_ERROR "FFT992_INSTALL_PREFIX is required")
endif()

if(NOT DEFINED FFT992_DOWNSTREAM_BUILD_DIR)
  message(FATAL_ERROR "FFT992_DOWNSTREAM_BUILD_DIR is required")
endif()

set(FFT992_DOWNSTREAM_SOURCE_DIR "${FFT992_SOURCE_DIR}/examples/fft992_downstream")

function(run_checked)
  set(options)
  set(oneValueArgs WORKING_DIRECTORY)
  set(multiValueArgs COMMAND)
  cmake_parse_arguments(RUN_CHECKED "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  execute_process(
    COMMAND ${RUN_CHECKED_COMMAND}
    WORKING_DIRECTORY "${RUN_CHECKED_WORKING_DIRECTORY}"
    RESULT_VARIABLE run_checked_exit_code
  )

  if(NOT run_checked_exit_code EQUAL 0)
    string(REPLACE ";" " " run_checked_command_string "${RUN_CHECKED_COMMAND}")
    message(FATAL_ERROR "Command failed (${run_checked_exit_code}): ${run_checked_command_string}")
  endif()
endfunction()

file(REMOVE_RECURSE "${FFT992_INSTALL_PREFIX}" "${FFT992_DOWNSTREAM_BUILD_DIR}")

run_checked(
  WORKING_DIRECTORY "${FFT992_BUILD_DIR}"
  COMMAND ${CMAKE_COMMAND} --install "${FFT992_BUILD_DIR}" --prefix "${FFT992_INSTALL_PREFIX}"
)

run_checked(
  WORKING_DIRECTORY "${FFT992_BUILD_DIR}"
  COMMAND ${CMAKE_COMMAND}
    -S "${FFT992_DOWNSTREAM_SOURCE_DIR}"
    -B "${FFT992_DOWNSTREAM_BUILD_DIR}"
    -DCMAKE_PREFIX_PATH:PATH=${FFT992_INSTALL_PREFIX}
)

run_checked(
  WORKING_DIRECTORY "${FFT992_BUILD_DIR}"
  COMMAND ${CMAKE_COMMAND} --build "${FFT992_DOWNSTREAM_BUILD_DIR}" --verbose
)