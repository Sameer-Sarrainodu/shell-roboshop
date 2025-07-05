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

dnf install golang -y
validate $? "installing golang"

id roboshop &>>$logfile
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$logfile
    validate $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $yellow SKIPPING $nc"
fi

mkdir -p /app
validate $? "making app"
rm -rf /app/*
curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>>$logfile 
cd /app 
unzip /tmp/dispatch.zip &>>$logfile
validate $? "down and unzipping "

cd /app
go mod init dispatch &>>$logfile
validate $? "go init"

go get &>>$logfile
validate $? "getting log"

go build &>>$logfile
validate $? "buildng go"

cp $scriptdir/dispatch.service /etc/systemd/system/dispatch.service &>>$logfile
validate $? "copying system service file."

systemctl daemon-reload
systemctl enable dispatch
systemctl start dispatch
validate $? "starting dispatch"

printtime

