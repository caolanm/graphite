include(GetPrerequisites)

function(nolib_test LIBNAME OBJECTFILE)
    string(REGEX REPLACE "[][^$.*+?|()-]" "\\\\\\0" LIBNAME_REGEX ${LIBNAME})
    if (${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
        add_test(NAME nolib-${LIBNAME}-${PROJECT_NAME}
            COMMAND otool -L ${OBJECTFILE})
        set_tests_properties(nolib-${LIBNAME}-${PROJECT_NAME} PROPERTIES 
            FAIL_REGULAR_EXPRESSION "${CMAKE_SHARED_LIBRARY_PREFIX}${LIBNAME_REGEX}[.0-9]+${CMAKE_SHARED_LIBRARY_SUFFIX}")
    else (${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
        add_test(NAME nolib-${LIBNAME}-${PROJECT_NAME}
            COMMAND readelf --dynamic ${OBJECTFILE})
        set_tests_properties(nolib-${LIBNAME}-${PROJECT_NAME} PROPERTIES 
            FAIL_REGULAR_EXPRESSION "0x[0-9a-f]+ \\(NEEDED\\)[ \\t]+Shared library: \\[${CMAKE_SHARED_LIBRARY_PREFIX}${LIBNAME_REGEX}${CMAKE_SHARED_LIBRARY_SUFFIX}.*\\]")
    endif (${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
endfunction(nolib_test)


MACRO(GET_TARGET_PROPERTY_WITH_DEFAULT _variable _target _property _default_value)
  GET_TARGET_PROPERTY (${_variable} ${_target} ${_property})
  IF (${_variable} MATCHES NOTFOUND)
    SET (${_variable} ${_default_value})
  ENDIF (${_variable} MATCHES NOTFOUND)
ENDMACRO (GET_TARGET_PROPERTY_WITH_DEFAULT)


FUNCTION(CREATE_LIBTOOL_FILE _target _install_DIR)
  GET_TARGET_PROPERTY(_target_location ${_target} LOCATION)
  GET_TARGET_PROPERTY_WITH_DEFAULT(_target_static_lib ${_target} STATIC_LIB "")
  GET_TARGET_PROPERTY_WITH_DEFAULT(_target_dependency_libs ${_target} LT_DEPENDENCY_LIBS "")
  GET_TARGET_PROPERTY_WITH_DEFAULT(_target_current ${_target} LT_VERSION_CURRENT 0)
  GET_TARGET_PROPERTY_WITH_DEFAULT(_target_age ${_target} LT_VERSION_AGE 0)
  GET_TARGET_PROPERTY_WITH_DEFAULT(_target_revision ${_target} LT_VERSION_REVISION 0)
  GET_TARGET_PROPERTY_WITH_DEFAULT(_target_installed ${_target} LT_INSTALLED yes)
  GET_TARGET_PROPERTY_WITH_DEFAULT(_target_shouldnotlink ${_target} LT_SHOULDNOTLINK no)
  GET_TARGET_PROPERTY_WITH_DEFAULT(_target_dlopen ${_target} LT_DLOPEN "")
  GET_TARGET_PROPERTY_WITH_DEFAULT(_target_dlpreopen ${_target} LT_DLPREOPEN "")
  GET_FILENAME_COMPONENT(_lanamewe ${_target_location} NAME_WE)
  GET_FILENAME_COMPONENT(_soname ${_target_location} NAME)
  GET_FILENAME_COMPONENT(_soext ${_target_location} EXT)
  SET(_laname ${PROJECT_BINARY_DIR}/${_lanamewe}.la)
  FILE(WRITE ${_laname} "# ${_lanamewe}.la - a libtool library file\n")
  FILE(APPEND ${_laname} "# Generated by CMake ${CMAKE_VERSION} (like GNU libtool)\n")
  FILE(APPEND ${_laname} "\n# Please DO NOT delete this file!\n# It is necessary for linking the library with libtool.\n\n" )
  FILE(APPEND ${_laname} "# The name that we can dlopen(3).\n")
  FILE(APPEND ${_laname} "dlname='${_soname}'\n\n")
  FILE(APPEND ${_laname} "# Names of this library.\n")
  if (${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
    FILE(APPEND ${_laname} "library_names='${_lanamwe}.${_target_current}.${_target_revision}.${_target_age}.${_soext} ${_lanamewe}.${_target_current}.${_soext} ${_soname}'\n\n")
  else (${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
    FILE(APPEND ${_laname} "library_names='${_soname}.${_target_current}.${_target_revision}.${_target_age} ${_soname}.${_target_current} ${_soname}'\n\n")
  endif (${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
  FILE(APPEND ${_laname} "# The name of the static archive.\n")
  FILE(APPEND ${_laname} "old_library='${_target_static_lib}'\n\n")
  FILE(APPEND ${_laname} "# Libraries that this one depends upon.\n")
  FILE(APPEND ${_laname} "dependency_libs='${_target_dependency_libs}'\n\n")
  FILE(APPEND ${_laname} "# Names of additional weak libraries provided by this library\n")
  FILE(APPEND ${_laname} "weak_library_names=\n\n")
  FILE(APPEND ${_laname} "# Version information for ${_lanamewe}.\n")
  FILE(APPEND ${_laname} "current=${_target_current}\n")
  FILE(APPEND ${_laname} "age=${_target_age}\n")
  FILE(APPEND ${_laname} "revision=${_target_revision}\n\n")
  FILE(APPEND ${_laname} "# Is this an already installed library?\n")
  FILE(APPEND ${_laname} "installed=${_target_installed}\n\n")
  FILE(APPEND ${_laname} "# Should we warn about portability when linking against -modules?\n")
  FILE(APPEND ${_laname} "shouldnotlink=${_target_shouldnotlink}\n\n")
  FILE(APPEND ${_laname} "# Files to dlopen/dlpreopen\n")
  FILE(APPEND ${_laname} "dlopen='${_target_dlopen}'\n")
  FILE(APPEND ${_laname} "dlpreopen='${_target_dlpreopen}'\n\n")
  FILE(APPEND ${_laname} "# Directory that this library needs to be installed in:\n")
  FILE(APPEND ${_laname} "libdir='${CMAKE_INSTALL_PREFIX}${_install_DIR}'\n")
  INSTALL( FILES ${_laname} DESTINATION ${CMAKE_INSTALL_PREFIX}${_install_DIR})
ENDFUNCTION(CREATE_LIBTOOL_FILE)


function(fonttest TESTNAME FONTFILE)
    if (EXISTS ${PROJECT_SOURCE_DIR}/standards/${TESTNAME}${CMAKE_SYSTEM_NAME}.log)
        set(PLATFORM_TEST_SUFFIX ${CMAKE_SYSTEM_NAME})
    endif (EXISTS ${PROJECT_SOURCE_DIR}/standards/${TESTNAME}${CMAKE_SYSTEM_NAME}.log)
    if (NOT (GRAPHITE2_NSEGCACHE OR GRAPHITE2_NFILEFACE))
        add_test(NAME ${TESTNAME} COMMAND $<TARGET_FILE:gr2fonttest> -trace ${PROJECT_BINARY_DIR}/${TESTNAME}.json -log ${PROJECT_BINARY_DIR}/${TESTNAME}.log ${PROJECT_SOURCE_DIR}/fonts/${FONTFILE} -codes ${ARGN})
        set_tests_properties(${TESTNAME} PROPERTIES TIMEOUT 3)
        if (GRAPHITE2_ASAN)
            set_property(TEST ${TESTNAME} APPEND PROPERTY ENVIRONMENT "ASAN_SYMBOLIZER_PATH=${ASAN_SYMBOLIZER}")
        endif (GRAPHITE2_ASAN)
        add_test(NAME ${TESTNAME}Output COMMAND ${CMAKE_COMMAND} -E compare_files ${PROJECT_BINARY_DIR}/${TESTNAME}.log ${PROJECT_SOURCE_DIR}/standards/${TESTNAME}${PLATFORM_TEST_SUFFIX}.log)
        if (NOT GRAPHITE2_NTRACING)
            add_test(NAME ${TESTNAME}Debug COMMAND python ${PROJECT_SOURCE_DIR}/jsoncmp ${PROJECT_BINARY_DIR}/${TESTNAME}.json ${PROJECT_SOURCE_DIR}/standards/${TESTNAME}.json)
            set_tests_properties(${TESTNAME}Debug  PROPERTIES DEPENDS ${TESTNAME})
        endif (NOT GRAPHITE2_NTRACING)
        set_tests_properties(${TESTNAME}Output PROPERTIES DEPENDS ${TESTNAME})
    endif (NOT (GRAPHITE2_NSEGCACHE OR GRAPHITE2_NFILEFACE))
endfunction(fonttest)


function(feattest TESTNAME FONTFILE)
    if (EXISTS ${PROJECT_SOURCE_DIR}/standards/${TESTNAME}${CMAKE_SYSTEM_NAME}.log)
        set(PLATFORM_TEST_SUFFIX ${CMAKE_SYSTEM_NAME})
    endif (EXISTS ${PROJECT_SOURCE_DIR}/standards/${TESTNAME}${CMAKE_SYSTEM_NAME}.log)
    if (NOT (GRAPHITE2_NSEGCACHE OR GRAPHITE2_NFILEFACE))
        add_test(NAME ${TESTNAME} COMMAND $<TARGET_FILE:gr2fonttest> -log ${PROJECT_BINARY_DIR}/${TESTNAME}.log ${PROJECT_SOURCE_DIR}/fonts/${FONTFILE})
        set_tests_properties(${TESTNAME} PROPERTIES TIMEOUT 3)
        add_test(NAME ${TESTNAME}Output COMMAND ${CMAKE_COMMAND} -E compare_files ${PROJECT_BINARY_DIR}/${TESTNAME}.log ${PROJECT_SOURCE_DIR}/standards/${TESTNAME}${PLATFORM_TEST_SUFFIX}.log)
        set_tests_properties(${TESTNAME}Output PROPERTIES DEPENDS ${TESTNAME})
    endif (NOT (GRAPHITE2_NSEGCACHE OR GRAPHITE2_NFILEFACE))
endfunction(feattest)

function(cmptest TESTNAME FONTFILE TEXTFILE)
    if (EXISTS ${PROJECT_SOURCE_DIR}/standards/${TESTNAME}${CMAKE_SYSTEM_NAME}.json)
        set(PLATFORM_TEST_SUFFIX ${CMAKE_SYSTEM_NAME})
    endif (EXISTS ${PROJECT_SOURCE_DIR}/standards/${TESTNAME}${CMAKE_SYSTEM_NAME}.json)
    if (NOT (GRAPHITE2_NFILEFACE))
        add_test(NAME ${TESTNAME} COMMAND python ${PROJECT_SOURCE_DIR}/fnttxtrender -t ${PROJECT_SOURCE_DIR}/texts/${TEXTFILE} -o ${PROJECT_BINARY_DIR}/${TESTNAME}.json -c ${PROJECT_SOURCE_DIR}/standards/${TESTNAME}${PLATFORM_TEST_SUFFIX}.json ${ARGN} ${PROJECT_SOURCE_DIR}/fonts/${FONTFILE})
        set_tests_properties(${TESTNAME} PROPERTIES TIMEOUT 30)
    endif (NOT (GRAPHITE2_NFILEFACE))
endfunction(cmptest)


