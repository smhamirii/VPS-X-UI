#!/usr/bin/bash

# main directory
cd

# kill all apt
sudo ufw disable
sudo killall apt apt-get

# update
sudo apt --fix-broken install
sudo apt clean
sudo apt update

# install necessary packages
apt install whiptail -y
sudo apt install curl wget jq -y

# Disable IPv6
echo "127.0.0.1 $(hostname)" >> /etc/hosts
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1

# Make changes permanent by adding to /etc/sysctl.conf
grep -qxF 'net.ipv6.conf.all.disable_ipv6 = 1' /etc/sysctl.conf || echo 'net.ipv6.conf.all.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf
grep -qxF 'net.ipv6.conf.default.disable_ipv6 = 1' /etc/sysctl.conf || echo 'net.ipv6.conf.default.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf
grep -qxF 'net.ipv6.conf.lo.disable_ipv6 = 1' /etc/sysctl.conf || echo 'net.ipv6.conf.lo.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf

sudo sysctl -p

while true; do
    var7=$(whiptail --title "SAMIR VPN Creator" --menu "Welcome to Samir VPN Creator, choose an option:" 20 70 9 \
        "1" "Server Upgrade" \
        "2" "Install X-UI Panel" \
        "3" "Install Reverse Tunnel" \
        "4" "Certificate for Subdomain" \
        "5" "Cloudflare DNS Management" \
        "6" "Unistall X-UI Panel" \
        "7" "Unistall Reverse Tunnel" \
        "8" "Check Internet Connection" \
        "9" "Exit" 3>&1 1>&2 2>&3)

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
            ;;
        "2")
            # Install x-ui
            var1="y"
            var2="samir"
            var3="samir"
            var4="8443"
            echo -e "$var1\n$var2\n$var3\n$var4" | bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
            ;;
        "3")
            # BBR setup
            sudo modprobe tcp_bbr
            echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
            echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
            sudo sysctl -p

            # Choose server location
            var6=$(whiptail --title "Choose Server" --menu "Choose server location:" 15 60 2 \
                "1" "Iran" \
                "2" "Kharej" 3>&1 1>&2 2>&3)

            if [[ "$var6" == "1" ]]; then
                var11="2"
                echo -e "$var11" | bash <(curl -Ls https://raw.githubusercontent.com/radkesvat/ReverseTlsTunnel/master/scripts/RtTunnel.sh)
                wait
                sudo rm /etc/resolv.conf
                sudo touch /etc/resolv.conf

                #change dns
                echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
                echo "nameserver 4.2.2.4" | sudo tee -a /etc/resolv.conf
                
                #reload dns
                sudo systemd-resolve --flush-caches
                sudo systemctl restart systemd-resolved

                #options
                var12="1"
                var13="no"
                var14="5.4"
                var16="qwer"
                var17="no"
                var15=$(whiptail --inputbox "Enter the SNI Domain:" 8 39 3>&1 1>&2 2>&3)
                
                #script
                echo -e "$var12\n$var13\n$var14\n$var6\n$var15\n$var16\n$var17" | bash <(curl -Ls https://raw.githubusercontent.com/radkesvat/ReverseTlsTunnel/master/scripts/RtTunnel.sh)

            elif [[ "$var6" == "2" ]]; then
                var11="2"
                echo -e "$var11" | bash <(curl -Ls https://raw.githubusercontent.com/radkesvat/ReverseTlsTunnel/master/scripts/RtTunnel.sh)
                wait
                sudo rm /etc/resolv.conf
                sudo touch /etc/resolv.conf

                #change dns
                echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf
                echo "nameserver 1.0.0.1" | sudo tee -a /etc/resolv.conf
                
                #reload dns
                sudo systemd-resolve --flush-caches
                sudo systemctl restart systemd-resolved

                #options
                var12="1"
                var13="no"
                var14="5.4"
                var16="qwer"
                var17="no"
                var15=$(whiptail --inputbox "Enter the SNI Domain:" 8 39 3>&1 1>&2 2>&3)
                var18=$(whiptail --inputbox "Enter the Iran IP:" 8 39 3>&1 1>&2 2>&3)
                
                #script
                echo -e "$var12\n$var13\n$var14\n$var6\n$var15\n$var18\n$var16" | bash <(curl -Ls https://raw.githubusercontent.com/radkesvat/ReverseTlsTunnel/master/scripts/RtTunnel.sh)

            else
                whiptail --msgbox "Invalid response. Please enter 1 or 2." 8 45
            fi
            ;;
        "4")
            # Install cron if not already installed and enable it
            sudo apt install cron -y
            sudo systemctl enable cron

            # Prompt the user to enter the subdomain
            read -p "Please enter the subdomain for which you want to create an SSL certificate (e.g., subdomain.example.com): " SUBDOMAIN

            # Validate that the subdomain is not empty
            if [[ -z "$SUBDOMAIN" ]]; then
                echo "Error: Subdomain cannot be empty. Please run the script again and provide a valid subdomain."
                exit 1
            fi

            # Define directory to store certificate files
            CERT_DIR="/etc/ssl/$SUBDOMAIN"
            echo "Certificate directory: $CERT_DIR"

            # Install dependencies if not already installed
            echo "Updating packages and installing necessary dependencies..."
            sudo apt update
            sudo apt install -y certbot nginx

            # Stop any services using port 80 temporarily to allow Certbot to bind
            echo "Stopping web server temporarily to use port 80..."
            sudo systemctl stop nginx

            # Use the HTTP-01 challenge with Certbot's standalone server to issue certificate
            echo "Issuing certificate for $SUBDOMAIN using HTTP-01 challenge..."
            sudo certbot certonly --standalone --preferred-challenges http \
              --register-unsafely-without-email \
              --agree-tos \
              -d $SUBDOMAIN

            # Check if the certificate was issued successfully
            if [ $? -eq 0 ]; then
                echo "Certificate issued successfully for $SUBDOMAIN!"
            else
                echo "Error: Failed to issue certificate for $SUBDOMAIN."
                sudo systemctl start nginx   # Ensure the web server is restarted
                exit 1
            fi

            # Create SSL directory if it does not exist
            sudo mkdir -p $CERT_DIR

            # Copy the certificates to the desired directory
            echo "Copying certificate and key to $CERT_DIR..."
            sudo cp /etc/letsencrypt/live/$SUBDOMAIN/fullchain.pem $CERT_DIR/fullchain.pem
            sudo cp /etc/letsencrypt/live/$SUBDOMAIN/privkey.pem $CERT_DIR/privkey.pem

            # Restart the web server to apply the new certificates
            echo "Restarting web server..."
            sudo systemctl start nginx

            # Create the renewal script
            RENEW_SCRIPT_PATH="/etc/letsencrypt/scripts/renew.sh"
            echo "Creating renewal script at $RENEW_SCRIPT_PATH..."
            sudo mkdir -p /etc/letsencrypt/scripts

            # Create a renewal script with the correct EOF syntax
            sudo bash -c "cat > $RENEW_SCRIPT_PATH << 'EOF'
#!/bin/bash
# Renew certificate for $SUBDOMAIN using HTTP-01 challenge
certbot renew --standalone --preferred-challenges http

# Copy the renewed certificate and key to the $CERT_DIR
sudo cp /etc/letsencrypt/live/$SUBDOMAIN/fullchain.pem $CERT_DIR/fullchain.pem
sudo cp /etc/letsencrypt/live/$SUBDOMAIN/privkey.pem $CERT_DIR/privkey.pem

# Reload web server to apply new certificates
sudo systemctl reload nginx   # Replace nginx with your web server if needed
EOF"

            # Make the renewal script executable
            sudo chmod +x $RENEW_SCRIPT_PATH

            # Create a cron job for automatic renewal
            echo "Setting up cron job for automatic renewal..."
            (crontab -l 2>/dev/null; echo "0 0 * * * $RENEW_SCRIPT_PATH > /dev/null 2>&1") | crontab -

            echo "SSL certificate setup and automatic renewal complete for $SUBDOMAIN!"
            ;;

        "5")
            # Function to display error messages and exit the script
            error_exit() {
                echo "$1" 1>&2
                exit 1
            }

            # Function to check if required commands are installed
            check_dependencies() {
                for cmd in curl jq; do
                    if ! command -v $cmd &>/dev/null; then
                        error_exit "$cmd is required but not installed. Install it using: sudo apt install $cmd"
                    fi
                done
            }

            # Function to manage Cloudflare DNS
            cloudflare_dns_management() {
                # Check dependencies first
                check_dependencies

                # Prompt for Cloudflare API token, domain, and subdomain
                read -p "Enter your Cloudflare API token: " CF_API_TOKEN
                read -p "Enter your domain (example.com): " DOMAIN
                read -p "Enter your custom subdomain (e.g., api, blog): " SUBDOMAIN

                # Validate inputs
                if [[ -z "$CF_API_TOKEN" || -z "$DOMAIN" || -z "$SUBDOMAIN" ]]; then
                    error_exit "Cloudflare API token, domain, and subdomain must be provided."
                fi

                # Get the public IP of the machine (server IP)
                IP=$(curl -s https://api.ipify.org)
                if [[ -z "$IP" ]]; then
                    error_exit "Failed to retrieve your public IP address."
                fi

                echo "Your current public IP address is: $IP"

                # Fetch the zone ID for the domain
                ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
                    -H "Authorization: Bearer $CF_API_TOKEN" \
                    -H "Content-Type: application/json" | jq -r '.result[0].id')

                # Exit if no zone ID is found
                if [[ -z "$ZONE_ID" || "$ZONE_ID" == "null" ]]; then
                    error_exit "Failed to retrieve the zone ID for $DOMAIN. Please check the domain and API token."
                fi

                # Check if the DNS record for the custom subdomain exists
                RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$SUBDOMAIN.$DOMAIN" \
                    -H "Authorization: Bearer $CF_API_TOKEN" \
                    -H "Content-Type: application/json" | jq -r '.result[0].id')

                if [[ -z "$RECORD_ID" || "$RECORD_ID" == "null" ]]; then
                    # If no record exists, create a new one
                    echo "No DNS record found for $SUBDOMAIN.$DOMAIN. Creating a new DNS record..."
                    CREATE_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
                        -H "Authorization: Bearer $CF_API_TOKEN" \
                        -H "Content-Type: application/json" \
                        --data '{"type":"A","name":"'"$SUBDOMAIN.$DOMAIN"'","content":"'"$IP"'","ttl":120,"proxied":false}')

                    # Check if DNS record creation was successful
                    if echo "$CREATE_RESPONSE" | jq -r '.success' | grep -q "true"; then
                        echo "Successfully created a new DNS record for $SUBDOMAIN.$DOMAIN with IP $IP."
                    else
                        error_exit "Failed to create the DNS record. Response: $CREATE_RESPONSE"
                    fi
                else
                    # If the DNS record exists, update the existing one
                    echo "DNS record for $SUBDOMAIN.$DOMAIN exists. Updating the IP address to $IP..."
                    UPDATE_RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
                        -H "Authorization: Bearer $CF_API_TOKEN" \
                        -H "Content-Type: application/json" \
                        --data '{"type":"A","name":"'"$SUBDOMAIN.$DOMAIN"'","content":"'"$IP"'","ttl":120,"proxied":false}')

                    # Check if the update was successful
                    if echo "$UPDATE_RESPONSE" | jq -r '.success' | grep -q "true"; then
                        echo "Successfully updated the IP address for $SUBDOMAIN.$DOMAIN to $IP."
                    else
                        error_exit "Failed to update the DNS record. Response: $UPDATE_RESPONSE"
                    fi
                fi
            }

            # Run the Cloudflare DNS management function
            cloudflare_dns_management
            ;;
        "6")
            # unistall x-ui
            var31="5"
            var32="y"
            echo -e "$var31\n$var32" | x-ui
            ;;
        "7")
            # unistall tunnel
            var11="2"
            echo -e "$var11" | bash <(curl -Ls https://raw.githubusercontent.com/radkesvat/ReverseTlsTunnel/master/scripts/RtTunnel.sh)
            ;;
        "8")
            # Connectivity check
            my_ip=$(hostname -I | awk '{print $1}')
            [[ -z "$my_ip" ]] && my_ip="Unknown"
            
            # Get server location
            server_location=$(whiptail --title "Server Location" --menu "Is this server located in Iran or a foreign location?" 15 60 2 \
            "Iran" "Iran server" \
            "Foreign" "Foreign server" 3>&1 1>&2 2>&3)
            
            other_server_ip=$(whiptail --inputbox "Enter the IP address of another server (Iran or Foreign):" 10 60 3>&1 1>&2 2>&3)
            
            # Function to perform a connectivity check with ping (from project 2)
            check_connectivity() {
                if ping -c 1 -W 1 "$1" &> /dev/null; then
                    echo "Connected"
                else
                    echo "Not Connected"
                fi
            }
            
            # Perform connectivity checks
            tamin_status=$(check_connectivity "tamin.ir")
            google_status=$(check_connectivity "google.com")
            my_ip_status=$(check_connectivity "$my_ip")
            other_server_status=$(check_connectivity "$other_server_ip")
            
            # Display results
            whiptail --title "Connectivity Check Results" --msgbox "Connectivity Check Results:\n\n\
            Tamin.ir: $tamin_status\n\
            Google.com: $google_status\n\
            My IP ($my_ip): $my_ip_status\n\
            Other Server IP ($other_server_ip): $other_server_status\n\n\
            Current Server Location: $server_location" 20 70        
            ;;
        "9")
            # Exit option
            exit 0
            ;;                
        *)
            whiptail --msgbox "Invalid option selected." 10 45
            ;;
    esac
done   
