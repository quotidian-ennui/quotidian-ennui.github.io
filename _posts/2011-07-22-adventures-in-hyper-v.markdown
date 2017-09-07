---
layout: post
title: "Adventures in Hyper-V"
date: 2011-07-22 08:52
comments: false
published: true
categories: tech hyper-v
tags: [tech, hyper-v]
description: "Connecting to a remote hyper-v server without a domain"
keywords: "hyper-v"

---

I've always been a fan of virtualising my development environment; nothing quite like carrying around a 220Gb disk image of Windows 2003 + SAP R/3 and writing a new SAP connector when you're on the road. Recently though, I've been getting less than stellar performance from vmplayer / vmserver; so I wanted to switch to a Type 1 hypervisor…

As it happens, due to various reasons (I say various, but I mean one reason) I have inherited a couple of laptops, all with broken screens; other than the broken screens they're perfectly servicable, and yet not worth refurbishing. They're both Core 2 Duo (T7250 or better)with 4 GB RAM and 250Gb hard drives; which should be  more than adequate to run a Type-1 hypervisor; they have Intel-VT and all that. I'm trying to find out if I could install ESXi onto these laptops; shall we just say that there's a dearth of information on the VMWare site about compatibility with laptop models, so I'm left with one choice, Hyper-V from Microsoft. Why didn't I just try and install ESXi? I could have; we're in the process of virtualising all our servers using VMWare already, so obviously there's a wealth of knowledge inhouse I can tap up, but that wouldn't have been interesting.

<!-- more -->

Hyper-V Server is a free download from Microsoft; this isn't the quite same as a Server 2008 with a Hyper-V role. The Hyper-V server is basically Server Core with the Hyper-V role enabled, but you can't enable anything else.

I won't bore you with the installation process, that was pretty painless, the wired NIC was autodetected (not the wireless though, but these will be static machines, so it's not a big deal). After installing; Hyper-V Server looks like Server Core, i.e. you get a command prompt window and that's pretty much it. Terse and unfriendly unless you like to dabble with Powershell cmdlets and commandline tools. Lucky me.

You've got to enable the Microsoft Remote System Admin Tools so that you can connect to the Hyper-V instance using a remote machine. I considered installing SCVMM but I don't have a Windows 2008 server handy (I expect that's an adventure that's waiting to happen for the other broken laptop); poor planning there I would think. So, this is where the adventure starts. Microsoft being Microsoft expects a lot of things to be domain based, so authentication can happen via AD. Nope, no domain round here. Still, Google's mostly my friend, I get on great with his frenemy Bing too, and after a bit of reading; here's what you have to distilled into an easy to follow set of steps. The client machine here is a Windows 7 Ultimate (32bit), I am NOT logged in as the Administrator user and UAC is not disabled!

* (Server) Install Hyper-V
* (Client) Install Remote Administration Tools - [http://www.microsoft.com/download/en/details.aspx?id=7887][]
* (Server) Fix the server's IP Address (not strictly necessary).
* (Server) Follow the instructions on Hyper-V to enable remote management
* (Client) Enable the Hyper-V remote tools
* Download hvremote.wsf from [http://archive.msdn.microsoft.com/HVRemote/Release/ProjectReleases.aspx?ReleaseId=3084][] and make it available to both server and client - How you do that is your thing.
* (Server) add a local user that matches your username on your client machine
* (Server) `cscript hvremote.wsf /add:[user]` (where user the user from the step before)
* (Client) `cscript hvremote.wsf /anondcom:grant` (in a Administrator's command prompt).
* (Client) `cscript hvremote.wsf /mmc:enable` (in a Administrator's command prompt).
* (Client) Use Control Panel -> Credentials manager so you can connect to the Hyper-V server as the Administrator user (which you'll have setup when you installed Hyper-V)
* (Client) Start Administrative Tools -> Hyper-V Tools and connect...

Now that Hyper-V was up and running and stashed back under the stairs, I thought I'd dive right in a start using it. I installed CentOS5.6 as I knew that had support from Microsoft (you can download the Linux Integration Components) and quickly setup a DHCP/DNS/SqueezeboxServer that was now missing. That is somewhat a chicken and the egg situation, you can't use Hyper-V to provide your DHCP, I also don't like the crappy DHCP server that comes built into various routers. Fixed IP addresses all round until I got that sorted (worst of all, I had to rely on the laptop to provide the tunes, not the Denon). A quick re-import of the same image so I have something to run builds on. After that though I dived right in and converted my SAP VMDK into a VHD. This can be distilled into a few easy steps provided you have enough disk space (the vmdk disk was physically 80Gb but diskspace is pretty cheap all things considered), my original inspiration was [http://www.adopenstatic.com/cs/blogs/ken/archive/2008/03/23/16710.aspx][].

* Shutdown the VM and back up the image; you know, I might not even like Hyper-V and move back to vmserver.
* Create an IDE disk and attach it to the VM (You can do this in vmplayer). Make sure the disk is IDE not SCSI, any size (like dreams) will do.
* Boot up the VM - Check to see if the disk is "visible" - You basically need to enable the IDE interface - (i.e. Windows has found new hardware) otherwise Hyper-V won't boot from the VHD.
* Uninstall VMWare Tools and kill it.
* Shutdown the VM,
* Convert the vmdk to vhd using a VMDK to VHD converter - I used  [http://vmtoolkit.com/files/default.aspx][] That'll take time, depending on how big the disk is.
* Make the VHD available to your Hyper-V instance
* Create a Virtual Machine in Hyper-V using the VHD as the disk.
* Boot it up and install the integration services/reboot make a note of the MAC address if you need it for various things like fixing the address in DHCP; actually allowing it to attach to your network because that's how you've rolled your DHCP server, unknown MAC's get denied.
* Start SAP and login.

In summary, I now have 3 images 2x CentOS 1x Windows 2003 running under Hyper-V on a laptop; and they're getting along fine. I've even enabled dynamic memory for the Windows 2003 instance; and I'm thinking about SCVMM +clustering +live migration, who doesn't want the equivalent of vmotion running across two broken laptops.

[http://www.microsoft.com/download/en/details.aspx?id=7887]: http://www.microsoft.com/download/en/details.aspx?id=7887
[http://archive.msdn.microsoft.com/HVRemote/Release/ProjectReleases.aspx?ReleaseId=3084]: http://archive.msdn.microsoft.com/HVRemote/Release/ProjectReleases.aspx?ReleaseId=3084
[http://www.adopenstatic.com/cs/blogs/ken/archive/2008/03/23/16710.aspx]: http://www.adopenstatic.com/cs/blogs/ken/archive/2008/03/23/16710.aspx
[http://vmtoolkit.com/files/default.aspx]: http://vmtoolkit.com/files/default.aspx