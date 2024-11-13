#!/bin/bash
# Installs Monitoring
## Usage: ./install.sh [kubeconfig]

if [ $# -ge 1 ] ; then
  export KUBECONFIG=$1
fi

NS=cattle-monitoring-system
#VERSION="102.0.5+up40.1.2"
VERSION="100.1.3+up19.0.3"

echo Create namespace cattle-monitoring-system
kubectl create namespace $NS

function installing_monitoring() {
  echo Updating helm repos
  helm repo add mosip https://mosip.github.io/mosip-helm
  helm repo update

  echo Installing Crds for Monitoring
  helm -n $NS install rancher-monitoring-crd mosip/rancher-monitoring-crd  --version $VERSION --create-namespace
  echo Installing Monitoring

  helm -n $NS install rancher-monitoring mosip/rancher-monitoring -f values.yaml --version $VERSION --create-namespace
  echo Installed monitoring
  return 0
}

# set commands for error handling.
set -e
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errtrace  # trace ERR through 'time command' and other functions
set -o pipefail  # trace ERR through pipes
installing_monitoring   # calling function
