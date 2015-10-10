#!/bin/bash
#
# Check and see if there are any new packages
#   in the centos git repos
#
# If there are, create the src.rpm, put the srpm 
#   in the correct queue, and send out an email
#

# Get the buildscripts global variables
source /usr/local/etc/buildscripts.conf

# Set the variables specific to this script
DEBUG="false"
NOW=$(date +"%Y-%m-%d %H:%M")
TODAY=$(date +%Y-%m-%d)
PACKAGEDIR="$WORKDIR/packagelist"
MAILFILE="$PACKAGEDIR/mailfile.centos.check.and.build.new.packages.$TODAY"
BUILDTYPE=""
PACKAGESFILES="build.allarches.packages build.noarch.packages build.x86_64.and.i686.packages build.x86_64.only.packages"

for PFILE in $PACKAGESFILES
do
  if [ "$DEBUG" == "true" ] ; then
    echo "PackageFile: $PFILE"
  fi
  # Work through the packages one at a time
  for packageline in `cat $PACKAGEDIR/$PFILE`
  do
    NEWSRPM=""
    package=`echo $packageline | cut -d',' -f1`
    packagegit=`echo $packageline | cut -d',' -f2`
    if ! [ -d $CENTOSGITDIR/$package ] ; then
      if [ "$DEBUG" == "true" ] ; then
        echo "New Repo for $package"
      fi
      # We do not have the repo yet, get it and create the srpm for it
      cd $CENTOSGITDIR
      git clone $packagegit
      cd $package
      git checkout c7
      echo "========================" >> $MAILFILE
      echo "New Repo: $package" >> $MAILFILE
      NEWDISTTAG=`return_disttag.sh 2>/dev/null </dev/null`
      NEWOUTPUT=`into_srpm.sh 2>/dev/null </dev/null`
      echo "------" >> $MAILFILE
      echo "$NEWDISTTAG" >> $MAILFILE
      echo "------" >> $MAILFILE
      echo "$NEWOUTPUT" >> $MAILFILE
      echo "------" >> $MAILFILE
      NEWSRPM=`echo "$NEWOUTPUT" | grep Wrote: | awk '{print $2}'`
    else
      # We need to pull and get the newest stuff
      cd $CENTOSGITDIR/$package
      git checkout -q c7
      GOUTPUT=`git pull 2>/dev/null </dev/null`
      if [ "$GOUTPUT" == "Already up-to-date." ] ; then
        if [ "$DEBUG" == "true" ] ; then
          echo "  No Update for $package"
        fi
      else
        if [ "$DEBUG" == "true" ] ; then
          echo "  Update for $package"
        fi
        echo "========================" >> $MAILFILE
        echo "NEW: $package" >> $MAILFILE
        echo "------" >> $MAILFILE
        echo "$GOUTPUT" >> $MAILFILE
        NEWDISTTAG=`return_disttag.sh 2>/dev/null </dev/null`
        NEWOUTPUT=`into_srpm.sh 2>/dev/null </dev/null`
        echo "------" >> $MAILFILE
        echo "$NEWDISTTAG" >> $MAILFILE
        echo "------" >> $MAILFILE
        echo "$NEWOUTPUT" >> $MAILFILE
        echo "------" >> $MAILFILE
        NEWSRPM=`echo "$NEWOUTPUT" | grep Wrote: | awk '{print $2}'`
      fi
    fi

    if ! [ "$NEWSRPM" == "" ] ; then
      case $PFILE in
        build.noarch.packages )
          cp $NEWSRPM $BUILDDIR/queue.$NOARCHBUILDARCH$NEWDISTTAG
          echo "  Put in queue.$NOARCHBUILDARCH$NEWDISTTAG" >> $MAILFILE
          ;;
        build.x86_64.only.packages )
          cp $NEWSRPM $BUILDDIR/queue.x86_64$NEWDISTTAG
          echo "  Put in queue.x86_64$NEWDISTTAG" >> $MAILFILE
          ;;
        build.x86_64.and.i686.packages )
          cp $NEWSRPM $BUILDDIR/queue.x86_64$NEWDISTTAG
          echo "  Put in queue.x86_64$NEWDISTTAG" >> $MAILFILE
          cp $NEWSRPM $BUILDDIR/queue.i386$NEWDISTTAG
          echo "  Put in queue.i386$NEWDISTTAG" >> $MAILFILE
          ;;
        build.allarches.packages )
          cp $NEWSRPM $BUILDDIR/queue.armv7$NEWDISTTAG
          echo "  Put in queue.armv7$NEWDISTTAG" >> $MAILFILE
          cp $NEWSRPM $BUILDDIR/queue.i386$NEWDISTTAG
          echo "  Put in queue.i386$NEWDISTTAG" >> $MAILFILE
          cp $NEWSRPM $BUILDDIR/queue.x86_64$NEWDISTTAG
          echo "  Put in queue.x86_64$NEWDISTTAG" >> $MAILFILE
          ;;
      esac
    fi
  done
done

if [ -s $MAILFILE ] ; then
  mail -s "NEW RHEL PACKAGES - $TODAY" $EMAILLIST < $MAILFILE
  mv $MAILFILE $LOGDIR/centos.check.and.build.new.packages.$TODAY
  echo "$NOW [SUCCESS] $0 [NEW PACKAGES] $LOGDIR/centos.check.and.build.new.packages.$TODAY" >> $LOGFILE
else
  echo "$NOW [SUCCESS] $0 [NO NEW PACKAGES]" >> $LOGFILE
fi

exit 0
