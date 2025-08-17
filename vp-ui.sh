#!/usr/bin/bash


backhaul_tunnel(){
    # Check if script is run as root
    if [[ $EUID -ne 0 ]]; then
        echo -e "\e[91mThis script must be run as root. Please use sudo.\e[0m"
        main_program
    fi

    # Function to install prerequisites
    install_prerequisites() {
        local os=$(uname -s)
        if [[ "$os" == "Linux" ]]; then
            whiptail --title "Installing Prerequisites" --infobox "Installing wget, curl, unzip, and tar..." 8 50
            apt update
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

        whiptail --title "Downloading Binary" --infobox "Downloading from $url..." 8 50
        curl -s -L "$url" -o "$file_name" --progress-bar

        mkdir -p /usr/local/bin/backhaul
        tar -xzf "$file_name" -C /usr/local/bin/backhaul
        rm -f "$file_name"
        whiptail --title "Success" --msgbox "Binary downloaded and extracted." 8 50
    }

    # Function to create loading bar
    loading_bar() {
        local message="$1"
        whiptail --title "Progress" --infobox "$message..." 8 50
        sleep 2
    }

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
        whiptail --title "Success" --msgbox "Server service created and started." 8 50
    }

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
        whiptail --title "Success" --msgbox "Client service created and started." 8 50
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

    # Function to configure Iran server
    backhaul_iran_server_tcpmuxmenu() {
        if [[ -d "/usr/local/bin/backhaul" ]]; then
            whiptail --title "Info" --msgbox "Backhaul already exists, skipping installation." 8 50
            return
        fi

        install_prerequisites
        download_binary

        local port_range
        port_range=$(whiptail --title "Port Range" --inputbox "Enter port range (e.g., 100-900):" 8 50 3>&1 1>&2 2>&3)

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

    # Function to configure Kharej client
    backhaul_kharej_client_tcpmuxmenu() {
        if [[ -d "/usr/local/bin/backhaul" ]]; then
            whiptail --title "Info" --msgbox "Backhaul already exists, skipping installation." 8 50
            return
        fi

        install_prerequisites
        download_binary

        local remote_addr
        remote_addr=$(whiptail --title "Remote Address" --inputbox "Enter IRAN (IPv4/IPv6):" 8 50 3>&1 1>&2 2>&3)
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

    # Function to check service status
    service_status() {
        local service_name="$1"
        local status=$(systemctl is-active "$service_name")
        if [[ "$status" == "active" ]]; then
            echo "Status: Online | Service Name: $service_name"
        else
            echo "Status: Offline | Service Name: $service_name"
        fi
    }

    # Function to get service logs
    service_logs() {
        local service_name="$1"
        local logs=$(journalctl -u "$service_name" --no-pager -n 5)
        if [[ -n "$logs" ]]; then
            echo "$logs"
        else
            echo "No entries"
        fi
    }

    # Function to get transport method
    transport_method() {
        local config_file="$1"
        local transport=$(grep '^transport' "$config_file" | cut -d '=' -f2 | tr -d ' "')
        if [[ -n "$transport" ]]; then
            echo "$transport"
        else
            echo "Unknown transport"
        fi
    }

    # Function to show status
    backhaul_single_status() {
        local output=""
        if [[ -f "/usr/local/bin/backhaul/server.toml" ]]; then
            output+="Server:\n"
            output+="$(service_status backhaul-server)\n"
            output+="Tunnel Method: $(transport_method /usr/local/bin/backhaul/server.toml)\n"
            output+="Service Logs:\n$(service_logs backhaul-server)\n\n"
        fi
        if [[ -f "/usr/local/bin/backhaul/client.toml" ]]; then
            output+="Client:\n"
            output+="$(service_status backhaul-client)\n"
            output+="Tunnel Method: $(transport_method /usr/local/bin/backhaul/client.toml)\n"
            output+="Service Logs:\n$(service_logs backhaul-client)\n"
        fi
        whiptail --title "Backhaul Status" --msgbox "$output" 20 70
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
        loading_bar "Uninstalling Iran Server"
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
        loading_bar "Uninstalling Kharej Client"
        uninstall_service backhaul-client
        delete_dir /usr/local/bin/backhaul
        delete_dir /etc/backhaul.json
        delete_dir /usr/local/bin/backhaul/client.toml
        delete_dir /etc/blackhaul
        systemctl daemon-reload
        whiptail --title "Success" --msgbox "Kharej Client uninstalled successfully." 8 50
    }

    # Function to edit server configuration
    edit_server_config() {
        local config_file="/usr/local/bin/backhaul/server.toml"
        local bind_addr=$(grep '^bind_addr' "$config_file" | cut -d '"' -f2)
        local token=$(grep '^token' "$config_file" | cut -d '"' -f2)
        local channel_size=$(grep '^channel_size' "$config_file" | cut -d '=' -f2 | tr -d ' ')
        local keepalive_period=$(grep '^keepalive_period' "$config_file" | cut -d '=' -f2 | tr -d ' ')
        local heartbeat=$(grep '^heartbeat' "$config_file" | cut -d '=' -f2 | tr -d ' ')
        local nodelay=$(grep '^nodelay' "$config_file" | cut -d '=' -f2 | tr -d ' ')
        local sniffer=$(grep '^sniffer' "$config_file" | cut -d '=' -f2 | tr -d ' ')
        local mux_con=$(grep '^mux_con' "$config_file" | cut -d '=' -f2 | tr -d ' ')
        local mux_version=$(grep '^mux_version' "$config_file" | cut -d '=' -f2 | tr -d ' ')
        local mux_framesize=$(grep '^mux_framesize' "$config_file" | cut -d '=' -f2 | tr -d ' ')
        local mux_recievebuffer=$(grep '^mux_recievebuffer' "$config_file" | cut -d '=' -f2 | tr -d ' ')
        local mux_streambuffer=$(grep '^mux_streambuffer' "$config_file" | cut -d '=' -f2 | tr -d ' ')

        while true; do
            CHOICE=$(whiptail --title "Edit Server Config" --menu "Choose an option" 20 60 12 \
                "1" "Modify Tunnel port (Current: $bind_addr)" \
                "2" "Modify token (Current: $token)" \
                "3" "Modify channel_size (Current: $channel_size)" \
                "4" "Modify keepalive_period (Current: $keepalive_period)" \
                "5" "Modify heartbeat (Current: $heartbeat)" \
                "6" "Toggle nodelay (Current: $nodelay)" \
                "7" "Toggle sniffer (Current: $sniffer)" \
                "8" "Edit/Add ports" \
                "9" "Modify mux_con (Current: $mux_con)" \
                "10" "Modify mux_version (Current: $mux_version)" \
                "11" "Modify mux_framesize (Current: $mux_framesize)" \
                "12" "Modify mux_recievebuffer (Current: $mux_recievebuffer)" \
                "13" "Modify mux_streambuffer (Current: $mux_streambuffer)" \
                "14" "Back" 3>&1 1>&2 2>&3)

            case $CHOICE in
                1)
                    new_port=$(whiptail --title "Tunnel Port" --inputbox "Enter new port (current: ${bind_addr##*:}):" 8 50 "${bind_addr##*:}" 3>&1 1>&2 2>&3)
                    sed -i "s/bind_addr = \".*\"/bind_addr = \"0.0.0.0:$new_port\"/" "$config_file"
                    systemctl restart backhaul-server
                    whiptail --title "Success" --msgbox "Tunnel port updated and service restarted." 8 50
                    ;;
                2)
                    new_token=$(whiptail --title "Token" --inputbox "Enter new token (current: $token):" 8 50 "$token" 3>&1 1>&2 2>&3)
                    sed -i "s/token = \".*\"/token = \"$new_token\"/" "$config_file"
                    systemctl restart backhaul-server
                    whiptail --title "Success" --msgbox "Token updated and service restarted." 8 50
                    ;;
                3)
                    new_channel_size=$(whiptail --title "Channel Size" --inputbox "Enter new channel_size (current: $channel_size):" 8 50 "$channel_size" 3>&1 1>&2 2>&3)
                    sed -i "s/channel_size = .*/channel_size = $new_channel_size/" "$config_file"
                    systemctl restart backhaul-server
                    whiptail --title "Success" --msgbox "Channel size updated and service restarted." 8 50
                    ;;
                4)
                    new_keepalive=$(whiptail --title "Keepalive Period" --inputbox "Enter new keepalive_period (current: $keepalive_period):" 8 50 "$keepalive_period" 3>&1 1>&2 2>&3)
                    sed -i "s/keepalive_period = .*/keepalive_period = $new_keepalive/" "$config_file"
                    systemctl restart backhaul-server
                    whiptail --title "Success" --msgbox "Keepalive period updated and service restarted." 8 50
                    ;;
                5)
                    new_heartbeat=$(whiptail --title "Heartbeat" --inputbox "Enter new heartbeat (current: $heartbeat):" 8 50 "$heartbeat" 3>&1 1>&2 2>&3)
                    sed -i "s/heartbeat = .*/heartbeat = $new_heartbeat/" "$config_file"
                    systemctl restart backhaul-server
                    whiptail --title "Success" --msgbox "Heartbeat updated and service restarted." 8 50
                    ;;
                6)
                    new_nodelay=$( [[ "$nodelay" == "true" ]] && echo "false" || echo "true" )
                    sed -i "s/nodelay = .*/nodelay = $new_nodelay/" "$config_file"
                    systemctl restart backhaul-server
                    whiptail --title "Success" --msgbox "Nodelay toggled and service restarted." 8 50
                    ;;
                7)
                    new_sniffer=$( [[ "$sniffer" == "true" ]] && echo "false" || echo "true" )
                    sed -i "s/sniffer = .*/sniffer = $new_sniffer/" "$config_file"
                    systemctl restart backhaul-server
                    whiptail --title "Success" --msgbox "Sniffer toggled and service restarted." 8 50
                    ;;
                8)
                    new_ports=$(whiptail --title "Ports" --inputbox "Enter port range (e.g., 100-900):" 8 50 3>&1 1>&2 2>&3)
                    sed -i '/ports = \[/,/]/c\ports = [\n    "'"$new_ports"'",\n]' "$config_file"
                    systemctl restart backhaul-server
                    whiptail --title "Success" --msgbox "Ports updated and service restarted." 8 50
                    ;;
                9)
                    new_mux_con=$(whiptail --title "Mux Con" --inputbox "Enter new mux_con (current: $mux_con):" 8 50 "$mux_con" 3>&1 1>&2 2>&3)
                    sed -i "s/mux_con = .*/mux_con = $new_mux_con/" "$config_file"
                    systemctl restart backhaul-server
                    whiptail --title "Success" --msgbox "Mux con updated and service restarted." 8 50
                    ;;
                10)
                    new_mux_version=$(whiptail --title "Mux Version" --inputbox "Enter new mux_version (current: $mux_version):" 8 50 "$mux_version" 3>&1 1>&2 2>&3)
                    sed -i "s/mux_version = .*/mux_version = $new_mux_version/" "$config_file"
                    systemctl restart backhaul-server
                    whiptail --title "Success" --msgbox "Mux version updated and service restarted." 8 50
                    ;;
                11)
                    new_mux_framesize=$(whiptail --title "Mux Framesize" --inputbox "Enter new mux_framesize (current: $mux_framesize):" 8 50 "$mux_framesize" 3>&1 1>&2 2>&3)
                    sed -i "s/mux_framesize = .*/mux_framesize = $new_mux_framesize/" "$config_file"
                    systemctl restart backhaul-server
                    whiptail --title "Success" --msgbox "Mux framesize updated and service restarted." 8 50
                    ;;
                12)
                    new_mux_recievebuffer=$(whiptail --title "Mux Receivebuffer" --inputbox "Enter new mux_recievebuffer (current: $mux_recievebuffer):" 8 50 "$mux_recievebuffer" 3>&1 1>&2 2>&3)
                    sed -i "s/mux_recievebuffer = .*/mux_recievebuffer = $new_mux_recievebuffer/" "$config_file"
                    systemctl restart backhaul-server
                    whiptail --title "Success" --msgbox "Mux receivebuffer updated and service restarted." 8 50
                    ;;
                13)
                    new_mux_streambuffer=$(whiptail --title "Mux Streambuffer" --inputbox "Enter new mux_streambuffer (current: $mux_streambuffer):" 8 50 "$mux_streambuffer" 3>&1 1>&2 2>&3)
                    sed -i "s/mux_streambuffer = .*/mux_streambuffer = $new_mux_streambuffer/" "$config_file"
                    systemctl restart backhaul-server
                    whiptail --title "Success" --msgbox "Mux streambuffer updated and service restarted." 8 50
                    ;;
                14)
                    return
                    ;;
                *)
                    return
                    ;;
            esac
        done
    }

    # Function to edit client configuration
    edit_client_config() {
        local config_file="/usr/local/bin/backhaul/client.toml"
        local remote_addr=$(grep '^remote_addr' "$config_file" | cut -d '"' -f2)
        local token=$(grep '^token' "$config_file" | cut -d '"' -f2)
        local connection_pool=$(grep '^connection_pool' "$config_file" | cut -d '=' -f2 | tr -d ' ')
        local keepalive_period=$(grep '^keepalive_period' "$config_file" | cut -d '=' -f2 | tr -d ' ')
        local dial_timeout=$(grep '^connection_pool' "$config_file" | cut -d '=' -f2 | tr -d ' ')
        local nodelay=$(grep '^nodelay' "$config_file" | cut -d '=' -f2 | tr -d ' ')
        local sniffer=$(grep '^sniffer' "$config_file" | cut -d '=' -f2 | tr -d ' ')
        local retry_interval=$(grep '^retry_interval' "$config_file" | cut -d '=' -f2 | tr -d ' ')
        local mux_version=$(grep '^mux_version' "$config_file" | cut -d '=' -f2 | tr -d ' ')
        local mux_framesize=$(grep '^mux_framesize' "$config_file" | cut -d '=' -f2 | tr -d ' ')
        local mux_recievebuffer=$(grep '^mux_recievebuffer' "$config_file" | cut -d '=' -f2 | tr -d ' ')
        local mux_streambuffer=$(grep '^mux_streambuffer' "$config_file" | cut -d '=' -f2 | tr -d ' ')

        while true; do
            CHOICE=$(whiptail --title "Edit Client Config" --menu "Choose an option" 20 60 11 \
                "1" "Modify Iran Server IP and port (Current: $remote_addr)" \
                "2" "Modify token (Current: $token)" \
                "3" "Modify connection_pool (Current: $connection_pool)" \
                "4" "Modify keepalive_period (Current: $keepalive_period)" \
                "5" "Modify dial_timeout (Current: $dial_timeout)" \
                "6" "Toggle nodelay (Current: $nodelay)" \
                "7" "Toggle sniffer (Current: $sniffer)" \
                "8" "Modify retry_interval (Current: $retry_interval)" \
                "9" "Modify mux_version (Current: $mux_version)" \
                "10" "Modify mux_framesize (Current: $mux_framesize)" \
                "11" "Modify mux_recievebuffer (Current: $mux_recievebuffer)" \
                "12" "Modify mux_streambuffer (Current: $mux_streambuffer)" \
                "13" "Back" 3>&1 1>&2 2>&3)

            case $CHOICE in
                1)
                    new_ip=$(whiptail --title "Iran Server IP" --inputbox "Enter new IP (current: ${remote_addr%:*}):" 8 50 "${remote_addr%:*}" 3>&1 1>&2 2>&3)
                    new_port=$(whiptail --title "Iran Server Port" --inputbox "Enter new port (current: ${remote_addr##*:}):" 8 50 "${remote_addr##*:}" 3>&1 1>&2 2>&3)
                    if [[ "$new_ip" =~ ":" && ! "$new_ip" =~ ^\[.*\]$ ]]; then
                        new_ip="[$new_ip]"
                    fi
                    sed -i "s/remote_addr = \".*\"/remote_addr = \"$new_ip:$new_port\"/" "$config_file"
                    systemctl restart backhaul-client
                    whiptail --title "Success" --msgbox "Iran Server IP and port updated and service restarted." 8 50
                    ;;
                2)
                    new_token=$(whiptail --title "Token" --inputbox "Enter new token (current: $token):" 8 50 "$token" 3>&1 1>&2 2>&3)
                    sed -i "s/token = \".*\"/token = \"$new_token\"/" "$config_file"
                    systemctl restart backhaul-client
                    whiptail --title "Success" --msgbox "Token updated and service restarted." 8 50
                    ;;
                3)
                    new_connection_pool=$(whiptail --title "Connection Pool" --inputbox "Enter new connection_pool (current: $connection_pool):" 8 50 "$connection_pool" 3>&1 1>&2 2>&3)
                    sed -i "s/connection_pool = .*/connection_pool = $new_connection_pool/" "$config_file"
                    systemctl restart backhaul-client
                    whiptail --title "Success" --msgbox "Connection pool updated and service restarted." 8 50
                    ;;
                4)
                    new_keepalive=$(whiptail --title "Keepalive Period" --inputbox "Enter new keepalive_period (current: $keepalive_period):" 8 50 "$keepalive_period" 3>&1 1>&2 2>&3)
                    sed -i "s/keepalive_period = .*/keepalive_period = $new_keepalive/" "$config_file"
                    systemctl restart backhaul-client
                    whiptail --title "Success" --msgbox "Keepalive period updated and service restarted." 8 50
                    ;;
                5)
                    new_dial_timeout=$(whiptail --title "Dial Timeout" --inputbox "Enter new dial_timeout (current: $dial_timeout):" 8 50 "$dial_timeout" 3>&1 1>&2 2>&3)
                    sed -i "s/dial_timeout = .*/dial_timeout = $new_dial_timeout/" "$config_file"
                    systemctl restart backhaul-client
                    whiptail --title "Success" --msgbox "Dial timeout updated and service restarted." 8 50
                    ;;
                6)
                    new_nodelay=$( [[ "$nodelay" == "true" ]] && echo "false" || echo "true" )
                    sed -i "s/nodelay = .*/nodelay = $new_nodelay/" "$config_file"
                    systemctl restart backhaul-client
                    whiptail --title "Success" --msgbox "Nodelay toggled and service restarted." 8 50
                    ;;
                7)
                    new_sniffer=$( [[ "$sniffer" == "true" ]] && echo "false" || echo "true" )
                    sed -i "s/sniffer = .*/sniffer = $new_sniffer/" "$config_file"
                    systemctl restart backhaul-client
                    whiptail --title "Success" --msgbox "Sniffer toggled and service restarted." 8 50
                    ;;
                8)
                    new_retry_interval=$(whiptail --title "Retry Interval" --inputbox "Enter new retry_interval (current: $retry_interval):" 8 50 "$retry_interval" 3>&1 1>&2 2>&3)
                    sed -i "s/retry_interval = .*/retry_interval = $new_retry_interval/" "$config_file"
                    systemctl restart backhaul-client
                    whiptail --title "Success" --msgbox "Retry interval updated and service restarted." 8 50
                    ;;
                9)
                    new_mux_version=$(whiptail --title "Mux Version" --inputbox "Enter new mux_version (current: $mux_version):" 8 50 "$mux_version" 3>&1 1>&2 2>&3)
                    sed -i "s/mux_version = .*/mux_version = $new_mux_version/" "$config_file"
                    systemctl restart backhaul-client
                    whiptail --title "Success" --msgbox "Mux version updated and service restarted." 8 50
                    ;;
                10)
                    new_mux_framesize=$(whiptail --title "Mux Framesize" --inputbox "Enter new mux_framesize (current: $mux_framesize):" 8 50 "$mux_framesize" 3>&1 1>&2 2>&3)
                    sed -i "s/mux_framesize = .*/mux_framesize = $new_mux_framesize/" "$config_file"
                    systemctl restart backhaul-client
                    whiptail --title "Success" --msgbox "Mux framesize updated and service restarted." 8 50
                    ;;
                11)
                    new_mux_recievebuffer=$(whiptail --title "Mux Receivebuffer" --inputbox "Enter new mux_recievebuffer (current: $mux_recievebuffer):" 8 50 "$mux_recievebuffer" 3>&1 1>&2 2>&3)
                    sed -i "s/mux_recievebuffer = .*/mux_recievebuffer = $new_mux_recievebuffer/" "$config_file"
                    systemctl restart backhaul-client
                    whiptail --title "Success" --msgbox "Mux receivebuffer updated and service restarted." 8 50
                    ;;
                12)
                    new_mux_streambuffer=$(whiptail --title "Mux Streambuffer" --inputbox "Enter new mux_streambuffer (current: $mux_streambuffer):" 8 50 "$mux_streambuffer" 3>&1 1>&2 2>&3)
                    sed -i "s/mux_streambuffer = .*/mux_streambuffer = $new_mux_streambuffer/" "$config_file"
                    systemctl restart backhaul-client
                    whiptail --title "Success" --msgbox "Mux streambuffer updated and service restarted." 8 50
                    ;;
                13)
                    return
                    ;;
                *)
                    return
                    ;;
            esac
        done
    }

    # Main menu
    while true; do
        CHOICE=$(whiptail --title "Backhaul Menu" --menu "Choose an option" 15 50 6 \
            "1" "Status" \
            "2" "Install" \
            "3" "Edit Backhaul" \
            "4" "Uninstall" \
            "5" "Restart" \
            "0" "Exit" 3>&1 1>&2 2>&3)

        case $CHOICE in
            1)
                backhaul_single_status
                ;;
            2)
                SUBCHOICE=$(whiptail --title "Single Menu" --menu "Choose an option" 12 50 3 \
                    "1" "IRAN Server" \
                    "2" "Kharej Client" \
                    "0" "Back" 3>&1 1>&2 2>&3)
                case $SUBCHOICE in
                    1)
                        backhaul_iran_server_tcpmuxmenu
                        ;;
                    2)
                        backhaul_kharej_client_tcpmuxmenu
                        ;;
                    0)
                        continue
                        ;;
                esac
                ;;
            3)
                SUBCHOICE=$(whiptail --title "Edit Backhaul" --menu "Choose an option" 12 50 3 \
                    "1" "IRAN Server" \
                    "2" "Kharej Client" \
                    "0" "Back" 3>&1 1>&2 2>&3)
                case $SUBCHOICE in
                    1)
                        edit_server_config
                        ;;
                    2)
                        edit_client_config
                        ;;
                    0)
                        continue
                        ;;
                esac
                ;;
            4)
                SUBCHOICE=$(whiptail --title "Uninstall" --menu "Choose an option" 12 50 3 \
                    "1" "IRAN Server" \
                    "2" "Kharej Client" \
                    "0" "Back" 3>&1 1>&2 2>&3)
                case $SUBCHOICE in
                    1)
                        backhaul_uninstall_single_iran
                        ;;
                    2)
                        backhaul_uninstall_single_kharej
                        ;;
                    0)
                        continue
                        ;;
                esac
                ;;
            5)
                SUBCHOICE=$(whiptail --title "Restart" --menu "Choose an option" 12 50 3 \
                    "1" "IRAN Server" \
                    "2" "Kharej Client" \
                    "0" "Back" 3>&1 1>&2 2>&3)
                case $SUBCHOICE in
                    1)
                        systemctl restart backhaul-server
                        whiptail --title "Success" --msgbox "Iran Server restarted." 8 50
                        ;;
                    2)
                        systemctl restart backhaul-client
                        whiptail --title "Success" --msgbox "Kharej Client restarted." 8 50
                        ;;
                    0)
                        continue
                        ;;
                esac
                ;;
            0)
                main_program
                ;;
        esac
    done
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

                whiptail --msgbox "Certificate revocation and cleanup complete for $SUBDOMAIN." 10 60
                ;;
            *)
                return 0
                ;;
        esac
    done
}


