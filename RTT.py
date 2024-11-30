import platform
import subprocess
import requests
import tarfile
import sys
import re
import os
import shutil
import time
import subprocess
from time import sleep
import readline
import io

sys.stdout = io.TextIOWrapper(sys.stdout.detach(), encoding="utf-8", errors="replace")

if os.geteuid() != 0:
    print("\033[91mThis script must be run as root. Please use sudo -i.\033[0m")
    sys.exit(1)

false= False

def install_prerequisites():
    print("\033[93mInstalling prerequisites...\033[0m")
    if platform.system() == "Linux":
        loading_bar("\033[93mInstalling wget, curl, unzip, and tar\033[0m")
        subprocess.run(['sudo', 'apt', 'install', '-y', 'wget', 'curl', 'unzip', 'tar'], check=True)
    elif platform.system() == "Darwin":
        loading_bar("\033[93mInstalling wget, curl, unzip, and gnu-tar\033[0m")
        subprocess.run(['brew', 'install', 'wget', 'curl', 'unzip', 'gnu-tar'], check=True)
    else:
        print("\033[91mWindows is not supported..\033[0m")
        exit(1)

def loading_bar(task):
    print(f"{task}... ", end="", flush=True)
    for _ in range(10):
        time.sleep(0.2) 
        print(".", end="", flush=True)
    display_checkmark("\033[92mdone\033[0m")

def download_binary():
    os_name = platform.system().lower()
    arch = platform.machine()
    url = ""

    if os_name == "linux" and arch == "x86_64":
        url = "https://github.com/Musixal/Backhaul/releases/download/v0.6.3/backhaul_linux_amd64.tar.gz"
        file_name = "/tmp/backhaul_linux_amd64.tar.gz"
    elif os_name == "linux" and arch == "aarch64":
        url = "https://github.com/Musixal/Backhaul/releases/download/v0.6.3/backhaul_linux_arm64.tar.gz"
        file_name = "/tmp/backhaul_linux_arm64.tar.gz"
    elif os_name == "darwin" and arch == "x86_64":
        url = "https://github.com/Musixal/Backhaul/releases/download/v0.6.3/backhaul_darwin_amd64.tar.gz"
        file_name = "/tmp/backhaul_darwin_amd64.tar.gz"
    elif os_name == "darwin" and arch == "arm64":
        url = "https://github.com/Musixal/Backhaul/releases/download/v0.6.3/backhaul_darwin_arm64.tar.gz"
        file_name = "/tmp/backhaul_darwin_arm64.tar.gz"
    else:
        print("\033[91mOS or arch Unsupported\033[0m ")
        exit(1)

    print(f"\033[93mDownloading the binary from {url}..\033[0m")
    response = requests.get(url, stream=True)
    response.raise_for_status()
    total_size = int(response.headers.get('content-length', 0))
    downloaded_size = 0
    with open(file_name, 'wb') as file:
        for chunk in response.iter_content(chunk_size=8192):
            file.write(chunk)
            downloaded_size += len(chunk)
            progress = int((downloaded_size / total_size) * 50)
            sys.stdout.write(f"\r[{'#' * progress}{'.' * (50 - progress)}] {downloaded_size / 1024:.2f} KB")
            sys.stdout.flush()
    print("\n\033[92mDownload complete\033[0m")

    target_dir = "/usr/local/bin/backhaul"
    os.makedirs(target_dir, exist_ok=True)

    print("\033[93mExtracting binary..\033[0m")
    if file_name.endswith('.tar.gz'):
        with tarfile.open(file_name, 'r:gz') as tar:
            tar.extractall(path=target_dir)

    print("\033[92mBinary downloaded and extracted\033[0m")

def display_checkmark(message):
    print("\u2714 " + message)

def clear():
    os.system("clear")

def display_notification(message):
    print("\u2728 " + message)


# Main MENU
def backhaul_menu():
    os.system("clear")
    while True:  
        print("\033[92m ^ ^\033[0m")
        print("\033[92m(\033[91mO,O\033[92m)\033[0m")
        print("\033[92m(   ) \033[92mBackhaul\033[93m Menu\033[0m")
        print('\033[92m "-"\033[93m══════════════════════════════════\033[0m')
        print("\033[93m╭───────────────────────────────────────╮\033[0m")
        print("\033[93mChoose what to do:\033[0m")
        print("1  \033[91mStatus\033[0m")
        print("2  \033[93mSingle\033[0m")
        print("3  \033[93mEdit Backhaul\033[0m")
        print("4  \033[91mUninstall\033[0m")
        print("0. \033[94mExit\033[0m")
        print("\033[93m╰───────────────────────────────────────╯\033[0m")

        try:
            choice = input("\033[38;5;205mEnter your choice Please: \033[0m")
            if choice == "1":
                backhaul_single_status()
            elif choice == "2":
                backhaul_tcpmux_single()
            elif choice == "3":
                backhaul_edit_tcpmuxsingle()
            elif choice == "4":
                backhaul_uninstall_single()
            elif choice == "0":  
                print("Exiting...")
                sys.exit()
            else:
                print("Invalid choice.")
            input("Press Enter to continue...")  

        except KeyboardInterrupt:
            display_error("\033[91m\nProgram interrupted. Exiting...\033[0m")
            sys.exit()

def display_error(message):
    print("\u2718 Error: " + message)
    

