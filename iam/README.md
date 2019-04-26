### Roles and Policies for csi-test cluster

Master:  
```
./create-iam-role.sh k8s-master policies/k8s-master.json
```

CSI Controller:
```
./create-iam-role.sh k8s-csi-controller policies/k8s-csi-controller.json policies/k8s-node-common.json
```

Node:
```
./create-iam-role.sh k8s-node-common policies/k8s-node-common.json
```