xui_complex(){

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
        local subdomain="$1"
        local use_cloudflare="$2"
        local cf_api_token=""
        local zone_id=""
        local record_id=""
        local original_ip=""
        local vps_ip=$(curl -s https://api.ipify.org) || error_exit "Failed to retrieve VPS IP address"

        if [[ "$use_cloudflare" == "yes" ]]; then
            # Prompt for Cloudflare API token
            cf_api_token=$(whiptail --inputbox "Enter your Cloudflare API token:" 10 60 3>&1 1>&2 2>&3)
            [[ $? -ne 0 || -z "$cf_api_token" ]] && error_exit "Cloudflare API token is required"
        fi

        # Prompt for subdomain
        subdomain=$(whiptail --inputbox "Enter your full domain (e.g., subdomain.example.com):" 10 60 3>&1 1>&2 2>&3)
        [[ $? -ne 0 || -z "$subdomain" ]] && error_exit "Domain is required"

        if [[ "$use_cloudflare" == "yes" ]]; then
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

            # Confirm before proceeding
            whiptail --yesno "Ready to proceed with certificate renewal:\n\nDomain: $subdomain\nCurrent IP: $original_ip\nVPS IP: $vps_ip\n\nContinue?" 15 60 || exit 0

            # Store original IP
            echo "$original_ip" > /tmp/original_ip_backup

            # Update DNS to VPS IP
            update_dns_record "$subdomain" "$vps_ip" "$zone_id" "$record_id" "$cf_api_token"
            whiptail --msgbox "Waiting 30 seconds for DNS propagation..." 10 60
            sleep 30
        else
            # Verify subdomain resolves to VPS IP
            resolved_ip=$(dig +short "$subdomain" | tail -n1)
            if [[ -z "$resolved_ip" || "$resolved_ip" != "$vps_ip" ]]; then
                error_exit "Subdomain $subdomain does not resolve to VPS IP $vps_ip. Please update DNS manually."
            fi
        fi

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

        if [[ "$use_cloudflare" == "yes" ]]; then
            # Let user choose final IP
            ip_choice=$(whiptail --title "Choose Final IP" --menu "Choose which IP to use after certificate renewal:" 15 60 2 \
                "1" "Restore previous IP ($original_ip)" \
                "2" "Keep current VPS IP ($vps_ip)" 3>&1 1>&2 2>&3)

            if [[ $? -ne 0 ]]; then
                whiptail --msgbox "No selection made. Using original IP ($original_ip)" 10 60
                final_ip=$original_ip
            else
                case $ip_choice in
                    1) final_ip=$original_ip ;;
                    2) final_ip=$vps_ip ;;
                esac
            fi

            # Update DNS to final IP
            update_dns_record "$subdomain" "$final_ip" "$zone_id" "$record_id" "$cf_api_token"
            rm -f /tmp/original_ip_backup
        else
            final_ip=$vps_ip
        fi

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
        whiptail --msgbox "HTTPS configuration completed!\nDomain: $subdomain\nFinal IP: $final_ip" 12 60
    }


    xui_cond=$(whiptail --title "X-UI SERVICE" --menu "X-UI SERVICE, choose an option:" 20 80 6 \
        "1" "X-UI Status" \
        "2" "Install X-UI without HTTPS" \
        "3" "Install X-UI with HTTPS (Manual DNS)" \
        "4" "Install X-UI with HTTPS (Cloudflare API)" \
        "5" "Unistall X-UI Panel" \
        "6" "Exit" 3>&1 1>&2 2>&3)

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
            install_xui
            whiptail --msgbox "X-UI installed without HTTPS configuration." 10 60
            ;;
        "3")
            install_xui
            configure_https "" "no"
            ;;
        "4")
            install_xui
            configure_https "" "yes"
            ;;
        "5")   
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
    FULL_DOMAIN=$(whiptail --inputbox "Enter your full domain (e.g., subdomain.example.com):" 10 60 3>&1 1>&2 2>&3) || return 1
    
    DOMAIN=$(echo "$FULL_DOMAIN" | sed -E 's/^[^.]+\.//')
    SUBDOMAIN=$(echo "$FULL_DOMAIN" | sed -E 's/^([^.]+).+$/\1/')

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
    whiptail --msgbox "Waiting 30 seconds for DNS propagation..." 10 60
    sleep 30

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


