#!/bin/sh
sed -i 's/\/bin\/sh -c \$NGX_AUTOTEST/auto\/nginx-remote-check.sh \$NGX_AUTOTEST/g' $1/auto/feature
sed -i 's/`\$NGX_AUTOTEST`/`auto\/nginx-remote-check.sh \$NGX_AUTOTEST`/g' $1/auto/feature
sed -i 's/$NGX_AUTOTEST >\/dev\/null 2>&1/auto\/run $NGX_AUTOTEST >\/dev\/null 2>&1/g' $1/auto/endianness
sed -i 's/ngx_size=`$NGX_AUTOTEST`/ngx_size=`auto\/nginx-remote-check.sh $NGX_AUTOTEST`/g' $1/auto/types/sizeof
sed -i 's/uname -r/auto\/nginx-remote-check.sh uname -r/g' $1/auto/os/linux
sed -i 's/distclean/distclean 2>\/dev\/null 1>\/dev\/null/g' $1/auto/lib/pcre/make
if [ ! -z $2 ] ; then
	sed -i "s/--disable-shared /--disable-shared --host=\"$2\" /g" $1/auto/lib/pcre/make
fi
if [ ! -z $3 ] ; then
	ssh-keygen -t rsa -f $1/auto/remote-ssh-key -N ""
	scp auto/remote-ssh-key.pub $3:
	ssh $3 "cat remote-ssh-key.pub >> ~/.ssh/authorized_keys ; chmod 600 ~/.ssh/authorized_keys"
	sed -i "s/localhost/$3/g" $1/auto/nginx-remote-check.sh
fi
