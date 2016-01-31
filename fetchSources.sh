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
pwd
echo "./configure --prefix=/usr                     \
            --docdir=/usr/share/doc/pcre-8.38 \
            --enable-unicode-properties       \
            --enable-pcre16                   \
            --enable-pcre32 && make ; make install   &&"
sleep 5

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
ApachePrefix="/opt/DU/httpd-build"
cd ~/httpd-2.4.12
pwd
echo "./configure --with-included-apr --prefix=${ApachePrefix} \ 
             --with-mpm=worker \
             --enable-mods-shared=most \
             --enable-maintainer-mode \
             --with-expat=builtin \
             --enable-proxy \
             --enable-proxy-http \
             --enable-proxy-ajp \
             --enable-so \
"
sleep 5
./configure --with-included-apr --prefix=${ApachePrefix} \
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

#mod_cluster
cd ~
git clone https://github.com/modcluster/mod_cluster.git
cd mod_cluster
git checkout 1.3.1.Final .

#Compile proxy_cluster
cd ~/mod_cluster/native/mod_proxy_cluster
./buildconf; ./configure --with-apxs=${ApachePrefix}/bin/apxs; make; cp *.so ${ApachePrefix}/modules/
#compile  advertise
cd ~/mod_cluster/native/advertise
./buildconf; ./configure --with-apxs=${ApachePrefix}/bin/apxs; make; cp *.so ${ApachePrefix}/modules/
#compile mod_manager
cd ~/mod_cluster/native/mod_manager
./buildconf; ./configure --with-apxs=${ApachePrefix}/bin/apxs; make; cp *.so ${ApachePrefix}/modules/
#compile mod_slotmem
cd ~/mod_cluster/native/mod_cluster_slotmem
./buildconf; ./configure --with-apxs=${ApachePrefix}/bin/apxs; make; cp *.so ${ApachePrefix}/modules/

#mod_cluster config file
cd ~
git clone https://gist.github.com/Karm/85cf36a52a8c203accce
cp ${ApachePrefix}/conf/httpd.conf ${ApachePrefix}/conf/httpd.conf_backup
cat 85cf36a52a8c203accce/mod_cluster.conf >> ${ApachePrefix}/conf/httpd.conf

#test if all works
echo "STARTING APACHE"
${ApachePrefix}/bin/apachectl start
sleep 5
curl localhost:6666/mcm |grep -i -n '<h1>mod_cluster/1.3.2.Final</h1>'
if [ $? -eq 0 ]; then echo "Mod_cluster is working, continue"; else echo "Mod_cluster is NOT working, exiting"; exit 1; fi

#ap_get_server_version()


#building mod_cluster for Tomcat
echo "Building mod_cluster with mvn"
sleep 5
cd ~/mod_cluster
mvn package -DskipTests

#jboss-logging library
cd ~
git clone https://github.com/jboss-logging/jboss-logging.git
cd ~/jboss-logging
echo "building jboss-logging with mvn"
sleep 5
mvn package -DskipTests

#Tomcat
cd ~
wget https://archive.apache.org/dist/tomcat/tomcat-8/v8.0.30/bin/apache-tomcat-8.0.30.zip
unzip apache-tomcat-8.0.30.zip
#cd apache-tomcat-8.0.30
#copiing libraries to Tomcat
cp ~/mod_cluster/core/target/*.jar ~/apache-tomcat-8.0.30/lib/.
cp ~/mod_cluster/container-spi/target/*.jar ~/apache-tomcat-8.0.30/lib/.
cp ~/mod_cluster/container/catalina/target/*.jar ~/apache-tomcat-8.0.30/lib/.
cp ~/mod_cluster/container/catalina-standalone/target/*.jar ~/apache-tomcat-8.0.30/lib/.
cp ~/mod_cluster/container/tomcat8/target/*.jar ~/apache-tomcat-8.0.30/lib/.
cp ~/jboss-logging/target/*.jar ~/apache-tomcat-8.0.30/lib/.

#setup Tomcat
myip=$(ifconfig end0s3 | sed -n '/enp0s3/,/netmask/p' | grep inet | awk '{print $2}')
sed -i 's/defaultHost="localhost"/defaultHost="localhost" jvmRoute="jvm1"/g' ~/apache-tomcat-8.0.30/conf/server.xml
sed -i 's/localhost/${myip}/g' ~/apache-tomcat-8.0.30/conf/server.xml


#starting tomcat server
chmod a+x apache-tomcat-8.0.30/bin/*.sh
echo "starting tomcat server"
sleep 5
sh apache-tomcat-8.0.30/bin/startup.sh
if [ $? -eq 0 ]; then echo "Tomcat starts, continue"; else echo "Tomcat is NOT working, exiting"; exit 1; fi
#testing tomcat
sleep 15
curl localhost:6666/mcm | grep -i -n '(ajp://'
if [ $? -eq 0 ]; then echo "Tomcat worker starts, continue"; else echo "Tomcat worker is NOT working, exiting"; exit 1; fi

#testing application
cd
wget https://github.com/Karm/clusterbench/archive/simplified-and-pure.zip
unzip simplified-and-pure.zip
cd simplified-and-pure
mvn package -DskipTests
cp clusterbench-ee6-web/target/clusterbench.war ~/apache-tomcat-8.0.30/webapps/
sleep 15
curl localhost:6666/clusterbench/requestinfo | grep -i "JVM route: jvm1"
if [ $? -eq 0 ]; then echo "Application is up and running, job is done"; else echo "something goes wrong at last step, exiting"; exit 1; fi

exit 0

