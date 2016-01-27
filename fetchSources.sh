#!/bin/bash
[ "$(whoami)" != 'root' ] && ( echo you are using a non-privileged account; exit 1 )

dnf -y install wget git curl gcc

#apache v2.4.12
myAPP="httpd"
myVER="2.4.12"
if [ "$(dnf info ${myAPP} | sed -n '/Instal/,/Description/p' | grep Version | awk '{print $3}')" != '${myVER}' ] ; then
    #dnf -y install httpd-2.4.12
    wget http://archive.apache.org/dist/httpd/${myAPP}-${myVER}.tar.gz
    tar -xf ${myAPP}-${myVER}.tar.gz #ternarni operator or maybe if    ? : echo fail to unpack archive ${myAPP}-${myVER}; exit 1
    if [ ! -d "${myAPP}-${myVER}" ] ; then
        echo fail to unpack archive ${myAPP}-${myVER}
        exit 1
    else
        #./${myAPP}-${myVER}/something....
    fi
else 
    echo apache works
fi

#apr 1.5.1
myAPP="apr"
myVER="1.5.1"
if [ "$(dnf info apr | sed -n '/Instal/,/Description/p' | grep Version | awk '{print $3}')" != '1.5.1' ] ; then
    dnf -y install apr-1.5.1
else 
    echo apr works
fi

#apr util 1.5.4
myAPP="apr_util"
myVER="1.5.4"
if [ "$(dnf info apr_util | sed -n '/Instal/,/Description/p' | grep Version | awk '{print $3}')" != '1.5.4' ] ; then
    dnf -y install apr_util-1.5.4
else 
    echo apr util works
fi

exit 0
