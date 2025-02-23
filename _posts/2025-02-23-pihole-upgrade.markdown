---
layout: post
title: "Upgrade pihole kubernetes from 5 to 6"
comments: false
tags: [tech, kubernetes]
# categories: [development,rant]
published: true
description: "Was there a point to making my upgrade rollback-able?"
keywords: ""
excerpt_separator: <!-- more -->
---

Pi-Hole 6.0 finally came out after a long beta, so of course we have to upgrade as soon as is practicable. It didn't end up being that hard an upgrade, but I wanted the configuration to be switchable between 5/6 in the initial instance within my kubernetes environment; this ended being the reason I haven't just got a pihole.toml and mounted it via a configmap. In the end the biggest issue was that dnsmasq behaviour had changed.

<!-- more -->

The summary of changes was:

- alive / readiness endpoints from `/admin/index.php` to `/admin`
- Environment variables based on looking at the default pihole.toml.

```terraform
  pihole_v6_env_vars = {
    # allows mount of files /etc/dnsmasq.d which we are doing.
    "FTLCONF_misc_etc_dnsmasq_d"                    = "true"
    "FTLCONF_webserver_port"                        = "80"
    "FTLCONF_dns_listeningMode"                     = "all"
    "FTLCONF_dns_bogusPriv"                         = "true"
    "FTLCONF_dns_domainNeeded"                      = "true"
    "FTLCONF_dns_upstreams"                         = "1.1.1.1;9.9.9.9;76.76.2.1"
    "FTLCONF_dns_dnssec"                            = "true"
    "FTLCONF_webserver_interface_theme"             = "default-dark"
    "FTLCONF_webserver_interface_boxed"             = "false"
    "FTLCONF_dns_analyzeOnlyAandAAAA"               = "true"
    "FTLCONF_dns_blocking_mode"                     = "NULL"
    "FTLCONF_dns_blockTTL"                          = "60"
    "FTLCONF_database_maxDBdays"                    = "63"
    "FTLCONF_dns_specialDomains_mozillaCanary"      = "true"
    "FTLCONF_dns_specialDomains_iCloudPrivateRelay" = "true"
    "FTLCONF_dns_replyWhenBusy"                     = "DROP"
    "FTLCONF_dns_rateLimit_count"                   = "20000"
    "FTLCONF_dns_rateLimit_interval"                = "10"
    "FTLCONF_dns_ignoreLocalhost"                   = "true"
    "FTLCONF_ntp_ipv4_active"                       = "false"
    "FTLCONF_ntp_ipv6_active"                       = "false"
    "FTLCONF_ntp_sync_active"                       = "false"
    "FTLCONF_misc_nice"                             = "-999"
    "TZ"                                            = "Europe/London"
  }
```

Since the pihole team have announced that `2024.07.0` is the last v5 docker image; I can have a switchable configuration between v5/v6 via a simple condition in HCL. It does seem pointless now that I've done the upgrade.

```terraform
pihole_v5 = local.images.pihole.version == "2024.07.0" ? true : false
```
