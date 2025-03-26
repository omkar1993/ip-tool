Python script for IP collision check 
************************************

cat ip-tool.py
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