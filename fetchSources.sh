#!/bin/bash
[ "$(whoami)" != 'root' ] && ( echo you are using a non-privileged account; exit 1 )

#install all dependances 
dnf -y install wget git curl gcc m4 perl autoconf automake libtool make patch python maven gcc-c++

#disable seLinux
#echo 0 > /selinux/enforce
#stoping firewall
systemctl stop firewalld.service

#removing all software i will install
dnf -y remove httpd apr apr-util tomcat mod_cluster

cd ~
#download binaries
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

#compiling pcre
cd ~/pcre-8.38
./configure --prefix=/usr                     \
            --docdir=/usr/share/doc/pcre-8.38 \
            --enable-unicode-properties       \
            --enable-pcre16                   \
            --enable-pcre32                 &&
make
make install                     &&
mv -v /usr/lib/libpcre.so.* /lib &&
ln -sfv ../../lib/$(readlink /usr/lib/libpcre.so) /usr/lib/libpcre.so


#compiling httpd
APACHE-PREFIX="/opt/DU/httpd-build"
cd ~/httpd-2.4.12
./configure --with-included-apr --prefix=${APACHE-PREFIX} 
             --with-mpm=worker \
             --enable-mods-shared=most \
             --enable-maintainer-mode \
             --with-expat=builtin \
             --enable-proxy \
             --enable-proxy-http \
             --enable-proxy-ajp \
             --enable-so \
             --disable-proxy-balancer && 
make &&
make install
# seting modules for apache
cp ${APACHE-PREFIX}/conf/httpd.conf ${APACHE-PREFIX}/conf/httpd.conf_backup
sed -i 's/#LoadModule proxy_module/LoadModule proxy_module/g;s/#LoadModule proxy_ajp_module/LoadModule proxy_ajp_module/g;s/#LoadModule slotmem_module/LoadModule slotmem_module/g;s/#LoadModule manager_module/LoadModule manager_module/g;s/#LoadModule proxy_cluster_module/LoadModule proxy_cluster_module/g;s/#LoadModule advertise_module/LoadModule advertise_module/g' ${APACHE-PREFIX}/conf/httpd.conf


#mod_cluster
cd ~
git clone https://github.com/modcluster/mod_cluster.git

#Compile proxy_cluster
cd ~/mod_cluster/native/mod_proxy_cluster
./buildconf; ./configure --with-apxs=${APACHE-PREFIX}/bin/apxs; make; cp *.so ${APACHE-PREFIX}/modules/
#compile  advertise
cd ~/mod_cluster/native/advertise
./buildconf; ./configure --with-apxs=${APACHE-PREFIX}/bin/apxs; make; cp *.so ${APACHE-PREFIX}/modules/
#compile mod_manager
cd ~/mod_cluster/native/mod_manager
./buildconf; ./configure --with-apxs=${APACHE-PREFIX}/bin/apxs; make; cp *.so ${APACHE-PREFIX}/modules/
#compile mod_slotmem
cd ~/mod_cluster/native/mod_cluster_slotmem
./buildconf; ./configure --with-apxs=${APACHE-PREFIX}/bin/apxs; make; cp *.so ${APACHE-PREFIX}/modules/




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
