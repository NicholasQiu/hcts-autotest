#!/usr/bin/bash

pkginfo SUNWhcts
if [ "$?" == "0" ]; then

cat > hcts_remove.exp << EOF
#/usr/bin/expect -f

spawn pkgrm SUNWhcts
set timeout 20

expect {
	timeout {
		send_user "timeout!"
		exp_exit
	}
	"Do you want to remove this package?" {
		send -- "y\r"
		exp_continue
	}
	"Do you want to continue with the removal of this package" {
		send -- "y\r"
		interact
	}
}
EOF

expect hcts_remove.exp
rm -rf hcts_remove.exp

rm -rf /var/hcts/*
	
else
	exit 0
fi
