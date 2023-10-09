##################
# Create Cluster #
##################

minikube start \
    --vm-driver virtualbox \
    --cpus 4 \
    --memory 8192

minikube addons enable default-storageclass

minikube addons enable storage-provisioner

##################
# Delete Cluster #
##################

minikube delete