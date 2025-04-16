# Define color codes for terminal text for better visibility
$Green = "`e[32m"  # Green text
$Yellow = "`e[33m" # Yellow text
$Red = "`e[31m"    # Red text
$Blue = "`e[34m"   # Blue text
$Reset = "`e[0m"   # Reset text color to default

# Main menu function to display options and navigate to selected functionality
function Main-Menu {
    Clear-Host  # Clear the terminal screen for better readability
    Write-Host "${Blue}=== Network Management Suite ==="
    Write-Host "1. Setup Network Monitoring"  # Option for setting up network monitoring tools
    Write-Host "2. Configure IP Management"   # Option for configuring IP management tools
    Write-Host "3. Configure Proxychains"     # Option for setting up proxychains configuration
    Write-Host "4. Run Security Tools"        # Option for running various security tools
    Write-Host "5. Exit"                      # Option to exit the script
    Write-Host "==============================${Reset}"
    $Choice = Read-Host "${Green}Enter your choice (1-5)${Reset}"  # Prompt user for input

    # Handle user input and call the corresponding function
    switch ($Choice) {
        1 { Setup-NetworkTools }  # Navigate to network monitoring setup
        2 { Select-IPManagementTool }  # Navigate to IP management configuration
        3 { Configure-Proxychains }  # Navigate to proxychains configuration
        4 { Run-SecurityTools }  # Navigate to security tools
        5 { Write-Host "${Yellow}Exiting...${Reset}"; exit }  # Exit the script
        Default { Write-Host "${Red}Invalid option!${Reset}"; Start-Sleep -Seconds 1; Main-Menu } # Handle invalid input
    }
}

# Function to set up network monitoring tools
function Setup-NetworkTools {
    Clear-Host  # Clear the terminal
    Write-Host "${Blue}=== Network Monitoring Setup ==="
    Write-Host "${Yellow}[!] Listing USB devices...${Reset}"
    Get-PnpDevice | Where-Object { $_.Class -eq "USB" } | Format-Table  # List USB devices connected to the system

    Write-Host "${Yellow}[!] Checking wireless interfaces...${Reset}"
    netsh wlan show interfaces  # Display wireless network interfaces

    Write-Host "${Yellow}[!] Displaying wireless configuration...${Reset}"
    netsh wlan show drivers  # Show details of wireless network drivers

    # Prompt user to configure Bluetooth
    $BtChoice = Read-Host "${Green}Configure Bluetooth? (y/n)${Reset}"
    if ($BtChoice -eq 'y') {
        Write-Host "${Yellow}[!] Configuring Bluetooth...${Reset}"
        Get-Service bthserv | Start-Service  # Start the Bluetooth service if not already running
    }

    Write-Host "${Yellow}[!] Restarting NetworkManager...${Reset}"
    Restart-Service -Name "WlanSvc"  # Restart the WLAN service to apply changes

    Read-Host "${Green}Press enter to return to main menu...${Reset}"  # Wait for user input before returning to the menu
    Main-Menu  # Return to the main menu
}

# Function to configure IP management tools
function Select-IPManagementTool {
    Clear-Host  # Clear the terminal
    Write-Host "${Blue}=== IP Management Configuration ==="
    Write-Host "1. phpIPAM"  # Option for phpIPAM installation
    Write-Host "2. NetBox"   # Option for NetBox installation
    Write-Host "3. GestióIP" # Option for GestióIP installation
    Write-Host "4. TeemIp"   # Option for TeemIp installation
    Write-Host "5. Return to Main Menu"  # Return to the main menu
    Write-Host "===============================${Reset}"
    $Choice = Read-Host "${Green}Enter your choice (1-5)${Reset}"  # Prompt user for input

    # Handle user input for IP management tools
    switch ($Choice) {
        1 {
            Write-Host "${Yellow}Installing phpIPAM...${Reset}"
            # Add phpIPAM installation steps here
        }
        2 {
            Write-Host "${Yellow}Installing NetBox...${Reset}"
            # Add NetBox installation steps here
        }
        3 {
            Write-Host "${Yellow}Installing GestióIP...${Reset}"
            # Add GestióIP installation steps here
        }
        4 {
            Write-Host "${Yellow}Installing TeemIp...${Reset}"
            # Add TeemIp installation steps here
        }
        5 { Main-Menu }  # Return to main menu
        Default { Write-Host "${Red}Invalid option!${Reset}"; Start-Sleep -Seconds 1; Select-IPManagementTool } # Handle invalid input
    }

    Read-Host "${Green}Press enter to return to main menu...${Reset}"  # Wait for user input before returning to the menu
    Main-Menu  # Return to the main menu
}

