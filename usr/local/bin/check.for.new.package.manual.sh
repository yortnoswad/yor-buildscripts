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
BUILDTYPE="manual"
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
    echo "### Update found: $package" >> $MAILFILE
    echo "$GOUTPUT" >> $MAILFILE
  else
    # We need to pull and get the newest stuff
    cd $CENTOSGITDIR/$package
    GOUTPUT=$(git pull)
    if [ "$GOUTPUT" == "Already up-to-date." ] ; then
      echo "No Update for $package"
    else
      echo "### Update found: $package ###" >> $MAILFILE
      echo "$GOUTPUT" >> $MAILFILE      
    fi
  fi
done

# 
if [ -s $MAILFILE ] ; then
  mail -s "NEW PACKAGES - MANUAL - $TODAY" $EMAILLIST < $MAILFILE
  mv $MAILFILE $LOGDIR/new.$BUILDTYPE.packages.$TODAY
  echo "$NOW [SUCCESS] $0 [NEW PACKAGES] $LOGDIR/new.$BUILDTYPE.packages.$TODAY" >> $LOGFILE
else
  echo "$NOW [SUCCESS] $0 [NO NEW PACKAGES]" >> $LOGFILE
fi

exit 0
