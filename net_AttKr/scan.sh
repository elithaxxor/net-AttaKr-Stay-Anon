#!/bin/bash

# Parse command-line arguments
# This section processes the command-line arguments provided to the script.
# It supports the following options:
#   --stealth: Enables stealth mode for scanning (uses nmap -sn for a ping-only scan).
#   --range: Specifies the range of IP addresses to scan (e.g., 192.168.1.0/24).
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --stealth) 
            # If the --stealth flag is provided, set the stealth variable to true.
            stealth=true 
            ;;
        --range) 
            # If the --range option is provided, capture the next argument as the range.
            range="$2"
            shift # Skip the next argument since it has been processed.
            ;;
        *) 
            # Handle unknown parameters by displaying an error message and exiting the script.
            echo "Unknown parameter: $1"
            exit 1 
            ;;
    esac
    shift # Continue to the next argument.
done

# Validate range parameter
# Ensure that the --range parameter has been provided; otherwise, display an error and exit.
if [ -z "$range" ]; then
    echo "Please specify a range with --range (e.g., 192.168.1.0/24)"
    exit 1
fi

# Check anonymity mode (set by anon-mode.sh)
# This section determines whether anonymity mode is enabled by sourcing a configuration file.
# The "anonymity.conf" file should define the ANON_MODE variable as true or false.
# If the file is not found, default to ANON_MODE=false.
source ./config/anonymity.conf 2>/dev/null || ANON_MODE=false

if [ "$ANON_MODE" = true ]; then
    # If anonymity mode is enabled, prepend the "torsocks" command to enforce traffic routing through Tor.
    CMD="torsocks"
else
    # If anonymity mode is not enabled, leave the CMD variable empty.
    CMD=""
fi

# Perform scan
# This section runs the nmap command based on the provided options.
if [ "$stealth" = true ]; then
    # If stealth mode is enabled, perform a ping-only scan (-sn) on the specified range.
    $CMD nmap -sn "$range"
else
    # If stealth mode is not enabled, perform a full scan on the specified range.
    $CMD nmap "$range"
fi
