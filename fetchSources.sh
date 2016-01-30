#!/bin/bash
[ "$(whoami)" != 'root' ] && ( echo you are using a non-privileged account; exit 1 )

#install all dependances 
dnf -y install wget git curl gcc m4 perl autoconf automake libtool make patch python maven

#disable seLinux
#echo 0 > /selinux/enforce
#stoping firewall
systemctl stop firewalld.service

#removing all software i will install
dnf -y remove httpd apr apr-util tomcat mod_cluster

cd ~
#apache v2.4.12
myAPP="httpd"
myVER="2.4.12"
wget http://archive.apache.org/dist/httpd/httpd-2.4.12.tar.gz
tar xf httpd-2.4.12.tar.gz
wget https://archive.apache.org/dist/apr/apr-1.5.1.tar.gz
tar xf apr-1.5.1.tar.gz
mv apr-1.5.1 httpd-2.4.12/srclib/apr
wget https://archive.apache.org/dist/apr/apr-util-1.5.4.tar.gz
tar xf apr-util-1.5.4.tar.gz
mv apr-util-1.5.4 httpd-2.4.12/srclib/apr-util
wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.38.tar.gz
tar xf pcre-8.38.tar.gz
cd pcre-8.38
./configure --prefix=/usr                     \
            --docdir=/usr/share/doc/pcre-8.38 \
            --enable-unicode-properties       \
            --enable-pcre16                   \
            --enable-pcre32                   \
            --enable-pcregrep-libz            \
            --enable-pcregrep-libbz2          \
            --enable-pcretest-libreadline     \
            --disable-static                 &&
make
make install                     &&
mv -v /usr/lib/libpcre.so.* /lib &&
ln -sfv ../../lib/$(readlink /usr/lib/libpcre.so) /usr/lib/libpcre.so


#compiling httpd
cd httpd-2.4.12
./configure --with-included-apr --with-pcre

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
    wget https://archive.apache.org/dist/apr/apr-1.5.1.tar.gz
else 
    echo apr works
fi

#apr-util 1.5.4
myAPP="apr-util"
myVER="1.5.4"
if [ "$(dnf info apr_util | sed -n '/Instal/,/Description/p' | grep Version | awk '{print $3}')" != '1.5.4' ] ; then
    dnf -y install apr_util-1.5.4
    wget https://archive.apache.org/dist/apr/apr-util-1.5.4.tar.gz
else 
    echo apr util works
fi

#Tomcat
wget https://archive.apache.org/dist/tomcat/tomcat-8/v8.0.30/bin/apache-tomcat-8.0.30.zip

exit 0
