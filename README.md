Builds a small kubernetes cluster based on Calico's tutorial setup.

# Setup

First time:

```
./update-opt-bin.sh
```

Then build it:

```
EXTRAS=true NET=[calico|weave|flannel] vagrant up
```

# Clients

You can open the kubernetes UI by running:
```
./bin/open-ui
```

There is also a little status watcher script:
```
./watch.sh
```

You can ssh into the k8s-master instance to use various tools:
- kubectl
- calicoctl
- weave
- odp

You can also use them locally (except for weave/odp):
```
./bin/setup-clients
```

# Services

Normally you simply connect to the `NodePort` on any of the `host-only` VM addresses.

The following ports are also forwarded to `localhost` for ease of use:
- 8080 = k8 ui
- 2379 = etcd

TODO: Setup `Ingress/Itsio` to expose http services via central point.
