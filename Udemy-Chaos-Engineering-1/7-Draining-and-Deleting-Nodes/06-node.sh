
######################
# Creating A Cluster #
######################

#################################
# Installing Istio Service Mesh #
#################################

istioctl manifest install \
    --skip-confirmation

#############################
# Deploying The Application #
#############################

cd go-demo-8


kubectl create namespace go-demo-8

kubectl label namespace go-demo-8 \
    istio-injection=enabled

kubectl --namespace go-demo-8 \
    apply --filename k8s/app-db

kubectl --namespace go-demo-8 \
    rollout status deployment go-demo-8

# If EKS
export INGRESS_HOST=$(kubectl \
    --namespace istio-system \
    get service istio-ingressgateway \
    --output jsonpath="{.status.loadBalancer.ingress[0].hostname}")

echo $INGRESS_HOST

curl -H "Host: go-demo-8.acme.com" \
    "http://$INGRESS_HOST"

###########################
# Draining Worker Nodes #
###########################
    
cat chaos/node-drain.yaml

kubectl describe nodes

export NODE_LABEL="beta.kubernetes.io/os=linux"
export NODE_LABEL="kubernetes.io/hostname=ip-192-168-48-111.us-east-2.compute.internal"

chaos run chaos/node-drain.yaml \
    --rollback-strategy=always

############################
# Uncordoning Worker Nodes #
############################

kubectl get nodes

cat chaos/node-uncordon.yaml

diff chaos/node-drain.yaml \
    chaos/node-uncordon.yaml

chaos run chaos/node-uncordon.yaml \
    --rollback-strategy=always

kubectl get nodes

##########################
# Making Nodes Drainable #
##########################

kubectl --namespace istio-system \
    get deployment

export CLUSTER_NAME=[...] # Replace `[...]` with the name of the cluster (e.g., `chaos`)

# NOTE: Might need to increase quotas


# If EKS
eksctl get nodegroup \
    --cluster $CLUSTER_NAME

# If EKS
export NODE_GROUP=[...] # Replace `[...]` with the node group

# If EKS
eksctl scale nodegroup \
    --cluster=$CLUSTER_NAME \
    --nodes 3 \
    $NODE_GROUP


kubectl get nodes

# Repeat the previous command if there are no three `Ready` nodes

kubectl --namespace istio-system \
    get hpa

kubectl --namespace istio-system \
    patch hpa istio-ingressgateway \
    --patch '{"spec": {"minReplicas": 2}}'

kubectl --namespace istio-system \
    get hpa

kubectl --namespace istio-system \
    get pods \
    --output wide

chaos run chaos/node-uncordon.yaml \
    --rollback-strategy=always

kubectl get nodes

#########################
# Deleting Worker Nodes #
#########################

cat chaos/node-delete.yaml

diff chaos/node-uncordon.yaml \
    chaos/node-delete.yaml

chaos run chaos/node-delete.yaml \
    --rollback-strategy=always

kubectl get nodes

# NOTE: You might need to terminate the node that was removed from Kubernetes

kubectl --namespace go-demo-8 \
    get pods

############################
# Destroying Cluster Zones #
############################

##############################
# Destroying What We Created #
##############################

cd ..

kubectl delete namespace go-demo-8