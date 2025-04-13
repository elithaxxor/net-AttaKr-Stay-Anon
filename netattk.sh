#!/bin/bash

echo "give me a bottle of rum!"
#!/bin/bash

# Color definitions
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

# Main menu function
main_menu() {
    clear
    echo "${BLUE}=== Network Management Suite ==="
    echo "1. Setup Network Monitoring"
    echo "2. Configure IP Management"
    echo "3. Configure Proxychains"
    echo "4. Run Security Tools"
    echo "5. Exit"
    echo "===============================${RESET}"
    read -p "${GREEN}Enter your choice (1-5): ${RESET}" choice

    case $choice in
        1) setup_network_tools ;;
        2) select_ip_management_tool ;;
        3) configure_proxychains ;;
        4) run_security_tools ;;
        5) echo "${YELLOW}Exiting...${RESET}"; exit 0 ;;
        *) echo "${RED}Invalid option!${RESET}"; sleep 1; main_menu ;;
    esac
}

setup_network_tools() {
    clear
    echo "${BLUE}=== Network Monitoring Setup ==="
    echo "${YELLOW}[!] Listing USB devices...${RESET}"
    lsusb

    echo "${YELLOW}[!] Checking airmon-ng...${RESET}"
    sudo airmon-ng check

    echo "${YELLOW}[!] Killing conflicting processes...${RESET}"
    sudo airmon-ng check kill

    echo "${YELLOW}[!] Starting airmon-ng on interfaces...${RESET}"
    interfaces=($(iw dev | awk '$1=="Interface"{print $2}'))
    
    for intf in "${interfaces[@]}"; do
        echo "${BLUE}Starting monitor mode on $intf${RESET}"
        sudo airmon-ng start $intf
    done

    echo "${YELLOW}[!] Displaying wireless configuration...${RESET}"
    iwconfig

    read -p "${GREEN}Configure Bluetooth? (y/n): ${RESET}" bt_choice
    if [[ $bt_choice == "y" ]]; then
        echo "${YELLOW}[!] Configuring Bluetooth...${RESET}"
        sudo hciconfig -a
        sudo hciconfig hci0 up
        sudo hciconfig -a
    fi

    echo "${YELLOW}[!] Restarting NetworkManager...${RESET}"
    sudo systemctl restart NetworkManager

    read -p "${GREEN}Press enter to return to main menu...${RESET}"
    main_menu
}

