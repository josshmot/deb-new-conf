# --------CHECK ROOT--------
# Verify this has root permissions
if [[ $(id -u) != 0 ]]
then
    echo -e "This script requires root permisions to run. Please run as root or with the sudo command."
    exit
fi

# --------SETUP WORKING AREA--------
echo "Setting up working area..."

# Get working directory (we this is run from run.sh then it should be the root of that script)
working_dir=$(pwd)

# Create tmp directory, which we'll remove at the end
$temp_dir="$work_dir/tmp"
mkdir $temp_dir

# --------GRUB CONFIG--------
echo "Setting up grub defaults..."

# Copy GRUB config & run update-grub
cp ./res/grub_default /etc/default/grub
update-grub

# --------APT & NALA CONFIG--------
echo "Configuring apt and nala..."

# Copy apt sources.list
cp ./res/apt_sources.list /etc/apt/sources.list

# Add i386 architecture
dpkg --add-architecture i386

# apt update && install nala
apt update; apt install nala -y

# Perform nala upgrade
nala upgrade -y

# --------INSTALL NVIDIA DRIVERS--------
echo "Installing Nvidia drivers..."

# Install nvidia-driver
nala install nvidia-driver -y

# --------CLONE REPOS--------
echo "Setting up git..."

# Install git, gcm
nala install git

wget -P $temp_dir $(cat ./config/gcm_bin_url) # we will remove this temporary file later
nala install ./tmp/gcm-linux_amd64*

# Set git user.name & configure gcm
git config --global user.name josshmot
git config --global user.email $(cat ./offline/github_email)

git-credential-manager configure

git config --global credential.credentialStore secretservice

# ONLY IF ~/repos/ DOESN'T ALREADY EXIST:
if [[ ! -d "~/repos" ]]
then
    echo "Setting up repos directory..."
    
    # mkdir ~/repos/extern/ if it doesn't already exist
    mkdir ~/repos/extern

    # clone github repos to ~/repos/
    cd ~/repos
    cat $working_dir/config/git_repos | while read repo_url
    do
        git clone repo_url
    done
    cd $working_dir

    # Download BASS binaries to ~/repos/extern/ and configure to run seamlessly with CVAS repo
    cat $working_dir/config/bass24_liburls | while read bass24_url
    do
        # get zip filename and output dir
        bass24_zip=$(basename $bass24_url)
        bass24_dir="~/repos/extern/${bass24_zip%.*}"

        # download and unzip
        wget -P $temp_dir $bass24_url
        unzip -d $bass24_dir $temp_dir/$bass24_zip

        # copy libs to required directories
        cat $working_dir/config/bass24_outdirs | while read bass24_outdir
        do
            mkdir $bass24_outdir
            cp $bass24_dir/libx/x86_64/. $bass24_outdir
        done
    done
else
    echo "Repos directory already exists. Skipping."
fi

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
