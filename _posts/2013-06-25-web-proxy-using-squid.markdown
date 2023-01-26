---
layout: post
title: "Web proxy using Squid"
date: 2013-06-25 10:00
comments: false
#categories: [tech]
tags: [tech]
published: true
description: "My daughter going to bypass my safety filters; that doesn't mean I shouldn't at least try."
keywords: "windows linux squid proxy wpad dhcpd"

---

I have a daughter; in the near future she's going to start browsing and terrorizing the web at large. One of the things that's been at the back of my mind is how I'm going to handle that. I don't subscribe to the notion of ISP level filtering; not because I think it's a bad idea (it might not be a bad idea, but it's sure to be implemented terribly), but because I don't think that I should abrogate my parental responsibilities in that fashion. The other thing of course, is that my daughter will (eventually) be able to bypass any security; that's not an if, it's a when; when she can do that, then good on her; I think I'd have to trust her by then. In the meantime though, it's time to start locking down the network...

<!-- more -->

There are a couple of caveats to this; my wife works for a large corporate and the group policy on her laptop and other devices is spectacularly well defined; I would have expected nothing less. This means that all the things that I'm doing are geared around transparently supporting her laptop when it's at home (I don't have a Windows domain or similar) but still supplying an acceptable level of of filtering. Basic network service configuration isn't covered because there's already a lot of stuff out there on the web that gives a better set of examples. My router is also sufficiently capable because the end-goal is for only a single IP address (the proxy server) to have direct access to the web at large.

## DNS/DHCP/HTTPD pre-requisites ##

First step is to use [OpenDNS][]; that's given me the ability to filter Web content via DNS lookups based on my own specific criteria. Rather than relying on my router to provide DNS / DHCP, I already have an instance of dhcpd and bind running; it's always used the OpenDNS servers as a forwarder, so I just needed to create an account at OpenDNS and configure my settings. My dhcpd configuration already specifies that my bind instance is the only DNS server around; along with some other funky things that are out of scope.

I created a ``wpad`` A record in bind so that wpad.chan.net resolves to an actual IP address, similarly one for ``proxy``. I also created a virtual host in apache and assigned it the server aliases ``proxy.chan.net`` and ``wpad.chan.net``. I'm using this virtual host to host the files required to support my proxy (remember to add some type header definitions for ``application/x-ns-proxy-autoconfig``)

## Squid Proxy ##

[Squid][] is trivial to configure; on CentOS, the example squid configuration file is ready to use bar the network settings. After running squid for a while, I found that I had to add in some specific items that aren't in the example. Squid runs in conjunction with [squidguard][] giving me blacklist control; squid, squidguard, squidguard-blacklists are all available via yum (I have rpmforge enabled).

My changes from the example are shown below with enough of the context to show you where I added them.

```text

acl SSL_ports port 443
acl mail_ports port 993         # imaps
acl im_ports port 1863          # MSN
acl im_ports port 5222          # GoogleTalk
acl im_ports port 3158          # trillian
# ... by default there are some other ports listed here
acl Safe_ports port 993         # imaps

# Deny CONNECT to other than secure SSL ports
http_access allow CONNECT mail_ports
http_access allow CONNECT im_ports
http_access deny CONNECT !SSL_ports

# ... rest of the squid file.
# At the bottom of the file.
url_rewrite_program /usr/bin/squidguard -c /etc/squid/squidguard.conf
```

I've basically added definitions for _mail_ports_ and _im_ports_; these are then available for the various IM clients to use the proxy CONNECT directive to connect to. Port 993 is the standard port for IMAPS which because I've configured gmail in the Windows 8 Mail application; it will try to access via the proxy (according to the squid logs). Then we're denying all other CONNECT requests to anything other than the standard SSL port.

Squidguard is next, and I've used a very minimal configuration (/etc/squid/squidguard.conf); you can blacklist what you want based on the squidguard-blacklists.conf example. After configuration I rebuilt the squidguard database (it might not have been done yet) using ``squidguard -C all`` and then restarted squid.

```text

#
# CONFIG FILE FOR SQUIDGUARD
#

dbhome /var/lib/squidguard
logdir /var/log/squidguard

#
# DESTINATION CLASSES:
#
dest adult {
  logfile   adult.log
  domainlist      adult/domains
  urllist         adult/urls
  expressionlist  adult/expressions
  redirect        http://proxy.chan.net/blocked.html
}
dest gambling {
   logfile   gambling.log
   domainlist      gambling/domains
   urllist         gambling/urls
   expressionlist  gambling/expressions
   redirect        http://proxy.chan.net/blocked.html
}
acl {
        default {
                pass     !adult !gambling all
                redirect        http://proxy.chan.net/blocked.html
        }
}
```


I now have a proxy configured and tested it (I went to one of the domains listed in /var/lib/squidguard/gambling/domains); if you've been successful, then you will see your blocked.html page (or a 404 error saying blocked.html couldn't be found). With the proxy running I now needed to notify all the clients to use the proxy; we can do that via WPAD (Web Proxy Auto Discovery) and DHCP.