# Install Tunnel
def backhaul_tcpmux_single():
    os.system("clear")
    print("\033[92m ^ ^\033[0m")
    print("\033[92m(\033[91mO,O\033[92m)\033[0m")
    print("\033[92m(   ) \033[92mBackhaul\033[96m TCPMux\033[93m Single Menu\033[0m")
    print('\033[92m "-"\033[93m══════════════════════════════════\033[0m')
    print("\033[93m╭───────────────────────────────────────╮\033[0m")
    print("\033[93mChoose what to do:\033[0m")
    print("1  \033[93mIRAN Server\033[0m")
    print("2  \033[92mKharej Client\033[0m")
    print("0. \033[94mback to the previous menu\033[0m")
    print("\033[93m╰───────────────────────────────────────╯\033[0m")
    choice = input("\033[38;5;205mEnter your choice Please: \033[0m")
    if choice == "1":
        backhaul_iran_server_tcpmuxmenu()
            
    elif choice == "2":
        backhaul_kharej_client_tcpmuxmenu()
            
    elif choice == "0":
        clear()
        backhaul_menu()

    else:
        print("Invalid choice.")

# Iran Tunnel
def backhaul_iran_server_tcpmuxmenu():
    os.system("clear")
    print("\033[92m ^ ^\033[0m")
    print("\033[92m(\033[91mO,O\033[92m)\033[0m")
    print("\033[92m(   ) \033[92mBackhaul \033[92mIRAN Server \033[93m Single Menu\033[0m")
    print('\033[92m "-"\033[93m══════════════════════════════════\033[0m')
    print("\033[93m───────────────────────────────────────\033[0m")
    
    backhaul_directory = "/usr/local/bin/backhaul"
    if os.path.exists(backhaul_directory):
        print(f"\033[93mbackhaul exists, skipping\033[0m")
        backhaul_menu()
    else:
        install_prerequisites()
        download_binary()
        bind_addr = f"0.0.0.0:{23123}"


    config = {
        "bind_addr": bind_addr,
        "transport": "tcpmux",
        "token": "samirkala",
        "keepalive_period": 75,
        "nodelay": false,
        "channel_size": 2048,
        "heartbeat": 40,
        "mux_con": 8,
        "mux_version": 1,
        "mux_framesize": 32768,
        "mux_recievebuffer": 4194304,
        "mux_streambuffer": 65536,
        "sniffer": false,
        "sniffer_log": "",
        "web_port": 0,
        "log_level": "info",
    }

    ports = []    
    port_range = input("\033[93mEnter \033[92mport range \033[97m(e.g: 100-900)\033[93m: \033[0m")        
    ports.append(f"{port_range}")
    config["ports"] = ports

    config_path = "/usr/local/bin/backhaul/server.toml"
    with open(config_path, 'w') as config_file:
        config_file.write("[server]\n")
        for key, value in config.items():
            if key == "ports":
                config_file.write("ports = [\n")
                for port in value:
                    config_file.write(f'    "{port}",\n')
                config_file.write("]\n")
            else:
                if isinstance(value, bool):
                    config_file.write(f'{key} = {"true" if value else "false"}\n')
                elif isinstance(value, int):
                    config_file.write(f'{key} = {value}\n')
                else:
                    config_file.write(f'{key} = "{value}"\n')

    display_checkmark(f"\033[92mConfig file created at {config_path}\033[0m")
    create_singleserver_service()
    enable_backhaul_reset_server()


def create_singleserver_service():
    service_content = """
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
"""
    service_path = "/etc/systemd/system/backhaul-server.service"
    with open(service_path, 'w') as service_file:
        service_file.write(service_content)
    
    os.system("systemctl daemon-reload")
    os.system("systemctl enable backhaul-server.service")
    os.system("systemctl start backhaul-server.service")
    display_checkmark(f"Service file created at {service_path}")


def enable_backhaul_reset_server():
    interval_seconds = 21600
    reset_backhaul_server(interval_seconds)
        


def reset_backhaul_server(interval):
    service_name = "backhaul_reset.service"

    daemon_script_content = f"""#!/bin/bash
INTERVAL={interval}

while true; do
    /bin/bash /etc/backhaul_reset.sh
    sleep $INTERVAL
done
"""

    with open("/usr/local/bin/backhaul_daemon.sh", "w") as daemon_script_file:
        daemon_script_file.write(daemon_script_content)

    subprocess.run(["chmod", "+x", "/usr/local/bin/backhaul_daemon.sh"])

    service_content = f"""[Unit]
Description=Custom Daemon

[Service]
ExecStart=/usr/local/bin/backhaul_daemon.sh
Restart=always

[Install]
WantedBy=multi-user.target
"""

    with open(f"/etc/systemd/system/{service_name}", "w") as service_file:
        service_file.write(service_content)

    ipsec_reset_script_content = """#!/bin/bash
systemctl daemon-reload 
systemctl restart backhaul-server 
sudo journalctl --vacuum-size=1M --unit=backhaul-server.service
"""

    with open("/etc/backhaul_reset.sh", "w") as script_file:
        script_file.write(ipsec_reset_script_content)

    subprocess.run(["chmod", "+x", "/etc/backhaul_reset.sh"])
    subprocess.run(["systemctl", "daemon-reload"])
    subprocess.run(["systemctl", "enable", service_name])
    subprocess.run(["systemctl", "restart", service_name])


