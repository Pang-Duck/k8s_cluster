#!/usr/bin/env bash

# hosts

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

# package install & add repo

dnf-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

cat <<EOF >/etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

dnf update
#dnf install -y vim && dnf install -y dnf-utils && dnf install -y containerd.io && dnf install -y nfs-utils
dnf install -y vim dnf-utils containerd.io nfs-utils curl kubeadm kubelet kubectl
containerd config default >/etc/containerd/config.toml

systemctl daemon-reload
systemctl enable containerd

# kernel mode setting
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system
