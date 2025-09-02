---
layout: post
title: "Upgrading git on bookworm"
comments: false
tags: [development]
# categories: [development,rant]
published: true
description: "Because security hates your docker images."
keywords: ""
excerpt_separator: <!-- more -->
---

Well, it has come to pass that any images that have git installed on them, and are based on debian bookworm (which is a fair number of images, given that trixie is still relatively new) will trigger a security vulnerability because of [CVE-2025-48384](https://nvd.nist.gov/vuln/detail/CVE-2025-48384) which is very cool. Boom, the security team are telling you that you have to patch all the things because it's classed as a HIGH vulnerability (and 8.0 is high).

<!-- more -->

This is one of those times where I'd suggest that if you have a docker image, and you are in fact running `git clone --recursive` on repositories that are under your control, and yet _could have been weaponized_ then we have a slightly different of problems. If you are running `git clone --recursive` on random repositories that you do not control, inside your docker image then again, you potentially have a different set of problems.

There are things we know.

- git 2.47.3 has been accepted into the next update of debian trixie (this is a fixed version)
- there is a source package that is available to that effect
- we _could_ compile that source package and make it run on bookworm because compile from source right?

So, let's do that; with our proposed use-case of (why are we still using Jenkins?) _"the base jenkins agent images are vulnerable, please upgrade git on those images by EOB Today!"_; let's do that in the fastest way possible, leaving us with a safe version of git.

What we need to do is to basically

- download the source package
- build the appropriate .deb files
- install the .deb files into the actual runtime image.

```
ARG GIT_VERSION=2.47.3
ARG GIT_MAN_DEB=git-man_${GIT_VERSION}-0+deb13u1_all.deb
ARG GIT_BIN_DEB=git_${GIT_VERSION}-0+deb13u1_amd64.deb

FROM docker.io/jenkins/inbound-agent:jdk21 AS builder
ARG GIT_VERSION
ARG GIT_MAN_DEB
ARG GIT_BIN_DEB
USER root

RUN \
  apt -y update && \
  apt install --yes devscripts && \
  mkdir git-rebuild && \
  cd git-rebuild && \
  dget https://deb.debian.org/debian/pool/main/g/git/git_${GIT_VERSION}-0+deb13u1.dsc && \
  cd git-${GIT_VERSION} && \
  apt install --yes build-essential libpcre3-dev subversion libsvn-perl libyaml-perl cvs cvsps libdbd-sqlite3-perl dh-exec apache2-dev asciidoc xmlto docbook-xsl libz-dev libcurl4-gnutls-dev && \
  DEB_BUILD_OPTIONS=nocheck debuild -b -uc -us

FROM docker.io/jenkins/inbound-agent:jdk21
ARG GIT_MAN_DEB
ARG GIT_BIN_DEB
USER root

RUN \
  apt-get update && \
  apt-get --yes --no-install-recommends install jq unzip gnupg xz-utils && \
  apt-get clean && \
  rm -rf /tmp/* /var/cache/* /var/lib/apt/lists/*

RUN --mount=type=bind,source=/home/jenkins/git-rebuild,from=builder \
  dpkg -i ${GIT_MAN_DEB} ${GIT_BIN_DEB} && \
  git --version
```

There we go, a `docker build --progress=plain --tag my-jenkins-agent:latest --file Dockerfile` will show you the git version at the end; which will be _2.47.3_. The building of the package itself is easy since the packaging tools will tell you all the missing packages that you haven't yet installed so you just need to iteratively go through that.

> The bonus here is that, if you do this on your development machine, then there is no impact on `apt install gh`; otherwise compiling git from source means that you end up having to compile ghcli from source as well.