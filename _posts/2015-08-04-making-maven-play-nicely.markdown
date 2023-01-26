---
layout: post
title: "Making Maven play nicely"
date: 2015-08-04 13:00
comments: false
#categories: [development, java]
tags: [development, java]
published: true
description: "Are Maven's opinionated conventions all that useful for any semi-complex build environment?"
keywords: "java, maven, ant"
header-img: img/banner_broken-plane.jpg
---

We use [Apache Ivy][] as our dependency management tool of choice; backed by an installation of [Sonatype Nexus][]. Recently, due to a restructure of some internal projects we're using Maven to publish (some) snapshot artefacts into our nexus repository and then referencing them when the time comes to generate our nightly downloads. You'd think this would be a relatively simple thing to do, but it was really much harder than it should have been.

<!-- more -->

Publishing into nexus using Maven isn't the problem. The real problem is the way in which Maven generates builds with timestamps for snapshot artefacts. Their argument is that _all builds have to be re-creatable_. My argument would be, it's a __snapshot__! It is surely implicit in the name that this artefact might change without warning; if you wanted a re-creatable build then promote the artefact to a formal release and host it in a release repository. Not only that, given that disk-space might still be a consideration, in all likelihood your Nexus admin is likely to have a purge job on the snapshot repository to delete old and stale artefacts which means that in 9 months time, when you come back to what you were doing, it's not the same as the last time anyway!

Anyway, our Maven artefacts are now published into Nexus, with a timestamp. A consequence of our _core runtime_ build process is that when we publish artefacts, we always publish a set of example XML for each available component. It is easier to do this using Ant+Ivy than it was to try and do this using Maven. This combination of a _custom ivy configuration_ with Maven timestamping behaviour now causes a bit of a headache within the scripts that prepare the downloadable zip file.

The problem is two-fold.

Because we have a custom ivy configuration; if we simply use an `<ibiblio>` repository in our _ivy-settings.xml_ then it will use the associated pom files by default (we are creating these for our own artefacts, because we want to play nice with others). This means that the ivy resolution phase never checks the associated ivy file, which means that we never find our custom ivy configurations giving you an unresolved dependency error.

```console
:: problems summary ::
:::: WARNINGS
  ::::::::::::::::::::::::::::::::::::::::::::::
  ::          UNRESOLVED DEPENDENCIES         ::
  ::::::::::::::::::::::::::::::::::::::::::::::
  :: com.adaptris#adp-core;3.0-SNAPSHOT: configuration not found in com.adaptris#adp-core;3.0-SNAPSHOT: 'examples'. It was required from com.adaptris#core-packaging;3.0-SNAPSHOT examples
  ::::::::::::::::::::::::::::::::::::::::::::::
```

So we have configured our repositories so that ivy doesn't think it is an ibiblio resolver:


```xml
<url name="snapshots" m2compatible="true" checkmodified="true" changingPattern=".*SNAPSHOT.*">
  <ivy pattern="${snapshots}/[organisation]/[module]/[revision]/ivy-[revision].xml"/>
  <artifact pattern="${snapshots}/[organisation]/[module]/[revision]/[artifact]-[revision].[ext]"/>
  <artifact pattern="${snapshots}/[organisation]/[module]/[type]/[artifact]-[revision].[ext]"/>
  <artifact pattern="${snapshots}/[organisation]/[module]/[type]/[artifact]-[revision]-[classifier].[ext]"/>
  <artifact pattern="${snapshots}/[organisation]/[module]/[type]/[artifact]-[revision]-[type].[ext]"/>
  <artifact pattern="${snapshots}/[organisation]/[module]/[type]s/[artifact]-[revision].[ext]"/>
  <artifact pattern="${snapshots}/[organisation]/[module]/[type]s/[artifact]-[revision]-[classifier].[ext]"/>
  <artifact pattern="${snapshots}/[organisation]/[module]/[type]s/[artifact]-[revision]-[type].[ext]"/>
</url>
```

The 2nd part of the problem is down to Maven's intransigence when building snapshot artefacts and their interaction with Ivy. Timestamped artefacts are supported by ivy (but only if you accept the ibiblio default patterns), but it means that we have to effectively duplicate the repository inside the ivy settings file only this time we treat it as a normal ibiblio repository:

```xml
<chain name="nexus-repo-resolver">
  <resolver ref="snapshots"/>
  <resolver ref="releases"/>
  <!-- This is an "extra" one so that we can resolve maven timestamped snapshots !! -->
  <ibiblio name="snapshots-ts" m2compatible="true" usepoms="true" root="${snapshots}" changingPattern=".*SNAPSHOT.*" checkmodified="true"/>
  <ibiblio name="public" m2compatible="true" root="${nexus-public}"/>
  <ibiblio name="private" m2compatible="true" root="${nexus-private}"/>
  <ibiblio name="thirdparty" m2compatible="true" root="${thirdparty}"/>
</chain>
```

In the end; the flexibility of Ant+Ivy won out over the conventions of Maven. You think you're clever Maven, but you really aren't.

[Sonatype Nexus]: http://www.sonatype.org/nexus/
[Apache Ivy]: http://ant.apache.org/ivy



