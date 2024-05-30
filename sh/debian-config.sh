# --------GET LOGFILE & USER DIRECTORY--------
if [[ $# != 2 ]]
then
    echo -e "!! User directory and/or logfile not provided! Aborting!"
    exit
fi

home=$1
logfile=$2
echo -e "" >> "$logfile"
echo -e "--------debian-config.sh--------" >> "$logfile"

# --------CHECK ROOT--------
echo -e ""
echo -e "Verifying elevation to root..."

# Verify this has root permissions
if [[ $(id -u) != 0 ]]
then
    echo -e "!! This script requires root permisions to run. Please run as root or with the sudo command!"
    exit
fi

# --------SETUP WORKING AREA--------
echo -e ""
echo -e "Setting up working area..."

# Create folder in /tmp, copy contents of iso there and set working directory
working_dir=/tmp/deb-new-conf
mkdir $working_dir &>> "$logfile"
cp -r ./ $working_dir/ &>> "$logfile"
echo -e "-> Created '$working_dir' and copied files from source"

# --------GRUB CONFIG--------
echo -e ""
echo -e "Setting up grub defaults..."

# Copy GRUB config & run update-grub
cp ./res/grub_default /etc/default/grub &>> "$logfile"
echo -e "-> Copied new grub config file: grub will now update..."
update-grub &>> "$logfile"
if [[ $? != 0 ]]
then
    echo -e "An error occurred, aborting!"
    exit
fi

echo -e "---> Grub updated!"

# --------APT & NALA CONFIG--------
echo -e ""
echo -e "Configuring apt and nala..."

# Copy apt sources.list
cp ./res/apt_sources.list /etc/apt/sources.list &>> "$logfile"
echo -e "-> Copied new sources.list"

# Add i386 architecture
dpkg --add-architecture i386 &>> "$logfile"
echo -e "-> Added x86 architecture"

# apt update && install nala
echo -e "-> Updating apt package lists..."
apt update &>> "$logfile"
if [[ $? != 0 ]]
then
    echo -e "An error occurred, aborting!"
    exit
fi
echo -e "---> Package lists updated!"

echo -e "-> Installing nala..."
apt install nala -y &>> "$logfile"
if [[ $? != 0 ]]
then
    echo -e "An error occurred, aborting!"
    exit
fi
echo -e "---> Nala installed!"

# Perform apt upgrade
echo "-> Upgrading packages..."
nala upgrade -y &>> "$logfile"
if [[ $? != 0 ]]
then
    echo -e "An error occurred, aborting!"
    exit
fi
echo -e "---> Upgrade complete!"

# --------INSTALL NVIDIA DRIVERS--------
echo -e ""
echo "Installing Nvidia drivers. This could take some time..."

# Install nvidia-driver
nala install nvidia-driver -y &>> "$logfile"
if [[ $? != 0 ]]
then
    echo -e "An error occurred, aborting!"
    exit
fi
echo -e "-> Nvidia drivers installed."

# --------CLONE REPOS--------
echo -e ""
echo -e "Setting up git..."

# Install git, gcm
nala install git -y &>> "$logfile"
if [[ $? != 0 ]]
then
    echo -e "An error occurred, aborting!"
    exit
fi
echo -e "-> Installed git"

gcm_bin_url=$(cat ./config/gcm_bin_url)
gcm_bin_fname=$(basename "$gcm_bin_url")
wget -P "$working_dir" "$gcm_bin_url" &>> "$logfile"
if [[ $? != 0 ]]
then
    echo -e "An error occurred, aborting!"
    exit
fi
echo -e "-> Downloaded GCM"
nala install $working_dir/$gcm_bin_fname -y &>> "$logfile"
if [[ $? != 0 ]]
then
    echo -e "An error occurred, aborting!"
    exit
fi
echo -e "-> Installed GCM"

# Set git user.name & configure gcm
git config --global user.name josshmot &>> "$logfile"
git config --global user.email $(cat ./offline/github_email) &>> "$logfile"
echo -e "-> Configured git username and email"

git-credential-manager configure &>> "$logfile"
if [[ $? != 0 ]]
then
    echo -e "An error occurred, aborting!"
    exit
fi

git config --global credential.credentialStore secretservice &>> "$logfile"

echo -e "-> Configured git credentials"

# --------SETUP REPOS DIRECTORY--------
echo -e ""

# ONLY IF ~/repos/ DOESN'T ALREADY EXIST:
if [[ ! -d "$home/repos" ]]
then
    echo -e "Setting up repos directory..."
    
    # mkdir ~/repos/extern/ if it doesn't already exist
    mkdir -p $home/repos/extern &>> "$logfile"
    echo -e "-> Created ~/repos/ and ~/repos/extern/"

    # clone github repos to ~/repos/
    echo -e "-> Cloning repos:"
    cd $home/repos &>> "$logfile"
    cat "$working_dir"/config/git_repos | while read repo_url
    do
        git clone "$repo_url" &>> "$logfile"
        if [[ $? != 0 ]]
        then
            echo -e "An error occurred, aborting!"
            exit
        fi
        echo -e "---> $repo_url"
    done
    cd "$working_dir"

    # Download BASS binaries to ~/repos/extern/ and configure to run seamlessly with CVAS repo
    echo -e "-> Downloading BASS libraries for CVAS repo..."
    cat "$working_dir"/config/bass24_liburls | while read bass24_url
    do
        # get zip filename and output dir
        bass24_zip=$(basename $bass24_url)
        bass24_dir=$home/repos/extern/${bass24_zip%.*}
        echo -e "---> $bass24_dir"

        # download and unzip
        wget -P "$working_dir" "$bass24_url" &>> "$logfile"
        if [[ $? != 0 ]]
        then
            echo -e "An error occurred, aborting!"
            exit
        fi
        echo -e "-----> Downloaded"
        mkdir -p $bass24_dir &>> "$logfile"
        unzip -d "$bass24_dir" "$working_dir"/"$bass24_zip" &>> "$logfile"
        if [[ $? != 0 ]]
        then
            echo -e "An error occurred, aborting!"
            exit
        fi
        echo -e "-----> Unzipped"

        # copy libs to required directories
        cat "$working_dir"/config/bass24_outdirs | while read bass24_outdir
        do
            mkdir -p "$home/$bass24_outdir" &>> "$logfile"
            cp -r "$bass24_dir"/libx/x86_64/. "$home/$bass24_outdir" &>> "$logfile"
            if [[ $? != 0 ]]
            then
                echo -e "An error occurred, aborting!"
                exit
            fi
            echo -e "-----> Copied into: $home/$bass24_outdir"
        done
    done
else
    echo -e "Repos directory already exists. Skipping."
fi

# --------INSTALL KDE DESKTOP--------


# --------INSTALL ASUSCTL--------
# Install asusctl dependancies


# Install rustup (with no user input?) & restart shell with 'bash'


# Remove ~/repos/extern/asusctl/ if it exists


# Download and unpack asusctl to ~/repos/extern/; build and install


# Set system profile to 'balanced'


# Copy startup script & add to cron


# --------INSTALL GFX MODE SWITCH--------
# Download and install envycontrol


# Install libnotify-bin


# Copy envycontrol_autoswitch.sh & give exec permissions


# Add permissions to sudoers file


# Add .desktop applications if they don't already exist


# --------INSTALL VSCODE--------
# Download and install VSCode


# Install vscode extensions


# --------INSTALL ENIGMA--------
# Install enigma dependancies


# Download and unpack enigma to ~/repos/extern/; build and install


# --------INSTALL WINE--------
# Install aptitude


# Install winehq-stable


# -------INSTALL STEAM & GAMES--------
# Install steam-installer


# ??? Copy game files, set compatibility settings & install games in steam programatically ???


# Copy RHEM wine script & give execution permissions


# --------INSTALL & CONFIGURE GENERAL UTILS--------
# Install neofetch, fzf, vim, mpv, keepassxc, virt-manager


# Configure keepassxc


# Copy .desktop applications


# Copy ~/Desktop/


# Copy ~/VMs/


# Copy ~/img/


# Copy ~/.config/


# --------REBOOT--------
# reboot
