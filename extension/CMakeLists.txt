if(POLICY CMP0135)
	cmake_policy(SET CMP0135 NEW)
endif()

include(FetchContent)

if(NOT DEFINED ENV{HASHLINK} OR "$ENV{HASHLINK}" STREQUAL "")
	message(FATAL_ERROR "HASHLINK environment variable is not set")
endif()

set(HASHLINK_ROOT "$ENV{HASHLINK}")

find_path(
	HASHLINK_INCLUDE_DIR
	NAMES hl.h
	HINTS
		"${HASHLINK_ROOT}/include"
		"${HASHLINK_ROOT}/src"
	NO_DEFAULT_PATH
)

if(WIN32)
	find_library(
		HASHLINK_LIBRARY
		NAMES libhl
		HINTS
			"${HASHLINK_ROOT}"
			"${HASHLINK_ROOT}/lib"
		NO_DEFAULT_PATH
	)
elseif(UNIX AND NOT APPLE)
	find_library(
		HASHLINK_LIBRARY
		NAMES hl
		HINTS
			"${HASHLINK_ROOT}"
			"${HASHLINK_ROOT}/lib"
			"${HASHLINK_ROOT}/build/bin"
		NO_DEFAULT_PATH
	)
else()
	message(FATAL_ERROR "Unsupported platform")
endif()

if(NOT HASHLINK_INCLUDE_DIR)
	message(FATAL_ERROR
		"Could not find hl.h under HASHLINK=${HASHLINK_ROOT}"
	)
endif()

if(NOT HASHLINK_LIBRARY)
	message(FATAL_ERROR
		"Could not find HashLink library under HASHLINK=${HASHLINK_ROOT}"
	)
endif()

set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(FT_DISABLE_ZLIB TRUE CACHE BOOL "" FORCE)
set(FT_DISABLE_BZIP2 TRUE CACHE BOOL "" FORCE)
set(FT_DISABLE_PNG TRUE CACHE BOOL "" FORCE)
set(FT_DISABLE_HARFBUZZ TRUE CACHE BOOL "" FORCE)
set(FT_DISABLE_BROTLI TRUE CACHE BOOL "" FORCE)

FetchContent_Declare(
	freetype
	GIT_REPOSITORY https://github.com/freetype/freetype.git
	GIT_TAG VER-2-14-3
	GIT_SHALLOW TRUE
)

FetchContent_MakeAvailable(freetype)

add_library(extension SHARED
	freetype.c
)

set_target_properties(extension PROPERTIES
	OUTPUT_NAME "freetype"
	PREFIX ""
	SUFFIX ".hdll"
	C_STANDARD 23
	C_STANDARD_REQUIRED ON
)

target_include_directories(extension PRIVATE
	"${HASHLINK_INCLUDE_DIR}"
)

target_link_libraries(extension PRIVATE
	freetype
	"${HASHLINK_LIBRARY}"
)

if(MSVC)
	set_target_properties(extension PROPERTIES
		MSVC_RUNTIME_LIBRARY
			"MultiThreaded$<$<CONFIG:Debug>:Debug>DLL"
	)

	target_compile_options(extension PRIVATE
		/wd4244
		/wd4267
		/wd4996
	)

	target_link_options(extension PRIVATE
		/NODEFAULTLIB:LIBCMT
		/NODEFAULTLIB:LIBCMTD
	)
endif()


if(UNIX AND NOT APPLE)
	set_target_properties(extension PROPERTIES
		BUILD_RPATH "$ORIGIN"
		INSTALL_RPATH "$ORIGIN"
	)
endif()