# Kharej Tunnel
def backhaul_kharej_client_tcpmuxmenu():
    os.system("clear")
    print("\033[92m ^ ^\033[0m")
    print("\033[92m(\033[91mO,O\033[92m)\033[0m")
    print("\033[92m(   ) \033[92mBackhaul \033[92mKharej Client \033[93mSingle Menu\033[0m")
    print('\033[92m "-"\033[93m══════════════════════════════════\033[0m')
    print("\033[93m───────────────────────────────────────\033[0m")

    backhaul_directory = "/usr/local/bin/backhaul"
    if os.path.exists(backhaul_directory):
        print(f"\033[93mbackhaul exists, skipping\033[0m")
        backhaul_menu()
    else:
        install_prerequisites()
        download_binary()

    print("\033[93m───────────────────────────────────────\033[0m")

    remote_addr = input("\033[93mEnter\033[92m IRAN \033[97m(IPv4/IPv6)\033[93m: \033[0m").strip()
    if ":" in remote_addr:  
        remote_addr = f"[{remote_addr}]"
    remote_addr_with_port = f"{remote_addr}:{23123}"

    config = {
        "remote_addr": remote_addr_with_port,
        "transport": "tcpmux",
        "token": "samirkala",
        "connection_pool": 8,
        "aggressive_pool": false,
        "keepalive_period": 75,
        "dial_timeout": 10,
        "nodelay": false,
        "retry_interval": 3,
        "mux_version": 1,
        "mux_framesize": 32768,
        "mux_recievebuffer": 4194304,
        "mux_streambuffer": 65536,
        "sniffer": false,
        "sniffer_log": "/etc/backhaul_client1.json",
        "web_port": 0,
        "log_level": "info",
    }

    config_path = "/usr/local/bin/backhaul/client.toml"
    with open(config_path, 'w') as config_file:
        config_file.write("[client]\n")
        for key, value in config.items():
            if isinstance(value, bool):
                config_file.write(f'{key} = {"true" if value else "false"}\n')
            elif isinstance(value, int):
                config_file.write(f'{key} = {value}\n')
            else:
                config_file.write(f'{key} = "{value}"\n')

    display_checkmark(f"\033[92mClient config file created at {config_path}\033[0m")
    create_singleclient_service()
    enable_backhaul_reset_client()


def create_singleclient_service():
    service_content = """
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
"""
    service_path = "/etc/systemd/system/backhaul-client.service"
    with open(service_path, 'w') as service_file:
        service_file.write(service_content)
    
    os.system("systemctl daemon-reload")
    os.system("systemctl enable backhaul-client.service")
    os.system("systemctl restart backhaul-client.service")
    display_checkmark(f"Client service file created at {service_path}")


def enable_backhaul_reset_client():
    interval_seconds = 21600
    reset_backhaul_client(interval_seconds)


def reset_backhaul_client(interval):
    service_name = "backhaul_reset.service"

    daemon_script_content = f"""#!/bin/bash
INTERVAL={interval}

while true; do
    /bin/bash /etc/backhaul_reset.sh
    sleep $INTERVAL
done
"""

    with open("/usr/local/bin/backhaul_daemon.sh", "w") as daemon_script_file:
        daemon_script_file.write(daemon_script_content)

    subprocess.run(["chmod", "+x", "/usr/local/bin/backhaul_daemon.sh"])

    service_content = f"""[Unit]
Description=Custom Daemon

[Service]
ExecStart=/usr/local/bin/backhaul_daemon.sh
Restart=always

[Install]
WantedBy=multi-user.target
"""

    with open(f"/etc/systemd/system/{service_name}", "w") as service_file:
        service_file.write(service_content)

    ipsec_reset_script_content = """#!/bin/bash
systemctl daemon-reload 
systemctl restart backhaul-client 
sudo journalctl --vacuum-size=1M --unit=backhaul-client.service
"""

    with open("/etc/backhaul_reset.sh", "w") as script_file:
        script_file.write(ipsec_reset_script_content)

    subprocess.run(["chmod", "+x", "/etc/backhaul_reset.sh"])
    subprocess.run(["systemctl", "daemon-reload"])
    subprocess.run(["systemctl", "enable", service_name])
    subprocess.run(["systemctl", "restart", service_name])


# Tunnel status
def backhaul_single_status():
    os.system("clear")
    print("\033[92m ^ ^\033[0m")
    print("\033[92m(\033[91mO,O\033[92m)\033[0m")
    print("\033[92m(   ) \033[93mBackhaul Status Menu\033[0m")
    print('\033[92m "-"\033[93m══════════════════════════\033[0m')
    print("\033[93m╭───────────────────────────────────────╮\033[0m")
    print("\033[93mYou are viewing the status of your Backhaul services:\033[0m")

    if os.path.exists(SERVER_CONFIG):
        print("\n\033[92mServer:\033[0m")
        service_status(SERVER_SERVICE)
        transport_server = transport_method(SERVER_CONFIG)
        print(f" \033[93mTunnel Method:\033[97m {transport_server} \033[0m")
        service_logs(SERVER_SERVICE)

    if os.path.exists(CLIENT_CONFIG):
        print("\n\033[92mClient:\033[0m")
        service_status(CLIENT_SERVICE)
        transport_client = transport_method(CLIENT_CONFIG)
        print(f" \033[93mTunnel Method:\033[97m {transport_client} \033[0m")
        service_logs(CLIENT_SERVICE)
    
    print("\n0. \033[94mback to the previous menu\033[0m")
    print("\033[93m╰───────────────────────────────────────╯\033[0m")
    choice = input("\033[38;5;205mEnter your choice: \033[0m")
    if choice == "0":
        backhaul_menu()
    else:
        print("\n\033[91mInvalid choice, please try again.\033[0m")


def service_status(service_name):
    output = subprocess.run(
        ["systemctl", "is-active", service_name], capture_output=True, text=True
    )
    status = output.stdout.strip()

    if status == "active":
        print(f" \033[93mStatus:\033[92m Online\033[0m | \033[93mService Name:\033[97m {service_name}\033[0m")
    else:
        print(f" \033[93mStatus:\033[91m Offline\033[0m | \033[93mService Name:\033[97m {service_name}\033[0m")


