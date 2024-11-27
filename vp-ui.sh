#!/usr/bin/bash

# main directory
cd

# kill all apt
sudo killall apt apt-get

# update
sudo apt --fix-broken install
sudo apt clean
sudo dpkg --configure -a

# main update
sudo apt update

# install necessary packages
sudo apt install wget whiptail lsof iptables unzip gcc git curl tar jq -y

# pip install --upgrade pip
pip install --upgrade requests requests-toolbelt urllib3 certbot

# Disable IPv6
echo "127.0.0.1 $(hostname)" >> /etc/hosts
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1

# Make changes permanent by adding to /etc/sysctl.conf
grep -qxF 'net.ipv6.conf.all.disable_ipv6 = 1' /etc/sysctl.conf || echo 'net.ipv6.conf.all.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf
grep -qxF 'net.ipv6.conf.default.disable_ipv6 = 1' /etc/sysctl.conf || echo 'net.ipv6.conf.default.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf
grep -qxF 'net.ipv6.conf.lo.disable_ipv6 = 1' /etc/sysctl.conf || echo 'net.ipv6.conf.lo.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf

# ip problem
sudo sysctl -p

# clear screen
clear

while true; do
    while true; do
        # main directory
        cd

        # Main menu
        var7=$(whiptail --title "SAMIR VPN Creator" --menu "Welcome to Samir VPN Creator, choose an option:" 20 80 13 \
            "1" "Server Upgrade" \
            "2" "Internet Connection" \
            "3" "X-UI SERVICE" \
            "4" "Reverse Tunnel (Old method)" \
            "5" "Reverse Tunnel (New method)" \
            "6" "Cetificate + Change IP" \
            "7" "Virtual RAM" \
            "8" "Change Main IP(Not Tested)" \
            "9" "SSL Certificate" \
            "10" "Change Subdomain IP" \
            "11" "Auto Restart Server" \
            "12" "Auto Server Change(should run on kharej)" \
            "13" "Exit" 3>&1 1>&2 2>&3)


        case "$var7" in
            "1")
                # Choose server location
                var6=$(whiptail --title "Choose Server" --menu "Choose server location:" 15 60 2 \
                    "1" "Iran" \
                    "2" "Kharej" 3>&1 1>&2 2>&3)

                if [[ "$var6" == "1" ]]; then
                    sudo rm /etc/resolv.conf
                    sudo touch /etc/resolv.conf
                    echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
                    echo "nameserver 4.2.2.4" | sudo tee -a /etc/resolv.conf           
                elif [[ "$var6" == "2" ]]; then
                    sudo rm /etc/resolv.conf
                    sudo touch /etc/resolv.conf
                    echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf
                    echo "nameserver 1.0.0.1" | sudo tee -a /etc/resolv.conf
                else
                    whiptail --msgbox "Invalid response. Please enter 1 or 2." 8 45
                fi
                
                #update dns
                sudo systemd-resolve --flush-caches
                sudo systemctl restart systemd-resolved

                # Enable BBR congestion control for better throughput
                sudo tee /etc/sysctl.conf > /dev/null <<EOF
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_fin_timeout=30
net.ipv4.tcp_keepalive_time=1200
net.core.wmem_max=67108864
net.core.rmem_max=67108864
net.ipv4.tcp_wmem=4096 87380 67108864
net.ipv4.tcp_rmem=4096 87380 67108864
net.core.netdev_max_backlog=250000
net.core.somaxconn=32768
EOF

                # Apply sysctl settings
                sudo sysctl -p

                # Optimize system limits
                sudo tee /etc/security/limits.conf > /dev/null <<EOF
