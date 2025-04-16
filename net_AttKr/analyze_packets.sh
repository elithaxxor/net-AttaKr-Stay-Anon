#!/bin/bash

# analyze packets using TCPDUMP 

interface=$(ip route | grep default | awk '{print $5}')
# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --interface) interface="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

sudo tcpdump -i "$interface"