select_ip_management_tool() {
    clear
    echo "${BLUE}=== IP Management Configuration ==="
    echo "1. phpIPAM"
    echo "2. NetBox"
    echo "3. GestióIP"
    echo "4. TeemIp"
    echo "5. Return to Main Menu"
    echo "===============================${RESET}"
    read -p "${GREEN}Enter your choice (1-5): ${RESET}" choice

    case $choice in
        1)
            echo "${YELLOW}Installing phpIPAM...${RESET}"
            sudo apt update && sudo apt install -y apache2 mariadb-server php php-mysql php-xml php-mbstring
            sudo mysql -e "CREATE DATABASE phpipam;"
            sudo mysql -e "CREATE USER 'phpipam'@'localhost' IDENTIFIED BY '${DB_PASS}';"
            sudo mysql -e "GRANT ALL PRIVILEGES ON phpipam.* TO 'phpipam'@'localhost';"
            sudo mysql -e "FLUSH PRIVILEGES;"
            
            cd /var/www/html
            sudo git clone https://github.com/phpipam/phpipam.git
            sudo chown -R www-data:www-data phpipam
            cp phpipam/config.dist.php phpipam/config.php
            
            echo "${GREEN}phpIPAM installed! Access at: http://$(hostname -I | awk '{print $1}')/phpipam${RESET}"
            ;;
        2)
            echo "${YELLOW}Installing NetBox...${RESET}"
            sudo apt update && sudo apt install -y python3 python3-pip python3-venv git
            sudo git clone -b master https://github.com/netbox-community/netbox.git /opt/netbox
            cd /opt/netbox
            
            python3 -m venv venv
            source venv/bin/activate
            pip install -r requirements.txt
            
            echo "${GREEN}NetBox installed! Configure with: python3 manage.py runserver 0.0.0.0:8000${RESET}"
            ;;
        3)
            echo "${YELLOW}Installing GestióIP...${RESET}"
            sudo apt update && sudo apt install -y apache2 mariadb-server php php-mysql php-xml php-mbstring
            sudo mysql -e "CREATE DATABASE gestioip;"
            sudo mysql -e "CREATE USER 'gestioip'@'localhost' IDENTIFIED BY '${DB_PASS}';"
            sudo mysql -e "GRANT ALL PRIVILEGES ON gestioip.* TO 'gestioip'@'localhost';"
            sudo mysql -e "FLUSH PRIVILEGES;"
            
            cd /var/www/html
            sudo git clone https://github.com/gestioip/gestioip.git
            sudo chown -R www-data:www-data gestioip
            cp gestioip/config.php.example gestioip/config.php
            
            echo "${GREEN}GestioIP installed! Access at: http://$(hostname -I | awk '{print $1}')/gestioip${RESET}"
            ;;
        4)
            echo "${YELLOW}Installing TeemIp...${RESET}"
            sudo apt update && sudo apt install -y apache2 mariadb-server php php-mysql php-xml php-mbstring
            sudo mysql -e "CREATE DATABASE teemip;"
            sudo mysql -e "CREATE USER 'teemip'@'localhost' IDENTIFIED BY '${DB_PASS}';"
            sudo mysql -e "GRANT ALL PRIVILEGES ON teemip.* TO 'teemip'@'localhost';"
            sudo mysql -e "FLUSH PRIVILEGES;"
            
            cd /var/www/html
            sudo git clone https://github.com/TeemIp/teemip.git
            sudo chown -R www-data:www-data teemip
            cp teemip/config.php.example teemip/config.php
            
            echo "${GREEN}TeemIp installed! Access at: http://$(hostname -I | awk '{print $1}')/teemip${RESET}"
            ;;
        5) main_menu ;;
        *) echo "${RED}Invalid option!${RESET}"; sleep 1; select_ip_management_tool ;;
    esac
    
    read -p "${GREEN}Press enter to return to main menu...${RESET}"
    main_menu
}

configure_proxychains() {
    clear
    echo "${BLUE}=== Proxychains Configuration ==="
    echo "${YELLOW}[!] Current proxychains config:${RESET}"
    tail -n 5 /etc/proxychains.conf
    
    echo "\n${BLUE}Select proxy type:"
    echo "1. HTTP"
    echo "2. SOCKS4"
    echo "3. SOCKS5"
    read -p "${GREEN}Enter choice (1-3): ${RESET}" ptype
    
    case $ptype in
        1) proxy_type="http" ;;
        2) proxy_type="socks4" ;;
        3) proxy_type="socks5" ;;
        *) echo "${RED}Invalid type! Using SOCKS5${RESET}"; proxy_type="socks5" ;;
    esac
    
    read -p "${GREEN}Enter proxy IP: ${RESET}" proxy_ip
    read -p "${GREEN}Enter proxy port: ${RESET}" proxy_port
    
    echo "${YELLOW}Configuring proxychains...${RESET}"
    sudo sed -i "s/^strict_chain/#strict_chain/" /etc/proxychains.conf
    sudo sed -i "s/#dynamic_chain/dynamic_chain/" /etc/proxychains.conf
    echo "$proxy_type $proxy_ip $proxy_port" | sudo tee -a /etc/proxychains.conf
    
    echo "${GREEN}Proxy configured! Test with: proxychains curl ifconfig.me${RESET}"
    read -p "${GREEN}Press enter to return to main menu...${RESET}"
    main_menu
}

