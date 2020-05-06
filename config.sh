#!/bin/bash
# ------------------------------------------------------------------
# [Author     ] acidcrash376
# [Title      ] Initial Configuration Script
# [Description] Script to setup from initial install. Checks some required
#		packages are installed, checks localisation, IP configuration
#		and DHCP server instance are configured.
#		Still to do: hostapd install
# [Last Update] 06/05/2020
# [Version    ] v0.5
# [URL        ] https://github.com/acidcrash376/Linux-Router-Config
# ------------------------------------------------------------------
#
#USAGE="Usage: command -ihv args"
print_usage() {
	printf "Usage: sudo ./config.sh -a <ip> -b <subnet> -c <gateway> -d <dns>"
}
#
# --- Options processing -------------------------------------------

# --- Functions ----------------------------------------------------
function checkpriv {
if [ "$EUID" -ne 0 ]
  	then
		echo -e "\e[31m        Please run as root! Exiting...\e[39m"
  		exit
fi
}

function getreq {
dpkg -s $tool &> /dev/null
if [ $? -ne 0 ]
	then
                echo -e "\e[33m" $tool "is not installed, installing...\e[39m"
                echo " "
                apt update &> /dev/null
                apt install $tool -y &> /dev/null
                echo -e "\e[32m" $tool "has been installed, moving on...\e[39m"
                echo " "
        else
                echo -e "\e[32m"  $tool "is already installed, moving on...\e[39m"
		echo " "
fi
}

# --- Body ----------------------------------------------------------
echo " "
echo -e "       " "\e[97m\e[1m\e[4m\e[44mConfiguration Script\e[39m\e[49m\e[0m"
echo " "
echo " "

checkpriv


echo -e "\e[36m\e[1m\e[4m> Checking pre-requisites are installed\e[39m\e[0m"
echo " "

tool="net-tools"
getreq
tool="isc-dhcp-server"
getreq

# --- --- Set locale and keyboard --- ---
echo -e "\e[36m\e[1m\e[4m> Setting Locale and Keyboard Layout\e[39m\e[0m]"
echo ""
localectl set-locale LANG=en_GB.UTF-8
setxkbmap gb
echo -e "\e[32mLocale & Keyboard configured successfully\e[39m"

# --- --- Set IP --- ---
echo "network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:
      addresses:
        - 172.16.0.156/24
      gateway4: 172.16.0.2
      nameservers:
          search: []
          addresses: [1.1.1.1]
    ens34:
      addresses:
        - 172.17.0.2/24
      nameservers:
          search: []
          addresses: [1.1.1.1]
" > /etc/netplan/11-network-manager-eth.yaml
#cat /etc/netplan/11-network-manager-eth.yaml
echo " "
echo -e "\e[36m\e[1m\e[4m> Configuring Network Interfaces\e[39m\e[0m"
echo " "
sudo netplan apply
if [ $? -eq 0 ]
	then
		echo -e "\e[32mNetwork interfaces configured successfully\e[39m"
		echo " "
		ens33=$(ip a | grep ens33 | grep inet | awk '{print $2}' | cut -d '/' -f1)
		ens34=$(ip a | grep ens34 | grep inet | awk '{print $2}' | cut -d '/' -f1)
		echo -e "\e[33mIP address of ens33 is\e[49m" $ens33
		echo -e "\e[33mIP address of ens34 is\e[49m" $ens34
		echo " "
	else
		echo -e "\e[31mNetwork interfaces configuration failed\e[39m"
		exit
	fi


# --- --- Enable IPv4 Forwarding --- ---
echo -e "\e[36m\e[1m\e[4m> Configure IP Forwarding\e[39m\e[0m"
echo " "
cp /etc/sysctl.conf /etc/sysctl.conf.bak
echo -e "\e[33msysctl.conf backed up to \e[93m/etc/sysctl.conf.bak\e[39m"
echo " "
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
echo -e "\e[32mIP Forwarding configured successfully\e[39m"
echo " "

# --- --- DHCP Server --- ---
echo -e "\e[36m\e[1m\e[4m> Configure IP Forwarding\e[39m\e[0m"
echo " "
cp /etc/default/isc-dhcp-server /etc/default/isc-dhcp-server.bak
echo -e "\e[33misc-dhcp-server backed up to \e[93m/etc/default/isc-dhcp-server.bak\e[39m"

sed -i 's/INTERFACESv4=""/INTERFACESv4="ens34"/g' /etc/default/isc-dhcp-server

cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcp.conf.bak
echo -e "\e[33mdhcpd.conf backed up to \e[93m/etc/dhcp/dhcpd.conf.bak\e[39m"
echo " "
echo "ddns-update-style none;
default-lease-time 600;
max-lease-time 7200;
option domain-name-servers 1.1.1.1;
option domain-name \"internet.acs\";
authorative;
log-facility local7;

subnet 172.17.0.0 netmask 255.255.255.0 {
range 172.17.0.10 172.17.0.40;
option subnet-mask 255.255.255.0;
option domain-name-servers 1.1.1.1;
option domain-name \"internet.acs\";
option broadcast-address 172.17.0.255;
option routers 172.17.0.2;
default-lease-time 600;
max-lease-time 7200;
}
" > /etc/dhcp/dhcpd.conf
echo -e "\e[33mDHCP pool configured on ens34\e[39m"
echo -e "\e[33mPool range: 172.17.0.10 - 172.17.0.40\e[39m"
echo " "
systemctl restart isc-dhcp-server
systemctl status isc-dhcp-server &> /dev/null
if [ $? -eq 0 ]
	then
		echo -e "\e[32mDHCP configured successfully\e[39m"
		echo " "
	else
		echo -e "\e[31mDHCP configuration failed, check config\e[39m"
		systemctl status isc-dhcp-server
		exit
fi

# --- --- iptables, NAT --- ---
echo -e "\e[36m\e[1m\e[4m> Configure iptables NAT\e[39m\e[0m"
echo " "
iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE
echo -e "\e[32miptables NAT  configured successfully\e[39m"
echo " "

echo -e "       " "\e[97m\e[1m\e[4m\e[44mScript Complete\e[39m\e[49m\e[0m"
echo " "
