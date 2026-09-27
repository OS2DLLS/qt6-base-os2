# Qt 6 für OS/2 – Build- und Installationsanleitung

Diese Datei dokumentiert den reproduzierbaren Qt-6.2.12-Build auf OS/2.

## Ergebnis

Der belastbare Build ist statisch. Installationsprefix:

```text
/usr/local/Qt-6.2.12
D:\USR\LOCAL\Qt-6.2.12
```

Gebaut/installiert werden insbesondere:

```text
Qt6Core.a Qt6Concurrent.a Qt6Network.a Qt6Sql.a Qt6Xml.a
Qt6Gui.a Qt6Widgets.a Qt6PrintSupport.a Qt6DBus.a
```

OpenGL ist deaktiviert. Der Shared-DLL-Link mit GCC 9.2/EMX/OMF-ILink ist
nicht zuverlässig; dazu gibt es weiter unten einen separaten Abschnitt.

## Voraussetzungen

Verwendete Toolchain:

```text
CMake 3.31.7
GCC 9.2.0
GNU Make 4.2.1
OS/2 OMF/ILink
```

Pakete:

```sh
yum -y install pthread-devel libcx-devel exceptq-devel libicu-devel
```

Prüfen:

```sh
rpm -q pthread-devel libcx-devel exceptq-devel libicu-devel
ls -l /@unixroot/usr/include/pthread.h
ls -l /@unixroot/usr/include/poll.h
ls -l /@unixroot/usr/include/unicode/ucnv.h
```

## Umgebung

```sh
export PATH="C:/sys/bin;C:/OS2;D:/USR/LOCAL/BIN;D:/USR/SBIN;D:/USR/BIN"
```

Werkzeuge:

```text
D:/USR/BIN/cmake.exe
D:/USR/BIN/make.exe
D:/USR/BIN/cc.exe
D:/USR/BIN/c++.exe
C:/OS2/ilink.exe
```

## Saubere Konfiguration

Quelle und Build:

```text
D:/qt6-base-os2
D:/qt6-base-os2/build-ssh
```

Alten Build bei einer vollständigen Neukonfiguration entfernen:

```sh
rm -rf D:/qt6-base-os2/build-ssh
```

Statische OS/2-Konfiguration:

```sh
cmake \
  -S D:/qt6-base-os2 \
  -B D:/qt6-base-os2/build-ssh \
  -G "Unix Makefiles" \
  -DQT_BUILD_SHARED_LIBS=OFF \
  -DBUILD_SHARED_LIBS=OFF \
  -DFEATURE_shared=OFF \
  -DTEST_ld_version_script=OFF \
  -DFEATURE_icu=ON \
  -DFEATURE_poll_select=ON \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_C_FLAGS="-O0 -D__USE_EMX" \
  -DCMAKE_CXX_FLAGS="-O0 -D__USE_EMX" \
  -DCMAKE_EXE_LINKER_FLAGS="-Zomf" \
  -DCMAKE_SHARED_LINKER_FLAGS= \
  -DCMAKE_CXX_STANDARD_LIBRARIES="-licuuc_dll -licuin_dll -lcx" \
  -DCMAKE_LINKER=C:/OS2/ilink.exe \
  -DCMAKE_MAKE_PROGRAM=D:/USR/BIN/make.exe
```

Wichtige Optionen:

- `-O0`: verhindert GCC-9.2-Segmentation-Faults bei großen Qt-Dateien.
- `-D__USE_EMX`: aktiviert OS/2-libc-Erweiterungen.
- `FEATURE_icu=ON`: aktiviert ICU-Text- und Collator-Unterstützung.
- `FEATURE_poll_select=ON`: baut die Qt-Poll-Implementierung.
- `TEST_ld_version_script=OFF`: ILink unterstützt GNU-`--version-script` nicht.
- `-lcx`: bindet OS/2-libc-Funktionen wie `mmap`, `spawn2` und Poll ein.

## Build

Seriell bauen:

```sh
cmake --build D:/qt6-base-os2/build-ssh --parallel 1
```

Loggen:

```sh
cmake --build D:/qt6-base-os2/build-ssh --parallel 1 \
  > D:/qt6-base-os2/build-ssh/build.log 2>&1
printf "BUILD_EXIT:%s\n" "$?" >> D:/qt6-base-os2/build-ssh/build.log
```

Library-Targets ohne problematische Zusatzgeneratoren:

