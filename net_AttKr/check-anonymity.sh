#!/bin/bash

# Check if the Tor process is running
# The `pgrep` command searches for processes by name. The `-x` option ensures an exact match.
# If the process "tor" is found, the script proceeds with the anonymity check.
if pgrep -x "tor" > /dev/null; then
    # Inform the user that the Tor process is active
    echo "Tor is running"

    # Check the current IP address through the Tor network
    # The `curl` command fetches data from the Tor Project's API to verify the IP.
    # The `-s` option suppresses progress information to keep the output clean.
    ip=$(curl -s https://check.torproject.org/api/ip)

    # Verify if the IP is routed through the Tor network
    # The response from the API contains a JSON field `IsTor` which indicates
    # whether Tor is being used for the current connection.
    if echo "$ip" | grep -q "IsTor\":true"; then
        # If the field "IsTor" is true, anonymity is confirmed
        echo "Anonymity is enabled"
    else
        # If the field "IsTor" is not true, anonymity is not enabled
        echo "Anonymity is not enabled"
    fi
else
    # Inform the user that the Tor process is not running
    echo "Tor is not running"
fi
