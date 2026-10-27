# Qt 6 for OS/2

This repository contains the Qt 6 base sources and the OS/2-specific changes
needed to cross-compile Qt shared libraries from a Linux host. The supported
output format is OS/2 OMF DLLs produced by the `cross-os2emx` toolchain.

## Requirements

* Linux x86_64 host
* CMake 3.16 or newer
* GNU Make
* A native Qt 6 host installation containing the Qt build tools (`moc`,
  `rcc`, and friends)
* An installed [`cross-os2emx`](https://github.com/komh/cross-os2emx)
  toolchain

By default the toolchain is expected at `$HOME/opt/os2emx`. Set
`OS2EMX_PREFIX` when it is installed elsewhere. `QT_HOST_PATH` must point to a
native Qt installation for the host tools; it is not the OS/2 target prefix.
For the current Vacuum/OS/2 setup, the cross sysroot (including `pthread.h`) is
under `/data/os2emx`; the target OpenSSL package is expected under
`/data/os2emx/i686-pc-os2-emx`.

## Linux to OS/2 build

From the repository root, configure once with CMake and then invoke Make:

# Current workspace paths under the active OS/2 prefix.

```sh
export OS2EMX_PREFIX="/data/os2emx"
export OS2EMX_AR="/data/os2emx/bin/emxomfar"
export QT_HOST_PATH="/data/qt6-host"
export OPENSSL_ROOT_DIR="/data/os2emx/i686-pc-os2-emx"

cmake -S . -B build-os2 -G "Unix Makefiles" \
  -DCMAKE_TOOLCHAIN_FILE="$PWD/cmake/qt6-os2.cmake" \
  -DOPENSSL_ROOT_DIR="$OPENSSL_ROOT_DIR" \
  -DINPUT_openssl=runtime
make -C build-os2 -j2
```

The native Qt tools must be runnable by the host. With Nix-provided host Qt,
run the commands from the corresponding `nix develop` environment (or export
the Nix store directories containing the host tools' shared libraries). A
self-contained Linux Qt installation needs no additional runtime setup. Once
the host environment is ready, the build itself is exactly two commands:
`cmake ...` followed by `make -C build-os2`.

The checked-in toolchain file supplies the target compiler, target sysroot,
OMF archiver, `emxomfld` linker flags, and the `libcx` runtime libraries. The
Qt-specific defaults disable ICU and Brotli, disable tests/examples/benchmarks,
and disable GNU linker version scripts because those features are not provided
by the OS/2 OMF link environment. Override a default with an explicit CMake
cache option when the corresponding OS/2 dependency is installed.

### SSL for Vacuum

`INPUT_openssl=runtime` enables Qt's dynamically loaded OpenSSL backend. Qt's
`ssl` feature is derived from that backend; do not force `FEATURE_ssl=ON` by
itself. `OPENSSL_ROOT_DIR` must identify the **target** OpenSSL prefix (with
`include/openssl` and `lib`), never a Linux host OpenSSL installation. The
cross-toolchain sysroot must also provide the target `pthread.h`: Qt's
OpenSSL-header configure test includes it. In this setup, use
`OS2EMX_PREFIX=/data/os2emx` and
`OPENSSL_ROOT_DIR=/data/os2emx/i686-pc-os2-emx`.

After configuration, verify the feature selection before building:

```sh
grep -E '^(OPENSSL_INCLUDE_DIR|FEATURE_openssl_runtime|QT_FEATURE_openssl_runtime|QT_FEATURE_ssl):' \
  build-os2/CMakeCache.txt
```

The expected result includes a found target `OPENSSL_INCLUDE_DIR` and
`FEATURE_openssl_runtime:BOOL=ON`, `QT_FEATURE_openssl_runtime:INTERNAL=ON`,
and `QT_FEATURE_ssl:INTERNAL=ON`. The runtime build also needs the Qt TLS
plugin and target OpenSSL DLLs reachable by OS/2. Qt searches for names matching
`ssl*.dll` and `crypto*.dll`; this OpenSSL prefix supplies `ssl3.dll` and
`crypto3.dll` below `lib`.

A clean rebuild (in the same shell, retaining the environment exports above) is:

```sh
rm -rf build-os2
cmake -S . -B build-os2 -G "Unix Makefiles" \
  -DCMAKE_TOOLCHAIN_FILE="$PWD/cmake/qt6-os2.cmake" \
  -DOPENSSL_ROOT_DIR="$OPENSSL_ROOT_DIR" \
  -DINPUT_openssl=runtime
make -C build-os2 -j2
```

## Output

The build produces target DLLs in `build-os2/bin`, including:

```text
Qt6Core.dll
Qt6Gui.dll
Qt6Network.dll
Qt6Widgets.dll
Qt6PrintSupport.dll
Qt6Sql.dll
Qt6Xml.dll
```

OS/2 platform and image/database plugins are emitted below
`build-os2/plugins`. The corresponding OMF import libraries (`Qt6Core.lib`,
etc.) are emitted below `build-os2/lib`.

Verify that the files are OS/2 targets rather than host Linux objects:

```sh
file build-os2/bin/Qt6Core.dll
file build-os2/lib/Qt6Core.lib
```

## Installation

Install into a staging prefix with the normal CMake install step:

```sh
cmake --install build-os2 --prefix "$PWD/qt6-os2-install"
```

The staging directory can then be copied to an OS/2 system. Keep the target
DLLs, their `.lib` import libraries, the Qt headers, and the `plugins`
directory together.

## Repository layout

* `cmake/qt6-os2.cmake` is the self-contained Linux-to-OS/2 CMake toolchain.
* `README-OS2-BUILD.md` contains the historical/manual OS/2 build notes.
* Build trees and generated logs are intentionally outside the source tree and
  are ignored by Git.
