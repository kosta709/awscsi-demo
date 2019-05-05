### Generic PVC Flow
##### Common kubernetes vs storage system specific actions 
To get PersistentVolumes and PersistentVolumeClaims mechanism working, Kubernetes runs many componets which are common for all volume types along with storage system specific code. 

* PVC Provisioning Process:
  - watch for pending PVC with StorageClass which has provisioner fields
  - call storage system specific API (ebs, gcp-disk, ceph, etc) to create real volume according to storage class parameters
  - Create PersistentVolume object with appropriative PersistentVolumeSource and set references for both pvc and pv (bound)
  - Waits, handling errors, retries, events

* Start pod with pvc on a node:
  - wait until pvc is bound and get its PersistentVolumeSource object
  - attach volume to node by calling storage system specific API
  - wait until volume is attached
  - mount device of the attached volume (/dev/* ) . It is also VolumeSource specific code
  - start containers of the pod with an access to the mountpoint of the volume
  - waits, handling errors, retries, events

* Stop pod with pvc on node:
  - stop container
  - unmount the volume
  - detach volume from the node
  - waits, handling errors, retries, events

* Delete PVC bounded to PV with reclaimPolicy=Delete
  - Wait until the volume is not attached to any node
  - call storage system specific API delete real volume according to VolumeSource parameters
  - Delete PV and PVC objects from Kubernetes
  - waits, handling errors, retries, events