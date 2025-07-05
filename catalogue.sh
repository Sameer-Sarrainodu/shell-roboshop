#!/bin/bash
red="\[31m"
green="\[32m"
yellow="\033[1;33m"
nc="\[0m"
logsdir="/var/log/shellscript-logs"
scriptname=$(basename "$0" | cut -d "." -f1)
logfile="$logsdir/$scriptname.log"
scriptdir=$PWD

mkdir -p $logsdir
echo " script executed at $(date)"|tee -a $logfile

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

dnf module disable nodejs -y &>>$logfile
validate $? "disabling nodejs"

dnf module enable modejs:20 -y &>>$logfile
validate $? "enabling nodejs"

dnf install nodejs -y &>>$logfile
validate $? "installing nodejs"

id roboshop
if [ $? -ne 0 ] then

    useradd --system --home /app --shell /sbin/nologin --comment "roboshop sytem user" roboshop $>>$logfile
    validate $? "creating system user roboshop"
else
    echo -e "user already existed $yellow skipping $nc"
fi

mkdir /app &>>$logfile
validate $? "making /app dir"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
validate $? "Downloading Catalogue"

rm -rf /app/*
cd /app 
unzip /tmp/catalogue.zip &>>$LOG_FILE
validate $? "unzipping catalogue"

cd /app
npm install &>>$logfile
validate $? "installing resources"


cp $scriptdir/catalogue.service /etc/systemd/system/catalogue.service &>>$logfile
validate $? "copying catalogue service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue  &>>$LOG_FILE
systemctl start catalogue
validate $? "Starting Catalogue"

cp $scriptdir/mongo.repo /etc/yum.repos.d/mongo.repo 
dnf install mongodb-mongosh -y &>>$LOG_FILE
validate $? "Installing MongoDB Client"

mongosh --host mongod.sharkdev.shop --eval 'show dbs' &>>$logfile
status=$?
if [ $status -ne 0 ]
then
    mongosh --host mongod.sharkdev.site </app/db/master-data.js &>>logfile
    validate $? "loading data into mongodb"
else
    echo -e "data is already loaded "

printtime