run_security_tools() {
    clear
    echo "${BLUE}=== Security Tools ==="
    echo "${RED}WARNING: These tools should only be used on authorized networks!${RESET}"
    echo "1. Network Scanner"
    echo "2. Vulnerability Scanner"
    echo "3. Anonymization Suite"
    echo "4. Return to Main Menu"
    read -p "${GREEN}Enter choice (1-4): ${RESET}" choice
    
    case $choice in
        1)
            read -p "${GREEN}Enter target range (e.g., 192.168.1.0/24): ${RESET}" target
            echo "${YELLOW}Starting network scan...${RESET}"
            sudo nmap -sS -T4 $target
            ;;
        2)
            read -p "${GREEN}Enter target IP: ${RESET}" target
            echo "${YELLOW}Starting vulnerability scan...${RESET}"
            sudo openvas-start
            sudo gvm-start
            ;;
        3)
            echo "${YELLOW}Starting anonymization...${RESET}"
            sudo systemctl start tor
            sudo proxychains firefox &
            echo "${GREEN}Browser traffic now routed through Tor!${RESET}"
            ;;
        4) main_menu ;;
        *) echo "${RED}Invalid option!${RESET}"; sleep 1; run_security_tools ;;
    esac
    
    read -p "${GREEN}Press enter to return to main menu...${RESET}"
    main_menu
}

# Initialization
if [ "$EUID" -ne 0 ]; then
    echo "${RED}Please run as root!${RESET}"
    exit 1
fi

read -sp "${GREEN}Set database password: ${RESET}" DB_PASS
export DB_PASS
echo

main_menu#!/bin/bash

# Color definitions
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

# Main menu function
main_menu() {
    clear
    echo "${BLUE}=== Network Management Suite ==="
    echo "1. Setup Network Monitoring"
    echo "2. Configure IP Management"
    echo "3. Configure Proxychains"
    echo "4. Run Security Tools"
    echo "5. Exit"
    echo "===============================${RESET}"
    read -p "${GREEN}Enter your choice (1-5): ${RESET}" choice

    case $choice in
        1) setup_network_tools ;;
        2) select_ip_management_tool ;;
        3) configure_proxychains ;;
        4) run_security_tools ;;
        5) echo "${YELLOW}Exiting...${RESET}"; exit 0 ;;
        *) echo "${RED}Invalid option!${RESET}"; sleep 1; main_menu ;;
    esac
}

setup_network_tools() {
    clear
    echo "${BLUE}=== Network Monitoring Setup ==="
    echo "${YELLOW}[!] Listing USB devices...${RESET}"
    lsusb

    echo "${YELLOW}[!] Checking airmon-ng...${RESET}"
    sudo airmon-ng check

    echo "${YELLOW}[!] Killing conflicting processes...${RESET}"
    sudo airmon-ng check kill

    echo "${YELLOW}[!] Starting airmon-ng on interfaces...${RESET}"
    interfaces=($(iw dev | awk '$1=="Interface"{print $2}'))
    
    for intf in "${interfaces[@]}"; do
        echo "${BLUE}Starting monitor mode on $intf${RESET}"
        sudo airmon-ng start $intf
    done

    echo "${YELLOW}[!] Displaying wireless configuration...${RESET}"
    iwconfig

    read -p "${GREEN}Configure Bluetooth? (y/n): ${RESET}" bt_choice
    if [[ $bt_choice == "y" ]]; then
        echo "${YELLOW}[!] Configuring Bluetooth...${RESET}"
        sudo hciconfig -a
        sudo hciconfig hci0 up
        sudo hciconfig -a
    fi

    echo "${YELLOW}[!] Restarting NetworkManager...${RESET}"
    sudo systemctl restart NetworkManager

    read -p "${GREEN}Press enter to return to main menu...${RESET}"
    main_menu
}

