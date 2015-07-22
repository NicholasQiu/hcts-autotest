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

function envinit() {
	# verify the current host ready for hcts automation
	if [ $(svcs -a | grep autofs | grep online) -ne 0 ]; then
		svcadm enable svc:/system/filesystem/autofs:default
		if [ "$?" != "0" ]; then
			echo "envinit: autofs not online."
			return $EXIT_BAD
		fi
	fi

	cd /ws/opg-lab-tools/ || {
		/net/hcts.cn.oracle.com/export/automation/localscripts/oraldap init-ldapswitch
		if [ "$?" != "0" ]; then
			echo "envinit: init ldapswitch fail."
			return $EXIT_BAD
		fi
	}

	# verify the remote client PermitRootLogin
	# this part to be continued?

	return $EXIT_OK
}


##
### ssh without password related functions
##
function sshkeypairgen() {
	# generate ssh public/private key pair if it needs
	if [ ! -f "$HOME/.ssh/id_rsa" ] || [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
		expect /net/hcts.cn.oracle.com/export/automation/localscripts/ssh_key_gen.exp
	fi

	return $EXIT_OK
}

function ssh_copy_id() {
	# copy and cat the id_rsa.pub to remote machine's authorized
	# args: <hostname>
	sed "/$1/d" $HOME/.ssh/known_hosts > /root/.known_hosts_tmp
	mv /root/.known_hosts_tmp > $HOME/.ssh/known_hosts

	expect /net/hcts.cn.oracle.com/export/automation/localscripts/scp_id_rsa.exp $1
	expect /net/hcts.cn.oracle.com/export/automation/localscripts/scp_ssh_copy_id.exp $1
	expect /net/hcts.cn.oracle.com/export/automation/localscripts/exec_ssh_copy_id.exp $1

	return $EXIT_OK
}

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
	# check if the machine needs solaris installation
	# args: <hostname> <os_rel> <os_bld>

	sed "/$1/d" $HOME/.ssh/known_hosts > $HOME/.known_hosts_tmp
	mv $HOME/.known_hosts_tmp $HOME/.ssh/known_hosts

	ssh_copy_id $1
	if [ "$?" != "0" ]; then
		echo "osneedsinst: ssh copy id FAIL"
		return $EXIT_BAD
	fi

	branch=`ssh root@$1 pkg info entire | grep Branch | \
		awk -F: '{print $2}' | \
		sed 's/^ *//g;s/ *$//g'`

	case "$2" in
		"s11u3")
			Branch="0.175.3.0.0.$3.0"
			;;
		"s12")
			Branch="5.12.0.0.0.$3.0"
			;;
	esac

	if [ "$branch" == "$Branch" ]; then
		echo "osneedsinst: No need installation."
		return $EXIT_BAD
	fi

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

	expect /net/hcts.cn.oracle.com/export/automation/localscripts/scp_rbt_script.exp $1
	expect /net/hcts.cn.oracle.com/export/automation/localscripts/exec_rbt_script.exp $1

	return $EXIT_OK
}

function osverify() {
	# make sure the given solaris is installed on the machine
	# args: <hostname> <os_rel> <os_bld>

	ping $1
	if [ "$?" != "0" ]; then
		echo "osverify: ping $1 FAIL"
		return $EXIT_BAD
	fi

	ssh_copy_id $1
	if [ "$?" != "0" ]; then
		echo "osverify: ssh copy id FAIL"
		return $EXIT_BAD
	fi

	branch=`ssh root@$1 pkg info entire | grep Branch | \
		awk -F: '{print $2}' | \
		sed 's/^ *//g;s/ *$//g'`

	case "$2" in
		"s11u3")
			Branch="0.175.3.0.0.$3.0"
			;;
		"s12")
			Branch="5.12.0.0.0.$3.0"
			;;
	esac

	if [ "$branch" != "$Branch" ]; then
		echo "osverify: Branch No. dismatch. Installation FAIL"
		return $EXIT_BAD
	fi

	return $EXIT_OK
}



##
### hcts installation related part
##

function hctsinstall() {
	# args: <hostname> <hcts_ver> <hcts_bld>
	arch=`getarch $1`
	scp /net/hcts.cn.oracle.com/export/automation/remotescripts/hcts_install.sh root@$1:/root
	ssh root@$1 "/root/hcts_install.sh $1 ${arch} $2 $3"

	return $EXIT_OK
}

function hctsreservenet0() {
	ssh root@$1 "echo 'net0' > /opt/SUNWhcts/etc/exclude.conf"
	return $EXIT_OK
}

function hctsreconfigure() {
	scp /net/hcts.cn.oracle.com/export/automation/remotescripts/hcts_reconfigure.exp root@$1:/root
	ssh root@$1 "expect -f /root/hcts_reconfigure.exp"

	return $EXIT_OK
}


##
### clean tempary scripts
##

function remoteclean() {
	# remove tempary scripts on remote machine
	# args: <hostname>

	ssh root@$1 "rm -rf /root/hcts_install.sh /root/hcts_reconfigure.exp"

	return $EXIT_OK
}
