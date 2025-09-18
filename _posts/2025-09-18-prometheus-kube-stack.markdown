---
layout: post
title: "Prometheus Kube Stack upgrades"
comments: false
tags: [kubernetes, rant]
# categories: [development,rant]
published: true
description: "The principle of least surprise is a thing, but not for prometheus-community"
keywords: ""
excerpt_separator: <!-- more -->
---

It's fascinating to subscribe and use open source community releases. If you're not a hard-core user, more of a dabbling amateur then you don't know the ins and outs of the product. That leaves you at a slight disadvantage when upgrades come around. This was certainly the case when I upgraded my `kube-prometheus-stack` from 76.4.x to 77.x. All my existing Grafana dashboards lovingly curated by me had disappeared!

<!-- more -->

Now, I'm going to go on record and say I don't _actually care that much about the ins and outs of prometheus and grafana_. I use it, but that's just about the long and the short of it; I'm a semi-literate technical user who's able to get into trouble.

The symptom of the upgrade was that all my dashboards had disappeared. Grafana is installed without persistence in my K8S homelab, and discovery is via the classic `grafana_dashboards: "1"` label. All the dashboards were being upgraded (because I haven't disabled the default dashboards) but none of them were showing up when I connected to grafana.

The things I've noticed about the release notes from the helm charts are

- They are impenetrable
- You have to spend a lot of time figuring out exactly what has changed
- They often violate the principle of least surprise without warning
- This was a major upgrade (so they got that right) with operators going from 0.84.1 to 0.85

This is their right of course, they're open-source and I'm getting it for free; but with this upgrade it boils down to this log statement from the sidecar that is started as part of the grafana deployment (this is the sidecar that discovers all the dashboards and config maps in kubernetes)

```console
 "Retrying (Retry(total=0, connect=10, read=5, redirect=None, status=None)) after connection broken by
     ''SSLError(SSLCertVerificationError(1, '[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed:
     CA cert does not include key usage extension (_ssl.c:1032)'))': /api/v1/secrets?labelSelector=grafa...
 "MaxRetryError when calling kubernetes: HTTPSConnectionPool(host='x.x.x.x', port=443): Max retries exceeded with url: /api/v1/conf...
 "MaxRetryError when calling kubernetes: HTTPSConnectionPool(host='x.x.x.x', port=443): Max retries exceeded with url: /api/v1/secr...```
```

Yay! - yet another TLS certificate problem (this is a semi-hard constant in my working life).

The right answer is to fix the certificate but the most pragmatic answer is to disable TLS verification in the sidecar, but it is not obvious how to do that, since there are no explicit values that control TLS for the sidecar in the default chart values. This means I have to go digging into the actual charts. The long and the short of it is to do this in your helm values override.

```yaml
grafana:
  enabled: true
  sidecar:
    skipTlsVerify: true
```

Which then ends up with a sidecar deployment (for `grafana-sc-datasources` and `grafana-sc-dashboards`) which is bang-on the right thing to have.

```yaml
   - name: grafana-sc-datasources
     image: "quay.io/kiwigrid/k8s-sidecar:1.30.10"
     imagePullPolicy: IfNotPresent
     env:
      ...
      - name: SKIP_TLS_VERIFY
        value: "true"
```

Helm is great until it's not great; at which point, you _have to know all there is to know about the thing you're trying to install via helm_ and then some extra things about helm templating. At this point, I may as well use terraform with explicitly defined kubernetes resources, because doing the above would have been _absolutely piss easy_; and in fact fulfils the same boundary conditions (I know terraform, and now I know more than I want about prometheus).

That's a hour that I'm never getting back; still listening to Mozart's "Coronation Mass" is never wasted time.