select_ip_management_tool() {
    clear
    echo "${BLUE}=== IP Management Configuration ==="
    echo "1. phpIPAM"
    echo "2. NetBox"
    echo "3. GestióIP"
    echo "4. TeemIp"
    echo "5. Return to Main Menu"
    echo "===============================${RESET}"
    read -p "${GREEN}Enter your choice (1-5): ${RESET}" choice

    case $choice in
        1)
            echo "${YELLOW}Installing phpIPAM...${RESET}"
            sudo apt update && sudo apt install -y apache2 mariadb-server php php-mysql php-xml php-mbstring
            sudo mysql -e "CREATE DATABASE phpipam;"
            sudo mysql -e "CREATE USER 'phpipam'@'localhost' IDENTIFIED BY '${DB_PASS}';"
            sudo mysql -e "GRANT ALL PRIVILEGES ON phpipam.* TO 'phpipam'@'localhost';"
            sudo mysql -e "FLUSH PRIVILEGES;"
            
            cd /var/www/html
            sudo git clone https://github.com/phpipam/phpipam.git
            sudo chown -R www-data:www-data phpipam
            cp phpipam/config.dist.php phpipam/config.php
            
            echo "${GREEN}phpIPAM installed! Access at: http://$(hostname -I | awk '{print $1}')/phpipam${RESET}"
            ;;
        2)
            echo "${YELLOW}Installing NetBox...${RESET}"
            sudo apt update && sudo apt install -y python3 python3-pip python3-venv git
            sudo git clone -b master https://github.com/netbox-community/netbox.git /opt/netbox
            cd /opt/netbox
            
            python3 -m venv venv
            source venv/bin/activate
            pip install -r requirements.txt
            
            echo "${GREEN}NetBox installed! Configure with: python3 manage.py runserver 0.0.0.0:8000${RESET}"
            ;;
        3)
            echo "${YELLOW}Installing GestióIP...${RESET}"
            sudo apt update && sudo apt install -y apache2 mariadb-server php php-mysql php-xml php-mbstring
            sudo mysql -e "CREATE DATABASE gestioip;"
            sudo mysql -e "CREATE USER 'gestioip'@'localhost' IDENTIFIED BY '${DB_PASS}';"
            sudo mysql -e "GRANT ALL PRIVILEGES ON gestioip.* TO 'gestioip'@'localhost';"
            sudo mysql -e "FLUSH PRIVILEGES;"
            
            cd /var/www/html
            sudo git clone https://github.com/gestioip/gestioip.git
            sudo chown -R www-data:www-data gestioip
            cp gestioip/config.php.example gestioip/config.php
            
            echo "${GREEN}GestioIP installed! Access at: http://$(hostname -I | awk '{print $1}')/gestioip${RESET}"
            ;;
        4)
            echo "${YELLOW}Installing TeemIp...${RESET}"
            sudo apt update && sudo apt install -y apache2 mariadb-server php php-mysql php-xml php-mbstring
            sudo mysql -e "CREATE DATABASE teemip;"
            sudo mysql -e "CREATE USER 'teemip'@'localhost' IDENTIFIED BY '${DB_PASS}';"
            sudo mysql -e "GRANT ALL PRIVILEGES ON teemip.* TO 'teemip'@'localhost';"
            sudo mysql -e "FLUSH PRIVILEGES;"
            
            cd /var/www/html
            sudo git clone https://github.com/TeemIp/teemip.git
            sudo chown -R www-data:www-data teemip
            cp teemip/config.php.example teemip/config.php
            
            echo "${GREEN}TeemIp installed! Access at: http://$(hostname -I | awk '{print $1}')/teemip${RESET}"
            ;;
        5) main_menu ;;
    read -p "${GREEN}Enter proxy IP: ${RESET}" proxy_ip
    read -p "${GREEN}Enter proxy port: ${RESET}" proxy_port
    echo " [!] You can add more proxies to the chain via its cofnfig file, I willl update this section soon."
        *) echo "${RED}Invalid option!${RESET}"; sleep 1; select_ip_management_tool ;;
    esac
    
    read -p "${GREEN}Press enter to return to main menu...${RESET}"
    main_menu
}

