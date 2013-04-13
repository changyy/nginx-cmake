nginx-cmake
===========
Normal Usage:
<pre>
$ git clone --recursive https://github.com/changyy/nginx-cmake.git
$ cd nginx-cmake
$ mkdir build
$ cd build
$ cmake ..
$ make
$ ./nginx-out/sbin/nginx -p ./nginx-out/
</pre>

Cross Compiler (Testing on ARM Device):
<pre>
$ git clone --recursive https://github.com/changyy/nginx-cmake.git
$ cd nginx-cmake
$ mkdir build
$ cd build
$ cmake .. -DCMAKE_TOOLCHAIN_FILE=/path/toolchain-arm6.cmake
...
CMake Error at CMakeLists.txt:14 (message):
  Please use -DREMOTE_DEVICE_SSH_LOGIN='account@remote_device_ip' again (need
  sshd & scp service)
...
$ cmake .. -DCMAKE_TOOLCHAIN_FILE=/path/toolchain-arm6.cmake -DREMOTE_DEVICE_SSH_LOGIN='root@192.168.168.168'
$ make
$ scp -r ./nginx-out root@192.168.168.168:/tmp
$ ssh root@192.168.168.168 "/tmp/nginx-out/sbin/nginx -p /tmp/nginx-out/"
(need to check the shared library used by sbin/ngix: readelf -a sbin/nginx | grep Shared)
</pre>

Thanks for this sharing: [Ali's blog: Cross-compile nginx 1.3.6](http://r1729.blogspot.tw/2012/10/cross-compile-nginx-136.html) & [YangAcer](https://github.com/yangacer)'s help.
