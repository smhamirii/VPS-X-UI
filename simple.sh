#!/usr/bin/bash


# Function to install prerequisites
install_prerequisites() {
    local os=$(uname -s)
    if [[ "$os" == "Linux" ]]; then
        apt install -y wget curl unzip tar whiptail
    else
        whiptail --title "Error" --msgbox "This script only supports Linux." 8 50
        main_program
    fi
}


# Function to download binary
download_binary() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    local url=""
    local file_name="/tmp/backhaul.tar.gz"

    case "$os-$arch" in
        "linux-x86_64")
            url="https://github.com/Musixal/Backhaul/releases/download/v0.6.3/backhaul_linux_amd64.tar.gz"
            ;;
        "linux-aarch64")
            url="https://github.com/Musixal/Backhaul/releases/download/v0.6.3/backhaul_linux_arm64.tar.gz"
            ;;
        *)
            whiptail --title "Error" --msgbox "Unsupported OS or architecture." 8 50
            main_program
            ;;
    esac

    curl -s -L "$url" -o "$file_name" --progress-bar

    mkdir -p /usr/local/bin/backhaul
    tar -xzf "$file_name" -C /usr/local/bin/backhaul
    rm -f "$file_name"
}


# Function to uninstall service
uninstall_service() {
    local service_name="$1"
    systemctl stop "$service_name" >/dev/null 2>&1
    systemctl disable "$service_name" >/dev/null 2>&1
    rm -f "/etc/systemd/system/$service_name.service"
}


# Function to delete directory or file
delete_dir() {
    local path="$1"
    if [[ -e "$path" ]]; then
        if [[ -d "$path" ]]; then
            rm -rf "$path"
        else
            rm -f "$path"
        fi
    fi
}



# Function to uninstall Iran server
backhaul_uninstall_single_iran() {
    uninstall_service backhaul-server
    delete_dir /usr/local/bin/backhaul
    delete_dir /etc/backhaul.json
    delete_dir /usr/local/bin/backhaul/server.toml
    delete_dir /etc/blackhaul
    systemctl daemon-reload
    whiptail --title "Success" --msgbox "Iran Server uninstalled successfully." 8 50
}


# Function to uninstall Kharej client
backhaul_uninstall_single_kharej() {
    # Unistall X-UI confiramtion
    if whiptail --title "Delete Confirmation" --yesno "Are you sure you want to delete?" 10 60; then
        var31="5"
        var32="y"
        echo -e "$var31\n$var32" | x-ui                    
    else
        main_program
    fi     
    uninstall_service backhaul-client
    delete_dir /usr/local/bin/backhaul
    delete_dir /etc/backhaul.json
    delete_dir /usr/local/bin/backhaul/client.toml
    delete_dir /etc/blackhaul
    systemctl daemon-reload
    whiptail --title "Success" --msgbox "Kharej Client uninstalled successfully." 8 50
}



edit_iran() {
    
    local config_file="/usr/local/bin/backhaul/server.toml"
    new_ports=$(whiptail --title "Ports" --inputbox "Enter port range (e.g., 100-900):" 8 50 3>&1 1>&2 2>&3)
    sed -i '/ports = \[/,/]/c\ports = [\n    "'"$new_ports"'",\n]' "$config_file"
    systemctl restart backhaul-server
    whiptail --title "Success" --msgbox "Ports updated and service restarted." 8 50      
}
            


