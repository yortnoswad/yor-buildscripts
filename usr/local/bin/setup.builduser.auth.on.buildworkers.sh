#!/bin/bash
#
# Copy the buildusers public ssh key to the buildusers
#   on all the build machines
#
# This script should be run by the user who has access
#   to BUILDUSERPUB
#
# Note: This script is still in the dumb stage, if there
#   are duplicate machines, they will get the key added 
#   more than one time.  This does not cause any problems
#   other than a messy authconfig file.
#
# Get the buildscripts global variables
source /usr/local/etc/buildscripts.conf

for machine in $X86_64BUILDWORKERS $I386BUILDWORKERS $ARM32BUILDWORKERS
do
  ssh-copy-id -i $BUILDUSERPUB $BUILDUSER@$machine
done