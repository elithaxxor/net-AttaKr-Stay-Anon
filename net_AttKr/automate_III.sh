#!/bin/bash

# Function to display help
show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --module <module> [params] : Run the specified module with parameters"
    echo "  --anon <action> : Enable, disable, or check anonymity"
    echo "  --help : Show this help message"
}

# Function to display menu
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

# Function to perform scan
perform_scan() {
    source ./config/settings.conf 2>/dev/null
    read -p "Enter IP range [${default_range}]: " range 
    range=${range:-$default_range}
    read -p "Use stealth mode? (y/n): " stealth
    if [ "$stealth" = "y" ]; then
        sudo ./scan.sh --range "$range" --stealth
    else
        sudo ./scan.sh --range "$range"
    fi
}

# Function to perform MITM
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

# Function to perform deauth
perform_deauth() {
    source ./config/settings.conf 2>/dev/null
    read -p "Enter interface [${interface}]: " user_interface
    interface=${user_interface:-$interface}
    read -p "Enter BSSID: " bssid
    read -p "Enter client MAC (optional): " client
    if [ -n "$client" ]; then
        sudo ./wifi-attacks.sh --interface "$interface" --deauth --bssid "$bssid" --client "$client"
    else
        sudo ./wifi-attacks.sh --interface "$interface" --deauth --bssid "$bssid"  
    fi
}

# Function to perform analysis
perform_analysis() {
    source ./config/settings.conf 2>/dev/null
    read -p "Enter interface [${interface}]: " user_interface
    interface=${user_interface:-$interface}
    sudo ./packet-analysis.sh --interface "$interface" 
}

# Main logic 
if [ "$1" = "--help" ]; then
    show_help
    exit 0
elif [ $# -eq 0 ]; then
    # Interactive mode
    while true; do
        show_menu
        read -p "Select an option: " choice
        case $choice in
            1) sudo ./anon-mode.sh --enable ;;
            2) sudo ./anon-mode.sh --disable ;;  
            3) ./check-anonymity.sh ;;
            4) perform_scan ;;
            5) perform_mitm ;;
            6) perform_deauth ;;
            7) perform_analysis ;;
            8) exit 0 ;;
            *) echo "Invalid option" ;;
        esac
    done
else
    # Command-line mode  
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
        case $anon_action in
            enable) sudo ./anon-mode.sh --enable ;;
            disable) sudo ./anon-mode.sh --disable ;;
            check) ./check-anonymity.sh ;;
            *) echo "Invalid anonymity action"; show_help; exit 1 ;;
        esac
    elif [ -n "$module" ]; then
        case $module in
            scan) sudo ./scan.sh "${params[@]}" ;;
            mitm) sudo ./mitm.sh "${params[@]}" ;;
            wifi-attacks) sudo ./wifi-attacks.sh "${params[@]}" ;;
            packet-analysis) sudo ./packet-analysis.sh "${params[@]}" ;;
            *) echo "Invalid module"; show_help; exit 1 ;;
        esac
    else
        echo "No action specified"; show_help; exit 1 
    fi
fi
