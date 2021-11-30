# Installing Istio by Hand

In this video are going to install Istio by hand, by applying the
Kubernetes resources such as CRDs and component deployments.

## Prerequesites

You will need a running Kubernetes with enough resources. If you install
Istio locally in Docker Desktop make sure you followed the instructions
under https://istio.io/docs/setup/platform-setup/docker/

## Step 1: Setup and Verify

First, you need to download and setup the latest Istio release.
At the time of writing this is `1.3.4`, upgrade to latest version if desired.
```
# first install istioctl CLI
URL: https://istio.io/latest/docs/ops/diagnostic-tools/istioctl/

curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.11.3 sh -
cd istio-1.11.3
echo "export PATH=$PWD/bin:$PATH" >> ~/.bash_profile

# open new shell to load updated PATH variable

$ istioctl verify-install
```

## Step 2: Installation

In this step we are installing the Istio CRDs as well as the components and
services for the Istio demo.

```
# display the list of available profiles
istioctl profile list

istioctl install --set profile=demo -y

# Verifying the installation
kubectl get pods,svc,deploy -n istio-system

# enable istio sidecar injection by adding a label
kubectl label namespace default istio-injection=enabled
```

## (Optional) Step 4: Uninstall Istio

In case you want to uninstall Istio, issue the following commands:
```
kubectl label namespace default istio-injection-

istioctl manifest generate \
    --set profile=demo \
    | kubectl delete -f -
```
