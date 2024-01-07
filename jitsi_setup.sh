#!/bin/bash
# Set and get repo
echo 'deb https://download.jitsi.org stable/' >> /etc/apt/sources.list.d/jitsi-stable.list
wget -qO - https://download.jitsi.org/jitsi-key.gpg.key | apt-key add -
apt-get update

# set parameters for jitsi
echo "DefaultLimitNOFILE=65000" >> /etc/systemd/system.conf
echo "DefaultLimitNPROC=65000" >> /etc/systemd/system.conf
echo "DefaultTasksMax=65000" >> /etc/systemd/system.conf

systemctl daemon-reload # reload

# set install parameters for jitsi
sudo apt-get install debconf-utils -y
cat << EOF | debconf-set-selections
jitsi-meet-web-config   jitsi-meet/jaas-choice  boolean false
jitsi-meet-web-config   jitsi-meet/cert-choice  select  I want to use my own certificate
jitsi-videobridge2      jitsi-videobridge/jvb-hostname  string  meet.xn--rotzlffel-47a.ch
EOF

# install jitsi
export DEBIAN_FRONTEND="noninteractive"
apt install jitsi-meet -y
