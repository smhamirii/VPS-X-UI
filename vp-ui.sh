#!/usr/bin/bash


server_upgrade(){
    up1(){
        sudo apt upgrade -y 
    }

    up2(){
        # Enable BBR by adding it to sysctl configuration
        echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf

        # Apply the changes immediately
        sudo sysctl -p
    }

    up3(){
        # Choose server location
        server_location=$(whiptail --title "Choose Server" --menu "Choose server location:" 15 60 2 \
            "1" "Iran" \
            "2" "Kharej" 3>&1 1>&2 2>&3)

        if [[ "$server_location" == "1" ]]; then
            sudo rm /etc/resolv.conf
            sudo touch /etc/resolv.conf
            echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
            echo "nameserver 4.2.2.4" | sudo tee -a /etc/resolv.conf
            whiptail --msgbox "DNS Updated" 8 45

        elif [[ "$server_location" == "2" ]]; then
            sudo rm /etc/resolv.conf
            sudo touch /etc/resolv.conf
            echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf
            echo "nameserver 1.0.0.1" | sudo tee -a /etc/resolv.conf
            whiptail --msgbox "DNS Updated" 8 45

        fi            
    }

    up4(){
        sudo ufw disable
    }

    # setup condition
    upgrade_choose=$(whiptail --title "Choose Server" --menu "Choose server location:" 15 60 6 \
        "1" "Full Upgrade(one click)" \
        "2" "Server Upgrade" \
        "3" "BBR Setup" \
        "4" "DNS Update" \
        "5" "Firewall Disable" \
        "6" "Exit" 3>&1 1>&2 2>&3)

    if [[ "$upgrade_choose" == "1" ]]; then
        up1 && \
        up2 && \
        up3 && \
        up4

    elif [[ "$upgrade_choose" == "2" ]]; then
        up1

    elif [[ "$upgrade_choose" == "3" ]]; then
        up2

    elif [[ "$upgrade_choose" == "4" ]]; then
        up3

    elif [[ "$upgrade_choose" == "5" ]]; then
        up4

    fi
        
    # clear screen
    clear    
}


internet_connection(){
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
}


xui_complex(){
    while true; do
        xui_cond=$(whiptail --title "X-UI SERVICE" --menu "X-UI SERVICE, choose an option:" 20 80 3 \
            "1" "X-UI Status" \
            "2" "Install X-UI Sanaei Panel" \
            "3" "Unistall X-UI Panel" 3>&1 1>&2 2>&3)

        case "$xui_cond" in
            "1")
                # Check if /usr/bin/x-ui file exists
                if [ -f "/usr/bin/x-ui" ]; then
                    # Display a message using whiptail if the file exists
                    whiptail --title "File Check" --msgbox "x-ui exists!" 8 45
                    x-ui
                    clear
                    return 0
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
                    continue
                fi                
                ;;
            *)
                return 1
                ;;
        esac
    done
}


reverse_old(){
    while true; do
        reverseold_menu=$(whiptail --title "Reverse Tunnel" --menu "Reverse Tunnel, choose an option:" 20 80 3 \
            "1" "Tunnel Status" \
            "2" "Install Reverse Tunnel" \
            "3" "Unistall Reverse Tunnel" 3>&1 1>&2 2>&3)

        case "$reverseold_menu" in
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
                    continue
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
                    continue
                fi

                sni=$(whiptail --inputbox "Please Enter SNI (default: tamin.ir):" 10 60 "tamin.ir" 3>&1 1>&2 2>&3)

                if [ "$server_choice" == "2" ]; then
                    server_ip=$(whiptail --inputbox "Please Enter IRAN IP (internal-server):" 10 60 3>&1 1>&2 2>&3)
                    arguments="--kharej --iran-ip:$server_ip --iran-port:443 --toip:127.0.0.1 --toport:multiport --password:qwer --sni:$sni --terminate:24"
                elif [ "$server_choice" == "1" ]; then
                    arguments="--iran --lport:23-65535 --sni:$sni --password:qwer --terminate:24"
                else
                    whiptail --msgbox "Invalid choice. Please enter '1' or '2'." 8 45
                    continue
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
                    continue
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
                    continue
                fi
                ;;
            *)
                return 1
                ;;
        esac
    done
}


