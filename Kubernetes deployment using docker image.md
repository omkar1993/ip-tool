Kubernetes deployment using docker image for IP-collision
*********************************************************

STEP 1 : Create a Dockerfile to deploy python script with prerequisites installed 

# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory inside the container
WORKDIR /app

# Install necessary Python packages (Kubernetes client, etc.)
RUN pip install --no-cache-dir kubernetes ipaddress

# Copy the script into the container at /app
COPY ip-tool.py /app/

# Define the command to run the script
CMD ["python", "ip-tool.py"]

STEP 2 : Build Dockerfile to create image

docker build -t ip-tool:latest -f Dockerfile .

STEP 3 : Push image to dockerhub registry

docker tag ip-tool:latest omkar1993/ip-tool:latest
docker push omkar1993/ip-tool:latest

STEP 4 : Pull docker image on kubernetes master server

docker pull omkar1993/ip-tool:latest

STEP 5 : Create kubernetes deployment to deploy pods using docker image

On Kuberntes Master server
*********************************************************

mkdir /ip-tool
cd /ip-tool

cat ip-tool-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ip-tool-deployment
  namespace: application  
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ip-tool
  template:
    metadata:
      labels:
        app: ip-tool
    spec:
      containers:
      - name: ip-tool
        image: omkar1993/ip-tool:latest2   
        command: ["python", "ip-tool.py"]
        args: []   
      serviceAccountName: ip-tool-service-account 

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ip-tool-service-account
  namespace: application  

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ip-tool-clusterrole 
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["list", "get"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ip-tool-clusterrolebinding
subjects:
  - kind: ServiceAccount
    name: ip-tool-service-account
    namespace: application 
roleRef:
  kind: ClusterRole
  name: ip-tool-clusterrole
  apiGroup: rbac.authorization.k8s.io

STEP 6 : Apply and Verify the Deployment

kubectl apply -f ip-tool-deployment.yaml

[root@master ip-tool]# kubectl get deployments -n application
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
ip-tool-deployment   1/1     1            0           70s
mongodb              1/1     1            1           33h
mongodb-exporter     1/1     1            1           23h
my-todo-app          1/1     1            1           33h

[root@master ip-tool]# kubectl get serviceaccounts -n application
NAME                      SECRETS   AGE
default                   0         35h
ip-tool-service-account   0         75s
promtail                  0         27h

[root@master ip-tool]# kubectl get clusterrolebindings | grep ip-tool-clusterrolebinding
ip-tool-clusterrolebinding                               ClusterRole/ip-tool-clusterrole                                                    118s
[root@master ip-tool]# 

[root@master ip-tool]# kubectl get pods -n application
NAME                                  READY   STATUS    RESTARTS      AGE
ip-tool-deployment-5b8dbc97cf-ll6zr   1/1     Running   2 (14s ago)   17s
mongodb-77fc48fffd-qr99s              1/1     Running   4 (42m ago)   34h
mongodb-exporter-5fc9848b67-fpnqx     1/1     Running   2 (42m ago)   24h
my-todo-app-64f844cbcd-ngs7b          1/1     Running   4 (42m ago)   34h
promtail-mptq6                        1/1     Running   3 (42m ago)   28h
promtail-mqqp9                        1/1     Running   3 (42m ago)   28h

STEP 7 : Check pod logs for output

kubectl logs ip-tool-deployment-5b8dbc97cf-ll6zr -n application

Pod IPs in Cluster:
10.244.1.196
10.244.1.181
10.244.1.183
10.244.1.182
10.244.0.9
10.244.1.190
172.31.2.128
172.31.8.166
10.244.1.184
10.244.1.188
172.31.2.128
172.31.2.128
172.31.2.128
172.31.2.128
172.31.8.166
172.31.2.128
10.244.1.187
10.244.1.186
172.31.8.166
172.31.2.128
10.244.1.189
10.244.1.185
172.31.2.128
No collision check triggered.
IPs of Pods in Cluster:
10.244.1.196
10.244.1.181
10.244.1.183
10.244.1.182
10.244.0.9
10.244.1.190
172.31.2.128
172.31.8.166
10.244.1.184
10.244.1.188
172.31.2.128
172.31.2.128
172.31.2.128
172.31.2.128
172.31.8.166
172.31.2.128
10.244.1.187
10.244.1.186
172.31.8.166
172.31.2.128
10.244.1.189
10.244.1.185
172.31.2.128
[root@master ip-tool]#