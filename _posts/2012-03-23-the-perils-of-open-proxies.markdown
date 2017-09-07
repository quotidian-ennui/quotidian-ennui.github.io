---
layout: post
title: "The Perils Of Open Proxies"
date: 2012-03-23 12:00
comments: false
categories: tech linux
tags: [tech, linux]
published: true
description: "I setup an open proxy by mistake, and used iptables to filter out rogue connections"
keywords: "apache, linux, proxy"

---

Once upon a time, a very long ago now, about last Friday, I was provisioning some new VM images kindly provided to me by our infrastructure team. Apparently I have my own dedicated ESX server (admittedly running on some old hardware they had lying around) with which to play around to my heart's content. That environment is intended to be a replacement for this server; but truth be told I haven't had time to migrate all the services running on this machine over. In fact I'm currently having trouble making hudson run the unit tests.

Anyway, I was in a rush and setup mod_ajp_proxy/tomcat on the box without really thinking about what I was doing. To cut a long story short, I missed off the most important line in the proxy configuration _Deny From All_ which meant that effectively this box was operating as an open proxy.

_Oh dear..._

<!-- more -->

Indeed within about 2 days the box was being hit by thousands upon thousands of requests; our network performance was still within acceptable limits (it wasn't saturating it) but it was obvious that I'd screwed up. I gave myself a _final written warning_[^1] for that, and quickly resolved that item of configuration so that everyone trying to use it as proxy would get a 403 response. Everything was back to normal, but we were still getting hit by the requests (we still are).

Of course, reconfiguring the VM so that it had a different external IP address was a possibility; we did have plenty of addresses spare. That would have been the simple solution and one I might have considered but by then we'd already had a couple of test deployments that were publicly available. So, in the interests of expediency, I decided to use iptables to start blocking the ip addresses that kept trying to use the machine as a proxy.

## Reconfigure Apache

Logging is pretty powerful in apache, and what we really needed to do was to create a minimal access log that only contains the information we want.


{% highlight apache %}
<VirtualHost 1.2.3.4:80>
  ErrorDocument 403 "403"
  LogLevel crit
  LogFormat "%h %>s" minimal
  CustomLog logs/access-minimal.log minimal
  CustomLog logs/access_log combined

</VirtualHost>
{% endhighlight %}

So here we are setting up some custom logging to logs/access-minimal which will only contain the IP address and HTTP status code; the output is below. Additionally to save bandwidth whenever a 403 status would be triggered, it just sends back "403" without any adornment.

{% highlight text %}
106.9.207.77 403
59.124.31.178 403
59.124.31.178 403
122.138.2.110 403
41.34.190.207 403
180.76.5.171 200
180.76.5.161 200
{% endhighlight %}

## Block the pesky proxy wannabes

From here it's a pretty easy thing to parse using awk; you only need to tail the file and start adding IP addresses that have a 403 status code; here's a one liner that can do exactly that.

{% highlight console %}
tail -f /var/log/httpd/access-minimal.log|while read pi; do echo "$pi"|grep 403|gawk '{print $1}'|while read pi;do /sbin/iptables -I INPUT -s $pi -j DROP;done;done
{% endhighlight %}

You've been modifying the httpd configuration file so you're able to get a bit of root shell action (probably using "screen":http://linux.die.net/man/1/screen). Personally, for some reason, I've always preferred to trigger my scripts via cron; so that's what I did; the script also has to have following features over the one-liner

* Allow you to "never block" certain ip addresses (stored in /etc/httpd/conf/httpblock.ignored, 1 IP per line)
* Only add IP addresses that aren't already in iptables (the reason for this is because I'm processing the entirety of access-minimal.log everytime the cronjob is triggered which is pure laziness on my part)

{% highlight bash %}
#!/bin/bash

HTTP_CONF_DIR="/etc/httpd/conf"
LOG_DIR="/var/log/httpd"
HOSTS_DENY="${HTTP_CONF_DIR}/hosts.deny"
LOG_FILE="${LOG_DIR}/access-minimal.log"
TMP_IPTABLES_DENY=`mktemp /tmp/iptables.drop.XXXXXXXX`
TMP_IPTABLES_NEW=`mktemp /tmp/iptables.drop.XXXXXXXX`
TMPFILES="$TMP_IPTABLES_DENY $TMP_IPTABLES_NEW"
# Defaults to 127.0.0.1 if the file doesn't exist or is empty.
IGNORED_HOSTS=`if [ -s ${HTTP_CONF_DIR}/httpblock.ignored ]; then cat ${HTTP_CONF_DIR}/httpblock.ignored; else echo 127.0.0.1; fi`
function dropForbidden() {
  cat $LOG_FILE | grep -vF "$IGNORED_HOSTS" | awk '$2 == 403 || $2 == 400 { print $1 }' | sort | uniq >> $TMP_IPTABLES_NEW
  iptables -L -n | grep DROP | awk '{print $4}' | sort | uniq >> $TMP_IPTABLES_DENY
  FORBIDDEN=`cat $TMP_IPTABLES_NEW | grep -vF --file="$TMP_IPTABLES_DENY"`
  for ip in $FORBIDDEN
  do
   iptables -I INPUT -s $ip -j DROP
  done
}
dropForbidden
rm -f $TMPFILES
{% endhighlight %}

The script has changed a fair bit since I first wrote it, so this is just a starting point; once in a while you would probably want to prune all the iptables entries that haven't had any hits in a while as those pesky script kiddies have gotten bored. You will want to make sure that logrotate is rotating the logfiles on a daily basis to start off with; and then onto a weekly basis once the amount of logging settles down.


[^1]: This is a popular adaptris-ism when someone does something wrong; way back in the mists of time, a few of us had warnings for nonsensical things that would never have stood up in a employment tribunal. Nowadays when we say it, it's a slap on the wrist to remind us of the old days.
