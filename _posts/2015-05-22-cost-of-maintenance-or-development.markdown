---
layout: post
title: "Maintenance cost vs Development cost"
date: 2015-05-22 13:00
comments: false
#categories: [integration, interlok]
tags: [integration, interlok]
published: true
description: "The cost of a new integration is outweighed by the cost of maintainence"
keywords: "integration, interlok"
header-img: img/banner_crane.jpg
---

When we first started building Interlok we had a very clear design goal; it's about the lowering the cost of maintenance as opposed to lowering the cost of new development. It's simply a happy by-product of our design goals that the cost of integrating a new system is lowered as well. When faced with a classic integration problem; whether or not it's customer facing or just integrating various back-end systems; once you have the process up, running and in production; the maintenance of that integration is going to be the major cost factor.

<!-- more -->

Having a whizz-bang UI is a great selling tool; one of the questions that I often get asked is why our UI doesn't do more; or why it's not as fancy as some other product. The thinking behind this is that management wants the non-technical business team to be able to model complex business processes in the tool and push those into production. I would temper this desire with a bit of caution. The investment cycle for these kinds of things is measured in years; integrated back-end systems will become a critical part of your business and the ongoing maintainability of those systems is fundamental.

Interlok is a piece of software that behaves predictably; it doesn't try to be too clever about things. This makes it easy to maintain. All the configuration is plain text rather than binary objects so your systems team is free to choose whatever method they want to manage instances; deploy it in Docker, host your configuration directly in a source code control system.


