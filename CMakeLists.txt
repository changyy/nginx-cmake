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

set(TOOL_NGINX_SOURCE nginx-1.2.8.tar.gz)
set(TOOL_NGINX_DIR nginx-1.2.8)
set(SELF_PRECONFIG_OPTIONS "")
#set(CONFIG_ADD_OPTIONS "--prefix=${CMAKE_BINARY_DIR}/nginx-out;--with-pcre=${CMAKE_BINARY_DIR}/pcre-8.32;--with-zlib=${CMAKE_BINARY_DIR}/zlib-1.2.7;--with-openssl=${CMAKE_BINARY_DIR}/openssl-1.0.1e;--with-sha1=${CMAKE_BINARY_DIR}/sha;")
#set(CONFIG_ADD_OPTIONS "--prefix=${CMAKE_BINARY_DIR}/nginx-out;--with-pcre=${CMAKE_BINARY_DIR}/pcre-8.32;--with-zlib=${CMAKE_BINARY_DIR}/libz-cmake/zlib-1.2.8;--with-openssl=${CMAKE_BINARY_DIR}/libssl-cmake/openssl-1.0.1e;--with-sha1=${CMAKE_BINARY_DIR}/sha;")
set(CONFIG_ADD_OPTIONS "--prefix=${CMAKE_BINARY_DIR}/nginx-out;--with-pcre=${CMAKE_BINARY_DIR}/pcre-8.32;--with-zlib=${CMAKE_BINARY_DIR}/libz-cmake/zlib-1.2.8;--with-sha1=${CMAKE_BINARY_DIR}/sha;")
#set(CONFIG_ADD_OPTIONS "--prefix=${CMAKE_BINARY_DIR}/nginx-out;--with-pcre=${CMAKE_BINARY_DIR}/pcre-8.32;--with-zlib=${CMAKE_BINARY_DIR}/zlib-1.2.7")
	if(NOT DEFINED ENABLE_HTTPS)
		message( "[nginx] https is disable (add -DENABLE_HTTPS:bool=on to switch on)" )
	else(NOT DEFINED ENABLE_HTTPS)
		message( "[nginx] https is enable (remove -DENABLE_HTTPS:bool=${ENABLE_HTTPS} to switch off)" )
		set(CONFIG_ADD_OPTIONS "${CONFIG_ADD_OPTIONS};--with-http_ssl_module")
	endif(NOT DEFINED ENABLE_HTTPS)


	if(DEFINED CMAKE_TOOLCHAIN_FILE)
		add_custom_command(
			OUTPUT BUILD_NGINX
			# libpcre
			COMMAND test -e ${CMAKE_CURRENT_SOURCE_DIR}/pcre-8.32.tar.bz2 || wget http://downloads.sourceforge.net/project/pcre/pcre/8.32/pcre-8.32.tar.bz2 -O ${CMAKE_CURRENT_SOURCE_DIR}/pcre-8.32.tar.bz2
			COMMAND tar -xjvf ${CMAKE_CURRENT_SOURCE_DIR}/pcre-8.32.tar.bz2
			# libsha
			COMMAND tar -xzvf ${CMAKE_CURRENT_SOURCE_DIR}/libsha-0.8.2b.tar.gz
			# nginx source
			COMMAND test -e ${CMAKE_CURRENT_SOURCE_DIR}/${TOOL_NGINX_SOURCE} || wget http://nginx.org/download/${TOOL_NGINX_SOURCE} -O ${CMAKE_CURRENT_SOURCE_DIR}/${TOOL_NGINX_SOURCE}
			COMMAND tar -xzvf ${CMAKE_CURRENT_SOURCE_DIR}/${TOOL_NGINX_SOURCE}
			# configure
			COMMAND cd ${TOOL_NGINX_DIR} && cp ${CMAKE_CURRENT_SOURCE_DIR}/nginx-remote-check.sh auto/ && sh ${CMAKE_CURRENT_SOURCE_DIR}/nginx-patch-with-device.sh . ${target_platform} ${REMOTE_DEVICE_SSH_LOGIN} && time ${target_platform_preconfigure_options} ${SELF_PRECONFIG_OPTIONS} ./configure ${CONFIG_ADD_OPTIONS} --with-cc-opt="-I${CMAKE_BINARY_DIR}/include" --with-ld-opt="-L${CMAKE_BINARY_DIR}/lib" && make && make install
			WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
			COMMENT "Build nginx"
		)
	else(DEFINED CMAKE_TOOLCHAIN_FILE)
		add_custom_command(
			OUTPUT BUILD_NGINX
			# libpcre
			COMMAND test -e ${CMAKE_CURRENT_SOURCE_DIR}/pcre-8.32.tar.bz2 || wget http://downloads.sourceforge.net/project/pcre/pcre/8.32/pcre-8.32.tar.bz2 -O ${CMAKE_CURRENT_SOURCE_DIR}/pcre-8.32.tar.bz2
			COMMAND tar -xjvf ${CMAKE_CURRENT_SOURCE_DIR}/pcre-8.32.tar.bz2
			# libsha
			COMMAND tar -xzvf ${CMAKE_CURRENT_SOURCE_DIR}/libsha-0.8.2b.tar.gz
			# nginx source
			COMMAND test -e ${CMAKE_CURRENT_SOURCE_DIR}/${TOOL_NGINX_SOURCE} || wget http://nginx.org/download/${TOOL_NGINX_SOURCE} -O ${CMAKE_CURRENT_SOURCE_DIR}/${TOOL_NGINX_SOURCE}
			COMMAND tar -xzvf ${CMAKE_CURRENT_SOURCE_DIR}/${TOOL_NGINX_SOURCE}
			# configure
			COMMAND cd ${CMAKE_BINARY_DIR}/${TOOL_NGINX_DIR} && ./configure ${CONFIG_ADD_OPTIONS} --with-cc-opt="-I${CMAKE_BINARY_DIR}/include" --with-ld-opt="-L${CMAKE_BINARY_DIR}/lib" && make && make install
			WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
			COMMENT "Build nginx" 
		)
	endif(DEFINED CMAKE_TOOLCHAIN_FILE)
	add_custom_target(build_nginx ALL DEPENDS ${SELF_DEPENDS} BUILD_NGINX )
