
######################
# Creating A Cluster #
######################

#############################
# Deploying The Application #
#############################

cd go-demo-8

kubectl create namespace go-demo-8

cat k8s/terminate-pods/app/*

kubectl --namespace go-demo-8 \
    apply --filename k8s/terminate-pods/app

kubectl --namespace go-demo-8 \
    rollout status deployment go-demo-8

kubectl --namespace go-demo-8 \
    get pods,svc,deploy

##############################
# Validating The Application #
##############################

kubectl --namespace go-demo-8 \
    get ingress

kubectl apply \
    --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.27.0/deploy/static/mandatory.yaml

# If Minikube
minikube addons enable ingress

# If Docker Desktop, GKE, or AKS
kubectl apply \
    --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.47.0/deploy/static/provider/cloud/deploy.yaml

# If EKS
kubectl apply \
    --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.47.0/deploy/static/provider/aws/deploy.yaml

# If Minikube
export INGRESS_HOST=$(minikube ip)

# If Docker Desktop or EKS
export INGRESS_HOST=$(kubectl \
    --namespace ingress-nginx \
    get service ingress-nginx-controller \
    --output jsonpath="{.status.loadBalancer.ingress[0].hostname}")

# If GKE or AKS
export INGRESS_HOST=$(kubectl \
    --namespace ingress-nginx \
    get service ingress-nginx \
    --output jsonpath="{.status.loadBalancer.ingress[0].ip}")

echo $INGRESS_HOST

# Repeat the `export` command if the output is empty

cat k8s/health/ingress.yaml

kubectl --namespace go-demo-8 \
    apply --filename k8s/health/ingress.yaml

curl -H "Host: go-demo-8.acme.com" \
    "http://$INGRESS_HOST"

#################################
# Validating Application Health #
#################################

cat chaos/health.yaml

chaos run chaos/health.yaml

kubectl --namespace go-demo-8 \
    get pods

cat chaos/health-pause.yaml

diff chaos/health.yaml \
    chaos/health-pause.yaml

chaos run chaos/health-pause.yaml

kubectl --namespace go-demo-8 \
    get pods

#######################################
# Validating Application - Highly Available #
#######################################

cat chaos/health-http.yaml

diff chaos/health-pause.yaml \
    chaos/health-http.yaml

chaos run chaos/health-http.yaml

cat k8s/health/hpa.yaml

kubectl apply --namespace go-demo-8 \
    --filename k8s/health/hpa.yaml

kubectl --namespace go-demo-8 \
    get hpa

# Repeat if the number of replicas is not `2`

chaos run chaos/health-http.yaml

########################################
# Terminating Application Dependencies #
########################################

cat chaos/health-db.yaml

diff chaos/health-http.yaml \
    chaos/health-db.yaml

chaos run chaos/health-db.yaml

##############################
# Destroying What We Created #
##############################

cd ..

kubectl delete namespace go-demo-8