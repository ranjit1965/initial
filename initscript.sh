#!/bin/bash
#
SERVER="root@serverb"
#
#echo "Installing HTTPD..."
ssh $SERVER "dnf install -y httpd"
#
echo "Updating Apache Port from 80 to 82..."
ssh $SERVER "sed -i 's/^Listen 80$/Listen 82/' /etc/httpd/conf/httpd.conf"

#
echo "Adding webpage content..."
ssh $SERVER "echo 'All the best guys keep rocking!!' > /var/www/html/index.html"
#
#echo "Enabling & Starting HTTPD Service..."
#ssh $SERVER "systemctl enable --now httpd"
#
#echo "Restarting HTTPD..."
#ssh $SERVER "systemctl restart httpd"
#
echo "HTTPD Setup Completed Successfully on serverb!"
#

ssh root@serverb.lab.example.com 'useradd -d /localhome/production5 -m production5'
ssh root@serverb.lab.example.com 'useradd david'
ssh root@serverb.lab.example.com 'echo "redhat" | passwd --stdin production5'
ssh root@utility.lab.example.com << 'EOF'
echo "Setting up NFS share on utility machine"
mkdir -p /user-homes/production5
chmod 777 /user-homes/production5

# Install and enable NFS
dnf install -y nfs-utils
systemctl enable --now nfs-server
#
# # Configure exports
echo "/user-homes/production5 *(rw,sync,no_root_squash)" > /etc/exports
exportfs -rav
#
#Configure firewall for NFS
systemctl enable --now firewalld
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --reload
#
# # Verify
echo "NFS export configured successfully:"
exportfs -v
echo "Firewall rules:"
firewall-cmd --list-all
EOF

#Clone a Repository
git clone https://github.com/Marieswaran2003/systemc-timer
scp ~/systemc-timer/lookup-1.0-1.el10.noarch.rpm root@serverb:~/

#Booting Menu
echo "Lab Script"
lab start rootpw-recover

echo "Hostname Updated"
ssh root@serverb.lab.example.com 'hostnamectl set-hostname localhost'
echo "Updating IP address and gateway using NetworkManager..."
ssh root@serverb 'nmcli con mod "Wired connection 1" ipv4.addresses 172.25.250.30/16'
ssh root@serverb 'nmcli con mod "Wired connection 1" ipv4.gateway 172.25.250.254'
ssh root@serverb 'nmcli con mod "Wired connection 1" ipv4.method manual'
ssh root@serverb 'nmcli con up "Wired connection 1"'

echo "Servera Updation"
echo "Creating 1GB partition on servera..."

ssh root@servera '(
echo -e "n\np\n1\n\n+1G\nw" | fdisk /dev/sdb
partprobe /dev/sdb
mkfs.xfs -f /dev/sdb1
)'

echo "Partition /dev/sdb1 created and formatted with XFS on servera."

ssh root@servera.lab.example.com  vgcreate -s 8M vg /dev/sdb1
ssh root@servera.lab.example.com  lvcreate -L 100M  -n lv  vg
ssh root@servera.lab.example.com mkdir /lo
ssh root@servera.lab.example.com 'mkfs.ext3 /dev/vg/lv'
ssh root@servera.lab.example.com 'echo "/dev/vg/lv  /lo  ext3  defaults 0 0" >> /etc/fstab'
ssh root@servera.lab.example.com  mount -a
ssh root@servera.lab.example.com  lsblk
ssh root@servera.lab.example.com 'tuned-adm profile powersave'
ssh root@serverb.lab.example.com rm -rvf /etc/yum.repos.d/*
ssh root@servera.lab.example.com rm -rvf /etc/yum.repos.d/*
ssh root@servera.lab.example.com 'echo "redhat" | passwd --stdin devops'
echo "All The Best"
