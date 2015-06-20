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
MAILFILE="$REPODIR/mailfile.$TODAY"
PACKAGEDIR="$WORKDIR/packagelist"
NEWBUILDFILE="build.manual.packages"


# Pull down the full centos repo list, and massage it into a nice file
#$BINDIR/centos.git.repolist.py -b c7 | cut -d'/' -f6 | grep .git | rev | cut -c 5- | rev | sort -u > $TODAYLIST
$BINDIR/centos.git.repolist.py -b c7 | cut -d'/' -f6 | grep .git | while read line
do
  URL="https://git.centos.org/git/rpms/$line"
  REPO="$(echo $line | rev | cut -c 5- | rev )"
  echo "$REPO,$URL" >> $TODAYLIST
done
sort -u -o $TODAYLIST $TODAYLIST

# Make sure we have yesterdays list, even if it is empty
[ -f $YESTERDAYLIST ] || touch $YESTERDAYLIST

# Compare todays repolist with yesterdays, and act accordingly
if $(diff --brief $TODAYLIST $YESTERDAYLIST > /dev/null) ; then
  # There was no package added
  # If there was no change, get rid of the clutter
  /bin/rm -f $TODAYLIST
  # Be sure to log that we ran and our status
  echo "$NOW [SUCCESS] $0 [NO CHANGE]" >> $LOGFILE
else
  # There was a package added
  # List the changes and put them in the mail file
  comm -23 $TODAYLIST $YESTERDAYLIST > $MAILFILE
  # Send our email out
  mail -s "NEW REPOS - $TODAY" $EMAILLIST < $MAILFILE
  # Add this list to the history file, with date stamp
  echo "## $TODAY" >> $HISTORYFILE
  cat $MAILFILE >> $HISTORYFILE
  # Add this list to the newrepo file
  #   The new repo file should be cleaned out when it is 
  #   determined what categories the repos fall in
  cat $MAILFILE >> $NEWREPOFILE
  # Change the link so we are ready for the next run
  ln -sf $TODAYLIST $YESTERDAYLIST
  # cleanup
  /bin/rm -f $MAILFILE
  # Be sure to log that we ran and our status
  echo "$NOW [SUCCESS] $0 [NEW REPOS] $NEWREPOFILE" >> $LOGFILE
fi

