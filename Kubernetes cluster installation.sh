Kubernetes cluster installation
*******************************

#Disable selinux
*****************
sestatus
vi /etc/sysconfig/selinux
reboot

#Add Kernel Modules
*******************
modprobe br_netfilter
modprobe ip_vs
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_sh
modprobe overlay

#Configure Sysctl
*****************
cat > /etc/modules-load.d/kubernetes.conf << EOF
br_netfilter
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
overlay
EOF

cat > /etc/sysctl.d/kubernetes.conf << EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system

#Install Containerd
*******************
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf makecache
dnf -y install containerd.io
sh -c "containerd config default > /etc/containerd/config.toml" ; cat /etc/containerd/config.toml
cat /etc/containerd/config.toml | grep SystemdCgroup
vi /etc/containerd/config.toml
systemctl enable --now containerd.service
systemctl reboot

#Install Docker 
***************
hostnamectl set-hostname master
systemctl status containerd.service
yum install -y docker-ce docker-ce-cli
vi /etc/docker/daemon.json
systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl start docker
systemctl status docker

#Install Kubernetes Components
******************************
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

dnf makecache
dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet.service
sudo kubeadm config images pull
#Run below command only on master node
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl get pods -n kube-system
kubeadm token create --print-join-command
kubectl get pods -o wide
kubectl get nodes -o wide
kubectl get nodes

#Run below command only on worker node
kubeadm join 172.31.2.128:6443 --token ai5sb1.njrtl5by0gui9ain --discovery-token-ca-cert-hash sha256:bd9eee7997290fbda555aa5713f1c203d37ed5681ead2b94177f764580d352e0