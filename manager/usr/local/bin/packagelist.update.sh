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
PACKAGEDIR="$WORKDIR/packagelist"
OPTIONS="new allarches manual noarch x86_64.and.i686 x86_64.only donotbuild"

help() {
  echo "Usage: $0 <source> <dest> <package>"
  echo ""
  echo "<source> must be in the following list:"
  echo "$OPTIONS"
  echo ""
  echo "<dest> cannot be new, but otherwise must be in above list:"
  echo ""
  echo "example: $0 new noarch thunderbird"
  echo "example: $0 allarches manual firefox"
}

# very light sanity check
PACKAGE="$3"
if [ "$PACKAGE" == "" ] ; then
  help
  exit 1
fi

# Set source
case "$1" in
  new )
    # Variables for new are different than everything else
    REPODIR="$WORKDIR/repolist"
    NEWREPOFILE="$REPODIR/newrepo"
    # Make sure everything we need is there.
    if ! [ -d $REPODIR ] ; then
      echo "There is no repodir, we are unable to proceed"
      exit 10
    fi
    if ! [ -s $NEWREPOFILE ] ; then
      echo "The newrepo file is gone or empty, there are no packages to move"
      exit 11
    fi
    SOURCEFILE=$NEWREPOFILE
    ;;
  allarches | manual | noarch | x86_64.and.i686 | x86_64.only | donotbuild )
    SOURCEFILE=$PACKAGEDIR/build.$1.packages 
    ;;
  * )
    help
    exit 2
    ;;
esac

# Set destination
case "$2" in
  allarches | manual | noarch | x86_64.and.i686 | x86_64.only | donotbuild )
    DESTFILE=$PACKAGEDIR/build.$2.packages 
    ;;
  * )
    help
    exit 3
    ;;
esac
  
# Begin the move
echo "Moving: $PACKAGE"

# Make sure our packagedir is there
[ -d $PACKAGEDIR ] || mkdir -p $PACKAGEDIR

packageline=$(grep "^$PACKAGE," $SOURCEFILE)
if [ "$packageline" == "" ] ; then
  echo "  $PACKAGE is not found the source.  Exiting"
  exit 4
else
  echo "  Putting $PACKAGE in build.$2.packages"
  echo $packageline >> $DESTFILE
  echo "  Removing $PACKAGE from newrepo file"
  sed -i "/^${PACKAGE},/d" $SOURCEFILE
fi

echo "Finished"
exit 0