edit_kharej() {

    local config_file="/usr/local/bin/backhaul/client.toml"
    local remote_addr=$(grep '^remote_addr' "$config_file" | cut -d '"' -f2)
    new_port=${remote_addr##*:}

    local vps_ip=$(curl -s https://api.ipify.org) || error_exit "Failed to retrieve VPS IP address"
    local cf_api_token=$(whiptail --inputbox "Enter your Cloudflare API token:" 8 50 3>&1 1>&2 2>&3)
    local subdomain=$(whiptail --inputbox "Enter your full domain (e.g., subdomain.example.com):" 8 50 3>&1 1>&2 2>&3)
    local remote_addr=$(whiptail --title "Remote Address" --inputbox "Enter IRAN (IPv4/IPv6):" 8 50 3>&1 1>&2 2>&3)


    # Function to check or create DNS record
    check_or_create_dns_record() {
        local full_domain="$1"
        local ip="$2"
        local zone_id="$3"
        local cf_token="$4"

        local record_info=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?name=$full_domain" \
            -H "Authorization: Bearer $cf_token" \
            -H "Content-Type: application/json")
        
        local record_exists=$(echo "$record_info" | jq -r '.result | length')

        if [ "$record_exists" -eq 0 ]; then
            local create_response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
                -H "Authorization: Bearer $cf_token" \
                -H "Content-Type: application/json" \
                --data '{"type":"A","name":"'"$full_domain"'","content":"'"$ip"'","ttl":120,"proxied":false}')

            if ! echo "$create_response" | jq -r '.success' | grep -q "true"; then
                error_exit "Failed to create DNS record"
            fi
            
            record_info=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?name=$full_domain" \
                -H "Authorization: Bearer $cf_token" \
                -H "Content-Type: application/json")
        fi

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


    # Function to configure HTTPS
    configure_https() {
        local use_cloudflare="$2"
        local zone_id=""
        local record_id=""
        local original_ip=""

        [[ $? -ne 0 || -z "$cf_api_token" ]] && error_exit "Cloudflare API token is required"
        
        # Prompt for subdomain
        [[ $? -ne 0 || -z "$subdomain" ]] && error_exit "Domain is required"
        
        # Extract main domain
        domain=$(echo "$subdomain" | awk -F '.' '{print $(NF-1)"."$NF}')
        [[ -z "$domain" ]] && error_exit "Failed to extract main domain"

        # Get zone ID
        zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$domain" \
            -H "Authorization: Bearer $cf_api_token" \
            -H "Content-Type: application/json" | jq -r '.result[0].id')
        [[ -z "$zone_id" || "$zone_id" == "null" ]] && error_exit "Failed to retrieve zone ID"

        # Check or create DNS record
        record_info=$(check_or_create_dns_record "$subdomain" "$remote_addr" "$zone_id" "$cf_api_token")
        record_id=$(echo "$record_info" | cut -d' ' -f1)

        # Update DNS to VPS IP
        update_dns_record "$subdomain" "$remote_addr" "$zone_id" "$record_id" "$cf_api_token"
    }
    configure_https
    
    new_ip=$remote_addr

    if [[ "$new_ip" =~ ":" && ! "$new_ip" =~ ^\[.*\]$ ]]; then
        new_ip="[$new_ip]"
    fi
    sed -i "s/remote_addr = \".*\"/remote_addr = \"$new_ip:$new_port\"/" "$config_file"
    systemctl restart backhaul-client
    whiptail --title "Success" --msgbox "Iran Server IP and port updated and service restarted." 8 50 
    
}


install_iran_server() {

    # Enable BBR by adding it to sysctl configuration
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf

    # Apply the changes immediately
    sudo sysctl -p

    local port_range
    port_range=$(whiptail --title "Port Range" --inputbox "Enter port range (e.g., 100-900):" 8 50 3>&1 1>&2 2>&3)

    # Function to create server service
    create_singleserver_service() {
        cat << EOF > /etc/systemd/system/backhaul-server.service
[Unit]
Description=Backhaul Reverse Tunnel Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/backhaul/backhaul -c /usr/local/bin/backhaul/server.toml
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable backhaul-server.service
        systemctl start backhaul-server.service
    }

    # Function to enable server reset
    enable_backhaul_reset_server() {
        local interval=21600
        cat << EOF > /usr/local/bin/backhaul_daemon.sh
#!/bin/bash
INTERVAL=$interval

while true; do
    /bin/bash /etc/backhaul_reset.sh
    sleep \$INTERVAL
done
EOF
        chmod +x /usr/local/bin/backhaul_daemon.sh

        cat << EOF > /etc/systemd/system/backhaul_reset.service
[Unit]
Description=Custom Daemon

[Service]
ExecStart=/usr/local/bin/backhaul_daemon.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

        cat << EOF > /etc/backhaul_reset.sh
#!/bin/bash
systemctl daemon-reload 
systemctl restart backhaul-server 
journalctl --vacuum-size=1M --unit=backhaul-server.service
EOF
        chmod +x /etc/backhaul_reset.sh

        systemctl daemon-reload
        systemctl enable backhaul_reset.service
        systemctl restart backhaul_reset.service
    }    


    # Function to configure Iran server
    backhaul_iran_server_tcpmuxmenu() {
        if [[ -d "/usr/local/bin/backhaul" ]]; then
            whiptail --title "Info" --msgbox "Backhaul already exists, skipping installation." 8 50
            return
        fi

        install_prerequisites
        download_binary

        cat << EOF > /usr/local/bin/backhaul/server.toml
[server]
bind_addr = "0.0.0.0:23123"
transport = "tcpmux"
token = "samirkala"
keepalive_period = 75
nodelay = false
channel_size = 2048
heartbeat = 40
mux_con = 8
mux_version = 1
mux_framesize = 32768
mux_recievebuffer = 4194304
mux_streambuffer = 65536
sniffer = false
sniffer_log = ""
web_port = 0
log_level = "info"
ports = [
    "$port_range",
]
EOF
        create_singleserver_service
        enable_backhaul_reset_server
        whiptail --title "Success" --msgbox "Iran server configured successfully." 8 50
    }
    
    backhaul_iran_server_tcpmuxmenu

}



install_kharej_server() {

    # Enable BBR by adding it to sysctl configuration
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf

    # Apply the changes immediately
    sudo sysctl -p

    local vps_ip=$(curl -s https://api.ipify.org) || error_exit "Failed to retrieve VPS IP address"
    local cf_api_token=$(whiptail --inputbox "Enter your Cloudflare API token:" 8 50 3>&1 1>&2 2>&3)
    local subdomain=$(whiptail --inputbox "Enter your full domain (e.g., subdomain.example.com):" 8 50 3>&1 1>&2 2>&3)
    local remote_addr=$(whiptail --title "Remote Address" --inputbox "Enter IRAN (IPv4/IPv6):" 8 50 3>&1 1>&2 2>&3)
            
    # Confirm before proceeding
    whiptail --yesno "Ready to proceed:\n\nDomain: $subdomain\nIran IP: $remote_addr\nVPS IP: $vps_ip\n\nContinue?" 15 60 || exit 0


    # Function to create client service
    create_singleclient_service() {
        cat << EOF > /etc/systemd/system/backhaul-client.service
[Unit]
Description=Backhaul Reverse Tunnel Client Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/backhaul/backhaul -c /usr/local/bin/backhaul/client.toml
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable backhaul-client.service
        systemctl restart backhaul-client.service
    }



    # Function to enable client reset
    enable_backhaul_reset_client() {
        local interval=21600
        cat << EOF > /usr/local/bin/backhaul_daemon.sh
#!/bin/bash
INTERVAL=$interval

while true; do
    /bin/bash /etc/backhaul_reset.sh
    sleep \$INTERVAL
done
EOF
        chmod +x /usr/local/bin/backhaul_daemon.sh

        cat << EOF > /etc/systemd/system/backhaul_reset.service
[Unit]
Description=Custom Daemon

[Service]
ExecStart=/usr/local/bin/backhaul_daemon.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

        cat << EOF > /etc/backhaul_reset.sh
#!/bin/bash
systemctl daemon-reload 
systemctl restart backhaul-client 
journalctl --vacuum-size=1M --unit=backhaul-client.service
EOF
        chmod +x /etc/backhaul_reset.sh

        systemctl daemon-reload
        systemctl enable backhaul_reset.service
        systemctl restart backhaul_reset.service
    }



    # Function to configure Kharej client
    backhaul_kharej_client_tcpmuxmenu() {
        if [[ -d "/usr/local/bin/backhaul" ]]; then
            whiptail --title "Info" --msgbox "Backhaul already exists, skipping installation." 8 50
            return
        fi

        install_prerequisites
        download_binary

        if [[ "$remote_addr" =~ ":" && ! "$remote_addr" =~ ^\[.*\]$ ]]; then
            remote_addr="[$remote_addr]"
        fi
        remote_addr_with_port="$remote_addr:23123"

        cat << EOF > /usr/local/bin/backhaul/client.toml
[client]
remote_addr = "$remote_addr_with_port"
transport = "tcpmux"
token = "samirkala"
connection_pool = 8
aggressive_pool = false
keepalive_period = 75
dial_timeout = 10
nodelay = false
retry_interval = 3
mux_version = 1
mux_framesize = 32768
mux_recievebuffer = 4194304
mux_streambuffer = 65536
sniffer = false
sniffer_log = "/etc/backhaul_client1.json"
web_port = 0
log_level = "info"
EOF
        create_singleclient_service
        enable_backhaul_reset_client
        whiptail --title "Success" --msgbox "Kharej client configured successfully." 8 50
    }                                                                                                      

    
    xui_complex() {

        # Function to determine architecture
        arch() {
            case "$(uname -m)" in
                x86_64 | x64 | amd64) echo 'amd64' ;;
                i*86 | x86) echo '386' ;;
                armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
                armv7* | armv7 | arm) echo 'armv7' ;;
                armv6* | armv6) echo 'armv6' ;;
                armv5* | armv5) echo 'armv5' ;;
                s390x) echo 's390x' ;;
                *) whiptail --msgbox "Unsupported CPU architecture!" 10 60; exit 1 ;;
            esac
        }

        # Error handling function
        error_exit() {
            whiptail --msgbox "Error: $1" 10 60
            exit 1
        }

        # Function to install X-UI (common steps)
        install_xui() {
            # Install requirements
            apt-get update
            apt-get install -y -q wget curl tar tzdata sqlite3 jq || error_exit "Failed to install required packages"

            # Change directory
            cd /usr/local/ || error_exit "Failed to change to /usr/local/"

            # Download X-UI
            url="https://github.com/MHSanaei/3x-ui/releases/download/v2.6.0/x-ui-linux-$(arch).tar.gz"
            wget -N --no-check-certificate -O /usr/local/x-ui-linux-$(arch).tar.gz "$url" || error_exit "Failed to download X-UI"

            # Remove existing X-UI installation if present
            if [[ -e /usr/local/x-ui/ ]]; then
                systemctl stop x-ui 2>/dev/null
                rm -rf /usr/local/x-ui/
            fi

            # Extract and clean up
            tar zxvf x-ui-linux-$(arch).tar.gz || error_exit "Failed to extract X-UI"
            rm -f x-ui-linux-$(arch).tar.gz
            cd x-ui || error_exit "Failed to change to x-ui directory"
            chmod +x x-ui

            # Handle architecture-specific binary
            if [[ $(arch) == "armv5" || $(arch) == "armv6" || $(arch) == "armv7" ]]; then
                mv bin/xray-linux-$(arch) bin/xray-linux-arm
                chmod +x bin/xray-linux-arm
            fi

            chmod +x x-ui bin/xray-linux-$(arch)
            cp -f x-ui.service /etc/systemd/system/ || error_exit "Failed to copy x-ui.service"
            wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/MHSanaei/3x-ui/main/x-ui.sh || error_exit "Failed to download x-ui.sh"
            chmod +x /usr/local/x-ui/x-ui.sh /usr/bin/x-ui

            # Set default settings
            /usr/local/x-ui/x-ui setting -username "samir" -password "samir" -port "2096" -webBasePath "" || error_exit "Failed to set X-UI settings"
            /usr/local/x-ui/x-ui migrate || error_exit "Failed to migrate X-UI database"

            # Reload and start services
            systemctl daemon-reload
            systemctl enable x-ui
            systemctl start x-ui || error_exit "Failed to start X-UI"
            cd
        }

        # Function to check or create DNS record
        check_or_create_dns_record() {
            local full_domain="$1"
            local ip="$2"
            local zone_id="$3"
            local cf_token="$4"

            local record_info=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?name=$full_domain" \
                -H "Authorization: Bearer $cf_token" \
                -H "Content-Type: application/json")
            
            local record_exists=$(echo "$record_info" | jq -r '.result | length')

            if [ "$record_exists" -eq 0 ]; then
                local create_response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
                    -H "Authorization: Bearer $cf_token" \
                    -H "Content-Type: application/json" \
                    --data '{"type":"A","name":"'"$full_domain"'","content":"'"$ip"'","ttl":120,"proxied":false}')

                if ! echo "$create_response" | jq -r '.success' | grep -q "true"; then
                    error_exit "Failed to create DNS record"
                fi
                
                record_info=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?name=$full_domain" \
                    -H "Authorization: Bearer $cf_token" \
                    -H "Content-Type: application/json")
            fi

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

        # Function to configure HTTPS
        configure_https() {

            local use_cloudflare="$2"

            local zone_id=""
            local record_id=""
            local original_ip=""

        
            [[ $? -ne 0 || -z "$cf_api_token" ]] && error_exit "Cloudflare API token is required"
           

            # Prompt for subdomain
            [[ $? -ne 0 || -z "$subdomain" ]] && error_exit "Domain is required"

            
            # Extract main domain
            domain=$(echo "$subdomain" | awk -F '.' '{print $(NF-1)"."$NF}')
            [[ -z "$domain" ]] && error_exit "Failed to extract main domain"

            # Get zone ID
            zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$domain" \
                -H "Authorization: Bearer $cf_api_token" \
                -H "Content-Type: application/json" | jq -r '.result[0].id')
            [[ -z "$zone_id" || "$zone_id" == "null" ]] && error_exit "Failed to retrieve zone ID"

            # Check or create DNS record
            record_info=$(check_or_create_dns_record "$subdomain" "$vps_ip" "$zone_id" "$cf_api_token")
            record_id=$(echo "$record_info" | cut -d' ' -f1)
            original_ip=$(echo "$record_info" | cut -d' ' -f2)

            # Store original IP
            echo "$original_ip" > /tmp/original_ip_backup

            # Update DNS to VPS IP
            update_dns_record "$subdomain" "$vps_ip" "$zone_id" "$record_id" "$cf_api_token"
            whiptail --msgbox "Waiting 30 seconds for DNS propagation..." 10 60
            sleep 30


            # Install certbot and nginx
            apt install -y certbot nginx || error_exit "Failed to install certbot and nginx"

            # Stop nginx
            systemctl stop nginx || error_exit "Failed to stop nginx"

            # Request certificate
            certbot certonly --standalone --preferred-challenges http \
                --register-unsafely-without-email \
                --agree-tos \
                -d "$subdomain" || error_exit "Failed to obtain certificate"
            
            # Start nginx
            systemctl start nginx || error_exit "Failed to start nginx"


            final_ip=$remote_addr
            

            # Update X-UI database with certificate paths
            web_cert_file="/etc/letsencrypt/live/$subdomain/fullchain.pem"
            web_key_file="/etc/letsencrypt/live/$subdomain/privkey.pem"
            db_path="/etc/x-ui/x-ui.db"

            if [[ ! -f "$db_path" ]]; then
                error_exit "x-ui.db not found at $db_path"
            fi

            if [[ ! -f "$web_cert_file" || ! -f "$web_key_file" ]]; then
                error_exit "Certificate files not found for $subdomain"
            fi

            cp "$db_path" "$db_path.bak"
            sqlite3 "$db_path" <<EOF
INSERT INTO settings (key, value) VALUES ('webCertFile', '$web_cert_file');
INSERT INTO settings (key, value) VALUES ('webKeyFile', '$web_key_file');
EOF

            systemctl restart x-ui || error_exit "Failed to restart X-UI"
        }

        install_xui
        configure_https

    }

    xui_complex
    backhaul_kharej_client_tcpmuxmenu    
    
}


