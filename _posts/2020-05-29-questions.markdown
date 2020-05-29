---
layout: post
title: "Questions; there's a point"
comments: false
tags: [rant]
categories: [rant]
published: true
description: "I have questions about your project; you should have done the thinking already."
keywords: ""
excerpt_separator: <!-- more -->
---

I have _chief_ in my job title. Does this makes my opinion count for more? Not really, I just have more paperwork to do; more board reports to write; fewer things on my to-do list that I find interesting. Because of my so-called job title, I'm asked to review / rubber stamp projects and approaches because no-one likes to take reponsibility for the decision. This means more meetings and less time actually building things. What's frustrating about a lot of the meetings is that people aren't prepared sufficiently. They aren't prepared to do the hard work up front; they simply want to be able to carry on as they've always done. I'm not Bill Gates, and this isn't one of his infamous technical reviews, but if I can get to the stage where you sound ill-prepared; it's not going to end well.

<!-- more -->

So, my job is all about asking questions; it's to ask all the the questions that everyone in the meeting wants to ask, but can't/won't/doesn't want to. We can talk a lot about the big vision, and what problems it solves, but you haven't given any thought about the end state; how you're going to get there; you don't have a clue what the next step in your journey is going to be. All we know is that you have 6 months to build it in, because the product team have already promised marketing a go-live date in Q3. You want me to rubber stamp the project because senior leadership has realised it hasn't had architectural signoff (since these things are apparently important).

The things all these meetings have in common are all run along the same lines.

- _What's the impact on support_ - I'm personally not up-to-date with the latest framework du jour; if I'm not, then our support team are unlikely to be. What's going to happen after go-live and it gets chucked at the support team. This has a practical consequence because support just thinks anything you've touched is shit, and they end up not being nice to you. You probably want support to be nice to you.
- _We have team X; who are most skilled in framework Y; that's why we've chosen that framework_ - This isn't about languages, but about a specific framework in that language. If you haven't covered yourself in glory with the last project that used this framework, then why is familiarity a driver for choice.
- _We're going to re-invent the wheel by handling this particular requirement by writing our own shit from scratch_ - some things might already be a solved problem; and you just have to choose.
- _How are you going to deploy it?_
- _How are we going to scale it?_ - `java -Xmx16G` is probably not a great scaling strategy to handle an additional 100 requests a minute.

I ask the hard questions and it makes me a pain the ass. I don't get invited to project meetings because I make it too hard for the delivery manager. That's your loss, not mine.
