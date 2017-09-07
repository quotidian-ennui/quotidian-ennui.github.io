---
layout: post
title: "Project Management Tools"
date: 2012-05-25 13:00
comments: false
categories: development
tags: [development]
published: true
description: "Why we settled on redmine as our project management tool"
keywords: "redmine, centos"

---

Our main development management tool is [Redmine](http://www.redmine.org). It has been since December 2010. We tried a lot of tools before settling on redmine. It was the only one that we ended up going back to and using. If, after a month of trying to use something, you end up not using it, then either you're too set in your ways, or the tool isn't good enough. Our journey to settling on redmine as our web based project management tool is a long and chequered one, and it all started in 2010.

<!-- more -->

We are a fully distributed team; offices in South Africa, Sydney, London (and my house of course) will do that for you. Previously we used [Bugzilla](http://www.bugzilla.org) and [XPlanner](http://xplanner.codehaus.org/) as a basic project management tool[^1]; but outside of the circle of developers, no-one used it. Faced with project managers still using Excel to manage issues something had to change as it all just seemed like such a backward step into the early 90's. We got rid of XPlanner and kept bugzilla purely as a bug tracker. We tried to make bugzilla work as a lightweight project management tool (it can be integrated with, and we are experts at integration...), but it wasn't sexy enough or something. Perhaps the big picture of the ant put people off.

In the UK we tried [VersionOne](http://www.versionone.com) and ran a project using it but for the project management team it was too extreme; to be fair, we weren't strict agilists (still aren't) and some of the concepts didn't sit well with how we wanted to work.

Our Australian development team quickly settled on basecamp as their tool of choice, and it's pretty good. We ran a couple of projects in it but I wasn't altogether happy with it didn't integrate nicely with my check-in messages in mercurial; that and I'm a little bit paranoid about data being stored in the cloud.

We even tried [Teambox](http://teambox.com) briefly, but that really wasn't ready for prime time. If there was an agent that could update things based on my repository activity then perhaps. I do not want share with my team via Dropbox thank you very much.

In the end; there was Redmine, we used it for a month; and we actually found ourselves using it. Initially we still used bugzilla for tracking bugs, and we transitioned to using redmine fully for development by about Summer 2011. Bugzilla is still installed, and available, our CI server actually uses the bugzilla database for authentication purposes but all the projects are now closed for bug entry (a lot of things actually use the Bugzilla database for authentication).

Ultimately it comes down to this, developers treat the source code/check-in messages as the documentation. We don't really want to write more documentation or update a website with something that we've just written already. So being able to put as my checkin message

{% highlight text %}
redmineID #9876 and redmineID #9875

SLF4JBridgeHandler.install() is now called if the system property
jul.log4j.bridge is set to true. Explicitly added org.slf4j api with
a scope of provided so that it is not included in the jars in the
distribution.
This fixes #9876
{% endhighlight %}

and having this update both issue numbers with that comment, and _change the state of issue 9876 so that it is 90% complete_ means that a lot of the drudgery that helps to keep the project managers happy is automatically done for you and means we can get on with something more interesting instead.

Still change is a necessary part of the development lifecycle; we're currently evaluating Confluence + Jira in anticipation of making a move to a more unified tool in terms of project/product management and issue management. I personally _like_ redmine and I'll be sad to see it go but all our distributed teams will have to sacrifice something and unify on a single tool.

[^1]: I did actually have high hopes for XPlanner; but it's not a great advert when it seems you let your main domain name lapse.