def service_logs(service_name):
    print("\033[93mService Logs:\033[0m")
    output = subprocess.run(
        ["journalctl", "-u", service_name, "--no-pager", "-n", "5"],
        capture_output=True, text=True
    )
    logs = output.stdout.strip()
    if logs:
        print(f"\033[97m{logs}\033[0m")
    else:
        print("\033[91mNo entries\033[0m")


def transport_method(config_file):
    try:
        with open(config_file, "r") as file:
            for line in file:
                line = line.strip()

                if line.startswith("transport"):
                    transport = line.split("=")[-1].strip().replace('"', '')
                    return transport

    except FileNotFoundError:
        return "\033[91mFile not found\033[0m"
    
    return "\033[91mUnknown transport\033[0m"


SERVER_CONFIG = "/usr/local/bin/backhaul/server.toml"
CLIENT_CONFIG = "/usr/local/bin/backhaul/client.toml"
SERVER_SERVICE = "backhaul-server"
CLIENT_SERVICE = "backhaul-client"


# Edit Tunnel
def backhaul_edit_tcpmuxsingle():
    os.system("clear")
    print("\033[92m ^ ^\033[0m")
    print("\033[92m(\033[91mO,O\033[92m)\033[0m")
    print("\033[92m(   ) \033[92mBackhaul Single TCPMux\033[93m Edit Menu\033[0m")
    print('\033[92m "-"\033[93m══════════════════════════════════\033[0m')
    print("\033[93m╭───────────────────────────────────────╮\033[0m")
    print("\033[93mChoose what to do:\033[0m")
    print("1  \033[93mIRAN Server\033[0m")
    print("2  \033[92mKharej Client\033[0m")
    print("0. \033[94mback to the previous menu\033[0m")
    print("\033[93m╰───────────────────────────────────────╯\033[0m")
    choice = input("\033[38;5;205mEnter your choice Please: \033[0m")
    if choice == "1":
        lines = read_config_server()
        configwssmux_single_server_menu(lines)
            
    elif choice == "2":
        lines = read_config_client()
        configwssmux_single_client_menu(lines)
            
    elif choice == "0":
        clear()
        backhaul_menu()
            
    else:
        print("Invalid choice.")


def read_config_server():
    with open(CONFIG_SERVER, 'r') as file:
        lines = file.readlines()
    return lines


def read_config_client():
    with open(CONFIG_CLIENT, 'r') as file:
        lines = file.readlines()
    return lines


CONFIG_SERVER = "/usr/local/bin/backhaul/server.toml"
SERVICE_SERVER = "backhaul-server"
CONFIG_CLIENT = "/usr/local/bin/backhaul/client.toml"
SERVICE_CLIENT = "backhaul-client"


def configwssmux_single_server_menu(lines):
    while True:
        display_server(lines)
        current_bind_addr = current_value(lines, "bind_addr")
        current_token = current_value(lines, "token")
        current_channel_size = current_value(lines, "channel_size")
        current_keepalive_period = current_value(lines, "keepalive_period")
        current_heartbeat = current_value(lines, "heartbeat")
        current_mux_con = current_value(lines, "mux_con")
        current_mux_version = current_value(lines, "mux_version")
        current_mux_framesize = current_value(lines, "mux_framesize")
        current_mux_recievebuffer = current_value(lines, "mux_recievebuffer")
        current_mux_streambuffer = current_value(lines, "mux_streambuffer")
        print("\033[93m╭───────────────────────────────────────╮\033[0m")
        print(f"1. \033[93mModify \033[92mTunnel port\033[0m (bind_addr) [Current: {current_bind_addr}]\033[0m")
        print(f"2. \033[93mModify \033[92mtoken\033[96m [Current: {current_token}]\033[0m")
        print(f"3. \033[93mModify \033[92mchannel_size\033[96m [Current: {current_channel_size}]\033[0m")
        print(f"4. \033[93mModify \033[92mkeepalive_period\033[96m [Current: {current_keepalive_period}]\033[0m")
        print(f"5. \033[93mModify \033[92mheartbeat\033[96m [Current: {current_heartbeat}]\033[0m")
        print(f"6. \033[93mToggle \033[92mnodelay\033[96m [Current: {current_value(lines, 'nodelay')}]\033[0m")
        print(f"7. \033[93mToggle \033[92msniffer\033[96m [Current: {current_value(lines, 'sniffer')}]\033[0m")
        print("8. \033[93mEdit/Add \033[92mports\033[0m")
        print(f"9. \033[93mModify \033[92mmux_con\033[96m [Current: {current_mux_con}]\033[0m")
        print(f"10. \033[93mModify \033[92mmux_version\033[96m [Current: {current_mux_version}]\033[0m")
        print(f"11. \033[93mModify \033[92mmux_framesize\033[96m [Current: {current_mux_framesize}]\033[0m")
        print(f"12. \033[93mModify \033[92mmux_recievebuffer\033[96m [Current: {current_mux_recievebuffer}]\033[0m")
        print(f"13. \033[93mModify \033[92mmux_streambuffer\033[96m [Current: {current_mux_streambuffer}]\033[0m")
        print("14. \033[92mSave and Restart\033[0m")
        print("15. \033[94mBack to the edit menu\033[0m")
        print("\033[93m╰───────────────────────────────────────╯\033[0m")

        choice = input("\nEnter your choice: ").strip()

        if choice == "1":
            lines = bind_addr(lines)
        elif choice == "2":
            new_value = input(f"\033[93mEnter \033[92mnew token\033[93m (current: {current_token}): \033[0m")
            lines = edit_value(lines, "token", new_value)
        elif choice == "3":
            new_value = input(f"\033[93mEnter \033[92mnew channel_size \033[93m (current: {current_channel_size}): \033[0m")
            lines = edit_numeric(lines, "channel_size", new_value)
        elif choice == "4":
            new_value = input(f"\033[93mEnter \033[92mnew keepalive_period \033[93m (current: {current_keepalive_period}): \033[0m")
            lines = edit_numeric(lines, "keepalive_period", new_value)
        elif choice == "5":
            new_value = input(f"\033[93mEnter \033[92mnew heartbeat interval \033[93m (current: {current_heartbeat}): \033[0m")
            lines = edit_numeric(lines, "heartbeat", new_value)
        elif choice == "6":
            lines = toggle_option(lines, "nodelay")
        elif choice == "7":
            lines = toggle_option(lines, "sniffer")
        elif choice == "8":
            lines = edit_ports(lines)
        elif choice == "9":
            new_value = input(f"\033[93mEnter \033[92mnew mux_con \033[93m (current: {current_mux_con}): \033[0m")
            lines = edit_numeric(lines, "mux_con", new_value)
        elif choice == "10":
            new_value = input(f"\033[93mEnter \033[92mnew mux_version \033[93m (current: {current_mux_version}): \033[0m")
            lines = edit_numeric(lines, "mux_version", new_value)
        elif choice == "11":
            new_value = input(f"\033[93mEnter \033[92mnew mux_framesize \033[93m (current: {current_mux_framesize}): \033[0m")
            lines = edit_numeric(lines, "mux_framesize", new_value)
        elif choice == "12":
            new_value = input(f"\033[93mEnter \033[92mnew mux_recievebuffer \033[93m (current: {current_mux_recievebuffer}): \033[0m")
            lines = edit_numeric(lines, "mux_recievebuffer", new_value)
        elif choice == "13":
            new_value = input(f"\033[93mEnter \033[92mnew mux_streambuffer \033[93m (current: {current_mux_streambuffer}): \033[0m")
            lines = edit_numeric(lines, "mux_streambuffer", new_value)
        elif choice == "14":
            write_config_server(lines)
            restart_service_server()
            display_checkmark("\n\033[92mConfiguration saved and service restarted\033[0m")
            
        elif choice == "15":
            backhaul_edit_tcpmuxsingle()
        else:
            print("\n\033[91mWrong choice, try again.")

