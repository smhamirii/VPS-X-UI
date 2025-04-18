#!/usr/bin/bash


mainreverse() {
    # Colors for console output
    red='\033[0;31m'
    green='\033[0;32m'
    yellow='\033[1;33m'
    purple='\033[0;35m'
    cyan='\033[0;36m'
    blue='\033[0;34m'
    rest='\033[0m'

    # Detect the Linux distribution
    detect_distribution() {
        if [ -f /etc/os-release ]; then
            source /etc/os-release
            case "${ID}" in
            ubuntu | debian)
                p_m="apt-get"
                ;;
            centos)
                p_m="yum"
                ;;
            fedora)
                p_m="dnf"
                ;;
            *)
                whiptail --title "Error" --msgbox "Unsupported distribution!" 8 40
                main_program
                ;;
            esac
        else
            whiptail --title "Error" --msgbox "Unsupported distribution!" 8 40
            main_program
        fi
    }

    # Install Dependencies
    check_dependencies() {
        detect_distribution

        local dependencies
        dependencies=("wget" "curl" "unzip" "socat" "jq")

        for dep in "${dependencies[@]}"; do
            if ! command -v "${dep}" &>/dev/null; then
                whiptail --title "Installing Dependency" --msgbox "${dep} is not installed. Installing..." 8 40
                sudo "${p_m}" install "${dep}" -y
            fi
        done
    }

    # Check and install Waterwall
    install_waterwall() {
        LATEST_RELEASE=$(curl --silent "https://api.github.com/repos/radkesvat/WaterWall/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
        INSTALL_DIR="/root/Waterwall"
        FILE_NAME="Waterwall"

        if [ ! -f "$INSTALL_DIR/$FILE_NAME" ]; then
            check_dependencies
            whiptail --title "Installing Waterwall" --msgbox "Installing Waterwall...\nLatest version: ${LATEST_RELEASE}" 10 50

            if [ -z "$LATEST_RELEASE" ]; then
                whiptail --title "Error" --msgbox "Failed to get the latest release version." 8 40
                return 1
            fi

            # Determine the download URL based on the architecture
            ARCH=$(uname -m)
            if [ "$ARCH" == "x86_64" ]; then
                DOWNLOAD_URL="https://github.com/radkesvat/WaterWall/releases/download/${LATEST_RELEASE}/Waterwall-linux-64.zip"
            elif [ "$ARCH" == "aarch64" ]; then
                DOWNLOAD_URL="https://github.com/radkesvat/WaterWall/releases/download/${LATEST_RELEASE}/Waterwall-linux-arm64.zip"
            else
                whiptail --title "Error" --msgbox "Unsupported architecture: $ARCH" 8 40
                return 1
            fi

            # Create the installation directory if it doesn't exist
            mkdir -p "$INSTALL_DIR"

            # Download the ZIP file directly into INSTALL_DIR
            ZIP_FILE="$INSTALL_DIR/Waterwall.zip"
            curl -L -o "$ZIP_FILE" "$DOWNLOAD_URL"
            if [ $? -ne 0 ]; then
                whiptail --title "Error" --msgbox "Download failed." 8 40
                return 1
            fi

            # Unzip the downloaded file directly into INSTALL_DIR
            unzip "$ZIP_FILE" -d "$INSTALL_DIR" >/dev/null 2>&1
            if [ $? -ne 0 ]; then
                whiptail --title "Error" --msgbox "Unzip failed." 8 40
                rm -f "$ZIP_FILE"
                return 1
            fi

            rm -f "$ZIP_FILE"

            # Set executable permission for Waterwall binary
            sudo chmod +x "$INSTALL_DIR/$FILE_NAME"
            if [ $? -ne 0 ]; then
                whiptail --title "Error" --msgbox "Failed to set executable permission for Waterwall." 8 40
                return 1
            fi

            whiptail --title "Success" --msgbox "Waterwall installed successfully in $INSTALL_DIR." 8 50
            return 0
        fi
    }

    # Create core.json
    create_core_json() {
        if [ ! -d /root/Waterwall ]; then
            mkdir -p /root/Waterwall
        fi

        if [ ! -f ~/Waterwall/core.json ]; then
            whiptail --title "Creating core.json" --msgbox "Creating core.json..." 8 40
            cat <<EOF >~/Waterwall/core.json
{
    "log": {
        "path": "log/",
        "core": {
            "loglevel": "DEBUG",
            "file": "core.log",
            "console": true
        },
        "network": {
            "loglevel": "DEBUG",
            "file": "network.log",
            "console": true
        },
        "dns": {
            "loglevel": "SILENT",
            "file": "dns.log",
            "console": false
        }
    },
    "dns": {},
    "misc": {
        "workers": 0,
        "ram-profile": "server",
        "libs-path": "libs/"
    },
    "configs": [
        "config.json"
    ]
}
EOF
        fi
    }

    # Check Waterwall status
    check_waterwall_status() {
        sleep 1
        if sudo systemctl is-active --quiet Waterwall.service; then
            whiptail --title "Status" --msgbox "Waterwall Installed successfully: [running ✔]" 8 50
        else
            whiptail --title "Status" --msgbox "Waterwall is not installed or [Not running ✗]" 8 50
        fi
    }

    # Create Service
    waterwall_service() {
        create_core_json
        cat <<EOL >/etc/systemd/system/Waterwall.service
[Unit]
Description=Waterwall Tunnel Service
After=network.target

[Service]
Type=idle
User=root
WorkingDirectory=/root/Waterwall
ExecStart=/root/Waterwall/Waterwall
Restart=always

[Install]
WantedBy=multi-user.target
EOL

        sudo systemctl daemon-reload
        sudo systemctl enable Waterwall.service
        sudo systemctl restart Waterwall.service >/dev/null 2>&1
        check_waterwall_status
    }

    # Reality Reverse Tunnel
    reality_reverse() {
        create_reverse_reality_server_multiport_iran() {
            start_port=$(whiptail --title "Input" --inputbox "Enter the starting local port [greater than 23]:" 8 40 3>&1 1>&2 2>&3)
            [ $? -ne 0 ] && return
            end_port=$(whiptail --title "Input" --inputbox "Enter the ending local port [less than 65535]:" 8 40 3>&1 1>&2 2>&3)
            [ $? -ne 0 ] && return
            remote_address=$(whiptail --title "Input" --inputbox "Enter the kharej address:" 8 40 3>&1 1>&2 2>&3)
            [ $? -ne 0 ] && return
            sni=google.com
            passwd=samiri

            install_waterwall

            json=$(
                cat <<EOF
{
    "name": "reverse_reality_server_multiport",
    "nodes": [
        {
            "name": "users_inbound",
            "type": "TcpListener",
            "settings": {
                "address": "0.0.0.0",
                "port": [$start_port,$end_port],
                "nodelay": true
            },
            "next": "header"
        },
        {
            "name": "header",
            "type": "HeaderClient",
            "settings": {
                "data": "src_context->port"
            },
            "next": "bridge2"
        },
        {
            "name": "bridge2",
            "type": "Bridge",
            "settings": {
                "pair": "bridge1"
            }
        },
        {
            "name": "bridge1",
            "type": "Bridge",
            "settings": {
                "pair": "bridge2"
            }
        },
        {
            "name": "reverse_server",
            "type": "ReverseServer",
            "settings": {},
            "next": "bridge1"
        },
        {
            "name": "reality_server",
            "type": "RealityServer",
            "settings": {
                "destination": "reality_dest",
                "password": "$passwd"
            },
            "next": "reverse_server"
        },
        {
            "name": "kharej_inbound",
            "type": "TcpListener",
            "settings": {
                "address": "0.0.0.0",
                "port": 443,
                "nodelay": true,
                "whitelist": [
                    "$remote_address/32"
                ]
            },
            "next": "reality_server"
        },
        {
            "name": "reality_dest",
            "type": "TcpConnector",
            "settings": {
                "nodelay": true,
                "address": "$sni",
                "port": 443
            }
        }
    ]
}
EOF
            )

            echo "$json" >/root/Waterwall/config.json
        }

        create_reverse_reality_client_multiport_kharej() {
            whiptail --title "Info" --msgbox "This method uses port 443. Make sure it is not already in use and is open." 10 50
            remote_address=$(whiptail --title "Input" --inputbox "Enter the iran address:" 8 40 3>&1 1>&2 2>&3)
            [ $? -ne 0 ] && return
            sni=google.com
            passwd=samiri
            min_un=16

            install_waterwall

            json=$(
                cat <<EOF
{
    "name": "reverse_reality_client_multiport",
    "nodes": [
        {
            "name": "outbound_to_core",
            "type": "TcpConnector",
            "settings": {
                "nodelay": true,
                "address": "127.0.0.1",
                "port": "dest_context->port"
            }
        },
        {
            "name": "header",
            "type": "HeaderServer",
            "settings": {
                "override": "dest_context->port"
            },
            "next": "outbound_to_core"
        },
        {
            "name": "bridge1",
            "type": "Bridge",
            "settings": {
                "pair": "bridge2"
            },
            "next": "header"
        },
        {
            "name": "bridge2",
            "type": "Bridge",
            "settings": {
                "pair": "bridge1"
            },
            "next": "reverse_client"
        },
        {
            "name": "reverse_client",
            "type": "ReverseClient",
            "settings": {
                "minimum-unused": $min_un
            },
            "next": "reality_client"
        },
        {
            "name": "reality_client",
            "type": "RealityClient",
            "settings": {
                "sni": "$sni",
                "password": "$passwd"
            },
            "next": "outbound_to_iran"
        },
        {
            "name": "outbound_to_iran",
            "type": "TcpConnector",
            "settings": {
                "nodelay": true,
                "address": "$remote_address",
                "port": 443
            }
        }
    ]
}
EOF
            )

            echo "$json" >/root/Waterwall/config.json
        }

        choice=$(whiptail --title "Reality Reverse Tunnel" --menu "Choose an option:" 15 50 4 \
            "1" "Reverse Reality Multiport Iran" \
            "2" "Reverse Reality Multiport Kharej" \
            "0" "Back to Main Menu" 3>&1 1>&2 2>&3)

        case $choice in
        1)
            create_reverse_reality_server_multiport_iran
            waterwall_service
            ;;
        2)
            create_reverse_reality_client_multiport_kharej
            waterwall_service
            ;;
        0)
            mainreverse
            ;;
        *)
            whiptail --title "Error" --msgbox "Invalid choice!" 8 40
            ;;
        esac
    }

    # Reset Iptables rules
    reset_iptables() {
        if whiptail --title "Reset Iptables" --yesno "Reset Iptables rules to default settings?" 8 50; then
            sudo iptables -P INPUT ACCEPT
            sudo iptables -P FORWARD ACCEPT
            sudo iptables -P OUTPUT ACCEPT

            sudo iptables -F
            sudo iptables -X
            sudo iptables -Z
            sudo iptables -t nat -F
            sudo iptables -t nat -X
            sudo iptables -t mangle -F
            sudo iptables -t mangle -X
            sudo iptables -t raw -F
            sudo iptables -t raw -X

            whiptail --title "Success" --msgbox "Iptables rules have been successfully reset." 8 50
        fi
    }

    # Get IP address
    ip_address=$(hostname -I | awk '{print $1}' || curl -s https://api64.ipify.org)

    # Check firewall status
    ufw() {
        if sudo ufw status | grep -q "Status: active"; then
            if whiptail --title "Firewall Active" --yesno "The firewall is active. Disable it?" 8 50; then
                sudo ufw disable
                whiptail --title "Success" --msgbox "Firewall disabled." 8 40
            fi
        fi
    }

    # Reset Tunnel
    reset_tunnel() {
        create_reset_tunnel_iran() {
            server_ip=$(whiptail --title "Input" --inputbox "Enter the local IP address [$ip_address]:" 8 40 "$ip_address" 3>&1 1>&2 2>&3)
            [ $? -ne 0 ] && return
            remote_address=$(whiptail --title "Input" --inputbox "Enter the remote IP address:" 8 40 3>&1 1>&2 2>&3)
            [ $? -ne 0 ] && return
            ufw
            reset_iptables
            install_waterwall

            json=$(
                cat <<EOF
{
  "name": "reset_tunnel_iran",
  "nodes": [
    {
      "name": "input",
      "type": "TcpListener",
      "settings": {
        "address": "0.0.0.0",
        "port": [
          23,
          65535
        ],
        "nodelay": true
      },
      "next": "output"
    },
    {
      "name": "output",
      "type": "TcpConnector",
      "settings": {
        "nodelay": true,
        "address": "10.0.0.2",
        "port": "src_context->port"
      }
    },
    {
      "name": "tdev",
      "type": "TunDevice",
      "settings": {
        "device-name": "tun0",
        "device-ip": "10.0.0.1/24"
      }
    },
    {
      "name": "rdev",
      "type": "RawDevice",
      "settings": {
        "mode": "injector"
      }
    },
    {
      "name": "cdev",
      "type": "CaptureDevice",
      "settings": {
        "direction": "incoming",
        "filter-mode": "source-ip",
        "ip": "$remote_address/32"
      }
    },
    {
      "name": "route1_receiver",
      "type": "Layer3Receiver",
      "settings": {
        "device": "tdev"
      },
      "next": "route1_source_changer"
    },
    {
      "name": "route1_source_changer",
      "type": "Layer3IpOverrider",
      "settings": {
        "mode": "source-ip",
        "ipv4": "$server_ip"
      },
      "next": "tcp_reset_on"
    },
    {
      "name": "tcp_reset_on",
      "type": "Layer3TcpManipulator",
      "settings": {
        "bit-reset": "on"
      },
      "next": "route1_dest_setter"
    },
    {
      "name": "route1_dest_setter",
      "type": "Layer3IpOverrider",
      "settings": {
        "mode": "dest-ip",
        "ipv4": "$remote_address"
      },
      "next": "route1_writer"
    },
    {
      "name": "route1_writer",
      "type": "Layer3Sender",
      "settings": {
        "device": "rdev"
      }
    },
    {
      "name": "route2_receiver",
      "type": "Layer3Receiver",
      "settings": {
        "device": "cdev"
      },
      "next": "route2_source_changer"
    },
    {
      "name": "route2_source_changer",
      "type": "Layer3IpOverrider",
      "settings": {
        "mode": "source-ip",
        "ipv4": "10.0.0.2"
      },
      "next": "tcp_reset_off"
    },
    {
      "name": "tcp_reset_off",
      "type": "Layer3TcpManipulator",
      "settings": {
        "bit-reset": "off"
      },
      "next": "route2_dest_setter"
    },
    {
      "name": "route2_dest_setter",
      "type": "Layer3IpOverrider",
      "settings": {
        "mode": "dest-ip",
        "ipv4": "10.0.0.1"
      },
      "next": "route2_writer"
    },
    {
      "name": "route2_writer",
      "type": "Layer3Sender",
      "settings": {
        "device": "tdev"
      }
    }
  ]
}
EOF
            )
            echo "$json" >/root/Waterwall/config.json
        }

        create_reset_tunnel_kharej() {
            server_ip=$(whiptail --title "Input" --inputbox "Enter the local IP address [$ip_address]:" 8 40 "$ip_address" 3>&1 1>&2 2>&3)
            [ $? -ne 0 ] && return
            remote_address=$(whiptail --title "Input" --inputbox "Enter the remote IP address:" 8 40 3>&1 1>&2 2>&3)
            [ $? -ne 0 ] && return
            ufw
            reset_iptables
            install_waterwall

            json=$(
                cat <<EOF
{
  "name": "reset_tunnel_kharej",
  "nodes": [
    {
      "name": "tdev",
      "type": "TunDevice",
      "settings": {
        "device-name": "tun0",
        "device-ip": "10.0.0.1/24"
      }
    },
    {
      "name": "rdev",
      "type": "RawDevice",
      "settings": {
        "mode": "injector"
      }
    },
    {
      "name": "cdev",
      "type": "CaptureDevice",
      "settings": {
        "direction": "incoming",
        "filter-mode": "source-ip",
        "ip": "$remote_address/32"
      }
    },
    {
      "name": "route1_receiver",
      "type": "Layer3Receiver",
      "settings": {
        "device": "tdev"
      },
      "next": "route1_source_changer"
    },
    {
      "name": "route1_source_changer",
      "type": "Layer3IpOverrider",
      "settings": {
        "mode": "source-ip",
        "ipv4": "$server_ip"
      },
      "next": "tcp_reset_on"
    },
    {
      "name": "tcp_reset_on",
      "type": "Layer3TcpManipulator",
      "settings": {
        "bit-reset": "on"
      },
      "next": "route1_dest_setter"
    },
    {
      "name": "route1_dest_setter",
      "type": "Layer3IpOverrider",
      "settings": {
        "mode": "dest-ip",
        "ipv4": "$remote_address"
      },
      "next": "route1_writer"
    },
    {
      "name": "route1_writer",
      "type": "Layer3Sender",
      "settings": {
        "device": "rdev"
      }
    },
    {
      "name": "route2_receiver",
      "type": "Layer3Receiver",
      "settings": {
        "device": "cdev"
      },
      "next": "route2_source_changer"
    },
    {
      "name": "route2_source_changer",
      "type": "Layer3IpOverrider",
      "settings": {
        "mode": "source-ip",
        "ipv4": "10.0.0.2"
      },
      "next": "tcp_reset_off"
    },
    {
      "name": "tcp_reset_off",
      "type": "Layer3TcpManipulator",
      "settings": {
        "bit-reset": "off"
      },
      "next": "route2_dest_setter"
    },
    {
      "name": "route2_dest_setter",
      "type": "Layer3IpOverrider",
      "settings": {
        "mode": "dest-ip",
        "ipv4": "10.0.0.1"
      },
      "next": "route2_writer"
    },
    {
      "name": "route2_writer",
      "type": "Layer3Sender",
      "settings": {
        "device": "tdev"
      }
    }
  ]
}
EOF
            )
            echo "$json" >/root/Waterwall/config.json
        }

        choice=$(whiptail --title "Reset Tunnel" --menu "Choose an option:" 15 50 4 \
            "1" "Reset Tunnel Multiport Iran" \
            "2" "Reset Tunnel Multiport Kharej" \
            "3" "Reset Iptables Rules" \
            "0" "Back to Main Menu" 3>&1 1>&2 2>&3)

        case $choice in
        1)
            create_reset_tunnel_iran
            waterwall_service
            ;;
        2)
            create_reset_tunnel_kharej
            waterwall_service
            ;;
        3)
            reset_iptables
            ;;
        0)
            mainreverse
            ;;
        *)
            whiptail --title "Error" --msgbox "Invalid choice!" 8 40
            ;;
        esac
    }

    # Uninstall Waterwall
    uninstall_waterwall() {
        if [ -f ~/Waterwall/config.json ] || [ -f /etc/systemd/system/Waterwall.service ]; then
            if whiptail --title "Uninstall Waterwall" --yesno "Proceed with uninstalling Waterwall?" 8 50; then
                if [ -d ~/Waterwall/cert ] || [ -f ~/.acme/acme.sh ]; then
                    if whiptail --title "Delete Certificates" --yesno "Do you want to delete the Domain Certificates?" 8 50; then
                        domain=$(whiptail --title "Input" --inputbox "Enter Your domain:" 8 40 3>&1 1>&2 2>&3)
                        [ $? -ne 0 ] && return
                        rm -rf ~/.acme.sh/"${domain}"_ecc
                        rm -rf ~/Waterwall/cert
                        whiptail --title "Success" --msgbox "Certificate for ${domain} has been deleted." 8 50
                    fi
                fi

                rm -rf ~/Waterwall/{core.json,config.json,Waterwall,log/}
                systemctl stop Waterwall.service >/dev/null 2>&1
                systemctl disable Waterwall.service >/dev/null 2>&1
                rm -rf /etc/systemd/system/Waterwall.service >/dev/null 2>&1
                whiptail --title "Success" --msgbox "Waterwall has been uninstalled successfully." 8 50
            fi
        else
            whiptail --title "Error" --msgbox "Waterwall is not installed." 8 40
        fi
    }

    # Check tunnel status
    check_tunnel_status() {
        if sudo systemctl is-active --quiet Waterwall.service; then
            status="Waterwall: [running ✔]"
        else
            status="Waterwall: [Not running ✗]"
        fi
        echo "$status"
    }


    check_install_service() {
        if [ -f /etc/systemd/system/Waterwall.service ]; then
            whiptail --title "Error" --msgbox "Please uninstall the existing Waterwall service before continuing" 10 60
            mainreverse
        fi
    }


    while true; do
        status=$(check_tunnel_status)
        choice=$(whiptail --title "Main Menu" --menu "Reality Reverse Tunnel\n\n$status\n\nChoose an option:" 20 50 6 \
            "1" "Reality Reverse Tunnel" \
            "2" "Reset Tunnel" \
            "3" "Uninstall Waterwall" \
            "0" "Exit" 3>&1 1>&2 2>&3)

        case $choice in
        1)
            check_install_service
            reality_reverse
            ;;
        2)
            reset_tunnel
            ;;
        3)
            uninstall_waterwall
            ;;
        0)
            main_program
            ;;
        *)
            whiptail --title "Error" --msgbox "Invalid choice!" 8 40
            ;;
        esac
    done
}


