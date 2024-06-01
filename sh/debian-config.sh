# Help function to automatically log output, and terminate script upon some failed command
log_try () {
    echo -e $@ &>> "$logfile"
    $@ &>> "$logfile"
    if [[ $? != 0 ]]
    then
        cleanup
        echo -e "" # just in case the cursor's at the end of a line rather than the beginning
        exit 1
    fi
}

# Executed at the end of the script or upon some error - cleans up temp directory
cleanup () {
    # MAKE SURE NO SPOOKY "rm -rf /"s CAN SNEAK IN HERE - only allow deleting things in /tmp/
    if [[ $temp_dir != "/tmp/"* ]]
    then
        echo -e "Something has gone horribly wrong - tried to clean up temp directory, but it's not in /tmp!"
        echo -e "Aborting to avoid deleting anything important."
        log_try echo -e "BEEG PROBLEM: Failed to cleanup temp directory, as it wasn't in /tmp"
        exit 1
    fi
    rm -rf $temp_dir
}

# --------GET LOGFILE & USER ID--------
if [[ $# != 2 ]]
then
    echo -e "!! User ID and/or logfile not provided! Aborting!"
    exit 2
fi

uid=$1
uname=$(id -nu $uid)
home=$(eval echo ~$uname)
logfile=$2
log_try echo -e ""
log_try echo -e "--------debian-config.sh--------"

# --------CHECK ROOT--------
echo -e ""
echo -e "Verifying elevation to root..."

# Verify this has root permissions
if [[ $(id -u) != 0 ]]
then
    echo -e "!! This script requires root permisions to run. Please run as root or with the sudo command!"
    exit 1
fi

# --------SETUP SOURCE DIR & TEMP DIR--------
echo -e ""
echo -e "Setting up working environment..."

# Set source directory to the iso/usb, and create temp directory in /tmp
source_dir=$(pwd)
temp_dir=/tmp/deb-new-conf
log_try mkdir $temp_dir
echo -e "-> Assigned source directory '$source_dir'"
echo -e "-> Created temporary directory '$temp_dir'"

# --------WIFI SPEED FIX--------
echo -e ""
echo -e "Copying wifi speed fix..."
log_try cp $source_dir/res/iwlwifi.conf /etc/modprobe.d/iwlwifi.conf

# --------GRUB CONFIG--------
echo -e ""
echo -e "Setting up grub defaults..."

# Copy GRUB config & run update-grub
log_try cp $source_dir/res/grub_default /etc/default/grub
echo -e -n "-> Copied new grub config file: grub will now update..."
log_try update-grub
echo -e "Done!"

# --------APT & NALA CONFIG--------
echo -e ""
echo -e "Configuring apt and nala..."

# Copy apt sources.list
log_try cp $source_dir/res/apt_sources.list /etc/apt/sources.list
echo -e "-> Copied new sources.list"

# Add i386 architecture
log_try dpkg --add-architecture i386
echo -e "-> Added x86 architecture"

# apt update && install nala
echo -e -n "-> Updating apt package lists..."
log_try apt update
echo -e "Done!"

echo -e -n "-> Installing nala..."
log_try apt install nala -y
echo -e "Done!"

# Perform apt upgrade
echo -e -n "-> Upgrading packages (NOT REALLY SHHH)..."
# log_try nala upgrade -y
echo -e "Done!"

# --------INSTALL NVIDIA DRIVERS--------
echo -e ""
echo -e -n "Installing Nvidia drivers (NOT REALLY SHHH). This could take some time..."

# Install nvidia-driver
# log_try nala install nvidia-driver -y
echo -e "Done!"

# --------CLONE REPOS--------
echo -e ""
echo -e "Setting up git..."

# Install git, gcm
echo -e -n "-> Installing git..."
log_try nala install git -y
echo -e "Done!"

echo -e -n "-> Downloading GCM..."
gcm_bin_url=$(cat $source_dir/config/gcm_bin_url)
gcm_bin_fname=$(basename "$gcm_bin_url")
log_try wget -P "$temp_dir" "$gcm_bin_url"
echo -e "Done!"

echo -e -n "-> Installing GCM..."
log_try nala install $temp_dir/$gcm_bin_fname -y
echo -e "Done!"

# Set git user.name & configure gcm
log_try git config --global user.name josshmot
log_try git config --global user.email $(cat ./offline/github_email)
echo -e "-> Configured git username and email"

log_try git-credential-manager configure

log_try git config --global credential.credentialStore secretservice

echo -e "-> Configured git credentials"

# --------SETUP REPOS DIRECTORY--------
echo -e ""

# ONLY IF ~/repos/ DOESN'T ALREADY EXIST:
if [[ ! -d "$home/repos" ]]
then
    echo -e "Setting up repos directory..."

    # Install unzip if we haven't already
    log_try nala install unzip -y
    echo -e "-> Installed unzip"
    
    # mkdir ~/repos/extern/ if it doesn't already exist
    log_try mkdir -p $home/repos/extern
    echo -e "-> Created ~/repos/ and ~/repos/extern/"

    # clone github repos to ~/repos/
    echo -e "-> Cloning repos:"
    log_try cd $home/repos
    cat $source_dir/config/git_repos | while read repo_url
    do
        echo -e -n "      $repo_url..."
        log_try git clone "$repo_url"
        echo -e "Done!"
    done
    cd "$source_dir"

    # Download BASS binaries to ~/repos/extern/ and configure to run seamlessly with CVAS repo
    echo -e "-> Downloading BASS libraries for CVAS repo..."
    cat $source_dir/config/bass24_liburls | while read bass24_url
    do
        # get zip filename and output dir
        bass24_zip=$(basename $bass24_url)
        bass24_dir=$home/repos/extern/${bass24_zip%.*}

        # download and unzip
        echo -e -n "      Downloading $bass24_dir..."
        log_try wget -P "$temp_dir" "$bass24_url"
        echo -e "Done!"
        log_try mkdir -p $bass24_dir
        echo -e -n "      Unzipping $bass24_dir..."
        log_try unzip -d "$bass24_dir" "$temp_dir"/"$bass24_zip"
        echo -e "Done!"


        # copy libs to required directories
        cat "$source_dir"/config/bass24_outdirs | while read bass24_outdir
        do
            log_try mkdir -p "$home/$bass24_outdir"
            log_try cp -r "$bass24_dir"/libs/x86_64/. "$home/$bass24_outdir"
            echo -e "      Copied into: $home/$bass24_outdir"
        done
    done
else
    echo -e "Repos directory already exists. Skipping."
fi

# --------INSTALL DOTNET--------
echo -e ""
echo -e "Installing dotnet..."

echo -e -n "-> Adding support for Microsoft production packages..."
log_try wget -P $temp_dir https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb
log_try dpkg -i $temp_dir/packages-microsoft-prod.deb
echo -e "Done!"

echo -e -n "-> Updating package lists..."
log_try nala update
echo -e "Done!"

echo -e -n "-> Installing dotnet SDK..."
log_try nala install dotnet-sdk-8.0 -y
echo -e "Done!"

# --------INSTALL KDE DESKTOP--------
echo -e ""
echo -e -n "Installing KDE Desktop if needed. This could take a very long time..."
log_try nala install task-kde-desktop -y
echo -e "Done!"

# --------INSTALL ASUSCTL--------
echo -e ""
echo -e "Building and installing asusctl..."

# Install asusctl dependancies
echo -e -n "-> Installing dependancies..."
log_try nala install curl make gcc pkg-config libudev-dev libseat-dev libxkbcommon-dev libinput-dev libgbm-dev -y
echo -e "Done!"

# Install rustup (with no user input?) & apply env to shell
echo -e -n "-> Installing rustup..."
log_try wget -O $temp_dir/rustup-install.sh https://sh.rustup.rs
log_try sudo -u $uname bash $temp_dir/rustup-install.sh -y
echo -e "Done!"

# Remove ~/repos/extern/asusctl/ if it exists
if [[ -d $home/repos/extern/asusctl ]]
then
    log_try rm -rf $home/repos/extern/asusctl
    echo -e "-> Removed old asusctl repo"
fi

# Download and unpack asusctl to ~/repos/extern/
echo -e -n "-> Cloning asusctl repo..."
log_try cd $home/repos/extern
log_try git clone https://gitlab.com/asus-linux/asusctl.git
echo -e "Done!"

# Build and install
echo -e -n "-> Building asusctl (not actually SHHHH). This could take a very long time..."
log_try cd $home/repos/extern/asusctl
log_try chmod 777 -R $home/repos/extern/asusctl
# log_try sudo -u $uname env "PATH=$home/.cargo/bin:$PATH" make # need to run this as the original user because for SOME REASON RUST ONLY INSTALLS FOR ONE USER...WTFTFWTTFWTFTFWT
# log_try make install
log_try cd $source_dir
echo -e "Done!"

# --------INSTALL GFX MODE SWITCH--------
echo -e ""
echo -e "Installing GFX Mode Switch..."

# Download and install envycontrol
envycontrol_url=$(curl -s https://api.github.com/repos/bayasdev/envycontrol/releases/latest | grep browser_download_url | cut -d '"' -f 4)

echo -e -n "-> Downloading envycontrol..."
log_try wget -P $temp_dir $envycontrol_url
echo -e "Done!"

echo -e -n "-> Installing envycontrol..."
log_try nala install $temp_dir/$(basename $envycontrol_url) -y
echo -e "Done!"

# Install libnotify-bin
echo -e -n "-> Installing libnotify-bin..."
log_try nala install libnotify-bin -y
echo -e "Done!"

# Copy envycontrol_autoswitch.sh & give exec permissions
if ! [[ -d /usr/local/sh ]]
then
    log_try mkdir -p /usr/local/sh
    echo -e "-> Created /usr/local/sh/"
fi
log_try cp $source_dir/res/envycontrol_autoswitch.sh /usr/local/sh/envycontrol_autoswitch.sh
echo -e "-> Copied envycontrol autoswitch script"

log_try chmod +x /usr/local/sh/envycontrol_autoswitch.sh
echo -e "-> Applied execution permissions"

# Add permissions to sudoers file
log_try echo -e "%users\tALL=(ALL:ALL) NOPASSWD:\t/usr/local/sh/envycontrol_autoswitch.sh" >> /etc/sudoers
echo -e "-> Allowed script sudo execution without password in sudoers file"

# --------INSTALL VSCODE--------
echo -e ""
echo -e "Installing VSCode..."

# Download and install VSCode
echo -e -n "-> Downloading package..."
log_try wget -O $temp_dir/vscode.deb https://go.microsoft.com/fwlink/?LinkID=760868
echo -e "Done!"

echo -e -n "-> Installing package..."
log_try nala install $temp_dir/vscode.deb -y
echo -e "Done!"

# Install vscode extensions
echo -e "-> Installing extensions. This could take some time..."
cat "$source_dir"/config/vscode_extensions | while read vscode_extension
    do
        echo -e -n "      $vscode_extension..."
        log_try code --install-extension $vscode_extension
        echo -e "Done!"
    done

# --------INSTALL ENIGMA--------
echo -e ""
echo -e "Building and installing Enigma"

# Install enigma dependancies
echo -e -n "-> Installing dependancies..."
log_try nala install g++ libsdl2-dev libsdl2-ttf-dev libsdl2-mixer-dev libsdl2-image-dev libxerces-c-dev libcurlpp-dev imagemagick -y
echo -e "Done!"

# Download and unpack enigma to ~/repos/extern/
enigma_url=$(cat $source_dir/config/enigma_url)

echo -e -n "-> Downloading source..."
log_try wget -P $temp_dir $enigma_url
echo -e "Done!"

echo -e -n "-> Extracting archive..."
log_try tar -xf $temp_dir/$(basename $enigma_url) -C $home/repos/extern/
echo -e "Done!"

# Move to source directory and build
log_try cd $home/repos/extern
log_try cd $(ls | grep enigma)

echo -e -n "-> Configuring build environment..."
log_try ./configure
echo -e "Done!"

echo -e -n "-> Building Enigma. This could take some time..."
log_try make -j$(nproc --all)
echo -e "Done!"

echo -e -n "-> Installing Enigma..."
log_try make install
echo -e "Done!"

log_try cd $source_dir

# --------INSTALL WINE--------
echo -e "Installing Wine..."

# Install aptitude
echo -e ""
echo -e -n "-> Installing Aptitude..."
log_try nala install aptitude -y
echo -e "Done!"

# Install winehq-stable
log_try mkdir -pm755 /etc/apt/keyrings
log_try wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
echo -e "-> Added WineHQ repository key"

log_try wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources
echo -e "-> Added WineHQ sources"

echo -e -n "-> Updating package lists..."
log_try nala update
echo -e "Done!"

echo -e -n "-> Installing WineHQ..."
log_try aptitude install winehq-stable -y
echo -e "Done!"

# -------INSTALL STEAM & GAMES--------
# Install steam-installer


# ??? Copy game files, set compatibility settings & install games in steam programatically ???


# Copy RHEM wine script & give execution permissions


# --------INSTALL SPOTIFY--------



# --------INSTALL & CONFIGURE GENERAL UTILS--------
# Install neofetch, fzf, vim, mpv, keepassxc, virt-manager


# Configure keepassxc


# Copy .desktop applications


# Copy ~/Desktop/


# Copy ~/VMs/


# Copy ~/img/


# Copy ~/.config/


# --------CLEAN UP & REBOOT--------
# cleanup
# reboot
