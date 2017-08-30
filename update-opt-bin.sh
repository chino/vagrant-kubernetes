k8s=${1:-v1.7.4}
wget -N -P ./opt-bin https://storage.googleapis.com/kubernetes-release/release/${k8s}/bin/linux/amd64/kubectl
wget -N -P ./opt-bin https://storage.googleapis.com/kubernetes-release/release/${k8s}/bin/linux/amd64/kube-apiserver
wget -N -P ./opt-bin https://storage.googleapis.com/kubernetes-release/release/${k8s}/bin/linux/amd64/kube-controller-manager
wget -N -P ./opt-bin https://storage.googleapis.com/kubernetes-release/release/${k8s}/bin/linux/amd64/kube-scheduler
wget -N -P ./opt-bin https://storage.googleapis.com/kubernetes-release/release/${k8s}/bin/linux/amd64/kubelet
wget -N -P ./opt-bin https://storage.googleapis.com/kubernetes-release/release/${k8s}/bin/linux/amd64/kube-proxy
wget -N -P ./opt-bin https://storage.googleapis.com/kubernetes-release/release/${k8s}/bin/linux/amd64/kubelet
wget -N -P ./opt-bin https://storage.googleapis.com/kubernetes-release/release/${k8s}/bin/linux/amd64/kube-proxy
wget -N -P ./opt-bin https://github.com/containernetworking/cni/releases/download/v0.6.0/cni-v0.6.0.tgz
