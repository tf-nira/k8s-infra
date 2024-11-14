#!/bin/bash

if [ $# -ge 1 ] ; then
   export KUBECONFIG=$1
fi

NS=cattle-logging-system
VERSION="100.1.3+up3.17.7"

echo Create namespace logging
kubectl create namespace $NS

echo Updating helm repos
helm repo add mosip https://mosip.github.io/mosip-helm
helm repo update

echo "Installing rancher-logging-crd"
helm -n $NS install rancher-logging-crd mosip/rancher-logging-crd --version $VERSION --wait

echo "Installing rancher-logging"
helm -n $NS install rancher-logging mosip/rancher-logging --version $VERSION --wait
