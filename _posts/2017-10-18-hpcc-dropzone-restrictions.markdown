---
layout: post
title: "HPCC: dfuplus fails to spray files"
date: 2017-10-18 13:00
comments: false
tags: [tech, hyper-v]
categories: [tech, hyper-v]
published: true
description: ""
keywords: "hyper-v, hpcc, dfuplus"
excerpt_separator: <!-- more -->
---

Just upgraded my local HPCC virtual machine instance to HPCC 6.4.2 + Hyper-V. This time I converted the image using [qemu-img](https://cloudbase.it/qemu-img-windows/). Sadly though I couldn't use dfuplus to spray files in. It complains about `Failed: No Drop Zone on 'xxx' configured at '/path/to/file'`. I had to do a lot of digging to get to the solution; basically you just need to edit `/etc/HPCCSystems/environment.conf` and change _useDropZoneRestrictions_ to false; afterwards, restart all the hpcc services. Sadly their documentation is quite lacking on this new feature; I'm sure there are great reasons for it, but for me, backwards compatibility rules should have meant that it defaulted to false, not true.