# Function to check connectivity status
get_connectivity_status() {

    if [[ -d "/usr/local/bin/backhaul" ]]; then
        info_tun="exists!"
    else
        info_tun="not exists!"
    fi

    if [ -f "/usr/bin/x-ui" ]; then
        info_xui="exists!"
    else
        info_xui="not exist!"
    fi     

    check_connectivity() {
        ping_output=$(ping -c 1 -W 1 "$1" 2>&1)
        if echo "$ping_output" | grep -q "1 received"; then
            ping_time=$(echo "$ping_output" | grep "time=" | awk -F'time=' '{print $2}' | awk '{print $1}')
            echo "Connected (Ping: ${ping_time} ms)"
        else
            echo "Not Connected"
        fi
    }

    # Get local IP
    my_ip=$(hostname -I | awk '{print $1}')
    [[ -z "$my_ip" ]] && my_ip="Unknown"

    # Get country
    response=$(curl -s "http://ip-api.com/json/$my_ip")
    country=$(echo "$response" | jq -r '.country' || echo "Unknown")

    # Check connectivity for multiple sites
    soft98_status=$(check_connectivity "soft98.ir")
    google_status=$(check_connectivity "google.com")

    # Output all information
    echo "Connectivity Status:"
    echo "soft98.ir: $soft98_status"
    echo "Google.com: $google_status"
    echo "My IP $my_ip"
    echo "Country: $country"
    echo "XUI Panel: $info_xui"
    echo "Tunnel: $info_tun"
}