configure_proxychains() {
    clear
    echo "${BLUE}=== Proxychains Configuration ==="
    echo "${YELLOW}[!] Current proxychains config:${RESET}"
    tail -n 5 /etc/proxychains.conf
    read -p "${GREEN}Enter proxy IP: ${RESET}" proxy_ip
    read -p "${GREEN}Enter proxy port: ${RESET}" proxy_port
    echo " [!] You can add more proxies to the chain via its cofnfig file, I willl update this section soon."
    
    read -p "${GREEN}Enter proxy IP: ${RESET}" proxy_ip
    read -p "${GREEN}Enter proxy port: ${RESET}" proxy_port
    echo " [!] You can add more proxies to the chain via its cofnfig file, I willl update this section soon."
    echo "\n${BLUE}Select proxy type:"
    echo "1. HTTP"
    echo "2. SOCKS4"
    echo "3. SOCKS5"
    read -p "${GREEN}Enter choice (1-3): ${RESET}" ptype
    
    case $ptype in
        1) proxy_type="http" ;;
        2) proxy_type="socks4" ;;
        3) proxy_type="socks5" ;;
        *) echo "${RED}Invalid type! Using SOCKS5${RESET}
    read -p "${GREEN}Enter proxy IP: ${RESET}" proxy_ip
    read -p "${GREEN}Enter proxy port: ${RESET}" proxy_port
    echo " [!] You can add more proxies to the chain via its cofnfig file, I willl update this section soon.""; proxy_type="socks5" ;;
    esac
    
    read -p "${GREEN}Enter proxy IP: ${RESET}" proxy_ip
    read -p "${GREEN}Enter proxy port: ${RESET}" proxy_port
    echo " [!] You can add more proxies to the chain via its cofnfig file, I willl update this section soon."
    
    echo "${YELLOW}Configuring proxychains...${RESET}"
    sudo sed -i "s/^strict_chain/#strict_chain/" /etc/proxychains.conf
    sudo sed -i "s/#dynamic_chain/dynamic_chain/" /etc/proxychains.conf
    echo "$proxy_type $proxy_ip $proxy_port" | sudo tee -a /etc/proxychains.conf
    
    echo "${GREEN}Proxy configured! Test with: proxychains curl ifconfig.me${RESET}"
    read -p "${GREEN}Press enter to return to main menu...${RESET}"
    main_menu
}

run_security_tools() {
    clear
    echo "${BLUE}=== Security Tools ==="
    echo "${RED}WARNING: These tools should only be used on authorized networks!${RESET}"
    echo "1. Network Scanner"
    echo "2. Vulnerability Scanner"
    echo "3. Anonymization Suite"
    read -p "${GREEN}Enter proxy IP: ${RESET}" proxy_ip
    read -p "${GREEN}Enter proxy port: ${RESET}" proxy_port
    echo " [!] You can add more proxies to the chain via its cofnfig file, I willl update this section soon."
    echo "4. Return to Main Menu"
    read -p "${GREEN}Enter choice (1-4): ${RESET}" choice
    
    case $choice in
        1)
            read -p "${GREEN}Enter target range (e.g., 192.168.1.0/24): ${RESET}" target
            echo "${YELLOW}Starting network scan...${RESET}"
            sudo nmap -sS -T4 $target
            ;;
        2)
            read -p "${GREEN}Enter target IP: ${RESET}" target
            echo "${YELLOW}Starting vulnerability scan...${RESET}"
            sudo openvas-start
            sudo gvm-start
            ;;
        3)
            echo "${YELLOW}Starting anonymization...${RESET}"
            sudo systemctl start tor
            sudo proxychains firefox &
            echo "${GREEN}Browser traffic now routed through Tor!${RESET}"
            ;;
        4) main_menu ;;
        *) echo "${RED}Invalid option!${RESET}"; sleep 1; run_security_tools ;;
    esac
    
    read -p "${GREEN}Press enter to return to main menu...${RESET}"
    main_menu
}

# Initialization
if [ "$EUID" -ne 0 ]; then
    read -p "${GREEN}Enter proxy IP: ${RESET}" proxy_ip
    read -p "${GREEN}Enter proxy port: ${RESET}" proxy_port
    echo " [!] You can add more proxies to the chain via its cofnfig file, I willl update this section soon."
    echo "${RED}Please run as root!${RESET}"
    exit 1
