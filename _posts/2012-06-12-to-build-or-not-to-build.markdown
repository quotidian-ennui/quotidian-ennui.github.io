---
layout: post
title: "To Build or Not to Build"
date: 2012-06-11 22:30
comments: false
categories: development rant
tags: [development, rant]
published: true
description: "Why I think a build step is critical for project collaboration"

---

I started doing Assembly, then C, dabbled in COBOL for a while so I've always had to have a build/compile step as of my development workflow. Working with Java hasn't been anything different, you use ant or maven to compile your source files and then run your tests. Lately I've been reading more and more about people _hating_ java and their myriad reasons for that. I don't think I have anything to add around that subject other than more invective so I shan't. I happen to know few languages and I just choose the best one for the job at hand, _just do the work_. Java has it's idiosyncrasies, but if your reason for hating java is that until recently you couldn't do a switch statement with Strings; you shouldn't hate java, you should hate yourself for being a programmer _who likes switch statements_ ;).

<!-- more -->

One of the things that always comes out is that all these _cool_ languages are dynamic; you don't need to compile them, so your feedback loop is much quicker. If you're building a webapp you can just edit `/var/www/html/myCoolPage.php`, hit reload and see your changes. _I'm not sure that this is a good thing_.

Fast feedback is useful and having a script _deploy.sh_ which does the same thing (i.e. copies any changed files from ~/workspace/myProject into /var/www/html) is only going to take, at worst, ~10 seconds. Is this time lag so critical to your schedule that you can't afford those 10 seconds? Take a step back and _consider your changes_, rather than rushing in; otherwise it's just [programming by coincidence](http://pragprog.com/the-pragmatic-programmer/extracts/coincidence). Required reading, along with Code Complete by Steve McConnell

## So, why have a build step

The build step is probably synonymous with the install step; it configures the application so that it can be run on your platform; it sorts out any dependencies you might need. After all installing new software on Linux is a breeze, you'll have done something like this countless times...

{% highlight console %}
[root@linux ~]# ./configure
[root@linux ~]# make clean test
[root@linux ~]# make install
{% endhighlight %}

Why do you think GNU Autotools, autoconf and all that other stuff came about? Is your application so awesome that you can plough your own furrow and not build on the shoulders of giants? Your application might be some wunderbar paradigm shifting piece of awesomeness; but more often than not, it's just an application; _average_ just like the rest of us. You need to have the discipline to lower the support burden for your colleagues; some of this is documentation, but a lot of it is to having something that makes it easy for others to collaborate with you on your project.

### Separation of Concerns

The deployable artefact, whatever that may be, is fundamentally a runtime artefact which might not have a 1-1 relationship to _what you check into your scm repository_. Having your mercurial project checked out into /var/www/html might seem like a good idea, but trust me, it just isn't, *EVER*[^1]. Well done, you have just forced your repository tree to mirror that of your own development environment. Your environment will differ from the production environment, you're working on Windows, it'll be deployed on Solaris x86; your filesystem is case insensitive, the production environment is case sensitive. Having a system whereby the SCM repository is bundled and packaged into the runtime artefact means that your repository is clean of any unwanted cruft.

### Deployment

I have a certain amount of sympathy for any sysadmin/deployment team; I feel sorry for them when I see some of the projects that they have to deploy. Lack of clear instructions, having to manually modify configuration files in multiple places, some of which aren't even documented. If you're too lazy to help them deploy _your project right_ then let's be honest, your project isn't worth deploying. Having to check something out, and then modify some source files (even it is to change the database string) before deploying violates the one of the cardinal rules: _Everything that gets deployed needs to be re-creatable from SCM from the checked in source._

Having a build step allows you to generate the runtime artefact with the correct runtime settings, drawing in all the correct dependencies and pre-requisites from a configuration file that you've filled out with information you've gotten from them.

{% highlight console %}
[deployer@linux ~]# hg clone -r TAG_NAME ssh://me@scm/project
[deployer@linux ~]# ant -Dbuild.environment=production clean war
{% endhighlight %}

The bare minimum of what you give your deploy team is something like the above; it should build you a deployable artefact, pre-configured for the production environment so that they can just drop into tomcat, WebsphereAS, JBoss or whatever. Better yet, set it up in hudson as a job; start using [flyway](http://flywaydb.org) to migrate your databases; it's then a one click deployment step.

Those are the primary reasons as to why I think a build step is a critical part of your development workflow. It's not glamorous, it's not cool, but like it or not, you'll spend less of your time debugging your production deployment because you've automated it; this means you can get on with something more interesting instead. Just because it works in _mvn jetty:run_ doesn't mean it will work when I deploy it in production in Weblogic.

[^1]: This piece is a direct consequence of one of our developers working in PHP in exactly this fashion; his webapp had an upload area in _/var/www/html_, and he had over 800Mb stored in it which he checked in into his local repo; he kept complaining that it was failing to push...
