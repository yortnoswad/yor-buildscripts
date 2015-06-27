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
BUILDTYPE="x86_64.only"
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
    GOUTPUT=$(git clone $packagegit)
    echo "### Update found: $package ###" >> $MAILFILE
    echo "$GOUTPUT" >> $MAILFILE
  else
    # We need to pull and get the newest stuff
    cd $CENTOSGITDIR/$package
    GOUTPUT=$(git pull)
    if [ "$GOUTPUT" == "Already up-to-date." ] ; then
      echo "No Update for $package"
    else
      echo "### Update found: $package ###" >> $MAILFILE
      #echo "$GOUTPUT" >> $MAILFILE
      NEWDISTTAG=$(return_disttag.sh)
      NEWSRPM=$(into_srpm.sh | grep Wrote: | awk '{print $2}')
      if [ "$NEWSRPM" == "" ] ; then
        echo "  ### ERROR: unable to create srpm for $package ###" >> $MAILFILE
      else
        case $NEWDISTTAG in
          .el7 )
            cp $NEWSRPM $BUILDDIR/queue.x86_64
            echo "  ### $NEWSRPM put in queue.x86_64 ###" >> $MAILFILE
            ;;
          .el7_0 )
            cp $NEWSRPM $BUILDDIR/queue.x86_64.7_0
            echo "  ### $NEWSRPM put in queue.x86_64.7_0 ###" >> $MAILFILE
            ;;
          .el7_1 )
            cp $NEWSRPM $BUILDDIR/queue.x86_64.7_1
            echo "  ### $NEWSRPM put in queue.x86_64.7_1 ###" >> $MAILFILE
            ;;
          .el7_2 )
            cp $NEWSRPM $BUILDDIR/queue.x86_64.7_2
            echo "  ### $NEWSRPM put in queue.x86_64.7_2 ###" >> $MAILFILE
            ;;
          * )
            echo "  ### ERROR: dist tag $NEWDISTTAG is not in our list of tag ###" >> $MAILFILE
            ;;
        esac
      fi
    fi
  fi
done


if [ -s $MAILFILE ] ; then
  mail -s "NEW PACKAGES - x86_64 ONLY - $TODAY" $EMAILLIST < $MAILFILE
  mv $MAILFILE $LOGDIR/new.$BUILDTYPE.packages.$TODAY
  echo "$NOW [SUCCESS] $0 [NEW PACKAGES] $LOGDIR/new.$BUILDTYPE.packages.$TODAY" >> $LOGFILE
else
  echo "$NOW [SUCCESS] $0 [NO NEW PACKAGES]" >> $LOGFILE
fi

exit 0