def configwssmux_single_client_menu(lines):
    while True:
        display_client(lines)
        current_remote_addr = current_value(lines, "remote_addr")
        current_token = current_value(lines, "token")
        current_connection_pool = current_value(lines, "connection_pool")
        current_keepalive_period = current_value(lines, "keepalive_period")
        current_dial_timeout = current_value(lines, "dial_timeout")
        current_mux_version = current_value(lines, "mux_version")
        current_mux_framesize = current_value(lines, "mux_framesize")
        current_mux_recievebuffer = current_value(lines, "mux_recievebuffer")
        current_mux_streambuffer = current_value(lines, "mux_streambuffer")
        current_retry_interval = current_value(lines, "retry_interval")

        print("\033[93m╭───────────────────────────────────────╮\033[0m")
        print(f"1. \033[93mModify \033[92mIran Server IP\033[0m and \033[92mport\033[96m [Current: {current_remote_addr}]\033[0m")
        print(f"2. \033[93mModify \033[92mtoken\033[96m [Current: {current_token}]\033[0m")
        print(f"3. \033[93mModify \033[92mconnection_pool\033[96m [Current: {current_connection_pool}]\033[0m")
        print(f"4. \033[93mModify \033[92mkeepalive_period\033[96m [Current: {current_keepalive_period}]\033[0m")
        print(f"5. \033[93mModify \033[92mdial_timeout\033[96m [Current: {current_dial_timeout}]\033[0m")
        print(f"6. \033[93mModify \033[92mnodelay\033[96m [Current: {current_value(lines, 'nodelay')}]\033[0m")
        print(f"7. \033[93mModify \033[92msniffer\033[96m [Current: {current_value(lines, 'sniffer')}]\033[0m")
        print(f"8. \033[93mModify \033[92mretry_interval\033[96m [Current: {current_retry_interval}]\033[0m")
        print(f"9. \033[93mModify \033[92mmux_version\033[96m [Current: {current_mux_version}]\033[0m")
        print(f"10. \033[93mModify \033[92mmux_framesize\033[96m [Current: {current_mux_framesize}]\033[0m")
        print(f"11. \033[93mModify \033[92mmux_recievebuffer\033[96m [Current: {current_mux_recievebuffer}]\033[0m")
        print(f"12. \033[93mModify \033[92mmux_streambuffer\033[96m [Current: {current_mux_streambuffer}]\033[0m")
        print("13. \033[92mSave and Restart\033[0m")
        print("14. \033[94mBack to the edit menu\033[0m")
        print("\033[93m╰───────────────────────────────────────╯\033[0m")

        choice = input("\nEnter your choice: ").strip()

        if choice == "1":
            lines = remote_addr(lines)
        elif choice == "2":
            new_value = input(f"\033[93mEnter \033[92mnew token\033[93m (current: {current_token}): \033[0m")
            lines = edit_value(lines, "token", new_value)
        elif choice == "3":
            new_value = input(f"\033[93mEnter \033[92mnew connection_pool \033[93m (current: {current_connection_pool}): \033[0m")
            lines = edit_numeric(lines, "connection_pool", new_value)
        elif choice == "4":
            new_value = input(f"\033[93mEnter \033[92mnew keepalive_period \033[93m (current: {current_keepalive_period}): \033[0m")
            lines = edit_numeric(lines, "keepalive_period", new_value)
        elif choice == "5":
            new_value = input(f"\033[93mEnter \033[92mnew dial_timeout \033[93m (current: {current_dial_timeout}): \033[0m")
            lines = edit_numeric(lines, "dial_timeout", new_value)
        elif choice == "6":
            lines = toggle_option(lines, "nodelay")
        elif choice == "7":
            lines = toggle_option(lines, "sniffer")
        elif choice == "8":
            new_value = input(f"\033[93mEnter \033[92mnew retry_interval \033[93m (current: {current_retry_interval}): \033[0m")
            lines = edit_numeric(lines, "retry_interval", new_value)
        elif choice == "9":
            new_value = input(f"\033[93mEnter \033[92mnew mux_version \033[93m (current: {current_mux_version}): \033[0m")
            lines = edit_numeric(lines, "mux_version", new_value)
        elif choice == "10":
            new_value = input(f"\033[93mEnter \033[92mnew mux_framesize \033[93m (current: {current_mux_framesize}): \033[0m")
            lines = edit_numeric(lines, "mux_framesize", new_value)
        elif choice == "11`":
            new_value = input(f"\033[93mEnter \033[92mnew mux_recievebuffer \033[93m (current: {current_mux_recievebuffer}): \033[0m")
            lines = edit_numeric(lines, "mux_recievebuffer", new_value)
        elif choice == "12":
            new_value = input(f"\033[93mEnter \033[92mnew mux_streambuffer \033[93m (current: {current_mux_streambuffer}): \033[0m")
            lines = edit_numeric(lines, "mux_streambuffer", new_value)
        elif choice == "13":
            write_config_client(lines)
            restart_service_client()
            display_checkmark("\n\033[92mConfiguration saved and client service restarted\033[0m")
            
        elif choice == "14":
            backhaul_edit_tcpmuxsingle()
        else:
            print("\n\033[91mWrong choice, try again.")


