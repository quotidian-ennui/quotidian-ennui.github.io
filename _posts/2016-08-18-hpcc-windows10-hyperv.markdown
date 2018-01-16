---
layout: post
date: 2016-08-18 11:00
comments: false
tags: [tech, hyper-v]
categories: [tech, hyper-v]
published: true
title: "Virtualbox isn't the only tool in the box"
description: "Running HPCC systems Virtualbox image under Hyper-V"
keywords: "hyper-v, hpcc, ubuntu"
header-img: img/banner-knives.jpg
---

Now that I don't have VirtualBox installed, I have to migrate my [HPCC Systems][] environment into Hyper-V; this was a brief flurry of amusement, but in the end I have a HPCC system running under Hyper-V with minimal fuss. Along the way I have discovered something new about the virtual box environment that [HPCC Systems][] makes available for download.

<!-- more -->

Previously, you'll have created a NAT switch in Hyper-V; now would be a good time to install a quick and dirty DHCP server; you could opt for [http://www.dhcpserver.de](http://www.dhcpserver.de) which works with minimal fuss. Remember to bind it to only the network cards you want to assign it to. Download a new fresh version of the OVA file, and open it up using your preferred archiver and grab the `box-disk1.vmdk` out of there. If you wish to port an already existing VMDK file (because you've done some prototyping in ECL or whatnot); then you will need to make sure that the assigned IP address that the new virtual machine gets is the same as what was assigned by VirtualBox (it just saves extra configuration work later).

## Convert VMDK to VHD

I used `vboxmanage` to do this; I still have VirtualBox installed elsewhere in my environment. If you haven't then there are plenty of other tools out there. You don't need to remove the VirtualBox guest tools; the image has both virtualbox tools and vmware tools installed, and they're clever enough to not start in a Hyper-V environment.

{% highlight text %}

vboxmanage clonehd .\box-disk1.vmdk .\hpcc-6.0.4.vhd -format VHD

{% endhighlight %}

Alternatively if you don't have virtual box installed anywhere then you could use [https://cloudbase.it/qemu-img-windows/](https://cloudbase.it/qemu-img-windows/)

{% highlight text %}

qemu-img.exe convert .\box-disk1.vmdk -O vhdx .\hpcc-6.0.4.vhd

{% endhighlight %}

I personally didn't have much luck with the [Microsoft VMWare Machine Converter](https://www.microsoft.com/en-us/download/details.aspx?id=42497) as it complained about disk database entry descriptor; but YMMV.

{% highlight text %}

Import-Module 'C:\Program Files\Microsoft Virtual Machine Converter\MvmcCmdlet.psd1'
ConvertTo-MvmcVirtualHardDisk -SourceLiteralPath ".\box-disk1.vmdk" -VhdType DynamicHardDisk -VhdFormat vhdx -DestinationLiteralPath ".\hpcc-6.4.2.vhdx"

{% endhighlight %}

## Create the Hyper-V virtual machine

Create the virtual machine in Hyper-V; binding it to the disk that you've just migrated. The virtal machine details are pretty simple; you'll need to add 2 standard network cards, the second one needs to be bound to the `NAT network` where your new dhcp server is running. You can remove the legacy network cards and/or DVD drives as you wish.

![hyper-v-settings]({{ blog_baseurl }}/images/posts/hpcc-hyperv.png)


After that; start it up and you're good to go.


[HPCC Systems]: http://www.hpccsystems.com
[VirtualBox]: http://www.virtualbox.org



