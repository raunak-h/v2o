#!/usr/bin/bash
rm -r ~/v2o/logs 2> /dev/null
mkdir ~/v2o/logs
echo Starting Batch Test against Exhaustive, Sequential Standard and Sequential Custom matching
time bash vid23dexhaustive.sh $1
echo Exhaustive Test complete
time bash vid23dseqstd.sh $1
echo Sequential Standard Test complete
time bash vid23dseqcust.sh $1
echo Sequential Custom Test complete
