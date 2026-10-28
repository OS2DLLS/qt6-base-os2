# CMake toolchain for building Qt 6.2.x for OS/2 on a Linux host.
#
# Usage:
#   OS2EMX_PREFIX=/data/os2emx \
#   QT_HOST_PATH=$PWD/../qt6-host-install \
#   cmake -S . -B build-os2 \
#     -DCMAKE_TOOLCHAIN_FILE=cmake/qt6-os2.cmake
#
# The cross-os2emx installation supplies the i686-pc-os2-emx compiler,
# sysroot, OMF archiver, and emxomfld linker.

set(CMAKE_SYSTEM_NAME OS2)
set(CMAKE_SYSTEM_PROCESSOR i686)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

if(DEFINED OS2EMX_PREFIX AND NOT "${OS2EMX_PREFIX}" STREQUAL "")
    file(REAL_PATH "${OS2EMX_PREFIX}" OS2EMX_PREFIX)
elseif(DEFINED ENV{OS2EMX_PREFIX} AND NOT "$ENV{OS2EMX_PREFIX}" STREQUAL "")
    file(REAL_PATH "$ENV{OS2EMX_PREFIX}" OS2EMX_PREFIX)
else()
    set(OS2EMX_PREFIX "/data/os2emx")
endif()

if(NOT IS_DIRECTORY "${OS2EMX_PREFIX}")
    message(FATAL_ERROR
        "OS2EMX_PREFIX does not exist: ${OS2EMX_PREFIX}\n"
        "Build and install cross-os2emx first, or set OS2EMX_PREFIX.")
endif()

if(DEFINED ENV{QT_HOST_PATH} AND NOT "$ENV{QT_HOST_PATH}" STREQUAL "")
    set(QT_HOST_PATH "$ENV{QT_HOST_PATH}" CACHE PATH
        "Native Qt host tools used while building Qt for OS/2" FORCE)
endif()
if(DEFINED QT_HOST_PATH AND NOT QT_HOST_PATH STREQUAL "" AND
   NOT IS_DIRECTORY "${QT_HOST_PATH}")
    message(FATAL_ERROR "QT_HOST_PATH does not exist: ${QT_HOST_PATH}")
endif()
set(CMAKE_TRY_COMPILE_PLATFORM_VARIABLES QT_HOST_PATH OS2EMX_PREFIX)

set(OS2EMX_TARGET "i686-pc-os2-emx")
set(CMAKE_C_COMPILER "${CMAKE_CURRENT_LIST_DIR}/os2-gcc")
set(CMAKE_CXX_COMPILER "${CMAKE_CURRENT_LIST_DIR}/os2-g++")
# Use the verified OMF archiver from the active cross-build environment.  It
# is a host tool that writes OMF archives; do not replace it with GNU ar.
if(DEFINED ENV{OS2EMX_AR} AND NOT "$ENV{OS2EMX_AR}" STREQUAL "")
    set(OS2EMX_AR "$ENV{OS2EMX_AR}")
else()
    set(OS2EMX_AR "${OS2EMX_PREFIX}/${OS2EMX_TARGET}/bin/emxomfar")
endif()
set(CMAKE_AR "${OS2EMX_AR}" CACHE FILEPATH "Host OMF archiver" FORCE)
set(CMAKE_RANLIB ":" CACHE STRING "No-op ranlib for OMF archives" FORCE)
set(CMAKE_STRIP "${OS2EMX_PREFIX}/bin/${OS2EMX_TARGET}-strip")
set(CMAKE_C_COMPILER_AR "${CMAKE_AR}" CACHE FILEPATH "C archiver" FORCE)
set(CMAKE_CXX_COMPILER_AR "${CMAKE_AR}" CACHE FILEPATH "C++ archiver" FORCE)
set(CMAKE_C_ARCHIVE_CREATE "${CMAKE_AR} cr <TARGET> <OBJECTS>")
set(CMAKE_C_ARCHIVE_APPEND "${CMAKE_AR} r <TARGET> <OBJECTS>")
set(CMAKE_C_ARCHIVE_FINISH "${CMAKE_COMMAND} -E true")
set(CMAKE_CXX_ARCHIVE_CREATE "${CMAKE_AR} cr <TARGET> <OBJECTS>")
set(CMAKE_CXX_ARCHIVE_APPEND "${CMAKE_AR} r <TARGET> <OBJECTS>")
set(CMAKE_CXX_ARCHIVE_FINISH "${CMAKE_COMMAND} -E true")
set(CMAKE_SYSROOT "${OS2EMX_PREFIX}/${OS2EMX_TARGET}")

