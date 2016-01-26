# automation_apache
instant project for interview

Assignment
==========
We would like you to complete the following steps comprising Apache HTTP Server,
its dependencies and mod_cluster module compilation with a small code modification.
Furthermore, it is required to build several Java libraries and download and 
install Tomcat servlet container.

The whole objective is to setup Apache HTTP Server as a proxy in front
of Tomcat servlet container.

Last but not least, we need you to create a script that automates everything
you did so as we could run it on a Fedora linux box connected to the Internet.

If you get stuck at any point, feel free to improvise, do something differently
or even modify the assignment itself.

Prepare Apache HTTP Server
--------------------------
1)
Fetch sources of the following projects from upstream:
 - Apache HTTP Server in version 2.4.12
 - APR 1.5.1
 - APR Util 1.5.4
 - mod_cluster 1.3.1.Final (directory "native")
and compile them on a Fedora system. You can build without mod_ssl or
crypto libraries. You will need numerous tools and dependencies, install them
one by one as Apache's Autotools configure script warnings will guide you.

2)
Prepare a functional Apache HTTP Server installation with mod_cluster
configured. For instance, if /opt/DU/httpd-build/ is the installation,
this is your mod_cluster config file: /opt/DU/httpd-build/conf/extra/mod_cluster.conf [1]

Start the server and navigate to mod_cluster manager console [2]

    curl localhost:6666/mcm

You should see that mod_cluster is operational:

    <h1>mod_cluster/1.3.1.Final</h1>

3)
Change the C code of Mod_cluster manager console so ad it contains
the version of Apache HTTP Server it currently runs with. Compile and
load the modules again.
The console should then look like this:

 <h1>Apache/2.4.12 (Unix) mod_cluster/1.3.1.Final</h1><h1>mod_cluster/1.3.1.Final</h1>

The Apache HTTP Server version must not be hardcoded, it must use the
Apache core function that spits out the version string.


Prepare Tomcat installation
---------------------------
1) 
Build mod_cluster Java libraries in the root of the mod_cluster project
you fetched in the previous step. Simply run:

    mvn package -DskipTests

The libraries you will need for the Tomcat 8 lib directory are:

    mod_cluster-container-catalina
    mod_cluster-container-catalina-standalone
    mod_cluster-container-spi
    mod_cluster-container-tomcat8
    mod_cluster-core

You will also need jboss-logging library. Clone jboss-logging project from
GitHub and build it with maven. You can -DskipTests.


2)
Download Tomcat 8 from Apache web site and unzip it. Browse mod_cluster documentation [3]
and configure mod_cluster Listener in server.xml.

Set connector address to IPv4 address of the box on eth0 and
set jvmRoute="XXX".
Copy the aforementioned libraries to the directory where Tomcat expects libraries.

3)
Start Tomcat and Apache.
You need to have SeLinux properly configured to allow UDP port 23364 and TCP
ports 23364, 8080, 8009 and to have the respective setting on you firewall;
or you could switch both off.

When you start both Apache and Tomcat, after some dozens of seconds at most,
you should see that Tomcat registered itself with the Apache HTTP Server
as a worker to which Apache could forward requests.

You could verify this by error_log on LogLevel Debug examination with
Apache HTTP Server or by accessing the Mod_cluster manager console on
Apache HTTP Server where you could see something like:


    <h1> Node XXX (ajp://192.168.122.118:8009): </h1>

4)
Download simple test web application clusterbench and build its simplified-and-pure branch.
You could directly use the download link [4].

Deploy this artifact to your Tomcat installation:

    clusterbench-ee6-web/target/clusterbench.war

You notice on the Mod_cluster manager console that the context got registered
with the Apache HTTP Server. Now you can access this URL:


    curl localhost:6666/clusterbench/requestinfo

and you should see content featuring several values with "JVM route: XXX" among them.


Prepare script
--------------
Automate everything you did in a form of a script. You could use Bash, Python,
Ruby, Perl or actually pretty much anything that could be installed on
a Fedora machine with a simple "dnf install something" command.

You can enumerate any standard tools as your dependencies, i.e.
patch for applying your C code changes, wget for downloading, curl for testing URLs,
git or svn etc.

Optional addition:
 You could install 2 Tomcats with different ports and JVMRoutes and see how
 Apache HTTP Server load balances requests among them.


Evaluation
----------
 - We will setup a Fedora virtual machine of the version you tell us (20? 21? 22?).
 - We will run the automation script you provided us with

Don't worry, the evaluation is to be done by human, so if anything gets stuck,
we will try to help your automation script pass, e.g. by installing any missing 
tools or correcting simple installation path problems.


[1] https://gist.github.com/Karm/85cf36a52a8c203accce
[2] http://docs.jboss.org/mod_cluster/1.3.0/html_single/#SetHandlermod_cluster-manager
[3] http://docs.jboss.org/mod_cluster/1.3.0/html_single
[4] https://github.com/Karm/clusterbench/archive/simplified-and-pure.zip
