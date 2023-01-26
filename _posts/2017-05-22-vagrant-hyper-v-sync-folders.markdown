---
layout: post
title: "Vagrant + Hyper-V sync folders"
date: 2017-05-22 17:00
comments: false
#categories: [tech, hyper-v]
tags: [tech, hyper-v]
published: true
description: "Issues mounting local folders in vagrant"
keywords: "hyper-v, vagrant, linux"
header-img: img/banner_broken-plane-2.jpg
---

One of the things that [Vagrant][] (in Hyper-V mode) does if you sync folders with your linux machine is to attempt to mount them via SMB. This can lead to a few problems; you can work through them, but it's always easier to cut and paste from someone else's pain right?

## Multiple IP Addresses

If you have two Hyper-V network interfaces installed; then vagrant might have a bit of trouble working out which one is the correct one to attempt to connect to via cifs. This is often the case if you also have [Docker for Windows][] installed in Windows 10. Vagrant eventually complains about not being able to mount any of your sync folders and helpfully outputs the command it was trying to execute. Check that the IP Address is the correct one; if it isn't then you need to change your `Vagrantfile` so that you specify the `smb_host`

```text

  config.vm.synced_folder ".", "/home/vagrant/sync", type:"smb", smb_host:"172.21.21.1"

```

## Public/Private networking

Similar to the problem with VMWare network interfaces, your Hyper-V switch is probably in the _Unidentified network_ which means that your firewall is likely to be in play blocking traffic. Search for your switch using regedit; it'll be one (or two) of the keys under the key `HKEY_LOCAL_MACHINE/SYSTEM/ControlSet001/Control/Class/{4D36E972-E325-11CE-BFC1-08002BE10318}`. Add a DWORD value to the numbered directory (e.g. `HKEY_LOCAL_MACHINE/SYSTEM/ControlSet001/Control/Class/{4D36E972-E325-11CE-BFC1-08002BE10318}/0007`) with the name _*NdisDeviceType_ (yes, include the *) and make the value 1. Disable/ Enable the network interface.

## SMBv1

Well, what with Wannacrypt and all of that monkey business; you may have disabled the SMBv1 Protocol. Great idea, but you'll have to mount the drives now using a specific SMB version...

```text

  config.vm.synced_folder ".", "/home/vagrant/sync", type:"smb", smb_host:"172.21.21.1", mount_options: ["vers=2.1"]

```

## Deleting "old" shares

Each time you attempt to mount the drives a new share is created. Each shares are named a random 32 character string (I'm sure it means something, life is sometimes a bit too short). These shares can persist which can be a little annoying. What we want to do is to delete them periodically; this is quite easy, as you're probably already using an admin powershell to run vagrant (well you have to have admin, and who uses cmd.exe anyway?), so this is a simple case of using (I called the script __vagrant-smb-cleanup.ps1__) a couple of powershell commands to delete shares you don't want anymore (make sure the vagrant machine is halted first).

```powershell

$shares=net view . | select-string "[\w]{32}" -AllMatches
$shares | forEach-Object { net share $_.toString().split(" ")[0] /delete }

```

Or; if you have Ubuntu installed natively via WSL, then you can do `bash vagrant-smb-cleanup.sh` from your admin command prompt. That script will contain the same thing, but for bash...

```bash

#!/bin/bash

NET_EXE="/mnt/c/Windows/System32/net.exe"
shares=`$NET_EXE view . | grep -P -e "[\\w]{32}" | cut -d' ' -f 1`

for share in $shares
do
  $NET_EXE share $share /DELETE
done

```


[Vagrant]: http://www.vagrantup.com
[Docker for Windows]: https://store.docker.com/editions/community/docker-ce-desktop-windows



