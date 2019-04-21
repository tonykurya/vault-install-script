#!/bin/bash

rm -rf /opt/vaultinstall
echo "helm init"
echo "- - - - - - - - - - -"
echo "                     "

helm init
sleep 5
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
echo "                     "
echo "- - - - - - - - - - -"
echo "                     "
read -p "Press enter to Install consul"

#vaultinstall path
mkdir /opt/vaultinstall
cd /opt/vaultinstall

# Clone the chart repo
git clone https://github.com/hashicorp/consul-helm.git
cd consul-helm

# Checkout a tagged version
git checkout v0.1.0
sed -i "s/replicas: 3/replicas: 2/" values.yaml
sed -i "s/bootstrapExpect: 3/bootstrapExpect: 2/" values.yaml
sed -i "s/type: null/type: NodePort/" values.yaml

# Run Helm
helm install --name consul ./ --namespace vaultdemo

sleep 120

# get pods status
kubectl get pods --namespace vaultdemo
echo "                     "
echo "- - - - - - - - - - -"
echo "                     "
read -p "Press enter to Install etcd-operator"

cd /opt/vaultinstall 

#Add repo
helm repo add banzaicloud-stable http://kubernetes-charts.banzaicloud.com/branch/master

#Install etcd-operator
cd /opt/vaultinstall/
git clone  https://github.com/banzaicloud/banzai-charts.git
cd banzai-charts
helm install etcd-operator --namespace vaultdemo --name etcd-operator
sleep 10
kubectl get pods --namespace vaultdemo
echo "                     "
echo "- - - - - - - - - - -"
echo "                     "
#Install vault-operator
read -p "Press enter to Install vault-operator"
cd /opt/vaultinstall/banzai-charts
rm -rf vault-operator/requirements.yaml
helm install vault-operator --namespace vaultdemo --name vault-operator
sleep 20
kubectl get pods --namespace vaultdemo
echo "                     "
echo "- - - - - - - - - - -"
echo "                     "
# Install vault-secrets-webhook
read -p "Press enter to Install vault-secrets-webhook"
cd /opt/vaultinstall/banzai-charts
helm repo add banzaicloud-stable http://kubernetes-charts.banzaicloud.com/branch/master
helm repo update
helm upgrade --namespace vswh --install vswh banzaicloud-stable/vault-secrets-webhook
sleep 10
kubectl get pods --namespace vswh
echo "                     "
echo "- - - - - - - - - - -"
echo "                     "
#Install prometheus-operator
read -p "Press enter to Install prometheus-operator"
cd /opt/vaultinstall/
git clone  https://github.com/coreos/prometheus-operator.git
cd prometheus-operator/
sed -i "s/namespace: default/namespace: vaultdemo/" bundle.yaml
kubectl apply -f bundle.yaml
sleep 10
kubectl get serviceaccount --namespace vaultdemo
echo "                     "
echo "- - - - - - - - - - -"
echo "                     "
# Install vault
read -p "Press enter to Install vault"
cd /opt/vaultinstall/banzai-charts
helm install banzaicloud-stable/vault --set vault.config.storage.consul.address="consul-ui:80",vault.config.storage.consul.path="vault" --namespace vaultdemo --name vault
kubectl get pods --namespace vaultdemo