fi

read -sp "${GREEN}Set database password: ${RESET}" DB_PASS
export DB_PASS
echo

main_menu#!/bin/bash

# Color definitions
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

# Main menu function
main_menu() {
    clear
    echo "${BLUE}=== Network Management Suite ==="
    echo "1. Setup Network Monitoring"
    echo "2. Configure IP Management"
    echo "3. Configure Proxychains"
    echo "4. Run Security Tools"
    echo "5. Exit"
    echo "===============================${RESET}"
    read -p "${GREEN}Enter your choice (1-5): ${RESET}" choice

    case $choice in
        1) setup_network_tools ;;
        2) select_ip_management_tool ;;
        3) configure_proxychains ;;
    read -p "${GREEN}Enter proxy IP: ${RESET}" proxy_ip
    read -p "${GREEN}Enter proxy port: ${RESET}" proxy_port
    echo " [!] You can add more proxies to the chain via its cofnfig file, I willl update this section soon."
        4) run_security_tools ;;
        5) echo "${YELLOW}Exiting...${RESET}"; exit 0 ;;
        *) echo "${RED}Invalid option!${RESET}"; sleep 1; main_menu ;;
    esac
}

setup_network_tools() {
    clear
    echo "${BLUE}=== Network Monitoring Setup ==="
    echo "${YELLOW}[!] Listing USB devices...${RESET}"
    lsusb

    echo "${YELLOW}[!] Checking airmon-ng...${RESET}"
    sudo airmon-ng check

    echo "${YELLOW}[!] Killing conflicting processes...${RESET}"
    sudo airmon-ng check kill

    echo "${YELLOW}[!] Starting airmon-ng on interfaces...
    read -p "${GREEN}Enter proxy IP: ${RESET}" proxy_ip
    read -p "${GREEN}Enter proxy port: ${RESET}" proxy_port
    echo " [!] You can add more proxies to the chain via its cofnfig file, I willl update this section soon."${RESET}"
    interfaces=($(iw dev | awk '$1=="Interface"{print $2}'))
    
    for intf in "${interfaces[@]}"; do
        echo "${BLUE}Starting monitor mode on $intf${RESET}"
        sudo airmon-ng start $intf
    done

    echo "${YELLOW}[!] Displaying wireless configuration...${RESET}"
    iwconfig

    read -p "${GREEN}Configure Bluetooth? (y/n): ${RESET}" bt_choice
    if [[ $bt_choice == "y" ]]; then
        echo "${YELLOW}[!] Configuring Bluetooth...${RESET}"
        sudo hciconfig -a
        sudo hciconfig hci0 up
        sudo hciconfig -a
    fi

    read -p "${GREEN}Enter proxy IP: ${RESET}" proxy_ip
    read -p "${GREEN}Enter proxy port: ${RESET}" proxy_port
    echo " [!] You can add more proxies to the chain via its cofnfig file, I willl update this section soon."
    echo "${YELLOW}[!] Restarting NetworkManager...${RESET}"
    sudo systemctl restart NetworkManager

    read -p "${GREEN}Press enter to return to main menu...${RESET}"
    main_menu
}

