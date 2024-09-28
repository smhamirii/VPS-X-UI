#!/usr/bin/bash

# Update and upgrade system
cd
sudo apt update && sudo apt upgrade -y
wait
apt install whiptail -y
apt-get install jq

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
    var7=$(whiptail --title "VPN Creator" --menu "Welcome to VPN creator, choose an option:" 20 70 8 \
        "1" "Check Internet Connection" \
        "2" "Install X-UI" \
        "3" "Install Tunnel" \
        "4" "Install Certificate for Subdomain" \
        "5" "Cloudflare DNS Management" \
        "6" "Unistall X-UI" \
        "7" "Unistall Tunnel" \
        "8" "Exit" 3>&1 1>&2 2>&3)

    case "$var7" in
        "1")
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
        "2")
            # Install x-ui
            var1="y"
            var2="samir"
            var3="samir"
            var4="8443"
            echo -e "$var1\n$var2\n$var3\n$var4" | bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
            ;;
        "3")
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
                
                echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
                echo "nameserver 4.2.2.4" | sudo tee -a /etc/resolv.conf

                var12="1"
                var13="no"
                var14="5.4"
                var16="qwer"
                var17="no"
                var15=$(whiptail --inputbox "Enter the SNI Domain:" 8 39 3>&1 1>&2 2>&3)
                
                echo -e "$var12\n$var13\n$var14\n$var6\n$var15\n$var16\n$var17" | bash <(curl -Ls https://raw.githubusercontent.com/radkesvat/ReverseTlsTunnel/master/scripts/RtTunnel.sh)

            elif [[ "$var6" == "2" ]]; then
                var11="2"
                echo -e "$var11" | bash <(curl -Ls https://raw.githubusercontent.com/radkesvat/ReverseTlsTunnel/master/scripts/RtTunnel.sh)
                wait
                sudo rm /etc/resolv.conf
                sudo touch /etc/resolv.conf

                echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf
                echo "nameserver 1.0.0.1" | sudo tee -a /etc/resolv.conf

                var12="1"
                var13="no"
                var14="5.4"
                var16="qwer"
                var17="no"
                var15=$(whiptail --inputbox "Enter the SNI Domain:" 8 39 3>&1 1>&2 2>&3)
                var18=$(whiptail --inputbox "Enter the Iran IP:" 8 39 3>&1 1>&2 2>&3)
                
                echo -e "$var12\n$var13\n$var14\n$var6\n$var15\n$var18\n$var16" | bash <(curl -Ls https://raw.githubusercontent.com/radkesvat/ReverseTlsTunnel/master/scripts/RtTunnel.sh)

            else
                whiptail --msgbox "Invalid response. Please enter 1 or 2." 8 45
            fi
            ;;
        "4")
            # Install certificate for subdomain
            var8=$(whiptail --inputbox "Enter your subdomain:" 8 39 3>&1 1>&2 2>&3)
            sudo apt install certbot python3-certbot-nginx -y
            sudo certbot --nginx -d "$var8" --register-unsafely-without-email --agree-tos
            sudo certbot renew --dry-run
            ;;
        "5")
            # Function to manage Cloudflare DNS (from project 2)
            cloudflare_dns_management() {
                # Check if jq is installed, which is used to parse JSON
                if ! command -v jq &> /dev/null; then
                error_exit "jq is required but not installed. Install it using: sudo apt install jq"
                fi

                # Prompt for Cloudflare API token, domain, and subdomain
                read -p "Enter your Cloudflare API token: " CF_API_TOKEN
                read -p "Enter your domain (example.com): " DOMAIN
                read -p "Enter your custom subdomain (e.g., api, blog): " SUBDOMAIN

                # Get the public IP of the machine (server IP)
                IP=$(curl -s https://api.ipify.org)

                # Exit if IP is not retrieved
                if [ -z "$IP" ]; then
                error_exit "Failed to retrieve your public IP address."
                fi

                echo "Your current public IP address is: $IP"

                # Fetch the zone ID for the domain
                ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
                    -H "Authorization: Bearer $CF_API_TOKEN" \
                    -H "Content-Type: application/json" | jq -r '.result[0].id')

                # Exit if no zone ID is found
                if [ -z "$ZONE_ID" ] || [ "$ZONE_ID" == "null" ]; then
                error_exit "Failed to retrieve the zone ID for $DOMAIN. Please check the domain and API token."
                fi

                # Check if the DNS record for the custom subdomain exists
                RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$SUBDOMAIN.$DOMAIN" \
                    -H "Authorization: Bearer $CF_API_TOKEN" \
                    -H "Content-Type: application/json" | jq -r '.result[0].id')

                # If the DNS record doesn't exist, create a new one
                if [ -z "$RECORD_ID" ] || [ "$RECORD_ID" == "null" ]; then
                echo "No DNS record found for $SUBDOMAIN.$DOMAIN. Creating a new DNS record."

                CREATE_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
                    -H "Authorization: Bearer $CF_API_TOKEN" \
                    -H "Content-Type: application/json" \
                    --data '{"type":"A","name":"'"$SUBDOMAIN.$DOMAIN"'","content":"'"$IP"'","ttl":120,"proxied":false}')

                # Check if the DNS record creation was successful
                if echo "$CREATE_RESPONSE" | jq -r '.success' | grep -q "true"; then
                    echo "Successfully created a new DNS record for $SUBDOMAIN.$DOMAIN with IP $IP."
                else
                    error_exit "Failed to create the DNS record. Response: $CREATE_RESPONSE"
                fi
                else
                # If the DNS record exists, update the existing one
                echo "DNS record for $SUBDOMAIN.$DOMAIN exists. Updating the IP address."

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
        
            # Cloudflare DNS Management (from Project 2)
            cloudflare_dns_management
            ;;
        "6")
            # unistall x-ui
            var31="5"
            var32="y"
            echo -e "$var31\n$var32" | x-ui
            exit 0
            ;;
        "7")
            # unistall tunnel
            var11="2"
            echo -e "$var11" | bash <(curl -Ls https://raw.githubusercontent.com/radkesvat/ReverseTlsTunnel/master/scripts/RtTunnel.sh)
            ;;
        "8")
            # Exit option
            exit 0
            ;;                
        *)
            whiptail --msgbox "Invalid option selected." 8 45
            ;;
    esac
done   
