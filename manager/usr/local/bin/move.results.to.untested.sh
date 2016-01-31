#!/bin/bash
#
# Check and see if there are any newly built packages
#
# If there are, move them to the untested section, record it,
#   put them in the repo, send out an email
#

# Get the buildscripts global variables
source /usr/local/etc/buildscripts.conf

# Set the variables specific to this script
NOW=$(date +"%Y-%m-%d %H:%M")
TODAY=$(date +%Y-%m-%d)
UNTESTEDDIR="$BUILDDIR/results/untested"
UNTESTEDRESULTS="$UNTESTEDDIR/results"
MAILFILE="$UNTESTEDDIR/mailfile.$TODAY"
RESULTSLIST="result.noarch result.armv7 result.i386 result.x86_64"

# Work through the results one directory at a time
for resultdir in $RESULTSLIST
do
  cd $BUILDDIR/results/$resultdir
  ls -d1 */*/* 2>/dev/null | while read packdir
  do
    # Check to make sure we are not catching something
    #   in mid transfer
    if [ -f $packdir/logs/root.log ] ; then
      echo $resultdir $(rpm -qp --qf "%{name} %{version} %{release}" $packdir/SRPM/*.src.rpm ) >> $UNTESTEDRESULTS
      case $resultdir in
        result.noarch )
            cp -f $packdir/RPM/*.rpm $YORREPODIR/7untested/i386/os/Packages/ 2>/dev/null
            cp -f $packdir/RPM/*.rpm $YORREPODIR/7untested/x86_64/os/Packages/ 2>/dev/null
            cp -f $packdir/RPM/*.rpm $YORREPODIR/7untested/armv7/os/Packages/ 2>/dev/null
            ;;
        result.armv7 )
            cp -f $packdir/RPM/*.rpm $YORREPODIR/7untested/armv7/os/Packages/ 2>/dev/null
            ;;
        result.i386 )
            cp -f $packdir/RPM/*.rpm $YORREPODIR/7untested/i386/os/Packages/ 2>/dev/null
            ;;
        result.x86_64 )
            cp -f $packdir/RPM/*.rpm $YORREPODIR/7untested/x86_64/os/Packages/ 2>/dev/null
            ;;
      esac
      packge="$(echo $packdir | cut -d'/' -f1)"
      cp -frp $packge $UNTESTEDDIR/$resultdir/
      rm -rf $packge
      echo $resultdir $packdir >> $MAILFILE
    fi
  done
done


if [ -s $MAILFILE ] ; then
  # Update the repo files
  createrepo -q -d $YORREPODIR/7untested/i386/os
  createrepo -q -d $YORREPODIR/7untested/x86_64/os
  createrepo -q -d $YORREPODIR/7untested/armv7/os
  # rsync the untested area
  rsync -avH --delete -e "ssh -i $BUILDUSERPEM -l $BUILDUSER" $YORREPODIR/7untested/ $REMOTESERVER:$REMOTEREPODIR/7untested/
  # Send the mail
  mail -s "UNTESTED NEW PACKAGES - $TODAY" $EMAILLIST < $MAILFILE
  mv $MAILFILE $LOGDIR/new.untested.rpms/new.untested.packages.$TODAY
  echo "$NOW [SUCCESS] $0 [UNTESTED NEW PACKAGES] $LOGDIR/new.$BUILDTYPE.packages.$TODAY" >> $LOGFILE
else
  echo "$NOW [SUCCESS] $0 [UNTESTED NO NEW PACKAGES]" >> $LOGFILE
fi

exit 0
