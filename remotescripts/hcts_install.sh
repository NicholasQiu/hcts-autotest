#!/usr/bin/bash

# args: <hostname> <arch> <hcts_ver> <hcts_bld>

test "$2" == "sparc" && HCTS_PKG="hcts.$3-sparc.tar.gz" || \
	HCTS_PKG="hcts.$3.tar.gz"

cp /net/emei/projects/HCTS/Build/Build$3/$4/$HCTS_PKG /root
tar zxf $HCTS_PKG

cd hcts.$3 
cat > hcts_install.exp << EOF
#/usr/bin/expect -f

spawn pkgadd -d . SUNWhcts
set timeout 20

expect {
	timeout {
		send_user "timeout!"
		exp_exit
	}
	"Do you want to continue with the installation of <SUNWhcts>" {
		send -- "y\r"
		interact
	}
}
EOF

expect hcts_install.exp
