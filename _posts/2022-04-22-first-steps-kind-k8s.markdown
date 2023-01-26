---
layout: post
title: "Using Kind to sandbox Kubernetes"
comments: false
tags: [tech,kubernetes]
#categories: [tech,kubernetes]
published: true
description: "Better for sandboxes, fewer opinions, less magic"
keywords: ""
excerpt_separator: <!-- more -->
---

[Last time]({{ site.baseurl }}/blog/2022/04/14/first-steps-microk8s) I ended spending far longer wrestling with microk8s on windows than actually doing Kubernetes based things. I've tried microk8s on my RPi instances, and it plays absolutely fine so it was definitely the interoperability between Windows and microk8s. As a result I decided to do the same thing with [kind](https://kind.sigs.k8s.io/) just to reflect on the differences.

TLDR; My opinion is that [kind](https://kind.sigs.k8s.io/) is much better for creating sandbox test environments; I might consider something like [talos](https://talos.dev) as well for building out a K8S environment. Since Kind has fewer opinions, you're not wrestling with your search engine, and you can mostly follow the vanilla K8S install guides for whatever you want. I'm still going to bootstrap K8S with an ingress controller running ActiveMQ, Elasticsearch and Kibana. KEDA is installed, and I'll be installing Interlok later on into the cluster.

<!-- more -->

# Things I worked out

- The only real thing I had to figure out was how to patch the ingress controller with the required settings. There wasn't any fighting with the interoperability between docker/windows/k8s.
- Hyper-V apparently prefers contiguous memory which means that if you provision a 8Gb machine, then even though there might be (just) enough memory to create the VM, Hyper-V might not want to. This was the cause of some frustration when using microk8s on windows.
    - The laptop has 16Gb -> the kind cluster ran relatively happily whereas microk8s wasn't guaranteed to.
- Kind still has magic since it installs the local storage class from _Rancher_ and CNI as part of its bootstrapping process. This means we can get things done quicker in a sandbox, otherwise it would be [https://github.com/kelseyhightower/kubernetes-the-hard-way](https://github.com/kelseyhightower/kubernetes-the-hard-way) all the way.
- `kind load docker-image` is very useful but do make sure your ImagePullPolicy is `IfNotPresent`
- I opted for a 2 worker nodes because I could, not because I had to, you could just do everything in a single node, and remove both `-worker` lines from the cluster definition.
- We can arguably get the same experience with microk8s by ignoring their addons and treating it as a vanilla K8S environment but fighting with Windows about microk8s is not how I want to spend my time.

# Bootstrap Kind

You'll need to `scoop install kind kubectl helm` as a bare minimum (or use your preferred package manager) and I'm assuming that you have docker installed. You also need to do the __/etc/hosts__ dance - `127.0.0.1 kind.zzlc activemq.kind.zzlc kibana.kind.zzlc elasticsearch.kind.zzlc`. You only have to do this the once (unlike microk8s).

We're going to build a cluster of 3 nodes (2 workers and 1 control-plane), with port-forwarding enabled for HTTP and ActiveMQ (openwire + amqp). The _docker update_ updates the container(s) so that they don't auto restart. It is, after all, a disposable sandbox. We're also going to pull and push images into the local cluster purely for efficiency to avoid multiple pulls if you reset your cluster repeatedly.

```yml
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
nodes:
  - role: control-plane
    kubeadmConfigPatches:
    - |
      kind: InitConfiguration
      nodeRegistration:
        kubeletExtraArgs:
          node-labels: "ingress-ready=true"
    extraPortMappings:
    - containerPort: 61616
      hostPort: 61616
      protocol: TCP
    - containerPort: 5672
      hostPort: 5672
      protocol: TCP
    - containerPort: 80
      hostPort: 80
      protocol: TCP
  - role: worker
  - role: worker
```

```console
kind create cluster --config ./kind-cluster.yml
kubectl config use-context kind-kind
docker update --restart=no kind-control-plane kind-worker kind-worker2
docker pull docker.elastic.co/elasticsearch/elasticsearch:7.17.1
docker pull docker.elastic.co/kibana/kibana:7.17.1
docker pull lewinc/activemq:latest-liberica-alpine
kind load docker-image docker.elastic.co/elasticsearch/elasticsearch:7.17.1
kind load docker-image docker.elastic.co/kibana/kibana:7.17.1
kind load docker-image lewinc/activemq:latest-liberica-alpine
```


## Enable the dashboard

This is the TLDR; version of [https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard). I'm using exactly the same configuration as per [their creating a sample user documentation](https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md) You should of course read their documentation for the full picture.  Since we probably want pretty charts, we also install metrics-server and patch it so we can do insecure tls.

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.5.1/aio/deploy/recommended.yaml
kubectl apply -f k8s-dashboard-user.yml
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch -n kube-system deployment metrics-server --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kubectl rollout status deployment kubernetes-dashboard -n kubernetes-dashboard --timeout=600s
```

## Enable NGINX Ingress

> The helm chart way of installing ingress-nginx doesn't patch the containers, so the ports aren't exposed (since nginx-controller ends up running on _kind-worker_ not _kind-control-plane_) so we really do need to follow the instructions from [https://kind.sigs.k8s.io/docs/user/ingress](https://kind.sigs.k8s.io/docs/user/ingress)


Once we've enabled the ingress controller we create a new config map that contains our port mappings c.f. [https://kubernetes.github.io/ingress-nginx/user-guide/exposing-tcp-udp-services/](https://kubernetes.github.io/ingress-nginx/user-guide/exposing-tcp-udp-services/) and we patch the deployment so that we add the ports and the required commandline flag. The jsonpatch file may end up being wrong since we don't control upstream, so eyeball the configuration afterwards we should have added a _--tcp-services-configmap_ arg and the 5672/61616 ports to the list of ports exposed.


```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl apply -f nginx-tcp-configmap.yml -n ingress-nginx
kubectl patch deployment ingress-nginx-controller -n ingress-nginx --type "json" --patch "$(cat ./kind-ingress-controller.jsonpatch)"
kubectl rollout status deployment ingress-nginx-controller -n ingress-nginx --timeout=600s
```


```yml
kind: ConfigMap
apiVersion: v1
metadata:
  name: nginx-ingress-tcp-conf
  namespace: ingress-nginx
data:
  5672: "quotidian-ennui/activemq:5672"
  61616: "quotidian-ennui/activemq:61616"
```

```json
[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/ports/-",
    "value": { "name": "amqp-5672", "hostPort": 5672, "containerPort": 5672, "protocol": "TCP" }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/ports/-",
    "value": { "name": "openwire-61616", "hostPort": 61616, "containerPort": 61616, "protocol": "TCP" }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--tcp-services-configmap=$(POD_NAMESPACE)/nginx-ingress-tcp-conf"
  }
]
```

## ActiveMQ

We're just going to re-use everything previously from [my previous gist](https://gist.github.com/quotidian-ennui/575546ba89ea0f4dfe8276fb7a845ef8) with some minor changes. We're going to install KEDA now as well.

- Edit the activemq.yml so that the ingressClassName is `nginx`
- The host should be `activemq.kind.zzlc`
- The ImagePullPolicy to `IfNotPresent` (instead of `Always` to avoid docker rate limits)


```
kubectl apply -f https://github.com/kedacore/keda/releases/download/v2.6.1/keda-2.6.1.yaml
kubectl create namespace quotidian-ennui
kubectl apply -f activemq.yml -n quotidian-ennui
kubectl rollout status deployment activemq -n quotidian-ennui --timeout=600s
```

### Elasticsearch

We're going to use helm with slightly modified files from the gist again. The key differences between this and the microk8s version are:

- We don't define the storageClass for elasticsearch, their example suggests `local-path`, but the default cluster creation suggests it should be `standard`. We don't bother with it, since there's only a single storage class and we let it work itself out.
- We remove the `sysctlInitContainer` and `esConfig` section.
- We change the ingress controller class name back to nginx (from public).
- We change the ingress hosts to be _XXX.kind.zzlc_

```
helm repo add elastic https://helm.elastic.co
helm install elasticsearch --namespace quotidian-ennui --version 7.17.1 elastic/elasticsearch -f helm-elastic-values.yml
helm install kibana --namespace quotidian-ennui --version 7.17.1 elastic/kibana -f helm-kibana-values.yml
kubectl rollout status deployment kibana-kibana -n quotidian-ennui --timeout=600s
```

At this point http://elasticsearch.kind.zzlc and http://kibana.kind.zzlc should work.
