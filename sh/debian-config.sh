# --------CHECK ROOT--------
# Verify this has root permissions
if [[ $(id -u) != 0 ]]
then
    echo -e "This script requires root permisions to run. Please run as root or with the sudo command."
    exit
fi


# --------GRUB CONFIG--------
# Copy GRUB config & run update-grub


# --------APT & NALA CONFIG--------
# Copy apt sources.list


# Perform apt update & upgrade


# Install nala


# --------INSTALL NVIDIA DRIVERS--------
# Install nvidia-driver


# --------CLONE REPOS--------
# Install git, gcm


# Set git user.name & configure gcm


# ONLY IF ~/repos/ DOESN'T ALREADY EXIST:


    # mkdir ~/repos/extern/ if it doesn't already exist


    # clone github repos to ~/repos/


    # Download BASS binaries to ~/repos/extern/ and configure to run seamlessly with CVAS repo


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
