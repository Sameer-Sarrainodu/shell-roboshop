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
echo " script executed at $(date)"|tee -a $logfile

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

dnf module disable nodejs -y &>>$logfile
validate $? "disabling nodejs"

dnf module enable nodejs:20 -y &>>$logfile
validate $? "enabling nodejs"

dnf install nodejs -y &>>$logfile
validate $? "installing nodejs"

id roboshop &>>$logfile
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$logfile
    validate $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $yellow SKIPPING $nc"
fi

mkdir -p /app &>>$logfile
validate $? "making /app dir"
rm -rf /app/*
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$logfile
validate $? "Downloading Catalogue"

cd /app 
unzip /tmp/catalogue.zip &>>$logfile
validate $? "unzipping catalogue"

cd /app
npm install &>>$logfile
validate $? "installing resources"


cp $scriptdir/catalogue.service /etc/systemd/system/catalogue.service &>>$logfile
validate $? "copying catalogue service"

systemctl daemon-reload &>>$logfile
systemctl enable catalogue  &>>$logfile
systemctl start catalogue
validate $? "Starting Catalogue"

cp $scriptdir/mongo.repo /etc/yum.repos.d/mongo.repo 
dnf install mongodb-mongosh -y &>>$logfile
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