select_ip_management_tool() {
    clear
    echo "${BLUE}=== IP Management Configuration ==="
    echo "1. phpIPAM"
    echo "2. NetBox"
    echo "3. GestióIP"
    echo "4. TeemIp"
    echo "5. Return to Main Menu"
    echo "===============================${RESET}"
    read -p "${GREEN}Enter your choice (1-5): ${RESET}" choice

    case $choice in
        1)
            echo "${YELLOW}Installing phpIPAM...${RESET}"
            sudo apt update && sudo apt install -y apache2 mariadb-server php php-mysql php-xml php-mbstring
            sudo mysql -e "CREATE DATABASE phpipam;"
            sudo mysql -e "CREATE USER 'phpipam'@'localhost' IDENTIFIED BY '${DB_PASS}';"
            sudo mysql -e "GRANT ALL PRIVILEGES ON phpipam.* TO 'phpipam'@'localhost';"
            sudo mysql -e "FLUSH PRIVILEGES;"
    read -p "${GREEN}Enter proxy IP: ${RESET}" proxy_ip
    read -p "${GREEN}Enter proxy port: ${RESET}" proxy_port
    echo " [!] You can add more proxies to the chain via its cofnfig file, I willl update this section soon."
            
            cd /var/www/html
            sudo git clone https://github.com/phpipam/phpipam.git
            sudo chown -R www-data:www-data phpipam
            cp phpipam/config.dist.php phpipam/config.php
            
            echo "${GREEN}phpIPAM installed! Access at: http://$(hostname -I | awk '{print $1}')/phpipam${RESET}"
            ;;
        2)
            echo "${YELLOW}Installing NetBox...${RESET}"
            sudo apt update && sudo apt install -y python3
    read -p "${GREEN}Enter proxy IP: ${RESET}" proxy_ip
    read -p "${GREEN}Enter proxy port: ${RESET}" proxy_port
    echo " [!] You can add more proxies to the chain via its cofnfig file, I willl update this section soon." python3-pip python3-venv git
            sudo git clone -b master https://github.com/netbox-community/netbox.git /opt/netbox
            cd /opt/netbox
            
            python3 -m venv venv
            source venv/bin/activate
            pip install -r requirements.txt
            
            echo "${GREEN}NetBox installed! Configure with: python3 manage.py runserver 0.0.0.0:8000${RESET}"
            ;;
        3)
            echo "${YELLOW}Installing GestióIP...${RESET}"
            sudo apt update && sudo apt install -y apache2 mariadb-server php php-mysql php-xml php-mbstring
            sudo mysql -e "CREATE DATABASE gestioip;"
            sudo mysql -e "CREATE USER 'gestioip'@'localhost' IDENTIFIED BY '${DB_PASS}';"
            sudo mysql -e "GRANT ALL PRIVILEGES ON gestioip.* TO 'gestioip'@'localhost';"
            sudo mysql -e "FLUSH PRIVILEGES;"
            
            cd /var/www/html
            sudo git clone https://github.com/gestioip/gestioip.git
            sudo chown -R www-data:www-data gestioip
            cp gestioip/config.php.example gestioip/config.php
            
            echo "${GREEN}GestioIP installed! Access at: http://$(hostname -I | awk '{print $1}')/gestioip${RESET}"
            ;;
        4)
            echo "${YELLOW}Installing TeemIp...${RESET}"
            sudo apt update && sudo apt install -y apache2 mariadb-server php php-mysql php-xml php-mbstring
            sudo mysql -e "CREATE DATABASE teemip;"
            sudo mysql -e "CREATE USER 'teemip'@'localhost' IDENTIFIED BY '${DB_PASS}';"
            sudo mysql -e "GRANT ALL PRIVILEGES ON teemip.* TO 'teemip'@'localhost';"
            sudo mysql -e "FLUSH PRIVILEGES;"
            
            cd /var/www/html
            sudo git clone https://github.com/TeemIp/teemip.git
            sudo chown -R www-data:www-data teemip
            cp teemip/config.php.example teemip/config.php
            
            echo "${GREEN}TeemIp installed! Access at: http://$(hostname -I | awk '{print $1}')/teemip${RESET}"
            ;;
        5) main_menu ;;
        *) echo "${RED}Invalid option!${RESET}"; sleep 1; select_ip_management_tool ;;
    esac
    
    read -p "${GREEN}Press enter to return to main menu...${RESET}"
    main_menu
}

