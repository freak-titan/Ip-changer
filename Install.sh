#!/bin/bash

# Check if the script is being run as root
if [ "$UID" -ne 0 ]; then
    echo "Script must be run as root."
    exit 1
fi

# Function to install required packages
install_packages() {
    local distro
    distro=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
    distro=${distro//\"/}
    
    case "$distro" in
        *"Ubuntu"* | *"Debian"*)
            apt-get update
            apt-get install -y curl tor
            ;;
        *"Fedora"* | *"CentOS"* | *"Red Hat"* | *"Amazon Linux"*)
            yum update
            yum install -y curl tor
            ;;
        *"Arch"*)
            pacman -S --noconfirm curl tor
            ;;
        *)
            echo "Unsupported distribution: $distro. Please install curl and tor manually."
            exit 1
            ;;
    esac
}

# Check if curl and tor are installed, install them if not
if ! command -v curl &> /dev/null || ! command -v tor &> /dev/null; then
    echo "Installing curl and tor"
    install_packages
fi

# Start tor service if it's not already running
if ! systemctl --quiet is-active tor.service; then
    echo "Starting tor service"
    systemctl start tor.service
fi

# Function to get the current IP address
get_ip() {
    local url get_ip ip
    url="https://checkip.amazonaws.com"
    get_ip=$(curl -s -x socks5h://127.0.0.1:9050 "$url")
    ip=$(echo "$get_ip" | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}')
    echo "$ip"
}

# Function to change the IP address
change_ip() {
    echo "Reloading tor service"
    systemctl reload tor.service
    echo -e "\033[34mNew IP address: $(get_ip)\033[0m"
}

# Clear the screen and display the ASCII art
clear
cat << EOF
IP-Changer
                                                                                                       
EOF

# Main loop to change IP address
while true; do
    read -rp $'\033[34mEnter time interval in seconds (type 0 for infinite IP changes): \033[0m' interval
    read -rp $'\033[34mEnter number of times to change IP address (type 0 for infinite IP changes): \033[0m' times

    if [ "$interval" -eq "0" ] || [ "$times" -eq "0" ]; then
        echo "Starting infinite IP changes"
        while true; do
            change_ip
            interval=$(shuf -i 10-20 -n 1)
            sleep "$interval"
        done
    else
        for ((i=0; i< times; i++)); do
            change_ip
            sleep "$interval"
        done
    fi
done
