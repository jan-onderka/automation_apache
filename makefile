#
all: fetch_all_sources installpkg

fetch_all_sources: fetchSources.sh
    bash fetchSources.sh

# - Apache HTTP Server in version 2.4.12
# - APR 1.5.1
# - APR Util 1.5.4
# - mod_cluster 1.3.1.Final (directory "native")
installpkg:
    

#hello: main.o factorial.o hello.o
    #$(CC) main.o factorial.o hello.o -o hello


clean:
    #rm *o hello
