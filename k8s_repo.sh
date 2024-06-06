#!/usr/bin/env bash

# package install

dnf-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf update
dnf install -y vim && dnf install -y dnf-utils && dnf install -y containerd.io

# disable firewalld & selinux
systemctl stop firewalld && systemctl disable firewalld
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# swapoff
swapoff -a
sed -i -e '/swap/d' /etc/fstab
systemctl daemon-reload

# add repository

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
