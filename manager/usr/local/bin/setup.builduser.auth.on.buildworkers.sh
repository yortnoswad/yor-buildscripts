#!/bin/bash
#
# Copy the buildusers public ssh key to the buildusers
#   on all the machines listed on the command line
#
# This script should be run by the user who has access
#   to BUILDUSERPUB
#
# Note: This script is still in the dumb stage.
#
# Get the buildscripts global variables
source /usr/local/etc/buildscripts.conf

for machine in "$@"
do
  ssh-copy-id -i $BUILDUSERPUB $BUILDUSER@$machine
done