reverse_new(){
    reversei_menu=$(whiptail --title "Reverse Tunnel" --menu "Reverse Tunnel with python" 15 60 3 \
        "1" "PYTHON 3 INSTALL" \
        "2" "Without Update" \
        "3" "Exit" 3>&1 1>&2 2>&3)


    if [[ "$reversei_menu" == "1" ]]; then
        # insatll python
        apt install python3 -y && sudo apt install python3-pip &&  pip install colorama && pip install netifaces && apt install curl -y
       
        # insatll colorama
        pip3 install colorama
       
        # insatll pip
        sudo apt-get install python-pip -y  &&  apt-get install python3 -y && alias python=python3 && python -m pip install colorama && python -m pip install netifaces
       
        # apt update
        sudo apt update -y && sudo apt install -y python3 python3-pip curl && pip3 install --upgrade pip && pip3 install netifaces colorama requests

        # installing tunnel
        if [ -f "RTT.py" ]; then
            rm RTT.py
        fi
        wget https://raw.githubusercontent.com/smhamirii/VPS-X-UI/refs/heads/main/RTT.py
        python3 RTT.py

    elif [[ "$reversei_menu" == "2" ]]; then
        # installing tunnel
        if [ -f "RTT.py" ]; then
            rm RTT.py
        fi
        wget https://raw.githubusercontent.com/smhamirii/VPS-X-UI/refs/heads/main/RTT.py
        python3 RTT.py

    fi  
}


