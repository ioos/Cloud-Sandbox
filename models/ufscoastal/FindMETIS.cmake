message(STATUS "Finding METIS")
message(STATUS "METIS environment directory: $ENV{METIS_PATH}")

find_library(
  METIS_LIBRARY
  NAMES metis
  HINTS ENV METIS_PATH
  PATH_SUFFIXES lib lib64
)

find_path(
  METIS_INCLUDE_DIR
  NAMES metis.h
  HINTS ENV METIS_PATH
  PATH_SUFFIXES include
)

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(
  METIS
  REQUIRED_VARS
    METIS_LIBRARY
    METIS_INCLUDE_DIR
)

if(METIS_FOUND)
  get_filename_component(
    METIS_LIBRARY_DIR
    "${METIS_LIBRARY}"
    DIRECTORY
  )

  if(NOT TARGET METIS::METIS)
    add_library(METIS::METIS UNKNOWN IMPORTED)

    set_target_properties(
      METIS::METIS PROPERTIES
      IMPORTED_LOCATION "${METIS_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${METIS_INCLUDE_DIR}"
    )
  endif()
endif()

message(STATUS "METIS_LIBRARY: ${METIS_LIBRARY}")
message(STATUS "METIS_LIBRARY_DIR: ${METIS_LIBRARY_DIR}")
message(STATUS "METIS_INCLUDE_DIR: ${METIS_INCLUDE_DIR}")
