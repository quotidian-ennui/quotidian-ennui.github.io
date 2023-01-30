---
layout: post
title: "Setting up CentOS-6 Just So"
date: 2012-04-05 16:00
comments: false
#categories: [tech, linux]
tags: [tech, linux]
published: true
description: "How I setup CentOS 6"
keywords: "linux, centos"
excerpt_separator: <!-- more -->
---

The infrastructure team that we have at Adaptris is great; but sometimes when they setup a new vm image for me, there's some things that are not quite right. I guess it's because I'm a very particular kind of guy when it comes to how machines are setup. I thought that I'd write about how the development machines are setup. They're setup *just so* which means that I can get working on them straight away[^1].

Our development machines are migrating to use [CentOS 6](http://www.centos.org/) which is a source RPM rebuild of a _prominent North American Enterprise Linux vendor_; we still have quite a few machines that are based on Centos 5 but new machine deployments tend to be the latest stable release.

<!-- more -->

Generally speaking, we always run our machines at runlevel 3. That's always been a choice we've explicitly taken; we don't need the additional X11 overhead. There's only one exception; you can't install Progress Sonic 8.5 without X11 (the installer won't run in console mode) - I'm sure that there are ways round this but when _sh ./install.bin -i console_ doesn't work like any other normal InstallAnywhere compiled installer, then that's a little annoying.

## Fixing the locale ##

It seems to me that our first set of kickstart scripts weren't properly tested; when executing java for the first time, the _file.encoding_ system property is sometimes ANSI_X3.4-1968 which basically means that the installation hasn't set the locale properly, you can see this when you use locale command and it has a bit of a whine and moan about the default locale.

```console
[root@bungle] ~# locale
locale: Cannot set LC_CTYPE to default locale: No such file or directory
locale: Cannot set LC_MESSAGES to default locale: No such file or directory
locale: Cannot set LC_ALL to default locale: No such file or directory
LANG=en_UK.UTF-8
# Some more stuff missed out here.
```

This is easily fixed by using localedef to define the locales properly

```console
[root@spongebob ~]# localedef -i en_US -f UTF-8 en_US.UTF-8
[root@spongebob ~]# localedef -i en_GB -f UTF-8 en_UK.UTF-8
```

## Removing unused packages

While the default installation is all well and good; my background has always led me to remove what I think are unnecessary packages, this is probably a function of growing up with only a 20Mb hard disk. These days I'm sure we could leave them installed and it wouldn't have much impact but a little bit of spring cleaning never hurt anyone.

For a virgin Centos 6, runlevel 5 system, then there are *always* a bunch of RPMs that can be removed impacting any day-to-day activities. The standard list that I remove is as follows; of course YMMV depending on what the machine needs to do; it's not such a big deal to _yum install_ them afterwards.

```console
yum -y -q remove  bluez-libs pwlib boost cscope ctags doxygen squid spamassassin
yum -y -q remove  pilot-link gdb gcc-java libgcj libgcj-devel
yum -y -q remove  valgrind valgrind-callgrind jessie synaptics cadaver bluez-bluefw
yum -y -q remove  emacs emacs-common emacs-leim emacspeak
yum -y -q remove  abyssinica-fonts cjkuni-fonts-common jomolhari-fonts khmeros-fonts-common kurdit-unikurd-web-fonts klug-fonts lohit-assamese-fonts lohit-bengali-fonts lohit-devanagari-fonts
yum -y -q remove  lohit-gujarati-fonts lohit-kannada-fonts lohit-oriya-fonts lohit-punjabi-fonts lohit-tamil-fonts lohit-telugu-fonts madan-fonts paktype-fonts-common sil-padauk-fonts
yum -y -q remove  smc-fonts-common thai-scalable-fonts-common thai-scalable-waree-fonts tibetan-machine-uni-fonts un-core-dotum-fonts un-core-fonts-common vlgothic-fonts-common wqy-zenhei-fonts
yum -y -q remove  m17n-contrib-assamese m17n-contrib-bengali m17n-contrib-gujarati m17n-contrib-hindi m17n-contrib-kannada m17n-contrib-maithili m17n-contrib-malayalam m17n-contrib-marathi
yum -y -q remove  m17n-contrib-oriya m17n-contrib-punjabi m17n-contrib-sinhala m17n-contrib-tamil m17n-contrib-telugu m17n-contrib-urdu pulseaudio webalizer
```