foreach(tool IN ITEMS CMAKE_C_COMPILER CMAKE_CXX_COMPILER CMAKE_AR CMAKE_STRIP)
    if(NOT EXISTS "${${tool}}")
        message(FATAL_ERROR "Required cross tool is missing: ${${tool}}")
    endif()
endforeach()
if(NOT CMAKE_RANLIB STREQUAL ":" AND NOT EXISTS "${CMAKE_RANLIB}")
    message(FATAL_ERROR "Required ranlib is missing: ${CMAKE_RANLIB}")
endif()
if(NOT IS_DIRECTORY "${CMAKE_SYSROOT}")
    message(FATAL_ERROR "Cross sysroot is missing: ${CMAKE_SYSROOT}")
endif()

list(APPEND CMAKE_SYSTEM_PREFIX_PATH "${CMAKE_SYSROOT}")
set(CMAKE_FIND_ROOT_PATH "${CMAKE_SYSROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(CMAKE_C_FLAGS_INIT "-Zomf -Zsym -Zmap -O2")
set(CMAKE_CXX_FLAGS_INIT "-Zomf -Zsym -Zmap -O2 -DHB_NO_MT")
set(CMAKE_C_FLAGS "-Zomf -Zsym -Zmap -O2 -idirafter ${CMAKE_SYSROOT}/include/os2tk45"
    CACHE STRING "OS/2 C compiler flags" FORCE)
set(CMAKE_CXX_FLAGS "-Zomf -Zsym -Zmap -O2 -DHB_NO_MT -idirafter ${CMAKE_SYSROOT}/include/os2tk45"
    CACHE STRING "OS/2 C++ compiler flags" FORCE)
set(CMAKE_EXE_LINKER_FLAGS_INIT "-Zomf -Zsym -Zmap -Zcrtdll")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "-Zomf -Zsym -Zmap -Zcrtdll")
set(CMAKE_MODULE_LINKER_FLAGS_INIT "-Zomf -Zsym -Zmap -Zcrtdll")
set(CMAKE_CXX_STANDARD_LIBRARIES "-lcx -Zcrtdll" CACHE STRING
    "OS/2 runtime libraries" FORCE)
set(CMAKE_C_STANDARD_LIBRARIES "-lcx -Zcrtdll" CACHE STRING
    "OS/2 runtime libraries" FORCE)

# Qt's OS/2 port uses the native OS/2 thread primitives.  Do not make the
# generic CMake Threads package inject a nonexistent pthreads_s.a archive.
set(THREADS_PREFER_PTHREAD_FLAG OFF CACHE BOOL "" FORCE)
set(CMAKE_THREAD_LIBS_INIT "" CACHE STRING "OS/2 thread libraries" FORCE)
set(CMAKE_USE_PTHREADS_INIT OFF CACHE BOOL "" FORCE)

# Qt's OS/2 build is intentionally conservative: these options are the
# defaults used by the verified Linux-to-OS/2 shared-DLL build. They remain
# cache variables so callers can override them explicitly.
set(QT_BUILD_SHARED_LIBS ON CACHE BOOL "Build Qt shared libraries")
set(BUILD_SHARED_LIBS ON CACHE BOOL "Build shared libraries")
set(FEATURE_icu OFF CACHE STRING "Disable ICU for the OS/2 cross sysroot")
set(FEATURE_brotli OFF CACHE STRING "Disable Brotli when its OS/2 library is unavailable")
set(FEATURE_dbus OFF CACHE STRING "Disable D-Bus tools and libraries for the OS/2 cross build")
# libudev is Linux-host-specific; never select a host pkg-config result for OS/2.
set(FEATURE_libudev OFF CACHE BOOL "Disable Linux libudev for the OS/2 cross build" FORCE)
set(INPUT_opengl no CACHE STRING "Disable OpenGL for the OS/2 cross build")
set(INPUT_libb2 qt CACHE STRING "Use Qt's bundled BLAKE2 implementation")
set(INPUT_openssl runtime CACHE STRING "Enable the Qt runtime OpenSSL backend when target headers are found")
set(TEST_ld_version_script OFF CACHE BOOL "Disable GNU version scripts for the OS/2 linker")
set(QT_BUILD_TESTS OFF CACHE BOOL "Do not build Qt tests")
set(QT_BUILD_EXAMPLES OFF CACHE BOOL "Do not build Qt examples")
set(QT_BUILD_BENCHMARKS OFF CACHE BOOL "Do not build Qt benchmarks")
