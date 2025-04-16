#!/bin/bash

# Get the active network interface dynamically
# The `ip` command is used to find the default network interface associated with the default route.
# `awk` extracts the interface name from the output.
interface=$(ip route | grep default | awk '{print $5}')

# Check if a valid interface was found
if [ -z "$interface" ]; then
    echo "No active network interface found. Please check your network settings."
    exit 1
fi

# Main case statement to handle script arguments
case $1 in
    --enable)
        # Enable anonymity mode
        # Step 1: Spoof the MAC address of the network interface
        # The `macchanger` command is used to randomly change the MAC address of the specified interface.
        echo "Spoofing MAC address for interface: $interface"
        sudo macchanger -r "$interface"

        # Step 2: Start the Tor service
        # The `systemctl` command is used to start the Tor anonymity network service.
        echo "Starting Tor service..."
        sudo systemctl start tor

        # Step 3: Update the anonymity configuration file
        # A configuration file is updated to indicate that anonymity mode is enabled.
        echo "ANON_MODE=true" > ./config/anonymity.conf
        echo "Anonymity enabled"
        ;;
    --disable)
        # Disable anonymity mode
        # Step 1: Restore the original MAC address of the network interface
        # The `macchanger` command is used to reset the MAC address to its permanent value.
        echo "Restoring original MAC address for interface: $interface"
        sudo macchanger -p "$interface"

        # Step 2: Stop the Tor service
        # The `systemctl` command is used to stop the Tor anonymity network service.
        echo "Stopping Tor service..."
        sudo systemctl stop tor

        # Step 3: Update the anonymity configuration file
        # A configuration file is updated to indicate that anonymity mode is disabled.
        echo "ANON_MODE=false" > ./config/anonymity.conf
        echo "Anonymity disabled"
        ;;
    *)
        # Handle invalid or missing arguments
        # Display a usage message and exit with an error code.
        echo "Usage: ./anon-mode.sh --enable | --disable"
        exit 1
        ;;
esac
