#!/usr/bin/bash

#args: <os_code> <os_bld>

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

sed "s/BE_NAME/${BE_NAME}/g" ai-manifest-template.xml > ai.1.xml
sed "s/OS_BRANCH_NO/${OS_BRANCH_NO}/g" ai.1.xml > ai.2.xml
sed "s/OS_IPS_REPO/${OS_IPS_REPO}/g" ai.2.xml > ai.xml

rm -rf ai.1.xml ai.2.xml
