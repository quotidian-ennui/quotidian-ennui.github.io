---
layout: post
title: "First steps in microk8s"
comments: false
tags: [tech,kubernetes]
categories: [tech,kubernetes]
published: true
description: "It hides the magic, and I hate not seeing the magic"
keywords: ""
excerpt_separator: <!-- more -->
---

I've been making my first foray into deploying some things into K8S. I've never really used it in anger to deploy something that I have a personal relationship with. My trusted peers tell me that [kind](https://kind.sigs.k8s.io/) is probably one of the better ways to start with K8S; I've also got a use case where I'm intending to build a cluster at home (via a bunch of RPIs) and since microk8s touts itself has being zero-ops and it has a KEDA add on I thought I'd give it a spin.

This is 2 days worth of fun, mostly wrestling with my search engine of choice for the right terms to narrow down to my specific problem. In many respects nothing that I'm doing is new or special and should have been painless; but once you get past the _most trivial of examples_ you're in a world of search pain or stack overflow noise if you aren't already an Kubernetes expert. So, this is a blog post that tries to save you pain with a non-trivial trivial example of deploying something you could use in the real world.

I'm going to bootstrap a single kubernetes node with an ingress controller running ActiveMQ, Elasticsearch and Kibana. This is easy to do if you were using docker compose, and that's what I would usually do, but I wanted to play with KEDA since I have an interest in understanding how to autoscale workers that are attached to JMS, and what gotcha's I need to think about.

<!-- more -->

## Things that I wish I knew before I started.

This is just an assorted list of things that I wish I knew but still blundered my way through via a combination of brute force and ignorance.

1. MicroK8S uses Multipass under the covers, so that means you end up spin up a Hyper-V Ubuntu VM. This isn't a problem in my lab, but is a problem on my laptop (mainly memory pressure issue because of docker).
2. There are definitely networking issues if your combination is MicroK8s/Multipass/Hyper-V which I am. I'm  certain things _just work_ if you're using the microk8s on Ubuntu natively.
3. The on-boot RAM you provision for the underlying multipass machine determines what's reported when you do `microk8s kubectl describe node microk8s-vm`. This stands to reason once you think about it, K8S doesn't care and doesn't know about dynamic memory.
   - With this in mind initialise microk8s with the amount of memory you think you need (say 8/12/16Gb); shutdown the machine edit the memory, so that on-boot is the desired amount, and dynamic memory ranges from 512Mb to _desired+512Mb_. That's a pre-emptive attempt to make sure that microk8s doesn't exhaust all the memory, leaving you with something for the OS to do its thing.
   - Turn off checkpoints (this is a sandbox env, and I don't care).
4. The KEDA addon is pinned at 2.1.0; which isn't awful but that version doesn't know about activemq autoscaler.
5. The ingress add-on is pre-enabled with configmaps for TCP/UDP port forwarding which does make things somewhat simpler.
6. I can't trust microk8s to start properly; so I end up using `multipass start microk8s-vm && microk8s start`.

# Bootstrap MicroK8S

- Install it, and afterwards follow [https://microk8s.io/docs/dockerhub-limits] for your preferred method to handling rate limiting.
    - I opted for `microk8s kubectl create secret docker-registry dockerhub --docker-server=https://index.docker.io/v1/ --docker-username=myUsername --docker-password=XXXXXXX --docker-email=myemail@example.com` because this seems like the _right thing to do_, the various yaml files reflect that my image secrets are in a secrets called `dockerhub`
- `microk8s enable ingress dashboard dns registry helm3`
- `microk8s kubectl apply -f https://github.com/kedacore/keda/releases/download/v2.6.1/keda-2.6.1.yaml`
    - This effectively does the same thing as enabling the addon, but it moves us to the latest release

## Windows default switch networking

Multipass will default to using the Hyper-V default switch which presents problems since it doesn't guarantee static IP addresses. These notes hopefully save you bother when the Hyper-V default switch decides to issue _yet another IP address_ to your microk8s-vm because you've left it stopped overnight. I'm only running a single node microk8s cluster and their documentation suggests that it should be able to cope with IP Address changes, but it doesn't or won't.

- `scoop install sudo jq` because _like the pigeons_ we love a bit of that (if you aren't using _scoop_, then use the _choco_ equivalent).
- Make sure the multipass service is started; there's no guarantee that it stays started (apparently): `sudo net start multipass`

You should switch to using DNS Names rather than the derived IP Addresses with kubectl, or make sure that every time you restart microk8s you regenerate the config. If you're using your own version of kubectl, then it's best to switch to using DNS names so you don't have to keep "managing" your local kube config.

### Using DNS Names

- edit _$HOME/AppData/MicroK8s/config_; change the server to be `microk8s-vm.mshome.net` rather than the IP Address.
    - If you've merged into ~/.kube/config then do the same thing there.
- Get a shell on the microk8s-vm and edit _/var/snap/microk8s/current/certs/csr.conf.template_ so that you add in microk8s-vm.mshome.net as one of the `alt_names` -> `DNS.6 = microk8s-vm.mshome.net`
- Restart the services `microk8s.stop && microk8s.start` via the shell while on the VM.

## Removing the day-to-day grind

I live in the wingit+bash shell but I appear to have some trouble typing _micro_ repeatedly so here's a bunch of aliases to make my life easier. I know that I'm going to us an ingress controller and I want to be able to start my browser with _http://activemq.microk8s.local_ and hit the admin interface for activemq so I am modifying the hosts file _whenever I start microk8s_[^1].

```bash
mk8s() {
  local action=$1
  case "$action" in
    start )
      multipass start microk8s-vm
      microk8s start
      microk8s config > $HOME/AppData/Local/MicroK8s/config
      mk8s_host=$(multipass info microk8s-vm | grep IPv4 | awk '{ print $2}')
      # This does mean we get the secure desktop yes/no prompt.
      sudo $HOME/bin/microk8s-hosts.ps1 -ip "$mk8s_host"
      ;;
    config )
      microk8s config > $HOME/AppData/Local/MicroK8s/config
      ;;
    hosts )
      mk8s_host=$(multipass info microk8s-vm | grep IPv4 | awk '{ print $2}')
      # This does mean we get the secure desktop yes/no prompt.
      sudo $HOME/bin/microk8s-hosts.ps1 -ip "$mk8s_host"
    token )
      # Gives you the token for the dashboard
      ## using get secret + go template would be better but falls foul of blog templating...
      microk8s kubectl -n kube-system describe secret $(microk8s kubectl -n kube-system get secret | grep default-token | cut -d " " -f1)
      ;;
    info )
      microk8s kubectl describe node microk8s-vm
      ;;
    ip )
      # jq + tr or grep + awk...
      # multipass info microk8s-vm --format json | jq '.info."microk8s-vm".ipv4[0]' | tr -d '"'
      multipass info microk8s-vm | grep IPv4 | awk '{ print $2}'
      ;;
    dashboard )
      # Starts chrome
      local ip=$(multipass info microk8s-vm | grep IPv4 | awk '{ print $2 }')
      local port=$(microk8s kubectl -n kube-system get services -l k8s-app=kubernetes-dashboard --no-headers=true -o custom-columns="Port:.spec.ports[0].nodePort")
      # local port=$(microk8s kubectl -n kube-system get services -l k8s-app=kubernetes-dashboard --no-headers=true | awk '{ print $5 }' | awk -F: '{ print $2 }' | awk -F"/" '{ print $1 }')
      start chrome --ignore-certificate-errors --incognito -new-tab "https://$ip:$port"
      ;;
    *)
      microk8s $@
      ;;
  esac
}
alias mkctl='microk8s kubectl'
# because you want to run telnet from within the K8S cluster - https://github.com/mcwarman/k8s-jump-box
alias k8ssh='winpty microk8s kubectl run jump-box --image=ghcr.io/mcwarman/k8s-jump-box:1 -i -t --image-pull-policy=Always --restart=Never --rm'
```

### dashboard-proxy

This is to remove the need to run `microk8s dashboard-proxy`. Just make the kubernetes-dashboard a NodePort rather than a ClusterIP so we can access it. If you have the bash aliases above, then `mk8s dashboard` will do the right thing and you can login via the output from `mk8s token`.

```console
$ mkctl -n kube-system edit service kubernetes-dashboard
# Change ClusterIP to be NodePort
$ mkctl -n kube-system get services
NAME                        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE
metrics-server              ClusterIP   10.152.183.171   <none>        443/TCP                  11m
dashboard-metrics-scraper   ClusterIP   10.152.183.136   <none>        8000/TCP                 10m
kube-dns                    ClusterIP   10.152.183.10    <none>        53/UDP,53/TCP,9153/TCP   10m
kubernetes-dashboard        NodePort    10.152.183.247   <none>        443:31635/TCP            10m
```

## Bootstrap the namespace

If you're going to use helm3 with local files (i.e. you want to modify my gists) then We need to mount _a directory_ on the multipass VM; on Windows I had set privileged-mounts to be true (`multipass set local.privileged-mounts=true`). Note that when you pass in the filename via wingit+bash you need to do a `//` otherwise it will try and do some kind of local path resolution, so `helm3 -f //mnt/quotidian-ennui/xxx.yml`.

- `multipass mount . microk8s-vm:/mnt/quotidian-ennui`
- `mkctl create namespace quotidian-ennui`

# ActiveMQ

There don't seem to be any _obvious_ ActiveMQ Helm charts out there, so we can do a single node manually. That isn't to say there aren't any, but I haven't googled very hard, and I am probably reinventing the wheel. We're doing the bare minimum of work here, if this wasn't a sandbox environment I would think about having these files properly checked into source control.

> Be aware that the ingress addon uses `public` as the classname for the controller rather than `nginx`; I guess it's so that you can switch between ingress providers w/o changing your application ingress descriptors. The examples for elasticsearch for instance use `nginx`.

1. Patch the ingress controller tcp configmap so that we can port forward the standard AMQP and openwire ports
2. Patch the ingress controller daemonset so that the ports are forwarded.
3. Create the ActiveMQ Deployment


```console
$ mkctl patch configmap nginx-ingress-tcp-microk8s-conf -n ingress \
  --patch "$(curl -s https://gist.githubusercontent.com/quotidian-ennui/575546ba89ea0f4dfe8276fb7a845ef8/raw/289444405fe4a3ce66e89152e2b92ea3cf0a2388/nginx-tcp-configmap-patch.yml)"

$ mkctl patch ds -n ingress nginx-ingress-microk8s-controller --type "json" \
  --patch "$(curl -s https://gist.githubusercontent.com/quotidian-ennui/575546ba89ea0f4dfe8276fb7a845ef8/raw/289444405fe4a3ce66e89152e2b92ea3cf0a2388/nginx-ingress-controller.jsonpatch)"

$ mkctl apply -f https://gist.githubusercontent.com/quotidian-ennui/575546ba89ea0f4dfe8276fb7a845ef8/raw/289444405fe4a3ce66e89152e2b92ea3cf0a2388/activemq.yml \
  -n quotidian-ennui

```

At this point, you should be able to point your browser to http://activemq.microk8s.local and use the credentials `admin/admin`, and you can connect to  `activemq.microk8s.local:61616` via telnet or your preferred ActiveMQ client.

Note that the `lewinc/activemq:latest-liberica-alpine` referenced in the activemq.yml gist (as of 2022-04-13) has had the `<cors>` specification removed from `jolokia-access.xml`. While arguably more insecure, this means we don't have to jump through more hoops with KEDA.

# Elasticsearch

Well, elasticsearch has a helm chart so we can just use `microk8s helm3` to install it once we've figured out precisely what we want. I want a single node elastic search instance, it's a sandbox and I don't really care about resilience.

```console
$ mk8s helm3 repo add elastic https://helm.elastic.co
$ mk8s helm3 install elasticsearch --namespace quotidian-ennui \
    --version 7.17.1 elastic/elasticsearch \
    -f https://gist.githubusercontent.com/quotidian-ennui/575546ba89ea0f4dfe8276fb7a845ef8/raw/0a86dc2e4e456bd193e9500314ad910b7af9572a/elasticsearch-helm-values.yml
$ mk8s helm3 install kibana --namespace quotidian-ennui \
    --version 7.17.1 elastic/kibana \
    -f https://gist.githubusercontent.com/quotidian-ennui/575546ba89ea0f4dfe8276fb7a845ef8/raw/bf0bc7f21ff59e337632cc83343b3e6707ba6122/kibana-helm-values.yml
```

Since I have enabled ingress on both elasticsearch & kibana, they're available on http://elasticsearch.microk8s.local and http://kibana.microk8s.local respectively.


[^1]: Powershell script [microk8s-host.ps1](https://gist.github.com/quotidian-ennui/575546ba89ea0f4dfe8276fb7a845ef8#file-microk8s-hosts-ps1) that edits the hosts file