```sh
cmake --build D:/qt6-base-os2/build-ssh --target \
  Core Concurrent Network Sql Xml Gui Widgets PrintSupport DBus \
  --parallel 1
```

## Installation

```sh
cmake --install D:/qt6-base-os2/build-ssh --component Devel
```

Bei diesem Qt-/OS2-Setup die statischen Archive zusätzlich direkt kopieren:

```sh
mkdir -p D:/USR/LOCAL/Qt-6.2.12/lib
cp D:/qt6-base-os2/build-ssh/lib/Qt6Core.a \
   D:/qt6-base-os2/build-ssh/lib/Qt6Concurrent.a \
   D:/qt6-base-os2/build-ssh/lib/Qt6Network.a \
   D:/qt6-base-os2/build-ssh/lib/Qt6Sql.a \
   D:/qt6-base-os2/build-ssh/lib/Qt6Xml.a \
   D:/qt6-base-os2/build-ssh/lib/Qt6Gui.a \
   D:/qt6-base-os2/build-ssh/lib/Qt6Widgets.a \
   D:/qt6-base-os2/build-ssh/lib/Qt6PrintSupport.a \
   D:/qt6-base-os2/build-ssh/lib/Qt6DBus.a \
   D:/USR/LOCAL/Qt-6.2.12/lib/
```

Falls Modulheader fehlen:

```sh
mkdir -p D:/USR/LOCAL/Qt-6.2.12/include
cp -a D:/qt6-base-os2/build-ssh/include/QtGui \
      D:/qt6-base-os2/build-ssh/include/QtWidgets \
      D:/qt6-base-os2/build-ssh/include/QtPrintSupport \
      D:/qt6-base-os2/build-ssh/include/QtDBus \
      D:/USR/LOCAL/Qt-6.2.12/include/
```

Verifizieren:

```sh
ls -l D:/USR/LOCAL/Qt-6.2.12/lib/Qt6Core.a
ls -l D:/USR/LOCAL/Qt-6.2.12/lib/Qt6Gui.a
ls -l D:/USR/LOCAL/Qt-6.2.12/lib/Qt6Widgets.a
ls -l D:/USR/LOCAL/Qt-6.2.12/include/QtCore/qglobal.h
```

## Nutzung in anderen CMake-Projekten

```sh
cmake -S . -B build \
  -DCMAKE_PREFIX_PATH=/usr/local/Qt-6.2.12 \
  -DCMAKE_BUILD_TYPE=Debug
```

```cmake
find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets)
target_link_libraries(mein_programm PRIVATE Qt6::Core Qt6::Gui Qt6::Widgets)
```

Die Qt-Version ist statisch. Anwendungen müssen daher die benötigten
OS/2-/ICU-/libcx-Abhängigkeiten ebenfalls berücksichtigen.

## DEF-Dateien und Shared-DLL-Versuch

Aus den tatsächlichen globalen Symbolen der statischen Archive wurden DEF-
Dateien mit `nm` erzeugt:

```text
D:/qt6-base-os2/build-ssh/lib/Qt6Core.def
D:/qt6-base-os2/build-ssh/lib/Qt6Concurrent.def
D:/qt6-base-os2/build-ssh/lib/Qt6DBus.def
D:/qt6-base-os2/build-ssh/lib/Qt6Gui.def
D:/qt6-base-os2/build-ssh/lib/Qt6Network.def
D:/qt6-base-os2/build-ssh/lib/Qt6PrintSupport.def
D:/qt6-base-os2/build-ssh/lib/Qt6Sql.def
D:/qt6-base-os2/build-ssh/lib/Qt6Widgets.def
D:/qt6-base-os2/build-ssh/lib/Qt6Xml.def
```

Sie wurden zusätzlich installiert nach:

```text
D:/USR/LOCAL/Qt-6.2.12/lib
/usr/local/Qt-6.2.12/lib
```

Ein vollständiger Shared-DLL-Link ist noch nicht erfolgreich verifiziert.
Der OMF-/ILink-Linker meldet bei Qt6 große Export-/Importtabellen (`LNK2022`).
Der statische Build ist deshalb die funktionierende Produktionsvariante.

## Bekannte Einschränkung

`qdbusxml2cpp.exe` ist auf diesem OS/2-GCC-/OMF-Setup noch nicht fertig gebaut.
Der Library-Build und die Library-Installation sind davon unabhängig.