* soft     nproc          655350
* hard     nproc          655350
* soft     nofile         655350
* hard     nofile         655350
root soft     nproc          655350
root hard     nproc          655350
root soft     nofile         655350
root hard     nofile         655350
EOF

                #upgrade
                sudo apt upgrade -y

                # Step 2: Install unattended-upgrades if not already installed
                sudo apt install -y unattended-upgrades

                # Step 3: Enable unattended-upgrades
                sudo dpkg-reconfigure --priority=low unattended-upgrades -y

                # Step 4: Configure unattended-upgrades to apply kernel updates and reboot automatically
                # Unattended-Upgrades Configuration File
                CONFIG_FILE="/etc/apt/apt.conf.d/50unattended-upgrades"

                # Backup existing configuration
                sudo cp $CONFIG_FILE $CONFIG_FILE.bak

                # Modify configuration to ensure kernel updates and reboots are enabled
                sudo sed -i '/^\/\/ "${distro_id}:${distro_codename}-updates";/s/^\/\///' $CONFIG_FILE
                sudo sed -i '/^\/\/ Unattended-Upgrade::Automatic-Reboot "false";/s/^\/\///' $CONFIG_FILE
                sudo sed -i 's/Unattended-Upgrade::Automatic-Reboot "false"/Unattended-Upgrade::Automatic-Reboot "true"/' $CONFIG_FILE
                sudo sed -i 's/\/\/ Unattended-Upgrade::Automatic-Reboot-Time "02:00"/Unattended-Upgrade::Automatic-Reboot-Time "02:00"/' $CONFIG_FILE

                # Step 5: Enable automatic updates
                AUTO_UPGRADES_FILE="/etc/apt/apt.conf.d/20auto-upgrades"

                # Ensure this file contains the required lines for periodic updates
                echo 'APT::Periodic::Update-Package-Lists "1";' | sudo tee $AUTO_UPGRADES_FILE > /dev/null
                echo 'APT::Periodic::Unattended-Upgrade "1";' | sudo tee -a $AUTO_UPGRADES_FILE > /dev/null

                # Step 6: Restart unattended-upgrades service
                sudo systemctl restart unattended-upgrades
                echo "Kernel auto-upgrade setup completed."
                
                # clear screen
                clear
                ;;
            "2")
                # Get the server's own IP address
                my_ip=$(hostname -I | awk '{print $1}')
                [[ -z "$my_ip" ]] && my_ip="Unknown"

                # Get server location from the user
                server_location=$(whiptail --title "Server Location" --menu "Is this server located in Iran or a kharej location?" 15 60 2 \
                "Iran" "Iran server" \
                "kharej" "kharej server" 3>&1 1>&2 2>&3)

                # Prompt user to input the IP of another server
                other_server_ip=$(whiptail --inputbox "Enter the IP address of another server (Iran or kharej):" 10 60 3>&1 1>&2 2>&3)

                # Function to perform connectivity check with ping and return status + ping time
                check_connectivity() {
                    # Run ping and extract the round-trip time (rtt)
                    ping_output=$(ping -c 1 -W 1 "$1" 2>&1)

                    # Check if ping was successful
                    if echo "$ping_output" | grep -q "1 received"; then
                        # Extract and display the round-trip time from the ping output
                        ping_time=$(echo "$ping_output" | grep "time=" | awk -F'time=' '{print $2}' | awk '{print $1}')
                        echo "Connected (Ping: ${ping_time} ms)"
                    else
                        echo "Not Connected"
                    fi
                }

                # Perform connectivity checks
                tamin_status=$(check_connectivity "tamin.ir")
                google_status=$(check_connectivity "google.com")
                my_ip_status=$(check_connectivity "$my_ip")
                other_server_status=$(check_connectivity "$other_server_ip")

                # Display the results
                whiptail --title "Connectivity Check Results" --msgbox "Connectivity Check Results:\n\n\
                Tamin.ir: $tamin_status\n\
                Google.com: $google_status\n\
                My IP ($my_ip): $my_ip_status\n\
                Other Server IP ($other_server_ip): $other_server_status\n\n\
                Current Server Location: $server_location" 20 80 12
                ;;
            "3")                
                x1=$(whiptail --title "X-UI SERVICE" --menu "X-UI SERVICE, choose an option:" 20 80 3 \
                    "1" "X-UI Status" \
                    "2" "Install X-UI Sanaei Panel" \
                    "3" "Unistall X-UI Panel" 3>&1 1>&2 2>&3)

                case "$x1" in
                    "1")
                        # Check if /usr/bin/x-ui file exists
                        if [ -f "/usr/bin/x-ui" ]; then
                            # Display a message using whiptail if the file exists
                            whiptail --title "File Check" --msgbox "x-ui exists!" 8 45
                            x-ui
                            clear
                            break
                        else
                            # Display a message using whiptail if the file does not exist
                            whiptail --title "File Check" --msgbox "x-ui does not exist!" 8 45
                        fi                            
                        ;;
                    "2")
                        # Install x-ui View Sanaei
                        arch() {
                            case "$(uname -m)" in
                            x86_64 | x64 | amd64) echo 'amd64' ;;
                            i*86 | x86) echo '386' ;;
                            armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
                            armv7* | armv7 | arm) echo 'armv7' ;;
                            armv6* | armv6) echo 'armv6' ;;
                            armv5* | armv5) echo 'armv5' ;;
                            s390x) echo 's390x' ;;
                            *) echo -e "${green}Unsupported CPU architecture! ${plain}" && rm -f install.sh && exit 1 ;;
                            esac
                        }

                        # requirment
                        apt-get install -y -q wget curl tar tzdata

                        # change directory
                        cd /usr/local/

                        # download
                        url="https://github.com/MHSanaei/3x-ui/releases/download/v2.4.0/x-ui-linux-$(arch).tar.gz"

                        wget -N --no-check-certificate -O /usr/local/x-ui-linux-$(arch).tar.gz ${url}


                        if [[ -e /usr/local/x-ui/ ]]; then
                            systemctl stop x-ui
                            rm /usr/local/x-ui/ -rf
                        fi

                        # download
                        tar zxvf x-ui-linux-$(arch).tar.gz
                        rm x-ui-linux-$(arch).tar.gz -f
                        cd x-ui
                        chmod +x x-ui

                        # Check the system's architecture and rename the file accordingly
                        if [[ $(arch) == "armv5" || $(arch) == "armv6" || $(arch) == "armv7" ]]; then
                            mv bin/xray-linux-$(arch) bin/xray-linux-arm
                            chmod +x bin/xray-linux-arm
                        fi

                        # check system arch
                        chmod +x x-ui bin/xray-linux-$(arch)
                        cp -f x-ui.service /etc/systemd/system/
                        wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/MHSanaei/3x-ui/main/x-ui.sh
                        chmod +x /usr/local/x-ui/x-ui.sh
                        chmod +x /usr/bin/x-ui

                        # setting
                        /usr/local/x-ui/x-ui setting -username "samir" -password "samir" -port "2096" -webBasePath ""
                        /usr/local/x-ui/x-ui migrate

                        # reload
                        systemctl daemon-reload
                        systemctl enable x-ui
                        systemctl start x-ui
                        
                        # change directory
                        cd           
                        ;;
                    "3")   
                        # Unistall X-UI confiramtion
                        if whiptail --title "Delete Confirmation" --yesno "Are you sure you want to delete x-ui?" 10 60; then
                            var31="5"
                            var32="y"
                            echo -e "$var31\n$var32" | x-ui                    
                        else
                            break
                        fi                
                        ;;
                esac
                ;;
            "4")
                x2=$(whiptail --title "Reverse Tunnel" --menu "Reverse Tunnel, choose an option:" 20 80 3 \
                    "1" "Tunnel Status" \
                    "2" "Install Reverse Tunnel" \
                    "3" "Unistall Reverse Tunnel" 3>&1 1>&2 2>&3)

                case "$x2" in
                    "1")
                        # Check the status of the tunnel service
                        if sudo systemctl is-active --quiet tunnel.service; then
                            whiptail --msgbox "Tunnel is Active" 8 45
                        else
                            whiptail --msgbox "Tunnel is NOT Active" 8 45
                        fi
                        ;;
                    "2")               
                        # Check installed service

                        if [ -f "/etc/systemd/system/tunnel.service" ]; then
                            whiptail --msgbox "The service is already installed." 8 45
                            break
                        fi
                        
                        # install rtt Custom version
                        
                        URL="https://github.com/radkesvat/ReverseTlsTunnel/releases/download/V5.4/v5.4_linux_amd64.zip"

                        wget $URL -O v5.4_linux_amd64.zip
                        unzip -o v5.4_linux_amd64.zip
                        chmod +x RTT
                        rm v5.4_linux_amd64.zip
                        
                        # Change directory to /etc/systemd/system
                        cd /etc/systemd/system

                        # Function to configure arguments based on user's choice
                        
                        server_choice=$(whiptail --title "Server Selection" --menu "Which server do you want to use?" 15 60 2 \
                            "1" "Iran (internal-server)" \
                            "2" "Kharej (external-server)" 3>&1 1>&2 2>&3)

                        if [ $? -ne 0 ]; then
                            whiptail --msgbox "Operation canceled." 8 45
                            break
                        fi

                        sni=$(whiptail --inputbox "Please Enter SNI (default: tamin.ir):" 10 60 "tamin.ir" 3>&1 1>&2 2>&3)

                        if [ "$server_choice" == "2" ]; then
                            server_ip=$(whiptail --inputbox "Please Enter IRAN IP (internal-server):" 10 60 3>&1 1>&2 2>&3)
                            arguments="--kharej --iran-ip:$server_ip --iran-port:443 --toip:127.0.0.1 --toport:multiport --password:qwer --sni:$sni --terminate:24"
                        elif [ "$server_choice" == "1" ]; then
                            arguments="--iran --lport:23-65535 --sni:$sni --password:qwer --terminate:24"
                        else
                            whiptail --msgbox "Invalid choice. Please enter '1' or '2'." 8 45
                            break
                        fi
                    

                        # Create a new service file named tunnel.service
                        cat <<EOL > tunnel.service
