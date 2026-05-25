if(POLICY CMP0135)
	cmake_policy(SET CMP0135 NEW)
endif()

include(FetchContent)

FetchContent_Declare(
	freetype_binaries
	URL https://github.com/ubawurinna/freetype-windows-binaries/archive/refs/tags/v2.14.3.zip
	DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)

FetchContent_MakeAvailable(freetype_binaries)

set(FREETYPE_ROOT "${freetype_binaries_SOURCE_DIR}")
set(FREETYPE_ARCH "x64")
if(CMAKE_SIZEOF_VOID_P EQUAL 4)
	set(FREETYPE_ARCH "x86")
endif()
if(CMAKE_SYSTEM_PROCESSOR MATCHES "ARM64|aarch64")
	set(FREETYPE_ARCH "arm64")
endif()

set(FREETYPE_LIBRARY "${FREETYPE_ROOT}/release static/vs2026/${FREETYPE_ARCH}/freetype.lib")
if(NOT EXISTS "${FREETYPE_LIBRARY}")
	message(FATAL_ERROR "FreeType static library not found: ${FREETYPE_LIBRARY}")
endif()

add_library(extension SHARED freetype.c)

set_target_properties(extension PROPERTIES
	OUTPUT_NAME "freetype"
	SUFFIX ".hdll"
	C_STANDARD 99
	C_STANDARD_REQUIRED ON
	MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL"
)

target_include_directories(extension PRIVATE
	"$ENV{HASHLINK}/include"
	"${FREETYPE_ROOT}/include"
)

target_link_libraries(extension PRIVATE
	"$ENV{HASHLINK}/libhl.lib"
	"${FREETYPE_LIBRARY}"
)

if(MSVC)
	target_compile_options(extension PRIVATE /wd4244 /wd4267 /wd4996)
	target_link_options(extension PRIVATE /NODEFAULTLIB:LIBCMT /NODEFAULTLIB:LIBCMTD)
endif()
