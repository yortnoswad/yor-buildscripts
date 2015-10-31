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

# First, sign everything
echo "Signing everything"
echo
rpm --resign $UNTESTEDDIR/*/*/*/*/*/*.rpm
if ! [ $? -eq 0 ] ; then
  echo "Problem with rpm signing ... exiting"
  exit 1
fi

# Tell us where to look for where the packages go
echo "You usually can find what you want here."
echo "   https://rhn.redhat.com/errata/rhel-server-7-errata.html"
echo "   https://rhn.redhat.com/errata/rhel-server-fastrack-7-errata.html"
echo

# Work through the results one directory at a time
for resultdir in $RESULTSLIST
do
  cd $BUILDDIR/results/untested/$resultdir
  pwd
  echo
  
  for resultsline in $(ls -d1 */*/* 2>/dev/null)
  do

  rpmname=$(rpm -qp --nosignature --qf "%{name}" $resultsline/SRPM/*.src.rpm )
  rpmversion=$(rpm -qp --nosignature --qf "%{version}" $resultsline/SRPM/*.src.rpm )
  rpmrelease=$(rpm -qp --nosignature --qf "%{release}" $resultsline/SRPM/*.src.rpm )
  echo " $rpmname-$rpmversion-$rpmrelease $resultdir"
  read -p "    (o)s (s)ecurity (f)astbug (e)xtras (p)ass : " decision
  
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
    e | extra | extras )
      echo "extras"
      echo
      finaldir="extras"
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
            cp -frp $packdir $TESTINGDIR/x86_64/$finaldir/$rpmname/$rpmversion/
            rm -rf $packdir
            rmdir --ignore-fail-on-non-empty $namedir/$rpmversion $namedir
            ;;
        result.armv7 )
            cp -f $packdir/RPM/*.rpm $YORREPODIR/7testing/armv7/$finaldir/
            ls -1 $packdir/RPM/*.rpm | while read thisrpm
            do
              rm -f $YORREPODIR/7untested/armv7/os/Packages/$thisrpm
            done
            mkdir -p  $TESTINGDIR/armv7/$finaldir/$rpmname/$rpmversion
            cp -frp $packdir $TESTINGDIR/armv7/$finaldir/$rpmname/$rpmversion/
            rm -rf $packdir
            rmdir --ignore-fail-on-non-empty $namedir/$rpmversion $namedir
            ;;
        result.i386 )
            cp -f $packdir/RPM/*.rpm $YORREPODIR/7testing/i386/$finaldir/
            ls -1 $packdir/RPM/*.rpm | while read thisrpm
            do
              rm -f $YORREPODIR/7untested/i386/os/Packages/$thisrpm
            done
            mkdir -p  $TESTINGDIR/i386/$finaldir/$rpmname/$rpmversion
            cp -frp $packdir $TESTINGDIR/i386/$finaldir/$rpmname/$rpmversion/
            rm -rf $packdir
            rmdir --ignore-fail-on-non-empty $namedir/$rpmversion $namedir
            ;;
        result.x86_64 )
            cp -f $packdir/RPM/*.rpm $YORREPODIR/7testing/x86_64/$finaldir/
            ls -1 $packdir/RPM/*.rpm | while read thisrpm
            do
              rm -f $YORREPODIR/7untested/x86_64/os/Packages/$thisrpm
            done
            mkdir -p $TESTINGDIR/x86_64/$finaldir/$rpmname/$rpmversion
            cp -frp $packdir $TESTINGDIR/x86_64/$finaldir/$rpmname/$rpmversion/
            rm -rf $packdir
            rmdir --ignore-fail-on-non-empty $namedir/$rpmversion $namedir
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
    echo "  Updating i386"
    createrepo --update -g $YORREPODIR/7testing/i386/os/comps-yor7-i386.xml -d $YORREPODIR/7testing/i386/os
    echo "  Updating x86_64"
    createrepo --update -g $YORREPODIR/7testing/x86_64/os/comps-yor7-x86_64.xml -d $YORREPODIR/7testing/x86_64/os
    echo "  Updating armv7"
    createrepo --update -g $YORREPODIR/7testing/armv7/os/comps-yor7-armv7.xml -d $YORREPODIR/7testing/armv7/os
  fi
  if grep -q updates/security $MAILFILE ; then
    echo "Creating repos - updates/security"
    echo "  Rebuilding i386"
    createrepo --update -d $YORREPODIR/7testing/i386/updates/security
    echo "  Rebuilding x86_64"
    createrepo --update -d $YORREPODIR/7testing/x86_64/updates/security
    echo "  Rebuilding armv7"
    createrepo --update -d $YORREPODIR/7testing/armv7/updates/security
  fi
  if grep -q updates/fastbugs $MAILFILE ; then
    echo "Creating repos - updates/fastbugs"
    echo "  Rebuilding i386"
    createrepo --update -d $YORREPODIR/7testing/i386/updates/fastbugs
    echo "  Rebuilding x86_64"
    createrepo --update -d $YORREPODIR/7testing/x86_64/updates/fastbugs
    echo "  Rebuilding armv7"
    createrepo --update -d $YORREPODIR/7testing/armv7/updates/fastbugs
  fi
  if grep -q extras $MAILFILE ; then
    echo "Creating repos - extras"
    echo "  Updating i386"
    createrepo --update -g $YORREPODIR/7/extras/comps-yor7-extra.xml -d $YORREPODIR/7/extras/i386
    echo "  Updating x86_64"
    createrepo --update -g $YORREPODIR/7/extras/comps-yor7-extra.xml -d $YORREPODIR/7/extras/x86_64
    echo "  Updating armv7"
    createrepo --update -g $YORREPODIR/7/extras/comps-yor7-extra.xml -d $YORREPODIR/7/extras/armv7
  fi
  # Clear out the untested files that are now in tested
  cd $YORREPODIRs
  ls -1 7testing/i386/updates/security/ 7testing/i386/updates/fastbugs/ 7testing/i386/os/Packages/  | while read line
    do 
      rm -f 7untested/i386/os/Packages/$line
    done
  ls -1 7testing/x86_64/updates/security/ 7testing/x86_64/updates/fastbugs/ 7testing/x86_64/os/Packages/  | while read line
    do 
      rm -f 7untested/x86_64/os/Packages/$line
    done
  ls -1 7testing/armv7/updates/security/ 7testing/armv7/updates/fastbugs/ 7testing/armv7/os/Packages/  | while read line
    do 
      rm -f 7untested/armv7/os/Packages/$line
    done
  # Update the untested repo files
  echo "Updating the untested repos"
    echo "  Rebuilding i386"
  createrepo -d $YORREPODIR/7untested/i386/os
    echo "  Rebuilding x86_64"
  createrepo -d $YORREPODIR/7untested/x86_64/os
    echo "  Rebuilding armv7"
  createrepo -d $YORREPODIR/7untested/armv7/os

  # rsync the testing area
  rsync -avH --delete-after --progress -e "ssh -i $BUILDUSERPEM -l $BUILDUSER" --exclude=armv7/iso --exclude=i386/iso --exclude=x86_64/iso $YORREPODIR/7testing/ $REMOTESERVER:$REMOTEREPODIR/7testing/
  # rsync the extras area
  rsync -avH --delete-after --progress -e "ssh -i $BUILDUSERPEM -l $BUILDUSER" $YORREPODIR/7/extras/ $REMOTESERVER:$REMOTEREPODIR/7/extras/
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
