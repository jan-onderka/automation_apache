#!/bin/bash
[ "$(whoami)" != 'root' ] && ( echo you are using a non-privileged account; exit 1 )
SUCESS=0
#apache v2.4.12
if [ dnf info httpd | sed -n '/Instal/,/Description/p' | grep Version | awk '{print $3}' != '2.4.12' ] ; then
    echo not work
fi

exit $SUCESS
