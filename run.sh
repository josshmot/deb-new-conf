# Init log file and write timestamp
logfile=/tmp/deb-new-conf.log
echo "" &>> $logfile
date &>> $logfile

# Check we aren't in root
if [[ $(id -u) = 0 ]]
then
    echo -e "!! Do not run this script as root! Instead run as some user, and the script will elevate itself when required."
    echo -e "Script failed: ran run.sh as root" &>> $logfile
    exit
fi

# Clear console
clear

# Move working directory to location of this script
cd $(dirname "$0")

# Acquire user directory
echo -e ""
echo -e "Acquiring user ID..."
uid=$(id -u)
echo -e "-> User ID is: '$uid'"
echo -e "Ran as user: $uid" &>> $logfile

# Specify templogfile path
templogfile=/tmp/deb-new-conf.log.tmp # We need this, as we can't write to the currently open log file from within debian-config.sh

# Elevate to root and run primary script in bash so that we can use our fancy bash commands
echo -e ""
echo -e "This script requires root access via sudo to install components. Please enter your password if requested."
sudo bash ./sh/debian-config.sh $uid $templogfile
configresult=$?

# copy temp log file contents into log file (only if required)
if [[ $configresult != 2 ]]
then
    cat $templogfile &>> $logfile
fi

if [[ $configresult != 0 ]]
then
    echo "Script was aborted because an error occurred. A log can be found in: '$logfile'"
    exit 1
fi
exit 0
