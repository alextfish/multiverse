#!/bin/bash
count=0;
logdir='/c/Users/achurchi/Dropbox/Creations/rails_projects/multiverse/log';
while true; do
 # Loop every hour
 this_hour=`date +%H`;
 echo Logging multiverse logs for hour $this_hour: $count files last hour...
 count=0;
 while [ $this_hour == `date +%H` ]; do
   # Loop while it's this hour
   count=$[$count + 1];
   logfilename=$logdir/"Heroku_log_`date +%Y-%m-%d_h%k`_$count.log";
   echo Logging to $logfilename at `date +%T`
   heroku logs -t >$logfilename;
   echo Finished logging to $logfilename at `date +%T`: it was `du -sk $logfilename | cut -d ' ' -f 1`k when I finished
 done
done
