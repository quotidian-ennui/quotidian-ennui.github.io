---
layout: post
title: "Fixing your mercurial mistakes after the fact"
date: 2012-04-20 13:00
comments: false
#categories: [tech, development, scm]
tags: [tech, development, scm]
published: true
description: "Tidying up after yourself when you screw things up in mercurial"
keywords: "mercurial"
excerpt_separator: <!-- more -->
---

Our source code management tool of choice is [Mercurial](http://mercurial.selenic.com); which is a python based DVCS. We switched back in 2009 once we'd gotten fed up with CVS. There are still a few internal projects using CVS, but these days almost all the developers are using mercurial. People always ask why we never moved to subversion and generally my answer has always been  _because it's not *significantly* better than CVS_. Yes it _is_ better, it might even be CVS done right (not that this is a good advertisement for subversion); but ultimately, I need to use it on the plane or during a proof of concept with no external network access and collaborative development has to take place.

When you have a team of people actively maintaining a code base, someone somewhere is going to break something. It's unavoidable, skill levels, and interest levels in SCM tools vary massively. We tend to trust the people working on the codebase so more often than not everyone has push access to our repositories. That means mercurial is going to break, at some point, sometime. Just this last week, we had 2 SCM breakages in 2 separate projects, one of which I fixed, and the other was manually merged by the team of devs.

<!-- more -->

[Mercurial: The Definitive Guide](http://hgbook.red-bean.com/) is pretty much what it says on the tin; The [Finding and Fixing mistakes](http://hgbook.red-bean.com/read/finding-and-fixing-mistakes.html) chapter has all the answers, you just have to decide how you want to fix the problem.

## Rolling back a transaction

Ok; so the scenario is, Alice and Bob are writing code, and sharing it via a centralised repository. Carol comes along and makes a couple of changes and pushes them as well. Bob pulls the change, but realises that this change breaks something that he's working on locally.

You can revert the last transaction by using the _rollback_ command which allows you to rollback the last transaction; a fetch or pull treats all the changesets that were pulled as a single transaction so it's quite easy to rollback all the changes that you've pulled.

```console
lchan@atom /work/code
$ hg fetch
pulling from /work/staging_code
searching for changes
adding changesets
adding manifests
adding file changes
added 1 changesets with 1 changes to 1 files
1 files updated, 0 files merged, 0 files removed, 0 files unresolved

lchan@atom /work/code
$ hg rollback
repository tip rolled back to revision 1703 (undo pull)
working directory now based on revision 1703
```

If you are using the _fetch_ extension then this will leave some files that have been _merged_ but not checked in. You almost *certainly* want to do _hg update --clean_ to get rid of all the evidence now.

Remember that you've only modified your local repository here, the next time you pull, you're going to be the same position. There are changes out there, in the wild that you're going to have to merge at some point.

## Using histedit to remove changes

You could enable the histedit plugin and drop the changes you want, but this basically leaves you in the same situation as above, the changes are out there, and you're going to have to merge them in at some point in the future.

Of course you can force everyone to clone a fresh copy once you've replaced the master but you're generally better off using _backout_ as described next.

## Backing out your changes because it's too late, it's out there.

Ok; You've been happily checking your code into your local repository; your code is awesome. But _oh dear_ during a refactoring exercise you now realise that some of your code needs to be reverted back to a previous version because what was great an hour ago, isn't so great now. If you've been clever then each check-in is the _minimal set_ that needed to be checked in rather than a monolithic check-in where the _most suitable checkin message_ is actually *many many changes*[^1] then this shouldn't be too hard.

This is where the _backout_ command comes in. It won't delete the change you've made, but what it will do is create a new change that _reverses_ the change that you made (you've kept the history, and if you had to, you can revert back to the reverted back code). For example, I need to back out change 1704 and get rid of those _now not so awesome_ changes.

```console
$ hg log
changeset:   1705:b05f76acb193
tag:         tip
user:        Lewin Chan <lewin.chan@adaptris.com>
date:        Wed Apr 18 21:10:19 2012 +0100
summary:     This code is pretty good too.

changeset:   1704:6afbe4e1205a
user:        Lewin Chan <lewin.chan@adaptris.com>
date:        Wed Apr 18 20:39:18 2012 +0100
summary:     This code change is awesome...

changeset:   1703:1c3459c2f19f
user:        Lewin Chan <lewin.chan@adaptris.com>
date:        Wed Apr 18 20:34:45 2012 +0100
summary:     Fixed bug:1947 - the spitfires should now fire.

lchan@atom /work/code
$ hg backout --merge 1704
reverting build.xml
created new head
changeset 1706:cff8eece43c0 backs out changeset 1704:6afbe4e1205a
merging with changeset 1706:cff8eece43c0
merging build.xml
3 files to edit
0 files updated, 1 files merged, 0 files removed, 0 files unresolved
(branch merge, don't forget to commit)
```



[^1]: Back in the day, there was a tendency for some of the CVS commits to have _many many changes_ as the commit message; it's now part of our long and chequered history.

