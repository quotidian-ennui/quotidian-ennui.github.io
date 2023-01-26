---
layout: post
title: "Slow Java Crypto Performance on Linux"
date: 2012-06-15 17:00
comments: false
#categories: [java, linux]
tags: [java, linux]
published: true
description: "Slow SecureRandom is always annoying; I just wish Oracle would fix their documentation"
keywords: "java, centos, SecureRandom"

---

I've had a new virtual server (CentOS 6.x) commissioned to run as a [jenkins](http://jenkins-ci.org) slave. After installing all the pre-requisites on the box and configuring various build properties; I started a standard build of the framework on the machine. The build works, but it's extremely slow.

After some investigation and isolation; we nailed it down to `SecureKeyFactory.generateSecret()` which is used when we decode passwords. The performance of encoding didn't really seem to be affected, the big problem was with decoding. We tend to store all our passwords encoded in our various build properties so whenever *Password.decode()* was called, this would take ~30 to 40 seconds consistently.

_It's SecureRandom again isn't it_

<!-- more -->

It's always SecureRandom; if you have a problem with speed during a cryptographic operation you can point the finger at SecureRandom. It all stems there being not enough randomness in /dev/random; the virtual machine isn't doing enough network reads or disk accesses or something to generate any more entropy and it's blocking.

There are 3 easy fixes to the problem; some of which make the machine a bit less random when it comes to generating random numbers. These aren't production machines where randomness is a critical part of its operation so any fix is acceptable[^1]. Answers can be derived from reading the answers to this [StackOverflow Question](http://stackoverflow.com/questions/137212/how-to-solve-performance-problem-with-java-securerandom) and following some of the links.

## Install haveged

* Install [haveged](http://www.issihosts.com/haveged/downloads.html) from your favourite repo. It's pretty much there for all the popular linux distributions.

## Make java actually use /dev/urandom

We checked `${java.home}/jre/lib/security/java.security`, and as always the securerandom.source property points to file:/dev/urandom. The notes in the file itself says that the NativePRNG will use /dev/urandom; however, it lies, lying like a [Gregor MacGregor](http://en.wikipedia.org/wiki/Gregor_MacGregor) as [Bug 6202721](http://bugs.sun.com/view_bug.do?bug_id=6202721) will testify; file:/dev/urandom is treated as magic, and it ends up using /dev/random *regardless*. That's pretty frustrating; it's not the fact that it's magic and it points to /dev/random, it's the fact that the lazy fools haven't even updated the documentation; it's been like that, for what, 8 years, and they haven't modified the stupid _java.security_ documentation. Still, all you really have to do is to make the URI *not magic* anymore.

```properties
#
# Select the source of seed data for SecureRandom. By default an
# attempt is made to use the entropy gathering device specified by
# the securerandom.source property. If an exception occurs when
# accessing the URL then the traditional system/thread activity
# algorithm is used.
#
# On Solaris and Linux systems, if file:/dev/urandom is specified and it
# exists, a special SecureRandom implementation is activated by default.
# This "NativePRNG" reads random bytes directly from /dev/urandom.
#
# On Windows systems, the URLs file:/dev/random and file:/dev/urandom
# enables use of the Microsoft CryptoAPI seed functionality.
#
# securerandom.source=file:/dev/urandom
securerandom.source=file:/dev/./urandom
```

There, your java installation is patched up, and now ready for some not so random crypto action.


## Install rng-tools

As */proc/sys/kernel/random/entropy_avail* is always reporting an extremely low value; /dev/random is genuinely an issue, so we would be better off installing *rng-tools* and using _rngd_ to feed the kernel random device. On most CentOS machines rng-tools is probably installed, but likely won't have been started as part of the initscripts. The configuration itself is extremely straight forward, as it's a single program with minimal configuration.

```console
[root@linux ~]# yum install rng-tools
[root@linux ~]# echo 'EXTRAOPTIONS="-i -o /dev/random -r /dev/urandom -t 10 -W 2048"' > /etc/sysconfig/rngd
[root@linux ~]# chkconfig rngd on
[root@linux ~]# service rngd restart
```

The man page for rngd is pretty comprehensive so you can check that for the exact meanings for each parameter. The only thing that is a must is the -i flag as your source device (/dev/urandom) isn't going to FIPS compliant and you don't want rngd to terminate unexpectedly.

## Conclusion

Any one of these solutions will fix the problem, it's largely down to personal preference as to which one you use; If you have multiple versions of java, and multiple applications that might need entropy then the first is probably preferable. The third is _ok_ but might cause you additional issues if you run an HTTPS enabled service with limited cipher suites...

[^1]: It's another question entirely if you want to do this on a production machine; security is a trade-off as Bruce Schneier would say.