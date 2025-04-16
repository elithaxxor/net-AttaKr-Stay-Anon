#!/bin/bash

# This script is a modular toolkit for performing network attacks, anonymity management,
# and traffic analysis. The script provides both an interactive menu and command-line options.

# Dynamically fetch the active network interface
# The `ip route` command identifies the default network interface associated with the default route.
# This ensures the primary active interface is automatically selected if the user does not specify one.
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
    source ./config/settings.conf 2>/dev/null # Load configuration if available
    read -p "Enter IP range [${default_range}]: " range
    range=${range:-$default_range} # Use the default range if none is provided
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
    source ./config/settings.conf 2>/dev/null # Load configuration if available
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
    source ./config/settings.conf 2>/dev/null # Load configuration if available
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
perform_analysis() {
    source ./config/settings.conf 2>/dev/null # Load configuration if available
    read -p "Enter interface [${interface}]: " user_interface
    interface=${user_interface:-$interface} # Use the detected interface if none is provided
    sudo ./packet-analysis.sh --interface "$interface"
}

# Main logic for handling command-line arguments or interactive mode
if [ "$1" = "--help" ]; then
    # Display help information if the --help flag is provided
    show_help
    exit 0
elif [ $# -eq 0 ]; then
    # Interactive mode: Display the menu and handle user selections
    while true; do
        show_menu
        read -p "Select an option: " choice
        case $choice in
            1) sudo ./anon-mode.sh --enable ;; # Enable anonymity
            2) sudo ./anon-mode.sh --disable ;; # Disable anonymity
            3) ./check-anonymity.sh ;; # Check anonymity status
            4) perform_scan ;; # Perform a network scan
            5) perform_mitm ;; # Start a MITM attack
            6) perform_deauth ;; # Perform Wi-Fi deauthentication
            7) perform_analysis ;; # Analyze network traffic
            8) exit 0 ;; # Exit the script
            *) echo "Invalid option" ;; # Handle invalid menu selections
        esac
    done
else
    # Command-line mode: Parse and execute specified options
    module=""
    anon_action=""
    params=()
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --module)
                module=$2
                shift 2
                ;;
            --anon)
                anon_action=$2
                shift 2
                ;;
            *)
                params+=("$1")
                shift
                ;;
        esac
    done

    # Handle anonymity actions
    if [ -n "$anon_action" ]; then
        case $anon_action in
            enable) sudo ./anon-mode.sh --enable ;;
            disable) sudo ./anon-mode.sh --disable ;;
            check) ./check-anonymity.sh ;;
            *) echo "Invalid anonymity action"; show_help; exit 1 ;;
        esac

    # Handle specific modules
    elif [ -n "$module" ]; then
        case $module in
            scan) sudo ./scan.sh "${params[@]}" ;;
            mitm) sudo ./mitm.sh "${params[@]}" ;;
            wifi-attacks) sudo ./wifi-attacks.sh "${params[@]}" ;;
            packet-analysis) sudo ./packet-analysis.sh "${params[@]}" ;;
            *) echo "Invalid module"; show_help; exit 1 ;;
        esac
    else
        echo "No action specified"
        show_help
        exit 1
    fi
fi
