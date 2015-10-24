#!/bin/bash
#
# Check and see if there are any new packages
#   in the list of epel7 packages
#
# If there are, download the src.rpm, put the srpm 
#   in the correct queue, and send out an email
#

# Get the buildscripts global variables
source /usr/local/etc/buildscripts.conf

# Set the variables specific to this script
NOW=$(date +"%Y-%m-%d %H:%M")
TODAY=$(date +%Y-%m-%d)
PACKAGEDIR="$WORKDIR/packagelist"
MAILFILE="$PACKAGEDIR/mailfile.epel7.check.and.build.new.packages.$TODAY"
BUILDTYPE=""
PACKAGESFILES="epel7.allarches.packages"

cd $CENTOSGITDIR/..
for PFILE in $PACKAGESFILES
do
  # Work through the packages one at a time
  for package in `cat $PACKAGEDIR/$PFILE`
  do
    # Find the latest version of the package
    latestpackage=`koji latest-build epel7 $package | grep epel7 | cut -d' ' -f1`
    if ! [ -f $CENTOSGITDIR/../epel7/SRPMS/$latestpackage.src.rpm ] && ! [ "$latestpackage" == "" ] ; then
      echo "========================" >> $MAILFILE
      echo "NEW: $latestpackage" >> $MAILFILE
      echo "------" >> $MAILFILE
      cd $CENTOSGITDIR/../epel7/SRPMS
      koji download-build --arch=src --latestfrom=epel7 $package > /dev/null 2>&1
      case $PFILE in
        epel7.i686.packages )
          cp $latestpackage.src.rpm $BUILDDIR/queue/queue.i386.yor7
          echo "  Put in queue.i386.yor7" >> $MAILFILE
          ;;
        epel7.armv7.and.i686.packages )
          cp $latestpackage.src.rpm $BUILDDIR/queue/queue.armv7.yor7
          echo "  Put in queue.armv7.yor7" >> $MAILFILE
          cp $latestpackage.src.rpm $BUILDDIR/queue/queue.i386.yor7
          echo "  Put in queue.i386.yor7" >> $MAILFILE
          ;;
        epel7.allarches.packages )
          cp $latestpackage.src.rpm $BUILDDIR/queue/queue.armv7.yor7
          echo "  Put in queue.armv7.yor7" >> $MAILFILE
          cp $latestpackage.src.rpm $BUILDDIR/queue/queue.i386.yor7
          echo "  Put in queue.i386.yor7" >> $MAILFILE
          cp $latestpackage.src.rpm $BUILDDIR/queue/queue.x86_64.yor7
          echo "  Put in queue.x86_64.yor7" >> $MAILFILE
          ;;
      esac
    fi
  done
done

if [ -s $MAILFILE ] ; then
  mail -s "NEW EPEL7 PACKAGES - $TODAY" $EMAILLIST < $MAILFILE
  mv $MAILFILE $LOGDIR/new.packages/epel7.check.and.build.new.packages.$TODAY
  echo "$NOW [SUCCESS] $0 [NEW PACKAGES] $LOGDIR/new.packages/epel7.check.and.build.new.packages.$TODAY" >> $LOGFILE
else
  echo "$NOW [SUCCESS] $0 [NO NEW PACKAGES]" >> $LOGFILE
fi

exit 0
