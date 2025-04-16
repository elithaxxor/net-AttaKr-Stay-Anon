#!/bin/bash

# Dynamically fetch the active network interface
# Use the `ip route` command to identify the default network interface associated with the default route.
# This ensures the script automatically selects the primary active interface if not specified in the configuration.
interface=$(ip route | grep default | awk '{print $5}')

# Validate that an active network interface was detected
# If no interface is found, prompt the user to ensure network settings are configured or specify one manually.
if [ -z "$interface" ]; then
    echo "No active network interface found. Please check your network settings or specify an interface manually."
    exit 1
fi

# Function to display help information
# This function displays a usage guide for the script, outlining the available options and their descriptions.
show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --module <module> [params] : Run the specified module with parameters"
    echo "  --anon <action> : Enable, disable, or check anonymity"
    echo "  --help : Show this help message"
}

# Function to display the main menu in interactive mode
# This function provides a user-friendly interface to select various functionalities.
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
# This function reads user input for the target IP range and mode (stealth or regular) and executes the scan.
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

# Function to perform a MITM attack
# This function reads user input for the target and gateway IPs, and optionally captures traffic.
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

# Function to perform a Wi-Fi deauthentication attack
# This function reads user input for the interface, BSSID, and optional client MAC address.
perform_deauth() {
    source ./config/settings.conf 2>/dev/null
    read -p "Enter interface [${interface}]: " user_interface
    interface=${user_interface:-$interface} # Use dynamically detected interface if none is provided
    read -p "Enter BSSID: " bssid
    read -p "Enter client MAC (optional): " client
    if [ -n "$client" ]; then
        sudo ./wifi-attacks.sh --interface "$interface" --deauth --bssid "$bssid" --client "$client"
    else
        sudo ./wifi-attacks.sh --interface "$interface" --deauth --bssid "$bssid"
    fi
}

# Function to analyze network traffic
# This function reads user input for the interface and runs the packet analysis script.
perform_analysis() {
    source ./config/settings.conf 2>/dev/null
    read -p "Enter interface [${interface}]: " user_interface
    interface=${user_interface:-$interface} # Use dynamically detected interface if none is provided
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
    if [ -n "$anon_action" ]; then
        # Handle anonymity actions
        case $anon_action in
            enable) sudo ./anon-mode.sh --enable ;;
            disable) sudo ./anon-mode.sh --disable ;;
            check) ./check-anonymity.sh ;;
            *) echo "Invalid anonymity action"; show_help; exit 1 ;;
        esac
    elif [ -n "$module" ]; then
        # Handle module-based actions
        case $module in
            scan) sudo ./scan.sh "${params[@]}" ;;
            mitm) sudo ./mitm.sh "${params[@]}" ;;
            wifi-attacks) sudo ./wifi-attacks.sh "${params[@]}" ;;
            packet-analysis) sudo ./packet-analysis.sh "${params[@]}" ;;
            *) echo "Invalid module"; show_help; exit 1 ;;
        esac
    else
        # Handle missing actions
        echo "No action specified"
        show_help
        exit 1
    fi
fi