configure_proxychains() {
    clear
    echo "${BLUE}=== Proxychains Configuration ==="
    echo "${YELLOW}[!] Current proxychains config:${RESET}"
    tail -n 5 /etc/proxychains.conf
    
    echo "\n${BLUE}Select proxy type:"
    echo "1. HTTP"
    echo "2. SOCKS4"
    echo "3. SOCKS5"
    read -p "${GREEN}Enter choice (1-3): ${RESET}" ptype
    
    case $ptype in
        1) proxy_type="http" ;;
        2) proxy_type="socks4" ;;
        3) proxy_type="socks5" ;;
    read -p "${GREEN}Enter proxy IP: ${RESET}" proxy_ip
    read -p "${GREEN}Enter proxy port: ${RESET}" proxy_port
    echo " [!] You can add more proxies to the chain via its cofnfig file, I willl update this section soon."
        *) echo "${RED}Invalid type! Using SOCKS5${RESET}"; proxy_type="socks5" ;;
    esac
    
    read -p "${GREEN}Enter proxy IP: ${RESET}" proxy_ip
    read -p "${GREEN}Enter proxy port: ${RESET}" proxy_port
    
    echo "${YELLOW}Configuring proxychains...${RESET}"
    sudo sed -i "s/^strict_chain/#strict_chain/" /etc/proxychains.conf
    sudo sed -i "s/#dynamic_chain/dynamic_chain/" /etc/proxychains.conf
    echo "$proxy_type $proxy_ip $proxy_port" | sudo tee -a /etc/proxychains.conf
    
    echo "${GREEN}Proxy configured! Test with: proxychains curl ifconfig.me${RESET}"
    read -p "${GREEN}Press enter to return to main menu...${RESET}"
    main_menu
}

run_security_tools() {
    clear
    echo "${BLUE}=== Security Tools ==="
    echo "${RED}WARNING: These tools should only be used on authorized networks!${RESET}"
    echo "1. Network Scanner"
    echo "2. Vulnerability Scanner"
    echo "3. Anonymization Suite"
    echo "4. Return to Main Menu"
    read -p "${GREEN}Enter choice (1-4): ${RESET}" choice
    
    case $choice in
        1)
            read -p "${GREEN}Enter target range (e.g., 192.168.1.0/24): ${RESET}" target
            echo "${YELLOW}Starting network scan...${RESET}"
            sudo nmap -sS -T4 $target
            ;;
        2)
            read -p "${GREEN}Enter target IP: ${RESET}" target
            echo "${YELLOW}Starting vulnerability scan...${RESET}"
            sudo openvas-start
            sudo gvm-start
            ;;
        3)
            echo "${YELLOW}Starting anonymization...${RESET}"
            sudo systemctl start tor
            sudo proxychains firefox &
            echo "${GREEN}Browser traffic now routed through Tor!${RESET}"
            ;;
        4) main_menu ;;
        *) echo "${RED}Invalid option!${RESET}"; sleep 1; run_security_tools ;;
    esac
    
    read -p "${GREEN}Press enter to return to main menu...${R
    read -p "${GREEN}Enter proxy IP: ${RESET}" proxy_ip
    read -p "${GREEN}Enter proxy port: ${RESET}" proxy_port
    echo " [!] You can add more proxies to the chain via its cofnfig file, I willl update this section soon."ESET}"
    main_menu
    read -p "${GREEN}Enter proxy IP: ${RESET}" proxy_ip
    read -p "${GREEN}Enter proxy port: ${RESET}" proxy_port
    echo " [!] You can add more proxies to the chain via its cofnfig file, I willl update this section soon."
}

    read -p "${GREEN}Enter proxy IP: ${RESET}" proxy_ip
    read -p "${GREEN}Enter proxy port: ${RESET}" proxy_port
    echo " [!] You can add more proxies to the chain via its
    read -p "${GREEN}Enter proxy IP: ${RESET}" proxy_ip
    read -p "${GREEN}Enter proxy port: ${RESET}" proxy_port
    echo " [!] You can add more proxies to the chain via its cofnfig file, I willl update this section soon." cofnfig file, I willl update this section soon."
# Initialization
if [ "$EUID" -ne 0 ]; then
    echo "${RED}Please run as root!${RESET}"
    exit 1
fi

read -sp "${GREEN}Set database password: ${RESET}" DB_PASS
export DB_PASS
echo

main_menu
