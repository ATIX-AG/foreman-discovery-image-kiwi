#!/bin/bash
#======================================
# Functions...
#--------------------------------------
test -f /.kconfig && . /.kconfig

#======================================
# Greeting...
#--------------------------------------
echo "Configure image: [${kiwi_iname}]..."

# On Debian based distributions the kiwi built in way
# to setup locale, keyboard and timezone via systemd tools
# does not work because not(yet) provided by the distribution.
# Thus the following manual steps to make the values provided
# in the image description effective needs to be done.
#
#=======================================
# Setup system locale
#---------------------------------------
echo "LANG=${kiwi_language}" > /etc/locale.conf

#=======================================
# Setup system keymap
#---------------------------------------
echo "KEYMAP=${kiwi_keytable}" > /etc/vconsole.conf
echo "FONT=eurlatgr.psfu" >> /etc/vconsole.conf
echo "FONT_MAP=" >> /etc/vconsole.conf
echo "FONT_UNIMAP=" >> /etc/vconsole.conf

#=======================================
# Setup system timezone
#---------------------------------------
[ -f /etc/localtime ] && rm /etc/localtime
ln -s /usr/share/zoneinfo/${kiwi_timezone} /etc/localtime

#=======================================
# Setup HW clock to UTC
#---------------------------------------
echo "0.0 0 0.0" > /etc/adjtime
echo "0" >> /etc/adjtime
echo "UTC" >> /etc/adjtime

#======================================
# Disable systemd NTP timesync
#--------------------------------------
baseRemoveService systemd-timesyncd

#======================================
# Enable firstboot resolv.conf setting
#--------------------------------------
baseInsertService symlink-resolvconf

#======================================
# Setup default target, multi-user
#--------------------------------------
baseSetRunlevel 3

#======================================
# Clear apt-get data
#--------------------------------------
apt-get clean
rm -r /var/lib/apt/*
rm -r /var/cache/apt/*

#=======================================
# Foreman Discovery Image
#---------------------------------------

echo " * ensure /etc/os-release is present (needed for RHEL 7.0)"
touch /etc/os-release

echo " * disabling legacy network services (needed for RHEL 7.0)"
systemctl disable network.service

echo " * disabling kdump crash service"
systemctl disable kdump.service

echo " * configuring NetworkManager and udev/nm-prepare"
cat > /etc/NetworkManager/NetworkManager.conf <<'NM'
[main]
monitor-connection-files=no
no-auto-default=*
plugins=ifupdown,keyfile
[logging]
level=DEBUG

[ifupdown]
managed=false

[keyfile]
unmanaged-devices=*,except:type:ethernet
NM
cat > /etc/udev/rules.d/81-nm-prepare.rules <<'UDEV'
ACTION=="add", SUBSYSTEM=="net", NAME!="lo", RUN+="/usr/bin/systemd-cat -t nm-prepare /usr/bin/nm-prepare %k"
UDEV

echo " * configuring TFTP firewall modules"
echo -e "ip_conntrack_tftp\nnf_conntrack_netbios_ns" > /etc/modules-load.d/tftp-firewall.conf

# https://blog.thewatertower.org/2019/05/01/tftp-part-2-the-tftp-client-requires-a-firewalld-as-well/
firewall-offline-cmd --new-policy hostTftpTraffic
firewall-offline-cmd --policy hostTftpTraffic --add-ingress-zone HOST
firewall-offline-cmd --policy hostTftpTraffic --add-egress-zone ANY
firewall-offline-cmd --policy hostTftpTraffic --add-service tftp

echo " * enabling NetworkManager system services (needed for RHEL 7.0)"
systemctl enable NetworkManager.service
systemctl enable NetworkManager-dispatcher.service
systemctl enable NetworkManager-wait-online.service

echo " * enabling nm-prepare service"
systemctl enable nm-prepare.service

echo " * enabling required system services"
systemctl enable ipmi.service
systemctl enable foreman-proxy.service
systemctl enable discovery-fetch-extensions.path
systemctl enable discovery-start-extensions.service
systemctl enable discovery-menu.service
systemctl enable discovery-script-pxe.service
systemctl enable discovery-script-pxeless.service

# register service is started manually from discovery-menu
systemctl disable discovery-register.service

echo " * disabling some unused system services"
systemctl disable ipmi.service

echo " * open foreman-proxy port via firewalld"
firewall-offline-cmd --zone=public --add-port=8443/tcp --add-port=8448/tcp

echo " * setting up foreman proxy service"
sed -i 's/After=.*/After=basic.target network-online.target nm-prepare.service/' /usr/lib/systemd/system/foreman-proxy.service
sed -i 's/Wants=.*/Wants=basic.target network-online.target nm-prepare.service/' /usr/lib/systemd/system/foreman-proxy.service
sed -i '/\[Unit\]/a ConditionPathExists=/etc/NetworkManager/system-connections/primary' /usr/lib/systemd/system/foreman-proxy.service
sed -i '/\[Service\]/a EnvironmentFile=-/etc/default/discovery' /usr/lib/systemd/system/foreman-proxy.service
sed -i '/\[Service\]/a ExecStartPre=/usr/bin/generate-proxy-cert' /usr/lib/systemd/system/foreman-proxy.service
sed -i '/\[Service\]/a PermissionsStartOnly=true' /usr/lib/systemd/system/foreman-proxy.service
sed -i '/\[Service\]/a TimeoutStartSec=9999' /usr/lib/systemd/system/foreman-proxy.service
/sbin/usermod -a -G tty foreman-proxy