iran_server() {

    SUBCHOICE=$(whiptail --title "Iran Server" --menu "Choose an option:" 15 60 5 \
        "1" "Install" \
        "2" "Change config ports" \
        "3" "Restart tunnel" \
        "4" "Unistall" \
        "0" "Exit" 3>&1 1>&2 2>&3)
    case $SUBCHOICE in
        1)
            install_iran_server
            ;;
        2)
            edit_iran
            ;;
        3)
            systemctl restart backhaul-server            
            ;;
        4)
            backhaul_uninstall_single_iran
            ;;            
        0)
            exit
            ;;
    esac
}


kharej_server() {

    SUBCHOICE=$(whiptail --title "Kharej Server" --menu "Choose an option:" 15 60 5 \
        "1" "Install" \
        "2" "Change Iran server" \
        "3" "Restart tunnel" \
        "4" "Unistall" \
        "0" "Exit" 3>&1 1>&2 2>&3)
    case $SUBCHOICE in
        1)
            install_kharej_server            
            ;;
        2)
            edit_kharej
            ;;
        3)
            systemctl restart backhaul-client     
            ;;
        4)
            backhaul_uninstall_single_kharej
            ;;
        0)
            exit
            ;;
    esac
}


main_program() {

    # main directory
    cd

    # Get connectivity status
    conn_status=$(get_connectivity_status)

    SUBCHOICE=$(whiptail --title "Samir Vpn Creator" --menu "Welcome to Samir VPN Creator\n\n$conn_status\n\nChoose server s location" 20 60 3 \
        "1" "IRAN Server" \
        "2" "Kharej server" \
        "0" "Exit" 3>&1 1>&2 2>&3)
    case $SUBCHOICE in
        1)
            iran_server
            ;;
        2)
            kharej_server
            ;;
        0)
            exit
            ;;
    esac
}

# kill all apt
sudo killall apt apt-get

# update
sudo apt --fix-broken install
sudo apt clean
sudo dpkg --configure -a

# main update
sudo apt update

# install necessary packages
sudo apt install -y sqlite3 wget whiptail lsof iptables unzip gcc git curl tar jq

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
          






   
           



