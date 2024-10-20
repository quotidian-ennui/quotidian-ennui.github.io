---
layout: post
title: "microk8s requires nf_conntrack but doesn't enforce it"
comments: false
tags: [kubernetes, microk8s, ubuntu]
# categories: [terraform,github]
published: true
description: "I'm never getting these 2 hours back again"
keywords: ""
excerpt_separator: <!-- more -->
---

Yep, I use Microk8s to run my local homelab; this is in spite of the fact that I know _just enough to be dangerous_ and run kubernetes the hard way. I'm also baselining my underlying OS on Ubuntu, and yes, I know that Canonical doesn't adhere to the one true way so I deserve everything that I'm getting here.

<!-- more -->

I recently upgraded my homelab to Ubuntu 24.04.1 and I noticed that my K8S cluster wasn't coming up after a reboot. There's a kubereboot process running on each of the nodes because I like things to be hands-off as much as possible.

The symptom was that kubectl after a reboot would sometimes fail to connect to 16443 with a `The connection to the server :16443 was refused - did you specify the right port...` and then afterwards would work fine. `kubectl logs` would say something something about the kubelet listening on port 10250 not responding... The usual troubleshooting led down various blind alleys but the only common factor was that `microk8s inspect` would suddenly make the node work again. This led me to this post: <https://discuss.kubernetes.io/t/microk8s-broken-after-reboot-but-microk8s-inspect-fixes-it-every-time-how/28748> and lo and behold, the symptom and fix was precisely the same.

So for the avoidance of doubt; if you are in a situation where `microk8s inspect` makes your node start working after a reboot then do as the post suggests and enable nf_conntrack. I did this, and added it to `/etc/modules` after doing some more reading around it (eventually <https://github.com/canonical/microk8s/issues/4449#issuecomment-2360606044>). Or just enable tracking of connections in the kernel; it makes sense now I think about it.

```bash
sudo modprobe nf_conntrack && grep -qxF 'nf_conntrack' /etc/modules || echo 'nf_conntrack' | sudo tee -a /etc/modules
```

Why this isn't a dependency of the snap or in fact enforced by the microk8s wrapper I don't know. I didn't explicitly enable it in 22.04 either, and that was running microk8s 1.31/stable quite happily though a couple of reboots. I'm never getting those hours back again but at least I haven't violated my 3 sixes SLA.
