---
layout: post
title: "What makes you an expert developer?"
date: 2013-02-28 17:00
comments: false
#categories: [development, rant]
tags: [development, rant]
published: true
description: "Are you an expert developer if you've had n years experience?"
keywords: "development, recruitment"

---

I re-watched groundhog day quite recently; it is still a work of genius but it got me to thinking about the subtext of the film and how it relates to software development.

<!-- more -->

The key take-away from the film isn't that Bill Murray gets the girl; it's that it takes time to get good at things. Studies have suggested that it takes about 10000 hours of _meaningful practice_ to become an expert in any given task; if we assume 8 hour days, and 250 working days a year, that's 5 years.

Based on this, is it safe to assume that someone with 5 years experience in development could be considered an expert? Well, no; sometimes you can interview someone with 5 years experience and it becomes quite apparent that they have had 1 years experience 5 times, rather than 5 years experience. You can have all the buzzwords you want on your CV; if you say you're a JMS expert, and yet you don't know what the JMSReplyTo header is for I'm not going to look upon that favourably.

As part of our interview process, I ask our prospective candidates to complete a (short) [test]({{ site.baseurl }}/artifacts/interview.zip). I wouldn't say that the test is very hard; almost all the questions can be found by using your preferred search engine; it is primarily a test of initiative, planning and communication. I'm always surprised with how many glowing CV's I've seen and yet their test evaluation ends up being very poor. One chap used Spring for everything; which might not have been a bad thing, but he included a copy of the jars into every question, and tried to email it to me; needless to say it didn't work.

Hiring developers is hard, there's lots of people who have been writing web applications using whatever framework is the flavour of the day. Our job as integration experts involves knowing enough about any given system to get into trouble; our top people know enough to get themselves out of trouble too. There are a huge number of systems out there, each with their own esoteric limitations and complexities so I need the person who can implement RFC2204 from scratch in java (or RFC5024 if you prefer) not the person who thinks using `@Cache(usage=CacheConcurrencyStrategy.READ_WRITE)` makes them a hibernate expert.
