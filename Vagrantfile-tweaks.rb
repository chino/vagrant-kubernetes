# vim: set ts=2 sw=2 et ft=ruby :
# rubocop: disable all

# should at least be on same version as we are to not run into bugs
host.vm.box_version = ">= 1409.7.0"

# this is required to allow multicast data to pass on the vbox host-only network
host.vm.provider :virtualbox do |vb|
  vb.customize [ "modifyvm", :id, "--nicpromisc2", "allow-all" ]
end

# add vagrant folder for easy access
host.vm.synced_folder ".", "/vagrant", id: "core",
  :nfs => true, :mount_options => ['nolock,vers=3,udp']

if i == 1
  # port forwards because things like cisco vpn client breaks host-only networking
  host.vm.network "forwarded_port", guest: 8080, host: 8080 # k8 ui
  host.vm.network "forwarded_port", guest: 2379, host: 2379 # etcd

  # setup bash completion for kubectl
  host.vm.provision :file, :source => "/usr/local/etc/bash_completion", :destination => "/home/core/bash_completion"
  host.vm.provision :shell, :inline => "
    set -ex
    sed -i 's!/usr/local/etc/bash_completion!/home/core/bash_completion!g' /home/core/bash_completion
    echo '
      source /home/core/bash_completion
      source <(kubectl completion bash)
    ' > /etc/profile.d/completion
    unlink /home/core/.bashrc
    echo '
      source /etc/profile.d/*
    ' >> /home/core/.bashrc
  ", :privileged => true
end

host.vm.provision :shell, :inline => "
  set -ex

  echo 'waiting for systemd to finish starting'
  files=(kube-proxy kubelet)
  [[ #{i} == 1 ]] &&
    files+=(kube-apiserver kube-controller-manager kube-scheduler kubectl)
  for file in ${files[*]}; do while ! [[ -e /opt/bin/$file ]]; do sleep 1; done; done

  echo waiting for kubernetes api to be reachable
  while ! curl -S -s -L http://172.18.18.101:8080 >/dev/null; do sleep 1; done

  echo waiting for etcd to be reachable
  while ! curl -S -s -L http://172.18.18.101:2379 >/dev/null; do sleep 1; done

  echo checking etcd version
  curl -L http://172.18.18.101:2379/version

  echo checking docker
  docker ps

  # kube-proxy will use the conntrack utility to fix stale conntrack entries
  # https://github.com/projectcalico/calico/issues/1055
  sudo cp /vagrant/utils/conntrack /opt/bin/

  # do this on all hosts
  if [[ '#{ENV['NET']}' == weave ]]; then
    sudo cp /vagrant/utils/odp /opt/bin/
    sudo cp /vagrant/utils/weave /opt/bin/
  fi

  # on the master host
  if [[ #{i} == 1 ]]; then
    echo setting up kubectl
    kubectl config set-cluster vagrant-cluster --server=http://172.18.18.101:8080
    kubectl config set-context vagrant-system --cluster=vagrant-cluster
    kubectl config use-context vagrant-system

    echo waiting for k8s api to be fully up?
    while true; do
      kubectl api-versions | grep 'extensions/v1beta1' && break
    done

    if [[ '#{ENV['NET']}' == weave ]]; then
      echo installing weave
      kubectl apply -f https://git.io/weave-kube-1.6

      kubectl get pods --all-namespaces
    elif [[ '#{ENV['NET']}' == flannel ]]; then
      echo installing flannel
      kubectl apply -f /vagrant/kube-flannel.yaml

    # could not get dhcp plugin to work
    elif [[ '#{ENV['NET']}' == cni-macvlan-dhcp ]]; then
      echo setting up cni macvlan with dhcp ipam
      kubectl apply -f /vagrant/cni-macvlan-dhcp.yaml

    # host-local will not work for multi-node cluster
    elif [[ '#{ENV['NET']}' == cni-macvlan-host-local ]]; then
      echo setting up cni macvlan with host-olocal ipam
      kubectl apply -f /vagrant/cni-macvlan-host-local.yaml

    # TODO: https://kubernetes.io/docs/concepts/cluster-administration/network-plugins/#kubenet
    elif [[ '#{ENV['NET']}' == none ]]; then
      :; # do nothing...

    else
      # sed gets rid of ipip encap
      echo installing calico
      curl -L http://docs.projectcalico.org/v2.5/getting-started/kubernetes/installation/hosted/calico.yaml | sed 's/always/off/' | kubectl apply -f -

      kubectl get pods --all-namespaces

      echo downloading calicoctl
      curl -L -O https://github.com/projectcalico/calicoctl/releases/download/v1.5.0/calicoctl
      chmod +x calicoctl
      mkdir -p /opt/bin
      mv calicoctl /opt/bin

      echo checking calico
      while ! calicoctl node status; do sleep 1; done
    fi

    echo installing skydns
    #kubectl apply -f http://docs.projectcalico.org/v2.5/getting-started/kubernetes/installation/manifests/skydns.yaml
    kubectl apply -f /vagrant/skydns.yaml
    kubectl get pods --all-namespaces

    if [[ '#{ENV['EXTRAS']}' == true ]]; then
      echo installing k8 dashboard
      kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/alternative/kubernetes-dashboard.yaml
      kubectl get pods --all-namespaces

      echo installing heapster for container metrics and graphs in ui
      [[ -d heapster ]] ||
        git clone https://github.com/kubernetes/heapster.git
      (
        cd heapster/deploy/kube-config/influxdb
        kubectl apply -f .
        kubectl get pods --all-namespaces
      )
    fi
  fi

  # enable multicast pings to broadcast addresses
  sysctl net.ipv4.icmp_echo_ignore_broadcasts=0

  true
"
