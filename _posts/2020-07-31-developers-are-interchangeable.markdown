---
layout: post
title: "The 'developers are interchangeable' conundrum"
comments: false
tags: [development]
#categories: [development]
published: true
description: "Interchangeable implies monoculture and homogeneity"
keywords: ""
excerpt_separator: <!-- more -->
---

I'm now at the stage of my life where I have accrued some measure of experience and marginal success (insert the appropriate Liam Neeson quote here). I'm also quite expensive, because I'm a middle aged man that's been on some career trajectory; yet at some level I'm viewed as being interchangeable with some other anonymous developer. This has got me thinking as to whether that's really the case or whether like most things, it's that way because that's the _easy way out_.

<!-- more -->

It all comes down to measuring the wrong things, measuring the inputs and not measuring the outcomes. We can take baking to illustrate the point: I have baked brownies using a recipe that my wife has tuned to be reliable and easy. The brownies that I make taste different to the brownies that she makes. The ingredients and quantities are the same; the process is the same; the equipment is the same; and yet the outcome is different. The result is the same (we have brownies) but the outcome is different (my brownies aren't as satisfying...). I'm not an interchangeable cog in the the baking process so why should anyone expect a developers be any different.

All developers will have had slightly different experiences to get to where they are; they may come to the same conclusions, but the process may well be different and we would be well advised to bear that in mind.

I've learnt a few things during my time building teams and delivering software; in retrospect I've been lucky because I've been involved in some interesting projects, and largely as a result of that met and worked with some interesting people. Perhaps this means I'm not interchangeable with some other anonymous developer

## More isn't always the answer

Throwing more developers at a project at the wrong time isn't the answer. Stand-ups take longer, and if you're hierarchally structured, then things get lost in translation (dare I say chinese whispers). If you speak to my manager, my manager speaks to me then just means that I will do the wrong thing. Increasing the cost of communication has a high chance of causing visible project failure. The interpersonal relationships and productivity between individuals can suffer as they have to navigate around __how best to interact with this other individual__. You will get pissed off, and sometimes that will come out in your interactions with people. They then have to learn why you're pissed off, and whether it's something they've done. I personally manage this by having a [user-manual]({{ site.baseurl}}/about/).

If you're outsourcing your development to a cheaper country/using cheaper contractors then that might improve your financial cost baseline, but it's going to cost you more in time and effort. The proximity of the team to you in terms of timezones is a factor; the physical location as well (this is increasingly more apparent during the COVID-19 lockdown) since you will incur an increased cost of communication.

People are messy and having blanket prescribed processes can be counter-productive.

## Paying lip service to unit-testing means you hate your future self

Unit testing is one of those things. Like backups, you don't need them until you need them. By the time you figure out you needed them, it's probably too late. It's too late because no-one has any confidence in your project; you've broken a deployment enough times with some bug that would have been caught by unit tests and automated integration testing. At this point _this product needs a complete rewrite_ becomes the default position for the powers that be.

Have unit tests so that you have confidence when you refactor. Measure the code coverage diff on pull requests; that gives you an idea of whether or not the developer is thinking about testability. If you're on 95% coverage and you accept a PR that has 0% diff coverage; while it might not lower your actual code coverage meaningfully; it does mean you have a code-path that is not tested, so your future self has more work to do at 3am when that shit hits the fan.

## The customer has to participate in testing

If the actual users don't care enough about what you're delivering to commit to a time-window for testing then it doesn't matter what you deliver: _This is crap because it doesn't do this thing that I expected it to do_....

The actual user is the person who's going to use your software day-to-day; not the commissioning stakeholder. This is the sharp end of the project, the stakeholder has already been wined and dined; they don't matter if the end-user is sad.

## Deadlines are mostly artificial

Most deadlines are ultimately meaningless, mystifying arbitrary and often bear no relationship to the complexity of the problem cum feature. If you have a single developer working on an 100k+ LOC codebase, and they've been given a week to deliver feature X; then that deadline is most arbitrary and meaningless. You probably won't achieve it, you'll burn out the developer, and the quality will be, at best, riddled with short cuts and technical debt (more likely it will just be shit).

## Know what good looks like

For me good tends to mean reducing the support burden; if that's not the case then I generally find that the deliverable isn't going to be fit-for-purpose for the customer either. If an anonymous developer can't take your project and deploy it in 20 minutes, then the delivery team hasn't thought about what good looks like, and they will probably throw bugs back in the user's face with the words _it works on my machine_.

If your product is so complicated then I can't possibly undestand it, then good will mean you have to spend time _you don't want to spend_ doing documentation; building docker images; automated pipelines and all that stuff.

Even better is knowing what good looks like in the context of your financial and resourcing constraints. It's inevitable that you want more players; more developer; more CPU time; and you'll be denied by the business. In that context, good is somewhat different to a good where money is no object.

## Things change, so it's a journey

I've been involved, more than once, where we've delivered a great project; the customer is ecstatic. After a few years; before you know it; they hate us. We've moved onto delivering the next thing for another customer and not spent any time keeping the old one happy. The product looks dated (cos it's not Web 2.0 or whatever); it has multiple vulnerabilities, because we used struts, and their perfectly valid statement is _we paid you X over the last 10 years, and we expect you to fix all these things for free_. If we'd done something incrementally, then we wouldn't be in position. It's a bit like owning a car, you have to service it to make sure it keeps running year after year. If something isn't fit for purpose, then you replace it. That's why the customer is paying support & maintenance, and you should be writing them letters to say your next service is due.

Servicing technical debt is a pain; it's not sexy (since invariably you aren't using the framework-du-jour) so no one wants to do it but you have to. You have to keep revisiting all the things that are still in production; think about whether you want to sunset; and tell the customer what their migration plan needs to be. If you want to keep raking in the maintenance, then you will have to put the work in to service the product. If that means taking your headcount +50 because you have 100+ unloved products out there, then perhaps your business model is rewarding the wrong behaviours.

## Don't be scared of throwing it away.

Most things are a one-off until you can use exactly that same codebase for a different customer. This is fine. Don't declare it a product if it can't be reused, or it takes you 6 months to onboard a new customer. This is a language nuance and expectation thing. If you declare something to be a product especially in terms of software, then people will naturally think of it as something like Office, or Windows.

If it's a product then you need to have a driving vision behind it. Sometimes products fail because they are purely sales-led; being sales-led can lead to very short-term thinking since your only focus is on delivering the feature that's been promised for tomorrow, not on the product itself: _let's not worry about the passwords being stored in plain text, we have to deliver the feature tomorrow_.

Sometimes it can be better to think about all initial deliverables as a throw-away so you don't get stuck in the good-money-after-bad rut.
