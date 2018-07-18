Gadgetron in Kubernetes
=======================

This repository contains a first initial setup for running a distributed deployment of the [Gadgetron](https://github.com/gadgetron/gadgetron) in a Kubernetes cluster in Azure. 

*Note: This is only an initial implementation and some tuning and adjustment will be needed for scaling parameters, etc.*

The setup uses [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) to adjust the number of Gadgetron instances (pods) running in the cluster in response to cpu utilizaion and it uses [cluster-autoscaling](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler) to adjust the number of nodes. Specifically, an increase in cpu utilization will lead to the deployment of more Gadgetron instances and when the resources on existing nodes are exhausted more will be added. Idle nodes will be removed from the cluster after some idle time. 

Shared files (dependencies and exported data) are stored in [Azure Files](https://azure.microsoft.com/en-us/services/storage/files/).

The Gadgetron used a single load balanced endpoint to reach the nodes in the cluster. This endpoint is passed to the `gadgetron` executable with the `-e` command line switch. The [`gadgetron_kubernetes_prestop.sh`](gadgetron_kubernetes_prestop.sh) script is used as a PreStop lifecycle hook by Kubernetes. 

Deployment Instructions
-----------------------

1. Set up Kubernets cluster in Azure using `acs-engine`. See [detailed instructions](acs-engine/README.md).

2. Create shared storage for dependencies and data. Use the convenience script [`create_shared_storage.sh`](create_shared_storage.sh):

    ```bash
    ./create_shared_storage.sh
    ```

    Or if you would like to specify the resource group, storage account name and location:

    ```bash
    ./create_shared_storage.sh -r mygroup -a mystorageaccountname -l eastus
    ```

3. Deploy gadgetron kubernetes:

    ```
    kubectl apply -f gadgetron-kubernetes.yaml
    ```

4. Deploy SSH jump server:

    See [https://github.com/kubernetes-contrib/jumpserver](https://github.com/kubernetes-contrib/jumpserver) for details.

    ```bash
    #Get an SSH key, here we are using the one for the current user
    SSHKEY=$(cat ~/.ssh/id_rsa.pub |base64 -w 0)
    sed "s/PUBLIC_KEY/$SSHKEY/" gadgetron-ssh-secret.yaml.tmpl > gadgetron-ssh-secret.yaml

    #Create a secret with the key
    kubectl create -f gadgetron-ssh-secret.yaml

    #Deploy the jump server
    kubectl apply -f gadgetron-ssh-jump-server.yaml
    ```

Connecting with SSH to the jump server
--------------------------------------

The jump sever enables the "standard" Gadgetron connection paradigm through an SSH tunnel. The Gadgetron instances themselves are not directly accessible. Discover the relvant IPs and open a tunnel with:

```bash
#Public (external) IP:
EXTERNALIP=$(kubectl get svc sshd-jumpserver-svc --output=json | jq -r .status.loadBalancer.ingress[0].ip)

#Internal (cluster) IP:
GTCLUSTERIP=$(kubectl get svc gadgetron-frontend --output=json | jq -r .spec.clusterIP)

#Open tunnel:
ssh -L 9022:${GTCLUSTERIP}:9002 root@${EXTERNALIP}
```

Updates and Maintenance
-----------------------

If you need to update the version (Docker image) for the Gadgetron, simply edit the [`gadgetron-kubernetes.yaml`](gadgetron-kubernetes.yaml) to change the image name and reapply:

```
kubectl apply -f gadgetron-kubernetes.yaml
```

The new image will be applied as a rolling update keeping the cluster Gadgetron cluster running throughout the deployment process. 