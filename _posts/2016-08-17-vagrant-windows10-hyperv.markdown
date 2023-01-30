---
layout: post
title: "Vagrant + Hyper-V (Windows 10 anniversary)"
date: 2016-08-17 17:00
comments: false
#categories: [tech, hyper-v]
tags: [tech, hyper-v]
published: true
description: "Making Vagrant play nicely with Hyper-V; that can be a bit of a ballache"
keywords: "hyper-v, vagrant, linux"
header-img: img/banner_broken-plane-2.jpg
excerpt_separator: <!-- more -->
---

Well, my personal laptop has been upgraded to Windows 10 Anniversary; it's a dual SSD + HD affair, an Asus NX501-JW which hasn't been affected by the other "SSD+HD" bricking issues that have been in the tech news. Anyway, either I, or Microsoft during the upgrade, uninstalled Virtualbox, which I had been using to run an [HPCC Systems][] environment amongst other things. In the end, the chance to run Docker natively, and Linux shell natively via Hyper-V persuaded me that I should try and get [Vagrant][] to play nice to Hyper-V; this then is an afternoon of fun and games.

<!-- more -->

VirtualBox has long been the default provider for Vagrant and if you search for boxes on [Atlas][], they're the ones that are most popular. Hyper-V is supported, but there aren't as many boxes around. This then is a distilled how-to for getting a box up and running with NAT on Hyper-V. For brevity, I've just distilled the raw commands with no explanation as to why I'm doing things as I've done them; they just worked for me.

## Create a NAT switch

Once you have the Hyper-V role enabled; then you need to add a virtual switch, so use powershell to do that (run as Administrator naturally) rather than the Hyper-V manager UI.

```powershell

New-VMSwitch –SwitchName "NATSwitch" –SwitchType Internal
New-NetIPAddress –IPAddress 172.21.21.1 -PrefixLength 24 -InterfaceAlias "vEthernet (NATSwitch)"
New-NetNat –Name MyNATnetwork –InternalIPInterfaceAddressPrefix 172.21.21.0/24

```

It does some stuff, but eventually you have a switch that is NAT enabled, and your IP Address is 172.21.21.1 for the network card associated with the switch. The source was [http://www.thomasmaurer.ch/2016/05/set-up-a-hyper-v-virtual-switch-using-a-nat-network/](http://www.thomasmaurer.ch/2016/05/set-up-a-hyper-v-virtual-switch-using-a-nat-network/).

## Vagrant UP and Down

Our production machines are all CentOS or variants of, so I like to stick with what I know. There aren't that many CentOS 7 boxes available, so I used `serveit/centos-7` which works well enough.

```text

Vagrant.configure(2) do |config|
  config.vm.box = "serveit/centos-7"
  config.vm.provider "hyperv"

  config.vm.network "private_network", ip: "172.21.12.10", auto_config: false

  config.vm.synced_folder ".", "/home/vagrant/sync"
  config.vm.provider "hyperv" do |vb|
      vb.memory = "2048"
      vb.cpus = "2"
      vb.vmname = "HyperV-Vagrant-CentOS-7"
  end
end

```

Once you run `vagrant up`, it's up, and you can `vagrant ssh` to it; but it may well have defaulted to IPV6; which probably isn't all the useful for you.

```text
    default: IP: fe80::215:5dff:fe48:5307
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: fe80::215:5dff:fe48:5307:22
    default: SSH username: vagrant
    default: SSH auth method: private key
    default:
    default: Vagrant insecure key detected. Vagrant will automatically replace
    default: this with a newly generated keypair for better security.
    default:
    default: Inserting generated public key within guest...
    default: Removing insecure key from the guest if it's present...
    default: Key inserted! Disconnecting and reconnecting using new SSH key...
==> default: Machine booted and ready!
==> default: Preparing SMB shared folders...
    default: You will be asked for the username and password to use for the SMB
    default: folders shortly. Please use the proper username/password of your
    default: Windows account.
    default:
    default: Username:
    default: Password (will be hidden):
==> default: Mounting SMB shared folders...
We couldn't detect an IP address that was routable to this
machine from the guest machine! Please verify networking is properly
setup in the guest machine and that it is able to access this
host.

As another option, you can manually specify an IP for the machine
to mount from using the `smb_host` option to the synced folder.

```


### Fiddling the network card.

So, now we need to fix up the network card (easy enough to do) with a fixed IP Address.

```text

[root@centos7 ~]# cat /etc/sysconfig/network-scripts/ifcfg-eth0
TYPE=Ethernet
BOOTPROTO=static
ONBOOT="yes"
IPADDR=172.21.21.10
NETMASK=255.255.255.0
GATEWAY=172.21.21.1
DNS1=8.8.8.8
[root@centos7 ~]#

```

After that, a `vagrant halt` followed by a `vagrant` up will fix up the IP addresses nicely.


## Huh, can't mount my shared folders

If you're using the `serveit/centos-7` image then it may fail to mount whatever shared folders you've specified with some error or other. To cut a long story short, because it's a minimal image, it doesn't come with cifs-utils; Get that via yum (because you have NAT right) and you'll be able to mount whatever shares you need in your vagrant file, and voila you have a provisioned CentOS-7 machine.

```text
Bringing machine 'default' up with 'hyperv' provider...
==> default: Verifying Hyper-V is enabled...
==> default: Starting the machine...
==> default: Waiting for the machine to report its IP address...
    default: Timeout: 120 seconds
    default: IP: 172.21.21.10
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 172.21.21.10:22
    default: SSH username: vagrant
    default: SSH auth method: private key
==> default: Machine booted and ready!
==> default: Preparing SMB shared folders...
    default: You will be asked for the username and password to use for the SMB
    default: folders shortly. Please use the proper username/password of your
    default: Windows account.
    default:
    default: Username: myusername
    default: Password (will be hidden):
==> default: Mounting SMB shared folders...
    default: C:/Users/lchan/work => /home/vagrant/work
    default: C:/Users/lchan/.m2 => /home/vagrant/.m2
    default: C:/Users/lchan/.ivy2 => /home/vagrant/.ivy2
    default: C:/Users/lchan/.ant => /home/vagrant/.ant
==> default: Machine already provisioned. Run `vagrant provision` or use the `--provision`
==> default: flag to force provisioning. Provisioners marked to run always will still run.
```


[HPCC Systems]: http://www.hpccsystems.com
[Vagrant]: http://www.vagrantup.com
[Atlas]: http://atlas.hashicorp.com/boxes/search



