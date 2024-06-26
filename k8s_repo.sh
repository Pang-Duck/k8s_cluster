#!/usr/bin/env bash

# test
# hosts config

cat <<EOF >>/etc/hosts
10.60.200.60 acc-master1
10.60.200.61 acc-master2
10.60.200.62 acc-master3
10.60.200.63 acc-worker1
10.60.200.64 acc-loadbalancer
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
yum install -y epel-release vim yum-utils nfs-utils curl bash-completion wget net-utils bind-utils iproute-tc
yum install -y podman
yumdownloader --downloadonly containerd.io
rpm -Uvh --force --nodeps containerd.io*
containerd config default >/etc/containerd/config.toml
sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml
systemctl daemon-reload
systemctl enable containerd
systmectl restart containerd
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

sysctl --system

# kubectl auto complete
cat <<EOF >>~/.bashrc
source <(kubectl completion bash)
alias k=kubectl
complete -o default __start_kubectl k
source /usr/share/bash-completion/bash_completion
EOF
source ~/.bashrc