certificate_complex(){
    error_exit() {
        whiptail --msgbox "Error: $1" 10 60
        return 1  # Changed from return to exit for proper script termination
    }

    # Function to check if DNS record exists and create if it doesn't
    check_or_create_dns_record() {
        local full_domain="$1"
        local ip="$2"
        local zone_id="$3"
        local cf_token="$4"

        # Check if record exists
        local record_info=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?name=$full_domain" \
            -H "Authorization: Bearer $cf_token" \
            -H "Content-Type: application/json")
        
        local record_exists=$(echo "$record_info" | jq -r '.result | length')

        if [ "$record_exists" -eq 0 ]; then
            # Create new record
            local create_response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
                -H "Authorization: Bearer $cf_token" \
                -H "Content-Type: application/json" \
                --data '{"type":"A","name":"'"$full_domain"'","content":"'"$ip"'","ttl":120,"proxied":false}')

            if ! echo "$create_response" | jq -r '.success' | grep -q "true"; then
                error_exit "Failed to create DNS record"
            fi
            
            # Get the new record ID
            record_info=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?name=$full_domain" \
                -H "Authorization: Bearer $cf_token" \
                -H "Content-Type: application/json")
        fi

        # Return record ID and current IP
        echo "$record_info" | jq -r '.result[0] | .id + " " + .content'
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

    # Trap Ctrl+C and cleanup
    trap 'echo "Operation cancelled by user"; exit 1' INT

    # Get the current VPS IP
    VPS_IP=$(curl -s https://api.ipify.org)
    [[ -z "$VPS_IP" ]] && error_exit "Failed to retrieve VPS IP address"

    # Prompt for required information
    CF_API_TOKEN=$(whiptail --inputbox "Enter your Cloudflare API token:" 10 60 3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return 1  # User pressed Cancel
    
    FULL_DOMAIN=$(whiptail --inputbox "Enter your full domain (e.g., subdomain.example.com):" 10 60 3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return 1  # User pressed Cancel

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

    # Check if record exists or create new one
    RECORD_INFO=$(check_or_create_dns_record "$FULL_DOMAIN" "$VPS_IP" "$ZONE_ID" "$CF_API_TOKEN")
    RECORD_ID=$(echo "$RECORD_INFO" | cut -d' ' -f1)
    ORIGINAL_IP=$(echo "$RECORD_INFO" | cut -d' ' -f2)

    # Show confirmation before proceeding
    whiptail --yesno "Ready to proceed with certificate renewal:\n\nDomain: $FULL_DOMAIN\nCurrent IP: $ORIGINAL_IP\nVPS IP: $VPS_IP\n\nContinue?" 15 60
    [[ $? -ne 0 ]] && return 0  # User selected No

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

    # Handle menu cancel
    if [ $? -ne 0 ]; then
        whiptail --msgbox "No selection made. Using original IP ($ORIGINAL_IP)" 10 60
        FINAL_IP=$ORIGINAL_IP
    else
        case $IP_CHOICE in
            1)
                FINAL_IP=$ORIGINAL_IP
                ;;
            2)
                FINAL_IP=$(whiptail --inputbox "Enter the new IP address:" 10 60 3>&1 1>&2 2>&3)
                if [[ $? -ne 0 || -z "$FINAL_IP" ]]; then
                    whiptail --msgbox "No IP provided. Using original IP ($ORIGINAL_IP)" 10 60
                    FINAL_IP=$ORIGINAL_IP
                fi
                ;;
            3)
                FINAL_IP=$VPS_IP
                ;;
        esac
    fi

    # Update DNS to final IP
    echo "Updating DNS to final IP: $FINAL_IP"
    update_dns_record "$FULL_DOMAIN" "$FINAL_IP" "$ZONE_ID" "$RECORD_ID" "$CF_API_TOKEN"
    DNS_UPDATE_STATUS=$?

    # Clean up
    rm -f /tmp/original_ip_backup

    # Final status - check both certificate and DNS update status
    if [ $CERT_STATUS -eq 0 ] && [ $DNS_UPDATE_STATUS -eq 0 ]; then
        whiptail --msgbox "Certificate renewal complete!\nDNS updated successfully!\n\nDomain: $FULL_DOMAIN\nFinal IP: $FINAL_IP" 12 60
    else
        # Provide more specific error information
        ERROR_MSG="Operation encountered issues:\n\n"
        [ $CERT_STATUS -ne 0 ] && ERROR_MSG+="- Certificate renewal failed\n"
        [ $DNS_UPDATE_STATUS -ne 0 ] && ERROR_MSG+="- DNS update failed\n\n"
        ERROR_MSG+="Domain: $FULL_DOMAIN\nFinal IP: $FINAL_IP"
        
        whiptail --msgbox "$ERROR_MSG" 15 60
    fi

    # Return the overall status
    [ $CERT_STATUS -eq 0 ] && [ $DNS_UPDATE_STATUS -eq 0 ]
}


