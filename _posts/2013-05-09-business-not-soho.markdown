---
layout: post
title: "The benefits of an business class router"
date: 2013-05-08 17:00
comments: false
#categories: [tech]
tags: [tech]
published: true
description: "The consumer router you've got is rubbish if you actually need to work from home"
keywords: "tech, vdsl"

---

I was pretty much one of the first 10 ADSL installations in Reading; I was with BT back then (waaaay back in 2001), and I have stayed with them, during all that time I've only had 1 week's outage and they've been pretty reliable. What has irked me is that my local exchange has been fibre-enabled since 2011; it's only now that I've been able to get BT Infinity (installed for 2 weeks now). The nice engineer came round and disabled all my phone sockets bar the one in the study. The reasons for this I'm sure are quite technically sound I'm not a telecoms engineer; he said you can only run the infinity modem off the master socket (I don't have power near that socket); he moved the master socket to the office, which incidentally meant that all the other sockets have been disabled.

<!-- more -->

Anyway this story isn't about my woes with BT infinity, it's more to do with the amusement factor I have with so-called consumer devices. When the engineer left I went to speedtest.net and tested the speed. It was the new 80/20 infinity, or rather 60/9 in my case. This was running with the HH3 and their modem with a wired ethernet connection to my laptop. For the first few days at least I was going to leave it like this, but the HH3 is virtually useless, it doesn't give me the management features that I want or the WiFi range. I don't get Wifi in the spare bedroom because it's diagonally opposite the study on the ground floor.

I made the investment to buy a [Draytek Vigor 2850vn](http://www.draytek.co.uk/products/vigor2850.html) a while ago. I've been using it with my existing ADSL connection (it supports ADSL/VDSL/Ethernet WAN/3G via USB) and it's been rock solid with uptime measured in weeks and months rather than the random reboots every day that I had been getting with the HH2 and other sundry other ADSL modems.

As expected, soon enough, my wife started complaining that the WiFi signal wasn't working well enough in the kitchen so I had to fire up the Draytek and set about the VDSL configuration. First of all I disabled all the QoS settings on my router (it has a lot of things you can tweak and tinker with); I'm a big fan of it supporting multiple SSIDs, so I can have a public WiFi network that can't talk to the internal network (more about that another day).

The first setup that I had was with the Draytek in Ethernet WAN mode; plugging in the Thomson modem into the designated LAN port and using the Thomson as the modem still. Like this performance was already improved, better WiFi coverage and some speed improvements. I was tempted to leave it like that because I never read the T&C's properly (anyone remember the artificial restriction that you _had to use the alcatel frog modem_ to connect via ADSL???). In the end though, having the additional power-draw for the modem seemed a bit silly, so I plugged the VDSL cable directly into the Draytek and let it do its fine. It switched over without missing a beat.

The Draytek really has been an excellent product so far; the ability to setup a very simple PPTP VPN without having to resort to OpenVPN or pptpd on CentOS has been an added bonus. The speedtest.net report has also gone up to about 75/15 which is a marked improvement anyway, but you can't read too much into these things as I wasn't being very scientific about the whole thing.