def display_server(lines):
    print("\033[92m ^ ^\033[0m")
    print("\033[92m(\033[91mO,O\033[92m)\033[0m")
    print("\033[92m(   ) \033[93mServer Edit Menu\033[0m")
    print('\033[92m "-"\033[93m══════════════════════════\033[0m')
    print("\033[93m╭──────────────────\033[92m[Server] Configuration\033[93m─────────────────────╮\033[0m")
    for line in lines:
        print(line.strip())
    print("\033[93m╰─────────────────────────────────────────────────────────────╯\033[0m")


def current_value(lines, key):
    for line in lines:
        if line.startswith(key):
            return line.split("=")[-1].strip().replace('"', '')
    return None


def bind_addr(lines):
    for i, line in enumerate(lines):
        if line.startswith("bind_addr"):
            current_value = line.split("=")[-1].strip().replace('"', '')
            ip, current_port = current_value.split(":")
            
            new_port = input(f"\033[93mEnter \033[92mnew \033[96mTunnel port \033[97m(current: {current_port})\033[93m: \033[0m").strip()
            if new_port:
                lines[i] = f'bind_addr = "{ip}:{new_port}"\n'
            break
    return lines


def edit_value(lines, key, new_value):
    for i, line in enumerate(lines):
        if line.startswith(key):
            lines[i] = f'{key} = "{new_value}"\n'
    return lines


def remote_addr(lines):
    for i, line in enumerate(lines):
        if line.startswith("remote_addr"):
            current_value = line.split("=")[-1].strip().replace('"', '')

            match = re.match(r'^\[?(.*?)\]?:([0-9]+)$', current_value)
            if not match:
                raise ValueError("Invalid remote_addr format")

            ip, current_port = match.groups()

            new_ip = input(f"\033[93mEnter new Iran Server IP \033[97m(current: {ip})\033[93m: \033[0m").strip() or ip
            new_port = input(f"\033[93mEnter new Iran Server port \033[97m(current: {current_port})\033[93m: \033[0m").strip() or current_port

            if ":" in new_ip and not new_ip.startswith("["):
                new_ip = f"[{new_ip}]"
            elif "." in new_ip and new_ip.startswith("["):
                new_ip = new_ip.strip("[]") 

            lines[i] = f'remote_addr = "{new_ip}:{new_port}"\n'
            break
    return lines


def edit_numeric(lines, key, new_value):
    for i, line in enumerate(lines):
        if line.startswith(key):
            lines[i] = f'{key} = {new_value}\n'
    return lines


