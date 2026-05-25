cmake_minimum_required(VERSION 3.10)

if(POLICY CMP0141)
	cmake_policy(SET CMP0141 NEW)
	set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT "$<$<CONFIG:Debug,RelWithDebInfo>:ProgramDatabase>")
endif()

project(hlfreetype LANGUAGES C)

add_subdirectory(extension)
