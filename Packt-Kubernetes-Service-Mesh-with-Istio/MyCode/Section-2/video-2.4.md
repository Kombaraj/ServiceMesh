# Blue/Green and Canary Deployments

## Prerequisites

This video assumes that you have running Istio installation on your Kubernetes cluster.

Optionally, create a dedicated namespace for this showcase and label it appropriately for the sidecar injector webhook to work. Or simply use the default namespace.

```
$ kubectl label namespace default istio-injection=enabled

$ kubectl get svc istio-ingressgateway -n istio-system
# if GKE
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# If EKS
export INGRESS_HOST=$(kubectl \
    --namespace istio-system \
    get service istio-ingressgateway \
    --output jsonpath="{.status.loadBalancer.ingress[0].hostname}")

echo $INGRESS_HOST

# deploy sample application
$ kubectl apply -f kubernetes/hello-istio.yaml

# create ingress gateway and route traffic to microservices
$ kubectl apply -f kubernetes/hello-istio-gateway.yaml
$ kubectl apply -f kubernetes/hello-istio-virtual-service.yaml

# apply the version subsets as destinations
$ kubectl apply -f kubernetes/hello-istio-destination.yaml
```

## Running

```
# perform blue green release deployment
$ kubectl apply -f kubernetes/hello-istio-v1.yaml
$ curl -H "Host: hello-istio.cloud" "http://$INGRESS_HOST/api/hello"

$ kubectl apply -f kubernetes/hello-istio-v2.yaml
$ curl -H "Host: hello-istio.cloud" "http://$INGRESS_HOST/api/hello"

# perform canary release deployment
$ kubectl apply -f kubernetes/hello-istio-100-0.yaml
$ kubectl apply -f kubernetes/hello-istio-75-25.yaml
$ kubectl apply -f kubernetes/hello-istio-50-50.yaml
$ kubectl apply -f kubernetes/hello-istio-25-75.yaml
$ kubectl apply -f kubernetes/hello-istio-0-100.yaml
```