[Unit]
Description=my tunnel service

[Service]
Type=idle
User=root
WorkingDirectory=/root
ExecStart=/root/RTT $arguments
Restart=always

[Install]
WantedBy=multi-user.target
EOL

                        # Reload systemctl daemon and start the service
                        sudo systemctl daemon-reload
                        sudo systemctl start tunnel.service
                        sudo systemctl enable tunnel.service
                        
                        # main directory
                        cd
                        ;;
                    "3")
                        # unistall tunnel
                        
                        # Check if the service is installed
                        if [ ! -f "/etc/systemd/system/tunnel.service" ]; then
                            echo "The service is not installed."
                            break
                        fi
                        
                        # confiramtion
                        if whiptail --title "Delete Confirmation" --yesno "Are you sure you want to delete tunnel?" 10 60; then
                            # Stop and disable the service
                            sudo systemctl stop tunnel.service
                            sudo systemctl disable tunnel.service

                            # Remove service file
                            sudo rm /etc/systemd/system/tunnel.service
                            sudo systemctl reset-failed
                            sudo rm RTT
                            sudo rm install.sh 2>/dev/null

                            echo "Uninstallation completed successfully."
                            
                        else
                            break
                        fi
                        ;;
                esac               
                ;;
            "5")
                if [ -f "RTT.py" ]; then
                    rm RTT.py
                fi
                wget https://raw.githubusercontent.com/smhamirii/VPS-X-UI/refs/heads/main/RTT.py
                python3 RTT.py
                ;;
            "6")
                error_exit() {
                    whiptail --msgbox "Error: $1" 10 60
                    exit 1
                }

                # Function to update DNS record
                update_dns_record() {
                    local full_domain="$1"
                    local ip="$2"
                    local zone_id="$3"
                    local record_id="$4"
                    local cf_token="$5"

                    local update_response=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id" \
                        -H "Authorization: Bearer $cf_token" \
                        -H "Content-Type: application/json" \
                        --data '{"type":"A","name":"'"$full_domain"'","content":"'"$ip"'","ttl":120,"proxied":false}')

                    if ! echo "$update_response" | jq -r '.success' | grep -q "true"; then
                        error_exit "Failed to update DNS record"
                    fi
                }

                # Get the current VPS IP
                VPS_IP=$(curl -s https://api.ipify.org)
                [[ -z "$VPS_IP" ]] && error_exit "Failed to retrieve VPS IP address"

                # Prompt for required information
                CF_API_TOKEN=$(whiptail --inputbox "Enter your Cloudflare API token:" 10 60 3>&1 1>&2 2>&3)
                FULL_DOMAIN=$(whiptail --inputbox "Enter your full domain (e.g., subdomain.example.com):" 10 60 3>&1 1>&2 2>&3)

                # Validate inputs
                [[ -z "$CF_API_TOKEN" ]] && error_exit "Cloudflare API token is required"
                [[ -z "$FULL_DOMAIN" ]] && error_exit "Domain is required"

                # Extract main domain from full domain
                DOMAIN=$(echo "$FULL_DOMAIN" | awk -F '.' '{print $(NF-1)"."$NF}')
                [[ -z "$DOMAIN" ]] && error_exit "Failed to extract main domain"

                # Get zone ID
                ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
                    -H "Authorization: Bearer $CF_API_TOKEN" \
                    -H "Content-Type: application/json" | jq -r '.result[0].id')

                [[ -z "$ZONE_ID" || "$ZONE_ID" == "null" ]] && error_exit "Failed to retrieve zone ID"

                # Get record ID and current (original) IP
                RECORD_INFO=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$FULL_DOMAIN" \
                    -H "Authorization: Bearer $CF_API_TOKEN" \
                    -H "Content-Type: application/json")

                RECORD_ID=$(echo "$RECORD_INFO" | jq -r '.result[0].id')
                ORIGINAL_IP=$(echo "$RECORD_INFO" | jq -r '.result[0].content')

                [[ -z "$RECORD_ID" || "$RECORD_ID" == "null" ]] && error_exit "Failed to retrieve DNS record"
                [[ -z "$ORIGINAL_IP" ]] && error_exit "Failed to retrieve original IP"

                # Show confirmation before proceeding
                whiptail --yesno "Ready to proceed with certificate renewal:\n\nDomain: $FULL_DOMAIN\nCurrent IP: $ORIGINAL_IP\nVPS IP: $VPS_IP\n\nContinue?" 15 60 || exit 0

                # Store original IP in a temporary file for safety
                echo "$ORIGINAL_IP" > /tmp/original_ip_backup

                # Update DNS to VPS IP
                echo "Updating DNS to VPS IP: $VPS_IP"
                update_dns_record "$FULL_DOMAIN" "$VPS_IP" "$ZONE_ID" "$RECORD_ID" "$CF_API_TOKEN"

                # Wait for DNS propagation
                whiptail --msgbox "Waiting 60 seconds for DNS propagation..." 10 60
                sleep 60

                # Install dependencies if not already installed
                sudo apt install -y certbot nginx

                # Stop nginx temporarily
                sudo systemctl stop nginx

                # Request new certificate
                echo "Requesting new SSL certificate..."
                sudo certbot certonly --standalone --preferred-challenges http \
                    --register-unsafely-without-email \
                    --agree-tos \
                    -d "$FULL_DOMAIN"

                CERT_STATUS=$?

                # Start nginx
                sudo systemctl start nginx

                # Let user choose which IP to use after certificate renewal
                IP_CHOICE=$(whiptail --title "Choose Final IP" --menu "Choose which IP to use after certificate renewal:" 15 60 3 \
                    "1" "Restore previous IP ($ORIGINAL_IP)" \
                    "2" "Set custom IP" \
                    "3" "Keep current VPS IP ($VPS_IP)" 3>&1 1>&2 2>&3)

                case $IP_CHOICE in
                    1)
                        FINAL_IP=$ORIGINAL_IP
                        ;;
                    2)
                        FINAL_IP=$(whiptail --inputbox "Enter the new IP address:" 10 60 3>&1 1>&2 2>&3)
                        if [[ -z "$FINAL_IP" ]]; then
                            whiptail --msgbox "No IP provided. Using original IP ($ORIGINAL_IP)" 10 60
                            FINAL_IP=$ORIGINAL_IP
                        fi
                        ;;
                    3)
                        FINAL_IP=$VPS_IP
                        ;;
                    *)
                        whiptail --msgbox "No selection made. Using original IP ($ORIGINAL_IP)" 10 60
                        FINAL_IP=$ORIGINAL_IP
                        ;;
                esac

                # Update DNS to final IP
                echo "Updating DNS to final IP: $FINAL_IP"
                update_dns_record "$FULL_DOMAIN" "$FINAL_IP" "$ZONE_ID" "$RECORD_ID" "$CF_API_TOKEN"

                # Clean up
                rm -f /tmp/original_ip_backup

                # Final status
                if [ $CERT_STATUS -eq 0 ]; then
                    whiptail --msgbox "Certificate renewal complete!\n\nDomain: $FULL_DOMAIN\nFinal IP: $FINAL_IP" 12 60
                else
                    whiptail --msgbox "Certificate renewal failed!\n\nDomain: $FULL_DOMAIN\nFinal IP: $FINAL_IP" 12 60
                fi

                ;;
            "7")
                configure_swap() {
                    # Check if running as root
                    if [ "$EUID" -ne 0 ]; then
                        whiptail --title "Error" --msgbox "Please run as root (sudo)" 8 40
                        return 1
                    fi

                    # remove existing swap
                    if ! whiptail --title "Confirm" --yesno "This will remove existing swap and create a new swap file. Continue?" 8 60; then
                        return 1
                    fi

                    # Get system memory
                    local total_ram=$(free -m | grep Mem | awk '{print $2}')

                    # Calculate recommended swap size (equal to RAM for systems up to 4GB, half of RAM for larger systems)
                    local recommended_swap=$total_ram
                    if [ $total_ram -gt 4096 ]; then
                        recommended_swap=$((total_ram / 2))
                    fi

                    # Ask for swap size
                    local swap_size=$(whiptail --title "Swap Size" --inputbox "\
                Enter desired swap size in MB
                Recommended size: ${recommended_swap}MB
                Your RAM: ${total_ram}MB" 12 50 "$recommended_swap" 3>&1 1>&2 2>&3)

                    # Check if user cancelled
                    if [ $? -ne 0 ]; then
                        whiptail --title "Cancelled" --msgbox "Operation cancelled by user." 8 40
                        return 1
                    fi

                    # Validate input
                    if ! [[ "$swap_size" =~ ^[0-9]+$ ]]; then
                        whiptail --title "Error" --msgbox "Please enter a valid number." 8 40
                        return 1
                    fi

                    # Confirm before proceeding with large swap sizes
                    if [ "$swap_size" -gt $((total_ram * 2)) ]; then
                        if ! whiptail --title "Warning" --yesno "The selected swap size is more than twice your RAM size. Are you sure you want to continue?" 8 60; then
                            return 1
                        fi
                    fi

                    # Disable all swap
                    echo "Disabling existing swap..."
                    swapoff -a || {
                        whiptail --title "Error" --msgbox "Failed to disable existing swap." 8 40
                        return 1
                    }

                    # Remove swap entries from /etc/fstab
                    echo "Removing swap entries from /etc/fstab..."
                    sed -i '/swap/d' /etc/fstab

                    # Remove existing swap file if it exists
                    if [ -f /swapfile ]; then
                        echo "Removing existing swap file..."
                        rm -f /swapfile
                    fi

                    whiptail --title "Swap Removal" --msgbox "Existing swap has been removed." 8 40

                    # Create swap file
                    echo "Creating new swap file..."
                    if ! dd if=/dev/zero of=/swapfile bs=1M count="$swap_size" status=progress; then
                        whiptail --title "Error" --msgbox "Failed to create swap file." 8 40
                        return 1
                    fi

                    # Set correct permissions
                    echo "Setting permissions..."
                    chmod 600 /swapfile || {
                        whiptail --title "Error" --msgbox "Failed to set swap file permissions." 8 40
                        return 1
                    }

                    # Format as swap
                    echo "Formatting swap file..."
                    if ! mkswap /swapfile; then
                        whiptail --title "Error" --msgbox "Failed to format swap file." 8 40
                        return 1
                    fi

                    # Enable swap
                    echo "Enabling swap..."
                    if ! swapon /swapfile; then
                        whiptail --title "Error" --msgbox "Failed to enable swap." 8 40
                        return 1
                    fi

                    # Add to fstab
                    echo "Updating /etc/fstab..."
                    echo '/swapfile none swap sw 0 0' >> /etc/fstab

                    # Configure swappiness
                    echo "Configuring swappiness..."
                    echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf
                    sysctl -p /etc/sysctl.d/99-swappiness.conf

                    whiptail --title "Success" --msgbox "New swap file of ${swap_size}MB has been created and enabled." 8 50
                    return 0
                }

                # Call the function
                configure_swap
                ;;
            "8")
                get_ipv4_addresses() {
                    # Get all IPv4 addresses and their interface names
                    ip -4 addr show | grep inet | grep -v '127.0.0.1' | awk '{print $2, "("$NF")"}'
                }

                # Function to set the default route
                set_default_route() {
                    local chosen_ip="$1"
                    local interface=$(ip addr show | grep "$chosen_ip" | awk '{print $NF}')
                    
                    # Remove existing default routes
                    ip route del default 2>/dev/null

                    # Get the gateway for the chosen interface
                    local gateway=$(ip route | grep "$interface" | grep -v 'default' | awk '{print $1}' | cut -d'/' -f1 | head -n1)
                    
                    # Add new default route
                    if ip route add default via "$gateway" dev "$interface"; then
                        return 0
                    else
                        return 1
                    fi
                }

                # Get all IPv4 addresses
                IPS=($(get_ipv4_addresses))

                if [ ${#IPS[@]} -eq 0 ]; then
                    whiptail --title "Error" --msgbox "No IPv4 addresses found!" 8 40
                    exit 1
                fi

                # Create options array for whiptail
                OPTIONS=()
                for ((i=0; i<${#IPS[@]}; i+=2)); do
                    OPTIONS+=("${IPS[i]}" "${IPS[i+1]}")
                done

                # Show menu with IP addresses
                CHOSEN_IP=$(whiptail --title "Select Main IP Address" \
                    --menu "Choose the IP address to use as main internet connection:" \
                    20 60 10 \
                    "${OPTIONS[@]}" \
                    3>&1 1>&2 2>&3)

                # Check if user canceled
                if [ $? -ne 0 ]; then
                    echo "Operation canceled by user"
                    exit 1
                fi

                # Extract IP address without CIDR notation
                CHOSEN_IP=$(echo $CHOSEN_IP | cut -d'/' -f1)

                # Show confirmation dialog
                if whiptail --title "Confirm Selection" --yesno "Are you sure you want to set $CHOSEN_IP as your main IP?" 8 60; then
                    # Backup current network configuration
                    cp /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.backup.$(date +%Y%m%d-%H%M%S)
                    
                    # Set the new default route
                    if set_default_route "$CHOSEN_IP"; then
                        whiptail --title "Success" --msgbox "Successfully set $CHOSEN_IP as main IP.\nA backup of your network configuration has been created." 10 60
                        
                        # Show current routing table
                        echo "Current routing table:"
                        ip route show
                    else
                        whiptail --title "Error" --msgbox "Failed to set $CHOSEN_IP as main IP.\nPlease check system logs for more information." 10 60
                    fi
                else
                    echo "Operation canceled by user"
                    exit 1
                fi
                ;;
            "9")
                x3=$(whiptail --title "SSL Certificate" --menu "SSL Certificate, choose an option:" 20 80 2 \
                    "1" "Certificate for Subdomain SSL" \
                    "2" "Revoke Certificate SSL" 3>&1 1>&2 2>&3)

                case "$x3" in
                    "1")
                        # Install cron if not already installed and enable it
                        sudo apt install cron -y
                        sudo systemctl enable cron

                        # Prompt the user to enter the subdomain
                        SUBDOMAIN=$(whiptail --inputbox "Please enter the subdomain for which you want to create an SSL certificate (e.g., subdomain.example.com):" 10 60 3>&1 1>&2 2>&3)

                        # Validate that the subdomain is not empty
                        if [[ -z "$SUBDOMAIN" ]]; then
                            whiptail --msgbox "Error: Subdomain cannot be empty. Please run the script again and provide a valid subdomain." 10 60
                            break
                        fi

                        # Define directory to store certificate files
                        CERT_DIR="/etc/ssl/$SUBDOMAIN"
                        whiptail --msgbox "Certificate directory: $CERT_DIR" 10 60

                        # Install dependencies if not already installed
                        sudo apt install -y certbot nginx

                        # Stop any services using port 80 temporarily to allow Certbot to bind
                        sudo systemctl stop nginx

                        # Use the HTTP-01 challenge with Certbot's standalone server to issue certificate
                        sudo certbot certonly --standalone --preferred-challenges http \
                        --register-unsafely-without-email \
                        --agree-tos \
                        -d $SUBDOMAIN

                        # Check if the certificate was issued successfully
                        if [ $? -eq 0 ]; then
                            whiptail --msgbox "Certificate issued successfully for $SUBDOMAIN!" 10 60
                        else
                            whiptail --msgbox "Error: Failed to issue certificate for $SUBDOMAIN." 10 60
                            sudo systemctl start nginx   # Ensure the web server is restarted
                            break
                        fi

                        # Create SSL directory if it does not exist
                        sudo mkdir -p $CERT_DIR

                        # Copy the certificates to the desired directory
                        sudo cp /etc/letsencrypt/live/$SUBDOMAIN/fullchain.pem $CERT_DIR/fullchain.pem
                        sudo cp /etc/letsencrypt/live/$SUBDOMAIN/privkey.pem $CERT_DIR/privkey.pem

                        # Restart the web server to apply the new certificates
                        sudo systemctl start nginx

                        # Create the renewal script
                        RENEW_SCRIPT_PATH="/etc/letsencrypt/scripts/renew.sh"
                        sudo mkdir -p /etc/letsencrypt/scripts

                        # Append the renewal commands for the new subdomain
                        sudo bash -c "cat >> $RENEW_SCRIPT_PATH << 'EOF'
#!/bin/bash
# Renew certificate for $SUBDOMAIN using HTTP-01 challenge
certbot renew --standalone --preferred-challenges http

# Copy the renewed certificate and key to the $CERT_DIR
sudo cp /etc/letsencrypt/live/$SUBDOMAIN/fullchain.pem $CERT_DIR/fullchain.pem
sudo cp /etc/letsencrypt/live/$SUBDOMAIN/privkey.pem $CERT_DIR/privkey.pem

# Reload web server to apply new certificates
sudo systemctl reload nginx   # Replace nginx with your web server if needed
EOF"

                        # Ensure the renewal script has a proper shebang and permissions
                        if ! grep -q "#!/bin/bash" "$RENEW_SCRIPT_PATH"; then
                            sudo sed -i '1i#!/bin/bash' "$RENEW_SCRIPT_PATH"
                        fi

                        # Make the renewal script executable
                        sudo chmod +x $RENEW_SCRIPT_PATH

                        # Create a cron job for automatic renewal if not already set
                        if ! crontab -l | grep -q "$RENEW_SCRIPT_PATH"; then
                            (crontab -l 2>/dev/null; echo "0 0 * * * $RENEW_SCRIPT_PATH > /dev/null 2>&1") | crontab -
                        fi
                        ;;        
                    "2")
                        # Prompt the user to enter the subdomain to revoke
                        SUBDOMAIN=$(whiptail --inputbox "Please enter the subdomain you want to revoke (e.g., subdomain.example.com):" 10 60 3>&1 1>&2 2>&3)

                        # Validate that the subdomain is not empty
                        if [[ -z "$SUBDOMAIN" ]]; then
                            whiptail --msgbox "Error: Subdomain cannot be empty. Please provide a valid subdomain." 10 60
                            break
                        fi

                        # Define the certificate paths
                        CERT_DIR="/etc/ssl/$SUBDOMAIN"
                        CERT_PATH="/etc/letsencrypt/live/$SUBDOMAIN/fullchain.pem"

                        # Check if the certificate exists for the subdomain
                        if [[ ! -f "$CERT_PATH" ]]; then
                            whiptail --msgbox "Error: Certificate for $SUBDOMAIN does not exist." 10 60
                            break
                        fi

                        # Revoke the certificate using certbot
                        whiptail --msgbox "Revoking the certificate for $SUBDOMAIN..." 10 60
                        sudo certbot revoke --cert-path "$CERT_PATH" --reason "unspecified"

                        # Optionally delete the certificate files
                        DELETE_CERT_FILES=$(whiptail --yesno "Do you want to delete the certificate files for $SUBDOMAIN?" 10 60)
                        if [[ $? -eq 0 ]]; then
                            sudo rm -rf "/etc/letsencrypt/live/$SUBDOMAIN"
                            sudo rm -rf "/etc/letsencrypt/archive/$SUBDOMAIN"
                            sudo rm -rf "/etc/letsencrypt/renewal/$SUBDOMAIN.conf"
                            sudo rm -rf "$CERT_DIR"
                            whiptail --msgbox "Certificate files for $SUBDOMAIN deleted." 10 60
                        else
                            whiptail --msgbox "Certificate files retained." 10 60
                        fi

                        # Remove the specific cron job for this subdomain
                        (crontab -l 2>/dev/null | grep -v "$SUBDOMAIN") | crontab -

                        # Remove the renewal section for the specific subdomain from the renewal script
                        RENEW_SCRIPT_PATH="/etc/letsencrypt/scripts/renew.sh"
                        if [[ -f "$RENEW_SCRIPT_PATH" ]]; then                    
                            # Remove the block of lines related to the subdomain
                            sudo sed -i "/# Renew certificate for $SUBDOMAIN/,/sudo systemctl reload nginx/d" "$RENEW_SCRIPT_PATH"
                        fi

                        whiptail --msgbox "Certificate revocation and cleanup complete for $SUBDOMAIN." 10 60
                        ;;
                esac
                ;;
            "10")
                # Function to manage Cloudflare DNS                                    
                if [[ -n "$IP" ]]; then
                    unset IP
                fi

                # Get the public IP of the machine (server IP)
                IP=$(curl -s https://api.ipify.org)
                if [[ -z "$IP" ]]; then
                    whiptail --msgbox "Failed to retrieve your public IP address." 10 60
                    break
                fi

                # Choose IP location
                var61=$(whiptail --title "Choose IP" --menu "Choose IP USE VPS IP OR Custom IP:" 15 60 2 \
                    "1" "MY IP : $IP" \
                    "2" "Custom IP" 3>&1 1>&2 2>&3)
        
                if [[ "$var61" == "2" ]]; then
                    IP=$(whiptail --inputbox "Enter Custom IP" 10 60 3>&1 1>&2 2>&3)
                fi
                
                # Prompt for Cloudflare API token, domain, and subdomain
                CF_API_TOKEN=$(whiptail --inputbox "Enter your Cloudflare API token:" 10 60 3>&1 1>&2 2>&3)
                DOMAIN=$(whiptail --inputbox "Enter your domain (example.com):" 10 60 3>&1 1>&2 2>&3)
                SUBDOMAIN=$(whiptail --inputbox "Enter your custom subdomain (e.g., api, blog):" 10 60 3>&1 1>&2 2>&3)

                # Validate inputs
                if [[ -z "$CF_API_TOKEN" || -z "$DOMAIN" || -z "$SUBDOMAIN" ]]; then
                    whiptail --msgbox "Cloudflare API token, domain, and subdomain must be provided." 10 60
                    break
                fi

                # Fetch the zone ID for the domain
                ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
                    -H "Authorization: Bearer $CF_API_TOKEN" \
                    -H "Content-Type: application/json" | jq -r '.result[0].id')

                # Exit if no zone ID is found
                if [[ -z "$ZONE_ID" || "$ZONE_ID" == "null" ]]; then
                    whiptail --msgbox "Failed to retrieve the zone ID for $DOMAIN. Please check the domain and API token." 10 60
                    break
                fi

                # Check if the DNS record for the custom subdomain exists
                RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$SUBDOMAIN.$DOMAIN" \
                    -H "Authorization: Bearer $CF_API_TOKEN" \
                    -H "Content-Type: application/json" | jq -r '.result[0].id')

                if [[ -z "$RECORD_ID" || "$RECORD_ID" == "null" ]]; then
                    # If no record exists, create a new one
                    whiptail --msgbox "No DNS record found for $SUBDOMAIN.$DOMAIN. Creating a new DNS record..." 10 60
                    CREATE_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
                        -H "Authorization: Bearer $CF_API_TOKEN" \
                        -H "Content-Type: application/json" \
                        --data '{"type":"A","name":"'"$SUBDOMAIN.$DOMAIN"'","content":"'"$IP"'","ttl":120,"proxied":false}')

                    # Check if DNS record creation was successful
                    if echo "$CREATE_RESPONSE" | jq -r '.success' | grep -q "true"; then
                        whiptail --msgbox "Successfully created a new DNS record for $SUBDOMAIN.$DOMAIN with IP $IP." 10 60
                    else
                        whiptail --msgbox "Failed to create the DNS record. Response: $CREATE_RESPONSE" 10 60
                        break
                    fi
                else
                    # If the DNS record exists, update the existing one
                    whiptail --msgbox "DNS record for $SUBDOMAIN.$DOMAIN exists. Updating the IP address to $IP..." 10 60
                    UPDATE_RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
                        -H "Authorization: Bearer $CF_API_TOKEN" \
                        -H "Content-Type: application/json" \
                        --data '{"type":"A","name":"'"$SUBDOMAIN.$DOMAIN"'","content":"'"$IP"'","ttl":120,"proxied":false}')

                    # Check if the update was successful
                    if echo "$UPDATE_RESPONSE" | jq -r '.success' | grep -q "true"; then
                        whiptail --msgbox "Successfully updated the IP address for $SUBDOMAIN.$DOMAIN to $IP." 10 60
                    else
                        whiptail --msgbox "Failed to update the DNS record. Response: $UPDATE_RESPONSE" 10 60
                        break
                    fi
                fi                
                ;;  
            "11")
                # Use whiptail to create a menu with two options
                OPTION1=$(whiptail --title "Manage Reboot Cron Job" --menu "Choose an option:" 15 50 2 \
                "1" "Add reboot cron job (1 AM UTC daily)" \
                "2" "Remove reboot cron job" 3>&1 1>&2 2>&3)

                CRON_JOB1="0 1 * * * /sbin/shutdown -r now"

                # Check which option was selected
                if [[ "$OPTION1" == "1" ]]; then
                        # Add cron job to restart at 4 AM if it doesn't already exist
                        (crontab -l | grep -F "$CRON_JOB1") || (crontab -l ; echo "$CRON_JOB1") | crontab -
                        whiptail --msgbox "Reboot cron job added successfully!" 8 40
                elif [[ "$OPTION1" == "2" ]]; then
                        # Remove the reboot cron job if it exists
                        (crontab -l | grep -v -F "$CRON_JOB1" | crontab -) && whiptail --msgbox "Reboot cron job removed!" 8 40        
                else
                        whiptail --msgbox "No valid option selected. Exiting." 8 40
                        break
                fi               
                ;;
            "12")
                v2ray_monitor_module() {
                    # Global Configuration
                    local V2M_CONFIG_FILE="/etc/v2ray_monitor/config.conf"
                    local V2M_SCRIPT_ENABLED_FILE="/etc/v2ray_monitor/script_enabled"
                    local V2M_LOG_FILE="/var/log/v2ray_monitor.log"
                    local V2M_LOG_ARCHIVE_DIR="/var/log/v2ray_monitor_archive"
                    local V2M_LOCK_FILE="/var/run/v2ray_monitor.lock"
                    local V2M_SCRIPT_PATH="$(readlink -f "${0}")"

                    # Check for required dependencies
                    v2m_check_dependencies() {
                        local missing_deps=()
                        for cmd in jq curl whiptail gzip; do
                            if ! command -v "${cmd}" &> /dev/null; then
                                missing_deps+=("${cmd}")
                            fi
                        done
                        
                        if [ "${#missing_deps[@]}" -ne 0 ]; then
                            echo "Missing required dependencies: ${missing_deps[*]}"
                            return 1
                        fi
                        return 0
                    }

                    # Create required directories
                    v2m_setup_directories() {
                        local dirs=("$(dirname "${V2M_CONFIG_FILE}")" "$(dirname "${V2M_LOG_FILE}")" "${V2M_LOG_ARCHIVE_DIR}")
                        for dir in "${dirs[@]}"; do
                            sudo mkdir -p "${dir}"
                            sudo chmod 755 "${dir}"
                        done
                    }

                    # Logging Function
                    v2m_log_message() {
                        local message="${1}"
                        echo "$(date '+%Y-%m-%d %H:%M:%S') - ${message}" >> "${V2M_LOG_FILE}"
                    }

                    # Configuration Loading Function
                    v2m_load_config() {
                        if [[ -f "${V2M_CONFIG_FILE}" ]]; then
                            # shellcheck source=/dev/null
                            source "${V2M_CONFIG_FILE}"
                            return 0
                        else
                            v2m_log_message "No existing configuration found"
                            return 1
                        fi
                    }

                    # Configuration Saving Function
                    v2m_save_config() {
                        sudo mkdir -p "$(dirname "${V2M_CONFIG_FILE}")"
                        sudo tee "${V2M_CONFIG_FILE}" > /dev/null << EOF
V2M_CLOUDFLARE_API_TOKEN="${V2M_CLOUDFLARE_API_TOKEN}"
V2M_FULL_DOMAIN="${V2M_FULL_DOMAIN}"
V2M_IRAN_IP="${V2M_IRAN_IP}"
V2M_KHAREJ_IP="${V2M_KHAREJ_IP}"
EOF

                        sudo chmod 600 "${V2M_CONFIG_FILE}"
                    }

                    # Log Rotation Function
                    v2m_rotate_logs() {
                        if [[ -s "${V2M_LOG_FILE}" ]]; then
                            sudo mkdir -p "${V2M_LOG_ARCHIVE_DIR}"
                            local archive_log="${V2M_LOG_ARCHIVE_DIR}/v2ray_monitor_$(date '+%Y%m%d_%H%M%S').log.gz"
                            sudo gzip -c "${V2M_LOG_FILE}" > "${archive_log}"
                            sudo truncate -s 0 "${V2M_LOG_FILE}"
                            find "${V2M_LOG_ARCHIVE_DIR}" -name "*.gz" -mtime +30 -delete
                        fi
                    }

                    # IP Validation Function
                    v2m_validate_ip() {
                        local ip="${1}"
                        if [[ ! "${ip}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                            return 1
                        fi
                        local IFS='.'
                        read -ra ADDR <<< "${ip}"
                        for i in "${ADDR[@]}"; do
                            if [ "${i}" -lt 0 ] || [ "${i}" -gt 255 ]; then
                                return 1
                            fi
                        done
                        return 0
                    }

                    # Domain Validation Function
                    v2m_validate_domain() {
                        local domain="${1}"
                        if [[ ! "${domain}" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$ ]]; then
                            return 1
                        fi
                        return 0
                    }

                    # Cloudflare DNS Update Function
                    v2m_update_cloudflare_dns() {
                        local new_ip="${1}"
                        local max_retries=3
                        local retry_count=0
                        
                        # Extract domain parts correctly
                        local main_domain subdomain
                        subdomain=$(echo "${V2M_FULL_DOMAIN}" | cut -d. -f1)
                        main_domain=$(echo "${V2M_FULL_DOMAIN}" | cut -d. -f2-)

                        while [ ${retry_count} -lt ${max_retries} ]; do
                            local zone_response
                            zone_response=$(curl -s -f -X GET "https://api.cloudflare.com/client/v4/zones?name=${main_domain}" \
                                -H "Authorization: Bearer ${V2M_CLOUDFLARE_API_TOKEN}" \
                                -H "Content-Type: application/json" 2>/dev/null)
                            
                            if [ $? -ne 0 ]; then
                                v2m_log_message "Failed to connect to Cloudflare API"
                                ((retry_count++))
                                sleep 5
                                continue
                            }
                            
                            local zone_id
                            zone_id=$(echo "${zone_response}" | jq -r '.result[0].id')

                            if [[ -z "${zone_id}" || "${zone_id}" == "null" ]]; then
                                v2m_log_message "Failed to retrieve zone ID for ${main_domain}"
                                return 1
                            fi

                            local record_response
                            record_response=$(curl -s -f -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?name=${V2M_FULL_DOMAIN}" \
                                -H "Authorization: Bearer ${V2M_CLOUDFLARE_API_TOKEN}" \
                                -H "Content-Type: application/json" 2>/dev/null)
                                
                            if [ $? -ne 0 ]; then
                                v2m_log_message "Failed to retrieve DNS records"
                                ((retry_count++))
                                sleep 5
                                continue
                            
                            
                            local record_id
                            record_id=$(echo "${record_response}" | jq -r '.result[0].id')

                            if [[ -n "${record_id}" && "${record_id}" != "null" ]]; then
                                local update_response
                                update_response=$(curl -s -f -X PUT "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${record_id}" \
                                    -H "Authorization: Bearer ${V2M_CLOUDFLARE_API_TOKEN}" \
                                    -H "Content-Type: application/json" \
                                    --data "{\"type\":\"A\",\"name\":\"${V2M_FULL_DOMAIN}\",\"content\":\"${new_ip}\",\"ttl\":120,\"proxied\":false}" 2>/dev/null)
                                    
                                if [ $? -ne 0 ]; then
                                    v2m_log_message "Failed to update DNS record"
                                    ((retry_count++))
                                    sleep 5
                                    continue
                                fi

                                if echo "${update_response}" | jq -r '.success' | grep -q "true"; then
                                    v2m_log_message "Updated DNS record for ${V2M_FULL_DOMAIN} to ${new_ip}"
                                    return 0
                                fi
                            fi
                            
                            ((retry_count++))
                            sleep 5
                        done
                        
                        v2m_log_message "Failed to update DNS after ${max_retries} attempts"
                        return 1
                    }

                    # Server Connectivity Check Function
                    v2m_check_connectivity() {
                        local target_ip="${1}"
                        local attempt=0
                        local max_attempts=3

                        while [ ${attempt} -lt ${max_attempts} ]; do
                            if ping -c 1 -W 1 "${target_ip}" &> /dev/null; then
                                return 0
                            fi
                            ((attempt++))
                            sleep 5
                        done
                        return 1
                    }

                    # Acquire lock function
                    v2m_acquire_lock() {
                        if ! mkdir "${V2M_LOCK_FILE}" 2>/dev/null; then
                            if [ -d "${V2M_LOCK_FILE}" ]; then
                                local pid
                                pid=$(cat "${V2M_LOCK_FILE}/pid" 2>/dev/null)
                                if [ -n "${pid}" ] && ! kill -0 "${pid}" 2>/dev/null; then
                                    rm -rf "${V2M_LOCK_FILE}"
                                    mkdir "${V2M_LOCK_FILE}"
                                else
                                    return 1
                                fi
                            fi
                        fi
                        echo $$ > "${V2M_LOCK_FILE}/pid"
                        return 0
                    }

                    # Release lock function
                    v2m_release_lock() {
                        rm -rf "${V2M_LOCK_FILE}"
                    }

                    # Server Monitoring Function
                    v2m_monitor_servers() {
                        if ! v2m_acquire_lock; then
                            v2m_log_message "Another instance is already running"
                            return 1
                        fi
                        
                        trap v2m_release_lock EXIT
                        
                        while [[ -f "${V2M_SCRIPT_ENABLED_FILE}" ]]; do
                            if ! v2m_check_connectivity "${V2M_IRAN_IP}"; then
                                v2m_log_message "Iran server unreachable. Switching to Kharej IP."
                                v2m_update_cloudflare_dns "${V2M_KHAREJ_IP}" >>/dev/null 2>&1
                            else
                                v2m_log_message "Iran server reachable. Updating to Iran IP."
                                v2m_update_cloudflare_dns "${V2M_IRAN_IP}" >>/dev/null 2>&1
                            fi
                            sleep 900
                        done
                    }

                    # Setup Monitoring Configuration Function
                    v2m_setup_monitoring() {
                        V2M_CLOUDFLARE_API_TOKEN=$(whiptail --inputbox "Enter Cloudflare API Token:" 10 60 3>&1 1>&2 2>&3)
                        if [[ -z "${V2M_CLOUDFLARE_API_TOKEN}" ]]; then
                            whiptail --msgbox "API Token is required." 10 60
                            return 1
                        fi

                        V2M_FULL_DOMAIN=$(whiptail --inputbox "Enter full domain (e.g., api.example.com):" 10 60 3>&1 1>&2 2>&3)
                        if [[ -z "${V2M_FULL_DOMAIN}" ]] || ! v2m_validate_domain "${V2M_FULL_DOMAIN}"; then
                            whiptail --msgbox "Invalid domain format." 10 60
                            return 1
                        fi

                        V2M_IRAN_IP=$(whiptail --inputbox "Enter Iran Server IP:" 10 60 3>&1 1>&2 2>&3)
                        if [[ -z "${V2M_IRAN_IP}" ]] || ! v2m_validate_ip "${V2M_IRAN_IP}"; then
                            whiptail --msgbox "Invalid IP address format." 10 60
                            return 1
                        fi

                        V2M_KHAREJ_IP=$(curl -s https://api.ipify.org)
                        if [[ -z "${V2M_KHAREJ_IP}" ]] || ! v2m_validate_ip "${V2M_KHAREJ_IP}"; then
                            whiptail --msgbox "Failed to detect VPS IP address." 10 60
                            return 1
                        fi

                        v2m_save_config

                        sudo touch "${V2M_SCRIPT_ENABLED_FILE}"
                        nohup bash -c "$(declare -f v2m_monitor_servers v2m_log_message v2m_check_connectivity v2m_update_cloudflare_dns v2m_acquire_lock v2m_release_lock); v2m_monitor_servers" >> "${V2M_LOG_FILE}" 2>&1 &
                    }

                    # Main Menu Function
                    v2m_main_menu() {
                        while true; do
                            local CHOICE
                            CHOICE=$(whiptail --title "V2Ray Server Monitor" --menu "Choose an option:" 15 60 5 \
                            "1" "Setup Monitoring" \
                            "2" "Stop Monitoring" \
                            "3" "View Logs" \
                            "4" "Show Current Status" \
                            "5" "Exit" 3>&1 1>&2 2>&3)

                            case "${CHOICE}" in
                                1) 
                                    v2m_setup_monitoring
                                    whiptail --msgbox "Monitoring setup complete. Monitoring started in background." 10 60
                                    ;;
                                2)
                                    sudo rm -f "${V2M_SCRIPT_ENABLED_FILE}"
                                    whiptail --msgbox "Monitoring stopped." 10 60
                                    ;;
                                3)
                                    if [[ -f "${V2M_LOG_FILE}" ]]; then
                                        whiptail --scrolltext --title "Monitor Logs" --textbox "${V2M_LOG_FILE}" 20 70
                                    else
                                        whiptail --msgbox "No logs found." 10 60
                                    fi
                                    ;;
                                4)
                                    local STATUS="Not Running"
                                    [[ -f "${V2M_SCRIPT_ENABLED_FILE}" ]] && STATUS="Running"
                                    
                                    v2m_load_config
                                    
                                    whiptail --msgbox "Current Status:\n\nMonitoring: ${STATUS}\nDomain: ${V2M_FULL_DOMAIN}\nIran IP: ${V2M_IRAN_IP}\nKharej IP: ${V2M_KHAREJ_IP}" 15 60
                                    ;;
                                5)
                                    return 0
                                    ;;
                            esac
                        done
                    }

                    # Initialize the module
                    if ! v2m_check_dependencies; then
                        echo "Missing required dependencies. Please install them first."
                        return 1
                    fi

                    v2m_setup_directories
                    
                    # Handle different operation modes
                    case "${1}" in 
                        start)
                            v2m_setup_monitoring
                            ;;
                        stop)
                            sudo rm -f "${V2M_SCRIPT_ENABLED_FILE}"
                            ;;
                        status)
                            local STATUS="Not Running"
                            [[ -f "${V2M_SCRIPT_ENABLED_FILE}" ]] && STATUS="Running"
                            echo "Status: ${STATUS}"
                            ;;
                        rotate_logs)
                            v2m_rotate_logs
                            ;;
                        menu)
                            v2m_main_menu
                            ;;
                        *)
                            v2m_main_menu
                            ;;
                    esac

                    return 0
                }

                v2ray_monitor_module menu
                # Example usage:
                # v2ray_monitor_module "menu"    # To show the menu
                # v2ray_monitor_module "start"   # To start monitoring
                # v2ray_monitor_module "stop"    # To stop monitoring
                # v2ray_monitor_module "status"  # To check status
                ;;
            "13")
                # Exit option
                exit 0
                ;;                
            *)
                exit 0
                ;;
        esac
    done
done   

