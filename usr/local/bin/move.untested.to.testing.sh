#!/bin/bash
#
# Sign the untested rpms.  Then move them into their
#   appropriate areas: fastbug, security, os, or pass
#
# NOTE: Rewrite this so that it doesn't use the UNTESTEDRESULTS file
#       It should just look at what is in the untested directories.
#

# Get the buildscripts global variables
source /usr/local/etc/buildscripts.conf

# Set the variables specific to this script
NOW=$(date +"%Y-%m-%d %H:%M")
TODAY=$(date +%Y-%m-%d)
TESTINGDIR="$BUILDDIR/results/testing"
UNTESTEDDIR="$BUILDDIR/results/untested"
UNTESTEDRESULTS="$UNTESTEDDIR/results"
MAILFILE="$TESTINGDIR/mailfile.$TODAY"
RESULTSLIST="result.noarch result.armv7 result.i386 result.x86_64"

# # First, sign everything
# echo "Signing everything"
# echo
# rpm --resign $UNTESTEDDIR/*/*/*/*/*/*.rpm
# if ! [ $? -eq 0 ] ; then
#   echo "Problem with rpm signing ... exiting"
#   exit 1
# fi

# Tell us where to look for where the packages go
echo "You usually can find what you want here."
echo "   https://rhn.redhat.com/errata/rhel-server-7-errata.html"
echo

