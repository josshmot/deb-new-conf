# Move working directory to location of this script
cd "$(dirname "$0")"

# Run primary script in bash so that we can use our fancy bash commands
bash ./sh/debian-config.sh