speed_testi(){
    # Run speedtest and capture output
    SPEED_RESULT=$(curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -)

    # Display live results in whiptail
    whiptail --title "Speed Test Results" \
            --scrolltext \
            --msgbox "$SPEED_RESULT" 20 70
}


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

    up3() {
        # Choose server location
        server_location=$(whiptail --title "Choose Server" --menu "Choose server location:" 15 60 2 \
            "1" "Iran" \
            "2" "Kharej" 3>&1 1>&2 2>&3)

        # Use case to handle server location
        case "$server_location" in
            1)
                sudo rm /etc/resolv.conf
                sudo touch /etc/resolv.conf
                echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
                echo "nameserver 4.2.2.4" | sudo tee -a /etc/resolv.conf
                whiptail --msgbox "DNS Updated" 8 45
                ;;
            2)
                sudo rm /etc/resolv.conf
                sudo touch /etc/resolv.conf
                echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf
                echo "nameserver 1.0.0.1" | sudo tee -a /etc/resolv.conf
                whiptail --msgbox "DNS Updated" 8 45
                ;;
            *)
                whiptail --msgbox "Invalid selection." 8 45
                return 1
                ;;
        esac
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


    # Use case to handle menu selection
    case "$upgrade_choose" in
        1)
            up1 && up2 && up3 && up4
            ;;
        2)
            up1
            ;;
        3)
            up2
            ;;
        4)
            up3
            ;;
        5)
            up4
            ;;
        6)
            clear
            main_program
            ;;
        *)
            whiptail --msgbox "Invalid selection." 8 45
            clear
            return 1
            ;;
    esac

    # clear screen
    clear
}