def edit_ports(lines):
    ports_section = False
    ports_index_start = -1
    ports_index_end = -1
    ports = []

    for i, line in enumerate(lines):
        if line.startswith("ports = ["):
            ports_section = True
            ports_index_start = i
        if ports_section and line.strip() == "]":
            ports_index_end = i
            break

    if ports_index_start != -1 and ports_index_end != -1:
        ports = lines[ports_index_start + 1:ports_index_end]

    print("\033[93m───────────────────────────────────────\033[0m")
    print("\033[92mCurrent Ports Configuration:\033[0m")
    print("\033[93m───────────────────────────────────────\033[0m")
    for i, port in enumerate(ports):
        print(f"{i + 1}) {port.strip()}")

    choice = input("\n\033[93mEnter the \033[92mnumber \033[93mto edit \033[97mor 'add' \033[92m to add a new port\033[97m:\033[0m ").strip().lower()

    if choice == 'add':
        add_choice = input("\033[93m (1)\033[92m regular port \033[93m (2)\033[94m port range? \033[0m").strip()

        if add_choice == '1':
            print("\033[93m╭───────────────────────────────────────╮\033[0m")
            print("1) \033[93mlocal_port=remote_port \033[97m(example: 4000=5000)")
            print("2) \033[93mlocal_ip:local_port=remote_port \033[97m(example: 127.0.0.2:443=5201)")
            print("3) \033[93mlocal_port=remote_ip:remote_port \033[97m(example: 443=1.1.1.1:5201)")
            print("4) \033[93mlocal_ip:local_port=remote_ip:remote_port \033[97m(example: 127.0.0.2:443=1.1.1.1:5201)")
            print("\033[93m╰───────────────────────────────────────╯\033[0m")

            regular_format_choice = input("Enter choice: \033[0m").strip()

            if regular_format_choice == '1':
                local_port = input("\033[93mEnter local port: \033[0m").strip()
                remote_port = input("\033[93mEnter remote port: \033[0m").strip()
                new_port = f'{local_port}={remote_port}'
            elif regular_format_choice == '2':
                local_ip = input("\033[93mEnter local IP: \033[0m").strip()
                local_port = input("\033[93mEnter local port: \033[0m").strip()
                remote_port = input("\033[93mEnter remote port: \033[0m").strip()
                new_port = f'{local_ip}:{local_port}={remote_port}'
            elif regular_format_choice == '3':
                local_port = input("\033[93mEnter local port: \033[0m").strip()
                remote_ip = input("\033[93mEnter remote IP: \033[0m").strip()
                remote_port = input("\033[93mEnter remote port: \033[0m").strip()
                new_port = f'{local_port}={remote_ip}:{remote_port}'
            elif regular_format_choice == '4':
                local_ip = input("\033[93mEnter local IP: \033[0m").strip()
                local_port = input("\033[93mEnter local port: \033[0m").strip()
                remote_ip = input("\033[93mEnter remote IP: \033[0m").strip()
                remote_port = input("\033[93mEnter remote port: \033[0m").strip()
                new_port = f'{local_ip}:{local_port}={remote_ip}:{remote_port}'
            else:
                print("\033[91mInvalid choice!\033[0m")
                return lines

        elif add_choice == '2':
            print("\033[93m╭───────────────────────────────────────╮\033[0m")
            print("1)\033[93m port-range \033[97m(example: 443-600)")
            print("2)\033[93m port-range:remote-port \033[97m(example: 443-600:5201)")
            print("3)\033[93m port-range=remote_ip:remote-port \033[97m(example: 443-600=1.1.1.1:5201)")
            print("\033[93m╰───────────────────────────────────────╯\033[0m")
            
            range_format_choice = input("Enter choice: \033[0m").strip()

            if range_format_choice == '1':
                port_range = input("\033[93mEnter \033[92mport range \033[93m(e.g., 500-600): \033[0m").strip()
                new_port = f'{port_range}'
            elif range_format_choice == '2':
                port_range = input("\033[93mEnter \033[92mport range \033[93m(e.g., 500-600): \033[0m").strip()
                forward_port = input("\033[93mEnter \033[92mremote port\033[93m: \033[0m").strip()
                new_port = f'{port_range}:{forward_port}'
            elif range_format_choice == '3':
                port_range = input("\033[93mEnter \033[92mport range\033[93m (e.g., 500-600): \033[0m").strip()
                remote_ip = input("\033[93mEnter \033[92mremote IP: \033[0m").strip()
                forward_port = input("\033[93mEnter \033[92mremote port: \033[0m").strip()
                new_port = f'{port_range}={remote_ip}:{forward_port}'
            else:
                print("\033[91mInvalid choice!\033[0m")
                return lines

        else:
            print("\033[91mWrong choice, choose 1 or 2.\033[0m")
            return lines

        ports.append(f'    "{new_port}",\n')

    else:
        index = int(choice) - 1
        current_port = ports[index].strip()

        if '-' in current_port or ':' in current_port:
            new_port = input(f"\033[93mEdit port range \033[96m{current_port}\033[97m (press Enter to keep unchanged)\033[93m: \033[0m")
        else:
            new_port = input(f"\033[93mEdit regular port \033[96m{current_port}\033[97m (press Enter to keep unchanged)\033[93m: \033[0m")

        if new_port:
            ports[index] = f'    "{new_port}",\n'

    lines = lines[:ports_index_start + 1] + ports + lines[ports_index_end:]

    return lines


def toggle_option(lines, key):
    current_val = true_value(lines, key)
    print("\033[93m───────────────────────────────────────\033[0m")
    print(f"\033[93mCurrent \033[92m{key}\033[93m:\033[97m {current_val}\033[0m")
    print("\033[93m╭───────────────────────────────────────╮\033[0m")
    print("\033[93mChoose a new value:\033[0m")
    print("1)\033[92m true\033[0m")
    print("2)\033[91m false\033[0m")
    print("\033[93m╰───────────────────────────────────────╯\033[0m")
    choice = input("Enter your choice: ").strip()
    
    if choice == "1":
        new_value = "true"
    elif choice == "2":
        new_value = "false"
    else:
        print("\033[91mWrong choice!\033[0m")
        return lines
    
    for i, line in enumerate(lines):
        if line.startswith(key):
            lines[i] = f'{key} = {new_value}\n'
            break
    
    return lines


def true_value(lines, key):
    for line in lines:
        if line.startswith(key):
            return line.split("=")[-1].strip().replace('"', '')
    return None


