#!/bin/bash

# This script is a modular toolkit for performing network attacks, anonymity management,
# and traffic analysis. The script provides an interactive menu and command-line options.

# Dynamically fetch the active network interface
# Use the `ip route` command to identify the default network interface associated with the default route.
# This ensures the script automatically selects the primary active interface if not specified by the user.
interface=$(ip route | grep default | awk '{print $5}')

# Function to display help information
# This function provides usage instructions and lists available options for the script.
show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --module <module> [params] : Run the specified module with parameters"
    echo "  --anon <action> : Enable, disable, or check anonymity"
    echo "  --help : Show this help message"
}

# Function to display the interactive menu
# This function is called in interactive mode to allow users to select an option.
show_menu() {
    echo "Welcome to net-AttaKr-Stay-Anon"
    echo "Please select an option:"
    echo "1. Enable Anonymity"
    echo "2. Disable Anonymity"
    echo "3. Check Anonymity Status"
    echo "4. Perform Network Scan"
    echo "5. Start MITM Attack"
    echo "6. Perform Wi-Fi Deauthentication"
    echo "7. Analyze Network Traffic"
    echo "8. Exit"
}

# Function to perform a network scan
# Prompts the user for an IP range and whether to use stealth mode, then runs the scan.
perform_scan() {
    source ./config/settings.conf 2>/dev/null
    read -p "Enter IP range [${default_range}]: " range
    range=${range:-$default_range} # Use default range if none is provided
    read -p "Use stealth mode? (y/n): " stealth
    if [ "$stealth" = "y" ]; then
        sudo ./scan.sh --range "$range" --stealth
    else
        sudo ./scan.sh --range "$range"
    fi
}

# Function to perform a man-in-the-middle (MITM) attack
# Prompts the user for target and gateway IPs, and optionally captures network traffic.
perform_mitm() {
    source ./config/settings.conf 2>/dev/null
    read -p "Enter target IP: " target
    read -p "Enter gateway IP: " gateway
    read -p "Capture traffic? (y/n): " capture
    if [ "$capture" = "y" ]; then
        sudo ./mitm.sh --interface "$interface" --target "$target" --gateway "$gateway" --capture
    else
        sudo ./mitm.sh --interface "$interface" --target "$target" --gateway "$gateway"
    fi
}

# Function to perform Wi-Fi deauthentication
# Prompts the user for the interface, BSSID, and optional client MAC address, then runs the attack.
perform_deauth() {
    source ./config/settings.conf 2>/dev/null
    read -p "Enter interface [${interface}]: " user_interface
    interface=${user_interface:-$interface} # Use the detected interface if none is provided
    read -p "Enter BSSID: " bssid
    read -p "Enter client MAC (optional): " client
    if [ -n "$client" ]; then
        sudo ./wifi-attacks.sh --interface "$interface" --deauth --bssid "$bssid" --client "$client"
    else
        sudo ./wifi-attacks.sh --interface "$interface" --deauth --bssid "$bssid"
    fi
}

# Function to perform network traffic analysis
# Prompts the user for the interface and runs the packet analysis script.
perform_analysis
