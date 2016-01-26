#INCLIB=../tstlib
#LIBS=$(INCLIB)/tlib.a
FETCH=fetch_all_sources
INS=install_all_packages
FRCHECK=first_check_applications
SET=setup_applications
SECHECK=second_check_applications
all: $(FETCH) $(INS) $(FRCHECK) $(SET) $(SECHECK) $(SECHECK)

$(FETCH): fetchSources.sh
    bash fetchSources.sh

# - Apache HTTP Server in version 2.4.12
# - APR 1.5.1
# - APR Util 1.5.4
# - mod_cluster 1.3.1.Final (directory "native")
$(INS):
    
# first check of setup
$(FRCHECK):

# make some changes to applications
$(SET):

# second check applications
$(SECHECK):

clean:
    #rm *o hello