rtt_tunnel_hysteria(){

    # Function to check for required dependencies
    check_dependencies() {

        sudo apt install -y net-tools

        for cmd in whiptail wget openssl systemctl netstat nc; do
            if ! command -v "$cmd" &>/dev/null; then
            whiptail --title "Error" --msgbox "Required command '$cmd' is not installed. Please install it and try again." 10 60
            main_program
            fi
        done
    }

    # Function to validate IPv4 address
    validate_ipv4() {
        local ip="$1"
        if [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            IFS='.' read -r -a octets <<< "$ip"
            for octet in "${octets[@]}"; do
            if [[ "$octet" -lt 0 || "$octet" -gt 255 ]]; then
                return 1
            fi
            done
            return 0
        else
            return 1
        fi
    }


    # Main Hysteria installation function
    install_hysteria() {
        
        
        ARCH=$(uname -m)

        HYSTERIA_VERSION_AMD64="https://github.com/apernet/hysteria/releases/download/app%2Fv2.6.1/hysteria-linux-amd64"
        HYSTERIA_VERSION_ARM="https://github.com/apernet/hysteria/releases/download/app%2Fv2.6.1/hysteria-linux-arm"
        HYSTERIA_VERSION_ARM64="https://github.com/apernet/hysteria/releases/download/app%2Fv2.6.1/hysteria-linux-arm64"

        DOWNLOAD_URL=""

        case "$ARCH" in
            x86_64)
            DOWNLOAD_URL="$HYSTERIA_VERSION_AMD64"
            ;;
            armv7l|armv6l)
            DOWNLOAD_URL="$HYSTERIA_VERSION_ARM"
            ;;
            aarch64)
            DOWNLOAD_URL="$HYSTERIA_VERSION_ARM64"
            ;;
            *)
            whiptail --title "Error" --msgbox "System architecture '$ARCH' is not supported." 10 60
            main_program
            ;;
        esac

        whiptail --title "Info" --msgbox "Downloading Hysteria binary for architecture: $ARCH" 10 60
        wget -O hysteria "$DOWNLOAD_URL" >> /var/log/hysteria_install.log 2>&1
        if [ $? -ne 0 ]; then
            whiptail --title "Error" --msgbox "Failed to download Hysteria binary. Check /var/log/hysteria_install.log." 10 60
            main_program
        fi

        chmod +x hysteria
        sudo mv hysteria /usr/local/bin/
        sudo mkdir -p /etc/hysteria/
        sudo chmod 755 /etc/hysteria/

        SERVER_TYPE=$(whiptail --title "Server Type" --menu "Are you installing on the Iranian server or the Foreign server?" 15 60 2 \
            "Iran" "Iranian Server" \
            "Foreign" "Foreign Server" 3>&1 1>&2 2>&3)

        if [ $? -ne 0 ]; then
            whiptail --title "Warning" --msgbox "Operation canceled." 10 60
            main_program
        fi

        SERVER_TYPE=$(echo "$SERVER_TYPE" | tr '[:upper:]' '[:lower:]')

        if [ "$SERVER_TYPE" == "foreign" ]; then
            whiptail --title "Info" --msgbox "Setting up the foreign server..." 10 60

            sudo apt update -y >> /var/log/hysteria_install.log 2>&1
            sudo apt install -y openssl >> /var/log/hysteria_install.log 2>&1

            whiptail --title "Info" --msgbox "Creating a self-signed certificate..." 10 60
            sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
            -keyout /etc/hysteria/self.key \
            -out /etc/hysteria/self.crt \
            -subj "/CN=myserver" >> /var/log/hysteria_install.log 2>&1

            H_PORT=23023
            H_PASSWORD=samir321

            cat << EOF | sudo tee /etc/hysteria/server-config.yaml > /dev/null
