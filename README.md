IP Tool for Kubernetes Cluster
This project consists of a Python script to check the IP addresses assigned to Pods in a Kubernetes cluster and identify any IP address collisions. The script is run inside a Docker container, which is deployed in the Kubernetes cluster. The project also includes the creation of a Docker image, uploading it to Docker Hub, and deploying it on a Kubernetes cluster.

Steps to Complete the Assignment
********************************
1. Write a Python Script to Get IP Addresses of Pods and Check for Collision
The Python script is used to list the IP addresses assigned to pods in a Kubernetes cluster and check if any IPs are colliding.

import argparse
import ipaddress
import os
from kubernetes import client, config

def get_pod_ips():
    # Load Kubernetes configuration (assuming running inside a pod with appropriate service account permissions)
    try:
        config.load_incluster_config()  # Automatically loads from within a cluster
    except:
        print("Failed to load in-cluster config. Ensure the pod has access to the cluster.")
        exit(1)

    v1 = client.CoreV1Api()
    pods = v1.list_pod_for_all_namespaces(watch=False)
    pod_ips = []

    for pod in pods.items:
        # Get the pod's IP address
        if pod.status.pod_ip:
            pod_ips.append(pod.status.pod_ip)
    
    return pod_ips

def check_collision(ip_networks, output_file):
    collided_networks = []
    seen_networks = set()
    
    for network in ip_networks:
        try:
            ip_obj = ipaddress.IPv4Address(network)  # Use IPv4Address for exact IP matching
            if ip_obj in seen_networks:
                collided_networks.append(network)
            else:
                seen_networks.add(ip_obj)
        except ValueError as e:
            print(f"Skipping invalid IP: {network}")
    
    if collided_networks:
        with open(output_file, 'w') as f:
            f.write("\n".join(collided_networks))
        print(f"Collisions found: {', '.join(collided_networks)}")
    else:
        print("No collisions found.")

def main():
    parser = argparse.ArgumentParser(description="IP Tool")
    parser.add_argument('--check-collision', metavar='<file_path>', type=str, help="Check for IP collisions from a file.")
    args = parser.parse_args()
    
    pod_ips = get_pod_ips()
    print("Pod IPs in Cluster:")
    print("\n".join(pod_ips))
    
    if args.check_collision:
        check_collision(pod_ips, args.check_collision)
    else:
        print("No collision check triggered.")
        print("IPs of Pods in Cluster:")
        print("\n".join(pod_ips))

if __name__ == "__main__":
    main()

2. Create a Dockerfile to Run Python Script and Install Dependencies
This Dockerfile builds an image for the Python script, installing necessary dependencies such as kubernetes and ipaddress.

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

3. Build the Docker Image
Run the following command to build the Docker image:

docker build -t omkar1993/ip-tool:latest .

4. Upload the Docker Image to Docker Hub
Login to Docker Hub:

docker login
Then push the image to Docker Hub:

docker push omkar1993/ip-tool:latest

5. Kubernetes Cluster Installation
Install Kubernetes on the master and worker nodes. You can follow the official Kubernetes documentation to set up a cluster:

Kubernetes Installation Guide
https://infotechys.com/install-a-kubernetes-cluster-on-rhel-9/

6. Pull the Docker Image on the Kubernetes Master Node
On the Kubernetes master node, pull the Docker image from Docker Hub:

docker pull omkar1993/ip-tool:latest

7. Create a Deployment to Deploy Pod on Kubernetes Cluster
Create a Kubernetes deployment YAML file (ip-tool-deployment.yaml) for deploying the ip-tool Docker image as a pod on the cluster:

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

Apply the deployment to the Kubernetes cluster:

kubectl apply -f ip-tool-deployment.yaml

8. Check and Verify Deployment Status
Verify the status of the deployment and check if the pod is running:

kubectl get deployments -n application
kubectl get pods -n application

You should see the ip-tool-deployment with one pod running.

9. Check Logs of Pod for Output
To check the logs of the pod and see the output of the script:

kubectl logs -l app=ip-tool -n application

This will show the logs for all the pods related to the ip-tool deployment.

[root@master ip-tool]# kubectl get pods -n application
NAME                                  READY   STATUS    RESTARTS      AGE
ip-tool-deployment-5b8dbc97cf-ll6zr   1/1     Running   2 (14s ago)   17s
mongodb-77fc48fffd-qr99s              1/1     Running   4 (42m ago)   34h
mongodb-exporter-5fc9848b67-fpnqx     1/1     Running   2 (42m ago)   24h
my-todo-app-64f844cbcd-ngs7b          1/1     Running   4 (42m ago)   34h
promtail-mptq6                        1/1     Running   3 (42m ago)   28h
promtail-mqqp9                        1/1     Running   3 (42m ago)   28h

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

9. Check pod logs for output

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

Conclusion
This project successfully deploys a Python script in a Kubernetes cluster to fetch the IP addresses assigned to pods and check for collisions. The process involves creating the Python script, building and pushing a Docker image, deploying it in Kubernetes, and verifying the results.
