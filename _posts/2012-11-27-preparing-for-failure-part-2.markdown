---
layout: post
title: "Preparing for failure; part 2"
date: 2012-11-27 10:00
comments: false
categories: development
tags: [development]
published: true
description: "Setting the foundations for project success"
keywords: "team development management"

---

So, we've ascertained that projects are more likely to fail than succeed; but somehow we succeed a lot of the time. There are some general principles that I apply when delivering any project which I've found makes everyone a lot happier; the team, the business stakeholders, and me. A word of warning; anecdotal evidence is not science, no matter what some alternative therapists would have you believe; I'm not a PMP and I don't have any qualifications from the PMI. All of this might just be hokum and inapplicable outside of my experience.

<!-- more -->

The things developers do; things like continuous integration, test driven development, agile, whatever the flavor du jour is; are all secondary to these core principles. Continuous integration is going to be of marginal use if the project has already been setup to fail; it won't fix what's broken; but it will be effective in helping you give structure to your development process.

## Limit distractions

There have been plenty of studies[^1] around multi-tasking and the effects of having to switch tasks. _So don't_. Let the team work on the project without interruptions. The hoary story about locking a team of developers in a room with a supply of pizza and waiting for the project to be completed is one way you can look at it. I prefer to think of myself as the bouncer on the door to an exclusive nightclub; you have to make sure that _their name's on the list_ before they go in and disturb your VIPs. It's a subject that has been covered [many times](http://www.joelonsoftware.com/articles/fog0000000022.html), in [many blogs](http://www.codinghorror.com/blog/2006/09/the-multi-tasking-myth.html), and in [books](http://www.amazon.co.uk/Quality-Software-Management-Systems-Thinking/dp/0932633226/ref=sr_1_1?ie=UTF8&qid=1353786914&sr=8-1) by people with far more influence than me.

Interruptions will happen; your boss may need the team to help him so he can demo XYZ, or your skip-level has a pet project that is _super critical_. No matter what you do, some interruptions are inevitable; the only thing you can do is to make them aware of the cost of the interruption.

My productivity as the project manager is measured by my team's, not by my own. They're the ones wrestling with a thorny O(n ^2^) problem trying to get some updates to take less than 20hours; I'm just the guy that has his eye on the target.

## Get the right team/Trust the team

This goes without saying; when the team is firing on all cylinders then you increase productivity; the team has to work well together, and you have to trust that the team is going to deliver the project. Otherwse you're setting the project up to fail. This is so obvious that there's no point writing down all the pithy statements that spring to mind. If you've done your job properly then you will be able to trust the team to do theirs. If not, well that's a different story, either you should go; or you're going to have to let some of them go.

## Prepare now, so you can take it easy later

Projects don't fail at the end[^2]. Start the project in the right way, the rest of it is easy. Given a proof of concept that needs delivering, I don't dive in and just write code, I make sure that the CI server and environment is in place, my ant scripts are fit for purpose; I often think about how it needs to be packaged for delivery to the pre-sales engineers. When you start a project, there is a massive temptation for developers to ignore the end-game and to just start working on the nearest bit of code that seems to make sense. _Stop them_. As the project manager I have my eye on the target; I'm air traffic control, and the plane needs to take off safely. I'm also responsible for bringing the plane safely into land and being prepared helps you do just that.

## Reporting is not communication

Project meetings are often viewed as a waste of time by developers. It's nothing personal, but _it is distracting_ and distractions are bad. Manage and prioritise your project tasks in a collaboration tool ([we chose redmine for this]({{ site.baseurl }}/blog/2012/05/25/project-management-tools/)); hook that tool into the commit messages. Gather all that information and check the progress against your expectations. If they're radically different, then figure out why before you consider having a meeting (is it because your milestones are poorly thought-out and issues from other milestones have to be _done first_?). Having a daily or weekly status update meeting isn't going to be helpful, especially there is no clear objective to the meeting; you'll spend all your time talking about the same thing over and over again; *Reporting is not communication*; I can't stress this enough. The information will already be there, don't lower productivity by asking for it in an update meeting.

This also works to your own advantage, you can choose when you want to take a snapshot view of the project; you don't have to rely on status update meetings; you will be prepared when management come-a-knocking.

[^1]: Just search for multitasking studies on the web. There will be a lot of hits, some useful some not like most things on the web.
[^2]: That's what they say... _Projects don't fail at the end. They fail at the beginning._
