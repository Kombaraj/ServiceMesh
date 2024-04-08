# 4. Deploy Sample App to EKS and Expose Service using Ingress

Refs: 
- https://github.com/kubernetes/examples/tree/master/guestbook

![alt text](../imgs/guestbook_architecture.png "K8s Architecture")

Frontend PHP app
- load balanced by public ELB
- read request load balanced to multiple slaves
- write request to a single master

Backend Redis
- single master (write)
- multi slaves (read)
- slaves sync continuously from master

## 4.1 Deploy GuestBook Application
```
kubectl apply -f guestbook-all-in-one.yaml
```


Get service and pod
```
$ kubectl get pod,service
NAME                                READY   STATUS    RESTARTS   AGE
pod/frontend-79b6ddfbfc-jhlmb       2/2     Running   0          67s
pod/frontend-79b6ddfbfc-jp98h       2/2     Running   0          67s
pod/frontend-79b6ddfbfc-xrdsb       2/2     Running   0          67s
pod/redis-master-6dcd9ffcb5-rcvpk   2/2     Running   0          69s
pod/redis-slave-588769fbc5-2fd9t    2/2     Running   0          68s
pod/redis-slave-588769fbc5-bf6tx    2/2     Running   0          68s

NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)        AGE
service/frontend       LoadBalancer   10.100.159.98    a26ae93ca22a84fd6bd141083945fd63-1968953581.us-east-1.elb.amazonaws.com   80:30503/TCP   69s
service/kubernetes     ClusterIP      10.100.0.1       <none>                                                                    443/TCP        22m
service/redis-master   ClusterIP      10.100.193.102   <none>                                                                    6379/TCP       71s
service/redis-slave    ClusterIP      10.100.80.154    <none>                                                                    6379/TCP       70s
```


## 4.4 Get external ELB DNS
```sh
echo $(kubectl  get svc frontend | awk '{ print $4 }' | tail -1):$(kubectl  get svc frontend | awk '{ print $5 }' | tail -1 | cut -d ":" -f 1)

# output
a24ac71d1c2e046f59e46720494f5322-359345983.us-west-2.elb.amazonaws.com:80
```

Visit it from browser __after 3-5 minutes when ELB is ready__

![alt text](../imgs/guestbook_ui.png "K8s Architecture")


## 4.5 What Just Happened?!
![alt text](../imgs/eks_aws_architecture_with_apps.png "K8s Architecture")


## 4.6 Install Nginx Ingress Controller
```sh
# Install Nginx Ingress Controller using Helm:
helm repo add stable https://charts.helm.sh/stable 
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
kubectl create ns ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx

kubectl -n ingress-nginx get pods,svc,deploy
```


## 4.7 Create Ingress resource for L7 load balancing by http hosts & paths


Create ingress resource
```bash
kubectl apply -f ingress.yaml
```

Get the public DNS of AWS ELB created from the `nginx-ingress-controller-controller` service
```bash
kubectl  get svc nginx-ingress-controller-controller -n nginx-ingress-controller | awk '{ print $4 }' | tail -1
```

Output
```bash
# visit this from browser
a588cbec4e4e34e1bbc1cc066f38e3e0-1988798789.us-west-2.elb.amazonaws.com
```

![alt text](../imgs/guestbook_ui_from_ingress.png "K8s Architecture")


## 4.8 Delete AWS ELB created by K8s Service of type LoadBalancer
Now modify `guestbook` service type from `LoadBalancer` to `NodePort`.

First get yaml 
```bash
$ kubectl get svc
NAME           TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)        AGE
frontend       LoadBalancer   10.100.159.98    a26ae93ca22a84fd6bd141083945fd63-1968953581.us-east-1.elb.amazonaws.com   80:30503/TCP   26m       
kubernetes     ClusterIP      10.100.0.1       <none>                                                                    443/TCP        48m
redis-master   ClusterIP      10.100.193.102   <none>                                                                    6379/TCP       26m       
redis-slave    ClusterIP      10.100.80.154    <none>                                                                    6379/TCP       26m       

$ kubectl patch svc frontend -p '{"spec": {"type": "NodePort"}}'
service/frontend patched

$ kubectl get svc
NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
frontend       NodePort    10.100.159.98    <none>        80:30503/TCP   28m
kubernetes     ClusterIP   10.100.0.1       <none>        443/TCP        49m
redis-master   ClusterIP   10.100.193.102   <none>        6379/TCP       28m
redis-slave    ClusterIP   10.100.80.154    <none>        6379/TCP       28m

```


Lastly, check ingress controller's public DNS is reachable from browser
```bash
# visit the URL from browser
kubectl  get svc ingress-nginx-controller -n ingress-nginx| awk '{ print $4 }' | tail -1
```

## 4.9  What Just Happened?
1. Replaced `guestbook` service of type `LoadBalancer` to of `NodePort`
2. Front `guestbook` service with `nginx-ingress-controller` service of type `LoadBalancer`
3. `nginx-ingress-controller` pod will do L7 load balancing based on HTTP path and host
4. Now you can create multiple services and bind them to one ingress controller (one AWS ELB)

__Before Ingress__
![alt text](../imgs/eks_aws_architecture_with_apps.png "K8s Architecture")

__After Ingress__
![alt text](../imgs/eks_aws_architecture_with_apps_ingress.png "K8s Ingress")


__With Istio Enabled__
![alt text](../imgs/eks_aws_architecture_with_apps_ingress_istio.png "K8s Ingress")
