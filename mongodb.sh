#!/bin/bash
red="\[31m"
green="\[32m"
yellow="\033[1;33m"
nc="\[0m"
logsdir="/var/log/shellscript-logs"
scriptname=$(basename "$0" | cut -d "." -f1)
logfile="$logsdir/$scriptname.log"
scriptdir=$PWD

mkdir -p logsdir
echo "script executed at $(date)|tee -a $logfile
checkroot(){
userid=$(id -u)
if [$userid -ne 0 ]
then
    echo -e "$red Error:you are not a sudo $nc"|tee -a$logfile
    sudo -i
    exit 1
else
    echo -e "$green success$nc: you are sudo"|tee -a$logfile
fi
}
validate(){
    if [ $1 -ne 0 ]
    then
        echo -e "$red error:$2 is not installed $nc" |tee -a$logfile
        exit 1
    else
        echo -e "$green success:$nc installed $2 successfully"|tee -a$logfile
    fi

}
printtime(){
endtime=$(date +%s)
totaltime=$((endtime-starttime))
echo -e "script executed successfully,$yellow time taken: $totaltime seconds $nc"
}

checkroot

cp $scriptdir/mongo.repo /etc/yum.repos.d/mongo.repo &>>$logfile
validate $? "copying mongorepo to location"

dnf install mongodb-org -y &>>$logfile
validate $? "installing mongodb"

systemctl enable mongod &>>$logfile
systemctl start mongod &>>$logfile
validate $? "starting mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
validate $? "edited mongodconf file"

systemctl restart mongod
validate $? "restarting mongod"

printtime