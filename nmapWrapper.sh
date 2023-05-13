#!/bin/bash
ENV=$1
FILETYPE=$2
SCANTYPE=$3
RESULTDIR=$4

set -x
# add cleanup
rm -rf HTMLFiles/
rm -rf RESULT/
rm -rf S3/

sudo yum install nmap -y

git clone https://github.com/nmap/nmap.git

if [ $FILETYPE == "YES" ]
then
        echo "The provided argument is the file."
        if [ $ENV == "AWSQA" ]
          then
            FILENAME=IPAddressAWSQA.txt
          else
            FILENAME=IPAddress.txt
        fi

        while IFS= read -r line; do
          echo "$line"
          ./nmapAutomator.sh -H $line -t ${SCANTYPE} -o ${RESULTDIR}
        done < $FILENAME

        ./generatehtmlreport.sh $ENV $FILETYPE
#if the provided argument is not file and directory then it does not exist on the system.
else
        echo "The given argument is a array"
        serviceArray=("$@")
        arraySize=${#serviceArray[@]}

        for (( i=4; i<$arraySize; i++ ))
        do
          ./nmapAutomator.sh -H ${serviceArray[i]} -t ${SCANTYPE} -o ${RESULTDIR}
          ./generatehtmlreport.sh $ENV $FILETYPE ${serviceArray[i]}
        done
fi

./copyLogstoS3.sh $ENV