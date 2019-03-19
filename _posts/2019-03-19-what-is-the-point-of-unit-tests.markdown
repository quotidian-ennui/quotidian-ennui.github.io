---
layout: post
title: "What's the point of unit-tests"
comments: false
tags: [development,interlok]
categories: [development,interlok]
published: true
description: "Unit tests are like QA, backups and disaster recovery; you don't need it until you need it"
keywords: ""
excerpt_separator: <!-- more -->
---

Unit tests are good; that's the accepted truth and you won't find many developers that disagree with that statement. Yet we live in a world where there are projects running in production that don't have unit tests. In fact, having crap tests, like having unmaintained documentation, is, in any reasonably complex codebase, arguably worse than having no tests at all. _What then is the point of unit tests?_ Subjectively, I find that unit tests can be used as a measure of understanding what you're trying to deliver. 

<!-- more -->

If you haven't got time to do unit tests in the course of the project, then that means you've underestimated the scope of the problem; feature creep has occurred; and all the time you would have spent writing unit tests has now been burned on delivering new project features and/or meeting arbitrary deadlines. If you're in this position, then you're going to be constantly accruing technical debt since the likelihood is that ongoing maintenance and feature requests are going to managed under the _Columbo style of project management_ (`Just one last thing...`) which never ends well.

If on the other hand, you have 100% code coverage from unit tests then this probably just means you have too much time on your hands. The result may well be awesome, but if things have moved on and you've missed the window of opportunity, then sadly, it's a bit of a white elephant. After all good enough is more useful than perfect.

You don't have to have unit tests. Unit tests are like QA, backups, or disaster recovery; it's not needed until it's needed. This isn't a problem if you can keep track of all the possible side effects from changes you make. It doesn't scale that well, since everyone has to have the same understanding of the codebase as you do; and you're often left having the _Sword of Damocles_ hanging over your head in a support sense; this might be fine in the short term, but probably won't let you go and do something more interesting instead. I use unit tests to preserve the sanity of my future self.

Working in the integration space; I tend to fall into the camp that unit tests aren't as useful as integration tests. Accordingly, in [Interlok][], our unit tests are actually a combination of unit tests and integration tests (e.g. we actually start a JMS broker inline to run a bunch of tests); we tend not to mock unless we have to. The code coverage just gives us confidence to make changes; the code coverage metric actually differs between travis and our internal build server; up to about 6%; since the internal build server actually runs more tests since we know certain applications will be available that wouldn't be under travis.

[Interlok]: https://github.com/adaptris/interlok
