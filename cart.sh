#!/bin/bash
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

dnf module disable nodejs -y &>>$logfile
validate $? "disable nodejs"

dnf module enable nodejs:20 -y &>>$logfile
validate $? "enable nodejs"

dnf install nodejs -y &>>$logfile
validate $? "installing nodejs"

id roboshop
if [ $? -ne 0 ] 
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$logfile
    validate $? "creating system user"
else
    echo -e " user already exits" &>>$logfile
fi

mkdir -p /app
validate $? "making /app"

rm -rf /app/*
curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$logfile
validate $? "download resource"
cd /app 
unzip /tmp/cart.zip &>>$logfile
validate $? "unzipping code"

cd /app
npm install &>>$logfile
validate $? "installing resources"

cp $scriptdir/cart.service /etc/systemd/system/cart.service &>>$logfile
validate $? "copying systemdfile"

systemctl daemon-reload &>>$logfile
validate $? "reload"

systemctl enable cart
systemctl start cart &>>$logfile
validate $? "starting cart"

printtime