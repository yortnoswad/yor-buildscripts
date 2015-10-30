#!/bin/bash
#
# Check and see if there are any new packages
#   in the list of fedora packages
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
MAILFILE="$PACKAGEDIR/mailfile.fedora.check.and.build.new.packages.$TODAY"
BUILDTYPE=""
PACKAGESFILES="fedora.armv7.and.i686.packages fedora.i686.packages fedora.armv7.packages fedora.allarches.packages"

for PFILE in $PACKAGESFILES
do
  # Work through the packages one at a time
  for package in `cat $PACKAGEDIR/$PFILE`
  do
    # Find the latest version of the package
    latestpackage=`koji latest-build $FEDORATAG $package | grep $FEDORATAG | cut -d' ' -f1`
    if ! [ -f $FEDORAGITDIR/SRPMS/$latestpackage.src.rpm ] && ! [ "$latestpackage" == "" ] ; then
      echo "========================" >> $MAILFILE
      echo "NEW: $latestpackage" >> $MAILFILE
      echo "------" >> $MAILFILE
      cd $FEDORAGITDIR/SRPMS
      koji download-build --arch=src --latestfrom=$FEDORATAG $package > /dev/null 2>&1
      case $PFILE in
        fedora.i686.packages )
          cp $latestpackage.src.rpm $BUILDDIR/queue/queue.i386.yor7
          echo "  Put in queue.i386.yor7" >> $MAILFILE
          ;;
        fedora.armv7.packages )
          cp $latestpackage.src.rpm $BUILDDIR/queue/queue.armv7.yor7
          echo "  Put in queue.armv7.yor7" >> $MAILFILE
          ;;
        fedora.armv7.and.i686.packages )
          cp $latestpackage.src.rpm $BUILDDIR/queue/queue.armv7.yor7
          echo "  Put in queue.armv7.yor7" >> $MAILFILE
          cp $latestpackage.src.rpm $BUILDDIR/queue/queue.i386.yor7
          echo "  Put in queue.i386.yor7" >> $MAILFILE
          ;;
        fedora.allarches.packages )
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
  mail -s "NEW FEDORA PACKAGES - $TODAY" $EMAILLIST < $MAILFILE
  mv $MAILFILE $LOGDIR/new.packages/fedora.check.and.build.new.packages.$TODAY
  echo "$NOW [SUCCESS] $0 [NEW PACKAGES] $LOGDIR/new.packages/fedora.check.and.build.new.packages.$TODAY" >> $LOGFILE
else
  echo "$NOW [SUCCESS] $0 [NO NEW PACKAGES]" >> $LOGFILE
fi

exit 0
