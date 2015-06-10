TODAY=$(date +%Y-%m-%d)
REPODIR="/srv/gitrepo/lists/repolist"
BINDIR="/srv/gitrepo/centos/centos-git-common"
TODAYLIST="$REPODIR/repolist-$TODAY"
YESTERDAYLIST="$REPODIR/repolist-YESTERDAY"
MAILFILE="$REPODIR/mailfile.$TODAY"
LOGFILE="$REPODIR/logfile"

date >> $LOGFILE

#1 - Get repo list
#./centos.git.repolist.py -b c7 > /tmp/repolist
#cat /tmp/repolist | cut -d'/' -f6 | grep .git | rev | cut -c 5- | rev | sort -u > /tmp/repolist.trimmed
$BINDIR/centos.git.repolist.py -b c7 | cut -d'/' -f6 | grep .git | rev | cut -c 5- | rev | sort -u > $TODAYLIST
if $(diff --brief $TODAYLIST $YESTERDAYLIST > /dev/null) ; then
  # There was no package added
  /bin/rm -f $TODAYLIST
else
  # There was a package added
  comm -23 $TODAYLIST $YESTERDAYLIST >> $MAILFILE
  mail -s "NEW PACKAGES - $TODAY" yortnoswad@gmail.com < $MAILFILE
  cat $MAILFILE >> $LOGFILE
  ln -sf $TODAYLIST $YESTERDAYLIST
  /bin/rm -f $MAILFILE
fi