virtual_ram(){
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


change_main_ip(){
    # Check if script is run as root
    if [ "$EUID" -ne 0 ]; then
        whiptail --title "Error" --msgbox "Please run as root or with sudo" 8 40
        return 1
    fi

    # Function to backup interfaces file
    backup_interfaces() {
        local backup_file="/etc/network/interfaces.backup.$(date +%Y%m%d_%H%M%S)"
        cp /etc/network/interfaces "$backup_file"
        whiptail --title "Backup" --msgbox "Backup created: $backup_file" 8 60
    }

    # Function to get all physical interfaces
    get_interfaces() {
        ip -o link show | grep -v "lo" | awk -F': ' '{print $2}' | cut -d'@' -f1
    }

    # Function to get all IPv4 addresses for a specific interface
    get_ipv4_addresses() {
        local interface=$1
        ip -o addr show dev "$interface" | grep 'inet ' | awk '{print $4}'
    }

    # Function to get gateway for an interface
    get_gateway() {
        local interface=$1
        ip route show dev "$interface" | grep default | awk '{print $3}'
    }

    # Function to extract existing IPv6 and DNS configuration
    get_existing_config() {
        local interface=$1
        local config_file="/etc/network/interfaces"
        local in_ipv6=0
        local ipv6_config=""
        
        while IFS= read -r line; do
            if [[ $line =~ ^iface[[:space:]]+$interface[[:space:]]+inet6[[:space:]]+static ]]; then
                in_ipv6=1
                ipv6_config+="$line\n"
            elif [[ $in_ipv6 -eq 1 && $line =~ ^[[:space:]] ]]; then
                ipv6_config+="$line\n"
            elif [[ $in_ipv6 -eq 1 ]]; then
                in_ipv6=0
            fi
        done < "$config_file"
        
        echo -e "$ipv6_config"
    }

    # Function to update interfaces file
    update_interfaces_file() {
        local interface=$1
        local ipv4_address=$2
        local ipv4_gateway=$3
        local existing_ipv6=$(get_existing_config "$interface")
        
        # Create new interfaces file content
        cat > /etc/network/interfaces << EOF
# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto $interface
iface $interface inet static
address $ipv4_address
netmask 255.255.255.255
gateway $ipv4_gateway
EOF

        # Add existing IPv6 configuration if it exists
        if [ -n "$existing_ipv6" ]; then
            echo -e "\n$existing_ipv6" >> /etc/network/interfaces
        fi
    }

    # Function to restart networking
    restart_networking() {
        if systemctl restart networking.service; then
            whiptail --title "Success" --msgbox "Network service restarted successfully" 8 40
        else
            whiptail --title "Error" --msgbox "Failed to restart networking service" 8 40
            return 1
        fi
    }

    # Function to create menu items for whiptail
    create_menu_items() {
        local items=("$@")
        local menu_items=()
        local i=1
        for item in "${items[@]}"; do
            menu_items+=("$i" "$item")
            ((i++))
        done
        echo "${menu_items[@]}"
    }

    # Main script execution
    # Show welcome message
    whiptail --title "Network IP Switcher" --msgbox "Welcome to Network IP Switcher\n\nThis tool will help you change your network interface configuration." 10 60

    # Get interfaces and create menu
    interfaces=($(get_interfaces))
    if [ ${#interfaces[@]} -eq 0 ]; then
        whiptail --title "Error" --msgbox "No network interfaces found" 8 40
        return 1
    fi

    menu_items=$(create_menu_items "${interfaces[@]}")
    interface_choice=$(whiptail --title "Select Interface" --menu "Choose a network interface:" 15 60 5 ${menu_items} 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
        return 1
    fi
    selected_interface=${interfaces[$((interface_choice-1))]}

    # Get IPv4 addresses and create menu
    ipv4_addresses=($(get_ipv4_addresses "$selected_interface"))
    if [ ${#ipv4_addresses[@]} -eq 0 ]; then
        whiptail --title "Error" --msgbox "No IPv4 addresses found for interface $selected_interface" 8 60
        return 1
    fi

    menu_items=$(create_menu_items "${ipv4_addresses[@]}")
    ip_choice=$(whiptail --title "Select IP Address" --menu "Choose an IP address:" 15 60 5 ${menu_items} 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
        return 1
    fi
    selected_ip=${ipv4_addresses[$((ip_choice-1))]}
    selected_ip=${selected_ip%/*}  # Remove CIDR notation if present

    # Get gateway
    current_gateway=$(get_gateway "$selected_interface")
    if [ -z "$current_gateway" ]; then
        current_gateway=$(whiptail --title "Gateway Input" --inputbox "Enter gateway address:" 8 60 3>&1 1>&2 2>&3)
        if [ $? -ne 0 ]; then
            return 1
        fi
    fi

    # Show confirmation
    confirmation_text="Interface: $selected_interface\nIPv4 Address: $selected_ip\nIPv4 Gateway: $current_gateway\n\nExisting IPv6 and DNS settings will be preserved."
    if whiptail --title "Confirm Changes" --yesno "$confirmation_text" 15 60; then
        # Perform the changes
        backup_interfaces
        update_interfaces_file "$selected_interface" "$selected_ip" "$current_gateway"
        restart_networking
        whiptail --title "Success" --msgbox "Configuration updated successfully" 8 40
    else
        whiptail --title "Cancelled" --msgbox "Operation cancelled" 8 40
        return 1
    fi
}


certificates(){
    while true; do
        sslv=$(whiptail --title "SSL Certificate" --menu "SSL Certificate, choose an option:" 20 80 2 \
            "1" "Certificate for Subdomain SSL" \
            "2" "Revoke Certificate SSL" 3>&1 1>&2 2>&3)

        case "$sslv" in
            "1")
                # Install cron if not already installed and enable it
                sudo apt install cron -y
                sudo systemctl enable cron

                # Prompt the user to enter the subdomain
                SUBDOMAIN=$(whiptail --inputbox "Please enter the subdomain for which you want to create an SSL certificate (e.g., subdomain.example.com):" 10 60 3>&1 1>&2 2>&3)

                # Validate that the subdomain is not empty
                if [[ -z "$SUBDOMAIN" ]]; then
                    whiptail --msgbox "Error: Subdomain cannot be empty. Please run the script again and provide a valid subdomain." 10 60
                    return 1
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
                    return 1
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
                    return 1
                fi

                # Define the certificate paths
                CERT_DIR="/etc/ssl/$SUBDOMAIN"
                CERT_PATH="/etc/letsencrypt/live/$SUBDOMAIN/fullchain.pem"

                # Check if the certificate exists for the subdomain
                if [[ ! -f "$CERT_PATH" ]]; then
                    whiptail --msgbox "Error: Certificate for $SUBDOMAIN does not exist." 10 60
                    return 1
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
            *)
                return 0
                ;;
        esac
    done
}


subdomains(){
    # Function to manage Cloudflare DNS                                    
    if [[ -n "$IP" ]]; then
        unset IP
    fi

    # Get the public IP of the machine (server IP)
    IP=$(curl -s https://api.ipify.org)
    if [[ -z "$IP" ]]; then
        whiptail --msgbox "Failed to retrieve your public IP address." 10 60
        return 1
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
        return 1
    fi

    # Fetch the zone ID for the domain
    ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json" | jq -r '.result[0].id')

    # Exit if no zone ID is found
    if [[ -z "$ZONE_ID" || "$ZONE_ID" == "null" ]]; then
        whiptail --msgbox "Failed to retrieve the zone ID for $DOMAIN. Please check the domain and API token." 10 60
        return 1
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
            return 1
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
            return 1
        fi
    fi 
}


auto_ip_change(){
    # Script configuration and paths
    SCRIPT_NAME="cloudflare-ddns"
    SCRIPT_PATH="/usr/local/bin/${SCRIPT_NAME}.sh"
    SERVICE_PATH="/etc/systemd/system/${SCRIPT_NAME}.service"
    CONFIG_PATH="/etc/${SCRIPT_NAME}.conf"
    STATUS_FILE="/tmp/${SCRIPT_NAME}_current_server.status"

    # Required dependencies
    REQUIRED_PACKAGES=("jq" "curl" "whiptail")


    # Check and install dependencies
    check_dependencies() {
        for pkg in "${REQUIRED_PACKAGES[@]}"; do
            if ! dpkg -s "$pkg" >/dev/null 2>&1; then
                if ! whiptail --title "Dependencies Missing" --yesno "Package $pkg is not installed. Install now?" 10 60; then
                    whiptail --msgbox "Cannot proceed without required packages." 10 60
                    return 1
                fi
                sudo apt-get update
                sudo apt-get install -y "$pkg"
            fi
        done
    }

    # Function to send Telegram message
    send_telegram_message() {
        local message="$1"
        
        # Read chat IDs from config
        if [ -n "$TELEGRAM_CHAT_IDS" ]; then
            IFS=',' read -ra CHAT_IDS <<< "$TELEGRAM_CHAT_IDS"
            for chat_id in "${CHAT_IDS[@]}"; do
                curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
                    -d "chat_id=${chat_id}" \
                    -d "text=${message}" \
                    -d "parse_mode=HTML"
            done
        fi
    }


    # Save configuration to a config file
    save_configuration() {
        # Create config file
        sudo tee "$CONFIG_PATH" > /dev/null << EOF
CF_API_KEY="$CF_API_KEY"
DOMAIN="$DOMAIN"
SUBDOMAIN="$SUBDOMAIN"
KHAREJ_SERVER_IP="$KHAREJ_SERVER_IP"
IRAN_SERVER_IP="$IRAN_SERVER_IP"
ZONE_ID="$ZONE_ID"
TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
TELEGRAM_CHAT_IDS="$TELEGRAM_CHAT_IDS"
EOF
        sudo chmod 600 "$CONFIG_PATH"
    }

    # Check if subdomain exists
    check_subdomain_exists() {
        local RECORD_RESPONSE=$(curl -s -X GET \
            "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$SUBDOMAIN.$DOMAIN" \
            -H "Authorization: Bearer $CF_API_KEY" \
            -H "Content-Type: application/json")
        
        local RECORD_COUNT=$(echo "$RECORD_RESPONSE" | jq '.result | length')
        
        if [ "$RECORD_COUNT" -eq 0 ]; then
            whiptail --msgbox "Error: Subdomain $SUBDOMAIN.$DOMAIN does not exist in Cloudflare. Please create it first." 10 60
            return 1
        fi
        return 0
    }

    # Collect configuration from user
    get_configuration() {
        # Cloudflare API Configuration
        CF_API_KEY=$(whiptail --inputbox "Enter Cloudflare API Key" 10 60 3>&1 1>&2 2>&3) || return 1    
        FULL_DOMAIN=$(whiptail --inputbox "Enter your full domain (e.g., subdomain.example.com):" 10 60 3>&1 1>&2 2>&3) || return 1
        
        # Extract domain and subdomain
        DOMAIN=$(echo "$FULL_DOMAIN" | sed -E 's/^[^.]+\.//')
        SUBDOMAIN=$(echo "$FULL_DOMAIN" | sed -E 's/^([^.]+).+$/\1/')
        
        # Find zone ID first
        find_zone_id || return 1

        # Check if subdomain exists
        check_subdomain_exists || return 1
        
        # Server IPs
        KHAREJ_SERVER_IP=$(curl -s https://api.ipify.org)
        IRAN_SERVER_IP=$(whiptail --inputbox "Enter Iran Server IP" 10 60 3>&1 1>&2 2>&3) || return 1

        # Telegram Configuration
        TELEGRAM_BOT_TOKEN=$(whiptail --inputbox "Enter Telegram Bot Token" 10 60 3>&1 1>&2 2>&3) || return 1
        TELEGRAM_CHAT_IDS=$(whiptail --inputbox "Enter Telegram Chat IDs (comma-separated for multiple users)" 10 60 3>&1 1>&2 2>&3) || return 1
    }

    # Create the monitoring script
    create_monitor_script() {
        sudo mkdir -p "$(dirname "$SCRIPT_PATH")"
        sudo tee "$SCRIPT_PATH" > /dev/null << 'EOF'
#!/bin/bash

CONFIG_PATH="/etc/cloudflare-ddns.conf"
source "$CONFIG_PATH"

CURRENT_SERVER_IP=""

send_telegram_notification() {
    local message="$1"
    if [ -n "$TELEGRAM_CHAT_IDS" ]; then
        IFS=',' read -ra CHAT_IDS <<< "$TELEGRAM_CHAT_IDS"
        for chat_id in "${CHAT_IDS[@]}"; do
            curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
                -d "chat_id=${chat_id}" \
                -d "text=${message}" \
                -d "parse_mode=HTML"
        done
    fi
}

update_dns_record() {
    local TARGET_IP=$1
    local SWITCH_REASON=$2
    
    # Get current DNS record
    RECORD_RESPONSE=$(curl -s -X GET \
        "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$SUBDOMAIN.$DOMAIN" \
        -H "Authorization: Bearer $CF_API_KEY" \
        -H "Content-Type: application/json")
    
    RECORD_ID=$(echo "$RECORD_RESPONSE" | jq -r '.result[0].id')
    CURRENT_IP=$(echo "$RECORD_RESPONSE" | jq -r '.result[0].content')
    
    # Only update if IP is different
    if [ "$CURRENT_IP" != "$TARGET_IP" ]; then
        UPDATE_RESPONSE=$(curl -s -X PUT \
            "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
            -H "Authorization: Bearer $CF_API_KEY" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"$SUBDOMAIN\",\"content\":\"$TARGET_IP\",\"ttl\":1,\"proxied\":false}")
        
        if echo "$UPDATE_RESPONSE" | jq -e '.success' > /dev/null; then
            NOTIFICATION_MSG="🔄 DNS Update Alert\n\nDomain: $SUBDOMAIN.$DOMAIN\nOld IP: $CURRENT_IP\nNew IP: $TARGET_IP\nReason: $SWITCH_REASON\nTimestamp: $(date '+%Y-%m-%d %H:%M:%S')"
            send_telegram_notification "$NOTIFICATION_MSG"
            echo "DNS updated from $CURRENT_IP to $TARGET_IP" | systemd-cat -t cloudflare-ddns -p info
            CURRENT_SERVER_IP="$TARGET_IP"
        else
            echo "DNS update failed" | systemd-cat -t cloudflare-ddns -p err
        fi
    fi
}

while true; do
    if ping -c 3 "$IRAN_SERVER_IP" > /dev/null 2>&1; then
        update_dns_record "$IRAN_SERVER_IP" "Iran server is now reachable"
    else
        update_dns_record "$KHAREJ_SERVER_IP" "Iran server is unreachable"
    fi
    
    sleep 300
done
EOF
        sudo chmod +x "$SCRIPT_PATH"
    }


    # Create systemd service file
    create_service_file() {
        # Create the monitoring script first
        create_monitor_script || return 1

        sudo tee "$SERVICE_PATH" > /dev/null << EOF
[Unit]
Description=Cloudflare Dynamic DNS Monitoring Service
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash $SCRIPT_PATH
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF
    }

    # Install script and service
    install_service() {
        create_service_file || return 1

        # Reload systemd, enable and start service
        sudo systemctl daemon-reload
        sudo systemctl enable "$SCRIPT_NAME.service"
        sudo systemctl start "$SCRIPT_NAME.service"

        whiptail --msgbox "Service installed and started successfully!" 10 60
    }

    # Uninstall service
    uninstall_service() {
        # Stop and disable service
        sudo systemctl stop "$SCRIPT_NAME.service"
        sudo systemctl disable "$SCRIPT_NAME.service"

        # Remove files
        sudo rm -f "$SERVICE_PATH" "$SCRIPT_PATH" "$CONFIG_PATH"

        # Reload systemd
        sudo systemctl daemon-reload

        whiptail --msgbox "Service removed successfully!" 10 60
    }

    # Enhanced status checking function
    check_current_server_status() {
        if [ ! -f "$CONFIG_PATH" ]; then
            whiptail --msgbox "Configuration file not found. Please install the service first." 10 60
            return 1
        fi

        # Source the configuration
        source "$CONFIG_PATH"

        # Fetch current DNS record
        RECORD_RESPONSE=$(curl -s -X GET \
            "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$SUBDOMAIN.$DOMAIN" \
            -H "Authorization: Bearer $CF_API_KEY" \
            -H "Content-Type: application/json")
        
        # Extract current IP
        CURRENT_IP=$(echo "$RECORD_RESPONSE" | jq -r '.result[0].content')

        # Determine which server is active
        if [ "$CURRENT_IP" == "$KHAREJ_SERVER_IP" ]; then
            SERVER_STATUS="Kharej Server ($KHAREJ_SERVER_IP) is Active"
        elif [ "$CURRENT_IP" == "$IRAN_SERVER_IP" ]; then
            SERVER_STATUS="Iran Server ($IRAN_SERVER_IP) is Active"
        else
            SERVER_STATUS="Unknown Server IP ($CURRENT_IP)"
        fi

        # Get systemd service status
        SERVICE_STATUS=$(systemctl is-active "$SCRIPT_NAME.service")

        # Show detailed status
        whiptail --title "Service Status" --msgbox "
Service State: $SERVICE_STATUS
Active Server: $SERVER_STATUS

Kharej Server IP: $KHAREJ_SERVER_IP
Iran Server IP: $IRAN_SERVER_IP
Domain: $SUBDOMAIN.$DOMAIN" 15 60
    }

    # Main menu for Cloudflare DDNS Management
    main_menu1() {
        while true; do
            CHOICE=$(whiptail --title "Cloudflare Dynamic DNS Management" --menu "Choose an option:" 15 60 7 \
                "1" "Install and Configure Service" \
                "2" "Start Service" \
                "3" "Stop Service" \
                "4" "Restart Service" \
                "5" "Check Service Status" \
                "6" "Remove Service" \
                "7" "Exit" 3>&1 1>&2 2>&3)

            exitstatus=$?
            if [ $exitstatus != 0 ]; then
                return 1
            fi

            case $CHOICE in
                1)
                    check_dependencies && \
                    get_configuration && \
                    find_zone_id && \
                    save_configuration && \
                    install_service
                    ;;
                2)
                    sudo systemctl start "$SCRIPT_NAME.service"
                    whiptail --msgbox "Service started!" 10 60
                    ;;
                3)
                    sudo systemctl stop "$SCRIPT_NAME.service"
                    whiptail --msgbox "Service stopped!" 10 60
                    ;;
                4)
                    sudo systemctl restart "$SCRIPT_NAME.service"
                    whiptail --msgbox "Service restarted!" 10 60
                    ;;
                5)
                    check_current_server_status
                    ;;
                6)
                    uninstall_service
                    ;;
                7)
                    return 0
                    ;;
            esac
        done
    }


    # Run the main menu
    main_menu1
}


speed_testi(){
    # Run speedtest and capture output
    SPEED_RESULT=$(curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -)

    # Display live results in whiptail
    whiptail --title "Speed Test Results" \
            --scrolltext \
            --msgbox "$SPEED_RESULT" 20 70
}


# main program
main_program() {
    while true; do
        # main directory
        cd

        # Main menu
        main_obj=$(whiptail --title "SAMIR VPN Creator" --menu "Welcome to Samir VPN Creator, choose an option:" 20 80 13 \
            "1" "X-UI SERVICE" \
            "2" "Reverse Tunnel (New method)" \
            "3" "SSL Cetificate + Change Subdomain IP" \
            "4" "Auto IP Change(run on kharej)" \
            "5" "Server Upgrade" \
            "6" "Ping Servers" \
            "7" "Speed Test" \
            "8" "Virtual RAM" \
            "9" "Change VPS Main IP(Not Tested)" \
            "10" "SSL Certificate" \
            "11" "Change Subdomain IP" \
            "12" "Reverse Tunnel (Old method)" \
            "13" "Exit" 3>&1 1>&2 2>&3)


        case "$main_obj" in
            "1")
                xui_complex                
                ;;
            "2")
                reverse_new   
                ;;
            "3")
                certificate_complex                
                ;;
            "4")
                auto_ip_change               
                ;;
            "5")
                server_upgrade
                ;;
            "6")
                internet_connection      
                ;;
            "7")
                speed_testi
                ;;
            "8")
                virtual_ram        
                ;;
            "9")
                change_main_ip       
                ;;
            "10")
                certificates
                ;;
            "11")
                subdomains 
                ;;
            "12")
                reverse_old    
                ;;
            "13")
                exit 0
                ;;
        esac
    done     
}

# main directory
cd


# starter menu
starter_menu=$(whiptail --title "Welcome" --menu "First time or not:" 15 60 3 \
    "1" "First Time" \
    "2" "Without Update" \
    "3" "Exit" 3>&1 1>&2 2>&3)


if [[ "$starter_menu" == "1" ]]; then

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

    # main program
    main_program

elif [[ "$starter_menu" == "2" ]]; then

    # ip problem
    sudo sysctl -p

    # clear screen
    clear
    
    # main program
    main_program

else
    exit 0
fi

