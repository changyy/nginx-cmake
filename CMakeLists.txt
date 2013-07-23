cmake_minimum_required(VERSION 2.8)
project (nginx)

if (DEFINED CMAKE_TOOLCHAIN_FILE)
	message("Include Cross Platform cmake: " ${CROSS_PLATFORM_CMAKE})
	get_filename_component(COMPILER_NAME ${CMAKE_C_COMPILER} NAME)
	message( "CMAKE_C_COMPILER: ${COMPILER_NAME}")
	string(REGEX REPLACE "(.*)-gcc" "\\1" target_platform "${COMPILER_NAME}")
	message( "target_platform: ${target_platform}")
	set(target_platform_preconfigure_options "CC=${target_platform}-gcc;AR=${target_platform}-ar;LD=${target_platform}-ld;RANLIB=${target_platform}-ranlib;NM=${target_platform}-nm;AS=${target_platform}-as;OBJDUMP=${target_platform}-objdump;OBJCOPY=${target_platform}-objcopy;STRIP=${target_platform}-strip;STRINGS=${target_platform}-strings;SIZE=${target_platform}-size")

	if(NOT DEFINED REMOTE_DEVICE_SSH_LOGIN)
		message( "" )
		message( FATAL_ERROR "Please use -DREMOTE_DEVICE_SSH_LOGIN='account@remote_device_ip' again (need sshd & scp service)" )
	endif(NOT DEFINED REMOTE_DEVICE_SSH_LOGIN)
endif(DEFINED CMAKE_TOOLCHAIN_FILE)

set(SELF_DEPENDS "")
if(NOT TARGET build_libz)
	add_subdirectory(libz-cmake)
endif(NOT TARGET build_libz)
set(SELF_DEPENDS "${SELF_DEPENDS};build_libz")

if(NOT TARGET build_libssl)
	add_subdirectory(libssl-cmake)
endif(NOT TARGET build_libssl)
set(SELF_DEPENDS "${SELF_DEPENDS};build_libssl")

if(NOT TARGET build_liblua)
	add_subdirectory(liblua-cmake)
endif(NOT TARGET build_liblua)
set(SELF_DEPENDS "${SELF_DEPENDS};build_liblua")

if(NOT TARGET build_NginxUploadModule)
	add_subdirectory(nginx-upload-module)
endif(NOT TARGET build_NginxUploadModule)
set(SELF_DEPENDS "${SELF_DEPENDS};build_NginxUploadModule")



set(TOOL_TARGET_NAME "build_nginx")
set(TOOL_TARGET_BUILD_OUTPUT "BUILD_NGINX")
set(TOOL_TARGET_COMMENT "build nginx")
set(TOOL_TARGET_SOURCE nginx-1.2.8.tar.gz)
set(TOOL_TARGET_DIR nginx-1.2.8)
#set(TOOL_TARGET_SOURCE nginx-1.4.1.tar.gz)
#set(TOOL_TARGET_DIR nginx-1.4.1)
set(TOOL_TARGET_PATCH ${TOOL_TARGET_DIR}.patch)
set(TOOL_TARGET_INSTALL_PREFIX ${CMAKE_BINARY_DIR})

set(SELF_PRECONFIG_OPTIONS "")
set(CONFIG_ADD_OPTIONS "--prefix=${TOOL_TARGET_INSTALL_PREFIX}/nginx-out;--with-pcre=${TOOL_TARGET_INSTALL_PREFIX}/pcre-8.32;--with-sha1=${TOOL_TARGET_INSTALL_PREFIX}/sha;--with-zlib=${TOOL_TARGET_INSTALL_PREFIX}/libz-cmake/zlib-1.2.8")