# Work through the results one directory at a time
for resultdir in $RESULTSLIST
do
  cd $BUILDDIR/results/untested/$resultdir
  pwd
  echo
  
  for resultsline in $(ls -d1 */*/*)
  do

  rpmname=$(rpm -qp --nosignature --qf "%{name}" $resultsline/SRPM/*.src.rpm )
  rpmversion=$(rpm -qp --nosignature --qf "%{version}" $resultsline/SRPM/*.src.rpm )
  rpmrelease=$(rpm -qp --nosignature --qf "%{release}" $resultsline/SRPM/*.src.rpm )
  echo " $rpmname-$rpmversion-$rpmrelease $resultdir"
  read -p "    (o)s (s)ecurity (f)astbug (p)ass : " decision
  
  case $decision in
    o | os )
      echo "os"
      echo
      finaldir="os/Packages"
      ;;
    s | security )
      echo "security"
      echo
      finaldir="updates/security"
      ;;
    f | fastbug )
      echo "fastbug"
      echo
      finaldir="updates/fastbugs"
      ;;
    * )
      echo "skipping ..."
      echo
      finaldir="skipped"
      ;;
  esac

  if [ "$finaldir" == "skipped" ] ; then
    echo "$resultsline" >> $UNTESTEDRESULTS.skipped
  else
      packdir="$UNTESTEDDIR/$resultdir/$rpmname/$rpmversion/$rpmrelease"
      namedir="$UNTESTEDDIR/$resultdir/$rpmname"
      case $resultdir in
        result.noarch )
            cp -f $packdir/RPM/*.rpm $YORREPODIR/7testing/i386/$finaldir/
            cp -f $packdir/RPM/*.rpm $YORREPODIR/7testing/x86_64/$finaldir/
            cp -f $packdir/RPM/*.rpm $YORREPODIR/7testing/armv7/$finaldir/
            ls -1 $packdir/RPM/*.rpm | while read thisrpm
            do
              rm -f $YORREPODIR/7untested/armv7/os/Packages/$thisrpm
              rm -f $YORREPODIR/7untested/i386/os/Packages/$thisrpm
              rm -f $YORREPODIR/7untested/x86_64/os/Packages/$thisrpm
            done
            mkdir -p  $TESTINGDIR/{armv7,i386,x86_64}/$finaldir/$rpmname/$rpmversion
            cp -rp $packdir $TESTINGDIR/armv7/$finaldir/$rpmname/$rpmversion/
            cp -rp $packdir $TESTINGDIR/i386/$finaldir/$rpmname/$rpmversion/
            mv $packdir $TESTINGDIR/x86_64/$finaldir/$rpmname/$rpmversion/
            rmdir --ignore-fail-on-non-empty $namedir $namedir/$rpmversion
            ;;
        result.armv7 )
            cp -f $packdir/RPM/*.rpm $YORREPODIR/7testing/armv7/$finaldir/
            ls -1 $packdir/RPM/*.rpm | while read thisrpm
            do
              rm -f $YORREPODIR/7untested/armv7/os/Packages/$thisrpm
            done
            mkdir -p  $TESTINGDIR/armv7/$finaldir/$rpmname/$rpmversion
            mv $packdir $TESTINGDIR/armv7/$finaldir/$rpmname/$rpmversion/
            rmdir --ignore-fail-on-non-empty $namedir $namedir/$rpmversion
            ;;
        result.i386 )
            cp -f $packdir/RPM/*.rpm $YORREPODIR/7testing/i386/$finaldir/
            ls -1 $packdir/RPM/*.rpm | while read thisrpm
            do
              rm -f $YORREPODIR/7untested/i386/os/Packages/$thisrpm
            done
            mkdir -p  $TESTINGDIR/i386/$finaldir/$rpmname/$rpmversion
            mv $packdir $TESTINGDIR/i386/$finaldir/$rpmname/$rpmversion/
            rmdir --ignore-fail-on-non-empty $namedir $namedir/$rpmversion
            ;;
        result.x86_64 )
            cp -f $packdir/RPM/*.rpm $YORREPODIR/7testing/x86_64/$finaldir/
            ls -1 $packdir/RPM/*.rpm | while read thisrpm
            do
              rm -f $YORREPODIR/7untested/x86_64/os/Packages/$thisrpm
            done
            mkdir -p $TESTINGDIR/x86_64/$finaldir/$rpmname/$rpmversion
            mv $packdir $TESTINGDIR/x86_64/$finaldir/$rpmname/$rpmversion/
            rmdir --ignore-fail-on-non-empty $namedir $namedir/$rpmversion
            ;;
      esac
      echo " $rpmname-$rpmversion-$rpmrelease $resultdir $finaldir" >> $MAILFILE
  fi
  done
done

# cat $UNTESTEDRESULTS >> $UNTESTEDRESULTS.$TODAY
# rm -f $UNTESTEDRESULTS
# if [ -s $UNTESTEDRESULTS.skipped ] ; then
#   mv $UNTESTEDRESULTS.skipped $UNTESTEDRESULTS
# fi

if [ -s $MAILFILE ] ; then
  # Update the repo files
  if grep -q os/Packages $MAILFILE ; then
    echo "Creating repos - os"
    createrepo --update -g $YORREPODIR/7testing/i386/os/comps-yor7-i386.xml -d $YORREPODIR/7testing/i386/os
    createrepo --update -g $YORREPODIR/7testing/x86_64/os/comps-yor7-x86_64.xml -d $YORREPODIR/7testing/x86_64/os
    createrepo --update -g $YORREPODIR/7testing/armv7/os/comps-yor7-armv7.xml -d $YORREPODIR/7testing/armv7/os
  fi
  if grep -q updates/security $MAILFILE ; then
    echo "Creating repos - updates/security"
    createrepo --update -d $YORREPODIR/7testing/i386/updates/security
    createrepo --update -d $YORREPODIR/7testing/x86_64/updates/security
    createrepo --update -d $YORREPODIR/7testing/armv7/updates/security
  fi
  if grep -q updates/fastbugs $MAILFILE ; then
    echo "Creating repos - updates/fastbugs"
    createrepo --update -d $YORREPODIR/7testing/i386/updates/fastbugs
    createrepo --update -d $YORREPODIR/7testing/x86_64/updates/fastbugs
    createrepo --update -d $YORREPODIR/7testing/armv7/updates/fastbugs
  fi
  # Update the untested repo files
  echo "Updating the untested repos"
  createrepo -d $YORREPODIR/7untested/i386/os
  createrepo -d $YORREPODIR/7untested/x86_64/os
  createrepo -d $YORREPODIR/7untested/armv7/os

  # rsync the testing area
  rsync -avH --delete-after --progress -e "ssh -i $BUILDUSERPEM -l $BUILDUSER" --exclude=armv7/iso --exclude=i386/iso --exclude=x86_64/iso $YORREPODIR/7testing/ $REMOTESERVER:$REMOTEREPODIR/7testing/
  # rsync the untested area
  rsync -avH --delete-after -e "ssh -i $BUILDUSERPEM -l $BUILDUSER" $YORREPODIR/7untested/ $REMOTESERVER:$REMOTEREPODIR/7untested/

  # Send the mail
  mail -s "TESTING NEW PACKAGES - $TODAY" $EMAILLIST < $MAILFILE
  mv $MAILFILE $LOGDIR/new.testing.rpms/new.testing.packages.$TODAY
  echo "$NOW [SUCCESS] $0 [TESTING NEW PACKAGES] $LOGDIR/new.$BUILDTYPE.packages.$TODAY" >> $LOGFILE
else
  echo "$NOW [SUCCESS] $0 [TESTING NO NEW PACKAGES]" >> $LOGFILE
fi

exit 0
