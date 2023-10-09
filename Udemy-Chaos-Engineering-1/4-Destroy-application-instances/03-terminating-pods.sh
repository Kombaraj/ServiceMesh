
######################
# Creating A Cluster #
######################

#############################
# Deploying The Application #
#############################

git clone \
    https://github.com/vfarcic/go-demo-8.git

cd go-demo-8

git pull

kubectl create namespace go-demo-8

cat k8s/terminate-pods/pod.yaml

kubectl --namespace go-demo-8 \
    apply --filename k8s/terminate-pods/pod.yaml

#################################
# Discovering Kubernetes Plugin #
#################################

pip install -U chaostoolkit-kubernetes

chaos discover chaostoolkit-kubernetes

cat discovery.json

#####################################
# Terminating Application Instances #
#####################################

cat chaos/terminate-pod.yaml

chaos run chaos/terminate-pod.yaml

echo $?

kubectl --namespace go-demo-8 \
    get pods

###########################
# Steady State Hypothesis #
# A Steady State Hypothesis describes “what normal looks like” for your system in order for the experiment to surface information 
# about weaknesses when compared against the declared “normal” tolerances of what is measured.
# 
# Method
# An experiment’s activities are contained within its Method block.

# Probes
# A probe is a way of observing a particular set of conditions in the system that is undergoing experimentation.

# Actions
# An action is a particular activity that needs to be enacted on the system under experimentation.

# Rollbacks
# An experiment may define a sequence of actions that revert what was undone during the experiment.

# Controls
# An experiment may declare a set of controls which have an impact over the execution of the experiment itself. 
# Controls are operational elements rather than experimental.
###########################

cat chaos/terminate-pod-ssh.yaml

diff chaos/terminate-pod.yaml \
    chaos/terminate-pod-ssh.yaml

chaos run chaos/terminate-pod-ssh.yaml

echo $?

kubectl --namespace go-demo-8 \
    apply --filename k8s/terminate-pods/pod.yaml

chaos run chaos/terminate-pod-ssh.yaml

echo $?

kubectl --namespace go-demo-8 \
    apply --filename k8s/terminate-pods/pod.yaml

#########################
# Pausing After Actions #
#########################

cat chaos/terminate-pod-pause.yaml

diff chaos/terminate-pod-ssh.yaml \
    chaos/terminate-pod-pause.yaml

chaos run chaos/terminate-pod-pause.yaml

echo $?

kubectl --namespace go-demo-8 \
    apply --filename k8s/terminate-pods/pod.yaml

#########################
# Phases And Conditions #
#########################

kubectl --namespace go-demo-8 \
    describe pod go-demo-8

kubectl --namespace go-demo-8 \
    get pods

cat chaos/terminate-pod-phase.yaml

diff chaos/terminate-pod-pause.yaml \
    chaos/terminate-pod-phase.yaml

chaos run chaos/terminate-pod-phase.yaml

echo $?

kubectl --namespace go-demo-8 \
    logs go-demo-8

kubectl --namespace go-demo-8 \
    apply --filename k8s/db

kubectl --namespace go-demo-8 \
    rollout status \
    deployment go-demo-8-db

kubectl --namespace go-demo-8 \
    get pods

# Repeat the previous command until the `go-demo-8` Pod `STATUS` is `Running`

chaos run chaos/terminate-pod-phase.yaml

echo $?

#################################
# Making The App Fault-Tolerant #
#################################

cat k8s/terminate-pods/deployment.yaml

kubectl --namespace go-demo-8 \
    apply --filename k8s/terminate-pods/deployment.yaml

kubectl --namespace go-demo-8 \
    rollout status \
    deployment go-demo-8

chaos run chaos/terminate-pod-phase.yaml

# Note: The Application is now Fault Tolerant not Highly Available

##############################
# Destroying What We Created #
##############################

cd ..

kubectl delete namespace go-demo-8