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
yum install -y yum-utils device-mapper-persistent-data lvm2 tc

### Add docker repository.
amazon-linux-extras install -y docker 

# Restart docker.
systemctl enable docker
systemctl start docker
usermod -a -G docker ec2-user


### Install Kubelet and kubeadm
echo "
Installing lubelet and kubeadm"
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg

EOF

yum install -y kubelet-1.14.1-0 kubeadm-1.14.1-0
if [[ $? != 0 ]]; then
   echo "Failed to install kube components"
   exit 1
fi

systemctl enable --now kubelet

echo "--- Joining Cluster "
KUBEADM_CONF=/root/kubeadm-join-config.conf
K8S_API_ENDPOINT_INTERNAL="test1-master-int.mydomain.com:6443"
KUBEADM_TOKEN="******"
CA_CERT_HASH="sha256:******"

cat <<EOF >${KUBEADM_CONF}
apiVersion: kubeadm.k8s.io/v1beta1
kind: JoinConfiguration
nodeRegistration:
  # see https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm#NodeRegistrationOptions
  taints:
  - key: CriticalAddonsOnly
    effect: NoSchedule
    value: "true"
  kubeletExtraArgs:
    node-labels: "node-type=csi-controller"
    cloud-provider: "aws"
    allow-privileged: "true"
    feature-gates: "CSINodeInfo=true,CSIDriverRegistry=true,CSIBlockVolume=true"
discovery:
  bootstrapToken:
    apiServerEndpoint: ${K8S_API_ENDPOINT_INTERNAL}
    token: ${KUBEADM_TOKEN}
    caCertHashes:
    - ${CA_CERT_HASH}
EOF

kubeadm join --config ${KUBEADM_CONF}