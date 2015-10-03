#!/bin/bash
#
# Setup the buildscripts scripts and enviroment
#
# Be sure to fixup common/usr/local/etc/buildscripts.conf
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
source common/usr/local/etc/buildscripts.conf

HERE="$PWD"

# Make sure directories exist
echo "  Setup direcories (if needed) ..."
[ -d $BINDIR ] || mkdir -p $BINDIR
[ -d $BUILDDIR ] || mkdir -p $BUILDDIR


# Copy buildscripts files over
echo "  Copy the buildscripts files to their places ..."
cd $HERE

# Copy scripts over 
/bin/cp -f -p worker/usr/local/bin/* $BINDIR

# Configuration file - only if there isn't one, otherwise put it in as .new
if [ -f /usr/local/etc/buildscripts.conf ] ; then
  /bin/cp -f -p common/usr/local/etc/buildscripts.conf /usr/local/etc/buildscripts.conf.new
else
  /bin/cp -f -p common/usr/local/etc/buildscripts.conf /usr/local/etc/buildscripts.conf
fi

# Copy the mock config files over, do not overright if they are already there.
cd $HERE/worker/etc/mock
ls -1 *.cfg | while read line
do
  if [ -f /etc/mock/$line ] ; then
  /bin/cp -f -p $line /etc/mock/$line.new
else
  /bin/cp -f -p $line /etc/mock/$line
fi
done

# And ... now we're done
echo "buildscripts is now setup."
echo ""
echo "REMINDER: Before running make sure mock is setup properly"
echo "    for the user that will be running the build scrips."
echo ""
exit 0