def display_client(lines):
    print("\033[92m ^ ^\033[0m")
    print("\033[92m(\033[91mO,O\033[92m)\033[0m")
    print("\033[92m(   ) \033[93mClient Edit Menu\033[0m")
    print('\033[92m "-"\033[93m══════════════════════════\033[0m')
    print("\033[93m╭──────────────────\033[92m[Client] Configuration\033[93m─────────────────────╮\033[0m")
    for line in lines:
        print(line.strip())
    print("\033[93m╰─────────────────────────────────────────────────────────────╯\033[0m")


def write_config_server(lines):
    with open(CONFIG_SERVER, 'w') as file:
        file.writelines(lines)

def restart_service_server():
    os.system(f"systemctl restart {SERVICE_SERVER}")


def write_config_client(lines):
    with open(CONFIG_CLIENT, 'w') as file:
        file.writelines(lines)

def restart_service_client():
    os.system(f"systemctl restart {SERVICE_CLIENT}")


# Unistall TUNNEL
def backhaul_uninstall_single():
    os.system("clear")
    print("\033[92m ^ ^\033[0m")
    print("\033[92m(\033[91mO,O\033[92m)\033[0m")
    print("\033[92m(   ) \033[92mBackhaul\033[93m Uninstall Menu\033[0m")
    print('\033[92m "-"\033[93m══════════════════════════════════\033[0m')
    print("\033[93m╭───────────────────────────────────────╮\033[0m")
    print("\033[93mChoose what to do:\033[0m")
    print("1  \033[93mIRAN Server\033[0m")
    print("2  \033[92mKharej Client\033[0m")
    print("0. \033[94mback to the previous menu\033[0m")
    print("\033[93m╰───────────────────────────────────────╯\033[0m")
    choice = input("\033[38;5;205mEnter your choice Please: \033[0m")
    if choice == "1":
        backhaul_uninstall_single_iran()
            
    elif choice == "2":
        backhaul_uninstall_single_kharej()
            
    elif choice == "0":
        backhaul_menu()
            
    else:
        print("Invalid choice.")


def backhaul_uninstall_single_iran():
    os.system("clear")
    print("\033[92m ^ ^\033[0m")
    print("\033[92m(\033[91mO,O\033[92m)\033[0m")
    print("\033[92m(   ) \033[93mUninstalling Iran Server\033[0m")
    print('\033[92m "-"\033[93m══════════════════════════\033[0m')
    print("\033[93mUninstalling Iran Server...\033[0m")
    uninstall_service(BACKHAUL_SERVER_SERVICE)
    display_notification("\033[93mRemoving configuration files for Iran Server...\033[0m")
    delete_dir(BACKHAUL_DIR, "directory")
    delete_dir(BACKHAUL_JSON, "file")
    delete_dir(SERVER_TOML, "file")
    rmv_backhauldirectory()
    reloaddaemon()
    loadbar("Finishing Iran Server uninstallation")
    display_checkmark("\n\033[92mUninstallation of Iran Server complete.\033[0m")

def display_notification(message):
    print("\u2728 " + message)

def backhaul_uninstall_single_kharej():
    os.system("clear")
    print("\033[92m ^ ^\033[0m")
    print("\033[92m(\033[91mO,O\033[92m)\033[0m")
    print("\033[92m(   ) \033[93mUninstalling Kharej Client\033[0m")
    print('\033[92m "-"\033[93m══════════════════════════\033[0m')
    print("\033[93mUninstalling Kharej Client...\033[0m")
    uninstall_service(BACKHAUL_CLIENT_SERVICE)
    display_notification("\033[93mRemoving configuration files for Kharej Client...\033[0m")
    delete_dir(BACKHAUL_DIR, "directory")
    delete_dir(BACKHAUL_JSON, "file")
    delete_dir(CLIENT_TOML, "file")
    rmv_backhauldirectory()
    reloaddaemon()

    loadbar("Finishing Kharej Client uninstallation")
    display_checkmark("\n\033[92mUninstallation of Kharej Client complete.\033[0m")

def uninstall_service(service_name):
    subprocess.run(["systemctl", "stop", service_name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(["systemctl", "disable", service_name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    service_file = f"/etc/systemd/system/{service_name}.service"
    if os.path.exists(service_file):
        os.remove(service_file)

def delete_dir(path, type_of_path):
    if os.path.exists(path):
        try:
            if type_of_path == "directory":
                shutil.rmtree(path)  
            elif type_of_path == "file":
                os.remove(path) 
        except OSError as e:
            print(f"\033[91mError: {e}\033[0m")

def rmv_backhauldirectory():
    print("\033[93mWould you like to delete the \033[92mBackhaul project\033[93m directory? (\033[92myes\033[93m/\033[91mno\033[93m) :\033[0m ", end="")
    choice = input().strip().lower()
    if choice in ["yes", "y"]:
        delete_dir(BACKHAUL_INSTALL_DIR, "directory")

def reloaddaemon():
    print("\n\033[93mReloading systemd daemon...\033[0m")
    subprocess.run(["systemctl", "daemon-reload"])

def loadbar(action, length=20):
    print(f"\n\033[93m{action}...\033[0m", end="")
    for i in range(length):
        time.sleep(0.1)  
        print("\033[92m█\033[0m", end="", flush=True)
    print()  


BACKHAUL_SERVER_SERVICE = "backhaul-server"
BACKHAUL_CLIENT_SERVICE = "backhaul-client"
SERVER_TOML = "/usr/local/bin/backhaul/server.toml"
CLIENT_TOML = "/usr/local/bin/backhaul/client.toml"
BACKHAUL_JSON = "/etc/backhaul.json"
BACKHAUL_DIR = "/etc/blackhaul"
BACKHAUL_INSTALL_DIR = "/usr/local/bin/backhaul"


backhaul_menu()
