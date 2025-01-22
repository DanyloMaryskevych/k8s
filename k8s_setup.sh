#!/bin/bash

# Function to display usage
usage() {
  echo "Usage: $0 -v <version> -c <cidr> -r <role>"
  echo "Example: $0 -v v1.30 -c 10.244.0.0/16 -r master"
  exit 1
}

# Parse command line arguments
while getopts "v:c:r:" opt; do
  case $opt in
    v) K8S_VERSION=$OPTARG ;;
    c) CIDR_BLOCK=$OPTARG ;;
    r) ROLE=$OPTARG ;;
    *) usage ;;
  esac
done

# Validate inputs
if [ -z "$K8S_VERSION" ] || [ -z "$ROLE" ]; then
  usage
fi

# Validate CIDR for the master role
if [[ "$ROLE" == "master" && -z "$CIDR_BLOCK" ]]; then
  echo "Error: CIDR block is required for the 'master' role."
  usage
fi

# Validate role input
if [[ "$ROLE" != "worker" && "$ROLE" != "master" ]]; then
  echo "Error: Invalid role. Please specify either 'worker' or 'master'."
  exit 1
fi
# Print the selected options
echo "Kubernetes Version: $K8S_VERSION"
echo "CIDR Block: $CIDR_BLOCK"
echo "Role: $ROLE"

# Update the system package index
sudo apt-get update

# Install necessary dependencies
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Add Kubernetes GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update the package index again to include Kubernetes repository
sudo apt-get update

# Install Kubernetes components
sudo apt-get install -y kubelet kubeadm kubectl

# Prevent automatic updates of these packages
sudo apt-mark hold kubelet kubeadm kubectl

# Enable and start the kubelet service
sudo systemctl enable --now kubelet

echo "Kubernetes $K8S_VERSION installation completed successfully."

echo "Setup container runtime"
sudo apt-get update
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd.service

sudo modprobe br_netfilter
sudo echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sudo echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
sudo sysctl -p


# Role-specific configuration
if [ "$ROLE" == "master" ]; then
  echo "Configuring as Master Node..."

  kubeadm init --pod-network-cidr=$CIDR_BLOCK --cri-socket="unix:///var/run/containerd/containerd.sock"

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  # Setup flannel
  wget https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
  cat kube-flannel.yml | sed "s#\"Network\": \"10.244.0.0/16\"#\"Network\": \"$CIDR_BLOCK\"#" | tee kube-flannel-new.yml

  mv kube-flannel-new.yml kube-flannel.yml
  kubectl apply -f kube-flannel.yml

  echo "Kubernetes setup for role $ROLE is complete."

elif [ "$ROLE" == "worker" ]; then
  echo "Worker Node is configured successsfully. Now get jion command on master node."
  echo ""
  echo "     kubeadm token create --print-join-command"
  echo ""
fi

echo "Create alias 'k=kubectl'"
echo "alias k='kubectl'" >> ~/.bashrc
source ~/.bashrc

echo "Done!"
