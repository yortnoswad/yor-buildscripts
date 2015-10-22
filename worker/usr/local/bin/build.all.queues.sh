#!/bin/bash
#
# Check and see if there are any new repos (packages)
#   in the list of centos rpm git repo's
#
# If there are, send out an email, and put the new
#   repos in the newrepo file
#

# Get the buildscripts global variables
source /usr/local/etc/buildscripts.conf

# Setup Variables
DEBUG="true"
MONTH="$(date +%Y-%m)"
BUILDHOST=`hostname`
WORKDIR="$BUILDDIR/working/$BUILDHOST"
LOCKFILE="$WORKDIR/lockfile"
LOGFILE="$WORKDIR/logs/$MONTH.log"
VERSIONLIST="yor7 el7 7_1 7_2"
HOSTARCH="$(uname -i)"
case $HOSTARCH in
  armv7 | armv7l | armv7hl )
    ARCHLIST="armv7"
    ;;
  i386 )
    ARCHLIST="i386"
    ;;
  x86_64 )
    ARCHLIST="x86_64 i386"
    ;;
  * )
    echo "No build queues for arch: $HOSTARCH"
    exit 1
    ;;
esac
if [ "$HOSTARCH" == "$NOARCHBUILDREALARCH" ] ; then
  ARCHLIST="$ARCHLIST noarch"
fi

# Only run if we aren't already running
if [ -f $LOCKFILE ] ; then
  exit 5
else
  # Create lockfile
  echo $$ > $LOCKFILE
  
  # Setup dirs
  mkdir -p $WORKDIR $WORKDIR/logs
  
  # Start logs
  echo "===============" >> $LOGFILE
  date +%Y-%m-%d::%H:%M >> $LOGFILE
  echo "-----" >> $LOGFILE
  
  # Run through all the versions, for each arch we are doing
  for THISARCH in $ARCHLIST
  do
    for THISVERSION in $VERSIONLIST
    do
      if [ "$DEBUG" == "true" ] ; then
        echo "  Running: $THISARCH $THISVERSION"
      fi
      echo "  Running: $THISARCH $THISVERSION" >> $LOGFILE
      rebuild.packages.sh $THISARCH $THISVERSION >> $LOGFILE 2>&1
    done
  done
  # Remove lockfile
  /bin/rm -f $LOCKFILE

fi