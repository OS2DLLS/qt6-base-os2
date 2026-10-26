# OS/2 Qt DLL basenames must fit the 8.3 limit. Keep CMake target names and
# public Qt6:: imported targets intact; change only the produced filenames.
set(_os2_qt_output_names
    "Network=Qt6Net"
    "Concurrent=Qt6Conc"
    "Widgets=Qt6Wgt"
    "PrintSupport=Qt6Prt"
    "QOffscreenIntegrationPlugin=qoffscr"
    "QTuioTouchPlugin=qtuio"
    "QTlsBackendCertOnlyPlugin=qcert"
)

function(os2_qt_add_import_library target)
    if(NOT TARGET "${target}")
        message(FATAL_ERROR "OS/2 import-library target is missing: ${target}")
    endif()
    get_target_property(_target_type "${target}" TYPE)
    if(NOT _target_type STREQUAL "SHARED_LIBRARY")
        message(FATAL_ERROR
            "OS/2 import-library target ${target} is not shared (type: ${_target_type})")
    endif()

    set(_emximp "$ENV{OS2EMX_PREFIX}/bin/emximp")
    if(NOT EXISTS "${_emximp}")
        message(FATAL_ERROR "OS/2 import-library tool is missing: ${_emximp}")
    endif()

    # This function is called from the module directory that created target.
    add_custom_command(TARGET "${target}" POST_BUILD
        COMMAND "${_emximp}" -q -p16 -o
                "$<TARGET_LINKER_FILE:${target}>"
                "$<TARGET_FILE:${target}>"
        COMMENT "Generating OMF import library for ${target}"
        VERBATIM
    )
endfunction()

function(_os2_finalize_qt_dlls)
    foreach(_mapping IN LISTS _os2_qt_output_names)
        string(REPLACE "=" ";" _pair "${_mapping}")
        list(GET _pair 0 _target)
        list(GET _pair 1 _output_name)
        if(TARGET "${_target}")
            set_target_properties("${_target}" PROPERTIES OUTPUT_NAME "${_output_name}")
        endif()
    endforeach()
endfunction()

# This helper is included by Qt's top-level CMakeLists on OS/2. Defer until
# Qt has declared all module targets before setting their output filenames.
cmake_language(DEFER DIRECTORY "${CMAKE_SOURCE_DIR}" CALL _os2_finalize_qt_dlls)