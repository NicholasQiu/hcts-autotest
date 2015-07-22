#!/usr/bin/bash

. /net/hcts.cn.oracle.com/export/automation/common/functions.sh

E_ENVINIT=85
E_HOSTNAMECHK=86
E_OSBUILDCHK=87
E_HCTSBUILDCHK=88
E_AIGEN=89
E_ADDCLIENT=90
E_DELCLIENT=91
E_RBTCLIENT=92
E_OSVERIFY=93
E_HCTSINST=94
E_HCTSRESERVNET0=95
E_HCTSRECONF=96


function usage() {
	echo "Usage: "
	echo "$0 <hostname> <os_rel> <os_bld> <hcts_ver> <hcts_bld>"
	echo "Example: $0 bluesea s11u3 26 5.7 15"
	return $EXIT_OK
}


function autoinstall() {
	# install solaris & hcts
	# args: <hostname> <os_rel> <os_bld> <hcts_ver> <hcts_bld>
	envinit $1 || {
		echo "Local Environment Init Fail."
		return $E_ENVINIT
	}
	sshkeypairgen

	hostnamechk $1 || {
		echo "Hostname Check Fail."
		return $E_HOSTNAMECHK
	}
	osbuildchk $2 $3 || {
		echo "Solaris Check Fail."
		return $E_OSBUILDCHK
	}
	hctsbuildchk $4 $5 || {
		echo "HCTS Check Fail."
		return $E_HCTSBUILDCHK
	}

	osneedsinst $1 $2 $3 && {
		aimanifestgen $2 $3 || {
			echo "AI Generation Fail."
			return $E_AIGEN
		}
		arch=`getarch $1`
		addclient $3 $1 $2 ${arch} || {
			echo "Addclient Fail."
			return $E_ADDCLIENT
		}
		delclient $1 || {
			echo "Delclient Fail."
			return $E_DELCLIENT
		}
		rbtclient $1 || {
			echo "Reboot Client Fail."
			return $E_RBTCLIENT
		}
		sleep 1800
	}

	osverify $1 $2 $3 || {
		echo "Solaris Verify Fail."
		return $E_OSVERIFY
	}
	hctsinstall $1 $4 $5 || {
		echo "HCTS Installation Fail."
		return $E_HCTSINST
	}
	hctsreservenet0 $1 || {
		echo "HCTS Exclude NET0 Fail."
		return $E_HCTSRESERVNET0
	}
	hctsreconfigure $1 || {
		echo "HCTS Reconfigure Fail."
		return $E_HCTSRECONF
	}

	return $EXIT_OK
}

# -- Main -- #
if [ $# -ne 5 ]; then
	usage
	exit $EXIT_BAD
fi
autoinstall $1 $2 $3 $4 $5
