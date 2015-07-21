#!/usr/bin/bash

if [ ! -d ".ssh" ];then
	mkdir .ssh
fi

cat id_rsa.pub > .ssh/authorized_keys


