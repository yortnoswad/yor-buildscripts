#!/bin/bash
#
# Move packages our of the newrepo file
#   and into the correct package build file
#
# In the future all "move.newrepo" scripts 
#   should be consolodated into one
#

# Get the buildscripts global variables
source /usr/local/etc/buildscripts.conf

# Set the variables specific to this script
REPODIR="$WORKDIR/repolist"
NEWREPOFILE="$REPODIR/newrepo"
PACKAGEDIR="$WORKDIR/packagelist"
NEWBUILDFILE="build.noarch.packages"

# Make sure everything we need is there.
[ -d $PACKAGEDIR ] || mkdir -p $PACKAGEDIR
if ! [ -d $REPODIR ] ; then
  echo "There is no repodir, we are unable to proceed"
  exit 10
fi
if ! [ -s $NEWREPOFILE ] ; then
  echo "The newrepo file is gone or empty, there are no packages to move"
  exit 11
fi

# Grab the list of packages to move, and work through them one by one.
for package in $*; do
  echo "Moving: $package"
  packageline=$(grep "^$package," $NEWREPOFILE)
  if [ "$packageline" == "" ] ; then
    echo "  $package is not found in newrepo file.  Skipping"
  else
    echo "  Putting $package in $NEWBUILDFILE"
    echo $packageline >> $PACKAGEDIR/$NEWBUILDFILE
    echo "  Removing $package from newrepo file"
    sed -i "/^${package},/d" $NEWREPOFILE
  fi
done

echo "Finished"
exit 0