auto_ip_change() {
    # Script configuration and paths
    check_dependencies() {
        REQUIRED_PACKAGES=("jq" "curl" "whiptail" "netcat-openbsd" "network-manager")
        for pkg in "${REQUIRED_PACKAGES[@]}"; do
            if ! dpkg -s "$pkg" >/dev/null 2>&1; then
                echo "Package $pkg is not installed. Attempting to install..."
                if ! sudo apt-get update || ! sudo apt-get install -y "$pkg"; then
                    echo "Failed to install $pkg. Please install it manually and rerun the script."
                    exit 1
                fi
            fi
        done
    }
    check_dependencies

    SCRIPT_NAME="cloudflare-ddns"
    SCRIPT_PATH="/usr/local/bin/${SCRIPT_NAME}.sh"
    SERVICE_PATH="/etc/systemd/system/${SCRIPT_NAME}.service"
    CONFIG_PATH="/etc/${SCRIPT_NAME}.conf"
    STATUS_FILE="/tmp/${SCRIPT_NAME}_current_server.status"
    LOG_FILE="/var/log/${SCRIPT_NAME}.log"

    # Function to send Telegram message
    send_telegram_message() {
        local message="$1"
        local max_attempts=3
        local attempt=1

        if [ -z "$TELEGRAM_CHAT_IDS" ] || [ -z "$TELEGRAM_BOT_TOKEN" ]; then
            echo "$(date): Telegram configuration missing" >> "$LOG_FILE"
            return 1
        fi

        IFS=',' read -ra CHAT_IDS <<< "$TELEGRAM_CHAT_IDS"
        for chat_id in "${CHAT_IDS[@]}"; do
            attempt=1
            while [ $attempt -le $max_attempts ]; do
                RESPONSE=$(curl -s -m 10 "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
                    -d "chat_id=${chat_id}" \
                    -d "text=${message}" \
                    -d "parse_mode=HTML")
                
                if echo "$RESPONSE" | jq -e '.ok' > /dev/null 2>&1; then
                    echo "$(date): Telegram message sent to $chat_id" >> "$LOG_FILE"
                    break
                else
                    echo "$(date): Telegram message attempt $attempt to $chat_id failed: $RESPONSE" >> "$LOG_FILE"
                    sleep 5
                    ((attempt++))
                fi
            done
            if [ $attempt -gt $max_attempts ]; then
                echo "$(date): Failed to send Telegram message to $chat_id after $max_attempts attempts" >> "$LOG_FILE"
            fi
        done
    }

    # Load existing configuration (optional during initial setup)
    load_configuration() {
        if [ -f "$CONFIG_PATH" ]; then
            source "$CONFIG_PATH"
            return 0
        fi
        return 0
    }

    # Save configuration to a config file
    save_configuration() {
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

    # Find zone ID function
    find_zone_id() {
        ZONE_RESPONSE=$(curl -s -X GET \
            "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
            -H "Authorization: Bearer $CF_API_KEY" \
            -H "Content-Type: application/json")
        
        ZONE_ID=$(echo "$ZONE_RESPONSE" | jq -r '.result[0].id')
        
        if [ "$ZONE_ID" = "null" ] || [ -z "$ZONE_ID" ]; then
            whiptail --msgbox "Failed to find Zone ID for domain $DOMAIN. Please check if the domain exists in your Cloudflare account." 10 60
            return 1
        fi
        return 0
    }

    # Check if subdomain exists function
    check_subdomain_exists() {
        RECORD_RESPONSE=$(curl -s -X GET \
            "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$SUBDOMAIN.$DOMAIN" \
            -H "Authorization: Bearer $CF_API_KEY" \
            -H "Content-Type: application/json")
        
        RECORD_COUNT=$(echo "$RECORD_RESPONSE" | jq '.result | length')
        
        if [ "$RECORD_COUNT" = "null" ] || [ "$RECORD_COUNT" -eq 0 ]; then
            whiptail --msgbox "Error: Subdomain $SUBDOMAIN.$DOMAIN does not exist in Cloudflare. Please create it first." 10 60
            return 1
        fi
        return 0
    }

    # Get or edit configuration function
    get_configuration() {
        load_configuration

        CF_API_KEY=$(whiptail --inputbox "Enter Cloudflare API Key (current: ${CF_API_KEY:-None})" 10 60 "${CF_API_KEY:-}" 3>&1 1>&2 2>&3) || return 1    
        # Fix for extra dot: construct default value properly
        DEFAULT_DOMAIN=""
        if [ -n "$SUBDOMAIN" ] && [ -n "$DOMAIN" ]; then
            DEFAULT_DOMAIN="$SUBDOMAIN.$DOMAIN"
        fi
        FULL_DOMAIN=$(whiptail --inputbox "Enter your full domain (e.g., subdomain.example.com) (current: ${DEFAULT_DOMAIN:-None})" 10 60 "$DEFAULT_DOMAIN" 3>&1 1>&2 2>&3) || return 1
        
        DOMAIN=$(echo "$FULL_DOMAIN" | sed -E 's/^[^.]+\.//')
        SUBDOMAIN=$(echo "$FULL_DOMAIN" | sed -E 's/^([^.]+).+$/\1/')
        
        find_zone_id || return 1
        check_subdomain_exists || return 1
        
        KHAREJ_SERVER_IP=$(curl -s https://api.ipify.org)
        
        IRAN_SERVER_IP=$(whiptail --inputbox "Enter Iran Server IP (current: ${IRAN_SERVER_IP:-None})" 10 60 "${IRAN_SERVER_IP:-}" 3>&1 1>&2 2>&3) || return 1
        TELEGRAM_BOT_TOKEN=$(whiptail --inputbox "Enter Telegram Bot Token (current: ${TELEGRAM_BOT_TOKEN:-None})" 10 60 "${TELEGRAM_BOT_TOKEN:-}" 3>&1 1>&2 2>&3) || return 1
        TELEGRAM_CHAT_IDS=$(whiptail --inputbox "Enter Telegram Chat IDs (comma-separated) (current: ${TELEGRAM_CHAT_IDS:-None})" 10 60 "${TELEGRAM_CHAT_IDS:-}" 3>&1 1>&2 2>&3) || return 1
        return 0
    }

    # Create the monitoring script
    create_monitor_script() {
        sudo mkdir -p "$(dirname "$SCRIPT_PATH")"
        sudo tee "$SCRIPT_PATH" > /dev/null << 'EOF'
#!/bin/bash

CONFIG_PATH="/etc/cloudflare-ddns.conf"
LOG_FILE="/var/log/cloudflare-ddns.log"
source "$CONFIG_PATH"

CURRENT_SERVER_IP=""
FAILURE_COUNT=0
LAST_FAILURE_TIME=0
LAST_DNS_IP=""
LAST_DNS_CHECK=0
DNS_CACHE_DURATION=1800

send_telegram_notification() {
    local message="$1"
    local max_attempts=3
    local attempt=1

    if [ -z "$TELEGRAM_CHAT_IDS" ] || [ -z "$TELEGRAM_BOT_TOKEN" ]; then
        echo "$(date): Telegram configuration missing" >> "$LOG_FILE"
        return 1
    fi

    IFS=',' read -ra CHAT_IDS <<< "$TELEGRAM_CHAT_IDS"
    for chat_id in "${CHAT_IDS[@]}"; do
        attempt=1
        while [ $attempt -le $max_attempts ]; do
            RESPONSE=$(curl -s -m 10 "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
                -d "chat_id=${chat_id}" \
                -d "text=${message}" \
                -d "parse_mode=HTML")
            
            if echo "$RESPONSE" | jq -e '.ok' > /dev/null 2>&1; then
                echo "$(date): Telegram message sent to $chat_id" >> "$LOG_FILE"
                break
            else
                echo "$(date): Telegram message attempt $attempt to $chat_id failed: $RESPONSE" >> "$LOG_FILE"
                sleep 5
                ((attempt++))
            fi
        done
        if [ $attempt -gt $max_attempts ]; then
            echo "$(date): Failed to send Telegram message to $chat_id after $max_attempts attempts" >> "$LOG_FILE"
        fi
    done
}

update_dns_record() {
    local TARGET_IP=$1
    local SWITCH_REASON=$2
    
    if [ "$TARGET_IP" = "$LAST_DNS_IP" ]; then
        echo "$(date): No DNS update needed, IP unchanged: $TARGET_IP" >> "$LOG_FILE"
        return 0
    fi

    RECORD_RESPONSE=$(curl -s -X GET \
        "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$SUBDOMAIN.$DOMAIN" \
        -H "Authorization: Bearer $CF_API_KEY" \
        -H "Content-Type: application/json")
    
    RECORD_ID=$(echo "$RECORD_RESPONSE" | jq -r '.result[0].id')
    CURRENT_IP=$(echo "$RECORD_RESPONSE" | jq -r '.result[0].content')
    
    if [ "$CURRENT_IP" != "$TARGET_IP" ]; then
        UPDATE_RESPONSE=$(curl -s -X PUT \
            "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
            -H "Authorization: Bearer $CF_API_KEY" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"$SUBDOMAIN\",\"content\":\"$TARGET_IP\",\"ttl\":1,\"proxied\":false}")
        
        if echo "$UPDATE_RESPONSE" | jq -e '.success' > /dev/null; then
            NOTIFICATION_MSG="🔄 DNS Update Alert || Domain: $SUBDOMAIN.$DOMAIN || Old IP: $CURRENT_IP || New IP: $TARGET_IP || Reason: $SWITCH_REASON || Timestamp: $(TZ='Asia/Tehran' date '+%Y-%m-%d %H:%M:%S')"
            send_telegram_notification "$NOTIFICATION_MSG"
            echo "$(date): DNS updated from $CURRENT_IP to $TARGET_IP" >> "$LOG_FILE"
            CURRENT_SERVER_IP="$TARGET_IP"
            LAST_DNS_IP="$TARGET_IP"
            LAST_DNS_CHECK=$(date +%s)
        else
            echo "$(date): DNS update failed: $UPDATE_RESPONSE" >> "$LOG_FILE"
            send_telegram_notification "🚨 DNS update failed for $SUBDOMAIN.$DOMAIN: Check Cloudflare settings at $(TZ='Asia/Tehran' date '+%Y-%m-%d %H:%M:%S')"
        fi
    fi
}

check_server_status() {
    local target_ip=$1
    local max_attempts=3
    local attempt=1
    local success=false

    while [ $attempt -le $max_attempts ]; do
        if ping -c 2 -W 2 "$target_ip" > /dev/null 2>&1; then
            success=true
            break
        fi
        echo "$(date): Ping attempt $attempt to $target_ip failed" >> "$LOG_FILE"
        sleep 5
        ((attempt++))
    done

    if [ "$success" = false ]; then
        if nc -z -w 5 "$target_ip" 443 > /dev/null 2>&1; then
            success=true
            echo "$(date): TCP check to $target_ip:443 succeeded" >> "$LOG_FILE"
        else
            echo "$(date): TCP check to $target_ip:443 failed" >> "$LOG_FILE"
        fi
    fi

    [ "$success" = true ]
}

check_internet_connectivity() {
    if ping -c 2 8.8.8.8 > /dev/null 2>&1; then
        FAILURE_COUNT=0
        LAST_FAILURE_TIME=0
        return 0
    fi

    echo "$(date): Internet connectivity lost" >> "$LOG_FILE"
    ((FAILURE_COUNT++))
    
    if [ $FAILURE_COUNT -eq 1 ]; then
        LAST_FAILURE_TIME=$(date +%s)
    fi

    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$((CURRENT_TIME - LAST_FAILURE_TIME))

    if [ $FAILURE_COUNT -ge 3 ] && [ $TIME_DIFF -ge 900 ]; then
        send_telegram_notification "🌐 Internet down for 15+ minutes on $(hostname), rebooting at $(TZ='Asia/Tehran' date '+%Y-%m-%d %H:%M:%S')"
        echo "$(date): Internet down for 15+ minutes, rebooting..." >> "$LOG_FILE"
        /sbin/reboot
        return 1
    fi

    nmcli networking off && nmcli networking on
    sleep 10
    if ping -c 2 8.8.8.8 > /dev/null 2>&1; then
        send_telegram_notification "🌐 Internet restored on $(hostname) at $(TZ='Asia/Tehran' date '+%Y-%m-%d %H:%M:%S')"
        FAILURE_COUNT=0
        LAST_FAILURE_TIME=0
        return 0
    else
        send_telegram_notification "🌐 Internet restoration attempt failed on $(hostname) at $(TZ='Asia/Tehran' date '+%Y-%m-%d %H:%M:%S')"
        return 1
    fi
}

log_system_resources() {
    FREE_MEM=$(free -m | awk '/Mem:/ {print $4}')
    CPU_USAGE=$(awk -v t1=$(awk '/cpu /{print $2+$4}' /proc/stat) -v t2=$(sleep 1; awk '/cpu /{print $2+$4}' /proc/stat) 'BEGIN {printf "%.0f", (t2-t1)*100/1000}' </dev/null)
    if [ "$FREE_MEM" -lt 100 ] || [ "$CPU_USAGE" -gt 90 ]; then
        echo "$(date): Low resources detected: Free RAM=$FREE_MEM MB, CPU=$CPU_USAGE%" >> "$LOG_FILE"
        send_telegram_notification "⚠️ Low resources on $(hostname): Free RAM=$FREE_MEM MB, CPU=$CPU_USAGE% at $(TZ='Asia/Tehran' date '+%Y-%m-%d %H:%M:%S')"
    fi
}

# Telegram bot logic
process_telegram_update() {
    local update="$1"
    local update_id=$(echo "$update" | jq -r '.update_id' 2>/dev/null)
    local chat_id=$(echo "$update" | jq -r '.message.chat.id' 2>/dev/null)
    local message_text=$(echo "$update" | jq -r '.message.text' 2>/dev/null)

    if [ -z "$update_id" ] || [ -z "$chat_id" ] || [ -z "$message_text" ]; then
        echo "$(date): Skipping invalid update: $update" >> "$LOG_FILE"
        return 1
    fi

    # Check if the chat_id is authorized
    local authorized=false
    for auth_chat_id in ${TELEGRAM_CHAT_IDS//,/ }; do
        if [ "$chat_id" = "$auth_chat_id" ]; then
            authorized=true
            break
        fi
    done

    if [ "$authorized" = false ]; then
        echo "$(date): Unauthorized chat ID: $chat_id" >> "$LOG_FILE"
        return 1
    fi

    # Handle /start command
    if [ "$message_text" = "/start" ]; then
        MESSAGE="👋 <b>Welcome to Cloudflare DDNS Bot!</b>%0AUse /status to check the current server status."
        RESPONSE=$(curl -s -m 10 "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d "chat_id=${chat_id}" \
            -d "text=${MESSAGE}" \
            -d "parse_mode=HTML")
        if echo "$RESPONSE" | jq -e '.ok' > /dev/null 2>&1; then
            echo "$(date): Sent /start response to $chat_id" >> "$LOG_FILE"
        else
            echo "$(date): Failed to send /start response to $chat_id: $RESPONSE" >> "$LOG_FILE"
        fi
    fi

    # Handle /status command
    if [ "$message_text" = "/status" ]; then
        if [ $(( $(date +%s) - LAST_DNS_CHECK )) -gt $DNS_CACHE_DURATION ]; then
            RECORD_RESPONSE=$(curl -s -X GET \
                "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$SUBDOMAIN.$DOMAIN" \
                -H "Authorization: Bearer $CF_API_KEY" \
                -H "Content-Type: application/json")
            LAST_DNS_IP=$(echo "$RECORD_RESPONSE" | jq -r '.result[0].content' 2>/dev/null)
            LAST_DNS_CHECK=$(date +%s)
        fi

        if [ -n "$LAST_DNS_IP" ]; then
            if [ "$LAST_DNS_IP" = "$KHAREJ_SERVER_IP" ]; then
                SERVER_STATUS="Kharej Server ($KHAREJ_SERVER_IP)"
            elif [ "$LAST_DNS_IP" = "$IRAN_SERVER_IP" ]; then
                SERVER_STATUS="Iran Server ($IRAN_SERVER_IP)"
            else
                SERVER_STATUS="Unknown ($LAST_DNS_IP)"
            fi

            TEHRAN_TIME=$(TZ='Asia/Tehran' date '+%Y-%m-%d %H:%M:%S')
            MESSAGE="🌐 <b>Server Status</b>%0AActive: $SERVER_STATUS%0ATime (Tehran): $TEHRAN_TIME"
            RESPONSE=$(curl -s -m 10 "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
                -d "chat_id=${chat_id}" \
                -d "text=${MESSAGE}" \
                -d "parse_mode=HTML")
            if echo "$RESPONSE" | jq -e '.ok' > /dev/null 2>&1; then
                echo "$(date): Sent /status response to $chat_id" >> "$LOG_FILE"
            else
                echo "$(date): Failed to send /status response to $chat_id: $RESPONSE" >> "$LOG_FILE"
            fi
        else
            echo "$(date): Failed to retrieve DNS IP for /status" >> "$LOG_FILE"
            send_telegram_notification "⚠️ Failed to retrieve DNS IP for /status command"
        fi
    fi

    echo "$update_id"
}

telegram_loop() {
    local offset_file="/tmp/telegram_offset"
    local offset=0
    local failure_count=0
    local max_failures=5

    # Initialize offset
    if [ -f "$offset_file" ]; then
        offset=$(cat "$offset_file" 2>/dev/null || echo 0)
    fi

    while true; do
        # Fetch updates with a longer timeout for long polling
        RESPONSE=$(curl -s -m 15 "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?offset=$offset&timeout=30")

        # Check if the response is valid JSON and successful
        if ! echo "$RESPONSE" | jq -e '.ok' > /dev/null 2>&1; then
            echo "$(date): Telegram API request failed: $RESPONSE" >> "$LOG_FILE"
            ((failure_count++))
            if [ $failure_count -ge $max_failures ]; then
                echo "$(date): Too many API failures, resetting offset" >> "$LOG_FILE"
                offset=0
                failure_count=0
                echo "0" > "$offset_file"
            fi
            sleep 5
            continue
        fi

        # Reset failure count on successful API call
        failure_count=0

        # Check if there are updates
        UPDATE_COUNT=$(echo "$RESPONSE" | jq '.result | length' 2>/dev/null)
        if [ -z "$UPDATE_COUNT" ] || [ "$UPDATE_COUNT" -eq 0 ]; then
            sleep 3
            continue
        fi

        # Process each update
        LATEST_UPDATE_ID=0
        UPDATES=$(echo "$RESPONSE" | jq -c '.result[]' 2>/dev/null)
        while IFS= read -r update; do
            if [ -n "$update" ]; then
                UPDATE_ID=$(process_telegram_update "$update")
                if [ -n "$UPDATE_ID" ]; then
                    LATEST_UPDATE_ID=$((UPDATE_ID + 1))
                fi
            fi
        done <<< "$UPDATES"

        # Update the offset if we processed any updates
        if [ $LATEST_UPDATE_ID -gt 0 ]; then
            offset=$LATEST_UPDATE_ID
            echo "$offset" > "$offset_file" 2>/dev/null || echo "$(date): Failed to write offset to $offset_file" >> "$LOG_FILE"
        fi

        sleep 3
    done
}

main_loop() {
    while true; do
        log_system_resources
        check_internet_connectivity || echo "$(date): Internet check failed" >> "$LOG_FILE"
        
        if check_server_status "$IRAN_SERVER_IP"; then
            update_dns_record "$IRAN_SERVER_IP" "Iran server is reachable"
        else
            update_dns_record "$KHAREJ_SERVER_IP" "Iran server is unreachable"
        fi
        sleep 300
    done
}

telegram_loop &
main_loop
EOF
        sudo chmod +x "$SCRIPT_PATH"
    }

    # Create systemd service file
    create_service_file() {
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
        check_dependencies || return 1
        get_configuration || return 1
        save_configuration || return 1
        create_service_file || return 1

        sudo systemctl daemon-reload
        sudo systemctl enable "$SCRIPT_NAME.service"
        sudo systemctl start "$SCRIPT_NAME.service"

        whiptail --msgbox "Service installed and started successfully!" 10 60
    }

    # Uninstall service
    uninstall_service() {
        sudo systemctl stop "$SCRIPT_NAME.service"
        sudo systemctl disable "$SCRIPT_NAME.service"

        sudo rm -f "$SERVICE_PATH" "$SCRIPT_PATH" "$CONFIG_PATH"

        sudo systemctl daemon-reload

        whiptail --msgbox "Service removed successfully!" 10 60
    }

    # Enhanced status checking function
    check_current_server_status() {
        if [ ! -f "$CONFIG_PATH" ]; then
            whiptail --msgbox "Configuration file not found. Please install the service first." 10 60
            return 1
        fi

        source "$CONFIG_PATH"

        RECORD_RESPONSE=$(curl -s -X GET \
            "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$SUBDOMAIN.$DOMAIN" \
            -H "Authorization: Bearer $CF_API_KEY" \
            -H "Content-Type: application/json")
        
        CURRENT_IP=$(echo "$RECORD_RESPONSE" | jq -r '.result[0].content')

        if [ "$CURRENT_IP" = "$KHAREJ_SERVER_IP" ]; then
            SERVER_STATUS="Kharej Server ($KHAREJ_SERVER_IP)"
        elif [ "$CURRENT_IP" = "$IRAN_SERVER_IP" ]; then
            SERVER_STATUS="Iran Server ($IRAN_SERVER_IP)"
        else
            SERVER_STATUS="Unknown Server IP ($CURRENT_IP)"
        fi

        SERVICE_STATUS=$(systemctl is-active "$SCRIPT_NAME.service")
        TEHRAN_TIME=$(TZ='Asia/Tehran' date '+%Y-%m-%d %H:%M:%S')

        whiptail --title "Service Status" --msgbox "
Service State: $SERVICE_STATUS
Active Server: $SERVER_STATUS
Time (Tehran): $TEHRAN_TIME

Kharej Server IP: $KHAREJ_SERVER_IP
Iran Server IP: $IRAN_SERVER_IP
Domain: $SUBDOMAIN.$DOMAIN" 15 60
    }

    # Edit configuration function
    edit_configuration() {
        if [ ! -f "$CONFIG_PATH" ]; then
            whiptail --msgbox "Configuration file not found. Please install the service first." 10 60
            return 1
        fi
        load_configuration || return 1
        get_configuration || return 1
        save_configuration || return 1
        whiptail --msgbox "Configuration updated successfully! Restart the service for changes to take effect." 10 60
        sudo systemctl restart "$SCRIPT_NAME.service"
    }

    # Main menu for Cloudflare DDNS Management
    main_menu1() {
        while true; do
            CHOICE=$(whiptail --title "Cloudflare Dynamic DNS Management" --menu "Choose an option:" 15 60 8 \
                "1" "Install and Configure Service" \
                "2" "Start Service" \
                "3" "Stop Service" \
                "4" "Restart Service" \
                "5" "Check Service Status" \
                "6" "Remove Service" \
                "7" "Edit Configuration" \
                "8" "Exit" 3>&1 1>&2 2>&3)

            exitstatus=$?
            if [ $exitstatus != 0 ]; then
                exit 0
            fi

            case $CHOICE in
                1)
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
                    edit_configuration
                    ;;
                8)
                    exit 0
                    ;;
            esac
        done
    }

    # Start the DDNS management
    main_menu1
}


# Function to check connectivity status
get_connectivity_status() {
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
    my_ip_status=$(check_connectivity "$my_ip")

    # Output all information
    echo "Connectivity Status:"
    echo "soft98.ir: $soft98_status"
    echo "Google.com: $google_status"
    echo "My IP ($my_ip): $my_ip_status"
    echo "Country: $country"
}


usertelegram() {
    # Define paths
    LOG_FILE="/var/log/mhsanaee_bot.log"
    BOT_SCRIPT_PATH="/opt/mhsanaee-bot/mhsanaee_bot.sh"

    # Function to log messages
    log() {
        echo "$(date): $1" >> "$LOG_FILE" 2>>"$LOG_FILE"
    }

    # Check for required dependencies
    check_dependencies() {
        local deps=("curl" "jq" "whiptail" "sqlite3" "bc")
        for dep in "${deps[@]}"; do
            if ! command -v "$dep" &> /dev/null; then
                log "Error: Required dependency $dep not found"
                whiptail --msgbox "Error: Package $dep is not installed. Please install it." 8 60
                exit 1
            fi
        done
    }

    # Whiptail menu for installation, uninstallation, and editing
    show_menu() {
        CHOICE=$(whiptail --title "Mhsanaee Bot Management" --menu "Select an option" 15 60 5 \
            "1" "Install bot" \
            "2" "Uninstall bot" \
            "3" "Edit bot token" \
            "4" "Start bot" \
            "5" "Stop bot" 3>&1 1>&2 2>&3)
        
        case $CHOICE in
            1) install_bot ;;
            2) uninstall_bot ;;
            3) edit_token ;;
            4) start_bot ;;
            5) stop_bot ;;
        esac
    }

    # Function to start the bot
    start_bot() {
        if [ ! -f /etc/systemd/system/mhsanaee-bot.service ]; then
            whiptail --msgbox "Error: Bot is not installed. Please install the bot first." 8 60
            return
        fi
        systemctl start mhsanaee-bot
        if [ $? -eq 0 ]; then
            whiptail --msgbox "Bot started successfully!" 8 60
            log "Bot started successfully"
        else
            whiptail --msgbox "Error: Failed to start bot." 8 60
            log "Error: Failed to start bot"
        fi
    }

    # Function to stop the bot
    stop_bot() {
        if [ ! -f /etc/systemd/system/mhsanaee-bot.service ]; then
            whiptail --msgbox "Error: Bot is not installed." 8 60
            return
        fi
        systemctl stop mhsanaee-bot
        if [ $? -eq 0 ]; then
            whiptail --msgbox "Bot stopped successfully!" 8 60
            log "Bot stopped successfully"
        else
            whiptail --msgbox "Error: Failed to stop bot." 8 60
            log "Error: Failed to stop bot"
        fi
    }

    # Installation function
    install_bot() {
        # Ask for bot token
        BOT_TOKEN=$(whiptail --inputbox "Enter your Telegram bot token" 8 60 3>&1 1>&2 2>&3)
        if [ -z "$BOT_TOKEN" ]; then
            whiptail --msgbox "Bot token is required. Installation aborted." 8 60
            log "Installation aborted: No bot token provided"
            return
        fi

        # Create bot directory with proper permissions
        mkdir -p /opt/mhsanaee-bot
        chmod 755 /opt/mhsanaee-bot

        # Write bot script to /opt/mhsanaee-bot/mhsanaee_bot.sh
        cat << 'EOF' > "$BOT_SCRIPT_PATH"
#!/bin/bash

LOG_FILE="/var/log/mhsanaee_bot.log"

# Function to log messages
log() {
    echo "$(date): $1" >> "$LOG_FILE" 2>>"$LOG_FILE"
}

# Bot logic starts here
run_bot() {
    # Load configuration
    if ! source /opt/mhsanaee-bot/config.sh; then
        log "Error: Failed to source /opt/mhsanaee-bot/config.sh"
        exit 1
    fi

    # Check if database exists
    if [ ! -f "$DB_PATH" ]; then
        log "Error: Database file $DB_PATH not found"
        exit 1
    fi

    # Function to send Telegram message
    send_message() {
        local chat_id=$1
        local message=$2
        curl -s -X POST "$API_URL/sendMessage" \
            -d chat_id="$chat_id" \
            -d text="$message" \
            -d parse_mode="HTML" >/dev/null
        if [ $? -ne 0 ]; then
            log "Error: Failed to send message to chat_id=$chat_id"
        fi
    }

    # Function to parse VLESS config
    parse_vless_config() {
        local vless=$1
        if [[ $vless =~ vless://([a-z0-9-]{8}-[a-z0-9-]{4}-[a-z0-9-]{4}-[a-z0-9-]{4}-[a-z0-9-]{12})@[^:]+:[0-9]+(\?.*#[^[:space:]]+|#[^[:space:]]+) ]]; then
            EMAIL=$(echo "$vless" | grep -oP '#\K[^[:space:]]+' | tr '[:upper:]' '[:lower:]' | sed 's/[^-]*-//')
            echo "$EMAIL"
        else
            log "Error: Invalid VLESS config: $vless"
            echo ""
        fi
    }

    # Function to query client usage from SQLite
    get_client_usage() {
        local email=$1
        local result
        log "Debug: Querying database for email: $email"
        result=$(sqlite3 "$DB_PATH" "SELECT total, up + down AS used, expiry_time FROM client_traffics WHERE LOWER(email) = LOWER('$email');" 2>>"$LOG_FILE")
        if [ $? -ne 0 ]; then
            log "Error: SQLite query failed for email: $email"
        else
            log "Debug: Query result for email $email: $result"
        fi
        echo "$result"
    }

    # Function to format usage response in Persian
    format_usage() {
        local total=$1
        local used=$2
        local expiry=$3
        if [ -z "$total" ] || [ -z "$used" ] || [ -z "$expiry" ]; then
            log "Error: One or more usage values are empty"
            echo -e "<b>اطلاعات استفاده کانفیگ</b>\nمجموع: نامشخص\nاستفاده‌شده: نامشخص\nمانده: نامشخص\nانقضا: نامشخص\n<b>وضعیت: نامشخص</b>"
            return
        fi
        total_gb=$(echo "scale=2; $total / 1073741824" | bc | awk '{printf "%.2f", $0}')
        used_gb=$(echo "scale=2; $used / 1073741824" | bc | awk '{printf "%.2f", $0}')
        if [ "$total" -eq 0 ]; then
            remaining="نامحدود"
        else
            remaining=$(echo "scale=2; $total_gb - $used_gb" | bc | awk '{printf "%.2f", $0}')
            remaining="${remaining} گیگابایت"
        fi
        current_time=$(date +%s)
        expiry_timestamp=$((expiry / 1000))
        if [ "$total" -eq 0 ] && [ "$expiry" -eq 0 ]; then
            status="فعال"
        elif [ "$total" -eq 0 ]; then
            if [ "$expiry_timestamp" -le "$current_time" ] && [ "$expiry" -ne 0 ]; then
                status="منقضی‌شده"
            else
                status="فعال"
            fi
        elif [ "$expiry" -eq 0 ]; then
            if [ $(echo "$used > $total" | bc) -eq 1 ]; then
                status="منقضی‌شده"
            else
                status="فعال"
            fi
        else
            if [ "$expiry_timestamp" -le "$current_time" ] || [ $(echo "$used > $total" | bc) -eq 1 ]; then
                status="منقضی‌شده"
            else
                status="فعال"
            fi
        fi
        if [ "$expiry" -eq 0 ]; then
            expiry_date="بدون انقضا"
            remaining_time=""
        else
            expiry_date=$(TZ="$TEHRAN_TZ" date -d "@$expiry_timestamp" +"%Y-%m-%d %H:%M:%S (تهران)")
            remaining_days=$(( (expiry_timestamp - current_time) / 86400 ))
            remaining_time="مانده: $remaining_days روز"
        fi
        echo -e "<b>اطلاعات استفاده کانفیگ</b>\nمجموع: ${total_gb} گیگابایت\nاستفاده‌شده: ${used_gb} گیگابایت\nمانده: $remaining\nانقضا: $expiry_date\n$remaining_time\n<b>وضعیت: $status</b>"
    }

    # Function to handle commands
    handle_command() {
        local chat_id=$1
        local command=$2
        local args=$3
        case "$command" in
            "/start")
                send_message "$chat_id" "خوش آمدید به ربات تلگرام SafeNet! لطفاً پیکربندی VLESS خود را برای من فوروارد کنید تا جزئیات استفاده را نمایش دهم."
                ;;
            "/help")
                send_message "$chat_id" "دستورات موجود:\n/start - شروع ربات\nلطفاً پیکربندی VLESS خود را فوروارد کنید."
                ;;
            *)
                send_message "$chat_id" "دستور ناشناخته. لطفاً پیکربندی VLESS خود را فوروارد کنید یا از /help استفاده کنید."
                ;;
        esac
    }

    # Main loop for long polling
    OFFSET=0
    while true; do
        updates=$(curl -s -X GET "$API_URL/getUpdates?offset=$OFFSET&timeout=30")
        if [ $? -ne 0 ]; then
            log "Error: Failed to fetch updates from Telegram API"
            sleep 5
            continue
        fi
        update_ids=$(echo "$updates" | jq -r '.result[].update_id' 2>>"$LOG_FILE")
        if [ $? -ne 0 ]; then
            log "Error: jq failed to parse update_ids"
            sleep 5
            continue
        fi
        if [ -z "$update_ids" ]; then
            sleep 1
            continue
        fi
        for update_id in $update_ids
        do
            OFFSET=$((update_id + 1))
            chat_id=$(echo "$updates" | jq -r ".result[] | select(.update_id == $update_id) | .message.chat.id" 2>>"$LOG_FILE")
            if [ $? -ne 0 ]; then
                log "Error: jq failed to parse chat_id for update_id=$update_id"
                continue
            fi
            text=$(echo "$updates" | jq -r ".result[] | select(.update_id == $update_id) | .message.text // empty" 2>>"$LOG_FILE")
            if [ $? -ne 0 ]; then
                log "Error: jq failed to parse text for update_id=$update_id"
                continue
            fi
            if [[ "$text" =~ ^vless:// ]]; then
                email=$(parse_vless_config "$text")
                if [ -z "$email" ]; then
                    send_message "$chat_id" "خطا: پیکربندی VLESS نامعتبر است"
                    continue
                fi
                log "Debug: Extracted email: $email"
                result=$(get_client_usage "$email")
                if [ -z "$result" ]; then
                    send_message "$chat_id" "خطا: کانفیگ با ایمیل '$email' یافت نشد"
                    continue
                fi
                IFS='|' read -r total used expiry <<<"$result"
                if [ -z "$total" ] || [ -z "$used" ] || [ -z "$expiry" ]; then
                    log "Error: Failed to parse usage result: $result"
                    send_message "$chat_id" "خطا: امکان بازیابی جزئیات استفاده وجود ندارد"
                    continue
                fi
                response=$(format_usage "$total" "$used" "$expiry")
                send_message "$chat_id" "$response"
                continue
            fi
            if [[ "$text" =~ ^/ ]]; then
                command=$(echo "$text" | awk '{print $1}')
                args=$(echo "$text" | awk '{$1=""; print $0}' | xargs)
                handle_command "$chat_id" "$command" "$args"
            fi
        done
    done
}

# Main execution
if [ "$1" == "--run" ]; then
    log "Starting bot"
    run_bot
else
    echo "This script should only be run by the systemd service with --run argument."
    exit 1
fi
EOF
        if [ $? -ne 0 ]; then
            log "Error: Failed to write bot script to $BOT_SCRIPT_PATH"
            whiptail --msgbox "Error: Failed to write bot script." 8 60
            exit 1
        fi
        chmod +x "$BOT_SCRIPT_PATH"

        # Save bot token to config file
        echo "BOT_TOKEN=\"$BOT_TOKEN\"" > /opt/mhsanaee-bot/config.sh
        echo "API_URL=\"https://api.telegram.org/bot$BOT_TOKEN\"" >> /opt/mhsanaee-bot/config.sh
        echo "DB_PATH=\"/etc/x-ui/x-ui.db\"" >> /opt/mhsanaee-bot/config.sh
        echo "LOG_FILE=\"/var/log/mhsanaee_bot.log\"" >> /opt/mhsanaee-bot/config.sh
        echo "TEHRAN_TZ=\"Asia/Tehran\"" >> /opt/mhsanaee-bot/config.sh
        chmod 644 /opt/mhsanaee-bot/config.sh

        # Ensure log file exists with proper permissions
        touch "$LOG_FILE"
        chmod 644 "$LOG_FILE"

        # Create systemd service
        cat << EOF > /etc/systemd/system/mhsanaee-bot.service
[Unit]
Description=Mhsanaee Telegram Bot
After=network.target

[Service]
ExecStart=/bin/bash /opt/mhsanaee-bot/mhsanaee_bot.sh --run
WorkingDirectory=/opt/mhsanaee-bot
Restart=always
User=root
StandardOutput=append:/var/log/mhsanaee_bot.log
StandardError=append:/var/log/mhsanaee_bot.log
StartLimitIntervalSec=60
StartLimitBurst=10

[Install]
WantedBy=multi-user.target
EOF

        chmod 644 /etc/systemd/system/mhsanaee-bot.service
        systemctl daemon-reload
        systemctl enable mhsanaee-bot
        systemctl start mhsanaee-bot
        if [ $? -ne 0 ]; then
            log "Error: Failed to start mhsanaee-bot service"
            whiptail --msgbox "Error: Failed to start bot service." 8 60
            exit 1
        fi

        whiptail --msgbox "Bot installed and started successfully!" 8 60
        log "Bot installed and started successfully"
    }

    # Uninstallation function
    uninstall_bot() {
        if [ -f /etc/systemd/system/mhsanaee-bot.service ]; then
            systemctl stop mhsanaee-bot
            systemctl disable mhsanaee-bot
            rm -f /etc/systemd/system/mhsanaee-bot.service
            systemctl daemon-reload
        fi
        rm -rf /opt/mhsanaee-bot
        rm -f /var/log/mhsanaee_bot.log
        whiptail --msgbox "Bot uninstalled successfully!" 8 60
        log "Bot uninstalled successfully"
    }

    # Edit token function
    edit_token() {
        if [ ! -f /opt/mhsanaee-bot/config.sh ]; then
            whiptail --msgbox "Error: Bot is not installed. Cannot edit token." 8 60
            return
        fi
        CURRENT_TOKEN=$(grep BOT_TOKEN /opt/mhsanaee-bot/config.sh | cut -d'"' -f2)
        NEW_TOKEN=$(whiptail --inputbox "Enter new Telegram bot token" 8 60 "$CURRENT_TOKEN" 3>&1 1>&2 2>&3)
        if [ -n "$NEW_TOKEN" ]; then
            sed -i "s/BOT_TOKEN=\".*\"/BOT_TOKEN=\"$NEW_TOKEN\"/" /opt/mhsanaee-bot/config.sh
            sed -i "s|API_URL=\".*\"|API_URL=\"https://api.telegram.org/bot$NEW_TOKEN\"|" /opt/mhsanaee-bot/config.sh
            systemctl restart mhsanaee-bot
            if [ $? -eq 0 ]; then
                whiptail --msgbox "Bot token updated and bot restarted successfully!" 8 60
                log "Bot token updated and bot restarted"
            else
                whiptail --msgbox "Error: Failed to restart bot." 8 60
                log "Error: Failed to restart bot after token update"
            fi
        fi
    }

    # Main execution
    check_dependencies
    show_menu
}

