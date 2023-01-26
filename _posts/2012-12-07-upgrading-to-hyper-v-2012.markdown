---
layout: post
title: "Upgrading to Hyper-V 2012"
date: 2012-12-07 17:00
comments: false
#categories: [tech, hyper-v]
tags: [tech, hyper-v]
published: true
description: "Upgrading from Hyper-V 2008 to Hyper-V 2012"
keywords: "hyper-v"

---

Hyper-V 2012 has been out for a while now; I finally took the plunge and upgraded my lab infrastructure at home[^1]. Given that all my test containers are virtualised in Hyper-V 2008 already; it should just be a case of moving the images around to free up a host machine so that the hosts can be upgraded in sequence. Ultimately it was painless, but time consuming; a large part of it was copying gigabytes of data around my network.

<!-- more -->

I've been quite happy managing my Hyper-V instances using the Windows 7 Hyper-V manager via RSAT (after some [jiggery pokery]({{ site.baseurl }}/blog/2011/07/22/adventures-in-hyper-v/)); my main development machine is Windows 7 and after some research on the web, it appears that you can't manage Hyper-V 2012 instances via the tools available to Windows 7. So all in all it's just easier to install Windows Server 2012 with Hyper-V role enabled on a host machine. I admit that I was lazy and installed the GUI, rather than just going for Server Core. The other machines are installed with the Hyper-V 2012 ISO download.

I'm still not running a domain, all the core network services like DNS/DHCP are running on a virtualised CentOS image. Trying to manage the other Hyper-V instances from the Server 2012 instance won't work until you do `winrm set winrm/config/client @{TrustedHosts="RemoteComputerA,RemoteComputerB"}` on the server (use the fully qualified domain name) which adds all the remote machines as a TrustedHost.

After installation of the first Hyper-V 2012; the existing machines were exported, and re-imported (I did isolate them from the rest of the network) and started them up; in the end there were only a couple of issues.

* My CentOS 5 machines had issues relating to the version of Hyper-V Linux integration components that I was using. They were all running IC 2.1 (which requires you to compile it).
    * They probably needed to be using IC 3.4. I didn't try to resolve this; I just rebuilt them using my kickstart scripts (they are test machines after all, and prone to be being rebuilt every so often).
    * The Hyper-V manager still says that all my linux machines have a network-status of *degraded*, and I should install the latest integration services (Linux IC 3.4 is the latest right now!) - this is a bit annoying as you're reminded of that in the server dashboard as well.
* My Windows 2003 instance doesn't seem to work with the latest integration services from Hyper-V 2012 so that's been left running the older integration services.
    * The Hyper-V Guest Shutdown server doesn't start; the error was *procedure entry point vmbuspipeserverresume missing in dynamic link library vmbuspipe.dll* (I executed _vmicsvc -feature Shutdown_ manually from the commandline)
    * I tried a couple of things: uninstall/re-install (same error), copying over the vmbuspipe.dll from the 2012 instance (invalid dll). In the end the only visible consequence is the same complaint in the Hyper-V Manager: *degraded*.

I also took the chance to virtualise one of my desktop machines; it's been around for a while and is stuffed full to the gills with disks. We don't really use the desktop other than to run Microsoft Money and having all that power for something that's so low-rent seems a bit silly; I used [disk2vhd](http://technet.microsoft.com/en-gb/sysinternals/ee656415.aspx) to convert the system disk into a VHD; and then created a VM in Hyper-V that is attached to the VHD. The hardware detection does it's thing and after a couple of reboots everything is back (albeit missing a few disks). A note of caution, I converted my system disk from a _dynamic_ disk to a _basic_ disk beforehand (I followed option 2 at [SevenForums](http://www.sevenforums.com/tutorials/26829-convert-dynamic-disk-basic-disk.html)) as the VHD created from my dynamic disk wouldn't mount in the Windows 2012, which I took as a bad sign; it would have been a basic disk originally, but I had been playing with software raid and other such things a while ago.

[^1]: I have inherited a bunch of _broken_ laptops; it's over-egging it to call it a _lab_


