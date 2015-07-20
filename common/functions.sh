#!/usr/bin/bash

EXIT_OK=0
EXIT_BAD=1

AITIMESTAMP="`date +%s`"
AITEMPLATE="/net/hcts.cn.oracle.com/export/automation/aimanifests/ai-manifest-template.xml"
AIMANIFESTFILE_1="/net/hcts.cn.oracle.com/export/aimanifest/ai-$AITIMESTAMP.1.xml"
AIMANIFESTFILE_2="/net/hcts.cn.oracle.com/export/aimanifest/ai-$AITIMESTAMP.2.xml"
AIMANIFESTFILE="/net/hcts.cn.oracle.com/export/aimanifest/ai-$AITIMESTAMP.xml"


##
### initiate the environment.
##
# autofs  oraldap ssh-permitrootlogin x86-firstboot



##
### the following three functions aim at parameters check.
##
function hostnamechk() {
	# check if hostname exists or is supported
	# args: <hostname>
	# exist&support, returns EXIT_OK
	case "$1" in
		"bluesea"|"blueriver"|"bluewhite"|"blueblack"|"bluebox"|"goldbox"|"goldfinger"|"goldmemory"|"goldeye"|"goldcloth"|"goldcoast"|"firering"|"fireship"|"woodshoe"|"woodfence"|"shipfish")
			echo "hostnamechk: $1 is OK."
			;;
		"*")
			echo "hostnamechk: $1 in supported now."
			return $EXIT_BAD
			;;
	esac

	return $EXIT_OK
}

function osbuildchk() {
	# check if solaris version and build exists
	# args: <os_rel> <os_bld>
	# exist&support, returns EXIT_OK

	curpwd=`pwd`
	case "$1" in
		"s11u3")
			cd /net/nana/nana/products/Solaris_11/s11.3/;
			;;
		"s12")
			cd /net/nana/nana/products/Solaris_12/s12.0/;
			;;
		"*")
			echo "osbuildchk: $1 not supported now.\nCurrentlysupported: s11u3, s12."
			return $EXIT_BAD
			;;
	esac

	if [ -d "$2" ]; then
		echo "osbuildchk: $1 $2 is OK."
		cd $curpwd
	else
		echo "osbuildchk: $1 has no build of $2!\nPlease check the os version and build No."
		cd $curpwd
		return $EXIT_BAD
	fi

	return $EXIT_OK
}

function hctsbuildchk() {
	# check if hcts version and build exists
	# args: <hcts_ver> <hcts_bld>
	# exist&suppost, returns EXIT_OK

	curpwd=`pwd`
	if [ "$1" != "5.6" -a "$1" != "5.7" ]; then
		echo "hctsbuildchk: $1 not supported now.\nCurrently hcts supported versions: 5.6, 5.7"
		return $EXIT_BAD;
	fi
	
	cd /net/emei/projects/HCTS/Build/Build$1;
	if [ -d "$2" ]; then
		echo "hctsbuildchk: $1 $2 is OK."
		cd $curpwd
	else
		echo "hctsbuildchk: $1 has no build of $2.\nPlease check hcts version and build."
		cd $curpwd
		return $EXIT_BAD
	fi

	return $EXIT_OK
}


##
### the following are Solaris Installation related functions
##
function osneedsinst() {

	return $EXIT_OK
}

function aimanifestgen() {
	# generate ai-manifest according to templates in dir aimanifests
	# args: <os_rel> <os_bld>
	# new one locates in/net/hcts.cn.oracle.com/export/aimanifest

	case "$1" in
		"s11u3")
			BE_NAME="$1_$2"
			OS_BRANCH_NO="0.5.11-0.175.3.0.0.$2.0"
			OS_IPS_REPO="s11u3"
			;;
		"s12")
			BE_NAME="$1_$2"
			OS_BRANCH_NO="5.12-5.12.0.0.0.$2.0"
			OS_IPS_REPO="s12"
			;;
	esac

	sed "s/BE_NAME/${BE_NAME}/g" $AITEMPLATE > $AIMANIFESTFILE_1
	sed "s/OS_BRANCH_NO/${OS_BRANCH_NO}/g" $AIMANIFESTFILE_1 > $AIMANIFESTFILE_2
	sed "s/OS_IPS_REPO/${OS_IPS_REPO}/g" $AIMANIFESTFILE_2 > $AIMANIFESTFILE
	chmod 755 $AIMANIFESTFILE
	rm -rf $AIMANIFESTFILE_1 $AIMANIFESTFILE_2

	return $EXIT_OK
}

function getarch() {
	# return given machine's platform
	# args: <hostname>
	case "$1" in
		"bluewhite"|"blueriver"|"goldbox"|"goldmemory"|"goldfinger")
			arch="i386"
			;;
		"blueblack"|"bluesea"|"bluebox"|"goldeye"|"firering"|"fireship"|"woodshoe"|"woodfence"|"shipfish")
			arch="sparc"
			;;
	esac
	echo $arch

	return $EXIT_OK
}

function addclient() {
	# run /ws/opg-lab-tools/addclient.pl
	# args: <os_bld> <hostname> <os_rel> <arch>

	/ws/opg-lab-tools/addclient.pl --manifest=$AIMANIFESTFILE --build=$1 $2 $3 $4
	if [ "$?" == "0" ]; then
		echo "addclient: $2 $3 $1 OK"
	else
		echo "addclient: $2 $3 $1 FAIL"
		return $EXIT_BAD
	fi

	return $EXIT_OK
}

function delclient() {
	# disable netboot to avoid repeatly installation
	# args: <hostname>
	echo "/ws/opg-lab-tools/addclient.pl --disable-netboot $1" | at now + 12 minutes
	if [ "$?" == "0" ]; then
		echo "delclient: $1 OK"
	else
		echo "delclient: $1 FAIL"
		return $EXIT_BAD
	fi
	return $EXIT_OK
}

function rbtclient() {
	# reboot client for netinstall
	# args: <hostname>
	sed "/$1/d" $HOME/.ssh/known_hosts > $HOME/.known_hosts_tmp
	mv $HOME/.known_hosts_tmp $HOME/.ssh/known_hosts

	expect /net/hcts.cn.oracle.com/export/automation/localscripts/

}