# main program
main_program() {
    while true; do
        # main directory
        cd

        # Get connectivity status
        conn_status=$(get_connectivity_status)

        # Main menu with connectivity status
        main_obj=$(whiptail --title "SAMIR VPN Creator" --menu "Welcome to Samir VPN Creator\n\n$conn_status\n\nChoose an option:" 30 80 11 \
            "1" "X-UI SERVICE" \
            "2" "X-UI User Telegram Bot" \
            "3" "Reverse Tunnel" \
            "4" "SSL Cetificate + Change Subdomaion Custom IP" \
            "5" "Auto IP of Subdomain Change(run on kharej)" \
            "6" "Server Upgrade" \
            "7" "Speed Test" \
            "8" "Virtual RAM" \
            "9" "Change Subdomain IP" \
            "10" "SSL Certificate" \
            "11" "Exit" 3>&1 1>&2 2>&3)

        case "$main_obj" in
            "1")
                xui_complex
                ;;
            "2")
                usertelegram
                ;;
            "3")
                backhaul_tunnel
                ;;
            "4")
                certificate_complex
                ;;
            "5")
                auto_ip_change
                ;;
            "6")
                server_upgrade
                ;;
            "7")
                speed_testi
                ;;
            "8")
                virtual_ram       
                ;;
            "9")
                subdomains
                ;;
            "10")
                certificates
                ;;
            "11")
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
    sudo apt install -y python3 python3-pip sqlite3 wget whiptail lsof iptables unzip gcc git curl tar jq

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





