#!/usr/bin/env bash
# file-name: k8s_repo.sh

# hosts config

cat <<EOF >/etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
10.60.200.60 k8s-master1 
10.60.200.61 k8s-master2
10.60.200.62 k8s-master3
10.60.200.63 k8s-node1
EOF

# disable firewalld & selinux
systemctl stop firewalld && systemctl disable firewalld
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# swapoff
swapoff -a
sed -i -e '/swap/d' /etc/fstab
systemctl daemon-reload

# addrepo & packages install

yum-config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
yum install -y kubeadm kubelet kubectl --disableexcludes=kubernetes
yum install -y epel-release vim yum-utils nfs-utils curl bash-completion wget net-utils bind-utils iproute-tc podman
yumdownloader --downloadonly containerd.io
rpm -Uvh --force --nodeps containerd.io*
containerd config default >/etc/containerd/config.toml
sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml
systemctl daemon-reload
systemctl enable containerd
systemctl restart containerd
systemctl enable kubelet

# kernel mode setting
cat <<EOF | tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

# network bridge setting
cat <<EOF | tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

echo "net.ipv4.ip_nonlocal_bind=1" >>/etc/sysctl.conf
echo "net.ipv4.ip_forward=1" >>/etc/sysctl.conf

sysctl --system

# kubectl auto complete
cat <<EOF >>~/.bashrc
source <(kubectl completion bash)
alias k=kubectl
complete -o default __start_kubectl k
source /usr/share/bash-completion/bash_completion
EOF
source ~/.bashrc

test
