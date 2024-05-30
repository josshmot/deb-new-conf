# Init log file and write timestamp
logfile=/tmp/deb-new-conf.log
echo "" | tee -a $logfile &>/dev/null
date | tee -a $logfile &>/dev/null

# Check we aren't in root
if [[ $(id -u) = 0 ]]
then
    echo -e "!! Do not run this script as root! Instead run as some user, and the script will elevate itself when required."
    echo -e "Script failed: ran run.sh as root" | tee -a $logfile &>/dev/null
    exit
fi

# Move working directory to location of this script
cd $(dirname "$0")

# Acquire user directory
echo -e "Acquiring user directory..."
home=$(readlink -f ~/)
echo -e "-> User directory is: '$home'"
echo -e "Home directory: $home" | tee -a $logfile &>/dev/null

# Elevate to root and run primary script in bash so that we can use our fancy bash commands
echo -e ""
echo -e "This script requires root access via sudo to install components. Please enter your password if requested."
sudo bash ./sh/debian-config.sh $home $logfile
