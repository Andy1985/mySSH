#!/bin/bash

WorkPath="/home/dep/MailSampleUpload"
LogPath="${WorkPath}/log"
ABSLogPath=/home/xmail/.bogofilter/t
SaveTime=10
LogSaveTime=90

cd ${LogPath}
for file in `/bin/ls`
do
	FileTime=`/bin/echo ${file}|/bin/sed s/[a-zA-Z.]//g`
	LimitTime=`/bin/date +'%Y%m%d' --date "$LogSaveTime days ago"`
	[ $FileTime -lt $LimitTime ] && /bin/rm -vrf $file
done

cd $ABSLogPath
for file in `/bin/ls`
do
	FileTime=`/bin/echo $file | /bin/awk -F '.' '{print $1}'|/bin/awk -F '_' '{print $3}'`
        LimitTime=`/bin/date +'%Y%m%d%H%M%S' --date "$SaveTime days ago"`
        [ $FileTime -lt $LimitTime ] && /bin/rm -vrf $file	
done
