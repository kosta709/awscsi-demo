### Start k8s cluster by kubeadm for csi test

##### Create master node:
  * Amazon Linux 2 image
  * Public IP subnet
  * Tags: Name=test1-master, KubernetesCluster=test1
  * IAM role = k8s-master - see `../iam`
  * security group with inbound tcp 6443 and 22

##### Assing DNS names in route53 (ips are dummy)
  34.34.34.34 - test1-master.mydomain.com
  172.16.101.31 - test1-master-int.mydomain.com

##### Install Master
scp `init-master.sh` and `kubeadm-init-config.yaml` to the master node  and execute:
```
./init-master.sh
kubeadm init --config ./kubeadm-init-config.yaml
```
Write down `kubeadm join` command and edit `install-node-userdata-*.sh` with correct token can ca_cert_hash
download /etc/admin/admin.conf , edit it to set cluster.server=test1-master.mydomain.com and 

Install calico network:
```
# Note that CALICO_IPV4POOL_CIDR in calico.yaml should be same as podSubnet in kubeadm-init-config.yaml
kubectl apply -f calico/rbac-kdd.yaml -f calico/calico.yaml
```

Ensure that nodes are healthy
See https://medium.com/@kosta709/kubernetes-by-kubeadm-config-yamls-94e2ee11244 for more "gitops" of kubeadm usage  

##### Create Autoscaling group for csi-controller
Create Launch Configration to run in the same vpc as master
* set IAM Role = k8s-csi-controller
* only ssh is needed to be open on the on security group 
* set userData to the content of `userdata-csi-controller.sh` - we set taint "CriticalAddonsOnly" and label "node-type=csi-controller"

Create Autoscaling group for the LC above, set TAG `KubernetesCluster=test1`
Launch end ensure that instance connects to the master by `kubectl get nodes --show-labels`  

##### Create Autoscaling group for node
Create Launch Configration to run in the same vpc as master and single subnet (us-east-1d)
* set IAM Role = k8s-node-common
* only ssh is needed to be open on the security group
* set userData to the content of `userdata-node.sh` - we set label "node-type=worker"

Create Autoscaling group for the LC above, set TAG `KubernetesCluster=test1`
Launch end ensure that instance connects to the master by `kubectl get nodes --show-labels`  




