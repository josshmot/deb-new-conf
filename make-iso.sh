# Check for arg
if [[ $# != 1 ]]
then
	echo "Output directory was not provided!"
	exit
fi

# Check for --help
if [[ $1 = "--help" ]]
then
	echo "Usage: make-iso.sh [OUTPUT_DIR]"
	exit
fi

# Check for genisoimage
command -v genisoimage >/dev/null 2>&1 || { echo >&2 "This script requires genisoimage to run."; exit 1; }

# Delete conflicting file if it exists
if [[ -f $1/deb-new-conf.iso ]]
then
	rm -f $1/deb-new-conf.iso
fi

# Make iso
genisoimage -J -r -V DEB_NEW_CONF -o $1/deb-new-conf.iso ./
if [[ $? != 0 ]]
then
	exit 1
fi

exit 0
