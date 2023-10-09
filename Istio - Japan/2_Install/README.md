# 2. Install Istio
# 2.1 Install Istio using istioctl
Ref: https://istio.io/latest/docs/setup/install/
```sh
# first install istioctl CLI
curl -L https://istio.io/downloadIstio | sh -
cd istio-1.19.0
echo "export PATH=$PWD/bin:$PATH" >> ~/.bash_profile

# open new shell to load updated PATH variable
```


# 2.2 Install Istio to K8s cluster using istio config profile
Ref: https://istio.io/latest/docs/setup/additional-setup/config-profiles/

There are a few preset profiles we can install:
- default
- demo
- minimal
- etc

![alt text](../imgs/istio_profile.png "Istio")

We will install `demo` profile, which comes with ingress/egress gateways, as well as grafana, kiali, jaegger (request tracing), and prometheus monitoring/metrics dashboards.
```sh
# display the list of available profiles
$ istioctl profile list
Istio configuration profiles:
    ambient
    default
    demo
    empty
    external
    minimal
    openshift
    preview
    remote

# save config into yaml
istioctl profile dump demo > profile_demo_config.yaml
```

Output
```sh
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  addonComponents:
    grafana:
      enabled: true
      k8s:
        replicaCount: 1
    istiocoredns:
      enabled: false
    kiali:
      enabled: true
      k8s:
        replicaCount: 1
    prometheus:
      enabled: true
      k8s:
        replicaCount: 1
    tracing:
      enabled: true
  components:
    base:
      enabled: true
    citadel:
      enabled: false
      k8s:
        strategy:
          rollingUpdate:
            maxSurge: 100%
            maxUnavailable: 25%
    cni:
      enabled: false
    egressGateways:
    - enabled: true
      k8s:
        resources:
          requests:
            cpu: 10m
            memory: 40Mi
      name: istio-egressgateway
```


# use "istioctl install" 

```
$ istioctl install --set profile=demo
This will install the Istio 1.19.0 "demo" profile (with components: Istio core, Istiod, Ingress gateways, and Egress gateways) into the cluster. Proceed? (y/N) Y
✔ Istio core installed
✔ Istiod installed
✔ Egress gateways installed
✔ Ingress gateways installed
✔ Installation complete                                                                                                                                                     Made this installation the default for injection and validation.

```
</p></details>


Analyze and detect potential issues with your Istio configuration
```sh
istioctl analyze --all-namespaces

# output
Warn [IST0102] (Namespace default) The namespace is not enabled for Istio injection. Run 'kubectl label namespace default istio-injection=enabled' to enable it, or 'kubectl label namespace default istio-injection=disabled' to explicitly mark it as not needing injection
Warn [IST0102] (Namespace kube-node-lease) The namespace is not enabled for Istio injection. Run 'kubectl label namespace kube-node-lease istio-injection=enabled' to enable it, or 'kubectl label namespace kube-node-lease istio-injection=disabled' to explicitly mark it as not needing injection
Error: Analyzers found issues when analyzing all namespaces.
See https://istio.io/docs/reference/config/analysis for more information about causes and resolutions.
```

Show objects created
```sh
$ kubectl get pod,svc -n istio-system
NAME                                        READY   STATUS    RESTARTS   AGE
pod/istio-egressgateway-5875bcbf6c-mm2pr    1/1     Running   0          81s
pod/istio-ingressgateway-54555748df-pmv2r   1/1     Running   0          80s
pod/istiod-6987557fdd-zp8th                 1/1     Running   0          89s

NAME                           TYPE           CLUSTER-IP       EXTERNAL-IP                                                              PORT(S)                                                                      AGE
service/istio-egressgateway    ClusterIP      10.100.228.232   <none>                                                                   80/TCP,443/TCP                                                               78s
service/istio-ingressgateway   LoadBalancer   10.100.44.127    afdd7c09b8be64b00833727acb6b88ac-855646155.us-east-1.elb.amazonaws.com   15021:32746/TCP,80:30779/TCP,443:30113/TCP,31400:30223/TCP,15443:31323/TCP   78s
service/istiod                 ClusterIP      10.100.138.87    <none>                                                                   15010/TCP,15012/TCP,443/TCP,15014/TCP                                        87s

```


Notice a service `istio-ingressgateway` in `istio-system` namespace created AWS ELB of type classic load balancer
```
service/istio-ingressgateway        LoadBalancer   10.100.229.231   a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com   15020:32676/TCP,80:32703/TCP,443:30964/TCP,31400:30057/TCP,15443:32059/TCP   15m
```

Check AWS ELB created by istio ingress gateway service

![alt text](../imgs/ingress_gateway_aws_elb.png "Istio")


Also notice a pod `istiod-7d6dff85dd-w5szx`. 
This is the pod that contains istio pilot (service discovery), Galley (config), sidecar injector, that is `istiod`.
> istiod unifies functionality that Pilot, Galley, Citadel and the sidecar injector previously performed, into a single binary



# 2.3 Enable Istio Sidecar Injection 

Add a namespace label to instruct Istio to automatically inject Envoy sidecar proxies when you deploy your application later
```sh
# first describe default namespace
kubectl describe ns default

# output
Name:         default
Labels:       <none>
Annotations:  <none>
Status:       Active
No resource quota.
No resource limits.

# enable istio sidecar injection by adding a label
kubectl label namespace default istio-injection=enabled

# verify label is added
# output
Name:         default
Labels:       istio-injection=enabled
Annotations:  <none>
Status:       Active
No resource quota.
No resource limits.

# to disable
kubectl label namespace default istio-injection-
```
# Uninstall Istio #
```sh
istioctl uninstall -y --purge
kubectl delete namespace istio-system
```

# Uninstall EKS Kubernetes Cluster #
```sh
eksctl delete cluster <<Cluster Name>>
```
