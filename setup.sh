#!/bin/bash
#
# Setup the buildscripts scripts and enviroment
#
# Be sure to fixup usr/local/etc/buildscripts.conf
#   to match your enviroment because that is what we
#   will be using to set things up
#
# This script does not have to be root, but it should
#   be run by a user who has access to all the direcories
#   that are listed in the buildscripts.conf file
#
# At the time of the writting, this has to be
#   run in the git repo base directory

# Get the buildscripts global variables
source usr/local/etc/buildscripts.conf

HERE="$PWD"

# Make sure directories exist
echo "  Setup direcories (if needed) ..."
[ -d $CENTOSGITDIR ] || mkdir -p $CENTOSGITDIR
[ -d $BINDIR ] || mkdir -p $BINDIR
[ -d $WORKDIR ] || mkdir -p $WORKDIR
[ -d $LOGDIR ] || mkdir -p $LOGDIR

# Ensure we have centos-git-common repo
echo "  Get the latest centos-git-common git repo ..."
if [ -d $CENTOSGITDIR/centos-git-common ] ; then
  cd $CENTOSGITDIR/centos-git-common
  git pull
else
  cd $CENTOSGITDIR
  git clone https://git.centos.org/git/centos-git-common.git
fi

# Copy all the centos-git-common script to our bin directory
echo "  Copy the latest centos-git-common files to our bin directory ..."
cd $CENTOSGITDIR/centos-git-common
/bin/cp -f *.sh *.py $BINDIR

# Copy buildscripts files over
echo "  Copy the buildscripts files to their places ..."
cd $HERE
# Sorry, but we've got to know where the buildscripts.conf is
#  so at this time this can't be configurable.
cp usr/local/etc/* /usr/local/etc/
cp usr/local/bin/* $BINDIR

# And ... now we're done
echo "buildscripts is now setup."
exit 0
