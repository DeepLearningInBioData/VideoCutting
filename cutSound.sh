#!/bin/bash
if [ $# -ne 3 ]; then						#check if there are enough arguments
	printf "Usage: ./cutSound.sh <CSV Name> <sourceFolder> <destinationFolder>"
	exit
fi
csvName=$1							#get the arguments
srcFolder=$2
destFolder=$3
mkdir -p $destFolder						#create folder to store
xsv select Rename,Sec $csvName > converted.csv			#create csv with required columns
INPUT=converted.csv
OLDIFS=$IFS
IFS=,
regex="V.*"
paddingFormat="00:0"
srcFolder="${srcFolder}/"
destFolder="${destFolder}/"
wavFormat=".wav"

[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }

while read name time
do
	if [[ $name =~ $regex ]];				#select if the row is valid
	then
		startTime=$( echo "$time" | cut -d "-" -f 1)
		endTime=$( echo "$time" | cut -d "-" -f 2)
		startTime="${paddingFormat}${startTime}"
		endTime="${paddingFormat}${endTime}"
		src="${srcFolder}$name$wavFormat"
		startFormat=$(date -jf '%H:%M:%S' "$startTime" '+%s')
		endFormat=$(date -jf '%H:%M:%S' "$endTime" '+%s')
		totalDuration=$((endFormat - startFormat))
		count=5
		nameCount=1
		while [ $count -le $totalDuration ]		#keep cutting if the startTime < endTime
		do
			endFormat=$((startFormat + 5))
			endTime=$(date -r $endFormat '+%H:%M:%S')
			extension="_$nameCount"
			dest="$destFolder$name$extension$wavFormat"
			echo "startTime: $startTime"
			echo "endTime: $endTime"
			echo "dest: $dest"
			ffmpeg -y -i $src -ss $startTime -to $endTime -async 1 $dest < /dev/null		#read from default input otherwise it skips lines
			startFormat=$((startFormat + 5))
			startTime=$(date -r $startFormat '+%H:%M:%S')
			count=$(($count + 5))
			((nameCount++))
		done
	fi
done < $INPUT
IFS=$OLDIFS