## DHCP/DNS Part deux ##

The history behind option-252 is long and varied; it's only interesting in the sense that we can use it to send information back to our clients with the proxy URL.

```text

option wpad code 252 = text;
option wpad "http://proxy.chan.net/proxy.pac ";

class "MSFT" {
  # see https://lists.isc.org/pipermail/dhcp-users/2009-October/010496.html
  match if substring(option vendor-class-identifier, 0, 4) = "MSFT";
  option dhcp-parameter-request-list = concat(option dhcp-parameter-request-list, fc);
}

```

There's one thing that is of note here; I have put a space at the end of my proxy URL; this is to work-around some instances where an Microsoft client will strip off the last character due to trying to NUL terminate the string (I suspect by now this is resolved, as the last reference to it that I've found is around 2009); this in itself leads to some odd behaviour described later on.

### The proxy.pac file ###

The simplest possible proxy.pac file is as follows; more complicated examples abound on the net; some good notes can be found at the [ProxyPacFiles][] website.

```javascript

function FindProxyForURL(url, host)
{
  return "PROXY 172.16.0.1:3128";
}

```

I added this file into my virtual hosts document root as ``proxy.pac`` and made 3 symbolic links to it, their names were "``proxy.pac ``" (there is a trailing space), "``proxy.pac%20``", "``wpad.dat``" for reasons that will become clear. Generally speaking the two files that should be called into action will be proxy.pac (for those clients that work with dhcpd option 252), and wpad.dat for those clients that have tried to auto-configure using a DNS name along the lines of ``http://wpad/wpad.dat``.

## Client configuration ##

Here's a list of changes that I had to do to cope with various client configurations; Linux and Windows (7/8/2012) just worked.

### iPhone (iOS 6) ###

With the iPhone I needed to specifically configure the HTTP proxy to be AUTO for the wireless network (it defaults to NONE); even after that the iPhone had a problem with the proxy auto configuration file; it can't find it. The access_log for httpd has

```text

172.16.2.2 - - [17/Jun/2013:20:45:16 +0100] "GET /proxy.pac%20 HTTP/1.1" 404 296 "-" "Chrome/27.0.1453.10 CFNetwork/609.1.4 Darwin/13.0.0"
172.16.2.2 - - [17/Jun/2013:20:45:16 +0100] "GET /proxy.pac%20 HTTP/1.1" 404 296 "-" "Chrome/27.0.1453.10 CFNetwork/609.1.4 Darwin/13.0.0"
172.16.2.2 - - [17/Jun/2013:21:12:23 +0100] "GET /proxy.pac%2520 HTTP/1.1" 404 298 "-" "MobileSafari/8536.25 CFNetwork/609.1.4 Darwin/13.0.0"
172.16.2.2 - - [17/Jun/2013:21:12:25 +0100] "GET /proxy.pac%2520 HTTP/1.1" 404 298 "-" "syncdefaultsd (unknown version) CFNetwork/609.1.4 Darwin/13.0.0"

```

It's looking for the wrong file entirely; ``%25`` is the encoded form for ``%``; which isn't as crazy as it seems (but is in fact utterly wrong); that's the reason for the symlink "``proxy.pac%20``". Using Chrome on iOS, then you get the correct behaviour; it looks for the actual file specified in dhcpd.conf option which is "``proxy.pac ``" (with a space).

### Other devices ###

Android + Windows phone - They don't appear to support WPAD files, so it appears we have to configure the proxy manually for the wireless network in question (it is possible to configure a proxy on a per-network basis on Jelly Bean and Windows Phone 8); this isn't yet a big deal but will cause some frustration I'm sure to visitors to my house...

I haven't tested this with Mac OSX clients; I don't have one; because the keyboard layout sucks on a Macbook (I don't use a macs because they don't adhere to the BS4822 standard). Its behaviour will likely be be the same as the iPhone, so it should all be good.

## Finally ##

I've locked down the network so that no traffic gets to the web (IM/HTTP/HTTPS) unless it comes from 172.16.0.1. Not much is broken right now, but I'm sure I have broken some device's network access or other. I'm not (yet) locking down any other ports like POP3/SMTP/SSH. VPN access is another thing; this is probably the start of an arms race. The happy side effect of all of this is that because of Dynamic DNS + SSH tunnelling, I now also have a ready made proxy for when I'm out of the country, or access is locked down so I can't access my VPN.

[OpenDNS]: http://www.opendns.org/
[Squid]: http://www.squid-cache.org/
[squidguard]: http://www.squidguard.org/
[ProxyPacFiles]: http://www.proxypacfiles.com/proxypac/