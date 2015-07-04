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

# Set the variables specific to this script
NOW=$(date +"%Y-%m-%d %H:%M")
TODAY=$(date +%Y-%m-%d)
UNTESTEDDIR="$BUILDDIR/results/untested"
UNTESTEDRESULTS="$UNTESTEDDIR/results"
MAILFILE="$UNTESTEDDIR/mailfile.$TODAY"
RESULTSLIST="result.noarch result.aarch32 result.i386 result.x86_64"

# Work through the results one directory at a time
for resultdir in "$RESULTSLIST"
do
  cd $BUILDDIR/$resultdir
  ls -d1 */*/* | while read packdir
  do
    # Check to make sure we are not catching something
    #   in mid transfer
    if [ -f $packdir/logs/root.log ] ; then
      echo $resultdir $(rpm -qp --qf "%{name} %{version} %{release}" $packdir/SRPM/*.src.rpm ) >> $UNTESTEDRESULTS
      case $resultdir in
        result.noarch )
            cp -f $packdir/RPM/*.rpm $YORREPODIR/7untested/i386/os/Packages/
            cp -f $packdir/RPM/*.rpm $YORREPODIR/7untested/x86_64/os/Packages/
            cp -f $packdir/RPM/*.rpm $YORREPODIR/7untested/armv7/os/Packages/
            ;;
        result.aarch32 )
            cp -f $packdir/RPM/*.rpm $YORREPODIR/7untested/armv7/os/Packages/
            ;;
        result.i386 )
            cp -f $packdir/RPM/*.rpm $YORREPODIR/7untested/i386/os/Packages/
            ;;
        result.x86_64 )
            cp -f $packdir/RPM/*.rpm $YORREPODIR/7untested/x86_64/os/Packages/
            ;;
      esac
      mv $packdir $UNTESTEDDIR/
      echo $resultdir $packdir >> $MAILFILE
    fi
  done
done


if [ -s $MAILFILE ] ; then
  # Update the repo files
  createrepo -d $YORREPODIR/7untested/i386/os
  createrepo -d $YORREPODIR/7untested/x86_64/os
  createrepo -d $YORREPODIR/7untested/armv7/os
  # rsync the untested area
  rsync -avH --delete -e "ssh -i $BUILDUSERPEM -l $BUILDUSER" $YORREPODIR/7untested/ $REMOTESERVER:$REMOTEREPODIR/7untested/
  # Send the mail
  mail -s "UNTESTED NEW PACKAGES - $TODAY" $EMAILLIST < $MAILFILE
  mv $MAILFILE $LOGDIR/new.$BUILDTYPE.packages.$TODAY
  echo "$NOW [SUCCESS] $0 [UNTESTED NEW PACKAGES] $LOGDIR/new.$BUILDTYPE.packages.$TODAY" >> $LOGFILE
else
  echo "$NOW [SUCCESS] $0 [UNTESTED NO NEW PACKAGES]" >> $LOGFILE
fi

exit 0