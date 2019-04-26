#!/bin/bash
# Installig master and its prerequrests

echo "-------\n  Loading Modules\n--------\n"
modprobe -va overlay br_netfilter
cat > /etc/modules-load.d/99-kubernetes.conf <<EOF
overlay
br_netfilter
EOF

echo -e "-------\n  Setup required sysctl params, these persist across reboots\n--------\n"
cat > /etc/sysctl.d/99-kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl --system

# Set SELinux in permissive mode (effectively disabling it)
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Install Docker CE
## Set up the repository
### Install required packages.
yum update -y
yum install -y yum-utils device-mapper-persistent-data lvm2

### Add docker repository.
amazon-linux-extras install -y docker

# Restart docker.
systemctl enable docker
systemctl start docker
usermod -a -G docker ec2-user

### Install Kubelet and kubeadm
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
gpgkey= https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg

EOF

yum install -y kubelet-1.4.1-0 kubeadm-1.14.1-0 kubectl-1.14.1-0

systemctl enable --now kubelet