listen: ":$H_PORT"
tls:
  cert: /etc/hysteria/self.crt
  key: /etc/hysteria/self.key
auth:
  type: password
  password: "$H_PASSWORD"
speedTest: true
EOF

            sudo chmod 644 /etc/hysteria/server-config.yaml
            sudo chown root:root /etc/hysteria/server-config.yaml

            cat << EOF | sudo tee /etc/systemd/system/hysteria.service > /dev/null
[Unit]
Description=Hysteria2 Tunnel Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/hysteria server -c /etc/hysteria/server-config.yaml
Restart=always
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

            sudo systemctl daemon-reload
            sudo systemctl enable hysteria
            sudo systemctl start hysteria >> /var/log/hysteria_install.log 2>&1
            (crontab -l 2>/dev/null | grep -v "systemctl restart hysteria"; echo "0 */3 * * * /usr/bin/systemctl restart hysteria") | crontab -

            whiptail --title "Success" --msgbox "Foreign server configured successfully." 10 60

        elif [ "$SERVER_TYPE" == "iran" ]; then
            whiptail --title "Info" --msgbox "Setting up the Iranian server..." 10 60

            REMOTE_IP="localhost"
            SERVER_COUNT=1

            declare -A SERVER_INFO_INDEXED=()

            for (( i=1; i<=$SERVER_COUNT; i++ )); do
            whiptail --title "Info" --msgbox "Configuring foreign server number $i:" 10 60

            FOREIGN_IP=$(whiptail --title "Foreign Server IP" --inputbox "Enter the IPv4 address of the foreign server:" 10 60 3>&1 1>&2 2>&3)
            if [ $? -ne 0 ]; then
                whiptail --title "Warning" --msgbox "Operation canceled." 10 60
                main_program
            fi

            if ! validate_ipv4 "$FOREIGN_IP"; then
                whiptail --title "Error" --msgbox "Invalid IPv4 address: $FOREIGN_IP. Please enter a valid IPv4 address." 10 60
                main_program
            fi

            SERVER_ADDRESS="$FOREIGN_IP"
            FOREIGN_PORT=23023
            FOREIGN_PASSWORD=samir321
            FOREIGN_SNI=google.com

            PORT_FORWARD_COUNT=$(whiptail --title "Port Count" --inputbox "How many ports to tunnel for this server?" 10 60 3>&1 1>&2 2>&3)
            if [ $? -ne 0 ]; then
                whiptail --title "Warning" --msgbox "Operation canceled." 10 60
                main_program
            fi

            if ! [[ "$PORT_FORWARD_COUNT" =~ ^[0-9]+$ ]] || [ "$PORT_FORWARD_COUNT" -lt 1 ]; then
                whiptail --title "Error" --msgbox "Invalid port count. Enter a positive number." 10 60
                main_program
            fi

            TCP_FORWARD=""
            UDP_FORWARD=""
            FORWARDED_PORTS=""

            for (( p=1; p<=$PORT_FORWARD_COUNT; p++ )); do
                TUNNEL_PORT=$(whiptail --title "Tunnel Port" --inputbox "Enter port number #$p to tunnel:" 10 60 3>&1 1>&2 2>&3)
                if [ $? -ne 0 ]; then
                whiptail --title "Warning" --msgbox "Operation canceled." 10 60
                main_program
                fi

                if ! [[ "$TUNNEL_PORT" =~ ^[0-9]+$ ]] || [ "$TUNNEL_PORT" -lt 1 ] || [ "$TUNNEL_PORT" -gt 65535 ]; then
                whiptail --title "Error" --msgbox "Invalid port number: $TUNNEL_PORT. Enter a number between 1 and 65535." 10 60
                main_program
                fi

                # Generate correctly indented forwarding entries
                TCP_FORWARD+="  - listen: 0.0.0.0:$TUNNEL_PORT
    remote: '$REMOTE_IP:$TUNNEL_PORT'
