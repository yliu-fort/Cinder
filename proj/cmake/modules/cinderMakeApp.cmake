include( CMakeParseArguments )

function( ci_make_app )
	set( oneValueArgs APP_NAME CINDER_PATH )
	set( multiValueArgs SOURCES )

	cmake_parse_arguments( ARG "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

	if( NOT ARG_APP_NAME )
		set( ARG_APP_NAME "${PROJECT_NAME}" )
	endif()

	if( ARG_UNPARSED_ARGUMENTS )
		message( WARNING "unhandled arguments: ${ARG_UNPARSED_ARGUMENTS}" )
	endif()

	if( NOT CMAKE_BUILD_TYPE )
		message( STATUS "Setting default CMAKE_BUILD_TYPE to Debug" )
		set( CMAKE_BUILD_TYPE Debug CACHE STRING
			"Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel. "
			FORCE
			)
	endif()

	# CLion specific: If we can detect that the output binary app is going to be placed in clion's cache,
	# reroute it to be within the user app's project. This is necessary for cinder's assets systemt o work.
	if( ${CMAKE_BINARY_DIR} MATCHES "Caches/CLion" )
		set( CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/build/${CMAKE_BUILD_TYPE} )
		if( CINDER_BUILD_VERBOSE )
			message( WARNING "detected Clion output to cache, rerouted to sample directory: ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" )
		endif()
	endif()

	if( CINDER_BUILD_VERBOSE )
		message( STATUS "APP_NAME: ${ARG_APP_NAME}" )
		message( STATUS "SOURCES: ${ARG_SOURCES}" )
		message( STATUS "CINDER_PATH: ${ARG_CINDER_PATH}" )
		message( STATUS "CMAKE_RUNTIME_OUTPUT_DIRECTORY: ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" )
		message( STATUS "CMAKE_BINARY_DIR: ${CMAKE_BINARY_DIR}" )
	endif()


	# TODO: how can we keep these variabels in sync with how they're defined in main CMakeLists.txt?
	if( CMAKE_SYSTEM_NAME MATCHES "Darwin" )
		set( CINDER_TARGET "macosx" )
		set( CINDER_MAC TRUE )
	elseif( CMAKE_SYSTEM_NAME MATCHES "Linux" )
		set( CINDER_TARGET "linux" )
		set( CINDER_LINUX TRUE )
		execute_process( COMMAND uname -m COMMAND tr -d '\n' OUTPUT_VARIABLE CINDER_ARCH )
	elseif( CMAKE_SYSTEM_NAME MATCHES "Windows" )
		set( CINDER_TARGET "msw" )
		set( CINDER_MSW TRUE )
	else()
		message( FATAL_ERROR "CINDER_TARGET not defined, and no default for platform '${CMAKE_SYSTEM_NAME}.'" )
	endif()

	# pull in cinder's exported configuration
	if( NOT TARGET cinder )
		find_package( cinder REQUIRED
				PATHS "${ARG_CINDER_PATH}/lib/${CINDER_TARGET}/${CINDER_ARCH}/${CMAKE_BUILD_TYPE}/${CINDER_TARGET_GL}" 
				"$ENV{Cinder_Dir}/lib/${CINDER_TARGET}/${CINDER_ARCH}/${CMAKE_BUILD_TYPE}/${CINDER_TARGET_GL}" 
		)
	endif()

	if( CINDER_MAC )
		# set icon
		set( ICON_NAME "CinderApp.icns" )
		set( ICON_PATH "${ARG_CINDER_PATH}/samples/data/${ICON_NAME}" )

		# copy .icns to bundle's resources folder
		set_source_files_properties( ${ICON_PATH} PROPERTIES MACOSX_PACKAGE_LOCATION Resources )
	endif()

	add_executable( ${ARG_APP_NAME} MACOSX_BUNDLE WIN32 ${ARG_SOURCES} ${ICON_PATH} )

	target_link_libraries( ${ARG_APP_NAME} cinder )

	if( CINDER_MAC )
		# set bundle info.plist properties
		set_target_properties( ${ARG_APP_NAME} PROPERTIES
			MACOSX_BUNDLE_BUNDLE_NAME ${ARG_APP_NAME}
			MACOSX_BUNDLE_ICON_FILE ${ICON_NAME}
		)
	endif()

endfunction()
