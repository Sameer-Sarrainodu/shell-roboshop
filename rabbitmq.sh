#!/bin/bash
starttime=$(date +%s)
red="\e[31m"
green="\e[32m"
yellow="\e[33m"
nc="\e[0m"
logsdir="/var/log/shellscript-logs"
scriptname=$(basename "$0" | cut -d "." -f1)
logfile="$logsdir/$scriptname.log"
scriptdir=$PWD

mkdir -p $logsdir
echo "script executed at $(date)"|tee -a $logfile

checkroot(){
userid=$(id -u)
if [ $userid -ne 0 ]
then
    echo -e "$red Error:you are not a sudo $nc"|tee -a $logfile
    sudo -i
    exit 1
else
    echo -e "$green success$nc: you are sudo"|tee -a $logfile
fi
}
validate(){
    if [ $1 -ne 0 ]
    then
        echo -e "$red error:$2 is not installed $nc" |tee -a $logfile
        exit 1
    else
        echo -e "$green success:$nc installed $2 successfully"|tee -a $logfile
    fi

}
printtime(){
endtime=$(date +%s)
totaltime=$((endtime-starttime))
echo -e "script executed successfully,$yellow time taken: $totaltime seconds $nc"
}
checkroot

cp $scriptdir/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
validate $? "rabbitmq repo file"

dnf install rabbitmq-server -y &>>$logfile
validate $? "installing rabbitmq"

systemctl enable rabbitmq-server
systemctl start rabbitmq-server
validate $? "starting rabbitmq"

rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
validate $? "permision"

printtime