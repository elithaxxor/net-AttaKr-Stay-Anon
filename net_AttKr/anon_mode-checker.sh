#!/bin/bash

# anonymous mode checker 

interface=$(iw dev | awk '$1=="Interface"{print $2}' | head -n 1)

case $1 in
    --enable)
        # Spoof MAC address
        sudo macchanger -r "$interface"
        # Start Tor
        sudo systemctl start tor
        echo "ANON_MODE=true" > ./config/anonymity.conf
        echo "Anonymity enabled"
        ;;
    --disable)
        # Restore MAC address
        sudo macchanger -p "$interface"
        # Stop Tor
        sudo systemctl stop tor
        echo "ANON_MODE=false" > ./config/anonymity.conf
        echo "Anonymity disabled"
        ;;
    *)
        echo "Usage: ./anon-mode.sh --enable | --disable"
        exit 1
        ;;
esac
