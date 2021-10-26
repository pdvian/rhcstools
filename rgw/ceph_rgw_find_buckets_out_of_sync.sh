#!/bin/bash

cdir="/tmp/rgw-ms.$(date +%F_%H-%M-%S)"
show_help()
{
    echo "Usage: `basename $0` <bucket-stats-from-primary-zone> <bucket-stats-from-secondary-zone>"
    exit -1
}

if [ $# -eq 0 ]
then
    echo "No arguments supplied"
    show_help
elif [ $# -ne 2 ]
then
    echo "Invalid arguments supplied"
    show_help
fi

mkdir ${cdir}
for bstatfile in $1 $2;
do
	for bucketstr in $(cat ${bstatfile}|grep bucket|grep -v bucket_quota|awk -F: '{print $2}'|sort);
	do
		bucket=$(echo $bucketstr|awk -F'"' '{print $2}');
		num_obj=$(cat ${bstatfile}|grep -v master_ver|grep -A 50 "\"$bucket\""|grep -B 50 bucket_quota|grep -A15 rgw.main|grep num_objects|awk -F: '{print $2}');
		echo "$bucket          $num_obj";
	done|awk '{ printf "%-60s %d \n", $1, $2 }' > ${cdir}/processed.${bstatfile}
done
echo "Buckets outof sync info available at : ${cdir}/outofsync.buckets"
sdiff -w 300 -s ${cdir}/processed.$1 ${cdir}/processed.$2 | tee ${cdir}/outofsync.buckets
