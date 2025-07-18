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

dnf install maven -y &>>$logfile
validate $? "installing maven"

id roboshop &>>$logfile
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$logfile
    validate $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $yellow SKIPPING $nc"
fi

mkdir -p /app
validate $? "creating dir /app"

rm -rf /app/*
curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$logfile
cd /app 
unzip /tmp/shipping.zip
validate $? "down and unzipping"

cd /app 
mvn clean package &>>$logfile 
validate $? "clean mvn project" 

mv target/shipping-1.0.jar shipping.jar &>>$logfile
validate $? "mvoing shipping"

cp $scriptdir/shipping.service /etc/systemd/system/shipping.service &>>$logfile
validate $? "coping shipping service"

systemctl daemon-reload &>>$logfile
validate $? "reload"

systemctl enable shipping
systemctl start shipping &>>$logfile
validate $? "starting shipping"

dnf install mysql -y
validate $? "installing mysql"

mysql -h mysql.sharkdev.shop -uroot -pRoboShop@1 < /app/db/schema.sql
mysql -h mysql.sharkdev.shop -uroot -pRoboShop@1 < /app/db/app-user.sql
mysql -h mysql.sharkdev.shop -uroot -pRoboShop@1 < /app/db/master-data.sql

systemctl restart shipping
validate $? "restarting"

printtime