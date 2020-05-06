# Linux-Router-Config
Script for configuring a Linux box (soon to be a RaspberryPi) to act as a light weight router

# [Author     ] acidcrash376
# [Title      ] Initial Configuration Script
# [Description] Script to setup from initial install. Checks some required packages are installed, checks localisation, IP configuration and DHCP server instance are configured. Still to do: hostapd install
# [Last Update] 06/05/2020
# [Version    ] v0.5
# [URL        ] https://github.com/acidcrash376/Linux-Router-Config

Script currently assumes you are running on a single WAN and single LAN instance, configure the language and keyboard layout, set the IP addresses, configure DHCP on the LAN interface and configure NAT.

# To do:
* Hostapd - wireless access point for LAN interface
* Generalisation - Make the script a little more generic and require less back end tweaking, specifically interface names
