# 4. Deploy Sample App to EKS and Expose Service using Ingress

Refs: 
- https://github.com/kubernetes/examples/tree/master/guestbook/all-in-one

![alt text](../imgs/guestbook_architecture.png "K8s Architecture")

Frontend PHP app
- load balanced by public ELB
- read request load balanced to multiple slaves
- write request to a single master

Backend Redis
- single master (write)
- multi slaves (read)
- slaves sync continuously from master


```
kubectl apply -f guestbook-all-in-one.yaml
```

## 4.4 Get external ELB DNS
```sh
echo $(kubectl  get svc frontend | awk '{ print $4 }' | tail -1):$(kubectl  get svc frontend | awk '{ print $5 }' | tail -1 | cut -d ":" -f 1)

# output
a8274ce21a7f94416a5b6214f6f50205-1187236704.us-east-2.elb.amazonaws.com:80
```

Visit it from browser __after 3-5 minutes when ELB is ready__

![alt text](../imgs/guestbook_ui.png "K8s Architecture")


## 4.5 What Just Happened?!
![alt text](../imgs/eks_aws_architecture_with_apps.png "K8s Architecture")


## 4.6 Install Nginx Ingress Controller
```
helm repo list
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update

kubectl create namespace nginx-ingress-controller
helm install nginx-ingress-controller nginx-stable/nginx-ingress -n nginx-ingress-controller
k -n nginx-ingress-controller get pods,svc,deploy
```
Output
```bash
NAME                                                          READY   STATUS    RESTARTS   AGE
pod/nginx-ingress-controller-nginx-ingress-7ffc9b45c7-c2ctt   1/1     Running   0          30s

NAME                                             TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)                      AGE
service/nginx-ingress-controller-nginx-ingress   LoadBalancer   10.100.238.201   a920ec60b98b04397b3664926be309a3-1107836477.us-east-2.elb.amazonaws.com   80:30973/TCP,443:31900/TCP   31s

NAME                                                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-ingress-controller-nginx-ingress   1/1     1            1           31s
```
## 4.7 Create Ingress resource for L7 load balancing by http hosts & paths

[ingress.yaml](ingress.yaml)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
```

Create ingress resource
```bash
kubectl apply -f ingress.yaml
```

Get the public DNS of AWS ELB created from the `nginx-ingress-controller-controller` service
```bash
kubectl  get svc nginx-ingress-controller-nginx-ingress -n nginx-ingress-controller | awk '{ print $4 }' | tail -1
```

Output
```bash
# visit this from browser
a920ec60b98b04397b3664926be309a3-1107836477.us-east-2.elb.amazonaws.com
```

![alt text](../imgs/guestbook_ui_from_ingress.png "K8s Architecture")


## 4.8 Delete AWS ELB created by K8s Service of type LoadBalancer
Now modify `guestbook` service type from `LoadBalancer` to `NodePort`.

First get yaml 
```bash
kubectl get svc frontend -o yaml
```

Strip out `status` etc that are added after created
[service_guestbook_nodeport.yaml](service_guestbook_nodeport.yaml)
```
apiVersion: v1
kind: Service
metadata:
  name: frontend
  labels:
    app: guestbook
    tier: frontend
spec:
  # comment or delete the following line if you want to use a LoadBalancer
  type: NodePort 
  # if your cluster supports it, uncomment the following to automatically create
  # an external load-balanced IP for the frontend service.
  # type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: guestbook
    tier: frontend
```

Delete the existing `guestbook` service as service is immutable
```bash
kubectl delete svc frontend
```

Then apply new service
```bash
kubectl apply -f service_guestbook_nodeport.yaml
```

Check services in `default` namespace
```bash
$ kubectl get svc

NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
frontend       NodePort    10.100.19.222    <none>        80:31078/TCP   6s
kubernetes     ClusterIP   10.100.0.1       <none>        443/TCP        101m
redis-master   ClusterIP   10.100.181.236   <none>        6379/TCP       41m
redis-slave    ClusterIP   10.100.27.82     <none>        6379/TCP       41m
```

Lastly, check ingress controller's public DNS is reachable from browser
```bash
# visit the URL from browser
kubectl  get svc nginx-ingress-controller-nginx-ingress -n nginx-ingress-controller | awk '{ print $4 }' | tail -1
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
