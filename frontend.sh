#!/bin/bash
starttime=$(date +%s)
red="\e[31m"
green="\e[32m"
yellow="\e[e33m"
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
    echo -e "$green success${nc}: you are sudo"|tee -a $logfile
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
dnf module disable nginx -y &>>$logfile
validate $? "disable default nginx"

dnf module enable nginx:1.24 -y &>>$logfile
validate $? "enableing nginx 1.24"

dnf install nginx -y&>>$logfile
validate $? "installing nginx"

rm -rf /usr/share/nginx/html/* &>>$logfile
validate $? "removing default"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$logfile
validate $? "downloading frontend resource"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$logfile
validate $? "unzipping frontend"

cp $scriptdir/nginx.conf /etc/nginx/nginx.conf
validate $? "copying nginx conf"

systemctl restart nginx
validate $? "restarting nginx"

printtime