That's right I remove emacs; I don't use it, *vi* is king, and always will be; _nano_ if you have to.

## Extra packages

The CentOS repositories are great and all but you'll probably end up wanting some extra things that aren't installed by default (by kickstart or otherwise).

```console
rpm -Uhv http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.i686.rpm
rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-5.noarch.rpm
yum install centos-release-cr
yum --enablerepo=rpmforge-extras install git mercurial
yum --enablerepo=rpmforge-extras install freenx
yum install denyhosts
```

As you're probably aware _git_ and _mercurial_ are DVCS implementions. Internally, our source control is hosted under [mercurial](http://mercurial.selenic.com) because at the time we migrated from CVS, git wasn't really for Windows (yes it had a Windows port, but it was difficult and awkward); that's probably changed with [SmartGit](http://www.syntevo.com/smartgit/index.html) and [TortoiseGit](http://code.google.com/p/tortoisegit/) being available. To me, Windows users still seem to be an afterthought for git; whether or not git is better or worse than mercurial isn't an issue, there's plenty of opinion on the web about that, I'm happy to use both and I'm not going to inflame opinions in the diehard fans of either camp.

Freenx is an application/thin-client server based on nx technology. Basically it allows us to tunnel an entire X11 session over ssh. You can find more about it at [www.nomachine.com](http://www.nomachine.com/download.php)

## Denyhosts

[Denyhosts](http://denyhosts.sourceforge.net/) is awesome. I install it everywhere that has a public IP address and accessible via SSH. Before I found out about denyhosts back in 2005, I had a hand-cranked script that parsed /var/log/secure for SSH hacking attempts on our servers; that worked well enough and is still used in some places. It wasn't a bad script, just denyhosts is much better at it than anything a dilettante like myself could write. So this is a quick guide to setting up denyhosts up for your linux machine.

```console
[root@spongebob ~]# ## This might be /usr/share/denyhosts/data.
[root@spongebob ~]# cd /var/lib/denyhosts
[root@spongebob ~]# cat /etc/passwd | awk -F: '$3 < 499 { print $1 }' >restricted-usernames
```

This creates a list of usernames that are considered restricted (all of them with an id < 500) which will force denyhosts to reject all attempts to login with say _mysql_; you should also at this point edit the allowed-hosts file to add in all the hosts that you _never want to deny_. This step is quite important because otherwise you might end up barring your own IP address when you can't remember your own password.

I also add in/modify the following lines in _/etc/denyhosts.conf_ to enable synchronization and emailling of when hosts are added into the deny file.

```text
PURGE_DENY = 30d
PURGE_THRESHOLD = 0
BLOCK_SERVICE = ALL
ADMIN_EMAIL = my_user_address@gmail.com
SMTP_SUBJECT = DenyHosts Report from my_new_machine
RESET_ON_SUCCESS = yes
DAEMON_PURGE = 1d
SYNC_SERVER = http://xmlrpc.denyhosts.net:9911
```

## And Finally

```text
rm -f /etc/hosts.deny
touch /etc/hosts.deny
echo "Access is granted to this server only to authorized personnel only" > /etc/issue.net
echo "PermitRootLogin no" >>/etc/ssh/sshd_config
echo "Banner /etc/issue.net" >>/etc/ssh/sshd_config
service sshd restart
service denyhosts restart
```

And that is that, we're now ready to actually start deploying the application in question; java-based or otherwise.

[^1]: By the time I've finished all of this I'm happy that I can install java/ant/maven on the machine and it'll work to my satisfaction.
