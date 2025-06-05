#!/bin/bash

LOG=/root/first-boot.log

# quick exit if the logfile already exist
[ -f $LOG ] && exit 0

# first boot setup
echo '#DO NOT DELETE THE LOGFILE' >$LOG


