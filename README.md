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

For the `/data` workspace, enter `/data/shell.nix` before building. It exports
`OS2EMX_PREFIX=/data/os2emx`, the matching target sysroot and OMF tools, and
`OS2EMX_INSTALL_ROOT=/data/os2emx` and
`OS2EMX_HOST_INSTALL_ROOT=/data/os2emx`. Native Linux Qt host tools and OS/2
target Qt files install into the shared `/data/os2emx` Unix-style prefix. The
OpenSSL target headers and libraries are discovered under
`/data/os2emx/i686-pc-os2-emx`.

When the OS/2 target prefix is still CMake's default, `QtSetup.cmake` selects
`$OS2EMX_INSTALL_ROOT` (therefore `/data/os2emx` in this workspace). An explicit
`-DCMAKE_INSTALL_PREFIX=...` remains an override. Use a fresh build directory
when validating the default; an existing CMake cache retains its previous
prefix.

## Linux to OS/2 build

The supported workspace entry point is the root Makefile. From the already
active `/data/shell.nix` shell, run `make qt-base` in `/data`; it builds the
toolchain and target dependencies, installs native Qt host tools, configures
Qt Base with this OS/2 toolchain, and installs Qt to the default target prefix.
The Makefile does not start a nested Nix shell.

For a direct diagnostic configure, use the same shell and an out-of-tree build
directory. The install prefix is intentionally not passed: this exercises the
`QtSetup.cmake` default.

```sh
nix-shell /data/shell.nix
cmake -S /data/qt6-base-os2 -B /data/build-nix/qt6-base-os2-os2emx-ninja \
  -DCMAKE_TOOLCHAIN_FILE=/data/qt6-base-os2/cmake/qt6-os2.cmake \
  -DQT_HOST_PATH=/data/os2emx \
  -DOPENSSL_ROOT_DIR=/data/os2emx/i686-pc-os2-emx \
  -DINPUT_openssl=runtime -DCMAKE_BUILD_TYPE=Release
cmake --build /data/build-nix/qt6-base-os2-os2emx-ninja --parallel 2
cmake --install /data/build-nix/qt6-base-os2-os2emx-ninja
```

`shell.nix` selects Ninja and limits builds to two jobs. The host Qt prefix must
contain runnable Linux Qt tools and their CMake host packages (`Qt6HostInfo`,
`Qt6CoreTools`, `Qt6GuiTools`, and `Qt6WidgetsTools`). The root Makefile builds
and installs that host tree before configuring Qt Base. Host and target builds
remain separate build trees but share the `/data/os2emx` install prefix.

The checked-in Qt toolchain file supplies the target compiler, target sysroot,
OMF archiver, `emxomfld` linker flags, and `libcx` runtime libraries. The
Qt-specific defaults disable ICU and Brotli, disable tests/examples/benchmarks,
and disable GNU linker version scripts because those features are not provided
by the OS/2 OMF link environment. Override a default with an explicit CMake
cache option only when the corresponding OS/2 dependency is installed.

### Runtime OpenSSL backend

`INPUT_openssl=runtime` enables Qt's dynamically loaded OpenSSL backend. Qt's
`ssl` feature is derived from that backend; do not force `FEATURE_ssl=ON` by
itself. `OPENSSL_ROOT_DIR` must identify the **target** OpenSSL prefix (with
`include/openssl` and `lib`), never a Linux host OpenSSL installation. The
cross-toolchain sysroot must also provide the target `pthread.h`: Qt's
OpenSSL-header configure test includes it. The `/data` Makefile supplies the
target sysroot as `OPENSSL_ROOT_DIR` and selects `INPUT_openssl=runtime`.

After configuration, verify the feature selection before building:

```sh
grep -E '^(OPENSSL_INCLUDE_DIR|FEATURE_openssl_runtime|QT_FEATURE_openssl_runtime|QT_FEATURE_ssl):' \
  /data/build-nix/qt6-base-os2-os2emx-ninja/CMakeCache.txt
```

The expected result includes a found target `OPENSSL_INCLUDE_DIR` and
`FEATURE_openssl_runtime:BOOL=ON`, `QT_FEATURE_openssl_runtime:INTERNAL=ON`,
and `QT_FEATURE_ssl:INTERNAL=ON`. The runtime build also needs the Qt TLS
plugin and target OpenSSL DLLs reachable by OS/2. Qt searches for names matching
`ssl*.dll` and `crypto*.dll`; this OpenSSL prefix supplies `ssl3.dll` and
`crypto3.dll` below `lib`.

A clean diagnostic configure uses a new build directory (the Makefile's
standard build directory remains under `/data/build-nix`):

```sh
cmake -S /data/qt6-base-os2 -B /data/build-nix/qt6-base-os2-os2emx-ninja \
  -DCMAKE_TOOLCHAIN_FILE=/data/qt6-base-os2/cmake/qt6-os2.cmake \
  -DQT_HOST_PATH=/data/os2emx \
  -DOPENSSL_ROOT_DIR=/data/os2emx/i686-pc-os2-emx \
  -DINPUT_openssl=runtime -DCMAKE_BUILD_TYPE=Release
cmake --build /data/build-nix/qt6-base-os2-os2emx-ninja --parallel 2
```

## Output

The build produces target DLLs in
`/data/build-nix/qt6-base-os2-os2emx-ninja/bin`, including:

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
`/data/build-nix/qt6-base-os2-os2emx-ninja/plugins`. The corresponding OMF import
libraries (`Qt6Core.lib`, etc.) are emitted below
`/data/build-nix/qt6-base-os2-os2emx-ninja/lib`.

Verify that the files are OS/2 targets rather than host Linux objects:

```sh
file /data/build-nix/qt6-base-os2-os2emx-ninja/bin/Qt6Core.dll
file /data/build-nix/qt6-base-os2-os2emx-ninja/lib/Qt6Core.lib
```

## Installation

The root Makefile installs to `/data/os2emx` by default. For a direct
CMake install, run `cmake --install` without `--prefix` so the configured
prefix is respected:

```sh
cmake --install /data/build-nix/qt6-base-os2-os2emx-ninja
```

`/data/os2emx` is a shared prefix containing the Linux host Qt tools, OS/2 Qt
files, the toolchain, and the nested target sysroot. Do not copy the entire
prefix to OS/2; package only the required Qt DLLs, import libraries, headers,
plugins, and their runtime dependencies.

## Repository layout

* `cmake/qt6-os2.cmake` is the self-contained Linux-to-OS/2 CMake toolchain.
* `README-OS2-BUILD.md` contains the historical/manual OS/2 build notes.
* Build trees and generated logs are intentionally outside the source tree and
  are ignored by Git.
