---
layout: post
title: "HPCC 6.4.2: dfuplus fails to spray files"
date: 2017-10-18 13:00
comments: false
tags: [tech, hyper-v]
categories: [tech, hyper-v]
published: true
description: ""
keywords: "hyper-v, hpcc, dfuplus"
excerpt_separator: <!-- more -->
---

We're in the middle of doing an upgrade of our systest HPCC instances to 6.4.2 so I thought it would be a good time to upgrade my local HPCC virtual machine instance to HPCC 6.4.2 + Hyper-V. This time I converted the image using [qemu-img](https://cloudbase.it/qemu-img-windows/). Sadly though I couldn't use dfuplus to spray files in. It complains about `Failed: No Drop Zone on 'xxx' configured at '/path/to/file'`. When I tried to despray files using dfuplus you get a different message `Dropzone not found for network address x.x.x.x.`.

<!-- more -->

I had to do a lot of digging to get to the solution; basically you just need to edit `/etc/HPCCSystems/environment.conf` and change _useDropZoneRestrictions_ to false; afterwards, restart all the hpcc services. Sadly their documentation is quite lacking on this new feature; I'm sure there are great reasons for it, but for me, backwards compatibility rules should have meant that it defaulted to false, not true.

However making despray is not such an easy thing. It seems the only way that it would work was if I explicitly configured my local laptop as a drop zone.

* Start up the configmgr instance on the box.
* Add a new dropzone, with the path that matches where you're going to despray stuff to (if you're brave; use `C:\`; I'm not brave) 
* Add a server to the serverlist associated with that drop zone that has your laptop's IP Address (e.g. 172.21.21.1)
* Restart according to the configmgr manual

The directory you've specified on your laptop will now show up in ECL Watch -> Landing zones if you have an instance of `dfuplus action=dafilesrv` already running... And if you've been super-brave, think about all the things you could do now... I'm not sure this is what was intended. After a bit of disucssion internally, it appears that there are some issues with dropzone restrictions in 6.4; so the long and the short of it is I suggest you either fallback to 6.2.22 or wait for 6.4.4.

