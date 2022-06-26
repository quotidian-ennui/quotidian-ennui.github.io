---
layout: post
title: "Network issues with Ubuntu 22.04 on a Mac Mini"
comments: false
tags: [tech, ubuntu]
categories: [tech, ubuntu]
published: true
description: "Obscure 13 year old bugs and regressions"
keywords: ""
excerpt_separator: <!-- more -->
---

You know what they they say, you can always run Linux on your old hardware. I have a Mac Mini, more specifically a `Apple Inc. Macmini7,1/Mac` c. 2015/2016 whose usefulness is now at an end. It's worth pointing out here that I don't think this particular Mac was actually ever any good as a long term piece of kit; soldered RAM and having to break out my torx screw driver set never equates to fun times in my book. Still, it should be fine with Linux running on it, being a spare Kubernetes node in my homelab...

<!-- more -->

Ubuntu installs without a problem on the machine itself, but I immediately began noticing some weird behaviours once it had joined my K8S cluster. Intermittently it would report as _NotReady_ and things would migrate to other nodes in the cluster; after about 5 minutes it would re-appear again as being _Ready_. A not entirely satisfactory state of affairs in my book; I'm not running production workloads that are terribly edgy so I wasn't expecting this kind of nonsense from it.

I initally went through a spate of thinking that it was the power-save features being enabled by Ubuntu by default but even after turning off all the ACPI features it was still happening. Things going to sleep when you think you've told them not to is something that happens more than you think when you build a homelab out of discarded laptops and other bits and pieces. It was no longer obvious so I turned to `dmesg` to figure out if there was anything obviously wrong. I'm not an expert but one of the things I do know is that it helpfully has a `---[ cut here ]---` where it thinks there might be something you want to see, so that's exactly what I looked for.

It turns out that the message that helped me the most was near that : `tg3 ... enp1s0f0: transmit timed out, resetting` which coincided with the start of the perceived network failure; then a big bunch of hexdump data (only interesting as a last resort), and some more possibly more interesting things; I'm vaguely aware that tg3 is the network module for Broadcom cards. The search term `tg3 transmit timed out, resetting` led me to [this kernel issue report](https://bugzilla.kernel.org/show_bug.cgi?id=12877) which was first reported 2009, and is still open in 2022. The long and the short of it is the Broadcom BCM57766 network card with which the Mac Mini is fitted isn't playing nicely with the Linux kernel. It played nicely for a while, but now isn't (read the bug report).

The work-around is to turn off IOMMU which, as I understand it, means you can't bind any of the hardware directly to virtual machines running on the host. I've never needed that feature, so that's what we're going to do because life is too short.

```bash
sudo su -
echo 'GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX amd_iommu=off intel_iommu=off"' >  /etc/default/grub.d/disable_iommu.cfg
update-grub
reboot
```

The result is that I have a spare node in my MicroK8S cluster; the network issues haven't come back over the last few days and it's been stable enough that I might start trusting it.
