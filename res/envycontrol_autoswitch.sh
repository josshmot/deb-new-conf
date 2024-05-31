# Function to run notify-send as root, copied straight from Stack Overflow :)
notify_send()
{
    local display=$DISPLAY
    local user=$(who | grep '('$display')' | awk '{print $1}' | head -n 1)
    local uid=$(id -u $user)
    sudo -u $user DISPLAY=$display DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$uid/bus notify-send "$@"
}

# Set up variables
goalmode=$1
curmode=$(envycontrol -q)

# Check for query argument
if [ $goalmode = "query" ]
then
    notify_send -a "Switch GFX Mode" "Debian is currently running in $curmode GFX mode."
    exit
fi

# Only execute if we need to change mode
if [ $goalmode = $curmode ]
then
    notify_send -a "Switch GFX Mode" "Debian is already in $goalmode mode." "No reboot is required."
    exit
fi

notify_send -u critical -a "Switch GFX Mode" "Switching to $goalmode mode." "Debian will reboot shortly."
envycontrol -s $goalmode

# Handle some error during switch
if [ $? != 0 ]
then
    notify_send -a "Switch GFX Mode" "Error switching to $goalmode mode." "Is '$goalmode' really a valid graphics mode?"
    exit
fi

# If everything has gone well, we reboot
reboot