# nginx modules
set(CONFIG_ADD_OPTIONS "${CONFIG_ADD_OPTIONS};--add-module=${CMAKE_CURRENT_SOURCE_DIR}/modules/lua-nginx-module")
set(CONFIG_ADD_OPTIONS "${CONFIG_ADD_OPTIONS};--add-module=${CMAKE_CURRENT_SOURCE_DIR}/modules/mod_zip")
set(CONFIG_ADD_OPTIONS "${CONFIG_ADD_OPTIONS};--add-module=${CMAKE_CURRENT_SOURCE_DIR}/modules/nginx-upload-module")

	if(NOT DEFINED ENABLE_HTTPS)
		message( "[nginx] https is disable (add -DENABLE_HTTPS:bool=on to switch on)" )
	else(NOT DEFINED ENABLE_HTTPS)
		message( "[nginx] https is enable (remove -DENABLE_HTTPS:bool=${ENABLE_HTTPS} to switch off)" )
		set(CONFIG_ADD_OPTIONS "${CONFIG_ADD_OPTIONS};--with-http_ssl_module")
	endif(NOT DEFINED ENABLE_HTTPS)


	if(DEFINED CMAKE_TOOLCHAIN_FILE)
		add_custom_command(
			OUTPUT ${TOOL_TARGET_BUILD_OUTPUT}
			# libpcre
			COMMAND test -e ${CMAKE_CURRENT_SOURCE_DIR}/pcre-8.32.tar.bz2 || wget http://downloads.sourceforge.net/project/pcre/pcre/8.32/pcre-8.32.tar.bz2 -O ${CMAKE_CURRENT_SOURCE_DIR}/pcre-8.32.tar.bz2
			COMMAND tar -xjvf ${CMAKE_CURRENT_SOURCE_DIR}/pcre-8.32.tar.bz2
			# libsha
			COMMAND tar -xzvf ${CMAKE_CURRENT_SOURCE_DIR}/libsha-0.8.2b.tar.gz
			# nginx source
			COMMAND test -e ${CMAKE_CURRENT_SOURCE_DIR}/${TOOL_TARGET_SOURCE} || wget http://nginx.org/download/${TOOL_TARGET_SOURCE} -O ${CMAKE_CURRENT_SOURCE_DIR}/${TOOL_TARGET_SOURCE}
			COMMAND tar -xzvf ${CMAKE_CURRENT_SOURCE_DIR}/${TOOL_TARGET_SOURCE}
			# patch
			COMMAND test -e ${CMAKE_CURRENT_SOURCE_DIR}/${TOOL_TARGET_PATCH} && cd ${TOOL_TARGET_DIR} && patch -p1 < ${CMAKE_CURRENT_SOURCE_DIR}/${TOOL_TARGET_PATCH} && echo "use patch file: ${CMAKE_CURRENT_SOURCE_DIR}/${TOOL_TARGET_PATCH}" && touch ${CMAKE_CURRENT_BINARY_DIR}/_build_with_patch || echo "no patch file"
			# configure
			COMMAND cd ${TOOL_TARGET_DIR} && cp ${CMAKE_CURRENT_SOURCE_DIR}/nginx-remote-check.sh auto/ && sh ${CMAKE_CURRENT_SOURCE_DIR}/nginx-patch-with-device.sh . ${target_platform} ${REMOTE_DEVICE_SSH_LOGIN} && time ${target_platform_preconfigure_options} ${SELF_PRECONFIG_OPTIONS} ./configure ${CONFIG_ADD_OPTIONS} --with-cc-opt="-I${TOOL_TARGET_INSTALL_PREFIX}/include" --with-ld-opt="-L${TOOL_TARGET_INSTALL_PREFIX}/lib" && make && make install
			WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
			COMMENT "Build nginx"
		)
	else(DEFINED CMAKE_TOOLCHAIN_FILE)
		add_custom_command(
			OUTPUT ${TOOL_TARGET_BUILD_OUTPUT}
			# libpcre
			COMMAND test -e ${CMAKE_CURRENT_SOURCE_DIR}/pcre-8.32.tar.bz2 || wget http://downloads.sourceforge.net/project/pcre/pcre/8.32/pcre-8.32.tar.bz2 -O ${CMAKE_CURRENT_SOURCE_DIR}/pcre-8.32.tar.bz2
			COMMAND tar -xjvf ${CMAKE_CURRENT_SOURCE_DIR}/pcre-8.32.tar.bz2
			# libsha
			COMMAND tar -xzvf ${CMAKE_CURRENT_SOURCE_DIR}/libsha-0.8.2b.tar.gz
			# nginx source
			COMMAND test -e ${CMAKE_CURRENT_SOURCE_DIR}/${TOOL_TARGET_SOURCE} || wget http://nginx.org/download/${TOOL_TARGET_SOURCE} -O ${CMAKE_CURRENT_SOURCE_DIR}/${TOOL_TARGET_SOURCE}
			COMMAND tar -xzvf ${CMAKE_CURRENT_SOURCE_DIR}/${TOOL_TARGET_SOURCE}
			# patch
			COMMAND test -e ${CMAKE_CURRENT_SOURCE_DIR}/${TOOL_TARGET_PATCH} && cd ${TOOL_TARGET_DIR} && patch -p1 < ${CMAKE_CURRENT_SOURCE_DIR}/${TOOL_TARGET_PATCH} && echo "use patch file: ${CMAKE_CURRENT_SOURCE_DIR}/${TOOL_TARGET_PATCH}" && touch ${CMAKE_CURRENT_BINARY_DIR}/_build_with_patch || echo "no patch file"
			# configure
			COMMAND cd ${TOOL_TARGET_INSTALL_PREFIX}/${TOOL_TARGET_DIR} && ./configure ${CONFIG_ADD_OPTIONS} && make -j2 && make install
			WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
			COMMENT "Build nginx" 
		)
	endif(DEFINED CMAKE_TOOLCHAIN_FILE)
	add_custom_target(build_nginx ALL DEPENDS ${SELF_DEPENDS} ${TOOL_TARGET_BUILD_OUTPUT} )