"
                UDP_FORWARD+="  - listen: 0.0.0.0:$TUNNEL_PORT
    remote: '$REMOTE_IP:$TUNNEL_PORT'
"

                if [ -z "$FORWARDED_PORTS" ]; then
                FORWARDED_PORTS="$TUNNEL_PORT"
                else
                FORWARDED_PORTS="$FORWARDED_PORTS, $TUNNEL_PORT"
                fi
            done

            IRAN_CONFIG="/etc/hysteria/iran-config${i}.yaml"
            sudo bash -c "cat << EOF > $IRAN_CONFIG
server: \"$SERVER_ADDRESS:$FOREIGN_PORT\"
auth: \"$FOREIGN_PASSWORD\"
tls:
  sni: \"$FOREIGN_SNI\"
  insecure: true

quic:
  initStreamReceiveWindow: 8388608
  maxIdleTimeout: 11s
  keepAliveInterval: 10s

tcpForwarding:
$TCP_FORWARD
udpForwarding:
$UDP_FORWARD
EOF"

            sudo chmod 644 "$IRAN_CONFIG"
            sudo chown root:root "$IRAN_CONFIG"
            IRAN_SERVICE="/etc/systemd/system/hysteria${i}.service"
            sudo bash -c "cat << EOF > $IRAN_SERVICE
