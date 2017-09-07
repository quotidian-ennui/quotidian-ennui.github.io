---
layout: post
title: "Dangling my toes in Hyper-V; come on in"
date: 2011-08-05 11:46
published: true
comments: false
categories: tech hyper-v
tags: [tech, hyper-v]
description: "Rebuilding integration services on Centos 5 for a kernel that isn't running"
keywords: "hyper-v, centos, linux"

---

A quick update this week; I updated the kernel on one of my CentOS 5.6 images and rebooted; it wouldn't boot as it couldn't find any LVM volumes. At least you can always reboot into a previous kernel.

If I'm being honest, just blithely running yum -y update, reboot was a trifle silly. Still, if you can't do that with virtual machines when can you do it (that's what snapshots are for). The affected machine itself doesn't really do much other than run a couple of JMS Brokers/MySQL/Postfix/IMAP/FTP/SSH so my unit tests have things to work against (my life is more interesting that this, honest).

<!-- more -->

So, MSDN is my friend because the answers are all on their forums. The problem is quite specifically that the makefile provided by the Microsoft team assumes that you want to enable the integration services for the current running kernel. There are a couple of solutions I found on the web.

Firstly, disable the integration services, reboot into the new kernel, recompile the integration components, and everything will be magically up again. That's boring, and rebooting is quite a Microsofty thing to do; never liked it, never will. The second option was far more prosaic; just edit the Makefile and where it calls uname -r; make it always return the kernel release that you want to build and install into. Still because you're effectively installing a new kernel, you'll want to reboot again; just can't get away  from it can you.

GNU/Linux being what it is, you can spoof the kernel release by making sure an equivalent script 'uname' is on the PATH first; here's a script that spoofs the kernel release (there are infinitely better ways to do this; this is just one); I just put it in a directory called fake_uname

{% highlight bash %}
#/bin/bash
# This is just to query the RPM database and find out the latest kernel.
# It makes use of the fact that rpm -q kernel seems to put the "latest" version 
# at the bottom of the output. That might not be reliable so YMMV
function show_latest_kernel
{
  declare -a installed_kernels=(`rpm -q kernel`)
  last=`echo ${#installed_kernels[@]}`
  latest_kernel=`echo ${installed_kernels[$last-1]}`
  echo ${latest_kernel#kernel-}
}

case $1 in
    -r)
        show_latest_kernel
        ;;
    *)
        exec /bin/uname $1
        ;;
esac
{% endhighlight %}

After that it's just a case of

{% highlight bash %}
export PATH=./fake_uname:$PATH
make
make install
{% endhighlight %}

Voila, we have enabled the Hyper-V Linux integration services 2.1 for a kernel that isn't currently running; just don't forget to delete the backup images in /boot once you're happy things are working.

Note: If you're using CentOS 6 / RHEL 6, then you'll be using the Linux Integration Services 3.1 which is an RPM install rather than a source recompile.

