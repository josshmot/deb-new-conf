# Check we aren't in root
if [[ $(id -u) = 0 ]]
then
    echo -e "Do not run this script as root! Instead run as some user, and the script will elevate itself when required."
    exit
fi

# Move working directory to location of this script
cd $(dirname "$0")

# Acquire user directory
echo -e "Acquiring user directory..."
home = $(readlink -f ~/)
echo -e "User directory is: $home"

# Elevate to root and run primary script in bash so that we can use our fancy bash commands
echo -e "This script now requires root access via sudo to install components. Please enter your password when requested."
sudo bash ./sh/debian-config.sh $home