cat >/etc/foreman-proxy/settings.yml <<'CFG'
---
:settings_directory: /etc/foreman-proxy/settings.d
# certificate is generated by /usr/bin/generate-proxy-cert
:ssl_certificate: /etc/foreman-proxy/cert.pem
:ssl_ca_file: /etc/foreman-proxy/cert.pem
:ssl_private_key: /etc/foreman-proxy/key.pem
:daemon: true
:http_port: 8448
:https_port: 8443
:log_file: SYSLOG
:log_level: DEBUG
:log_buffer: 1000
:log_buffer_errors: 500
CFG

cat >/etc/foreman-proxy/settings.d/discovery_image.yml <<'CFG'
---
:enabled: true
CFG

cat >/etc/foreman-proxy/settings.d/bmc.yml <<'CFG'
---
:enabled: true
:bmc_default_provider: shell
CFG

cat >/etc/foreman-proxy/settings.d/facts.yml <<'CFG'
---
:enabled: true
CFG

cat >/etc/foreman-proxy/settings.d/logs.yml <<'CFG'
---
:enabled: true
CFG

echo " * setting up systemd"
echo "DumpCore=no" >> /etc/systemd/system.conf

echo " * setting multi-user.target as default"
systemctl set-default multi-user.target

echo " * setting up journald and ttys"
systemctl disable getty@tty1.service getty@tty2.service
systemctl mask getty@tty1.service getty@tty2.service
echo "Storage=volatile" >> /etc/systemd/journald.conf
echo "RuntimeMaxUse=25M" >> /etc/systemd/journald.conf
echo "ForwardToSyslog=no" >> /etc/systemd/journald.conf
echo "ForwardToConsole=no" >> /etc/systemd/journald.conf
systemctl enable journalctl.service

echo " * setting suid bits"
chmod +s /sbin/ethtool
chmod +s /usr/sbin/dmidecode
chmod +s /usr/bin/ipmitool

# Add foreman-proxy user to sudo and disable interactive tty for reboot
echo " * setting up sudo"
sed -i -e 's/^Defaults.*requiretty/Defaults !requiretty/g' /etc/sudoers
echo "foreman-proxy ALL=NOPASSWD: /usr/sbin/reboot" >> /etc/sudoers
echo "foreman-proxy ALL=NOPASSWD: /usr/sbin/shutdown" >> /etc/sudoers
echo "foreman-proxy ALL=NOPASSWD: /usr/sbin/kexec" >> /etc/sudoers

echo " * dropping some friendly aliases"
echo "alias vim=vi" >> /root/.bashrc
echo "alias halt=poweroff" >> /root/.bashrc

# Base env for extracting zip extensions
mkdir -p /opt/extension/{bin,lib,lib/ruby,facts}

echo " * setting up lldp service"
systemctl enable lldpad.socket
cat > /etc/udev/rules.d/82-enable-lldp.rules <<'UDEV'
ACTION=="add", SUBSYSTEM=="net", NAME!="lo", TAG+="systemd", ENV{SYSTEMD_WANTS}="enable-lldp@%k.service"
UDEV

echo " * enable promiscuous mode on all physical network interfaces"
cat > /etc/udev/rules.d/83-enable-promiscuous-mode.rules <<'UDEV'
ACTION=="add", SUBSYSTEM=="net", NAME!="lo", TAG+="systemd", ENV{SYSTEMD_WANTS}="enable-promiscuous-mode@%k.service"
UDEV

# extra modules for livecd-creator/livemedia-creator
echo 'add_drivers+="mptbase mptscsih mptspi hv_storvsc hid_hyperv hv_netvsc hv_vmbus"' > /etc/dracut.conf.d/99-discovery.conf

echo '0.1-atix' > /usr/share/fdi/VERSION

# Install required rubygems
gem install newt -v 0.9.7
apt -y autoremove make git gcc ruby-dev libnewt-dev
gem install facter -v 4.2.10
gem install fast_gettext -v 1.8.0
gem install smart_proxy_discovery_image -v 1.6.0
