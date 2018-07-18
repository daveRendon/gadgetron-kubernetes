#!/bin/bash

#Download the prestop script
wget -O /opt/gadgetron_kubernetes_prestop.sh https://raw.githubusercontent.com/hansenms/gadgetron-kubernetes/master/gadgetron_kubernetes_prestop.sh


#Get the load balanced endpoint
gtservice=$(wget -O - -o /dev/null --ca-certificate /var/run/secrets/kubernetes.io/serviceaccount/ca.crt --header "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" https://kubernetes/api/v1/namespaces/default/services/gadgetron-frontend)
clusterIP=$(echo $gtservice | jq -r .spec.clusterIP)
clusterPort=$(echo $gtservice | jq -r .spec.ports[0].port)

#Run the Gadgetron using load balanced endpoint
gadgetron -e ${clusterIP}:${clusterPort}