[Unit]
Description=Hysteria2 Foreign Server ${i}
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/hysteria client -c /etc/hysteria/iran-config${i}.yaml
Restart=always
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF"

            (crontab -l 2>/dev/null | grep -v "systemctl restart hysteria${i}"; echo "0 4 * * * /usr/bin/systemctl restart hysteria${i}") | crontab -

            sudo systemctl daemon-reload
            sudo systemctl enable hysteria${i}
            sudo systemctl start hysteria${i} >> /var/log/hysteria_install.log 2>&1

            SERVER_INFO_INDEXED["server_${i}_info"]="$FOREIGN_PORT|$FOREIGN_PASSWORD|$FOREIGN_SNI|$FORWARDED_PORTS"
            done

            whiptail --title "Success" --msgbox "Iranian server configured successfully." 10 60

            INFO_MESSAGE="Server Configuration Summary:\n\n"
            for (( i=1; i<=$SERVER_COUNT; i++ )); do
            INFO="${SERVER_INFO_INDEXED["server_${i}_info"]}"
            IFS='|' read -r port pass sni forwards <<< "$INFO"
            INFO_MESSAGE+="Server $i:\nPort: $port\nPassword: $pass\nSNI: $sni\nForwarded Ports: $forwards\n\n"
            done
            INFO_MESSAGE+="Done."
            whiptail --title "Summary" --msgbox "$INFO_MESSAGE" 20 60

        else
            whiptail --title "Error" --msgbox "Invalid server type selected." 10 60
            main_program
        fi
    }

    # Uninstall Hysteria function
    uninstall_hysteria() {
        whiptail --title "Info" --msgbox "Uninstalling Hysteria..." 10 60
        sudo systemctl daemon-reload 2>/dev/null
        for i in {1..9} ""; do
            sudo systemctl disable hysteria$i 2>/dev/null
            sudo systemctl stop hysteria$i 2>/dev/null
            sudo rm -f /etc/systemd/system/hysteria$i.service 2>/dev/null
        done
        sudo rm -f /etc/hysteria/server-config.yaml 2>/dev/null
        for i in {1..8}; do
            sudo rm -f /etc/hysteria/iran-config$i.yaml 2>/dev/null
        done
        sudo rm -f /usr/local/bin/hysteria 2>/dev/null
        sudo rm -rf /etc/hysteria/ 2>/dev/null
        crontab -l 2>/dev/null | grep -v "systemctl restart hysteria" | crontab -
        whiptail --title "Success" --msgbox "Hysteria uninstalled successfully." 10 60

        if whiptail --title "Reboot System" --yesno "Reboot the system?" 10 60; then
            whiptail --title "Info" --msgbox "Rebooting the system..." 10 60
            sudo reboot
        else
            whiptail --title "Info" --msgbox "Reboot skipped." 10 60
        fi
    }

    # Main menu
    check_dependencies
    CHOICE=$(whiptail --title "Hysteria Setup" --menu "Choose an option:" 15 60 3 \
    "1" "Install Hysteria" \
    "2" "Uninstall Hysteria" \
    "3" "Exit" 3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
    whiptail --title "Warning" --msgbox "Operation canceled." 10 60
    main_program
    fi

    case "$CHOICE" in
    1)
        install_hysteria
        ;;
    2)
        uninstall_hysteria
        ;;
    3)
        whiptail --title "Info" --msgbox "Exiting..." 10 60
        main_program
        ;;
    *)
        whiptail --title "Error" --msgbox "Invalid option. Exiting..." 10 60
        main_program
        ;;
    esac
}


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


