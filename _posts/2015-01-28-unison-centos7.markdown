---
layout: post
title: "Unison on Centos 7"
date: 2015-01-28 13:00
comments: false
categories:  tech linux
tags: [tech, linux]
published: true
description: "Why isn't Unison in the EPEL repository for CentOS 7"
keywords: "linux, centos, unison"
header-img: img/banner_field.jpg
---

I generally use [unison][] to keep my work environment on various machines in sync. I use it like a poor man's Dropbox in effect; call me old fashioned but I don't tend to use any cloud storage provider for security reasons. Unison means that it is trivial for me to move between my main development environment and other platforms, but as a project it appears to be unloved. I've recently installed a couple of instances of CentOS 7 in my test lab, and unison isn't provided; it's not in in the epel repository either.

<!-- more -->

Compiling unison from scratch is quite simple, install the latest version of ocaml, and then just run ``make`` having downloaded the source distribution for unison;  which is exactly what I did. However, initial attempts to synchronize always failed.

{% highlight text %}
Dumping archives to ~/unison.dump on both hosts
Finished dumping archives
Fatal error: Internal error: New archives are not identical.
Retaining original archives.  Please run Unison again to bring them up to date.
{% endhighlight %}


If you are using the [pre-compiled Windows binaries][windows-unison] then you're at 2.40.x which uses ocaml 3.12; the latest version of ocaml is 4.x (which is what you get when you ``yum install ocaml`` on CentOS 7) and they tend to give different results depending on what you're doing (the why isn't important, life is too short). What you need to do is to download ocaml 3.12 from source and install it.

{% highlight console %}
./configure
make world.opt
make install
{% endhighlight %}

After that, rebuild unison once again.

[unison]: http://www.cis.upenn.edu/~bcpierce/unison/
[windows-unison]: http://alan.petitepomme.net/unison/index.html
