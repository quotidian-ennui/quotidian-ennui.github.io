---
layout: post
title: "VMPlayer network interfaces with Private/Public Networking"
date: 2011-08-19 08:58
published: true
comments: false
#categories: [tech, vmware]
tags: [tech, vmware]
description: "Making VMPlayer Network interfaces part of the private network"
keywords: "vmware, windows7"

---

One of the things that you'll find with VMPlayer is that the network interfaces aren't registered properly with Windows (Vista or 7) which means that you're always in the Public zone, so your firewall is always turned on (that's right, you have a firewall don't you).

<!-- more -->

Of course that means that your running VM can't talk to any services on your host machine. After all you might want your VM to talk to the database server running on your host machine. If you had Windows Ultimate or Enterprise, then you could change the firewall rules on a port by port/public/private/domain basis, but those of you limping along with the home premium or lower editions don't get much choice in the matter.

Well, after a registry hack, the networking interfaces won't affect your public/private networking status.

You'll need regedit of course, browse to

```text
HKEY_LOCAL_MACHINE/SYSTEM/ControlSet001/Control/Class/{4D36E972-E325-11CE-BFC1-08002BE10318}
```

At this point you'll see a list of 0000 to nnnn keys; go through each of them until you find the ones that say *\DosDevices\VMnet8* and *\DosDevices\VMnet1*. The names will depend on your environment and what devices you want to change, but I think they're generally going to be VMnet8 and VMnet1

Add a DWORD value with the name _*NdisDeviceType_ (yes, include the *) and make the value 1. Disable/ Enable the network interfaces, and hey presto, when you click on the network icon in your taskbar it won't have a park bench on it.