# Function to configure proxychains
function Configure-Proxychains {
    Clear-Host  # Clear the terminal
    Write-Host "${Blue}=== Proxychains Configuration ==="
    Write-Host "${Yellow}[!] Current proxychains config:${Reset}"
    Get-Content -Path "C:\Path\To\proxychains.conf" -Tail 5  # Display the last 5 lines of the proxychains configuration file

    Write-Host "${Blue}Select proxy type:"
    Write-Host "1. HTTP"  # HTTP proxy
    Write-Host "2. SOCKS4"  # SOCKS4 proxy
    Write-Host "3. SOCKS5"  # SOCKS5 proxy
    $PType = Read-Host "${Green}Enter choice (1-3)${Reset}"  # Prompt user for proxy type selection

    # Determine proxy type based on user input
    switch ($PType) {
        1 { $ProxyType = "http" }
        2 { $ProxyType = "socks4" }
        3 { $ProxyType = "socks5" }
        Default { Write-Host "${Red}Invalid type! Using SOCKS5${Reset}"; $ProxyType = "socks5" } # Default to SOCKS5 if invalid input
    }

    # Prompt user for proxy IP and port
    $ProxyIP = Read-Host "${Green}Enter proxy IP${Reset}"
    $ProxyPort = Read-Host "${Green}Enter proxy port${Reset}"

    Write-Host "${Yellow}Configuring proxychains...${Reset}"
    Add-Content -Path "C:\Path\To\proxychains.conf" -Value "$ProxyType $ProxyIP $ProxyPort"  # Add proxy configuration to the file

    Write-Host "${Green}Proxy configured! Test with: proxychains curl ifconfig.me${Reset}"  # Inform user of successful configuration
    Read-Host "${Green}Press enter to return to main menu...${Reset}"  # Wait for user input before returning to the menu
    Main-Menu  # Return to the main menu
}

# Function to run security tools
function Run-SecurityTools {
    Clear-Host  # Clear the terminal
    Write-Host "${Blue}=== Security Tools ==="
    Write-Host "${Red}WARNING: These tools should only be used on authorized networks!${Reset}"
    Write-Host "1. Network Scanner"  # Option for network scanning
    Write-Host "2. Vulnerability Scanner"  # Option for vulnerability scanning
    Write-Host "3. Anonymization Suite"  # Option for anonymization tools
    Write-Host "4. Return to Main Menu"  # Return to the main menu
    $Choice = Read-Host "${Green}Enter choice (1-4)${Reset}"  # Prompt user for input

    # Handle user input for security tools
    switch ($Choice) {
        1 {
            $Target = Read-Host "${Green}Enter target range (e.g., 192.168.1.0/24)${Reset}"  # Prompt user for target range
            Write-Host "${Yellow}Starting network scan...${Reset}"
            nmap -sS -T4 $Target  # Perform network scan using nmap
        }
        2 {
            $Target = Read-Host "${Green}Enter target IP${Reset}"  # Prompt user for target IP
            Write-Host "${Yellow}Starting vulnerability scan...${Reset}"
            # Add vulnerability scanner command here
        }
        3 {
            Write-Host "${Yellow}Starting anonymization...${Reset}"
            Start-Process -FilePath "tor.exe"  # Start Tor service
            Start-Process -FilePath "firefox.exe" -ArgumentList "-proxy-server=localhost:9050"  # Open Firefox routed through Tor
            Write-Host "${Green}Browser traffic now routed through Tor!${Reset}"  # Inform user of successful anonymization
        }
        4 { Main-Menu }  # Return to main menu
        Default { Write-Host "${Red}Invalid option!${Reset}"; Start-Sleep -Seconds 1; Run-SecurityTools } # Handle invalid input
    }

    Read-Host "${Green}Press enter to return to main menu...${Reset}"  # Wait for user input before returning to the menu
    Main-Menu  # Return to the main menu
}

# Initialization steps
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "${Red}Please run as administrator!${Reset}"  # Check if script is run as administrator
    exit  # Exit if not
}

# Securely prompt user for database password
$DBPass = Read-Host -AsSecureString "${Green}Set database password${Reset}"
$Env:DB_PASS = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($DBPass))

Main-Menu  # Start the main menu
