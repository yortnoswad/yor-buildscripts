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
PACKAGEDIR="$WORKDIR/packagelist"
BUILDTYPE="x86_64.and.i686"
MAILFILE="$PACKAGEDIR/mailfile.$BUILDTYPE.$TODAY"
PACKAGESFILE="$PACKAGEDIR/build.$BUILDTYPE.packages"

# Work through the packages one at a time
cat $PACKAGESFILE | while read packageline
do
  package=$(echo $packageline | cut -d',' -f1)
  packagegit=$(echo $packageline | cut -d',' -f2)
  if ! [ -d $CENTOSGITDIR/$package ] ; then
    # We do not have the repo yet, get it and mark that is has changed
    cd $CENTOSGITDIR
    git clone $packagegit
    cd $package
    git checkout c7
    echo "##############################" >> $MAILFILE
    echo "### Update found: $package  - New Repo ###" >> $MAILFILE
      NEWDISTTAG=$(return_disttag.sh)
      NEWOUTPUT="$(/usr/local/bin/into_srpm.sh)"
      echo "------" >> $MAILFILE
      echo "$NEWDISTTAG" >> $MAILFILE
      echo "------" >> $MAILFILE
      echo "$NEWOUTPUT" >> $MAILFILE
      echo "------" >> $MAILFILE
      NEWSRPM=$(echo "$NEWOUTPUT" | grep Wrote: | awk '{print $2}')
      if [ "$NEWSRPM" == "" ] ; then
        echo "  ### ERROR: unable to create srpm for $package ###" >> $MAILFILE
      else
        case $NEWDISTTAG in
          .el7 )
            cp $NEWSRPM $BUILDDIR/queue/queue.x86_64
            cp $NEWSRPM $BUILDDIR/queue/queue.i386
            echo "  ### $NEWSRPM put in queue.(x86_64,i386) ###" >> $MAILFILE
            ;;
          .el7_0 )
            cp $NEWSRPM $BUILDDIR/queue/queue.x86_64.7_0
            cp $NEWSRPM $BUILDDIR/queue/queue.i386.7_0
            echo "  ### $NEWSRPM put in queue.(x86_64,i386).7_0 ###" >> $MAILFILE
            ;;
          .el7_1 )
            cp $NEWSRPM $BUILDDIR/queue/queue.x86_64.7_1
            cp $NEWSRPM $BUILDDIR/queue/queue.i386.7_1
            echo "  ### $NEWSRPM put in queue.(x86_64,i386).7_1 ###" >> $MAILFILE
            ;;
          .el7_2 )
            cp $NEWSRPM $BUILDDIR/queue/queue.x86_64.7_2
            cp $NEWSRPM $BUILDDIR/queue/queue.i386.7_2
            echo "  ### $NEWSRPM put in queue.(x86_64,i386).7_2 ###" >> $MAILFILE
            ;;
          * )
            echo "  ### ERROR: dist tag $NEWDISTTAG is not in our list of tag ###" >> $MAILFILE
            ;;
        esac
      fi
      echo "##############################" >> $MAILFILE
  else
    # We need to pull and get the newest stuff
    cd $CENTOSGITDIR/$package
    git checkout -q c7
    GOUTPUT=`git pull`
    if [ "$GOUTPUT" == "Already up-to-date." ] ; then
      echo "No Update for $package"
    else
      echo "##############################" >> $MAILFILE
      echo "### Update found: $package ###" >> $MAILFILE
      echo "$GOUTPUT" >> $MAILFILE
      NEWDISTTAG=$(return_disttag.sh)
      NEWOUTPUT="$(/usr/local/bin/into_srpm.sh)"
      echo "------" >> $MAILFILE
      echo "$NEWDISTTAG" >> $MAILFILE
      echo "------" >> $MAILFILE
      echo "$NEWOUTPUT" >> $MAILFILE
      echo "------" >> $MAILFILE
      NEWSRPM=$(echo "$NEWOUTPUT" | grep Wrote: | awk '{print $2}')
      if [ "$NEWSRPM" == "" ] ; then
        echo "  ### ERROR: unable to create srpm for $package ###" >> $MAILFILE
      else
        case $NEWDISTTAG in
          .el7 )
            cp $NEWSRPM $BUILDDIR/queue/queue.x86_64
            cp $NEWSRPM $BUILDDIR/queue/queue.i386
            echo "  ### $NEWSRPM put in queue.(x86_64,i386) ###" >> $MAILFILE
            ;;
          .el7_0 )
            cp $NEWSRPM $BUILDDIR/queue/queue.x86_64.7_0
            cp $NEWSRPM $BUILDDIR/queue/queue.i386.7_0
            echo "  ### $NEWSRPM put in queue.(x86_64,i386).7_0 ###" >> $MAILFILE
            ;;
          .el7_1 )
            cp $NEWSRPM $BUILDDIR/queue/queue.x86_64.7_1
            cp $NEWSRPM $BUILDDIR/queue/queue.i386.7_1
            echo "  ### $NEWSRPM put in queue.(x86_64,i386).7_1 ###" >> $MAILFILE
            ;;
          .el7_2 )
            cp $NEWSRPM $BUILDDIR/queue/queue.x86_64.7_2
            cp $NEWSRPM $BUILDDIR/queue/queue.i386.7_2
            echo "  ### $NEWSRPM put in queue.(x86_64,i386).7_2 ###" >> $MAILFILE
            ;;
          * )
            echo "  ### ERROR: dist tag $NEWDISTTAG is not in our list of tag ###" >> $MAILFILE
            ;;
        esac
      fi
      echo "##############################" >> $MAILFILE
    fi
  fi
done


if [ -s $MAILFILE ] ; then
  mail -s "NEW PACKAGES - x86_64 and i386 - $TODAY" $EMAILLIST < $MAILFILE
  mv $MAILFILE $LOGDIR/new.$BUILDTYPE.packages.$TODAY
  echo "$NOW [SUCCESS] $0 [NEW PACKAGES] $LOGDIR/new.$BUILDTYPE.packages.$TODAY" >> $LOGFILE
else
  echo "$NOW [SUCCESS] $0 [NO NEW PACKAGES]" >> $LOGFILE
fi

exit 0
