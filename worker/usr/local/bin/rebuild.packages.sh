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

# Show help
show_help (){
  echo ""
  echo "Usage: $0 <queue> [version]"
  echo ""
  echo "queue: noarch i386 x86_64 armv7"
  echo "version: 7_0 7_1 7_2 yor7"
  echo ""
  echo "Examples:"
  echo "  $0 i386"
  echo "  $0 x86_64 7_1"
  echo "  $0 armv7 7_1"
  echo "  $0 noarch 7_1"
  exit 1
}

#############
# Check options
#############
if [ "$1" == "" ] ; then
  show_help
else
  QUEUE="$1"
  case $1 in
    aarch32 | armv7 )
      ARCH="armv7"
      REALARCH="armv7hl"
      ;;
    i386 )
      ARCH="i386"
      REALARCH="i686"
      ;;
    x86_64 )
      ARCH="x86_64"
      REALARCH="x86_64"
      ;;
    noarch )
      ARCH="$NOARCHBUILDARCH"
      REALARCH="$NOARCHBUILDREALARCH"
      ;;
    * )
      echo "ERROR - Unknown arch: $1"
      show_help
      ;;
  esac
  if [ "$2" == "" ] ; then
    VERSION=""
  else
    case  $2 in
      7_0 | 7_1 | yor7 )
	VERSION=".$2"
	;;
      * )
	echo "ERROR - Unsupported version: $2"
	show_help
	;;
    esac
  fi
fi

#############
# VARIABLES
#############
BUILDHOST=`hostname`
QUEUEDIR="$BUILDDIR/queue.$QUEUE${VERSION}"
DONEDIR="$BUILDDIR/done.$QUEUE${VERSION}"
FAILDIR="$BUILDDIR/fail.$QUEUE${VERSION}"
BUILDWORKDIR="$BUILDDIR/work.$QUEUE${VERSION}.$BUILDHOST"
MOCKSTYLE="yor-7-$ARCH${VERSION}"
MOCKRESULT="/var/lib/mock/$MOCKSTYLE/result/"
FINALRESULT="$BUILDDIR/result.$QUEUE"
RUNQUEUE="True"

#Setup
mkdir -p $DONEDIR $FAILDIR $BUILDWORKDIR/done $FINALRESULT

# See if there is anything to build
while [ "$RUNQUEUE" = "True" ]
do
	cd $QUEUEDIR
	THISSRPM=`ls -1 *.src.rpm 2>/dev/null | head -n 1`
	echo "BUILDING: $THISSRPM"
	if ! [ "$THISSRPM" = "" ] ; then
		mv $QUEUEDIR/$THISSRPM $BUILDWORKDIR 
		cd $BUILDWORKDIR
		if [ -f $THISSRPM ] ; then
			RPMNAME=`rpm -qp --qf "%{name}" $THISSRPM 2>/dev/null`
			cp $THISSRPM /tmp/
			#mock --clean --arch=$REALARCH --define="packager Yor Linux" --define="vendor Yor Linux" -r $MOCKSTYLE --rebuild /tmp/$THISSRPM
			#mock --no-clean --arch=$REALARCH --define="packager Yor Linux" --define="vendor Yor Linux" -r $MOCKSTYLE --rebuild /tmp/$THISSRPM
			mock --arch=$REALARCH --define="packager Yor Linux" --define="vendor Yor Linux" -r $MOCKSTYLE --rebuild /tmp/$THISSRPM
			if [ $? -eq 0 ] ; then
				echo "  SUCCESS: $RPMNAME"
				echo "SUCCESS: $RPMNAME $THISRPM" >> $BUILDWORKDIR/results.$$.txt
				/bin/mv -f $THISSRPM $DONEDIR/
				RPMVERSION=`rpm -qp --qf "%{version}" $MOCKRESULT/*.src.rpm 2>/dev/null`
				RPMRELEASE=`rpm -qp --qf "%{release}" $MOCKRESULT/*.src.rpm 2>/dev/null`
				RPMRESULTDIR="$FINALRESULT/$RPMNAME/$RPMVERSION/$RPMRELEASE"
				mkdir -p $RPMRESULTDIR/{devel,logs,RPM,SRPM}
				/bin/mv -f $MOCKRESULT/*.src.rpm $RPMRESULTDIR/SRPM/
				/bin/mv -f $MOCKRESULT/*debuginfo*.rpm $RPMRESULTDIR/devel/
				/bin/mv -f $MOCKRESULT/*.rpm $RPMRESULTDIR/RPM/
				/bin/mv -f $MOCKRESULT/* $RPMRESULTDIR/logs/
			else
				echo "  FAILURE: $RPMNAME"
				echo "FAILURE: $RPMNAME $THISRPM" >> $BUILDWORKDIR/results.$$.txt
				mkdir -p $FAILDIR/$RPMNAME
				/bin/mv -f $THISSRPM $FAILDIR/$RPMNAME
				/bin/mv -f $MOCKRESULT/* $FAILDIR/$RPMNAME
			fi
			rm -f /tmp/$THISSRPM
		else
			echo " Looks like we hit a race condition, moving on..."
		fi
	else
		RUNQUEUE="False"
	fi
	echo "FINISHED WITH $THISSRPM"
done

# Send off email
if [ -s $BUILDWORKDIR/results.$$.txt ] ; then
  mail -s "BUILD RESULTS - $QUEUE ${VERSION}" $EMAILLIST < $BUILDWORKDIR/results.$$.txt
  mv $BUILDWORKDIR/results.$$.txt $BUILDWORKDIR/done/
fi

exit 0
