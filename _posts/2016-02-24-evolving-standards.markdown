---
layout: post
title: "The pain of evolving standards"
date: 2016-02-24 13:00
comments: false
#categories: [development]
tags: [development]
published: true
description: ""
keywords: "development"
excerpt_separator: <!-- more -->
---

I’ve recently had the pleasure of being involved in the aftermath of a penetration test on a fairly low-key web based application (it was government sponsored; and they quite rightly wanted to test the application for vulnerabilities) during the trial phase and subsequently trying to deal with the recommendations. Some of the previous penetration tests that we’ve undergone seemed quite amateurish in comparison to this one; the disclosures, where appropriate, were very detailed and comprehensive.

<!-- more -->

Penetration tests that don’t understand context are next to useless. For instance, a couple of years ago, one penetration test had a high risk vulnerability because we were disclosing the Apache httpd version number; they claimed it was vulnerable, because it wasn’t the latest 2.4 release. For this particular application, the target platform was RHEL 6.x (patched) which means that all ' fixes for httpd had been and would be backported to 2.2 by Redhat themselves for as long as RHEL 6.x was in support. They insisted it was a problem after repeated tests (and the customer refused to sign-off), so all we did in the end was turn off exposing the server version number in httpd config. We passed the penetration test, but we were no more or less secure for doing that.

One of the things that was highlighted by this latest penetration test was that developer naivety was a factor in certain decisions and project management did not have a good understanding of ' best practises. The mobile team had a requirement to hash a PIN and send it over the wire to the back-end system; unilaterally they decided to use the SHA-1 algorithm with no salt. If the application had been in production; this would have had real repercussions. SHA-1 has been off the approved list for a while; SHA-2 is the current standard; SHA-3 was just formalized back in August 2015.

Now the situation here is not that the developers chose SHA-1 with no salt; the issue really is, standards change all the time; _how do we go about supporting new standards and still maintain backwards compatibility without having major back-end changes every time the standards change_. This isn’t just about using the latest standards (for instance SHA-3 may not hit widespread adoption for another year; and there may still be limited support in your language of choice); what’s good enough now, isn’t going to be good enough in the future. You need to have a clear grasp of what standards you’ll be supporting and when the timeframe for those changes need to be incorporated into your application.

If you need to move fast, some of these decisions can be deferred; but you’re going to have to make a note of them, re-visit them, and make a choice. New features on your application can be like building new houses; they’ll look lovely but if your sewers aren’t up to scratch, then eventually you’re going to have raw effluent coming out of the drains and spoiling your lawn. The aggravated clean-up costs from that will far exceed the cost of doing it properly in the first place.

originally posted on [medium](https://medium.com/order-from-ambiguity/the-pain-of-evolving-standards-1e470191116e)
{: .faded}