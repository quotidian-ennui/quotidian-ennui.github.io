---
layout: post
title: "Supportability isn't an afterthought"
# date: 2015-10-14 13:00
comments: false
#categories: [development]
tags: [development]
published: true
description: ""
keywords: "development"
---

These days we're consumed with the new; always looking to get rid of the old in favour of something that's newer, brighter and shinier. It's very obvious with consumer electronics and the built in obsolescence that comes with almost every single product on the market. The pace of change, Moore's law, all support this kind of behaviour; my watch has more computing power in it, most likely, than the ZX Spectrum that was my first computer.

<!-- more -->

Every now and then I check out all the web frameworks that are out there; if we take JavaScript as an example then we can see what's out there quite easily: [http://www.infoq.com/research/javascript-frameworks-2015](). It wouldn't be unimaginable for me to consider doing the next web project in a different JavaScript framework because it's newer and trendier; each month there's a new one on the scene because yet another super-developer believes that theirs is the one true way. Sometimes the quest for the new means you miss one of the key cornerstones around which we should think about development: supportability.

Supportability is one of the soft requirements for any project; if you can't support the ongoing deployment and use of your product then you don't have a product. Supporting it doesn't just mean getting the product out of the door; it means being able to support changes that are required by customers (undoubtedly what you have developed isn't quite what the customer had in mind). If your product is a website that the users can customize then having a good self-help guide is a must to lower the supportability costs. Make sure that it's up to date for each release; having something that's out of date is sometimes even more frustrating that not having the information there at all.

Even the language choice or programming style is important for supportability; you're probably a brilliant developer, just like everyone would classify themselves as an above-average driver. The unfortunate person from third-line support who has to look at your code at 3am isn't a developer though (it isn't their day job) so using obtuse constructs in the language just because you can doesn't add to the supportability. It includes having clear build instructions so that you can build and deploy locally, unit tests so that you can be confident you haven't broken anything when you make a change and technical documentation for everything else. This is the stuff that, typically, developers don't like doing.

One of the points that I always try to make to any team is this: I am a developer who's not an expert in your language or framework. If I can't debug your code and figure out how I am going to approach fixing it within an hour or two, then we're in the situation where this team is going to have product support hanging over them like the sword of Damocles. This might be a price that you're willing to pay now, but you won't get to do more interesting things in the future.

originally posted on [medium](https://medium.com/order-from-ambiguity/supportability-isn-t-an-afterthought-e9755a14fc4f)
{: .faded}