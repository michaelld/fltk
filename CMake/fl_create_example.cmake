#
# A macro used by the CMake build system for the Fast Light Tool Kit (FLTK).
# Written by Michael Surette
#
# Copyright 1998-2020 by Bill Spitzak and others.
#
# This library is free software. Distribution and use rights are outlined in
# the file "COPYING" which should have been included with this file.  If this
# file is missing or damaged, see the license at:
#
#     https://www.fltk.org/COPYING.php
#
# Please see the following page on how to report bugs and issues:
#
#     https://www.fltk.org/bugs.php
#

################################################################################
#
# macro CREATE_EXAMPLE - Create a test/demo (example) program
#
# Input:
#
# - NAME: program name, e.g. 'hello'
#
# - SOURCES: list of source files, separated by ';' (needs quotes)
#   Sources can be:
#   - .c/.cxx files, e.g. 'hello.cxx'
#   - .fl (fluid) files, e.g. 'radio.fl'
#   - .plist file (macOS), e.g. 'editor-Info.plist'
#   - .icns file (macOS Icon), e.g. 'checkers.icns'
#   - .rc file (Windows resource file, e.g. icon definition)
#
#   Order of sources doesn't matter, multiple .cxx and .fl files are
#   supported, but only one .plist and one .icns file.
#
#   File name (type), e.g. '.icns' matters, it is parsed internally:
#   File types .fl, .plist, and .icns are treated specifically,
#   all other file types are added to the target's source files.
#
#   macOS specific .icns and .plist files are ignored on other platforms.
#
# - LIBRARIES:
#   List of libraries (CMake target names), separated by ';'. Needs
#   quotes if more than one library is needed, e.g. "fltk_gl;fltk"
#
# CREATE_EXAMPLE can have an optional fourth argument with a list of options
# - the option ANDROID_OK is set if CREATE_EXAMPLE creates code for Android
#   builds in addition to the native build
#
################################################################################

macro (CREATE_EXAMPLE NAME SOURCES LIBRARIES)

  set (srcs)                    # source files
  set (flsrcs)                  # fluid source (.fl) files
  set (TARGET_NAME ${NAME})     # CMake target name
  set (ICON_NAME)               # macOS icon (max. one)
  set (PLIST)                   # macOS .plist file (max. one)
  set (ICON_PATH)               # macOS icon resource path

  # create macOS bundle? 0 = no, 1 = yes

  if (APPLE AND (NOT OPTION_APPLE_X11) AND (NOT OPTION_APPLE_SDL))
    set (MAC_BUNDLE 1)
  else ()
    set (MAC_BUNDLE 0)
  endif (APPLE AND (NOT OPTION_APPLE_X11) AND (NOT OPTION_APPLE_SDL))

  # rename target name "help" (reserved since CMake 2.8.12)
  # FIXME: not necessary in FLTK 1.4 but left for compatibility (06/2020)

  if (${TARGET_NAME} STREQUAL "help")
    set (TARGET_NAME "test_help")
  endif (${TARGET_NAME} STREQUAL "help")

  # filter input files for different handling (fluid, icon, plist, source)

  foreach (src ${SOURCES})
    if ("${src}" MATCHES "\\.fl$")
      list (APPEND flsrcs ${src})
    elseif ("${src}" MATCHES "\\.icns$")
      set (ICON_NAME "${src}")
    elseif ("${src}" MATCHES "\\.plist$")
      set (PLIST "${src}")
    else ()
      list (APPEND srcs ${src})
    endif ("${src}" MATCHES "\\.fl$")
  endforeach (src)

  # generate source files from .fl files, add output to sources

  if (flsrcs)
    FLTK_RUN_FLUID (FLUID_SOURCES "${flsrcs}")
    list (APPEND srcs ${FLUID_SOURCES})
    unset (FLUID_SOURCES)
  endif (flsrcs)

  # set macOS (icon) resource path if applicable

  if (MAC_BUNDLE AND ICON_NAME)
    set (ICON_PATH "${CMAKE_CURRENT_SOURCE_DIR}/${TARGET_NAME}.app/Contents/Resources/${ICON_NAME}")
  endif (MAC_BUNDLE AND ICON_NAME)

  ##############################################################################
  # copy macOS "bundle wrapper" (shell script) to target (bin) directory
  ##############################################################################
  #  (1) file (COPY   ...) to set execution permissions
  #  (2) file (RENAME ...) to move the file to its final place
  ##############################################################################

  if (MAC_BUNDLE)
    file (COPY
      ${CMAKE_CURRENT_SOURCE_DIR}/../CMake/macOS-bundle-wrapper.in
      DESTINATION ${CMAKE_CURRENT_BINARY_DIR}
      FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
        GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
    )
    file (RENAME
      ${CMAKE_CURRENT_BINARY_DIR}/macOS-bundle-wrapper.in
      ${EXECUTABLE_OUTPUT_PATH}/${TARGET_NAME}
    )
  endif (MAC_BUNDLE)

  ##############################################################################
  # add executable target and set properties (all platforms)
  ##############################################################################

  add_executable          (${TARGET_NAME} WIN32 MACOSX_BUNDLE ${srcs} ${ICON_PATH})
  set_target_properties   (${TARGET_NAME} PROPERTIES OUTPUT_NAME ${NAME})
  target_link_libraries   (${TARGET_NAME} ${LIBRARIES})

  if (ICON_PATH)
    set_target_properties (${TARGET_NAME} PROPERTIES MACOSX_BUNDLE_ICON_FILE ${ICON_NAME})
    set_target_properties (${TARGET_NAME} PROPERTIES RESOURCE ${ICON_PATH})
  endif (ICON_PATH)

  if (PLIST)
    set_target_properties (${TARGET_NAME} PROPERTIES MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/${PLIST}")
  endif (PLIST)

  ######################################################################
  # Parse optional fourth argument "ANDROID_OK", see description above.
  ######################################################################

  if (${ARGC} GREATER 3)
    foreach (OPTION ${ARGV3})
      if (${OPTION} STREQUAL "ANDROID_OK" AND OPTION_CREATE_ANDROID_STUDIO_IDE)
        CREATE_ANDROID_IDE_FOR_TEST (${NAME} ${SOURCES} ${LIBRARIES})
      endif ()
    endforeach ()
  endif ()

endmacro (CREATE_EXAMPLE NAME SOURCES LIBRARIES)
