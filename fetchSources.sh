#!/bin/bash
[ "$(whoami)" != 'root' ] && ( echo you are using a non-privileged account; exit 1 )
SUCESS=0
#yum-config-manager --add-repo repository_url
#yum-config-manager --enable repository
if $SUCESS
  then
  touch fetchSucess
fi
