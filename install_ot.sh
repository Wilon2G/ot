#!/bin/bash
# Exit on error, pipefail, and use of unbound variables
set -euo pipefail

# --- Configuration ---
ZIP_FILE="master.zip"
DIR_NAME="ot-master"
CONFIG_DEST="/etc/ot.conf.json" # Standard location for configuration
SCRIPT_DEST="/usr/local/bin/ot"
LOG_FILE="/var/log/ot.log"

echo "Starting installation of ot..."

dependencies=(wget unzip sudo mktemp jq terminator vboxmanage arp)
#Dependency Check
for cmd in ${dependencies[@]}; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Required command '$cmd' is not installed." >&2
        exit 1
    fi
done

TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT
cd "$TMP_DIR"

echo "Downloading files..."
wget https://github.com/Wilon2G/ot/archive/refs/heads/master.zip

echo "Extracting files..."
unzip "$ZIP_FILE" > /dev/null

#Use sudo for all system-level changes
echo "Installing files to system directories..."

# ---------------------------------------------------------------Log file setup
echo "Creating log file at $LOG_FILE and setting permissions..."
sudo touch "$LOG_FILE"
# Give the installing user write permission to the log file
sudo chown "$USER":"$(id -gn $USER)" "$LOG_FILE"

# --------------------------------------------------------------------Config file installation
sudo cp "$DIR_NAME/ot.conf.json" "$CONFIG_DEST"
echo "Config installed to $CONFIG_DEST ---!"

# --------------------------------------------------------------------------Executable script installation
sudo cp "$DIR_NAME/ot.sh" "$SCRIPT_DEST"
# Ensure the script is executable
sudo chmod +x "$SCRIPT_DEST"
echo "OT installed to $SCRIPT_DEST"

echo "Installation complete! You can now run ot"