xui_complex(){
    while true; do
        xui_cond=$(whiptail --title "X-UI SERVICE" --menu "X-UI SERVICE, choose an option:" 20 80 3 \
            "1" "X-UI Status" \
            "2" "Install X-UI Sanaei Panel" \
            "3" "Unistall X-UI Panel" 3>&1 1>&2 2>&3)

        # Check if Cancel was pressed
        cancelf
        
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
                    *) echo -e "${green}Unsupported CPU architecture! ${plain}" && rm -f install.sh && main_program ;;
                    esac
                }

                # requirment
                apt-get install -y -q wget curl tar tzdata

                # change directory
                cd /usr/local/

                # download
                url="https://github.com/MHSanaei/3x-ui/releases/download/v2.5.7/x-ui-linux-$(arch).tar.gz"

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


tunnelplatforms(){

    tunoption=$(whiptail  --menu "Reverse Tunnel Options, choose an option:" 20 80 4 \
        "1" "Backhaul" \
        "2" "Hysteria" \
        "3" "Reality" \
        "4" "Exit" 3>&1 1>&2 2>&3)

    case "$tunoption" in
        "1")
            backhaul_tunnel                
            ;;
        "2")
            rtt_tunnel_hysteria            
            ;;
        "3")
            mainreverse                
            ;;
        "4")
            main_program               
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
    SCRIPT_NAME="cloudflare-ddns"
    SCRIPT_PATH="/usr/local/bin/${SCRIPT_NAME}.sh"
    SERVICE_PATH="/etc/systemd/system/${SCRIPT_NAME}.service"
    CONFIG_PATH="/etc/${SCRIPT_NAME}.conf"
    STATUS_FILE="/tmp/${SCRIPT_NAME}_current_server.status"

    # Required dependencies
    REQUIRED_PACKAGES=("jq" "curl" "whiptail" "netcat-openbsd" "network-manager")

    # Check and install dependencies
    check_dependencies() {
        for pkg in "${REQUIRED_PACKAGES[@]}"; do
            if ! dpkg -s "$pkg" >/dev/null 2>&1; then
                if ! whiptail --title "Dependencies Missing" --yesno "Package $pkg is not installed. Install now?" 10 60; then
                    whiptail --msgbox "Cannot proceed without required packages." 10 60
                    exit 1
                fi
                sudo apt-get update
                sudo apt-get install -y "$pkg"
            fi
        done
    }

    # Function to send Telegram message
    send_telegram_message() {
        local message="$1"
        local max_attempts=3
        local attempt=1

        if [ -z "$TELEGRAM_CHAT_IDS" ] || [ -z "$TELEGRAM_BOT_TOKEN" ]; then
            echo "Telegram configuration missing" | systemd-cat -t cloudflare-ddns -p err
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
                
                if echo "$RESPONSE" | jq -e '.ok' > /dev/null; then
                    echo "Telegram message sent to $chat_id" | systemd-cat -t cloudflare-ddns -p info
                    break
                else
                    echo "Telegram message attempt $attempt to $chat_id failed: $RESPONSE" | systemd-cat -t cloudflare-ddns -p err
                    sleep 5
                    ((attempt++))
                fi
            done
            if [ $attempt -gt $max_attempts ]; then
                echo "Failed to send Telegram message to $chat_id after $max_attempts attempts" | systemd-cat -t cloudflare-ddns -p err
            fi
        done
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

    # Get configuration function
    get_configuration() {
        CF_API_KEY=$(whiptail --inputbox "Enter Cloudflare API Key" 10 60 3>&1 1>&2 2>&3) || return 1    
        FULL_DOMAIN=$(whiptail --inputbox "Enter your full domain (e.g., subdomain.example.com):" 10 60 3>&1 1>&2 2>&3) || return 1
        
        DOMAIN=$(echo "$FULL_DOMAIN" | sed -E 's/^[^.]+\.//')
        SUBDOMAIN=$(echo "$FULL_DOMAIN" | sed -E 's/^([^.]+).+$/\1/')
        
        find_zone_id || return 1
        check_subdomain_exists || return 1
        
        KHAREJ_SERVER_IP=$(curl -s https://api.ipify.org)
        IRAN_SERVER_IP=$(whiptail --inputbox "Enter Iran Server IP" 10 60 3>&1 1>&2 2>&3) || return 1
        TELEGRAM_BOT_TOKEN=$(whiptail --inputbox "Enter Telegram Bot Token" 10 60 3>&1 1>&2 2>&3) || return 1
        TELEGRAM_CHAT_IDS=$(whiptail --inputbox "Enter Telegram Chat IDs (comma-separated for multiple users)" 10 60 3>&1 1>&2 2>&3) || return 1
        return 0
    }

    # Create the monitoring script
    create_monitor_script() {
        sudo mkdir -p "$(dirname "$SCRIPT_PATH")"
        sudo tee "$SCRIPT_PATH" > /dev/null << 'EOF'
#!/bin/bash

CONFIG_PATH="/etc/cloudflare-ddns.conf"
source "$CONFIG_PATH"

CURRENT_SERVER_IP=""
FAILURE_COUNT=0
LAST_FAILURE_TIME=0

send_telegram_notification() {
    local message="$1"
    local max_attempts=3
    local attempt=1

    if [ -z "$TELEGRAM_CHAT_IDS" ] || [ -z "$TELEGRAM_BOT_TOKEN" ]; then
        echo "Telegram configuration missing" | systemd-cat -t cloudflare-ddns -p err
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
            
            if echo "$RESPONSE" | jq -e '.ok' > /dev/null; then
                echo "Telegram message sent to $chat_id" | systemd-cat -t cloudflare-ddns -p info
                break
            else
                echo "Telegram message attempt $attempt to $chat_id failed: $RESPONSE" | systemd-cat -t cloudflare-ddns -p err
                sleep 5
                ((attempt++))
            fi
        done
        if [ $attempt -gt $max_attempts ]; then
            echo "Failed to send Telegram message to $chat_id after $max_attempts attempts" | systemd-cat -t cloudflare-ddns -p err
        fi
    done
}

update_dns_record() {
    local TARGET_IP=$1
    local SWITCH_REASON=$2
    
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
            echo "DNS updated from $CURRENT_IP to $TARGET_IP" | systemd-cat -t cloudflare-ddns -p info
            CURRENT_SERVER_IP="$TARGET_IP"
        else
            echo "DNS update failed: $UPDATE_RESPONSE" | systemd-cat -t cloudflare-ddns -p err
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
        if ping -c 4 -W 2 "$target_ip" > /dev/null 2>&1; then
            success=true
            break
        fi
        echo "Ping attempt $attempt to $target_ip failed" | systemd-cat -t cloudflare-ddns -p warning
        sleep 5
        ((attempt++))
    done

    if [ "$success" = false ]; then
        if nc -z -w 5 "$target_ip" 443 > /dev/null 2>&1; then
            success=true
            echo "TCP check to $target_ip:443 succeeded" | systemd-cat -t cloudflare-ddns -p info
        else
            echo "TCP check to $target_ip:443 failed" | systemd-cat -t cloudflare-ddns -p warning
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

    echo "Internet connectivity lost" | systemd-cat -t cloudflare-ddns -p warning
    ((FAILURE_COUNT++))
    
    if [ $FAILURE_COUNT -eq 1 ]; then
        LAST_FAILURE_TIME=$(date +%s)
    fi

    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$((CURRENT_TIME - LAST_FAILURE_TIME))

    if [ $FAILURE_COUNT -ge 3 ] && [ $TIME_DIFF -ge 900 ]; then
        send_telegram_notification "🌐 Internet down for 15+ minutes on $(hostname), rebooting at $(TZ='Asia/Tehran' date '+%Y-%m-%d %H:%M:%S')"
        echo "Internet down for 15+ minutes, rebooting..." | systemd-cat -t cloudflare-ddns -p err
        /sbin/reboot
        return 1
    fi

    # Try resetting network
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
    CPU_USAGE=$(top -bn1 | head -n 3 | grep "Cpu(s)" | awk '{print $2}')
    if [ "$FREE_MEM" -lt 100 ] || [ "${CPU_USAGE%.*}" -gt 90 ]; then
        echo "Low resources detected: Free RAM=$FREE_MEM MB, CPU=$CPU_USAGE%" | systemd-cat -t cloudflare-ddns -p warning
        send_telegram_notification "⚠️ Low resources on $(hostname): Free RAM=$FREE_MEM MB, CPU=$CPU_USAGE% at $(TZ='Asia/Tehran' date '+%Y-%m-%d %H:%M:%S')"
    fi
}

handle_telegram_commands() {
    local offset_file="/tmp/telegram_offset"
    local offset=0

    if [ -f "$offset_file" ]; then
        offset=$(cat "$offset_file")
    fi

    RESPONSE=$(curl -s -m 10 "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?offset=$offset")

    if echo "$RESPONSE" | jq -e '.ok' > /dev/null; then
        UPDATES=$(echo "$RESPONSE" | jq '.result[]')
        if [ -n "$UPDATES" ]; then
            echo "$UPDATES" | while read -r update; do
                UPDATE_ID=$(echo "$update" | jq -r '.update_id')
                CHAT_ID=$(echo "$update" | jq -r '.message.chat.id')
                MESSAGE_TEXT=$(echo "$update" | jq -r '.message.text')

                # Verify chat ID is authorized
                if [[ ",${TELEGRAM_CHAT_IDS}," == *",${CHAT_ID},"* ]]; then
                    if [ "$MESSAGE_TEXT" == "/status" ]; then
                        RECORD_RESPONSE=$(curl -s -X GET \
                            "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$SUBDOMAIN.$DOMAIN" \
                            -H "Authorization: Bearer $CF_API_KEY" \
                            -H "Content-Type: application/json")
                        
                        CURRENT_IP=$(echo "$RECORD_RESPONSE" | jq -r '.result[0].content')
                        if [ "$CURRENT_IP" == "$KHAREJ_SERVER_IP" ]; then
                            SERVER_STATUS="Kharej Server ($KHAREJ_SERVER_IP)"
                        elif [ "$CURRENT_IP" == "$IRAN_SERVER_IP" ]; then
                            SERVER_STATUS="Iran Server ($IRAN_SERVER_IP)"
                        else
                            SERVER_STATUS="Unknown ($CURRENT_IP)"
                        fi

                        TEHRAN_TIME=$(TZ='Asia/Tehran' date '+%Y-%m-%d %H:%M:%S')
                        MESSAGE="🌐 <b>Server Status</b>%0AActive: $SERVER_STATUS%0ATime (Tehran): $TEHRAN_TIME"
                        curl -s -m 10 "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
                            -d "chat_id=${CHAT_ID}" \
                            -d "text=${MESSAGE}" \
                            -d "parse_mode=HTML"
                    fi
                fi

                # Update offset
                echo $((UPDATE_ID + 1)) > "$offset_file"
            done
        fi
    fi
}

while true; do
    log_system_resources
    check_internet_connectivity || echo "Internet check failed" | systemd-cat -t cloudflare-ddns -p err
    handle_telegram_commands

    if check_server_status "$IRAN_SERVER_IP"; then
        update_dns_record "$IRAN_SERVER_IP" "Iran server is reachable"
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

        if [ "$CURRENT_IP" == "$KHAREJ_SERVER_IP" ]; then
            SERVER_STATUS="Kharej Server ($KHAREJ_SERVER_IP)"
        elif [ "$CURRENT_IP" == "$IRAN_SERVER_IP" ]; then
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
                    main_program
                    ;;
            esac
        done
    }

    # Start the DDNS management
    main_menu1
}


# Function to get connectivity status for multiple sites
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


    my_ip=$(hostname -I | awk '{print $1}')
    [[ -z "$my_ip" ]] && my_ip="Unknown"

    tamin_status=$(check_connectivity "tamin.ir")
    google_status=$(check_connectivity "google.com")
    my_ip_status=$(check_connectivity "$my_ip")

    echo "Connectivity Status:\nTamin.ir: $tamin_status\nGoogle.com: $google_status\nMy IP ($my_ip): $my_ip_status"
}


# main program
main_program() {
    while true; do
        # main directory
        cd

        # Get connectivity status
        conn_status=$(get_connectivity_status)

        # Main menu with connectivity status
        main_obj=$(whiptail --title "SAMIR VPN Creator" --menu "Welcome to Samir VPN Creator\n\n$conn_status\n\nChoose an option:" 30 80 10 \
            "1" "X-UI SERVICE" \
            "2" "Reverse Tunnel" \
            "3" "SSL Cetificate + Change Subdomain IP" \
            "4" "Auto IP Change(run on kharej)" \
            "5" "Server Upgrade" \
            "6" "Speed Test" \
            "7" "Virtual RAM" \
            "8" "Change Subdomain IP" \
            "9" "SSL Certificate" \
            "10" "Exit" 3>&1 1>&2 2>&3)

        case "$main_obj" in
            "1")
                xui_complex                
                ;;
            "2")
                tunnelplatforms
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
                speed_testi
                ;;
            "7")
                virtual_ram                
                ;;
            "8")
                subdomains
                ;;
            "9")
                certificates
                ;;
            "10")
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