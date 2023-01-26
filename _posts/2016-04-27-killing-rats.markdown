---
layout: post
title: "Killing a rat is easier with an air rifle than an AK-47"
date: 2016-04-27 13:00
comments: false
#categories: [development]
tags: [development]
published: true
description: ""
keywords: "development"
---

If you have to hunt rats; what's the right choice of weapon? Probably the air-rifle. The AK-47 could do the job, but it would be inefficient; the amount of energy in each round would be a vast over-kill; accuracy and ricochets in confined spaces would also be a concern. You'd choose the right tool for the job and make sure it's the right tool.

<!-- more -->

Recently, we've had some source code scanned by a different (from normal) static code analysis tool. Our parent company insists on doing this periodically, and we're always happy to let them do it. What didn't impress me was the report that came back that said one of our products had 250+ high risk vulnerabilities. This, of course, immediately made it a political hot potato and I've had a lot of meetings on the back of this number without being able to review the results of the scan.

Given that we already use a static code analysis tool to scan our software; the outcome came as a huge surprise; and I wasn't willing to commit to anything around remediation without understanding the context. This was borne out when I finally had a chance to review the report.

To cut a long story short, all 250+ high risk vulnerabilities could be nailed down to 2 things:

The first is a fundamental misunderstanding of what the product is, what it does, and how it is deployed. Our primary product is an integration product that runs stand-alone with no user-interaction. The thing it does not do is expose a web interface that allows user input. It receives (or actively polls for) messages from a source system; does some data enrichment (perhaps); and sends the messages onward to the target system. Marking code as vulnerable because it opens a file and does not sanitise the input is pointless in this context; if we did sanitise the input (and by doing that change the input); it would no longer be an integration product and ultimately not fit for purpose. If it was a public facing web-based product that allowed user input; then that would be a vulnerability.

The second root cause was even more context driven; the tool was actually scanning all the sources files in the test/ directory, which is where all the unit tests and resources supporting those tests reside. These are never shipped to the customer or deployed in any fashion. Vulnerabilities here will be intentional; we may write vulnerable code for regression testing purposes.

Any kind of security audit depends on the context; if you don't understand the context in which software runs, then you won't be able to assert anything about the security of the software. Static code analysis tools are useful, but they won't understand the context and the output needs to be reviewed before any inferences can be drawn. Not doing this will, at best, be a distraction, or worse, cause management to hold more meetings stopping you from getting stuff done.

Ultimately, a lot of source code was tested, and the projects that were designed to be web-facing with user input did not have any high risk vulnerabilities; there were some low-risk ones and a couple of medium risk ones; which is exactly the result that I would have expected.

So, use the right tool for the job, and make sure it's the right one whenever you use it.

originally posted on [medium](https://medium.com/order-from-ambiguity/killing-a-rat-is-easier-with-an-air-rifle-than-an-ak-47-272f91e0dafd)
{: .faded}