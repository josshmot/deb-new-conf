log_try () { # Help function to automatically log output, and terminate script upon some failed command
    $@ &>> "$logfile"
    if [[ $? != 0 ]]
    then
        exit 1
    fi
}

# --------GET LOGFILE & USER DIRECTORY--------
if [[ $# != 2 ]]
then
    echo -e "!! User directory and/or logfile not provided! Aborting!"
    exit 2
fi

home=$1
logfile=$2
log_try echo -e ""
log_try echo -e "--------debian-config.sh--------"

# --------CHECK ROOT--------
echo -e "Verifying elevation to root..."

# Verify this has root permissions
if [[ $(id -u) != 0 ]]
then
    echo -e "!! This script requires root permisions to run. Please run as root or with the sudo command!"
    exit 1
fi

# --------SETUP WORKING AREA--------
echo -e "Setting up working area..."

# Create folder in /tmp, copy contents of iso there and set working directory
working_dir=/tmp/deb-new-conf
log_try mkdir $working_dir
log_try cp -r ./ $working_dir/
echo -e "-> Created '$working_dir' and copied files from source"

# --------GRUB CONFIG--------
echo -e "Setting up grub defaults..."

# Copy GRUB config & run update-grub
log_try cp ./res/grub_default /etc/default/grub
echo -e "-> Copied new grub config file: grub will now update..."
log_try update-grub
echo -e "---> Grub updated!"

# --------APT & NALA CONFIG--------
echo -e "Configuring apt and nala..."

# Copy apt sources.list
log_try cp ./res/apt_sources.list /etc/apt/sources.list
echo -e "-> Copied new sources.list"

# Add i386 architecture
log_try dpkg --add-architecture i386
echo -e "-> Added x86 architecture"

# apt update && install nala
echo -e "-> Updating apt package lists..."
log_try apt update
echo -e "---> Package lists updated!"

echo -e "-> Installing nala..."
log_try apt install nala -y
echo -e "---> Nala installed!"

# Perform apt upgrade
echo "-> Upgrading packages..."
log_try nala upgrade -y
echo -e "---> Upgrade complete!"

# --------INSTALL NVIDIA DRIVERS--------
echo "Installing Nvidia drivers. This could take some time..."

# Install nvidia-driver
log_try nala install nvidia-driver -y
echo -e "-> Nvidia drivers installed."

# --------CLONE REPOS--------
echo -e "Setting up git..."

# Install git, gcm
log_try nala install git -y
echo -e "-> Installed git"

gcm_bin_url=$(cat ./config/gcm_bin_url)
gcm_bin_fname=$(basename "$gcm_bin_url")
log_try wget -P "$working_dir" "$gcm_bin_url"
echo -e "-> Downloaded GCM"

log_try nala install $working_dir/$gcm_bin_fname -y
echo -e "-> Installed GCM"

# Set git user.name & configure gcm
log_try git config --global user.name josshmot
log_try git config --global user.email $(cat ./offline/github_email)
echo -e "-> Configured git username and email"

log_try git-credential-manager configure

log_try git config --global credential.credentialStore secretservice

echo -e "-> Configured git credentials"

# --------SETUP REPOS DIRECTORY--------

# ONLY IF ~/repos/ DOESN'T ALREADY EXIST:
if [[ ! -d "$home/repos" ]]
then
    echo -e "Setting up repos directory..."
    
    # mkdir ~/repos/extern/ if it doesn't already exist
    log_try mkdir -p $home/repos/extern
    echo -e "-> Created ~/repos/ and ~/repos/extern/"

    # clone github repos to ~/repos/
    echo -e "-> Cloning repos:"
    log_try cd $home/repos
    cat "$working_dir"/config/git_repos | while read repo_url
    do
        log_try git clone "$repo_url"
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
        log_try wget -P "$working_dir" "$bass24_url"
        echo -e "-----> Downloaded"
        log_try mkdir -p $bass24_dir
        log_try unzip -d "$bass24_dir" "$working_dir"/"$bass24_zip"
        echo -e "-----> Unzipped"

        # copy libs to required directories
        cat "$working_dir"/config/bass24_outdirs | while read bass24_outdir
        do
            log_try mkdir -p "$home/$bass24_outdir"
            log_try cp -r "$bass24_dir"/libx/x86_64/. "$home/$bass24_outdir"
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

exit 0
