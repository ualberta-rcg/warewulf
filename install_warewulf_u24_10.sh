#!/bin/bash

# Exit on error
set -e

# Define variables
INTERFACE="ens19"
IP_ADDRESS="172.16.254.1"
NETMASK="255.255.255.0"
SUBNET="172.16.254.0"
RANGE_START="172.16.254.100"
RANGE_END="172.16.254.200"
GATEWAY="172.16.254.1"

# Update and install dependencies
apt update && apt upgrade -y
apt install -y build-essential tftp tftpd-hpa nfs-kernel-server isc-dhcp-server

# Install Warewulf
wget https://github.com/warewulf/warewulf/releases/download/v4.4.0/warewulf-4.4.0.tar.gz
mkdir -p /opt/warewulf
cd /opt/warewulf
tar -xvzf ~/warewulf-4.4.0.tar.gz
cd warewulf-4.4.0
./configure && make && make install

# Configure DHCP for PXE
cat <<EOL > /etc/dhcp/dhcpd.conf
subnet $SUBNET netmask $NETMASK {
    range $RANGE_START $RANGE_END;
    option routers $GATEWAY;
    option broadcast-address 172.16.254.255;
    next-server $IP_ADDRESS;
    filename "pxelinux.0";
}
EOL

sed -i "s/INTERFACESv4=.*/INTERFACESv4=\"$INTERFACE\"/" /etc/default/isc-dhcp-server

systemctl restart isc-dhcp-server

# Configure TFTP
sed -i "s/TFTP_ADDRESS=.*/TFTP_ADDRESS=\"$IP_ADDRESS:69\"/" /etc/default/tftpd-hpa
systemctl restart tftpd-hpa

# Configure Warewulf
wwctl configure
wwctl configure dhcp
wwctl configure nfs
wwctl configure tftp

# Enable Warewulf services
systemctl enable warewulfd
systemctl start warewulfd

# Verify installation
echo "Warewulf installation and configuration completed successfully."
