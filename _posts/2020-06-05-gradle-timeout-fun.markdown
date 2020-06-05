---
layout: post
title: "Gradle timeout fun"
comments: false
tags: [development,java]
categories: [development,java]
published: true
description: "Corporate transparent proxies are always fun"
keywords: ""
excerpt_separator: <!-- more -->
---

Since the whole work from home thing has started; there have been a couple of changes that I've noticed. First of all: I used to be able to use Teams on my personal hardware; but now I can't because they're not managed by the company. This has had the sad side effect of forcing me to consistently use my corporate laptop because I can't use my personal hardware with Teams; sure I can use the web based version of teams, but Edge/Chrome on Windows can't seem to use my bluetooth headset properly (it works fine with the skype windows app) which I suspect is because the context switch from _high def sound_ to _low-def sound so we have the bandwidth to use both speaker + mic_ is what's confusing the browser (web skype test call takes ages to funnel sound to the headset).

This post isn't about the that, it's about gradle which I have some control over. What I've noticed is that intermittently my gradle builds fail with _Read timed out_ issues; this made me think that our external facing artefact repo was having issues, until I realised that it absolutely never happened when I wasn't on the Mac.

<!-- more -->

The symptom manifests itself like this, interestingly, it rarely manifests itself using ant+ivy, but relatively consistently with gradle.

```
> Could not resolve all files for configuration ':interlokRuntime'.
   > Could not resolve com.adaptris:interlok-client-jmx:3.10-SNAPSHOT.
     Required by:
         project : > com.adaptris:interlok-workflow-rest-services:3.10-SNAPSHOT:20200604.133604-382
      > Could not resolve com.adaptris:interlok-client-jmx:3.10-SNAPSHOT.
         > Could not get resource 'https://nexus.adaptris.net/nexus/content/groups/public/com/adaptris/interlok-client-jmx/3.10-SNAPSHOT/interlok-client-jmx-3.10-SNAPSHOT.pom'.
            > Could not GET 'https://nexus.adaptris.net/nexus/content/groups/public/com/adaptris/interlok-client-jmx/3.10-SNAPSHOT/interlok-client-jmx-3.10-SNAPSHOT.pom'.
               > Read timed out
```

My corporate Mac has to be on the VPN to access teams/outlook (this might not be true now, behaviour changed slightly this week) which means I'm on the VPN, and I'm subject to the whims of the transparent proxy that's in place for monitoring/my own good. What I think is happening is

* Gradle makes a HTTP request to check a POM/jar file whatever, maven-metadata.xml seems to be quite popular for failures
* The proxy realises that this file isn't in its "cache"
* It queues it up to go and get the file, but doesn't tell gradle in any fashion
* gradle gets bored of waiting for the first byte, and raises the "read timed out" exception.

The easy answer then is to just increase the timeouts in gradle.

```
$ cat ~/.gradle/gradle.properties
# Set the socket timeout to 5 minutes (good for proxies)
systemProp.org.gradle.internal.http.socketTimeout=300000
 # the number of retries (initial included) (default 3)
systemProp.org.gradle.internal.repository.max.retries=10
 # the initial time before retrying, in milliseconds (default 125)
systemProp.org.gradle.internal.repository.initial.backoff=500
```

Since gradle will naturally try to use all the cores as its `--max-workers` setting; there may also be eventually some rate-limiting that's killing everyone, since of course, the transparent proxy means that everyone on the VPN will probably present as the same external IP address; so I might end up having to do `gradle --max-workers=1 clean test` so slow down my builds even more; _but that might just help the AV keep up_.

There's other odd behaviours that happen that I suspect are proxy/networking related. I have a "git-mirror" script that updates/mirrors all the repos that I actively work on. The script will "fail" if I'm on the VPN, and I don't stick a `sleep 5` in the script for loop; it probably doesn't have to be 5 seconds, but a sleep is required, because otherwise I get the same kind of errors from executing `git pull` quickly in succession.