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

#mod_cluster config file
cd ~
git clone https://gist.github.com/Karm/85cf36a52a8c203accce
cp ${APACHE-PREFIX}/conf/extra/httpd.conf ${APACHE-PREFIX}/conf/extra/httpd.conf_backup2
cat 85cf36a52a8c203accce/mod_cluster.conf >> ${APACHE-PREFIX}/conf/extra/httpd.conf

#test if all works
${APACHE-PREFIX}/bin/apachctl start
curl localhost:6666/mcm |grep -i -n '<h1>mod_cluster/1.3.2.Final</h1>'
if [ $? -eq 0 ]; then echo "Mod_cluster is working, continue"; else echo "it is NOT working, exiting"; exit 1; fi

#ap_get_server_version()


#building mod_cluster for Tomcat
cd ~/mod_cluster
mvn package -DskipTests

#jboss-logging library
cd ~
git clone https://github.com/jboss-logging/jboss-logging.git
cd ~/jboss-logging
mvn package -DskipTests

#Tomcat
cd ~
wget https://archive.apache.org/dist/tomcat/tomcat-8/v8.0.30/bin/apache-tomcat-8.0.30.zip
unzip apache-tomcat-8.0.30.zip
#cd apache-tomcat-8.0.30


exit 0
cp ~/mod_cluster/core/target/*.jar ~/apache-tomcat-8.0.30/lib/.
cp ~/mod_cluster/container-spi/target/*.jar ~/apache-tomcat-8.0.30/lib/.
cp ~/mod_cluster/container/catalina/target/*.jar ~/apache-tomcat-8.0.30/lib/.
cp ~/mod_cluster/container/catalina-standalone/target/*.jar ~/apache-tomcat-8.0.30/lib/.
cp ~/mod_cluster/container/tomcat8/target/*.jar ~/apache-tomcat-8.0.30/lib/.
