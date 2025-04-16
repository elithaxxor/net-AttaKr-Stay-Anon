#!/bin/bash

# Get the active network interface dynamically
# The `ip` command is used to find the default network interface associated with the default route.
# `awk` extracts the interface name from the output.
interface=$(ip route | grep default | awk '{print $5}')

# Check if a valid network interface was found
# If no interface is found, the script exits with an error message.
if [ -z "$interface" ]; then
    echo "No active network interface found. Please check your network settings."
    exit 1
fi

# Parse command-line arguments
# This section processes options provided to the script.
# Supported option:
#   --interface <interface-name>: Allows the user to specify a custom network interface.
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --interface) 
            # Assign the user-specified interface to the variable
            interface="$2"
            shift # Skip the next argument since it has been processed
            ;;
        *) 
            # Handle unknown arguments and provide an error message
            echo "Unknown parameter: $1"
            echo "Usage: ./script.sh [--interface <interface-name>]"
            exit 1
            ;;
    esac
    shift # Move to the next argument
done

# Validate the selected network interface
# Check if the specified interface exists on the system using the `ip link` command.
if ! ip link show "$interface" > /dev/null 2>&1; then
    echo "Error: Network interface '$interface' not found."
    echo "Please specify a valid interface using --interface <interface-name>."
    exit 1
fi

# Display the selected network interface
# Inform the user about the interface being used for the tcpdump operation.
echo "Using network interface: $interface"

# Start packet capture using tcpdump
# The `tcpdump` command captures packets on the specified interface.
# The `-i` option specifies the interface to listen on.
echo "Starting packet capture on interface: $interface"
sudo tcpdump -i "$interface"
