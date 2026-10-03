# AMRS cmake, modeled on SWAT-MODFLOW3 / swat-model/swatplus (out-of-source builds, Release/Debug,
# gfortran / ifx / ifort). Sources live in src (SWAT), src/MODFLOW (MODFLOW-NWT + RT3D) and src/SALINITY.
###############################################################
if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_BINARY_DIR}")
   message(FATAL_ERROR "'in-source' builds not permitted, e.g. use 'cmake --preset gfortran_release_linux' instead.")
endif()

cmake_minimum_required(VERSION 3.22)

cmake_host_system_information(RESULT os_id   QUERY DISTRIB_ID)
cmake_host_system_information(RESULT os_like QUERY DISTRIB_ID_LIKE)

project(amrs VERSION 1.0 LANGUAGES Fortran)

option(AMRS_FPE_TRAP "Debug builds (gfortran and Intel): trap floating-point errors (invalid, divide by zero, overflow)" ON)

include(CTest)

if(NOT TAG)
    find_package(Git QUIET)
    if(GIT_FOUND)
        execute_process(
          COMMAND ${GIT_EXECUTABLE} describe --tags --always
          WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
          OUTPUT_VARIABLE TAG
          OUTPUT_STRIP_TRAILING_WHITESPACE
          ERROR_QUIET
        )
    endif()
    if(NOT TAG)
        set(TAG "unknown")
    endif()
endif()

# The code base is fixed-form (.f) plus some free-form (.f90). CMake picks the form from the
# extension, so no -ffixed/-ffree flag is needed. Legacy MODFLOW/SWAT code needs -std=legacy.
if(CMAKE_Fortran_COMPILER_ID MATCHES "GNU")
    set(fdialect "-std=legacy -fdec -fallow-argument-mismatch -ffixed-line-length-none -ffree-line-length-none -fbacktrace -finit-local-zero -fno-unsafe-math-optimizations -frounding-math -w")
    set(fdebug   "-g -O0 -fcheck=bounds")
    if(AMRS_FPE_TRAP)
        # stop at floating-point errors; the Docker debug build turns this off (harmless
        # divide-by-zero etc. would stop a model that is otherwise fine)
        string(APPEND fdebug " -ffpe-trap=invalid,zero,overflow")
    endif()
    set(frelease "-O2")
    set(FFC      "gnu")
    string(TOLOWER "${os_id}" os_id_lc)
    string(TOLOWER "${os_like}" os_like_lc)
    # Arch and Fedora do not ship a static libgfortran, so they get a dynamic executable
    if(NOT APPLE AND NOT ("${os_id_lc}" MATCHES "^(arch|fedora)$" OR "${os_like_lc}" MATCHES "arch"))
        link_libraries("-static")
    endif()
elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "IntelLLVM")
    # -fpe3: no floating-point traps (the salt code does invalid operations that the Windows
    # build survived); Debug traps them again with -fpe0 unless AMRS_FPE_TRAP=OFF
    set(fdialect "-fpp -extend-source -fpe3 -traceback")
    set(fdebug   "-warn all,nointerfaces -O0 -check bounds")
    if(AMRS_FPE_TRAP)
        string(APPEND fdebug " -fpe0")
    endif()
    set(frelease "-O2")
    set(FFC      "ifx")
    if(UNIX AND NOT APPLE)
        # Intel runtime (libimf, ...) is not on user machines: link it statically
        link_libraries("-static-intel")
    endif()
elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "Intel")
    set(fdialect "-fpp -extend-source -fpe3 -traceback -diag-disable=10448")
    set(fdebug   "-warn all,nointerfaces -O0 -check bounds")
    if(AMRS_FPE_TRAP)
        string(APPEND fdebug " -fpe0")
    endif()
    set(frelease "-O2")
    set(FFC      "ifort")
    if(UNIX AND NOT APPLE)
        # Intel runtime (libimf, ...) is not on user machines: link it statically
        link_libraries("-static-intel")
    endif()
endif()

string(TOLOWER ${CMAKE_HOST_SYSTEM_PROCESSOR} ARCH)
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(AR "lin_${ARCH}")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(AR "win_${ARCH}")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(AR "mac_${ARCH}")
else()
    set(AR "unknown")
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    set(TY "-Rel")
elseif(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(TY "-Dbg")
else()
    set(TY "")
endif()

set(AMRS_EXE "amrs-${TAG}-${FFC}-${AR}${TY}")

set(CMAKE_Fortran_FLAGS         "${CMAKE_Fortran_FLAGS} ${fdialect}")
set(CMAKE_Fortran_FLAGS_DEBUG   "${fdebug}")
set(CMAKE_Fortran_FLAGS_RELEASE "${frelease}")

file(GLOB sources CONFIGURE_DEPENDS
    src/*.f   src/*.f90
    src/MODFLOW/*.f src/MODFLOW/*.f90
    src/SALINITY/*.f src/SALINITY/*.f90
)

# Version banner (printed at the start of a run): filled in at configure time
string(TIMESTAMP ISO "%Y-%m-%d %H:%M:%S UTC" UTC)
set(AMRS_VERSION "${TAG}")
configure_file("${PROJECT_SOURCE_DIR}/src/version_info.f90.in"
               "${CMAKE_BINARY_DIR}/version_info.f90" @ONLY)
list(APPEND sources "${CMAKE_BINARY_DIR}/version_info.f90")

add_executable(${AMRS_EXE} ${sources})
# mf_openspec.inc is INCLUDEd by several MODFLOW files
target_include_directories(${AMRS_EXE} PRIVATE src/MODFLOW)
set_target_properties(${AMRS_EXE} PROPERTIES
    Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${AMRS_EXE}.dir/mod"
)

install(TARGETS ${AMRS_EXE} RUNTIME DESTINATION bin)

# Smoke test: the executable starts and reports its version (needs no input data)
add_test(NAME version COMMAND ${AMRS_EXE} --version)

# Regression test: runs the dataset and compares with its reference outputs.
# Uses the example model in data/animas (in git, once a reference run is added); pass
# -DAMRS_DATASET=<dir> to use another model.
find_package(Python3 QUIET COMPONENTS Interpreter)
set(AMRS_DATASET "${PROJECT_SOURCE_DIR}/data/animas" CACHE PATH "Model folder for the regression test")
if(Python3_FOUND AND EXISTS "${AMRS_DATASET}/APEXRUN.DAT")
    add_test(NAME dataset_regression
             COMMAND ${Python3_EXECUTABLE} ${PROJECT_SOURCE_DIR}/scripts/regress.py
                     $<TARGET_FILE:${AMRS_EXE}> ${AMRS_DATASET})
endif()

message("-- Build Type   ${CMAKE_BUILD_TYPE}")
message("-- Compiler     ${CMAKE_Fortran_COMPILER} (${CMAKE_Fortran_COMPILER_ID} ${CMAKE_Fortran_COMPILER_VERSION})")
message("-- FFLAGS       ${CMAKE_Fortran_FLAGS}")
message("--  RELEASE     ${CMAKE_Fortran_FLAGS_RELEASE}")
message("--  DEBUG       ${CMAKE_Fortran_FLAGS_DEBUG}")
message("-- Executable   ${AMRS_EXE}")
