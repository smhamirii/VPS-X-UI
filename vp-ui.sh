#!/usr/bin/bash

# main directory
cd

# Log file setup
LOG_FILE="/var/log/package-repair-$(date +%Y%m%d-%H%M%S).log"
echo "Starting package management repair process at $(date)" | sudo tee -a $LOG_FILE

# Function to log commands and their output
log_command() {
    echo "Running: $1" | sudo tee -a $LOG_FILE
    eval "sudo $1" 2>&1 | sudo tee -a $LOG_FILE
    return ${PIPESTATUS[0]}
}

# Function to check if processes are running
check_processes() {
    if pgrep -x "apt" > /dev/null || pgrep -x "apt-get" > /dev/null; then
        echo "Found running apt processes. Attempting to terminate..." | sudo tee -a $LOG_FILE
        log_command "killall apt apt-get"
        sleep 2
    else
        echo "No apt processes found running." | sudo tee -a $LOG_FILE
    fi
}

# Main repair sequence
main_update() {
    # First check and kill running processes
    check_processes

    # Array of commands to run in sequence
    commands=(
        "apt --fix-broken install -y"
        "apt clean"
        "dpkg --configure -a"
        "apt update"
        "apt autoremove -y"
    )

    # Execute each command and check for errors
    for cmd in "${commands[@]}"; do
        echo -e "\nExecuting: $cmd" | sudo tee -a $LOG_FILE
        if ! log_command "$cmd"; then
            echo "Error executing: $cmd" | sudo tee -a $LOG_FILE
            echo "Please check the log file at $LOG_FILE for details."
            exit 1
        fi
    done

    echo -e "\nPackage management repair completed successfully!" | sudo tee -a $LOG_FILE
    echo "Log file saved at: $LOG_FILE"
}

# main update
main_update

# install necessary packages
sudo apt install wget whiptail lsof iptables unzip gcc git curl tar jq -y

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
        var7=$(whiptail --title "SAMIR VPN Creator" --menu "Welcome to Samir VPN Creator, choose an option:" 20 80 10 \
            "1" "Server Upgrade" \
            "2" "Internet Connection" \
            "3" "X-UI SERVICE" \
            "4" "Reverse Tunnel" \
            "5" "SSL Certificate" \
            "6" "Change Subdomain IP" \
            "7" "Virtual RAM" \
            "8" "Change Main IP" \
            "9" "Auto Restart Server" \
            "10" "Exit" 3>&1 1>&2 2>&3)


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
                
                #disable firewall for opening port
                sudo ufw disable
                
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
                        /usr/local/x-ui/x-ui setting -username "samir" -password "samir" -port "8443" -webBasePath ""
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
            "6")
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
            "7")
                # remove existing swap
                if ! whiptail --title "Confirm" --yesno "This will remove existing swap and create a new swap file. Continue?" 8 60; then
                    break
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

                if [ $? -ne 0 ]; then
                    whiptail --title "Cancelled" --msgbox "Operation cancelled by user." 8 40
                    break
                fi

                # Validate input
                if ! [[ "$swap_size" =~ ^[0-9]+$ ]]; then
                    whiptail --title "Error" --msgbox "Please enter a valid number." 8 40
                    break
                fi


                # Disable all swap
                swapoff -a

                # Remove swap entries from /etc/fstab
                sed -i '/swap/d' /etc/fstab

                # Remove existing swap file if it exists
                rm -f /swapfile

                whiptail --title "Swap Removal" --msgbox "Existing swap has been removed." 8 40

                local size=$1

                # Create swap file
                dd if=/dev/zero of=/swapfile bs=1M count=$size status=progress

                # Set correct permissions
                chmod 600 /swapfile

                # Format as swap
                mkswap /swapfile

                # Enable swap
                swapon /swapfile

                # Add to fstab
                echo '/swapfile none swap sw 0 0' >> /etc/fstab

                # Configure swappiness
                echo 'vm.swappiness=10' >> /etc/sysctl.conf
                sysctl -p

                whiptail --title "Swap Creation" --msgbox "New swap file of ${size}MB has been created and enabled." 8 50
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
            "10")
                # Exit option
                exit 0
                ;;                
            *)
                exit 0
                ;;
        esac
    done
done   

